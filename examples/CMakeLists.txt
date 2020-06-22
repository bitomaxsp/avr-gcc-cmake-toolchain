cmake_minimum_required(VERSION 3.15)

project(MyProjectName C CXX)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake)

include(cmake/build_options.cmake)

add_avr_executable(main main.cc)
