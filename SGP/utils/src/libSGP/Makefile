###############################################################################
# Joseph Zambreno               
# Department of Electrical and Computer Engineering
# Iowa State University
###############################################################################

###############################################################################
# Makefile for creating static library for SGP common driver utils
###############################################################################


# suffix rules
.SUFFIXES: .o .c


#Library Name
LIBNAME		:= libSGP.a
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
COMMONFLAGS	+= -O2 
ifdef OS	
COMMONFLAGS += -mno-ms-bitfields
endif
INCLUDES 	:= -I. -I$(SOURCE)/../../include

#check if verbose
ifeq ($(verbose),1)
	VERBOSE :=
else
	VERBOSE := 
endif

OBJFILES := $(ROOTOBJDIR)/sgp_axi.o $(ROOTOBJDIR)/sgp_system.o $(ROOTOBJDIR)/sgp_graphics.o $(ROOTOBJDIR)/sgp_transmit.o $(ROOTOBJDIR)/sgp.o
OBJFILES32 := $(ROOTOBJDIR)/sgp_axi.o.32 $(ROOTOBJDIR)/sgp_system.o.32 $(ROOTOBJDIR)/sgp_graphics.o.32 $(ROOTOBJDIR)/sgp_transmit.o.32 $(ROOTOBJDIR)/sgp.o.32
SRCFILES := $(SOURCE)/sgp_axi.c $(SOURCE)/sgp_system.c $(SOURCE)/sgp_graphics.c $(SOURCE)/sgp_transmit.c $(SOURCE)/sgp.c

all: makedirectories $(SRCFILES) $(OBJFILES) $(OBJFILES32)
	$(VERBOSE)$(CLIB) $(TARGET) $(OBJFILES)
	$(VERBOSE)$(CLIB) $(TARGET32) $(OBJFILES32)

#Compile all .c files
$(ROOTOBJDIR)/%.o : $(SOURCE)/%.c
	$(VERBOSE)$(CC) -fPIC -c $(INCLUDES) $(COMMONFLAGS) -o $@ $<

$(ROOTOBJDIR)/%.o.32 : $(SOURCE)/%.c
	$(VERBOSE)$(CC) -m32 -fPIC -c $(INCLUDES) $(COMMONFLAGS) -o $@ $<

clean:
	$(VERBOSE)rm -rf $(ROOTOBJDIR)
	$(VERBOSE)rm -f $(TARGET)
	$(VERBOSE)rm -f $(TARGET32)

makedirectories:
	$(VERBOSE)mkdir -p $(ROOTOBJDIR)
	$(VERBOSE)mkdir -p $(ROOTLIBDIR)
	$(VERBOSE)mkdir -p $(ROOTLIBDIR32)
