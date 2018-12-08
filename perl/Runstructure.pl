#!/usr/bin/perl -w

use strict;
use Cwd qw(abs_path);
use Getopt::Long;
use Data::Dumper;
use File::Basename qw(basename dirname);
use FindBin qw($Bin $Script);

my $version= "1.0";
my $Writer = "wangyt";
my $Date   = "2018/04/02";

#######################################################################################
my ($vcf,$key,$od,$maf,$int,$minK,$maxK,$rep);
my ($queue,$maxproc);
GetOptions(
	"vcf:s"	=> \$vcf,
	"od:s"	=> \$od,
	"key:s" => \$key,
	"maf:f" => \$maf,
	"int:f" => \$int,
	'minK:i' => \$minK,
	'maxK:i' => \$maxK,
	'rep:i' => \$rep,
	'queue:s' => \$queue,
	'maxproc:i' => \$maxproc,
	"h|?" => \&help,
) || &help;

&help unless ($vcf && $key && $od ); #必须有的参数,没有提示help

sub help
{
	print <<"	Usage End.";
	
    Description:
        Data    : $Date
        Version : $version
        Writer  : $Writer
    Usage:
        -vcf     <file>      must be given
        -od      <dir>       must be given
        -key     <str>       must be given  
                
        -maf     [0.05]
        -int     [0.8]
        -minK    [1]
        -maxK    [11]
        -rep     [3]
        
        -queue   general.q
        -maxproc 80
                                                            
        -h       Help document
        
	Usage End.
	exit;
}

mkdir($od,0755) unless -d $od;如果没有$od，则chainman
$od = abs_path($od); #全路径
$vcf = abs_path($vcf);#全路径
$maf ||= 0.05; 或者
$int ||= 0.8;
$minK ||= 1;
$maxK ||= 11;
$rep ||= 3;
$queue ||= "general.q";
$maxproc ||= 80;

######################################################################################
my $Time_Start;
$Time_Start = sub_format_datetime(localtime(time()));
print "\nStart Time :[$Time_Start]\n\n";
######################################################################################

#vcftools文件进行过滤
mkdir("$od/1_vcf",0755) unless -d "$od/1_vcf"; #创建文件夹
my $cmd = "$Bin/vcftools --vcf $vcf --out $od/1_vcf/$key --recode --maf $maf --max-missing $int  --remove-indels --min-alleles 2 --max-alleles 2";
#$Bin是脚本所在位置
&run_or_die($cmd);#子程序，运行上面的命令

#基于LD过滤连锁位点，保留中性位点
open IN,"$od/1_vcf/$key.recode.vcf" or die $!; #前面生成了$key.recode.vcf
open OUT,">$od/1_vcf/$key.recode.id.vcf" or die $!; #$key.recode.id.vcf
while(<IN>){
	chomp;
	next if /^$/;
	if( /^\#/){
		print OUT "$_\n";
	}else{
		my ($chr,$pos,undef,@res) = split /\s+/;
		my $id = join("__",$chr,$pos);
		my $res = join "\t",@res;
		print OUT "$chr\t$pos\t$id\t$res\n";
	}	
}
close IN;
close OUT;

mkdir("$od/2_plink") unless -d "$od/2_plink"; #生成$od/2_plink文件夹
mkdir("$od/3_structure") unless -d "$od/3_structure"; #生成$od/3_structure
$cmd = "cd $od/2_plink && $Bin/plink --noweb --vcf $od/1_vcf/$key.recode.id.vcf --indep-pairwise 212 5  0.2 --out $key --allow-extra-chr ";
#
&run_or_die($cmd);
$cmd = "cd $od/3_structure &&  $Bin/plink --noweb --vcf $od/1_vcf/$key.recode.id.vcf --extract $od/2_plink/$key.prune.in --recode structure --out $od/3_structure/$key --allow-extra-chr";
&run_or_die($cmd);

# structure分析
my $structure = "$od/3_structure/$key.recode.strct_in";
#样本数
my $sam = (split /\s+/, `wc -l $structure`)[0] ; 
chomp $sam;
$sam = $sam-2;#去除前两行（第一行是chr,第二行是数字）
#位点数
my $loci = `head -n 1 $structure \| perl -ne \'\@a=split; print scalar \@a\'` ; #列数，即pos数 ; \| \' \@ 需要转义 
chomp $loci;

