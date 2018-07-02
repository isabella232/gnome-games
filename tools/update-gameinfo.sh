#!/bin/bash

TMP_GAMEINFO_DOC='gameinfo/out/playstation.gameinfo.xml.in.tmp'
GAMEINFO_DOC='../plugins/playstation/data/playstation.gameinfo.xml.in'

gameinfo/psxdatacenter-gameinfo.py
# Sort the existing document before merging the already sorted newly generated
# one into it. This avoids inconsistencies in case the sorting function got
# updated.
gameinfo/sort.py $GAMEINFO_DOC
gameinfo/merge.py $TMP_GAMEINFO_DOC $GAMEINFO_DOC $GAMEINFO_DOC
