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

import globals, std/os, std/streams, std/random

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
        waitingForKey*: bool
        waitingRegister: uint8

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

proc keyDown*(chip8: var Chip8, key: uint8) =
    chip8.key[key] = 1

    if chip8.waitingForKey:
        chip8.V[chip8.waitingRegister] = key
        chip8.waitingForKey = false
        advancePC(chip8)

proc keyUp*(chip8: var Chip8, key: uint8) =
    chip8.key[key] = 0

# 0x00E0
proc instruction_CLS*(chip8: var Chip8) =
    chip8.gfx = default(array[DISPLAY_SIZE, uint8])

# 0x00EE
proc instruction_RET*(chip8: var Chip8) =
    chip8.pc = chip8.stack[chip8.sp]
    dec chip8.sp

# 0x1nnn
proc instruction_JP*(chip8: var Chip8, nnn: uint16) =
    chip8.pc = nnn

# 0x2nnn
proc instruction_CALL*(chip8: var Chip8, nnn: uint16) =
    inc chip8.sp
    chip8.stack[chip8.sp] = chip8.pc
    chip8.pc = nnn

# 0x3xkk
proc instruction_SE_Vx_kk*(chip8: var Chip8, x: uint8, kk: uint8) =
    if chip8.V[x] == kk:
        advancePC(chip8)

# 0x4xkk
proc instruction_SNE_Vx_kk*(chip8: var Chip8, x: uint8, kk: uint8) =
    if chip8.V[x] != kk:
        advancePC(chip8)

# 0x5xy0
proc instruction_SE_Vx_Vy*(chip8: var Chip8, x: uint8, y: uint8) =
    if chip8.V[x] == chip8.V[y]:
        advancePC(chip8)

# 0x6xkk
proc instruction_LD_Vx_kk*(chip8: var Chip8, x: uint8, kk: uint8) =
    chip8.V[x] = kk

# 0x7xkk
proc instruction_ADD_Vx_kk*(chip8: var Chip8, x: uint8, kk: uint8) =
    chip8.V[x] += kk

# 0x8xy0
proc instruction_LD_Vx_Vy*(chip8: var Chip8, x: uint8, y: uint8) =
    chip8.V[x] = chip8.V[y]

# 0x8xy1
proc instruction_OR_Vx_Vy*(chip8: var Chip8, x: uint8, y: uint8) =
    chip8.V[x] = chip8.V[x] or chip8.V[y]
    chip8.V[0xF] = 0 # Chip-8 quirk

# 0x8xy2
proc instruction_AND_Vx_Vy*(chip8: var Chip8, x: uint8, y: uint8) =
    chip8.V[x] = chip8.V[x] and chip8.V[y]
    chip8.V[0xF] = 0 # Chip-8 quirk

# 0x8xy3
proc instruction_XOR_Vx_Vy*(chip8: var Chip8, x: uint8, y: uint8) =
    chip8.V[x] = chip8.V[x] xor chip8.V[y]
    chip8.V[0xF] = 0 # Chip-8 quirk

# 0x8xy4
proc instruction_ADD_Vx_Vy*(chip8: var Chip8, x: uint8, y: uint8) =
    let sum = chip8.V[x].uint16 + chip8.V[y].uint16
    chip8.V[x] = sum.uint8
    chip8.V[0xF] = if sum > 255: 1 else: 0

# 0x8xy5
proc instruction_SUB_Vx_Vy*(chip8: var Chip8, x: uint8, y: uint8) =
    let carries = chip8.V[x] >= chip8.V[y]
    chip8.V[x] = (chip8.V[x] - chip8.V[y]).uint8
    chip8.V[0xF] = if carries: 1 else: 0

# 0x8xy6
proc instruction_SHR_Vx_Vy*(chip8: var Chip8, x: uint8, y: uint8) =
    let lsb = chip8.V[x] and 0x1
    chip8.V[x] = chip8.V[x] shr 1
    chip8.V[0xF] = lsb

# 0x8xy7
proc instruction_SUBN_Vx_Vy*(chip8: var Chip8, x: uint8, y: uint8) =
    let carries = chip8.V[y] >= chip8.V[x]
    chip8.V[x] = (chip8.V[y] - chip8.V[x]).uint8
    chip8.V[0xF] = if carries: 1 else: 0

# 0x8xyE
proc instruction_SHL_Vx_Vy*(chip8: var Chip8, x: uint8, y: uint8) =
    let lsb = (chip8.V[x] shr 7) and 0x1
    chip8.V[x] = chip8.V[x] shl 1
    chip8.V[0xF] = lsb

