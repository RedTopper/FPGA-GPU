project(glslc_test)

add_executable(${PROJECT_NAME}
        glslc_test.c)

target_link_libraries(${PROJECT_NAME} SGP ws2_32 shaderc_shared lua )
