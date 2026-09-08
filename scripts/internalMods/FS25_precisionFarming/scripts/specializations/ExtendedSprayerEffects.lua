ExtendedSprayerEffects = {}
ExtendedSprayerEffects.SPEC_NAME = g_currentModName .. ".extendedSprayerEffects"
ExtendedSprayerEffects.SPEC_TABLE_NAME = "spec_" .. g_currentModName .. ".extendedSprayerEffects"
ExtendedSprayerEffects.EFFECT_DIRECTION_OFF = { 0, 0 }
ExtendedSprayerEffects.EFFECT_DIRECTION_START = { 1, 1 }
ExtendedSprayerEffects.EFFECT_DIRECTION_STOP = { 1, -1 }

function ExtendedSprayerEffects.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(Sprayer, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(ExtendedSprayer, specializations)
	end
	return v2_
end
function ExtendedSprayerEffects.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("ExtendedSprayerEffects")
	v3_:register(XMLValueType.INT, "vehicle.sprayer.nozzles(?)#foldingConfigurationIndex", "Folding configuration index to use these nozzles", 1)
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.sprayer.nozzles(?).nozzle(?)#node", "Nozzle Node")
	v3_:register(XMLValueType.VECTOR_TRANS, "vehicle.sprayer.nozzles(?).nozzle(?)#translation", "Translation offset from the defined node")
	v3_:register(XMLValueType.VECTOR_ROT, "vehicle.sprayer.nozzles(?).nozzle(?)#rotation", "Rotation offset from the defined node")
	v3_:setXMLSpecializationType()
end

function ExtendedSprayerEffects.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "addExtendedSprayerNozzleEffects", ExtendedSprayerEffects.addExtendedSprayerNozzleEffects)
	SpecializationUtil.registerFunction(vehicleType, "addExtendedSprayerNozzleEffect", ExtendedSprayerEffects.addExtendedSprayerNozzleEffect)
	SpecializationUtil.registerFunction(vehicleType, "initExtendedSprayerNozzleEffect", ExtendedSprayerEffects.initExtendedSprayerNozzleEffect)
	SpecializationUtil.registerFunction(vehicleType, "updateExtendedSprayerNozzleEffectsState", ExtendedSprayerEffects.updateExtendedSprayerNozzleEffectsState)
	SpecializationUtil.registerFunction(vehicleType, "updateExtendedSprayerNozzleEffectState", ExtendedSprayerEffects.updateExtendedSprayerNozzleEffectState)
	SpecializationUtil.registerFunction(vehicleType, "updateExtendedSprayerNozzleEffects", ExtendedSprayerEffects.updateExtendedSprayerNozzleEffects)
	SpecializationUtil.registerFunction(vehicleType, "getNumExtendedSprayerNozzleEffectsActive", ExtendedSprayerEffects.getNumExtendedSprayerNozzleEffectsActive)
end

function ExtendedSprayerEffects.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreEffectsVisible", ExtendedSprayerEffects.getAreEffectsVisible)
end

function ExtendedSprayerEffects.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ExtendedSprayerEffects)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", ExtendedSprayerEffects)
	SpecializationUtil.registerEventListener(vehicleType, "onPreInitComponentPlacement", ExtendedSprayerEffects)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", ExtendedSprayerEffects)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", ExtendedSprayerEffects)
end

