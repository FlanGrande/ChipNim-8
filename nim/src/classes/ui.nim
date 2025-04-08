import gdext
import chip8/chip8
import chip8emulator
import strutils

import gdext/classes/gdNode
import gdext/classes/gdControl
import gdext/classes/gdLabel
import gdext/classes/gdButton
import gdext/classes/gdScrollContainer
import gdext/classes/gdVBoxContainer
import gdext/classes/gdPanelContainer
import gdext/classes/gdInputEvent
import gdext/classes/gdInputEventMouseButton
import gdext/classes/gdCheckButton

type UI* {.gdsync.} = ptr object of Control
  Chip8Emulator* {.gdexport.}: Chip8Emulator
  RomNameLabel* {.gdexport.}: Label
  StepCounter* {.gdexport.}: Label
  OpcodesScrollPanelContainer* {.gdexport.}: PanelContainer # This is the container that contains the scroll container
  OpcodesScrollContainer* {.gdexport.}: ScrollContainer
  OpcodesVBox* {.gdexport.}: VBoxContainer
  OpcodeFollowCheckButton* {.gdexport.}: CheckButton
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
  self.StepCounter.text = $self.Chip8Emulator.chip8.step_counter
  
  # Create a save state for the current step
  self.Chip8Emulator.chip8.saveState(self.Chip8Emulator.chip8.step_counter - 1)

  # Append label with the current execution cycle to OpcodesVBox
  let opcodeLabel: Button = Button.instantiate "opcode_label_" & $(self.Chip8Emulator.chip8.step_counter - 1)
  opcodeLabel.text = self.Chip8Emulator.chip8.current_instruction
  opcodeLabel.mouse_filter = mouseFilterPass
  opcodeLabel.alignment = horizontalAlignmentLeft
  
  # Connect the click signal to the label
  discard opcodeLabel.connect("gui_input", self.callable("_on_opcode_label_gui_input").bind(self.Chip8Emulator.chip8.step_counter - 1))
  
  self.OpcodesVBox.add_child(opcodeLabel)

  if self.OpcodeFollowCheckButton.button_pressed and not self.isUserHoveringOnOpcodesScrollPanelContainer:
    self.OpcodesScrollContainer.scroll_vertical = self.OpcodesVBox.get_child_count() * 200

proc on_opcode_label_gui_input(self: UI, event: GdRef[InputEvent], step_counter: uint32) {.gdsync, name: "_on_opcode_label_gui_input".} =
  # Check if left mouse button was just pressed
  if event[].is_class("InputEventMouseButton") and event[].is_action_pressed("left_click"):
    print("Loading state for step: ", step_counter)
    if self.Chip8Emulator.chip8.hasState(step_counter):
      self.Chip8Emulator.chip8.loadState(step_counter)
      self.Chip8Emulator.update_display()
      var nodesToRemove: seq[Node] = @[]

      # Remove all labels under the clicked one, as they are called opcode_label_<step_counter>
      for i in 0..<self.OpcodesVBox.get_child_count():
        let child: Node = self.OpcodesVBox.get_child(i)
        var childName = child.name
        var childLabelNumber = childName.split("_")[2]
        var childStepCounter = toInt(childLabelNumber)

        if childStepCounter.uint32 > step_counter:
          nodesToRemove.add(child)
      
      # Remove all the nodes in the nodesToRemove sequence
      for node in nodesToRemove:
        self.OpcodesVBox.remove_child(node)
        node.queue_free()
      
      # Remove saved states after the current one
      self.Chip8Emulator.chip8.removeStatesAfter(step_counter)
      
      print("State loaded successfully")
      print("Removed ", nodesToRemove.len, " nodes")
    else:
      print("No saved state found for step: ", step_counter)

proc on_opcodes_scroll_panel_container_mouse_entered(self: UI) {.gdsync, name: "_on_opcodes_scroll_panel_container_mouse_entered".} =
  self.isUserHoveringOnOpcodesScrollPanelContainer = true

proc on_opcodes_scroll_panel_container_mouse_exited(self: UI) {.gdsync, name: "_on_opcodes_scroll_panel_container_mouse_exited".} =
  self.isUserHoveringOnOpcodesScrollPanelContainer = false
