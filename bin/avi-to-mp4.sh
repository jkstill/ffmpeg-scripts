#!/usr/bin/env bash

set -u
set -o pipefail

rootDir="${1:-.}"

logDir='./logs'
mkdir -p $logDir

timestamp="$(date '+%Y%m%d-%H%M%S')"
logFile="${logDir}/avi-to-mp4-${timestamp}.log"
successList="${logDir}/avi-to-mp4-success-${timestamp}.txt"
deleteCandidates="${logDir}/avi-delete-candidates-${timestamp}.txt"
failedList="${logDir}/avi-failed-${timestamp}.txt"

: > "$logFile"
: > "$successList"
: > "$deleteCandidates"
: > "$failedList"

echo "Root directory: $rootDir" | tee -a "$logFile"
echo "Log file: $logFile" | tee -a "$logFile"
echo

while IFS= read -r -d '' aviFile; do

	# skip if autocross, already done
	chk4Ax=${aviFile:0:28}
	[[ $chk4Ax == '/mnt/photos/autos/autross'/ ]] && continue

   dirName="${aviFile%/*}"
   baseName="${aviFile##*/}"
   stem="${baseName%.*}"
   mp4File="${dirName}/${stem}.mp4"

   echo "Converting:" | tee -a "$logFile"
   echo "  AVI: $aviFile" | tee -a "$logFile"
   echo "  MP4: $mp4File" | tee -a "$logFile"

   if [[ -e "$mp4File" ]]; then
      echo "  SKIPPED: target already exists" | tee -a "$logFile"
      echo "$aviFile" >> "$failedList"
      echo >> "$logFile"
      continue
   fi

   if ffmpeg -nostdin -hide_banner -loglevel warning \
      -i "$aviFile" \
      -c:v libx264 -crf 20 -preset medium \
      -c:a aac -b:a 192k \
      "$mp4File" < /dev/null >> "$logFile" 2>&1
   then
      echo "$mp4File" >> "$successList"
      echo "$aviFile" >> "$deleteCandidates"
   else
      rc=$?
      rm -f "$mp4File"
      echo "$aviFile" >> "$failedList"
      echo "FAILED rc=$rc: $aviFile" >> "$logFile"
   fi

done < <(find "$rootDir" -type f -iname '*.avi' -print0)


echo
echo "Done."
echo "Log file:                $logFile"
echo "Successful MP4 files:    $successList"
echo "AVI delete candidates:   $deleteCandidates"
echo "Failed/skipped AVI list: $failedList"
