#!/usr/bin/env perl

use strict;
use strict;
use Cwd qw(abs_path);
use Getopt::Long;
use File::Basename qw(basename dirname);
use FindBin qw($Bin $Script);
use Cwd qw(abs_path);

#force parameter
my ($vcf,$group,$key,$od);

#chrlen and chrid
my($chrlen,$chrid);

#select sweep
my ($anno,$gff);
my ($win,$step,$type);

#LD
my ($plink,$haploview,$maxdistance,$noref);

#admixture
my ($mink,$maxk);

#tree
my ($k2p,$pdis);

#kinship
my ($kinship,$posnum);

#evolution
my ($tree,$ld,$pca,$select,$admixture);

my ($minMAF,$minInt);
my ($queue,$maxproc);

#web_report
my ($cfg,$RESEQ,$SLAF,$NOSLAF);

################################################################################
GetOptions(
	"help|?"	=> \&help,
	'vcf:s'		=> \$vcf,
	'group:s'	=> \$group,
	'key:s'		=> \$key,
	'od:s'		=> \$od,
	'chrlen:s'	=> \$chrlen,
	'chrid:s'	=> \$chrid,
	
	'anno:s'	=> \$anno,
	'gff:s'		=> \$gff,
	'window:i'	=> \$win,
	'step:i'	=> \$step,
	'type:s'	=> \$type,
	
	'plink:s'	=> \$plink,
	'haploview:s'	=> \$haploview,
	'noref:s'	=> \$noref,
	'maxdistance:i' => \$maxdistance,
	
	'mink:i'	=> \$mink,
	'maxk:i'	=> \$maxk,
	
	'k2p:s'		=> \$k2p,
	'pdis:s'	=> \$pdis,
	
	'kinship:s'	=> \$kinship,
	'posnum:i'	=> \$posnum,
	
	'queue:s'	=> \$queue,
	'maxproc:i'	=> \$maxproc,
	'minMAF:f'	=> \$minMAF,
	'minInt:f'	=> \$minInt,
	
	'ld:s'		=> \$ld,
	'pca:s'		=> \$pca,
	'tree:s'	=> \$tree,
	'admixture:s'	=> \$admixture,
	'select:s'	=> \$select,
	
	'cfg:s'		=> \$cfg,
	'RESEQ:s'	=> \$RESEQ,
	'SLAF:s'	=> \$SLAF,
	'NOSLAF:s'	=> \$NOSLAF,
	
) || &help;

&help unless ($vcf and $group and $key and $od);

die "Please provide the chrlen and chrid if you select -select!\n" if (defined $select and !defined $chrlen and !defined $chrid);
die "Please provide the gff if you select -anno!\n" if (defined $anno and !defined $gff);
die "Please at least select one of k2p or pdis if you select -tree!\n" if (defined $tree and !defined $k2p and !defined $pdis);
die "Please at least select one of plink or haploview if you select -ld!\n" if(defined $ld and !defined $plink and !defined $haploview and !defined $noref);

################################################################################
$minMAF ||= 0.05;
$minInt ||= 0.5;
$win ||= 100;
$step ||= 10;
$mink ||= 1;
$maxk ||= 10;
$posnum ||= 2000;
$maxdistance ||= 1000;
$type ||= "gene";

$vcf = abs_path($vcf) if defined $vcf;
$group = abs_path($group) if defined $group;
mkdir($od,0755) unless -d $od;
$od = abs_path($od);

$chrlen	= abs_path($chrlen) if defined $chrlen;
$chrid = abs_path($chrid) if defined $chrid;
$gff = abs_path($gff) if defined $gff;
$anno = abs_path($anno) if defined $anno;
$cfg = abs_path($cfg) if defined $cfg;

######################################################genotype file
mkdir("$od/genotype",0755) unless -d "$od/genotype";
my $cmd;
if(!-e "$od/genotype/$key.recode.vcf"){
	$cmd = "$Bin/software/vcftools --vcf $vcf --maf $minMAF --max-missing $minInt --min-alleles 2 --max-alleles 2 --recode --out $od/genotype/$key\n";
	#生成genotype/$key.recode.vcf
	&run_or_die($cmd);
}
if(!-e "$od/genotype/$key.snplist"){
	$cmd = "perl $Bin/genotype/vcf_to_snplist_v1.2.pl -i $od/genotype/$key.recode.vcf -o $od/genotype/$key.snplist -ref 0";
	#根据genotype/$key.recode.vcf生成genotype/$key.snplist -ref
	&run_or_die($cmd);
}

mkdir("$od/Work_sh",0755) unless -d "$od/Work_sh";
#####################################################tree
$cmd = "";
if(defined $tree){
	mkdir("$od/tree",0755) unless -d "$od/tree";
	$cmd = "perl $Bin/genotype/snp2xxx.pl -snplist $od/genotype/$key.snplist -od $od/tree -key $key -minMAF $minMAF -minInt $minInt -mega";
	&run_or_die($cmd);
	$cmd = "";
	if(defined $k2p){
		$cmd .= "$Bin/tree/megacc -a $Bin/tree/infer_NJ_nucleotide_K2P.mao -d $od/tree/mega/$key.meg -o $od/tree/$key\_k2p \n";
	}
	if(defined $pdis){
		$cmd .= "$Bin/tree/megacc -a $Bin/tree/infer_NJ_nucleotide_pdistance.mao -d $od/tree/mega/$key.meg -o $od/tree/$key\_pdist \n";
	}
}

