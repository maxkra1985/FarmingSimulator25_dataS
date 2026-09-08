AutoLoaderBales = {}

function AutoLoaderBales.prerequisitesPresent(vehicleType)
	return true
end
function AutoLoaderBales.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("AutoLoaderBales")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.autoLoaderBales.trigger#node", "Bale pickup trigger node")
	v1_:register(XMLValueType.STRING, "vehicle.autoLoaderBales.baleTypes.baleType(?)#fillTypes", "List of supported fill types (if empty, all fill types are allowed)")
	v1_:register(XMLValueType.FLOAT, "vehicle.autoLoaderBales.baleTypes.baleType(?)#diameter", "Bale diameter", 0)
	v1_:register(XMLValueType.FLOAT, "vehicle.autoLoaderBales.baleTypes.baleType(?)#width", "Bale width", 0)
	v1_:register(XMLValueType.FLOAT, "vehicle.autoLoaderBales.baleTypes.baleType(?)#height", "Bale height", 0)
	v1_:register(XMLValueType.FLOAT, "vehicle.autoLoaderBales.baleTypes.baleType(?)#length", "Bale length", 0)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.autoLoaderBales.baleTypes.baleType(?).spawnPlace#node", "Node to spawn the bale")
	v1_:register(XMLValueType.INT, "vehicle.autoLoaderBales.baleTypes.baleType(?).spawnPlace#numBales", "Number of bales that can be loaded", 1)
	v1_:register(XMLValueType.VECTOR_3, "vehicle.autoLoaderBales.baleTypes.baleType(?).spawnPlace#offsetDirection", "Defines the axis in which the additional bales are moved", "0 1 0")
	v1_:register(XMLValueType.BOOL, "vehicle.autoLoaderBales.baleTypes.baleType(?).spawnPlace#mountBale", "Defines if the bale is mounted or just moved to the position of the spawn node", true)
	v1_:setXMLSpecializationType()
	local v2_ = Vehicle.xmlSchemaSavegame
	Bale.registerSavegameXMLPaths(v2_, "vehicles.vehicle(?).autoLoaderBales.bale(?)")
end

function AutoLoaderBales.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "autoLoaderBalesTriggerCallback", AutoLoaderBales.autoLoaderBalesTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "getAutoLoadBaleTypeFromBale", AutoLoaderBales.getAutoLoadBaleTypeFromBale)
	SpecializationUtil.registerFunction(vehicleType, "doAutoLoadBale", AutoLoaderBales.doAutoLoadBale)
	SpecializationUtil.registerFunction(vehicleType, "getIsBaleAutoLoadable", AutoLoaderBales.getIsBaleAutoLoadable)
end

function AutoLoaderBales.registerOverwrittenFunctions(vehicleType) end

function AutoLoaderBales.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AutoLoaderBales)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", AutoLoaderBales)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AutoLoaderBales)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AutoLoaderBales)
end

-- Local values: spec
function AutoLoaderBales:onLoad(savegame)
	local v_u_6_ = self.spec_autoLoaderBales
	v_u_6_.balesInTrigger = {}
	v_u_6_.balePickupDelay = 0
	v_u_6_.mountedBales = {}
	v_u_6_.numMountedBales = 0
	v_u_6_.loadedBaleType = nil
	if self.isServer then
		v_u_6_.triggerId = self.xmlFile:getValue("vehicle.autoLoaderBales.trigger#node", nil, self.components, self.i3dMappings)
		if v_u_6_.triggerId ~= nil then
			addTrigger(v_u_6_.triggerId, "autoLoaderBalesTriggerCallback", self)
		end
		v_u_6_.baleTypes = {}
		self.xmlFile:iterate("vehicle.autoLoaderBales.baleTypes.baleType", function(_, p7_)
			-- upvalues: (copy) self, (copy) v_u_6_
			local v8_ = {
				["spawnNode"] = self.xmlFile:getValue(p7_ .. ".spawnPlace#node", nil, self.components, self.i3dMappings)
			}
			if v8_.spawnNode == nil then
				Logging.xmlWarning(self.xmlFile, "Missing spawn place node in \'%s\'", p7_)
				return
			else
				v8_.numBales = self.xmlFile:getValue(p7_ .. ".spawnPlace#numBales", 1)
				v8_.offsetDirection = self.xmlFile:getValue(p7_ .. ".spawnPlace#offsetDirection", "0 1 0", true)
				v8_.mountBale = self.xmlFile:getValue(p7_ .. ".spawnPlace#mountBale", true)
				v8_.diameter = MathUtil.round(self.xmlFile:getValue(p7_ .. "#diameter", 0), 2)
				v8_.width = MathUtil.round(self.xmlFile:getValue(p7_ .. "#width", 0), 2)
				v8_.height = MathUtil.round(self.xmlFile:getValue(p7_ .. "#height", 0), 2)
				v8_.length = MathUtil.round(self.xmlFile:getValue(p7_ .. "#length", 0), 2)
				local v9_ = self.xmlFile:getValue(p7_ .. "#fillTypes")
				v8_.fillTypes = g_fillTypeManager:getFillTypesByNames(v9_, "Warning: \'" .. self.xmlFile:getFilename() .. "\' has invalid fillType \'%s\'.")
				if (v8_.diameter == 0 or v8_.width == 0) and (v8_.width == 0 or (v8_.height == 0 or v8_.length == 0)) then
					Logging.xmlWarning(self.xmlFile, "Incomplete bale size defintion in \'%s\'", p7_)
				else
					local v10_ = v_u_6_.baleTypes
					table.insert(v10_, v8_)
				end
			end
		end)
	end
