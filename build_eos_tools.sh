#!/bin/bash
START_TIME="$(date)"
# Remove a single if test in the build script that doesn't like eos being a git submodule
if ! patch eos/eosio_build.sh -R -p0 -s -f --dry-run -i eos.patch; then
	patch eos/eosio_build.sh  -p0 -f -i eos.patch
fi
cd eos
BUILD_VERSION="$(git tag --list | grep mainnet | sort | tail -1)"
echo "Building $BUILD_VERSION..."
git checkout $BUILD_VERSION
git status
git submodule update --init --recursive
./eosio_build.sh -s EOS
cd ../eosio.cdt
BUILD_VERSION="$(git tag --list | grep mainnet | sort | tail -1)"
git checkout $BUILD_VERSION
git submodule update --init --recursive
./build.sh
END_TIME="$(date)"
echo "=================== eos and eosio.cdt built ================="
echo "Build Start Time: $START_TIME"
echo "Build End Time: $END_TIME"

read -p "Would you like to install eos and eosio.cdt? (Y/N)" response

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