# ItemCache

Caches item data returned by GetItemInfo() and a little extra.

ItemCache can be run as a standalone addon to store data between sessions, or can be embedded into another addon as a library.

ItemCache monitors multiple vectors (such as GET_ITEM_INFO_RECEIVED, chat channels, mouseover) and looks for item information. When an item's info is observed by ItemCache, it is remembered. The user can then retrieve that information instantly without needing the item to be loaded.
Quick note: ItemCache uses the terms 'cache' and 'load' distinctly. An item being cached means that its information is known to ItemCache, so the item data can be retrieved instantly. An item being loaded means that the default GetItemInfo will return non-nil results. The caching is controlled by ItemCache, and the loading is controlled by Blizzard. An item that isn't loaded will take one or more frames to load. Loaded items can eventually become unloaded again. An item can be cached even if it isn't loaded. An item can be loaded even if it isn't cached.


# Documentation

Check the [wiki](https://github.com/Anonomit/ItemCache/wiki) (WIP).




# Examples

``` lua
local ItemCache = LibStub("ItemCache")

local hearthstone = ItemCache:Item(6948) -- Returns an Item object for an item with id 6948 (which is Hearthstone)
print(hearthstone:GetLink()) -- Returns the item link for the item. Will return nil if the item is not cached (hearthstone probably is!)

local healingBoots = ItemCache:Item(30680, -26) -- Returns an Item object for Glider's Boots of Healing
healingBoots:OnCache(function(item)
  print(item:GetLink()) -- Never returns nil (as long as the item actually exists)
end) -- Prints the item link as soon as the item is in the cache. Also loads the item if it is not yet cached.

print(healingBoots:IsCached()) -- Returns true if the boots have been seen before, false otherwise
healingBoots:Load() -- Attempts to load the item into memory so that the default GetItemInfo will be populated
healingBoots:Cache() -- Same as above but does nothing if the item has already been seen by ItemCache

```


# Installation

Install as you would with any other addon.

For developers:
You can include ItemCache as a library in whatever addon you want (for example in a libs/ folder). The only necessary file is ItemCache.lua. The TOC file of your addon should have ItemCache listed as an optional dependency, and should reference ItemCache.lua. If you prefer to reference an XML file, you can embed both ItemCache.lua and ItemCache.xml. When ItemCache is embedded as a library, its only dependency is LibStub. If the ItemCache addon is enabled and up to date, then data will persist between sessions. Otherwise, ItemCache will not store data between sessions when it is embedded as a library.


# Usage

Write this in any lua file where you want to use it:

``` lua
local ItemCache = LibStub("ItemCache")
```

The simplest use is to then request item info with GetItemInfo:

``` lua
local name, link, etc = ItemCache:GetItemInfo(itemData)
```

This method wraps the global function of the same name. It can be used in place of the regular GetItemInfo. if ItemCache already knows the info for this item, then it's returned instantly, even if the item is not actually loaded.


# Notes

ItemCache will only store data between sessions if it is running as an addon.

All item data will be thrown out when WoW updates. This is intentional.

The cache is locale-specific. Only the cache for the current locale is active.
