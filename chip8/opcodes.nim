# Chip-8 Opcodes
const
    OPCODE_CLS* = 0x00E0
    OPCODE_JP* = 0x1000

    OPCODE_LD_VX_KK* = 0x6000
    OPCODE_ADD_VX_KK* = 0x7000

    OPCODE_LD_I_NNN* = 0xA000 

    OPCODE_DRAW* = 0xD000

# Masks
const
    MASK_OPCODE* = 0xF000
    MASK_NNN* = 0x0FFF
    MASK_X* = 0x0F00
    MASK_Y* = 0x00F0
    MASK_N* = 0x000F
    MASK_KK* = 0x00FF
