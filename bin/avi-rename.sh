#!/usr/bin/env bash

set -u
set -o pipefail

rootDir="${1:-.}"

timestamp="$(date '+%Y%m%d-%H%M%S')"
logFile="avi-to-mp4-${timestamp}.log"
successList="mp4-success-${timestamp}.txt"
deleteCandidates="avi-delete-candidates-${timestamp}.txt"
failedList="avi-failed-${timestamp}.txt"

: > "$logFile"
: > "$successList"
: > "$deleteCandidates"
: > "$failedList"

echo "Root directory: $rootDir" | tee -a "$logFile"
echo "Log file: $logFile" | tee -a "$logFile"
echo

find "$rootDir" -type f \( -iname '*.avi' \) -print0 |
while IFS= read -r -d '' aviFile; do

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

   if ffmpeg -hide_banner -loglevel warning \
      -i "$aviFile" \
      -c:v libx264 -crf 20 -preset medium \
      -c:a aac -b:a 192k \
      "$mp4File" >> "$logFile" 2>&1
   then
      echo "  OK" | tee -a "$logFile"
      echo "$mp4File" >> "$successList"
      echo "$aviFile" >> "$deleteCandidates"
   else
      rc=$?
      echo "  FAILED rc=$rc" | tee -a "$logFile"
      rm -f "$mp4File"
      echo "$aviFile" >> "$failedList"
   fi

   echo >> "$logFile"

done

echo
echo "Done."
echo "Log file:                $logFile"
echo "Successful MP4 files:    $successList"
echo "AVI delete candidates:   $deleteCandidates"
echo "Failed/skipped AVI list: $failedList"
