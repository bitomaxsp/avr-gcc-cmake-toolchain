# AVR GCC toolchain file for avr-gcc

## How to use it in your project

If you do not have cmake folder yet in your project structure use the following command to add one as a submodule:

```
  git submodule add git@github.com:bitomaxsp/avr-gcc-cmake-toolchain.git ./cmake
```

Now cmake folder contains all required files.

## How to use toolchain file

It is implied that you already have avr-gcc install on you machine. If it is not, do it now.

If you already have avr-gcc installed then just create *CMakeLists.txt* file in the root folder of your project
and look at the example code how to fill it in.
