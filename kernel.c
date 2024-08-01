#include "keyboard_map.h"

#define BYTES_FOR_EACH_ELEMENT 2
#define LINES 25
#define COLUMNS_IN_LINE 80
#define SCREEN_SIZE BYTES_FOR_EACH_ELEMENT * LINES * COLUMNS_IN_LINE
#define KEYBOARD_STATUS_PORT 0x64
#define KEYBOARD_DATA_PORT 0x60
#define IDT_SIZE 256

#define ENTER_KEYCODE 0x1C
#define BACKSPACE_KEYCODE 0x08

#define false 0
#define true 1

#define for_each(item, array) \
            for(int keep = 1, \
                    count = 0, \
                    size = sizeof(array) / sizeof *(array); \
                keep && count != size; \
                keep = !keep, count++) \
                for(item = (array) + count; keep; keep = !keep)

extern unsigned char keyboard_map[128];
extern void keyboard_handler(void);
extern void load_idt(unsigned long *idt_ptr);
extern char read_port(unsigned short port);
extern void write_port(unsigned short port, unsigned char data);//This would be the equivalent of Linux' outb

unsigned int current_loc = 0;
unsigned int currentLine= 0;

char *vidptr = (char*)0xb8000;

struct line{
    char contents[COLUMNS_IN_LINE];
    int index;
};



//STRUCT LINE

struct line line_initialize(){
    struct line l = {
        {0},
        -1
    };
    return l;
}

int line_isAtEnd(struct line line){
    return line.index == COLUMNS_IN_LINE - 1;
}

int line_write(struct line *line, char c){
    if(line_isAtEnd(*line) == false) {
        line->contents[++line->index] = c;
        return true;
    }
    return false;
}

int line_backspace(struct line *line){
    if(line->index >= 0){
        line->contents[line->index--] = 0;
        return true;
    }
    return false;
}

int line_isEmpty(struct line line){
    for_each(char* c, line.contents){
        if(c != 0){
            return false;
        }
    }
    return true;
}

struct line lines[25];

struct IDT_entry{

    unsigned short int offset_lowerbits;
    unsigned short int selector;
    unsigned char zero;
    unsigned char type_attr;
    unsigned short int offset_higherbits;

};

struct IDT_entry IDT[IDT_SIZE];

void idt_init(void){
    unsigned long keyboard_address;
    unsigned long idt_address;
    unsigned long idt_ptr[2];
    
    keyboard_address = (unsigned long) keyboard_handler;
    IDT[0x21].offset_lowerbits = keyboard_address & 0xffff;
    IDT[0x21].selector = 0x08;
    IDT[0x21].zero = 0;
    IDT[0x21].type_attr = 0x8e;
    IDT[0x21].offset_higherbits = (keyboard_address & 0xffff0000) >> 16;

    write_port(0x20, 0x11);
    write_port(0xA0, 0x11);

    write_port(0x21, 0x20);
    write_port(0xA1, 0x28);

    write_port(0x21, 0x00);
    write_port(0xA1, 0x00);

    write_port(0x21, 0x01);
    write_port(0xA1, 0x01);

    write_port(0x21, 0xff);
    write_port(0xA1, 0xff);

    idt_address = (unsigned long) IDT;
    idt_ptr[0] = (sizeof (struct IDT_entry) * IDT_SIZE) + ((idt_address & 0xffff) << 16);
    idt_ptr[1] = idt_address >> 16;

    load_idt(idt_ptr);

}

void kb_init(void){
    write_port(0x21, 0xFD);
}


void kprint(const char *str){
    unsigned int i = 0;
    while(str[i] != '\0'){
        vidptr[current_loc++] = str[i++];
        vidptr[current_loc++] = 0x07;
    }
}

void kprint_newline(void){
    currentLine++;
    unsigned int line_size = BYTES_FOR_EACH_ELEMENT * COLUMNS_IN_LINE;
    current_loc = currentLine * line_size;
    lines[currentLine] = line_initialize();
}

void kprint_backspace(void){
    vidptr[current_loc - 2] = ' ';
    vidptr[current_loc - 1] = 0x07;
    current_loc -= 2;
    if(!line_backspace(&lines[currentLine])){
        currentLine--;
        current_loc = currentLine * BYTES_FOR_EACH_ELEMENT * COLUMNS_IN_LINE + (lines[currentLine].index + 1) * BYTES_FOR_EACH_ELEMENT;
    }
}

void clear_screen(void){
    unsigned int i = 0;
    while(i < SCREEN_SIZE){
        vidptr[i++] = ' ';
        vidptr[i++] = 0x07;
    }
}

void update_cursor(int x, int y){
    unsigned short int pos = y * COLUMNS_IN_LINE + x;

    write_port(0x3d4, 0x0f);
    write_port(0x3d5, (pos & 0xff));
    write_port(0x3d4, 0x0e);
    write_port(0x3d5, ((pos >> 8) & 0xff));
}

void keyboard_handler_main(void){
    unsigned char status;
    char keycode;

    write_port(0x20, 0x20);
    status = read_port(KEYBOARD_STATUS_PORT);

    if(status & 0x01){
        keycode = read_port(KEYBOARD_DATA_PORT);
        unsigned char key = keyboard_map[(unsigned char) keycode];
        if(keycode < 0)
            return;
        if(key == *"\n"){
            kprint_newline();
        }else if(key == *"\b"){
            kprint_backspace();
        }else if(line_write(&lines[currentLine], key)){
            vidptr[current_loc++] = key;
            vidptr[current_loc++] = 0x07;
        }else{
            kprint_newline();
            if(line_write(&lines[currentLine], key)){
                vidptr[current_loc++] = key;
                vidptr[current_loc++] = 0x07;
            }
        }
        update_cursor(lines[currentLine].index, currentLine);
    }
}

void kmain(void);

void kmain(void){
    const char *str = "blacktar";
    clear_screen();
    lines[currentLine] = line_initialize();
	kprint(str);
    kprint_newline();
    kprint_newline();

    idt_init();
    kb_init();
    
    while(1);
}

void print(const char* str){
    kprint_newline();
    kprint(str);
}