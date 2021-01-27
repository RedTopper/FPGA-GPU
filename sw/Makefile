CC   	= gcc
CFLAGS 	= -O2 -std=c99 -Wall
LDFLAGS = -lm

OBJ  	= mvmac.o
EXEC  = mvmac



$(EXEC): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

clean:
	rm -rf *~ *# core ../core *.o *.exe $(EXEC);