end

function AutoLoaderBales:onLoadFinished(savegame)
	if savegame ~= nil and not savegame.resetVehicles then
		savegame.xmlFile:iterate(savegame.key .. ".autoLoaderBales.bale", function(_, p13_)
			-- upvalues: (copy) savegame, (copy) self
			local v14_ = {}
			Bale.loadBaleAttributesFromXMLFile(v14_, savegame.xmlFile, p13_, savegame.resetVehicles)
			local v15_ = Bale.new(self.isServer, self.isClient)
			if v15_:loadFromConfigXML(v14_.xmlFilename, 0, 0, 0, 0, 0, 0, v14_.uniqueId) then
				v15_:applyBaleAttributes(v14_)
				local v16_ = self:getAutoLoadBaleTypeFromBale(v15_)
				if v16_ ~= nil then
					self:doAutoLoadBale(v16_, v15_)
					return
				end
				v15_:delete()
			end
		end)
	end
end

-- Local values: spec, bale, _, bale, _
function AutoLoaderBales:onDelete()
	local v18_ = self.spec_autoLoaderBales
	if v18_.triggerId ~= nil then
		removeTrigger(v18_.triggerId)
	end
	if v18_.balesInTrigger ~= nil then
		for v19_, _ in pairs(v18_.balesInTrigger) do
			if v19_.removeDeleteListener ~= nil then
				v19_:removeDeleteListener(self, AutoLoaderBales.onBaleDeleted)
			end
		end
		table.clear(v18_.balesInTrigger)
	end
	if v18_.mountedBales ~= nil then
		for v20_, _ in pairs(v18_.mountedBales) do
			if v20_.removeDeleteListener ~= nil then
				v20_:removeDeleteListener(self, AutoLoaderBales.onDeleteAutoLoaderBalesObject)
			end
			v20_:unmountKinematic()
			v20_:setNeedsSaving(true)
		end
		table.clear(v18_.mountedBales)
	end
end

-- Local values: spec, index, bale, _, baleKey
function AutoLoaderBales:saveToXMLFile(xmlFile, key, usedModNames)
	local v24_ = self.spec_autoLoaderBales
	local v25_ = 0
	for v26_, _ in pairs(v24_.mountedBales) do
		v26_:saveToXMLFile(xmlFile, (string.format("%s.bale(%d)", key, v25_)))
		v25_ = v25_ + 1
	end
end

-- Local values: spec, baleMaxHeight, baleToLoad, baleTypeToLoad, object, num, baleType, _, y, _
function AutoLoaderBales:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v28_ = self.spec_autoLoaderBales
	local v29_ = v28_.balePickupDelay - 1
	v28_.balePickupDelay = math.max(v29_, 0)
	if v28_.balePickupDelay == 0 then
		local v30_ = 0
		local v31_ = nil
		local v32_ = nil
		for v33_, v34_ in pairs(v28_.balesInTrigger) do
			if v34_ > 0 and self:getIsBaleAutoLoadable(v33_) then
				local v35_ = self:getAutoLoadBaleTypeFromBale(v33_)
				if v35_ ~= nil and v28_.numMountedBales < v35_.numBales then
					local _, v36_, _ = getWorldTranslation(v33_.nodeId)
					if v30_ < v36_ then
						v32_ = v35_
						v31_ = v33_
						v30_ = v36_
					end
				end
			end
		end
		if v31_ ~= nil then
			self:doAutoLoadBale(v32_, v31_)
			v28_.balesInTrigger[v31_] = nil
			v28_.balePickupDelay = 10
		end
	end
