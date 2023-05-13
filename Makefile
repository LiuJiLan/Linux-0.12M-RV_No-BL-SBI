

# 暂时不支持RAMDISK
RAMDISK = #-DRAMDISK=512


# 编译工具部分
CROSS_COMPILE = riscv64-unknown-elf-

AS		= ${CROSS_COMPILE}as
LD 		= ${CROSS_COMPILE}ld
# LDFLAGS = -s -x -M
# `-s`：这个选项告诉编译器/链接器去掉所有调试符号
# `-x`：这个选项告诉链接器将所有被未引用的符号剔除
LDFLAGS = -M
# $(RAMDISK)参数只在main中使用, 我认为不应该放在CC指令后面
CC 		= ${CROSS_COMPILE}gcc
CFLAGS 	= -Wall -g -ggdb -nostdlib -fno-builtin \
		-mcmodel=medany -mabi=lp64f -march=rv64imafc
CPP     = ${CROSS_COMPILE}cpp -nostdinc -Iinclude

####额外部分
OBJCOPY = ${CROSS_COMPILE}objcopy
OBJDUMP = ${CROSS_COMPILE}objdump


# 磁盘设置部分
# Linux 0.12 中使用单独的build工具将这两个值写入系统的镜像当中
# *HIL Handle it Later, 后面再来处理这个问题
#ROOT_DEV=/dev/hd6          #
#SWAP_DEV=/dev/hd2


ARCHIVES = kernel/kernel.o mm/mm.o fs/fs.o
DRIVERS  = kernel/blk_drv/blk_drv.a kernel/chr_drv/chr_drv.a
MATH	 = kernel/math/math.a
LIBS	 = lib/lib.a


# 我们此处用新格式代替Linux 0.12中的旧格式
# 例如 .c.o: 变为 %.o : %.c
# 另外我在xv6-qemu使用的规则是$@, 而这里遵循Linux 0.12中使用$*做自动目标变量

#.c.s:	# 我没有看到源码中有相应规则从.c到.s, 所以注释掉这一规则, 如果后续有问题再解开
#	$(CC) $(CFLAGS) \
#	-nostdinc -Iinclude -S -o $*.s $<
%.o : %.s
	$(AS) -c -o $*.o $<
%.o : %.c
	$(CC) $(CFLAGS) \
	-nostdinc -Iinclude -c -o $*.o $<
%.o : %.S
	@${CC} ${CFLAGS} -c -o $@ $<
	
all: Image

Image: # boot/bootsect boot/setup tools/system tools/build # *HIL
	echo "Image rule not implemented!"
#	tools/build boot/bootsect boot/setup tools/system $(ROOT_DEV) \
#		$(SWAP_DEV) > Image
#	sync


# 我们的系统不需要存在硬盘中, 或者说不是在我们需要掌控的范围内
# qemu直接将bin文件载入RAM
# VisionFive2中我们使用boot分区的extlinux.conf来让u-boot来载入我们的系统
#disk: Image
#	dd bs=8192 if=Image of=/dev/PS0


# 我们不使用tools/build来额外处理来制作Image
# qemu中使用OBJCOPY来提取bin文件, 相当于Image的作用
# 我们直接使用u-boot工具中的mkimage来制作VisionFive2的Image
#tools/build: tools/build.c
#	$(CC) $(CFLAGS) \
#	-o tools/build tools/build.c


# 我们的head为了使用一些宏, 所以我们使用的是.S文件
# 我们先单独给boot/head.o设置一个规则, 如果其他.s文件也要改用.S
# 就应该设置一条.S到.s的通用规则
boot/head.o: boot/head.S
	$(CC) $(CFLAGS) \
	-nostdinc -Iinclude -c -o boot/head.o boot/head.S
	

tools/system: boot/head.o init/main.o \
		$(ARCHIVES) $(DRIVERS) $(MATH) $(LIBS)
	$(LD) $(LDFLAGS) boot/head.o init/main.o \
	$(ARCHIVES) \
	$(DRIVERS) \
	$(MATH) \
	$(LIBS) \
	-o tools/system > System.map
	
	
