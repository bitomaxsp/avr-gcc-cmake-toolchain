option(MCU_TYPE_FOR_FILENAME "Set MCU type in file name" NO)

if (NOT ((CMAKE_BUILD_TYPE MATCHES Release) OR
         (CMAKE_BUILD_TYPE MATCHES RelWithDebInfo) OR
         (CMAKE_BUILD_TYPE MATCHES Debug) OR
         (CMAKE_BUILD_TYPE MATCHES MinSizeRel)))
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose cmake build type: Debug Release" FORCE)
endif()

# set (CMAKE_CXX_STANDARD_REQUIRED 17)

#Get CPU frequency
message(CHECK_START "Looking for defined F_CPU frequency")
if (NOT F_CPU)
  file(READ ${CMAKE_SOURCE_DIR}/fcpu.txt F_CPU_READ 0)
  if (NOT F_CPU_READ)
    message(FATAL_ERROR "fcpu.txt seems to be empty. Put CPU frequency in Mhz on the first line")
  endif()

  string(STRIP ${F_CPU_READ} F_CPU_READ)

  if (NOT F_CPU_READ)
    message(CHECK_FAIL "Not found F_CPU")
    message(FATAL_ERROR "F_CPU must be defined")
  else()
    message(CHECK_PASS "Found in file, F_CPU: ${F_CPU_READ}")
    set(F_CPU ${F_CPU_READ} CACHE STRING "Set F_CPU value")
  endif()

else()
  message(CHECK_PASS "Found F_CPU as define: ${F_CPU}")
  set(F_CPU ${F_CPU} CACHE STRING "Set F_CPU value")
endif()

# Get MCU
message(CHECK_START "Looking for defined M_MCU for mcu type")
if(NOT M_MCU)
  file(READ ${CMAKE_SOURCE_DIR}/mmcu.txt M_MCU_READ 0)
  if (NOT M_MCU_READ)
    message(FATAL_ERROR "mmcu.txt seems to be empty. Put CPU type on the first line. (see 'avr-gcc --target-help' for valid values)")
  endif()

  string(STRIP ${M_MCU_READ} M_MCU_READ)

  if (NOT M_MCU_READ)
    message(CHECK_FAIL "Not found mcu type")
    message(FATAL_ERROR "CPU must be defined")
  else()
    message(CHECK_PASS "Found in file, M_MCU: ${M_MCU_READ}")
    set(M_MCU ${M_MCU_READ} CACHE STRING "Set default MCU: ${M_MCU_READ}")
  endif()

else()
  message(CHECK_PASS "Found M_MCU as define: ${M_MCU}")
  set(M_MCU ${M_MCU} CACHE STRING "Set default MCU: ${M_MCU} (see 'avr-gcc --target-help' for valid values)")
endif()

# image suffix if needed
set(MCU_FILENAME_SUFFIX "")
if (MCU_TYPE_FOR_FILENAME)
  set(MCU_FILENAME_SUFFIX ${M_MCU})
endif()

#default avr-size args
if(NOT AVR_SIZE_ARGS)
    if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL Darwin)
        set(AVR_SIZE_ARGS -A)
    else()
        set(AVR_SIZE_ARGS -C;--mcu=${M_MCU})
    endif()
endif()


# prepare base flags for upload tool
set(AVRDUDE_COMMON_OPTIONS -v -e -p ${M_MCU} -c ${AVRDUDE_PROGRAMMER})

add_definitions(-DF_CPU=${F_CPU}UL)

# -mmcu=${M_MCU}
set(COMMON_BUILD_FLAGS "-ffunction-sections -fno-common -fdata-sections -Wno-error=narrowing -flto")

# C flags regardless of build type
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=c99 ${COMMON_BUILD_FLAGS}")
# C++ flags regardless of build type
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17 ${COMMON_BUILD_FLAGS}")

