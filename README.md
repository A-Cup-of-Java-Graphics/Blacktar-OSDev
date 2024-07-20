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
