import gdext
import chip8/chip8
import chip8/globals

import gdext/classes/gdNode2D

type Chip8Renderer* {.gdsync.} = ptr object of Node2D
  chip8: Chip8

method ready(self: Chip8Renderer) {.gdsync.} =
  self.chip8 = initChip8()
  loadRom(self.chip8, "roms/games/Animal Race [Brian Astle].ch8")

method draw(self: Chip8Renderer) {.gdsync.} =
  for i in 0..<DISPLAY_SIZE:
    let x: int32 = i.int32 mod DISPLAY_WIDTH.int32
    let y: int32 = i.int32 div DISPLAY_WIDTH.int32
    let rectPosition: Vector2 = vector2(x.float32 * PIXEL_WIDTH.float32, y.float32 * PIXEL_HEIGHT.float32)
    let rectSize: Vector2 = vector2(PIXEL_WIDTH.float32, PIXEL_HEIGHT.float32)
    let rect: Rect2 = rect2(rectPosition, rectSize)

    if self.chip8.gfx[i] == 1:
      draw_rect(self, rect, color(1, 0.5, 0))
    else:
      draw_rect(self, rect, color(0, 0, 0))

method process(self: Chip8Renderer, delta: float64) {.gdsync.} =
  discard self.chip8.emulateCycle()

  if self.chip8.didDraw:
    queue_redraw(self)

method input(self: Chip8Renderer, event: InputEvent) {.gdsync.} =
  print("input")
