#!/usr/bin/env python
# -*- coding:utf-8 -*-

from xml.dom import minidom
import requests


def get_xml_node_value_by_tag(xmldoc, tag):
    return xmldoc.getElementsByTagName(tag)[0].firstChild.nodeValue


def http_get_content(url):
    return requests.get(url, headers={'User-Agent': 'WFT-1.0'}).content


def get_song_xml(sid):
    url = ('http://www.xiami.com/song/playlist'
           '/id/{0}'
           '/object_name/default'
           '/object_id/0').format(sid)
    return http_get_content(url)


def get_song_metadata(sid):
    xml = get_song_xml(sid)
    xmldoc = minidom.parseString(xml)
    return {
        'artist': get_xml_node_value_by_tag(xmldoc, 'artist'),
        'title': get_xml_node_value_by_tag(xmldoc, 'title'),
        'album_name': get_xml_node_value_by_tag(xmldoc, 'album_name'),
        'lyric_rul': get_xml_node_value_by_tag(xmldoc, 'lyric'),
        'location': get_xml_node_value_by_tag(xmldoc, 'location'),
    }


def get_album_metadata(aid):
    pass


if __name__ == "__main__":
    print get_song_metadata(185694)
