AutoLoadForwarder = {}

function AutoLoadForwarder.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(AutomaticArmControlForwarder, specializations)
end
function AutoLoadForwarder.initSpecialization()
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("AutoLoadForwarder")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.autoLoadForwarder#idlePositionNode", "Crane will move to this position after the tree has been loaded")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.autoLoadForwarder#dropPositionNode", "Crane will move to this position before the tree is dropped on the loading bay")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.autoLoadForwarder#craneTreeJointNode", "Tree will be mounted to this node while mounted to the crane")
	v2_:register(XMLValueType.INT, "vehicle.autoLoadForwarder.loadPlaces#fillUnitIndex", "Fill unit index")
	v2_:register(XMLValueType.FLOAT, "vehicle.autoLoadForwarder.loadPlaces#dropOffset", "Y offset of crane to the load place before dropping the tree", 0)
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.autoLoadForwarder.loadPlaces.loadPlace(?)#node", "Load place node")
	v2_:register(XMLValueType.STRING, "vehicle.autoLoadForwarder.grabAnimation#name", "Grab animation name")
	v2_:register(XMLValueType.FLOAT, "vehicle.autoLoadForwarder.grabAnimation#speedScale", "Animation speed scale")
	v2_:register(XMLValueType.FLOAT, "vehicle.autoLoadForwarder.grabAnimation#filledTime", "Target animation time when a tree is grabbed")
	v2_:setXMLSpecializationType()
	Vehicle.xmlSchemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).autoLoadForwarder#treeI3DFilename", "Path to i3d file of the tree")
end

function AutoLoadForwarder.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onAutoLoadForwaderMountedTree")
end

function AutoLoadForwarder.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "mountTreeToCrane", AutoLoadForwarder.mountTreeToCrane)
	SpecializationUtil.registerFunction(vehicleType, "addTreeToLoadPlaces", AutoLoadForwarder.addTreeToLoadPlaces)
	SpecializationUtil.registerFunction(vehicleType, "removeMountedObject", AutoLoadForwarder.removeMountedObject)
	SpecializationUtil.registerFunction(vehicleType, "sortLoadedTreeObjects", AutoLoadForwarder.sortLoadedTreeObjects)
end

function AutoLoadForwarder.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", AutoLoadForwarder.getAreControlledActionsAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", AutoLoadForwarder.addToPhysics)
end

function AutoLoadForwarder.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AutoLoadForwarder)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AutoLoadForwarder)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AutoLoadForwarder)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AutoLoadForwarder)
	SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", AutoLoadForwarder)
end

-- Local values: spec
function AutoLoadForwarder:onLoad(savegame)
	local v_u_8_ = self.spec_autoLoadForwarder
	v_u_8_.idlePositionNode = self.xmlFile:getValue("vehicle.autoLoadForwarder#idlePositionNode", nil, self.components, self.i3dMappings)
	v_u_8_.dropPositionNode = self.xmlFile:getValue("vehicle.autoLoadForwarder#dropPositionNode", nil, self.components, self.i3dMappings)
	v_u_8_.craneTreeJointNode = self.xmlFile:getValue("vehicle.autoLoadForwarder#craneTreeJointNode", nil, self.components, self.i3dMappings)
	v_u_8_.loadPlaces = {}
	v_u_8_.loadPlaceFillUnitIndex = self.xmlFile:getValue("vehicle.autoLoadForwarder.loadPlaces#fillUnitIndex", 1)
	v_u_8_.loadPlaceDropOffset = self.xmlFile:getValue("vehicle.autoLoadForwarder.loadPlaces#dropOffset", 0)
	self.xmlFile:iterate("vehicle.autoLoadForwarder.loadPlaces.loadPlace", function(_, p9_)
		-- upvalues: (copy) self, (copy) v_u_8_
		local v10_ = {
			["node"] = self.xmlFile:getValue(p9_ .. "#node", nil, self.components, self.i3dMappings)
		}
		if v10_.node ~= nil then
			v10_.treeObject = nil
			local v11_ = v_u_8_.loadPlaces
			table.insert(v11_, v10_)
		end
	end)
	v_u_8_.grabAnimation = {}
	v_u_8_.grabAnimation.name = self.xmlFile:getValue("vehicle.autoLoadForwarder.grabAnimation#name")
	v_u_8_.grabAnimation.speedScale = self.xmlFile:getValue("vehicle.autoLoadForwarder.grabAnimation#speedScale", 1)
	v_u_8_.grabAnimation.filledTime = self.xmlFile:getValue("vehicle.autoLoadForwarder.grabAnimation#filledTime", 0.5)
	v_u_8_.grappleTreeId = nil
	v_u_8_.pendingIdleReturn = false
	v_u_8_.texts = {}
	v_u_8_.texts.warning_forwarderNoTreeInRange = g_i18n:getText("warning_forwarderNoTreeInRange")
