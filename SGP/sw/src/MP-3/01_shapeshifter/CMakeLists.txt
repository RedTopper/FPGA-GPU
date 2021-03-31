project(MP_3_01_shapeshifter)

add_executable(${PROJECT_NAME} ${BASE}
        01_shapeshifter.cpp)

target_link_libraries(${PROJECT_NAME} ${LINK_LIBS})
