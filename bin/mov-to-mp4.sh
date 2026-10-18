#!/usr/bin/env bash

set -u
set -o pipefail

rootDir="${1:-.}"

logDir='./logs'
mkdir -p $logDir

timestamp="$(date '+%Y%m%d-%H%M%S')"
logFile="${logDir}/mov-to-mp4-${timestamp}.log"
successList="${logDir}/mov-to-mp4-success-${timestamp}.txt"
deleteCandidates="${logDir}/mov-delete-candidates-${timestamp}.txt"
failedList="${logDir}/mov-failed-${timestamp}.txt"

: > "$logFile"
: > "$successList"
: > "$deleteCandidates"
: > "$failedList"

echo "Root directory: $rootDir" | tee -a "$logFile"
echo "Log file: $logFile" | tee -a "$logFile"
echo

while IFS= read -r -d '' movFile; do

	# skip if autocross, already done
	chk4Ax=${movFile:0:28}
	[[ $chk4Ax == '/mnt/photos/autos/autross'/ ]] && continue

   dirName="${movFile%/*}"
   baseName="${movFile##*/}"
   stem="${baseName%.*}"
   mp4File="${dirName}/${stem}.mp4"

   echo "Converting:" | tee -a "$logFile"
   echo "  mov: $movFile" | tee -a "$logFile"
   echo "  MP4: $mp4File" | tee -a "$logFile"

: <<'COMMENT'
   if [[ -e "$mp4File" ]] && [[ -s "$mp4File" ]] ; then
      echo "  SKIPPED: target already exists" | tee -a "$logFile"
      echo "$movFile" >> "$failedList"
      echo >> "$logFile"
      continue
   fi
COMMENT

	tmpFile="${mp4File}.tmp.$$" || { echo "failed to create tmpfile"; exit 1; }
	rm -f $tmpFile
	rm -f $mp4File

	if ffmpeg -nostdin -hide_banner -loglevel warning -y \
   	-fflags +genpts \
   	-i "$movFile" \
   	-map 0:v:0 -map 0:a? \
   	-c:v libx264 -preset medium -crf 22 \
   	-pix_fmt yuv420p \
   	-c:a aac -b:a 128k -ar 48000 -ac 2 \
   	-movflags +faststart \
   	-map_metadata 0 \
   	"$tmpFile" < /dev/null >> "$logFile" 2>&1
	then
		mv "$tmpFile" "$mp4File" || { echo "failed to 'mv "$tmpFile" "$mp4File"'"; exit 1; }
		echo "COPY OK: $mp4File" >> "$logFile"
		echo "$movFile" >> $deleteCandidates

	else
		rm -f "$tmpFile"
		echo "COPY FAILED, re-encoding: $movFile" >> "$logFile"

		ffmpeg -nostdin -hide_banner -loglevel warning \
			-fflags +genpts \
			-i "$movFile" \
			-vsync vfr \
			-c:v libx264 -crf 20 -preset medium \
			-c:a aac -b:a 128k \
			-movflags +faststart -map_metadata 0 \
			"$mp4File" < /dev/null >> "$logFile" 2>&1
		fi

done < <(find "$rootDir" -type f -iname '*.mov' -print0)


echo
echo "Done."
echo "Log file:                $logFile"
echo "Successful MP4 files:    $successList"
echo "MOV delete candidates:   $deleteCandidates"
echo "Failed/skipped MOV list: $failedList"

