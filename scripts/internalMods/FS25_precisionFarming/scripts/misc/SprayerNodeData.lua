-- Local values: SprayerNodeData_mt
SprayerNodeData = {}
SprayerNodeData.MOD_NAME = g_currentModName
SprayerNodeData.BASE_DIRECTORY = g_currentModDirectory
SprayerNodeData.xmlSchema = nil
SprayerNodeData.SPRAYER_NOZZLE_EFFECT_FILENAME = g_currentModDirectory .. "shared/sprayerNozzleEffect.i3d"
local SprayerNodeData_mt = Class(SprayerNodeData)

-- Upvalues: SprayerNodeData_mt
-- Local values: self
function SprayerNodeData.new(precisionFarming, customMt)
	-- upvalues: (copy) SprayerNodeData_mt
	local v4_ = customMt or SprayerNodeData_mt
	local v5_ = setmetatable({}, v4_)
	v5_.precisionFarming = precisionFarming
	v5_.linkageData = {}
	v5_.sensorTypes = {}
	v5_.dataLoaded = false
	v5_.priceWeedSpotSpray = 0
	v5_.priceSeeAndSpray = 0
	v5_.pricePulseWidthModulation = 0
	SprayerNodeData.xmlSchema = XMLSchema.new("sprayerNodeData")
	v5_:registerXMLPaths(SprayerNodeData.xmlSchema)
	return v5_
end

-- Local values: _, sensorType
function SprayerNodeData:delete()
	if self.sprayerEffectNode ~= nil then
		delete(self.sprayerEffectNode)
		self.sprayerEffectNode = nil
	end
	for _, v7_ in ipairs(self.sensorTypes) do
		if v7_.node ~= nil then
			delete(v7_.node)
			v7_.node = nil
		end
		if v7_.sharedLoadRequestId ~= nil then
			g_i3DManager:releaseSharedI3DFile(v7_.sharedLoadRequestId)
			v7_.sharedLoadRequestId = nil
		end
	end
	if self.samples ~= nil then
		g_soundManager:deleteSamples(self.samples)
	end
	self.linkageData = {}
end

function SprayerNodeData:loadFromXML(_, _, baseDirectory, configFileName, mapFilename)
	if not self.dataLoaded then
		self:loadData()
	end
end

function SprayerNodeData:getConfigPrices()
	return self.priceWeedSpotSpray, self.priceSeeAndSpray, self.pricePulseWidthModulation
end

-- Local values: sample
function SprayerNodeData:getClonedSectionSamples(name, linkNode, modifierTargetObject)
	local v14_ = self.samples[name]
	if v14_ ~= nil then
		return g_soundManager:cloneSample(v14_, linkNode, modifierTargetObject)
	end
	Logging.warning("Missing sample \'%s\' in SprayerNodeData", name)
	return nil
end

