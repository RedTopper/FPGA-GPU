project(ogldir1)

set(SOURCE_FILES
        controls.cpp
        objloader.cpp
        quaternion_utils.cpp
        shader.cpp
        tangentspace.cpp
        text2D.cpp
        texture.cpp
        vboindexer.cpp)

add_library(${PROJECT_NAME} STATIC ${SOURCE_FILES})
