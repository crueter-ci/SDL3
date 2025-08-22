set(SHARED_SUFFIX so)
set(STATIC_SUFFIX a)

set(SDL2_LIB_DIR ${CMAKE_CURRENT_LIST_DIR}/lib)
set(SDL2_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/include/SDL2)

# Change to match imported library names
if (BUILD_SHARED_LIBS)
    add_library(SDL2 SHARED IMPORTED)
    set_target_properties(SDL2 PROPERTIES
        IMPORTED_LOCATION ${SDL2_LIB_DIR}/libSDL2.${SHARED_SUFFIX}
        INTERFACE_INCLUDE_DIRECTORIES ${SDL2_INCLUDE_DIR}
    )
else()
    add_library(SDL2 STATIC IMPORTED)
    set_target_properties(SDL2 PROPERTIES
        IMPORTED_LOCATION ${SDL2_LIB_DIR}/libSDL2.${STATIC_SUFFIX}
        INTERFACE_INCLUDE_DIRECTORIES ${SDL2_INCLUDE_DIR}
    )
endif()

add_library(SDL2::SDL2 ALIAS SDL2)

if (CMAKE_SYSTEM_NAME MATCHES ".*FreeBSD.*")
    target_link_libraries(SDL2 PRIVATE usbhid inotify)
endif()

function(link_sdl2)
    foreach(TARGET ${ARGN})
        if (TARGET ${TARGET})
            target_link_libraries(${TARGET} PUBLIC SDL2)
        endif()
    endforeach()
endfunction()
