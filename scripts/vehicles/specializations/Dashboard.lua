Dashboard = {}
source("dataS/scripts/vehicles/DashboardValueType.lua")
Dashboard.DEFAULT_MAX_UPDATE_DISTANCE = 7.5
Dashboard.DEFAULT_MAX_UPDATE_DISTANCE_CRITICAL = 20
Dashboard.GROUP_XML_KEY = "vehicle.dashboard.groups.group(?)"
Dashboard.TYPES = {}
Dashboard.TYPES.EMITTER = 0
Dashboard.TYPES.NUMBER = 1
Dashboard.TYPES.ANIMATION = 2
Dashboard.TYPES.ROT = 3
Dashboard.TYPES.TRANS = 4
Dashboard.TYPES.VISIBILITY = 5
Dashboard.TYPES.TEXT = 6
Dashboard.TYPES.SLIDER = 7
Dashboard.TYPES.MULTI_STATE = 8
Dashboard.TYPE_DATA = {}
Dashboard.COLORS = {}
Dashboard.COLORS.GREY = {
	0.3,
	0.3,
	0.3,
	1
}
Dashboard.COLORS.DARK_GREY = {
	0.15,
	0.15,
	0.15,
	1
}
Dashboard.COLORS.BLACK = {
	0.05,
	0.05,
	0.05,
	1
}
Dashboard.COLORS.LIGHT_GREEN = {
	0.05,
	0.15,
	0.05,
	1
}
Dashboard.COLORS.RED = {
	1,
	0,
	0,
	1
}
Dashboard.COLORS.GREEN = {
	0,
	1,
	0,
	1
}
Dashboard.COLORS.BLUE = {
	0,
	0,
	1,
	1
}
Dashboard.COLORS.YELLOW = {
	1,
	1,
	0,
	1
}
Dashboard.COLORS.ORANGE = {
	1,
	0.5,
	0,
	1
}
Dashboard.COLORS.WHITE = {
	1,
	1,
	1,
	1
}
Dashboard.compoundsXMLSchema = nil

function Dashboard.prerequisitesPresent(specializations)
	return true
end
function Dashboard.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("Dashboard")
	Dashboard.registerDashboardXMLPaths(v1_, "vehicle.dashboard.default")
	v1_:register(XMLValueType.STRING, Dashboard.GROUP_XML_KEY .. "#name", "Dashboard group name")
	v1_:register(XMLValueType.FLOAT, "vehicle.dashboard#maxUpdateDistance", "Max. distance to vehicle root to update connection hoses", Dashboard.DEFAULT_MAX_UPDATE_DISTANCE)
	v1_:register(XMLValueType.FLOAT, "vehicle.dashboard#maxUpdateDistanceCritical", "Max. distance to vehicle root to update critical connection hoses (All with type \'ROT\')", Dashboard.DEFAULT_MAX_UPDATE_DISTANCE_CRITICAL)
	v1_:register(XMLValueType.TIME, "vehicle.dashboard#tickIntervall", "If defined the low priority dashboard will get updated at this interval (otherwise every second frame)")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.dashboard.compounds.compound(?)#linkNode", "Link node for dashboard compound")
	v1_:register(XMLValueType.STRING, "vehicle.dashboard.compounds.compound(?)#filename", "Path to compound xml file")
	v1_:register(XMLValueType.STRING, "vehicle.dashboard.compounds.compound(?)#name", "Name of dashboard compound to load")
	v1_:register(XMLValueType.STRING_LIST, "vehicle.dashboard.compounds.compound(?)#configIds", "Configuration identifiers (the given configuations will be enabled, separated by whitespace)")
	v1_:register(XMLValueType.STRING, "vehicle.dashboard.compounds.compound(?).configurationDependency(?)#configName", "Name of the vehicle config")
	v1_:register(XMLValueType.INT, "vehicle.dashboard.compounds.compound(?).configurationDependency(?)#configIndex", "Index of the vehicle config")
	v1_:register(XMLValueType.BOOL, "vehicle.dashboard.compounds.compound(?).configurationDependency(?)#useCompound", "Use dashboard compound only when the defined configuration is set", false)
	v1_:register(XMLValueType.STRING_LIST, "vehicle.dashboard.compounds.compound(?).configurationDependency(?)#additionalConfigIds", "Dashboard config ids to be used when this vehicle config is active")
	v1_:register(XMLValueType.STRING_LIST, "vehicle.dashboard.compounds.compound(?).configurationDependency(?)#disabledConfigIds", "Dashboard config ids to be used when this vehicle config is active")
	v1_:setXMLSpecializationType()
	if Dashboard.compoundsXMLSchema == nil then
		Dashboard.compoundsXMLSchema = XMLSchema.new("dashboardCompounds")
	end
	Dashboard.compoundsXMLSchema:register(XMLValueType.NODE_INDEX, "dashboardCompounds.dashboardCompound(?)#node", "Root node in i3d file to load")
	Dashboard.compoundsXMLSchema:register(XMLValueType.STRING, "dashboardCompounds.dashboardCompound(?)#filename", "Path to i3d file")
	Dashboard.compoundsXMLSchema:register(XMLValueType.STRING, "dashboardCompounds.dashboardCompound(?)#name", "Name of dashboard compound")
	I3DUtil.registerI3dMappingXMLPaths(Dashboard.compoundsXMLSchema, "dashboardCompounds")
	Dashboard.registerDashboardXMLPaths(Dashboard.compoundsXMLSchema, "dashboardCompounds.dashboardCompound(?)")
	Dashboard.compoundsXMLSchema:register(XMLValueType.STRING, "dashboardCompounds.dashboardCompound(?).configuration(?)#id", "Identifier of the configuration")
	Dashboard.registerDashboardXMLPaths(Dashboard.compoundsXMLSchema, "dashboardCompounds.dashboardCompound(?).configuration(?)")
	ObjectChangeUtil.registerObjectChangeXMLPaths(Dashboard.compoundsXMLSchema, "dashboardCompounds.dashboardCompound(?).configuration(?)")
end

function Dashboard.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onRegisterDashboardValueTypes")
end

function Dashboard.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "registerDashboardValueType", Dashboard.registerDashboardValueType)
	SpecializationUtil.registerFunction(vehicleType, "updateDashboards", Dashboard.updateDashboards)
	SpecializationUtil.registerFunction(vehicleType, "updateDashboardValueType", Dashboard.updateDashboardValueType)
	SpecializationUtil.registerFunction(vehicleType, "loadDashboardGroupFromXML", Dashboard.loadDashboardGroupFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsDashboardGroupActive", Dashboard.getIsDashboardGroupActive)
	SpecializationUtil.registerFunction(vehicleType, "getDashboardGroupByName", Dashboard.getDashboardGroupByName)
	SpecializationUtil.registerFunction(vehicleType, "loadDashboardCompoundFromXML", Dashboard.loadDashboardCompoundFromXML)
	SpecializationUtil.registerFunction(vehicleType, "onDashboardCompoundLoaded", Dashboard.onDashboardCompoundLoaded)
	SpecializationUtil.registerFunction(vehicleType, "loadDashboardCompoundFromExternalXML", Dashboard.loadDashboardCompoundFromExternalXML)
	SpecializationUtil.registerFunction(vehicleType, "loadDashboardsFromXML", Dashboard.loadDashboardsFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadDashboardFromXML", Dashboard.loadDashboardFromXML)
	SpecializationUtil.registerFunction(vehicleType, "setDashboardsDirty", Dashboard.setDashboardsDirty)
	SpecializationUtil.registerFunction(vehicleType, "getDashboardValue", Dashboard.getDashboardValue)
end

function Dashboard.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Dashboard)
	SpecializationUtil.registerEventListener(vehicleType, "onPreInitComponentPlacement", Dashboard)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Dashboard)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Dashboard)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Dashboard)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateEnd", Dashboard)
end

-- Local values: spec, i, baseKey, group
function Dashboard:onLoad(savegame)
	local v6_ = self.spec_dashboard
	v6_.dashboards = {}
	v6_.groupDashboards = {}
	v6_.dashboardsByValueType = {}
	v6_.dashboardsByValueTypeDirty = {}
	v6_.tickDashboards = {}
	v6_.criticalDashboards = {}
	v6_.numDashboards = 0
	v6_.groups = {}
	v6_.sortedGroups = {}
	v6_.groupUpdateIndex = 1
	v6_.hasGroups = false
	v6_.dashboardTypesLoaded = false
	v6_.dashboardValueTypes = {}
	v6_.sharedLoadRequestIds = {}
	local v7_ = 0
	while true do
		local v8_ = string.format("%s.groups.group(%d)", "vehicle.dashboard", v7_)
		if not self.xmlFile:hasProperty(v8_) then
			break
		end
		local v9_ = {}
		if self:loadDashboardGroupFromXML(self.xmlFile, v8_, v9_) then
			v6_.groups[v9_.name] = v9_
			local v10_ = v6_.sortedGroups
			table.insert(v10_, v9_)
			v6_.hasGroups = true
		end
		v7_ = v7_ + 1
	end
	v6_.isDirty = false
	v6_.isDirtyTick = false
	v6_.tickIntervall = self.xmlFile:getValue("vehicle.dashboard#tickIntervall")
	v6_.timeSinceLastTick = 0
	v6_.maxUpdateDistance = self.xmlFile:getValue("vehicle.dashboard#maxUpdateDistance", Dashboard.DEFAULT_MAX_UPDATE_DISTANCE)
	v6_.maxUpdateDistanceCritical = self.xmlFile:getValue("vehicle.dashboard#maxUpdateDistanceCritical", Dashboard.DEFAULT_MAX_UPDATE_DISTANCE_CRITICAL)
	v6_.lastUpdateDistance = math.huge
end

-- Local values: spec, _, dashboardValueType
function Dashboard:onPreInitComponentPlacement(savegame)
	local v_u_12_ = self.spec_dashboard
	if self.isClient then
		SpecializationUtil.raiseEvent(self, "onRegisterDashboardValueTypes")
		v_u_12_.dashboardTypesLoaded = true
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.default")
		for _, v13_ in ipairs(v_u_12_.dashboardValueTypes) do
			v13_:loadFromXML(self.xmlFile, self)
		end
		v_u_12_.dashboardCompounds = {}
		self.xmlFile:iterate("vehicle.dashboard.compounds.compound", function(_, p14_)
			-- upvalues: (copy) self, (copy) v_u_12_
			local v15_ = {}
			if self:loadDashboardCompoundFromXML(self.xmlFile, p14_, v15_) then
				local v16_ = v_u_12_.dashboardCompounds
				table.insert(v16_, v15_)
			end
		end)
	end
	if not self.isClient or v_u_12_.numDashboards == 0 then
		SpecializationUtil.removeEventListener(self, "onUpdate", Dashboard)
		SpecializationUtil.removeEventListener(self, "onUpdateTick", Dashboard)
	end
