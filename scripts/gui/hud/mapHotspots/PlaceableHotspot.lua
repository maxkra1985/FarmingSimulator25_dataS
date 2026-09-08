-- Local values: PlaceableHotspot_mt
PlaceableHotspot = {}
PlaceableHotspot.TYPE = {}
PlaceableHotspot.TYPE.LOADING = 1
PlaceableHotspot.TYPE.UNLOADING = 2
PlaceableHotspot.TYPE.UNLOADING_TRAIN = 3
PlaceableHotspot.TYPE.PRODUCTION_POINT = 4
PlaceableHotspot.TYPE.SHOP = 5
PlaceableHotspot.TYPE.FARM = 6
PlaceableHotspot.TYPE.FUEL = 7
PlaceableHotspot.TYPE.ELECTRICITY = 8
PlaceableHotspot.TYPE.SHOP_ANIMAL = 9
PlaceableHotspot.TYPE.CHICKEN = 10
PlaceableHotspot.TYPE.PIG = 11
PlaceableHotspot.TYPE.SHEEP = 12
PlaceableHotspot.TYPE.COW = 13
PlaceableHotspot.TYPE.HORSE = 14
PlaceableHotspot.TYPE.TRAIN = 15
PlaceableHotspot.TYPE.BEE = 16
PlaceableHotspot.TYPE.EXCLAMATION_MARK = 17
PlaceableHotspot.TYPE.UNLOADING_PALLET = 18
PlaceableHotspot.TYPE.FISHPOND = 19
PlaceableHotspot.TYPE.FISHBREEDING = 20
PlaceableHotspot.TYPE.WILDLIFE = 21
PlaceableHotspot.CATEGORY_MAPPING = {}
PlaceableHotspot.CATEGORY_MAPPING[PlaceableHotspot.TYPE.UNLOADING] = MapHotspot.CATEGORY_UNLOADING
PlaceableHotspot.CATEGORY_MAPPING[PlaceableHotspot.TYPE.UNLOADING_PALLET] = MapHotspot.CATEGORY_UNLOADING
PlaceableHotspot.CATEGORY_MAPPING[PlaceableHotspot.TYPE.UNLOADING_TRAIN] = MapHotspot.CATEGORY_UNLOADING
PlaceableHotspot.CATEGORY_MAPPING[PlaceableHotspot.TYPE.LOADING] = MapHotspot.CATEGORY_LOADING
PlaceableHotspot.CATEGORY_MAPPING[PlaceableHotspot.TYPE.PRODUCTION_POINT] = MapHotspot.CATEGORY_PRODUCTION
PlaceableHotspot.CATEGORY_MAPPING[PlaceableHotspot.TYPE.SHOP] = MapHotspot.CATEGORY_SHOP
PlaceableHotspot.CATEGORY_MAPPING[PlaceableHotspot.TYPE.FARM] = MapHotspot.CATEGORY_OTHER
PlaceableHotspot.CATEGORY_MAPPING[PlaceableHotspot.TYPE.FUEL] = MapHotspot.CATEGORY_LOADING
PlaceableHotspot.CATEGORY_MAPPING[PlaceableHotspot.TYPE.ELECTRICITY] = MapHotspot.CATEGORY_LOADING
PlaceableHotspot.CATEGORY_MAPPING[PlaceableHotspot.TYPE.EXCLAMATION_MARK] = MapHotspot.CATEGORY_OTHER
PlaceableHotspot.CATEGORY_MAPPING[PlaceableHotspot.TYPE.SHOP_ANIMAL] = MapHotspot.CATEGORY_SHOP
PlaceableHotspot.CATEGORY_MAPPING[PlaceableHotspot.TYPE.CHICKEN] = MapHotspot.CATEGORY_ANIMAL
PlaceableHotspot.CATEGORY_MAPPING[PlaceableHotspot.TYPE.PIG] = MapHotspot.CATEGORY_ANIMAL
PlaceableHotspot.CATEGORY_MAPPING[PlaceableHotspot.TYPE.SHEEP] = MapHotspot.CATEGORY_ANIMAL
PlaceableHotspot.CATEGORY_MAPPING[PlaceableHotspot.TYPE.COW] = MapHotspot.CATEGORY_ANIMAL
PlaceableHotspot.CATEGORY_MAPPING[PlaceableHotspot.TYPE.HORSE] = MapHotspot.CATEGORY_ANIMAL
PlaceableHotspot.CATEGORY_MAPPING[PlaceableHotspot.TYPE.TRAIN] = MapHotspot.CATEGORY_OTHER
PlaceableHotspot.CATEGORY_MAPPING[PlaceableHotspot.TYPE.BEE] = MapHotspot.CATEGORY_ANIMAL
PlaceableHotspot.CATEGORY_MAPPING[PlaceableHotspot.TYPE.FISHPOND] = MapHotspot.CATEGORY_PRODUCTION
PlaceableHotspot.CATEGORY_MAPPING[PlaceableHotspot.TYPE.FISHBREEDING] = MapHotspot.CATEGORY_PRODUCTION
PlaceableHotspot.CATEGORY_MAPPING[PlaceableHotspot.TYPE.WILDLIFE] = MapHotspot.CATEGORY_ANIMAL
PlaceableHotspot.SLICE = {}
PlaceableHotspot.SLICE[PlaceableHotspot.TYPE.UNLOADING] = "mapHotspots.tipStation"
PlaceableHotspot.SLICE[PlaceableHotspot.TYPE.UNLOADING_TRAIN] = "mapHotspots.tipStationTrain"
PlaceableHotspot.SLICE[PlaceableHotspot.TYPE.UNLOADING_PALLET] = "mapHotspots.pallet"
PlaceableHotspot.SLICE[PlaceableHotspot.TYPE.PRODUCTION_POINT] = "mapHotspots.production"
PlaceableHotspot.SLICE[PlaceableHotspot.TYPE.SHOP] = "mapHotspots.otherShop"
PlaceableHotspot.SLICE[PlaceableHotspot.TYPE.FARM] = "mapHotspots.otherHouse"
PlaceableHotspot.SLICE[PlaceableHotspot.TYPE.FUEL] = "mapHotspots.loadingStationFuel"
PlaceableHotspot.SLICE[PlaceableHotspot.TYPE.ELECTRICITY] = "mapHotspots.loadingStationElectricCharge"
PlaceableHotspot.SLICE[PlaceableHotspot.TYPE.EXCLAMATION_MARK] = "mapHotspots.contract"
PlaceableHotspot.SLICE[PlaceableHotspot.TYPE.LOADING] = "mapHotspots.loadingStation"
PlaceableHotspot.SLICE[PlaceableHotspot.TYPE.SHOP_ANIMAL] = "mapHotspots.otherAnimalDealer"
PlaceableHotspot.SLICE[PlaceableHotspot.TYPE.CHICKEN] = "mapHotspots.animalsChicken"
PlaceableHotspot.SLICE[PlaceableHotspot.TYPE.PIG] = "mapHotspots.animalsPig"
PlaceableHotspot.SLICE[PlaceableHotspot.TYPE.SHEEP] = "mapHotspots.animalsSheep"
PlaceableHotspot.SLICE[PlaceableHotspot.TYPE.COW] = "mapHotspots.animalsCow"
PlaceableHotspot.SLICE[PlaceableHotspot.TYPE.HORSE] = "mapHotspots.animalsHorse"
PlaceableHotspot.SLICE[PlaceableHotspot.TYPE.TRAIN] = "mapHotspots.otherTrain"
PlaceableHotspot.SLICE[PlaceableHotspot.TYPE.BEE] = "mapHotspots.animalsBee"
PlaceableHotspot.SLICE[PlaceableHotspot.TYPE.FISHPOND] = "mapHotspots.fishPond"
PlaceableHotspot.SLICE[PlaceableHotspot.TYPE.FISHBREEDING] = "mapHotspots.fishBreeding"
PlaceableHotspot.SLICE[PlaceableHotspot.TYPE.WILDLIFE] = "mapHotspots.wildlife"
PlaceableHotspot.COLOR = {}
PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.UNLOADING] = {
	0.2664,
	0.0048,
	0.1384,
	1
}
PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.UNLOADING_TRAIN] = {
	0.2664,
	0.0048,
	0.1384,
	1
}
PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.UNLOADING_PALLET] = {
	0.2664,
	0.0048,
	0.1384,
	1
}
PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.PRODUCTION_POINT] = {
	0.0065,
	0.5583,
	0.5711,
	1
}
PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.SHOP] = {
	0.6105,
	0.5583,
	0.0027,
	1
}
PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.FARM] = {
	0.6105,
	0.5583,
	0.0027,
	1
}
PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.FUEL] = {
	0.0203,
	0.0685,
	0.4287,
	1
}
PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.ELECTRICITY] = {
	0.0203,
	0.0685,
	0.4287,
	1
}
PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.EXCLAMATION_MARK] = {
	0.0027,
	0.1981,
	0.0152,
	1
}
PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.LOADING] = {
	0.0203,
	0.0685,
	0.4287,
	1
}
PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.SHOP_ANIMAL] = {
	0.6105,
	0.5583,
	0.0027,
	1
}
PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.CHICKEN] = {
	0.006,
	0.1441,
	0.1144,
	1
}
PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.PIG] = {
	0.006,
	0.1441,
	0.1144,
	1
}
PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.SHEEP] = {
	0.006,
	0.1441,
	0.1144,
	1
}
PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.COW] = {
	0.006,
	0.1441,
	0.1144,
	1
}
PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.HORSE] = {
	0.006,
	0.1441,
	0.1144,
	1
}
PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.TRAIN] = {
	0.6105,
	0.5583,
	0.0027,
	1
}
PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.BEE] = {
	0.006,
	0.1441,
	0.1144,
	1
}
PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.FISHPOND] = {
	0.006,
	0.1441,
	0.1144,
	1
}
PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.FISHBREEDING] = {
	0.006,
	0.1441,
	0.1144,
	1
}
PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.WILDLIFE] = {
	0.105,
	0.105,
	0.012,
	1
}
local PlaceableHotspot_mt = Class(PlaceableHotspot, MapHotspot)

