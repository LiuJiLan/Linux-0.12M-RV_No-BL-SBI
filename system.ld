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

V_P_DIFF = OxFFFFFF8000000000;
PHYSICAL_BASE = RAM_START + 0x00200000;
VIRTUAL_BASE = PHYSICAL_BASE + V_P_DIFF;

PROVIDE(kpgtbl = PHYSICAL_BASE);
PROVIDE(LD_RAM_START = RAM_START);
PROVIDE(LD_RAM_START = RAM_START);
PROVIDE(LD_RAM_START = RAM_START);

SECTIONS
{
    . = VIRTUAL_BASE;
    .text :AT(PHYSICAL_BASE) {
        head.o(.text)
        /*main.o(.text)*/
        *(.text)
    }
    
    . = ALIGN(4096);
    PROVIDE(etext = .);

    .rodata : {
     *(.rodata)
    }
    
    
    
    .data : {
        head.o(.data)
        *(.data)
    }

    .bss :{
            *(.bss)
    }
    
    PROVIDE(kend = .);
}
