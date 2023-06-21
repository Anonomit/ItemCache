
local ADDON_NAME, Data = ...

local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)



local tblConcat = table.concat


do
  Addon.GUI = {}
  local GUI = Addon.GUI
  
  local links = setmetatable({}, {__index = function(t, k) return k end})
  
  function GUI:SwapLinks(link1, link2)
    links[link1], links[link2] = links[link2], links[link1]
  end
  
  local defaultInc   = 1000
  local defaultOrder = 1000
  local order        = defaultOrder
  
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
    if type(keys) ~= "table" then keys = {keys} end
    local key = widgetType .. "_" .. (tblConcat(keys, ".") or "")
    opts.args[key] = {name = name, desc = desc, type = widgetType, order = order or self:Order(), disabled = disabled}
    opts.args[key].set = function(info, val)        Addon:SetOption(val, unpack(keys)) end
    opts.args[key].get = function(info)      return Addon:GetOption(unpack(keys))      end
    return opts.args[key]
  end
  
  function GUI:CreateHeader(opts, name)
    return self:CreateEntry(opts, self:Order(), name, nil, "header", nil, self:Order(0))
  end
  
  function GUI:CreateDescription(opts, desc, fontSize)
    local option = self:CreateEntry(opts, self:Order(), desc, nil, "description", nil, self:Order(0))
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
    option.set = function(info, val)        set(info, not val) end
    option.get = function(info)      return not get()          end
    return option
  end
  
  function GUI:CreateSelect(opts, keys, name, desc, values, sorting, disabled)
    local option = self:CreateEntry(opts, keys, name, desc, "select", disabled)
    option.values  = values
    option.sorting = sorting
    option.style   = "dropdown"
    return option
  end
  
  function GUI:CreateMultiSelect(opts, keys, name, desc, values, disabled)
    local option = self:CreateEntry(opts, keys, name, desc, "multiselect", disabled)
    option.values  = values
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
    option.set   = function(info, r, g, b)        Addon:SetOption(Addon:ConvertColorFromBlizzard(r, g, b), unpack(keys)) end
    option.get   = function(info)          return Addon:ConvertColorToBlizzard(Addon:GetOption(unpack(keys)))            end
    return option
  end
  
  function GUI:CreateExecute(opts, key, name, desc, func, disabled)
    local option = self:CreateEntry(opts, key, name, desc, "execute", disabled)
    option.func  = func
    return option
  end
  
  function GUI:CreateGroup(opts, key, name, desc, groupType, disabled)
    key = "group_" .. links[key]
    opts.args[key] = {name = name, desc = desc, type = "group", childGroups = groupType, args = {}, order = self:Order(), disabled = disabled}
    return opts.args[key]
  end
  
  function GUI:CreateGroupBox(opts, name)
    local key = "group_" .. self:Order(-1)
    opts.args[key] = {name = name, type = "group", args = {}, order = self:Order(), inline = true}
    return opts.args[key]
  end
  
  function GUI:CreateGroupTop(name, groupType, disabled)
    return {name = name, type = "group", childGroups = groupType, args = {}, order = self:Order(), disabled = disabled}
  end
end





