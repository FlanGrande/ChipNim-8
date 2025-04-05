import gdext

type ChipNim8Renderer* {.gdsync.} = ptr object of Node
  chipNim8: ChipNim8

proc _init(self: ChipNim8Renderer) {.gdsync.} =
  self.chipNim8 = ChipNim8.new()