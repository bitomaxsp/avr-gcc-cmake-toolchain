#!/bin/bash

set -ev

F_CPU=${F_CPU:-16000000}
M_MCU=${M_MCU:-atmega328}
BUILD_FOLDER=${BUILD_FOLDER:-./.build}

cmake -B $BUILD_FOLDER -DF_CPU=$F_CPU -DM_MCU=$M_MCU -DCMAKE_TOOLCHAIN_FILE=./cmake/avr-gcc-toolchain.cmake .
cmake --build $BUILD_FOLDER
