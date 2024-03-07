#!/bin/bash
set -e

BUILD_LTO=1
BUILD_NO_LTO=1
BUILD_DEBUG=1
BUILD_ORIGINAL_DEPS=1
STRIP=1


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

if [[ BUILD_DEBUG ]] then
	TEMP_DIR_DEBUG="$(pwd)/$1/build-unikernel-debug"
	mkdir -p $TEMP_DIR_DEBUG || true
	rm -rf $TEMP_DIR_DEBUG/*
fi

if [[ BUILD_ORIGINAL_DEPS ]] then
	TEMP_DIR_ORIGINAL_DEPS="$(pwd)/$1/build-unikernel-original-deps"
	mkdir -p $TEMP_DIR_ORIGINAL_DEPS || true
	rm -rf $TEMP_DIR_ORIGINAL_DEPS/*
fi

mkdir -p $TEMP_DIR || true
rm -rf $TEMP_DIR/*

cat $(pwd)/$1/unikernel.yaml | docker run --rm -i -v $TEMP_DIR:/output --user $(id -u) unikernel-export:latest -
if [[ BUILD_LTO ]]; then
	docker run --rm -v $TEMP_DIR:/input -v $TEMP_DIR_LTO:/output --user $(id -u) unikernel-build:lto -flto=thin &
fi

if [[ BUILD_NO_LTO ]]; then
	docker run --rm -v $TEMP_DIR:/input -v $TEMP_DIR_NO_LTO:/output --user $(id -u) unikernel-build:no-lto &
fi

if [[ BUILD_DEBUG ]]; then
	docker run --rm -v $TEMP_DIR:/input -v $TEMP_DIR_DEBUG:/output --user $(id -u) unikernel-build:debug &
fi

if [[ BUILD_ORIGINAL_DEPS ]]; then
	docker run --rm -v $TEMP_DIR:/input -v $TEMP_DIR_ORIGINAL_DEPS:/output --user $(id -u) unikernel-build:original-deps &
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
if [[ BUILD_DEBUG ]] then
	for f in $TEMP_DIR_DEBUG/unikernel*; do mv "$f" "$TEMP_DIR/$(basename $f).debug"; done
	rm -rf $TEMP_DIR_DEBUG
fi

if [[ BUILD_ORIGINAL_DEPS ]] then
	for f in $TEMP_DIR_ORIGINAL_DEPS/unikernel*; do mv "$f" "$TEMP_DIR/$(basename $f).original-deps"; done
	rm -rf $TEMP_DIR_ORIGINAL_DEPS
fi

if [[ STRIP ]]; then
	for f in $TEMP_DIR/unikernel*; do cp "$f" "$f.strip" && echo "Stripping $f" && strip "$f.strip"; done
fi
