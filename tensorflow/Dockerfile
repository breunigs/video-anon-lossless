# syntax=docker/dockerfile:experimental

FROM tensorflow/tensorflow:devel AS builder

WORKDIR /tensorflow_src
RUN rm $(which bazel)
RUN apt-get update && apt-get -y install python bash-completion --no-install-recommends
RUN wget --quiet https://github.com/bazelbuild/bazel/releases/download/0.26.1/bazel_0.26.1-linux-x86_64.deb && dpkg -i bazel_0.26.1-linux-x86_64.deb
RUN --mount=type=cache,target=/root/.cache/ \
  git checkout r1.15 && \
  ./configure && \
  nice -n20 bazel build --config=opt --config=noaws --config=nogcp --config=nohdfs --config=nonccl //tensorflow/tools/pip_package:build_pip_package --config=v1 && \
  nice -n20 ./bazel-bin/tensorflow/tools/pip_package/build_pip_package /

FROM scratch

COPY --from=builder /tensorflow-1.15.5-cp36-cp36m-linux_x86_64.whl /
