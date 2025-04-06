import gdext
import chip8/chip8

import gdext/classes/gdNode
import gdext/classes/gdViewportTexture

type Chip8Renderer* {.gdsync.} = ptr object of Node
  chip8: Chip8
  viewportTexture* {.gdexport.}: gdref ViewportTexture

method ready(self: Chip8Renderer) {.gdsync.} =
  #self.chip8 = initChip8()
  print("ready")
  # loadRom(self.chip8, "/roms/games/Animal Race [Brian Astle].ch8")

method draw(self: Chip8Renderer) {.gdsync.} =
  print("draw")
  # Use chip8.gfx to draw the screen
  # Create a new texture
  discard

method process(self: Chip8Renderer, delta: float64) {.gdsync.} =
  print("process")
  discard

method input(self: Chip8Renderer, event: InputEvent) {.gdsync.} =
  print("input")
  discard
