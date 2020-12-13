#!/usr/bin/perl
use warnings;
use strict;
use File::Compare;
use File::Copy qw(move);
use autodie;

my $home         = $ENV{"HOME"};
my $local        = "$home/.local/";
my $bin          = "${local}bin/";
my $status       = "perl $bin/status.pl ";
my $sys          = "$bin/sys";
my $history_root = "$home/.cache/history/";

if (@ARGV) {
    my $command = $ARGV[0];
    if ( $command eq "mail" ) {
        exit if system("$sys online");
        my $mail_files = "/tmp/mail";
        if ( !-d $mail_files ) {
            mkdir $mail_files;
        }
        my $time = `date +%Y-%m-%d-%H-`;
        chomp $time;
        $time .= `date +%M` >= 30 ? "30" : "00";
        $mail_files = $mail_files . "/$time";

        unless ( system("pgrep -x mutt > /dev/null") ) {
            system("rm -f $mail_files");
            exit;
        }
        exit if -e "$mail_files";
        system("$sys mail");
        system("touch $mail_files");
    }
    elsif ( $command eq "notify" ) {
        system("perl ${bin}notify.pl");
    }
    elsif ( $command eq "cleanup" ) {
        my $cleanup_date = `date +%Y-%m-%d`;
        chomp $cleanup_date;
        my $cleanup_dir = "/tmp/cleanup/";
        if ( !-d $cleanup_dir ) {
            mkdir $cleanup_dir;
        }
        my $cleanup = $cleanup_dir . $cleanup_date;
        exit if -e $cleanup;
        for ( ( "undo", "swap", "backup" ) ) {
            my $vim_dir = "$home/.vim/$_/";
            if ( -d $vim_dir ) {
                system("find $vim_dir -type f -mtime +1 -exec rm {} \\;");
            }
        }
        my $history_dir = "$history_root$cleanup_date";
        system("mkdir -p $history_dir");
        system("rsync -ar $home/.mozilla/ $history_dir/mozilla");
        system("cp .bash_history $history_dir/bash_history");
        my $cnt = 0;
        for my $cleanup (`ls $history_root | sort -r`) {
            $cnt++;
            system("rm -rf $history_root$cleanup") if ( $cnt > 3 );
        }
        system("touch $cleanup");
    }
    elsif ( $command eq "backup" ) {
        system("source ~/.variables && perl ${bin}backup.pl | systemd-cat -t backup");
    }
    elsif ( $command eq "wiki" ) {
        my $wiki = "$home/.cache/wiki/";
        my $hash = "${wiki}hash";
        my $prev = $hash . ".prev";
        my $note = "$home/store/personal/notebook";
        system("mkdir -p $wiki");
        system("find $note -type f -exec md5sum {} \\; > $hash");
        if ( -e $prev ) {
            exit 0 if ( system("diff -u $prev $hash") == 0 );
        }
        system("mv $hash $prev");
        system("zim --export $note --output $wiki/notebook/ --overwrite --index-page index");
    }
    exit;
}

my $cnt = 1;
while (1) {
    $cnt++;
    if ( $cnt >= 5 ) {
        system("$status notify &");
        system("$status mail &");
        system("$status cleanup &");
        system("$status wiki &");
        system("$status backup &");
        $cnt = 0;
    }
    sleep 5;
}