-- Local values: spec, linkData, _, i
function ExtendedSprayerEffects:onLoad(savegame)
	local v_u_8_ = self[ExtendedSprayerEffects.SPEC_TABLE_NAME]
	v_u_8_.pwmEnabled = (self.configurations.pulseWidthModulation or 1) > 1
	local v9_ = v_u_8_.pwmEnabled
	if not v9_ then
		if self.getIsSpotSprayEnabled == nil then
			v9_ = false
		else
			v9_ = self:getIsSpotSprayEnabled()
		end
	end
	v_u_8_.individualNozzleControl = v9_
	v_u_8_.effectFadeTime = 250
	v_u_8_.effectsDirty = false
	v_u_8_.sprayerEffects = {}
	v_u_8_.sprayerEffectsBySection = {}
	v_u_8_.soundSamplesBySection = {}
	if g_precisionFarming ~= nil then
		local v10_, _ = g_precisionFarming:getSprayerNodeData(self.configFileName, self.configurations)
		if v10_ ~= nil then
			self:addExtendedSprayerNozzleEffects(v10_)
		end
	end
	v_u_8_.nozzleNodesToDelete = {}
	self.xmlFile:iterate("vehicle.sprayer.nozzles", function(_, p11_)
		-- upvalues: (copy) self, (copy) v_u_8_
		local v_u_12_ = self.xmlFile:getValue(p11_ .. "#foldingConfigurationIndex", 1)
		self.xmlFile:iterate(p11_ .. ".nozzle", function(_, p13_)
			-- upvalues: (ref) self, (copy) v_u_12_, (ref) v_u_8_
			local v14_ = self.xmlFile:getValue(p13_ .. "#node", nil, self.components, self.i3dMappings)
			if v14_ ~= nil then
				if v_u_12_ == self.configurations.folding or self.configurations.folding == nil and v_u_12_ == 1 then
					local v15_ = g_precisionFarming:getClonedSprayerEffectNode()
					if v15_ ~= nil then
						local v16_ = {}
						if self:addExtendedSprayerNozzleEffect(v16_, v15_, v14_, {
							["translation"] = self.xmlFile:getValue(p13_ .. "#translation", { 0, 0, 0 }, true),
							["rotation"] = self.xmlFile:getValue(p13_ .. "#rotation", { 0, 0, 0 }, true)
						}) then
							local v17_ = v_u_8_.sprayerEffects
							table.insert(v17_, v16_)
							return
						end
					end
				else
					v_u_8_.nozzleNodesToDelete[v14_] = true
				end
			end
		end)
	end)
	for v18_ = 1, #v_u_8_.nozzleNodesToDelete do
		if entityExists(v_u_8_.nozzleNodesToDelete[v18_]) then
			delete(v_u_8_.nozzleNodesToDelete[v18_])
		end
	end
	v_u_8_.nozzleNodesToDelete = {}
end

-- Local values: spec, _, effectData
function ExtendedSprayerEffects:onPostLoad(savegame)
	local v20_ = self[ExtendedSprayerEffects.SPEC_TABLE_NAME]
	for _, v21_ in pairs(v20_.sprayerEffects) do
		self:initExtendedSprayerNozzleEffect(v21_)
		if v20_.sprayerEffectsBySection[v21_.sectionIndex] == nil then
			v20_.sprayerEffectsBySection[v21_.sectionIndex] = {}
		end
		local v22_ = v20_.sprayerEffectsBySection[v21_.sectionIndex]
		table.insert(v22_, v21_)
	end
end

-- Local values: spec, specSprayer, _, sprayType, leftX, leftY, leftZ, numLeft, rightX, rightY, rightZ, numRight, sectionIndex, sprayerEffects, linkNode, wx, wy, wz, isLeft, i, effectData, x, y, z, xOffset, _, _, numEffects, sampleData, sampleLinkNode, sampleLinkNode, _, sampleData
function ExtendedSprayerEffects:onPreInitComponentPlacement(savegame)
	local v24_ = self[ExtendedSprayerEffects.SPEC_TABLE_NAME]
	v24_.numCustomEffects = #v24_.sprayerEffects
	v24_.hasCustomEffects = v24_.numCustomEffects > 0
	if v24_.hasCustomEffects then
		SpecializationUtil.removeEventListener(self, "onDraw", VariableWorkWidth)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", VariableWorkWidth)
		local v25_ = self.spec_sprayer
		if v25_.samples ~= nil then
			g_soundManager:deleteSamples(v25_.samples.spray)
			v25_.samples.spray = {}
		end
		for _, v26_ in pairs(v25_.sprayTypes) do
			if v26_.samples ~= nil then
				g_soundManager:deleteSamples(v26_.samples.spray)
				v26_.samples.spray = {}
			end
		end
		local v27_ = 0
		local v28_ = 0
		local v29_ = 0
		local v30_ = 0
		local v31_ = 0
		local v32_ = 0
		local v33_ = 0
		local v34_ = 0
		for v35_, v36_ in pairs(v24_.sprayerEffectsBySection) do
			local v37_ = createTransformGroup("sectionCenterNode" .. tostring(v35_))
			link(self.rootNode, v37_)
			local v38_ = 0
			local v39_ = 0
			local v40_ = 0
			local v41_ = false
			for _, v42_ in ipairs(v36_) do
				local v43_, v44_, v45_ = getWorldTranslation(v42_.effectNode)
				v38_ = v38_ + v43_
				v39_ = v39_ + v44_
				v40_ = v40_ + v45_
				local v46_, _, _ = localToLocal(v42_.effectNode, self.rootNode, 0, 0, 0)
				if v46_ > 0 then
					v32_ = v32_ + v43_
					v33_ = v33_ + v44_
					v30_ = v30_ + v45_
					v31_ = v31_ + 1
					v41_ = true
				else
					v34_ = v34_ + v43_
					v27_ = v27_ + v44_
					v29_ = v29_ + v45_
					v28_ = v28_ + 1
				end
			end
			local v47_ = #v36_
			local v48_ = v38_ / v47_
			local v49_ = v39_ / v47_
			local v50_ = v40_ / v47_
			setWorldTranslation(v37_, v48_, v49_, v50_)
			v24_.soundSamplesBySection[v35_] = {
				["linkNode"] = v37_,
				["sectionIndex"] = v35_,
				["sprayIsActive"] = false,
				["isLeft"] = v41_
			}
		end
		if v31_ > 0 then
			local v51_ = v32_ / v31_
			local v52_ = v33_ / v31_
			local v53_ = v30_ / v31_
			local v54_ = createTransformGroup("sectionsLeftNode")
			link(self.rootNode, v54_)
			setWorldTranslation(v54_, v51_, v52_, v53_)
			v24_.spraySampleLeft = g_precisionFarming:getSprayerClonedSectionSamples("spray", v54_, self)
		end
		if v28_ > 0 then
			local v55_ = v34_ / v28_
			local v56_ = v27_ / v28_
			local v57_ = v29_ / v28_
			local v58_ = createTransformGroup("sectionsRightNode")
			link(self.rootNode, v58_)
			setWorldTranslation(v58_, v55_, v56_, v57_)
			v24_.spraySampleRight = g_precisionFarming:getSprayerClonedSectionSamples("spray", v58_, self)
		end
		for _, v59_ in pairs(v24_.soundSamplesBySection) do
			if v59_.isLeft then
				v59_.spray = v24_.spraySampleLeft
			else
				v59_.spray = v24_.spraySampleRight
			end
		end
	else
		SpecializationUtil.removeEventListener(self, "onUpdate", ExtendedSprayerEffects)
	end
