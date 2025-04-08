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

import globals, strformat, std/os, std/streams, std/random, std/strutils, audio, opcodes
import chip8state

type
    Chip8* = object
        memory*: array[MEMORY_SIZE, uint8]
        V: array[16, uint8]           # 16 general purpose registers V0 to VF
        I: uint16                     # Index register
        pc*: uint16                   # Program counter
        step_counter*: uint32
        current_instruction*: string
        gfx*: array[DISPLAY_SIZE, uint8]    # Graphics: 64x32 monochrome display
        delay_timer: uint8
        sound_timer: uint8
        stack: array[16, uint16]
        sp: uint8                     # Stack pointer
        key: array[16, uint8]         # Hex-based keypad (0x0–0xF)
        waitingForKey*: bool
        waitingRegister: uint8
        romName*: string
        didDraw*: bool                 # Flag to indicate if the screen was drawn during the last frame

# Type to store the decoded components of an opcode
type
    DecodedOpcode* = object
        opcode*: uint16               # The full opcode
        nnn*: uint16                  # A 12-bit value (NNN)
        x*: uint8                     # A 4-bit register index (X)
        y*: uint8                     # A 4-bit register index (Y)
        n*: uint8                     # A 4-bit value (N)
        kk*: uint8                    # An 8-bit value (KK)

proc initChip8*(): Chip8 =
    result = Chip8()
    result.pc = PROGRAM_START              # Programs start at 0x200
    result.didDraw = false

    for i in 0..<FONTSET.len:
        result.memory[FONTSET_START + i] = FONTSET[i]

proc tickTimers*(chip8: var Chip8) =
    if chip8.delay_timer > 0:
        dec chip8.delay_timer

    if chip8.sound_timer > 0:
        dec chip8.sound_timer
        beep()
    else:
        unbeep()

proc readMemory*(chip8: var Chip8, address: uint16): uint16 =
    result = (chip8.memory[address].uint16 shl 8) or chip8.memory[address + 1].uint16

proc advancePC*(chip8: var Chip8) =
    chip8.pc += 2

proc keyDown*(chip8: var Chip8, key: uint8) =
    chip8.key[key] = 1

proc keyUp*(chip8: var Chip8, key: uint8) =
    chip8.key[key] = 0

    if chip8.waitingForKey:
        chip8.V[chip8.waitingRegister] = key
        chip8.waitingForKey = false

# 0x00E0
proc instruction_CLS*(chip8: var Chip8) =
    chip8.gfx = default(array[DISPLAY_SIZE, uint8])
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | 00 E0 | CLS"

# 0x00EE
proc instruction_RET*(chip8: var Chip8) =
    chip8.pc = chip8.stack[chip8.sp]
    dec chip8.sp
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | 00 EE | RET"
    
# 0x1nnn
proc instruction_JP*(chip8: var Chip8, nnn: uint16) =
    let firstByte = (nnn shr 8) and 0xFF
    let secondByte = nnn and 0xFF

    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | {firstByte:02X} {secondByte:02X} | JP 0x{nnn:04X}"
    chip8.pc = nnn

# 0x2nnn
proc instruction_CALL*(chip8: var Chip8, nnn: uint16) =
    let firstByte = (nnn shr 8) and 0xFF
    let secondByte = nnn and 0xFF
    
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | {firstByte:02X} {secondByte:02X} | CALL 0x{nnn:04X}"
    inc chip8.sp
    chip8.stack[chip8.sp] = chip8.pc
    chip8.pc = nnn

