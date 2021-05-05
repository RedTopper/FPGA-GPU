###############################################################################
# Joseph Zambreno               
# Department of Electrical and Computer Engineering
# Iowa State University
###############################################################################

###############################################################################
# Makefile for building an OpenGL software application
###############################################################################


# Executable name
EXECUTABLE := Main

# Extra path for shared source
SHAREDIR := ../shared/ogldir1/

# C source files (separated by spaces)
LIB := -lstdc++fs
CFLAGS := -std=gnu++17
CFILES :=  
CPPFILES := $(EXECUTABLE).cpp \
	Super-Haxagon/source/Core/Game.cpp \
	Super-Haxagon/source/Core/Metadata.cpp \
	Super-Haxagon/source/Core/Platform.cpp \
	Super-Haxagon/source/Core/Structs.cpp \
	Super-Haxagon/source/Core/Surface.cpp \
	Super-Haxagon/source/Core/SurfaceGame.cpp \
	Super-Haxagon/source/Core/SurfaceUI.cpp \
	Super-Haxagon/source/Core/Vector.cpp \
	Super-Haxagon/source/Factories/LevelFactory.cpp \
	Super-Haxagon/source/Factories/PatternFactory.cpp \
	Super-Haxagon/source/Factories/WallFactory.cpp \
	Super-Haxagon/source/Objects/Level.cpp \
	Super-Haxagon/source/Objects/Pattern.cpp \
	Super-Haxagon/source/Objects/Wall.cpp \
	Super-Haxagon/source/States/Load.cpp \
	Super-Haxagon/source/States/Menu.cpp \
	Super-Haxagon/source/States/Over.cpp \
	Super-Haxagon/source/States/Play.cpp \
	Super-Haxagon/source/States/Quit.cpp \
	Super-Haxagon/source/States/Transition.cpp \
	Super-Haxagon/source/States/Win.cpp \
	SGP-Driver/source/AudioLoaderSGP.cpp \
	SGP-Driver/source/AudioPlayerSGP.cpp \
	SGP-Driver/source/FontSGP.cpp \
	SGP-Driver/source/PlatformSGP.cpp \
	SGP-Driver/source/SurfaceSGP.cpp \
	SGP-Driver/source/SurfaceGameSGP.cpp


# Additional include directories
INCLUDE_PATH := -I../shared/ogldir1/ -ISuper-Haxagon/include -ISGP-Driver/include

# Additional link library directories
LIB_PATH := -L.

# Additional link libraries
#LIB := -lm

###############################################################################
# Rules and targets

include ../../common/common.mk

###############################################################################
# Build code in the shared/ directory as well
SRCDIR2=$(SHAREDIR)
$(OBJDIR)/%.cpp.o : $(SRCDIR2)%.cpp $(C_DEPS) #$(REQFILE)
	$(VERBOSE)$(CPP) $(CFLAGS) $(INCLUDE_PATH) -o $@ -c $<