end

-- Local values: spec, isTurnedOn, lastSpeed, _, sprayerEffects
function ExtendedSprayerEffects:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v62_ = self[ExtendedSprayerEffects.SPEC_TABLE_NAME]
	local v63_ = self:getIsTurnedOn()
	local v64_ = self:getLastSpeed()
	if v62_.individualNozzleControl then
		self:updateExtendedSprayerNozzleEffectsState(v62_.sprayerEffects, false, dt, v63_, v64_)
	else
		for _, v65_ in pairs(v62_.sprayerEffectsBySection) do
			self:updateExtendedSprayerNozzleEffectsState(v65_, true, dt, v63_, v64_)
		end
	end
	if v62_.effectsDirty then
		v62_.effectsDirty = false
		self:updateExtendedSprayerNozzleEffects(dt)
		self:raiseActive()
	end
end

-- Local values: spec
function ExtendedSprayerEffects:onDelete()
	local v67_ = self[ExtendedSprayerEffects.SPEC_TABLE_NAME]
	g_soundManager:deleteSample(v67_.spraySampleLeft)
	g_soundManager:deleteSample(v67_.spraySampleRight)
end

-- Local values: spec, _, effectNodeData, linkNode, effectNode, effectData
function ExtendedSprayerEffects:addExtendedSprayerNozzleEffects(linkData)
	local v70_ = self[ExtendedSprayerEffects.SPEC_TABLE_NAME]
	for _, v71_ in pairs(linkData.effectNodes) do
		local v72_
		if v71_.nodeName == nil or self.i3dMappings[v71_.nodeName] == nil then
			v72_ = nil
		else
			v72_ = self.i3dMappings[v71_.nodeName].nodeId
		end
		if v72_ ~= nil then
			local v73_ = g_precisionFarming:getClonedSprayerEffectNode()
			if v73_ ~= nil then
				local v74_ = {}
				if self:addExtendedSprayerNozzleEffect(v74_, v73_, v72_, v71_) then
					local v75_ = v70_.sprayerEffects
					table.insert(v75_, v74_)
				end
			end
		end
	end
end

-- Local values: spec, _
function ExtendedSprayerEffects:addExtendedSprayerNozzleEffect(effectData, effectNode, linkNode, effectNodeData)
	local v81_ = self[ExtendedSprayerEffects.SPEC_TABLE_NAME]
	effectData.effectNode = effectNode
	effectData.isActive = false
	effectData.amountScale = 1
	effectData.lastWorldTranslation = { 0, 0, 0 }
	effectData.speed = 0
	effectData.fadeCur = { -1, 1 }
	effectData.fadeDir = ExtendedSprayerEffects.EFFECT_DIRECTION_OFF
	effectData.state = ShaderPlaneEffect.STATE_OFF
	setShaderParameter(effectNode, "fadeProgress", effectData.fadeCur[1], effectData.fadeCur[2], 0, 0, false)
	setShaderParameter(effectNode, "offsetUV", math.random(), math.random(), 0, 0, false)
	setShaderParameter(effectNode, "isPulsating", v81_.pwmEnabled and 1 or 0, nil, nil, nil, false)
	setShaderParameter(effectNode, "blinkMulti", 1, 1, 100, math.random() * 100, false)
	link(linkNode, effectNode)
	if effectNodeData ~= nil then
		setTranslation(effectNode, effectNodeData.translation[1], effectNodeData.translation[2], effectNodeData.translation[3])
		setRotation(effectNode, effectNodeData.rotation[1], effectNodeData.rotation[2], effectNodeData.rotation[3])
	end
	local v82_, _, _ = localToLocal(effectNode, self:getParentComponent(linkNode), 0, 0, 0)
	effectData.xOffset = v82_
	return true