-- Upvalues: PlaceableHotspot_mt
-- Local values: self
function PlaceableHotspot.new(customMt)
	-- upvalues: (copy) PlaceableHotspot_mt
	local v3_ = MapHotspot.new(customMt or PlaceableHotspot_mt)
	if Platform.isMobile then
		local v4_, v5_ = getNormalizedScreenValues(90, 90)
		v3_.width = v4_
		v3_.height = v5_
		v3_.clickArea = MapHotspot.getClickCircle(0.667)
	else
		local v6_, v7_ = getNormalizedScreenValues(50, 50)
		v3_.width = v6_
		v3_.height = v7_
		v3_.clickArea = MapHotspot.getClickArea({
			9,
			13,
			82,
			82
		}, { 100, 100 }, 0)
	end
	v3_.placeableType = PlaceableHotspot.TYPE.UNLOADING
	v3_.iconSmall = g_overlayManager:createOverlay("mapHotspots.miniMapHotspot", 0, 0, v3_.width, v3_.height)
	local v8_ = v3_.iconSmall
	local v9_ = PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.UNLOADING]
	v8_:setColor(unpack(v9_))
	v3_.lastRenderedIcon = v3_.iconSmall
	v3_.teleportWorldX = nil
	v3_.teleportWorldY = nil
	v3_.teleportWorldZ = nil
	v3_.name = nil
	return v3_
