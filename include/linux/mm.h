#ifndef mm_h
#define mm_h

#include <arch/types.h>
#include <linux/config.h>

#define PAGE_SIZE PGSIZE

//我们不再使用低地址标识, 而是将整个RAM空间放进去
//#define LOW_MEM 0x100000
extern size_t HIGH_MEMORY;
#define PAGING_MEMORY RAM_SIZE
#define PAGING_PAGES (PAGING_MEMORY>>12)
#define MAP_NR(addr) (((addr)-RAM_START)>>12)
#define USED 100

extern unsigned char mem_map[PAGING_PAGES];

//相关标志我们之后定义


#endif /* mm_h */
