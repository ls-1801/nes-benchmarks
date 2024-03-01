#!/bin/bash


INPUT=$1

TEMP_DIR=./build-unikernel

mkdir $TEMP_DIR || true
rm -rf $TEMP_DIR/*

cat $1 | docker run --rm -i -v $TEMP_DIR:/output --user $(id -u) unikernel-export:latest -
docker run --rm -v $TEMP_DIR:/input -v $(pwd):/output --user $(id -u) unikernel-build:latest
