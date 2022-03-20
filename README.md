# ItemCache

Caches item data returned by GetItemInfo() and more.

Can be run standalone to store data between sessions, or can be embedded as a library.



# Documentation

Check the [wiki](https://github.com/Anonomit/ItemCache/wiki) (WIP).




# Examples

``` lua
local ItemCache = LibStub"ItemCache"


```


# Installation

Install as you would with any other addon.

For developers:
You can include ItemCache as a library in whatever addon you want (for example in a libs/ folder). Make sure the toc file includes SemVer.xml or SemVer.lua. LibStub is a required library, so be sure to include that too (if it isn't already). Additionally, make sure that you set ItemCache as an optional dependency in the toc file. If the addon is found and enabled, it will take precedence and data will persist between sessions.


Write this in any lua file where you want to use it:

``` lua
local ItemCache = LibStub"ItemCache"
```

The simplest use is to then request item info with GetItemInfo:

``` lua
local name, link = ItemCache:GetItemInfo(itemData)
```

This method wraps the global function of the same name. It can be used in place of the regular GetItemInfo.


# Notes

ItemCache will only store data between sessions if it is running as an addon.

All item data will be thrown out when WoW updates. This is intentional.

A separate cache is used for each locale.
