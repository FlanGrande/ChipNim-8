import sdl3
import chip8/chip8
import chip8/display
import chip8/globals
import chip8/opcodes

proc main() =
    # Chip-8 Emulator loop
    if not SDL_Init(SDL_INIT_VIDEO):
        quit("SDL_Init Error: " & $SDL_GetError())

    let win = SDL_CreateWindow("Hello SDL2", PIXEL_WIDTH * DISPLAY_WIDTH, PIXEL_HEIGHT * DISPLAY_HEIGHT, 0)
    if win == nil:
        quit("SDL_CreateWindow Error: " & $SDL_GetError())

    let renderer = SDL_CreateRenderer(win, nil)
    if renderer == nil:
        quit("SDL_CreateRenderer Error: " & $SDL_GetError())

    
    # Initialize Chip8
    var chip8: Chip8 = initChip8()
    var running: bool = true
    var event: SDL_Event # I think this is already a pointer, no need to use (addr)

    while running:
        var requestFrame: bool = false

        while SDL_PollEvent(event):
            if event.type == SDL_EventQuit:
                running = false

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
                requestFrame = draw(chip8, x, y, n)
            else:
                echo "Unknown opcode: ", opcode


        if chip8.pc > 0xFFF:
            echo "Program finished"
            break

        if requestFrame:
            SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255)
            SDL_RenderClear(renderer)
            render(renderer, chip8.gfx)
            SDL_RenderPresent(renderer)

    # Cleanup
    SDL_DestroyRenderer(renderer)
    SDL_DestroyWindow(win)
    SDL_Quit()

main()