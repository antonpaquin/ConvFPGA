#include <stdio.h>
#include <string.h>
#include <stdlib.h>

FILE *ioport_handle;

void ioport_open(char *fname) {
    ioport_handle = fopen(fname, "wb");
    if (!ioport_handle) {
        printf("Could not open file for append: %s\n", fname);
        exit(1);
    }
}

void ioport_close(void) {
    fclose(ioport_handle);
}

void ioport_write(char *c, int len) {
    fwrite(c, sizeof(char), len, ioport_handle);
    fflush(ioport_handle);
}
