#!/usr/bin/perl
use warnings;
use strict;
use File::Compare;
use File::Copy qw(move);
use autodie;

my $home         = $ENV{"HOME"};
my $local        = "$home/.local/";
my $bin          = "${local}bin/";
my $status       = "perl ${bin}status.pl ";
my $sys          = "$bin/sys";
my $history_root = "$home/.cache/history/";

if (@ARGV) {
    my $command = $ARGV[0];
    if ( $command eq "notify" ) {
        system("perl ${bin}notify.pl");
    }
    elsif ( $command eq "backlight" ) {
        my $classes = `ls /sys/class/backlight/ | wc -l` + 0;
        if ( $classes == 0 ) {
            exit 0;
        }
        my $pids  = system("pidof i3lock > /dev/null");
        my $light = `brightnessctl get` + 0;
        my $set   = "";
        if ( $light < 1500 ) {
            if ( $pids != 0 ) {
                $set = "50%";
            }
        }
        else {
            if ( $pids == 0 ) {
                $set = "5";
            }
        }
        if ($set) {
            system("brightnessctl set $set > /dev/null");
        }
    }
    elsif ( $command eq "regen" ) {
        my $rcache = "~/.cache/regen";
        my $curr   = "$rcache/current";
        my $prev   = "$curr.prev";
        my $menu   = "~/.fluxbox/usermenu";
        my $apps   = "~/.local/apps/enabled";
        system("mkdir -p $rcache") if !-d $rcache;
        system("ls $apps/*.app | sort > $curr");
        if ( -e $prev ) {
            if ( system("diff -u $prev $curr") == 0 ) {
                exit 0;
            }
        }
        system("echo [separator] > $menu");
        for my $app (`cat $curr | rev | cut -d '/' -f 1 | rev`) {
            chomp $app;
            if ( !$app ) {
                next;
            }
            my $name = `echo $app | cut -d '.' -f 1`;
            chomp $name;
            system("echo '[exec] ($name) {/bin/bash $apps/$app}' >> $menu");
        }
        system("echo [separator] >> $menu");
        system("mv $curr $prev");
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
        system("rsync -ar $home/.fluxbox/ $history_dir/fluxbox");
        system("cp .bash_history $history_dir/bash_history");
        my $cnt = 0;
        for my $cleanup (`ls $history_root | sort -r`) {
            $cnt++;
            system("rm -rf $history_root$cleanup") if ( $cnt > 3 );
        }
        system("touch $cleanup");
    }
    elsif ( $command eq "backup" ) {
        my $server = `source $home/.variables && echo \$SERVER`;
        chomp $server;
        my $tmp = "/tmp/backup/";
        mkdir $tmp if !-d $tmp;
        my $check = `date +%Y-%m-%d.%H`;
        chomp $check;
        $check = $tmp . $check;
        exit 0 if -e $check;

        my $target = "rsync://$server/backup";
        if ( system("rsync --list-only $target > /dev/null") == 0 ) {
            system(
"rsync -av /var/cache/voidedtech/backup/ rsync://$server/backup/"
            );
            system("rsync -av --delete-after rsync://$server/pull $home/.cache/wiki");
            system("touch $check");
        }
    }
    exit;
}

my $display = $ENV{"DISPLAY"};

my $cnt = 1;
while (1) {
    if ( !$display ) {
        sleep 5;
        next;
    }
    $cnt++;
    if ( $cnt % 15 == 0 ) {
        system("$status notify &");
    }
    if ( $cnt >= 30 ) {
        system("$status cleanup &");
        system("$status backup &");
        system("$status regen &");
        $cnt = 0;
    }
    system("$status backlight &");
    sleep 1;
}
