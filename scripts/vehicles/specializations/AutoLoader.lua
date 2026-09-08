AutoLoader = {}

function AutoLoader.prerequisitesPresent(specializations)
	return true
end
function AutoLoader.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("AutoLoader")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.autoLoader.areas.area(?)#node", "Area root node")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.autoLoader.areas.area(?).trigger(?)#node", "Trigger node")
	v1_:register(XMLValueType.BOOL, "vehicle.autoLoader.areas.area(?).trigger(?)#alwaysActive", "Sets a trigger always active")
	v1_:register(XMLValueType.FLOAT, "vehicle.autoLoader.areas.area(?)#length", "Area length")
	v1_:register(XMLValueType.FLOAT, "vehicle.autoLoader.areas.area(?)#width", "Area width")
	v1_:register(XMLValueType.FLOAT, "vehicle.autoLoader.areas.area(?)#height", "Area height (only used for collision checks)")
	v1_:register(XMLValueType.FLOAT, "vehicle.autoLoader.areas.area(?)#spacing", "Area spacing")
	v1_:setXMLSpecializationType()
	local v2_ = Vehicle.xmlSchemaSavegame
	v2_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).autoLoader.mountedObject(?)#mountPosX", "Mount position x")
	v2_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).autoLoader.mountedObject(?)#mountPosZ", "Mount position z")
	v2_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).autoLoader.mountedObject(?)#mountSizeX", "Mount size x")
	v2_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).autoLoader.mountedObject(?)#mountSizeZ", "Mount size z")
	v2_:register(XMLValueType.INT, "vehicles.vehicle(?).autoLoader.mountedObject(?)#mountAreaIndex", "Mount area index")
	v2_:register(XMLValueType.INT, "vehicles.vehicle(?).autoLoader.mountedObject(?)#vehicleUniqueId", "Vehicle unique id")
	Bale.registerSavegameXMLPaths(v2_, "vehicles.vehicle(?).autoLoader.mountedObject(?).bale")
end

function AutoLoader.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "autoLoaderPickupTriggerCallback", AutoLoader.autoLoaderPickupTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "autoLoaderOverlapCallback", AutoLoader.autoLoaderOverlapCallback)
	SpecializationUtil.registerFunction(vehicleType, "getIsValidAutoLoaderObject", AutoLoader.getIsValidAutoLoaderObject)
	SpecializationUtil.registerFunction(vehicleType, "getIsAutoLoadingAllowed", AutoLoader.getIsAutoLoadingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "onUnmountObject", AutoLoader.onUnmountObject)
end

function AutoLoader.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDynamicMountTimeToMount", AutoLoader.getDynamicMountTimeToMount)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", AutoLoader.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", AutoLoader.removeFromPhysics)
end

function AutoLoader.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AutoLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AutoLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AutoLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AutoLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", AutoLoader)
end

