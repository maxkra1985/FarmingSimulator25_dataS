-- Local values: RollercoasterHotspot_mt
RollercoasterHotspot = {}
RollercoasterHotspot.MOD_DIRECTORY = g_currentModDirectory
local RollercoasterHotspot_mt = Class(RollercoasterHotspot, PlaceableHotspot)

-- Upvalues: RollercoasterHotspot_mt
-- Local values: self
function RollercoasterHotspot.new(customMt)
	-- upvalues: (copy) RollercoasterHotspot_mt
	local v3_ = PlaceableHotspot.new(customMt or RollercoasterHotspot_mt)
	local v4_, v5_ = getNormalizedScreenValues(50, 50)
	v3_.width = v4_
	v3_.height = v5_
	v3_.iconConstruction = g_overlayManager:createOverlay("mapHotspots.contractConstruction", 0, 0, v3_.width, v3_.height)
	v3_.iconRollercoaster = g_overlayManager:createOverlay("mapHotspots.rollercoaster", 0, 0, v3_.width, v3_.height)
	local v6_ = v3_.iconSmall
	local v7_ = PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.EXCLAMATION_MARK]
	v6_:setColor(unpack(v7_))
	v3_.activeIcon = v3_.iconConstruction
	v3_.activeCategory = MapHotspot.CATEGORY_UNLOADING
	return v3_
end

function RollercoasterHotspot:delete()
	RollercoasterHotspot:superClass().delete(self)
	if self.iconConstruction ~= nil then
		self.iconConstruction:delete()
		self.iconConstruction = nil
	end
	if self.iconRollercoaster ~= nil then
		self.iconRollercoaster:delete()
		self.iconRollercoaster = nil
	end
end

function RollercoasterHotspot:changeToRollercoaster()
	self.activeIcon = self.iconRollercoaster
	self.activeCategory = MapHotspot.CATEGORY_OTHER
end

function RollercoasterHotspot:setScale(scale)
	if self.iconRollercoaster ~= nil then
		self.iconRollercoaster:setScale(scale, scale)
	end
	if self.iconConstruction ~= nil then
		self.iconConstruction:setScale(scale, scale)
	end
	RollercoasterHotspot:superClass().setScale(self, scale)
end

function RollercoasterHotspot:getCategory()
	return self.activeCategory
end

function RollercoasterHotspot:getIsPersistent()
	return false
end

function RollercoasterHotspot:getRenderLast()
	return false
end

function RollercoasterHotspot:setPlaceableType(placeableType)
	RollercoasterHotspot:superClass().setPlaceableType(self, placeableType)
	if self.iconSmall ~= nil then
		local v15_ = self.iconSmall
		local v16_ = PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.EXCLAMATION_MARK]
		v15_:setColor(unpack(v16_))
	end
end

-- Local values: activeIcon
function RollercoasterHotspot:render(x, y, rotation, small)
	local v22_ = self.activeIcon
	if small then
		v22_ = self.iconSmall
	end
	if v22_ ~= nil then
		v22_:setPosition(x, y)
		v22_:setRotation(rotation or 0, v22_.width * 0.5, v22_.height * 0.5)
		v22_:setColor(nil, nil, nil, self.isBlinking and (self:getCanBlink() and IngameMap.alpha) or 1)
		v22_:render()
	end
end
