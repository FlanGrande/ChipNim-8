import gdext
import chip8/chip8
import chip8emulator
import std/strformat
import std/parseutils

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
import gdext/classes/gdFileDialog

type UI* {.gdsync.} = ptr object of Control
  Chip8Emulator* {.gdexport.}: Chip8Emulator
  RomNameLabel* {.gdexport.}: Label
  StepCounter* {.gdexport.}: Label

  V0DecValueLabel* {.gdexport.}: Label
  V0HexValueLabel* {.gdexport.}: Label
  V1DecValueLabel* {.gdexport.}: Label
  V1HexValueLabel* {.gdexport.}: Label
  V2DecValueLabel* {.gdexport.}: Label
  V2HexValueLabel* {.gdexport.}: Label
  V3DecValueLabel* {.gdexport.}: Label
  V3HexValueLabel* {.gdexport.}: Label
  V4DecValueLabel* {.gdexport.}: Label
  V4HexValueLabel* {.gdexport.}: Label
  V5DecValueLabel* {.gdexport.}: Label
  V5HexValueLabel* {.gdexport.}: Label
  V6DecValueLabel* {.gdexport.}: Label
  V6HexValueLabel* {.gdexport.}: Label
  V7DecValueLabel* {.gdexport.}: Label
  V7HexValueLabel* {.gdexport.}: Label
  V8DecValueLabel* {.gdexport.}: Label
  V8HexValueLabel* {.gdexport.}: Label
  V9DecValueLabel* {.gdexport.}: Label
  V9HexValueLabel* {.gdexport.}: Label
  VADecValueLabel* {.gdexport.}: Label
  VAHexValueLabel* {.gdexport.}: Label
  VBDecValueLabel* {.gdexport.}: Label
  VBHexValueLabel* {.gdexport.}: Label
  VCDecValueLabel* {.gdexport.}: Label
  VCHexValueLabel* {.gdexport.}: Label
  VDDecValueLabel* {.gdexport.}: Label
  VDHexValueLabel* {.gdexport.}: Label
  VEDecValueLabel* {.gdexport.}: Label
  VEHexValueLabel* {.gdexport.}: Label
  VFDecValueLabel* {.gdexport.}: Label
  VFHexValueLabel* {.gdexport.}: Label

  # Stack UI Labels
  Stack0ValueLabel* {.gdexport.}: Label
  Stack1ValueLabel* {.gdexport.}: Label
  Stack2ValueLabel* {.gdexport.}: Label
  Stack3ValueLabel* {.gdexport.}: Label
  Stack4ValueLabel* {.gdexport.}: Label
  Stack5ValueLabel* {.gdexport.}: Label
  Stack6ValueLabel* {.gdexport.}: Label
  Stack7ValueLabel* {.gdexport.}: Label
  Stack8ValueLabel* {.gdexport.}: Label
  Stack9ValueLabel* {.gdexport.}: Label
  Stack10ValueLabel* {.gdexport.}: Label
  Stack11ValueLabel* {.gdexport.}: Label
  Stack12ValueLabel* {.gdexport.}: Label
  Stack13ValueLabel* {.gdexport.}: Label
  Stack14ValueLabel* {.gdexport.}: Label
  Stack15ValueLabel* {.gdexport.}: Label

  OpenRomButton* {.gdexport.}: Button
  FileDialog* {.gdexport.}: FileDialog
  PlayPauseButton* {.gdexport.}: CheckButton
  
  OpcodesScrollPanelContainer* {.gdexport.}: PanelContainer # This is the container that contains the scroll container
  OpcodesScrollContainer* {.gdexport.}: ScrollContainer
  OpcodesVBox* {.gdexport.}: VBoxContainer
  OpcodeFollowCheckButton* {.gdexport.}: CheckButton
  isUserHoveringOnOpcodesScrollPanelContainer: bool

proc getStackLabelByIndex(self: UI, index: int): Label

method ready(self: UI) {.gdsync.} =
  discard self.Chip8Emulator.connect("rom_loaded", self.callable("_on_rom_loaded"))
  discard self.Chip8Emulator.connect("update_debug_ui", self.callable("_on_chip8_emulator_update"))
  discard self.OpcodesScrollPanelContainer.connect("mouse_entered", self.callable("_on_opcodes_scroll_panel_container_mouse_entered"))
  discard self.OpcodesScrollPanelContainer.connect("mouse_exited", self.callable("_on_opcodes_scroll_panel_container_mouse_exited"))
  discard self.OpenRomButton.connect("pressed", self.callable("_on_open_rom_button_pressed"))
  discard self.FileDialog.connect("file_selected", self.callable("_on_file_dialog_file_selected"))
  discard self.PlayPauseButton.connect("toggled", self.callable("_on_play_pause_button_toggled"))
  self.isUserHoveringOnOpcodesScrollPanelContainer = false
  
  # Initialize stack labels to invisible
  for i in 0..<16:
    let stackLabel = self.getStackLabelByIndex(i)
    if stackLabel != nil:
      stackLabel.text = "nil"

