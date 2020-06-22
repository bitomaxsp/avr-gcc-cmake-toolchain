
# spcify the following cmake argument -DCMAKE_TOOLCHAIN_FILE=<path to this file>


set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR avr)

find_program(AVR_CC avr-gcc REQUIRED)
find_program(AVR_CXX avr-g++ REQUIRED)
find_program(AVR_OBJCOPY avr-objcopy REQUIRED)
find_program(AVR_SIZE_TOOL avr-size REQUIRED)
find_program(AVR_OBJDUMP avr-objdump REQUIRED)
find_program(AVR_DUDE avrdude REQUIRED)

set(CMAKE_C_COMPILER ${AVR_CC})
set(CMAKE_CXX_COMPILER ${AVR_CXX})

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(AVR 1)

# Programmer section

if(NOT AVRDUDE_PORT)
  set(AVRDUDE_PORT usb CACHE STRING "Set default avrdude upload port: usb")
endif()

# default programmer
if(NOT AVRDUDE_PROGRAMMER)
  set(AVRDUDE_PROGRAMMER usbtiny CACHE STRING "Set default programmer model: usbtiny")
endif()

set(CMAKE_C_FLAGS_DEBUG_INIT "-O0 -DDEBUG")
set(CMAKE_CXX_FLAGS_DEBUG_INIT "-O0 -DDEBUG")
set(CMAKE_C_FLAGS_RELEASE_INIT "-Os -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE_INIT "-Os -DNDEBUG")
