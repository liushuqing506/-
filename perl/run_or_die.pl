#! /usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Cwd qw(abs_path);
use File::Basename qw(dirname basename);
use Data::Dumper;
use FindBin qw($Bin $Script);


my $cmd="perl 2.pl";

&run_or_die($cmd);
        
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
        print "$Time:\t$txt\n" ;  #2018-12-11 16:56:22:    done.
        #return ($time) ;
}


sub sub_format_datetime #Time calculation subroutine
{
        my($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = @_;
        $wday = $yday = $isdst = 0;
        sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}
