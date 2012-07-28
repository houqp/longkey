
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

To download album http://www.xiami.com/album/169898:

```perl
perl xiami.pl -aid 169898 -path /music/path
```



