/*
沿用之前的链接脚本, 记得在最用删除无用的PROVIDE
*/


OUTPUT_ARCH( "riscv" )

ENTRY(_start)

/*
我本想能让RAM_START直接从platform.h引入
但是似乎没有什么好办法
退而其次, 在platfrom中做一次判断
*/
RAM_START = LD_RAM_START;
PROVIDE(LD_RAM_START = RAM_START);

V_P_DIFF = 0xFFFFFF8000000000;
PHYSICAL_BASE = RAM_START + 0x80200000;
VIRTUAL_BASE = PHYSICAL_BASE + V_P_DIFF;

/*
kpg for kernel page table (2GiB huge page).
ipg for idle(task 0) page table.
PS: 2 is biggest page level.
    0 is smallest page level.
*/
PROVIDE(kpg = PHYSICAL_BASE);
PROVIDE(ipg2 = PHYSICAL_BASE + 4096);
PROVIDE(ipg1 = PHYSICAL_BASE + 4096*2);
PROVIDE(ipg0 = PHYSICAL_BASE + 4096*3);

SECTIONS
{
    . = VIRTUAL_BASE;
    .text :AT(PHYSICAL_BASE) {
        boot/head.o(.text)
        /*main.o(.text)*/
        *(.text)
    }
    
    . = ALIGN(4096);
    PROVIDE(etext = .);

    .rodata : {
     *(.rodata)
    }
    
    
    
    .data : {
        boot/head.o(.data)
        *(.data)
    }

    .bss :{
            *(.bss)
    }
    
    PROVIDE(kend = .);
}
