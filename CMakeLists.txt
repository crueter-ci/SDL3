cmake_minimum_required(VERSION 3.10)

# Change for find_package if necessary
set(SDL3_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}")

set(SDL3_LIB_DIR ${CMAKE_CURRENT_LIST_DIR}/lib)
set(SDL3_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/include/SDL3)

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
    )
else()
    if (BUILD_SHARED_LIBS)
        add_library(SDL3 SHARED IMPORTED GLOBAL)
        set_target_properties(SDL3 PROPERTIES
            IMPORTED_LOCATION ${SDL3_LIB_DIR}/libSDL3.dll
            IMPORTED_IMPLIB ${SDL3_LIB_DIR}/libSDL3.lib
        )
    else()
        add_library(SDL3 STATIC IMPORTED GLOBAL)
        set_target_properties(SDL3 PROPERTIES IMPORTED_LOCATION
                              ${SDL3_LIB_DIR}/libSDL3_static.lib
                              INTERFACE_LINK_LIBRARIES
                              "\$<LINK_ONLY:kernel32>;\$<LINK_ONLY:user32>;\$<LINK_ONLY:gdi32>;\$<LINK_ONLY:winmm>;\$<LINK_ONLY:imm32>;\$<LINK_ONLY:ole32>;\$<LINK_ONLY:oleaut32>;\$<LINK_ONLY:version>;\$<LINK_ONLY:uuid>;\$<LINK_ONLY:advapi32>;\$<LINK_ONLY:setupapi>;\$<LINK_ONLY:shell32>;\$<LINK_ONLY:dinput8>;\$<LINK_ONLY:>")
    endif()
endif()

set_target_properties(SDL3 PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES ${SDL3_INCLUDE_DIR}
)

add_library(SDL3::SDL3 ALIAS SDL3)

if (CMAKE_SYSTEM_NAME MATCHES ".*FreeBSD.*")
    target_link_libraries(SDL3 INTERFACE usbhid inotify)
endif()