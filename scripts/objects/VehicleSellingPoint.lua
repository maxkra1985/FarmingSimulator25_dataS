-- Local values: VehicleSellingPoint_mt, VehicleSellingPointActivatable_mt
VehicleSellingPoint = {}
local VehicleSellingPoint_mt = Class(VehicleSellingPoint)

function VehicleSellingPoint.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#playerTriggerNode", "Player trigger node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#iconNode", "Icon node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#sellTriggerNode", "Sell trigger node")
	schema:register(XMLValueType.BOOL, basePath .. "#ownWorkshop", "Owned by player", false)
	schema:register(XMLValueType.BOOL, basePath .. "#mobileWorkshop", "Workshop is on vehicle", false)
end
function VehicleSellingPoint.new()
	-- upvalues: (copy) VehicleSellingPoint_mt
	local v4_ = VehicleSellingPoint_mt
	local v5_ = setmetatable({}, v4_)
	v5_.vehicleShapesInRange = {}
	v5_.activateText = ""
	v5_.isEnabled = true
	return v5_
end

function VehicleSellingPoint:load(components, xmlFile, key, i3dMappings)
	self.playerTrigger = xmlFile:getValue(key .. "#playerTriggerNode", nil, components, i3dMappings)
	self.sellIcon = xmlFile:getValue(key .. "#iconNode", nil, components, i3dMappings)
	self.sellTriggerNode = xmlFile:getValue(key .. "#sellTriggerNode", nil, components, i3dMappings)
	self.ownWorkshop = xmlFile:getValue(key .. "#ownWorkshop", false)
	self.mobileWorkshop = xmlFile:getValue(key .. "#mobileWorkshop", false)
	if not CollisionFlag.getHasMaskFlagSet(self.playerTrigger, CollisionFlag.PLAYER) then
		Logging.xmlWarning(xmlFile, "Missing collision mask bit \'%d\'. Please add this bit to vehicle selling player trigger node \'%s\'", CollisionFlag.getBit(CollisionFlag.PLAYER), I3DUtil.getNodePath(self.playerTrigger))
	end
	addTrigger(self.playerTrigger, "triggerCallback", self)
	if not CollisionFlag.getHasMaskFlagSet(self.sellTriggerNode, CollisionFlag.VEHICLE) then
		Logging.xmlWarning(xmlFile, "Missing collision mask bit \'%d\'. Please add this bit to vehicle sell area trigger node \'%s\'", CollisionFlag.getBit(CollisionFlag.VEHICLE), I3DUtil.getNodePath(self.sellTriggerNode))
	end
	addTrigger(self.sellTriggerNode, "sellAreaTriggerCallback", self)
	self.activatable = VehicleSellingPointActivatable.new(self, self.ownWorkshop)
	g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.playerFarmChanged, self)
	g_messageCenter:subscribe(MessageType.PLAYER_CREATED, self.playerFarmChanged, self)
	self:updateIconVisibility()
end

function VehicleSellingPoint:delete()
	g_messageCenter:unsubscribeAll(self)
	if self.playerTrigger ~= nil then
		removeTrigger(self.playerTrigger)
		self.playerTrigger = nil
	end
	if self.sellTriggerNode ~= nil then
		removeTrigger(self.sellTriggerNode)
		self.sellTriggerNode = nil
	end
	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
	self.sellIcon = nil
end

-- Local values: vehicles
function VehicleSellingPoint:openMenu()
	local v13_ = self:determineCurrentVehicles()
	g_workshopScreen:setSellingPoint(self, not self.ownWorkshop, self.ownWorkshop, self.mobileWorkshop)
	g_workshopScreen:setVehicles(v13_)
	g_gui:showGui("WorkshopScreen")
end

function VehicleSellingPoint:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if self.isEnabled and (g_currentMission.missionInfo:isa(FSCareerMissionInfo) and (onEnter or onLeave)) and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
		if onEnter then
			g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
			return
		end
		g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
		self:determineCurrentVehicles()
	end
end

