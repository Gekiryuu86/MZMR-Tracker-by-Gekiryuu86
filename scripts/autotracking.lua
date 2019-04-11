-- Configuration --------------------------------------
DEV_DEBUG = true
AUTOTRACKER_ENABLE_DEBUG_LOGGING = false
-------------------------------------------------------

file = io.open("test.log", "w")
io.output(file)

if (DEV_DEBUG) then
  file:write("Settings Loaded")
end

function autotracker_started()
  if (DEV_DEBUG) then
    file:write("Autotracker Started")
  end
    -- Invoked when the auto-tracker is activated/connected
end

U8_READ_CACHE = 0
U8_READ_CACHE_ADDRESS = 0

U16_READ_CACHE = 0
U16_READ_CACHE_ADDRESS = 0

FLAG_DIFFICULTY = 0x0300002C -- values of this byte can be 0 (easy), 1 (medium), 2 (hard)

-- SEGMENT_BASE is the location of all flags and values we'll be looking at. The segment is 15 bytes long with some useless data in between.
SEGMENT_BASE = 0x03001530

-- offsets for specific values/flags
OFFSET_MAX_HEALTH     = SEGMENT_BASE + 0x00
OFFSET_MAX_MISSILES   = SEGMENT_BASE + 0x02
OFFSET_MAX_SUPERS     = SEGMENT_BASE + 0x04
OFFSET_MAX_POWER_BOMB = SEGMENT_BASE + 0x05
OFFSET_BEAM_BOMB      = SEGMENT_BASE + 0x0C
OFFSET_UNIQUE_ITEMS   = SEGMENT_BASE + 0x0E

-- flags from the byte OFFSET_BEAM_BOMB
FLAG_LONG             = 0x1
FLAG_ICE              = 0x2
FLAG_WAVE             = 0x4
FLAG_PLASMA           = 0x8
FLAG_CHARGE           = 0x10
FLAG_BOMBS            = 0x80

-- flags from the byte OFFSET_UNIQUE_ITEMS
FLAG_JUMP             = 0x1
FLAG_SPEED            = 0x2
FLAG_SPACE            = 0x4
FLAG_SCREW            = 0x8
FLAG_VARIA            = 0x10
FLAG_GRAVITY          = 0x20
FLAG_MORPH            = 0x40
FLAG_POWER            = 0x80

if (DEV_DEBUG) then
  file:write("Variables initialized")
end

function InvalidateReadCaches()
  U8_READ_CACHE_ADDRESS = 0
  U16_READ_CACHE_ADDRESS = 0
end -- InvalidateReadCaches()

-- read one byte from memory at address (offset) in segment
function ReadU8(segment, address)
  if U8_READ_CACHE_ADDRESS ~= address then
    U8_READ_CACHE = segment:ReadUInt8(address)
    U8_READ_CACHE_ADDRESS = address
  end

  return U8_READ_CACHE
end -- ReadU8(segment, address)

-- read two bytes from memory at address (offset) in segment
function ReadU16(segment, address)
  if U16_READ_CACHE_ADDRESS ~= address then
    U16_READ_CACHE = segment:ReadUInt16(address)
    U16_READ_CACHE_ADDRESS = address        
  end

  return U16_READ_CACHE
end -- ReadU16(segment, address)

-- update a tracker item directly with the byte value at address
function updateProgressiveItemFromByte(segment, code, address, offset)
  local item = Tracker:FindObjectForCode(code)
  if item then
    local value = ReadU8(segment, address)
    item.CurrentStage = value + (offset or 0)
  end
end -- updateProgressiveItemFromByte(segment, code, address, offset)

-- toggle a tracker item based on the flag in address
function updateToggleItemFromByteAndFlag(segment, code, address, flag) 
  local item = Tracker:FindObjectForCode(code)
  if item then
    local value = ReadU8(segment, address)
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
      file:write(item.Name, code, flag)
    end

    local flagTest = value & flag

    if flagTest ~= 0 then
      item.Active = true
    else
      item.Active = false
    end
  end
end -- updateToggleItemFromByteAndFlag(segment, code, address, flag) 

if (DEV_DEBUG) then
  file:write("Functions Defined")
end

-- where all the work is done
function updateItemsFromMemorySegment(segment)

  InvalidateReadCaches()

  if (segment == SEGMENT_BASE) then
    local flagDifficulty = ReadU8(FLAG_DIFFICULTY, 0)

    local etank = Tracker:FindObjectForCode("etank")
    if etank then
      local maxEtanks = (ReadU16(OFFSET_MAX_HEALTH, 0) - 99) / (flagDifficulty == 2 and 50 or 100)
      etank.CurrentStage = maxEtanks
    end
    updateProgressiveItemFromByte(segment, "missile",   OFFSET_MAX_MISSILES, 0)
    updateProgressiveItemFromByte(segment, "super",     OFFSET_MAX_SUPERS, 0)
    updateProgressiveItemFromByte(segment, "powerbomb", OFFSET_MAX_POWER_BOMB, 0)
  end

  if (segment == SEGMENT_BEAM_BOMB) then
    updateToggleItemFromByteAndFlag(segment, "long",    SEGMENT_BEAM_BOMB, FLAG_LONG    )
    updateToggleItemFromByteAndFlag(segment, "ice",     SEGMENT_BEAM_BOMB, FLAG_ICE     )
    updateToggleItemFromByteAndFlag(segment, "wave",    SEGMENT_BEAM_BOMB, FLAG_WAVE    )
    updateToggleItemFromByteAndFlag(segment, "plasma",  SEGMENT_BEAM_BOMB, FLAG_PLASMA  )
    updateToggleItemFromByteAndFlag(segment, "charge",  SEGMENT_BEAM_BOMB, FLAG_CHARGE  )
    updateToggleItemFromByteAndFlag(segment, "bomb",    SEGMENT_BEAM_BOMB, FLAG_BOMB    )
  end

  if (segment == SEGMENT_SUIT) then
    updateToggleItemFromByteAndFlag(segment, "jump",    SEGMENT_SUIT, FLAG_JUMP    )
    updateToggleItemFromByteAndFlag(segment, "speed",   SEGMENT_SUIT, FLAG_SPEED   )
    updateToggleItemFromByteAndFlag(segment, "space",   SEGMENT_SUIT, FLAG_SPACE   )
    updateToggleItemFromByteAndFlag(segment, "screw",   SEGMENT_SUIT, FLAG_SCREW   )
    updateToggleItemFromByteAndFlag(segment, "varia",   SEGMENT_SUIT, FLAG_VARIA   )
    updateToggleItemFromByteAndFlag(segment, "gravity", SEGMENT_SUIT, FLAG_GRAVITY )
    updateToggleItemFromByteAndFlag(segment, "morph",   SEGMENT_SUIT, FLAG_MORPH   )
    updateToggleItemFromByteAndFlag(segment, "grip",    SEGMENT_SUIT, FLAG_GRIP    )
  end
end -- updateItemsFromMemorySegment(segment)

if (DEV_DEBUG) then
  file:write("Main Function Defined")
end

-- These are what keep the script running
ScriptHost:AddMemoryWatch("MZM Tank Data",        SEGMENT_BASE,        5, updateItemsFromMemorySegment)
ScriptHost:AddMemoryWatch("MZM Beam-Bomb Data",   OFFSET_BEAM_BOMB,    1, updateItemsFromMemorySegment)
ScriptHost:AddMemoryWatch("MZM Unique Item Data", OFFSET_UNIQUE_ITEMS, 1, updateItemsFromMemorySegment)

if (DEV_DEBUG) then
  file:write("Memory watches added")
end

file:close()
