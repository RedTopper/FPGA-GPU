CC   	= gcc
CFLAGS 	= -O2 -Wall -I. -I../../include
LDFLAGS = -L../../lib64 -lSGP -lsimpleGLU -lm 

ifdef OS	
CFLAGS += -mno-ms-bitfields
LDFLAGS += -lws2_32
endif


OBJ  	= sgp_fbtransmit.o utils.o
EXEC  = sgp_fbtransmit
EXEC_WIN = $(EXEC).exe

%.o : %.c ../../lib64/libSGP.a ../../lib64/libsimpleGLU.a
	$(CC) $(CFLAGS) -o $@ -c $<

all:$(EXEC)

$(EXEC): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
	mkdir -p ../../bin/
	cp -f $(EXEC) ../../bin/ 2>/dev/null || :
	cp -f $(EXEC_WIN) ../../bin/ 2>/dev/null || :

../../lib64/libSGPUtils.a:
	make -C ../libSGP all

../../lib64/libsimpleGLU.a:
	make -C ../libsimpleGLU all

clean:
	rm -rf *~ *# core ../core *.o *.exe $(EXEC) ../../bin/$(EXEC) ../../bin/$(EXEC_WIN); 
