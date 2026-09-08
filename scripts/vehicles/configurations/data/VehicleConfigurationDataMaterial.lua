VehicleConfigurationDataMaterial = {}

-- Local values: materialKey
function VehicleConfigurationDataMaterial.registerXMLPaths(schema, rootPath, configPath)
	schema:setXMLSharedRegistration("VehicleConfigurationDataMaterial", configPath)
	local v3_ = configPath .. ".material(?)"
	VehicleMaterial.registerXMLPaths(schema, v3_)
	schema:register(XMLValueType.BOOL, v3_ .. "#ignoreWarning", "If set to \'true\' there is no warning if the material is not found.", false)
	schema:register(XMLValueType.NODE_INDEX, v3_ .. "#node", "If defined, the \'targetMaterialSlotName\' is only replaced for this node")
	schema:register(XMLValueType.STRING, v3_ .. "#sourceMaterialSlotName", "Material with this slot name replaces the material defined with \'targetMaterialSlotName\'")
	schema:register(XMLValueType.STRING, v3_ .. "#targetMaterialSlotName", "Material with this slot name is replaced the material defined with \'sourceMaterialSlotName\'")
	schema:register(XMLValueType.BOOL, v3_ .. "#useBaseColor", "Use base vehicle color", false)
	schema:register(XMLValueType.INT, v3_ .. "#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
	schema:register(XMLValueType.BOOL, v3_ .. "#useRimColor", "Use rim color", false)
	schema:resetXMLSharedRegistration("VehicleConfigurationDataMaterial", configPath)
end
function VehicleConfigurationDataMaterial.onLoadFinished(p_u_4_, p_u_5_, _, ...)
	if p_u_5_.configKey ~= "" then
		local v_u_6_
		if p_u_5_:isa(VehicleConfigurationItemColor) then
			v_u_6_ = p_u_5_:getColor()
		else
			v_u_6_ = nil
		end
		p_u_4_.xmlFile:iterate(p_u_5_.configKey .. ".material", function(_, p7_)
			-- upvalues: (copy) p_u_4_, (ref) v_u_6_, (copy) p_u_5_
			XMLUtil.checkDeprecatedXMLElements(p_u_4_.xmlFile, p7_ .. "#refNode", p7_ .. "#sourceMaterialSlotName")
			local v8_ = p_u_4_.xmlFile:getValue(p7_ .. "#materialSlotName")
			if v8_ == nil then
				local v9_ = p_u_4_.xmlFile:getValue(p7_ .. "#node", nil, p_u_4_.components, p_u_4_.i3dMappings)
				local v10_ = p_u_4_.xmlFile:getValue(p7_ .. "#sourceMaterialSlotName")
				local v11_ = p_u_4_.xmlFile:getValue(p7_ .. "#targetMaterialSlotName")
				if v10_ ~= nil and v11_ ~= nil then
					local v12_ = nil
					for _, v13_ in pairs(p_u_4_.components) do
						v12_ = MaterialUtil.getMaterialBySlotName(v13_.node, v11_)
						if v12_ ~= nil then
							break
						end
					end
					local v14_ = nil
					for _, v15_ in pairs(p_u_4_.components) do
						v14_ = MaterialUtil.getMaterialBySlotName(v15_.node, v10_)
						if v14_ ~= nil then
							break
						end
					end
					if v12_ == nil then
						Logging.xmlWarning(p_u_4_.xmlFile, "Unable to find targetMaterialSlotName \'%s\' in \'%s\'", v11_, p_u_5_.configKey)
						return
					elseif v14_ == nil then
						Logging.xmlWarning(p_u_4_.xmlFile, "Unable to find sourceMaterialSlotName \'%s\' in \'%s\'", v10_, p_u_5_.configKey)
						return
					elseif v9_ == nil then
						for _, v16_ in pairs(p_u_4_.components) do
							MaterialUtil.replaceMaterialRec(v16_.node, v12_, v14_)
						end
					else
						MaterialUtil.replaceMaterialRec(v9_, v12_, v14_)
					end
				end
				if v10_ ~= nil or v11_ ~= nil then
					Logging.xmlWarning(p_u_4_.xmlFile, "Both \'sourceMaterialSlotName\' and \'targetMaterialSlotName\' need to be defined in \'%s\'", p7_)
				end
			else
				local v17_ = nil
				if p_u_4_.xmlFile:getValue(p7_ .. "#useBaseColor") then
					v17_ = VehicleConfigurationItemColor.getMaterialByColorConfiguration(p_u_4_, "baseColor")
				else
					local v18_ = p_u_4_.xmlFile:getValue(p7_ .. "#useDesignColorIndex")
					if v18_ == nil then
						if p_u_4_.xmlFile:getBool(p7_ .. "#useRimColor", false) then
							v17_ = VehicleConfigurationItemColor.getMaterialByColorConfiguration(p_u_4_, "rimColor")
							if v17_ == nil then
								v17_ = VehicleMaterial.new(p_u_4_.baseDirectory)
								v17_:setTemplateName("RIM_DEFAULT")
							end
						end
					else
						local v19_ = v18_ < 2 and "designColor" or string.format("designColor%d", v18_)
						v17_ = VehicleConfigurationItemColor.getMaterialByColorConfiguration(p_u_4_, v19_)
					end
				end
				if v17_ == nil then
					v17_ = VehicleMaterial.new(p_u_4_.baseDirectory)
					v17_:setColor(v_u_6_)
					v17_:loadFromXML(p_u_4_.xmlFile, p7_, p_u_4_.customEnvironment)
				end
				if v17_ ~= nil and (v8_ ~= nil and not (v17_:applyToVehicle(p_u_4_, v8_) or p_u_4_.xmlFile:getValue(p7_ .. "#ignoreWarning", false))) then
					Logging.xmlWarning(p_u_4_.xmlFile, "Failed to find material by material slot name \'%s\' in \'%s\'", v8_, p7_)
					return
				end
			end
		end)
	end
end
VehicleConfigurationItem.registerGlobalConfigurationData(VehicleConfigurationDataMaterial)
