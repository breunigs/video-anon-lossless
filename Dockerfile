# syntax=docker/dockerfile:experimental

FROM tensorflow/tensorflow:1.15.5

RUN mkdir /app/ /anonymizer-weights-cache
WORKDIR /app/

RUN apt-get update && apt-get -y install --no-install-recommends \
  coreutils \
  ffmpeg \
  git \
  imagemagick \
  python3 \
  python3-pip \
  python3-setuptools \
  python3-wheel

RUN pip3 install --upgrade pip
COPY requirements.txt /app/
RUN pip3 uninstall tensorflow --yes && pip3 install -r requirements.txt

RUN git clone https://github.com/understand-ai/anonymizer.git anonymizer --depth 1 && \
  cd anonymizer && \
  git checkout 2fc7ab3f485621270ea9969297f0878c2a1b415e

ENV TF_XLA_FLAGS="--tf_xla_auto_jit=2 --tf_xla_cpu_global_jit"
ENV PYTHONPATH=${PYTHONPATH}:/app/anonymizer/

# run once to warm weights cache
RUN python3 /app/anonymizer/anonymizer/bin/anonymize.py \
  --weights /anonymizer-weights-cache \
  --image-output /data \
  --input /data

COPY upstream.patch /app/
RUN cd anonymizer && git apply /app/upstream.patch

ENTRYPOINT ["nice", "-n20", "python3", \
  "/app/anonymizer/anonymizer/bin/anonymize.py", \
  "--weights", "/anonymizer-weights-cache", \
  "--input", "/data", \
  "--write-detections"]
