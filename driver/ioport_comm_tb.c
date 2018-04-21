#include <unistd.h>
#include "ioport_comm.h"

int main() {
    ioport_open("~/tmp/verilog.port");
    ioport_write("anton", 5);
    usleep(1);
    ioport_write("was  ", 5);
    usleep(1);
    ioport_write("here ", 5);
    usleep(1);
    ioport_write("hello", 5);
    usleep(1);
    ioport_write("world", 5);
    usleep(1);
    ioport_close();
}
