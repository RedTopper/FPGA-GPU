project(MP_1_01_ClearTest)

add_executable(${PROJECT_NAME} ${BASE}
        01_ClearTest.c)

target_link_libraries(${PROJECT_NAME} ${LINK_LIBS})
