#!/usr/bin/env bash

set -e

POSTGRES_VERSION="12.17"

while getopts v: flag
do
    case "${flag}" in
        v) POSTGRES_VERSION=${OPTARG};;
    esac
done

# Prepare folders and cleanup
mkdir -pv ./build
mkdir -pv ./usr
rm -rf ./build/*
rm -rf ./usr/*
workdir=$PWD

# Install deps 
sudo apt install wget make gcc libreadline7 libreadline-dev tar \
    zlib1g zlib1g-dev libicu63 libicu-dev libperl-dev libperl5.28 \
    python3 python3-dev openssl libssl-dev uuid-runtime uuid-dev -y

# Get 'n' unpack postgres sources
wget https://ftp.postgresql.org/pub/source/v${POSTGRES_VERSION}/postgresql-${POSTGRES_VERSION}.tar.gz
tar -xvf ./postgresql-${POSTGRES_VERSION}.tar.gz

# Compile
cd build
../postgresql-${POSTGRES_VERSION}/configure --prefix=$workdir/usr/ --with-uuid=e2fs
make world-bin
make install-world-bin
