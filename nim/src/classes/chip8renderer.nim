import gdext
import chip8/chip8

import gdext/classes/gdNode2D

type Chip8Renderer* {.gdsync.} = ptr object of Node2D
  number: int = 0
  chip8: Chip8

method ready(self: Chip8Renderer) {.gdsync.} =
  #self.chip8 = initChip8()
  print("ready")
  # set_process_draw(true)
  # loadRom(self.chip8, "/roms/games/Animal Race [Brian Astle].ch8")

method draw(self: Chip8Renderer) {.gdsync.} =
  print("draw")
  # Use chip8.gfx to draw the screen
  # Create a new texture
  discard

method process(self: Chip8Renderer, delta: float64) {.gdsync.} =
  # print("process")
  # For now, let's update the drawing all the time
  queue_redraw(self)
  discard

method input(self: Chip8Renderer, event: InputEvent) {.gdsync.} =
  print("input")
  discard
