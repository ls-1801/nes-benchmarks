#!/bin/bash
set -e 

QUERY=$1
shift

mkdir $(pwd)/logs || true
docker run -it -p 8085 --net=host --user $(id -u) --rm -v "$(pwd)/data":/data -v "$(pwd)/logs/":/build_dir -v "$(pwd)/$QUERY/build":/input unikernel-test "$@"
