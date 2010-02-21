#!/bin/bash
#
#   Copyright 2010, Mate Ory <orymate@ubuntu.com>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.

if ! date -R >/dev/null
then
    echo date -R needed
    exit 3
fi

if [ ! -r "$1" ]
then
    echo Use: $0 'current-version.html [ output.xml [ http://base-uri ]]'
    exit 1;
fi
source rssgen.conf 2>/dev/null
if [ "x$BASE" = x -a "x$3" = x ]
then
        echo set '$3' or export '$BASE' or set '$BASE' in ./rssgen.conf
        exit 1
else
    if [ ! "x$3" = x ]
    then
        BASE="$3"
    fi
fi


mkdir -p .old || exit 2
if [ ! -r ".old/$1" ]
then
    touch ".old/$1" 
fi

OUT="$2"
if [ "x$OUT" = x ]
then
    OUT=output.xml
fi

if [ ! -r "$OUT" ]
then
    cat > "$OUT" <<EOTPL
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>HOME PAGE TITLE</title>
    <link>$BASE</link>
    <description></description>
    <language>en-us</language>
    <lastBuildDate>$(date -R)</lastBuildDate>
    <generator>rssgen.sh</generator>
    <!-- NEW ITEM HERE (do not remove) -->
  </channel>
</rss> 
EOTPL
    ${VISUAL:-vi} "$OUT"
fi

TMP=/tmp/rssgen.$RANDOM.html
touch $TMP || exit 2
touch $TMP.2 || exit 2

echo "# Give header and html description of new item" > $TMP
echo "Title: " >> $TMP
echo "Link: $BASE" >> $TMP
echo >> $TMP
diff -u ".old/$1" "$1" | grep '^+' | sed 's/^+//' >> $TMP
${VISUAL:-vi} "$TMP"

cp "$1" ".old/$1"
TITLE="$(sed -n -e '/^Title:/ p' $TMP|head -1)"
URI="$(sed -n -e '/^Link:/ p' $TMP|head -1)"

echo -n > $TMP.2
(
sed -n -e '1,/NEW ITEM HERE/ p' "$OUT"
echo '<item>'
echo ' <title>'$TITLE'</title>'
echo ' <link>'$URI'</link>'
echo ' <description><![CDATA['
sed -e '1,/^$/ d' $TMP
echo ' ]]></description>'
echo ' <guid>'$RANDOM$(date -R)'</guid>'
echo " <pubDate>$(date -R)</pubDate>"
echo '</item>'
sed -e '1,/NEW ITEM HERE/ d' "$OUT"
) >> $TMP.2
cp $TMP.2 "$OUT"

rm $TMP
rm $TMP.2
