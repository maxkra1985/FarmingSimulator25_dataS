-- Local values: AIHotspot_mt
AIHotspot = {}
local AIHotspot_mt = Class(AIHotspot, MapHotspot)

-- Upvalues: AIHotspot_mt
-- Local values: self, _, textSize, _, textSize
function AIHotspot.new(customMt)
	-- upvalues: (copy) AIHotspot_mt
	local v3_ = MapHotspot.new(customMt or AIHotspot_mt)
	if Platform.isMobile then
		local v4_, v5_ = getNormalizedScreenValues(120, 120)
		v3_.width = v4_
		v3_.height = v5_
		local _, v6_ = getNormalizedScreenValues(0, 20)
		v3_.textSize = v6_
		local v7_, v8_ = getNormalizedScreenValues(60, 53)
		v3_.textOffsetX = v7_
		v3_.textOffsetY = v8_
		v3_.clickArea = MapHotspot.getClickCircle(0.667)
	else
		local v9_, v10_ = getNormalizedScreenValues(50, 50)
		v3_.width = v9_
		v3_.height = v10_
		local _, v11_ = getNormalizedScreenValues(0, 10)
		v3_.textSize = v11_
		local v12_, v13_ = getNormalizedScreenValues(25, 21)
		v3_.textOffsetX = v12_
		v3_.textOffsetY = v13_
		v3_.clickArea = MapHotspot.getClickCircle(0.333)
	end
	v3_.name = nil
	v3_.icon = g_overlayManager:createOverlay("mapHotspots.worker", 0, 0, v3_.width, v3_.height)
	return v3_
end

function AIHotspot:getCategory()
	return MapHotspot.CATEGORY_AI
end

function AIHotspot:setVehicle(vehicle)
	self.vehicle = vehicle
end

function AIHotspot:getVehicle()
	return self.vehicle
end

function AIHotspot:setAIHelperName(name)
	self.name = name
end

-- Local values: x, _, z
function AIHotspot:getWorldPosition()
	local v20_, v21_
	if self.vehicle == nil or not entityExists(self.vehicle.rootNode) then
		v20_ = nil
		v21_ = nil
	else
		local v22_
		v20_, v22_, v21_ = getWorldTranslation(self.vehicle.rootNode)
	end
	return v20_, v21_
end

-- Local values: alpha
function AIHotspot:render(x, y, rotation, small)
	AIHotspot:superClass().render(self, x, y, rotation, small)
	if self.name ~= nil then
		local v28_ = not self.isBlinking and 1 or IngameMap.alpha
		setTextColor(1, 1, 1, v28_)
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextWrapWidth(0)
		setTextBold(false)
		renderText(x + self.textOffsetX * self.scale, y + self.textOffsetY * self.scale, self.textSize * self.scale, self.name)
		setTextColor(1, 1, 1, 1)
		setTextAlignment(RenderText.ALIGN_LEFT)
	end
end

-- Local values: farm, color
function AIHotspot:setOwnerFarmId(farmId)
	AIHotspot:superClass().setOwnerFarmId(self, farmId)
	if g_currentMission.missionDynamicInfo.isMultiplayer then
		local v31_ = g_farmManager:getFarmById(farmId)
		if v31_ ~= nil then
			local v32_ = Farm.COLORS[v31_.color]
			if v32_ ~= nil then
				self:setColor(unpack(v32_))
			end
		end
	end
end