end

-- Local values: spec, _, sharedLoadRequestId
function Dashboard:onDelete()
	local v18_ = self.spec_dashboard
	if v18_.sharedLoadRequestIds ~= nil then
		for _, v19_ in ipairs(v18_.sharedLoadRequestIds) do
			g_i3DManager:releaseSharedI3DFile(v19_)
		end
		v18_.sharedLoadRequestIds = nil
	end
end

-- Local values: spec
function Dashboard:registerDashboardValueType(dashboardValueType)
	local v22_ = self.spec_dashboard
	local v23_ = v22_.dashboardValueTypes
	table.insert(v23_, dashboardValueType)
	if v22_.dashboardTypesLoaded then
		dashboardValueType:loadFromXML(self.xmlFile, self)
	end
end

-- Local values: spec, group, _, dashboards
function Dashboard:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local v26_ = self.spec_dashboard
		if v26_.hasGroups then
			local v27_ = v26_.sortedGroups[v26_.groupUpdateIndex]
			if self:getIsDashboardGroupActive(v27_) ~= v27_.isActive then
				v27_.isActive = not v27_.isActive
				self:updateDashboards(v26_.groupDashboards, dt, true)
				self:updateDashboards(v26_.tickDashboards, dt, true)
				self:updateDashboards(v26_.criticalDashboards, dt, true)
				for _, v28_ in pairs(v26_.dashboardsByValueType) do
					self:updateDashboards(v28_, dt, true)
				end
			end
			v26_.groupUpdateIndex = v26_.groupUpdateIndex + 1
			if v26_.groupUpdateIndex > #v26_.sortedGroups then
				v26_.groupUpdateIndex = 1
			end
		end
		if self.currentUpdateDistance < v26_.maxUpdateDistanceCritical or v26_.isDirty then
			self:updateDashboards(v26_.criticalDashboards, dt)
			v26_.isDirty = false
		end
		if v26_.isDirtyTick then
			self:raiseActive()
		end
	end
end

-- Local values: spec, updateAllowed, valueType, dashboards
function Dashboard:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local v31_ = self.spec_dashboard
		if self.currentUpdateDistance < v31_.maxUpdateDistance or v31_.isDirtyTick then
			local v32_ = true
			if v31_.tickIntervall ~= nil then
				v31_.timeSinceLastTick = v31_.timeSinceLastTick + dt
				if v31_.timeSinceLastTick < v31_.tickIntervall then
					v32_ = false
				else
					v31_.timeSinceLastTick = 0
				end
			end
			if v32_ then
				self:updateDashboards(v31_.tickDashboards, dt)
				v31_.isDirtyTick = false
			end
		end
		if self.currentUpdateDistance < v31_.maxUpdateDistance then
			for v33_, v34_ in pairs(v31_.dashboardsByValueType) do
				if v31_.dashboardsByValueTypeDirty[v33_] then
					self:updateDashboards(v34_, dt, true)
					v31_.dashboardsByValueTypeDirty[v33_] = false
				end
			end
		end
	end
end