set(CMAKE_C_FLAGS_RELEASE "-Os -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE "-Os -DNDEBUG")

##########################################################################
# add_avr_executable
# - In var: EXECUTABLE_NAME
##########################################################################
function(add_avr_executable EXECUTABLE_NAME)

  if(NOT ARGN)
    message(FATAL_ERROR "No source files given for ${EXECUTABLE_NAME}.")
  endif()

  # set file names
  set(elf_file ${EXECUTABLE_NAME}${MCU_FILENAME_SUFFIX}.elf)
  set(hex_file ${EXECUTABLE_NAME}${MCU_FILENAME_SUFFIX}.hex)
  set(lst_file ${EXECUTABLE_NAME}${MCU_FILENAME_SUFFIX}.lst)
  set(map_file ${EXECUTABLE_NAME}${MCU_FILENAME_SUFFIX}.map)
  set(eeprom_image ${EXECUTABLE_NAME}${MCU_FILENAME_SUFFIX}-eeprom.hex)

  # elf file
  add_executable(${elf_file} EXCLUDE_FROM_ALL ${ARGN})

  target_compile_options(${elf_file} PUBLIC -mmcu=${M_MCU})
  target_link_options(${elf_file} PUBLIC -mmcu=${M_MCU} -fuse-linker-plugin -Wl,--gc-sections -mrelax -Wl,-Map,${map_file})

  add_custom_command(OUTPUT ${hex_file}
    COMMAND ${AVR_OBJCOPY} -j .text -j .data -O ihex ${elf_file} ${hex_file}
    COMMAND ${AVR_SIZE_TOOL} ${AVR_SIZE_ARGS} ${elf_file}
    DEPENDS ${elf_file}
  )

  add_custom_command(OUTPUT ${lst_file}
    COMMAND ${AVR_OBJDUMP} -d ${elf_file} > ${lst_file}
    DEPENDS ${elf_file}
  )

  # eeprom
  add_custom_command(OUTPUT ${eeprom_image}
    COMMAND ${AVR_OBJCOPY} -j .eeprom --set-section-flags=.eeprom=alloc,load
          --change-section-lma .eeprom=0 --no-change-warnings -O ihex ${elf_file} ${eeprom_image}
    DEPENDS ${elf_file}
  )

  add_custom_target(${EXECUTABLE_NAME}
    ALL
    DEPENDS ${hex_file} ${lst_file} ${eeprom_image}
  )

  # clean
  set_directory_properties(PROPERTIES ADDITIONAL_CLEAN_FILES "${map_file}")

  # upload - with avrdude
  add_custom_target(uploadu
    ${AVR_DUDE} ${AVRDUDE_COMMON_OPTIONS} ${AVRDUDE_OPTIONS} -U flash:w:${hex_file} -P ${AVRDUDE_PORT}
    DEPENDS ${hex_file}
    COMMENT "Uploading ${hex_file} to ${${M_MCU}} using ${AVRDUDE_PROGRAMMER}"
  )

  # upload eeprom only - with avrdude
  # see also bug http://savannah.nongnu.org/bugs/?40142
  add_custom_target(upload_eeprom
    ${AVR_DUDE} ${AVRDUDE_COMMON_OPTIONS} ${AVRDUDE_OPTIONS} -U eeprom:w:${eeprom_image} -P ${AVRDUDE_PORT}
    DEPENDS ${eeprom_image}
    COMMENT "Uploading ${eeprom_image} to ${${M_MCU}} using ${AVRDUDE_PROGRAMMER}"
  )

  add_custom_target(fuse
    ${AVR_DUDE} ${AVRDUDE_COMMON_OPTIONS} ${AVRDUDE_OPTIONS} -P ${AVRDUDE_PORT}
    DEPENDS ${hex_file}
    COMMENT "Uploading ${hex_file} to ${${M_MCU}} using ${AVRDUDE_PROGRAMMER}"
  )

  # disassemble
  add_custom_target(disassemble
    ${AVR_OBJDUMP} -h -S ${elf_file} > ${EXECUTABLE_NAME}.lst
    DEPENDS ${elf_file}
  )
endfunction()
