#!/bin/bash
#
# inspired by https://stackoverflow.com/questions/8523159/how-do-i-move-a-relative-symbolic-link#8523293
#          by Christopher Neylan

help() {
   echo 'usage: mv_ln src_ln dest_dir'
   echo '       mv_ln --help'
   echo
   echo '  Move the symbolic link src_ln into dest_dir while'
   echo '  keeping it relative'
   exit 1
}

[ "$1" == "--help" ] || [ ! -L "$1" ] || [ ! -d "$2" ] && help

set -e # exit on error

orig_link="$1"
orig_name=$( basename    "$orig_link" )
orig_dest=$( readlink -f "$orig_link" )
dest_dir="$2"

ln -r -s "$orig_dest" "$dest_dir/$orig_name"
rm "$orig_link"
