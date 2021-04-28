cmake_minimum_required(VERSION 3.10)
project(SGP DESCRIPTION "cpre480 Simple Graphics Processor")

set(CMAKE_CXX_STANDARD 11)

include_directories(${CMAKE_CURRENT_LIST_DIR}/utils/include)
include_directories(${CMAKE_CURRENT_LIST_DIR}/sw/src/shared/ogldir1)
include_directories(${CMAKE_CURRENT_LIST_DIR}/sw/src/shared/ogldir2)

# Dependencies
# pacman -S mingw-w64-x86_64-shaderc
# pacman -S mingw-w64-x86_64-glew
# pacman -S mingw-w64-x86_64-glfw
# I'm sure there's more

# Libraries
add_subdirectory(utils/src/libSGP)
#add_subdirectory(utils/src/libsimpleGL)
add_subdirectory(utils/src/libsimpleGLU)
add_subdirectory(sw/src/shared/ogldir1)

# Projects
set(LINK_LIBS ogldir1 opengl32 glew32 glfw3)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/sw/bin)
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
add_subdirectory(sw/src/MP-4/00_primitive)
add_subdirectory(sw/src/MP-4/01_fragment)
add_subdirectory(sw/src/MP-4/02_intersect)
add_subdirectory(sw/src/MP-4/03_blend)
add_subdirectory(sw/src/MP-4/04_texture)

# Utilities
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/utils/bin)
add_subdirectory(utils/src/glslc_test)
add_subdirectory(utils/src/sgp_fbtransmit)
add_subdirectory(utils/src/sgp_test)
