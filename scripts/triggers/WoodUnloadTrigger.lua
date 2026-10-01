WoodUnloadTrigger = {}
source("dataS/scripts/triggers/WoodUnloadTriggerEvent.lua")
source("dataS/scripts/triggers/WoodUnloadTriggerActivatable.lua")
local WoodUnloadTrigger_mt = Class(WoodUnloadTrigger, UnloadTrigger)
UnloadTrigger.registerCustomTrigger("woodTrigger", WoodUnloadTrigger)
InitStaticObjectClass(WoodUnloadTrigger, "WoodUnloadTrigger")
function WoodUnloadTrigger.registerXMLPaths(schema, basePath)
	UnloadTrigger.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#triggerNode", "Trigger node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#activationTriggerNode", "Activation trigger node for the player")
	schema:register(XMLValueType.BOOL, basePath .. "#autoUnload", "Wood is automatically unloaded", false)
	schema:register(XMLValueType.STRING, basePath .. "#trainSystemId", "Money will be added to the account of the current rental farm id of the train. This attribute is the unique id of the corresponding train system.")
end
function WoodUnloadTrigger.new(isServer, isClient, customMt)
	local self = UnloadTrigger.new(isServer, isClient, customMt or WoodUnloadTrigger_mt)
	self.triggerNode = nil
	self.woodInTrigger = {}
	self.vehiclesInTrigger = {}
	self.lastSplitShapeVolume = 0
	self.lastSplitType = nil
	self.lastSplitShapeStats = { sizeX = 0, sizeY = 0, sizeZ = 0, numConvexes = 0, numAttachments = 0 }
	self.extraAttributes = { price = 1 }
	return self
end
function WoodUnloadTrigger:load(components, xmlFile, xmlNode, target, extraAttributes, i3dMappings)
	if not WoodUnloadTrigger:superClass().load(self, components, xmlFile, xmlNode, target, extraAttributes, i3dMappings) then
		return false
	else
		local triggerNodeKey = xmlNode .. "#triggerNode"
		self.triggerNode = xmlFile:getValue(triggerNodeKey, nil, components, i3dMappings)
		if self.triggerNode ~= nil then
			local colMask = getCollisionFilterMask(self.triggerNode)
			if bit32.band(CollisionFlag.TREE, colMask) == 0 then
				Logging.xmlWarning(xmlFile, "Invalid collision filter mask for wood trigger '%s'. %s needs to be set!", triggerNodeKey, CollisionFlag.getBitAndName(CollisionFlag.TREE))
				return false
			else
				addTrigger(self.triggerNode, "woodTriggerCallback", self)
				local activationTrigger = xmlFile:getValue(xmlNode .. "#activationTriggerNode", nil, components, i3dMappings)
				if activationTrigger ~= nil then
					if not CollisionFlag.getHasMaskFlagSet(activationTrigger, CollisionFlag.PLAYER) then
						Logging.xmlWarning(xmlFile, "Missing collision filter mask '%s'. Please add this bit to sell trigger node '%s' in 'placeable.woodSellingStation#sellTrigger'.", CollisionFlag.getBitAndName(CollisionFlag.PLAYER), getName(activationTrigger))
						return false
					end
					self.activationTrigger = activationTrigger
					if self.activationTrigger ~= nil then
						addTrigger(self.activationTrigger, "woodSellTriggerCallback", self)
					end
				end
				self.autoUnload = xmlFile:getValue(xmlNode .. "#autoUnload", false)
				self.isManualSellingActive = true
				self.trainSystemId = xmlFile:getValue(xmlNode .. "#trainSystemId")
				self.trainSystem = nil
				self.activatable = WoodUnloadTriggerActivatable.new(self)
				return true
			end
		end
		return false
	end
