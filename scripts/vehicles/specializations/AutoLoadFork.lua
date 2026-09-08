AutoLoadFork = {}
AutoLoadFork.BLOCK_REMOUNT_TIME = 1000

function AutoLoadFork.prerequisitesPresent(self)
	return true
end
function AutoLoadFork.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("AutoLoadFork")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.autoLoadFork#triggerNode", "Trigger to detect the pallets")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.autoLoadFork#jointNode", "Node to join the pallets to")
	v1_:register(XMLValueType.STRING, "vehicle.autoLoadFork.liftAnimation#name", "Lift animation name")
	v1_:register(XMLValueType.FLOAT, "vehicle.autoLoadFork.liftAnimation#speedScale", "Animation speed scale")
	v1_:setXMLSpecializationType()
	local v2_ = Vehicle.xmlSchemaSavegame
	v2_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).autoLoadFork#liftAnimationTime", "Current state of lift animation")
	v2_:register(XMLValueType.INT, "vehicles.vehicle(?).autoLoadFork.mountedObject(?)#vehicleUniqueId", "Vehicle unique id")
	Bale.registerSavegameXMLPaths(v2_, "vehicles.vehicle(?).autoLoadFork.mountedObject(?).bale")
end

function AutoLoadFork.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "onAutoLoadForkTriggerCallback", AutoLoadFork.onAutoLoadForkTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "getCanUnloadFork", AutoLoadFork.getCanUnloadFork)
	SpecializationUtil.registerFunction(vehicleType, "getIsForkUnloadingAllowed", AutoLoadFork.getIsForkUnloadingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "doUnloadFork", AutoLoadFork.doUnloadFork)
	SpecializationUtil.registerFunction(vehicleType, "onUnmountObject", AutoLoadFork.onUnmountObject)
	SpecializationUtil.registerFunction(vehicleType, "mountObjectToFork", AutoLoadFork.mountObjectToFork)
end

function AutoLoadFork.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", AutoLoadFork.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", AutoLoadFork.removeFromPhysics)
end

function AutoLoadFork.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AutoLoadFork)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AutoLoadFork)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AutoLoadFork)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AutoLoadFork)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", AutoLoadFork)
	SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", AutoLoadFork)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AutoLoadFork)
end

-- Local values: spec
function AutoLoadFork:onLoad(savegame)
	local v7_ = self.spec_autoLoadFork
	if self.isServer then
		v7_.triggerNode = self.xmlFile:getValue("vehicle.autoLoadFork#triggerNode", nil, self.components, self.i3dMappings)
		if v7_.triggerNode ~= nil then
			addTrigger(v7_.triggerNode, "onAutoLoadForkTriggerCallback", self)
		end
	end
	v7_.jointNode = self.xmlFile:getValue("vehicle.autoLoadFork#jointNode", nil, self.components, self.i3dMappings)
	v7_.remountDistance = 0
	v7_.mountedObjects = {}
	v7_.unmountedObjects = {}
	v7_.liftAnimation = {}
	v7_.liftAnimation.name = self.xmlFile:getValue("vehicle.autoLoadFork.liftAnimation#name")
	v7_.liftAnimation.speedScale = self.xmlFile:getValue("vehicle.autoLoadFork.liftAnimation#speedScale", 1)
end

-- Local values: spec, xmlFile, liftAnimationTime, key
function AutoLoadFork:onPostLoad(savegame)
	local v_u_10_ = self.spec_autoLoadFork
	if savegame ~= nil and not savegame.resetVehicles then
		local v_u_11_ = savegame.xmlFile
		if v_u_10_.liftAnimation.name ~= nil then
			local v12_ = v_u_11_:getValue(savegame.key .. ".autoLoadFork#liftAnimationTime")
			if v12_ ~= nil then
				self:setAnimationTime(v_u_10_.liftAnimation.name, v12_, true, false)
			end
		end
		local v13_ = string.format("%s.autoLoadFork.mountedObject", savegame.key)
		v_u_10_.pendingVehicles = {}
		v_u_11_:iterate(v13_, function(_, p14_)
			-- upvalues: (copy) v_u_11_, (copy) v_u_10_, (copy) self
			local v15_ = v_u_11_:getValue(p14_ .. "#vehicleUniqueId")
			if v15_ == nil then
				if v_u_11_:hasProperty(p14_ .. ".bale") then
					local v16_ = Bale.new(self.isServer, self.isClient)
					if v16_:loadFromXMLFile(v_u_11_, p14_ .. ".bale", false) then
						v16_:register()
						self:mountObjectToFork(v16_)
						return
					end
					Logging.xmlWarning(v_u_11_, "Could not load autoLoadFork bale for \'%s\'", p14_)
					v16_:delete()
				end
			else
				local v17_ = v_u_10_.pendingVehicles
				table.insert(v17_, {
					["vehicleUniqueId"] = v15_
				})
			end
		end)
	end
end

