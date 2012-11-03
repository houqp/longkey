#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

sub unescape {
	my($str) = splice(@_);
	$str =~ s/%(..)/chr(hex($1))/eg;
	return $str;
}

sub sub_escape {
	my $str = shift;
	$str =~ s/\ /_/g;
	$str =~ s/'/_/g;
	return $str;
}

sub locdecode {
	my $loc = shift;
	my $n = int(substr($loc, 0, 1));
	my $left = substr($loc, 1);
	my $slen = int(length($left) / $n);
	my $scnt = length($left) % $n;
	my @arr;
	#print "orig: $loc\n";
	#print "n: $n\n";
	#print "slen: $slen\n";
	foreach (0 ... $scnt-1) {
		push(@arr, substr($left, ($slen+1)*$_, $slen+1));
	}
	foreach ($scnt ... $n-1) {
		push(@arr, substr($left, $slen*($_-$scnt)+($slen+1)*$scnt, $slen));
	}
	#print "arr:\n";
	#print join("\n", @arr);
	#print "\n";
	my $r1 = "";
	foreach my $i (0 ... length($arr[0])-1) {
		foreach my $j (0 ... @arr-1) {
			$r1 .= substr($arr[$j], $i, 1);
		}
	}
	#print "before escape:$r1\n";
	$r1 = unescape($r1);
	$r1 =~ tr/^+/0 /;
	$r1;
}

my $aid;
my $afile;
my $music;
my $retry;

GetOptions(
	'aid:s' => \$aid,
	'afile:s' => \$afile,
	'path:s' => \$music,
	'retry:s' => \$retry
);

die if ((!$afile && !$aid) || !$music);

# retry default to 20
if (!$retry) {
	$retry = 20;
}

my @aid_arr;
if ($aid) {
	push(@aid_arr, $aid);
}
if ($afile) {
	open my $info, $afile or die "Could not open $afile: $!";
	while (my $aid = <$info>) {
		#escape '\n'
		$aid =~ s/\n//g;
		push(@aid_arr, $aid);
	}
}

print "aid array = @aid_arr\n";
print "path = $music\n";
print "retry = $retry\n";

foreach (@aid_arr) {
	my $aid = $_;
	my $url = "http://www.xiami.com//song/playlist/id/$aid/type/1";

	print "Getting song.xml\n";
	system("wget $url 2>/dev/null -O song.xml");
	open(xml, "wget $url 2>/dev/null -O -|");
	my @titles;
	my @locs;
	my $album;
	my $artist;
	my $picurl;
	while (<xml>) {
		push (@titles, $1) if /^<title>/ && /\[([^\[\]]+)\]/;
		push (@locs, &locdecode($1)) if m|^<location>(.*)</location>$|;
		$album = $1 if /^<album_name>/ && /\[([^\[\]]+)\]/;
		#$artist = $1 if m|^<artist>(.*)</artist>$|;
		$artist = $1 if /^<artist>/ && /\[([^\[\]]+)\]/;
		$picurl = $1 if m|^<pic>(.*)</pic>$|;
	}

	print "$album - $artist\n";
	print join("\n", @titles);
	print "\n";

	my $coverfile = "$music/$artist/$album/cover.jpg";
	system("mkdir -p '$music'") if (! -e "$music");
	system("mkdir -p '$music/$artist/'") if (! -e "$music/$artist");
	system("mkdir -p '$music/$artist/$album'") if (! -e "$music/$artist/$album");
	system("wget -O '$coverfile' $picurl");
	system("echo '$aid' > '$music/$artist/$album/aid'");

	for (my $i = 0; $i < @titles; $i++) {
		my $track = $i + 1;
		my $title = sub_escape($titles[$i]);
		my $loc = $locs[$i];
		my $path = "$music/$artist/$album/$title.mp3";
		print "getting #$track - $title\n";
		my @s = stat($path);
		if (!$s[7] || $s[7] < 1000) {
			my $count = 0;
			while (system("wget $loc --no-proxy -O '$path'") == 2048) {
				$count = $count + 1;
				if ($count > $retry) {
					last;
				}
				print "retrying!\n";
			}
			system("mp3info2 -a '$artist' -t '$title' -l '$album' -n $track '$path'");
		} else {
			print "skipped $path\n";
			system("mp3info2 -F \"APIC < '$coverfile'\" '$path'");
		}
	}
}
