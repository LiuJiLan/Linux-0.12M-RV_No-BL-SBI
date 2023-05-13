#include "../types.h"

// 临时使用
#define PAGE_SIZE PGSIZE
// 注意, 我们用这种方式完成了64bits的对齐
// 不要使用uint8 user_stack[PAGE_SIZE]来替代
// 另外, 如果非gcc编译器以及编译优化后是不保证对齐的
// Linux 0.12中是PAGE_SIZE>>2, 注意是保证4KiB大小
size_t user_stack [ PAGE_SIZE>>3 ] ;

int main(){
    
}
