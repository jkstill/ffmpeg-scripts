#!/usr/bin/env bash
# viewscene - ffplay with timestamp + key-help overlay for reviewing scene clips
# usage: viewscene FILE [SEEK_SECONDS] [OFFSET_SECONDS]
#   SEEK_SECONDS   step for Left/Right arrows (default 5)
#   OFFSET_SECONDS added to displayed time, e.g. clip start in the original movie (default 0)

SYNC=0

mkhelp() {

help=$(mktemp)
trap 'rm -f "$help"' EXIT
cat > "$help" <<EOF
SPACE/p pause    s  step frame
Left/Right -/+${step}s   Down/Up -/+60s
PgUp start      PgDn end
Right-click: seek to mouse X position
f fullscreen  m mute  q/ESC quit
EOF
}


usage() {
   echo "usage: -f FILE -s SEEK_SECONDS -o OFFSET_SECONDS -y SYNC to scene-list" >&2
}  

# SYNC will show times at it appears in the scene-list, otherwise it will show times relative to the start of the file.
# ie. scene 2 time will be  the time as it appears in the original file.

set -u

offset=''
scenesFile=''
step=2

while getopts "n:f:s:o:yh" opt; do
   case $opt in
   f) sceneFile=$OPTARG ;
      [[ -r $sceneFile ]] || { echo "File not readable: $sceneFile" >&2; exit 1; } ;;
	n) scenesFile=$OPTARG;;
		#[[ -r $scenesFile || { echo "Scenes file not readable: $scenesFile" >&2; exit 1; };;
   s) step=$OPTARG ;;
	h) usage;;
   o) offset=$OPTARG ;;
   y) SYNC=1 ;;
   *) echo "usage: viewscene FILE [SEEK_SECONDS] [OFFSET_SECONDS]" >&2; exit 1 ;;
esac
done

#echo SYNC: $SYNC

if [[ $SYNC -eq 1 ]] && [[ -n $offset ]] ; then
	echo "cannot specify both -o and -y"; exit 1; 
fi

#echo scenesFile: $scenesFile

if [[ $SYNC -eq 1 ]] && [[ -z $scenesFile ]] ; then
	echo "-y requires -n "scenesfile""
	exit 1
fi

if [[ $SYNC -eq 1 ]]; then

	# get scene number from filename
	dirName=${sceneFile%/*} # get the directory name of the file
	baseFile=${sceneFile##*/} # get the base name of the file
	baseName=${baseFile%.*} # get the base name without extension
	
	# the scene number is the last part after the last dash
	sceneNumber=${baseName##*-} # get the scene number
	# normalize to no leading zeros
	sceneNumber=$((10#$sceneNumber)) # convert to decimal to remove leading zeros

	echo sceneNumber: $sceneNumber

	offset=$(awk -F, -v n=$sceneNumber 'NR>1 && $1+0==n {print $4}' $scenesFile)


	echo offset: $offset

else
	offset=0
fi

#exit

font="font=DejaVu Sans Mono:fontcolor=white:box=1:boxborderw=6"

mkhelp

ffplay -hide_banner -loglevel warning \
  -seek_interval "$step" \
  -window_title "$(basename "$sceneFile")" \
  -vf "drawtext=${font}:fontsize=28:boxcolor=black@0.6:x=10:y=10:text='%{pts\:hms\:${offset}}   frame %{n}',\
	drawtext=${font}:fontsize=18:boxcolor=black@0.5:x=10:y=h-th-10:textfile=${help}"  \
	"$sceneFile"