end

function PlaceableHotspot:delete()
	PlaceableHotspot:superClass().delete(self)
	if self.iconSmall ~= nil then
		self.iconSmall:delete()
		self.iconSmall = nil
	end
end

function PlaceableHotspot:getCategory()
	return PlaceableHotspot.CATEGORY_MAPPING[self.placeableType]
end

function PlaceableHotspot:setPlaceable(placeable)
	self.placeable = placeable
	self:createIcon()
	self:setPlaceableType(self.placeableType)
end

function PlaceableHotspot:getPlaceable()
	return self.placeable
end

-- Local values: slice
function PlaceableHotspot:setPlaceableType(placeableType)
	self.placeableType = placeableType
	if self.icon ~= nil then
		local v17_ = g_overlayManager:getSliceInfoById(PlaceableHotspot.SLICE[placeableType])
		if v17_ ~= nil then
			self.icon:setUVs(v17_.uvs)
		end
	end
	if self.iconSmall ~= nil then
		local v18_ = self.iconSmall
		local v19_ = PlaceableHotspot.COLOR[placeableType]
		v18_:setColor(unpack(v19_))
	end
end

function PlaceableHotspot:createIcon()
	if self.icon ~= nil then
		self.icon:delete()
	end
	self.icon = g_overlayManager:createOverlay(PlaceableHotspot.SLICE[self.placeableType], 0, 0, self.width, self.height)
	if self.icon ~= nil then
		local v21_ = self.icon
		local v22_ = self.color
		v21_:setColor(unpack(v22_))
		self.icon:setScale(self.scale, self.scale)
	end
