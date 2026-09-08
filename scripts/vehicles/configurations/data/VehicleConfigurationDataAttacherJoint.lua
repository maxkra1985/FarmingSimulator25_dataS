VehicleConfigurationDataAttacherJoint = {}

function VehicleConfigurationDataAttacherJoint.registerXMLPaths(schema, rootPath, configPath)
	AttacherJoints.registerAttacherJointXMLPaths(schema, configPath)
end

-- Local values: _, key, attacherJoint
function VehicleConfigurationDataAttacherJoint.onPrePostLoad(vehicle, configItem, configId)
	if configItem.configKey ~= "" then
		if vehicle.spec_attacherJoints ~= nil then
			for _, v5_ in vehicle.xmlFile:iterator(configItem.configKey .. ".attacherJoint") do
				local v6_ = {}
				if vehicle:loadAttacherJointFromXML(v6_, vehicle.xmlFile, v5_, 0) then
					local v7_ = vehicle.spec_attacherJoints.attacherJoints
					table.insert(v7_, v6_)
				end
			end
		end
	end
end
VehicleConfigurationItem.registerGlobalConfigurationData(VehicleConfigurationDataAttacherJoint)
