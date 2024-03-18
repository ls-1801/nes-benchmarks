#!/bin/bash

docker run -d --rm -v $(pwd):/config --name=coord --net=host localhost:5000/nebulastream/nes-executable-image:latest nesCoordinator --restPort=7070 --coordinatorIp=10.0.0.1 --rpcPort=8434 --worker.dataPort=8432 --worker.coordinatorPort=8434 --configPath=/config/coordinator.yaml --worker.workerId=1 --worker.localWorkerIp=10.0.0.1 --worker.bufferSizeInBytes=8192 --worker.numWorkerThreads=4
