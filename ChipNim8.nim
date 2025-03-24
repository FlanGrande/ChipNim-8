import chip8/chip8
import chip8/opcodes

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
        case opcode and MASK_OPCODE:
            of OPCODE_CLS: # Later on I can match with OPCODE_RET, and others in the same line
                if opcode == OPCODE_CLS:
                    clearScreen(chip8)


        if chip8.pc > 0xFFF:
            echo "Program finished"
            break
        
        


main()