-- Local values: HandToolHolderActivatable_mt
HandToolHolderActivatable = {}
local HandToolHolderActivatable_mt = Class(HandToolHolderActivatable)

-- Upvalues: HandToolHolderActivatable_mt
-- Local values: self
function HandToolHolderActivatable.new(handToolHolder, takeText, storeText, needTargeting)
	-- upvalues: (copy) HandToolHolderActivatable_mt
	local v6_ = HandToolHolderActivatable_mt
	local v7_ = setmetatable({}, v6_)
	v7_.handToolHolder = handToolHolder
	v7_.needTargeting = needTargeting
	v7_.takeText = takeText
	v7_.storeText = storeText
	v7_.activateText = v7_.takeText
	return v7_
end

-- Local values: localPlayer, targetedHandToolHolder, holderHandTool, playerHandTool, canPickup, canPickup
function HandToolHolderActivatable:getIsActivatable()
	local v9_ = g_localPlayer
	if v9_ == nil then
		return false
	end
	if self.needTargeting then
		if v9_.targeter == nil then
			return false
		end
		if HandToolUtil.getTargetedHandToolHolder(v9_.targeter) ~= self.handToolHolder then
			return false
		end
	end
	local v10_ = self.handToolHolder:getHandTool()
	local v11_ = v9_:getHeldHandTool()
	if v11_ == nil and v10_ ~= nil then
		local v12_ = v9_:getCanPickupHandTool(v10_)
		if v12_ then
			self.activateText = string.format(self.takeText, v10_.typeDesc)
		end
		return v12_
	end
	if v11_ == nil or v10_ ~= nil then
		return false
	end
	local v13_ = self.handToolHolder:getCanPickupHandTool(v11_)
	if v13_ then
		self.activateText = string.format(self.storeText, v11_.typeDesc)
	end
	return v13_
end

-- Local values: x, y, z, distance
function HandToolHolderActivatable:getDistance(positionX, positionY, positionZ)
	if self.needTargeting and self:getIsActivatable() then
		return 0
	end
	local v18_, v19_, v20_ = getWorldTranslation(self.handToolHolder.holderNode)
	return MathUtil.vector3Length(positionX - v18_, positionY - v19_, positionZ - v20_)
end

-- Local values: holderHandTool, playerHandTool
function HandToolHolderActivatable:run()
	local v22_ = self.handToolHolder:getHandTool()
	local v23_ = g_localPlayer:getHeldHandTool()
	if v23_ == nil and v22_ ~= nil then
		v22_:setHolder(g_localPlayer)
		g_localPlayer:setCurrentHandTool(v22_)
	elseif v23_ ~= nil and v22_ == nil then
		v23_:setHolder(self.handToolHolder)
	end
end
