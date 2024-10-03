

local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")


Addon.AceConfig         = LibStub"AceConfig-3.0"
Addon.AceConfigDialog   = LibStub"AceConfigDialog-3.0"
Addon.AceConfigRegistry = LibStub"AceConfigRegistry-3.0"
Addon.AceDB             = LibStub"AceDB-3.0"
Addon.AceDBOptions      = LibStub"AceDBOptions-3.0"

Addon.SemVer = LibStub"SemVer"




local strMatch     = string.match
local strSub       = string.sub
local strGsub      = string.gsub

local tblConcat    = table.concat
local tblSort      = table.sort
local tblRemove    = table.remove

local mathFloor    = math.floor
local mathMin      = math.min
local mathMax      = math.max
local mathRandom   = math.random

local ipairs       = ipairs
local next         = next
local unpack       = unpack
local select       = select
local type         = type
local format       = format
local tinsert      = tinsert
local strjoin      = strjoin
local tostring     = tostring
local tonumber     = tonumber
local getmetatable = getmetatable
local setmetatable = setmetatable
local assert       = assert
local random       = random








--  ██████╗ ███████╗██████╗ ██╗   ██╗ ██████╗ 
--  ██╔══██╗██╔════╝██╔══██╗██║   ██║██╔════╝ 
--  ██║  ██║█████╗  ██████╔╝██║   ██║██║  ███╗
--  ██║  ██║██╔══╝  ██╔══██╗██║   ██║██║   ██║
--  ██████╔╝███████╗██████╔╝╚██████╔╝╚██████╔╝
--  ╚═════╝ ╚══════╝╚═════╝  ╚═════╝  ╚═════╝ 


do
  Addon.debugPrefix = "[" .. (BINDING_HEADER_DEBUG or "Debug") .. "]"
  Addon.warnPrefix  = "[" .. (LUA_WARNING or "Warning") .. "]"
  
  local debugMode = false
  
  --@debug@
  do
    debugMode = true
    
    -- GAME_LOCALE = "enUS" -- AceLocale override
    
    -- TOOLTIP_UPDATE_TIME = 10000
  end
  --@end-debug@
  
  
  local function CheckOptionSafe(default, ...)
    if Addon.db then
      return Addon:CheckTable(Addon.db, ...)
    else
      return default
    end
  end
  
  function Addon:IsDebugEnabled()
    return CheckOptionSafe(debugMode, "global", "debug")
  end
  local function IsDebugSuppressed()
    return not Addon:IsDebugEnabled() or CheckOptionSafe(not debugMode, "global", "debugOutput", "suppressAll")
  end
  local function ShouldShowLuaErrors()
    return Addon:IsDebugEnabled() and CheckOptionSafe(debugMode, "global", "debugShowLuaErrors")
  end
  local function ShouldShowWarnings()
    return Addon:IsDebugEnabled() and CheckOptionSafe(debugMode, "global", "debugShowLuaWarnings")
  end
  function Addon:GetDebugView(key)
    return self:IsDebugEnabled() and not CheckOptionSafe(debugMode, "global", "suppressAll") and CheckOptionSafe(debugMode, "global", "debugView", key)
  end
  
  function Addon:Dump(t)
    return DevTools_Dump(t)
  end
  
  local function Debug(self, methodName, ...)
    if IsDebugSuppressed() then return end
    return self[methodName](self, ...)
  end
  function Addon:Debug(...)
    return Debug(self, "Print", self.debugPrefix, ...)
  end
  function Addon:Debugf(...)
    return Debug(self, "Printf", "%s " .. select(1, ...), self.debugPrefix, select(2, ...))
  end
  function Addon:DebugDump(t, header)
    if header then
      Debug(self, "Print", self.debugPrefix, tostring(header) .. ":")
    end
    return self:Dump(t)
  end
  
  
  local function Warn(self, methodName, ...)
    if not ShouldShowWarnings() then return end
    return self[methodName](self, ...)
  end
  function Addon:Warn(...)
    return Warn(self, "Print", self.warnPrefix, ...)
  end
  function Addon:Warnf(...)
    return Warn(self, "Printf", "%s " .. select(1, ...), self.warnPrefix, select(2, ...))
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
  function Addon:DebugDumpIf(keys, ...)
    return DebugIf(self, "DebugDump", keys, ...)
  end
  
  local function DebugIfOutput(self, methodName, key, ...)
    if self.GetGlobalOption and self:GetGlobalOptionQuiet("debugOutput", key) then
      return self[methodName](self, ...)
    end
  end
  function Addon:DebugIfOutput(key, ...)
    return DebugIfOutput(self, "Debug", key, ...)
  end
  function Addon:DebugfIfOutput(key, ...)
    return DebugIfOutput(self, "Debugf", key, ...)
  end
  function Addon:DebugDumpIfOutput(key, ...)
    return DebugIfOutput(self, "DebugDump", key, ...)
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
  
  
  do
    local function GetErrorHandler(errFunc)
      if Addon:IsDebugEnabled() and ShouldShowLuaErrors() then
        return function(...)
          geterrorhandler()(...)
          if errFunc then
            Addon:xpcall(errFunc)
          end
        end
      end
      return nop
    end
    -- calls func in protected mode. errors are announced and then passed to errFunc. errFunc errors silently. non-blocking.
    function Addon:xpcall(func, errFunc)
      return xpcall(func, GetErrorHandler(errFunc))
    end
    -- calls func in protected mode. errors passed to errFunc if it exists. errFunc errors silently. non-blocking.
    function Addon:xpcallSilent(func, errFunc)
      return xpcall(func, errFunc or nop)
    end
    -- calls func in protected mode. errors passed to errFunc. non-blocking, unless errFunc errors.
    function Addon:pcall(func, errFunc)
      local t = {pcall(func)}
      if not t[1] then
        errFunc(unpack(t, 2))
      end
      return unpack(t, 2)
    end
    -- Creates a non-blocking error.
    function Addon:Throw(...)
      if Addon:IsDebugEnabled() and ShouldShowLuaErrors() then
        geterrorhandler()(...)
      end
    end
    function Addon:Throwf(...)
      local args = {...}
      local count = select("#", ...)
      self:xpcall(function() self:Throw(format(unpack(args, 1, count))) end)
    end
    -- Creates a non-blocking error if bool is falsy.
    function Addon:ThrowAssert(bool, ...)
      if bool then return bool end
      if Addon:IsDebugEnabled() and ShouldShowLuaErrors() then
        geterrorhandler()(...)
      end
      return false
    end
    function Addon:ThrowfAssert(bool, ...)
      if bool then return bool end
      local args = {...}
      local count = select("#", ...)
      self:xpcall(function() self:Throw(format(unpack(args, 1, count))) end)
      return false
    end
    -- Creates a blocking error.
    function Addon:Error(str)
      error(str, 2)
    end
    function Addon:Errorf(...)
      error(format(...), 2)
    end
    function Addon:ErrorLevel(lvl, str)
      error(str, lvl + 1)
    end
    function Addon:ErrorfLevel(lvl, ...)
      error(format(...), lvl + 1)
    end
    -- Creates a blocking error if bool is falsy.
    function Addon:Assert(bool, str)
      if not bool then
        error(str, 2)
      end
    end
    function Addon:Assertf(bool, ...)
      if not bool then
        error(format(...), 2)
      end
    end
    function Addon:AssertLevel(lvl, bool, str)
      if not bool then
        error(str, lvl + 1)
      end
    end
    function Addon:AssertfLevel(lvl, bool, ...)
      if not bool then
        error(format(...), lvl + 1)
      end
    end
  end
end





--  ███████╗██╗  ██╗██████╗  █████╗ ███╗   ██╗███████╗██╗ ██████╗ ███╗   ██╗███████╗
--  ██╔════╝╚██╗██╔╝██╔══██╗██╔══██╗████╗  ██║██╔════╝██║██╔═══██╗████╗  ██║██╔════╝
--  █████╗   ╚███╔╝ ██████╔╝███████║██╔██╗ ██║███████╗██║██║   ██║██╔██╗ ██║███████╗
--  ██╔══╝   ██╔██╗ ██╔═══╝ ██╔══██║██║╚██╗██║╚════██║██║██║   ██║██║╚██╗██║╚════██║
--  ███████╗██╔╝ ██╗██║     ██║  ██║██║ ╚████║███████║██║╚██████╔╝██║ ╚████║███████║
--  ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

