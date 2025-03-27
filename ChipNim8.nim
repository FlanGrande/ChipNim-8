import sdl3
import std/strutils
import sequtils
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

    var missingOpcodes: seq[uint16] = @[]

    # Load ROM
    #loadRom(chip8, "roms/programs/IBM Logo.ch8")
    #loadRom(chip8, "roms/programs/Fishie [Hap, 2005].ch8")
    #loadRom(chip8, "roms/programs/Clock Program [Bill Fisher, 1981].ch8")
    loadRom(chip8, "roms/programs/Life [GV Samways, 1980].ch8")

    while running:
        # Process input
        let frameStart: uint64 = SDL_GetTicks()
        var requestFrame: bool = false

        while SDL_PollEvent(event):
            if event.type == SDL_EventQuit:
                running = false
        
        for _ in 0..<OPCODES_PER_FRAME:
            # Fetch
            let hiByte: uint16 = readMemory(chip8, chip8.pc).uint16 shl 8
            let loByte: uint16 = readMemory(chip8, chip8.pc + 1).uint16
            let opcode: uint16 = hiByte or loByte

            advancePC(chip8)

            # Decode
            let nnn: uint16 = opcode and MASK_NNN
            let x: uint8 = ((opcode and MASK_X) shr 8).uint8
            let y: uint8 = ((opcode and MASK_Y) shr 4).uint8
            let n: uint8 = (opcode and MASK_N).uint8
            let kk: uint8 = (opcode and MASK_KK).uint8
            
            echo "opcode: ", toHex(opcode, 4)
            echo "nnn: ", toHex(nnn, 4)
            echo "x: ", toHex(x, 4)
            echo "y: ", toHex(y, 4)
            echo "n: ", toHex(n, 4)
            echo "kk: ", toHex(kk, 4)

            case opcode and 0xF000:
                of 0x0000:
                    if opcode == OPCODE_CLS:
                        instruction_CLS(chip8)
                    elif opcode == OPCODE_RET:
                        instruction_RET(chip8)
                    else:
                        echo "Unknown opcode: ", toHex(opcode, 4)
                        missingOpcodes.add(opcode)
                of 0x1000:
                    instruction_JP(chip8, nnn)
                of 0x2000:
                    instruction_CALL(chip8, nnn)
                of 0x3000:
                    instruction_SE_Vx_kk(chip8, x, kk)
                of 0x4000:
                    instruction_SNE_Vx_kk(chip8, x, kk)
                of 0x5000:
                    instruction_SE_Vx_Vy(chip8, x, y)
                of 0x6000:
                    instruction_LD_Vx_kk(chip8, x, kk)
                of 0x7000:
                    instruction_ADD_Vx_kk(chip8, x, kk)
                # TO DO: 8xy0 - 8xyE
                # of 0x8000:
                #     if opcode == OPCODE_LD_Vx_Vy:
                #         instruction_LD_Vx_Vy(chip8, x, y)
                #     elif opcode == OPCODE_OR_Vx_Vy:
                #         instruction_OR_Vx_Vy(chip8, x, y)
                #     elif opcode == OPCODE_AND_Vx_Vy:
                #         instruction_AND_Vx_Vy(chip8, x, y)
                #     elif opcode == OPCODE_XOR_Vx_Vy:
                #         instruction_XOR_Vx_Vy(chip8, x, y)
                #     elif opcode == OPCODE_ADD_Vx_Vy:
                #         instruction_ADD_Vx_Vy(chip8, x, y)
                #     elif opcode == OPCODE_SUB_Vx_Vy:
                #         instruction_SUB_Vx_Vy(chip8, x, y)
                #     elif opcode == OPCODE_SHR_Vx:
                #         instruction_SHR_Vx(chip8, x)
                #     elif opcode == OPCODE_SUBN_Vx_Vy:
                #         instruction_SUBN_Vx_Vy(chip8, x, y)
                #     elif opcode == OPCODE_SHL_Vx:
                #         instruction_SHL_Vx(chip8, x)
                #     else:
                #         echo "Unknown opcode: ", toHex(opcode, 4)
                #         missingOpcodes.add(opcode)
                of 0x9000:
                    instruction_SNE_Vx_Vy(chip8, x, y)
                of 0xA000:
                    instruction_LD_I_nnn(chip8, nnn)
                of 0xB000:
                    instruction_JP_V0_nnn(chip8, nnn)
                of 0xC000:
                    instruction_RND_Vx_kk(chip8, x, kk)
                of 0xD000:
                    requestFrame = instruction_DRAW(chip8, x, y, n)
                of 0xE000:
                    if opcode == OPCODE_SKP_VX:
                        instruction_SKP_Vx(chip8, x)
                    elif opcode == OPCODE_SKNP_VX:
                        instruction_SKNP_Vx(chip8, x)
                    else:
                        echo "Unknown opcode: ", toHex(opcode, 4)
                        missingOpcodes.add(opcode)
                of 0xF000:
                    case opcode and 0x00FF:
                        of 0x0007:
                            instruction_LD_Vx_DT(chip8, x)
                        of 0x000A:
                            instruction_LD_Vx_K(chip8, x)
                        of 0x0015:
                            instruction_LD_DT_Vx(chip8, x)
                        of 0x0018:
                            instruction_LD_ST_Vx(chip8, x)
                        of 0x001E:
                            instruction_ADD_I_Vx(chip8, x)
                        of 0x0029:
                            instruction_LD_F_Vx(chip8, x)
                        of 0x0033:
                            instruction_LD_BCD_Vx(chip8, x)
                        of 0x0055:
                            instruction_LD_I_Vx(chip8, x)
                        of 0x0065:
                            instruction_LD_Vx_I(chip8, x)
                        else:
                            echo "Unknown opcode: ", toHex(opcode, 4)
                            missingOpcodes.add(opcode)
                else:
                    echo "Unknown opcode: ", toHex(opcode, 4)
                    missingOpcodes.add(opcode)

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

        if missingOpcodes.len > 0:
            echo "Missing opcodes: " & missingOpcodes.deduplicate().map(toHex).join(", ")
        
    # Cleanup
    SDL_DestroyRenderer(renderer)
    SDL_DestroyWindow(win)
    SDL_Quit()

main()