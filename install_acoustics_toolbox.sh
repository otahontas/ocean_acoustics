#!/bin/bash
set -e

if [ ! -d "at" ]; then
    echo "Downloading Acoustics Toolbox..."
    wget -O at.zip http://oalib.hlsresearch.com/AcousticsToolbox/at_2024_12_25.zip || {
        echo "Error: Failed to download Acoustics Toolbox"
        exit 1
    }

    echo "Unzipping..."
    unzip at.zip || {
        echo "Error: Failed to unzip at.zip"
        exit 1
    }

    rm -rf at.zip __MACOSX
    echo "Download complete"
else
    echo "at/ folder already exists, skipping download"
fi

echo "Building Acoustics Toolbox..."
cd at/ || {
    echo "Error: at/ directory not found"
    exit 1
}

mkdir -p bin || {
    echo "Error: Failed to create bin directory"
    exit 1
}

make clean || {
    echo "Error: make clean failed"
    exit 1
}

make all || {
    echo "Error: make all failed"
    exit 1
}

make install || {
    echo "Error: make install failed"
    exit 1
}

echo "Installation complete"
