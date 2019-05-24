#!/bin/bash

source ./conf.sh
source ./functions.sh
source ./dac_conf.sh

run_cmd "push action $daccustodian newperiod '{\"message\":\"New Period\"}' -p $daccustodian"
