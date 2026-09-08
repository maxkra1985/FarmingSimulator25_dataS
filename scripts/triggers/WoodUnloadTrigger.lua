-- Local values: WoodUnloadTrigger_mt
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

-- Upvalues: WoodUnloadTrigger_mt
-- Local values: self
function WoodUnloadTrigger.new(isServer, isClient, customMt)
	-- upvalues: (copy) WoodUnloadTrigger_mt
	local v7_ = UnloadTrigger.new(isServer, isClient, customMt or WoodUnloadTrigger_mt)
	v7_.triggerNode = nil
	v7_.woodInTrigger = {}
	v7_.vehiclesInTrigger = {}
	v7_.lastSplitShapeVolume = 0
	v7_.lastSplitType = nil
	v7_.lastSplitShapeStats = {
		["sizeX"] = 0,
		["sizeY"] = 0,
		["sizeZ"] = 0,
		["numConvexes"] = 0,
		["numAttachments"] = 0
	}
	v7_.extraAttributes = {
		["price"] = 1
	}
	return v7_
end

-- Local values: triggerNodeKey, colMask, activationTrigger
function WoodUnloadTrigger:load(components, xmlFile, xmlNode, target, extraAttributes, i3dMappings)
	if not WoodUnloadTrigger:superClass().load(self, components, xmlFile, xmlNode, target, extraAttributes, i3dMappings) then
		return false
	end
	local v15_ = xmlNode .. "#triggerNode"
	self.triggerNode = xmlFile:getValue(v15_, nil, components, i3dMappings)
	if self.triggerNode == nil then
		return false
	end
	local v16_ = getCollisionFilterMask(self.triggerNode)
	local v17_ = CollisionFlag.TREE
	if bit32.band(v17_, v16_) == 0 then
		Logging.xmlWarning(xmlFile, "Invalid collision filter mask for wood trigger \'%s\'. %s needs to be set!", v15_, CollisionFlag.getBitAndName(CollisionFlag.TREE))
		return false
	end
	addTrigger(self.triggerNode, "woodTriggerCallback", self)
	local v18_ = xmlFile:getValue(xmlNode .. "#activationTriggerNode", nil, components, i3dMappings)
	if v18_ ~= nil then
		if not CollisionFlag.getHasMaskFlagSet(v18_, CollisionFlag.PLAYER) then
			Logging.xmlWarning(xmlFile, "Missing collision filter mask \'%s\'. Please add this bit to sell trigger node \'%s\' in \'placeable.woodSellingStation#sellTrigger\'.", CollisionFlag.getBitAndName(CollisionFlag.PLAYER), getName(v18_))
			return false
		end
		self.activationTrigger = v18_
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

-- Local values: mission
function WoodUnloadTrigger:delete()
	if self.triggerNode ~= nil and self.triggerNode ~= 0 then
		removeTrigger(self.triggerNode)
		self.triggerNode = 0
	end
	if self.activationTrigger ~= nil then
		g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
		removeTrigger(self.activationTrigger)
		self.activationTrigger = nil
	end
	WoodUnloadTrigger:superClass().delete(self)
end

-- Local values: soldWood, totalMass, isFull, mission, isServer, _, nodeId, volume, qualityScale, maxSize, fillType, treeObject
function WoodUnloadTrigger:processWood(farmId, noEventSend)
	if not self.isServer then
		g_client:getServerConnection():sendEvent(WoodUnloadTriggerEvent.new(self, farmId))
		return
	end
	local v22_ = g_currentMission
	local v23_ = v22_:getIsServer()
	local v24_ = false
	local v25_ = false
	for _, v26_ in pairs(self.woodInTrigger) do
		if self:getCanProcessWood() then
			if entityExists(v26_) then
				v25_ = true
				local v27_, v28_, v29_ = self:calculateWoodBaseValue(v26_)
				self.extraAttributes.price = v28_
				self.extraAttributes.maxSize = v29_
				if v23_ then
					local v30_ = self:getTargetFillType(v29_, v27_)
					if self.getFillUnitFreeCapacity == nil or self:getFillUnitFreeCapacity(nil, v30_, farmId) > v27_ * 0.9 then
						self:addFillUnitFillLevel(farmId, nil, v27_, v30_, ToolType.undefined, nil, self.extraAttributes)
						self:onProcessedWood(v26_, v27_, v30_)
						local v31_ = v22_:getNodeObject(v26_)
						if v31_ == nil then
							delete(v26_)
						else
							v31_:delete()
						end
					else
						v24_ = true
					end
				end
			end
			if v24_ then
				break
			end
			self.woodInTrigger[v26_] = nil
		end
	end
	if v25_ and v23_ then
		g_farmManager:updateFarmStats(g_localPlayer.farmId, "woodTonsSold", 0)
	end
end

function WoodUnloadTrigger:getTargetFillType(maxSize, volume)
	return FillType.WOOD
end

function WoodUnloadTrigger:getCanProcessWood()
	return true
end

-- Local values: mission
function WoodUnloadTrigger:onProcessedWood(nodeId, volume, fillType)
	if nodeId ~= nil and nodeId ~= 0 then
		local v36_ = g_missionManager:getMissionBySplitShape(nodeId)
		if v36_ ~= nil and v36_.onTriggerProcessedWood ~= nil then
			v36_:onTriggerProcessedWood(self, nodeId, volume, fillType)
		end
	end
