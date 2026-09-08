-- Local values: PlatformIconElement_mt
PlatformIconElement = {}
local PlatformIconElement_mt = Class(PlatformIconElement, BitmapElement)
Gui.registerGuiElement("PlatformIcon", PlatformIconElement)

-- Upvalues: PlatformIconElement_mt
-- Local values: self
function PlatformIconElement.new(target, custom_mt)
	-- upvalues: (copy) PlatformIconElement_mt
	return PlatformIconElement:superClass().new(target, custom_mt or PlatformIconElement_mt)
end

function PlatformIconElement:delete()
	PlatformIconElement:superClass().delete(self)
end

function PlatformIconElement:copyAttributes(src)
	PlatformIconElement:superClass().copyAttributes(self, src)
	self.platformId = src.platformId
end

-- Local values: useOtherIcon
function PlatformIconElement:setPlatformId(platformId)
	local v9_ = ((GS_PLATFORM_ID == PlatformId.PS5 and platformId ~= PlatformId.PS5 or GS_PLATFORM_ID == PlatformId.XBOX_SERIES and platformId ~= PlatformId.XBOX_SERIES) and true or (GS_IS_MSSTORE_VERSION and (platformId ~= PlatformId.XBOX_SERIES and platformId ~= PlatformId.WIN) and true or false)) and 0 or platformId
	if PlatformIconElement.ALLOW_COLOR_CHANGE[v9_] then
		if self.colorSelectedBackup ~= nil then
			self.overlay.colorSelected = self.colorSelectedBackup
			self.colorSelectedBackup = nil
		end
	else
		self.colorSelectedBackup = self.overlay.colorSelected
		self.overlay.colorSelected = self.overlay.color
	end
	self:setImageSlice(nil, PlatformIconElement.SLICES[v9_])
end
PlatformIconElement.SLICES = {
	[0] = "gui.multiplayer_genericPlatform",
	[PlatformId.WIN] = "gui.multiplayer_PC",
	[PlatformId.MAC] = "gui.multiplayer_PC",
	[PlatformId.PS5] = "gui.multiplayer_playstation",
	[PlatformId.XBOX_SERIES] = "gui.multiplayer_xbox"
}
PlatformIconElement.ALLOW_COLOR_CHANGE = {
	[0] = true,
	[PlatformId.WIN] = true,
	[PlatformId.MAC] = true,
	[PlatformId.PS5] = false,
	[PlatformId.XBOX_SERIES] = true
}
