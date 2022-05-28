#!/bin/bash

#https://docs.ipfs.io/install/ipfs-desktop/#ubuntu
#https://github.com/ipfs/ipfs-desktop#linuxfreebsd

set -xeu

#sudo apt install hicolor-icon-theme mime-support
#
#wget --no-clobber https://github.com/ipfs-shipyard/ipfs-desktop/releases/download/v0.20.6/ipfs-desktop-0.20.6-linux-amd64.deb
#
#sudo dpkg -i ipfs-desktop-0.20.6-linux-amd64.deb


##sudo apt install nodejs npm
apt-get install nodejs yarn npm

nodejs --version

npm i -D @types/node

npm install -g node-gyp

