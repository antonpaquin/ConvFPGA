SRCS=driver.c filter.c image.c ioport_comm.c protocol.c image_processing.c
OBJS=$(SRCS:.c=.o)
HEAD=$(SRCS:.c=.h)

all: $(OBJS)
	gcc -o test test.c $(OBJS) -lm

image_processing.o: image_processing.c
	gcc -c -o image_processing.o image_processing.c -lm

.c.o: 
	gcc -c -o $@ $<
