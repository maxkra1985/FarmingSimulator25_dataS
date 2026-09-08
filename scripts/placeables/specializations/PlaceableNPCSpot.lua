PlaceableNPCSpot = {}

function PlaceableNPCSpot.prerequisitesPresent(specializations)
	return true
end

function PlaceableNPCSpot.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableNPCSpot)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableNPCSpot)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableNPCSpot)
end

function PlaceableNPCSpot.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("NPCSpot")
	NPCSpot.registerXMLPaths(schema, basePath .. ".npcSpots.spot(?)")
	schema:setXMLSpecializationType()
end

-- Local values: spec, placeableUniqueId, spots, index, key, uniqueId, spot
function PlaceableNPCSpot:onLoad(savegame)
	local v5_ = self.spec_npcSpot
	local v6_ = self:getUniqueId()
	local v7_ = {}
	for v8_, v9_ in self.xmlFile:iterator("placeable.npcSpots.spot") do
		local v10_ = string.format("PlaceableNPCSpot_%s_%d", v6_, v8_)
		local v11_ = NPCSpot.new()
		if v11_:loadFromXMLFile(self.xmlFile, v9_, self.components, self.i3dMappings, v10_) then
			table.insert(v7_, v11_)
		else
			v11_:delete()
		end
	end
	if #v7_ > 0 then
		v5_.spots = v7_
	end
end

-- Local values: spec, _, spot
function PlaceableNPCSpot:onFinalizePlacement()
	local v13_ = self.spec_npcSpot
	if v13_.spots ~= nil then
		for _, v14_ in ipairs(v13_.spots) do
			g_npcManager:addSpot(v14_)
		end
	end
end

-- Local values: spec, _, spot
function PlaceableNPCSpot:onDelete()
	local v16_ = self.spec_npcSpot
	if v16_.spots ~= nil then
		for _, v17_ in ipairs(v16_.spots) do
			g_npcManager:removeSpot(v17_)
		end
	end
end
