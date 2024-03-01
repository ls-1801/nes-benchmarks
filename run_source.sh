#!/bin/bash

$NES_DIR/cmake-build-unikernel-release-original-deps/nes-unikernel-source/unikernel-source -c build-unikernel/export.yaml -n $1 -t DATA_FILE -f $(pwd)/bid.bin -s 1000000