end

-- Local values: spec_variableWorkWidth, numSections, minWidth, sectionNode, x, _, section, _, section
function ExtendedSprayerEffects:initExtendedSprayerNozzleEffect(effectData)
	local v85_ = self.spec_variableWorkWidth
	if v85_ ~= nil and #v85_.sections > 0 then
		local v86_
		if #v85_.sectionNodes > 0 then
			local v87_ = v85_.sectionNodes[1]
			local v88_ = v87_.startTransX or v87_.startTrans[1]
			v86_ = math.abs(v88_)
		else
			v86_ = 1
		end
		local v89_ = effectData.xOffset or 0
		if v89_ > 0 then
			effectData.sectionIndex = 0
			for _, v90_ in ipairs(v85_.sectionsLeft) do
				if v86_ < v89_ and v89_ <= v90_.widthAbs then
					effectData.sectionIndex = v90_.index
					return
				end
			end
			return
		end
		effectData.sectionIndex = 0
		for _, v91_ in ipairs(v85_.sectionsRight) do
			if v89_ < -v86_ and v91_.widthAbs <= v89_ then
				effectData.sectionIndex = v91_.index
				return
			end
		end
	end
end

-- Local values: spec, anyEffectActive, _, effectData, isActive, amountScale, _, effectData, _, effectData, sampleData, sprayIsActive, anyOtherEffectActive, sectionIndex, otherSampleData, otherEffects, _, otherEffect
function ExtendedSprayerEffects:updateExtendedSprayerNozzleEffectsState(sprayerEffects, useFullSection, dt, isTurnedOn, lastSpeed)
	local v98_ = self[ExtendedSprayerEffects.SPEC_TABLE_NAME]
	local v99_ = false
	for _, v100_ in pairs(sprayerEffects) do
		local v101_, v102_ = self:updateExtendedSprayerNozzleEffectState(v100_, dt, isTurnedOn, lastSpeed)
		v100_.isDirty = v101_ ~= v100_.isActive
		v100_.isActive = v101_
		if v102_ ~= v100_.amountScale then
			v100_.amountScale = v102_
			v98_.effectsDirty = true
		end
		if useFullSection and v101_ then
			v99_ = true
			break
		end
	end
	if useFullSection and v99_ then
		for _, v103_ in pairs(sprayerEffects) do
			if not v103_.isActive then
				v103_.isActive = true
				v103_.isDirty = true
			end
		end
	end
	for _, v104_ in pairs(sprayerEffects) do
		if v104_.isDirty then
			v104_.isDirty = false
			v98_.effectsDirty = true
			if v104_.isActive then
				if v104_.state ~= ShaderPlaneEffect.STATE_ON and v104_.state ~= ShaderPlaneEffect.STATE_TURNING_ON then
					v104_.state = ShaderPlaneEffect.STATE_TURNING_ON
					v104_.fadeDir = ExtendedSprayerEffects.EFFECT_DIRECTION_START
					v104_.fadeCur[1] = -1
					v104_.fadeCur[2] = 1
				end
			elseif v104_.state ~= ShaderPlaneEffect.STATE_OFF and v104_.state ~= ShaderPlaneEffect.STATE_TURNING_OFF then
				v104_.state = ShaderPlaneEffect.STATE_TURNING_OFF
				v104_.fadeDir = ExtendedSprayerEffects.EFFECT_DIRECTION_STOP
			end
			local v105_ = v98_.soundSamplesBySection[v104_.sectionIndex]
			if v105_ ~= nil then
				local v106_ = g_soundManager:getIsSamplePlaying(v105_.spray)
				if v104_.isActive and not v106_ then
					g_soundManager:playSample(v105_.spray)
				end
				if not v104_.isActive then
					local v107_ = false
					for v108_, v109_ in pairs(v98_.soundSamplesBySection) do
						if v109_ ~= v105_ and v109_.spray == v105_.spray then
							local v110_ = v98_.sprayerEffectsBySection[v108_]
							for _, v111_ in pairs(v110_) do
								if v111_.isActive then
									v107_ = true
									break
								end
							end
						end
					end
					if not v107_ and v106_ then
						g_soundManager:stopSample(v105_.spray)
					end
				end
			end
		end
	end
