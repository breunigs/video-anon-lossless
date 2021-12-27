# video-anon-lossless

The repository builds a single Docker container that has all the necessary
pieces to detect and blur faces and license plates in videos. It pulls code
from these repos:

* [veloroute.hamburg](https://github.com/breunigs/veloroute/): the overarching
  project for which this tooling was built. Only the `detector.py` wrapper
  around YOLOv5 is grabbed from there. It's basically glue code.
* [frei0r-blur-from-json](https://github.com/breunigs/frei0r-blur-from-json): an
  ffmpeg plugin/video filter that reads blur annotations and then blurs these
  regions
* [YOLOv5](https://github.com/ultralytics/yolov5/) the lib providing the
  computer vision algorithm used for detection

# Usage

1. [Install Docker]()
2. Create the following folder structure:
   ```
   some-folder/
   some-folder/in/
   some-folder/in/my-video1.MP4
   some-folder/in/my-video2.mkv
   some-folder/out/
   ```
   Only `.MP4` and `.mkv` video files are supported. The file endings are case
   sensitive.
3. Open a terminal and run:

   ```bash
   # Linux/Mac
   cd some-folder/
   docker run -it \
     -e "OWNER_GROUP_FIX=$(id -u):$(id -g)" \
     --mount "type=bind,source=$(pwd),target=/workdir" \
     "ghcr.io/breunigs/video-anon-lossless:yolov5-cpu"
   ```
4. The detections will be put along the videos in `some-folder/in/`,
   the blurred and _lossless_ videos in `some-folder/out/`. You'll
   need to convert the video again to be usable, but simply uploading
   it to YouTube, Vimeo, etc. will just work fine.

# Usage and Building Details

On Linux, ensure Docker is installed, then simply run `run.sh`. It will
automatically build and run the container.

It will look for video files with the extensions `.mkv` or `.MP4` (case matters)
in the `in/` folder. First, it will detect areas to blur and cache the results
alongside the videos in the `in/` folder as `<video name>.json.gz` files. You
can interrupt this process by pressing `CTRL+C` and it will resume the next
time.

In a second step the videos are blurred. This is not interruptible, i.e. if you
break in between a video, the resulting video will be broken.

The output format is an `mkv` with the blurred video and copied
audio. Other metadata is lost -- in theory `ffmpeg` can copy it, but it stumbles
across GoPro metadata.

The resulting video files will be quite large since the video is stored
losslessly. It's likely that the video will not play fluently. Either change the
parameters in `run.sh` or use other software to further adjust as desired.

# Debugging

The way the container is set up, you can run it through
```bash
docker run -it … <image-name> -i
```
to get a shell. See `run.sh` for the other parameters.