-- Local values: filename, xmlFile, linkNode
function SprayerNodeData:loadData(loadVehicleData, loadEffect)
	if loadEffect ~= false then
		g_i3DManager:loadI3DFileAsync(SprayerNodeData.SPRAYER_NOZZLE_EFFECT_FILENAME, true, true, SprayerNodeData.onSprayerEffectLoaded, self, {})
	end
	local v18_ = Utils.getFilename("SprayerNodeData.xml", SprayerNodeData.BASE_DIRECTORY)
	local v_u_19_ = XMLFile.load("SprayerNodeData", v18_, SprayerNodeData.xmlSchema)
	if v_u_19_ ~= nil then
		self.priceWeedSpotSpray = v_u_19_:getValue("sprayerNodeData.configuration#priceWeedSpotSpray", 1000)
		self.priceSeeAndSpray = v_u_19_:getValue("sprayerNodeData.configuration#priceSeeAndSpray", 1000)
		self.pricePulseWidthModulation = v_u_19_:getValue("sprayerNodeData.configuration#pricePulseWidthModulation", 1000)
		local v20_ = getRootNode()
		self.samples = {}
		self.samples.spray = g_soundManager:loadSampleFromXML(v_u_19_, "sprayerNodeData.sounds", "spray", SprayerNodeData.BASE_DIRECTORY, v20_, 0, AudioGroup.VEHICLE, nil, self)
		if loadEffect ~= false then
			v_u_19_:iterate("sprayerNodeData.sensorTypes.sensorType", function(_, p21_)
				-- upvalues: (copy) v_u_19_, (copy) self
				local v22_ = {
					["id"] = v_u_19_:getValue(p21_ .. "#id"),
					["filename"] = v_u_19_:getValue(p21_ .. "#filename", nil, SprayerNodeData.BASE_DIRECTORY),
					["nodePath"] = v_u_19_:getValue(p21_ .. "#node"),
					["hasBracket"] = v_u_19_:getValue(p21_ .. "#hasBracket", false)
				}
				if v22_.id == nil or v22_.filename == nil then
					Logging.xmlWarning(v_u_19_, "Missing sensor type id or filename in \'%s\'", p21_)
				else
					v22_.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v22_.filename, true, true, SprayerNodeData.onWeedSensorLoaded, self, v22_)
				end
			end)
		end
		if loadVehicleData ~= false then
			self.linkageData = {}
			v_u_19_:iterate("sprayerNodeData.vehicles.vehicle", function(_, p23_)
				-- upvalues: (copy) v_u_19_, (copy) self
				local v24_ = {
					["filename"] = v_u_19_:getValue(p23_ .. "#filename")
				}
				if v24_.filename ~= nil then
					v24_.configurationName = v_u_19_:getValue(p23_ .. "#configurationName", "variableWorkWidth")
					v24_.configurations = {}
					for _, v25_ in v_u_19_:iterator(p23_ .. ".configuration") do
						local v26_ = {
							["effectNodes"] = {}
						}
						for _, v27_ in v_u_19_:iterator(v25_ .. ".effectNode") do
							local v28_ = {
								["nodeName"] = v_u_19_:getValue(v27_ .. "#node"),
								["translation"] = v_u_19_:getValue(v27_ .. "#translation", "0 0 0", true),
								["rotation"] = v_u_19_:getValue(v27_ .. "#rotation", "0 0 0", true)
							}
							local v29_ = v26_.effectNodes
							table.insert(v29_, v28_)
						end
						v26_.sensorNodes = {}
						for _, v30_ in v_u_19_:iterator(v25_ .. ".sensorNode") do
							local v31_ = {
								["id"] = v_u_19_:getValue(v30_ .. "#id"),
								["nodeName"] = v_u_19_:getValue(v30_ .. "#node"),
								["translation"] = v_u_19_:getValue(v30_ .. "#translation", "0 0 0", true),
								["rotation"] = v_u_19_:getValue(v30_ .. "#rotation", "0 0 0", true),
								["bracketSize"] = v_u_19_:getValue(v30_ .. "#bracketSize", 1)
							}
							local v32_ = v26_.sensorNodes
							table.insert(v32_, v31_)
						end
						if #v26_.effectNodes > 0 or #v26_.sensorNodes > 0 then
							local v33_ = v24_.configurations
							table.insert(v33_, v26_)
						end
					end
				end
				local v34_ = self.linkageData
				table.insert(v34_, v24_)
			end)
		end
		v_u_19_:delete()
	end
	self.dataLoaded = true
	return true
end

function SprayerNodeData:onSprayerEffectLoaded(i3dNode, failedReason, args)
	if i3dNode ~= 0 then
		self.sprayerEffectNode = getChildAt(i3dNode, 0)
		unlink(self.sprayerEffectNode)
		delete(i3dNode)
	end
end