-- Local values: spec
function Dashboard:onUpdateEnd(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local v37_ = self.spec_dashboard
		self:updateDashboards(v37_.tickDashboards, dt, true)
		self:updateDashboards(v37_.criticalDashboards, dt, true)
	end
end

function Dashboard:updateDashboardValueType(valueTypeName)
	self.spec_dashboard.dashboardsByValueTypeDirty[valueTypeName] = true
end

-- Local values: i, dashboard, isActive, j, value, min, max, center, isNumber, dir, limitFunc, maxValue
function Dashboard:updateDashboards(dashboards, dt, force)
	for v44_ = 1, #dashboards do
		local v45_ = dashboards[v44_]
		local v46_ = true
		for v47_ = 1, #v45_.groups do
			if not v45_.groups[v47_].isActive then
				v46_ = false
				break
			end
		end
		if v45_.valueType == nil then
			if force then
				v45_.stateFunc(self, v45_, true, nil, nil, v46_)
			end
		else
			local v48_, v49_, v50_, v51_, v52_ = v45_.valueType:getValue(v45_)
			if v45_.useStateChange then
				if v48_ ~= v45_.stateChangeLastValue then
					v45_.stateChangeLastValue = v48_
					if v45_.stateChangeValue == nil or (not v52_ and (v48_ and 1 or 0) or v48_) == v45_.stateChangeValue then
						v45_.stateChangeEndTime = g_time + v45_.stateChangeTime
					end
				end
				v48_ = v45_.stateChangeEndTime > g_time and 1 or 0
				v52_ = true
			end
			if v45_.minActiveValue ~= nil and v48_ < v45_.minActiveValue then
				v46_ = false
			end
			if v45_.maxActiveValue ~= nil and v45_.maxActiveValue < v48_ then
				v46_ = false
			end
			if v52_ then
				if v45_.scaleFactor ~= nil then
					v48_ = v48_ * v45_.scaleFactor
				end
				if v45_.offsetValue ~= nil then
					v48_ = v48_ + v45_.offsetValue
				end
				if v45_.valueMapping ~= nil then
					v48_ = v45_.valueMapping:get(v48_)
				end
			end
			if not v46_ then
				if v52_ then
					v48_ = v45_.idleValue
				else
					v48_ = v45_.idleValue > 0.5
				end
			end
			if v45_.doInterpolation then
				v48_ = not v52_ and (v48_ and 1 or 0) or v48_
				if v48_ ~= v45_.lastInterpolationValue then
					local v53_ = v48_ - v45_.lastInterpolationValue
					local v54_ = math.sign(v53_)
					local v55_ = math.min
					if v54_ < 0 then
						v55_ = math.max
					end
					v48_ = v55_(v45_.lastInterpolationValue + v45_.interpolationSpeed * v54_ * dt, v48_)
					v45_.lastInterpolationValue = v48_
				end
			end
			if v48_ ~= v45_.lastValue or force then
				v45_.lastValue = v48_
				local v56_
				if v52_ then
					if v49_ ~= nil then
						if v45_.doInterpolation then
							local v57_ = v45_.idleValue
							v49_ = math.min(v49_, v57_)
						end
						v48_ = math.max(v49_, v48_)
					end
					if v50_ ~= nil and v46_ then
						if v45_.doInterpolation then
							local v58_ = v45_.idleValue
							v50_ = math.max(v50_, v58_)
						end
						v48_ = math.min(v50_, v48_)
					end
					if v51_ == nil then
						v56_ = v50_
					else
						local v59_ = math.abs(v49_)
						local v60_ = math.abs(v50_)
						v56_ = math.max(v59_, v60_)
						if v48_ < v51_ then
							v48_ = -v48_ / v49_ * v56_
						elseif v51_ < v48_ then
							v48_ = v48_ / v50_ * v56_
						end
						v49_ = -v56_
					end
				else
					v56_ = v50_
				end
				v45_.stateFunc(self, v45_, v48_, v49_, v56_, v46_)
			end
		end
	end
end

function Dashboard:loadDashboardGroupFromXML(xmlFile, key, group)
	group.name = xmlFile:getValue(key .. "#name")
	if group.name == nil then
		Logging.xmlWarning(self.xmlFile, "Missing name for dashboard group \'%s\'", key)
		return false
	elseif self:getDashboardGroupByName(group.name) == nil then
		group.isActive = false
		return true
	else
		Logging.xmlWarning(self.xmlFile, "Duplicated dashboard group name \'%s\' for group \'%s\'", group.name, key)
		return false
	end
end

function Dashboard:getIsDashboardGroupActive(group)
	return true
end

function Dashboard:getDashboardGroupByName(name)
	return self.spec_dashboard.groups[name]
end

-- Local values: isAllowed, _, configDependencyKey, configName, configIndex, configIds, _, _configId, _, _configId, i, useCompound, dashboardXMLFile, compoundKey, i3dFilename, arguments, sharedLoadRequestId
function Dashboard:loadDashboardCompoundFromXML(xmlFile, key, compound)
	compound.linkNode = xmlFile:getValue(key .. "#linkNode", nil, self.components, self.i3dMappings)
	if compound.linkNode == nil then
		return false
	end
	compound.filename = xmlFile:getValue(key .. "#filename")
	if compound.filename == nil then
		return false
	end
	compound.filename = Utils.getFilename(compound.filename, self.baseDirectory)
	if compound.filename ~= nil then
		compound.name = xmlFile:getValue(key .. "#name")
		compound.configIds = xmlFile:getValue(key .. "#configIds", nil, true)
		local v71_ = true
		for _, v72_ in xmlFile:iterator(key .. ".configurationDependency") do
			local v73_ = xmlFile:getValue(v72_ .. "#configName")
			local v74_ = xmlFile:getValue(v72_ .. "#configIndex")
			if v73_ ~= nil and v74_ ~= nil then
				if self.configurations[v73_] == v74_ then
					local v75_ = xmlFile:getValue(v72_ .. "#additionalConfigIds", nil, true)
					if v75_ ~= nil then
						for _, v76_ in ipairs(v75_) do
							local v77_ = compound.configIds
							table.insert(v77_, v76_)
						end
					end
					local v78_ = xmlFile:getValue(v72_ .. "#disabledConfigIds", nil, true)
					if v78_ ~= nil then
						for _, v79_ in ipairs(v78_) do
							for v80_ = #compound.configIds, 1, -1 do
								if compound.configIds[v80_] == v79_ then
									table.remove(compound.configIds, v80_)
								end
							end
						end
					end
				elseif xmlFile:getValue(v72_ .. "#useCompound", false) then
					v71_ = false
				end
			end
		end
		if compound.name == nil then
			Logging.xmlWarning(xmlFile, "Missing name in \'%s\'", key)
			return false
		end
		if v71_ then
			local v_u_81_ = XMLFile.load("dashboardCompoundsXML", compound.filename, Dashboard.compoundsXMLSchema)
			if v_u_81_ ~= nil then
				local v_u_82_ = nil
				v_u_81_:iterate("dashboardCompounds.dashboardCompound", function(_, p83_)
					-- upvalues: (copy) v_u_81_, (copy) compound, (ref) v_u_82_
					if v_u_81_:getValue(p83_ .. "#name") == compound.name then
						v_u_82_ = p83_
					end
				end)
				if v_u_82_ == nil then
					Logging.xmlWarning(v_u_81_, "Unable to find compound by name \'%s\'", compound.name)
					v_u_81_:delete()
					return false
				end
				local v84_ = v_u_81_:getValue(v_u_82_ .. "#filename")
				if v84_ ~= nil then
					v84_ = Utils.getFilename(v84_, self.baseDirectory)
				end
				if v84_ == nil then
					Logging.xmlWarning(v_u_81_, "Missing filename for compound \'%s\'", compound.name)
					return false
				end
				local v85_ = {
					["dashboardXMLFile"] = v_u_81_,
					["compound"] = compound,
					["compoundKey"] = v_u_82_
				}
				local v86_ = self:loadSubSharedI3DFile(v84_, false, false, self.onDashboardCompoundLoaded, self, v85_)
				local v87_ = self.spec_dashboard.sharedLoadRequestIds
				table.insert(v87_, v86_)
				return true
			end
		end
	end
	return false
end

-- Local values: dashboardXMLFile, compound, compoundKey, components, i
function Dashboard:onDashboardCompoundLoaded(i3dNode, failedReason, args)
	local v91_ = args.dashboardXMLFile
	local v92_ = args.compound
	local v93_ = args.compoundKey
	if i3dNode ~= 0 then
		local v94_ = {}
		for v95_ = 1, getNumOfChildren(i3dNode) do
			local v96_ = {
				["node"] = getChildAt(i3dNode, v95_ - 1)
			}
			table.insert(v94_, v96_)
		end
		v92_.i3dMappings = {}
		I3DUtil.loadI3DMapping(v91_, "dashboardCompounds", v94_, v92_.i3dMappings, nil)
		self:loadDashboardCompoundFromExternalXML(v91_, v92_, v93_, v94_)
		delete(i3dNode)
	end
	v91_:delete()
end

-- Local values: node, _, configKey, isActive, id, _, _id, objects
function Dashboard:loadDashboardCompoundFromExternalXML(dashboardXMLFile, compound, compoundKey, components)
	local v102_ = dashboardXMLFile:getValue(compoundKey .. "#node", nil, components, compound.i3dMappings)
	if v102_ == nil then
		Logging.xmlWarning(dashboardXMLFile, "Unable to find node for compound at \'%s\'", compoundKey)
		return false
	end
	link(compound.linkNode, v102_)
	setTranslation(v102_, 0, 0, 0)
	setRotation(v102_, 0, 0, 0)
	self:loadDashboardsFromXML(dashboardXMLFile, compoundKey, nil, components, compound.i3dMappings, v102_)
	for _, v103_ in dashboardXMLFile:iterator(compoundKey .. ".configuration") do
		local v104_ = false
		local v105_ = dashboardXMLFile:getValue(v103_ .. "#id")
		if v105_ ~= nil and compound.configIds ~= nil then
			for _, v106_ in ipairs(compound.configIds) do
				if string.lower(v105_) == string.lower(v106_) then
					v104_ = true
				end
			end
		end
		local v107_ = {}
		ObjectChangeUtil.loadObjectChangeFromXML(dashboardXMLFile, v103_, v107_, components, compound)
		ObjectChangeUtil.setObjectChanges(v107_, v104_, compound)
		if v104_ then
			self:loadDashboardsFromXML(dashboardXMLFile, v103_, nil, components, compound.i3dMappings, v102_)
		end
	end
	return true
end

-- Local values: spec
function Dashboard:loadDashboardsFromXML(xmlFile, key, dashboardValueType, components, i3dMappings, parentNode)
	if self.isClient then
		local v_u_115_ = self.spec_dashboard
		xmlFile:iterate(key .. ".dashboard", function(_, p116_)
			-- upvalues: (copy) xmlFile, (copy) dashboardValueType, (copy) v_u_115_, (copy) self, (copy) components, (copy) i3dMappings, (copy) parentNode
			local v117_ = xmlFile:getValue(p116_ .. "#valueType")
			local v118_ = dashboardValueType
			local v119_ = 0
			if v118_ == nil and v117_ ~= nil then
				for _, v120_ in ipairs(v_u_115_.dashboardValueTypes) do
					if v117_ == v120_.name or v117_ == v120_.fullName then
						v119_ = v119_ + 1
						v118_ = v120_
					end
				end
			end
			if v119_ > 1 and v118_.xmlKey == nil then
				Logging.xmlWarning(xmlFile, "Dashboard valueType name \'%s\' is used in multiple specializations. Please specify with specialization prefix. (e.g. \'motorized.rpm\')", v117_)
			end
			if v117_ == nil or v118_ ~= nil then
				local v121_ = {}
				if self:loadDashboardFromXML(xmlFile, p116_, v121_, v118_, components or self.components, i3dMappings or self.i3dMappings, parentNode) then
					local v122_ = Dashboard.TYPE_DATA[v121_.displayTypeIndex].isCritical
					if v121_.isCritical ~= nil then
						v122_ = v121_.isCritical
					end
					if v122_ and (v118_ ~= nil and v118_.pollUpdate or v121_.doInterpolation) then
						local v123_ = v_u_115_.criticalDashboards
						table.insert(v123_, v121_)
					elseif v118_ == nil or (v118_.pollUpdate or v121_.doInterpolation) then
						if v118_ == nil then
							local v124_ = v_u_115_.groupDashboards
							table.insert(v124_, v121_)
						else
							local v125_ = v_u_115_.tickDashboards
							table.insert(v125_, v121_)
						end
					else
						local v126_ = v118_.fullName
						if v_u_115_.dashboardsByValueType[v126_] == nil then
							v_u_115_.dashboardsByValueType[v126_] = {}
							v_u_115_.dashboardsByValueTypeDirty[v126_] = false
						end
						local v127_ = v_u_115_.dashboardsByValueType[v126_]
						table.insert(v127_, v121_)
					end
					v_u_115_.numDashboards = v_u_115_.numDashboards + 1
				end
			else
				Logging.xmlWarning(xmlFile, "Unknown dashboard valueType \'%s\' for dashboard \'%s\'", v117_, p116_)
			end
		end)
	end
	return true
end

-- Local values: valueTypeName, displayType, displayTypeIndex, _, valueMappingKey, sourceValue, dashboardValue, groupsStr, groups, _, name, group, interpolationSpeed, typeData
function Dashboard:loadDashboardFromXML(xmlFile, key, dashboard, valueType, components, i3dMappings, parentNode)
	dashboard.valueType = valueType
	if valueType ~= nil then
		if valueType.isa == nil or not valueType:isa(DashboardValueType) then
			Logging.error("Deprecated call of Dashboard:loadDashboardFromXML. Needs to be called with DashboardValueType object or nil.")
			printCallstack()
			return false
		end
		local v136_ = xmlFile:getValue(key .. "#valueType")
		if v136_ ~= dashboard.valueType.name and v136_ ~= dashboard.valueType.fullName then
			return false
		end
	end
	local v137_ = xmlFile:getValue(key .. "#displayType")
	if v137_ == nil then
		Logging.xmlWarning(xmlFile, "Missing displayType for dashboard \'%s\'", key)
		return false
	end
	local v138_ = Dashboard.TYPES[string.upper(v137_)]
	if v138_ == nil then
		Logging.xmlWarning(xmlFile, "Unknown displayType \'%s\' for dashboard \'%s\'", v137_, key)
		return false
	end
	dashboard.displayTypeIndex = v138_
	dashboard.doInterpolation = xmlFile:getValue(key .. "#doInterpolation", false)
	dashboard.isCritical = xmlFile:getValue(key .. "#isCritical")
	dashboard.useStateChange = xmlFile:getValue(key .. "#useStateChange", false)
	if dashboard.useStateChange then
		dashboard.stateChangeValue = xmlFile:getValue(key .. "#stateChangeValue")
		dashboard.stateChangeTime = xmlFile:getValue(key .. "#stateChangeTime", 0.2)
		dashboard.stateChangeLastValue = nil
		dashboard.stateChangeEndTime = -math.huge
	end
	dashboard.idleValue = xmlFile:getValue(key .. "#idleValue", valueType == nil and 0 or (valueType.idleValue or 0))
	dashboard.lastInterpolationValue = dashboard.idleValue
	dashboard.offsetValue = xmlFile:getValue(key .. "#offsetValue")
	dashboard.scaleFactor = xmlFile:getValue(key .. "#scaleFactor")
	dashboard.minActiveValue = xmlFile:getValue(key .. "#minActiveValue")
	dashboard.maxActiveValue = xmlFile:getValue(key .. "#maxActiveValue")
	if xmlFile:hasProperty(key .. ".valueMapping") then
		dashboard.valueMapping = AnimCurve.new(linearInterpolator1)
		for _, v139_ in xmlFile:iterator(key .. ".valueMapping") do
			local v140_ = xmlFile:getValue(v139_ .. "#sourceValue")
			local v141_ = xmlFile:getValue(v139_ .. "#dashboardValue")
			if v140_ ~= nil and v141_ ~= nil then
				dashboard.valueMapping:addKeyframe({
					v141_,
					["time"] = v140_
				})
			end
		end
		if dashboard.valueMapping.numKeyframes == 0 then
			dashboard.valueMapping = nil
		end
	end
	dashboard.groups = {}
	local v142_ = xmlFile:getValue(key .. "#groups")
	if v142_ ~= nil then
		local v143_ = string.split(v142_, " ")
		for _, v144_ in ipairs(v143_) do
			local v145_ = self:getDashboardGroupByName(v144_)
			if v145_ == nil then
				Logging.xmlWarning(xmlFile, "Unable to find dashboard group \'%s\' for dashboard \'%s\'", v144_, key)
			else
				local v146_ = dashboard.groups
				table.insert(v146_, v145_)
			end
		end
	end
	if valueType == nil or valueType.stateFunction == nil then
		dashboard.stateFunc = Dashboard.defaultDashboardStateFunc
	else
		dashboard.stateFunc = valueType.stateFunction
	end
	local v147_
	if valueType == nil then
		v147_ = nil
	else
		v147_ = valueType:getInterpolationSpeed(dashboard)
	end
	dashboard.interpolationSpeed = xmlFile:getValue(key .. "#interpolationSpeed", v147_ or 0.005)
	local v148_ = Dashboard.TYPE_DATA[dashboard.displayTypeIndex]
	if v148_ == nil then
		return false
	end
	if not v148_.loadFunc(self, xmlFile, key, dashboard, components, i3dMappings, parentNode) then
		return false
	end
	if valueType ~= nil and (valueType.loadFunction ~= nil and not valueType.loadFunction(self, xmlFile, key, dashboard, components, i3dMappings, parentNode)) then
		return false
	end
	dashboard.lastValue = nil
	return true
end

-- Local values: typeData
function Dashboard:defaultDashboardStateFunc(dashboard, newValue, minValue, maxValue, isActive)
	Dashboard.TYPE_DATA[dashboard.displayTypeIndex].updateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
end

function Dashboard:setDashboardsDirty()
	self.spec_dashboard.isDirty = true
	self.spec_dashboard.isDirtyTick = true
	self:raiseActive()
end

-- Local values: object
function Dashboard:getDashboardValue(valueObject, valueFunc, dashboard)
	if type(valueFunc) == "number" or type(valueFunc) == "boolean" then
		return valueFunc
	elseif type(valueFunc) == "function" then
		return valueFunc(valueObject, dashboard)
	else
		local v159_ = valueObject[valueFunc]
		if type(v159_) == "function" then
			return valueObject[valueFunc](valueObject, dashboard)
		elseif type(v159_) == "number" or type(v159_) == "boolean" then
			return v159_
		else
			return nil
		end
	end
end

-- Local values: brandColor, vector
function Dashboard.getDashboardColor(xmlFile, colorStr, customEnvironment)
	if colorStr == nil then
		return nil
	elseif Dashboard.COLORS[string.upper(colorStr)] == nil then
		local v163_ = g_vehicleMaterialManager:getMaterialTemplateColorByName(colorStr, customEnvironment)
		if v163_ == nil then
			local v164_ = string.getVector(colorStr)
			if v164_ == nil or #v164_ < 3 then
				Logging.xmlWarning(xmlFile, "Unable to resolve color \'%s\'", colorStr)
				return nil
			else
				if #v164_ == 3 then
					v164_[4] = 1
				end
				return v164_
			end
		else
			return v163_
		end
	else
		return Dashboard.COLORS[string.upper(colorStr)]
	end
end

function Dashboard:warningAttributes(xmlFile, key, dashboard, isActive)
	dashboard.warningThresholdMin = xmlFile:getValue(key .. "#warningThresholdMin", -math.huge)
	dashboard.warningThresholdMax = xmlFile:getValue(key .. "#warningThresholdMax", math.huge)
	return true
end

-- Local values: typeData
function Dashboard.registerDisplayType(typeIndex, isCritical, schemaFunc, loadFunc, updateFunc)
	Dashboard.TYPE_DATA[typeIndex] = {
		["isCritical"] = isCritical,
		["schemaFunc"] = schemaFunc,
		["loadFunc"] = loadFunc,
		["updateFunc"] = updateFunc
	}
end
Dashboard.registerDisplayType(Dashboard.TYPES.EMITTER, false, function(p173_, p174_)
	p173_:register(XMLValueType.STRING, p174_ .. ".dashboard(?)#baseColor", "(EMITTER) Base color (DashboardColor OR BrandColor OR r g b a)")
	p173_:register(XMLValueType.STRING, p174_ .. ".dashboard(?)#emitColor", "(EMITTER) Emit color (DashboardColor OR BrandColor OR r g b a)")
	p173_:register(XMLValueType.FLOAT, p174_ .. ".dashboard(?)#intensity", "Intensity", 1)
	p173_:register(XMLValueType.BOOL, p174_ .. ".dashboard(?)#inverted", "(EMITTER) State will be inverted", false)
	p173_:register(XMLValueType.BOOL, p174_ .. ".dashboard(?)#toggleVisibility", "(EMITTER) If the mesh is not emitting (idle), the mesh will be hidden", false)
	p173_:register(XMLValueType.STRING, p174_ .. ".dashboard(?)#inactiveGroups", "(EMITTER) If defined, the inactive color/intensity will only be set if this group is active (if not active, the disabled color/intensity is used)")
	p173_:register(XMLValueType.FLOAT, p174_ .. ".dashboard(?)#disabledIntensity", "(EMITTER) Intensity while the dashboard group is not active")
	p173_:register(XMLValueType.STRING, p174_ .. ".dashboard(?)#disabledColor", "(EMITTER) Disabled emit color (DashboardColor OR BrandColor OR r g b a)")
	p173_:register(XMLValueType.FLOAT, p174_ .. ".dashboard(?)#inactiveIntensity", "(EMITTER) Intensity while the dashboard state is not active, but the group is active")
	p173_:register(XMLValueType.STRING, p174_ .. ".dashboard(?)#inactiveColor", "(EMITTER) Inactive emit color (DashboardColor OR BrandColor OR r g b a)")
	p173_:register(XMLValueType.BOOL, p174_ .. ".dashboard(?)#hideInactive", "(EMITTER) Hide the emitter shape when the dashboard is inactive", false)
	p173_:register(XMLValueType.BOOL, p174_ .. ".dashboard(?)#hideInactiveChildren", "(EMITTER) Hide all the children when the dashboard is inactive", false)
end, function(p175_, p176_, p177_, p178_, p179_, p180_, p181_)
	local v182_ = p176_:getValue(p177_ .. "#node", nil, p179_, p180_)
	if v182_ == nil then
		Logging.xmlWarning(p176_, "Missing node for emitter dashboard \'%s\'", p177_)
		return false
	end
	if p181_ ~= nil and not I3DUtil.getIsLinkedToNode(p181_, v182_) then
		Logging.xmlWarning(p176_, "Emitter dashboard node \'%s\' is not a child of the parent node \'%s\' in \'%s\'", getName(v182_), getName(p181_), p177_)
		return false
	end
	if not getHasClassId(v182_, ClassIds.SHAPE) then
		Logging.xmlWarning(p176_, "Emitter Dashboard node is not a shape! \'%s\' in \'%s\'", getName(v182_), p177_)
		return false
	end
	if not (getHasShaderParameter(v182_, "lightControl") or getHasShaderParameter(v182_, "lightIds0")) then
		Logging.xmlWarning(p176_, "Emitter dashboard shape not using \'lightControl\' or \'lightIds0\' shader parameter in \'%s\'", p177_)
		return false
	end
	p178_.node = v182_
	p178_.inverted = p176_:getValue(p177_ .. "#inverted", false)
	p178_.toggleVisibility = p176_:getValue(p177_ .. "#toggleVisibility", false)
	p178_.baseColor = Dashboard.getDashboardColor(p176_, p176_:getValue(p177_ .. "#baseColor"), p175_.customEnvironment)
	if p178_.baseColor ~= nil then
		setShaderParameter(p178_.node, "baseColor", p178_.baseColor[1], p178_.baseColor[2], p178_.baseColor[3], 1, false)
	end
	p178_.disabledIntensity = p176_:getValue(p177_ .. "#disabledIntensity")
	p178_.disabledColor = Dashboard.getDashboardColor(p176_, p176_:getValue(p177_ .. "#disabledColor"), p175_.customEnvironment)
	p178_.inactiveIntensity = p176_:getValue(p177_ .. "#inactiveIntensity")
	p178_.inactiveColor = Dashboard.getDashboardColor(p176_, p176_:getValue(p177_ .. "#inactiveColor"), p175_.customEnvironment)
	p178_.inactiveGroups = {}
	local v183_ = p176_:getValue(p177_ .. "#inactiveGroups")
	if v183_ ~= nil then
		local v184_ = string.split(v183_, " ")
		for _, v185_ in ipairs(v184_) do
			local v186_ = p175_:getDashboardGroupByName(v185_)
			if v186_ == nil then
				Logging.xmlWarning(p176_, "Unable to find inactive dashboard group \'%s\' for dashboard \'%s\'", v185_, p177_)
			else
				local v187_ = p178_.inactiveGroups
				table.insert(v187_, v186_)
			end
		end
	end
	p178_.emitColor = Dashboard.getDashboardColor(p176_, p176_:getValue(p177_ .. "#emitColor"), p175_.customEnvironment)
	if p178_.emitColor ~= nil then
		setShaderParameter(p178_.node, "emitColor", p178_.emitColor[1], p178_.emitColor[2], p178_.emitColor[3], 1, false)
	end
	p178_.intensity = p176_:getValue(p177_ .. "#intensity", 1)
	p178_.hideInactive = p176_:getValue(p177_ .. "#hideInactive", false)
	p178_.hideInactiveChildren = p176_:getValue(p177_ .. "#hideInactiveChildren", false)
	p178_.useLightControlShaderParameter = getHasShaderParameter(v182_, "lightControl")
	if p178_.stateFunc ~= nil then
		p178_.stateFunc(p175_, p178_, p178_.inverted, nil, nil, p178_.inverted)
	end
	return true
end, function(_, p188_, p189_, _, _, p190_)
	if type(p189_) == "number" then
		p189_ = p189_ > 0.5
	end
	local v191_ = 1
	local v192_ = nil
	if p188_.hideInactive then
		if not p190_ then
			setVisibility(p188_.node, false)
			return
		end
		setVisibility(p188_.node, true)
	end
	if p188_.hideInactiveChildren then
		for v193_ = 1, getNumOfChildren(p188_.node) do
			setVisibility(getChildAt(p188_.node, v193_ - 1), p190_)
		end
	end
	if p189_ ~= nil then
		if p188_.inverted then
			p189_ = not p189_
		end
		local v194_ = p188_.inactiveIntensity
		v192_ = p188_.inactiveColor
		for v195_ = 1, #p188_.inactiveGroups do
			if not p188_.inactiveGroups[v195_].isActive then
				v194_ = p188_.disabledIntensity
				v192_ = p188_.disabledColor
				break
			end
		end
		v191_ = p189_ and p188_.intensity or (v194_ or p188_.idleValue)
		if p189_ then
			v192_ = p188_.emitColor or v192_
		end
		if not p190_ then
			v191_ = p188_.disabledIntensity or p188_.idleValue
			v192_ = p188_.disabledColor
		end
		if p188_.toggleVisibility then
			setVisibility(p188_.node, p189_)
		end
	end
	local v196_
	if v192_ == nil then
		v196_ = false
	else
		setShaderParameter(p188_.node, "emitColor", v192_[1], v192_[2], v192_[3], 1, false)
		v196_ = v191_ > 0
	end
	if p188_.baseColor == nil then
		if v196_ then
			setShaderParameter(p188_.node, "baseColor", 0, 0, 0, 1, false)
		else
			setShaderParameter(p188_.node, "baseColor", nil, nil, nil, 0, false)
		end
	else
		setShaderParameter(p188_.node, "baseColor", p188_.baseColor[1], p188_.baseColor[2], p188_.baseColor[3], 1, false)
	end
	if p188_.useLightControlShaderParameter then
		setShaderParameter(p188_.node, "lightControl", v191_, nil, nil, nil, false)
	else
		setShaderParameter(p188_.node, "lightIds0", v191_, v191_, v191_, v191_, false)
		setShaderParameter(p188_.node, "lightIds1", v191_, v191_, v191_, v191_, false)
		setShaderParameter(p188_.node, "lightIds2", v191_, v191_, v191_, v191_, false)
		setShaderParameter(p188_.node, "lightIds3", v191_, v191_, v191_, v191_, false)
	end
end)
Dashboard.registerDisplayType(Dashboard.TYPES.NUMBER, false, function(p197_, p198_)
	p197_:register(XMLValueType.NODE_INDEX, p198_ .. ".dashboard(?)#numbers", "(NUMBER) Numbers node")
	p197_:register(XMLValueType.STRING, p198_ .. ".dashboard(?)#numberColor", "(NUMBER) Numbers color (DashboardColor OR BrandColor OR r g b a)")
	p197_:register(XMLValueType.INT, p198_ .. ".dashboard(?)#precision", "(NUMBER) Precision", 1)
	p197_:register(XMLValueType.STRING, p198_ .. ".dashboard(?)#font", "(NUMBER) Name of font to apply to mesh", "DIGIT")
	p197_:register(XMLValueType.BOOL, p198_ .. ".dashboard(?)#hasNormalMap", "(NUMBER) Normal map will be applied to number decals", false)
	p197_:register(XMLValueType.FLOAT, p198_ .. ".dashboard(?)#emissiveScale", "(NUMBER) Scale of emissive map", 0.2)
end, function(p199_, p200_, p201_, p202_, p203_, p204_, p205_)
	p202_.numbers = p200_:getValue(p201_ .. "#numbers", nil, p203_, p204_)
	if p205_ ~= nil and not I3DUtil.getIsLinkedToNode(p205_, p202_.numbers) then
		Logging.xmlWarning(p200_, "Numbers dashboard node \'%s\' is not a child of the parent node \'%s\' in \'%s\'", getName(p202_.numbers), getName(p205_), p201_)
		return false
	end
	p202_.numberColor = Dashboard.getDashboardColor(p200_, p200_:getValue(p201_ .. "#numberColor"), p199_.customEnvironment)
	if p202_.numberColor == nil then
		p202_.numberColor = {
			0.9,
			0.9,
			0.9,
			1
		}
	end
	if p202_.numbers == nil then
		Logging.xmlWarning(p200_, "Missing numbers node for dashboard \'%s\'", p201_)
		return false
	end
	p202_.precision = p200_:getValue(p201_ .. "#precision", 1)
	p202_.numChildren = getNumOfChildren(p202_.numbers)
	p202_.fontMaterialName = p200_:getValue(p201_ .. "#font", "DIGIT")
	p202_.hasNormalMap = p200_:getValue(p201_ .. "#hasNormalMap", false)
	p202_.emissiveScale = p200_:getValue(p201_ .. "#emissiveScale", 0.2)
	XMLUtil.checkDeprecatedXMLElements(p200_, p201_ .. "#hiddenAlpha")
	p202_.fontMaterial = g_materialManager:getFontMaterial(p202_.fontMaterialName, p199_.customEnvironment)
	if p202_.fontMaterial == nil then
		Logging.xmlWarning(p200_, "Unknown font \'%s\' in \'%s\'", p202_.fontMaterialName, p201_)
		return false
	end
	p202_.numberNodes = {}
	if p202_.numChildren - p202_.precision <= 0 then
		Logging.xmlWarning(p200_, "Not enough number meshes for vehicle hud \'%s\'", p201_)
		return false
	end
	for v206_ = 1, p202_.numChildren do
		local v207_ = getChildAt(p202_.numbers, v206_ - 1)
		if v207_ ~= nil then
			p202_.fontMaterial:assignFontMaterialToNode(v207_, p202_.hasNormalMap)
			if p202_.numberColor ~= nil then
				p202_.fontMaterial:setFontCharacterColor(v207_, p202_.numberColor[1], p202_.numberColor[2], p202_.numberColor[3], 1, p202_.emissiveScale)
			end
			setVisibility(v207_, false)
			local v208_ = p202_.numberNodes
			table.insert(v208_, v207_)
		end
	end
	p202_.maxValue = 10 ^ p202_.numChildren - 1 / 10 ^ p202_.precision
	return true
end, function(_, p209_, p210_, _, _, p211_)
	if type(p210_) == "number" then
		local v212_ = string.format
		local v213_ = "%." .. p209_.precision .. "f"
		local v214_ = tonumber(v212_(v213_, p210_)) * 10 ^ p209_.precision
		local v215_ = math.floor(v214_)
		for v216_ = 1, #p209_.numberNodes do
			local v217_ = p209_.numberNodes[v216_]
			if v215_ > 0 then
				local v218_ = v215_ / 10
				local v219_ = v215_ - math.floor(v218_) * 10
				v215_ = (v215_ - v219_) / 10
				p209_.fontMaterial:setFontCharacter(v217_, ("%d"):format(v219_))
				setVisibility(v217_, true)
			else
				p209_.fontMaterial:setFontCharacter(v217_, "0")
				if not p211_ or v216_ - 1 > p209_.precision then
					setVisibility(v217_, false)
				end
			end
		end
	elseif type(p210_) == "string" then
		local v220_ = p210_:len()
		for v221_ = 1, #p209_.numberNodes do
			local v222_ = p209_.numberNodes[v221_]
			if v221_ <= v220_ then
				local v223_ = v220_ - (v221_ - 1)
				p209_.fontMaterial:setFontCharacter(v222_, p210_:sub(v223_, v223_))
			end
			setVisibility(v222_, p211_)
		end
	end
end)
Dashboard.registerDisplayType(Dashboard.TYPES.ANIMATION, true, function(p224_, p225_)
	p224_:register(XMLValueType.STRING, p225_ .. ".dashboard(?)#animName", "(ANIMATION) Animation name")
	p224_:register(XMLValueType.FLOAT, p225_ .. ".dashboard(?)#minValueAnim", "(ANIMATION) Min. reference value for animation")
	p224_:register(XMLValueType.FLOAT, p225_ .. ".dashboard(?)#maxValueAnim", "(ANIMATION) Max. reference value for animation")
end, function(_, p226_, p227_, p228_, _, _)
	p228_.animName = p226_:getValue(p227_ .. "#animName")
	if p228_.animName == nil then
		Logging.xmlWarning(p226_, "Missing animation for dashboard \'%s\'", p227_)
		return false
	end
	p228_.minValueAnim = p226_:getValue(p227_ .. "#minValueAnim")
	p228_.maxValueAnim = p226_:getValue(p227_ .. "#maxValueAnim")
	return true
end, function(p229_, p230_, p231_, p232_, p233_, _)
	if p230_.animName ~= nil then
		if p229_:getAnimationExists(p230_.animName) then
			local v234_ = type(p231_) == "boolean" and (p231_ and 1 or 0) or p231_
			local v235_
			if p230_.minValueAnim == nil or p230_.maxValueAnim == nil then
				local v236_ = p232_ or 0
				v235_ = MathUtil.round((v234_ - v236_) / ((p233_ or 1) - v236_), 3)
			else
				local v237_ = p230_.minValueAnim
				local v238_ = p230_.maxValueAnim
				local v239_ = math.clamp(v234_, v237_, v238_)
				v235_ = MathUtil.round((v239_ - p230_.minValueAnim) / (p230_.maxValueAnim - p230_.minValueAnim), 3)
			end
			p229_:setAnimationTime(p230_.animName, v235_, true)
			return
		end
		Logging.xmlWarning(p229_.xmlFile, "Unknown animation name \'%s\' for dashboard!", p230_.animName)
		p230_.animName = nil
	end
end)
Dashboard.registerDisplayType(Dashboard.TYPES.ROT, true, function(p240_, p241_)
	p240_:register(XMLValueType.FLOAT, p241_ .. ".dashboard(?)#rotAxis", "(ROT) Rotation axis")
	p240_:register(XMLValueType.STRING, p241_ .. ".dashboard(?)#minRot", "(ROT) Min. rotation (Rotation value if rotAxis is given | Rotation Vector of rotAxis is not given)")
	p240_:register(XMLValueType.STRING, p241_ .. ".dashboard(?)#maxRot", "(ROT) Max. rotation (Rotation value if rotAxis is given | Rotation Vector of rotAxis is not given)")
	p240_:register(XMLValueType.FLOAT, p241_ .. ".dashboard(?)#minValueRot", "(ROT) Min. reference value for rotation")
	p240_:register(XMLValueType.FLOAT, p241_ .. ".dashboard(?)#maxValueRot", "(ROT) Max. reference value for rotation")
	p240_:register(XMLValueType.FLOAT, p241_ .. ".dashboard(?)#intensity", "Intensity", 1)
end, function(_, p242_, p243_, p244_, p245_, p246_, p247_)
	p244_.node = p242_:getValue(p243_ .. "#node", nil, p245_, p246_)
	if p244_.node == nil then
		Logging.xmlWarning(p242_, "Missing \'node\' for dashboard \'%s\'", p243_)
		return false
	end
	if p247_ ~= nil and not I3DUtil.getIsLinkedToNode(p247_, p244_.node) then
		Logging.xmlWarning(p242_, "Rotation dashboard node \'%s\' is not a child of the parent node \'%s\' in \'%s\'", getName(p244_.node), getName(p247_), p243_)
		return false
	end
	p244_.rotAxis = p242_:getValue(p243_ .. "#rotAxis")
	local v248_ = p242_:getValue(p243_ .. "#minRot")
	if v248_ == nil then
		Logging.xmlWarning(p242_, "Missing \'minRot\' attribute for dashboard \'%s\'", p243_)
		return false
	end
	if p244_.rotAxis == nil then
		p244_.minRot = v248_:getRadians(3)
	else
		local v249_ = tonumber(v248_)
		p244_.minRot = math.rad(v249_)
	end
	local v250_ = p242_:getValue(p243_ .. "#maxRot")
	if v250_ == nil then
		Logging.xmlWarning(p242_, "Missing \'maxRot\' attribute for dashboard \'%s\'", p243_)
		return false
	end
	if p244_.rotAxis == nil then
		p244_.maxRot = v250_:getRadians(3)
	else
		local v251_ = tonumber(v250_)
		p244_.maxRot = math.rad(v251_)
	end
	p244_.minValueRot = p242_:getValue(p243_ .. "#minValueRot")
	p244_.maxValueRot = p242_:getValue(p243_ .. "#maxValueRot")
	p244_.intensity = p242_:getValue(p243_ .. "#intensity")
	if p244_.intensity ~= nil and (getHasClassId(p244_.node, ClassIds.SHAPE) and getHasShaderParameter(p244_.node, "lightControl")) then
		setShaderParameter(p244_.node, "lightControl", p244_.intensity, 0, 0, 0, false)
	end
	return true
end, function(p252_, p253_, p254_, p255_, p256_, _)
	local v257_
	if type(p254_) == "boolean" then
		v257_ = p254_ and 1 or 0
	elseif p253_.minValueRot == nil or p253_.maxValueRot == nil then
		local v258_ = p255_ or 0
		v257_ = (p254_ - v258_) / ((p256_ or 1) - v258_)
	else
		local v259_ = p253_.minValueRot
		local v260_ = p253_.maxValueRot
		local v261_ = math.clamp(p254_, v259_, v260_)
		v257_ = MathUtil.round((v261_ - p253_.minValueRot) / (p253_.maxValueRot - p253_.minValueRot), 3)
	end
	if p253_.rotAxis == nil then
		local v262_, v263_, v264_ = MathUtil.vector3ArrayLerp(p253_.minRot, p253_.maxRot, v257_)
		setRotation(p253_.node, v262_, v263_, v264_)
		if p252_.setCharacterTargetNodeStateDirty ~= nil then
			p252_:setCharacterTargetNodeStateDirty(p253_.node)
		end
		if p252_.setMovingToolDirty ~= nil then
			p252_:setMovingToolDirty(p253_.node)
		end
	else
		local v265_, v266_, v267_ = getRotation(p253_.node)
		local v268_ = MathUtil.lerp(p253_.minRot, p253_.maxRot, v257_)
		if p253_.rotAxis == 1 then
			v265_ = v268_
			v268_ = v267_
		elseif p253_.rotAxis == 2 then
			v266_ = v268_
			v268_ = v267_
		end
		setRotation(p253_.node, v265_, v266_, v268_)
		if p252_.setCharacterTargetNodeStateDirty ~= nil then
			p252_:setCharacterTargetNodeStateDirty(p253_.node)
		end
		if p252_.setMovingToolDirty ~= nil then
			p252_:setMovingToolDirty(p253_.node)
			return
		end
	end
end)
Dashboard.registerDisplayType(Dashboard.TYPES.TRANS, true, function(p269_, p270_)
	p269_:register(XMLValueType.VECTOR_TRANS, p270_ .. ".dashboard(?)#minTrans", "(TRANS) Min. translation")
	p269_:register(XMLValueType.VECTOR_TRANS, p270_ .. ".dashboard(?)#maxTrans", "(TRANS) Max. translation")
	p269_:register(XMLValueType.FLOAT, p270_ .. ".dashboard(?)#minValueTrans", "(TRANS) Min. reference value for translation")
	p269_:register(XMLValueType.FLOAT, p270_ .. ".dashboard(?)#maxValueTrans", "(TRANS) Max. reference value for translation")
	p269_:register(XMLValueType.FLOAT, p270_ .. ".dashboard(?)#intensity", "Intensity", 1)
end, function(_, p271_, p272_, p273_, p274_, p275_, p276_)
	p273_.node = p271_:getValue(p272_ .. "#node", nil, p274_, p275_)
	if p273_.node == nil then
		Logging.xmlWarning(p271_, "Missing \'node\' for dashboard \'%s\'", p272_)
		return false
	end
	if p276_ ~= nil and not I3DUtil.getIsLinkedToNode(p276_, p273_.node) then
		Logging.xmlWarning(p271_, "Translation dashboard node \'%s\' is not a child of the parent node \'%s\' in \'%s\'", getName(p273_.node), getName(p276_), p272_)
		return false
	end
	p273_.minTrans = p271_:getValue(p272_ .. "#minTrans", nil, true)
	p273_.maxTrans = p271_:getValue(p272_ .. "#maxTrans", nil, true)
	if p273_.minTrans == nil or p273_.maxTrans ~= nil then
		if p273_.maxTrans ~= nil and p273_.minTrans == nil then
			Logging.xmlWarning(p271_, "Missing \'minTrans\' attribute for dashboard \'%s\'", p272_)
		end
	else
		Logging.xmlWarning(p271_, "Missing \'maxTrans\' attribute for dashboard \'%s\'", p272_)
	end
	p273_.minValueTrans = p271_:getValue(p272_ .. "#minValueTrans")
	p273_.maxValueTrans = p271_:getValue(p272_ .. "#maxValueTrans")
	p273_.intensity = p271_:getValue(p272_ .. "#intensity")
	if p273_.intensity ~= nil and (getHasClassId(p273_.node, ClassIds.SHAPE) and getHasShaderParameter(p273_.node, "lightControl")) then
		setShaderParameter(p273_.node, "lightControl", p273_.intensity, 0, 0, 0, false)
	end
	return true
end, function(p277_, p278_, p279_, p280_, p281_, _)
	local v282_
	if type(p279_) == "boolean" then
		v282_ = p279_ and 1 or 0
	elseif p278_.minValueTrans == nil or p278_.maxValueTrans == nil then
		local v283_ = p280_ or 0
		v282_ = (p279_ - v283_) / ((p281_ or 1) - v283_)
	else
		local v284_ = p278_.minValueTrans
		local v285_ = p278_.maxValueTrans
		local v286_ = math.clamp(p279_, v284_, v285_)
		v282_ = MathUtil.round((v286_ - p278_.minValueTrans) / (p278_.maxValueTrans - p278_.minValueTrans), 3)
	end
	local v287_, v288_, v289_ = MathUtil.vector3ArrayLerp(p278_.minTrans, p278_.maxTrans, v282_)
	setTranslation(p278_.node, v287_, v288_, v289_)
	if p277_.setCharacterTargetNodeStateDirty ~= nil then
		p277_:setCharacterTargetNodeStateDirty(p278_.node)
	end
	if p277_.setMovingToolDirty ~= nil then
		p277_:setMovingToolDirty(p278_.node)
	end
end)
Dashboard.registerDisplayType(Dashboard.TYPES.VISIBILITY, false, function(p290_, p291_)
	p290_:register(XMLValueType.BOOL, p291_ .. ".dashboard(?)#inverted", "(VISIBILITY) State will be inverted", false)
	p290_:register(XMLValueType.FLOAT, p291_ .. ".dashboard(?)#intensity", "Intensity", 1)
end, function(_, p292_, p293_, p294_, p295_, p296_, p297_)
	p294_.node = p292_:getValue(p293_ .. "#node", nil, p295_, p296_)
	if p294_.node == nil then
		Logging.xmlWarning(p292_, "Missing \'node\' for dashboard \'%s\'", p293_)
		return false
	end
	if p297_ ~= nil and not I3DUtil.getIsLinkedToNode(p297_, p294_.node) then
		Logging.xmlWarning(p292_, "Visibility dashboard node \'%s\' is not a child of the parent node \'%s\' in \'%s\'", getName(p294_.node), getName(p297_), p293_)
		return false
	end
	p294_.inverted = p292_:getValue(p293_ .. "#inverted", false)
	setVisibility(p294_.node, p294_.inverted)
	p294_.intensity = p292_:getValue(p293_ .. "#intensity")
	if p294_.intensity ~= nil and (getHasClassId(p294_.node, ClassIds.SHAPE) and getHasShaderParameter(p294_.node, "lightControl")) then
		setShaderParameter(p294_.node, "lightControl", p294_.intensity, 0, 0, 0, false)
	end
	return true
end, function(_, p298_, p299_, _, _, p300_)
	if type(p299_) == "number" then
		p299_ = p299_ > 0.5
	end
	if p299_ ~= nil then
		p300_ = p299_ and p300_
	end
	if p298_.inverted then
		p300_ = not p300_
	end
	setVisibility(p298_.node, p300_)
end)
Dashboard.registerDisplayType(Dashboard.TYPES.TEXT, false, function(p301_, p302_)
	p301_:register(XMLValueType.STRING, p302_ .. ".dashboard(?)#textColor", "(TEXT) Font color (DashboardColor OR BrandColor OR r g b a)")
	p301_:register(XMLValueType.STRING, p302_ .. ".dashboard(?)#hiddenColor", "(TEXT) Color of hidden character (if defined a \'0\' in this color is display instead of nothing)")
	p301_:register(XMLValueType.STRING, p302_ .. ".dashboard(?)#textAlignment", "(TEXT) Alignment of text (LEFT | RIGHT | CENTER)", "RIGHT")
	p301_:register(XMLValueType.FLOAT, p302_ .. ".dashboard(?)#textSize", "(TEXT) Size of font in meter", 0.03)
	p301_:register(XMLValueType.FLOAT, p302_ .. ".dashboard(?)#fontThickness", "(TEXT) Thickness factor for font characters", 1)
	p301_:register(XMLValueType.FLOAT, p302_ .. ".dashboard(?)#textScaleX", "(TEXT) Global X scale of text", 1)
	p301_:register(XMLValueType.FLOAT, p302_ .. ".dashboard(?)#textScaleY", "(TEXT) Global Y scale of text", 1)
	p301_:register(XMLValueType.FLOAT, p302_ .. ".dashboard(?)#textSpacing", "(TEXT) Scale factor for spacing between the characters", 1)
	p301_:register(XMLValueType.STRING, p302_ .. ".dashboard(?)#textMask", "(TEXT) Font Mask", "00.0")
end, function(p303_, p304_, p305_, p306_, p307_, p308_, p309_)
	p306_.node = p304_:getValue(p305_ .. "#node", nil, p307_, p308_)
	if p306_.node == nil then
		Logging.xmlWarning(p304_, "Missing \'node\' for text dashboard \'%s\'", p305_)
		return false
	end
	if p309_ ~= nil and not I3DUtil.getIsLinkedToNode(p309_, p306_.node) then
		Logging.xmlWarning(p304_, "Visibility dashboard node \'%s\' is not a child of the parent node \'%s\' in \'%s\'", getName(p306_.node), getName(p309_), p305_)
		return false
	end
	p306_.textColor = Dashboard.getDashboardColor(p304_, p304_:getValue(p305_ .. "#textColor"), p303_.customEnvironment)
	if p306_.textColor == nil then
		p306_.textColor = {
			0.9,
			0.9,
			0.9,
			1
		}
	end
	p306_.hiddenColor = Dashboard.getDashboardColor(p304_, p304_:getValue(p305_ .. "#hiddenColor"), p303_.customEnvironment)
	local v310_ = p304_:getValue(p305_ .. "#textAlignment", "RIGHT")
	p306_.textAlignment = RenderText["ALIGN_" .. string.upper(v310_)] or RenderText.ALIGN_RIGHT
	p306_.textSize = p304_:getValue(p305_ .. "#textSize", 0.03)
	p306_.textScaleX = p304_:getValue(p305_ .. "#textScaleX", 1)
	p306_.textScaleY = p304_:getValue(p305_ .. "#textScaleY", 1)
	p306_.textSpacing = p304_:getValue(p305_ .. "#textSpacing", 1)
	p306_.textMask = p304_:getValue(p305_ .. "#textMask", "00.0")
	local v311_, v312_ = Utils.maskToFormat(p306_.textMask)
	p306_.textFormatStr = v311_
	p306_.textFormatPrecision = v312_
	p306_.fontName = string.upper(p304_:getValue(p305_ .. "#font", "DIGIT"))
	p306_.fontThickness = p304_:getValue(p305_ .. "#fontThickness", 1)
	p306_.emissiveScale = p304_:getValue(p305_ .. "#emissiveScale", 0.2)
	local v313_ = g_materialManager:getFontMaterial(p306_.fontName, p303_.customEnvironment)
	if v313_ == nil then
		Logging.xmlWarning(p304_, "Unknown font \'%s\' in \'%s\'", p306_.fontName, p305_)
		return false
	end
	p306_.characterLine = CharacterLine.new(p306_.node, v313_, p306_.textMask:len())
	p306_.characterLine:setSizeAndScale(p306_.textSize, p306_.textScaleX, p306_.textScaleY)
	p306_.characterLine:setTextAlignment(p306_.textAlignment)
	p306_.characterLine:setFontThickness(p306_.fontThickness)
	p306_.characterLine:setUseNormalMap(false)
	p306_.characterLine:setColor(p306_.textColor, p306_.hiddenColor, p306_.emissiveScale)
	p306_.characterLine:setDecalLayer(2)
	p306_.characterLine:setCharacterSpacing(p306_.textSpacing)
	if p306_.characterLine == nil then
		Logging.xmlWarning(p304_, "Failed to create text in \'%s\'", p305_)
		return false
	end
	p306_.characterLine:setText(p306_.textMask)
	p306_.lastIntValue = nil
	p306_.lastFloatValue = nil
	local v314_ = p306_.textMask
	p306_.lastTextLength = string.len(v314_)
	setVisibility(p306_.characterLine.rootNode, false)
	return true
end, function(_, p315_, p316_, _, _, p317_)
	if type(p316_) == "number" then
		local v318_, v319_ = math.modf(p316_)
		local v320_ = (v319_ + 1e-6) * 10 ^ p315_.textFormatPrecision
		local v321_ = math.floor(v320_)
		local v322_ = math.abs(v321_)
		if v318_ ~= p315_.lastIntValue or v322_ ~= p315_.lastFloatValue then
			local v323_ = string.ltrim(string.format(p315_.textFormatStr, v318_, v322_))
			local v324_ = string.len(v323_)
			p315_.characterLine:setText(v323_, v324_ ~= p315_.lastTextLength)
			p315_.lastIntValue = v318_
			p315_.lastFloatValue = v322_
			p315_.lastTextLength = v324_
		end
	elseif type(p316_) == "string" then
		local v325_ = string.len(p316_)
		p315_.characterLine:setText(p316_, v325_ ~= p315_.lastTextLength)
		p315_.lastTextLength = v325_
	end
	setVisibility(p315_.characterLine.rootNode, p317_)
end)
Dashboard.registerDisplayType(Dashboard.TYPES.SLIDER, false, function(p326_, p327_)
	p326_:register(XMLValueType.FLOAT, p327_ .. ".dashboard(?)#minValueSlider", "(SLIDER) Min. reference value for slider")
	p326_:register(XMLValueType.FLOAT, p327_ .. ".dashboard(?)#maxValueSlider", "(SLIDER) Max. reference value for slider")
	p326_:register(XMLValueType.FLOAT, p327_ .. ".dashboard(?)#intensity", "Intensity", 1)
end, function(_, p328_, p329_, p330_, p331_, p332_, p333_)
	p330_.node = p328_:getValue(p329_ .. "#node", nil, p331_, p332_)
	if p330_.node == nil then
		Logging.xmlWarning(p328_, "Missing \'node\' for dashboard \'%s\'", p329_)
		return false
	end
	if p333_ ~= nil and not I3DUtil.getIsLinkedToNode(p333_, p330_.node) then
		Logging.xmlWarning(p328_, "Slider dashboard node \'%s\' is not a child of the parent node \'%s\' in \'%s\'", getName(p330_.node), getName(p333_), p329_)
		return false
	end
	if not getHasClassId(p330_.node, ClassIds.SHAPE) then
		Logging.xmlWarning(p328_, "Slider Dashboard node is not a shape! \'%s\' in \'%s\'", getName(p330_.node), p329_)
		return false
	end
	if not getHasShaderParameter(p330_.node, "sliderPos") then
		Logging.xmlWarning(p328_, "Node \'%s\' does not have a \'sliderPos\' shader parameter for dashboard \'%s\'", getName(p330_.node), p329_)
		return false
	end
	setShaderParameter(p330_.node, "sliderPos", 0, 0, 0, 0, false)
	p330_.minValueSlider = p328_:getValue(p329_ .. "#minValueSlider")
	p330_.maxValueSlider = p328_:getValue(p329_ .. "#maxValueSlider")
	if p330_.minValueSlider == nil or p330_.maxValueSlider ~= nil then
		if p330_.maxValueSlider ~= nil and p330_.minValueSlider == nil then
			Logging.xmlWarning(p328_, "Missing \'minValueSlider\' attribute for dashboard \'%s\'", p329_)
			p330_.maxValueSlider = nil
		end
	else
		Logging.xmlWarning(p328_, "Missing \'maxValueSlider\' attribute for dashboard \'%s\'", p329_)
		p330_.minValueSlider = nil
	end
	p330_.intensity = p328_:getValue(p329_ .. "#intensity", 1)
	setShaderParameter(p330_.node, "lightControl", p330_.intensity, 0, 0, 0, false)
	return true
end, function(_, p334_, p335_, p336_, p337_, _)
	if p334_.node ~= nil then
		local v338_ = type(p335_) == "boolean" and (p335_ and 1 or 0) or p335_
		local v339_
		if p334_.minValueSlider == nil or p334_.maxValueSlider == nil then
			local v340_ = p336_ or 0
			v339_ = MathUtil.round((v338_ - v340_) / ((p337_ or 1) - v340_), 3)
		else
			local v341_ = p334_.minValueSlider
			local v342_ = p334_.maxValueSlider
			local v343_ = math.clamp(v338_, v341_, v342_)
			v339_ = MathUtil.round((v343_ - p334_.minValueSlider) / (p334_.maxValueSlider - p334_.minValueSlider), 3)
		end
		setShaderParameter(p334_.node, "sliderPos", v339_, 0, 0, 0, false)
	end
end)
Dashboard.registerDisplayType(Dashboard.TYPES.MULTI_STATE, false, function(p344_, p345_)
	p344_:register(XMLValueType.VECTOR_N, p345_ .. ".dashboard(?).state(?)#value", "(MULTI_STATE) One or multiple values separated by space to activate the state")
	p344_:register(XMLValueType.VECTOR_ROT, p345_ .. ".dashboard(?).state(?)#rotation", "(MULTI_STATE) Rotation while state is active")
	p344_:register(XMLValueType.VECTOR_TRANS, p345_ .. ".dashboard(?).state(?)#translation", "(MULTI_STATE) Translation while state is active")
	p344_:register(XMLValueType.VECTOR_SCALE, p345_ .. ".dashboard(?).state(?)#scale", "(MULTI_STATE) Scale while state is active")
	p344_:register(XMLValueType.FLOAT, p345_ .. ".dashboard(?).state(?)#intensity", "(MULTI_STATE) Intensity if the node is a emitter")
	p344_:register(XMLValueType.STRING, p345_ .. ".dashboard(?).state(?)#emitColor", "(MULTI_STATE) Emit color if the node is a emitter")
	p344_:register(XMLValueType.BOOL, p345_ .. ".dashboard(?).state(?)#visibility", "(MULTI_STATE) Visibility while state is active")
end, function(p_u_346_, p_u_347_, p348_, p_u_349_, p350_, p351_, p352_)
	p_u_349_.node = p_u_347_:getValue(p348_ .. "#node", nil, p350_, p351_)
	if p_u_349_.node == nil then
		Logging.xmlWarning(p_u_347_, "Missing \'node\' for dashboard \'%s\'", p348_)
		return false
	end
	if p352_ ~= nil and not I3DUtil.getIsLinkedToNode(p352_, p_u_349_.node) then
		Logging.xmlWarning(p_u_347_, "Multi state dashboard node \'%s\' is not a child of the parent node \'%s\' in \'%s\'", getName(p_u_349_.node), getName(p352_), p348_)
		return false
	end
	p_u_349_.hasVisibility = false
	p_u_349_.hasEmitColor = false
	p_u_349_.hasIntensity = false
	p_u_349_.defaultStateIndex = -1
	p_u_349_.states = {}
	p_u_347_:iterate(p348_ .. ".state", function(p353_, p354_)
		-- upvalues: (copy) p_u_347_, (copy) p_u_349_, (copy) p_u_346_
		local v355_ = {
			["values"] = p_u_347_:getValue(p354_ .. "#value", nil, true)
		}
		if v355_.values == nil then
			p_u_349_.defaultStateIndex = p353_
		end
		v355_.rotation = p_u_347_:getValue(p354_ .. "#rotation", nil, true)
		v355_.translation = p_u_347_:getValue(p354_ .. "#translation", nil, true)
		v355_.scale = p_u_347_:getValue(p354_ .. "#scale", nil, true)
		v355_.visibility = p_u_347_:getValue(p354_ .. "#visibility")
		p_u_349_.hasVisibility = p_u_349_.hasVisibility or v355_.visibility ~= nil
		v355_.emitColor = Dashboard.getDashboardColor(p_u_347_, p_u_347_:getValue(p354_ .. "#emitColor"), p_u_346_.customEnvironment)
		p_u_349_.hasEmitColor = p_u_349_.hasEmitColor or v355_.emitColor ~= nil
		v355_.intensity = p_u_347_:getValue(p354_ .. "#intensity")
		p_u_349_.hasIntensity = p_u_349_.hasIntensity or v355_.intensity ~= nil
		local v356_ = p_u_349_.states
		table.insert(v356_, v355_)
	end)
	if (p_u_349_.hasEmitColor or p_u_349_.hasIntensity) and not getHasClassId(p_u_349_.node, ClassIds.SHAPE) then
		Logging.xmlWarning(p_u_347_, "Intensity or emitColor defined for non shape node in \'%s\'", p348_)
		return false
	end
	if #p_u_349_.states == 0 then
		Logging.xmlWarning(p_u_347_, "No states defined for dashboard \'%s\'", p348_)
		return false
	end
	p_u_349_.multiStateInterpolationTime = 1 / p_u_349_.interpolationSpeed
	p_u_349_.interpolationSpeed = 99999
	p_u_349_.lastState = nil
	function p_u_349_.get()
		-- upvalues: (copy) p_u_349_
		local v357_, v358_, v359_ = getTranslation(p_u_349_.node)
		local v360_, v361_, v362_ = getRotation(p_u_349_.node)
		local v363_, v364_, v365_ = getScale(p_u_349_.node)
		local v366_ = getVisibility(p_u_349_.node) and 1 or 0
		local v367_, v368_, v369_
		if p_u_349_.hasEmitColor and getHasShaderParameter(p_u_349_.node, "emitColor") then
			v367_, v368_, v369_ = getShaderParameter(p_u_349_.node, "emitColor")
		else
			v367_ = 1
			v368_ = 1
			v369_ = 1
		end
		return v357_, v358_, v359_, v360_, v361_, v362_, v363_, v364_, v365_, v366_, v367_, v368_, v369_, not (p_u_349_.hasIntensity and getHasShaderParameter(p_u_349_.node, "lightControl")) and 0 or getShaderParameter(p_u_349_.node, "lightControl")
	end
	function p_u_349_.set(p370_, p371_, p372_, p373_, p374_, p375_, p376_, p377_, p378_, p379_, p380_, p381_, p382_, p383_)
		-- upvalues: (copy) p_u_349_, (copy) p_u_346_
		setTranslation(p_u_349_.node, p370_, p371_, p372_)
		setRotation(p_u_349_.node, p373_, p374_, p375_)
		setScale(p_u_349_.node, p376_, p377_, p378_)
		if p_u_349_.hasVisibility then
			setVisibility(p_u_349_.node, p379_ >= 0.5)
		end
		if p_u_349_.hasEmitColor and getHasShaderParameter(p_u_349_.node, "emitColor") then
			setShaderParameter(p_u_349_.node, "emitColor", p380_, p381_, p382_, 1, false)
		end
		if p_u_349_.hasIntensity and getHasShaderParameter(p_u_349_.node, "lightControl") then
			setShaderParameter(p_u_349_.node, "lightControl", p383_, nil, nil, nil, false)
		end
		if p_u_346_.setCharacterTargetNodeStateDirty ~= nil then
			p_u_346_:setCharacterTargetNodeStateDirty(p_u_349_.node)
		end
		if p_u_346_.setMovingToolDirty ~= nil then
			p_u_346_:setMovingToolDirty(p_u_349_.node)
		end
	end
	p_u_349_.defaultRotation = { getRotation(p_u_349_.node) }
	p_u_349_.defaultTranslation = { getTranslation(p_u_349_.node) }
	p_u_349_.defaultScale = { getScale(p_u_349_.node) }
	p_u_349_.defaultVisibility = getVisibility(p_u_349_.node)
	p_u_349_.defaultEmitColor = { 1, 1, 1 }
	p_u_349_.defaultIntensity = 0
	return true
end, function(p384_, p385_, p386_, _, _, p387_)
	if p385_.node ~= nil then
		local v388_ = nil
		if p387_ then
			for v389_ = 1, #p385_.states do
				local v390_ = p385_.states[v389_]
				if v390_.values ~= nil then
					if type(p386_) == "table" then
						for v391_ = 1, #v390_.values do
							if p386_[v390_.values[v391_]] == true then
								v388_ = v390_
							end
						end
					elseif type(p386_) == "number" then
						p386_ = MathUtil.round(p386_)
						for v392_ = 1, #v390_.values do
							if v390_.values[v392_] == p386_ then
								v388_ = v390_
							end
						end
					elseif type(p386_) == "string" then
						p386_ = MathUtil.round(tonumber(p386_) or 0)
						for v393_ = 1, #v390_.values do
							if v390_.values[v393_] == p386_ then
								v388_ = v390_
							end
						end
					end
				end
			end
		end
		if v388_ == nil and p385_.defaultStateIndex > 0 then
			v388_ = p385_.states[p385_.defaultStateIndex]
		end
		if v388_ ~= p385_.lastState then
			local v394_ = p385_.defaultRotation
			local v395_ = p385_.defaultTranslation
			local v396_ = p385_.defaultScale
			local v397_ = p385_.defaultVisibility
			local v398_ = p385_.defaultEmitColor
			local v399_ = p385_.defaultIntensity
			if v388_ ~= nil then
				v394_ = v388_.rotation or v394_
				v395_ = v388_.translation or v395_
				v396_ = v388_.scale or v396_
				if v388_.visibility ~= nil then
					v397_ = v388_.visibility
				end
				if v388_.emitColor ~= nil then
					v398_ = v388_.emitColor
				end
				if v388_.intensity ~= nil then
					v399_ = v388_.intensity
				end
			end
			if p385_.doInterpolation then
				if p385_.interpolator ~= nil then
					p385_.interpolator:update(9999999)
				end
				local v400_ = ValueInterpolator.new(p385_.node .. "_dashboard", p385_.get, p385_.set, {
					v395_[1],
					v395_[2],
					v395_[3],
					v394_[1],
					v394_[2],
					v394_[3],
					v396_[1],
					v396_[2],
					v396_[3],
					v397_ and 1 or 0,
					v398_[1],
					v398_[2],
					v398_[3],
					v399_
				}, p385_.multiStateInterpolationTime)
				if v400_ ~= nil then
					p385_.interpolator = v400_
					p385_.interpolator:setDeleteListenerObject(p384_)
					p385_.interpolator:setFinishedFunc(function(p401_)
						p401_.interpolator = nil
					end, p385_)
				end
			else
				p385_.set(v395_[1], v395_[2], v395_[3], v394_[1], v394_[2], v394_[3], v396_[1], v396_[2], v396_[3], v397_ and 1 or 0, v398_[1], v398_[2], v398_[3], v399_)
			end
			p385_.lastState = v388_
		end
	end
end)

-- Local values: _, typeData
function Dashboard.registerDashboardXMLPaths(schema, basePath, availableValueTypes)
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#valueType", "Value type name", nil, nil, availableValueTypes)
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#displayType", "Display type name", nil, nil, table.toList(Dashboard.TYPES))
	schema:register(XMLValueType.BOOL, basePath .. ".dashboard(?)#doInterpolation", "Do interpolation", false)
	schema:register(XMLValueType.BOOL, basePath .. ".dashboard(?)#isCritical", "Defines if dashboard update is critical and should be done every frame", "automatically based on type")
	schema:register(XMLValueType.BOOL, basePath .. ".dashboard(?)#useStateChange", "Dashboard is active for a defined amount of time when the source value changes", false)
	schema:register(XMLValueType.TIME, basePath .. ".dashboard(?)#stateChangeTime", "Defines how long the dashboard is active when the state changes (seconds)", 0.2)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#stateChangeValue", "Defines the dashboard value which triggers the state change. If not defined, any state change will trigger it")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#interpolationSpeed", "Interpolation speed", 0.005)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#idleValue", "Idle value", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#offsetValue", "Offset the value by the given amount", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#scaleFactor", "Scale the value by the given factor", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#minActiveValue", "Min. value to activate this dashboard")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#maxActiveValue", "Max. value to activate this dashboard")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?).valueMapping(?)#sourceValue", "Source value")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?).valueMapping(?)#dashboardValue", "Value to be used for dashboard at this source value")
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#groups", "List of groups")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".dashboard(?)#node", "Node")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#warningThresholdMin", "(WARNING) Threshold min.")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#warningThresholdMax", "(WARNING) Threshold max.")
	for _, v405_ in pairs(Dashboard.TYPE_DATA) do
		v405_.schemaFunc(schema, basePath)
	end
	schema:addDelayedRegistrationPath(basePath .. ".dashboard(?)", "Dashboard")
end

function Dashboard.addDelayedRegistrationFunc(schema, func)
	schema:addDelayedRegistrationFunc("Dashboard", func)
	if Dashboard.compoundsXMLSchema == nil then
		Dashboard.compoundsXMLSchema = XMLSchema.new("dashboardCompounds")
	end
	Dashboard.compoundsXMLSchema:addDelayedRegistrationFunc("Dashboard", func)
end
