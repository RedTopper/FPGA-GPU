project(MP_2_01_TheRedTriangle)

add_executable(${PROJECT_NAME} ${BASE}
        01_TheRedTriangle.cpp)

target_link_libraries(${PROJECT_NAME} ${LINK_LIBS})
