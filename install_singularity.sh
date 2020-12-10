#!/bin/bash

sudo apt-get update && sudo apt-get install -y build-essential libseccomp-dev pkg-config squashfs-tools cryptsetup 

export VERSION=1.15.6 OS=linux ARCH=amd64 && rm -rf go$VERSION.$OS-$ARCH.tar.gz && wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz && sudo tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz && rm -rf go$VERSION.$OS-$ARCH.tar.gz

echo 'export PATH=/usr/local/go/bin:$PATH' >> ~/.bashrc && source ~/.bashrc

rm -rf singularity/
export VERSION=3.7.0 && wget https://github.com/hpcng/singularity/releases/download/v${VERSION}/singularity-${VERSION}.tar.gz && tar -xzf singularity-${VERSION}.tar.gz && cd singularity

./mconfig && make -C builddir && sudo make -C builddir install
