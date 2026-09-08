-- Local values: RailroadCaller_mt, RailroadCallerActivatable_mt
RailroadCaller = {}

function RailroadCaller.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#triggerNode", "Trigger node")
end
local v_u_3_ = Class(RailroadCaller)

-- Upvalues: RailroadCaller_mt
-- Local values: self
function RailroadCaller.new(isServer, isClient, trainSystem, nodeId, customMt)
	-- upvalues: (copy) v_u_3_
	local v9_ = customMt or v_u_3_
	local v10_ = setmetatable({}, v9_)
	v10_.trainSystem = trainSystem
	v10_.nodeId = nodeId
	v10_.isServer = isServer
	v10_.isClient = isClient
	v10_.activatable = RailroadCallerActivatable.new(v10_)
	return v10_
end

function RailroadCaller:loadFromXML(xmlFile, key, components, i3dMappings)
	self.triggerNode = xmlFile:getValue(key .. "#triggerNode", nil, components, i3dMappings)
	self.rootNode = self.triggerNode
	if self.triggerNode ~= nil then
		addTrigger(self.triggerNode, "railroadCallerTriggerCallback", self)
		return true
	end
	Logging.xmlWarning(xmlFile, "Missing trigger \'triggerNode\' for railroadCaller \'%s\'!", key)
	delete(xmlFile)
	return false
end

function RailroadCaller:delete()
	if self.triggerNode ~= nil then
		g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
		removeTrigger(self.triggerNode)
		self.triggerNode = nil
	end
end

function RailroadCaller:setSplineTimeByPosition(t, splineLength)
	self.splinePositionTime = SplineUtil.getValidSplineTime(t)
end

function RailroadCaller:railroadCallerTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if self.trainSystem ~= nil and (g_currentMission.missionInfo:isa(FSCareerMissionInfo) and (onEnter or onLeave)) and (g_localPlayer ~= nil and otherActorId == g_localPlayer.rootNode) then
		if onEnter then
			g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
			return
		end
		g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
	end
end

function RailroadCaller:callRailroad()
	if g_localPlayer.farmId == FarmManager.SPECTATOR_FARM_ID or not g_currentMission:getHasPlayerPermission(Farm.PERMISSION.BUY_VEHICLE) then
		InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.BUY_VEHICLE_NO_PERMISSION))
	elseif self.trainSystem ~= nil then
		self.trainSystem:toggleRent(g_localPlayer.farmId, self.splinePositionTime)
		return
	end
end
RailroadCallerActivatable = {}
local v_u_24_ = Class(RailroadCallerActivatable)
function RailroadCallerActivatable.new(p25_)
	-- upvalues: (copy) v_u_24_
	local v26_ = v_u_24_
	local v27_ = setmetatable({}, v26_)
	v27_.railroadCaller = p25_
	v27_.trainSystem = p25_.trainSystem
	v27_.activateTextRent = g_i18n:getText("action_rentTrain")
	v27_.activateTextWait = g_i18n:getText("action_waitForRentedTrain")
	v27_.activateTextGiveBack = g_i18n:getText("action_returnRentedTrain")
	v27_.activateText = v27_.activateTextRent
	return v27_
end

function RailroadCallerActivatable:getIsActivatable()
	if self.trainSystem:getCanBeRented(g_localPlayer.farmId) then
		return not g_localPlayer:getIsInVehicle()
	else
		return false
	end
end

function RailroadCallerActivatable:run()
	self.railroadCaller:callRailroad()
end

function RailroadCallerActivatable:activate()
	g_currentMission:addDrawable(self)
end

function RailroadCallerActivatable:deactivate()
	g_currentMission:removeDrawable(self)
end

-- Local values: spec, distance, distanceStr
function RailroadCallerActivatable:draw()
	local v33_ = self.trainSystem.spec_trainSystem
	if v33_.isRented then
		self.activateText = self.activateTextGiveBack
		if v33_.rootLocomotive ~= nil then
			local v34_ = v33_.rootLocomotive:getDistanceToRequestedPosition()
			if v34_ > 0 then
				local v35_ = string.format("%.1fkm", v34_ / 1000)
				if v34_ < 1000 then
					v35_ = string.format("%dm", v34_)
				end
				g_currentMission:addExtraPrintText(string.format(self.activateTextWait, v35_))
				return
			end
		end
	else
		self.activateText = string.format(self.activateTextRent, g_i18n:formatMoney(v33_.rentPricePerHour, 0, true, true))
	end
end

-- Local values: tx, ty, tz
function RailroadCallerActivatable:getDistance(x, y, z)
	if self.railroadCaller.triggerNode == nil then
		return math.huge
	end
	local v40_, v41_, v42_ = getWorldTranslation(self.railroadCaller.triggerNode)
	return MathUtil.vector3Length(x - v40_, y - v41_, z - v42_)
end
