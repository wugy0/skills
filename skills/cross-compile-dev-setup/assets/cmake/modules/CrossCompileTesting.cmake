# Cross-compile testing support (project-agnostic template).
#
# Provides:
#   cross_test_setup_gtest()      - fetch & build GoogleTest with the cross toolchain
#   cross_test_add(<name> ...)    - register a test, wire CTest + qemu, emit run script
#   cross_test_generate_runner()  - emit an aggregate run-tests.sh
#
# Tests run under CMAKE_CROSSCOMPILING_EMULATOR (set by the toolchain file to
# qemu-user), so `ctest` and the generated scripts both execute ARM binaries on
# the host. Replace the `<PROJECT>_*` names with your project's prefix.

include_guard(GLOBAL)

function(cross_test_setup_gtest)
    include(FetchContent)
    FetchContent_Declare(googletest
        GIT_REPOSITORY https://github.com/google/googletest.git
        GIT_TAG v1.14.0
        GIT_SHALLOW TRUE
    )
    set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(googletest)
endfunction()

# Generate build/run-<name>.sh that runs one test binary under the emulator.
function(_cross_test_generate_script name)
    if(CMAKE_CROSSCOMPILING_EMULATOR)
        string(REPLACE ";" " " _emu "${CMAKE_CROSSCOMPILING_EMULATOR}")
        set(_cmd "${_emu} $<TARGET_FILE:${name}>")
    else()
        set(_cmd "$<TARGET_FILE:${name}>")
    endif()
    file(GENERATE
        OUTPUT "${CMAKE_BINARY_DIR}/run-${name}.sh"
        CONTENT "#!/bin/sh\nset -e\nexec ${_cmd} \"$@\"\n"
    )
endfunction()

# cross_test_add(<name> <source>... [LINK <lib>...] [STANDARD <cxx_std_NN>])
#
# Builds a GoogleTest executable, registers it with CTest, generates a
# run-<name>.sh script, and records the name for the aggregate runner.
# GoogleTest 1.14 needs C++14; pass STANDARD to override per test.
function(cross_test_add name)
    cmake_parse_arguments(PARSE_ARGV 1 _arg "" "STANDARD" "LINK")
    if(NOT _arg_STANDARD)
        set(_arg_STANDARD cxx_std_14)
    endif()
    add_executable(${name} ${_arg_UNPARSED_ARGUMENTS})
    target_link_libraries(${name} PRIVATE GTest::gtest_main ${_arg_LINK})
    target_compile_features(${name} PRIVATE ${_arg_STANDARD})
    add_test(NAME ${name} COMMAND ${name})
    _cross_test_generate_script(${name})
    set_property(GLOBAL APPEND PROPERTY CROSS_TESTS ${name})
endfunction()

# Generate build/run-tests.sh that runs every registered test script in order.
function(cross_test_generate_runner)
    get_property(_tests GLOBAL PROPERTY CROSS_TESTS)
    if(NOT _tests)
        return()
    endif()
    set(_content "#!/bin/sh\nset -e\ncd \"$(dirname \"$0\")\"\n")
    foreach(_test IN LISTS _tests)
        string(APPEND _content "echo \"==> ${_test}\"\n./run-${_test}.sh \"$@\"\n")
    endforeach()
    file(GENERATE OUTPUT "${CMAKE_BINARY_DIR}/run-tests.sh" CONTENT "${_content}")
endfunction()
