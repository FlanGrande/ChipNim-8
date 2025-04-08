import globals

# Forward declaration for Chip8 (from chip8.nim)
type
    Chip8* = object of RootObj # This is just for the compiler, will be imported properly

type
    Chip8State* = object
        # Memory state
        memory*: array[MEMORY_SIZE, uint8]
        
        # CPU state
        V*: array[16, uint8]        # 16 general purpose registers V0 to VF
        I*: uint16                  # Index register
        pc*: uint16                 # Program counter
        
        # Graphics state
        gfx*: array[DISPLAY_SIZE, uint8]  # Graphics: 64x32 monochrome display
        didDraw*: bool              # Flag to indicate if the screen was drawn during the last frame
        
        # Timer state
        delay_timer*: uint8
        sound_timer*: uint8
        
        # Stack state
        stack*: array[16, uint16]
        sp*: uint8                  # Stack pointer
        
        # Input state
        key*: array[16, uint8]      # Hex-based keypad (0x0–0xF)
        waitingForKey*: bool
        waitingRegister*: uint8
        
        # ROM info
        romName*: string

# Declarations of procedures that will be implemented elsewhere
# to avoid circular imports with chip8.nim

# Creates a new Chip8State instance with default values
proc createState*(): Chip8State =
    result = Chip8State()
    # Initialize arrays and other default values
    result.pc = PROGRAM_START
    result.didDraw = false

# Creates a Chip8State from the current state of a Chip8 emulator
proc saveState*(chip8: var Chip8): Chip8State =
    result = Chip8State(
        memory: chip8.memory,
        V: chip8.V,
        I: chip8.I,
        pc: chip8.pc,
        gfx: chip8.gfx,
        didDraw: chip8.didDraw,
        delay_timer: chip8.delay_timer,
        sound_timer: chip8.sound_timer,
        stack: chip8.stack,
        sp: chip8.sp,
        key: chip8.key,
        waitingForKey: chip8.waitingForKey,
        waitingRegister: chip8.waitingRegister,
        romName: chip8.romName
    )

# Restores a Chip8 emulator to a previously saved state
proc loadState*(chip8: var Chip8, state: Chip8State) =
    chip8.memory = state.memory
    chip8.V = state.V
    chip8.I = state.I
    chip8.pc = state.pc
    chip8.gfx = state.gfx
    chip8.didDraw = state.didDraw
    chip8.delay_timer = state.delay_timer
    chip8.sound_timer = state.sound_timer
    chip8.stack = state.stack
    chip8.sp = state.sp
    chip8.key = state.key
    chip8.waitingForKey = state.waitingForKey
    chip8.waitingRegister = state.waitingRegister
    chip8.romName = state.romName 