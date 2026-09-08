Ropes = {}

function Ropes.prerequisitesPresent(specializations)
	return true
end
function Ropes.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("Ropes")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.ropes.rope(?)#baseNode", "Base node")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.ropes.rope(?)#targetNode", "Target node")
	v1_:register(XMLValueType.VECTOR_4, "vehicle.ropes.rope(?)#baseParameters", "Base parameters")
	v1_:register(XMLValueType.VECTOR_4, "vehicle.ropes.rope(?)#targetParameters", "Target parameters")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.ropes.rope(?).baseParameterAdjuster(?)#node", "Adjuster node")
	v1_:register(XMLValueType.INT, "vehicle.ropes.rope(?).baseParameterAdjuster(?)#rotationAxis", "Rotation axis")
	v1_:register(XMLValueType.VECTOR_ROT_2, "vehicle.ropes.rope(?).baseParameterAdjuster(?)#rotationRange", "Rotation range")
	v1_:register(XMLValueType.INT, "vehicle.ropes.rope(?).baseParameterAdjuster(?)#translationAxis", "Translation axis")
	v1_:register(XMLValueType.VECTOR_2, "vehicle.ropes.rope(?).baseParameterAdjuster(?)#translationRange", "Translation range")
	v1_:register(XMLValueType.VECTOR_4, "vehicle.ropes.rope(?).baseParameterAdjuster(?)#minTargetParameters", "Min. target parameters")
	v1_:register(XMLValueType.VECTOR_4, "vehicle.ropes.rope(?).baseParameterAdjuster(?)#maxTargetParameters", "Max. target parameters")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.ropes.rope(?).targetParameterAdjuster(?)#node", "Adjuster node")
	v1_:register(XMLValueType.INT, "vehicle.ropes.rope(?).targetParameterAdjuster(?)#rotationAxis", "Rotation axis")
	v1_:register(XMLValueType.VECTOR_ROT_2, "vehicle.ropes.rope(?).targetParameterAdjuster(?)#rotationRange", "Rotation range")
	v1_:register(XMLValueType.INT, "vehicle.ropes.rope(?).targetParameterAdjuster(?)#translationAxis", "Translation axis")
	v1_:register(XMLValueType.VECTOR_2, "vehicle.ropes.rope(?).targetParameterAdjuster(?)#translationRange", "Translation range")
	v1_:register(XMLValueType.VECTOR_4, "vehicle.ropes.rope(?).targetParameterAdjuster(?)#minTargetParameters", "Min. target parameters")
	v1_:register(XMLValueType.VECTOR_4, "vehicle.ropes.rope(?).targetParameterAdjuster(?)#maxTargetParameters", "Max. target parameters")
	v1_:setXMLSpecializationType()
end

function Ropes.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadAdjusterNode", Ropes.loadAdjusterNode)
	SpecializationUtil.registerFunction(vehicleType, "updateRopes", Ropes.updateRopes)
	SpecializationUtil.registerFunction(vehicleType, "updateAdjusterNodes", Ropes.updateAdjusterNodes)
end

function Ropes.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Ropes)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Ropes)
	SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", Ropes)
end

-- Local values: spec, _ropeIndex, ropeKey, entry, x, y, z, _, adjusterKey, adjusterNode, _, adjusterKey, adjusterNode
function Ropes:onLoad(savegame)
	local v5_ = self.spec_ropes
	if self.isClient then
		v5_.ropes = {}
		for _, v6_ in self.xmlFile:iterator("vehicle.ropes.rope") do
			local v7_ = {
				["baseNode"] = self.xmlFile:getValue(v6_ .. "#baseNode", nil, self.components, self.i3dMappings),
				["targetNode"] = self.xmlFile:getValue(v6_ .. "#targetNode", nil, self.components, self.i3dMappings),
				["baseParameters"] = self.xmlFile:getValue(v6_ .. "#baseParameters", nil, true)
			}
			if v7_.baseParameters == nil then
				Logging.xmlWarning(self.xmlFile, "Missing values for \'%s\'", v6_ .. "#baseParameters")
			else
				v7_.targetParameters = self.xmlFile:getValue(v6_ .. "#targetParameters", nil, true)
				if v7_.targetParameters == nil then
					Logging.xmlWarning(self.xmlFile, "Missing values for \'%s\'", v6_ .. "#targetParameters")
				else
					setShaderParameter(v7_.baseNode, "cv0", v7_.baseParameters[1], v7_.baseParameters[2], v7_.baseParameters[3], v7_.baseParameters[4], false)
					setShaderParameter(v7_.baseNode, "cv1", 0, 0, 0, 0, false)
					local v8_, v9_, v10_ = localToLocal(v7_.targetNode, v7_.baseNode, v7_.targetParameters[1], v7_.targetParameters[2], v7_.targetParameters[3])
					setShaderParameter(v7_.baseNode, "cv3", v8_, v9_, v10_, 0, false)
					v7_.baseParameterAdjusters = {}
					for _, v11_ in self.xmlFile:iterator(v6_ .. "baseParameterAdjuster") do
						local v12_ = {}
						if self:loadAdjusterNode(v12_, self.xmlFile, v11_) then
							local v13_ = v7_.baseParameterAdjusters
							table.insert(v13_, v12_)
						end
					end
					v7_.targetParameterAdjusters = {}
					for _, v14_ in self.xmlFile:iterator(v6_ .. "targetParameterAdjuster") do
						local v15_ = {}
						if self:loadAdjusterNode(v15_, self.xmlFile, v14_) then
							local v16_ = v7_.targetParameterAdjusters
							table.insert(v16_, v15_)
						end
					end
					local v17_ = v5_.ropes
					table.insert(v17_, v7_)
				end
			end
		end
	end
	if not self.isClient or #v5_.ropes == 0 then
		SpecializationUtil.removeEventListener(self, "onLoadFinished", Ropes)
		SpecializationUtil.removeEventListener(self, "onPostUpdate", Ropes)
	end