mkdir("$od/4_result") unless -d "$od/4_result";
open SH, ">$od/structure.sh" or die $!;
for (my $i=1;$i <= $rep;$i++){  #前面定义了$rep ||= 3;
	for($minK..$maxK){  # 前面定义了$minK ||= 1; $maxK ||= 11;
		print SH "$Bin/structure -m $Bin/mainparams_structure.cfg -e $Bin/extraparams_structure.cfg -K $_ -i $structure  -o $od/4_result/$key\_structure_K_$_\_$i  -L $loci -N $sam -D $i\n";
		#$Bin/extraparams_structure.cfg 脚本路径下面的文件
		#-K $_  $_是
		# -o $od/4_result/$key\_structure_K_$_\_$i  \_转义
	}
}
my $sh = "$od/structure.sh";
&qsub($sh,$queue,$maxproc);

#绘图
my $file = "$od/2_plink/$key.nosex";
mkdir("$od/5_final") unless -d "$od/5_final";
$maxK = $maxK -1;
$cmd = "/share/nas1/wangyt/software/R-3.4.3/bin/Rscript $Bin/structure.R $od/4_result/  $od/5_final/  $file $minK $maxK";
&run_or_die($cmd);
my $pdf = "$od/5_final/*.pdf";
$cmd = "cd $od/5_final/ && convert $pdf $key.png"; #convert是一个软件可以将pdf转换为png
&run_or_die($cmd);
$cmd = "/share/nas2/genome/bin/Rscript $Bin/deltaK.R $od/5_final/evannoMethodStructure.txt";
&run_or_die($cmd);

#结果整理
mkdir("$od/6_backup",0755) unless -d "$od/6_backup";
$cmd = "cd $od/5_final && cp *.pdf evannoMethodStructure.txt summariseQ.txt tabulateQ.txt $od/6_backup  &&  cp -r pop-both $od/6_backup/ && cd $od/6_backup && cd pop-both && rm *combined-aligned.txt";
&run_or_die($cmd);

my $lnk = 0;
my %hash;
open IN,"$od/5_final/evannoMethodStructure.txt" or die $!;
while(<IN>){
	chomp;
	next if /deltaK/;
	next if /NA/;
	my ($bestk,$value) = (split /\s+/)[2,14];
	$hash{$value} = $bestk;
	$lnk = $value if $value > $lnk;	
}
close IN;
my $bestk = $hash{$lnk};

my $Qmatrix = "$od/6_backup/pop-both/pop_K$bestk\-combined-merged.txt";
$cmd = "/share/nas2/genome/bin/Rscript $Bin/deal_result.R $file $Qmatrix $od/6_backup $key";
&run_or_die($cmd);
`sed -i '1i<Covariate>' $od/6_backup/$key.best_K$bestk.txt`; #在文件的一行插入<Covariate>，1i是第一行


#############################################################################
sub sub_format_datetime #Time calculation subroutine
{
        my($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = @_;
        $wday = $yday = $isdst = 0;
        sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}

sub Runtime # &Runtime($BEGIN);
{
        my ($t1)=@_;
        my $t=time()-$t1;
        print "Total elapsed time : [",&sub_time($t),"]\n";
}

sub sub_time
{
        my ($T)=@_;chomp $T;
        my $s=0;my $m=0;my $h=0;
        if ($T>=3600) {
                my $h=int ($T/3600);
                my $a=$T%3600;
                if ($a>=60) {
                        my $m=int($a/60);
                        $s=$a%60;
                        $T=$h."h\-".$m."m\-".$s."s";
                }else{
                        $T=$h."h-"."0m\-".$a."s";
                }
        }else{
                if ($T>=60) {
                        my $m=int($T/60);
                        $s=$T%60;
                        $T=$m."m\-".$s."s";
                }else{
                        $T=$T."s";
                }
        }
        return ($T);
}

sub run_or_die()
{
        my ($cmd) = @_ ;
        &show_log($cmd);
        my $flag = system($cmd) ;
        if ($flag != 0){
                &show_log("Error: command fail: $cmd");
                exit(1);
        }
        &show_log("done.");
        return ;
}

sub show_log()
{
        my ($txt) = @_ ;
        my $time = time();
        my $Time = &sub_format_datetime(localtime($time));
        print "$Time:\t$txt\n" ;
        return ($time) ;
}

sub qsub()
{
        my ($shfile, $queue, $ass_maxproc) = @_ ;
        if (`hostname` =~ /cluster/){
                my $cmd = "sh /share/nas2/genome/bmksoft/tool/qsub_sge_plus/v1.0/qsub_sge.plus.sh $shfile --maxproc $ass_maxproc --queue $queue --resource vf=15G --independent --reqsub" ;
                &run_or_die($cmd);
        }
        else{
                my $cmd = "sh /share/nas2/genome/bmksoft/tool/qsub_sge_plus/v1.0/qsub_sge.plus.sh $shfile --maxproc $ass_maxproc --queue $queue --resource vf=15G --independent --reqsub" ;
                &run_or_die($cmd);
        }
}



