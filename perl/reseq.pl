#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin $Script); #perl脚本的路径
use File::Basename qw(basename dirname);
use Cwd qq(abs_path);#运行perl脚本的路径
my $BEGIN_TIME=time();
my $Time_Start = &sub_format_datetime(localtime($BEGIN_TIME));
print "Program Starts Time:$Time_Start\n";
#================================================================================
use newPerlBase;
my $Title="Reseq";
my $version="2.3";
my %config=%{selectconf("$Bin/confdir/")};
#=================================================================================
# ------------------------------------------------------------------
# GetOptions test1
# ------------------------------------------------------------------
my ($cfg,$assign,$mpu,$db,$qu,$ploidy,$link,$test,$ud,$type);
GetOptions(
				"help|?" =>\&USAGE,
				"c:s"=>\$cfg,
				"assign:s"=>\$assign,
				"maxcpu:s"=>\$mpu,
				"database:s"=>\$db,
				"queue:s"=>\$qu,
				"ploidy:s"=>\$ploidy,
				"link:s" => \$link,
				"ud:s" => \$ud,
				"type:s" => \$type,
				"test"=>\$test,
				) or &USAGE;


&USAGE unless ($cfg );#must be geven
$assign||="1,2,3,4,5,6,10,11,12,13"; #||是 或运算符···如果前面的变量为空··那么就会执行后面的表达式··进行赋值~~~
$ploidy||=2;
$qu||="general.q";
$link ||= "link";
$ud ||= 5000;
my %cfg_hash;
my %project_hash;
my %info_hash;
$cfg=abs_path($cfg);
open (IN,$cfg) or die $!;
my $maxcpu = defined $mpu ? $mpu : 100 ;
$type ||= "gene";
my $database;
{
	my $line=`cat /share/nas2/genome/bmksoft/tool/newPerlBase/v1.0/cluster`;chomp $line;#cluster hpc05
	if ($line =~ "hpc05") {
        $database = defined $db ? $db : "$Bin/Database/database_hpc05.cfg" ;
	}elsif($line =~ "hpc02"){
		$database = defined $db ? $db : "$Bin/Database/database_hpc02.cfg" ;
	}elsif($line =~ "biocloud"){
		$database = defined $db ? $db : "$Bin/Database/database_biocloud.cfg" ;
	}else{
		print "The hostname if $line \n Database should correct for new environment!!!\n";
		die;
	}
}

