import sdl3
import std/strutils
import sequtils
import chip8/audio
import chip8/chip8
import chip8/display
import chip8/globals
import chip8/opcodes

proc main() =
    # Chip-8 Emulator loop
    if not SDL_Init(SDL_INIT_VIDEO or SDL_INIT_AUDIO):
        quit("SDL_Init Error: " & $SDL_GetError())

    let win = SDL_CreateWindow("Chip-8 Emulator", PIXEL_WIDTH * DISPLAY_WIDTH, PIXEL_HEIGHT * DISPLAY_HEIGHT, SDL_WINDOW_BORDERLESS)
    if win == nil:
        quit("SDL_CreateWindow Error: " & $SDL_GetError())

    let renderer = SDL_CreateRenderer(win, nil)
    if renderer == nil:
        quit("SDL_CreateRenderer Error: " & $SDL_GetError())

    initAudioSystem()

    # Initialize Chip8
    var chip8: Chip8 = initChip8()
    var running: bool = true
    var event: SDL_Event 

    # Load ROM
    #loadRom(chip8, "roms/programs/IBM Logo.ch8")
    #loadRom(chip8, "roms/programs/Fishie [Hap, 2005].ch8")
    # loadRom(chip8, "roms/programs/Clock Program [Bill Fisher, 1981].ch8")
    # loadRom(chip8, "roms/programs/Life [GV Samways, 1980].ch8")
    # loadRom(chip8, "roms/games/Tetris [Fran Dachille, 1991].ch8")
    # loadRom(chip8, "downloadedRoms/1-chip8-logo.ch8")
    # loadRom(chip8, "downloadedRoms/2-ibm-logo.ch8")
    # loadRom(chip8, "downloadedRoms/3-corax+.ch8")
    # loadRom(chip8, "downloadedRoms/4-flags.ch8")
    # loadRom(chip8, "downloadedRoms/5-quirks.ch8")
    # loadRom(chip8, "downloadedRoms/6-keypad.ch8")
    # loadRom(chip8, "downloadedRoms/7-beep.ch8")
    # loadRom(chip8, "roms/games/Addition Problems [Paul C. Moews].ch8")
    loadRom(chip8, "roms/games/Animal Race [Brian Astle].ch8")

    while running:
        # Process input
        let frameStart: uint64 = SDL_GetTicks()
        var requestFrame: bool = false

        while SDL_PollEvent(event):
            if event.type == SDL_EventQuit:
                running = false
            elif event.type == SDL_EventKeyDown:
                case event.key.scancode:
                    of SDL_SCANCODE_ESCAPE:
                        running = false
                    of SDLK_SCANCODE_TO_KEYCODE[0]:
                        keyDown(chip8, 0)
                    of SDLK_SCANCODE_TO_KEYCODE[1]:
                        keyDown(chip8, 1)
                    of SDLK_SCANCODE_TO_KEYCODE[2]:
                        keyDown(chip8, 2)
                    of SDLK_SCANCODE_TO_KEYCODE[3]:
                        keyDown(chip8, 3)
                    of SDLK_SCANCODE_TO_KEYCODE[4]:
                        keyDown(chip8, 4)
                    of SDLK_SCANCODE_TO_KEYCODE[5]:
                        keyDown(chip8, 5)
                    of SDLK_SCANCODE_TO_KEYCODE[6]:
                        keyDown(chip8, 6)
                    of SDLK_SCANCODE_TO_KEYCODE[7]:
                        keyDown(chip8, 7)
                    of SDLK_SCANCODE_TO_KEYCODE[8]:
                        keyDown(chip8, 8)
                    of SDLK_SCANCODE_TO_KEYCODE[9]:
                        keyDown(chip8, 9)
                    of SDLK_SCANCODE_TO_KEYCODE[10]:
                        keyDown(chip8, 10)
                    of SDLK_SCANCODE_TO_KEYCODE[11]:
                        keyDown(chip8, 11)
                    of SDLK_SCANCODE_TO_KEYCODE[12]:
                        keyDown(chip8, 12)
                    of SDLK_SCANCODE_TO_KEYCODE[13]:
                        keyDown(chip8, 13)
                    of SDLK_SCANCODE_TO_KEYCODE[14]:
                        keyDown(chip8, 14)
                    of SDLK_SCANCODE_TO_KEYCODE[15]:
                        keyDown(chip8, 15)
                    else:
                        echo "Unknown key: ", event.key.scancode
            elif event.type == SDL_EventKeyUp:
                case event.key.scancode:
                    of SDLK_SCANCODE_TO_KEYCODE[0]:
                        keyUp(chip8, 0)
                    of SDLK_SCANCODE_TO_KEYCODE[1]:
                        keyUp(chip8, 1)
                    of SDLK_SCANCODE_TO_KEYCODE[2]:
                        keyUp(chip8, 2)
                    of SDLK_SCANCODE_TO_KEYCODE[3]:
                        keyUp(chip8, 3)
                    of SDLK_SCANCODE_TO_KEYCODE[4]:
                        keyUp(chip8, 4)
                    of SDLK_SCANCODE_TO_KEYCODE[5]:
                        keyUp(chip8, 5)
                    of SDLK_SCANCODE_TO_KEYCODE[6]:
                        keyUp(chip8, 6)
                    of SDLK_SCANCODE_TO_KEYCODE[7]:
                        keyUp(chip8, 7)
                    of SDLK_SCANCODE_TO_KEYCODE[8]:
                        keyUp(chip8, 8)
                    of SDLK_SCANCODE_TO_KEYCODE[9]:
                        keyUp(chip8, 9)
                    of SDLK_SCANCODE_TO_KEYCODE[10]:
                        keyUp(chip8, 10)
                    of SDLK_SCANCODE_TO_KEYCODE[11]:
                        keyUp(chip8, 11)
                    of SDLK_SCANCODE_TO_KEYCODE[12]:
                        keyUp(chip8, 12)
                    of SDLK_SCANCODE_TO_KEYCODE[13]:
                        keyUp(chip8, 13)
                    of SDLK_SCANCODE_TO_KEYCODE[14]:
                        keyUp(chip8, 14)
                    of SDLK_SCANCODE_TO_KEYCODE[15]:
                        keyUp(chip8, 15)
                    else:
                        echo "Unknown key: ", event.key.scancode

        # Run a full frame of emulation
        requestFrame = emulateFrame(chip8)
        
        # Frame timing
        let frameTime: uint64 = SDL_GetTicks() - frameStart
        if frameTime < 1000 div 60:
            SDL_Delay(1000 div 60 - uint32(frameTime))

        # Render
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255)
        SDL_RenderClear(renderer)
        render(renderer, chip8.gfx)
        SDL_RenderPresent(renderer)
       
    # Cleanup
    SDL_DestroyAudioStream(audioStream)
    SDL_DestroyRenderer(renderer)
    SDL_DestroyWindow(win)
    SDL_Quit()

main()