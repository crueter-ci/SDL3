set(SDL2_LIB_DIR ${CMAKE_CURRENT_LIST_DIR}/lib)
set(SDL2_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/include/SDL2)

# Change to match imported library names
if (BUILD_SHARED_LIBS)
    add_library(SDL2 SHARED IMPORTED GLOBAL)
    set_target_properties(SDL2 PROPERTIES
        IMPORTED_LOCATION ${SDL2_LIB_DIR}/libSDL2.dll
        IMPORTED_IMPLIB ${SDL2_LIB_DIR}/libSDL2.lib
        INTERFACE_INCLUDE_DIRECTORIES ${SDL2_INCLUDE_DIR}
    )
else()
    add_library(SDL2 STATIC IMPORTED GLOBAL)
    set_target_properties(SDL2 PROPERTIES
        IMPORTED_LOCATION ${SDL2_LIB_DIR}/libSDL2_static.lib
        INTERFACE_INCLUDE_DIRECTORIES ${SDL2_INCLUDE_DIR}
        INTERFACE_LINK_LIBRARIES "\$<LINK_ONLY:kernel32>;\$<LINK_ONLY:user32>;\$<LINK_ONLY:gdi32>;\$<LINK_ONLY:winmm>;\$<LINK_ONLY:imm32>;\$<LINK_ONLY:ole32>;\$<LINK_ONLY:oleaut32>;\$<LINK_ONLY:version>;\$<LINK_ONLY:uuid>;\$<LINK_ONLY:advapi32>;\$<LINK_ONLY:setupapi>;\$<LINK_ONLY:shell32>;\$<LINK_ONLY:dinput8>;\$<LINK_ONLY:>"
    )
endif()

add_library(SDL2::SDL2 ALIAS SDL2)

function(link_sdl2)
    foreach(TARGET ${ARGN})
        if (TARGET ${TARGET})
            target_link_libraries(${TARGET} PUBLIC SDL2)
        endif()
    endforeach()
endfunction()