-- Local values: spec
function AutoLoader:onLoad(savegame)
	local v_u_7_ = self.spec_autoLoader
	if self.isServer then
		v_u_7_.collsionMask = CollisionFlag.VEHICLE + CollisionFlag.DYNAMIC_OBJECT
		v_u_7_.pendingObjects = {}
		v_u_7_.mountedObjects = {}
		v_u_7_.triggerToAreas = {}
		v_u_7_.alwaysActiveTriggers = {}
		v_u_7_.skippedObjects = {}
		self.xmlFile:iterate("vehicle.autoLoader.areas.area", function(_, p8_)
			-- upvalues: (copy) self, (copy) v_u_7_
			local v9_ = self.xmlFile:getValue(p8_ .. "#node", nil, self.components, self.i3dMappings)
			local v10_ = self.xmlFile:getValue(p8_ .. "#length", 6)
			local v11_ = self.xmlFile:getValue(p8_ .. "#width", 2.5)
			local v12_ = self.xmlFile:getValue(p8_ .. "#height", 4)
			local v13_ = self.xmlFile:getValue(p8_ .. "#spacing", 0.1)
			if v9_ ~= nil then
				if v_u_7_.areas == nil then
					v_u_7_.areas = {}
				end
				local v_u_14_ = {
					["node"] = v9_,
					["index"] = #v_u_7_.areas + 1,
					["width"] = v11_,
					["length"] = v10_,
					["height"] = v12_,
					["spacing"] = v13_,
					["grid"] = PlacementGrid2D.new(v9_, v11_, v10_, v13_, PlacementGrid2D.MODE_SIDES)
				}
				self.xmlFile:iterate(p8_ .. ".trigger", function(_, p15_)
					-- upvalues: (ref) self, (ref) v_u_7_, (copy) v_u_14_
					local v16_ = self.xmlFile:getValue(p15_ .. "#node", nil, self.components, self.i3dMappings)
					if v_u_7_.triggerToAreas[v16_] == nil then
						addTrigger(v16_, "autoLoaderPickupTriggerCallback", self)
						v_u_7_.triggerToAreas[v16_] = {}
					end
					if self.xmlFile:getValue(p15_ .. "#alwaysActive") then
						v_u_7_.alwaysActiveTriggers[v16_] = true
					end
					local v17_ = v_u_7_.triggerToAreas[v16_]
					local v18_ = v_u_14_
					table.insert(v17_, v18_)
				end)
				local v19_ = v_u_7_.areas
				table.insert(v19_, v_u_14_)
			end
		end)
	end
	v_u_7_.isAutoLoadingActive = false
	v_u_7_.warningNoSpace = g_i18n:getText("autoLoader_warningNoSpace")
	v_u_7_.warningTooLarge = g_i18n:getText("autoLoader_warningTooLarge")
end

-- Local values: spec, xmlFile, key
function AutoLoader:onPostLoad(savegame)
	if savegame ~= nil then
		local v_u_22_ = self.spec_autoLoader
		if not savegame.resetVehicles then
			local v_u_23_ = savegame.xmlFile
			local v24_ = string.format("%s.autoLoader.mountedObject", savegame.key)
			v_u_22_.pendingVehicles = {}
			v_u_23_:iterate(v24_, function(_, p25_)
				-- upvalues: (copy) v_u_23_, (copy) v_u_22_, (copy) self
				local v26_ = v_u_23_:getValue(p25_ .. "#mountPosX")
				local v27_ = v_u_23_:getValue(p25_ .. "#mountPosZ")
				local v28_ = v_u_23_:getValue(p25_ .. "#mountSizeX")
				local v29_ = v_u_23_:getValue(p25_ .. "#mountSizeZ")
				local v30_ = v_u_23_:getValue(p25_ .. "#mountAreaIndex")
				local v31_ = v_u_23_:getValue(p25_ .. "#vehicleUniqueId")
				local v32_ = v_u_22_.areas[v30_]
				if v32_ ~= nil then
					if v31_ ~= nil then
						local v33_ = v_u_22_.pendingVehicles
						table.insert(v33_, {
							["posX"] = v26_,
							["posZ"] = v27_,
							["sizeX"] = v28_,
							["sizeZ"] = v29_,
							["area"] = v32_,
							["vehicleUniqueId"] = v31_
						})
						return
					end
					if v_u_23_:hasProperty(p25_ .. ".bale") then
						local v34_ = Bale.new(self.isServer, self.isClient)
						if v34_:loadFromXMLFile(v_u_23_, p25_ .. ".bale", false) then
							v34_:register()
							if v34_:autoLoad(self, v32_.node, v26_, v27_, v28_, v29_) then
								v_u_22_.mountedObjects[v34_] = {
									v26_,
									v27_,
									v28_,
									v29_,
									v32_.index
								}
								v_u_22_.pendingObjects[v34_] = nil
								v32_.grid:blockAreaLocal(v26_, v27_, v28_, v29_)
								return
							end
						else
							Logging.xmlWarning(v_u_23_, "Could not load autoLoader bale for \'%s\'", p25_)
							v34_:delete()
						end
					end
				end
			end)
		end
	end
end

