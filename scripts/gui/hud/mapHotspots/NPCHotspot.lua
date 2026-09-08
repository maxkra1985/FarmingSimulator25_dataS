-- Local values: NPCHotspot_mt
NPCHotspot = {}
local NPCHotspot_mt = Class(NPCHotspot, MapHotspot)

-- Upvalues: NPCHotspot_mt
-- Local values: self
function NPCHotspot.new(npc, customMt)
	-- upvalues: (copy) NPCHotspot_mt
	local v4_ = MapHotspot.new(customMt or NPCHotspot_mt)
	v4_.npc = npc
	local v5_, v6_ = getNormalizedScreenValues(50, 50)
	v4_.width = v5_
	v4_.height = v6_
	v4_.icon = g_overlayManager:createOverlay("mapHotspots.npc", 0, 0, v4_.width, v4_.height)
	v4_.iconSmall = g_overlayManager:createOverlay("mapHotspots.miniMapHotspot", 0, 0, v4_.width, v4_.height)
	v4_.iconSmall:setColor(0.8, 0.76863, 0.03137, 1)
	v4_.forceNoRotation = true
	v4_.lastRenderedIcon = v4_.iconSmall
	v4_.clickArea = MapHotspot.getClickArea({
		9,
		13,
		82,
		82
	}, { 100, 100 }, 0)
	return v4_
end

function NPCHotspot:delete()
	NPCHotspot:superClass().delete(self)
	if self.icon ~= nil then
		self.icon:delete()
		self.icon = nil
	end
	if self.iconSmall ~= nil then
		self.iconSmall:delete()
		self.iconSmall = nil
	end
end

function NPCHotspot:getWidth()
	return self.lastRenderedIcon.width
end

function NPCHotspot:getHeight()
	return self.lastRenderedIcon.height
end

function NPCHotspot:getDimension()
	return self.lastRenderedIcon.width, self.lastRenderedIcon.height
end

function NPCHotspot:setScale(scale)
	self.iconSmall:setScale(scale, scale)
	if self.icon ~= nil then
		self.icon:setScale(scale, scale)
	end
	MapHotspot.setScale(self, scale)
end

function NPCHotspot:getCategory()
	return MapHotspot.CATEGORY_OTHER
end

function NPCHotspot:getIsPersistent()
	return false
end

function NPCHotspot:getRenderLast()
	return false
end

function NPCHotspot:getImageFilename()
	if self.npc == nil then
		return nil
	else
		return self.npc:getImageFilename()
	end
end

function NPCHotspot:getName()
	if self.npc == nil then
		return nil
	else
		return self.npc:getTitle()
	end
end

function NPCHotspot:getBeVisited()
	if self.npc == nil then
		return false
	else
		return self.npc:getBeVisited()
	end
end

function NPCHotspot:getNPC()
	return self.npc
end

function NPCHotspot:getTeleportWorldPosition()
	if self.npc == nil then
		return nil
	else
		return self.npc:getTeleportWorldPosition()
	end
end

-- Local values: x, _, z
function NPCHotspot:getWorldPosition()
	if self.npc == nil then
		return nil
	end
	local v19_, _, v20_ = self.npc:getTeleportWorldPosition()
	return v19_, v20_
end

-- Local values: icon, a
function NPCHotspot:render(x, y, rotation, small)
	local v25_ = self.icon
	if small then
		v25_ = self.iconSmall
	end
	self.lastRenderedIcon = v25_
	if v25_ ~= nil then
		local v26_ = self.isBlinking and IngameMap.alpha or 1
		v25_:renderCustom(x, y, v25_.width, v25_.height, nil, nil, nil, v26_)
	end
end
NPCHotspot.getWorldRotation = MapHotspot.getWorldRotation
