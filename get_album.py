#!/usr/bin/env python
# -*- coding:utf-8 -*-

import requests
import argparse

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("artist_id", help="artist id", type=str)
    parser.add_argument("-d", help="debug mode", action='store_true')
    args = parser.parse_args()

    headers = {
        'User-Agent': 'WTF-1.0',
    }
    url = 'http://www.xiami.com/artist/album/id/'+args.artist_id
    r = requests.get(url, headers=headers)
    try:
        page_div = r.content.split('<div class="all_page">')[1]\
                    .split('</div>')[0]
        page_num = len(page_div.split('p_num')) - 1
    except IndexError:
        page_num = 1
    else:
        pass
    if args.d:
        print("Total number of pages: "+str(page_num))
    for i in range(page_num):
        if args.d:
            print "parsing page {0}".format(i+1)
        url = 'http://www.xiami.com/artist/album/id/{0}/d//p//page/{1}'.format(
            args.artist_id, str(i+1))
        r = requests.get(url, headers=headers)
        album_list = r.content.split("playalbum('")
        # remove useless header
        album_list.pop(0)
        # there is dulplicate in albums, so we divide it by 2
        for j in range(len(album_list)/2):
            aid = album_list[j][:album_list[j].find("'")]
            print aid
