#!/bin/bash
set -e

BUILD_LTO=true
BUILD_NO_LTO=false
BUILD_DEBUG=false
BUILD_ORIGINAL_DEPS=false
STRIP=true

RUN_LOCAL=false

# Parse options
while getopts :ld opt; do
  case $opt in
    l)
      RUN_LOCAL=true
      ;;
    d)
      BUILD_DEBUG=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Shift to get the positional arguments
shift $((OPTIND-1))

BENCHMARK="$1"

echo "$1"


LOCAL=$(cat "$(pwd)/$BENCHMARK/unikernel.yaml" | sed 's/10.0.0.1/127.0.0.1/g' | yq '.topology.workers.[].node.port |= 8086 + (path | .[2]) | .topology.workers.[].node.ip |= "127.0.0.1"')

TEMP_DIR="$(pwd)/$BENCHMARK/build"

if  $BUILD_LTO;  then
	TEMP_DIR_LTO="$(pwd)/$BENCHMARK/build-unikernel-lto"
	mkdir -p $TEMP_DIR_LTO || true
	rm -rf $TEMP_DIR_LTO/*
fi

if  $BUILD_NO_LTO;  then
	TEMP_DIR_NO_LTO="$(pwd)/$BENCHMARK/build-unikernel-no-lto"
	mkdir -p $TEMP_DIR_NO_LTO || true
	rm -rf $TEMP_DIR_NO_LTO/*
fi

if  $BUILD_DEBUG;  then
	TEMP_DIR_DEBUG="$(pwd)/$BENCHMARK/build-unikernel-debug"
	mkdir -p $TEMP_DIR_DEBUG || true
	rm -rf $TEMP_DIR_DEBUG/*
fi

if $BUILD_ORIGINAL_DEPS ; then
	TEMP_DIR_ORIGINAL_DEPS="$(pwd)/$BENCHMARK/build-unikernel-original-deps"
	mkdir -p $TEMP_DIR_ORIGINAL_DEPS || true
	rm -rf $TEMP_DIR_ORIGINAL_DEPS/*
fi

mkdir -p $TEMP_DIR || true
rm -rf $TEMP_DIR/*

if  $RUN_LOCAL ; then
	printf "$LOCAL"
	printf "$LOCAL" | docker run --rm -i -v $TEMP_DIR:/output --user $(id -u) unikernel-export:latest -
else
	cat $(pwd)/$BENCHMARK/unikernel.yaml | docker run --rm -i -v $TEMP_DIR:/output --user $(id -u) unikernel-export:latest -
fi
if  $BUILD_LTO ; then
	docker run --rm -v $TEMP_DIR:/input -v $TEMP_DIR_LTO:/output --user $(id -u) unikernel-build:lto-debug-log -flto=thin -static &
fi

if  $BUILD_NO_LTO ; then
	docker run --rm -v $TEMP_DIR:/input -v $TEMP_DIR_NO_LTO:/output --user $(id -u) unikernel-build:no-lto &
fi

if  $BUILD_DEBUG ; then
	docker run --rm -v $TEMP_DIR:/input -v $TEMP_DIR_DEBUG:/output --user $(id -u) unikernel-build:debug &
fi

if  $BUILD_ORIGINAL_DEPS ; then
	docker run --rm -v $TEMP_DIR:/input -v $TEMP_DIR_ORIGINAL_DEPS:/output --user $(id -u) unikernel-build:original-deps &
fi

wait

cat "$TEMP_DIR/export.yaml" | yq "{\"commands\": [.workers[] | {\"type\": \"AddUnikernel\", \"nodeId\": .nodeId, \"queryId\": 1, \"pathToBinary\": \"$TEMP_DIR/unikernel\" + .nodeId +  \".lto\", \"args\": [], \"ip\": .ip} ]}" > "$TEMP_DIR/vmlauncher-script.yaml"

if  $BUILD_LTO ; then
	for f in $TEMP_DIR_LTO/unikernel*; do mv "$f" "$TEMP_DIR/$(basename $f).lto"; done
	rm -rf $TEMP_DIR_LTO
fi
if  $BUILD_NO_LTO ; then
	for f in $TEMP_DIR_NO_LTO/unikernel*; do mv "$f" "$TEMP_DIR/$(basename $f).no-lto"; done
	rm -rf $TEMP_DIR_NO_LTO
fi
if  $BUILD_DEBUG ; then
	for f in $TEMP_DIR_DEBUG/unikernel*; do mv "$f" "$TEMP_DIR/$(basename $f).debug"; done
	rm -rf $TEMP_DIR_DEBUG
fi

if  $BUILD_ORIGINAL_DEPS ; then
	for f in $TEMP_DIR_ORIGINAL_DEPS/unikernel*; do mv "$f" "$TEMP_DIR/$(basename $f).original-deps"; done
	rm -rf $TEMP_DIR_ORIGINAL_DEPS
fi

if  $STRIP ; then
	for f in $TEMP_DIR/unikernel*; do cp "$f" "$f.strip" && echo "Stripping $f" && strip "$f.strip"; done
fi
