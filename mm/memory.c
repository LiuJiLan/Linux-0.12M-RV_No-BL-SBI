#include <arch/types.h>
#include <linux/mm.h>

size_t HIGH_MEMORY = 0;
uint8 mem_map[PAGING_PAGES] = {0,};

void mem_init(size_t start_mem, size_t end_mem) {
    int i;

    HIGH_MEMORY = end_mem;
    for (i = 0; i < PAGING_PAGES; i++) {
        mem_map[i] = USED;
    }
    for (i=0 ; i<PAGING_PAGES ; i++)
        mem_map[i] = USED;
    i = (int)MAP_NR(start_mem);
    end_mem -= start_mem;
    end_mem >>= 12;
    while (end_mem-- > 0) {
        mem_map[i++]=0;
    }
}
