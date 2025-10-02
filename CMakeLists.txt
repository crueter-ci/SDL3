cmake_minimum_required(VERSION 3.10)

# Change for find_package if necessary
set(SDL2_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}")

set(SDL2_LIB_DIR ${CMAKE_CURRENT_LIST_DIR}/lib)
set(SDL2_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/include/SDL2)

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

    add_library(SDL2 ${LIB_TYPE} IMPORTED GLOBAL)
    set_target_properties(SDL2 PROPERTIES
        IMPORTED_LOCATION ${SDL2_LIB_DIR}/libSDL2.${LIB_SUFFIX}
        INTERFACE_INCLUDE_DIRECTORIES ${SDL2_INCLUDE_DIR}
    )
else()
    if (BUILD_SHARED_LIBS)
        add_library(SDL2 SHARED IMPORTED GLOBAL)
        set_target_properties(SDL2 PROPERTIES
            IMPORTED_LOCATION ${SDL2_LIB_DIR}/libSDL2.dll
            IMPORTED_IMPLIB ${SDL2_LIB_DIR}/libSDL2.lib
            INTERFACE_INCLUDE_DIRECTORIES ${SDL2_INCLUDE_DIR}
        )
    else()
        add_library(SDL2 STATIC IMPORTED GLOBAL)
        set_target_properties(SDL2 PROPERTIES IMPORTED_LOCATION
                              ${SDL2_LIB_DIR}/libSDL2_static.lib
                              INTERFACE_INCLUDE_DIRECTORIES ${SDL2_INCLUDE_DIR}
                              INTERFACE_LINK_LIBRARIES
                              "\$<LINK_ONLY:kernel32>;\$<LINK_ONLY:user32>;\$<LINK_ONLY:gdi32>;\$<LINK_ONLY:winmm>;\$<LINK_ONLY:imm32>;\$<LINK_ONLY:ole32>;\$<LINK_ONLY:oleaut32>;\$<LINK_ONLY:version>;\$<LINK_ONLY:uuid>;\$<LINK_ONLY:advapi32>;\$<LINK_ONLY:setupapi>;\$<LINK_ONLY:shell32>;\$<LINK_ONLY:dinput8>;\$<LINK_ONLY:>")
    endif()
endif()

add_library(SDL2::SDL2 ALIAS SDL2)

if (CMAKE_SYSTEM_NAME MATCHES ".*FreeBSD.*")
    target_link_libraries(SDL2 INTERFACE usbhid inotify)
endif()