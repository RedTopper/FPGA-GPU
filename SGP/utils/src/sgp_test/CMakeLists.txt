project(sgp_test)

add_executable(${PROJECT_NAME}
        sgp_test.c)

target_link_libraries(${PROJECT_NAME} simpleGLU SGP ws2_32)
