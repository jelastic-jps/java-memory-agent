#!/bin/bash
[ -z "${JAVA_OPTS_CONFFILE}" ] && {
 [ -f "/.jelenv" ] && { grep -qE '^\s*JAVA_OPTS_CONFFILE=' /.jelenv && export $(grep -E '^\s*JAVA_OPTS_CONFFILE=' /.jelenv); }
}

CONFFILE="${JAVA_OPTS_CONFFILE}"
declare -a confresult=()

if [ -f "$CONFFILE" ]; then
	OLD_IFS="$IFS"
	IFS=$'\n'
	val=($(cat "$CONFFILE" | grep -vE '^\s*#' | grep -v -vE '^\s*$' | sed -re "s/('|\") /'\n/g" -e "/(\"|')/! s/\s/\n/g" -e 's/(\s)(-.*=\")/\n\2/'))
	IFS="$OLD_IFS"

	for i in "${val[@]}"
    do
        if $(grep -qiE '\-Xmx[[:digit:]]{1,}[mgkMGK]$' <<< $i); then XMX="${i}";
        elif $(grep -qiE '\-Xms[[:digit:]]{1,}[mgkMGK]$' <<< $i); then XMS="${i}";
        elif $(grep -qiE '\-Xmn[[:digit:]]{1,}[mgkMGK]$' <<< $i); then XMN="${i}";
        elif $(grep -qiE '\-Xminf[[:digit:]\.]{1,}$' <<< $i); then XMINF="${i}";
        elif $(grep -qiE '\-Xmaxf[[:digit:]\.]{1,}$' <<< $i); then XMAXF="${i}";
        elif $(grep -qiE '\-XX:MaxPermSize=[[:digit:]\.]{1,}[mgkMGK]$' <<<  $i); then MAXPERMSIZE="${i}";
        else
			confresult=("${confresult[@]}" "$i")
        fi
    done

fi

[ -z "$XMX" ] || export XMX
[ -z "$XMS" ] || export XMS
[ -z "$XMN" ] || export XMN
[ -z "$XMINF" ] || export XMINF
[ -z "$XMAXF" ] || export XMAXF
[ -z "$MAXPERMSIZE" ] || export MAXPERMSIZE
[ -z "$confresult" ] || set -- "${confresult[@]}" "${@}"
