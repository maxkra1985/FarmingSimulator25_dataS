PlatformIconElement = {}
local PlatformIconElement_mt = Class(PlatformIconElement, BitmapElement)
Gui.registerGuiElement("PlatformIcon", PlatformIconElement)
function PlatformIconElement.new(target, custom_mt)
	local self = PlatformIconElement:superClass().new(target, custom_mt or PlatformIconElement_mt)
	return self
end
function PlatformIconElement:delete()
	PlatformIconElement:superClass().delete(self)
end
function PlatformIconElement:copyAttributes(src)
	PlatformIconElement:superClass().copyAttributes(self, src)
	self.platformId = src.platformId
end
function PlatformIconElement:setPlatformId(platformId)
	local useOtherIcon = false
	if GS_PLATFORM_ID == PlatformId.PS5 then
		if platformId ~= PlatformId.PS5 then
			useOtherIcon = true
		elseif GS_PLATFORM_ID == PlatformId.XBOX_SERIES then
			if platformId ~= PlatformId.XBOX_SERIES then
				useOtherIcon = true
			elseif GS_IS_MSSTORE_VERSION then
				if platformId ~= PlatformId.XBOX_SERIES and platformId ~= PlatformId.WIN then
					useOtherIcon = true
				end
			end
		end
	end
	if useOtherIcon then
		platformId = 0
	end
	if not PlatformIconElement.ALLOW_COLOR_CHANGE[platformId] then
		self.colorSelectedBackup = self.overlay.colorSelected
		self.overlay.colorSelected = self.overlay.color
	elseif self.colorSelectedBackup ~= nil then
		self.overlay.colorSelected = self.colorSelectedBackup
		self.colorSelectedBackup = nil
	end
	self:setImageSlice(nil, PlatformIconElement.SLICES[platformId])
end
PlatformIconElement.SLICES = { [0] = "gui.multiplayer_genericPlatform", [PlatformId.WIN] = "gui.multiplayer_PC", [PlatformId.MAC] = "gui.multiplayer_PC", [PlatformId.PS5] = "gui.multiplayer_playstation", [PlatformId.XBOX_SERIES] = "gui.multiplayer_xbox" }
PlatformIconElement.ALLOW_COLOR_CHANGE = { [0] = true, [PlatformId.WIN] = true, [PlatformId.MAC] = true, [PlatformId.PS5] = false, [PlatformId.XBOX_SERIES] = true }
