import gdext

import gdext/classes/gdControl
import gdext/classes/gdLabel
import classes/chip8renderer

type UI* {.gdsync.} = ptr object of Control
  RomNameLabel: Label
  Chip8Renderer* {.gdexport.}: Chip8Renderer
  # RomName: string

method ready(self: UI) {.gdsync.} =
  self.RomNameLabel = self/"DebugUI"/"VBoxContainer"/"RomName"/"Name" as Label
  discard self.Chip8Renderer.connect("rom_loaded", self.callable("_on_rom_loaded"))

proc rom_loaded(self: UI, rom_name: string) {.gdsync, name: "_on_rom_loaded".} =
  print("rom_loaded: ", rom_name)
  self.RomNameLabel.text = rom_name
