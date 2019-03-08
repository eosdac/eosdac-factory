#!/bin/bash

cwd=$(pwd)
$cwd/eos/build/bin/cleos --url http://jungle2.cryptolions.io:80/ "$@"

