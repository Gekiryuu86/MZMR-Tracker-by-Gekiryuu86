-- Configuration --------------------------------------
DEV_DEBUG = true
AUTOTRACKER_ENABLE_DEBUG_LOGGING = false
-------------------------------------------------------

file = io.open("test.log", "w")
io.output(file)

if (DEV_DEBUG) then
  file:write("Settings Loaded")
end

-------------------------------------------------------
-- Memory Locations
-------------------------------------------------------

local ADDRESS_DIFFICULTY = 0x0300002C -- values of this byte can be 0 (easy), 1 (medium), 2 (hard)

-- the array index is the item name for the tracker (etanks require calculation, so they're special)
-- address := memory address of the items' max value
-- length := number of bytes the value is stored in
DATA_TANKS["health"]  = { address = 0x03001530 , length = 2 }
DATA_TANKS["missile"] = { address = 0x03001532 , length = 2 }
DATA_TANKS["super"]   = { address = 0x03001534 , length = 1 }
DATA_TANKS["pb"]      = { address = 0x03001535 , length = 1 }

ADDRESS_BEAMS_BOMB = 0x0300153C
-- flag := the bit that determines if you have an item or not
DATA_BEAMS_BOMB["long"]   = { flag = 0x01 }
DATA_BEAMS_BOMB["ice"]    = { flag = 0x02 }
DATA_BEAMS_BOMB["wave"]   = { flag = 0x04 }
DATA_BEAMS_BOMB["plasma"] = { flag = 0x08 }
DATA_BEAMS_BOMB["charge"] = { flag = 0x10 }
DATA_BEAMS_BOMB["bomb"]   = { flag = 0x80 }

ADDRESS_ABILITIES = 0x0300153E -- this is separate in order to use the existing memory read functions
DATA_ABILITIES["hijump"]  = { flag = 0x01 }
DATA_ABILITIES["speed"]   = { flag = 0x02 }
DATA_ABILITIES["space"]   = { flag = 0x04 }
DATA_ABILITIES["screw"]   = { flag = 0x08 }
DATA_ABILITIES["varia"]   = { flag = 0x10 }
DATA_ABILITIES["gravity"] = { flag = 0x20 }
DATA_ABILITIES["morph"]   = { flag = 0x40 }
DATA_ABILITIES["grip"]    = { flag = 0x80 }

function autotracker_started()
  -- Invoked when the auto-tracker is activated/connected
end -- autotracker_started()

-------------------------------------------------------
-- Helper Functions
-------------------------------------------------------

U8_READ_CACHE = 0
U8_READ_CACHE_ADDRESS = 0

U16_READ_CACHE = 0
U16_READ_CACHE_ADDRESS = 0

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

-- update a tracker item directly with the U16 value at address
function updateProgressiveItem(segment, code, address, bytes, offset)
  local item = Tracker:FindObjectForCode(code)
  if (bytes == 1) then
    if item then
      local value = ReadU8(segment, address)
      item.CurrentStage = value + (offset or 0)
    end
  elseif (bytes == 2) then
    if item then
      local value = ReadU16(segment, address)
      item.CurrentStage = value + (offset or 0)
    end
  end
end -- updateProgressiveItem(segment, code, address, bytes, offset)

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

-------------------------------------------------------
-- Main Functions
-------------------------------------------------------

function updateTanksFromMemorySegment(segment)
  InvalidateReadCaches()
  
  local difficulty = ReadU8(segment, ADDRESS_DIFFICULTY)

  for itemName, value in pairs(DATA_TANKS)
  if itemName == "health" then
    local itemTracker = Tracker:FindObjectForCode("etank")
    if itemTracker then
      local etanks = ( ReadUInt16(segment, value.address) - 99) / (difficulty == 2 and 50 or 100)
      itemTracker.CurrentStage = etanks
    end
  else
    updateProgressiveItem(segment, itemName, value.address, value.length, 0)
  end
end -- updateTanksFromMemorySegment(segment)

function updateBeamsFromMemorySegment(segment)
  InvalidateReadCaches()

  for itemName, value in pairs(DATA_BEAMS_BOMB)
    updateToggleItemFromByteAndFlag(segment, itemName, ADDRESS_BEAMS_BOMB, value.flag)
  end
end -- updateBeamsFromMemorySegment(segment)

function updateAbilitiesFromMemorySegment(segment)
  InvalidateReadCaches()

  for itemName, value in pairs(DATA_ABILITIES)
    updateToggleItemFromByteAndFlag(segment, itemName, ADDRESS_ABILITIES, value.flag)
  end
end -- updateAbilitiesFromMemorySegment(segment)

-- These are what keep the script running
ScriptHost:AddMemoryWatch("MZM Tank Data",        DATA_TANKS["health"].address, 5, updateTanksFromMemorySegment)
ScriptHost:AddMemoryWatch("MZM Beam-Bomb Data",   ADDRESS_BEAMS_BOMB,           2, updateBeamsFromMemorySegment)
ScriptHost:AddMemoryWatch("MZM Unique Item Data", ADDRESS_ABILITIES,            2, updateAbilitiesFromMemorySegment)

file:close()