function SprayerNodeData:onWeedSensorLoaded(i3dNode, failedReason, sensorType)
	if i3dNode ~= 0 then
		sensorType.node = I3DUtil.indexToObject(i3dNode, sensorType.nodePath)
		if sensorType.node ~= nil then
			setTranslation(sensorType.node, 0, 0, 0)
			setRotation(sensorType.node, 0, 0, 0)
			unlink(sensorType.node)
			local v40_ = self.sensorTypes
			table.insert(v40_, sensorType)
		end
		delete(i3dNode)
	end
end

-- Local values: effectNode, material
function SprayerNodeData:getClonedSprayerEffectNode()
	if self.sprayerEffectNode == nil then
		return nil
	end
	local v42_ = clone(self.sprayerEffectNode, false, false, false)
	local v43_ = g_materialManager:getMaterial(FillType.LIQUIDFERTILIZER, "sprayer", 1)
	if v43_ ~= nil then
		setMaterial(v42_, v43_, 0)
	end
	return v42_
end

-- Local values: _, sensorType
function SprayerNodeData:getClonedSprayerWeedSensorNode(sensorTypeId)
	for _, v46_ in ipairs(self.sensorTypes) do
		if v46_.id == sensorTypeId and v46_.node ~= nil then
			return clone(v46_.node, false, false, false), v46_.hasBracket
		end
	end
	return nil, false
end

-- Local values: i, vehicleData, configId
function SprayerNodeData:getSprayerNodeData(configFileName, configurations)
	if configFileName ~= nil then
		for v50_ = 1, #self.linkageData do
			local v51_ = self.linkageData[v50_]
			if string.endsWith(configFileName, v51_.filename) then
				if configurations == nil then
					return v51_.configurations[1], v51_
				else
					local v52_ = configurations[v51_.configurationName]
					if v52_ == nil then
						return v51_.configurations[1], v51_
					else
						return v51_.configurations[v52_], v51_
					end
				end
			end
		end
	end
	return nil
end

function SprayerNodeData:overwriteGameFunctions(pfModule)
	pfModule:overwriteGameFunction(VehicleSystem, "consoleCommandReloadVehicle", function(p55_, p56_, p57_, p58_)
		-- upvalues: (copy) self
		self:loadData(true, false)
		return p55_(p56_, p57_, p58_)
	end)
	pfModule:overwriteGameFunction(ConfigurationUtil, "getConfigurationsFromXML", function(p59_, p60_, p61_, p62_, p63_, p64_, p65_, p66_)
		-- upvalues: (copy) self
		local v67_, v68_ = p59_(p60_, p61_, p62_, p63_, p64_, p65_, p66_)
		if not self.dataLoaded then
			self:loadData()
		end
		local _, v69_ = self:getSprayerNodeData(p61_.filename)
		if v69_ ~= nil then
			v67_ = v67_ == nil and {} or v67_
			v68_ = v68_ == nil and {} or v68_
			if v67_.weedSpotSpray == nil then
				local v70_ = {}
				local v71_ = VehicleConfigurationItem.new("weedSpotSpray")
				v71_.isDefault = true
				v71_.name = g_i18n:getText("configuration_valueNo")
				v71_.index = 1
				v71_.saveId = "1"
				v71_.price = 0
				v71_.isYesNoOption = true
				table.insert(v70_, v71_)
				local v72_ = VehicleConfigurationItem.new("weedSpotSpray")
				v72_.name = g_i18n:getText("configuration_valueYes")
				v72_.index = 2
				v72_.saveId = "2"
				v72_.price = 1
				v72_.isYesNoOption = true
				v72_.overwrittenTitle = "PTx Trimble - WeedSeeker\194\174 2"
				table.insert(v70_, v72_)
				v68_.weedSpotSpray = ConfigurationUtil.getDefaultConfigIdFromItems(v70_)
				v67_.weedSpotSpray = v70_
			end
			if v67_.pulseWidthModulation == nil then
				local v73_ = {}
				local v74_ = VehicleConfigurationItem.new("pulseWidthModulation")
				v74_.isDefault = true
				v74_.name = g_i18n:getText("configuration_valueNo")
				v74_.index = 1
				v74_.saveId = "1"
				v74_.price = 0
				v74_.isYesNoOption = true
				table.insert(v73_, v74_)
				local v75_ = VehicleConfigurationItem.new("pulseWidthModulation")
				v75_.name = g_i18n:getText("configuration_valueYes")
				v75_.index = 2
				v75_.saveId = "2"
				v75_.price = 1
				v75_.isYesNoOption = true
				table.insert(v73_, v75_)
				v68_.pulseWidthModulation = ConfigurationUtil.getDefaultConfigIdFromItems(v73_)
				v67_.pulseWidthModulation = v73_
			end
		end
		return v67_, v68_
	end)
