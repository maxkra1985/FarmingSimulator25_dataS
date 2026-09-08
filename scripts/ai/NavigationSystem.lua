-- Local values: NavigationSystem_mt
NavigationSystem = {}
local NavigationSystem_mt = Class(NavigationSystem)
g_xmlManager:addCreateSchemaFunction(function()
	NavigationSystem.xmlSchema = XMLSchema.new("savegame_navigationSystem")
end)
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = NavigationSystem.xmlSchema
	v2_:register(XMLValueType.VECTOR_TRANS, "navigationSystem.target#position", "Target position of the navigation", nil, false)
	v2_:register(XMLValueType.VECTOR_3, "navigationSystem.target#direction", "Target direction of the navigation", nil, false)
end)

-- Upvalues: NavigationSystem_mt
-- Local values: self
function NavigationSystem.new(customMt)
	-- upvalues: (copy) NavigationSystem_mt
	local v4_ = customMt or NavigationSystem_mt
	local v5_ = setmetatable({}, v4_)
	v5_.navigationMarker = NavigationMarker.new()
	v5_.positionNode = nil
	v5_.directionNode = nil
	return v5_
end

-- Local values: filepath
function NavigationSystem:loadMapData(xmlFile, missionInfo, baseDirectory)
	local v8_ = Utils.getFilename("$data/shared/assets/marker/navigationMarker.i3d", baseDirectory)
	self.loadRequestId = g_i3DManager:loadI3DFileAsync(v8_, true, true, self.onNavigationMarkerLoaded, self, nil)
	return true
end

function NavigationSystem:onNavigationMarkerLoaded(i3dNode, failedReason, args)
	if failedReason == LoadI3DFailedReason.NONE then
		self.positionNode = getChildAt(i3dNode, 0)
		self.directionNode = getChildAt(self.positionNode, 0)
		setVisibility(self.positionNode, false)
		setVisibility(self.directionNode, false)
		link(getRootNode(), self.positionNode)
		self:updateMarker()
		delete(i3dNode)
	end
	self.loadRequestId = nil
end

function NavigationSystem:delete()
	if self.loadRequestId ~= nil then
		g_i3DManager:cancelStreamI3DFile(self.loadRequestId)
		self.loadRequestId = nil
	end
	if self.positionNode ~= nil then
		delete(self.positionNode)
		self.positionNode = nil
	end
	if self.navigationMarker ~= nil then
		self.navigationMarker:delete()
		self.navigationMarker = nil
	end
end

-- Local values: xmlFile
function NavigationSystem:saveToXMLFile(xmlFilename)
	local v15_ = XMLFile.create("navigationSystem", xmlFilename, "navigationSystem", NavigationSystem.xmlSchema)
	if self.targetX ~= nil then
		v15_:setValue("navigationSystem.target#position", self.targetX, self.targetY, self.targetZ)
		if self.targetDirX ~= nil then
			v15_:setValue("navigationSystem.target#direction", self.targetDirX, self.targetDirY, self.targetDirZ)
		end
	end
	v15_:save()
	v15_:delete()
end

-- Local values: isActive, isActiveDir
function NavigationSystem:updateMarker()
	local v17_ = self.targetX ~= nil
	local v18_ = self.targetDirX ~= nil
	if self.navigationMarker ~= nil then
		self.navigationMarker:setVisibility(v17_)
	end
	if self.positionNode ~= nil then
		setVisibility(self.positionNode, v17_)
		setVisibility(self.directionNode, v18_)
		setWorldTranslation(self.positionNode, self.targetX or 0, self.targetY or 0, self.targetZ or 0)
		if self.targetDirX ~= nil then
			setVisibility(self.directionNode, true)
			setWorldDirection(self.directionNode, self.targetDirX, self.targetDirY, self.targetDirZ, 0, 1, 0)
		end
	end
end

function NavigationSystem:draw()
	self.navigationMarker:render()
end

function NavigationSystem:navigateTo(x, y, z, dirX, dirY, dirZ)
	self.navigationMarker:setWorldPosition(x, y + 1.4, z)
	self.navigationMarker:setVisibility(true)
	self.targetX = x
	self.targetY = y
	self.targetZ = z
	self.targetDirX = dirX
	self.targetDirY = dirY
	self.targetDirZ = dirZ
	g_currentMission:addDrawable(self)
	self:updateMarker()
end

function NavigationSystem:stop()
	self.targetX = nil
	self.targetY = nil
	self.targetZ = nil
	self.targetDirX = nil
	self.targetDirY = nil
	self.targetDirZ = nil
	g_currentMission:removeDrawable(self)
	self:updateMarker()
end
