import gdext
import chip8/chip8
import chip8/globals

import gdext/classes/gdNode2D

type Chip8Emulator* {.gdsync.} = ptr object of Node2D
  chip8*: Chip8

# Note: signals must be defined at the top of the file
proc rom_loaded(self: Chip8Emulator, rom_name: string): Error {.gdsync, signal.}
proc update_debug_ui(self: Chip8Emulator): Error {.gdsync, signal.}

method ready(self: Chip8Emulator) {.gdsync.} =
  self.chip8 = initChip8()
  loadRom(self.chip8, "roms/games/Animal Race [Brian Astle].ch8")
  discard self.rom_loaded("Animal Race [Brian Astle]")

method draw(self: Chip8Emulator) {.gdsync.} =
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

method process(self: Chip8Emulator, delta: float64) {.gdsync.} =
  discard self.chip8.emulateCycle()
  discard self.update_debug_ui()

  if self.chip8.didDraw:
    queue_redraw(self)

# Method to force update the display after loading a state
proc update_display*(self: Chip8Emulator) {.gdsync.} =
  queue_redraw(self)

# method input(self: Chip8Emulator, event: InputEvent) {.gdsync.} =
#   print("input")