end

function SprayerNodeData:registerXMLPaths(schema)
	schema:register(XMLValueType.INT, "sprayerNodeData.configuration#priceWeedSpotSpray", "Default spot spray config price per meter")
	schema:register(XMLValueType.INT, "sprayerNodeData.configuration#priceSeeAndSpray", "Default spot spray config price per meter (JD See & Spray)")
	schema:register(XMLValueType.INT, "sprayerNodeData.configuration#pricePulseWidthModulation", "Default pulse width modulation config price per meter")
	SoundManager.registerSampleXMLPaths(schema, "sprayerNodeData.sounds", "spray")
	schema:register(XMLValueType.STRING, "sprayerNodeData.vehicles.vehicle(?)#filename", "Last part of vehicle filename")
	schema:register(XMLValueType.STRING, "sprayerNodeData.vehicles.vehicle(?)#configurationName", "Name of configuration", "variableWorkWidth")
	schema:register(XMLValueType.STRING, "sprayerNodeData.vehicles.vehicle(?).configuration(?).effectNode(?)#node", "Name of node in i3d mapping")
	schema:register(XMLValueType.VECTOR_TRANS, "sprayerNodeData.vehicles.vehicle(?).configuration(?).effectNode(?)#translation", "Translation offset from node", "0 0 0")
	schema:register(XMLValueType.VECTOR_ROT, "sprayerNodeData.vehicles.vehicle(?).configuration(?).effectNode(?)#rotation", "Rotation offset from node", "0 0 0")
	schema:register(XMLValueType.STRING, "sprayerNodeData.sensorTypes.sensorType(?)#id", "Sensor identifier")
	schema:register(XMLValueType.FILENAME, "sprayerNodeData.sensorTypes.sensorType(?)#filename", "Path to the sensor i3d file")
	schema:register(XMLValueType.STRING, "sprayerNodeData.sensorTypes.sensorType(?)#node", "Path to the node in the i3d file")
	schema:register(XMLValueType.BOOL, "sprayerNodeData.sensorTypes.sensorType(?)#hasBracket", "Defines if the first child node is a scaleable bracket", false)
	schema:register(XMLValueType.STRING, "sprayerNodeData.vehicles.vehicle(?).configuration(?).sensorNode(?)#id", "Sensor identifier of the type to use")
	schema:register(XMLValueType.STRING, "sprayerNodeData.vehicles.vehicle(?).configuration(?).sensorNode(?)#node", "Name of node in i3d mapping")
	schema:register(XMLValueType.VECTOR_TRANS, "sprayerNodeData.vehicles.vehicle(?).configuration(?).sensorNode(?)#translation", "Translation offset from node", "0 0 0")
	schema:register(XMLValueType.VECTOR_ROT, "sprayerNodeData.vehicles.vehicle(?).configuration(?).sensorNode(?)#rotation", "Rotation offset from node", "0 0 0")
	schema:register(XMLValueType.FLOAT, "sprayerNodeData.vehicles.vehicle(?).configuration(?).sensorNode(?)#bracketSize", "Size of the bracket", 1)
end
