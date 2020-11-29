#!/usr/bin/perl
use strict;
use warnings;
use Sys::Hostname;

sub muted {
    return system("ponymix is-muted") == 0;
}

sub current {
    return 0 if muted;
    my $volume = `ponymix get-volume`;
    chomp $volume;
    return $volume;
}

sub setvol {
    my $vol = shift @ARGV;
    system("ponymix set-volume $vol");
}

my $host       = hostname;
my $controlled = 1;
if ( $ENV{"IS_DESKTOP"} ) {
    $controlled = 0;
}

my $cmd = "status";
if (@ARGV) {
    $cmd = shift @ARGV;
}

if ( $cmd eq "status" ) {
    print current;
    exit 0;
}
elsif ( $cmd eq "reset" ) {
    if ( $controlled == 0 ) {
        exit 0;
    }
    my $objects = `ponymix list`;
    my @parts   = split( "\n", $objects );
    my $last    = "";
    my $sink    = 0;
    for my $obj (@parts) {
        if ( $obj =~ s/^source [0-9]+: //g ) {
            $last = $obj;
            $sink = 0;
            next;
        }
        elsif ( $obj =~ s/^sink [0-9]+: //g ) {
            $last = $obj;
            $sink = 1;
            next;
        }
        if ($last) {
            my $command = "-t";
            if ($sink) {
                $command = "$command sink";
            }
            else {
                $command = "$command source";
            }
            $command = "$command -d $last";
            my $action = "";
            if ($sink) {
                $action = "mute";
            }
            else {
                if ( $obj =~ /Built-in Audio Analog Stereo/ ) {
                    $action = "set-volume 100";
                }
                else {
                    $action = "mute";
                }
            }
            $command = "$command $action";
            system("ponymix $command > /dev/null");
        }
        $last = "";
    }
}
elsif ( $cmd eq "mute" or $cmd eq "togglemute" ) {
    my $action = "mute";
    if ( $cmd eq "togglemute" ) {
        $action = "toggle";
    }
    system("ponymix $action");
}
elsif ( $cmd eq "inc" or $cmd eq "dec" ) {
    if ( $controlled == 0 ) {
        exit 0;
    }
    my $cur = current;
    if ( $cmd eq "inc" ) {
        if ( $cur >= 100 ) {
            exit 0;
        }
        $cur = $cur + 10;
    }
    else {
        if ( $cur <= 0 ) {
            exit 0;
        }
        $cur = $cur - 10;
    }
    system("ponymix set-volume $cur > /dev/null");
}
