#include <stdio.h>
#include <string.h>

FILE *ioport_handle;

void ioport_open(char *fname) {
    ioport_handle = fopen(fname, "a");
}

void ioport_close(void) {
    fclose(ioport_handle);
}

void ioport_write(char *c, int len) {
    fwrite(c, sizeof(char), len, ioport_handle);
    fflush(ioport_handle);
}
