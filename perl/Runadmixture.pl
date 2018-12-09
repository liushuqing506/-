#!/usr/bin/perl -w

use strict;
use Cwd;
use Getopt::Long;
use Data::Dumper;
use File::Basename qw(basename dirname);#文件路径
use FindBin qw($Bin $Script);#脚本路径

my $programe_dir = basename($0);  
my $path         = dirname($0);
#$0一般指脚本，basename($0)脚本的名字，dirname($0)脚本的路径
my $ver    = "1.0";
my $Writer = "Yangzj <yangzj\@biomarker.com.cn>";
my $Data   = "2012/9/12";
my $BEGIN  = time();

#######################################################################################

my ($snplist,$od,$key);
my ($C,$minInt,$minMAF,$minK,$maxK);

GetOptions(
			"snplist:s"	=>	\$snplist,
			"od:s"	=>	\$od,
			"key:s"	=>	\$key,	# keyname
			
			"minMAF:s"	=>	\$minMAF,	# minMAF
			"minInt:s"	=>	\$minInt,	# minInt
			"C:s"	=>	\$C,
			"minK:s"	=>	\$minK,
			"maxK:s"	=>	\$maxK,
			"h|?"	=>	\&help,
			) || &help;
&help unless ($snplist && $od);

sub help
{
	print <<"	Usage End.";
    Description:
        Writer  : $Writer
        Data    : $Data
        Version : $ver
        function: ......
    Usage:
        -snplist          snplist     must be given
        -od               outdir      must be given
        -key              keyname     must be given
		-C         <float|integer>    if <1, likehood less then C stop running. if >1, a maximum number C of iterations. [defaults: 0.01]
        -minMAF           <float>     Minor Allele Frequency, [0.05]
        -minInt           <float>     Allele Intergrity Frequency, [0.1]
        -minK             <int>       [2]
        -maxK             <int>       [10]
        -h                Help document
	Usage End.
	exit;
}

#######################################################################################
my $Time_Start;
$Time_Start = sub_format_datetime(localtime(time()));
print "\nStart $programe_dir Time :[$Time_Start]\n\n";
#######################################################################################
$minK ||= 2;$maxK ||= 10;
my $hostname=`hostname`;chomp $hostname;# 集群名
$snplist = &ABSOLUTE_DIR($snplist); # $snplist绝对路径
mkdir $od if (!-d $od);$od = &ABSOLUTE_DIR($od);#
$minMAF ||= 0.05;
$minInt ||= 0.5;
$C ||= 0.01;

`perl $Bin/bin/snp2xxx.pl -snplist $snplist -od $od -key $key -minMAF $minMAF -minInt $minInt -admixture `;
$minK ||= 2;$maxK ||= 10;my $admixturefile = "$od/admixture/$key.ped";
print "    admixture -minK $minK -maxK $maxK \n";
my $admixturetxt = "$od/admixturetxt";
mkdir $admixturetxt if (!-d $admixturetxt);
my $admixturepng = "$od/admixturepng";
mkdir $admixturepng if (!-d $admixturepng);

my $admixturesh = "$od/admixture.sh";
open (SH,">$admixturesh") || die "$!";
for ($minK..$maxK){
	#print SH "$Bin/bin/admixture -C $C --cv $admixturefile $_ &&\n";
	print SH "$Bin/bin/admixture -C $C --cv $admixturefile $_ >$od/admixture/cv\_$_\.log\n";
	#$_ 是从$minK..$maxK
}
close SH;

	#` sh /share/nas2/genome/bmksoft/tool/qsub_sge_plus/v1.0/qsub_sge.plus.sh --reqsub $admixturesh `;
	`cd $od/admixture && sh $admixturesh`;


#my $admixtureshdir = glob("${admixturesh}*qsub");
my $admixtureshdir = glob("$od/admixture");

`perl $Bin/bin/Getadmixturetxt.pl -file $admixturefile -id $admixtureshdir -od $admixturetxt -key $key `;

`perl $Bin/bin/Kvaluedistribution.pl -i $admixturetxt/$key.K_value_select -key $key -od $admixturetxt `;

`perl $Bin/bin/Population_structure.2.0.pl -id $admixturetxt -o $admixturepng/$key.admixture.svg `;


#######################################################################################
my $Time_End;
$Time_End = sub_format_datetime(localtime(time()));
print "\nEnd $programe_dir Time :[$Time_End]\n\n";
&Runtime($BEGIN);
#######################################################################################

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
	print "Total $programe_dir elapsed time : [",&sub_time($t),"]\n";
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

sub ABSOLUTE_DIR #$pavfile=&ABSOLUTE_DIR($pavfile);
{
	my $cur_dir=`pwd`;chomp($cur_dir);
	my ($in)=@_;
	my $return="";
	if(-f $in){
		my $dir=dirname($in);
		my $file=basename($in);
		chdir $dir;$dir=`pwd`;chomp $dir; #chdir 函数来切换当期目录
		$return="$dir/$file";
	}elsif(-d $in){
		chdir $in;$return=`pwd`;chomp $return;
	}else{
		warn "Warning just for file and dir\n";
		exit;
	}
	chdir $cur_dir;
	return $return;
}

