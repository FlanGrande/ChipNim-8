#[ 

Chip-8 Core

4096KB of memory
Programs start running at 0x200, 0x000-0x1FF is reserved for the interpreter
Some programs start at 0x600

Memory Map:
+---------------+= 0xFFF (4096) End of Chip-8 RAM
|               |
|               |
|               |
|               |
|               |
| 0x200 to 0xFFF|
|     Chip-8    |
| Program / Data|
|     Space     |
|               |
|               |
|               |
+- - - - - - - -+= 0x600 (1536) Start of ETI 660 Chip-8 programs
|               |
|               |
|               |
+---------------+= 0x200 (512) Start of most Chip-8 programs
| 0x000 to 0x1FF|
| Reserved for  |
|  interpreter  |
+---------------+= 0x000 (0) Start of Chip-8 RAM

16 general purpose registers V0 to VF
Index register: used to point to memory locations, usually sprites
Program counter: points to the current instruction in memory

The delay timer is active whenever the delay timer register (DT) is non-zero.
This timer does nothing more than subtract 1 from the value of DT at a rate of 60Hz.
When DT reaches 0, it deactivates.

The sound timer is active whenever the sound timer register (ST) is non-zero.
This timer also decrements at a rate of 60Hz, however, as long as ST's value is greater than zero, the Chip-8 buzzer will sound.
When ST reaches zero, the sound timer deactivates.
The sound produced by the Chip-8 interpreter has only one tone.
The frequency of this tone is decided by the author of the interpreter.

All instructions are 2 bytes long and are stored most-significant-byte first.
In memory, the first byte of each instruction should be located at an even addresses.
If a program includes sprite data, it should be padded so any instructions following it will be properly situated in RAM.

nnn or addr - A 12-bit value, the lowest 12 bits of the instruction
n or nibble - A 4-bit value, the lowest 4 bits of the instruction
x - A 4-bit value, the lower 4 bits of the high byte of the instruction
y - A 4-bit value, the upper 4 bits of the low byte of the instruction
kk or byte - An 8-bit value, the lowest 8 bits of the instruction

]#

import globals, std/os, std/streams

type
    Chip8* = object
        memory*: array[MEMORY_SIZE, uint8]
        V: array[16, uint8]           # 16 general purpose registers V0 to VF
        I: uint16                     # Index register
        pc*: uint16                   # Program counter
        gfx*: array[DISPLAY_SIZE, uint8]    # Graphics: 64x32 monochrome display
        delay_timer: uint8
        sound_timer: uint8
        stack: array[16, uint16]
        sp: uint8                     # Stack pointer
        key: array[16, uint8]         # Hex-based keypad (0x0–0xF)

proc initChip8*(): Chip8 =
    result = Chip8()
    result.pc = PROGRAM_START              # Programs start at 0x200

    for i in 0..<FONTSET.len:
        result.memory[FONTSET_START + i] = FONTSET[i]

proc tickTimers*(chip8: var Chip8) =
    if chip8.delay_timer > 0:
        dec chip8.delay_timer

    if chip8.sound_timer > 0:
        dec chip8.sound_timer

proc readMemory*(chip8: var Chip8, address: uint16): uint8 =
    result = chip8.memory[address]

proc advancePC*(chip8: var Chip8) =
    chip8.pc += 2




proc clearScreen*(chip8: var Chip8) =
    chip8.gfx = default(array[DISPLAY_SIZE, uint8])

proc jump*(chip8: var Chip8, nnn: uint16) =
    chip8.pc = nnn

# Caution: Chip8 registers are 8-bit, so we need to cast kk to uint8
# This might end up with unexpected results if kk is not in the range [0, 255]
# Maybe it would wrap around, but I'm not even sure
proc loadVx*(chip8: var Chip8, x: uint8, kk: uint8) =
    chip8.V[x] = kk

proc addVx*(chip8: var Chip8, x: uint8, kk: uint8) =
    chip8.V[x] += kk

proc loadI*(chip8: var Chip8, nnn: uint16) =
    chip8.I = nnn

proc draw*(chip8: var Chip8, x: uint8, y: uint8, n: uint8): bool =
    let coordX = chip8.V[x] mod DISPLAY_WIDTH
    let coordY = chip8.V[y] mod DISPLAY_HEIGHT
    var didDraw: bool = false

    chip8.V[0xF] = 0 # Why do we do this?

    for row in 0..<uint(n):
        let spriteByte = chip8.memory[chip8.I + row]

        for bit in 0..<uint(SPRITE_WIDTH):
            let pixelX = (coordX + bit) mod DISPLAY_WIDTH
            let pixelY = (coordY + row) mod DISPLAY_HEIGHT
            let index = pixelX + pixelY * DISPLAY_WIDTH

            let spritePixel = (spriteByte shr (7 - bit)) and 1
            let oldPixel = chip8.gfx[index]
            chip8.gfx[index] = oldPixel xor spritePixel

            if oldPixel == 1 and spritePixel == 1:
                chip8.V[0xF] = 1
            
            if spritePixel == 1:
                didDraw = true

    return didDraw




proc loadRom*(chip8: var Chip8, filename: string) =
    if not fileExists(filename):
        quit("ROM file not found: " & filename)

    let f = newFileStream(filename, fmRead)
    if f == nil:
        quit("Failed to open ROM file")

    defer: f.close()

    var i = 0
    while not f.atEnd() and PROGRAM_START + i < MEMORY_SIZE:
        let dataByte = f.readUint8()
        chip8.memory[PROGRAM_START + i] = dataByte
        inc i