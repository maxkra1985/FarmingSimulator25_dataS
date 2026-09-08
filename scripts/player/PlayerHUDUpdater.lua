-- Local values: PlayerHUDUpdater_mt
PlayerHUDUpdater = {}
local PlayerHUDUpdater_mt = Class(PlayerHUDUpdater)
function PlayerHUDUpdater.new()
	-- upvalues: (copy) PlayerHUDUpdater_mt
	local v2_ = PlayerHUDUpdater_mt
	local v3_ = setmetatable({}, v2_)
	v3_.object = nil
	v3_.splitShape = nil
	v3_.isBale = false
	v3_.isVehicle = false
	v3_.isPallet = false
	v3_.isSplitShape = false
	v3_.isAnimal = false
	local v4_ = g_currentMission.hud.infoDisplay
	if Platform.isMobile then
		v3_.fieldBox = v4_:createBox(InfoDisplayKeyValueBoxMobile)
		v3_.objectBox = v4_:createBox(InfoDisplayKeyValueBoxMobile)
	else
		v3_.fieldBox = v4_:createBox(InfoDisplayKeyValueBox)
		v3_.objectBox = v4_:createBox(InfoDisplayKeyValueBox)
	end
	v3_.fieldInfo = FieldState.new()
	return v3_
end

-- Local values: infoDisplay
function PlayerHUDUpdater:delete()
	local v6_ = g_currentMission.hud.infoDisplay
	v6_:destroyBox(self.fieldBox)
	v6_:destroyBox(self.objectBox)
end

function PlayerHUDUpdater:update(dt, x, y, z, rotY)
	self:showFieldInfo(x, z, rotY)
	if Platform.playerInfo.showVehicleInfo then
		if self.isVehicle then
			self:showVehicleInfo(self.object)
			return
		end
		if self.isBale then
			self:showBaleInfo(self.object)
			return
		end
		if self.isPallet then
			self:showPalletInfo(self.object)
			return
		end
		if self.isSplitShape and self.splitShape ~= nil then
			self:showSplitShapeInfo(self.splitShape)
			return
		end
		if self.isAnimal then
			self:showAnimalInfo(self.object)
		end
	end
end

function PlayerHUDUpdater:setCurrentRaycastTarget(node)
	if self.currentRaycastTarget ~= node then
		self.currentRaycastTarget = node
		self:updateRaycastObject()
	end
end

-- Local values: object, husbandryId, animalId, clusterHusbandry, cluster
function PlayerHUDUpdater:updateRaycastObject()
	if self.object ~= nil and self.object.removeDeleteListener ~= nil then
		self.object:removeDeleteListener(self, PlayerHUDUpdater.onDeleteObject)
	end
	self.isBale = false
	self.isVehicle = false
	self.isPallet = false
	self.isSplitShape = false
	self.isAnimal = false
	self.object = nil
	self.splitShape = nil
	if self.currentRaycastTarget == nil or not entityExists(self.currentRaycastTarget) then
		return
	else
		local v14_ = g_currentMission:getNodeObject(self.currentRaycastTarget)
		if v14_ == nil then
			if getHasClassId(self.currentRaycastTarget, ClassIds.MESH_SPLIT_SHAPE) then
				self.isSplitShape = true
				self.splitShape = self.currentRaycastTarget
			else
				local v15_, v16_ = getAnimalFromCollisionNode(self.currentRaycastTarget)
				if v15_ ~= nil and v15_ ~= 0 then
					local v17_ = g_currentMission.husbandrySystem:getClusterHusbandryById(v15_)
					if v17_ ~= nil then
						local v18_ = v17_:getClusterByAnimalId(v16_)
						if v18_ ~= nil then
							self.isAnimal = true
							self.object = v18_
							return
						end
					end
				end
			end
		else
			self.object = v14_
			if v14_:isa(Vehicle) then
				if v14_.isPallet then
					self.isPallet = true
				else
					self.isVehicle = true
				end
			elseif v14_:isa(Bale) then
				self.isBale = true
			end
			if self.object ~= nil and self.object.addDeleteListener ~= nil then
				self.object:addDeleteListener(self, PlayerHUDUpdater.onDeleteObject)
			end
			return
		end
	end
