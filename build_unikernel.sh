#!/bin/bash


INPUT=$1

TEMP_DIR=./build-unikernel

mkdir $TEMP_DIR || true
rm -rf $TEMP_DIR/*

cat $1 | docker run --rm -i -v $TEMP_DIR:/output --user $(id -u) unikernel-export:latest -

docker run --rm -v $TEMP_DIR:/input -v $TEMP_DIR:/output --user $(id -u) unikernel-build-no-lto:latest
for f in $TEMP_DIR/unikernel*; do mv "$f" "$(basename f).no-lto"; done
docker run --rm -v $TEMP_DIR:/input -v $(pwd):/output --user $(id -u) unikernel-build-lto:latest -flto=thin
for f in $TEMP_DIR/unikernel*; do mv "$f" "$(basename f).lto"; done
