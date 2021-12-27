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
  weights=$(dirname "${BASH_SOURCE[0]}")/weights.pt
  nice -n 19 -- /detector.py "${weights}" /workdir/in/

  shopt -s globstar
  if [ "${OWNER_GROUP_FIX:-}" != "" ]; then
    chown "${OWNER_GROUP_FIX}" /workdir/in/**/*.json.gz
  fi

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
    if [ "${OWNER_GROUP_FIX:-}" != "" ]; then
      chown "${OWNER_GROUP_FIX}" "${videoout}.mkv"
    fi
  done
else
  DOCKER_BUILDKIT=1
  NAME="breunigs/video-anon-lossless:latest"

  banner "Building…"
  docker build -t "${NAME}" .
  docker run -it -e  "OWNER_GROUP_FIX=$(id -u):$(id -g)" --mount "type=bind,source=$(pwd),target=/workdir" "${NAME}"
fi