end

function PlayerHUDUpdater:onDeleteObject(object)
	if object == self.object then
		self.isBale = false
		self.isVehicle = false
		self.isPallet = false
		self.isSplitShape = false
		self.isAnimal = false
		self.object = nil
	end
end

function PlayerHUDUpdater:convertFarmToName(farm)
	if g_currentMission.missionDynamicInfo.isMultiplayer then
		return farm.name
	else
		return g_i18n:getText("fieldInfo_ownerYou")
	end
end

-- Local values: name, farmId, box, farm, propertyState
function PlayerHUDUpdater:showVehicleInfo(vehicle)
	local v24_ = vehicle:getFullName()
	local v25_ = vehicle:getOwnerFarmId()
	if v25_ ~= FarmManager.SPECTATOR_FARM_ID then
		local v26_ = self.objectBox
		v26_:clear()
		v26_:setTitle(v24_)
		local v27_ = g_farmManager:getFarmById(v25_)
		if v27_ ~= nil then
			if vehicle:getPropertyState() == VehiclePropertyState.OWNED then
				v26_:addLine(g_i18n:getText("fieldInfo_ownedBy"), self:convertFarmToName(v27_))
			else
				v26_:addLine(g_i18n:getText("infohud_rentedBy"), self:convertFarmToName(v27_))
			end
		end
		vehicle:showInfo(v26_)
		v26_:showNextFrame()
	end
end

-- Local values: farm, box
function PlayerHUDUpdater:showBaleInfo(bale)
	local v30_ = g_farmManager:getFarmById(bale:getOwnerFarmId())
	local v31_ = self.objectBox
	v31_:clear()
	v31_:setTitle(g_i18n:getText("infohud_bale"))
	if v30_ ~= nil then
		v31_:addLine(g_i18n:getText("fieldInfo_ownedBy"), self:convertFarmToName(v30_))
	end
	bale:showInfo(v31_)
	v31_:showNextFrame()
end

-- Local values: mass, farm, box
function PlayerHUDUpdater:showPalletInfo(pallet)
	local v34_ = pallet:getTotalMass()
	local v35_ = g_farmManager:getFarmById(pallet:getOwnerFarmId())
	local v36_ = self.objectBox
	v36_:clear()
	if pallet.getInfoBoxTitle == nil then
		v36_:setTitle(g_i18n:getText("infohud_pallet"))
	else
		v36_:setTitle(pallet:getInfoBoxTitle())
	end
	if v35_ ~= nil then
		v36_:addLine(g_i18n:getText("fieldInfo_ownedBy"), self:convertFarmToName(v35_))
	end
	v36_:addLine(g_i18n:getText("infohud_mass"), g_i18n:formatMass(v34_))
	pallet:showInfo(v36_)
	v36_:showNextFrame()
end

-- Local values: splitTypeId, isSplit, isStatic, sizeX, sizeY, sizeZ, numConvexes, numAttachments, splitType, splitTypeName, length, box, mass
function PlayerHUDUpdater:showSplitShapeInfo(shape)
	if entityExists(shape) and getHasClassId(shape, ClassIds.MESH_SPLIT_SHAPE) then
		local v39_ = getSplitType(shape)
		if v39_ == 0 then
			return
		else
			local v40_ = getIsSplitShapeSplit(shape)
			local v41_ = getRigidBodyType(shape) == RigidBodyType.STATIC
			if v40_ and v41_ then
				return
			else
				local v42_, v43_, v44_, _, _ = getSplitShapeStats(shape)
				local v45_ = g_splitShapeManager:getSplitTypeByIndex(v39_)
				if v45_ then
					v45_ = v45_.title
				end
				local v46_ = math.max(v42_, v43_, v44_)
				if math.abs(v46_) ~= math.huge then
					local v47_ = self.objectBox
					v47_:clear()
					if v40_ then
						v47_:setTitle(g_i18n:getText("infohud_wood"))
					else
						v47_:setTitle(g_i18n:getText("infohud_tree"))
					end
					if v45_ ~= nil then
						v47_:addLine(g_i18n:getText("infohud_type"), v45_)
					end
					v47_:addLine(g_i18n:getText("infohud_length"), g_i18n:formatNumber(v46_, 1) .. " m")
					if g_currentMission:getIsServer() and not v41_ then
						local v48_ = getMass(shape)
						v47_:addLine(g_i18n:getText("infohud_mass"), g_i18n:formatMass(v48_))
					end
					v47_:showNextFrame()
				end
			end
		end
	else
		return
	end