end

function Ropes:onLoadFinished(savegame)
	self:updateRopes(9999)
end

function Ropes:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	Ropes.onPostUpdate(self, dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
end

function Ropes:onPostUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	self:updateRopes(dt)
end

-- Local values: node
function Ropes:loadAdjusterNode(adjusterNode, xmlFile, key)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", key .. "#node")
	local v30_ = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if v30_ == nil then
		Logging.xmlWarning(self.xmlFile, "Missing node attribute in \'%s\'", key)
		return false
	end
	adjusterNode.node = v30_
	adjusterNode.rotationAxis = xmlFile:getValue(key .. "#rotationAxis", 1)
	adjusterNode.rotationRange = xmlFile:getValue(key .. "#rotationRange", nil, true)
	adjusterNode.translationAxis = xmlFile:getValue(key .. "#translationAxis", 1)
	adjusterNode.translationRange = xmlFile:getValue(key .. "#translationRange", nil, true)
	adjusterNode.minTargetParameters = xmlFile:getValue(key .. "#minTargetParameters", nil, true)
	if adjusterNode.minTargetParameters == nil then
		Logging.xmlWarning(self.xmlFile, "Missing minTargetParameters attribute in \'%s\'", key)
		return false
	end
	adjusterNode.maxTargetParameters = xmlFile:getValue(key .. "#maxTargetParameters", nil, true)
	if adjusterNode.maxTargetParameters ~= nil then
		return true
	end
	Logging.xmlWarning(self.xmlFile, "Missing maxTargetParameters attribute in \'%s\'", key)
	return false
end

-- Local values: spec, _, rope, x, y, z
function Ropes:updateRopes(dt)
	local v32_ = self.spec_ropes
	for _, v33_ in pairs(v32_.ropes) do
		local v34_, v35_, v36_ = self:updateAdjusterNodes(v33_.baseParameterAdjusters)
		setShaderParameter(v33_.baseNode, "cv0", v33_.baseParameters[1] + v34_, v33_.baseParameters[2] + v35_, v33_.baseParameters[3] + v36_, 0, false)
		local v37_, v38_, v39_ = localToLocal(v33_.targetNode, v33_.baseNode, 0, 0, 0)
		setShaderParameter(v33_.baseNode, "cv2", 0, 0, 0, 0, false)
		setShaderParameter(v33_.baseNode, "cv3", v37_, v38_, v39_, 0, false)
		local v40_, v41_, v42_ = self:updateAdjusterNodes(v33_.targetParameterAdjusters)
		local v43_, v44_, v45_ = localToLocal(v33_.targetNode, v33_.baseNode, v33_.targetParameters[1] + v40_, v33_.targetParameters[2] + v41_, v33_.targetParameters[3] + v42_)
		setShaderParameter(v33_.baseNode, "cv4", v43_, v44_, v45_, 0, false)
	end
end

-- Local values: xRet, yRet, zRet, _, adjusterNode, rotations, rot, alpha, x, y, z, translations, trans, alpha, x, y, z
function Ropes:updateAdjusterNodes(adjusterNodes)
	local v47_ = 0
	local v48_ = 0
	local v49_ = 0
	for _, v50_ in pairs(adjusterNodes) do
		if v50_.rotationAxis == nil or v50_.rotationRange == nil then
			if v50_.translationAxis ~= nil and v50_.translationRange ~= nil then
				local v51_ = (({ getTranslation(v50_.node) })[v50_.translationAxis] - v50_.translationRange[1]) / (v50_.translationRange[2] - v50_.translationRange[1])
				local v52_ = math.min(1, v51_)
				local v53_ = math.max(0, v52_)
				local v54_, v55_, v56_ = MathUtil.vector3ArrayLerp(v50_.minTargetParameters, v50_.maxTargetParameters, v53_)
				v47_ = v47_ + v54_
				v48_ = v48_ + v55_
				v49_ = v49_ + v56_
			end
		else
			local v57_ = (({ getRotation(v50_.node) })[v50_.rotationAxis] - v50_.rotationRange[1]) / (v50_.rotationRange[2] - v50_.rotationRange[1])
			local v58_ = math.min(1, v57_)
			local v59_ = math.max(0, v58_)
			local v60_, v61_, v62_ = MathUtil.vector3ArrayLerp(v50_.minTargetParameters, v50_.maxTargetParameters, v59_)
			v47_ = v47_ + v60_
			v48_ = v48_ + v61_
			v49_ = v49_ + v62_
		end
	end
	return v47_, v48_, v49_
end
