#!/bin/bash

set -euo pipefail

banner() {
  echo
  echo "########################################"
  echo $@
  echo "########################################"
}

if [ "${IN_DOCKER:-0}" = "1" ]; then
  banner "Detecting…"
  nice -n 19 -- /detector.py /workdir/weights.pt /workdir/in/

  shopt -s globstar
  FILES=(/workdir/in/**/*.json.gz)
  for jsongz in $FILES
  do
    videoin=${jsongz/.json.gz/}
    videoout=${videoin/\/in\//\/out\/}

    banner "Blurring ${videoin}…"

    mkdir -p /workdir/out/
    nice -n 19 -- /usr/bin/ffmpeg \
      -i "${videoin}" \
      -vf "frei0r=jsonblur:${jsongz}|0" \
      -c:v ffv1 \
      -c:a copy \
      "${videoout}.mkv"
  done
else
  DOCKER_BUILDKIT=1
  NAME="breunigs/video-anon-lossless:latest"

  banner "Building…"
  docker build -t "${NAME}" .
  docker run -it --mount "type=bind,source=$(pwd),target=/workdir" "${NAME}"
fi



