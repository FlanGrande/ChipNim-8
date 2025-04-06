import gdext

import gdext/classes/gdControl
import gdext/classes/gdLabel

type UI* {.gdsync.} = ptr object of Control
  RomNameLabel: Label
  RomName: string

method ready(self: UI) {.gdsync.} =
  self.RomNameLabel = self/"DebugUI"/"VBoxContainer"/"RomName"/"Name" as Label
  self.RomName = "Animal Race [Brian Astle]"
  self.RomNameLabel.text = self.RomName