proc getStackLabelByIndex(self: UI, index: int): Label =
  case index:
    of 0: return self.Stack0ValueLabel
    of 1: return self.Stack1ValueLabel
    of 2: return self.Stack2ValueLabel
    of 3: return self.Stack3ValueLabel
    of 4: return self.Stack4ValueLabel
    of 5: return self.Stack5ValueLabel
    of 6: return self.Stack6ValueLabel
    of 7: return self.Stack7ValueLabel
    of 8: return self.Stack8ValueLabel
    of 9: return self.Stack9ValueLabel
    of 10: return self.Stack10ValueLabel
    of 11: return self.Stack11ValueLabel
    of 12: return self.Stack12ValueLabel
    of 13: return self.Stack13ValueLabel
    of 14: return self.Stack14ValueLabel
    of 15: return self.Stack15ValueLabel
    else: return nil

proc rom_loaded(self: UI) {.gdsync, name: "_on_rom_loaded".} =
  # Clean Opcodes window
  for i in 0..<self.OpcodesVBox.get_child_count():
    let child = self.OpcodesVBox.get_child(i) as Button
    child.visible = false

  self.RomNameLabel.text = self.Chip8Emulator.chip8.romName

proc update_debug_ui(self: UI) {.gdsync, name: "_on_chip8_emulator_update".} =
  self.StepCounter.text = $self.Chip8Emulator.chip8.step_counter

  self.V0DecValueLabel.text = &"{self.Chip8Emulator.chip8.V[0]:03}"
  self.V0HexValueLabel.text = &"{self.Chip8Emulator.chip8.V[0]:02X}"
  self.V1DecValueLabel.text = &"{self.Chip8Emulator.chip8.V[1]:03}"
  self.V1HexValueLabel.text = &"{self.Chip8Emulator.chip8.V[1]:02X}"
  self.V2DecValueLabel.text = &"{self.Chip8Emulator.chip8.V[2]:03}"
  self.V2HexValueLabel.text = &"{self.Chip8Emulator.chip8.V[2]:02X}"
  self.V3DecValueLabel.text = &"{self.Chip8Emulator.chip8.V[3]:03}"
  self.V3HexValueLabel.text = &"{self.Chip8Emulator.chip8.V[3]:02X}"
  self.V4DecValueLabel.text = &"{self.Chip8Emulator.chip8.V[4]:03}"
  self.V4HexValueLabel.text = &"{self.Chip8Emulator.chip8.V[4]:02X}"
  self.V5DecValueLabel.text = &"{self.Chip8Emulator.chip8.V[5]:03}"
  self.V5HexValueLabel.text = &"{self.Chip8Emulator.chip8.V[5]:02X}"
  self.V6DecValueLabel.text = &"{self.Chip8Emulator.chip8.V[6]:03}"
  self.V6HexValueLabel.text = &"{self.Chip8Emulator.chip8.V[6]:02X}"
  self.V7DecValueLabel.text = &"{self.Chip8Emulator.chip8.V[7]:03}"
  self.V7HexValueLabel.text = &"{self.Chip8Emulator.chip8.V[7]:02X}"
  self.V8DecValueLabel.text = &"{self.Chip8Emulator.chip8.V[8]:03}"
  self.V8HexValueLabel.text = &"{self.Chip8Emulator.chip8.V[8]:02X}"
  self.V9DecValueLabel.text = &"{self.Chip8Emulator.chip8.V[9]:03}"
  self.V9HexValueLabel.text = &"{self.Chip8Emulator.chip8.V[9]:02X}"
  self.VADecValueLabel.text = &"{self.Chip8Emulator.chip8.V[10]:03}"
  self.VAHexValueLabel.text = &"{self.Chip8Emulator.chip8.V[10]:02X}"
  self.VBDecValueLabel.text = &"{self.Chip8Emulator.chip8.V[11]:03}"
  self.VBHexValueLabel.text = &"{self.Chip8Emulator.chip8.V[11]:02X}"
  self.VCDecValueLabel.text = &"{self.Chip8Emulator.chip8.V[12]:03}"
  self.VCHexValueLabel.text = &"{self.Chip8Emulator.chip8.V[12]:02X}"
  self.VDDecValueLabel.text = &"{self.Chip8Emulator.chip8.V[13]:03}"
  self.VDHexValueLabel.text = &"{self.Chip8Emulator.chip8.V[13]:02X}"
  self.VEDecValueLabel.text = &"{self.Chip8Emulator.chip8.V[14]:03}"
  self.VEHexValueLabel.text = &"{self.Chip8Emulator.chip8.V[14]:02X}"
  self.VFDecValueLabel.text = &"{self.Chip8Emulator.chip8.V[15]:03}"
  self.VFHexValueLabel.text = &"{self.Chip8Emulator.chip8.V[15]:02X}"
  
  # Update stack values and visibility based on stack pointer
  for i in 0..<16:
    let stackLabel = self.getStackLabelByIndex(i)

    if stackLabel != nil:
      # Set the value in hexadecimal format
      stackLabel.text = &"{self.Chip8Emulator.chip8.stack[i]:03X}"
      
      # Make stack labels visible up to the stack pointer value
      let parent = stackLabel.get_parent() as VBoxContainer

      for j in 0..<parent.get_child_count():
        let child = parent.get_child(j) as Label
        child.visible = i <= self.Chip8Emulator.chip8.sp.int
  

  # Try to get opcode_label_<number>, if it exists but it's hidden, make it visible and change its content
  # Otherwise add a new one

  let opcodeLabelName = "opcode_label_" & $(self.Chip8Emulator.chip8.step_counter - 1)
  var opcodeLabel: Button = self.OpcodesVBox.get_node_or_null(opcodeLabelName) as Button

  # TO DO: We need to TEST that the save/load states are actually corrrect
  # E.g. We are not loading the state that was saved initially but the new one
  if opcodeLabel != nil:
    opcodeLabel.visible = true
    opcodeLabel.text = self.Chip8Emulator.chip8.current_instruction
  else:
    # Append label with the current execution cycle to OpcodesVBox
    opcodeLabel = Button.instantiate opcodeLabelName
    opcodeLabel.text = self.Chip8Emulator.chip8.current_instruction
    opcodeLabel.mouse_filter = mouseFilterPass
    opcodeLabel.alignment = horizontalAlignmentLeft
    
    # Connect the click signal to the label
    discard opcodeLabel.connect("gui_input", self.callable("_on_opcode_label_gui_input").bind(self.Chip8Emulator.chip8.step_counter - 1))
    
    self.OpcodesVBox.add_child(opcodeLabel)

  if self.OpcodeFollowCheckButton.button_pressed and not self.isUserHoveringOnOpcodesScrollPanelContainer:
    self.OpcodesScrollContainer.scroll_vertical = self.OpcodesVBox.get_child_count() * 200

