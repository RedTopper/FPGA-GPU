project(MP_1_06_ViewPorting)

add_executable(${PROJECT_NAME}
        06_ViewPorting.cpp)

target_link_libraries(${PROJECT_NAME} simpleGLU ${LINK_LIBS})
