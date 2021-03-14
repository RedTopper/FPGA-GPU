###############################################################################
# Joseph Zambreno               
# Department of Electrical and Computer Engineering
# Iowa State University
###############################################################################

###############################################################################
# Makefile for building an OpenGL software application
###############################################################################


# Executable name
EXECUTABLE := 03_flexseal

# Extra path for shared source
SHAREDIR := ../../shared/ogldir1/

# C source files (separated by spaces)
CFILES :=  
CPPFILES := $(SHAREDIR)shader.cpp $(EXECUTABLE).cpp

# Additional include directories
INCLUDE_PATH := -I../../shared/ogldir1/

# Additional link library directories
LIB_PATH := -L.

# Additional link libraries
#LIB := -lm

###############################################################################
# Rules and targets

include ../../../common/common.mk

###############################################################################
# Build code in the shared/ directory as well
SRCDIR2=$(SHAREDIR)
$(OBJDIR)/%.cpp.o : $(SRCDIR2)%.cpp $(C_DEPS) #$(REQFILE)
	$(VERBOSE)$(CPP) $(CFLAGS) $(INCLUDE_PATH) -o $@ -c $<