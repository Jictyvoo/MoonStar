#!/bin/bash
cd src/
allFilenames=""
function loop() { 
    for i in "$1"/*
    do
        if [ -d "$i" ]; then
            loop "$i"
        elif [ -e "$i" ]; then
            if [[ "$i" != "./main.lua" && "$i" != "./main.lua.c" ]]; then
                # echo "Found $i"
                allFilenames="$allFilenames $i"
            fi
        else
            echo "$i"" - Folder Empty"
        fi
    done
}

loop "."
allFilenames="${allFilenames//'./'/''}"
luastatic "main.lua" $allFilenames /usr/lib/x86_64-linux-gnu/liblua5.3.a -I/usr/include/lua5.3
mv main ../
# echo $allFilenames