end
function WoodUnloadTrigger:delete()
	if self.triggerNode ~= nil and self.triggerNode ~= 0 then
		removeTrigger(self.triggerNode)
		self.triggerNode = 0
	end
	if self.activationTrigger ~= nil then
		local mission = g_currentMission
		mission.activatableObjectsSystem:removeActivatable(self.activatable)
		removeTrigger(self.activationTrigger)
		self.activationTrigger = nil
	end
	WoodUnloadTrigger:superClass().delete(self)
end
function WoodUnloadTrigger:processWood(farmId, noEventSend)
	if not self.isServer then
		g_client:getServerConnection():sendEvent(WoodUnloadTriggerEvent.new(self, farmId))
	else
		local soldWood = false
		local totalMass = 0
		local isFull = false
		local mission = g_currentMission
		local isServer = mission:getIsServer()
		for _, nodeId in pairs(self.woodInTrigger) do
			if self:getCanProcessWood() then
				if entityExists(nodeId) then
					soldWood = true
					local volume, qualityScale, maxSize = self:calculateWoodBaseValue(nodeId)
					self.extraAttributes.price = qualityScale
					self.extraAttributes.maxSize = maxSize
					if isServer then
						local fillType = self:getTargetFillType(maxSize, volume)
						if self.getFillUnitFreeCapacity == nil or volume * 0.9 < self:getFillUnitFreeCapacity(nil, fillType, farmId) then
							self:addFillUnitFillLevel(farmId, nil, volume, fillType, ToolType.undefined, nil, self.extraAttributes)
							self:onProcessedWood(nodeId, volume, fillType)
							local treeObject = mission:getNodeObject(nodeId)
							if treeObject ~= nil then
								treeObject:delete()
							else
								delete(nodeId)
							end
						else
							isFull = true
						end
					end
				end
				if isFull then
					break
				end
				self.woodInTrigger[nodeId] = nil
			end
		end
		if soldWood and isServer then
			g_farmManager:updateFarmStats(g_localPlayer.farmId, "woodTonsSold", 0)
		end
	end
end
function WoodUnloadTrigger:getTargetFillType(maxSize, volume)
	return FillType.WOOD
end
function WoodUnloadTrigger:getCanProcessWood()
	return true
end
function WoodUnloadTrigger:onProcessedWood(nodeId, volume, fillType)
	if nodeId ~= nil and nodeId ~= 0 then
		local mission = g_missionManager:getMissionBySplitShape(nodeId)
		if mission ~= nil and mission.onTriggerProcessedWood ~= nil then
			mission:onTriggerProcessedWood(self, nodeId, volume, fillType)
		end
	end
end
function WoodUnloadTrigger:calculateWoodBaseValue(objectId)
	local volume = getVolume(objectId)
	local splitType = g_splitShapeManager:getSplitTypeByIndex(getSplitType(objectId))
	local sizeX, sizeY, sizeZ, numConvexes, numAttachments = getSplitShapeStats(objectId)
	return self:calculateWoodBaseValueForData(volume, splitType, sizeX, sizeY, sizeZ, numConvexes, numAttachments)
end
function WoodUnloadTrigger:calculateWoodBaseValueForData(volume, splitType, sizeX, sizeY, sizeZ, numConvexes, numAttachments)
	local qualityScale = 1
	local lengthScale = 1
	local defoliageScale = 1
	local maxSize = 0
	if sizeX ~= nil and 0 < volume then
		local bvVolume = sizeX * sizeY * sizeZ
		local volumeRatio = bvVolume / volume
		local volumeQuality = 1 - math.sqrt(math.clamp((volumeRatio - 3) / 7, 0, 1)) * 0.95
		local convexityQuality = 1 - math.clamp((numConvexes - 2) / 4, 0, 1) * 0.95
		maxSize = math.max(sizeX, sizeY, sizeZ)
		lengthScale = maxSize < 11 and 0.6 + math.min(math.max((maxSize - 1) / 5, 0), 1) * 0.6 or 1.2 - math.min(math.max((maxSize - 11) / 8, 0), 1) * 0.6
		local minQuality = math.min(convexityQuality, volumeQuality)
		local maxQuality = math.max(convexityQuality, volumeQuality)
		qualityScale = minQuality + (maxQuality - minQuality) * 0.3
		defoliageScale = 1 - math.min(numAttachments / 15, 1) * 0.8
	end
	local numDifficulties = #EconomicDifficulty.getAllOrdered()
	local mission = g_currentMission
	local missionInfo = mission.missionInfo
	qualityScale = MathUtil.lerp(1, qualityScale, missionInfo.economicDifficulty / numDifficulties)
	defoliageScale = MathUtil.lerp(1, defoliageScale, missionInfo.economicDifficulty / numDifficulties)
	return volume * splitType.volumeToLiter, splitType.pricePerLiter * qualityScale * defoliageScale * lengthScale, maxSize
