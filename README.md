This repo wraps [Understand AI's Anonymizer Tool](https://github.com/understand-ai/anonymizer/) into a Docker container to solve the aging build stack the tool needs. There's additional scripting to automatically blur videos and recompress them losslessly for further editing.

# Usage

```bash
anonymize_video /path/to/videos
```

This will convert all videos in the current directory into lossless, anonymized versions with a `_anonymized.mkv` suffix. Note that you'll need quite a lot of raw disk space because the script keeps all intermediate files until the full conversion is done.
