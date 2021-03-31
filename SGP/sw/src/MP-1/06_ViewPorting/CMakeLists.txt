project(MP_1_06_ViewPorting)

add_executable(${PROJECT_NAME} ${BASE} ${LIB_SIMPLE_GLU}
        06_ViewPorting.cpp)

target_link_libraries(${PROJECT_NAME} ${LINK_LIBS})
