#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $BEGIN_TIME=time();
my $Time_Start = &sub_format_datetime(localtime($BEGIN_TIME));
print "Program Starts Time:$Time_Start\n";

#===============================================================
use newPerlBase;
my $Title="count_deg_snp";
my $version="1.0.0";
#my %config=%{readconf("$Bin/../reseq_script.cfg")};
my %config=%{selectconf("$Bin/../confdir/")}; 
#===============================================================

# ------------------------------------------------------------------
# GetOptions
# ------------------------------------------------------------------
my ($fIn,$fOut);
GetOptions(
				"help|?" =>\&USAGE,
				"o:s"=>\$fOut,
				"i:s"=>\$fIn,
				) or &USAGE;
&USAGE unless ($fIn and $fOut);
my %snp_hash;
open (IN,$fIn) or die $!;
open (OUT,">$fOut") or die $!;
#$/=">";
my @sample_num;
while (<IN>) 
{
	chomp;
	if ($_=~/\#/) #以#开头行
	{
		my @sample=split/\t/,$_; #拆分
		for (my $i=0;$i<@sample ;$i++) #遍历第一行
		{
			if ($sample[$i]=~/^R\d+/) #如果以R+数字开头
			{
				push(@sample_num,$sample[$i]); #将所有样本编号存入数组
			}
		}
		next;
	}
	next if ($_=~/^\s*$/); #如果以$开头则跳过
	my @data=split /\t/,$_;  #非#和$开头行，拆分
	for (my $i=3;$i<@data;$i++)  #从3开始，即样本行为第3列
	{
#		print "$data[$i]\n";
		my $sam1_num=$i-3;  
		for (my $j=3;$j<@data;$j++)#
		{
			my $sam2_num=$j-3;
#			print "$data[$j]\n";die;
			if ($data[$i] ne $data[$j]&&$data[$i]!~/N/&&$data[$j]!~/N/)
			{
				$snp_hash{$sample_num[$sam1_num]}{$sample_num[$sam2_num]}++;
			}
			if ($sample_num[$sam1_num] eq $sample_num[$sam2_num])
			{
				$snp_hash{$sample_num[$sam1_num]}{$sample_num[$sam2_num]}=0;
			}
		}
	}
}
print OUT " \t";
foreach my $k1 (sort keys %snp_hash)
{
	print OUT "$k1\t"
}
print OUT "\n";
foreach my $sam1 (sort keys %snp_hash)
{
	print OUT "$sam1\t";
	foreach my $sam2(sort keys %{$snp_hash{$sam1}})
	{
		print OUT "$snp_hash{$sam1}{$sam2}\t";
	}print OUT "\n";
}








close (IN) ;
close (OUT) ;
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
	#求列表中的最大值
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
	#求列表中的最小值
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

sub USAGE {#
	my $usage=<<"USAGE";
ProgramName:
Version:	$version
Contact:	Wu jianhu <wujh\@biomarker.com.cn> 
Program Date:   2014.7.10
Description:	this program is used to extract DEG snp from *.snp
Usage:
  Options:
  -i <file>  input file,forced :eg :xxx/SNP/result/cucumber.formal.snp.vqsr.filter.snp
  
  -o <file>  output file,forced  
 
  -h         Help

USAGE
	print $usage;
	exit;
}
