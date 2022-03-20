
local ADDON_NAME, Data = ...


local buildMajor = tonumber(GetBuildInfo():match"^(%d+)%.")
if buildMajor == 2 then
  Data.WOW_VERSION = "BCC"
elseif buildMajor == 1 then
  Data.WOW_VERSION = "Classic"
end

function Data:IsBCC()
  return Data.WOW_VERSION == "BCC"
end
function Data:IsClassic()
  return Data.WOW_VERSION == "Classic"
end


Data.CHAT_COMMAND = ADDON_NAME:lower()

-- How spread out options are in interface options
local OPTIONS_DIVIDER_HEIGHT = 3



function Data:MakeDefaultOptions()
  return {
    profile = {
      
      Debug = {
        enabled = true,
        menu    = false,
      },
    },
    global = {
      
      UsePersistentStorage = true,
      
    },
  }
end



local function GetOptionTableHelpers(Options, Addon)
  local defaultInc = 1000
  local order      = 1000
  
  
  local function GetOption(key1, ...)
    if key1 == "global" then
      return Addon:GetGlobalOption(...)
    else
      return Addon:GetOption(key1, ...)
    end
  end
  local function SetOption(val, key1, ...)
    if key1 == "global" then
      return Addon:SetGlobalOption(val, ...)
    else
      return Addon:SetOption(val, key1, ...)
    end
  end
  
  local GUI = {}
  
  function GUI:GetOrder()
    return order
  end
  function GUI:SetOrder(newOrder)
    order = newOrder
  end
  function GUI:Order(inc)
    self:SetOrder(self:GetOrder() + (inc or defaultInc))
    return self:GetOrder()
  end
  
  function GUI:CreateEntry(key, name, desc, widgetType, order)
    key = widgetType .. "_" .. (key or "")
    Options.args[key] = {name = name, desc = desc, type = widgetType, order = order or self:Order()}
    return Options.args[key]
  end
  
  function GUI:CreateHeader(name)
    local option = self:CreateEntry(self:Order(), name, nil, "header", self:Order(0))
    return option
  end
  
  function GUI:CreateDescription(desc, fontSize)
    local option = self:CreateEntry(self:Order(), desc, nil, "description", self:Order(0))
    option.fontSize = fontSize or "large"
    return option
  end
  function GUI:CreateDivider(count)
    for i = 1, count or 3 do
      self:CreateDescription("", "small")
    end
  end
  function GUI:CreateNewline()
    return self:CreateDivider(1)
  end
  
  function GUI:CreateToggle(keys, name, desc, disabled)
    if type(keys) ~= "table" then keys = {keys} end
    local option = self:CreateEntry(table.concat(keys, "."), name, desc, "toggle")
    option.disabled = disabled
    option.set      = function(info, val)        SetOption(val, unpack(keys)) end
    option.get      = function(info)      return GetOption(unpack(keys))      end
    return option
  end
  function GUI:CreateRange(keys, name, desc, min, max, step, disabled)
    if type(keys) ~= "table" then keys = {keys} end
    local option = self:CreateEntry(table.concat(keys, "."), name, desc, "range")
    option.disabled = disabled
    option.min      = min
    option.max      = max
    option.step     = step
    option.set      = function(info, val)        SetOption(val, unpack(keys)) end
    option.get      = function(info)      return GetOption(unpack(keys))      end
    return option
  end
  function GUI:CreateInput(keys, name, desc, multiline, disabled)
    if type(keys) ~= "table" then keys = {keys} end
    local option = self:CreateEntry(table.concat(keys, "."), name, desc, "input")
    option.multiline = multiline
    option.disabled  = disabled
    option.set       = function(info, val)        SetOption(val, unpack(keys)) end
    option.get       = function(info)      return GetOption(unpack(keys))      end
    return option
  end
  function GUI:CreateExecute(key, name, desc, func)
    local option = self:CreateEntry(key, name, desc, "execute")
    option.func = func
    return option
  end
  
  return GUI
end


function Data:RefreshOptionsTable(title, Addon, L)
  Addon.Options[title] = Addon.Options[title] or {}
  Options = Addon.Options[title]
  wipe(Options)
  Options.name = title
  Options.type = "group"
  Options.args = {}
  
  local GUI = GetOptionTableHelpers(Options, Addon)
  
  GUI:CreateNewline()
  GUI:CreateToggle({"global", "UsePersistentStorage"}, L["Use Persistent Storage"], L["If enabled, cache will be stored on logout. This may slightly increase loading time.|n|nIf disabled, cache will be rebuilt during each session. This will result in dramatically more cache misses."])
  
  
  return Options
end




function Data:MakeDebugOptionsTable(title, Addon, L)
  local Options = {
    name = title,
    type = "group",
    args = {}
  }
  local GUI = GetOptionTableHelpers(Options, Addon)
  
  GUI:CreateToggle({"Debug", "enabled"}, "Enabled")
  
  return Options
end



