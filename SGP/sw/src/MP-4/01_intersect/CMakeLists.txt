project(MP_4_01_intersect)

add_executable(${PROJECT_NAME} ${BASE}
        01_intersect.cpp)

target_link_libraries(${PROJECT_NAME} ${LINK_LIBS})
