/*
沿用之前的链接脚本, 记得在最用删除无用的PROVIDE
*/


OUTPUT_ARCH( "riscv" )

ENTRY(_start)

/*
我本想能让RAM_START直接从platform.h引入
但是似乎没有什么好办法
退而其次, 在platform中做一次判断
*/
RAM_START = 0x80000000;
PROVIDE(LD_RAM_START = RAM_START);

V_P_DIFF = 0xFFFFFFC000000000;
PHYSICAL_BASE = RAM_START + 0x00200000;
VIRTUAL_BASE = PHYSICAL_BASE + V_P_DIFF;

/*
kpg for kernel page table (2GiB huge page).
ipg for idle(task 0) page table.
PS: 2 is biggest page level.
    0 is smallest page level.
*/
/*
Why VIRTUAL_BASE but no PHYSICAL_BASE?
Let me explain in the head.S
*/

/*
PROVIDE(kpg = VIRTUAL_BASE);
PROVIDE(ipg2 = VIRTUAL_BASE + 4096);
PROVIDE(ipg1 = VIRTUAL_BASE + 4096*2);
PROVIDE(ipg0 = VIRTUAL_BASE + 4096*3);*/
/*
May have more ipg0.
Let me explain in the head.S
*/

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
    
    PROVIDE(end = .);
}
