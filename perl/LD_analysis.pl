#! /usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Cwd qw(abs_path);
use File::Basename qw(dirname basename);
use Data::Dumper;
use FindBin qw($Bin $Script);

###getopt
my ($vcf,$maf,$int,$chrid,$od,$key,$window,$chrlen,$group);
my ($maxproc,$queue);
my ($plink,$haploview);
my ($r2,$nor2);
my ($ref);

GetOptions(
	'h|?'  => \&help,
	"vcf:s"  => \$vcf,
	"od:s"	=> \$od,
	"key:s" => \$key,
	"chrid:s" => \$chrid,
	"maf:f"	=> \$maf,
	"int:f"	=> \$int,
	"window:i" => \$window,
	"maxproc:i" => \$maxproc,
	"queue:s" => \$queue,
	"plink:s" => \$plink,
	"haploview:s" => \$haploview,
	"r2:f" => \$r2,
	"chrlen:s" => \$chrlen,
	"ref:s" => \$ref,
	"group:s" => \$group,
	"nor2:f" => \$nor2,
 ) || &help;

&help unless ($vcf and $od and $key);
die "You must be select at least one of plink and haploview!\n" if(!defined $plink and !defined $haploview and defined $ref);
die "You must be provide the chrlen if you select ref!\n" if(defined $ref and !defined $chrlen );
die "You must be provide the chrid if you select ref!\n" if(defined $ref and !defined $chrid );

$vcf = abs_path($vcf);
mkdir($od,0755) unless -d $od;
$od = abs_path($od);
$chrid = abs_path($chrid) if defined $ref;
$chrlen = abs_path($chrlen) if defined $ref;
$group = abs_path($group) if defined $group;

$maf ||= 0.05;
$int ||= 0.8;
$window ||= 1000;
$maxproc ||= 100;
$queue ||= "general.q";
$r2 ||= 0;
$nor2 ||= 0.8;

###########################
my $Time_Start;
$Time_Start = &sub_format_datetime(localtime(time()));
print "\nStart Time :[$Time_Start]\n\n";

