#include <stdio.h>
#include <unistd.h>

int get_current_uid() {
    return getuid();
}

int get_effective_uid() {
    return geteuid();
}