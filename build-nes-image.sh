#!/bin/bash

pushd $NES_DIR/docker/buildImage
docker buildx build  -t nes_package -f Dockerfile-NES-Build-ubuntu-22_04 .
popd

cache_dir=/tmp/nes-docker-cache
build_dir=/tmp/nes-docker-build
mkdir -p $cache_dir || true
mkdir -p $build_dir || true

pushd $NES_DIR
docker run -v $cache_dir:/cache_dir -v $build_dir:/build_dir -v $NES_DIR:/nebulastream -eNesBuildParallelism=22 --privileged --cap-add SYS_NICE --entrypoint /nebulastream/docker/buildImage/entrypoint-prepare-nes-package.sh nes_package
popd

cp $build_dir/NebulaStream-*-Linux.x86_64.deb $NES_DIR/nes-amd64.deb

pushd $NES_DIR
docker buildx build . -f docker/executableImage/Dockerfile-NES-Executable-Multi-Arch --platform=linux/amd64 --tag localhost:5000/nebulastream/nes-executable-image:latest --push
popd
