#!usr/bin/perl -w
use strict;
use Getopt::Long;
use autodie;

my ($infile,$outfile);
GetOptions(
     #                                                   "help|?" =>\&USAGE,
						                                "i:s"=>\$infile,
						                                "o:s"=>\$outfile,
 );

my $sam=`cut -f 3 $infile`;
my @sam=split /\n/,$sam;
my $num_all=@sam;

my $header=`head -n 1 $infile`;
my @sample=split /\t/,$header;


my %hash;
for my $i(3..$#sample+1){
    my $tmp_str=`cut -f $i $infile`;
	my @tmp=split /\n/,$tmp_str;
	#print "@tmp\n";
	my $sample_name=shift @tmp;
	$hash{$sample_name}=[@tmp];
}

##统计
my @samples=keys %hash;
my @ash2;
push @ash2,"\t\t@samples\n";
for my $i(0..$#samples){
	push @ash2,$samples[$i];
	for my $k(0..$#samples){
		my @ll=$hash{$samples[$k]};
		my $num = &compare(\@{$hash{$samples[$i]}},\@{$hash{$samples[$k]}});
		push @ash2,$num;
	}
	push @ash2,"\n";
}

my $trans = join "\t", @ash2;
print $trans;


sub compare(){
	my ($arr1,$arr2)=@_;
	my $count =0;
	for my $i(0..$num_all-2){
		if ($arr1->[$i] ne $arr2->[$i]){
			$count++;
		}
	}
	return $count;
}
