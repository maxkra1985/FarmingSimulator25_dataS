-- Local values: VehicleConfigurationItemWheel_mt
VehicleConfigurationItemWheel = {}
VehicleConfigurationItemWheel.SELECTOR = ConfigurationUtil.SELECTOR_MULTIOPTION
local VehicleConfigurationItemWheel_mt = Class(VehicleConfigurationItemWheel, VehicleConfigurationItem)

-- Upvalues: VehicleConfigurationItemWheel_mt
-- Local values: self
function VehicleConfigurationItemWheel.new(configName, customMt)
	-- upvalues: (copy) VehicleConfigurationItemWheel_mt
	return VehicleConfigurationItemWheel:superClass().new(configName, VehicleConfigurationItemWheel_mt)
end

-- Local values: name, brandDesc, configurationIndexToParentConfigIndex, dimensionCombinations, numWheels, i, dimensions, i, customBrandOrder, i, v, tireCategories, _, category, configWhitelistedCombinations, addTireCombinations, _, combination, i, defaultCombination, _, combination
function VehicleConfigurationItemWheel:loadFromXML(xmlFile, baseKey, configKey, baseDirectory, customEnvironment)
	if not VehicleConfigurationItemWheel:superClass().loadFromXML(self, xmlFile, baseKey, configKey, baseDirectory, customEnvironment) then
		return false
	end
	local v9_ = xmlFile:getValue(configKey .. "#brand")
	self.wheelBrandKey = configKey
	if v9_ ~= nil then
		local v10_ = g_brandManager:getBrandByName(v9_)
		if v10_ == nil then
			Logging.xmlWarning(xmlFile, "Wheel brand \'%s\' is not defined for \'%s\'!", v9_, configKey)
		else
			self.wheelBrandName = v10_.title
			self.wheelBrandIconFilename = v10_.image
		end
	end
	self.maxForwardSpeed = xmlFile:getValue(configKey .. "#maxForwardSpeed")
	self.maxForwardSpeedShop = xmlFile:getValue(configKey .. "#maxForwardSpeedShop")
	local v_u_11_ = Wheels.createConfigToParentConfigMapping(xmlFile)
	self.baseWheelData = {}
	xmlFile:iterate(configKey .. ".wheels.wheel", function(p12_, _)
		-- upvalues: (copy) xmlFile, (copy) v_u_11_, (copy) baseDirectory, (copy) self
		local v13_ = WheelXMLObject.new(xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration", 1, string.format(".wheels.wheel(%d)", p12_ - 1), v_u_11_)
		v13_:setXMLLoadKey("")
		local v14_ = nil
		local v15_ = v13_:getLocalValue("#dimensions")
		if v15_ ~= nil then
			local v16_ = v15_:split(" ")
			if #v16_ > 0 then
				v14_ = v16_[1]
			end
		end
		local v17_ = v13_:getLocalValue(".physics#xOffset", 0)
		local v18_ = v13_:getLocalValue("#rimOffset", 0)
		local v19_ = nil
		local v20_ = nil
		if v14_ == nil then
			local v21_ = v13_:getLocalValue("#filename")
			if v21_ ~= nil then
				local v22_ = Utils.getFilename(v21_, baseDirectory)
				v19_, v20_ = g_wheelManager:getWheelRadiusAndWidthFromFilename(v22_)
			end
		else
			v19_, v20_ = g_wheelManager:getWheelRadiusAndWidthFromDimension(v14_)
		end
		v13_:delete()
		if v19_ ~= nil and v20_ ~= nil then
			self.baseWheelData[p12_] = {
				["radius"] = v19_,
				["width"] = v20_,
				["xOffset"] = v17_,
				["rimOffset"] = v18_
			}
		end
	end)
	local v_u_23_ = {}
	local v_u_24_ = 0
	xmlFile:iterate(configKey .. ".wheels.wheel", function(p25_, _)
		-- upvalues: (copy) xmlFile, (copy) self, (copy) v_u_11_, (copy) v_u_23_, (ref) v_u_24_
		local v26_ = WheelXMLObject.new(xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration", self.index, string.format(".wheels.wheel(%d)", p25_ - 1), v_u_11_)
		v26_:setXMLLoadKey("")
		local v27_ = v26_:getLocalValue("#dimensions")
		if v27_ ~= nil then
			local v28_ = v27_:split(" ")
			for v29_, v30_ in ipairs(v28_) do
				if v_u_23_[v29_] == nil then
					v_u_23_[v29_] = {}
				end
				local v31_ = v_u_23_[v29_]
				table.insert(v31_, p25_, v30_)
			end
		end
		v26_:delete()
		v_u_24_ = v_u_24_ + 1
	end)
	local v32_ = v_u_24_
	for _, v33_ in pairs(v_u_23_) do
		for v34_ = 1, v32_ do
			if v33_[v34_] == nil then
				v33_[v34_] = "-"
			end
		end
	end
	if #v_u_23_ == 0 then
		return true
	end
	if self.wheelBrandName ~= nil then
		Logging.xmlWarning(xmlFile, "Wheel brand defined for dynamic configuration, this is not allowed! (%s)", configKey)
		return true
	end
	local v35_ = xmlFile:getValue("vehicle.wheels.wheelConfigurations#customBrandOrder", nil, true)
	if v35_ ~= nil then
		self.customBrandOrder = {}
		for v36_, v37_ in ipairs(v35_) do
			self.customBrandOrder[string.upper(v37_)] = v36_
		end
	end
	local v38_ = xmlFile:getValue(configKey .. "#tireCategories") or xmlFile:getValue("vehicle.wheels.wheelConfigurations#tireCategories")
	if v38_ ~= nil then
		local v39_ = v38_:split(" ")
		if #v39_ > 0 then
			self.tireCategories = {}
			for _, v40_ in ipairs(v39_) do
				self.tireCategories[v40_] = true
			end
		end
	end
	self.whitelistedCombinations = {}
	xmlFile:iterate("vehicle.wheels.wheelConfigurations.tireCombination", function(_, p41_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v42_ = xmlFile:getValue(p41_ .. "#brand")
		local v43_ = g_brandManager:getBrandByName(v42_)
		if v43_ ~= nil then
			local v44_ = xmlFile:getValue(p41_ .. "#names")
			if v44_ ~= nil then
				if v44_ == "-" then
					local v45_ = self.whitelistedCombinations
					table.insert(v45_, {
						["brand"] = v43_,
						["names"] = {}
					})
					return
				end
				local v46_ = v44_:split(" ")
				if #v46_ > 0 then
					local v47_ = self.whitelistedCombinations
					table.insert(v47_, {
						["brand"] = v43_,
						["names"] = v46_
					})
				end
			end
		end
	end)
	local v_u_48_ = {}
	local function v_u_58_(p49_)
		-- upvalues: (copy) v_u_11_, (copy) v_u_58_, (copy) xmlFile, (copy) v_u_48_
		local v50_ = v_u_11_[p49_]
		if v50_ ~= nil then
			v_u_58_(v50_)
		end
		xmlFile:iterate(string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration(%d).tireCombination", p49_ - 1), function(_, p51_)
			-- upvalues: (ref) xmlFile, (ref) v_u_48_
			local v52_ = xmlFile:getValue(p51_ .. "#brand")
			local v53_ = g_brandManager:getBrandByName(v52_)
			if v53_ ~= nil then
				local v54_ = xmlFile:getValue(p51_ .. "#names")
				if v54_ ~= nil then
					if v54_ == "-" then
						local v55_ = v_u_48_
						table.insert(v55_, {
							["brand"] = v53_,
							["names"] = {}
						})
						return
					end
					local v56_ = v54_:split(" ")
					if #v56_ > 0 then
						local v57_ = v_u_48_
						table.insert(v57_, {
							["brand"] = v53_,
							["names"] = v56_
						})
					end
				end
			end
		end)
	end
	v_u_58_(self.index)
	self.numDynamicConfigurations = xmlFile:getValue(configKey .. "#numDynamicConfigurations", math.huge)
	for _, v59_ in ipairs(v_u_48_) do
		for v60_ = #self.whitelistedCombinations, 1, -1 do
			if self.whitelistedCombinations[v60_].brand == v59_.brand then
				table.remove(self.whitelistedCombinations, v60_)
			end
		end
	end
	for _, v61_ in ipairs(v_u_48_) do
		local v62_ = self.whitelistedCombinations
		table.insert(v62_, v61_)
	end
	self.dimensionCombinations = v_u_23_
	return true
end

function VehicleConfigurationItemWheel:getNeedsRenaming(otherItem)
	if self.wheelBrandName == otherItem.wheelBrandName then
		return VehicleConfigurationItemWheel:superClass().getNeedsRenaming(self, otherItem)
	else
		return false
	end
end

-- Local values: configurationIndexToParentConfigIndex, maxOffset, wheelIndex, wheelData, wheelKey, baseWidth, baseXOffset, baseRimOffset, wheeXMLObject, xOffsetDifference, additionalOffset, i, key, _xmlFile, _, additionalWheelOffset
function VehicleConfigurationItemWheel:onSizeLoad(xmlFile, sizeData)
	VehicleConfigurationItemWheel:superClass().onSizeLoad(self, xmlFile, sizeData)
	if self.isDynamicConfig then
		self:applyGeneratedConfiguration(xmlFile)
		if xmlFile:getValue(self.configKey .. ".size#width") ~= nil then
			return
		end
		local v68_ = Wheels.createConfigToParentConfigMapping(xmlFile)
		local v69_ = 0
		for v70_, v71_ in ipairs(self.tireCombination.wheels) do
			if v71_.path ~= nil then
				local v72_ = string.format(".wheels.wheel(%d)", v70_ - 1)
				local v73_ = v71_.width
				local v74_, v75_
				if self.baseConfigItem.baseWheelData == nil or self.baseConfigItem.baseWheelData[v70_] == nil then
					v74_ = 0
					v75_ = 0
				else
					v73_ = self.baseConfigItem.baseWheelData[v70_].width
					v74_ = self.baseConfigItem.baseWheelData[v70_].xOffset
					v75_ = self.baseConfigItem.baseWheelData[v70_].rimOffset
				end
				local v76_ = WheelXMLObject.new(xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration", self.index, v72_, v68_)
				v76_:setXMLLoadKey("")
				local v77_ = (v76_:getLocalValue(".physics#xOffset", 0) - v74_) * 2 + (v76_:getLocalValue("#rimOffset", 0) - v75_) * 2
				local v78_ = v71_.width - v73_ + v77_
				local v79_ = math.max(v69_, v78_)
				local v80_ = 0
				local v81_ = 0
				while true do
					local v82_ = string.format(".additionalWheel(%d)", v80_)
					local v83_, _ = v76_:getXMLFileAndPropertyKey(v82_)
					if v83_ == nil then
						break
					end
					v81_ = v81_ + (v76_:getLocalValue(v82_ .. "#offset", 0) + v71_.width)
					v80_ = v80_ + 1
				end
				local v84_ = v81_ * 2 + (v71_.width - v73_) + v77_
				v69_ = math.max(v79_, v84_)
				v76_:delete()
			end
		end
		sizeData.width = sizeData.width + v69_
	end
end

-- Local values: i, baseConfigItem, hasWheelBrands, _, item, _, item
function VehicleConfigurationItemWheel.postLoad(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem, configName)
	VehicleConfigurationItemWheel:superClass().postLoad(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem, configName)
	for _, v93_ in ipairs(configurationItems) do
		if v93_.dimensionCombinations ~= nil and v93_.isSelectable then
			v93_.isSelectable = false
			VehicleConfigurationItemWheel.generateConfigurations(configurationItems, xmlFile, configName, v93_)
		end
	end
	local v94_ = false
	for _, v95_ in ipairs(configurationItems) do
		if v95_.wheelBrandName ~= nil then
			v94_ = true
			break
		end
	end
	if v94_ then
		for _, v96_ in ipairs(configurationItems) do
			if v96_.isSelectable and v96_.wheelBrandName == nil then
				Logging.xmlWarning(xmlFile, "Wheel brand missing for wheel configuration \'%s\'!", v96_.wheelBrandKey)
			end
		end
	end
end

-- Local values: parts, maxNumMatches, maxNumMatchesConfig, _, config, otherParts, numMatches, i
function VehicleConfigurationItemWheel.getFallbackConfigId(configs, configId, configName, configFileName)
	local v99_ = configId:split("_")
	local v100_ = 0
	local v101_ = nil
	for _, v102_ in pairs(configs) do
		local v103_ = v102_.saveId:split("_")
		local v104_ = #v99_
		local v105_ = #v103_
		local v106_ = 0
		for v107_ = 1, math.min(v104_, v105_) do
			if v99_[v107_] ~= v103_[v107_] then
				break
			end
			v106_ = v106_ + 1
		end
		if v100_ < v106_ then
			v101_ = v102_
			v100_ = v106_
		end
	end
	if v101_ == nil then
		return nil, nil
	else
		return v101_.index, v101_.saveId
	end
end

-- Local values: tireCombinations, _, tireCombination, configItem, index
function VehicleConfigurationItemWheel.generateConfigurations(configurationItems, xmlFile, configName, baseConfigItem)
	local v111_ = g_wheelManager:getTiresForDimensionCombinations(baseConfigItem.dimensionCombinations, baseConfigItem.tireCategories, baseConfigItem.whitelistedCombinations, baseConfigItem.numDynamicConfigurations, baseConfigItem.customBrandOrder)
	for _, v112_ in ipairs(v111_) do
		local v113_ = VehicleConfigurationItemWheel.new(configName)
		v113_.name = baseConfigItem.name
		if v112_.index > 1 then
			v113_.name = string.format("%s (%d)", v113_.name, v112_.index)
		end
		v113_.price = baseConfigItem.price
		v113_.wheelBrandName = v112_.wheelBrand.name
		v113_.wheelBrandIconFilename = v112_.wheelBrand.image
		v113_.isDefault = baseConfigItem.isDefault
		v113_.saveId = baseConfigItem.saveId .. "_" .. v112_.wheelSaveId
		v113_.isDynamicConfig = true
		v113_.tireCombination = v112_
		v113_.baseConfigItem = baseConfigItem
		v113_.maxForwardSpeed = baseConfigItem.maxForwardSpeed
		v113_.maxForwardSpeedShop = baseConfigItem.maxForwardSpeedShop
		table.insert(configurationItems, v113_)
		local v114_ = #configurationItems
		v113_:setIndex(v114_)
		v113_.configKey = string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration(%d)", v114_ - 1)
	end
end

-- Local values: configurationIndexToParentConfigIndex, wheelIndex, wheelData, wheelKey, wheeXMLObject, path, baseRadius, baseYOffset
function VehicleConfigurationItemWheel:applyGeneratedConfiguration(xmlFile)
	if self.isDynamicConfig then
		xmlFile:copyTree(self.baseConfigItem.configKey, self.configKey, true, ".wheel")
		xmlFile:setValue(self.configKey .. ".wheels#baseConfig", self.baseConfigItem.saveId)
		local v117_ = Wheels.createConfigToParentConfigMapping(xmlFile)
		for v118_, v119_ in ipairs(self.tireCombination.wheels) do
			local v120_ = string.format(".wheels.wheel(%d)", v118_ - 1)
			local v121_ = WheelXMLObject.new(xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration", self.baseConfigItem.index, v120_, v117_)
			v121_:setXMLLoadKey("")
			if v119_.path == nil then
				xmlFile:setBool(self.configKey .. v120_ .. "#temp", true)
			else
				local v122_ = v119_.path
				if string.startsWith(v122_, "data/shared/wheels") then
					v122_ = "$" .. v122_
				end
				xmlFile:setValue(self.configKey .. v120_ .. "#filename", v122_)
				local v123_ = v119_.radius
				if self.baseConfigItem.baseWheelData ~= nil and self.baseConfigItem.baseWheelData[v118_] ~= nil then
					v123_ = self.baseConfigItem.baseWheelData[v118_].radius
				end
				local v124_ = v121_:getLocalValue(".physics#yOffset") or 0
				xmlFile:setValue(self.configKey .. v120_ .. ".physics#yOffset", v124_ - (v123_ - v119_.radius))
			end
			v121_:delete()
		end
	end
end

-- Local values: parentConfigIndex, key, objects
function VehicleConfigurationItemWheel:applyObjectChanges(vehicle, configurationIndexToParentConfigIndex, index)
	local v129_ = configurationIndexToParentConfigIndex[index or self.index]
	if v129_ ~= nil then
		self:applyObjectChanges(vehicle, configurationIndexToParentConfigIndex, v129_)
	end
	local v130_ = string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration(%d)", (index or self.index) - 1)
	local v131_ = {}
	ObjectChangeUtil.loadObjectChangeFromXML(vehicle.xmlFile, v130_, v131_, vehicle.components, vehicle)
	ObjectChangeUtil.setObjectChanges(v131_, true, vehicle, vehicle.setMovingToolDirty)
end

function VehicleConfigurationItemWheel.registerXMLPaths(schema, rootPath, configPath)
	VehicleConfigurationItemWheel:superClass().registerXMLPaths(schema, rootPath, configPath)
	schema:register(XMLValueType.STRING, configPath .. "#brand", "Name of wheel brand")
	schema:register(XMLValueType.FLOAT, configPath .. "#maxForwardSpeed", "Max. speed to set on the transmission")
	schema:register(XMLValueType.FLOAT, configPath .. "#maxForwardSpeedShop", "Max. speed to display in the shop")
end
