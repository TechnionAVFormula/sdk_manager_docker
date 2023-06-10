#!/bin/bash

# Create directory and navigate into it
mkdir -p /tmp/protobuf
cd /tmp/protobuf

# Download protobuf
curl -o google-protobuf.tar.gz -LJO https://github.com/google/protobuf/tarball/v3.8.0

# Extract protobuf
tar -xzvf google-protobuf.tar.gz

# Move into extracted protobuf directory
cd protocolbuffers*

# Run the protobuf setup scripts
./autogen.sh
./configure --prefix=/usr/ CXXFLAGS=-fPIC

# Compile protobuf
make

# Install protobuf
sudo make install

# Clean up
rm -rf /tmp/protobuf/*

# Navigate back to the home directory
cd ~/
