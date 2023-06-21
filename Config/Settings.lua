
local ADDON_NAME, Data = ...

local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)




function Addon:MakeDefaultOptions()
  local fakeAddon = {
    db = {
      profile = {
        
        -- Debug options
        debug = false,
          
        debugOutput = {
          ["*"] = false,
        },
      },
      
      global = {
        UsePersistentStorage = true,
      },
    },
  }
  return fakeAddon.db
end
