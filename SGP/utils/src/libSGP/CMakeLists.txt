project(SGP)

set(SOURCE_FILES
        sgp.c
        sgp_axi.c
        sgp_graphics.c
        sgp_shaders.c
        sgp_system.c
        sgp_transmit.c)

add_library(${PROJECT_NAME} STATIC ${SOURCE_FILES})
