This repo wraps [Understand AI's Anonymizer Tool](https://github.com/understand-ai/anonymizer/) into a Docker container to solve the aging build stack the tool needs. Additionally it was changed to work with videos and extract their per-frame detections into a `.json.gz` file, which can be applied to the video using e.g. [a custom frei0r ffmpeg filter](https://github.com/breunigs/frei0r-blur-from-json).

The calculation is interruptible, already processed frames are stored in `.json.gz_wip` and moved to `.json.gz` once the video is fully processed.

# Usage

```bash
anonymize /path/to/videos
```
