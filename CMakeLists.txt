cmake_minimum_required(VERSION 3.10)

# Change for find_package if necessary
set(SDL3_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}")

set(SDL3_LIB_DIR ${CMAKE_CURRENT_LIST_DIR}/lib)
set(SDL3_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/include)

if (UNIX)
    if (APPLE)
        set(SHARED_SUFFIX dylib)
    else()
        set(SHARED_SUFFIX so)
    endif()

    if (BUILD_SHARED_LIBS)
        set(LIB_TYPE SHARED)
        set(LIB_SUFFIX ${SHARED_SUFFIX})
    else()
        set(LIB_TYPE STATIC)
        set(LIB_SUFFIX a)
    endif()

    add_library(SDL3 ${LIB_TYPE} IMPORTED GLOBAL)
    set_target_properties(SDL3 PROPERTIES
        IMPORTED_LOCATION ${SDL3_LIB_DIR}/libSDL3.${LIB_SUFFIX}
        INTERFACE_INCLUDE_DIRECTORIES ${SDL3_INCLUDE_DIR})
else()
    if (BUILD_SHARED_LIBS)
        add_library(SDL3 SHARED IMPORTED GLOBAL)
        set_target_properties(SDL3 PROPERTIES
            IMPORTED_LOCATION ${SDL3_LIB_DIR}/libSDL3.dll
            IMPORTED_IMPLIB ${SDL3_LIB_DIR}/libSDL3.lib
            INTERFACE_INCLUDE_DIRECTORIES ${SDL3_INCLUDE_DIR})
    else()
        add_library(SDL3 STATIC IMPORTED GLOBAL)
        set_target_properties(SDL3 PROPERTIES IMPORTED_LOCATION
            ${SDL3_LIB_DIR}/libSDL3_static.lib
            INTERFACE_INCLUDE_DIRECTORIES ${SDL3_INCLUDE_DIR}
            INTERFACE_LINK_LIBRARIES
            "$<LINK_ONLY:kernel32;user32;gdi32;winmm;imm32;ole32;oleaut32;version;uuid;advapi32;setupapi;shell32;dinput8;hid>")
    endif()
endif()

if (APPLE)
    foreach(FRAMEWORK AVFoundation AudioToolbox CoreAudio CoreHaptics
        CoreMedia CoreVideo ForceFeedback GameController QuartzCore)
        find_library(${FRAMEWORK}_LIBRARY ${FRAMEWORK})
        target_link_libraries(SDL3 INTERFACE ${${FRAMEWORK}_LIBRARY})
    endforeacH()
endif()

add_library(SDL3::SDL3 ALIAS SDL3)

if (CMAKE_SYSTEM_NAME MATCHES ".*FreeBSD.*")
    target_link_libraries(SDL3 INTERFACE usbhid inotify)
endif()
