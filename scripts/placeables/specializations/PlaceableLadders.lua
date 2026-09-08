PlaceableLadders = {}

function PlaceableLadders.prerequisitesPresent(specializations)
	return true
end

function PlaceableLadders.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableLadders)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableLadders)
end

function PlaceableLadders.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableLadders.collectPickObjects)
end

function PlaceableLadders.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Ladders")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".ladders.ladder(?)#triggerNode", "Ladder trigger node for player")
	schema:setXMLSpecializationType()
end

-- Local values: spec, _, key, triggerNode, ladderTrigger
function PlaceableLadders:onLoad(savegame)
	local v6_ = self.spec_ladders
	for _, v7_ in self.xmlFile:iterator("placeable.ladders.ladder") do
		local v8_ = self.xmlFile:getNode(v7_ .. "#triggerNode", nil, self.components, self.i3dMappings)
		if v8_ ~= nil then
			if v6_.ladderTriggers == nil then
				v6_.ladderTriggers = {}
			end
			local v9_ = LadderTrigger.new(v8_)
			local v10_ = v6_.ladderTriggers
			table.insert(v10_, v9_)
		end
	end
end

-- Local values: spec, _, ladderTrigger
function PlaceableLadders:onDelete()
	local v12_ = self.spec_ladders
	if v12_.ladderTriggers ~= nil then
		for _, v13_ in ipairs(v12_.ladderTriggers) do
			v13_:delete()
		end
	end
end

-- Local values: spec, foundNode, _, ladderTrigger
function PlaceableLadders:collectPickObjects(superFunc, node)
	local v17_ = self.spec_ladders
	local v18_ = false
	if v17_.ladderTriggers ~= nil then
		for _, v19_ in ipairs(v17_.ladderTriggers) do
			if node == v19_.node then
				v18_ = true
				break
			end
		end
	end
	if not v18_ then
		superFunc(self, node)
	end
end