end
function WoodUnloadTrigger:update(dt)
	WoodUnloadTrigger:superClass().update(self, dt)
	if self.isServer then
		local farmId = self.target:getOwnerFarmId()
		local mission = g_currentMission
		if self.trainSystemId ~= nil then
			if self.trainSystem == nil then
				local placeable = mission.placeableSystem:getPlaceableByUniqueId(self.trainSystemId)
				if placeable ~= nil and placeable.spec_trainSystem ~= nil then
					self.trainSystem = placeable
				end
			end
			if self.trainSystem ~= nil then
				farmId = self.trainSystem.spec_trainSystem.lastRentFarmId
			end
		elseif self.autoUnload then
			local vehicleNodeId = next(self.vehiclesInTrigger)
			if vehicleNodeId ~= nil then
				local vehicle = mission:getNodeObject(vehicleNodeId)
				if vehicle ~= nil then
					farmId = vehicle:getOwnerFarmId()
				else
					self.vehiclesInTrigger[vehicleNodeId] = nil
				end
			end
		end
		if farmId ~= FarmManager.SPECTATOR_FARM_ID then
			self:processWood(farmId)
		end
	end
end
function WoodUnloadTrigger:woodTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if otherId ~= 0 then
		local splitType = nil
		if getHasClassId(otherId, ClassIds.MESH_SPLIT_SHAPE) then
			splitType = g_splitShapeManager:getSplitTypeByIndex(getSplitType(otherId))
		end
		if splitType ~= nil and 0 < splitType.pricePerLiter then
			if onEnter then
				self.woodInTrigger[otherId] = otherId
				if self:getNeedRaiseActive() then
					self:raiseActive()
					return
				end
			end
			self.woodInTrigger[otherId] = nil
			return
		end
		if self.autoUnload then
			local mission = g_currentMission
			local object = mission:getNodeObject(otherId)
			if object ~= nil and object:isa(Vehicle) then
				if onEnter then
					self.vehiclesInTrigger[otherId] = (self.vehiclesInTrigger[otherId] or 0) + 1
					self:raiseActive()
					return
				end
				self.vehiclesInTrigger[otherId] = (self.vehiclesInTrigger[otherId] or 0) - 1
				if self.vehiclesInTrigger[otherId] <= 0 then
					self.vehiclesInTrigger[otherId] = nil
				end
			end
		end
	end
end
function WoodUnloadTrigger:getNeedRaiseActive()
	local _v2 = true
	if self.trainSystemId == nil then
		_v2 = self.autoUnload
	end
	return _v2
end
function WoodUnloadTrigger:getWoodLogs()
	return self.woodInTrigger
end
function WoodUnloadTrigger:woodSellTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if (onEnter or onLeave) and (g_localPlayer ~= nil and otherActorId == g_localPlayer.rootNode) then
		local mission = g_currentMission
		if onEnter then
			if self.isManualSellingActive then
				mission.activatableObjectsSystem:addActivatable(self.activatable)
			end
		else
			mission.activatableObjectsSystem:removeActivatable(self.activatable)
		end
	end
end
