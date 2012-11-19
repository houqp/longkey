#!/usr/bin/env python
# -*- coding:utf-8 -*-

import requests
import sys
import argparse

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("artist_id", help="artist id", type = str)
    args = parser.parse_args()

    r = requests.get('http://www.xiami.com/artist/album/id/'+args.artist_id)
    page_div = r.content.split('<div class="all_page">')[1].split('</div>')[0]
    page_num = len(page_div.split('p_num')) - 1
    #print("Total number of pages: "+str(page_num))
    for i in range(page_num):
        #print("parsing page: "+str(i+1))
        r = requests.get('http://www.xiami.com/artist/album/id/216/d//p//page/'+str(i+1))
        album_list = r.content.split("playalbum('")
        # remove useless header
        album_list.pop(0)
        # there is dulplicate in albums, so we divide it by 2
        for j in range(len(album_list)/2):
            aid = album_list[j][:album_list[j].find("'")]
            print aid

        