end

-- Local values: volume, splitType, sizeX, sizeY, sizeZ, numConvexes, numAttachments
function WoodUnloadTrigger:calculateWoodBaseValue(objectId)
	local v39_ = getVolume(objectId)
	local v40_ = g_splitShapeManager:getSplitTypeByIndex(getSplitType(objectId))
	local v41_, v42_, v43_, v44_, v45_ = getSplitShapeStats(objectId)
	return self:calculateWoodBaseValueForData(v39_, v40_, v41_, v42_, v43_, v44_, v45_)
end

-- Local values: qualityScale, lengthScale, defoliageScale, maxSize, bvVolume, volumeRatio, volumeQuality, convexityQuality, minQuality, maxQuality, numDifficulties, mission, missionInfo
function WoodUnloadTrigger:calculateWoodBaseValueForData(volume, splitType, sizeX, sizeY, sizeZ, numConvexes, numAttachments)
	local v53_, v54_, v55_, v56_
	if sizeX == nil or volume <= 0 then
		v53_ = 1
		v54_ = 1
		v55_ = 1
		v56_ = 0
	else
		local v57_ = (sizeX * sizeY * sizeZ / volume - 3) / 7
		local v58_ = math.clamp(v57_, 0, 1)
		local v59_ = 1 - math.sqrt(v58_) * 0.95
		local v60_ = (numConvexes - 2) / 4
		local v61_ = 1 - math.clamp(v60_, 0, 1) * 0.95
		v56_ = math.max(sizeX, sizeY, sizeZ)
		if v56_ < 11 then
			local v62_ = (v56_ - 1) / 5
			local v63_ = math.max(v62_, 0)
			v55_ = 0.6 + math.min(v63_, 1) * 0.6
		else
			local v64_ = (v56_ - 11) / 8
			local v65_ = math.max(v64_, 0)
			v55_ = 1.2 - math.min(v65_, 1) * 0.6
		end
		local v66_ = math.min(v61_, v59_)
		v53_ = v66_ + (math.max(v61_, v59_) - v66_) * 0.3
		local v67_ = numAttachments / 15
		v54_ = 1 - math.min(v67_, 1) * 0.8
	end
	local v68_ = #EconomicDifficulty.getAllOrdered()
	local v69_ = g_currentMission.missionInfo
	local v70_ = MathUtil.lerp(1, v53_, v69_.economicDifficulty / v68_)
	local v71_ = MathUtil.lerp(1, v54_, v69_.economicDifficulty / v68_)
	return volume * splitType.volumeToLiter, splitType.pricePerLiter * v70_ * v71_ * v55_, v56_
end

-- Local values: farmId, mission, placeable, vehicleNodeId, vehicle
function WoodUnloadTrigger:update(dt)
	WoodUnloadTrigger:superClass().update(self, dt)
	if self.isServer then
		local v74_ = self.target:getOwnerFarmId()
		local v75_ = g_currentMission
		if self.trainSystemId == nil then
			if self.autoUnload then
				local v76_ = next(self.vehiclesInTrigger)
				if v76_ ~= nil then
					local v77_ = v75_:getNodeObject(v76_)
					if v77_ == nil then
						self.vehiclesInTrigger[v76_] = nil
					else
						v74_ = v77_:getOwnerFarmId()
					end
				end
			end
		else
			if self.trainSystem == nil then
				local v78_ = v75_.placeableSystem:getPlaceableByUniqueId(self.trainSystemId)
				if v78_ ~= nil and v78_.spec_trainSystem ~= nil then
					self.trainSystem = v78_
				end
			end
			if self.trainSystem ~= nil then
				v74_ = self.trainSystem.spec_trainSystem.lastRentFarmId
			end
		end
		if v74_ ~= FarmManager.SPECTATOR_FARM_ID then
			self:processWood(v74_)
		end
	end
end

-- Local values: splitType, mission, object
function WoodUnloadTrigger:woodTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if otherId ~= 0 then
		local v82_
		if getHasClassId(otherId, ClassIds.MESH_SPLIT_SHAPE) then
			v82_ = g_splitShapeManager:getSplitTypeByIndex(getSplitType(otherId))
		else
			v82_ = nil
		end
		if v82_ == nil or v82_.pricePerLiter <= 0 then
			if self.autoUnload then
				local v83_ = g_currentMission:getNodeObject(otherId)
				if v83_ ~= nil and v83_:isa(Vehicle) then
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
		else
			if not onEnter then
				self.woodInTrigger[otherId] = nil
				return
			end
			self.woodInTrigger[otherId] = otherId
			if self:getNeedRaiseActive() then
				self:raiseActive()
				return
			end
		end
	end
end

function WoodUnloadTrigger:getNeedRaiseActive()
	return self.trainSystemId ~= nil and true or self.autoUnload
end

function WoodUnloadTrigger:getWoodLogs()
	return self.woodInTrigger
end

-- Local values: mission
function WoodUnloadTrigger:woodSellTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if (onEnter or onLeave) and (g_localPlayer ~= nil and otherActorId == g_localPlayer.rootNode) then
		local v90_ = g_currentMission
		if onEnter then
			if self.isManualSellingActive then
				v90_.activatableObjectsSystem:addActivatable(self.activatable)
				return
			end
		else
			v90_.activatableObjectsSystem:removeActivatable(self.activatable)
		end
	end
end
