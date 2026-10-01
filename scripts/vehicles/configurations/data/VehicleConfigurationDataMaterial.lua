VehicleConfigurationDataMaterial = {}
function VehicleConfigurationDataMaterial.registerXMLPaths(schema, rootPath, configPath)
	schema:setXMLSharedRegistration("VehicleConfigurationDataMaterial", configPath)
	local materialKey = configPath .. ".material(?)"
	VehicleMaterial.registerXMLPaths(schema, materialKey)
	schema:register(XMLValueType.BOOL, materialKey .. "#ignoreWarning", "If set to 'true' there is no warning if the material is not found.", false)
	schema:register(XMLValueType.NODE_INDEX, materialKey .. "#node", "If defined, the 'targetMaterialSlotName' is only replaced for this node")
	schema:register(XMLValueType.STRING, materialKey .. "#sourceMaterialSlotName", "Material with this slot name replaces the material defined with 'targetMaterialSlotName'")
	schema:register(XMLValueType.STRING, materialKey .. "#targetMaterialSlotName", "Material with this slot name is replaced the material defined with 'sourceMaterialSlotName'")
	schema:register(XMLValueType.BOOL, materialKey .. "#useBaseColor", "Use base vehicle color", false)
	schema:register(XMLValueType.INT, materialKey .. "#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
	schema:register(XMLValueType.BOOL, materialKey .. "#useRimColor", "Use rim color", false)
	schema:resetXMLSharedRegistration("VehicleConfigurationDataMaterial", configPath)
end
function VehicleConfigurationDataMaterial.onLoadFinished(vehicle, configItem, configId, ...)
	if configItem.configKey == "" then
		return
	else
		local color = nil
		if configItem:isa(VehicleConfigurationItemColor) then
			color = configItem:getColor()
		end
		vehicle.xmlFile:iterate(configItem.configKey .. ".material", function(index, materialKey)
			XMLUtil.checkDeprecatedXMLElements(vehicle.xmlFile, materialKey .. "#refNode", materialKey .. "#sourceMaterialSlotName")
			local targetMaterialSlotName = vehicle.xmlFile:getValue(materialKey .. "#materialSlotName")
			if targetMaterialSlotName ~= nil then
				local material = nil
				if vehicle.xmlFile:getValue(materialKey .. "#useBaseColor") then
					material = VehicleConfigurationItemColor.getMaterialByColorConfiguration(vehicle, "baseColor")
				else
					local useDesignColorIndex = vehicle.xmlFile:getValue(materialKey .. "#useDesignColorIndex")
					if useDesignColorIndex ~= nil then
						local configName = "designColor"
						if 2 <= useDesignColorIndex then
							configName = string.format("designColor%d", useDesignColorIndex)
						end
						material = VehicleConfigurationItemColor.getMaterialByColorConfiguration(vehicle, configName)
					elseif vehicle.xmlFile:getBool(materialKey .. "#useRimColor", false) then
						material = VehicleConfigurationItemColor.getMaterialByColorConfiguration(vehicle, "rimColor")
						if material == nil then
							material = VehicleMaterial.new(vehicle.baseDirectory)
							material:setTemplateName("RIM_DEFAULT")
						end
					end
				end
				if material == nil then
					material = VehicleMaterial.new(vehicle.baseDirectory)
					material:setColor(color)
					material:loadFromXML(vehicle.xmlFile, materialKey, vehicle.customEnvironment)
				end
				if material ~= nil and (targetMaterialSlotName ~= nil and (not material:applyToVehicle(vehicle, targetMaterialSlotName) and not vehicle.xmlFile:getValue(materialKey .. "#ignoreWarning", false))) then
					Logging.xmlWarning(vehicle.xmlFile, "Failed to find material by material slot name '%s' in '%s'", targetMaterialSlotName, materialKey)
				end
			else
				local node = vehicle.xmlFile:getValue(materialKey .. "#node", nil, vehicle.components, vehicle.i3dMappings)
				local sourceMaterialSlotName = vehicle.xmlFile:getValue(materialKey .. "#sourceMaterialSlotName")
				local targetMaterialSlotName = vehicle.xmlFile:getValue(materialKey .. "#targetMaterialSlotName")
				if sourceMaterialSlotName ~= nil and targetMaterialSlotName ~= nil then
					local oldMaterial = nil
					for _, component in pairs(vehicle.components) do
						oldMaterial = MaterialUtil.getMaterialBySlotName(component.node, targetMaterialSlotName)
						if oldMaterial == nil then
							continue
						end
						local newMaterial = nil
						for _, component in pairs(vehicle.components) do
							newMaterial = MaterialUtil.getMaterialBySlotName(component.node, sourceMaterialSlotName)
							if newMaterial == nil then
								continue
							end
							if oldMaterial ~= nil then
								if newMaterial ~= nil then
									if node ~= nil then
										MaterialUtil.replaceMaterialRec(node, oldMaterial, newMaterial)
										return
									else
										for _, component in pairs(vehicle.components) do
											MaterialUtil.replaceMaterialRec(component.node, oldMaterial, newMaterial)
										end
										return
									end
								end
								Logging.xmlWarning(vehicle.xmlFile, "Unable to find sourceMaterialSlotName '%s' in '%s'", sourceMaterialSlotName, configItem.configKey)
								return
							else
								Logging.xmlWarning(vehicle.xmlFile, "Unable to find targetMaterialSlotName '%s' in '%s'", targetMaterialSlotName, configItem.configKey)
								return
							end
						end
					end
				end
				if sourceMaterialSlotName ~= nil or targetMaterialSlotName ~= nil then
					Logging.xmlWarning(vehicle.xmlFile, "Both 'sourceMaterialSlotName' and 'targetMaterialSlotName' need to be defined in '%s'", materialKey)
				end
			end
		end)
	end
end
VehicleConfigurationItem.registerGlobalConfigurationData(VehicleConfigurationDataMaterial)
