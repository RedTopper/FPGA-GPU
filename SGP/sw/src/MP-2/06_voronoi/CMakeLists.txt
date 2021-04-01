project(MP_2_06_voronoi)

add_executable(${PROJECT_NAME}
        06_voronoi.cpp
        VoronoiDiagramGenerator.cpp)

target_link_libraries(${PROJECT_NAME} simpleGLU ${LINK_LIBS})
