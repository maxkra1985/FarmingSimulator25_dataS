-- Local values: ShipStatic_mt
ShipStatic = {}
local ShipStatic_mt = Class(ShipStatic, Object)
InitStaticObjectClass(ShipStatic, "ShipStatic")
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = OnCreateObjectSystem.xmlSchemaSavegame
	v2_:register(XMLValueType.BOOL, "onCreateLoadedObjects.object(?)#isVisible", "If ship is visible")
	v2_:register(XMLValueType.BOOL, "onCreateLoadedObjects.object(?)#isSwitchPending", "If ship visibilit switch is pending")
	v2_:register(XMLValueType.INT, "onCreateLoadedObjects.object(?)#nextChangeHour", "Next switching hour")
end)

-- Local values: ship
function ShipStatic:onCreate(node)
	local v4_ = ShipStatic.new(g_server ~= nil, g_client ~= nil)
	if v4_:load(node) then
		v4_:register(true)
	else
		v4_:delete()
	end
end

-- Upvalues: ShipStatic_mt
-- Local values: self
function ShipStatic.new(isServer, isClient, customMt)
	-- upvalues: (copy) ShipStatic_mt
	return Object.new(isServer, isClient, customMt or ShipStatic_mt)
end

function ShipStatic:load(node)
	self.rootNode = node
	self.isVisible = true
	self.nextChangeHour = math.random(0, 23)
	self.isSwitchPending = false
	self.saveId = getName(node)
	if self.isServer then
		self.dirtyFlag = self:getNextDirtyFlag()
		g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
	end
	g_currentMission.onCreateObjectSystem:add(self, true)
	return true
end

function ShipStatic:delete()
	g_messageCenter:unsubscribeAll(self)
	ShipStatic:superClass().delete(self)
end

function ShipStatic:loadFromXMLFile(xmlFile, key)
	self.isVisible = xmlFile:getValue(key .. "#isVisible", self.isVisible)
	self.isSwitchPending = xmlFile:getValue(key .. "#isSwitchPending", self.isSwitchPending)
	self.nextChangeHour = xmlFile:getValue(key .. "#nextChangeHour", self.nextChangeHour)
	self:setVisibility(self.isVisible)
	if self.isSwitchPending then
		self:raiseActive()
	end
	return true
end

function ShipStatic:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setValue(key .. "#isVisible", self.isVisible)
	xmlFile:setValue(key .. "#isSwitchPending", self.isSwitchPending)
	xmlFile:setValue(key .. "#nextChangeHour", self.nextChangeHour)
end

function ShipStatic:setVisibility(isVisible)
	self.isVisible = isVisible
	setVisibility(self.rootNode, isVisible)
	if isVisible then
		addToPhysics(self.rootNode)
	else
		removeFromPhysics(self.rootNode)
	end
end

function ShipStatic:readStream(streamId, connection, objectId)
	if connection:getIsServer() then
		self:setVisibility(streamReadBool(streamId))
	end
end

function ShipStatic:writeStream(streamId, connection)
	if not connection:getIsServer() then
		streamWriteBool(streamId, self.isVisible)
	end
end

function ShipStatic:readUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		self:setVisibility(streamReadBool(streamId))
	end
end

function ShipStatic:writeUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		streamWriteBool(streamId, self.isVisible)
	end
end

-- Local values: x, y, z, clipDistance, isInRange, _, streamId, cx, cy, cz, distance
function ShipStatic:updateTick(dt)
	if self.isServer and self.isSwitchPending then
		local v32_, v33_, v34_ = getWorldTranslation(self.rootNode)
		local v35_ = getEffectiveClipDistancesWithLOD(self.rootNode)
		local v36_ = false
		for _, v37_ in ipairs(g_server.clients) do
			local v38_, v39_, v40_ = g_server:getClientPosition(v37_)
			if MathUtil.vector3Length(v32_ - v38_, v33_ - v39_, v34_ - v40_) < v35_ then
				v36_ = true
				break
			end
		end
		if not v36_ then
			self:setVisibility(not self.isVisible)
			self:raiseDirtyFlags(self.dirtyFlag)
			self.isSwitchPending = false
			return
		end
		self:raiseActive()
	end
end

function ShipStatic:onHourChanged(currentHour)
	if self.isServer and self.nextChangeHour == currentHour then
		self.isSwitchPending = true
		self.nextChangeHour = (self.nextChangeHour + math.random(5, 23)) % 23
		self:raiseActive()
	end
end
