VehicleConfigurationDataAdditionalMass = {}

function VehicleConfigurationDataAdditionalMass.registerXMLPaths(schema, rootPath, configPath)
	schema:setXMLSharedRegistration("VehicleConfigurationDataAdditionalMass", configPath)
	schema:register(XMLValueType.NODE_INDEX, configPath .. ".component(?)#node", "Component node")
	schema:register(XMLValueType.NODE_INDEX, configPath .. ".component(?)#additionalMassNode", "At this position, the additional mass will be applied to the component")
	schema:register(XMLValueType.VECTOR_TRANS, configPath .. ".component(?)#additionalMassOffset", "Offset to the component node to apply the mass there")
	schema:register(XMLValueType.FLOAT, configPath .. ".component(?)#additionalMass", "Additional mass that is added to the component")
	schema:register(XMLValueType.BOOL, configPath .. ".component(?)#useTotalMassReference", "Use total mass of vehicle as reference for center of mass adjustment. Otherwise just the mass of the component itself", true)
	schema:register(XMLValueType.INT, configPath .. ".component(?).dependentComponentJoint#index", "Index of the component joint to influence")
	schema:register(XMLValueType.FLOAT, configPath .. ".component(?).dependentComponentJoint#transSpringFactor", "Factor that is applied to the trans spring of the component joint")
	schema:register(XMLValueType.FLOAT, configPath .. ".component(?).dependentComponentJoint#transDampingFactor", "Factor that is applied to the trans damping of the component joint")
	schema:resetXMLSharedRegistration("VehicleConfigurationDataAdditionalMass", configPath)
end

-- Local values: _, key, componentNode, additionalMass, additionalMassNode, additionalMassOffset, useTotalMassReference, componentJointIndex, transSpringFactor, transDampingFactor, totalMass, _, component, _, component, comX, comY, comZ, massX, massY, massZ, alpha, invAlpha
function VehicleConfigurationDataAdditionalMass.onLoad(vehicle, configItem, configId)
	if configItem.configKey ~= "" then
		for _, v5_ in vehicle.xmlFile:iterator(configItem.configKey .. ".component") do
			local v6_ = vehicle.xmlFile:getValue(v5_ .. "#node", nil, vehicle.components, vehicle.i3dMappings)
			local v7_ = vehicle.xmlFile:getValue(v5_ .. "#additionalMass", 0) * 0.001
			if v6_ ~= nil and v7_ ~= 0 then
				local v8_ = vehicle.xmlFile:getValue(v5_ .. "#additionalMassNode", nil, vehicle.components, vehicle.i3dMappings)
				local v9_ = vehicle.xmlFile:getValue(v5_ .. "#additionalMassOffset", nil, true)
				local v10_ = vehicle.xmlFile:getValue(v5_ .. "#useTotalMassReference", true)
				local v11_ = vehicle.xmlFile:getValue(v5_ .. ".dependentComponentJoint#index", nil)
				if v11_ ~= nil then
					local v12_ = vehicle.xmlFile:getValue(v5_ .. ".dependentComponentJoint#transSpringFactor", 1)
					local v13_ = vehicle.xmlFile:getValue(v5_ .. ".dependentComponentJoint#transDampingFactor", 1)
					if vehicle.setDependentComponentJointBaseFactors ~= nil then
						vehicle:setDependentComponentJointBaseFactors(v11_, v12_, v13_)
					end
				end
				local v14_ = 0
				for _, v15_ in ipairs(vehicle.components) do
					v14_ = v14_ + v15_.defaultMass
				end
				for _, v16_ in ipairs(vehicle.components) do
					if v16_.node == v6_ then
						if v8_ ~= nil or v9_ ~= nil then
							local v17_, v18_, v19_ = getCenterOfMass(v6_)
							local v20_, v21_, v22_
							if v8_ == nil then
								v20_ = v9_[1]
								v21_ = v9_[2]
								v22_ = v9_[3]
							else
								v20_, v21_, v22_ = localToLocal(v8_, v6_, 0, 0, 0)
							end
							local v23_ = v7_ / (v10_ and v14_ and v14_ or v16_.defaultMass)
							local v24_ = 1 - v23_
							local v25_ = v17_ * v24_ + v20_ * v23_
							local v26_ = v18_ * v24_ + v21_ * v23_
							local v27_ = v19_ * v24_ + v22_ * v23_
							setCenterOfMass(v6_, v25_, v26_, v27_)
						end
						v16_.defaultMass = v16_.defaultMass + v7_
						break
					end
				end
			end
		end
	end
end
VehicleConfigurationItem.registerGlobalConfigurationData(VehicleConfigurationDataAdditionalMass)