-- Local values: spec, _, mountedObjectId, object
function AutoLoadFork:onDelete()
	local v19_ = self.spec_autoLoadFork
	if self.isServer then
		for _, v20_ in pairs(v19_.mountedObjects) do
			local v21_ = NetworkUtil.getObject(v20_)
			if v21_ ~= nil then
				v21_:unmountKinematic()
			end
		end
	end
	if v19_.triggerNode ~= nil then
		removeTrigger(v19_.triggerNode)
	end
end

-- Local values: spec, _, data, vehicleUniqueId, vehicle, lastMovedDistance
function AutoLoadFork:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v23_ = self.spec_autoLoadFork
	if self.isServer then
		if v23_.pendingVehicles ~= nil then
			for _, v24_ in ipairs(v23_.pendingVehicles) do
				local v25_ = v24_.vehicleUniqueId
				local v26_ = g_currentMission.vehicleSystem:getVehicleByUniqueId(v25_)
				if v26_ ~= nil then
					self:mountObjectToFork(v26_)
				end
			end
			v23_.pendingVehicles = nil
		end
		if v23_.remountDistance > 0 then
			local v27_ = self.lastMovedDistance
			local v28_ = v23_.remountDistance - v27_
			v23_.remountDistance = math.max(0, v28_)
		end
	end
end

-- Local values: spec
function AutoLoadFork:onDeactivate()
	if self.isServer then
		self.spec_autoLoadFork.remountDistance = 0
	end
end

-- Local values: spec, i, _, mountedObjectId, object, mountKey
function AutoLoadFork:saveToXMLFile(xmlFile, key, usedModNames)
	local v33_ = self.spec_autoLoadFork
	if v33_.liftAnimation.name ~= nil then
		xmlFile:setValue(key .. "#liftAnimationTime", self:getAnimationTime(v33_.liftAnimation.name))
	end
	local v34_ = 0
	for _, v35_ in pairs(v33_.mountedObjects) do
		local v36_ = NetworkUtil.getObject(v35_)
		if v36_ ~= nil then
			local v37_ = string.format("%s.mountedObject(%d)", key, v34_)
			if v36_:isa(Vehicle) then
				xmlFile:setValue(v37_ .. "#vehicleUniqueId", v36_:getUniqueId())
			elseif v36_:isa(Bale) then
				v36_:saveToXMLFile(xmlFile, v37_ .. ".bale")
			end
			v34_ = v34_ + 1
		end
	end
end

-- Local values: spec, _, actionEventId
function AutoLoadFork:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v40_ = self.spec_autoLoadFork
		self:clearActionEventsTable(v40_.actionEvents)
		if isActiveForInputIgnoreSelection then
			local _, v41_ = self:addActionEvent(v40_.actionEvents, InputAction.UNLOAD_FORK, self, AutoLoadFork.actionEventUnloadFork, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v41_, GS_PRIO_NORMAL)
		end
	end
end

-- Local values: spec, actionController
function AutoLoadFork:onRootVehicleChanged(rootVehicle)
	local v44_ = self.spec_autoLoadFork
	local v45_ = rootVehicle.actionController
	if v45_ == nil then
		if v44_.controlledAction ~= nil then
			v44_.controlledAction:remove()
			v44_.controlledAction = nil
		end
		return
	elseif v44_.controlledAction == nil then
		v44_.controlledAction = v45_:registerAction("forkLifting", nil, 4)
		v44_.controlledAction:setCallback(self, AutoLoadFork.actionControllerEvent)
		v44_.controlledAction:setActionIcons("LOADER_LOWER", "LOADER_LIFT", false)
	else
		v44_.controlledAction:updateParent(v45_)
	end
end

-- Local values: spec
function AutoLoadFork:actionControllerEvent(direction)
	local v48_ = self.spec_autoLoadFork
	if v48_.liftAnimation.name ~= nil then
		self:playAnimation(v48_.liftAnimation.name, v48_.liftAnimation.speedScale * direction, self:getAnimationTime(v48_.liftAnimation.name))
	end
	return true
end

-- Local values: spec, i, mountedObjectId
function AutoLoadFork:onDeleteMountedObject(object)
	local v51_ = self.spec_autoLoadFork
	for v52_ = #v51_.mountedObjects, 1, -1 do
		if v51_.mountedObjects[v52_] == object.id then
			table.remove(v51_.mountedObjects, v52_)
			local v53_ = v51_.unmountedObjects
			local v54_ = {
				["objectId"] = object.id,
				["time"] = g_time
			}
			table.insert(v53_, v54_)
			return
		end
	end
end

