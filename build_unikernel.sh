#!/bin/bash
set -e

BUILD_LTO=1
BUILD_NO_LTO=0


TEMP_DIR="$(pwd)/$1/build"
if [[ BUILD_LTO ]] then
	TEMP_DIR_LTO="$(pwd)/$1/build-unikernel-lto"
	mkdir -p $TEMP_DIR_LTO || true
	rm -rf $TEMP_DIR_LTO/*
fi

if [[ BUILD_NO_LTO ]] then
	TEMP_DIR_NO_LTO="$(pwd)/$1/build-unikernel-no-lto"
	mkdir -p $TEMP_DIR_NO_LTO || true
	rm -rf $TEMP_DIR_NO_LTO/*
fi


mkdir -p $TEMP_DIR || true
rm -rf $TEMP_DIR/*

cat $(pwd)/$1/unikernel.yaml | docker run --rm -i -v $TEMP_DIR:/output --user $(id -u) unikernel-export:latest -
if [[ BUILD_LTO ]] then
	docker run --rm -v $TEMP_DIR:/input -v $TEMP_DIR_LTO:/output --user $(id -u) unikernel-build-lto:latest -flto=thin &
fi

if [[ BUILD_NO_LTO ]] then
	docker run --rm -v $TEMP_DIR:/input -v $TEMP_DIR_NO_LTO:/output --user $(id -u) unikernel-build-no-lto:latest &
fi
wait

if [[ BUILD_LTO ]] then
	for f in $TEMP_DIR_LTO/unikernel*; do mv "$f" "$TEMP_DIR/$(basename $f).lto"; done
	rm -rf $TEMP_DIR_LTO
fi
if [[ BUILD_NO_LTO ]] then
	for f in $TEMP_DIR_NO_LTO/unikernel*; do mv "$f" "$TEMP_DIR/$(basename $f).no-lto"; done
	rm -rf $TEMP_DIR_NO_LTO
fi