end

-- Local values: box
function PlayerHUDUpdater:showAnimalInfo(cluster)
	local v51_ = self.objectBox
	v51_:clear()
	v51_:setTitle(g_i18n:getText("infohud_animal"))
	cluster:showInfo(v51_)
	v51_:showNextFrame()
end

function PlayerHUDUpdater:onFieldDataUpdateFinished(data)
	if self.requestedFieldData then
		self.fieldData = data
		self.fieldInfoNeedsRebuild = true
	end
	self.requestedFieldData = false
end

-- Local values: fieldInfo, dirX, dirZ, distance, x, z, box
function PlayerHUDUpdater:showFieldInfo(posX, posZ, rotY)
	local v58_ = self.fieldInfo
	local v59_, v60_ = MathUtil.getDirectionFromYRotation(rotY)
	v58_:update(posX + v59_ * 2, posZ + v60_ * 2)
	if v58_.groundType ~= FieldGroundType.NONE then
		local v61_ = self.fieldBox
		v61_:clear()
		v61_:setTitle(g_i18n:getText("ui_fieldInfo"))
		self:fieldAddFarmland(v58_, v61_)
		self:fieldAddField(v58_, v61_)
		self:fieldAddWeed(v58_, v61_)
		self:fieldAddFieldActions(v58_, v61_)
		self.fieldInfoNeedsRebuild = false
		v61_:showNextFrame()
	end
end

-- Local values: farmName, ownedByYou, ownerFarmId, farmland, npc, farm
function PlayerHUDUpdater:fieldAddFarmland(fieldInfo, box)
	local v64_ = false
	local v65_ = fieldInfo.ownerFarmId
	local v66_
	if v65_ == g_currentMission:getFarmId() and v65_ ~= FarmManager.SPECTATOR_FARM_ID then
		v66_ = g_i18n:getText("fieldInfo_ownerYou")
		v64_ = true
	elseif v65_ == AccessHandler.EVERYONE or v65_ == AccessHandler.NOBODY then
		local v67_ = g_farmlandManager:getFarmlandById(fieldInfo.farmlandId)
		if v67_ == nil then
			v66_ = g_i18n:getText("fieldInfo_ownerNobody")
		else
			local v68_ = v67_:getNPC()
			v66_ = v68_ ~= nil and v68_.title or "Unknown"
		end
	else
		local v69_ = g_farmManager:getFarmById(v65_)
		if v69_ == nil then
			v66_ = "Unknown"
		else
			v66_ = v69_.name
		end
	end
	local v70_ = g_i18n:getText("fieldInfo_farmland")
	local v71_ = fieldInfo.farmlandId
	box:addLine(v70_, (tostring(v71_)))
	if Platform.playerInfo.showNPCNames then
		box:addLine(g_i18n:getText("fieldInfo_ownedBy"), v66_)
		return
	elseif v64_ then
		box:addLine(g_i18n:getText("fieldInfo_owned"))
	else
		box:addLine(g_i18n:getText("fieldInfo_notOwned"))
	end
end

