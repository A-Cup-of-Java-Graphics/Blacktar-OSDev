# Blacktar-OSDev
A simple OS in elf32 format and built into a disk in binary format.

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
dw 0xaa55
```

The second line is used to mark the the end of the 512 bytes bootloader, whicch is the magic number 0xAA55.<br>
If you open the built kernel.bin using a hex code reader, you will see that there is a series of zeroes followed by the byte AA55.<br>

The bootloader also loads up a GDT (Global Descriptor Table) which is then filled with a Kernel Code Segement and a Kernel Data Segment. <br>
Both segments run at Ring Level 0, allowing them to receive the least amount of protection, and the most amount of access.

The segments are composed of 3 main bytes :
![image](https://github.com/user-attachments/assets/ff2b04b9-fa04-48d6-8d33-ad4ee93d46bc)

Each Segment has a 
- limit : a **20 bit** value describing where the segment ends, can be multiplied by **4096(4KB)** if **granularity** = 1
- base : a **32 bit** value describing where the segment begins
- access byte :
  - present : must be **1** for entry to be valid
  - ring level : taking up **2 bits**, can be either :<br>
      *00,<br>
      01,<br>
      10, or 11*.<br> These respectfully represent the ring level of the segment, from 0-3. **Ring level 0** is used for kernels, **levels 1-2** are mostly used for device drivers, and **3** is used for user applications.<br>If a program demands resources that their ring does not provide, then they will trigger a **General Protection Fault** (int 13).
  - descriptor type : <br>if *clear (0)* defines a **System Segment** (e.g. Task State Segment),<br> if *set (1)* it defines a **data/code segment**
  - executable : <br>if *clear (0)* it generates a **Data Segment**, <br>if *set (1)* it generates an executable **Code Segment**
  - direction/conforming : <br>
      For **data selectors**, <br>it is a direction bit. If *clear (0)*, the **Data Segement** will **grow up** (Offset < limit), if *set (1)*, the **Data Segment** will **grow down** (Offset > limit)<br>
      For **code selectors**, <br>it is a conforming bit, if *clear (0)*, the **Code Segment** can **only execute in its own ring**, if *set (1)*, the **Code Segment** can be **executed from rings with lower privilege levels**, <br>e.g. Code Segment from Ring 2 can far jump to conforming code in Ring 1 segment. It is, however, not possible to jump from a higher privilege level to a lower privilege leve, i.e. Code from Ring 0 cannot far jump to conforming code in ring 2, but code from ring 2 or 3 can.<br>
  - readable/writable : <br>
      For **code segments**, if clear (0), read access for this segment is not allowed, if set (1), read access for this segment is allowed. Write access for code segments is never allowed.<br>
      For **data segments**, if clear (0), write access for this segment is not allowed, if set (1), write access for this segment is allowed. Read access for data segments is always allowed.<br>
  - accessed : <br>The CPU will set this bit to 1 after the segment has been accessed, unless set to 1 beforehand. If the GDT descriptor is stored in read-only pages, and this bit is 0, the CPU will trigger a page fault. Best set to 1 unless otherwise needed.
- flags byte :
  - granularity : if clear (0), **limit** is in 1 Byte blocks, if set (1), **limit** is in 4K byte blocks
  - default operation size : if clear (0), 16 bit, if set (1) 32 bit protected mode
  - long mode : if clear (0), long mode is disabled, if set (1) long mode is enabled
  - reserved bit : used for custom segment attributes, debugging, etc.

The Code Segment is created using the below code :
```
gdt_code: ;CODE SEGMENT
    dw 0xffff ;Segment limit
    dw 0x0 ;Segment Base (bits 0-15)
    db 0x0 ;Segment Base (bits 16-24)
    db 10011010b ;Access byte (in binary) : Present, Ring 0, Code Segment, Executable, Readable
    ;In CODE SEGMENTS Write access is never allowed
    db 11001111b ;Flags (in binary) : 4 bits of segment limit (bits 16-19), granularity (1), operation size (32-bit protected), long mode (disabled), available for system software (reserved)
    db 0x0 ;Segment Base (bits 24-31)
```
Here, we start by :
- Storing the lower bits of segment limit
- Storing the first **16 bits** of segment base
- Followed by **8 bits** of segment base
- Storing the access byte.
    In this instance, the access byte is ```10011010```,
    - The leftmost 1 represents ```present```,
    - The 2 zeros that follow represents the ```ring level```, which is 0 for kernel,
    - The 1 that follows is the ```descriptor type```, which represents that this is a code/data segment,
    - The 1 after that is the ```executable``` bit, which denotes that this segment is executable,
    - The 0 that ensues is the ```conforming``` bit, which here means that the kernel code should not be capable fo being executed from lower privilege levels,
    - The 1 after that is the ```readable/writable``` bit, which is 1 for readable,
    - Finally, the last 0 represents the ```accessed``` bit, it is 0, since it has yet to be accessed
- Stroing the flags byte.
    Here, the flags byte is ```11001111```,
    - The leftmost 1 represents ```granularity```, which indicates that the **limit** should be in 4KB blocks,
    - The second leftmost 1 represents the ```default operation size```, indicating that the code is operating under 32 bit protected mode, (code segment at least)
    - The 0 after that is the ```long mode``` bit, which indicates that long mode has not been activated,
    - The last 0 is a reserved bit for debugging and other purposes,
    - The 4 1s on the right represent the higher bits of **limit**
- Storing the higher bits (**last 8 bits**) of segment base

The Kernel is partially written in NASM and C. It currently handles the keyboard inputs. <br>
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
