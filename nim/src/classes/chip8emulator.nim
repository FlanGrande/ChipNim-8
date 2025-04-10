import gdext
import chip8/chip8
import chip8/globals

import gdext/classes/gdNode2D

type Chip8Emulator* {.gdsync.} = ptr object of Node2D
  chip8*: Chip8
  isPaused*: bool
# Note: signals must be defined at the top of the file
proc rom_loaded(self: Chip8Emulator): Error {.gdsync, signal.}
proc update_debug_ui(self: Chip8Emulator): Error {.gdsync, signal.}
proc openRom*(self: Chip8Emulator, path: string): void

method ready(self: Chip8Emulator) {.gdsync.} =
  self.chip8 = initChip8()
  self.openRom("roms/games/Animal Race [Brian Astle].ch8")

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
  if not self.isPaused:
    discard self.chip8.emulateCycle()
    discard self.update_debug_ui()

    if self.chip8.didDraw:
      queue_redraw(self)

# Method to force update the display after loading a state
proc update_display*(self: Chip8Emulator) {.gdsync.} =
  queue_redraw(self)

# method input(self: Chip8Emulator, event: InputEvent) {.gdsync.} =
#   print("input")

proc toggle_pause*(self: Chip8Emulator) {.gdsync.} =
  self.isPaused = not self.isPaused

proc openRom*(self: Chip8Emulator, path: string) {.gdsync.} =
  loadRom(self.chip8, path)
  print("rom loaded: ", self.chip8.romName)
  discard self.rom_loaded()
  queue_redraw(self)
