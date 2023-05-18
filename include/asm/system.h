#ifndef system_h
#define system_h

#include <arch/types.h>
#include <arch/riscv.h>

static inline void set_clint_vec(int n, void* addr){
    extern size_t clint_vec[];
    clint_vec[n] = (size_t)addr;
}

static inline void set_except_vec(int n, void* addr){
    extern size_t except_vec[];
    except_vec[n] = (size_t)addr;
}

static inline void set_plic_vec(int n, void* addr){
    extern size_t plic_vec[];
    plic_vec[n] = (size_t)addr;
}

#endif /* system_h */