#####################################################pca
if(defined $pca){
	mkdir("$od/pca",0755) unless -d "$od/pca";
	$cmd .= "perl $Bin/PCA/v1.0/PCA_analysis_v1.0.pl -vcf $od/genotype/$key.recode.vcf -group $group -od $od/pca -key $key -maf $minMAF -int $minInt\n";
	#生成PCA
}

#####################################################ld
if(defined $ld){
	mkdir("$od/ld",0755) unless -d "$od/ld";
	my $num = `cut -f 4 $group |sed '1d'|sort|uniq|wc -l`;chomp $num;
	if(defined $noref){
		$cmd .= "perl $Bin/LD/v1.0/LD_analysis_v1.0.pl -vcf $od/genotype/$key.recode.vcf -od $od/ld -key $key -nor2 0.8 -maf $minMAF -int $minInt\n";
	}elsif($num == 1){
		if(defined $plink){
			$cmd .= "perl $Bin/LD/v1.0/LD_analysis_v1.0.pl -vcf $od/genotype/$key.recode.vcf -od $od/ld -key $key -ref -chrid $chrid -chrlen $chrlen -plink -maf $minMAF -int $minInt -window $maxdistance\n";
		}
		if(defined $haploview){
			$cmd .= "perl $Bin/LD/v1.0/LD_analysis_v1.0.pl -vcf $od/genotype/$key.recode.vcf -od $od/ld -key $key -ref -chrid $chrid -chrlen $chrlen -haploview -maf $minMAF -int $minInt -window $maxdistance\n";
		}
	}else{
		if(defined $plink){
			$cmd .= "perl $Bin/LD/v1.0/LD_analysis_v1.0.pl -vcf $od/genotype/$key.recode.vcf -od $od/ld -key $key -group $group -ref -chrid $chrid -chrlen $chrlen -plink -maf $minMAF -int $minInt -window $maxdistance\n";
		}
		if(defined $haploview){
			$cmd .= "perl $Bin/LD/v1.0/LD_analysis_v1.0.pl -vcf $od/genotype/$key.recode.vcf -od $od/ld -key $key -group $group -ref -chrid $chrid -chrlen $chrlen -haploview -maf $minMAF -int $minInt -window $maxdistance\n";
		}		
	}
}

#######################################################admixture
if(defined $admixture){
	mkdir("$od/admixture",0755) unless -d "$od/admixture";
	$cmd .= "perl $Bin/admixture/v1.0/Runadmixture.pl -snplist $od/genotype/$key.snplist -od $od/admixture -key $key -minMAF $minMAF -minInt $minInt -minK $mink -maxK $maxk\n"
}

#######################################################kinship
if(defined $kinship){
	mkdir("$od/kinship",0755) unless -d "$od/kinship";
	$cmd .= "perl $Bin/kinship/Runkinship.pl -snplist $od/genotype/$key.snplist -od $od/kinship -key $key -minMAF $minMAF -minInt $minInt -posnum $posnum\n";
}

######################################################select
if(defined $select){
	mkdir ("$od/popgenome",0755) unless -d "$od/popgenome"; 
	if(defined $anno){
		$cmd .= "perl $Bin/PopGenome/v2.0.1/bin/select_sweep.pl -vcf $od/genotype/$key.recode.vcf -key $key -reflen1 $chrlen -reflen2 $chrid -od $od/popgenome -info $group -global 1 -minInt $minInt -minMAF $minMAF -type 2 -win $win -step $step -gff $gff -anno $anno -atype $type \n";
	}else{
		$cmd .= "perl $Bin/PopGenome/v2.0.1/bin/select_sweep.pl -vcf $od/genotype/$key.recode.vcf -key $key -reflen1 $chrlen -reflen2 $chrid -od $od/popgenome -info $group -global 1 -minInt $minInt -minMAF $minMAF -type 2 -win $win -step $step -atype $type\n";
	}
}

open SH,">$od/Work_sh/pop.sh" or die $!;
print SH "$cmd\n";
close SH;
&qsub("$od/Work_sh/pop.sh",$queue,$maxproc);

#########################################################deal with tree
if(defined $tree){
	if(defined $k2p){
		&adjusttree("$od/tree/$key\_k2p.nwk");
	}
	if(defined $pdis){
		&adjusttree("$od/tree/$key\_pdis.nwk");
	}
}

########################################################## extract the result
$cmd = "";
$cmd = "perl $Bin/tools/Extract_result_v1.1.pl -id $od/ -k $key -group $group\n";
&run_or_die($cmd);

