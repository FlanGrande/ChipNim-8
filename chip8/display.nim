#[

64x32 pixels display
64 width x 32 height

With this format:

(0,0)	(63,0)
(0,31)	(63,31)

A sprite is a group of bytes which are a binary representation of the desired picture.
Chip-8 sprites may be up to 15 bytes. for a possible sprite size of 8x15.

]#

import sdl3
import globals

proc render*(gfx: array[DISPLAY_SIZE, uint8]) =
    echo "Rendering" # TODO: Implement rendering

if not SDL_Init(SDL_INIT_VIDEO):
    quit("SDL_Init Error: " & $SDL_GetError())

let win = SDL_CreateWindow("Hello SDL3", 640, 480, 0)
if win == nil:
    quit("SDL_CreateWindow Error: " & $SDL_GetError())

let renderer = SDL_CreateRenderer(win, nil)
if renderer == nil:
    quit("SDL_CreateRenderer Error: " & $SDL_GetError())

var running: bool = true
var event: SDL_Event # I think this is already a pointer, no need to use (addr)

while running:
  while SDL_PollEvent(event):
    if event.type == SDL_EventQuit:
      running = false

  # Clear the screen
  SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255)
  SDL_RenderClear(renderer)

  # TODO: Call your emulator's render logic here
  # render(chip8)

  # Present the result
  SDL_RenderPresent(renderer)

SDL_DestroyRenderer(renderer)
SDL_DestroyWindow(win)
SDL_Quit()