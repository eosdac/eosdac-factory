#!/bin/bash

cwd=$(pwd)
# uncomment this next line if you want to run the specific version of keosd you built
#$cwd/eos/build/bin/keosd --wallet-dir $cwd --http-server-address localhost:8900 "$@"
keosd --wallet-dir $cwd --http-server-address localhost:8900 "$@"
