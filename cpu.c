#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>

extern uint8_t a, x;
extern uint16_t pc;

static uint8_t memory_map[0x10000];

uint8_t read6502(uint16_t address) {
	return memory_map[address];
}

void write6502(uint16_t address, uint8_t value) {
	memory_map[address] = value;
}

void print_mem(uint16_t start, uint16_t end) {
	if (start > end) {
		printf("Invalid memory bounds (start-end): %#04x-%#04x\n",start,end);
		exit(3);
	}
	
	uint16_t iter = start;
	while (iter < end) {
		if ((iter-start) % 0x10 == 0) {
			if (start != iter) {printf("\n");}
			printf("%04x:", iter);
		}
		if ((iter-start) % 2 == 0) {printf(" ");}

		printf("%02x", memory_map[iter]);
		++iter;
	}
	printf("\n");
}

int main(int argc, char* argv[]) {
	
	uint16_t load_address;
	uint16_t init_address;
	uint16_t play_address;
	uint16_t mem_address;
	uint8_t num_songs;
	uint8_t ntscpal;
	uint8_t byte;
	char user_input;

	printf("START!\n");
	
	// check for filename and song number
	if (argc != 3) {
		printf("ERROR: args suck\n");
		exit(1);
	}	

	// open file
	FILE* nsf;
	if ((nsf = fopen(argv[1],"rb")) == NULL) {
		printf("ERROR: file sucks\n");
		exit(2);
	}

	// get number of songs
	fseek(nsf, 0x6, SEEK_SET);
	fread(&num_songs, 0x1, 1, nsf);

	// get song selection, check valid
	int current_song = atoi(argv[2]);
	if (current_song < 1 || current_song > num_songs) {
		printf("Invalid song number: %d out of %d\n", current_song, (int) num_songs);
		exit(5);
	}

	// get NTSC/PAL bits
	fseek(nsf, 0x7a, SEEK_SET);
	fread(&ntscpal, 0x1, 1, nsf);

	// get load address
	fseek(nsf, 0x8, SEEK_SET);
	fread(&load_address, 0x2, 1, nsf);

	// get init address
	fseek(nsf, 0xa, SEEK_SET);
	fread(&init_address, 0x2, 1, nsf);

	// get play address
	fseek(nsf, 0xc, SEEK_SET);
	fread(&play_address, 0x2, 1, nsf);

	printf("LOAD %#04x\n", load_address);
	printf("INIT %#04x\n", init_address);
	printf("PLAY %#04x\n", play_address);

	// set pc to init_address
	memory_map[0xfffc] = (uint8_t) init_address;
	memory_map[0xfffd] = (uint8_t) (init_address >> 8);
	reset6502();
	
	// initialize sound registers
	uint16_t reg = 0x4000;
	for (; reg <= 0x4013; ++reg) {
		memory_map[reg] = 0x00;
	}
	memory_map[0x4015] = 0x0f;

	// initialize frame counter
	memory_map[0x4017] = 0x40;

	// Ignore bank switching

	// Set A register to selected song 
	a = (uint8_t) current_song-1;

	// Set X register to NTSC (0) or PAL (1)
	x = (uint8_t) (ntscpal & 0x01);
	
	// Load data from 0x80 to end of nsf file
	fseek(nsf, 0x80, SEEK_SET); // data start
	uint8_t* copy_ptr = &memory_map[load_address];
	while (fread(&byte, 1, 1, nsf) == 1) {
		*copy_ptr = byte;
		++copy_ptr;
	}

	// check if rom copying has exceeded the end of memory map
	if ((copy_ptr-memory_map) > 0x10000) {
		printf("ROM copy exceeds memory map: %#lx\n", (unsigned long) (copy_ptr-memory_map));
		exit(4);
	}
	
	// close file
	fclose(nsf);

	push16(0x4016-1); // push end address to stack
	push16(play_address-1); // push play address to stack

	// INIT routine
	//do {
	//	step6502();
	//	printf("A: %#04x X: %#04x PC: %#04x\n",a,x,pc);
	//} while (memory_map[pc] != 0x60); // RTS command

	//pc = play_address;

	// PLAY routine
	do {
		step6502();
		//printf("\nPLAY ADDRESS\n");
		//print_mem(play_address, play_address+100);
		printf("\nAPU REGS\n");
		print_mem(0x4000, 0x4018);
		//printf("\nA:    %#04x\nX:    %#04x\nPC: %#04x\n",a,x,pc);
		printf("A: %#04x X: %#04x PC: %#04x\n",a,x,pc);

		//printf("Press [n]ext instruction or [q]uit: ");
		//scanf(" %c", &user_input);
	//} while (user_input == 'n');
		usleep(10000);
	} while (pc != 0x4016); // RTS command

		//printf("\nLOAD ADDRESS\n");
		//print_mem(load_address, load_address+100);
		//printf("\nINIT ADDRESS\n");
		//print_mem(init_address, init_address+100);


	// write6502(0x4000, 0xCA);
	// printf("%#04x\n",  (unsigned char) read6502(0x4000));
	printf("END!\n");


	return 0;
}

