#!/bin/sh
# Extract the list of games supported by MAME
# $1: path to the MAME repository
# $2: file name of the produced game database

simple=' *[^,]+ *'
simpleg=' *([^,]+) *'
quoted=' *" *(.*?) *" *'
pattern="$simple,$simpleg,$simple,$simple,$simple,($simple,)?$simple,$simple,$quoted,$quoted,${simple}(${simple})?(,${simple})?"
regex="^GAMEL?\(${pattern}\) *(//.*)?$"

cat `find $1/src/mame/drivers -name "*.cpp" | sort` | egrep "^GAMEL?\(.*\)$" | sed -E "s|$regex|\1 \4|g" | sed -E 's/^([^ ]+) +(.+)$/\1 \2/g' | sort > $2
