import gdext
import chip8/chip8
import chip8/globals

import gdext/classes/gdNode2D
import gdext/classes/gdInputEvent
import gdext/classes/gdInputEventKey

type Chip8Emulator* {.gdsync.} = ptr object of Node2D
  chip8*: Chip8
  isPaused*: bool
# Note: signals must be defined at the top of the file
proc rom_loaded(self: Chip8Emulator): Error {.gdsync, signal.}
proc update_debug_ui(self: Chip8Emulator): Error {.gdsync, signal.}
proc special_state_saved(self: Chip8Emulator): Error {.gdsync, signal.}
proc special_state_loaded(self: Chip8Emulator): Error {.gdsync, signal.}
proc openRom*(self: Chip8Emulator, path: string): void
proc emulateFrame*(self: Chip8Emulator): bool {.gdsync.}

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
    discard self.emulateFrame()


# Method to force update the display after loading a state
proc update_display*(self: Chip8Emulator) {.gdsync.} =
  queue_redraw(self)

method input(self: Chip8Emulator, event: GdRef[InputEvent]) {.gdsync.} =
  if event[].is_class("InputEventKey"):
    if event[].is_action_pressed("1"):
      self.chip8.keyDown(1)
    if event[].is_action_pressed("2"):
      self.chip8.keyDown(2)
    if event[].is_action_pressed("3"):
      self.chip8.keyDown(3)
    if event[].is_action_pressed("4"):
      self.chip8.keyDown(4)
    if event[].is_action_pressed("5"):
      self.chip8.keyDown(5)
    if event[].is_action_pressed("6"):
      self.chip8.keyDown(6)
    if event[].is_action_pressed("7"):
      self.chip8.keyDown(7)
    if event[].is_action_pressed("8"):
      self.chip8.keyDown(8)
    if event[].is_action_pressed("9"):
      self.chip8.keyDown(9)
    if event[].is_action_pressed("0"):
      self.chip8.keyDown(0)
    if event[].is_action_pressed("A"):
      self.chip8.keyDown(10)
    if event[].is_action_pressed("B"):
      self.chip8.keyDown(11)
    if event[].is_action_pressed("C"):
      self.chip8.keyDown(12)
    if event[].is_action_pressed("D"):
      self.chip8.keyDown(13)
    if event[].is_action_pressed("E"):
      self.chip8.keyDown(14)
    if event[].is_action_pressed("F"):
      self.chip8.keyDown(15)
    
    if event[].is_action_released("1"):
      self.chip8.keyUp(1)
    if event[].is_action_released("2"):
      self.chip8.keyUp(2)
    if event[].is_action_released("3"):
      self.chip8.keyUp(3)
    if event[].is_action_released("4"):
      self.chip8.keyUp(4)
    if event[].is_action_released("5"):
      self.chip8.keyUp(5)
    if event[].is_action_released("6"):
      self.chip8.keyUp(6)
    if event[].is_action_released("7"):
      self.chip8.keyUp(7)
    if event[].is_action_released("8"):
      self.chip8.keyUp(8)
    if event[].is_action_released("9"):
      self.chip8.keyUp(9)
    if event[].is_action_released("0"):
      self.chip8.keyUp(0)
    if event[].is_action_released("A"):
      self.chip8.keyUp(10)
    if event[].is_action_released("B"):
      self.chip8.keyUp(11)
    if event[].is_action_released("C"):
      self.chip8.keyUp(12)
    if event[].is_action_released("D"):
      self.chip8.keyUp(13)
    if event[].is_action_released("E"):
      self.chip8.keyUp(14)
    if event[].is_action_released("F"):
      self.chip8.keyUp(15)

proc pause*(self: Chip8Emulator) {.gdsync.} =
  self.isPaused = true

proc resume*(self: Chip8Emulator) {.gdsync.} =
  self.isPaused = false

proc openRom*(self: Chip8Emulator, path: string) {.gdsync.} =
  loadRom(self.chip8, path)
  print("rom loaded: ", self.chip8.romName)
  discard self.rom_loaded()
  queue_redraw(self)

# Emulate a full frame (multiple cycles)
proc emulateFrame*(self: Chip8Emulator): bool =
    var didDrawInFrame = false
    
    for _ in 0..<8: # TODO: Hardcoded to 8 for now
        if self.chip8.waitingForKey:
            break
            
        let cycleResult = emulateCycle(self.chip8)
        discard self.update_debug_ui()
        queue_redraw(self)
        if not cycleResult:
            continue
            
        # Check if we drew to the screen
        if self.chip8.didDraw:
            didDrawInFrame = true
    
    # Update timers at the end of the frame
    self.chip8.tickTimers()
    
    return didDrawInFrame

# Save the current state to the special save slot
proc saveSpecialState*(self: Chip8Emulator) {.gdsync.} =
  saveSpecialState(self.chip8)
  print("Saved special state")
  discard self.special_state_saved()

# Load the state from the special save slot
proc loadSpecialState*(self: Chip8Emulator): bool {.gdsync.} =
  if not hasSpecialState(self.chip8):
    print("No special state found to load")
    return false
    
  let success = loadSpecialState(self.chip8)
  if success:
    print("Loaded special state")
    discard self.special_state_loaded()
    queue_redraw(self)
    
  return success

# Check if a special state exists
proc hasSpecialState*(self: Chip8Emulator): bool {.gdsync.} =
  return hasSpecialState(self.chip8)