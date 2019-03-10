#!/bin/bash
START_TIME="$(date)"
echo "Updating all submodules"
git submodule update --init --recursive
END_TIME="$(date)"
echo "Start Time: $START_TIME"
echo "End Time: $END_TIME"
