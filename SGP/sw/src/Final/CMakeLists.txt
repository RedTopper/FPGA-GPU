project(SuperHaxagon)

set(CMAKE_CXX_STANDARD 17)
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/SGP-Driver/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/Super-Haxagon/include")

add_executable(${PROJECT_NAME} WIN32 Main.cpp
        SGP-Driver/source/AudioLoaderSGP.cpp
        SGP-Driver/source/AudioPlayerSGP.cpp
        SGP-Driver/source/FontSGP.cpp
        SGP-Driver/source/PlatformSGP.cpp
        SGP-Driver/source/SurfaceSGP.cpp
        SGP-Driver/source/SurfaceGameSGP.cpp

        Super-Haxagon/source/States/Load.cpp
        Super-Haxagon/source/States/Menu.cpp
        Super-Haxagon/source/States/Over.cpp
        Super-Haxagon/source/States/Play.cpp
        Super-Haxagon/source/States/Quit.cpp
        Super-Haxagon/source/States/Transition.cpp
        Super-Haxagon/source/States/Win.cpp

        Super-Haxagon/source/Factories/LevelFactory.cpp
        Super-Haxagon/source/Factories/PatternFactory.cpp
        Super-Haxagon/source/Factories/WallFactory.cpp

        Super-Haxagon/source/Objects/Level.cpp
        Super-Haxagon/source/Objects/Pattern.cpp
        Super-Haxagon/source/Objects/Wall.cpp

        Super-Haxagon/source/Core/Platform.cpp
        Super-Haxagon/source/Core/Game.cpp
        Super-Haxagon/source/Core/Metadata.cpp

        Super-Haxagon/source/Core/Structs.cpp
        Super-Haxagon/source/Core/Surface.cpp
        Super-Haxagon/source/Core/SurfaceUI.cpp
        Super-Haxagon/source/Core/SurfaceGame.cpp
        Super-Haxagon/source/Core/Vector.cpp)

target_link_libraries(${PROJECT_NAME} ${LINK_LIBS})

add_custom_command(TARGET SuperHaxagon POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/Super-Haxagon/romfs $<TARGET_FILE_DIR:SuperHaxagon>/romfs)
