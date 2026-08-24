cmake_minimum_required(VERSION 3.10)

# Change for find_package if necessary
set(SDL3_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}")

set(SDL3_LIB_DIR ${CMAKE_CURRENT_LIST_DIR}/lib)
set(SDL3_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/include)

add_library(SDL3 STATIC IMPORTED)
set_target_properties(SDL3 PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES ${SDL3_INCLUDE_DIR})

if (UNIX)
    set_target_properties(SDL3 PROPERTIES
        IMPORTED_LOCATION ${SDL3_LIB_DIR}/libSDL3.a)
else()
    set_target_properties(SDL3 PROPERTIES IMPORTED_LOCATION
        ${SDL3_LIB_DIR}/libSDL3_static.lib
        INTERFACE_LINK_LIBRARIES
        "$<LINK_ONLY:kernel32;user32;gdi32;winmm;imm32;ole32;oleaut32;version;uuid;advapi32;setupapi;shell32;dinput8;hid>")
endif()

if (APPLE)
    foreach(FRAMEWORK AVFoundation AudioToolbox CoreAudio CoreHaptics
        CoreMedia CoreVideo ForceFeedback GameController QuartzCore)
        find_library(${FRAMEWORK}_LIBRARY ${FRAMEWORK})
        target_link_libraries(SDL3 INTERFACE ${${FRAMEWORK}_LIBRARY})
    endforeacH()
endif()

add_library(SDL3::SDL3 ALIAS SDL3)
