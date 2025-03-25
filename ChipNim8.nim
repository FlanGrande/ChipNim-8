import sdl3
import std/strutils
import chip8/chip8
import chip8/display
import chip8/globals
import chip8/opcodes

proc main() =
    # Chip-8 Emulator loop
    if not SDL_Init(SDL_INIT_VIDEO):
        quit("SDL_Init Error: " & $SDL_GetError())

    let win = SDL_CreateWindow("Hello SDL3", PIXEL_WIDTH * DISPLAY_WIDTH, PIXEL_HEIGHT * DISPLAY_HEIGHT, 0)
    if win == nil:
        quit("SDL_CreateWindow Error: " & $SDL_GetError())

    let renderer = SDL_CreateRenderer(win, nil)
    if renderer == nil:
        quit("SDL_CreateRenderer Error: " & $SDL_GetError())

    
    # Initialize Chip8
    var chip8: Chip8 = initChip8()
    var running: bool = true
    var event: SDL_Event # I think this is already a pointer, no need to use (addr)

    # Load ROM
    loadRom(chip8, "roms/programs/IBM Logo.ch8")

    while running:
        # Process input
        let frameStart: uint64 = SDL_GetTicks()
        var requestFrame: bool = false

        while SDL_PollEvent(event):
            if event.type == SDL_EventQuit:
                running = false
        
        for _ in 0..<OPCODES_PER_FRAME:
            # Fetch
            let opcode1: uint8 = readMemory(chip8, chip8.pc)
            let opcode2: uint8 = readMemory(chip8, chip8.pc + 1)
            let opcode: uint16 = (opcode1.uint16 shl 8) or opcode2.uint16
            # let opcode = (chip8.memory[chip8.pc].uint16 shl 8) or chip8.memory[chip8.pc + 1].uint16

            advancePC(chip8)

            # Decode
            let nnn: uint16 = opcode and MASK_NNN
            let x: uint16 = (opcode and MASK_X) shr 8
            let y: uint16 = (opcode and MASK_Y) shr 4
            let n: uint16 = opcode and MASK_N
            let kk: uint16 = opcode and MASK_KK
            
            echo "Opcode: ", toHex(opcode, 4)
            echo "nnn: ", toHex(nnn, 4)
            echo "x: ", toHex(x, 4)
            echo "y: ", toHex(y, 4)
            echo "n: ", toHex(n, 4)
            echo "kk: ", toHex(kk, 4)

            case opcode and MASK_OPCODE:
                of 0x0000:
                    if opcode == OPCODE_CLS: # Later on I can match with OPCODE_RET, and others in the same line
                        clearScreen(chip8)
                    else:
                        if opcode != 0x0000:
                            echo "Unknown opcode: ", toHex(opcode, 4)
                of OPCODE_JP:
                    jump(chip8, nnn)
                of OPCODE_LD_VX_KK:
                    loadVx(chip8, x, kk)
                of OPCODE_ADD_VX_KK:
                    addVx(chip8, x, kk)
                of OPCODE_LD_I_NNN:
                    loadI(chip8, nnn)
                of OPCODE_DRAW:
                    requestFrame = draw(chip8, x, y, n)
                else:
                    echo "Unknown opcode: ", toHex(opcode, 4)

            if chip8.pc > 0xFFF:
                echo "Program finished"
                SDL_Delay(5000)
                running = false
                break
            
        tickTimers(chip8)
       
        let frameTime: uint64 = SDL_GetTicks() - frameStart
        if frameTime < 1000 div 60:
            SDL_Delay(1000 div 60 - uint32(frameTime))
        
        #if requestFrame:
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255)
        SDL_RenderClear(renderer)
        render(renderer, chip8.gfx)
        SDL_RenderPresent(renderer)
        
    # Cleanup
    SDL_DestroyRenderer(renderer)
    SDL_DestroyWindow(win)
    SDL_Quit()

main()