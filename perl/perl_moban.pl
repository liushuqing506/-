#!/usr/bin/perl -w

use strict;
use Cwd qw(abs_path);
use Getopt::Long;
use Data::Dumper;
use File::Basename qw(basename dirname);
use FindBin qw($Bin $Script);

my $programe_dir=basename($0);
my $path=dirname($0);

my $ver    = "1.0";
my $Writer = "tangj <tangj\@biomarker.com.cn>";
my $Data   = "2014/12/09";
my $BEGIN=time();
#######################################################################################

# ------------------------------------------------------------------
# GetOptions
# ------------------------------------------------------------------
my ($in,$out,);
GetOptions(
                        "h|?" =>\&help,
                        "o:s"=>\$out,
                        "i:s"=>\$in,
                        
                        ) || &help;
&help unless ($out || $in);
$in=abs_path($in);
$out=abs_path($out);


my $cmd = "perl $Bin/fa_len_ATGC.pl -i $in -o $out";
&run_or_die($cmd);

sub show_log()
{
        my ($txt) = @_ ;
        #my $time = time();
        #my $Time = &sub_format_datetime(localtime($time));
        print "$txt\n";
        #return ($time) ;
}

sub run_or_die()
{
        my ($cmd) = @_ ;
        &show_log($cmd);
        my $flag = system($cmd) ;
        #print "$flag";
        if ($flag != 0){
                &show_log("Error: command fail: $cmd");
                exit(1);
        }
        &show_log("done.");
        return ;
}

sub help
{
        print "
    Description:
        Writer  : $Writer
        Data    : $Data
        Version : $ver
        function: ......
    Usage:
        -i      <file>    must be given
        -o      <dir>    must be given
         
        -h          Help document
        ";
}
