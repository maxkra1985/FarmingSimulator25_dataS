TipOccluder = {}

function TipOccluder.prerequisitesPresent(self)
	return true
end
function TipOccluder.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("TipOccluder")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.tipOccluder.occlusionArea(?)#start", "Start node")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.tipOccluder.occlusionArea(?)#width", "Width node")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.tipOccluder.occlusionArea(?)#height", "Height node")
	v1_:setXMLSpecializationType()
end

function TipOccluder.registerFunctions(self)
	SpecializationUtil.registerFunction(vehicleType, "getTipOcclusionAreas", TipOccluder.getTipOcclusionAreas)
	SpecializationUtil.registerFunction(vehicleType, "getWheelsWithTipOcclisionAreaGroupId", TipOccluder.getWheelsWithTipOcclisionAreaGroupId)
	SpecializationUtil.registerFunction(vehicleType, "getRequiresTipOcclusionArea", TipOccluder.getRequiresTipOcclusionArea)
end

function TipOccluder.registerOverwrittenFunctions(self) end

function TipOccluder.registerEventListeners(self)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", TipOccluder)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", TipOccluder)
end

-- Local values: spec, i, key, entry
function TipOccluder:onLoad(savegame)
	local v5_ = self.spec_tipOccluder
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.tipOcclusionAreas.tipOcclusionArea", "vehicle.tipOccluder.occlusionArea")
	v5_.tipOcclusionAreas = {}
	local v6_ = 0
	while true do
		local v7_ = string.format("vehicle.tipOccluder.occlusionArea(%d)", v6_)
		if not self.xmlFile:hasProperty(v7_) then
			break
		end
		local v8_ = {
			["start"] = self.xmlFile:getValue(v7_ .. "#start", nil, self.components, self.i3dMappings),
			["width"] = self.xmlFile:getValue(v7_ .. "#width", nil, self.components, self.i3dMappings),
			["height"] = self.xmlFile:getValue(v7_ .. "#height", nil, self.components, self.i3dMappings)
		}
		if v8_.start ~= nil and (v8_.width ~= nil and v8_.height ~= nil) then
			local v9_ = v5_.tipOcclusionAreas
			table.insert(v9_, v8_)
		end
		v6_ = v6_ + 1
	end
	v5_.createdTipOcclusionAreaGroupIds = {}
end

-- Local values: i, wheel, spec, wheelGroupId, vehicleRootNode, doCreate, area, groupId, occluderArea, start, width, height, xMax, xMin, zMax, zMin, usedWheels, rootNodeToUse, _, usedWheel, x, _, z
function TipOccluder:onLoadFinished(savegame)
	if self.getWheels ~= nil then
		for _, v11_ in ipairs(self:getWheels()) do
			local v12_ = self.spec_tipOccluder
			local v13_ = v11_.physics.tipOcclusionAreaGroupId
			if v13_ ~= nil then
				local v14_ = self.components[1].node
				local v15_ = true
				local v16_ = nil
				for v17_, v18_ in pairs(v12_.createdTipOcclusionAreaGroupIds) do
					if v17_ == v13_ then
						v16_ = v18_
						v15_ = false
						break
					end
				end
				if v15_ then
					local v19_ = createTransformGroup(string.format("tipOcclusionAreaGroupId%d", v13_))
					local v20_ = createTransformGroup(string.format("tipOcclusionAreaGroupId%d", v13_))
					local v21_ = createTransformGroup(string.format("tipOcclusionAreaGroupId%d", v13_))
					link(v14_, v19_)
					link(v14_, v20_)
					link(v14_, v21_)
					v16_ = {
						["start"] = v19_,
						["width"] = v20_,
						["height"] = v21_
					}
					local v22_ = v12_.tipOcclusionAreas
					table.insert(v22_, v16_)
					v12_.createdTipOcclusionAreaGroupIds[v13_] = v16_
				end
				if v16_ ~= nil then
					local v23_ = self:getWheelsWithTipOcclisionAreaGroupId(self:getWheels(), v13_)
					table.insert(v23_, v11_)
					local v24_ = v23_[#v23_].node
					link(v24_, v16_.start)
					link(v24_, v16_.width)
					link(v24_, v16_.height)
					local v25_ = -math.huge
					local v26_ = math.huge
					local v27_ = math.huge
					local v28_ = -math.huge
					for _, v29_ in pairs(v23_) do
						local v30_, _, v31_ = localToLocal(v29_.driveNode, v24_, v29_.physics.wheelShapeWidth - 0.5 * v29_.physics.width, 0, -v29_.physics.radius)
						v25_ = math.max(v30_, v25_)
						v26_ = math.min(v31_, v26_)
						local v32_, _, v33_ = localToLocal(v29_.driveNode, v24_, -v29_.physics.wheelShapeWidth + 0.5 * v29_.physics.width, 0, v29_.physics.radius)
						v27_ = math.min(v32_, v27_)
						v28_ = math.max(v33_, v28_)
					end
					setTranslation(v16_.start, v25_, 0, v26_)
					setTranslation(v16_.width, v27_, 0, v26_)
					setTranslation(v16_.height, v25_, 0, v28_)
				end
			end
		end
	end
	if self:getRequiresTipOcclusionArea() and #self.spec_tipOccluder.tipOcclusionAreas == 0 then
		Logging.xmlDevWarning(self.xmlFile, "No TipOcclusionArea defined")
	end
end

function TipOccluder:getTipOcclusionAreas()
	return self.spec_tipOccluder.tipOcclusionAreas
end

-- Local values: returnWheels, _, wheel
function TipOccluder:getWheelsWithTipOcclisionAreaGroupId(wheels, groupId)
	local v37_ = {}
	for _, v38_ in pairs(wheels) do
		if v38_.physics.tipOcclusionAreaGroupId == groupId then
			table.insert(v37_, v38_)
		end
	end
	return v37_
end

function TipOccluder.getRequiresTipOcclusionArea(self)
	return false
end
