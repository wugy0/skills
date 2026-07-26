# Developer tooling: compile_commands.json symlink + .clangd generation
# (project-agnostic template). Gated behind DEV_TOOLING so production builds
# skip it. Expects the toolchain file to export CROSS_CLANG_TARGET_TRIPLE,
# CROSS_TARGET_ROOTFS, and CROSS_COMPILER cache variables.

include_guard(GLOBAL)

# dev_tooling_enable()
#
# Creates a root compile_commands.json symlink (refreshed every build) and
# generates a .clangd config tuned for the cross compiler.
function(dev_tooling_enable)
    if(NOT DEV_TOOLING)
        return()
    endif()

    if(CMAKE_EXPORT_COMPILE_COMMANDS)
        add_custom_target(dev_tooling_compile_commands_link ALL
            COMMAND ${CMAKE_COMMAND} -E create_symlink
                "${CMAKE_BINARY_DIR}/compile_commands.json"
                "${CMAKE_SOURCE_DIR}/compile_commands.json"
            VERBATIM
        )
    endif()

    find_package(Python3 COMPONENTS Interpreter QUIET)
    if(NOT Python3_FOUND)
        message(STATUS "python3 not found; skipping .clangd generation")
        return()
    endif()

    set(_compiler "${CROSS_COMPILER}")
    if(_compiler STREQUAL "")
        set(_compiler "${CMAKE_CXX_COMPILER}")
    endif()

    if(NOT CROSS_TARGET_ROOTFS OR NOT CROSS_CLANG_TARGET_TRIPLE)
        message(STATUS "cross target metadata unavailable; skipping .clangd generation")
        return()
    endif()

    execute_process(
        COMMAND ${Python3_EXECUTABLE}
            "${CMAKE_CURRENT_SOURCE_DIR}/cmake/scripts/gen_clangd.py"
            --compiler "${_compiler}"
            --compile-commands-dir "${CMAKE_SOURCE_DIR}"
            --output "${CMAKE_SOURCE_DIR}/.clangd"
            --target-triple "${CROSS_CLANG_TARGET_TRIPLE}"
            --sysroot "${CROSS_TARGET_ROOTFS}"
        RESULT_VARIABLE _rv
    )
    if(NOT _rv EQUAL 0)
        message(WARNING ".clangd generation failed (exit ${_rv})")
    endif()
endfunction()
