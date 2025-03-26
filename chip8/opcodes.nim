# Chip-8 Opcodes Masks
const
    OPCODE_CLS* = 0x00E0            # Clear screen
    OPCODE_RET* = 0x00EE            # Return from subroutine
    OPCODE_SYS* = 0x0000            # System call (it's actually a mask for 0nnn)
    OPCODE_JP* = 0x1000             # Jump to address
    OPCODE_CALL* = 0x2000           # Call subroutine
    OPCODE_SE_VX_KK* = 0x3000       # Skip next instruction if Vx = kk
    OPCODE_SNE_VX_KK* = 0x4000      # Skip next instruction if Vx != kk
    OPCODE_SE_VX_VY* = 0x5000       # Skip next instruction if Vx = Vy
    OPCODE_LD_VX_KK* = 0x6000       # Load kk into Vx
    OPCODE_ADD_VX_KK* = 0x7000      # Add kk to Vx
    OPCODE_VX_VY_LOGIC* = 0x8000    # Covers 8xy0 - 8xyE
    OPCODE_SNE_VX_VY* = 0x9000      # Skip next instruction if Vx != Vy
    OPCODE_LD_I_NNN* = 0xA000       # Load nnn into I
    OPCODE_JP_V0_NNN* = 0xB000      # Jump to address nnn + V0
    OPCODE_RND_VX_KK* = 0xC000      # Generate a random number
    OPCODE_DRAW* = 0xD000           # Draw a sprite
    OPCODE_SKP_VX* = 0xE09E         # Skip next instruction if key with the value of Vx is pressed
    OPCODE_SKNP_VX* = 0xE0A1        # Skip next instruction if key with the value of Vx is not pressed
    OPCODE_LD_VX_DT* = 0xF007       # Load DT into Vx
    OPCODE_LD_VX_K* = 0xF00A        # Wait for a key press and store the value in Vx
    OPCODE_LD_DT_VX* = 0xF015       # Load Vx into DT
    OPCODE_LD_ST_VX* = 0xF018       # Load Vx into ST
    OPCODE_ADD_I_VX* = 0xF01E       # Add Vx to I
    OPCODE_LD_F_VX* = 0xF029        # Load sprite location into I
    OPCODE_LD_BCD_VX* = 0xF033        # Load BCD into memory
    OPCODE_LD_I_VX* = 0xF055        # Load V0 to Vx into memory
    OPCODE_LD_VX_I* = 0xF065        # Load memory into V0 to Vx


# Variable Masks
const
    MASK_OPCODE* = 0xF000
    MASK_NNN* = 0x0FFF
    MASK_X* = 0x0F00
    MASK_Y* = 0x00F0
    MASK_N* = 0x000F
    MASK_KK* = 0x00FF
