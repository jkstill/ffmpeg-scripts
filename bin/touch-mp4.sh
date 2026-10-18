#!/usr/bin/env bash

:<<'COMMENT'

Several hundred .AVI files were converted to MP4 so they would play in a browser app.

AVI files do not always play; it is browser dependent.

Now I want to set the timestamp of the new files to the same as the original.

A list of files was created from the logs

  grep -hi mp4$ logs/*.log| sort -u | awk '{ print $2 }' > mp4-converted-files.txt


the touch command is used with the -r option to set the timestamp the same as the original

COMMENT

set -auo pipefail

DRYRUN=${DRYRUN:-false}
#echo "DRYRUN: $DRYRUN"

[[ $DRYRUN == true ]] && {
	echo "This is a DRYRUN" 
	dryrunStatus='DRYRUN'
} || {
	echo "No DRYRUN - This is Live"
	dryrunStatus='LIVE'
}

mp4FileList=./mp4-converted-files.txt

[[ -r $mp4FileList ]] || { echo "Could not open '$mp4FileList'"; exit 1; }

logDir='logs';

mkdir -p $logDir

logFile=$logDir/touch-mp4-${dryrunStatus}-$(date +%Y-%m-%d_%H-%M-%S).log

# Redirect stdout ( > ) into a named pipe ( >() ) running "tee"
# process substitution
# clear/recreate the logfile
> $logFile
exec 1> >(tee -ia $logFile)
exec 2> >(tee -ia $logFile >&2)

while read mp4File; do
	echo '==========================================================================================='
	echo "========== $mp4File"
	echo '==========================================================================================='
	# strip the extension
	basename=${mp4File%%.mp4}
	echo "basename: $basename"
	# look for mov|avi files of the same name
	# these are on a CIFS filesystem, so case unimportant
	declare -a refFiles
	read -ra refFiles <<< $( ls -1 $basename.{MOV,AVI} 2>/dev/null)

	[[ ${#refFiles[*]} < 1 ]] && {
		echo "No reference file found for '$mp4File'"
		exit 1
	}

	echo "Ref File: ${refFiles[0]}"
	#ls -l "${refFiles[0]}"
	echo 

	if [[ $DRYRUN == true ]] ; then
		echo touch -r ${refFiles[0]} $mp4File
		ls -l $basename.{AVI,MOV,MP4} 2>/dev/null
	else
		touch -r ${refFiles[0]} $mp4File
		ls -l $basename.{AVI,MOV,MP4} 2>/dev/null
	fi

done < $mp4FileList

exec 1>&1
exec 2>&1

echo
echo logFile: $logFile
echo