do
  Addon.expansions = {
    retail  = 11,
    tww     = 11,
    df      = 10,
    sl      = 9,
    bfa     = 8,
    legion  = 7,
    wod     = 6,
    mop     = 5,
    cata    = 4,
    wrath   = 3,
    tbc     = 2,
    era     = 1,
    vanilla = 1,
  }
  
  Addon.expansionLevel = tonumber(GetBuildInfo():match"^(%d+)%.")
  
  Addon.isRetail  = Addon.expansionLevel >= Addon.expansions.retail
  Addon.isClassic = not Addon.isRetail
  
  Addon.isTWW     = Addon.expansionLevel == Addon.expansions.tww
  Addon.isDF      = Addon.expansionLevel == Addon.expansions.df
  Addon.isSL      = Addon.expansionLevel == Addon.expansions.sl
  Addon.isBfA     = Addon.expansionLevel == Addon.expansions.bfa
  Addon.isLegion  = Addon.expansionLevel == Addon.expansions.legion
  Addon.isWoD     = Addon.expansionLevel == Addon.expansions.wod
  Addon.isMoP     = Addon.expansionLevel == Addon.expansions.mop
  Addon.isCata    = Addon.expansionLevel == Addon.expansions.cata
  Addon.isWrath   = Addon.expansionLevel == Addon.expansions.wrath
  Addon.isTBC     = Addon.expansionLevel == Addon.expansions.tbc
  Addon.isEra     = Addon.expansionLevel == Addon.expansions.era
  
  local season = ((C_Seasons or {}).GetActiveSeason or nop)() or 0
  Addon.isSoM = season == Enum.SeasonID.SeasonOfMastery
  Addon.isSoD = season == Enum.SeasonID.SeasonOfDiscovery
end







