#[

64x32 pixels display
64 width x 32 height

With this format:

(0,0)	(63,0)
(0,31)	(63,31)

A sprite is a group of bytes which are a binary representation of the desired picture.
Chip-8 sprites may be up to 15 bytes. for a possible sprite size of 8x15.

]#

import globals, sdl3

proc render*(renderer: SDL_Renderer, gfx: array[DISPLAY_SIZE, uint8]) =
    for i in 0..<DISPLAY_SIZE:
        if gfx[i] == 1:
            let x = i mod DISPLAY_WIDTH * PIXEL_WIDTH
            let y = i div DISPLAY_WIDTH * PIXEL_HEIGHT
            let rect = SDL_FRect(
                x: x.float32,
                y: y.float32,
                w: PIXEL_WIDTH.float32,
                h: PIXEL_HEIGHT.float32
            )
            
            SDL_SetRenderDrawColor(renderer, 255, 128, 0, SDL_ALPHA_OPAQUE)
            SDL_RenderFillRect(renderer, addr rect)