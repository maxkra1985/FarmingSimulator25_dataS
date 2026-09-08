-- Local values: Farmland_mt
Farmland = {}
local Farmland_mt = Class(Farmland)

function Farmland.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#id", "Id of the farmland", nil, true)
	schema:register(XMLValueType.VECTOR_2, basePath .. "#indicatorPosition", "World position of the indicator", nil, false)
	schema:register(XMLValueType.STRING, basePath .. "#name", "Name of the farmland", nil, false)
	schema:register(XMLValueType.FLOAT, basePath .. "#areaInHa", "Area of the farmland in Ha", 2.5, false)
	schema:register(XMLValueType.FLOAT, basePath .. "#price", "Price of the farmland", nil, false)
	schema:register(XMLValueType.FLOAT, basePath .. "#priceScale", "Price scale of the farmland", 1, false)
	schema:register(XMLValueType.STRING, basePath .. "#npcName", "Name of the owner npc", nil, false)
	schema:register(XMLValueType.BOOL, basePath .. "#showOnFarmlandsScreen", "Indicates if the farmland should be shown on the map screen", true, false)
	schema:register(XMLValueType.BOOL, basePath .. "#defaultFarmProperty", "Indicates if the farmland is owned on start", true, false)
end

-- Upvalues: Farmland_mt
-- Local values: self
function Farmland.new(customMt)
	-- upvalues: (copy) Farmland_mt
	local v5_ = customMt or Farmland_mt
	local v6_ = setmetatable({}, v5_)
	v6_.isOwned = false
	v6_.xWorldPos = nil
	v6_.zWorldPos = nil
	v6_.field = nil
	v6_.boundingBox = nil
	return v6_
end

-- Local values: name, npc
function Farmland:load(xmlFile, key)
	self.id = xmlFile:getValue(key .. "#id")
	if self.id == nil or self.id == 0 then
		Logging.xmlError(xmlFile, "Invalid farmland id \'%s\'!", self.id)
		return false
	end
	local v10_, v11_ = xmlFile:getValue(key .. "#indicatorPosition")
	self.xWorldPos = v10_
	self.zWorldPos = v11_
	local v12_ = xmlFile:getValue(key .. "#name")
	if v12_ ~= nil then
		v12_ = g_i18n:convertText(v12_, g_currentMission.loadingMapModName)
	end
	if not v12_ then
		local v13_ = self.id
		v12_ = tostring(v13_)
	end
	self.name = v12_
	self.areaInHa = xmlFile:getValue(key .. "#areaInHa", 2.5)
	self.fixedPrice = xmlFile:getValue(key .. "#price")
	if self.fixedPrice == nil then
		self.priceFactor = xmlFile:getValue(key .. "#priceScale", 1)
	end
	self.price = self.fixedPrice or 1
	self:updatePrice()
	self.npcIndex = g_npcManager:getRandomIndex()
	local v14_ = g_npcManager:getNPCByName(xmlFile:getValue(key .. "#npcName"))
	if v14_ ~= nil then
		self.npcIndex = v14_.index
	end
	self.isOwned = false
	self.showOnFarmlandsScreen = xmlFile:getValue(key .. "#showOnFarmlandsScreen", true)
	self.defaultFarmProperty = xmlFile:getValue(key .. "#defaultFarmProperty", false)
	self.farmId = FarmlandManager.NO_OWNER_FARM_ID
	return true
end

function Farmland:delete()
	if self.mapHotspot ~= nil then
		g_currentMission:removeMapHotspot(self.mapHotspot)
		self.mapHotspot:delete()
		self.mapHotspot = nil
	end
end

-- Local values: xWorldPos, zWorldPos
function Farmland:setField(field)
	self.field = field
	if field ~= nil and self.mapHotspot ~= nil then
		local v18_, v19_ = field:getIndicatorPosition()
		self.mapHotspot:setWorldPosition(v18_, v19_)
	end
end

function Farmland:getField()
	return self.field
end

function Farmland:setIndicatorPosition(xWorldPos, zWorldPos)
	self.xWorldPos = xWorldPos
	self.zWorldPos = zWorldPos
	if self.mapHotspot ~= nil then
		self.mapHotspot:setWorldPosition(xWorldPos, zWorldPos)
	end
end

function Farmland:setBoundingBox(boundingBox)
	self.boundingBox = boundingBox
end

function Farmland:getBoundingBox()
	if self.boundingBox == nil then
		return nil, nil, nil, nil
	else
		return self.boundingBox.minX, self.boundingBox.minZ, self.boundingBox.maxX, self.boundingBox.maxZ
	end
end

function Farmland:getIndicatorPosition()
	if self.field == nil then
		return self.xWorldPos, self.zWorldPos
	else
		return self.field:getIndicatorPosition()
	end
end

function Farmland:getTeleportPosition()
	if self.field == nil then
		return self.xWorldPos, self.zWorldPos
	else
		return self.field:getTeleportPosition()
	end
end

function Farmland:getId()
	return self.id
end

function Farmland:getName()
	return self.name
end

function Farmland:setArea(areaInHa)
	self.areaInHa = areaInHa
	if self.fixedPrice == nil then
		self:updatePrice()
	end
end

function Farmland:updatePrice()
	self.price = g_farmlandManager:getPricePerHa() * self.areaInHa * self.priceFactor
end

function Farmland:getNPC()
	return g_npcManager:getNPCByIndex(self.npcIndex)
end

function Farmland:setOwnerFarmId(farmId)
	self.farmId = farmId
	self.isOwned = farmId ~= FarmlandManager.NO_OWNER_FARM_ID
	if self.mapHotspot ~= nil then
		self.mapHotspot:setOwnerFarmId(farmId)
	end
end

-- Local values: mapHotspot
function Farmland:addMapHotspot()
	if self.mapHotspot ~= nil then
		g_currentMission:removeMapHotspot(self.mapHotspot)
		self.mapHotspot:delete()
		self.mapHotspot = nil
	end
	local v38_ = FarmlandHotspot.new()
	v38_:setFarmland(self)
	self.mapHotspot = v38_
	self.mapHotspot:setOwnerFarmId(self.farmId)
	g_currentMission:addMapHotspot(v38_)
end

function Farmland:getMapHotspot()
	return self.mapHotspot
end
