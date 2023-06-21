

local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0")
ItemCacheAddon = Addon


Addon.AceConfig         = LibStub"AceConfig-3.0"
Addon.AceConfigDialog   = LibStub"AceConfigDialog-3.0"
Addon.AceConfigRegistry = LibStub"AceConfigRegistry-3.0"
Addon.AceDB             = LibStub"AceDB-3.0"
Addon.AceDBOptions      = LibStub"AceDBOptions-3.0"





local strMatch  = string.match
local strSub    = string.sub

local tblConcat = table.concat
local tblRemove = table.remove

local mathFloor = math.floor
local mathMin   = math.min
local mathMax   = math.max

local ipairs       = ipairs
local next         = next
local unpack       = unpack
local select       = select
local type         = type
local format       = format
local tostring     = tostring
local tonumber     = tonumber
local getmetatable = getmetatable
local setmetatable = setmetatable
local assert       = assert
local random       = random



Addon.onOptionSetHandlers = {}





--  ██████╗ ███████╗██████╗ ██╗   ██╗ ██████╗ 
--  ██╔══██╗██╔════╝██╔══██╗██║   ██║██╔════╝ 
--  ██║  ██║█████╗  ██████╔╝██║   ██║██║  ███╗
--  ██║  ██║██╔══╝  ██╔══██╗██║   ██║██║   ██║
--  ██████╔╝███████╗██████╔╝╚██████╔╝╚██████╔╝
--  ╚═════╝ ╚══════╝╚═════╝  ╚═════╝  ╚═════╝ 


do
  Addon.debugPrefix = "[" .. BINDING_HEADER_DEBUG .. "]"
  
  local debugMode = false
  
  --@debug@
  do
    debugMode = true
    
    -- GAME_LOCALE = "enUS" -- AceLocale override
    
    -- TOOLTIP_UPDATE_TIME = 10000
    
    -- DECIMAL_SEPERATOR = ","
  end
  --@end-debug@
  
  function Addon:IsDebugEnabled()
    if self.db then
      return self:GetOption"debug"
    else
      return debugMode
    end
  end
  
  local function Debug(self, methodName, ...)
    if not self:IsDebugEnabled() then return end
    if self.GetOption and self:GetOption("debugOutput", "suppressAll") then return end
    return self[methodName](self, ...)
  end
  function Addon:Debug(...)
    return Debug(self, "Print", self.debugPrefix, ...)
  end
  function Addon:Debugf(...)
    return Debug(self, "Printf", "%s " .. select(1, ...), self.debugPrefix, select(2, ...))
  end
  
  local function DebugIf(self, methodName, keys, ...)
    if self.GetOption and self:GetOption(unpack(keys)) then
      return self[methodName](self, ...)
    end
  end
  function Addon:DebugIf(keys, ...)
    return DebugIf(self, "Debug", keys, ...)
  end
  function Addon:DebugfIf(keys, ...)
    return DebugIf(self, "Debugf", keys, ...)
  end
  
  function Addon:DebugData(t)
    local texts = {}
    for _, data in ipairs(t) do
      if data[2] ~= nil then
        if type(data[2]) == "string" then
          tinsert(texts, data[1] .. ": '" .. data[2] .. "'")
        else
          tinsert(texts, data[1] .. ": " .. tostring(data[2]))
        end
      end
    end
    self:Debug(tblConcat(texts, ", "))
  end
  function Addon:DebugDataIf(keys, ...)
    if self.GetOption and self:GetOption(unpack(keys)) then
      return self:DebugData(...)
    end
  end
  
  
  function Addon:GetDebugView(key)
    return self:IsDebugEnabled() and not self:GetOption("debugView", "suppressAll") and self:GetOption("debugView", key)
  end
  
  do
    local function GetErrorHandler(errFunc)
      if Addon:IsDebugEnabled() and (not Addon:IsDBLoaded() or Addon:GetOption("debugOutput", "luaError")) then
        return function(...)
          geterrorhandler()(...)
          if errFunc then
            Addon:xpcall(errFunc)
          end
        end
      end
      return nop
    end
    function Addon:xpcall(func, errFunc)
      return xpcall(func, GetErrorHandler(errFunc))
    end
    function Addon:Throw(...)
      if Addon:IsDebugEnabled() and (not Addon:IsDBLoaded() or Addon:GetOption("debugOutput", "luaError")) then
        local text = format(...)
        geterrorhandler()(...)
      end
    end
    function Addon:Throwf(...)
      return self:Throw(format(...))
    end
  end