# 我们没有数学协处理器
#kernel/math/math.a:
#	(cd kernel/math; make)

kernel/blk_drv/blk_drv.a:
	(cd kernel/blk_drv; make)

kernel/chr_drv/chr_drv.a:
	(cd kernel/chr_drv; make)

kernel/kernel.o:
	(cd kernel; make)
	
mm/mm.o:
	(cd mm; make)

fs/fs.o:
	(cd fs; make)
	
lib/lib.a:
	(cd lib; make)


# 我们的代码中不使用boot/setup和boot/bootsect
# setup的工作使用静态的设置或者可能采取解析设备树来处理
# 对于我来说, 现在的设计是使用.h文件静态设置
#boot/setup: boot/setup.s
#	$(AS86) -o boot/setup.o boot/setup.s
#	$(LD86) -s -o boot/setup boot/setup.o
#
#boot/setup.s:	boot/setup.S include/linux/config.h
#	$(CPP) -traditional boot/setup.S -o boot/setup.s
#
#boot/bootsect.s:	boot/bootsect.S include/linux/config.h
#	$(CPP) -traditional boot/bootsect.S -o boot/bootsect.s
#
#boot/bootsect:	boot/bootsect.s
#	$(AS86) -o boot/bootsect.o boot/bootsect.s
#	$(LD86) -s -o boot/bootsect boot/bootsect.o

clean:
	#echo "clean rule not implemented!"
	rm -f boot/*.o debug/dis.asm debug/kernel.* \
	System.map tools/*
#	rm -f Image System.map tmp_make core boot/bootsect boot/setup \
#		boot/bootsect.s boot/setup.s
#	rm -f init/*.o tools/system tools/build boot/*.o
#	(cd mm;make clean)
#	(cd fs;make clean)
#	(cd kernel;make clean)
#	(cd lib;make clean)

# 不打算使用backup
#backup: clean
#	(cd .. ; tar cf - linux | compress - > backup.Z)
#	sync


dep:
	sed '/\#\#\# Dependencies/q' < Makefile > tmp_make
	(for i in init/*.c;do echo -n "init/";$(CPP) -M $$i;done) >> tmp_make
	cp tmp_make Makefile
	(cd fs; make dep)
	(cd kernel; make dep)
	(cd mm; make dep)
	
###########
# 开发阶段的临时使用的一些Makefile规则

DEBUG = ./debug

QEMU = qemu-system-riscv64
QFLAGS = -smp 1 -M virt -bios default
QFLAGS += -m 128M -nographic
#QFLAGS += -serial pipe:/tmp/guest
	
tools/system.elf: boot/head.o  # init/main.o \
		# $(ARCHIVES) $(DRIVERS) $(MATH) $(LIBS)
	$(LD) $(LDFLAGS) -T system.ld \
	boot/head.o \
	-o tools/system.elf > System.map
#	boot/head.o init/main.o \
#	$(ARCHIVES) \
#	$(DRIVERS) \
#	$(MATH) \
#	$(LIBS) \
#	-o tools/system > System.map
	
tools/kernel.elf: tools/system.elf
	#@${CC} ${CFLAGS} -T kernel.ld -o kernel.elf $^
	cp tools/system.elf tools/kernel.elf
	${OBJCOPY} -O binary tools/kernel.elf tools/kernel.bin
	
GDB = ${CROSS_COMPILE}gdb
READELF = ${CROSS_COMPILE}readelf

QFLAGS += -kernel tools/kernel.elf
	
debug: tools/kernel.elf
	$(OBJDUMP) -D -b binary -m riscv tools/kernel.bin > $(DEBUG)/dis.asm
	$(OBJDUMP) -S tools/kernel.elf > $(DEBUG)/kernel.asm
	$(READELF) -a -W tools/kernel.elf > $(DEBUG)/kernel.txt
	${QEMU} ${QFLAGS} -s -S &
	${GDB} tools/kernel.elf -q -x $(DEBUG)/gdbinit.txt



# 不要在这之后到文件末尾间书写任何东西, Dependencies之后的部分会被dep自动刷新掉
### Dependencies:
