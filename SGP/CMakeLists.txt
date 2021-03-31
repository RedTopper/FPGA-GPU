cmake_minimum_required(VERSION 3.10)
project(sgp)

set(CMAKE_CXX_STANDARD 11)

include_directories(${CMAKE_CURRENT_LIST_DIR}/utils/include)
include_directories(${CMAKE_CURRENT_LIST_DIR}/sw/src/shared/ogldir1)
include_directories(${CMAKE_CURRENT_LIST_DIR}/sw/src/shared/ogldir2)

set(BASE
        ${CMAKE_CURRENT_LIST_DIR}/sw/src/shared/ogldir1/shader.cpp)

set(LIB_SIMPLE_GLU
        ${CMAKE_CURRENT_LIST_DIR}/utils/src/libsimpleGLU/simpleGLU.c)

set(LINK_LIBS opengl32 glew32 glfw3)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/sw/bin)

# Note: Set each project's working directory to sw/bin
#       (sub programs access assets in ../common)
add_subdirectory(sw/src/MP-1/00_CustomTest)
add_subdirectory(sw/src/MP-1/01_ClearTest)
add_subdirectory(sw/src/MP-1/02_TheRedPixel)
add_subdirectory(sw/src/MP-1/03_Sierpinski)
add_subdirectory(sw/src/MP-1/04_Fractals)
add_subdirectory(sw/src/MP-1/05_Fern)
add_subdirectory(sw/src/MP-1/06_ViewPorting)
add_subdirectory(sw/src/MP-2/01_TheRedTriangle)
add_subdirectory(sw/src/MP-2/02_snowflake)
add_subdirectory(sw/src/MP-2/03_rand_triangles)
add_subdirectory(sw/src/MP-2/04_colorwheel)
add_subdirectory(sw/src/MP-2/05_tripaint)
add_subdirectory(sw/src/MP-2/06_voronoi)
add_subdirectory(sw/src/MP-3/01_shapeshifter)
add_subdirectory(sw/src/MP-3/02_cubeflyby)
add_subdirectory(sw/src/MP-3/03_flexseal)
add_subdirectory(sw/src/MP-4/01_intersect)
