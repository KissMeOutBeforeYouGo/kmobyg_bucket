#!/usr/bin/env bash

PYTHON_VERSION="3.8.18"

while getopts v: flag
do
    case "${flag}" in
        v) PYTHON_VERSION=${OPTARG};;
    esac
done

installdir=$PWD/install_dir

sudo apt install wget gcc make build-essential gdb lcov pkg-config \
      libbz2-dev libffi-dev libgdbm-dev libgdbm-compat-dev liblzma-dev \
      libncurses5-dev libreadline6-dev libsqlite3-dev libssl-dev \
      lzma lzma-dev tk-dev uuid-dev zlib1g-dev -y

wget https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz
tar -xvf ./Python-$PYTHON_VERSION.tgz
cd ./Python-$PYTHON_VERSION
mkdir -pv $installdir
rm -rf $installdir/usr
./configure --enable-optimizations --with-lto --enable-shared --prefix=/usr
make -j$(nproc)
make install DESTDIR=$installdir 