end

-- Local values: spec, fillLevel, i3dFilename, onTreeLoaded, _, forestryLog
function AutoLoadForwarder:onPostLoad(savegame)
	local v14_ = self.spec_autoLoadForwarder
	if v14_.grabAnimation.name ~= nil then
		self:setAnimationTime(v14_.grabAnimation.name, 1, true)
	end
	local v15_ = MathUtil.round(self:getFillUnitFillLevel(v14_.loadPlaceFillUnitIndex))
	if v15_ > 0 and not savegame.resetVehicles then
		self:addFillUnitFillLevel(self:getOwnerFarmId(), v14_.loadPlaceFillUnitIndex, -math.huge, self:getFillUnitFillType(v14_.loadPlaceFillUnitIndex), ToolType.UNDEFINED, nil)
		local v16_ = savegame.xmlFile:getValue(savegame.key .. ".autoLoadForwarder#treeI3DFilename")
		if v16_ ~= nil then
			local v17_ = NetworkUtil.convertFromNetworkFilename(v16_)
			local function v20_(_, p18_, p19_, _)
				-- upvalues: (copy) self
				if p19_ then
					self:addTreeToLoadPlaces(p18_)
				end
			end
			for _ = 1, v15_ do
				local v21_ = ForestryLog.new(self.isServer, self.isClient)
				v21_:loadFromFilename(v17_, 0, 0, 0, 0, 0, 0, v20_, self, v21_)
			end
		end
	end
end

-- Local values: spec, i, loadPlace
function AutoLoadForwarder:onDelete()
	local v23_ = self.spec_autoLoadForwarder
	for v24_ = #v23_.loadPlaces, 1, -1 do
		local v25_ = v23_.loadPlaces[v24_]
		if v25_.treeObject ~= nil then
			v25_.treeObject:delete()
			v25_.treeObject = nil
		end
	end
end

