project(sgp_fbtransmit)

add_executable(${PROJECT_NAME}
        sgp_fbtransmit.c
        utils.c)

target_link_libraries(${PROJECT_NAME} simpleGLU SGP ws2_32)