end

-- Local values: spec, x, y, z, lx, ly, lz, distance
function ExtendedSprayerEffects:updateExtendedSprayerNozzleEffectState(effectData, dt, isTurnedOn, lastSpeed)
	if effectData.sectionIndex ~= 0 and not self.spec_variableWorkWidth.sections[effectData.sectionIndex].isActive then
		return false, 1
	end
	if not self[ExtendedSprayerEffects.SPEC_TABLE_NAME].pwmEnabled then
		if (lastSpeed or 1) < 0.1 then
			isTurnedOn = false
		end
		return isTurnedOn, 1
	end
	local v116_, v117_, v118_ = getWorldTranslation(effectData.effectNode)
	local v119_ = effectData.lastWorldTranslation[1]
	local v120_ = effectData.lastWorldTranslation[2]
	local v121_ = effectData.lastWorldTranslation[3]
	effectData.speed = MathUtil.vector3Length(v116_ - v119_, v117_ - v120_, v118_ - v121_) / (g_physicsDt * 0.001) * 3.6
	local v122_ = effectData.lastWorldTranslation
	local v123_ = effectData.lastWorldTranslation
	local v124_ = effectData.lastWorldTranslation
	v122_[1] = v116_
	v123_[2] = v117_
	v124_[3] = v118_
	local v125_ = effectData.speed / self.speedLimit
	return isTurnedOn, math.min(v125_, 1)
end

-- Local values: spec, _, effectData, fadeSpeedScale, pauseTicks
function ExtendedSprayerEffects:updateExtendedSprayerNozzleEffects(dt)
	local v128_ = self[ExtendedSprayerEffects.SPEC_TABLE_NAME]
	for _, v129_ in pairs(v128_.sprayerEffects) do
		if v129_.state == ShaderPlaneEffect.STATE_TURNING_ON or v129_.state == ShaderPlaneEffect.STATE_TURNING_OFF then
			local v130_ = v129_.fadeCur
			local v131_ = v129_.fadeCur[1] + v129_.fadeDir[1] * (dt / (v128_.effectFadeTime * 1))
			local v132_ = math.min(v131_, 1)
			v130_[1] = math.max(v132_, -1)
			local v133_ = v129_.fadeCur
			local v134_ = v129_.fadeCur[2] + v129_.fadeDir[2] * (dt / (v128_.effectFadeTime * 1))
			local v135_ = math.min(v134_, 1)
			v133_[2] = math.max(v135_, -1)
			setShaderParameter(v129_.effectNode, "fadeProgress", v129_.fadeCur[1], v129_.fadeCur[2], 0, 0, false)
			if v129_.state == ShaderPlaneEffect.STATE_TURNING_OFF then
				if v129_.fadeCur[1] == 1 and v129_.fadeCur[2] == -1 then
					v129_.state = ShaderPlaneEffect.STATE_OFF
				end
			elseif v129_.state == ShaderPlaneEffect.STATE_TURNING_ON and (v129_.fadeCur[1] == 1 and v129_.fadeCur[2] == 1) then
				v129_.state = ShaderPlaneEffect.STATE_ON
			end
			v128_.effectsDirty = true
		end
		if v128_.pwmEnabled then
			local v136_ = (1 - v129_.amountScale) * 5
			local v137_ = math.floor(v136_)
			local v138_ = 1 + math.max(v137_, 0)
			setShaderParameter(v129_.effectNode, "blinkMulti", nil, v138_, nil, nil, false)
		end
	end
end

-- Local values: specEffects, numActiveEffects, _, effectData
function ExtendedSprayerEffects:getNumExtendedSprayerNozzleEffectsActive()
	local v140_ = self[ExtendedSprayerEffects.SPEC_TABLE_NAME]
	if not v140_.hasCustomEffects then
		return 1, 1
	end
	local v141_ = 0
	for _, v142_ in pairs(v140_.sprayerEffects) do
		if v142_.isActive then
			v141_ = v141_ + 1
		end
	end
	return v141_, v141_ / v140_.numCustomEffects
end

function ExtendedSprayerEffects:getAreEffectsVisible(superFunc)
	if self[ExtendedSprayerEffects.SPEC_TABLE_NAME].hasCustomEffects then
		return false
	else
		return superFunc(self)
	end
end
