###############################################################################
# Joseph Zambreno               
# Department of Electrical and Computer Engineering
# Iowa State University
###############################################################################

###############################################################################
# Makefile for creating static library for additional SGP helper functions
###############################################################################


# suffix rules
.SUFFIXES: .o .c


#Library Name
LIBNAME		:= libsimpleGLU.a
ROOTLIBDIR	:= ../../lib64
ROOTLIBDIR32	:= ../../lib
TARGET		:= $(ROOTLIBDIR)/$(LIBNAME)
TARGET32	:= $(ROOTLIBDIR32)/$(LIBNAME)


#Path to source files
SOURCE 	:= ./
ROOTOBJDIR := $(SOURCE)/build

# Compilers/Linkers
CC	:= gcc
LINK	:= gcc
CLIB	:= ar rcs

# Arguments
COMMONFLAGS	+= -O2 -lm
ifdef OS	
COMMONFLAGS += -mno-ms-bitfields
endif


INCLUDES 	:= -I. -I$(ROOTLIBDIR)/../include

#check if verbose
ifeq ($(verbose),1)
	VERBOSE :=
else
	VERBOSE := 
endif

OBJFILES := $(ROOTOBJDIR)/simpleGLU.o
SRCFILES := $(SOURCE)/simpleGLU.c

all: makedirectories $(OBJFILES)
	$(VERBOSE)$(CLIB) $(TARGET) $(OBJFILES)

#Compile all .c files
$(OBJFILES):$(SRCFILES)
	$(VERBOSE)$(CC) -c $(INCLUDES) $(COMMONFLAGS) -o $@ $<

clean:
	$(VERBOSE)rm -rf $(ROOTOBJDIR)
	$(VERBOSE)rm -f $(TARGET)

makedirectories:
	$(VERBOSE)mkdir -p $(ROOTOBJDIR)