-- Local values: spec, pendingObject, _, object, _, _, area, triggerNode, _
function AutoLoader:onDelete()
	local v36_ = self.spec_autoLoader
	if self.isServer then
		for v37_, _ in pairs(v36_.pendingObjects) do
			v37_:removeDeleteListener(self, AutoLoader.onDeletePendingObject)
		end
		for v38_, _ in pairs(v36_.mountedObjects) do
			v38_:unmountKinematic()
		end
		if v36_.areas ~= nil then
			for _, v39_ in ipairs(v36_.areas) do
				v39_.grid:delete()
			end
		end
		if v36_.triggerToAreas ~= nil then
			for v40_, _ in pairs(v36_.triggerToAreas) do
				removeTrigger(v40_)
			end
		end
	end
	v36_.skippedObjects = nil
	v36_.pendingObjects = nil
	v36_.mountedObjects = nil
end

-- Local values: spec, i, object, mountData, mountKey
function AutoLoader:saveToXMLFile(xmlFile, key, usedModNames)
	local v44_ = self.spec_autoLoader
	local v45_ = 0
	for v46_, v47_ in pairs(v44_.mountedObjects) do
		local v48_ = string.format("%s.mountedObject(%d)", key, v45_)
		xmlFile:setValue(v48_ .. "#mountPosX", v47_[1])
		xmlFile:setValue(v48_ .. "#mountPosZ", v47_[2])
		xmlFile:setValue(v48_ .. "#mountSizeX", v47_[3])
		xmlFile:setValue(v48_ .. "#mountSizeZ", v47_[4])
		xmlFile:setValue(v48_ .. "#mountAreaIndex", v47_[5])
		if v46_:isa(Vehicle) then
			xmlFile:setValue(v48_ .. "#vehicleUniqueId", v46_:getUniqueId())
		elseif v46_:isa(Bale) then
			v46_:saveToXMLFile(xmlFile, v48_ .. ".bale")
		end
		v45_ = v45_ + 1
	end
end