end

-- Local values: spec
function AutoLoaderBales:onDeleteAutoLoaderBalesObject(object)
	local v39_ = self.spec_autoLoaderBales
	if v39_.mountedBales[object] ~= nil then
		v39_.mountedBales[object] = nil
		v39_.numMountedBales = v39_.numMountedBales - 1
	end
	v39_.balesInTrigger[object] = nil
	if next(v39_.mountedBales) == nil then
		v39_.loadedBaleType = nil
	end
end

-- Local values: spec
function AutoLoaderBales:onBaleDeleted(object)
	self.spec_autoLoaderBales.balesInTrigger[object] = nil
end

-- Local values: object, spec
function AutoLoaderBales:autoLoaderBalesTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if otherActorId == 0 then
		return
	else
		local v45_ = g_currentMission:getNodeObject(otherActorId)
		if v45_ == nil then
			return
		elseif v45_:isa(Bale) and (g_currentMission.accessHandler:canFarmAccess(self:getActiveFarm(), v45_) and v45_:getAllowPickup()) then
			local v46_ = self.spec_autoLoaderBales
			if onEnter then
				v46_.balesInTrigger[v45_] = (v46_.balesInTrigger[v45_] or 0) + 1
				if v46_.balesInTrigger[v45_] == 1 then
					v45_:addDeleteListener(self, AutoLoaderBales.onBaleDeleted)
					return
				end
			else
				v46_.balesInTrigger[v45_] = (v46_.balesInTrigger[v45_] or 0) - 1
				if v46_.balesInTrigger[v45_] <= 0 then
					v46_.balesInTrigger[v45_] = nil
					v45_:removeDeleteListener(self, AutoLoaderBales.onBaleDeleted)
				end
			end
		end
	end
end

-- Local values: spec, baleFillType, i, baleType, fillTypeAllowed, j
function AutoLoaderBales:getAutoLoadBaleTypeFromBale(bale)
	local v49_ = self.spec_autoLoaderBales
	local v50_ = bale:getFillType()
	for v51_ = 1, #v49_.baleTypes do
		local v52_ = v49_.baleTypes[v51_]
		if v49_.loadedBaleType == nil or v52_ == v49_.loadedBaleType then
			local v53_ = #v52_.fillTypes == 0
			for v54_ = 1, #v52_.fillTypes do
				if v52_.fillTypes[v54_] == v50_ then
					v53_ = true
					break
				end
			end
			if v53_ and bale:getBaleMatchesSize(v52_.diameter, v52_.width, v52_.height, v52_.length) then
				return v52_
			end
		end
	end
	return nil
end

-- Local values: spec, x, y, z, vx, vy, vz
function AutoLoaderBales:doAutoLoadBale(baleType, bale)
	local v58_ = self.spec_autoLoaderBales
	if baleType.mountBale then
		local v59_, v60_, v61_
		if bale.isRoundbale then
			v59_ = baleType.offsetDirection[1] * v58_.numMountedBales * bale.diameter
			v60_ = baleType.offsetDirection[2] * v58_.numMountedBales * bale.diameter
			v61_ = baleType.offsetDirection[3] * v58_.numMountedBales * bale.width
		else
			v59_ = baleType.offsetDirection[1] * v58_.numMountedBales * bale.width
			v60_ = baleType.offsetDirection[2] * v58_.numMountedBales * bale.height
			v61_ = baleType.offsetDirection[3] * v58_.numMountedBales * bale.length
		end
		bale:mountKinematic(self, baleType.spawnNode, v59_, v60_, v61_, 0, 0, 0)
		bale:setNeedsSaving(false)
		v58_.mountedBales[bale] = true
		bale:addDeleteListener(self, AutoLoaderBales.onDeleteAutoLoaderBalesObject)
		v58_.loadedBaleType = baleType
		v58_.numMountedBales = v58_.numMountedBales + 1
	else
		removeFromPhysics(bale.nodeId)
		setTranslation(bale.nodeId, getWorldTranslation(baleType.spawnNode))
		setWorldRotation(bale.nodeId, getWorldRotation(baleType.spawnNode))
		addToPhysics(bale.nodeId)
		local v62_, v63_, v64_ = getLinearVelocity(self:getParentComponent(baleType.spawnNode))
		setLinearVelocity(bale.nodeId, v62_, v63_, v64_)
	end
end

function AutoLoaderBales:getIsBaleAutoLoadable(bale)
	return bale.mountObject == nil
end
