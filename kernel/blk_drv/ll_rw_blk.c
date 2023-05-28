#include <arch/types.h>
#include "blk.h"

struct request request[NR_REQUEST];

void blk_dev_init(void) {
    int i;
    
    for (i = 0; i < NR_REQUEST; i++) {
        request[i].dev = -1;
        request[i].next = NULL;
    }
}
