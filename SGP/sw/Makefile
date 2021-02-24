###############################################################################
# Joseph Zambreno               
# Department of Electrical and Computer Engineering
# Iowa State University
###############################################################################

###############################################################################
# Makefile for building all sw/ projects
###############################################################################


PROJECTS := $(shell find src -name Makefile)
LIBTOPDIR := ../utils/


%.ph_build : 
	make -C $(dir $*) $(MAKECMDGOALS)

%.ph_clean : 
	make -C $(dir $*) clean $(USE_DEVICE)


all: $(addsuffix .ph_build,$(PROJECTS))
	@echo "Finished building all projects"


clean: $(addsuffix .ph_clean,$(PROJECTS))
	rm bin/*
	@echo "Cleaned all projects" 


