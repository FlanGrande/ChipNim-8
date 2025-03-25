import chip8/chip8
import chip8/opcodes
import chip8/display

proc main() =
    # Chip-8 Emulator loop

    # Initialize Chip8
    var chip8: Chip8 = initChip8()

    # Main loop
    while true:
        # Fetch
        let opcode1: uint8 = readMemory(chip8, chip8.pc)
        let opcode2: uint8 = readMemory(chip8, chip8.pc + uint16(1))
        let opcode: uint16 = (opcode1 shl 8) or opcode2
        advancePC(chip8)

        # Decode
        let nnn: uint16 = opcode and MASK_NNN
        let x: uint16 = opcode and MASK_X
        let y: uint16 = opcode and MASK_Y
        let n: uint16 = opcode and MASK_N
        let kk: uint16 = opcode and MASK_KK

        case opcode and MASK_OPCODE:
            of OPCODE_CLS: # Later on I can match with OPCODE_RET, and others in the same line
                if opcode == OPCODE_CLS:
                    clearScreen(chip8)
            of OPCODE_JP:
                jump(chip8, nnn)
            of OPCODE_LD_VX_KK:
                loadVx(chip8, x, kk)
            of OPCODE_ADD_VX_KK:
                addVx(chip8, x, kk)
            of OPCODE_LD_I_NNN:
                loadI(chip8, nnn)
            of OPCODE_DRAW:
                draw(chip8, x, y, n)
            else:
                echo "Unknown opcode: ", opcode


        if chip8.pc > 0xFFF:
            echo "Program finished"
            break
        
        


main()