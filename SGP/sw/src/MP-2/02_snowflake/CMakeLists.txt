project(MP_2_02_snowflake)

add_executable(${PROJECT_NAME} ${BASE}
        02_snowflake.cpp)

target_link_libraries(${PROJECT_NAME} ${LINK_LIBS})
