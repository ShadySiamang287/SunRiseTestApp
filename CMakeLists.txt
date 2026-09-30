cmake_minimum_required(VERSION 3.28)
project(GameApp LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(FetchContent)

find_program(SLANGC_EXECUTABLE slangc REQUIRED)

function (add_slang_shader_target TARGET)

    cmake_parse_arguments(
        SHADER
        ""
        ""
        "SHADERS;COMMON_SOURCES"
        ${ARGN}
    )

    set(SHADERS_DIR "${CMAKE_BINARY_DIR}/shaders")

    file(MAKE_DIRECTORY "${SHADERS_DIR}")

    set(SHADER_OUTPUTS "")

    foreach(shader IN LISTS SHADER_SHADERS)

        # Format:
        # file.slang|entryPoint

        string(REPLACE "|" ";" shader_info "${shader}")

        list(GET shader_info 0 source)
        list(GET shader_info 1 entry)

        set(output "${SHADERS_DIR}/${entry}.spv")

        add_custom_command(
            OUTPUT "${output}"

            COMMAND
                ${SLANGC_EXECUTABLE}
                "${source}"
                -target spirv
                -profile spirv_1_6
                -emit-spirv-directly
                -fvk-use-entrypoint-name
                -entry "${entry}"
                -o "${output}"

            DEPENDS
                "${source}"
                ${SHADER_COMMON_SOURCES}

            COMMENT "Compiling Slang shader: ${entry}"
            VERBATIM
        )

        list(APPEND SHADER_OUTPUTS "${output}")

    endforeach()

    add_custom_target(
        ${TARGET}
        DEPENDS ${SHADER_OUTPUTS}
    )

endfunction()

FetchContent_Declare(SunriseEngine
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../Engine
)
FetchContent_MakeAvailable(SunriseEngine)

find_package(Vulkan REQUIRED)

set(SOURCES 
    src/GameApp.cpp
    src/MainScene.cpp
    src/FlyCamera.cpp
)

set(HEADERS 
    include/GameLayer.h
)

set(SHADER_SLANG_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/shaders/GBuffer.slang
    ${CMAKE_CURRENT_SOURCE_DIR}/shaders/vertex.slang
    ${CMAKE_CURRENT_SOURCE_DIR}/shaders/lightingVert.slang
    ${CMAKE_CURRENT_SOURCE_DIR}/shaders/lightingFrag.slang
    ${CMAKE_CURRENT_SOURCE_DIR}/shaders/ToneMapping.slang
)

add_executable(GameApp
    ${SOURCES}
    ${HEADERS}
)

add_custom_command(
    TARGET GameApp
    POST_BUILD

    COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${CMAKE_CURRENT_SOURCE_DIR}/assets"
        "$<TARGET_FILE_DIR:GameApp>/assets"

    COMMENT "Copying assets to output directory"
)

target_link_libraries(GameApp PUBLIC SunriseEngine Vulkan::Headers)
target_include_directories(GameApp PUBLIC ${PROJECT_SOURCE_DIR}/include)
add_slang_shader_target(shaders
    SHADERS
        "${CMAKE_CURRENT_SOURCE_DIR}/shaders/GBuffer.slang|gBufferFrag"
        "${CMAKE_CURRENT_SOURCE_DIR}/shaders/vertex.slang|vertMain"
        "${CMAKE_CURRENT_SOURCE_DIR}/shaders/lightingVert.slang|lightVert"
        "${CMAKE_CURRENT_SOURCE_DIR}/shaders/lightingFrag.slang|lightFrag"
        "${CMAKE_CURRENT_SOURCE_DIR}/shaders/ToneMapping.slang|toneMappingFrag"
        "${CMAKE_CURRENT_SOURCE_DIR}/shaders/bloom.slang|bloom"
        "${CMAKE_CURRENT_SOURCE_DIR}/shaders/FXAA.slang|FXAA"

    COMMON_SOURCES
        "${CMAKE_CURRENT_SOURCE_DIR}/shaders/common.slang"
)
add_dependencies(GameApp shaders)
