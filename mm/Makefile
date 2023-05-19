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

OBJS  = memory.o #swap.o page.o

all: mm.o

mm.o: $(OBJS)
	$(LD) -r -o mm.o $(OBJS)
	#sync

clean:
	rm -f *.o tmp_make
    #rm -f core *.o *.a tmp_make keyboard.s
    #for i in *.c;do rm -f `basename $$i .c`.s;done

dep:
	sed '/\#\#\# Dependencies/q' < Makefile > tmp_make
	(for i in *.c;do echo -n `echo $$i | sed 's,\.c,\.s,'`" "; \
	$(CPP) -M $$i;done) >> tmp_make
	cp tmp_make Makefile
    

### Dependencies:
memory.s memory.o: memory.c ../include/arch/types.h ../include/linux/mm.h \
 ../include/linux/config.h ../include/linux/../../platform.h