-- Local values: spec, object, t, _, data, vehicleUniqueId, vehicle, area, posX, posZ, sizeX, sizeZ, success, _, area, object, _, x, y, z, dirX, dirY, dirZ, upX, upY, upZ, extendX, extendY, extendZ, showTooLargeWarning, showNoSpaceWarning, pendingObject, triggerId, sizeX, sizeY, sizeZ, areas, _, area, foundSpace, try, posX, posZ, x, y, z, rx, ry, rz, success
function AutoLoader:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v51_ = self.spec_autoLoader
	if self.isServer and v51_.areas ~= nil then
		for v52_, v53_ in pairs(v51_.skippedObjects) do
			local v54_ = v53_ - dt
			v51_.skippedObjects[v52_] = v54_ > 0 and v54_ and v54_ or nil
		end
		if v51_.pendingVehicles ~= nil then
			for _, v55_ in ipairs(v51_.pendingVehicles) do
				local v56_ = v55_.vehicleUniqueId
				local v57_ = g_currentMission.vehicleSystem:getVehicleByUniqueId(v56_)
				if v57_ ~= nil then
					local v58_ = v55_.area
					local v59_ = v55_.posX
					local v60_ = v55_.posZ
					local v61_ = v55_.sizeX
					local v62_ = v55_.sizeZ
					if v57_:autoLoad(self, v58_.node, v59_, v60_, v61_, v62_) then
						v51_.mountedObjects[v57_] = {
							v59_,
							v60_,
							v61_,
							v62_,
							v58_.index
						}
						v51_.pendingObjects[v57_] = nil
						v57_:removeDeleteListener(self, AutoLoader.onDeletePendingObject)
						v58_.grid:blockAreaLocal(v59_, v60_, v61_, v62_)
					end
				end
			end
			v51_.pendingVehicles = nil
		end
		if v51_.needGridUpdate then
			v51_.needGridUpdate = false
			for _, v63_ in ipairs(v51_.areas) do
				v63_.grid:reset()
				for v64_, _ in pairs(v51_.mountedObjects) do
					local v65_, v66_, v67_, v68_, v69_, v70_, v71_, v72_, v73_, v74_, v75_, v76_ = v64_:getAutoLoadBoundingBox()
					v63_.grid:blockAreaByBoundingBox(v65_, v66_, v67_, v68_, v69_, v70_, v71_, v72_, v73_, v74_, v75_, v76_)
				end
			end
		end
		local v77_ = false
		local v78_ = false
		for v79_, v80_ in pairs(v51_.pendingObjects) do
			if v79_.isDeleted then
				v51_.pendingObjects[v79_] = true
			else
				if (v51_.isAutoLoadingActive or v51_.alwaysActiveTriggers[v80_] == true) and v79_:getAutoLoadIsAllowed() then
					local v81_, v82_, v83_ = v79_:getAutoLoadSize()
					local v84_ = v51_.triggerToAreas[v80_]
					for _, v85_ in ipairs(v84_) do
						if v81_ <= v85_.width and (v82_ <= v85_.height and v83_ <= v85_.length) then
							local v86_ = false
							for _ = 1, 3 do
								local v87_, v88_ = v85_.grid:getFreePosition(v81_, v83_)
								if v87_ == nil then
									v77_ = true
								else
									local v89_, v90_, v91_ = localToWorld(v85_.node, v87_ + v81_ * 0.5, v82_ * 0.5, v88_ + v83_ * 0.5)
									local v92_, v93_, v94_ = getWorldRotation(v85_.node)
									v51_.isAreaBlocked = false
									v51_.currentPendingObject = v79_
									overlapBox(v89_, v90_, v91_, v92_, v93_, v94_, v81_ * 0.5, v82_ * 0.5, v83_ * 0.5, "autoLoaderOverlapCallback", self, v51_.collsionMask, true, true, false, true)
									v51_.currentPendingObject = nil
									if v51_.isAreaBlocked then
										v85_.grid:blockAreaLocal(v87_, v88_, v81_, v83_)
									elseif v79_:autoLoad(self, v85_.node, v87_, v88_, v81_, v83_) then
										v51_.mountedObjects[v79_] = {
											v87_,
											v88_,
											v81_,
											v83_,
											v85_.index
										}
										v51_.pendingObjects[v79_] = nil
										v79_:removeDeleteListener(self, AutoLoader.onDeletePendingObject)
										v85_.grid:blockAreaLocal(v87_, v88_, v81_, v83_)
										v86_ = true
										v77_ = false
										v78_ = false
										break
									end
								end
							end
							if v86_ then
								break
							end
						else
							v78_ = true
						end
					end
				end
				if v77_ and v51_.warningNoSpace ~= nil then
					g_currentMission:showBlinkingWarning(v51_.warningNoSpace, 2000)
				elseif v78_ and v51_.warningTooLarge ~= nil then
					g_currentMission:showBlinkingWarning(v51_.warningTooLarge, 2000)
				end
			end
		end
		if Platform.gameplay.automaticVehicleControl and v51_.isAutoLoadingActive then
			self.rootVehicle:playControlledActions()
		end
	end
end

-- Local values: spec, _, area
function AutoLoader:onDraw()
	local v96_ = self.spec_autoLoader
	if v96_.areas ~= nil then
		for _, v97_ in ipairs(v96_.areas) do
			v97_.grid:drawDebug()
		end
	end
end

-- Local values: spec, object, _
function AutoLoader:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end
	if self.isServer then
		local v100_ = self.spec_autoLoader
		for v101_, _ in pairs(v100_.mountedObjects) do
			if v101_.addToPhysics ~= nil then
				v101_:addToPhysics()
			end
		end
	end
	return true
end

-- Local values: ret, spec, object, _
function AutoLoader:removeFromPhysics(superFunc)
	local v104_ = superFunc(self)
	if self.isServer then
		local v105_ = self.spec_autoLoader
		for v106_, _ in pairs(v105_.mountedObjects) do
			if v106_.removeFromPhysics ~= nil then
				v106_:removeFromPhysics()
			end
		end
	end
	return v104_
end

-- Local values: spec
function AutoLoader:onUnmountObject(object)
	local v109_ = self.spec_autoLoader
	v109_.skippedObjects[object] = 3000
	v109_.mountedObjects[object] = nil
	v109_.needGridUpdate = true
	self:raiseActive()
end

