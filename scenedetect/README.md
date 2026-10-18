
Some scripts and instructions for using scenedetect and ffplay synced with the scenedetect scene list.

## scenedetect


Create scene files from old B&W movies using the following command:

1945.m4v is the 1945 version of the The Big Sleep.

```bash
scenedetect --output 1945-scenes --stats 1945-stats.csv  -i 1945.m4v detect-threshold -t 12 split-video --copy list-scenes -s
```

## show individual scenes using ffplay

This command will show the individual scenes using ffplay, with the time shown being that from the movie file, not the scene file.

```bash
/viewscene.sh -y -n 1945-scenes/1945-Scenes.csv  -f 1945-scenes/1945-Scene-014.mp4
```