end





--  ██████╗  █████╗ ████████╗ █████╗ ██████╗  █████╗ ███████╗███████╗
--  ██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔════╝
--  ██║  ██║███████║   ██║   ███████║██████╔╝███████║███████╗█████╗  
--  ██║  ██║██╔══██║   ██║   ██╔══██║██╔══██╗██╔══██║╚════██║██╔══╝  
--  ██████╔╝██║  ██║   ██║   ██║  ██║██████╔╝██║  ██║███████║███████╗
--  ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝

do
  local function DeepCopy(orig, seen)
    local new
    if type(orig) == "table" then
      if seen[orig] then
        new = seen[orig]
      else
        new = {}
        seen[orig] = copy
        for k, v in next, orig, nil do
          new[DeepCopy(k, seen)] = DeepCopy(v, seen)
        end
        setmetatable(new, DeepCopy(getmetatable(orig), seen))
      end
    else
      new = orig
    end
    return new
  end
  function Addon:Copy(val)
    return DeepCopy(val, {})
  end
  
  function Addon:IsDBLoaded()
    return self.db ~= nil
  end
  function Addon:GetDB()
    return self.db
  end
  function Addon:GetDefaultDB()
    return self.dbDefault
  end
  function Addon:GetProfile()
    return Addon.GetDB(self).profile
  end
  function Addon:GetGlobal()
    return Addon:GetDB(self).global
  end
  function Addon:GetDefaultGlobal()
    return Addon:GetDefaultDB(self).global
  end
  function Addon:GetDefaultProfile()
    return Addon.GetDefaultDB(self).profile
  end
  local function GetOption(self, db, ...)
    local val = db
    for _, key in ipairs{...} do
      assert(type(val) == "table", format("Bad database access: %s", tblConcat({...}, " > ")))
      val = val[key]
    end
    return val
  end
  function Addon:GetOption(...)
    return GetOption(self, Addon.GetProfile(self), ...)
  end
  function Addon:GetDefaultOption(...)
    return GetOption(self, Addon.GetDefaultProfile(self), ...)
  end
  function Addon:GetGlobalOption(...)
    return GetOption(self, Addon.GetGlobal(self), ...)
  end
  local function SetOption(self, db, val, ...)
    local keys = {...}
    local lastKey = tblRemove(keys, #keys)
    local tbl = db
    for _, key in ipairs(keys) do
      tbl = tbl[key]
    end
    tbl[lastKey] = val
    Addon.OnOptionSet(Addon, db, val, ...)
  end
  function Addon:SetOption(val, ...)
    return SetOption(self, Addon.GetProfile(self), val, ...)
  end
  function Addon:SetGlobalOption(val, ...)
    return SetOption(self, Addon.GetGlobal(self), val, ...)
  end
  function Addon:ToggleOption(...)
    return Addon:SetOption(not Addon:GetOption(...), ...)
  end
  function Addon:ToggleGlobalOption(...)
    return Addon:SetOption(not Addon:GetGlobalOption(...), ...)
  end
  function Addon:ResetOption(...)
    return Addon.SetOption(self, Addon.Copy(self, Addon.GetDefaultOption(self, ...)), ...)
  end
  function Addon:ResetGlobalOption(...)
    return Addon.SetOption(self, Addon.Copy(self, Addon.GetDefaultGlobalOption(self, ...)), ...)
  end
  
  function Addon:OnOptionSet(...)
    if not self:GetDB() then return end -- db hasn't loaded yet
    for funcName, func in next, Addon.onOptionSetHandlers, nil do
      if type(func) == "function" then
        func(self, ...)
      else
        self[funcName](self, ...)
      end
    end
  end
end






--   ██████╗ ██████╗ ████████╗██╗ ██████╗ ███╗   ██╗███████╗
--  ██╔═══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
--  ██║   ██║██████╔╝   ██║   ██║██║   ██║██╔██╗ ██║███████╗
--  ██║   ██║██╔═══╝    ██║   ██║██║   ██║██║╚██╗██║╚════██║
--  ╚██████╔╝██║        ██║   ██║╚██████╔╝██║ ╚████║███████║
--   ╚═════╝ ╚═╝        ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

do
  function Addon:OpenConfig(category)
    InterfaceOptionsFrame_OpenToCategory(category)
    InterfaceOptionsFrame_OpenToCategory(category)
  end
  
  function Addon:ResetProfile(category)
    self:GetDB():ResetProfile()
    self.AceConfigRegistry:NotifyChange(category)
  end
  
  function Addon:CreateOptionsCategory(categoryName, options)
    local category = ADDON_NAME .. (categoryName and ("." .. categoryName) or "")
    self.AceConfig:RegisterOptionsTable(category, options)
    local Panel = self.AceConfigDialog:AddToBlizOptions(category, categoryName, categoryName and ADDON_NAME or nil)
    Panel.default = function() self:ResetProfile(category) end
    return Panel
  end
end






--  ███╗   ██╗██╗   ██╗███╗   ███╗██████╗ ███████╗██████╗ ███████╗
--  ████╗  ██║██║   ██║████╗ ████║██╔══██╗██╔════╝██╔══██╗██╔════╝
--  ██╔██╗ ██║██║   ██║██╔████╔██║██████╔╝█████╗  ██████╔╝███████╗
--  ██║╚██╗██║██║   ██║██║╚██╔╝██║██╔══██╗██╔══╝  ██╔══██╗╚════██║
--  ██║ ╚████║╚██████╔╝██║ ╚═╝ ██║██████╔╝███████╗██║  ██║███████║
--  ╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝

do
  function Addon:Round(num, nearest)
    nearest = nearest or 1
    local lower = mathFloor(num / nearest) * nearest
    local upper = lower + nearest
    return (upper - num < num - lower) and upper or lower
  end
  
  function Addon:Clamp(min, num, max)
    assert(type(min) == "number", "Can't clamp. min is " .. type(min))
    assert(type(max) == "number", "Can't clamp. max is " .. type(max))
    assert(min <= max, format("Can't clamp. min (%d) > max (%d)", min, max))
    return mathMin(mathMax(num, min), max)
  end
end






--  ████████╗ █████╗ ██████╗ ██╗     ███████╗███████╗
--  ╚══██╔══╝██╔══██╗██╔══██╗██║     ██╔════╝██╔════╝
--     ██║   ███████║██████╔╝██║     █████╗  ███████╗
--     ██║   ██╔══██║██╔══██╗██║     ██╔══╝  ╚════██║
--     ██║   ██║  ██║██████╔╝███████╗███████╗███████║
--     ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝╚══════╝

do
  function Addon:Map(t, ValMap, KeyMap)
    if type(KeyMap) == "table" then
      local keyTbl = KeyMap
      KeyMap = function(v, k, self) return keyTbl[k] end
    end
    if type(ValMap) == "table" then
      local valTbl = KeyMap
      ValMap = function(v, k, self) return valTbl[k] end
    end
    local new = {}
    for k, v in next, t, nil do
      local key, val = k, v
      if KeyMap then
        key = KeyMap(v, k, t)
      end
      if ValMap then
        val = ValMap(v, k, t)
      end
      if key then
        new[key] = val
      end
    end
    local meta = getmetatable(t)
    if meta then
      setmetatable(new, meta)
    end
    return new
  end
  
  function Addon:MakeLookupTable(t, val, keepOrigVals)
    local ValFunc
    if val ~= nil then
      if type(val) == "function" then
        ValFunc = val
      else
        ValFunc = function() return val end
      end
    end
    local new = {}
    for k, v in next, t, nil do
      if ValFunc then
        new[v] = ValFunc(v, k, t)
      else
        new[v] = k
      end
      if keepOrigVals and new[k] == nil then
        new[k] = v
      end
    end
    return new
  end
  
  function Addon:Random(t)
    return t[random(#t)]
  end
end
