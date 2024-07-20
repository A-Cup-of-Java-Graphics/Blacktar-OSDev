# Blacktar-OSDev
A simple OS

# BUILDING

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
# SOURCES

KERNEL : https://arjunsreedharan.org/post/82710718100/kernels-101-lets-write-a-kernel
BOOTLOADER : http://3zanders.co.uk/2017/10/13/writing-a-bootloader/
CONCEPT : http://www.osdever.net/tutorials/
CONCEPT : https://wiki.osdev.org/Creating_an_Operating_System
BOOTLOADER : https://www.independent-software.com/operating-system-development-first-bootloader-code.html
BOOTLOADER : https://stackoverflow.com/questions/34092965/second-stage-of-bootloader-prints-garbage-using-int-0x10-ah-0x0e/34095896#34095896
