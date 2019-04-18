#!/bin/bash
START_TIME="$(date)"
cd eos
BUILD_VERSION="$(git tag --list | grep mainnet | sort | tail -1)"
echo "Building $BUILD_VERSION..."
git checkout $BUILD_VERSION
git status
git submodule update --init --recursive
# Remove a single if test in the build script that doesn't like eos being a git submodule
if ! patch eosio_build.sh -R -p0 -s -f --dry-run -i ../eos.patch; then
        patch eosio_build.sh  -p0 -f -i ../eos.patch
fi
./eosio_build.sh -s EOS
cd ../eosio.cdt
BUILD_VERSION="$(git tag --list | sort | tail -1)"
echo "Latest version of eosio.cdt is $BUILD_VERSION but we're going to go ahead and use v1.5.0 as 1.6 has some bugs."
BUILD_VERSION="v1.5.0"
echo "Building $BUILD_VERSION..."
git checkout $BUILD_VERSION
git submodule update --init --recursive
./build.sh
echo "=================== eos and eosio.cdt built ================="
END_TIME="$(date)"
echo "Build Start Time: $START_TIME"
echo "Build End Time: $END_TIME"

read -p "Would you like to install eos and eosio.cdt (requires sudo)? (Y/N)" response

if [[ $response == "Y" || $response == "y" ]]; then
	START_TIME="$(date)"
	cd ../eos
	sudo ./eosio_install.sh
	cd ../eosio.cdt
	sudo ./install.sh
	END_TIME="$(date)"
	echo "Install Start Time: $START_TIME"
	echo "Install End Time: $END_TIME"
fi