-- Local values: object, spec, i, i, unmountedObject, i, mountedObjectId
function AutoLoadFork:onAutoLoadForkTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	local v59_ = g_currentMission:getNodeObject(otherId)
	if v59_ ~= nil and (v59_.isPallet or v59_:isa(Bale)) then
		local v60_ = self.spec_autoLoadFork
		if onEnter then
			if #v60_.mountedObjects == 0 and v60_.remountDistance <= 0 then
				for v61_ = 1, #v60_.mountedObjects do
					if v60_.mountedObjects[v61_] == v59_.id then
						return
					end
				end
				for v62_ = #v60_.unmountedObjects, 1, -1 do
					local v63_ = v60_.unmountedObjects[v62_]
					if v63_.objectId == v59_.id then
						if v63_.time + AutoLoadFork.BLOCK_REMOUNT_TIME > g_time then
							return
						end
					elseif v63_.time + AutoLoadFork.BLOCK_REMOUNT_TIME < g_time then
						table.remove(v60_.unmountedObjects, v62_)
					end
				end
				self:mountObjectToFork(v59_)
				return
			end
		elseif onLeave then
			for v64_ = #v60_.mountedObjects, 1, -1 do
				if v60_.mountedObjects[v64_] == v59_.id then
					v59_:removeDeleteListener(self, AutoLoadFork.onDeleteMountedObject)
					table.remove(v60_.mountedObjects, v64_)
					local v65_ = v60_.unmountedObjects
					local v66_ = {
						["objectId"] = v59_.id,
						["time"] = g_time
					}
					table.insert(v65_, v66_)
					return
				end
			end
		end
	end
end

-- Local values: spec, offsetX, offsetY, offsetZ, rotY
function AutoLoadFork:mountObjectToFork(object)
	local v69_ = self.spec_autoLoadFork
	local v70_ = 0
	local v71_ = 0
	local v72_ = 0
	if object.isPallet then
		v70_ = -object.spec_mountable.dynamicMountJointTransY or 0
		v71_ = object.size.length * 0.5 + object.size.lengthOffset
	elseif object:isa(Bale) then
		v71_ = object.width * 0.5
		v70_ = object.height * 0.2
		v72_ = 1.5707963267948966
	end
	if object.dynamicMountType == MountableObject.MOUNT_TYPE_KINEMATIC then
		object:unmountKinematic()
	end
	object:mountKinematic(self, v69_.jointNode, 0, v70_, v71_, 0, v72_, 0)
	local v73_ = v69_.mountedObjects
	local v74_ = object.id
	table.insert(v73_, v74_)
	object:addDeleteListener(self, AutoLoadFork.onDeleteMountedObject)
end

-- Local values: spec
function AutoLoadFork:getCanUnloadFork()
	return #self.spec_autoLoadFork.mountedObjects > 0
end

function AutoLoadFork.getIsForkUnloadingAllowed(self)
	return true
end

-- Local values: spec, i, mountedObjectId, object
function AutoLoadFork:doUnloadFork()
	local v77_ = self.spec_autoLoadFork
	for v78_ = #v77_.mountedObjects, 1, -1 do
		local v79_ = v77_.mountedObjects[v78_]
		local v80_ = NetworkUtil.getObject(v79_)
		if v80_ ~= nil then
			v80_:unmountKinematic()
			v80_:removeDeleteListener(self, AutoLoadFork.onDeleteMountedObject)
			table.remove(v77_.mountedObjects, v78_)
			local v81_ = v77_.unmountedObjects
			local v82_ = {
				["objectId"] = v80_.id,
				["time"] = g_time
			}
			table.insert(v81_, v82_)
		end
	end
end

function AutoLoadFork:actionEventUnloadFork(actionName, inputValue, callbackState, isAnalog)
	self:doUnloadFork()
end

-- Local values: spec, i, mountedObjectId
function AutoLoadFork:onUnmountObject(object)
	local v86_ = self.spec_autoLoadFork
	v86_.remountDistance = 5
	for v87_ = #v86_.mountedObjects, 1, -1 do
		if v86_.mountedObjects[v87_] == object.id then
			object:removeDeleteListener(self, AutoLoadFork.onDeleteMountedObject)
			table.remove(v86_.mountedObjects, v87_)
			local v88_ = v86_.unmountedObjects
			local v89_ = {
				["objectId"] = object.id,
				["time"] = g_time
			}
			table.insert(v88_, v89_)
			return
		end
	end
end

-- Local values: spec, i, mountedObjectId, object
function AutoLoadFork:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end
	if self.isServer then
		local v92_ = self.spec_autoLoadFork
		for v93_ = #v92_.mountedObjects, 1, -1 do
			local v94_ = v92_.mountedObjects[v93_]
			local v95_ = NetworkUtil.getObject(v94_)
			if v95_ ~= nil and v95_.addToPhysics ~= nil then
				v95_:addToPhysics()
			end
		end
	end
	return true
end

-- Local values: ret, spec, i, mountedObjectId, object
function AutoLoadFork:removeFromPhysics(superFunc)
	local v98_ = superFunc(self)
	if self.isServer then
		local v99_ = self.spec_autoLoadFork
		for v100_ = #v99_.mountedObjects, 1, -1 do
			local v101_ = v99_.mountedObjects[v100_]
			local v102_ = NetworkUtil.getObject(v101_)
			if v102_ ~= nil and v102_.removeFromPhysics ~= nil then
				v102_:removeFromPhysics()
			end
		end
	end
	return v98_
end
