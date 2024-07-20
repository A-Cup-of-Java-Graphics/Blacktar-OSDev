# Blacktar-OSDev
A simple OS in elf33 format and built into a disk in binary format.

# BUILDING

Due to my installation of msys, my ld command only accepts i386pe as an output format, as such i have to do an extra step to cooy it into binary using objcopy.

Build using the following commands :
```
nasm -felf32 bootloader.asm -o bootloader.o
gcc -m32 -c kernel.c -o kc.o
ld -mi386pe -T bootLink.ld -o kernel.pe bootloader.o kc.o
objcopy -O binary kernel.pe kernel.bin
```

# RUNNING

Run with qemu using the following commands :
```
qemu-system-i386 -fda kernel.bin
```

# CONCEPT

The BIOS wil only load the first 512 bytes into the memory, hence the boitloader must achieve all of its objectives within 512 bytes.<br>

To ensure that the bootloader is aligned in 512 bytes, we use the line :
```
times 510 - ($-$$) db 0
dd 0xaa55
```

The second line is used to mark the the end of the 512 bytes bootloader, whicch is the magic number 0xAA55.<br>
If you open the built kernel.bin using a hex code reader, you will see that there is a series of zeroes followed by the byte AA55.<br>

The Kernel is partially written in NASM and C. It currently handles the jeyboard inputs. <br>
To do so, it accesses the PIC keyboard and reads its inputs from 2 ports :
- 0x64 for status(state of keyboard), and
- 0x60 for data(key pressed etc)

# SOURCES

KERNEL : https://arjunsreedharan.org/post/82710718100/kernels-101-lets-write-a-kernel<br>
BOOTLOADER : http://3zanders.co.uk/2017/10/13/writing-a-bootloader/<br>
CONCEPT : http://www.osdever.net/tutorials/<br>
CONCEPT : https://wiki.osdev.org/Creating_an_Operating_System<br>
BOOTLOADER : https://www.independent-software.com/operating-system-development-first-bootloader-code.html<br>
BOOTLOADER : https://stackoverflow.com/questions/34092965/second-stage-of-bootloader-prints-garbage-using-int-0x10-ah-0x0e/34095896#34095896
