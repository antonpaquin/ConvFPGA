SRCS=driver.c filter.c image.c ioport_comm.c protocol.c image_processing.c mat2d.c head.c
OBJS=$(SRCS:.c=.o)
HEAD=$(SRCS:.c=.h)

all: CC=gcc
all: clean $(OBJS)
	$(CC) -o test test.c $(OBJS) -lm

image_processing.o: image_processing.c
	$(CC) -c -o image_processing.o image_processing.c -lm

head.o: head.c
	$(CC) -c -o head.o head.c -lm

.c.o: 
	$(CC) -c -o $@ $<

clean:
	rm ./*.o || true

arm: CC=arm-none-eabi-gcc
arm: clean $(OBJS)
	$(CC) -o test test.c $(OBJS) -lm -static --specs=nosys.specs
