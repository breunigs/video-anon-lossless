# syntax=docker/dockerfile:experimental

# build json blur frei0r ffmpeg plugin
FROM debian:stable-slim AS blur
ARG BLUR_GIT_SHA=0e3f4c6396bff074c03c35f0cf0b2d905c6fee85

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update --yes \
  && apt-get install --yes --no-install-recommends \
  ca-certificates \
  cmake \
  curl \
  frei0r-plugins-dev \
  g++ \
  git \
  libboost-dev \
  libboost-iostreams-dev \
  libmagick++-6-headers \
  libmagick++-6.q16-dev \
  make \
  unzip \
  && rm -rf /var/lib/apt/lists/*

RUN curl -L https://github.com/breunigs/frei0r-blur-from-json/archive/${BLUR_GIT_SHA}.zip > /tmp/blur.zip && \
  unzip -D -q /tmp/blur.zip -d /dummy/ \
  && rm /tmp/blur.zip \
  && mv /dummy/frei0r-blur-from-json-${BLUR_GIT_SHA}/ /build \
  && ls -alh / \
  && ls -alh /build/ \
  && cd /build \
  && cmake . \
  && make

# download a known-to-work yolov5 version
FROM debian:stable-slim AS yolo
ARG YOLO_GIT_SHA=c72270c076e1f087d3eb0b1ef3fb7ab55fe794ba

RUN apt-get update --yes \
  && apt-get install --yes --no-install-recommends \
  ca-certificates \
  curl \
  unzip \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/.cache/torch/hub/ && \
  curl -L https://github.com/ultralytics/yolov5/archive/${YOLO_GIT_SHA}.zip > /tmp/yolov5.zip && \
  unzip -D -q /tmp/yolov5.zip -d /root/.cache/torch/hub/ && \
  rm /tmp/yolov5.zip && \
  mv /root/.cache/torch/hub/yolov5-${YOLO_GIT_SHA} /root/.cache/torch/hub/ultralytics_yolov5_master

# download a known-to-work detection CLI
FROM debian:stable-slim AS detector
ARG VELO_GIT_SHA=e7cdfbebcd56815e392d72f00e1679d3057dda01

RUN apt-get update --yes \
  && apt-get install --yes --no-install-recommends \
  ca-certificates \
  curl \
  && rm -rf /var/lib/apt/lists/*
RUN curl -L https://raw.githubusercontent.com/breunigs/veloroute/${VELO_GIT_SHA}/tools/detection/detector.py > /detector.py \
  && chmod +x /detector.py

# runtime
FROM debian:stable-slim AS runtime

WORKDIR /workdir/
RUN mkdir -p /root/.frei0r-1/lib/ /root/.config/Ultralytics/ /workdir/

# font is to prevent YOLOv5 from downloading unnecessary assets
RUN apt-get update --yes \
  && apt-get install --yes --no-install-recommends \
  ffmpeg \
  fonts-dejavu-core \
  libboost-iostreams1.74.0 \
  libmagick++-6.q16-8 \
  python-is-python3 \
  python3 \
  python3-pip \
  && rm -rf /var/lib/apt/lists/* \
  && ln /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf /root/.config/Ultralytics/Arial.ttf

# install torch separately because it's so large
RUN pip install torch==1.10.1 \
  && rm -rf /root/.cache/pip

# install dependencies for the detector
RUN pip install \
  imageio \
  imageio-ffmpeg \
  tqdm>=4.41.0 \
  && rm -rf /root/.cache/pip

COPY --from=yolo /root/.cache/torch/hub/ /root/.cache/torch/hub/
RUN pip install -r /root/.cache/torch/hub/ultralytics_yolov5_master/requirements.txt \
  && rm -rf /root/.cache/pip

COPY --from=blur /build/jsonblur.so /root/.frei0r-1/lib/
COPY --from=detector /detector.py /detector.py
COPY run.sh /run.sh

# work around https://github.com/pytorch/pytorch/issues/67598
RUN sed -i "s/if torch.cuda.amp.common.amp_definitely_not_available() and self.device == 'cuda':/if enabled and torch.cuda.amp.common.amp_definitely_not_available() and self.device == 'cuda':/" /usr/local/lib/python3.9/dist-packages/torch/autocast_mode.py

ENV FREI0R_PATH=/root/.frei0r-1/lib/
ENV IN_DOCKER=1
ENTRYPOINT ["/bin/bash"]
CMD ["/run.sh"]