proc on_opcode_label_gui_input(self: UI, event: GdRef[InputEvent], step_to_load: uint32) {.gdsync, name: "_on_opcode_label_gui_input".} =
  # Check if left mouse button was just pressed
  if event[].is_class("InputEventMouseButton") and event[].is_action_pressed("left_click"):
    print("Loading state for step: ", step_to_load)
    if self.Chip8Emulator.chip8.hasState(step_to_load):
      self.Chip8Emulator.chip8.loadState(step_to_load)
      self.Chip8Emulator.update_display()
      var nodesToHide: seq[Button] = @[]
      let currentStepCounter = self.Chip8Emulator.chip8.step_counter
      let prefixLen = "opcode_label_".len

      # Remove all labels under the clicked one, as they are called opcode_label_<step_counter>
      for i in currentStepCounter.int32..<self.OpcodesVBox.get_child_count():
        let child: Button = self.OpcodesVBox.get_child(i) as Button
        var childName = $child.name
        var childStepCounter: int

        discard parseInt(childName, childStepCounter, prefixLen)

        if childStepCounter.uint32 > step_to_load:
          nodesToHide.add(child)
      
      # Remove all the nodes in the nodesToRemove sequence
      for node in nodesToHide:
        node.visible = false
      
      # Remove saved states after the current one
      self.Chip8Emulator.chip8.removeStatesAfter(step_to_load)
      
      print("State loaded successfully")
      print("Removed ", nodesToHide.len, " nodes")
    else:
      print("No saved state found for step: ", step_to_load)

proc on_opcodes_scroll_panel_container_mouse_entered(self: UI) {.gdsync, name: "_on_opcodes_scroll_panel_container_mouse_entered".} =
  self.isUserHoveringOnOpcodesScrollPanelContainer = true

proc on_opcodes_scroll_panel_container_mouse_exited(self: UI) {.gdsync, name: "_on_opcodes_scroll_panel_container_mouse_exited".} =
  self.isUserHoveringOnOpcodesScrollPanelContainer = false

proc on_open_rom_button_pressed(self: UI) {.gdsync, name: "_on_open_rom_button_pressed".} =
  self.Chip8Emulator.toggle_pause()
  self.FileDialog.popup_centered_ratio()

proc on_file_dialog_file_selected(self: UI, path: string) {.gdsync, name: "_on_file_dialog_file_selected".} =
  self.Chip8Emulator.openRom(path)
  self.Chip8Emulator.toggle_pause()

proc on_play_pause_button_toggled(self: UI) {.gdsync, name: "_on_play_pause_button_toggled".} =
  self.Chip8Emulator.toggle_pause()
