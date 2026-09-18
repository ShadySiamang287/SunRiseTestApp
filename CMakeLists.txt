cmake_minimum_required(VERSION 3.28)
project(GameApp LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(FetchContent)

find_program(SLANGC_EXECUTABLE slangc REQUIRED)

function (add_slang_shader_target TARGET)
  cmake_parse_arguments ("SHADER" "" "" "SOURCES;ENTRY_POINTS;COMMON_SOURCES" ${ARGN})

  if (NOT SHADER_ENTRY_POINTS)
    set (SHADER_ENTRY_POINTS vertMain fragMain)
  endif()

  set (ENTRY_FLAGS "")
  foreach (entry ${SHADER_ENTRY_POINTS})
    list (APPEND ENTRY_FLAGS -entry ${entry})
  endforeach()

  set (SHADERS_DIR ${CMAKE_BINARY_DIR}/shaders)
  add_custom_command (
          OUTPUT ${SHADERS_DIR}
          COMMAND ${CMAKE_COMMAND} -E make_directory ${SHADERS_DIR}
  )
  add_custom_command (
          OUTPUT  ${SHADERS_DIR}/slang.spv
          COMMAND ${SLANGC_EXECUTABLE} ${SHADER_SOURCES} -target spirv -profile spirv_1_6 -emit-spirv-directly -fvk-use-entrypoint-name ${ENTRY_FLAGS} -o slang.spv
          WORKING_DIRECTORY ${SHADERS_DIR}
          DEPENDS ${SHADERS_DIR} ${SHADER_SOURCES} ${SHADER_COMMON_SOURCES}
          COMMENT "Compiling Slang Shaders"
          VERBATIM
  )
  add_custom_target (${TARGET} DEPENDS ${SHADERS_DIR}/slang.spv)
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
)

add_executable(GameApp
    ${SOURCES}
    ${HEADERS}
)
target_link_libraries(GameApp PUBLIC SunriseEngine Vulkan::Headers)
target_include_directories(GameApp PUBLIC ${PROJECT_SOURCE_DIR}/include)
add_slang_shader_target( Shaders 
    SOURCES ${SHADER_SLANG_SOURCES}
    ENTRY_POINTS gBufferFrag vertMain lightVert lightFrag
    COMMON_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/shaders/common.slang
)
add_dependencies(GameApp Shaders)
