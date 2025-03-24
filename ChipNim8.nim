proc main() =
    # Chip-8 Emulator loop

    # Initialize Chip8
    let chip8 = initChip8()

    # Main loop
    while true:
        # Fetch
        let opcode: uint16 = (chip8.memory[chip8.pc] << 8) or chip8.memory[chip8.pc + 1] 

        # Decode
        


main()