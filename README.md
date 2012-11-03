
longkey
=======

xiami music downloader for linux


Dependencies
------------

* perl
* wget
* mp3info2

For Debian:

```bash
apt-get install perl wget libmp3-tag-perl
```

For Gentoo:

```bash
emerge -av perl wget MP3-Tag
```

Usage
-----

To download a single album http://www.xiami.com/album/169898:

```bash
perl xiami.pl -aid 169898 -path /music/path
```

To download multiple ablums at one shot, you can put all the album number in a file, one at a line, then issue:

```bash
perl xiami.pl -afile YOUR_FILE -path /music/path
```

You can also use `-retry 10` to set retry times to 10, the default value is 20.



