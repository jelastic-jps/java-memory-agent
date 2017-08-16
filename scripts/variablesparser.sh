#!/bin/bash
CONFFILE="${JAVA_OPTS_CONFFILE}"
confresult=""

if [ -f "$CONFFILE" ]; then
    confdata=$(sed '/^#/d' $CONFFILE | awk -F# '{print $1}' | sed 's/\s/\n/g')
    for i in $confdata
    do
        if $(echo $i | grep -q '#'); then continue; fi
        if $(grep -qiE '\-Xmx[[:digit:]]{1,}[mgkMGK]$' <<< $i); then XMX="${i}";
        elif $(grep -qiE '\-Xms[[:digit:]]{1,}[mgkMGK]$' <<< $i); then XMS="${i}";
        elif $(grep -qiE '\-Xmn[[:digit:]]{1,}[mgkMGK]$' <<< $i); then XMN="${i}";
        elif $(grep -qiE '\-Xminf[[:digit:]\.]{1,}$' <<< $i); then XMINF="${i}";
        elif $(grep -qiE '\-Xmaxf[[:digit:]\.]{1,}$' <<< $i); then XMAXF="${i}";
        elif $(grep -qiE '\-XX:MaxPermSize=[[:digit:]\.]{1,}[mgkMGK]$' <<<  $i); then MAXPERMSIZE="${i}";
        else
            confresult=$(echo " $confresult" " $i" | sed -e 's/&/\\&/g' -e 's/;/\\;/g' -e "s/?/\\?/g" -e "s/*/\\*/g" -e "s/(/\\(/g" -e "s/)/\\)/g")
        fi
    done
fi

[ -z "$XMX" ] || export XMX
[ -z "$XMS" ] || export XMS
[ -z "$XMN" ] || export XMN
[ -z "$XMINF" ] || export XMINF
[ -z "$XMAXF" ] || export XMAXF
[ -z "$MAXPERMSIZE" ] || export MAXPERMSIZE
[ -z "$confresult" ] || set -- $@ $confresult
