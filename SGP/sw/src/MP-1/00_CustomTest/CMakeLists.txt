project(MP_1_00_CustomTest)

add_executable(${PROJECT_NAME}
        00_CustomTest.cpp)

target_link_libraries(${PROJECT_NAME} ${LINK_LIBS})
