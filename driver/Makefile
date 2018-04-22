SRCS=driver.c filter.c image.c ioport_comm.c protocol.c image_processing.c
OBJS=$(SRCS:.c=.o)
HEAD=$(SRCS:.c=.h)

all: $(OBJS)
	gcc -o test test.c $(OBJS)

.c.o: 
	gcc -c -o $@ $<
