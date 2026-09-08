HeadlandAnimation = {}

function HeadlandAnimation.prerequisitesPresent(vehicleType)
	return true
end
function HeadlandAnimation.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("HeadlandAnimation")
	v1_:register(XMLValueType.TIME, "vehicle.headlandAnimation#activationDelay", "Headland is activated after this time above activationAngle", 0.5)
	v1_:register(XMLValueType.TIME, "vehicle.headlandAnimation#deactivationDelay", "Headland is deactivated after this time below deactivationAngle", 4)
	v1_:register(XMLValueType.FLOAT, "vehicle.headlandAnimation#activationAngle", "Headland is activated above this steering percentage [0-1]", 0.2)
	v1_:register(XMLValueType.FLOAT, "vehicle.headlandAnimation#deactivationAngle", "Headland is deactivated below this steering percentage [0-1]", 0.13)
	v1_:register(XMLValueType.STRING, "vehicle.headlandAnimation#requiredGroundTypes", "Headland is only activated one of these ground types is below vehicle")
	v1_:register(XMLValueType.STRING, "vehicle.headlandAnimation.animation(?)#name", "Animation name")
	v1_:register(XMLValueType.FLOAT, "vehicle.headlandAnimation.animation(?)#speed", "Animation speed")
	v1_:setXMLSpecializationType()
end

function HeadlandAnimation.registerFunctions(vehicleType) end

function HeadlandAnimation.registerOverwrittenFunctions(vehicleType) end

function HeadlandAnimation.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", HeadlandAnimation)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", HeadlandAnimation)
end

-- Local values: spec, requiredGroundTypesStr, i, name, groundType, i, baseKey, animation
function HeadlandAnimation:onLoad(savegame)
	local v4_ = self.spec_headlandAnimation
	v4_.isAvailable = self.xmlFile:hasProperty("vehicle.headlandAnimation")
	if v4_.isAvailable then
		v4_.headlandActivationDelay = self.xmlFile:getValue("vehicle.headlandAnimation#activationDelay", 0.5)
		v4_.headlandDeactivationDelay = self.xmlFile:getValue("vehicle.headlandAnimation#deactivationDelay", 4)
		v4_.headlandActivationAngle = self.xmlFile:getValue("vehicle.headlandAnimation#activationAngle", 0.2)
		v4_.headlandDeactivationAngle = self.xmlFile:getValue("vehicle.headlandAnimation#deactivationAngle", 0.13)
		local v5_ = self.xmlFile:getValue("vehicle.headlandAnimation#requiredGroundTypes"):split(" ")
		v4_.requiredGroundTypes = {}
		for v6_ = 1, #v5_ do
			local v7_ = v5_[v6_]
			if v7_ ~= nil and v7_ ~= "" then
				local v8_ = FieldGroundType[v7_]
				if v8_ == nil then
					Logging.xmlWarning(self.xmlFile, "Unknown ground type \'%s\' defined for headland animation", v7_)
				else
					v4_.requiredGroundTypes[v8_] = true
				end
			end
		end
		v4_.headlandDeactivationTime = 0
		v4_.headlandState = false
		v4_.lastHeadlandState = false
		v4_.animations = {}
		local v9_ = 0
		while true do
			local v10_ = string.format("vehicle.headlandAnimation.animation(%d)", v9_)
			if not self.xmlFile:hasProperty(v10_) then
				break
			end
			local v11_ = {
				["name"] = self.xmlFile:getValue(v10_ .. "#name"),
				["speed"] = self.xmlFile:getValue(v10_ .. "#speed")
			}
			if v11_.name ~= nil then
				local v12_ = v4_.animations
				table.insert(v12_, v11_)
			end
			v9_ = v9_ + 1
		end
	else
		SpecializationUtil.removeEventListener(self, "onUpdate", HeadlandAnimation)
	end
end

-- Local values: spec, validGround, x, y, z, _, _, groundType, direction, i, animation
function HeadlandAnimation:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v15_ = self.spec_headlandAnimation
	local v16_ = true
	if v15_.headlandRequiredDensityBits ~= 0 then
		local v17_, v18_, v19_ = getWorldTranslation(self.components[1].node)
		local _, _, v20_ = FSDensityMapUtil.getFieldDataAtWorldPosition(v17_, v18_, v19_)
		if v15_.requiredGroundTypes[v20_] ~= true then
			v16_ = false
		end
	end
	if v16_ then
		local v21_ = self.rotatedTime
		if math.abs(v21_) > v15_.headlandActivationAngle then
			v15_.headlandDeactivationTime = v15_.headlandDeactivationTime + dt
			if v15_.headlandDeactivationTime > v15_.headlandActivationDelay then
				v15_.headlandState = true
				v15_.headlandDeactivationTime = v15_.headlandDeactivationDelay
			end
			::l8::
			if v15_.headlandDeactivationTime == 0 then
				v15_.headlandState = false
			end
			if v15_.headlandState ~= v15_.lastHeadlandState then
				local v22_ = v15_.headlandState and 1 or -1
				for v23_ = 1, #v15_.animations do
					local v24_ = v15_.animations[v23_]
					self:playAnimation(v24_.name, v24_.speed * v22_, self:getAnimationTime(v24_.name))
				end
				v15_.lastHeadlandState = v15_.headlandState
			end
			return
		end
	end
	local v25_ = self.rotatedTime
	if math.abs(v25_) < v15_.headlandDeactivationAngle then
		local v26_ = v15_.headlandDeactivationTime - dt
		v15_.headlandDeactivationTime = math.max(v26_, 0)
	end
	goto l8
end
