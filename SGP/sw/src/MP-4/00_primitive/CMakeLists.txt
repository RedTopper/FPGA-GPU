project(MP_4_00_primitive)

add_executable(${PROJECT_NAME} ${BASE}
        00_primitive.cpp)

target_link_libraries(${PROJECT_NAME} ${LINK_LIBS})