while (<IN>)
{
	chomp;
	next if ($_=~/\#/);
	next if ($_=~/^\s*$/);
	my @data=split/\s+/,$_;
	$cfg_hash{$data[0]}=$data[1] if ($_=~/^chr_id/);
	$cfg_hash{$data[0]}=$data[1] if ($_=~/^analysis_dir/);
	$cfg_hash{$data[0]}=$data[1] if ($_=~/^extra_fa/);
	$project_hash{$data[0]}=$data[1] if ($_=~/^Project/);
	if ($_=~/^key_Project*/)
	{
		my $pr=(split/\_/,$data[0])[1];
		$info_hash{$pr}{key}=$data[1];
	}
}
close(IN);


open (IN, $database) || die "Can't open $database, $!\n" ;
my %hdatabase = ();
while (<IN>){
	chomp ;
	next if (m/^\#/ || m/^\s*$/);
	my ($key, $value) = split ;
	$hdatabase{$key} = $value ;
}
close(IN);
my $database_dir = $hdatabase{Database_Dir} ;

#==================================================
createLog($Title,$version,$$,"$cfg_hash{analysis_dir}/log/",$test);
mkdirOrDie("$cfg_hash{analysis_dir}/Work_sh");

#open(SH,">$cfg_hash{analysis_dir}/Work_sh/All_project.sh") or die $!;
my $pre_step||=1000000000;
my ($step2,$step3,$step4,$step5,$step6,$step7,$step8);
my @reseq_step;
my $anno_step||=50000;
my $draw_step||=50000;
my $diff_step||=50000;
my $extr_step||=50000;
my $word_step||=50000;
my $ana_step;
my @step=split/\,/,$assign;
print "assign step for run : @step\n";
#@step=@step;
my @all=sort {$a<=>$b} @step;
for (my $st=0;$st<@step ;$st++)
{
	if ($step[$st]==1)
	{
		$pre_step=shift (@all);
	}
	if ($step[$st]==2)
	{
		$step2=shift (@all)-1;
		push @reseq_step,$step2;
	}
	if ($step[$st]==3)
	{
		$step3=shift (@all)-1;
		push @reseq_step,$step3;
	}
	if ($step[$st]==4)
	{
		$step4=shift (@all)-1;
		push @reseq_step,$step4;
	}
	if ($step[$st]==5)
	{
		$step5=shift (@all)-1;
		push @reseq_step,$step5;
	}
	if ($step[$st]==6)
	{
		$step6=shift (@all)-1;
		push @reseq_step,$step6;
	}
#	if ($step[$st]==7)
#	{
#		$step7=shift (@all)-1;
#		push @reseq_step,$step7;
#	}
#	if ($step[$st]==8)
#	{
#		$step8=shift (@all)-1;
#		push @reseq_step,$step8;
#	}
	if ($step[$st]==9)
	{
		$anno_step=shift (@all);
	}
	if ($step[$st]==10)
	{
		$draw_step=shift (@all);
	}
	if ($step[$st]==11)
	{
		$diff_step=shift (@all);
	}
	if ($step[$st]==12)
	{
		$extr_step=shift (@all);
	}
	if ($step[$st]==13)
	{
		$word_step=shift (@all);
	}
#	if ($step[$st]==14) {
#		$word_step=shift (@all);
#	}
#	if ($step[$st]==15) {
#		$word_step=shift (@all);
#	}
}
if (@reseq_step)
{
	$ana_step=join "\,",@reseq_step;
}

our $pipeline_log_dir= "$cfg_hash{analysis_dir}" ;
open(LOG,">>$pipeline_log_dir/bioinfor_pipeline.log") or die $!;
&pipeline_log("This project will be analysed in step $assign .");

#=================================================================
#=======================pipelines control=========================

######--------------------------rawdata subpipeline
if ($pre_step==1)
{
	&pipeline_log("step_1: Data preparation start.");
	my $cmd="perl $Bin/Data_preparation/preparation_analysis.pl -cfg $cfg -db $database_dir -queue $qu -ploidy $ploidy";#$Bin is /share/nas2/genome/bmksoft/pipeline/Reseq/v3.0.4
	open OUT ,">$cfg_hash{analysis_dir}/Work_sh/step1_Data_preparation.sh";
	print OUT $cmd;
	close OUT;
	&pipeline_log($cmd);
    stepStart(1,"Data preparation");
	runOrDie("$cfg_hash{analysis_dir}/Work_sh/step1_Data_preparation.sh");
	stepTime(1);
	&pipeline_log("step_1: Data preparation finished.");
}
#close LOG;

#---------------------------------Reseqv1.4 sub pipeline for SNP,inde, SV,CNV, snp_indel_annotation
if ($ana_step)
{
	&pipeline_log("Resequncing subpipeline starts: $ana_step");
	foreach my $pro (keys %project_hash)
	{
		unless (-d "$cfg_hash{analysis_dir}/Analysis")
		{
			`mkdir $cfg_hash{analysis_dir}/Analysis`;
		}
		my $cmd="perl $Bin/Resequncing_v1.4.pl -c $cfg_hash{analysis_dir}/main.conf -p $info_hash{$pro}{key} -od $cfg_hash{analysis_dir}/Analysis -assign $ana_step -database $database -queue $qu -link $link -ud $ud -maxcpu $maxcpu -type $type";
		open OUT,">$cfg_hash{analysis_dir}/Work_sh/Reseq_subpipeline.sh";
		print OUT $cmd;
		close OUT;
	}
	
	stepStart("2","Ref、Mapping、SNP、SV ");
	&pipeline_log("Ref, Mapping, SNP, SV, Annotation");
	qsubOrDie("$cfg_hash{analysis_dir}/Work_sh/Reseq_subpipeline.sh","middle.q",100);
	stepTime("2");
	&pipeline_log("Resequncing subpipeline Finished !!");
}


#-------------------------------------step 9
if ($anno_step==9)
{	
	&pipeline_log("step_9: Function analysis start.");
	my $cmd="perl $Bin/Function_anno/process_function_anno.pl -cfg $cfg -db $database_dir";
	open OUT,">$cfg_hash{analysis_dir}/Work_sh/step9_Function_analysis.sh";
	print OUT $cmd;
	close OUT;
	&pipeline_log($cmd);
    stepStart(9,"Function analysis");
	#runOrDie("$cfg_hash{analysis_dir}/Work_sh/step9_Function_analysis.sh");
	qsubOrDie("$cfg_hash{analysis_dir}/Work_sh/step9_Function_analysis.sh","middle.q",100);
	stepTime(9);
	&pipeline_log("step_9: Function analysis finished.");
}

#------------------------------step 10
if ($draw_step==10)
{
	&pipeline_log("step_10: Draw circos start.");
	my $cmd="perl $Bin/Draw_Circos/process_Circos.pl -cfg $cfg -db $database_dir";
	open OUT,">$cfg_hash{analysis_dir}/Work_sh/step10_Circos.sh";
	print OUT $cmd;
	close OUT;
	&pipeline_log($cmd);
    stepStart(10,"Draw circos");
	runOrDie("$cfg_hash{analysis_dir}/Work_sh/step10_Circos.sh");
	stepTime(10);
	&pipeline_log("step_10: Draw circos finished.");
}


#------------------------------------step 11
if ($diff_step==11)
{
	stepStart(11,"Different analysis");
	&pipeline_log("step_11: Different analysis start.");
	{
		my $cmd="perl $Bin/DiffAnalysis/deggene.stst.pl -cfg $cfg -queue $qu -type $type";
		open OUT,">$cfg_hash{analysis_dir}/Work_sh/step11_1_deggene_stst.sh";
		print OUT $cmd;
		close OUT;
		&pipeline_log($cmd);
        stepStart(11.1,"step11_1_deggene_stst");
		runOrDie("$cfg_hash{analysis_dir}/Work_sh/step11_1_deggene_stst.sh");
		stepTime(11.1);
	}
	{
		my $cmd="perl $Bin/DiffAnalysis/deg.gene.stat.pl -cfg $cfg";
		open OUT,">$cfg_hash{analysis_dir}/Work_sh/step11_2_deg_gene_stat.sh";
		print OUT $cmd;
		close OUT;
        stepStart(11.2,"diff_step_deg_gene_stat");
		runOrDie("$cfg_hash{analysis_dir}/Work_sh/step11_2_deg_gene_stat.sh");
		stepTime(11.2);
	}
	{
		my $cmd="perl $Bin/Function_anno/extract_DEG_gene_v1.1.pl -cfg $cfg -db $database_dir -queue $qu";
		open OUT,">$cfg_hash{analysis_dir}/Work_sh/step11_3_extract_DEG_gene.sh";
		print OUT $cmd;
		close OUT;
        stepStart(11.3,"diff_step_extract_DEG_gene");
		runOrDie("$cfg_hash{analysis_dir}/Work_sh/step11_3_extract_DEG_gene.sh");
		stepTime(11.3);
	}
	&pipeline_log("step_11: Different analysis finished.");
	stepTime(11);
}

#---------------------------------------------------step 12
if ($extr_step==12)
{
	my $cmd="perl $Bin/Word_report/result.extract_v1.1.pl -cfg $cfg -db $database_dir";
	print "$cmd\n";
	open OUT,">$cfg_hash{analysis_dir}/Work_sh/step12_extract_result.sh";
	print OUT $cmd;
	close OUT;
	
	#&pipeline_log("Step_10: Result extract start.");
#	&pipeline_log("step_10: Web report start.");
#	&show_log("#------------ Start Analysis...") ;
#	&run_or_die($cmd);	
#	&show_log("#------------ Analysis done.") ;
	#&pipeline_log("Step_10: Result extract finished.");
#	&pipeline_log("step_10: Web report finished.");
    stepStart(12,"Result extract");
	runOrDie("$cfg_hash{analysis_dir}/Work_sh/step12_extract_result.sh");
	stepTime(12);
}

#---------------------------------------------------step 13
if ($word_step==13)
{
	&pipeline_log("step_13: Web report start.");
   	my $cmd_html="$config{python} $Bin/Word_report/reseq_xml_report.py -i $cfg ";
	open OUT,">$cfg_hash{analysis_dir}/Work_sh/step13_web_report.sh";
	print OUT $cmd_html;
	close OUT;
	&pipeline_log($cmd_html);
    	stepStart(13,"Web report");
	runOrDie("$cfg_hash{analysis_dir}/Work_sh/step13_web_report.sh");
	stepTime(13);
	&pipeline_log("step_13: Web report finished.");
}

totalTime();

&pipeline_log("Analysis of this project is completed.");
close LOG;

#=====================================================================================

#if ($word_step==14) {
#	my $cmd_customer_backup="perl $Bin/Word_report/customer_backup_v1.0.pl -cfg $cfg -db $database_dir";
#	&show_log("#------------ Start Analysis...") ;
#	&run_or_die($cmd_customer_backup);
#	&show_log("#------------ Analysis done.") ;
#}
#if ($word_step==15) {
# 	my $cmd_bmk_backup="perl $Bin/Word_report/bmk_backup_v1.0.pl -cfg $cfg";
#	&show_log("#------------ Start Analysis...") ;
#	&run_or_die($cmd_bmk_backup);
#	&show_log("#------------ Analysis done.") ;
#}
###############Draw Circos#############################################################

#######################################################################################
my $Time_End   = sub_format_datetime(localtime(time()));
print STDOUT "Program Ends Time:$Time_End\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
#######################################################################################

# ------------------------------------------------------------------
# sub function
# ------------------------------------------------------------------
#######################################################################################

sub ABSOLUTE_DIR{ #$pavfile=&ABSOLUTE_DIR($pavfile);
	my $cur_dir=`pwd`;chomp($cur_dir);
	my ($in)=@_;
	my $return="";
	if(-f $in){
		my $dir=dirname($in);
		my $file=basename($in);
		chdir $dir;$dir=`pwd`;chomp $dir;
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

#######################################################################################

sub max{#&max(lists or arry);
	#求列表中最大值
	my $max=shift;
	my $temp;
	while (@_) {
		$temp=shift;
		$max=$max>$temp?$max:$temp;
	}
	return $max;
}

#######################################################################################

sub min{#&min(lists or arry);
	#求列表中最小值
	my $min=shift;
	my $temp;
	while (@_) {
		$temp=shift;
		$min=$min<$temp?$min:$temp;
	}
	return $min;
}

#######################################################################################

sub revcom(){#&revcom($ref_seq);
	#获取字符串序列的反向互补序列，以字符串形式返回。ATTCCC->GGGAAT
	my $seq=shift;
	$seq=~tr/ATCGatcg/TAGCtagc/;
	$seq=reverse $seq;
	return uc $seq;			  
}

#######################################################################################

sub GetTime {
	my ($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst)=localtime(time());
	return sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}

#######################################################################################

sub sub_format_datetime {#Time calculation subroutine
	my($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = @_;
	$wday = $yday = $isdst = 0;
	sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}
###########################################################
sub show_log()
{
	my ($txt) = @_ ;
	my $time = time();
	my $Time = &sub_format_datetime(localtime($time));
	print "$Time:\t$txt\n" ;
	return ($time) ;
}
#############################################################
sub pipeline_log()
{
	my ($txt) = @_ ;
	my $time = time();
	my $Time = &sub_format_datetime(localtime($time));
	my $exist =	`grep "$txt" "$pipeline_log_dir/bioinfor_pipeline.log"` ;
	print LOG "$Time:\t$txt\n" if (!$exist) ;
	return ($time) ;
}
######################################################################
#&run_or_die($cmd);
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
######################################################################
## qsub
sub qsub()
{
	my ($shfile, $queue, $ass_maxproc) = @_ ;
	$queue ||= $qu ;
	$ass_maxproc ||= $maxcpu ;
	if (`hostname` =~ /cluster/){
        	my $cmd = "sh $config{qsub} --maxproc $ass_maxproc --queue $queue --resource vf=15G --reqsub $shfile --independent" ;
		&run_or_die($cmd);
	}
	else{
        	my $cmd = "sh $config{qsub} --maxproc $ass_maxproc --queue $queue --resource vf=15G --reqsub $shfile --independent" ;
		&run_or_die($cmd);
	}
}
#########################################################################
sub USAGE {#
	my $usage=<<"USAGE";
	Description:
		v1.0:	production process different form Analysis process is uesed to improve efficiency
	Usage
	Forced parameter:
		-c           config file                                must be given
		
	Optional parameter:
		-assign      assign some steps to run                   optional [default: 1,2,3,4,5,6,10,11,12,13 ]
	step number:     
		             Data_Preparation                           1
		             mapping                                    2
		             calling SNP and short Indel                3
		             calling SV                                 4
		             detect CNV                                 5
		             snp annotation                             6
		             Draw Circos                                10
		             Different Analysis                         11
		             Result extract                             12
		             web  report                                13

		-database    database species list file                 optional [$Bin/Database/database.cfg]
		-maxcpu      max qsub num                               optional [100]
		-queue       specify queue                              optional [general.q] 
		-link        link or unlink scaffold                    optional [link]
		-ud          snpeff annotation region                   optional [5000]
		-type        gene/mRNA                                  optional [gene]
		-ploidy      ploidy can be specified using the -ploidy argument for non-diploid organisms.default 2;
		-test	     test mode
	Other parameter:
		-h           Help document

USAGE
	print $usage;
	exit;
}
