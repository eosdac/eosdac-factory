#!/bin/bash

cwd=$(pwd)
$cwd/eos/build/bin/keosd --wallet-dir $cwd --http-server-address localhost:8900 "$@"
