###############################################################################
# Joseph Zambreno               
# Department of Electrical and Computer Engineering
# Iowa State University
###############################################################################

###############################################################################
# Makefile for building an OpenGL software application
###############################################################################

.SUFFIXES : .c .o


# Directory setup
ROOTDIR 	:= "$(CDIR)/sw"
ROOTBINDIR 	:= $(ROOTDIR)/bin
ROOTUTILDIR := "$(CDIR)/utils"
ROOTOBJDIR	:= ./obj
SRCDIR		:= ./
TARGET 	 	:= $(EXECUTABLE)

#Compilers
CC		:= gcc
CPP		:= g++
LINK		:= g++ 

# Includes
INCLUDE_PATH	+= -I. -I$(ROOTUTILDIR)/include/ -I$(ROOTDIR)/common/include/

# Libs
LIB_PATH	+= -L$(ROOTUTILDIR)/lib64/ -L$(ROOTDIR)/common/lib/


# Comp Flags
CFLAGS	+= -O2

# check if verbose 
ifeq ($(verbose), 0)
        VERBOSE := 
else
        VERBOSE := 
endif


###############################################################################
# Set up object files
###############################################################################
OBJDIR := $(ROOTOBJDIR)
OBJS +=  $(patsubst %.c,$(OBJDIR)/%.o,$(CFILES))
OBJS +=  $(patsubst %.cpp,$(OBJDIR)/%.cpp.o,$(CPPFILES))

$(info ${OBJS})

LIB += -lglfw -lGLEW -lGLU -lGL -lsimpleGLU 

LINKLINE = $(LINK) -o $(TARGET) $(OBJS) $(LIB_PATH) $(LIB)


##############################################################################
# Additional req files
##############################################################################
REQFILE := $(ROOTUTILDIR)/include/simpleGLU.h

##############################################################################
# Stuff
##############################################################################
define createdirrule
$(1): | $(dir $(1))

ifndef $(dir $(1))_DIRECTORY_RULE_IS_DEFINED
$(dir $(1)):
	@mkdir -p $$@

$(dir $(1))_DIRECTORY_RULE_IS_DEFINED := 1
endif
endef

###############################################################################
# Rules
###############################################################################
$(OBJDIR)/%.o : $(SRCDIR)%.c $(C_DEPS) #$(REQFILE)
	$(VERBOSE)$(CC) $(CFLAGS) $(INCLUDE_PATH) -o $@ -c $<

$(OBJDIR)/%.cpp.o : $(SRCDIR)%.cpp $(C_DEPS) #$(REQFILE)
	$(VERBOSE)$(CPP) $(CFLAGS) $(INCLUDE_PATH) -o $@ -c $<


$(TARGET): makedirectories $(OBJS) Makefile
	$(VERBOSE)$(LINKLINE)
	$(VERBOSE)cp $(TARGET) $(ROOTBINDIR)

#$(REQFILE):
#	make -C $(ROOTUTILDIR) all

makedirectories:
	$(VERBOSE)mkdir -p $(OBJDIR)
	$(VERBOSE)mkdir -p $(ROOTBINDIR)

clean:
	$(VERBOSE)rm -f *~
	$(VERBOSE)rm -rf $(OBJDIR)
	$(VERBOSE)rm -f $(TARGET)
	$(VERBOSE)rm -f *.trace

distclean: clean
	$(VERBOSE)rm -f $(ROOTBINDIR)/$(EXECUTABLE)
	
$(foreach file,$(OBJS),$(eval $(call createdirrule,$(file))))
