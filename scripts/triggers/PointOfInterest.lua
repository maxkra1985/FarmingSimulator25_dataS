-- Local values: PointOfInterest_mt
PointOfInterest = {}
local PointOfInterest_mt = Class(PointOfInterest)

function PointOfInterest.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#triggerNode", "Trigger node")
	schema:register(XMLValueType.STRING, basePath .. "#text", "POI text")
	schema:register(XMLValueType.STRING, basePath .. "#textFormat", "POI text additional format string")
	schema:register(XMLValueType.STRING, basePath .. "#textParams", "POI text format parameters")
	schema:register(XMLValueType.BOOL, basePath .. "#showOwner", "Show only for owners")
	schema:register(XMLValueType.BOOL, basePath .. "#showEveryone", "Show everyone")
end

-- Local values: poi
function PointOfInterest:onCreate(id)
	local v5_ = PointOfInterest:new()
	if v5_:loadFromNode(id) then
		g_currentMission:addNonUpdateable(v5_)
	else
		v5_:delete()
	end
end

-- Upvalues: PointOfInterest_mt
-- Local values: self
function PointOfInterest.new(placeable, customEnv, customMt)
	-- upvalues: (copy) PointOfInterest_mt
	local v9_ = customMt or PointOfInterest_mt
	local v10_ = setmetatable({}, v9_)
	v10_.placeable = placeable
	v10_.infoText = nil
	v10_.isEnabled = true
	v10_.customEnv = customEnv
	v10_.isPlayerInRange = false
	v10_.showOwner = true
	v10_.showEveryone = true
	v10_.vehicleNodesInRange = {}
	v10_.ownerFarmId = nil
	return v10_
end

-- Local values: text, formatStr, params
function PointOfInterest:load(components, xmlFile, key, customEnv, i3dMappings, rootNode)
	self.node = xmlFile:getValue(key .. "#triggerNode", nil, components, i3dMappings)
	CollisionFlag.setMaskFlag(self.node, CollisionFlag.PLAYER)
	CollisionFlag.setMaskFlag(self.node, CollisionFlag.VEHICLE)
	if self.node == nil then
		Logging.devWarning("Missing node for PointOfInterest \'%s\'", key)
		return false
	end
	local v16_ = xmlFile:getValue(key .. "#text")
	if v16_ == nil then
		Logging.xmlWarning(xmlFile, "Missing text for PointOfInterest \'%s\' (node \'%s\')", key, getName(self.node))
		return false
	end
	self.infoText = g_i18n:convertText(v16_, self.customEnv)
	local v17_ = xmlFile:getValue(key .. "#textFormat")
	local v18_ = xmlFile:getValue(key .. "#textParams")
	if v18_ ~= nil then
		if v17_ == nil then
			self.infoText = g_i18n:insertTextParams(self.infoText, v18_, self.customEnv, xmlFile)
		else
			local v19_ = g_i18n:insertTextParams(v17_, v18_, self.customEnv, xmlFile)
			self.infoText = string.format(self.infoText, v19_)
		end
	end
	self.showOwner = xmlFile:getValue(key .. "#showOwner", self.showOwner)
	self.showEveryone = xmlFile:getValue(key .. "#showEveryone", self.showEveryone)
	self:finalize()
	return true
end

-- Local values: text
function PointOfInterest:loadFromNode(node)
	self.node = node
	PointOfInterest.checkCollisionMask(node, nil)
	local v22_ = getUserAttribute(node, "text")
	self.showOwner = getUserAttribute(node, "showOwner") == "true"
	self.showEveryone = getUserAttribute(node, "showEveryone") == "true"
	if v22_ == nil then
		Logging.devWarning("Missing text for PointOfInterest \'%s\'", getName(self.node))
		return false
	end
	self.infoText = g_i18n:convertText(v22_, self.customEnv)
	self:finalize()
	return true
end

function PointOfInterest:finalize()
	if g_currentMission:getIsClient() then
		self.callbackId = addTrigger(self.node, "PointOfInterest:triggerCallback", self, false, self.triggerCallback)
	end
end

function PointOfInterest:delete()
	if self.callbackId ~= nil then
		removeTrigger(self.node, self.callbackId)
		self.callbackId = nil
	end
	g_currentMission:removeDrawable(self)
end

-- Local values: needsDrawing, farmId, node, _, vehicle
function PointOfInterest:getNeedsDrawing()
	if not g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_TRIGGER) or (not self.isEnabled or self.infoText == nil) then
		return false
	end
	local v26_ = self.isPlayerInRange
	local v27_ = g_currentMission:getFarmId()
	if not v26_ then
		for v28_, _ in pairs(self.vehicleNodesInRange) do
			if entityExists(v28_) then
				local v29_ = g_currentMission:getNodeObject(v28_)
				if v29_ ~= nil and v29_ == g_localPlayer:getCurrentVehicle() then
					v27_ = v29_:getOwnerFarmId()
					v26_ = true
				end
			else
				self.vehicleNodesInRange[v28_] = nil
			end
		end
	end
	if v26_ then
		if self.ownerFarmId == AccessHandler.EVERYONE then
			if not self.showEveryone then
				return false
			end
		elseif self.ownerFarmId == v27_ then
			if not self.showOwner then
				return false
			end
		else
			v26_ = false
		end
	end
	return v26_
end

function PointOfInterest:draw()
	if self:getNeedsDrawing() then
		g_currentMission.hud:setPOIInfoText(self.infoText)
	end
end

-- Local values: changed
function PointOfInterest:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if onEnter or onLeave then
		local v35_
		if g_localPlayer == nil or otherId ~= g_localPlayer.rootNode then
			if onEnter then
				self.vehicleNodesInRange[otherId] = true
				v35_ = true
			else
				self.vehicleNodesInRange[otherId] = nil
				v35_ = true
			end
		elseif onEnter then
			self.isPlayerInRange = true
			v35_ = true
		else
			self.isPlayerInRange = false
			v35_ = true
		end
		if v35_ then
			if self.isPlayerInRange or next(self.vehicleNodesInRange) ~= nil then
				g_currentMission:addDrawable(self)
				return
			end
			g_currentMission:removeDrawable(self)
		end
	end
end

function PointOfInterest:setOwnerFarmId(farmId)
	self.ownerFarmId = farmId
end
