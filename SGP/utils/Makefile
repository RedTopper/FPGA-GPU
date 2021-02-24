###############################################################################
# Joseph Zambreno               
# Department of Electrical and Computer Engineering
# Iowa State University
###############################################################################

###############################################################################
# Makefile for creating all utilities and libraries
###############################################################################


PROJECTS := $(shell find src -name Makefile)
LIBTOPDIR := ../utils


%.ph_build : lib/libSGP.a 
	make -C $(dir $*) $(MAKECMDGOALS)

%.ph_clean : 
	make -C $(dir $*) clean $(USE_DEVICE)


all: $(addsuffix .ph_build,$(PROJECTS))
	@echo "Finished building all projects"

lib/libSGP.a :
	make -C src/libSGP $(MAKECMDGOALS)

clean: $(addsuffix .ph_clean,$(PROJECTS))
	@echo "Cleaned all projects" 