-- Local values: spec, i, loadPlace
function AutoLoadForwarder:saveToXMLFile(xmlFile, key, usedModNames)
	local v29_ = self.spec_autoLoadForwarder
	if MathUtil.round(self:getFillUnitFillLevel(v29_.loadPlaceFillUnitIndex)) > 0 then
		for v30_ = 1, #v29_.loadPlaces do
			local v31_ = v29_.loadPlaces[v30_]
			if v31_.treeObject ~= nil then
				xmlFile:setValue(key .. "#treeI3DFilename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(v31_.treeObject.i3dFilename)))
				return
			end
		end
	end
end

-- Local values: spec, x, y, z, dx, dy, dz, treeId, nextLoadPlace, i, loadPlace, x, y, z, dx, dy, dz, treeObject, treeId, tx, ty, tz, dx, dy, dz
function AutoLoadForwarder:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v33_ = self.spec_autoLoadForwarder
	if Platform.gameplay.automaticVehicleControl then
		if self:getActionControllerDirection() == -1 then
			if v33_.grappleTreeId == nil then
				local v34_, v35_, v36_, v37_, v38_, v39_ = self:getAutomaticAlignmentCurrentTarget()
				if v34_ == nil then
					self:playControlledActions()
					return
				elseif self:getIsAutomaticAlignmentFinished() then
					local v40_ = v33_.craneTargetTreeId
					if v40_ == nil or not (entityExists(v40_) and self:mountTreeToCrane(v40_)) then
						v33_.grappleTreeId = nil
						self:playControlledActions()
						if v33_.grabAnimation.name ~= nil then
							self:playAnimation(v33_.grabAnimation.name, v33_.grabAnimation.speedScale, self:getAnimationTime(v33_.grabAnimation.name))
						end
					else
						v33_.grappleTreeId = v40_
						self:resetAutomaticAlignment()
						if v33_.grabAnimation.name ~= nil then
							self:setAnimationTime(v33_.grabAnimation.name, v33_.grabAnimation.filledTime, true)
						end
					end
					v33_.craneTargetTreeId = nil
				else
					self:doTreeArmAlignment(v34_, v35_, v36_, v37_, v38_, v39_, 1)
					if v33_.grabAnimation.name ~= nil and (not self:getIsAnimationPlaying(v33_.grabAnimation.name) and self:getAnimationTime(v33_.grabAnimation.name) > 0) then
						self:playAnimation(v33_.grabAnimation.name, -v33_.grabAnimation.speedScale, self:getAnimationTime(v33_.grabAnimation.name))
					end
					v33_.craneTargetTreeId = self:getAutomaticAlignmentTargetTree()
				end
			end
			local v41_ = nil
			for v42_ = 1, #v33_.loadPlaces do
				local v43_ = v33_.loadPlaces[v42_]
				if v43_.treeObject == nil then
					v41_ = v43_
					break
				end
			end
			if v41_ ~= nil then
				local v44_, v45_, v46_ = getWorldTranslation(v41_.node)
				local v47_, v48_, v49_ = localDirectionToWorld(v41_.node, 0, 0, 1)
				self:doTreeArmAlignment(v44_, v45_ + v33_.loadPlaceDropOffset, v46_, v47_, v48_, v49_, -1)
				if self:getIsAutomaticAlignmentFinished() then
					if v33_.grappleTreeId ~= nil and entityExists(v33_.grappleTreeId) then
						local v50_ = g_currentMission:getNodeObject(v33_.grappleTreeId)
						if v50_ ~= nil then
							self:addTreeToLoadPlaces(v50_)
						end
					end
					v33_.grappleTreeId = nil
					self:resetAutomaticAlignment()
					if self:getAutomaticAlignmentAvailableTargetTree() == nil or self:getFillUnitFreeCapacity(v33_.loadPlaceFillUnitIndex) < 1 then
						self:playControlledActions()
						if v33_.grabAnimation.name ~= nil then
							self:playAnimation(v33_.grabAnimation.name, v33_.grabAnimation.speedScale, self:getAnimationTime(v33_.grabAnimation.name))
							return
						end
					end
				end
			end
		elseif v33_.pendingIdleReturn then
			if v33_.idlePositionNode == nil then
				v33_.pendingIdleReturn = false
			else
				self:setEasyControlForcedTransMove(-1)
				local v51_, v52_, v53_ = getWorldTranslation(v33_.idlePositionNode)
				local v54_, v55_, v56_ = localDirectionToWorld(v33_.idlePositionNode, 0, 0, 1)
				self:doTreeArmAlignment(v51_, v52_, v53_, v54_, v55_, v56_, -1, true)
				if self:getIsAutomaticAlignmentFinished() then
					v33_.pendingIdleReturn = false
					return
				end
			end
		end
	end
end

-- Local values: spec, actionController
function AutoLoadForwarder:onRootVehicleChanged(rootVehicle)
	local v_u_59_ = self.spec_autoLoadForwarder
	local v60_ = rootVehicle.actionController
	if v60_ == nil then
		if v_u_59_.controlledAction ~= nil then
			v_u_59_.controlledAction:remove()
			v_u_59_.controlledAction = nil
		end
		return
	elseif v_u_59_.controlledAction == nil then
		v_u_59_.controlledAction = v60_:registerAction("forwarderLoading", nil, 4)
		v_u_59_.controlledAction:setCallback(self, AutoLoadForwarder.actionControllerEvent)
		v_u_59_.controlledAction:setIsAvailableFunction(function()
			-- upvalues: (copy) v_u_59_, (copy) self
			local v61_
			if v_u_59_.grappleTreeId == nil then
				v61_ = self:getFillUnitFreeCapacity(v_u_59_.loadPlaceFillUnitIndex) > 0
			else
				v61_ = false
			end
			return v61_
		end)
		v_u_59_.controlledAction:setActionIcons("LOAD_LOG", "LOAD_LOG", true)
	else
		v_u_59_.controlledAction:updateParent(v60_)
	end
end

-- Local values: spec
function AutoLoadForwarder:actionControllerEvent(direction)
	local v64_ = self.spec_autoLoadForwarder
	if direction < 0 then
		v64_.pendingIdleReturn = true
		self:resetAutomaticAlignment()
		if v64_.grabAnimation.name ~= nil then
			self:playAnimation(v64_.grabAnimation.name, v64_.grabAnimation.speedScale, self:getAnimationTime(v64_.grabAnimation.name))
		end
	else
		v64_.pendingIdleReturn = false
		self:resetAutomaticAlignment()
	end
	return true
end

-- Local values: treeId
function AutoLoadForwarder:getAreControlledActionsAllowed(superFunc)
	if self:getActionControllerDirection() == 1 and self:getAutomaticAlignmentTargetTree() == nil then
		return false, self.spec_autoLoadForwarder.texts.warning_forwarderNoTreeInRange
	else
		return superFunc(self)
	end
end

-- Local values: spec, i, loadPlace, rx, ry, rz
function AutoLoadForwarder:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end
	local v69_ = self.spec_autoLoadForwarder
	for v70_ = 1, #v69_.loadPlaces do
		local v71_ = v69_.loadPlaces[v70_]
		if v71_.treeObject ~= nil then
			local v72_, v73_, v74_ = getRotation(v71_.treeObject.nodeId)
			v71_.treeObject:mountKinematic(self, v71_.node, 0, 0, 0, v72_, v73_, v74_)
			SpecializationUtil.raiseEvent(self, "onAutoLoadForwaderMountedTree", v71_.treeObject.nodeId)
		end
	end
	return true
end

-- Local values: treeObject, spec, radius, rx, _, rz
function AutoLoadForwarder:mountTreeToCrane(treeId)
	local v77_ = g_currentMission:getNodeObject(treeId)
	if v77_ == nil then
		return false
	end
	local v78_ = self.spec_autoLoadForwarder
	local v79_ = getUserAttribute(treeId, "logRadius") or 0.5
	local v80_, _, v81_ = localRotationToLocal(treeId, v78_.craneTreeJointNode, 0, 0, 0)
	local v82_ = math.abs(v80_) < 1.5707963267948966 and 0 or v80_
	v77_:mountKinematic(self, v78_.craneTreeJointNode, 0, -v79_, 0, v82_, 0, v81_)
	SpecializationUtil.raiseEvent(self, "onAutoLoadForwaderMountedTree", v77_.nodeId)
	return true
end

-- Local values: spec, i, loadPlace, rx, _, rz
function AutoLoadForwarder:addTreeToLoadPlaces(treeObject)
	local v85_ = self.spec_autoLoadForwarder
	self:addFillUnitFillLevel(self:getOwnerFarmId(), v85_.loadPlaceFillUnitIndex, 1, self:getFillUnitFirstSupportedFillType(v85_.loadPlaceFillUnitIndex), ToolType.UNDEFINED, nil)
	for v86_ = 1, #v85_.loadPlaces do
		local v87_ = v85_.loadPlaces[v86_]
		if v87_.treeObject == nil then
			local v88_, _, v89_ = localRotationToLocal(treeObject.nodeId, v87_.node, 0, 0, 0)
			local v90_ = math.abs(v88_) < 1.5707963267948966 and 0 or 3.141592653589793
			treeObject:mountKinematic(self, v87_.node, 0, 0, 0, v90_, 0, v89_)
			v87_.treeObject = treeObject
			SpecializationUtil.raiseEvent(self, "onAutoLoadForwaderMountedTree", treeObject.nodeId)
			return
		end
	end
	treeObject:delete()
end

-- Local values: spec, i, loadPlace
function AutoLoadForwarder:removeMountedObject(object, isDeleting)
	local v93_ = self.spec_autoLoadForwarder
	for v94_ = 1, #v93_.loadPlaces do
		local v95_ = v93_.loadPlaces[v94_]
		if v95_.treeObject == object then
			v95_.treeObject = nil
			self:addFillUnitFillLevel(self:getOwnerFarmId(), v93_.loadPlaceFillUnitIndex, -1, self:getFillUnitFirstSupportedFillType(v93_.loadPlaceFillUnitIndex), ToolType.UNDEFINED, nil)
		end
	end
	self:sortLoadedTreeObjects()
end

-- Local values: spec, i, loadPlace, foundTree, j, loadPlace2, rx, ry, rz
function AutoLoadForwarder:sortLoadedTreeObjects()
	local v97_ = self.spec_autoLoadForwarder
	for v98_ = 1, #v97_.loadPlaces do
		local v99_ = v97_.loadPlaces[v98_]
		if v99_.treeObject == nil then
			local v100_ = false
			for v101_ = v98_ + 1, #v97_.loadPlaces do
				local v102_ = v97_.loadPlaces[v101_]
				if v102_.treeObject ~= nil then
					local v103_, v104_, v105_ = getRotation(v102_.treeObject.nodeId)
					v102_.treeObject:mountKinematic(self, v99_.node, 0, 0, 0, v103_, v104_, v105_)
					v99_.treeObject = v102_.treeObject
					v102_.treeObject = nil
					v100_ = true
					break
				end
			end
			if not v100_ then
				break
			end
		end
	end
end
