import gdext
import chip8/chip8
import chip8emulator

import gdext/classes/gdControl
import gdext/classes/gdLabel
import gdext/classes/gdScrollContainer
import gdext/classes/gdVBoxContainer
import gdext/classes/gdPanelContainer
import gdext/classes/gdInputEvent
import gdext/classes/gdInputEventMouseButton

type UI* {.gdsync.} = ptr object of Control
  Chip8Emulator* {.gdexport.}: Chip8Emulator
  RomNameLabel* {.gdexport.}: Label
  StepCounter* {.gdexport.}: Label
  OpcodesScrollPanelContainer* {.gdexport.}: PanelContainer # This is the container that contains the scroll container
  OpcodesScrollContainer* {.gdexport.}: ScrollContainer
  OpcodesVBox* {.gdexport.}: VBoxContainer
  isUserHoveringOnOpcodesScrollPanelContainer: bool

method ready(self: UI) {.gdsync.} =
  discard self.Chip8Emulator.connect("rom_loaded", self.callable("_on_rom_loaded"))
  discard self.Chip8Emulator.connect("update_debug_ui", self.callable("_on_chip8_emulator_update"))
  discard self.OpcodesScrollPanelContainer.connect("mouse_entered", self.callable("_on_opcodes_scroll_panel_container_mouse_entered"))
  discard self.OpcodesScrollPanelContainer.connect("mouse_exited", self.callable("_on_opcodes_scroll_panel_container_mouse_exited"))
  self.isUserHoveringOnOpcodesScrollPanelContainer = false

proc rom_loaded(self: UI, rom_name: string) {.gdsync, name: "_on_rom_loaded".} =
  print("rom_loaded: ", rom_name)
  self.RomNameLabel.text = rom_name

proc update_debug_ui(self: UI) {.gdsync, name: "_on_chip8_emulator_update".} =
  let chip8: Chip8 = self.Chip8Emulator.chip8
  self.StepCounter.text = $chip8.step_counter
  
  # Append label with the current execution cycel to OpcodesVBox
  let opcodeLabel: Label = Label.instantiate "opcode_label_" & $chip8.step_counter
  opcodeLabel.text = chip8.current_instruction
  self.OpcodesVBox.add_child(opcodeLabel)

  # if not self.isUserHoveringOnOpcodesScrollPanelContainer:
  #   self.OpcodesScrollContainer.scroll_vertical = self.OpcodesVBox.get_child_count() * 20

proc on_opcodes_scroll_panel_container_mouse_entered(self: UI) {.gdsync, name: "_on_opcodes_scroll_panel_container_mouse_entered".} =
  print("mouse_entered")
  # self.isUserHoveringOnOpcodesScrollPanelContainer = true

proc on_opcodes_scroll_panel_container_mouse_exited(self: UI) {.gdsync, name: "_on_opcodes_scroll_panel_container_mouse_exited".} =
  print("mouse_exited")
  # self.isUserHoveringOnOpcodesScrollPanelContainer = false