########################################################## web_report
if(defined $RESEQ){
	die "Please provide the config of reseq!\n" if !-e $cfg;
	print "****************Generate Reseq Evolution Web Report:**********************************\n";
	$cmd = "/share/nas2/genome/biosoft/Python/2.7.8/bin/python $Bin/web_rep/reseq_evolution/v1.1/reseq_evo_xml.py -i $cfg -e $od -k $key\n";	
	&run_or_die($cmd);
	print "Finished !!!\n";
}

if(defined $SLAF){
	die "Please provide the config of slaf!\n" if !-e $cfg;
	print "****************Generate Haplotype Evolution Web Report:**********************************\n";
	$cmd = "/share/nas2/genome/biosoft/Python/2.7.8/bin/python $Bin/web_rep/haplotype_evolution/v1.1/haplotype_evo_xml_report.py -i $cfg -evo $od -key $key\n";
	&run_or_die($cmd);
	print "Finished !!!\n";
}

if(defined $NOSLAF){
	die "Please provide the config of no slaf!\n" if !-e $cfg;
	print "****************Generate Polymap Evolution Web Report:**********************************\n";
	$cmd = "/share/nas2/genome/biosoft/Python/2.7.8/bin/python $Bin/web_rep/polymap_evolution/v1.0/polymap_xml_evo_report.py -i $cfg -evo $od -key $key\n";
	&run_or_die($cmd);
	print "Finished !!!\n";
}


################################################################################
sub sub_format_datetime #Time calculation subroutine
{
        my($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = @_;
        $wday = $yday = $isdst = 0;
        sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}

sub run_or_die()
{
        my ($cmd) = @_ ;
        &show_log($cmd); #2018-12-11 16:45:00:    /share/nas1/wangyt/script/SVN/Population/population/software/vcftools --vcf
        my $flag = system($cmd) ;
        if ($flag != 0){ #$cmd执行成功则返回0
                &show_log("Error: command fail: $cmd");
                exit(1);
        }
        &show_log("done."); #2018-12-11 16:56:22:    done.
        return ;
}

sub show_log()
{
        my ($txt) = @_ ;
        my $time = time();
        my $Time = &sub_format_datetime(localtime($time));
        print "$Time:\t$txt\n" ;  #2018-12-11 16:56:22:    done.
        return ($time) ;
}

sub adjusttree()
{
	my $tree = shift;
	open IN,$tree or die $!;
	my $dir = dirname($tree);
	my $base = basename($tree);
	$base =~ s/\.nwk/.motif.nwk/;
	open OUT,">$dir/$base" or die $!;
	while(<IN>){
		chomp;
		next if /^$/;
		s/(\))([0-9.]+):/$1.sprintf("%.f:",$2*100)/eg;
		print OUT $_;
	}
	close IN;
	close OUT;
}


sub qsub()
{
        my ($shfile, $queue, $ass_maxproc) = @_ ;
        if (`hostname` =~ /cluster/){
                my $cmd = "sh /share/nas2/genome/bmksoft/tool/qsub_sge_plus/v1.0/qsub_sge.plus.sh $shfile --maxproc $ass_maxproc --queue $queue --resource vf=30G --independent --reqsub" ;
                &run_or_die($cmd);
        }
        else{
                my $cmd = "sh /share/nas2/genome/bmksoft/tool/qsub_sge_plus/v1.0/qsub_sge.plus.sh $shfile --maxproc $ass_maxproc --queue $queue --resource vf=30G --independent --reqsub" ;
                &run_or_die($cmd);
        }
}


sub help
{
	print <<"	Usage End.";
	------------------------------------------------------------------------
	Usage:
	
	-vcf		variant call format	<file>		must be given
	-group		group info file		<file>		must be given
	-key		keyword			<str>		must be given
	-od		output directory	<outdir>	must be given
	
	-chrlen		chrom length file	<file>		optional
	-chrid		chrid file		<file>		optional
	
	-tree
	    -k2p	kimura 2-parameters	<defined>	optional
	    -pdis	pdistance 		<defined>	optional
		
	-pca		run PCA by eigensoft::smartpca
	
	-ld
	    -plink	run LD use plink	<defined>	optional
	    -haploview	run LD use haploview	<defined>	optional
	    -maxdistance	LD window	<1000kb>	optional
	    -noslaf				<defined>	optional
		
	-select
	    -win	window			<100kb>		optional
	    -step	step			<10kb>		optional
	    -anno	do anno for region	<defined>	optional
	    -gff	gff file		<file>		optional
	    -type	gene/mRNA	 	<gene>		optional		
	
	-kinship
	    -posnum	site loci		<2000>		optional
		
	-admixture
	    -mink	min K  			<1>		optional
	    -maxk	max K			<10>		optional
	
	-minMAF					0.05
	-minInt					0.5

	########################################################################
	-cfg		the config file for generate webreport
	   -RESEQ
	   -SLAF
	   -NOSLAF
	------------------------------------------------------------------------   
		
	Usage End.
	exit;	
}

