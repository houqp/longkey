#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use MP3::Tag;
use IO::File;
use File::Copy;
use File::Path qw(make_path);
use open ':encoding(utf8)';
use utf8;

sub unescape {
	my($str) = splice(@_);
	$str =~ s/%(..)/chr(hex($1))/eg;
	return $str;
}

sub sub_escape {
	my $str = shift;
	#$str =~ s/\ /\\\ /g;
	#$str =~ s/\ /_/g;
	$str =~ s/'/_/g;
	$str =~ s/\//_/g;
	#$str =~ s/\//\\\//g;
	#$str =~ s/\(/\\\(/g;
	#$str =~ s/\)/\\\)/g;
	return $str;
}

sub binslurp {
	my $file = shift;
	my $fh = IO::File->new("<$file") || die "$file: $!\n";
	local $/ = undef; # file slurp mode
	my $data = <$fh>;
	return $data
}

sub mime_type($) {
	my $filename = shift;
	my $mime_type;

	chomp $filename;
	$mime_type = 'image/jpeg' if $filename =~ /\.jpe?g$/i;
	$mime_type = 'image/png' if $filename =~ /\.png$/i;

	return $mime_type;
}

sub set_id3v2_tag {
# list of supprted frame for ID3v2
# http://search.cpan.org/~ilyaz/MP3-Tag-0.9708/ID3v2-Data.pod
#
# TALB: Album/Movie/Show title
# TPE1: Lead performer/Soloist
# TRCK: Track number
# TCOM: Composer
# TDAT: Date
# TENC: Encoded by
# TEXT: Lyricist/Text writer
# TIT2: Title/songname/content description
# TIT3: Subtitle/Description refinement
# TYER: Year
#
# Complex frames
# COMM: (Language, Description, Text)
# APIC: (MIME type, Picture Type, Description, _Data)
# USLT: Unsynchronised lyrics/text transcription
#       (Language, Description, Text)
# 
# Text encoding code for id3 tag
# $00 - ISO-8859-1 (ASCII).
# $01 - UCS-2 (UTF-16 encoded Unicode with BOM), in ID3v2.2 and ID3v2.3.
# $02 - UTF-16BE encoded Unicode without BOM, in ID3v2.4.
# $03 - UTF-8 encoded Unicode, in ID3v2.4.
# http://en.wikipedia.org/wiki/ID3
#
#
# All kinds of picture types
# Picture type:
#             $00  Other
#             $01  32x32 pixels 'file icon' (PNG only)
#             $02  Other file icon
#             $03  Cover (front)
#             $04  Cover (back)
#             $05  Leaflet page
#             $06  Media (e.g. label side of CD)
#             $07  Lead artist/lead performer/soloist
#             $08  Artist/performer
#             $09  Conductor
#             $0A  Band/Orchestra
#             $0B  Composer
#             $0C  Lyricist/text writer
#             $0D  Recording Location
#             $0E  During recording
#             $0F  During performance
#             $10  Movie/video screen capture
#             $11  A bright coloured fish
#             $12  Illustration
#             $13  Band/artist logotype
#             $14  Publisher/Studio logotype
	my $tag_info = shift;
	my $img = shift;
	my $path = shift;

	my $mp3 = MP3::Tag->new($path);
	my $id3v2 = $mp3->new_tag("ID3v2");
	$id3v2->add_frame("TIT2", $tag_info->{'title'});
	$id3v2->add_frame("TPE1", $tag_info->{'artist'});
	$id3v2->add_frame("TRCK", $tag_info->{'track'});
	$id3v2->add_frame("TALB", $tag_info->{'album'});
	$id3v2->add_frame("TSSE", "Longkey for Linux & Perl MP3-Tag module");
	$id3v2->add_frame("APIC",
		chr(0x03), # Text Encoding
		mime_type($img), # MIME Type
		chr(0x3), # Picture type
		"Cover Image", # Description
		binslurp($img) # Binary Data
	);
	$id3v2->write_tag;
	$mp3->close();
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
	$retry = 100;
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

# Xiami blocks wget user agents, so we fake one here.
my $user_agent = 'Mozilla/2112.0 (X11; Linux x86_64; rv:16.0) Gecko/20100101 Firefox/fuck.0';
#my $user_agent = 'Mozilla/5.0 (X11; Linux x86_64; rv:16.0) Gecko/20100101 Firefox/16.0';


foreach (@aid_arr) {
	my $aid = $_;
	my $url = "http://www.xiami.com//song/playlist/id/$aid/type/1";

	print "Getting song.xml\n";
	system("wget $url 2>/dev/null -O song.xml");
	open(xml, "song.xml");
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

	my %tag_info = (
		'artist' => $artist,
		'album' => $album,
	);
	$artist = sub_escape($artist);
	$album = sub_escape($album);
	my $coverfile = "$music/$artist/$album/cover.jpg";
	my $album_path = "$music/$artist/$album";
	make_path($album_path);

	my @s = stat($coverfile);
	if (!$s[7] || $s[7] < 1000) {
		system("wget -O '$coverfile' $picurl");
	}

	for (my $i = 0; $i < @titles; $i++) {
		$tag_info{'track'} = $i + 1;
		my $track = sub_escape($tag_info{'track'});
		$tag_info{'title'} = $titles[$i];
		my $title = sub_escape($tag_info{'title'});
		print "getting #$track - $title\n";

		my $loc = $locs[$i];
		my $path = "$album_path/$title.mp3";
		print "will be save to '$path'...\n";
		my @s = stat($path);
		if (!$s[7] || $s[7] < 1000) {
			my $count = 0;
			my $wget_command = "wget --user-agent='$user_agent' '$loc' --no-proxy -O '$path'";
			print $wget_command;
			while (system($wget_command) == 2048) {
				system("rm -rf $path");
				$count = $count + 1;
				if ($count > $retry) {
					last;
				}
				print "retrying!\n";
			}
			set_id3v2_tag(\%tag_info, $coverfile, $path);
		} else {
			print "skipped $path\n";
		}
	}

	move("song.xml", "$album_path/song.xml");
}
