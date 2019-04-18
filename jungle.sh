#!/bin/bash

cwd=$(pwd)
# uncomment this next line if you want to run the specific version of cleos you built
#$cwd/eos/build/bin/cleos --url http://jungle2.cryptolions.io:80/ "$@"
cleos --url http://jungle2.cryptolions.io:80/ "$@"