end

function PlaceableHotspot:setTeleportWorldPosition(x, y, z)
	self.teleportWorldX = x
	self.teleportWorldY = y
	self.teleportWorldZ = z
end

-- Local values: y
function PlaceableHotspot:getTeleportWorldPosition()
	if self.teleportWorldX == nil then
		return nil
	end
	local v28_ = getTerrainHeightAtWorldPos(g_terrainNode, self.teleportWorldX, 0, self.teleportWorldZ)
	local v29_ = self.teleportWorldX
	local v30_ = self.teleportWorldY
	return v29_, math.max(v28_, v30_), self.teleportWorldZ
end

function PlaceableHotspot:getBeVisited()
	return self.teleportWorldX ~= nil
end

function PlaceableHotspot:setScale(scale)
	self.iconSmall:setScale(scale, scale)
	MapHotspot.setScale(self, scale)
end

function PlaceableHotspot:getWidth()
	return self.lastRenderedIcon.width
end

function PlaceableHotspot:getHeight()
	return self.lastRenderedIcon.height
end

function PlaceableHotspot:getDimension()
	return self.lastRenderedIcon.width, self.lastRenderedIcon.height
end

-- Local values: icon, a, clickArea, width, height, radius
function PlaceableHotspot:render(x, y, rotation, small)
	local v42_ = self.icon
	if small then
		v42_ = self.iconSmall
	end
	self.lastRenderedIcon = v42_
	if v42_ ~= nil then
		local v43_ = self.isBlinking and IngameMap.alpha or 1
		v42_:renderCustom(x, y, v42_.width, v42_.height, nil, nil, nil, v43_, nil, nil, nil, nil, rotation or 0, v42_.width * 0.5, v42_.height * 0.5)
	end
	if MapHotspot.DEBUGGING then
		local v44_ = self.clickArea
		if v44_.areaType == MapHotspot.AREA.CIRCLE then
			local v45_ = self:getWidth()
			local v46_ = self:getHeight()
			local v47_ = v45_ * (v44_.radiusFactor or 1)
			drawOutlineCircle2D(x + v45_ * 0.5, y + v46_ * 0.5, v47_, 0.001, 40, 1, 0, 0, 1)
		end
	end
end

function PlaceableHotspot:getName()
	if self.name == nil then
		if self.placeable == nil then
			return nil
		else
			return self.placeable:getName()
		end
	else
		return self.name
	end
end

function PlaceableHotspot:setName(name)
	self.name = name
end

function PlaceableHotspot.getTypeByName(name)
	if name == nil then
		return nil
	end
	local v52_ = string.upper(name)
	return PlaceableHotspot.TYPE[v52_]
end
PlaceableHotspot.getWorldPosition = MapHotspot.getWorldPosition
PlaceableHotspot.getWorldRotation = MapHotspot.getWorldRotation