if (defined $ref){
	###chrlen
	my (%chrlen);
	open CHRLEN,$chrlen or die $!;
	while(<CHRLEN>){
		chomp;
		next if /^$/;next if /^\#/;
		my ($chr,$len) = (split /\s+/)[0,1];
		next if $len < $window*1000;
		$chrlen{$chr} = $len; #小于100万的
	}
	close CHRLEN;

	###filter the vcf by maf and int
	mkdir("$od/genotype",0755) unless -d "$od/genotype";
	my $cmd = "cd $od/genotype && $Bin/vcftools --vcf $vcf --out $key --maf $maf --max-missing $int --remove-indels --recode --min-alleles 2 --max-alleles 2\n";
	&run_or_die($cmd);
	###judge chr in vcf or not in 
	open VCF,"$od/genotype/$key.recode.vcf" or die $!;
	my %truelen;
	while(<VCF>){
		chomp;
		next if /^$/;next if /^\#/;
		my ($chr, $pos, $other) = split(/\s+/, $_, 3);
		if(exists $chrlen{$chr}){  #$chrlen{$chr} = $len; #小于100万的
			$truelen{$chr} = $pos;
		}else{
			delete $chrlen{$chr};	
		}
	}
	close VCF;
	###filter the chr in chrlen and chrid
	for my $chr(keys %truelen){
		if($truelen{$chr} < $window*1000){
			delete $chrlen{$chr};
		}
	}
	###combine the chrlen
	###my $chr = "--chr ".(join "  --chr ",sort keys %chrlen);
	### filter the chromsome by chrlen
	open VCF,"$od/genotype/$key.recode.vcf" or die $!;
	open OUT,">$od/genotype/$key.filter.recode.vcf" or die $!;
	while(<VCF>){
		chomp;
		next if /^$/;
		if(/^#/){
			print OUT "$_\n";
		}else{
			my ($chr) = (split /\s+/)[0];
			if(exists $chrlen{$chr}){
				print OUT "$_\n";
			}
		}
	}
	close OUT;
	close VCF;
	#$cmd = "cd $od/genotype && $Bin/vcftools --vcf $key.recode.vcf --recode --out $key.filter $chr\n";
	#&run_or_die($cmd);
	$vcf = "$od/genotype/$key.filter.recode.vcf";
	
	#deal with group info
	if(defined $group){
		open GROUP,$group or die $!;
		mkdir("$od/group",0755) unless -d "$od/group";
		system("rm $od/group/*");
		my (%color,@col,$col);
		while(<GROUP>){
			chomp;
			next if /^$/;next if /^\#/;
			my ($sam,$info,$color) = (split /\s+/)[2,3,4]; # $color没有	
			if(defined $color){
				$color{$info} = $color;
			}
			die "Your keyword[$key] is the same with the $info and please change it!\n" if $key eq $info;
			open OUT,">>$od/group/$info" or die $!; #将同一组的样本写入组文件
			print OUT "$sam\n";
			close OUT;
			open ALL,">>$od/group/$key" or die $!;#将所有样本写入一个关键词文件
			print ALL "$sam\n";
			close ALL;
		}
		if(%color){
			foreach my $keys(sort keys %color){
				chomp $keys;
				push @col,$color{$keys};
			}
			$col = join ",",@col;
		}
		close GROUP;
		my @group = glob "$od/group/*"; #几个分组和总的
		mkdir("$od/work_sh",0755) unless -d "$od/work_sh";
		$cmd = "";
		open SH,">$od/work_sh/format.sh" or die $!;
		foreach my $info(@group){ #逐一提取@group
			chomp $info;
			my $base = basename($info);
			mkdir("$od/SNP",0755) unless -d "$od/SNP";
			$cmd .= "cd $od/SNP && $Bin/vcftools --vcf $vcf --recode --out $base --keep $info && perl $Bin/vcf_to_snplist_v1.2.pl -i $base.recode.vcf -o $base.snplist -ref 0\n";
			#生成组和总的vcf文件
		}
		print SH "$cmd"; #将$cmd 写入$od/work_sh/format.sh
		close SH;
		&qsub("$od/work_sh/format.sh",$queue,$maxproc);
		
		##plink
		if(defined $plink){
			mkdir("$od/plink",0755) unless -d "$od/plink";
			my @snplist = glob "$od/SNP/*.snplist";
			mkdir("$od/work_sh",0755) unless -d "$od/work_sh";
			open SH,">$od/work_sh/plink_ld.sh" or die $!;
			$cmd = "";
			foreach my $snplist(@snplist){
				chomp $snplist;
				my $base = basename($snplist);
				$base =~ s/\.snplist//g; #将.snplist去除
				$cmd .= "perl $Bin/LD_plink.pl -snplist $snplist -od $od/plink/$base -key $base -chrid $chrid -minMAF $maf -minInt $int -ld_window_kb $window -ld_window_r2 $r2\n";
			}
			print SH "$cmd";
			close SH;
			&qsub("$od/work_sh/plink_ld.sh",$queue,$maxproc);

			mkdir("$od/plink/LD_group",0755) unless -d "$od/plink/LD_group";
			foreach my $info(@group){  
				chomp $info;
				my $base = basename($info);
				next if $base eq $key;
				`cp $od/plink/$base/decay_chrom/$base.r2 $od/plink/LD_group`;
			}
			$cmd = "";
			if(%color){
				$cmd = "Rscript $Bin/plot_LD_line.R --indir $od/plink/LD_group --key ${key}_group --outdir $od/plink --xlim $window --lowess F --chrom F --all T --color $col --lesize 0.6 --lewidth 0.5 --legendsize 6\n";
				print $cmd;
				`$cmd`;				
			}else{
				$cmd = "Rscript $Bin/plot_LD_line.R --indir $od/plink/LD_group --key ${key}_group --outdir $od/plink --xlim $window --lowess F --chrom F --all T --lesize 0.6 --lewidth 0.5 --legendsize 6\n";
				print $cmd;
				`$cmd`;				
			}
		}
		###haploview
		if(defined $haploview){
			mkdir("$od/haploview",0755) unless -d "$od/haploview";
			my @snplist = glob "$od/SNP/*.snplist";
			mkdir("$od/work_sh",0755) unless -d "$od/work_sh";
			open SH,">$od/work_sh/haploview_ld.sh" or die $!;
			$cmd = "";
			foreach my $snplist(@snplist){
				chomp $snplist;
				my $base = basename($snplist);
				$base =~ s/\.snplist//g;
				$cmd .= "perl $Bin/LD_haploview.pl -snplist $snplist -od $od/haploview/$base -key $base -chrid $chrid  -minMAF $maf -minInt $int -maxdistance $window\n"
			}
			print SH "$cmd";
			close SH;
			&qsub("$od/work_sh/haploview_ld.sh",$queue,$maxproc);
			mkdir("$od/haploview/LD_group",0755) unless -d "$od/haploview/LD_group";
			foreach my $info(@group){
				chomp $info;
				my $base = basename($info);
				next if $base eq $key;
				`cp $od/haploview/$base/decay_chrom/$base.r2 $od/haploview/LD_group`;
			}
			$cmd = "";
			if(%color){
				$cmd = "Rscript $Bin/plot_LD_line.R --indir $od/haploview/LD_group --key ${key}_group --outdir $od/haploview --xlim $window --lowess F --chrom F --all T --color $col --lesize 0.6 --lewidth 0.5 --legendsize 6\n";
				print $cmd;
				`$cmd`;
			}else{
				$cmd = "Rscript $Bin/plot_LD_line.R --indir $od/haploview/LD_group --key ${key}_group --outdir $od/haploview --xlim $window --lowess F --chrom F --all T --lesize 0.6 --lewidth 0.5 --legendsize 6\n";
				print $cmd;
				`$cmd`;				
			}
		}
		
	}else{
		$cmd = "";
		mkdir("$od/SNP",0755) unless -d "$od/SNP";
		$cmd = "cd $od/SNP && perl $Bin/vcf_to_snplist_v1.2.pl -i $vcf -o $key.snplist -ref 0 \n";
		print $cmd;
		`$cmd`;
		if(defined $plink){
			mkdir("$od/plink",0755) unless -d "$od/plink";
			mkdir("$od/work_sh",0755) unless -d "$od/work_sh";
			open SH,">$od/work_sh/plink_ld.sh" or die $!;
			my $snplist = "$od/SNP/$key.snplist";
			my $base = basename($snplist);
			$base =~ s/\.snplist//g;
			$cmd = "perl $Bin/LD_plink.pl -snplist $snplist -od $od/plink/$base -key $base -chrid $chrid -minMAF $maf -minInt $int -ld_window_kb $window -ld_window_r2 $r2\n";
			print SH "$cmd";
			close SH;
			&qsub("$od/work_sh/plink_ld.sh",$queue,$maxproc);
		}
		if(defined $haploview){
			mkdir("$od/haploview",0755) unless -d "$od/haploview";
			mkdir("$od/work_sh",0755) unless -d "$od/work_sh";
			open SH,">$od/work_sh/haploview_ld.sh" or die $!;
			my $snplist = "$od/SNP/$key.snplist";
			my $base = basename($snplist);
			$base =~ s/\.snplist//g;
			$cmd = "perl $Bin/LD_haploview.pl -snplist $snplist -od $od/haploview/$base -key $base -chrid $chrid  -minMAF $maf -minInt $int -maxdistance $window\n";
			print SH "$cmd";
			close SH;
			&qsub("$od/work_sh/haploview_ld.sh",$queue,$maxproc);	
		}
	}
	
}else{
	my $cmd = "";
	mkdir("$od/SNP",0755) unless -d "$od/SNP";
	mkdir("$od/work_sh",0755) unless -d "$od/work_sh";
	mkdir("$od/plink",0755) unless -d "$od/plink";
	$cmd = "cd $od/SNP && perl $Bin/vcf_to_snplist_v1.2.pl -i $vcf -o $key.snplist -ref 0 \n";
	print $cmd;
	`$cmd`;
	open SH,">$od/work_sh/ld_noref_plink.sh" or die $!;
	my $snplist = "$od/SNP/$key.snplist";
	$cmd = "perl $Bin/LD_noref_plink.pl -snplist $snplist -od $od/plink -key $key -minMAF $maf -minInt $int -ld_window_r2 $nor2\n";
	print SH "$cmd";
	close SH;
	`sh /share/nas2/genome/bmksoft/tool/qsub_sge_plus/v1.0/qsub_sge.plus.sh  --independent --queue $queue --maxproc $maxproc --reqsub $od/work_sh/ld_noref_plink.sh`;
}

my $Time_End;
$Time_End = &sub_format_datetime(localtime(time()));
print "\nEnd Time :[$Time_End]\n\n";

print "All done!!!\n";

#####sub
sub sub_format_datetime 
{
	my($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = @_;
	$wday = $yday = $isdst = 0;
	sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
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


 sub help{
 	print <<"	END";
 	------------------------------------------------------------------------
 	writer: wangyt
 	data:2018.8.31
 	Usage:
 		-vcf		variant call format file
 		-od 		output directory
 		-key		keyword
 		
 		-ref		<defined>
 		-group		group info
 		-chrid		chrid file
 		-chrlen         chrlen file
 		
 		-plink    	<defined>
 		-haploview	<defined>
 		
 		-maf		[0.05]
 		-int		[0.8]
 		-window		[1000 kb]
 		-r2		[0]
 		-nor2		[0.8]
 		-maxproc	[100]
 		-queue		[general.q]
 		
 	perl $Script -vcf Test.vcf -od LD -key Test -group group.txt -ref -chrid len1 -chrlen len2 -plink
	perl $Script -vcf marker.vcf -od noref -key marker -nor2 0.8 	
	------------------------------------------------------------------------ 		
	END
 	exit;	
 }