# 0x3xkk
proc instruction_SE_Vx_kk*(chip8: var Chip8, x: uint8, kk: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | 3{x:01X} {kk:02X} | SE V{x:01X}, {kk}"
    if chip8.V[x] == kk:
        advancePC(chip8)

# 0x4xkk
proc instruction_SNE_Vx_kk*(chip8: var Chip8, x: uint8, kk: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | 4{x:01X} {kk:02X} | SNE V{x:01X}, {kk}"
    if chip8.V[x] != kk:
        advancePC(chip8)

# 0x5xy0
proc instruction_SE_Vx_Vy*(chip8: var Chip8, x: uint8, y: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | 5{x:01X} {y:01X}0 | SE V{x:01X}, V{y:01X}"
    if chip8.V[x] == chip8.V[y]:
        advancePC(chip8)

# 0x6xkk
proc instruction_LD_Vx_kk*(chip8: var Chip8, x: uint8, kk: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | 6{x:01X} {kk:02X} | LD V{x:01X}, {kk}"
    chip8.V[x] = kk

# 0x7xkk
proc instruction_ADD_Vx_kk*(chip8: var Chip8, x: uint8, kk: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | 7{x:01X} {kk:02X} | ADD V{x:01X}, {kk}"
    chip8.V[x] += kk

# 0x8xy0
proc instruction_LD_Vx_Vy*(chip8: var Chip8, x: uint8, y: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | 8{x:01X} {y:01X}0 | LD V{x:01X}, V{y:01X}"
    chip8.V[x] = chip8.V[y]

# 0x8xy1
proc instruction_OR_Vx_Vy*(chip8: var Chip8, x: uint8, y: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | 8{x:01X} {y:01X}1 | OR V{x:01X}, V{y:01X}"
    chip8.V[x] = chip8.V[x] or chip8.V[y]
    chip8.V[0xF] = 0 # Chip-8 quirk

# 0x8xy2
proc instruction_AND_Vx_Vy*(chip8: var Chip8, x: uint8, y: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | 8{x:01X} {y:01X}2 | AND V{x:01X}, V{y:01X}"
    chip8.V[x] = chip8.V[x] and chip8.V[y]
    chip8.V[0xF] = 0 # Chip-8 quirk

# 0x8xy3
proc instruction_XOR_Vx_Vy*(chip8: var Chip8, x: uint8, y: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | 8{x:01X} {y:01X}3 | XOR V{x:01X}, V{y:01X}"
    chip8.V[x] = chip8.V[x] xor chip8.V[y]
    chip8.V[0xF] = 0 # Chip-8 quirk

# 0x8xy4
proc instruction_ADD_Vx_Vy*(chip8: var Chip8, x: uint8, y: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | 8{x:01X} {y:01X}4 | ADD V{x:01X}, V{y:01X}"
    let sum = chip8.V[x].uint16 + chip8.V[y].uint16
    chip8.V[x] = sum.uint8
    chip8.V[0xF] = if sum > 255: 1 else: 0

# 0x8xy5
proc instruction_SUB_Vx_Vy*(chip8: var Chip8, x: uint8, y: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | 8{x:01X} {y:01X}5 | SUB V{x:01X}, V{y:01X}"
    let carries = chip8.V[x] >= chip8.V[y]
    chip8.V[x] = (chip8.V[x] - chip8.V[y]).uint8
    chip8.V[0xF] = if carries: 1 else: 0

# 0x8xy6
proc instruction_SHR_Vx_Vy*(chip8: var Chip8, x: uint8, y: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | 8{x:01X} {y:01X}6 | SHR V{x:01X}, V{y:01X}"
    # Storing shifted Vy in Vx is a quirk of the Chip-8
    let shiftedVy = chip8.V[y] shr 1
    let lsb = chip8.V[x] and 0x1
    chip8.V[x] = shiftedVy
    chip8.V[0xF] = lsb

    # This version would be used on different Chip-8 interpreters
    # let lsb = chip8.V[x] and 0x1
    # chip8.V[x] = chip8.V[x] shr 1
    # chip8.V[0xF] = lsb

# 0x8xy7
proc instruction_SUBN_Vx_Vy*(chip8: var Chip8, x: uint8, y: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | 8{x:01X} {y:01X}7 | SUBN V{x:01X}, V{y:01X}"
    let carries = chip8.V[y] >= chip8.V[x]
    chip8.V[x] = (chip8.V[y] - chip8.V[x]).uint8
    chip8.V[0xF] = if carries: 1 else: 0

# 0x8xyE
proc instruction_SHL_Vx_Vy*(chip8: var Chip8, x: uint8, y: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | 8{x:01X} {y:01X}E | SHL V{x:01X}, V{y:01X}"
    # Storing shifted Vy in Vx is a quirk of the Chip-8
    let shiftedVy = chip8.V[y] shl 1
    let lsb = (chip8.V[x] shr 7) and 0x1
    chip8.V[x] = shiftedVy
    chip8.V[0xF] = lsb

    # This version would be used on different Chip-8 interpreters
    # let lsb = (chip8.V[x] shr 7) and 0x1
    # chip8.V[x] = chip8.V[x] shl 1
    # chip8.V[0xF] = lsb

# 0x9xy0
proc instruction_SNE_Vx_Vy*(chip8: var Chip8, x: uint8, y: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | 9{x:01X} {y:01X}0 | SNE V{x:01X}, V{y:01X}"
    if chip8.V[x] != chip8.V[y]:
        advancePC(chip8)

# 0xAnnn
proc instruction_LD_I_nnn*(chip8: var Chip8, nnn: uint16) =
    let firstByte = (nnn shr 8) and 0xFF
    let secondByte = nnn and 0xFF
    
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | {firstByte:02X} {secondByte:02X} | LD I, 0x{nnn:04X}"
    chip8.I = nnn

# 0xBnnn
proc instruction_JP_V0_nnn*(chip8: var Chip8, nnn: uint16) =
    let firstByte = (nnn shr 8) and 0xFF
    let secondByte = nnn and 0xFF
    
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | {firstByte:02X} {secondByte:02X} | JP V0, 0x{nnn:04X}"
    chip8.pc = chip8.V[0] or nnn

# 0xCxkk
proc instruction_RND_Vx_kk*(chip8: var Chip8, x: uint8, kk: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | C{x:01X} {kk:02X} | RND V{x:01X}, {kk}"
    chip8.V[x] = rand(256).uint8 and kk

# 0xDxyn
proc instruction_DRAW*(chip8: var Chip8, x: uint8, y: uint8, n: uint8, wrap: bool = false): bool =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | D{x:01X} {y:01X}{n:01X} | DRW V{x:01X}, V{y:01X}, {n}"
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

    # Update the chip8 didDraw flag
    chip8.didDraw = didDraw
    return didDraw

# 0xE09E
proc instruction_SKP_Vx*(chip8: var Chip8, x: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | E{x:01X} 9E | SKP V{x:01X}"
    if chip8.key[chip8.V[x]] == 1:
        advancePC(chip8)

# 0xE0A1
proc instruction_SKNP_Vx*(chip8: var Chip8, x: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | E{x:01X} A1 | SKNP V{x:01X}"
    if chip8.key[chip8.V[x]] == 0:
        advancePC(chip8)

# 0xFx07
proc instruction_LD_Vx_DT*(chip8: var Chip8, x: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | F{x:01X} 07 | LD V{x:01X}, DT"
    chip8.V[x] = chip8.delay_timer

# 0xFx0A
proc instruction_LD_Vx_K*(chip8: var Chip8, x: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | F{x:01X} 0A | LD V{x:01X}, K"
    chip8.waitingForKey = true
    chip8.waitingRegister = x

# 0xFx15
proc instruction_LD_DT_Vx*(chip8: var Chip8, x: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | F{x:01X} 15 | LD DT, V{x:01X}"
    chip8.delay_timer = chip8.V[x]

# 0xFx18
proc instruction_LD_ST_Vx*(chip8: var Chip8, x: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | F{x:01X} 18 | LD ST, V{x:01X}"
    chip8.sound_timer = chip8.V[x]

# 0xFx1E
proc instruction_ADD_I_Vx*(chip8: var Chip8, x: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | F{x:01X} 1E | ADD I, V{x:01X}"
    chip8.I += chip8.V[x]

# 0xFx29
proc instruction_LD_F_Vx*(chip8: var Chip8, x: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | F{x:01X} 29 | LD F, V{x:01X}"
    chip8.I = chip8.V[x] * FONTSET_WIDTH

# 0xFx33
proc instruction_LD_BCD_Vx*(chip8: var Chip8, x: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | F{x:01X} 33 | LD B, V{x:01X}"
    let hundreds = chip8.V[x] div 100
    let tens = (chip8.V[x] div 10) mod 10
    let units = chip8.V[x] mod 10

    chip8.memory[chip8.I] = hundreds
    chip8.memory[chip8.I + 1] = tens
    chip8.memory[chip8.I + 2] = units

# 0xFx55
proc instruction_LD_I_Vx*(chip8: var Chip8, x: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | F{x:01X} 55 | LD I, V{x:01X}"
    for i in uint8(0)..x:
        chip8.memory[chip8.I + i] = chip8.V[i]
    
    chip8.I += x + 1 # Chip8 quirk

# 0xFx65
proc instruction_LD_Vx_I*(chip8: var Chip8, x: uint8) =
    chip8.current_instruction = &"0x{chip8.pc - 2:03X} | F{x:01X} 65 | LD V{x:01X}, I"
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
    
    # Trim filename so that it has only the name of the file until there's a ( or a [
    chip8.romName = filename.split("(")[0].split("[")[0]

# New functions for fetch-decode-execute cycle

# Fetch the next opcode
proc fetchOpcode*(chip8: var Chip8): uint16 =
    if chip8.waitingForKey:
        return 0
    result = readMemory(chip8, chip8.pc)
    advancePC(chip8)

# Decode the opcode into its components
proc decodeOpcode*(opcode: uint16): DecodedOpcode =
    result.opcode = opcode
    result.nnn = opcode and MASK_NNN
    result.x = ((opcode and MASK_X) shr 8).uint8
    result.y = ((opcode and MASK_Y) shr 4).uint8
    result.n = (opcode and MASK_N).uint8
    result.kk = (opcode and MASK_KK).uint8

# Execute a decoded opcode
proc executeOpcode*(chip8: var Chip8, decoded: DecodedOpcode): bool =
    # Reset the didDraw flag before executing
    chip8.didDraw = false
    
    # Skip execution if waiting for key
    if chip8.waitingForKey:
        return false
    
    let opcode = decoded.opcode
    let nnn = decoded.nnn
    let x = decoded.x
    let y = decoded.y
    let n = decoded.n
    let kk = decoded.kk
    
    case opcode and 0xF000:
        of OPCODE_ZERO:
            if opcode == OPCODE_CLS:
                instruction_CLS(chip8)
            elif opcode == OPCODE_RET:
                instruction_RET(chip8)
            else:
                return false
        of OPCODE_JP:
            instruction_JP(chip8, nnn)
        of OPCODE_CALL:
            instruction_CALL(chip8, nnn)
        of OPCODE_SE_VX_KK:
            instruction_SE_Vx_kk(chip8, x, kk)
        of OPCODE_SNE_VX_KK:
            instruction_SNE_Vx_kk(chip8, x, kk)
        of OPCODE_SE_VX_VY:
            instruction_SE_Vx_Vy(chip8, x, y)
        of OPCODE_LD_VX_KK:
            instruction_LD_Vx_kk(chip8, x, kk)
        of OPCODE_ADD_VX_KK:
            instruction_ADD_Vx_kk(chip8, x, kk)
        of OPCODE_8:
            case opcode and 0xF00F:
                of OPCODE_LD_VX_VY:
                    instruction_LD_Vx_Vy(chip8, x, y)
                of OPCODE_OR_VX_VY:
                    instruction_OR_Vx_Vy(chip8, x, y)
                of OPCODE_AND_VX_VY:
                    instruction_AND_Vx_Vy(chip8, x, y)
                of OPCODE_XOR_VX_VY:
                    instruction_XOR_Vx_Vy(chip8, x, y)
                of OPCODE_ADD_VX_VY:
                    instruction_ADD_Vx_Vy(chip8, x, y)
                of OPCODE_SUB_VX_VY:
                    instruction_SUB_Vx_Vy(chip8, x, y)
                of OPCODE_SHR_VX_VY:
                    instruction_SHR_Vx_Vy(chip8, x, y)
                of OPCODE_SUBN_VX_VY:
                    instruction_SUBN_Vx_Vy(chip8, x, y)
                of OPCODE_SHL_VX_VY:
                    instruction_SHL_Vx_Vy(chip8, x, y)
                else:
                    return false
        of OPCODE_SNE_VX_VY:
            instruction_SNE_Vx_Vy(chip8, x, y)
        of OPCODE_LD_I_NNN:
            instruction_LD_I_nnn(chip8, nnn)
        of OPCODE_JP_V0_NNN:
            instruction_JP_V0_nnn(chip8, nnn)
        of OPCODE_RND_VX_KK:
            instruction_RND_Vx_kk(chip8, x, kk)
        of OPCODE_DRAW:
            chip8.didDraw = instruction_DRAW(chip8, x, y, n)
        of OPCODE_E:
            case opcode and 0xF0FF:
                of OPCODE_SKP_VX:
                    instruction_SKP_Vx(chip8, x)
                of OPCODE_SKNP_VX:
                    instruction_SKNP_Vx(chip8, x)
                else:
                    return false
        of OPCODE_F:
            case opcode and 0xF0FF:
                of OPCODE_LD_VX_DT:
                    instruction_LD_Vx_DT(chip8, x)
                of OPCODE_LD_VX_K:
                    instruction_LD_Vx_K(chip8, x)
                of OPCODE_LD_DT_VX:
                    instruction_LD_DT_Vx(chip8, x)
                of OPCODE_LD_ST_VX:
                    instruction_LD_ST_Vx(chip8, x)
                of OPCODE_ADD_I_VX:
                    instruction_ADD_I_Vx(chip8, x)
                of OPCODE_LD_F_VX:
                    instruction_LD_F_Vx(chip8, x)
                of OPCODE_LD_BCD_VX:
                    instruction_LD_BCD_Vx(chip8, x)
                of OPCODE_LD_I_VX:
                    instruction_LD_I_Vx(chip8, x)
                of OPCODE_LD_VX_I:
                    instruction_LD_Vx_I(chip8, x)
                else:
                    return false
        else:
            return false
    
    chip8.step_counter += 1

    return true

# Execute a single emulation cycle
proc emulateCycle*(chip8: var Chip8): bool =
    # Fetch
    let opcode = fetchOpcode(chip8)
    
    # Decode
    let decoded = decodeOpcode(opcode)
    
    # Execute
    return executeOpcode(chip8, decoded)

# Emulate a full frame (multiple cycles)
proc emulateFrame*(chip8: var Chip8, cyclesPerFrame: int = OPCODES_PER_FRAME): bool =
    var didDrawInFrame = false
    
    for _ in 0..<cyclesPerFrame:
        if chip8.waitingForKey:
            break
            
        let cycleResult = emulateCycle(chip8)
        if not cycleResult:
            continue
            
        # Check if we drew to the screen
        if chip8.didDraw:
            didDrawInFrame = true
    
    # Update timers at the end of the frame
    tickTimers(chip8)
    
    return didDrawInFrame

# State management functionality

# Creates a Chip8State from the current state of the emulator
proc saveState*(chip8: var Chip8): Chip8State =
    result = Chip8State(
        memory: chip8.memory,
        V: chip8.V,
        I: chip8.I,
        pc: chip8.pc,
        gfx: chip8.gfx,
        didDraw: chip8.didDraw,
        delay_timer: chip8.delay_timer,
        sound_timer: chip8.sound_timer,
        stack: chip8.stack,
        sp: chip8.sp,
        key: chip8.key,
        waitingForKey: chip8.waitingForKey,
        waitingRegister: chip8.waitingRegister,
        romName: chip8.romName
    )

# Restores the emulator to a previously saved state
proc loadState*(chip8: var Chip8, state: Chip8State) =
    chip8.memory = state.memory
    chip8.V = state.V
    chip8.I = state.I
    chip8.pc = state.pc
    chip8.gfx = state.gfx
    chip8.didDraw = state.didDraw
    chip8.delay_timer = state.delay_timer
    chip8.sound_timer = state.sound_timer
    chip8.stack = state.stack
    chip8.sp = state.sp
    chip8.key = state.key
    chip8.waitingForKey = state.waitingForKey
    chip8.waitingRegister = state.waitingRegister
    chip8.romName = state.romName