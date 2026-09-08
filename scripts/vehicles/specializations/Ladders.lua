Ladders = {}

function Ladders.prerequisitesPresent(specializations)
	return true
end

function Ladders.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Ladders)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Ladders)
end

function Ladders.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Ladders")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".ladders.ladder(?)#triggerNode", "Ladder trigger node for player")
	schema:setXMLSpecializationType()
end

-- Local values: spec, _, key, triggerNode, ladderTrigger
function Ladders:onLoad(savegame)
	local v5_ = self.spec_ladders
	for _, v6_ in self.xmlFile:iterator("vehicle.ladders.ladder") do
		local v7_ = self.xmlFile:getNode(v6_ .. "#triggerNode", nil, self.components, self.i3dMappings)
		if v7_ ~= nil then
			if v5_.ladderTriggers == nil then
				v5_.ladderTriggers = {}
			end
			local v8_ = LadderTrigger.new(v7_)
			local v9_ = v5_.ladderTriggers
			table.insert(v9_, v8_)
		end
	end
end

-- Local values: spec, _, ladderTrigger
function Ladders:onDelete()
	local v11_ = self.spec_ladders
	if v11_.ladderTriggers ~= nil then
		for _, v12_ in ipairs(v11_.ladderTriggers) do
			v12_:delete()
		end
	end
end
