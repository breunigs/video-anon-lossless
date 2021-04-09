FROM debian:stable-slim

ENV WEIGHTS_CACHE=/anonymizer-weights-cache
ENV PYTHON_VERSION=3.6.9

RUN mkdir /app/ ${WEIGHTS_CACHE}
WORKDIR /app/

RUN apt-get update && apt-get -y install --no-install-recommends \
  bash \
  build-essential \
  ca-certificates \
  coreutils \
  curl \
  ffmpeg \
  git \
  imagemagick \
  libssl-dev \
  ruby \
  ruby-bundler \
  zlib1g-dev

# Install asdf, because we need an older Python version than available in Debian buster
RUN git clone https://github.com/asdf-vm/asdf.git /asdf --branch v0.8.0 --depth 1 && \
  rm -rf /asdf/.git
COPY asdf /usr/bin/
RUN chmod +x /usr/bin/asdf
ENV ASDF_DIR=/asdf-dir/
ENV ASDF_DATA_DIR=/asdf-data-dir/
RUN asdf plugin add python && asdf install python ${PYTHON_VERSION} && asdf global python ${PYTHON_VERSION}

COPY requirements.txt /app/
RUN asdf exec pip3 install -r requirements.txt

RUN git clone https://github.com/understand-ai/anonymizer.git anonymizer --depth 1 && \
  cd anonymizer && \
  git checkout 2fc7ab3f485621270ea9969297f0878c2a1b415e

# run once to warm weights cache
ENV PYTHONPATH=${PYTHONPATH}:/app/anonymizer/
RUN asdf exec python /app/anonymizer/anonymizer/bin/anonymize.py \
  --weights ${WEIGHTS_CACHE} \
  --input /video \
  --image-output /video

# disable internal image blurring because it's rather slow on CPU.
# The imagemagick variant built into video-anon is much faster.
# Also skip detection if target JSON already exists.
COPY upstream.patch /app/
RUN cd anonymizer && git apply /app/upstream.patch

COPY Gemfile* /app/
RUN bundle install

ENTRYPOINT ["/app/video-anon"]
RUN touch /.tool-versions && chmod og+w /.tool-versions

COPY video-anon /app/
RUN chmod +x /app/video-anon
