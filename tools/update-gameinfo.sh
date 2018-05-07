#!/bin/bash

TMP_GAMEINFO_DOC='gameinfo/out/playstation.gameinfo.xml.in.tmp'
GAMEINFO_DOC='../plugins/playstation/data/playstation.gameinfo.xml.in'

gameinfo/psxdatacenter-gameinfo.py
gameinfo/sort.py $GAMEINFO_DOC
gameinfo/merge.py $TMP_GAMEINFO_DOC $GAMEINFO_DOC $GAMEINFO_DOC
