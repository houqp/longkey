#!/usr/bin/env python
# -*- coding:utf-8 -*-

import sys
from libxiami import get_artist_id


if __name__ == "__main__":
    if not len(sys.argv) != 1:
        print "usage: {0} keyword".format(sys.argv[0])
        sys.exit(0)

    kw = sys.argv[1]
    print "searching {0}...".format(kw)
    for ar in get_artist_id(kw):
        print "[{0:>10}]\t {1}".format(ar['id'], ar['name'])
