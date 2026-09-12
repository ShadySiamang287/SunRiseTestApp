cmake_minimum_required(VERSION 3.28)
project(GameApp LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

include(FetchContent)

FetchContent_Declare(SunriseEngine
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../Engine
)
FetchContent_MakeAvailable(SunriseEngine)

set(SOURCES 
    src/GameApp.cpp
)

set(HEADERS 

)

add_executable(GameApp
    ${SOURCES}
    ${HEADERS}
)
target_link_libraries(GameApp PUBLIC SunriseEngine)
target_include_directories(GameApp PUBLIC ${PROJECT_SOURCE_DIR}/include)