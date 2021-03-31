project(MP_2_06_voronoi)

add_executable(${PROJECT_NAME} ${BASE} ${LIB_SIMPLE_GLU}
        06_voronoi.cpp
        VoronoiDiagramGenerator.cpp)

target_link_libraries(${PROJECT_NAME} ${LINK_LIBS})