--  ████████╗ █████╗ ██████╗ ██╗     ███████╗███████╗
--  ╚══██╔══╝██╔══██╗██╔══██╗██║     ██╔════╝██╔════╝
--     ██║   ███████║██████╔╝██║     █████╗  ███████╗
--     ██║   ██╔══██║██╔══██╗██║     ██╔══╝  ╚════██║
--     ██║   ██║  ██║██████╔╝███████╗███████╗███████║
--     ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝╚══════╝

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
  
  function Addon:TableConcat(tbl, separator)
    local t = {}
    for i, v in ipairs(tbl) do
      if type(v) == "string" then
        t[i] = v
      else
        t[i] = tostring(v)
      end
    end
    return tblConcat(t, separator)
  end
  
  
  
  do
    local privates = setmetatable({}, {__mode = "k"})
    function Addon:GetPrivate(obj)
      return privates[obj]
    end
    function Addon:SetPrivate(obj, p)
      privates[obj] = p
      return obj
    end
  end
  
  do
    local function GetPre(t, i)
      return Addon:CheckTable(t, "links", i, 1) or i-1
    end
    local function GetNex(t, i)
      return Addon:CheckTable(t, "links", i, 2) or i+1
    end
    local function Link(t, pre, nex)
      local actual = rawget(t, "actual")
      if Addon:CheckTable(actual, pre) ~= nil and Addon:CheckTable(actual, nex) ~= nil then
        Addon:StoreInTable(t, "links", pre, 2, nex)
        Addon:StoreInTable(t, "links", nex, 1, pre)
      else
        if Addon:CheckTable(actual, pre) ~= nil then
          if Addon:CheckTable(t, "links", pre, 1) then
            Addon:RemoveInTable(t, "links", pre, 2)
          elseif Addon:CheckTable(t, "links", pre) then
            local links  = rawget(t, "links")
            rawset(links, pre, nil)
            if not next(links) then
              rawset(t, "links", nil)
            end
          end
        else
          if Addon:CheckTable(t, "links", nex, 2) then
            Addon:RemoveInTable(t, "links", nex, 1)
          elseif Addon:CheckTable(t, "links", nex, 2) then
            local links  = rawget(t, "links")
            rawset(links, nex, nil)
            if not next(links) then
              rawset(t, "links", nil)
            end
          end
        end
      end
    end
    
    local IndexedQueue = setmetatable({}, {__call = function(self, ...) return self:Create(...) end})
    Addon.IndexedQueue = IndexedQueue
    local meta = {}
    
    function IndexedQueue:Add(v)
      Addon:AssertfLevel(2, v ~= nil, "Attempted to add a nil value")
      
      local id  = Addon:CheckTable(self, "next")
      Addon:StoreInTable(self, "next", id + 1)
      
      local pre = Addon:CheckTable(self, "tail")
      if pre then
        if pre ~= id-1 then
          Addon:StoreInTable(self, "links", pre, 2, id)
          Addon:StoreInTable(self, "links", id,   1, pre)
        end
      end
      Addon:StoreInTable(self, "tail", id)
      Addon:StoreDefault(self, "head", id)
      
      Addon:StoreInTable(self, "actual", id, v)
      Addon:StoreInTable(self, "count", Addon:CheckTable(self, "count") + 1)
      
      return id
    end
    
    function IndexedQueue:Remove(id)
      Addon:AssertfLevel(2, type(id) == "number", "Attempted to remove a non-number index: %s (%s)", tostring(id), type(id))
      local v = rawget(Addon:CheckTable(self, "actual"), id)
      Addon:AssertfLevel(2, v ~= nil, "Attempted to remove a nil value from index: %s (%s)", tostring(id), type(id))
      
      local pre = GetPre(self, id)
      local nex = GetNex(self, id)
      if Addon:CheckTable(self, "links", id) then
        Addon:RemoveInTable(self, "links", id)
      end
      Link(self, pre, nex)
      
      if Addon:CheckTable(self, "head") == id then
        if Addon:CheckTable(self, "actual", nex) then
          Addon:StoreInTable(self, "head", nex)
        else
          Addon:RemoveInTable(self, "head")
        end
      end
      if Addon:CheckTable(self, "tail") == id then
        if Addon:CheckTable(self, "actual", pre) then
          Addon:StoreInTable(self, "tail", pre)
        else
          Addon:RemoveInTable(self, "tail")
        end
      end
      
      local value = Addon:CheckTable(self, "actual", id)
      Addon:RemoveInTable(self, "actual", id)
      Addon:StoreInTable(self, "count", Addon:CheckTable(self, "count") - 1)
      
      return value
    end
    
    function IndexedQueue:Pop()
      local tail = Addon:CheckTable(self, "tail")
      Addon:AssertLevel(2, tail, "Attempted to pop while empty")
      return IndexedQueue.Remove(self, tail)
    end
    
    function IndexedQueue:Get(id)
      Addon:AssertfLevel(2, type(id) == "number", "Attempted to access a non-number index: %s (%s)", tostring(id), type(id))
      return Addon:CheckTable(self, "actual", id)
    end
    
    function IndexedQueue:Wipe()
      wipe(Addon:CheckTable(self, "actual"))
      Addon:RemoveInTable(self, "links")
      Addon:RemoveInTable(self, "head")
      Addon:RemoveInTable(self, "tail")
      Addon:StoreInTable(self,  "count", 0)
      Addon:StoreInTable(self,  "next",  1)
      
      return self
    end
    
    function IndexedQueue:CanDefrag()
      return Addon:CheckTable(self, "next") ~= Addon:CheckTable(self, "count") + 1
    end
    
    function IndexedQueue:Defrag()
      if not IndexedQueue.CanDefrag(self) then return end
      
      local head, tail
      local nex = 1
      for i, v in IndexedQueue.iter(self) do
        if Addon:CheckTable(self, "head") == i then
          head = nex
        end
        if Addon:CheckTable(self, "tail") == i then
          tail = nex
        end
        if i ~= nex then
          Addon:StoreInTable(self,  "actual", nex, v)
          Addon:RemoveInTable(self, "actual", i)
        end
        nex = nex + 1
      end
      Addon:RemoveInTable(self, "links")
      Addon:StoreInTable(self,  "next", nex)
      Addon:StoreInTable(self,  "head", head)
      Addon:StoreInTable(self,  "tail", tail)
      
      return self
    end
    
    function IndexedQueue:GetCount()
      return Addon:CheckTable(self, "count")
    end
    
    function IndexedQueue:iter()
      local nex = Addon:CheckTable(self, "head")
      return function()
        local id = nex
        local v = rawget(Addon:CheckTable(self, "actual"), id)
        if v ~= nil then
          nex = GetNex(self, id)
          return id, v
        end
      end
    end
    
    function IndexedQueue:riter()
      local nex = Addon:CheckTable(self, "tail")
      return function()
        local id = nex
        local v = rawget(Addon:CheckTable(self, "actual"), id)
        if v ~= nil then
          nex = GetPre(self, id)
          return id, v
        end
      end
    end
    
    local meta = {
      __index = function(self, k)
        if IndexedQueue[k] then
          return IndexedQueue[k]
        else
          return IndexedQueue.Get(self, k)
        end
      end,
      __newindex = function(self, k, v)
        Addon:AssertfLevel(2, v == nil, "Attempted to insert an element by index: %s = %s", tostring(k), tostring(v))
        Addon:AssertfLevel(2, type(k) == "number", "Attempted to remove an element with an invalid key: %s (%s)", tostring(k), type(k))
        
        return IndexedQueue.Remove(self, k)
      end,
    }
    
    function IndexedQueue:Create(t)
      t = t or {}
      if getmetatable(t) == meta then return t end
      
      if Addon:CheckTable(t, "actual") == nil then
        t = {actual = t}
      end
      
      local actual = Addon:CheckTable(t, "actual")
      
      Addon:StoreDefault(t, "count", #actual)
      Addon:StoreDefault(t, "next",  #actual + 1)
      
      if next(actual) ~= nil then
        if not Addon:CheckTable(t, "head") then
          Addon:StoreInTable(t, "head", 1)
        end
        if not Addon:CheckTable(t, "tail") then
          Addon:StoreInTable(t, "tail", #actual)
        end
        Addon:StoreDefault(t, "head",  1)
        Addon:StoreDefault(t, "tail",  #actual)
      end
      
      return setmetatable(t, meta)
    end
  end
  
  function Addon.TimedTable(defaultDuration)
    local duration = defaultDuration
    local db       = {}
    local timers   = {}
    local count    = 0
    
    local funcs = {
      SetDuration = function(self, d)
        duration = d
        return self
      end,
      
      GetDuration = function(self)
        return duration
      end,
      
      Bump = function(self, k)
        if timers[k] then
          timers[k]:Cancel()
        end
        
        if db[k] ~= nil then
          timers[k] = C_Timer.NewTicker(duration, function() self[k] = nil end, 1)
        else
          timers[k] = nil
        end
        
        return self
      end,
      
      Set = function(self, k, v)
        local before = db[k] ~= nil and 1 or 0
        db[k] = v
        local after  = db[k] ~= nil and 1 or 0
        count = count + after - before
        
        self:Bump(k)
        return self
      end,
      
      Get = function(self, k)
        self:Bump(k)
        return db[k]
      end,
      
      GetCount = function(self)
        return count
      end,
      
      iter = function(self)
        return pairs(db)
      end,
      
      Wipe = function(self)
        for k, timer in pairs(timers) do
          timer:Cancel()
        end
        wipe(db)
        wipe(timers)
        count = 0
      end,
    }
    local meta = {
      __index = function(self, k)
        return funcs[k] or funcs.Get(self, k)
      end,
      __newindex = function(self, k, v)
        return self:Set(k, v)
      end,
    }
    
    return setmetatable({}, meta)
  end
  
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
  
  function Addon:Filter(t, ...)
    local new = {}
    
    for i, v in pairs(t) do
      local pass = true
      for j = 1, select("#", ...) do
        local filter = select(j, ...)
        if not filter(v, i, t) then
          pass = false
          break
        end
      end
      if pass then
        tinsert(new, v)
      end
    end
    
    local meta = getmetatable(self)
    if meta then
      setmetatable(new, meta)
    end
    
    return new
  end
  
  function Addon:Squish(t)
    local new = {}
    for k in pairs(t) do
      tinsert(new, k)
    end
    tblSort(new)
    for i, k in ipairs(new) do
      new[i] = t[k]
    end
    return new
  end
  
  function Addon:Shuffle(t)
    for i = #t, 2, -1 do
      local j = math.random(i)
      t[i], t[j] = t[j], t[i]
    end
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
        new[v] = true
      end
      if keepOrigVals and new[k] == nil then
        new[k] = v
      end
    end
    return new
  end
  
  function Addon:MakeBoolTable(t)
    return setmetatable(self:MakeLookupTable(t), {__index = function() return false end})
  end
  
  
  function Addon:MakeTable(t, ...)
    local parent = t
    
    for i, key in ipairs{...} do
      if not rawget(t, key) then
        rawset(t, key, {})
      end
      t = rawget(t, key)
    end
    return t
  end
  
  function Addon:StoreInTable(t, ...)
    local parent = t
    
    local keys = {...}
    local val = tblRemove(keys)
    local last = #keys
    for i, key in ipairs(keys) do
      if i == last then
        rawset(t, key, val)
      elseif not rawget(t, key) then
        rawset(t, key, {})
      end
      t = rawget(t, key)
    end
    return parent
  end
  
  function Addon:RemoveInTable(t, ...)
    local parent = t
    
    local keys = {...}
    local last = #keys
    for i, key in ipairs(keys) do
      if i == last then
        rawset(t, key, nil)
      elseif not rawget(t, key) then
        rawset(t, key, {})
      end
      t = rawget(t, key)
    end
    return parent
  end
  
  function Addon:StoreDefault(t, ...)
    local parent = t
    
    local keys = {...}
    local val = tblRemove(keys)
    local last = #keys
    for i, key in ipairs(keys) do
      if i == last then
        if rawget(t, key) == nil then
          rawset(t, key, val)
        end
      elseif not rawget(t, key) then
        rawset(t, key, {})
      end
      t = rawget(t, key)
    end
    return parent
  end
  
  function Addon:CheckTable(t, ...)
    local val = t
    for _, key in ipairs{...} do
      val = rawget(val or {}, key)
    end
    return val
  end
  
  function Addon:Concatenate(t1, t2)
    for i = 1, #t2 do
      t1[#t1+1] = t2[i]
    end
    for k, v in pairs(t2) do
      if type(k) ~= "number" then
        t1[k] = v
      end
    end
  end
  
  function Addon:Random(t)
    return t[random(#t)]
  end
  
  do
    cycleMemory = setmetatable({}, {__mode = "k"})
    function Addon:Cycle(t, offset)
      if cycleMemory[t] then
        cycleMemory[t] = next(t, cycleMemory[t]) or next(t)
      else
        cycleMemory[t] = offset or next(t)
      end
      return cycleMemory[t], t[cycleMemory[t]]
    end
  end
  
  do
    cycleMemory = setmetatable({}, {__mode = "k"})
    function Addon:ICycle(t, offset)
      cycleMemory[t] = ((cycleMemory[t] or (offset - 1) or 0) % #t) + 1
      return cycleMemory[t], t[cycleMemory[t]]
    end
  end
  
  local function SwitchHelper(result, val)
    if type(result) == "function" then
      return result(val)
    else
      return result
    end
  end
  function Addon:Switch(val, t, fallback)
    fallback = fallback or nop
    if val == nil then
      return SwitchHelper(fallback, val)
    else
      return SwitchHelper(setmetatable(t, {__index = function() return fallback end})[val], val)
    end
  end
  
  
  function Addon:ShortCircuit(expression, trueVal, falseVal)
    if expression then
      return trueVal
    else
      return falseVal
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
  local onOptionSetHandlers = {}
  function Addon:RegisterOptionSetHandler(func)
    tinsert(onOptionSetHandlers, func)
    return #onOptionSetHandlers
  end
  function Addon:UnregisterOptionSetHandler(id)
    onOptionSetHandlers[id] = nil
  end
  
  local function OnOptionSet(self, val, ...)
    if not self:GetDB() then return end -- db hasn't loaded yet
    self:DebugfIfOutput("optionSet", "Setting %s: %s", strjoin(" > ", ...), tostring(val))
    for id, func in next, onOptionSetHandlers, nil do
      if type(func) == "function" then
        func(self, val, ...)
      else
        self[func](self, val, ...)
      end
    end
  end
  
  local dbTables = {
    {"dbDefault", "Default", true},
    {"db", ""},
  }
  local dbTypes = {
    {"profile", ""},
    {"global", "Global"},
  }
  
  local defaultKey, defaultName
  
  for _, dbType in ipairs(dbTables) do
    local dbKey, dbName, isDefault = unpack(dbType, 1, 3)
    if isDefault then
      defaultKey  = dbKey
      defaultName = dbName
    end
    
    local IsDBLoaded = format("Is%sDBLoaded", dbName)
    local GetDB      = format("Get%sDB",      dbName)
    
    Addon[IsDBLoaded] = function(self)
    return self[dbKey] ~= nil
    end
    Addon[GetDB] = function(self)
      return self[dbKey]
    end
    
    for _, dbSection in ipairs(dbTypes) do
      local typeKey, typeName = unpack(dbSection, 1, 2)
      
      local GetOption             = format("Get%s%sOption",      dbName,      typeName)
      local GetOptionQuiet        = format("Get%s%sOptionQuiet", dbName,      typeName)
      local GetDefaultOption      = format("Get%s%sOption",      defaultName, typeName)
      local GetDefaultOptionQuiet = format("Get%s%sOptionQuiet", defaultName, typeName)
      
      Addon[GetOptionQuiet] = function(self, ...)
        assert(self[dbKey], format("Attempted to access database before initialization: %s", Addon:TableConcat({dbKey, typeKey, ...}, " > ")))
        local val = self[dbKey][typeKey]
        for _, key in ipairs{...} do
          assert(type(val) == "table", format("Bad database access: %s", Addon:TableConcat({dbKey, typeKey, ...}, " > ")))
          val = val[key]
        end
        return val
      end
      
      Addon[GetOption] = function(self, ...)
        local val = Addon[GetOptionQuiet](self, ...)
        if type(val) == "table" then
          Addon:Warnf("Database request returned a table: %s", Addon:TableConcat({dbKey, typeKey, ...}, " > "))
        end
        if val == nil then
          Addon:Warnf("Database request found empty value: %s", Addon:TableConcat({dbKey, typeKey, ...}, " > "))
        end
        return val
      end
      
      if not isDefault then
        local SetOption               = format("Set%s%sOption",               dbName, typeName)
        local SetOptionQuiet          = format("Set%s%sOptionQuiet",          dbName, typeName)
        local SetOptionConfig         = format("Set%s%sOptionConfig",         dbName, typeName)
        local SetOptionConfigQuiet    = format("Set%s%sOptionConfigQuiet",    dbName, typeName)
        local ToggleOption            = format("Toggle%s%sOption",            dbName, typeName)
        local ToggleOptionQuiet       = format("Toggle%s%sOptionQuiet",       dbName, typeName)
        local ToggleOptionConfig      = format("Toggle%s%sOptionConfig",      dbName, typeName)
        local ToggleOptionConfigQuiet = format("Toggle%s%sOptionConfigQuiet", dbName, typeName)
        local ResetOption             = format("Reset%s%sOption",             dbName, typeName)
        local ResetOptionQuiet        = format("Reset%s%sOptionQuiet",        dbName, typeName)
        local ResetOptionConfig       = format("Reset%s%sOptionConfig",       dbName, typeName)
        local ResetOptionConfigQuiet  = format("Reset%s%sOptionConfigQuiet",  dbName, typeName)
        
        local function Set(self, quiet, config, val, ...)
          assert(self[dbKey], format("Attempted to access database before initialization: %s = %s", Addon:TableConcat({dbKey, typeKey, ...}, " > "), tostring(val)))
          local keys = {...}
          local lastKey = tblRemove(keys, #keys)
          local tbl = self[dbKey][typeKey]
          for _, key in ipairs(keys) do
            assert(type(tbl[key]) == "table", format("Bad database access: %s = %s", Addon:TableConcat({dbKey, typeKey, ...}, " > "), tostring(val)))
            tbl = tbl[key]
          end
          local lastVal = tbl[lastKey]
          if not quiet and type(lastVal) == "table" then
            Addon:Warnf("Database access overwriting a table: %s", Addon:TableConcat({dbKey, typeKey, ...}, " > "))
          end
          tbl[lastKey] = val
          OnOptionSet(Addon, val, dbKey, typeKey, ...)
          if not config then
            Addon:NotifyChange()
          end
          return lastVal ~= val
        end
        
        Addon[SetOption] = function(self, val, ...)
          return Set(self, false, false, val, ...)
        end
        Addon[SetOptionConfig] = function(self, val, ...)
          return Set(self, false, true, val, ...)
        end
        Addon[SetOptionQuiet] = function(self, val, ...)
          return Set(self, true, false, val, ...)
        end
        Addon[SetOptionConfigQuiet] = function(self, val, ...)
          return Set(self, true, true, val, ...)
        end
        
        Addon[ToggleOption] = function(self, ...)
          return self[SetOption](self, not self[GetOption](self, ...), ...)
        end
        Addon[ToggleOptionConfig] = function(self, ...)
          return self[SetOptionConfig](self, not self[GetOption](self, ...), ...)
        end
        Addon[ToggleOptionQuiet] = function(self, ...)
          return self[SetOptionQuiet](self, not self[GetOptionQuiet](self, ...), ...)
        end
        Addon[ToggleOptionConfigQuiet] = function(self, ...)
          return self[SetOptionConfigQuiet](self, not self[GetOptionQuiet](self, ...), ...)
        end
        
        Addon[ResetOption] = function(self, ...)
          return self[SetOption](self, Addon.Copy(self, self[GetDefaultOption](self, ...)), ...)
        end
        Addon[ResetOptionConfig] = function(self, ...)
          return self[SetOptionConfig](self, Addon.Copy(self, self[GetDefaultOption](self, ...)), ...)
        end
        Addon[ResetOptionQuiet] = function(self, ...)
          return self[SetOptionQuiet](self, Addon.Copy(self, self[GetDefaultOptionQuiet](self, ...)), ...)
        end
        Addon[ResetOptionConfigQuiet] = function(self, ...)
          return self[SetOptionConfigQuiet](self, Addon.Copy(self, self[GetDefaultOptionQuiet](self, ...)), ...)
        end
      end
      
    end
  end
end





--  ███████╗██╗   ██╗███████╗███╗   ██╗████████╗███████╗
--  ██╔════╝██║   ██║██╔════╝████╗  ██║╚══██╔══╝██╔════╝
--  █████╗  ██║   ██║█████╗  ██╔██╗ ██║   ██║   ███████╗
--  ██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║╚██╗██║   ██║   ╚════██║
--  ███████╗ ╚████╔╝ ███████╗██║ ╚████║   ██║   ███████║
--  ╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝

do
  local function Call(func, ...)
    local args = {...}
    local nArgs = select("#", ...)
    if type(func) == "function" then
      Addon:xpcall(function() func(unpack(args, 1, nArgs)) end)
    else
      Addon:xpcall(function() Addon[func](unpack(args, 1, nArgs)) end)
    end
  end
  
  local nextRegistrationID = 1
  local registrations      = {}
  local onEventCallbacks   = {}
  local function OnEvent(event, ...)
    local t = onEventCallbacks[event]
    Addon:Assertf(t, "Event %s is registered, but no callbacks were found", event)
    for i, func in t:iter() do
      Call(func, Addon, event, ...)
    end
  end
  
  function Addon:RegisterEventCallback(...)
    local events = {...}
    local callback = tblRemove(events, #events)
    assert(#events > 0 and type(callback) == "function", "Expected events and function")
    
    local registration = {}
    local id = nextRegistrationID
    nextRegistrationID = nextRegistrationID + 1
    registrations[id] = registration
    
    func = function(...) if callback(...) then self:UnregisterEventCallback(id) end end
    
    for _, event in ipairs(events) do
      local callbacks = onEventCallbacks[event] or Addon.IndexedQueue()
      local index = callbacks:Add(func)
      if callbacks:GetCount() == 1 then
        onEventCallbacks[event] = callbacks
        self:RegisterEvent(event, OnEvent)
      end
      registration[#registration+1] = {event, index}
    end
    return id
  end
  function Addon:RegisterOneTimeEventCallback(...)
    local args = {...}
    local nArgs = select("#", ...)
    local callback = args[#args]
    args[#args] = function(...) callback(...) return true end
    
    return self:RegisterEventCallback(unpack(args, 1, nArgs))
  end
  
  function Addon:UnregisterEventCallback(id)
    local registration = registrations[id]
    for _, eventPath in ipairs(registration) do
      local event, index = unpack(eventPath)
      local callbacks = onEventCallbacks[event] or Addon.IndexedQueue()
      self:Assertf(callbacks:Remove(index), "Attempted to unregister callback %s from event %s, but it was not found", index, event)
      if callbacks:GetCount() == 0 then
        onEventCallbacks[event] = nil
        self:UnregisterEvent(event)
      end
    end
    registrations[id] = nil
  end
  
  
  do
    local events = {
      Initialize       = Addon.IndexedQueue(),
      Enable           = Addon.IndexedQueue(),
      OptionsOpenPre   = Addon.IndexedQueue(),
      OptionsOpenPost  = Addon.IndexedQueue(),
      -- OptionsClosePre  = Addon.IndexedQueue(),
      OptionsClosePost = Addon.IndexedQueue(),
    }
    
    for event, callbacks in pairs(events) do
      Addon["Run" .. event .. "Callbacks"] = function(self)
        for i, func in callbacks:iter() do
          Call(func, Addon)
        end
      end
      Addon["Register" .. event .. "Callback"] = function(self, func)
        return callbacks:Add(func)
      end
      Addon["Unregister" .. event .. "Callbacks"] = function(self)
        self:Assert(callbacks:GetCount() > 0, "Attempted to unregister " .. event .. " callbacks, but none were found")
        callbacks:Wipe()
      end
      Addon["Unregister" .. event .. "Callback"] = function(self, id)
        self:Assertf(callbacks:Remove(id), "Attempted to unregister " .. event .. " callback %s, but it was not found", id)
      end
    end
  end
  
  
  Addon:RegisterOptionsOpenPreCallback(function()
    Addon:DebugIfOutput("optionsOpenedPre", "Options opened (Pre)")
  end)
  Addon:RegisterOptionsOpenPostCallback(function()
    Addon:DebugIfOutput("optionsOpenedPost", "Options opened (Post)")
  end)
  Addon:RegisterOptionsClosePostCallback(function()
    Addon:DebugIfOutput("optionsClosedPost", "Options closed (Post)")
  end)
  
  
  function Addon:RegisterCVarCallback(cvar, func)
    return self:RegisterEventCallback("CVAR_UPDATE", function(self, event, ...)
      if cvar == ... then
        self:DebugfIfOutput("cvarSet", "CVar set: %s = %s", cvar, tostring(C_CVar.GetCVar(cvar)))
        func(self, event, ...)
      end
    end)
  end
  
  
  onAddonLoadCallbacks = {}
  function Addon:OnAddonLoad(addonName, func)
    local loaded, finished = IsAddOnLoaded(addonName)
    if finished then
      Call(func, self)
    else
      self:RegisterEventCallback("ADDON_LOADED", function(self, event, addon)
        if addon == addonName then
          Call(func, self)
          return true
        end
      end)
    end
  end
  
  function Addon:WhenOutOfCombat(func)
    if not InCombatLockdown() then
      Call(func, self)
    else
      self:RegisterOneTimeEventCallback("PLAYER_REGEN_ENABLED", function() Call(func, self) end)
    end
  end
end





--  ██████╗ ██╗      █████╗ ██╗   ██╗███████╗██████╗     ██████╗  █████╗ ████████╗ █████╗ 
--  ██╔══██╗██║     ██╔══██╗╚██╗ ██╔╝██╔════╝██╔══██╗    ██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗
--  ██████╔╝██║     ███████║ ╚████╔╝ █████╗  ██████╔╝    ██║  ██║███████║   ██║   ███████║
--  ██╔═══╝ ██║     ██╔══██║  ╚██╔╝  ██╔══╝  ██╔══██╗    ██║  ██║██╔══██║   ██║   ██╔══██║
--  ██║     ███████╗██║  ██║   ██║   ███████╗██║  ██║    ██████╔╝██║  ██║   ██║   ██║  ██║
--  ╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝

do
  local playerLocation = PlayerLocation:CreateFromUnit"player"
  
  
  Addon.MY_GUID = UnitGUID"player"
  
  
  Addon.MY_NAME = UnitNameUnmodified"player"
  
  
  Addon.MY_CLASS_LOCALNAME, MY_CLASS_FILENAME, Addon.MY_CLASS = UnitClass"player"
  
  
  Addon.MY_RACE_LOCALNAME, Addon.MY_RACE_FILENAME, Addon.MY_RACE = UnitRace"player"
  
  
  Addon.MY_FACTION = UnitFactionGroup"player"
  
  
  Addon.MAX_LEVEL = MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()] or 200
  Addon.MY_LEVEL = UnitLevel"player"
  Addon:RegisterEventCallback("PLAYER_LEVEL_UP", function(self, event, level) self.MY_LEVEL = UnitLevel"player" end)
  
  
  Addon.MY_SEX = UnitSex"player" - 2
  Addon:RegisterEnableCallback(function(self)
    self.MY_SEX = C_PlayerInfo.GetSex(PlayerLocation:CreateFromUnit"player")
    do
      for name, id in pairs(Enum.UnitSex) do
        if id == self.MY_SEX then
          self.MY_SEX_LOCALNAME = name
          break
        end
      end
    end
  end)
end




--   ██████╗ ██████╗ ████████╗██╗ ██████╗ ███╗   ██╗███████╗
--  ██╔═══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
--  ██║   ██║██████╔╝   ██║   ██║██║   ██║██╔██╗ ██║███████╗
--  ██║   ██║██╔═══╝    ██║   ██║██║   ██║██║╚██╗██║╚════██║
--  ╚██████╔╝██║        ██║   ██║╚██████╔╝██║ ╚████║███████║
--   ╚═════╝ ╚═╝        ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

do
  do
    Addon.GUI = {}
    local GUI = Addon.GUI
    
    local defaultInc   = 1000
    local defaultOrder = 1000
    local order        = defaultOrder
    
    local dbType = ""
    local GetFunction      = function(keys) local funcName = format("Get%sOption",         dbType) return function(info)          Addon:HideConfirmPopup() return Addon[funcName](Addon, unpack(keys))                                          end end
    local SetFunction      = function(keys) local funcName = format("Set%sOptionConfig",   dbType) return function(info, val)                                     Addon[funcName](Addon, val, unpack(keys))                                     end end
    local ResetFunction    = function(keys) local funcName = format("Reset%sOptionConfig", dbType) return function(info, val)                                     Addon[funcName](Addon, unpack(keys))                                          end end
    local GetColorFunction = function(keys) local funcName = format("Get%sOption",         dbType) return function(info)          Addon:HideConfirmPopup() return Addon:ConvertColorToBlizzard(Addon[funcName](Addon, unpack(keys)))            end end
    local SetColorFunction = function(keys) local funcName = format("Set%sOption",         dbType) return function(info, r, g, b)                                 Addon[funcName](Addon, Addon:ConvertColorFromBlizzard(r, g, b), unpack(keys)) end end
    
    
    local MultiGetFunction = function(keys)
      local funcName = format("Get%sOption", dbType)
      return function(info, key)
        local path = Addon:Copy(keys)
        path[#path+1] = key
        return Addon[funcName](Addon, unpack(path))
      end
    end
    
    local MultiSetFunction = function(keys)
      local funcName = format("Set%sOptionConfig", dbType)
      return function(info, key, val)
        local path = Addon:Copy(keys)
        path[#path+1] = key
        Addon[funcName](Addon, val, unpack(path))
      end
    end
    -- options window needs to redraw if color changes
    
    function GUI:SetDBType(typ)
      dbType = typ or ""
    end
    function GUI:ResetDBType()
      self:SetDBType()
    end
    
    function GUI:GetOrder()
      return order
    end
    function GUI:SetOrder(newOrder)
      order = newOrder
      return self
    end
    function GUI:ResetOrder()
      order = defaultOrder
      return self
    end
    function GUI:Order(inc)
      self:SetOrder(self:GetOrder() + (inc or defaultInc))
      return self:GetOrder()
    end
    
    function GUI:CreateEntry(opts, keys, name, desc, widgetType, disabled, order)
      order = order or self:Order()
      if type(keys) ~= "table" then keys = {keys} end
      local key = widgetType .. "_" .. (Addon:TableConcat(keys, ".") or "") .. "_" .. order
      opts.args[key] = {name = name, desc = desc, type = widgetType, order = order, disabled = disabled}
      opts.args[key].set = SetFunction(keys)
      opts.args[key].get = GetFunction(keys)
      return opts.args[key]
    end
    
    function GUI:CreateHeader(opts, name)
      return self:CreateEntry(opts, {"header"}, name, nil, "header")
    end
    
    function GUI:CreateDescription(opts, desc, fontSize)
      local option = self:CreateEntry(opts, {"description"}, desc, nil, "description")
      option.fontSize = fontSize or "large"
      return option
    end
    function GUI:CreateDivider(opts, count, fontSize)
      for i = 1, count or 1 do
        self:CreateDescription(opts, " ", fontSize or "small")
      end
    end
    function GUI:CreateNewline(opts)
      return self:CreateDescription(opts, " ", fontSize or "small")
    end
    
    function GUI:CreateToggle(opts, keys, name, desc, disabled)
      return self:CreateEntry(opts, keys, name, desc, "toggle", disabled)
    end
    
    function GUI:CreateReverseToggle(opts, keys, name, desc, disabled)
      local option = self:CreateEntry(opts, keys, name, desc, "toggle", disabled)
      local set, get = option.set, option.get
      option.get = function(info)      return not get()          end
      option.set = function(info, val)        set(info, not val) end
      return option
    end
    
    function GUI:CreateSelect(opts, keys, name, desc, values, sorting, disabled)
      local option = self:CreateEntry(opts, keys, name, desc, "select", disabled)
      option.values  = values
      option.sorting = sorting
      return option
    end
    function GUI:CreateDropdown(...)
      local option = self:CreateSelect(...)
      option.style = "dropdown"
      return option
    end
    function GUI:CreateRadio(...)
      local option = self:CreateSelect(...)
      option.style = "radio"
      return option
    end
    
    function GUI:CreateMultiSelect(opts, keys, name, desc, values, disabled)
      local option = self:CreateEntry(opts, keys, name, desc, "multiselect", disabled)
      option.values = values
      option.get = MultiGetFunction(keys)
      option.set = MultiSetFunction(keys)
      return option
    end
    function GUI:CreateMultiDropdown(...)
      local option = self:CreateMultiSelect(...)
      option.dialogControl = "Dropdown"
      return option
    end
    
    function GUI:CreateRange(opts, keys, name, desc, min, max, step, disabled)
      local option = self:CreateEntry(opts, keys, name, desc, "range", disabled)
      option.min   = min
      option.max   = max
      option.step  = step
      return option
    end
    
    function GUI:CreateInput(opts, keys, name, desc, multiline, disabled)
      local option     = self:CreateEntry(opts, keys, name, desc, "input", disabled)
      option.multiline = multiline
      return option
    end
    
    function GUI:CreateColor(opts, keys, name, desc, disabled)
      local option = self:CreateEntry(opts, keys, name, desc, "color", disabled)
      option.get   = GetColorFunction(keys)
      option.set   = SetColorFunction(keys)
      return option
    end
    
    function GUI:CreateExecute(opts, key, name, desc, func, disabled)
      local option = self:CreateEntry(opts, key, name, desc, "execute", disabled)
      option.func  = func
      return option
    end
    function GUI:CreateReset(opts, keys, func, disabled)
      local option = self:CreateEntry(opts, {"reset", unpack(keys)}, Addon.L["Reset"], nil, "execute", disabled)
      option.func  = func or ResetFunction(keys)
      option.width = 0.6
      return option
    end
    
    function GUI:CreateGroup(opts, key, name, desc, groupType, disabled)
      local order = self:Order()
      key = tostring(key or order)
      opts.args[key] = {name = name, desc = desc, type = "group", childGroups = groupType or "tab", args = {}, order = order, disabled = disabled}
      return opts.args[key]
    end
    function GUI:CreateGroupBox(opts, name)
      local option = self:CreateGroup(opts, nil, name or " ")
      option.inline = true
      return option
    end
    
    function GUI:CreateOpts(name, groupType, disabled)
      return {name = name, type = "group", childGroups = groupType or "tab", args = {}, order = self:Order()}
    end
  end
  
  
  
  
  function Addon:HideConfirmPopup()
    if not self:IsConfigOpen() then return end
    self:xpcall(function()
      if self.AceConfigDialog then
        local frame = self.AceConfigDialog.popup
        if frame then
          frame:Hide()
        end
      end
    end)
  end
  
  function Addon:NotifyChange()
    if not self:IsConfigOpen() then return end
    self:HideConfirmPopup()
    self:xpcall(function()
      if self.AceConfigRegistry then
        self.AceConfigRegistry:NotifyChange(ADDON_NAME)
      end
    end)
  end
  
  
  
  local blizzardCategory
  function Addon:OpenBlizzardConfig()
    Settings.OpenToCategory(blizzardCategory)
  end
  function Addon:CloseBlizzardConfig()
    SettingsPanel:Close(true)
  end
  function Addon:ToggleBlizzardConfig(...)
    if SettingsPanel:IsShown() then
      self:CloseBlizzardConfig(...)
    else
      self:OpenBlizzardConfig(...)
    end
  end
  
  local function HookCloseConfig()
    local hookedKey = ADDON_NAME .. "_OPEN"
    
    local frame = Addon:GetConfigWindow()
    Addon:ThrowAssert(frame, "Can't find frame to hook options menu close")
    
    local alreadyHooked = frame[hookedKey] ~= nil
    frame[hookedKey] = true
    
    if alreadyHooked then return end
    
    frame:HookScript('OnHide', function(self)
      local currentFrame = Addon:GetConfigWindow()
      if not currentFrame or self ~= currentFrame then
        if self[hookedKey] then
          Addon:RunOptionsClosePostCallbacks()
          self[hookedKey] = false
        end
      end
    end)
    
  end
  
  function Addon:GetConfigWindow()
    return self:CheckTable(self, "AceConfigDialog", "OpenFrames", ADDON_NAME, "frame")
  end
  function Addon:IsConfigOpen(...)
    return self:GetConfigWindow() and true or false
  end
  function Addon:OpenConfig(...)
    self:RunOptionsOpenPreCallbacks()
    self.AceConfigDialog:Open(ADDON_NAME)
    if select("#", ...) > 0 then
      self.AceConfigDialog:SelectGroup(ADDON_NAME, ...)
    end
    HookCloseConfig()
    self:RunOptionsOpenPostCallbacks()
  end
  function Addon:CloseConfig()
    -- self:RunOptionsClosePreCallbacks()
    self.AceConfigDialog:Close(ADDON_NAME)
    -- self:RunOptionsClosePostCallbacks()
  end
  function Addon:ToggleConfig(...)
    if self:IsConfigOpen(...) then
      self:CloseConfig()
    else
      self:OpenConfig(...)
    end
  end
  
  function Addon:RefreshDebugOptions()
    if self:CheckTable(self.AceConfigDialog:GetStatusTable(ADDON_NAME), "groups", "selected") == "Debug" then
      self.AceConfigRegistry:NotifyChange(ADDON_NAME)
    end
  end
  
  function Addon:ResetProfile(category)
    self:GetDB():ResetProfile()
    self.AceConfigRegistry:NotifyChange(category)
  end
  
  function Addon:CreateBlizzardOptionsCategory(options)
    local blizzardOptions = ADDON_NAME .. ".Blizzard"
    self.AceConfig:RegisterOptionsTable(blizzardOptions, options)
    local Panel, id = self.AceConfigDialog:AddToBlizOptions(blizzardOptions, ADDON_NAME)
    blizzardCategory = id
    Panel.default = function() self:ResetProfile(blizzardOptions) end
    return Panel
  end
  
  
  do
    local staticPopups = {}
    Addon.staticPopups = staticPopups
    
    local function MakeName(name)
      return ADDON_NAME .. "_" .. tostring(name)
    end
    
    
    local function SetPopupText(name, text)
      Addon:Assertf(Addon.staticPopups[name], "StaticPopup with name '%s' doesn't exist", name)
      
      Addon.staticPopups[name].text = text
    end
    
    local function GetDialogFrames(name)
      local key = MakeName(name)
      Addon:Assertf(StaticPopupDialogs[key], "StaticPopup with name '%s' doesn't exist", key)
      Addon:Assertf(staticPopups[name], "StaticPopup with name '%s' isn't owned by %s", key, ADDON_NAME)
      
      local frameName, data = StaticPopup_Visible(key)
      if not frameName then return end
      local textFrameName = frameName .. "Text"
      local frame     = _G[frameName]
      local textFrame = _G[textFrameName]
      Addon:Assertf(frame and textFrameName, "Couldn't get StaticPopup frames '%s' and '%s'", frameName, textFrameName)
      
      return frame, textFrame
    end
    
    function Addon:GetPopupData(name)
      local key = MakeName(name)
      self:Assertf(StaticPopupDialogs[key], "StaticPopup with name '%s' doesn't exist", key)
      self:Assertf(staticPopups[name], "StaticPopup with name '%s' isn't owned by %s", key, ADDON_NAME)
      
      local frameName, data = StaticPopup_Visible(key)
      if not data then return end
      
      return data.data
    end
    
    function Addon:InitPopup(name, popupConfig)
      local key = MakeName(name)
      self:Assertf(not StaticPopupDialogs[key], "StaticPopup with name '%s' already exists", key)
      
      StaticPopupDialogs[key] = popupConfig
      self.staticPopups[name] = popupConfig
      
      popupConfig.patternText = popupConfig.text
      SetPopupText(name, "")
    end
    
    function Addon:ShowPopup(name, data, ...)
      local key = MakeName(name)
      self:Assertf(StaticPopupDialogs[key], "StaticPopup with name '%s' doesn't exist", key)
      self:Assertf(staticPopups[name], "StaticPopup with name '%s' isn't owned by %s", key, ADDON_NAME)
      
      SetPopupText(name, "")
      
      StaticPopup_Show(key, nil, nil, data)
      self:EditPopupText(name, ...)
    end
    
    function Addon:HidePopup(name)
      local key = MakeName(name)
      self:Assertf(StaticPopupDialogs[key], "StaticPopup with name '%s' doesn't exist", key)
      self:Assertf(staticPopups[name], "StaticPopup with name '%s' isn't owned by %s", key, ADDON_NAME)
      
      StaticPopup_Hide(key)
    end
    
    function Addon:IsPopupShown(name)
      return self:GetPopupData(name) and true or false
    end
    
    function Addon:EditPopupText(name, ...)
      local key = MakeName(name)
      self:Assertf(StaticPopupDialogs[key], "StaticPopup with name '%s' doesn't exist", key)
      self:Assertf(staticPopups[name], "StaticPopup with name '%s' isn't owned by %s", key, ADDON_NAME)
      
      local frame, textFrame = GetDialogFrames(name)
      self:Assertf(textFrame, "StaticPopup text frame with name '%s' doesn't exist", textFrameName)
      
      textFrame:SetFormattedText(staticPopups[name].patternText, ...)
      SetPopupText(name, textFrame:GetText())
      StaticPopup_Resize(frame, key)
    end
  end
end




--  ████████╗██╗  ██╗██████╗ ███████╗ █████╗ ██████╗ ██╗███╗   ██╗ ██████╗ 
--  ╚══██╔══╝██║  ██║██╔══██╗██╔════╝██╔══██╗██╔══██╗██║████╗  ██║██╔════╝ 
--     ██║   ███████║██████╔╝█████╗  ███████║██║  ██║██║██╔██╗ ██║██║  ███╗
--     ██║   ██╔══██║██╔══██╗██╔══╝  ██╔══██║██║  ██║██║██║╚██╗██║██║   ██║
--     ██║   ██║  ██║██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║╚██████╔╝
--     ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ 
do
  local threads = {}
  Addon.threads = threads
  
  local meta = {
    __index = {
      Start = function(self) self.frame:Show() end,
      Stop  = function(self) self.frame:Hide() end,
      Run   = function(self) self.runner(self) end,
    },
  }
  
  local function MakeNewThread(name)
    local thread = setmetatable({}, meta)
    
    local data = {}
    local runner = function(self)
      if coroutine.status(thread.co) ~= "dead" then
        local success, err = coroutine.resume(thread.co, Addon, data)
        if not success then
          -- thread.error = true
          Addon:Throw(err)
        end
      end
      if coroutine.status(thread.co) == "dead" then
        thread:Stop()
      end
    end
    local frame = CreateFrame"Frame"
    frame:SetScript("OnUpdate", runner)
    
    
    thread.data   = data
    thread.runner = runner
    thread.frame  = frame
    
    threads[name] = thread
    return thread
  end
  
  
  function Addon:StartNewThread(name, func, nextFrame)
    self:Assertf(name,                     "Thread needs a name")
    self:Assertf(type(func) == "function", "Thread needs a function")
    
    local thread
    if threads[name] then
      thread = self:StopThread(name)
    else
      thread = MakeNewThread(name)
    end
    
    -- thread.error = nil
    thread.co = coroutine.create(func)
    thread:Start()
    
    if not nextFrame then
      thread:Run()
    end
  end
  
  function Addon:DoesThreadExist(name)
    return threads[name] and true or false
  end
  
  function Addon:StartThread(name)
    local thread = threads[name]
    if thread and not self:IsThreadDead(name) then
      thread:Start()
    end
    return thread
  end
  
  function Addon:StopThread(name)
    local thread = threads[name]
    if thread then
      thread:Stop()
    end
    return thread
  end
  
  function Addon:RunThread(name)
    local thread = threads[name]
    if thread then
      thread:Run()
    end
    return thread
  end
  
  function Addon:IsThreadDead(name)
    local thread = threads[name]
    return not thread or coroutine.status(thread.co) == "dead"
  end
  
  function Addon:GetThreadData(name)
    local thread = threads[name]
    return thread and thread.data or nil
  end
end




--   ██████╗██╗  ██╗ █████╗ ████████╗
--  ██╔════╝██║  ██║██╔══██╗╚══██╔══╝
--  ██║     ███████║███████║   ██║   
--  ██║     ██╔══██║██╔══██║   ██║   
--  ╚██████╗██║  ██║██║  ██║   ██║   
--   ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   

do
  Addon.chatArgs = {}
  
  function Addon:RegisterChatArg(arg, func)
    Addon.chatArgs[arg] = func
  end
  
  function Addon:RegisterChatArgAliases(arg, func)
    for i = #arg, 1, -1 do
      local alias = strSub(arg, 1, i)
      if not self.chatArgs[alias] then
        self:RegisterChatArg(alias, func)
      end
    end
    Addon.chatArgs[arg] = func
  end
  
  function Addon:OnChatCommand(input)
    local args = {self:GetArgs(input, 1)}
    
    local func = args[1] and self.chatArgs[args[1]] or nil
    if func then
      func(self, unpack(args))
    else
      self:OpenConfig()
    end
  end
  
  function Addon:InitChatCommands(...)
    for i, chatCommand in ipairs{...} do
      if i == 1 then
        self:MakeAddonOptions(chatCommand)
        self:MakeBlizzardOptions(chatCommand)
      end
      self:RegisterChatCommand(chatCommand, "OnChatCommand", true)
    end
    
    local function PrintVersion() self:Printf("Version: %s", tostring(self.version)) end
    self:RegisterChatArgAliases("version", PrintVersion)
  end
end




--   ██████╗ ██████╗ ██╗      ██████╗ ██████╗ ███████╗
--  ██╔════╝██╔═══██╗██║     ██╔═══██╗██╔══██╗██╔════╝
--  ██║     ██║   ██║██║     ██║   ██║██████╔╝███████╗
--  ██║     ██║   ██║██║     ██║   ██║██╔══██╗╚════██║
--  ╚██████╗╚██████╔╝███████╗╚██████╔╝██║  ██║███████║
--   ╚═════╝ ╚═════╝ ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝

do
  function Addon:GetHexFromColor(r, g, b)
    return format("%02x%02x%02x", r, g, b)
  end
  function Addon:ConvertColorFromBlizzard(r, g, b)
    return self:GetHexFromColor(self:Round(r*255, 1), self:Round(g*255, 1), self:Round(b*255, 1))
  end
  function Addon:GetTextColorAsHex(frame)
    return self:ConvertColorFromBlizzard(frame:GetTextColor())
  end
  
  function Addon:ConvertHexToRGB(hex)
    return tonumber(strSub(hex, 1, 2), 16), tonumber(strSub(hex, 3, 4), 16), tonumber(strSub(hex, 5, 6), 16), 1
  end
  function Addon:ConvertColorToBlizzard(hex)
    return tonumber(strSub(hex, 1, 2), 16) / 255, tonumber(strSub(hex, 3, 4), 16) / 255, tonumber(strSub(hex, 5, 6), 16) / 255, 1
  end
  function Addon:SetTextColorFromHex(frame, hex)
    frame:SetTextColor(self:ConvertColorToBlizzard(hex))
  end
  
  function Addon:TrimAlpha(hex)
    return strMatch(hex, "%x?%x?(%x%x%x%x%x%x)") or hex
  end
  function Addon:MakeColorCode(hex, text)
    return format("|cff%s%s%s", hex, text or "", text and "|r" or "")
  end
  
  function Addon:StripColorCode(text, hex)
    local pattern = hex and ("|c%x%x" .. hex) or "|c%x%x%x%x%x%x%x%x"
    return self:ChainGsub(text, {pattern, "|r", ""})
  end
end





--  ███╗   ██╗██╗   ██╗███╗   ███╗██████╗ ███████╗██████╗ ███████╗
--  ████╗  ██║██║   ██║████╗ ████║██╔══██╗██╔════╝██╔══██╗██╔════╝
--  ██╔██╗ ██║██║   ██║██╔████╔██║██████╔╝█████╗  ██████╔╝███████╗
--  ██║╚██╗██║██║   ██║██║╚██╔╝██║██╔══██╗██╔══╝  ██╔══██╗╚════██║
--  ██║ ╚████║╚██████╔╝██║ ╚═╝ ██║██████╔╝███████╗██║  ██║███████║
--  ╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝

do
  function Addon:ToNumber(text)
    if type(text) == "number" then
      return text
    end
    if type(text) ~= "string" then return nil end
    
    -- strip percentage
    text = strGsub(text, "%%*$", "")
    
    -- strip thousands separators, convert decimal separator into period
    if self.L["."] == "." then
      text = strGsub(text, "(%d)" .. self.L[","] .. "(%d%d%d)", "%1%2")
    else
      text = self:ChainGsub(text, {"(%d)%" .. self.L[","] .. "(%d%d%d)", "%1%2"}, {"%" .. self.L["."], "."})
    end
    
    return tonumber(text)
  end
  
  function Addon:ToFormattedNumber(text, numDecimalPlaces, decimalChar, thousandsChar, fourDigitException, separateDecimals)
    local decimal   = decimalChar   or self.L["."]
    local separator = thousandsChar or self.L[","]
    
    local number = self:ToNumber(text)
    if numDecimalPlaces then
      number = self:Round(number, 1 / 10^numDecimalPlaces)
    end
    
    local text  = tostring(abs(number))
    local left  = strMatch(text,  "^%-?%d+")
    local right = strMatch(text, "%.(%d*)$") or ""
    
    if numDecimalPlaces then
      while #right < numDecimalPlaces do
        right = right .. "0"
      end
    end
    
    if decimal ~= "" and #left > 3 and not (fourDigitException and #left <= 4) then
      local result = {}
      
      for i = #left, 0, -3 do
        result[mathFloor(i/3)+1] = strSub(left, mathMax(i-2, 0), i)
      end
      left = tblConcat(result, separator)
    end
    
    if separator ~= "" and #right > 3 and not (fourDigitException and #right <= 4) and separateDecimals then
      local result = {}
      
      for i = 1, #right, 3 do
        result[mathFloor(i/3)+1] = strSub(right, i, mathMin(i+2, #right))
      end
      right = tblConcat(result, separator)
    end
    
    text = left
    if #right > 0 then
      text = text .. decimal .. right
    end
    
    if number < 0 then
      text = "-" .. text
    end
    
    return text
  end
  
  
  do
    local function CompareMin(a, b) return a < b end
    local function CompareMax(a, b) return a > b end
    local function Store(compare, defaultNum, ...)
      local storedNum  = defaultNum
      local storedData = {...}
      local dataCount  = select("#", ...)
      local Store = setmetatable({}, {
        __index = {
          Store = function(self, num, ...)
            if not storedNum or compare(num, storedNum) then
              storedNum  = num
              storedData = {...}
              dataCount  = select("#", ...)
            end
            return self
          end,
          
          Get = function()
            return storedNum, unpack(storedData, 1, dataCount)
          end,
        }
      })
      return Store
    end
    
    function Addon:MinStore(...)
      return Store(CompareMin, ...)
    end
    function Addon:MaxStore(...)
      return Store(CompareMax, ...)
    end
  end
  
  
  function Addon:Round(num, nearest)
    nearest = nearest or 1
    local lower = mathFloor(num / nearest) * nearest
    local upper = lower + nearest
    return (upper - num < num - lower) and upper or lower
  end
  
  function Addon:Clamp(min, num, max)
    assert(not min or type(min) == "number", "Can't clamp. min is " .. type(min))
    assert(not max or type(max) == "number", "Can't clamp. max is " .. type(max))
    assert(not min or not max or (min <= max), format("Can't clamp. min (%d) > max (%d)", min, max))
    if min then
      num = mathMax(num, min)
    end
    if max then
      num = mathMin(num, max)
    end
    return num
  end
end






--  ███████╗████████╗██████╗ ██╗███╗   ██╗ ██████╗ ███████╗
--  ██╔════╝╚══██╔══╝██╔══██╗██║████╗  ██║██╔════╝ ██╔════╝
--  ███████╗   ██║   ██████╔╝██║██╔██╗ ██║██║  ███╗███████╗
--  ╚════██║   ██║   ██╔══██╗██║██║╚██╗██║██║   ██║╚════██║
--  ███████║   ██║   ██║  ██║██║██║ ╚████║╚██████╔╝███████║
--  ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝


do
  function Addon:ChainGsub(text, ...)
    for i, patterns in ipairs{...} do
      local newText = patterns[#patterns]
      for i = 1, #patterns - 1 do
        local oldText = patterns[i]
        text = strGsub(text, oldText, newText)
      end
    end
    return text
  end
end