-- Local values: fruitTypeIndex, growthState, isGrowing, fruitTypeDesc, text, fieldGroundSystem, harvestMultiplier, sprayLevelMax, sprayFactor
function PlayerHUDUpdater:fieldAddField(fieldInfo, box)
	local v74_ = fieldInfo.fruitTypeIndex
	local v75_ = fieldInfo.growthState
	local v76_ = false
	if v74_ ~= FruitType.UNKNOWN then
		local v77_ = g_fruitTypeManager:getFruitTypeByIndex(v74_)
		box:addLine(g_i18n:getText("statistic_fillType"), v77_.fillType.title)
		local v78_ = nil
		if v77_:getIsCut(v75_) then
			v78_ = g_i18n:getText("ui_growthMapCut")
		elseif v77_:getIsWithered(v75_) then
			v78_ = g_i18n:getText("ui_growthMapWithered")
		elseif v77_:getIsGrowing(v75_) then
			v78_ = g_i18n:getText("ui_growthMapGrowing")
			v76_ = true
		elseif v77_:getIsPreparable(v75_) then
			v78_ = g_i18n:getText("ui_growthMapReadyToPrepareForHarvest")
			v76_ = true
		elseif v77_:getIsHarvestable(v75_) then
			v78_ = g_i18n:getText("ui_growthMapReadyToHarvest")
			v76_ = true
		end
		if v78_ ~= nil then
			box:addLine(g_i18n:getText("ui_mapOverviewGrowth"), v78_)
		end
	end
	local v79_ = g_currentMission.fieldGroundSystem
	if v76_ then
		local v80_ = fieldInfo:getHarvestScaleMultiplier() - 1
		local v81_ = MathUtil.round(v80_ * 100)
		box:addLine(g_i18n:getText("fieldInfo_yieldBonus"), string.format("+ %d %%", v81_))
	end
	if fieldInfo.sprayLevel >= 0 then
		local v82_ = v79_:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		local v83_ = fieldInfo.sprayLevel / v82_
		box:addLine(g_i18n:getText("ui_growthMapFertilized"), string.format("%d %%", v83_ * 100))
	end
end

-- Local values: missionInfo
function PlayerHUDUpdater:fieldAddFieldActions(fieldInfo, box)
	local v86_ = g_currentMission.missionInfo
	if Platform.gameplay.useLimeCounter and (v86_.limeRequired and fieldInfo.limeLevel == 0) then
		box:addLine(g_i18n:getText("ui_growthMapNeedsLime"), nil, true)
	end
	if fieldInfo.plowLevel == 0 and v86_.plowingRequiredEnabled then
		box:addLine(g_i18n:getText("ui_growthMapNeedsPlowing"), nil, true)
	end
	if Platform.gameplay.useRolling and fieldInfo.rollerLevel > 0 then
		box:addLine(g_i18n:getText("ui_growthMapNeedsRolling"), nil, true)
	end
end

-- Local values: weedSystem, fieldInfoStates, weedState, fruitTypeIndex, growthState, toolName, fruitTypeDesc, weederReplacements, weed, targetState, hoeReplacements, weed, targetState, title
function PlayerHUDUpdater:fieldAddWeed(fieldInfo, box)
	if g_currentMission.missionInfo.weedsEnabled then
		local v89_ = g_currentMission.weedSystem
		local v90_ = v89_:getFieldInfoStates()
		local v91_ = fieldInfo.weedState
		local v92_ = fieldInfo.fruitTypeIndex or FruitType.UNKNOWN
		local v93_ = fieldInfo.growthState or 0
		local v94_ = nil
		if v91_ ~= 0 then
			local v95_
			if v92_ == nil then
				v95_ = nil
			else
				v95_ = g_fruitTypeManager:getFruitTypeByIndex(v92_)
			end
			if Platform.gameplay.hasWeeder then
				if (v95_ == nil or v95_:getIsWeedable(v93_)) and v89_:getWeederReplacements(false).weed.replacements[v91_] == 0 then
					v94_ = g_i18n:getText("weed_destruction_weeder")
				end
				if v94_ == nil and (v95_ == nil or v95_:getIsHoeable(v93_)) and v89_:getWeederReplacements(true).weed.replacements[v91_] == 0 then
					v94_ = g_i18n:getText("weed_destruction_hoe")
				end
			end
			if v94_ == nil and (v95_ == nil or v95_:getIsGrowing(v93_)) then
				v94_ = g_i18n:getText("weed_destruction_herbicide")
			end
			local v96_ = v90_[v91_]
			if v96_ ~= nil then
				box:addLine(v96_, v94_ or "", true)
			end
		end
	else
		return
	end
end