function VehicleSellingPoint:sellAreaTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if otherShapeId ~= nil and (onEnter or onLeave) then
		if onEnter then
			self.vehicleShapesInRange[otherShapeId] = true
		elseif onLeave then
			self.vehicleShapesInRange[otherShapeId] = nil
		end
		g_workshopScreen:updateVehicles(self, self:determineCurrentVehicles())
	end
end

-- Local values: vehicles, playerFarmId, shapeId, inRange, vehicle, subVehicles, _, subVehicle
function VehicleSellingPoint:determineCurrentVehicles()
	local v23_ = {}
	local v24_ = g_currentMission:getFarmId()
	if v24_ ~= FarmManager.SPECTATOR_FARM_ID then
		for v25_, v26_ in pairs(self.vehicleShapesInRange) do
			if v26_ == nil or not entityExists(v25_) then
				self.vehicleShapesInRange[v25_] = nil
			else
				local v27_ = g_currentMission.nodeToObject[v25_]
				if v27_ ~= nil and v27_:isa(Vehicle) then
					local v28_ = v27_.rootVehicle:getChildVehicles()
					for _, v29_ in ipairs(v28_) do
						if v29_:getShowInVehiclesOverview() and v29_:getOwnerFarmId() == v24_ then
							table.addElement(v23_, v29_)
						end
					end
				end
			end
		end
		table.sort(v23_, function(p30_, p31_)
			return p30_.rootNode < p31_.rootNode
		end)
	end
	return v23_
end

-- Local values: isAvailable, farmId, visibleForFarm
function VehicleSellingPoint:updateIconVisibility()
	if self.sellIcon ~= nil then
		local v33_ = self.isEnabled
		if v33_ then
			v33_ = g_currentMission.missionInfo:isa(FSCareerMissionInfo)
		end
		local v34_ = g_currentMission:getFarmId()
		local v35_
		if v34_ == FarmManager.SPECTATOR_FARM_ID then
			v35_ = false
		else
			v35_ = self:getOwnerFarmId() == AccessHandler.EVERYONE and true or v34_ == self:getOwnerFarmId()
		end
		setVisibility(self.sellIcon, v33_ and v35_)
	end
end

function VehicleSellingPoint:playerFarmChanged(player)
	if player == g_localPlayer then
		self:updateIconVisibility()
	end
end

function VehicleSellingPoint:setOwnerFarmId(ownerFarmId)
	self.ownerFarmId = ownerFarmId
	self:updateIconVisibility()
end

function VehicleSellingPoint:getOwnerFarmId()
	return self.ownerFarmId
end
VehicleSellingPointActivatable = {}
local v_u_41_ = Class(VehicleSellingPointActivatable)
function VehicleSellingPointActivatable.new(p42_, p43_)
	-- upvalues: (copy) v_u_41_
	local v44_ = v_u_41_
	local v45_ = setmetatable({}, v44_)
	v45_.sellingPoint = p42_
	if p43_ then
		v45_.activateText = g_i18n:getText("action_openWorkshopOptions")
		return v45_
	else
		v45_.activateText = g_i18n:getText("action_openDealerOptions")
		return v45_
	end
end

-- Local values: farmId, isSpectator
function VehicleSellingPointActivatable:getIsActivatable()
	if self.sellingPoint.isEnabled then
		if g_localPlayer:getIsInVehicle() then
			return false
		else
			local v47_ = g_currentMission:getFarmId()
			if v47_ == FarmManager.SPECTATOR_FARM_ID then
				return false
			else
				return self.sellingPoint:getOwnerFarmId() == AccessHandler.EVERYONE and true or v47_ == self.sellingPoint:getOwnerFarmId()
			end
		end
	else
		return false
	end
end

function VehicleSellingPointActivatable:run()
	if g_guidedTourManager:getIsTourRunning() then
		InfoDialog.show(g_i18n:getText("guidedTour_feature_deactivated"))
	else
		self.sellingPoint:openMenu()
	end
end

-- Local values: tx, _, tz
function VehicleSellingPointActivatable:getDistance(x, y, z)
	local v52_, _, v53_ = getWorldTranslation(self.sellingPoint.playerTrigger)
	return MathUtil.getPointPointDistance(v52_, v53_, x, z)
end