# 0x9xy0
proc instruction_SNE_Vx_Vy*(chip8: var Chip8, x: uint8, y: uint8) =
    if chip8.V[x] != chip8.V[y]:
        advancePC(chip8)

# 0xAnnn
proc instruction_LD_I_nnn*(chip8: var Chip8, nnn: uint16) =
    chip8.I = nnn

# 0xBnnn
proc instruction_JP_V0_nnn*(chip8: var Chip8, nnn: uint16) =
    chip8.pc = chip8.V[0] or nnn

# 0xCxkk
proc instruction_RND_Vx_kk*(chip8: var Chip8, x: uint8, kk: uint8) =
    chip8.V[x] = rand(256).uint8 and kk

# 0xDxyn
proc instruction_DRAW*(chip8: var Chip8, x: uint8, y: uint8, n: uint8, wrap: bool = false): bool =
    let coordX = chip8.V[x] mod DISPLAY_WIDTH
    let coordY = chip8.V[y] mod DISPLAY_HEIGHT
    var didDraw: bool = false

    chip8.V[0xF] = 0

    for row in 0..<uint(n):
        let spriteByte = chip8.memory[chip8.I + row]

        for bit in 0..<uint(SPRITE_WIDTH):
            var pixelX = coordX + bit
            var pixelY = coordY + row

            if pixelX >= DISPLAY_WIDTH or pixelY >= DISPLAY_HEIGHT:
                if wrap:
                    pixelX = (coordX + bit) mod DISPLAY_WIDTH
                    pixelY = (coordY + row) mod DISPLAY_HEIGHT
                else:
                    continue # Chip-8 quirk: clipping instead of wrapping around
            
            let index = pixelX + pixelY * DISPLAY_WIDTH
            let spritePixel = (spriteByte shr (7 - bit)) and 1
            let oldPixel = chip8.gfx[index]
            chip8.gfx[index] = oldPixel xor spritePixel

            if oldPixel == 1 and spritePixel == 1:
                chip8.V[0xF] = 1
            
            if spritePixel == 1:
                didDraw = true

    return didDraw

# 0xE09E
proc instruction_SKP_Vx*(chip8: var Chip8, x: uint8) =
    if chip8.key[chip8.V[x]] == 1:
        advancePC(chip8)

# 0xE0A1
proc instruction_SKNP_Vx*(chip8: var Chip8, x: uint8) =
    if chip8.key[chip8.V[x]] == 0:
        advancePC(chip8)

# 0xFx07
proc instruction_LD_Vx_DT*(chip8: var Chip8, x: uint8) =
    chip8.V[x] = chip8.delay_timer

# 0xFx0A
proc instruction_LD_Vx_K*(chip8: var Chip8, x: uint8) =
    chip8.waitingForKey = true
    chip8.waitingRegister = x

# 0xFx15
proc instruction_LD_DT_Vx*(chip8: var Chip8, x: uint8) =
    chip8.delay_timer = chip8.V[x]

# 0xFx18
proc instruction_LD_ST_Vx*(chip8: var Chip8, x: uint8) =
    chip8.sound_timer = chip8.V[x]

# 0xFx1E
proc instruction_ADD_I_Vx*(chip8: var Chip8, x: uint8) =
    chip8.I += chip8.V[x]

# 0xFx29
proc instruction_LD_F_Vx*(chip8: var Chip8, x: uint8) =
    chip8.I = chip8.V[x] * FONTSET_WIDTH

# 0xFx33
proc instruction_LD_BCD_Vx*(chip8: var Chip8, x: uint8) =
    let hundreds = chip8.V[x] div 100
    let tens = (chip8.V[x] div 10) mod 10
    let units = chip8.V[x] mod 10

    chip8.memory[chip8.I] = hundreds
    chip8.memory[chip8.I + 1] = tens
    chip8.memory[chip8.I + 2] = units

# 0xFx55
proc instruction_LD_I_Vx*(chip8: var Chip8, x: uint8) =
    for i in uint8(0)..x:
        chip8.memory[chip8.I + i] = chip8.V[i]
    
    chip8.I += x + 1 # Chip8 quirk

# 0xFx65
proc instruction_LD_Vx_I*(chip8: var Chip8, x: uint8) =
    for i in uint8(0)..x:
        chip8.V[i] = chip8.memory[chip8.I + i]
    
    chip8.I += x + 1 # Chip8 quirk

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