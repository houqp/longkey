
longkey
=======

xiami music downloader for linux


Dependencies
------------

* perl
* wget
* mp3info2
* requests

For Debian:

```bash
apt-get install perl wget libmp3-tag-perl python-requests
```

For Gentoo:

```bash
emerge -av perl wget MP3-Tag requests
```

Usage
-----

To download a single album http://www.xiami.com/album/169898:

```bash
perl xiami.pl -aid 169898 -path /music/path
```

To download multiple ablums at one shot, you can put all the album number in a file, one at a line, then issue:

```bash
perl xiami.pl -afile ALBUM_LIST -path /music/path
```

You can also use `-retry 10` to set retry times to 10, the default value is 20.

`get_album.py` can help you parse all the albums of a singer, so you can download albums in batch:

```bash
python get_album.py 216 > ALBUM_LIST
```


Thanks
------
original longkey project: http://code.google.com/p/longkey

mp3sync: http://www.sukria.net/code/mp3sync.html
