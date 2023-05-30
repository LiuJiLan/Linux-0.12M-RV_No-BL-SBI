# 编译工具部分
CROSS_COMPILE = riscv64-unknown-elf-

AR         = ${CROSS_COMPILE}ar
AS         = ${CROSS_COMPILE}as
LD         = ${CROSS_COMPILE}ld
LDFLAGS    = #-s -x
CC         = ${CROSS_COMPILE}gcc
CFLAGS     = -Wall -g -ggdb -nostdlib -fno-builtin \
    -mcmodel=medany -mabi=lp64f -march=rv64imafc \
    -I../include
CPP         = ${CROSS_COMPILE}cpp -nostdinc \
            -I../include

%.o : %.c
	$(CC) $(CFLAGS) \
	-c -o $*.o $<
%.o : %.S
	@${CC} ${CFLAGS} -c -o $*.o $<

OBJS  = sched.o sys_call.o asm.o traps.o \
	sys.o
#sched.o sys_call.o traps.o asm.o fork.o \
#panic.o printk.o vsprintf.o sys.o exit.o \
#signal.o mktime.o

kernel.o: $(OBJS)
	$(LD) -r -o kernel.o $(OBJS)
	#sync

clean:
	rm -f *.o tmp_make
    #rm -f core *.o *.a tmp_make keyboard.s
    #for i in *.c;do rm -f `basename $$i .c`.s;done
	(cd chr_drv; make clean)
	(cd blk_drv; make clean)
    #(cd math; make clean)

dep:
	sed '/\#\#\# Dependencies/q' < Makefile > tmp_make
	(for i in *.c;do echo -n `echo $$i | sed 's,\.c,\.s,'`" "; \
		$(CPP) -M $$i;done) >> tmp_make
	cp tmp_make Makefile
	(cd chr_drv; make dep)
	(cd blk_drv; make dep)
	

### Dependencies:
sched.s sched.o: sched.c ../include/arch/types.h ../include/linux/mm.h \
 ../include/linux/config.h ../include/linux/../../platform.h \
 ../include/linux/sched.h ../include/signal.h
sys.s sys.o: sys.c ../include/linux/sys.h ../include/linux/config.h \
 ../include/linux/../../platform.h ../include/linux/sched.h \
 ../include/arch/types.h
traps.s traps.o: traps.c ../include/arch/types.h ../include/asm/system.h \
 ../include/arch/riscv.h ../include/arch/types.h \
 ../include/linux/config.h ../include/linux/../../platform.h \
 ../include/debug.h
