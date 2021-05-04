project(sgpHaxagonDriver)

set(CMAKE_CXX_STANDARD 17)
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/SGP-Driver/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/Super-Haxagon/include")

set(SOURCE_FILES
        Main.cpp
        SGP-Driver/source/AudioLoaderSGP.cpp
        SGP-Driver/source/AudioPlayerSGP.cpp
        SGP-Driver/source/FontSGP.cpp
        SGP-Driver/source/PlatformSGP.cpp
        SGP-Driver/source/RenderTarget.cpp)

add_library(${PROJECT_NAME} STATIC ${SOURCE_FILES})
