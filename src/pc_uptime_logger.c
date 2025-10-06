#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(void) {
    FILE *f = fopen("/proc/stat", "r");
    if (!f) {
        perror("fopen");
        return 1;
    }

    char line[256];
    long btime = 0;

    while (fgets(line, sizeof(line), f)) {
        if (sscanf(line, "btime %ld", &btime) == 1) {
            break;
        }
    }

    fclose(f);

    if (btime == 0) {
        fprintf(stderr, "Could not find btime in /proc/stat\n");
        return 1;
    }

    printf("Boot time (epoch): %ld\n", btime);

    // Optional: print as human-readable time
    printf("Boot time (readable): %s", ctime(&btime));

    return 0;
}
