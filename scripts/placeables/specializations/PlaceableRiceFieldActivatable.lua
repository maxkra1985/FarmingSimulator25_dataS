-- Local values: PlaceableRiceFieldActivatable_mt
PlaceableRiceFieldActivatable = {}
local PlaceableRiceFieldActivatable_mt = Class(PlaceableRiceFieldActivatable)

-- Upvalues: PlaceableRiceFieldActivatable_mt
-- Local values: self
function PlaceableRiceFieldActivatable.new(riceFieldPlaceable)
	-- upvalues: (copy) PlaceableRiceFieldActivatable_mt
	local v3_ = PlaceableRiceFieldActivatable_mt
	local v4_ = setmetatable({}, v3_)
	v4_.riceFieldPlaceable = riceFieldPlaceable
	v4_.fieldIndex = nil
	v4_.activateText = g_i18n:getText("action_interact")
	return v4_
end

-- Local values: field, x, _, z
function PlaceableRiceFieldActivatable:getIsActivatable()
	if self.fieldIndex == nil then
		return false
	end
	local v6_ = self.riceFieldPlaceable:getFieldByIndex(self.fieldIndex)
	if v6_ == nil then
		return false
	end
	local v7_, _, v8_ = getWorldTranslation(v6_.playerTriggerNode)
	return g_currentMission.accessHandler:canFarmAccessLand(g_localPlayer.farmId, v7_, v8_)
end

function PlaceableRiceFieldActivatable:setRiceFieldIndex(fieldIndex)
	self.fieldIndex = fieldIndex
end

-- Local values: field, x, _, z, distance
function PlaceableRiceFieldActivatable:getDistance(posX, posY, posZ)
	if self.fieldIndex ~= nil then
		local v14_ = self.riceFieldPlaceable:getFieldByIndex(self.fieldIndex)
		if v14_.playerTriggerNode ~= nil then
			local v15_, _, v16_ = getWorldTranslation(v14_.playerTriggerNode)
			return MathUtil.vector2Length(posX - v15_, posZ - v16_)
		end
	end
	return math.huge
end

-- Local values: callback
function PlaceableRiceFieldActivatable:run()
	RiceFieldDialog.show(function(_, p18_)
		-- upvalues: (copy) self
		if p18_.isAccepted then
			local v19_ = self.riceFieldPlaceable.spec_riceField.waterMaxLevel * p18_.fillLevelPercentage
			self.riceFieldPlaceable:setWaterHeightTarget(self.fieldIndex, v19_)
		end
	end, self.riceFieldPlaceable, g_i18n:getText("ui_riceManageField"), self.fieldIndex)
end