-- Local values: spec
function AutoLoader:getIsValidAutoLoaderObject(object)
	if object == nil then
		return false
	elseif object == self then
		return false
	elseif self.spec_autoLoader.mountedObjects[object] == nil then
		if object:isa(Vehicle) or object:isa(Bale) then
			if object.getAutoLoadIsSupported == nil or not object:getAutoLoadIsSupported() then
				return false
			else
				return g_currentMission.accessHandler:canFarmAccess(self:getActiveFarm(), object) and true or false
			end
		else
			return false
		end
	else
		return false
	end
end

-- Local values: spec, object, shouldBeSkipped, object
function AutoLoader:autoLoaderPickupTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local v117_ = self.spec_autoLoader
	if onEnter then
		local v118_ = g_currentMission:getNodeObject(otherActorId)
		if otherActorId ~= 0 and (self:getIsAutoLoadingAllowed() and (v118_ == nil or v117_.mountedObjects[v118_] == nil)) then
			local v119_
			if v117_.skippedObjects[v118_] == nil then
				v119_ = false
			else
				v119_ = v117_.alwaysActiveTriggers[triggerId] == true
			end
			if self:getIsValidAutoLoaderObject(v118_) and (v117_.pendingObjects[v118_] ~= triggerId and not v119_) then
				v117_.pendingObjects[v118_] = triggerId
				v118_:addDeleteListener(self, AutoLoader.onDeletePendingObject)
				v117_.needGridUpdate = true
				self:raiseActive()
				return
			end
		end
	elseif onLeave then
		local v120_ = g_currentMission:getNodeObject(otherActorId)
		if v120_ ~= nil and v117_.pendingObjects[v120_] ~= nil then
			v117_.pendingObjects[v120_] = nil
			v120_:removeDeleteListener(self, AutoLoader.onDeletePendingObject)
		end
	end
end

-- Local values: object, spec
function AutoLoader:autoLoaderOverlapCallback(transformId)
	if transformId ~= 0 and (getHasClassId(transformId, ClassIds.SHAPE) and not getHasTrigger(transformId)) then
		local v123_ = g_currentMission:getNodeObject(transformId)
		local v124_ = self.spec_autoLoader
		if v123_ ~= self and (v124_.mountedObjects[v123_] == nil and v124_.currentPendingObject ~= v123_) then
			v124_.isAreaBlocked = true
			return false
		end
	end
	return true
end

-- Local values: _, y1, _, _, y2, _
function AutoLoader:getIsAutoLoadingAllowed()
	local _, v126_, _ = getWorldTranslation(self.components[1].node)
	local _, v127_, _ = localToWorld(self.components[1].node, 0, 1, 0)
	return v127_ - v126_ >= 0.5
end

function AutoLoader:getDynamicMountTimeToMount(superFunc)
	return self:getIsAutoLoadingAllowed() and -1 or math.huge
end

-- Local values: spec, actionController
function AutoLoader:onRootVehicleChanged(rootVehicle)
	local v131_ = self.spec_autoLoader
	local v132_ = rootVehicle.actionController
	if v132_ == nil then
		if v131_.controlledAction ~= nil then
			v131_.controlledAction:remove()
			v131_.controlledAction = nil
		end
		return
	elseif v131_.controlledAction == nil then
		v131_.controlledAction = v132_:registerAction("autoLoaderLoad", nil, 4)
		v131_.controlledAction:setCallback(self, AutoLoader.actionControllerEvent)
		v131_.controlledAction:setIsAvailableFunction(function()
			-- upvalues: (copy) self
			return next(self.spec_autoLoader.pendingObjects) ~= nil
		end)
		v131_.controlledAction:setActionIcons("AUTO_LOAD", "AUTO_LOAD", false)
	else
		v131_.controlledAction:updateParent(v132_)
	end
end

-- Local values: spec
function AutoLoader:actionControllerEvent(direction)
	local v135_ = self.spec_autoLoader
	if direction < 0 then
		v135_.isAutoLoadingActive = false
	else
		v135_.isAutoLoadingActive = true
	end
	return true
end

-- Local values: spec
function AutoLoader:onDeletePendingObject(object)
	self.spec_autoLoader.pendingObjects[object] = nil
end
