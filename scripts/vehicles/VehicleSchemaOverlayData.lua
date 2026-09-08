-- Local values: VehicleSchemaOverlayData_mt
VehicleSchemaOverlayData = {}
local VehicleSchemaOverlayData_mt = Class(VehicleSchemaOverlayData)

-- Upvalues: VehicleSchemaOverlayData_mt
-- Local values: self
function VehicleSchemaOverlayData.new(offsetX, offsetY, schemaName, invisibleBorderRight, invisibleBorderLeft)
	-- upvalues: (copy) VehicleSchemaOverlayData_mt
	local v7_ = VehicleSchemaOverlayData_mt
	local v8_ = setmetatable({}, v7_)
	v8_.offsetX = offsetX or 0
	v8_.offsetY = offsetY or 0
	v8_.schemaName = schemaName
	v8_.invisibleBorderRight = invisibleBorderRight or 0.05
	v8_.invisibleBorderLeft = invisibleBorderLeft or 0.05
	v8_.attacherJoints = nil
	return v8_
end

-- Local values: attacherJointData
function VehicleSchemaOverlayData:addAttacherJoint(attacherOffsetX, attacherOffsetY, rotation, invertX, liftedOffsetX, liftedOffsetY)
	if not self.attacherJoints then
		self.attacherJoints = {}
	end
	local v16_ = self.attacherJoints
	table.insert(v16_, {
		["x"] = attacherOffsetX or 0,
		["y"] = attacherOffsetY or 0,
		["rotation"] = rotation or 0,
		["invertX"] = invertX and true or false,
		["liftedOffsetX"] = liftedOffsetX or 0,
		["liftedOffsetY"] = liftedOffsetY or 5
	})
end
VehicleSchemaOverlayData.SCHEMA_OVERLAY = {}
VehicleSchemaOverlayData.SCHEMA_OVERLAY.VEHICLE = "VEHICLE"
VehicleSchemaOverlayData.SCHEMA_OVERLAY.HARVESTER = "HARVESTER"
VehicleSchemaOverlayData.SCHEMA_OVERLAY.TRUCK = "TRUCK"
VehicleSchemaOverlayData.SCHEMA_OVERLAY.CAR = "CAR"
VehicleSchemaOverlayData.SCHEMA_OVERLAY.LOADER = "LOADER"
VehicleSchemaOverlayData.SCHEMA_OVERLAY.IMPLEMENT = "IMPLEMENT"
VehicleSchemaOverlayData.SCHEMA_OVERLAY.TRAILER = "TRAILER"
VehicleSchemaOverlayData.SCHEMA_OVERLAY.COMBINE_HEADER = "COMBINE_HEADER"
VehicleSchemaOverlayData.SCHEMA_OVERLAY.FRONTLOADER = "FRONTLOADER"
VehicleSchemaOverlayData.SCHEMA_OVERLAY.MOTORBIKE = "MOTORBIKE"
