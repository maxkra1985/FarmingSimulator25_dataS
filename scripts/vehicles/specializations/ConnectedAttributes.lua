-- Local values: LocalOffset, LocalOffset_mt, ShaderParameter, ShaderParameter_mt, ShaderParameterPrev, ShaderParameterPrev_mt, Translation, Translation_mt, Rotation, Rotation_mt, JointLimitRot, JointLimitRot_mt, JointLimitTrans, JointLimitTrans_mt, AnimationTime, AnimationTime_mt
ConnectedAttributes = {}
ConnectedAttributes.COMBINE_OPERATION = {}
ConnectedAttributes.COMBINE_OPERATION.AVERAGE = 0
ConnectedAttributes.COMBINE_OPERATION.SUM = 1
ConnectedAttributes.COMBINE_OPERATION.SUBTRACT = 2
ConnectedAttributes.COMBINE_OPERATION.MULTIPLY = 3
ConnectedAttributes.COMBINE_OPERATION.DIVIDE = 4

function ConnectedAttributes.prerequisitesPresent(vehicleType)
	return true
end
function ConnectedAttributes.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("ConnectedAttributes")
	v1_:register(XMLValueType.BOOL, "vehicle.connectedAttributes.attribute(?)#isActiveDirty", "Attribute is permanently updated", false)
	v1_:register(XMLValueType.FLOAT, "vehicle.connectedAttributes.attribute(?)#maxUpdateDistance", "If the player is within this distance to the vehicle, the attribute is updated", "always")
	v1_:register(XMLValueType.STRING, "vehicle.connectedAttributes.attribute(?).updateByAnimation(?)#name", "Name of animation that triggers a update of the connected value")
	v1_:register(XMLValueType.BOOL, "vehicle.connectedAttributes.attribute(?).updateByAnimation(?)#onStart", "Update is triggered on start of the animation", false)
	v1_:register(XMLValueType.BOOL, "vehicle.connectedAttributes.attribute(?).updateByAnimation(?)#onRun", "Update is triggered while the animation is running", false)
	v1_:register(XMLValueType.BOOL, "vehicle.connectedAttributes.attribute(?).updateByAnimation(?)#onStop", "Update is triggered while the animation is stopped", false)
	v1_:register(XMLValueType.STRING, "vehicle.connectedAttributes.attribute(?).prerequisites.animation(?)#name", "Name of animation that needs to be in the defined target range")
	v1_:register(XMLValueType.FLOAT, "vehicle.connectedAttributes.attribute(?).prerequisites.animation(?)#minTime", "Min. time of animation", 0)
	v1_:register(XMLValueType.FLOAT, "vehicle.connectedAttributes.attribute(?).prerequisites.animation(?)#maxTime", "Max. time of animation", 1)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.connectedAttributes.attribute(?).source(?)#node", "Source reference node")
	v1_:register(XMLValueType.STRING, "vehicle.connectedAttributes.attribute(?).source(?)#type", "Source type (" .. ConnectedAttributes.TYPES_STRING .. ")", nil, nil, table.toList(ConnectedAttributes.TYPES_BY_NAME))
	v1_:register(XMLValueType.STRING, "vehicle.connectedAttributes.attribute(?).source(?)#values", "Value definition from the source")
	for v2_ = 1, #ConnectedAttributes.TYPES do
		ConnectedAttributes.TYPES[v2_].registerSourceXMLPaths(v1_, "vehicle.connectedAttributes.attribute(?).source(?)")
	end
	v1_:register(XMLValueType.STRING, "vehicle.connectedAttributes.attribute(?).combine(?)#value", "New value id of the combined value")
	v1_:register(XMLValueType.STRING, "vehicle.connectedAttributes.attribute(?).combine(?)#operation", "Operation to be executed on the values (AVERAGE, SUM, SUBTRACT, MULTIPLY, DIVIDE)")
	v1_:register(XMLValueType.STRING, "vehicle.connectedAttributes.attribute(?).combine(?)#values", "Values to combine")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.connectedAttributes.attribute(?).target(?)#node", "Target reference node")
	v1_:register(XMLValueType.STRING, "vehicle.connectedAttributes.attribute(?).target(?)#type", "Target type (" .. ConnectedAttributes.TYPES_STRING .. ")", nil, nil, table.toList(ConnectedAttributes.TYPES_BY_NAME))
	v1_:register(XMLValueType.STRING, "vehicle.connectedAttributes.attribute(?).target(?)#values", "Value definition how the source values are applied to the target")
	for v3_ = 1, #ConnectedAttributes.TYPES do
		ConnectedAttributes.TYPES[v3_].registerTargetXMLPaths(v1_, "vehicle.connectedAttributes.attribute(?).target(?)")
	end
	v1_:addDelayedRegistrationFunc("Cylindered:movingTool", function(p4_, p5_)
		p4_:register(XMLValueType.VECTOR_N, p5_ .. "#connectedAttributeIndices", "Connected attributes to update")
	end)
	v1_:addDelayedRegistrationFunc("Cylindered:movingPart", function(p6_, p7_)
		p6_:register(XMLValueType.VECTOR_N, p7_ .. "#connectedAttributeIndices", "Connected attributes to update")
	end)
	v1_:setXMLSpecializationType()
end

function ConnectedAttributes.registerFunctions(vehicleType) end

function ConnectedAttributes.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadExtraDependentParts", ConnectedAttributes.loadExtraDependentParts)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", ConnectedAttributes.updateExtraDependentParts)
end

function ConnectedAttributes.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ConnectedAttributes)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", ConnectedAttributes)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", ConnectedAttributes)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateEnd", ConnectedAttributes)
	SpecializationUtil.registerEventListener(vehicleType, "onPlayAnimation", ConnectedAttributes)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateAnimation", ConnectedAttributes)
	SpecializationUtil.registerEventListener(vehicleType, "onFinishAnimation", ConnectedAttributes)
end

-- Local values: spec, hasOnStart, hasOnRun, hasOnStop
function ConnectedAttributes:onLoad(savegame)
	local v_u_11_ = self.spec_connectedAttributes
	v_u_11_.attributes = {}
	v_u_11_.dirtyAttributes = {}
	local v_u_12_ = false
	local v_u_13_ = false
	local v_u_14_ = false
	self.xmlFile:iterate("vehicle.connectedAttributes.attribute", function(_, p15_)
		-- upvalues: (copy) self, (ref) v_u_12_, (ref) v_u_13_, (ref) v_u_14_, (copy) v_u_11_
		local v_u_16_ = {
			["isActive"] = false,
			["isActiveDirty"] = self.xmlFile:getValue(p15_ .. "#isActiveDirty", false),
			["maxUpdateDistance"] = self.xmlFile:getValue(p15_ .. "#maxUpdateDistance"),
			["values"] = {},
			["updateByAnimations"] = {}
		}
		self.xmlFile:iterate(p15_ .. ".updateByAnimation", function(_, p17_)
			-- upvalues: (ref) self, (copy) v_u_16_, (ref) v_u_12_, (ref) v_u_13_, (ref) v_u_14_
			local v18_ = {
				["animationName"] = self.xmlFile:getValue(p17_ .. "#name")
			}
			if v18_.animationName ~= nil then
				v18_.onStart = self.xmlFile:getValue(p17_ .. "#onStart", false)
				v18_.onRun = self.xmlFile:getValue(p17_ .. "#onRun", false)
				v18_.onStop = self.xmlFile:getValue(p17_ .. "#onStop", false)
				if v18_.onStart or (v18_.onRun or v18_.onStop) then
					local v19_ = v_u_16_.updateByAnimations
					table.insert(v19_, v18_)
					v_u_12_ = v_u_12_ or v18_.onStart
					v_u_13_ = v_u_13_ or v18_.onRun
					v_u_14_ = v_u_14_ or v18_.onStop
				end
			end
		end)
		v_u_16_.prerequisites = {}
		self.xmlFile:iterate(p15_ .. ".prerequisites.animation", function(_, p20_)
			-- upvalues: (ref) self, (copy) v_u_16_
			local v_u_21_ = self.xmlFile:getValue(p20_ .. "#name")
			local v_u_22_ = self.xmlFile:getValue(p20_ .. "#minTime", 0)
			local v_u_23_ = self.xmlFile:getValue(p20_ .. "#maxTime", 1)
			if v_u_21_ ~= nil and (v_u_22_ > 0 or v_u_23_ < 1) then
				local v24_ = v_u_16_.prerequisites
				local function v27_()
					-- upvalues: (ref) self, (copy) v_u_21_, (copy) v_u_22_, (copy) v_u_23_
					local v25_ = self:getAnimationTime(v_u_21_)
					local v26_
					if v_u_22_ <= v25_ then
						v26_ = v25_ <= v_u_23_
					else
						v26_ = false
					end
					return v26_
				end
				table.insert(v24_, v27_)
			end
		end)
		v_u_16_.sources = {}
		self.xmlFile:iterate(p15_ .. ".source", function(_, p28_)
			-- upvalues: (ref) self, (copy) v_u_16_
			local v29_ = {
				["node"] = self.xmlFile:getValue(p28_ .. "#node", nil, self.components, self.i3dMappings)
			}
			if v29_.node == nil then
				Logging.xmlWarning(self.xmlFile, "Missing node in \'%s\'", p28_)
				return
			else
				local v30_ = self.xmlFile:getValue(p28_ .. "#type")
				if v30_ == nil then
					Logging.xmlWarning(self.xmlFile, "Missing type in \'%s\'", p28_)
					return
				else
					v29_.typeClass = ConnectedAttributes.TYPES_BY_NAME[string.upper(v30_)]
					if v29_.typeClass == nil then
						Logging.xmlWarning(self.xmlFile, "Invalid type \'%s\' in \'%s\'", v30_, p28_)
						return
					elseif v29_.typeClass.isAvailable == nil or v29_.typeClass.isAvailable(self) then
						v29_.object = v29_.typeClass.new(self, v29_.node, self.xmlFile, p28_, self.components, self.i3dMappings)
						if v29_.object == nil then
							Logging.xmlWarning(self.xmlFile, "Failed to load source \'%s\'", p28_)
						else
							v29_.values = {}
							local v31_ = self.xmlFile:getValue(p28_ .. "#values")
							if v31_ ~= nil then
								local v32_ = v31_:split(" ")
								local v33_ = #v32_
								local v34_ = v29_.typeClass.NUM_VALUES
								for v35_ = 1, math.min(v33_, v34_) do
									if v32_[v35_] ~= "-" then
										v29_.values[v35_] = v32_[v35_]
										v_u_16_.values[v32_[v35_]] = 0
									end
								end
							end
							local v36_ = v_u_16_.sources
							table.insert(v36_, v29_)
						end
					else
						return
					end
				end
			end
		end)
		v_u_16_.combinations = {}
		self.xmlFile:iterate(p15_ .. ".combine", function(_, p37_)
			-- upvalues: (ref) self, (copy) v_u_16_
			local v38_ = {
				["value"] = self.xmlFile:getValue(p37_ .. "#value")
			}
			if v38_.value == nil then
				Logging.xmlWarning(self.xmlFile, "Missing value for \'%s\'", p37_)
				return
			else
				local v39_ = self.xmlFile:getValue(p37_ .. "#operation")
				if v39_ ~= nil then
					v38_.operation = ConnectedAttributes.COMBINE_OPERATION[string.upper(v39_)]
				end
				if v38_.operation == nil then
					Logging.xmlWarning(self.xmlFile, "Invalid operation for \'%s\'", p37_)
					return
				else
					v38_.values = {}
					local v40_ = self.xmlFile:getValue(p37_ .. "#values")
					if v40_ ~= nil then
						local v41_ = v40_:split(" ")
						for v42_ = 1, #v41_ do
							local v43_ = v41_[v42_]
							if v43_ ~= "" and v_u_16_.values[v43_] ~= nil then
								local v44_ = v38_.values
								table.insert(v44_, v43_)
							end
						end
					end
					v38_.numValues = #v38_.values
					if v38_.numValues == 0 then
						Logging.xmlWarning(self.xmlFile, "Missing values for \'%s\'", p37_)
					else
						v_u_16_.values[v38_.value] = 0
						local v45_ = v_u_16_.combinations
						table.insert(v45_, v38_)
					end
				end
			end
		end)
		v_u_16_.targets = {}
		self.xmlFile:iterate(p15_ .. ".target", function(_, p46_)
			-- upvalues: (ref) self, (copy) v_u_16_
			local v47_ = {
				["node"] = self.xmlFile:getValue(p46_ .. "#node", nil, self.components, self.i3dMappings)
			}
			if v47_.node == nil then
				Logging.xmlWarning(self.xmlFile, "Missing node in \'%s\'", p46_)
				return
			else
				local v48_ = self.xmlFile:getValue(p46_ .. "#type")
				if v48_ == nil then
					Logging.xmlWarning(self.xmlFile, "Missing type in \'%s\'", p46_)
					return
				else
					v47_.typeClass = ConnectedAttributes.TYPES_BY_NAME[string.upper(v48_)]
					if v47_.typeClass == nil then
						Logging.xmlWarning(self.xmlFile, "Invalid type \'%s\' in \'%s\'", v48_, p46_)
						return
					elseif v47_.typeClass.isAvailable == nil or v47_.typeClass.isAvailable(self) then
						v47_.object = v47_.typeClass.new(self, v47_.node, self.xmlFile, p46_, self.components, self.i3dMappings)
						if v47_.object == nil then
							Logging.xmlWarning(self.xmlFile, "Failed to load target \'%s\'", p46_)
						else
							v47_.object:get()
							v47_.values = {}
							v47_.factors = {}
							v47_.additionals = {}
							v47_.toSourceValue = {}
							local v49_ = self.xmlFile:getValue(p46_ .. "#values")
							if v49_ ~= nil then
								local v50_ = v49_:split(" ")
								local v51_ = #v50_
								local v52_ = v47_.typeClass.NUM_VALUES
								for v53_ = 1, math.min(v51_, v52_) do
									if v50_[v53_] ~= "-" then
										if v50_[v53_]:contains("*") then
											local v54_ = v50_[v53_]:split("*")
											v47_.values[v53_] = v54_[1]
											local v55_ = v47_.factors
											local v56_ = v54_[2]
											v55_[v53_] = tonumber(v56_) or 1
											v47_.additionals[v53_] = 0
										elseif v50_[v53_]:contains("/") then
											local v57_ = v50_[v53_]:split("/")
											v47_.values[v53_] = v57_[1]
											local v58_ = v47_.factors
											local v59_ = v57_[2]
											v58_[v53_] = 1 / (tonumber(v59_) or 1)
											v47_.additionals[v53_] = 0
										elseif v50_[v53_]:contains("+") then
											local v60_ = v50_[v53_]:split("+")
											v47_.values[v53_] = v60_[1]
											v47_.factors[v53_] = 1
											local v61_ = v47_.additionals
											local v62_ = v60_[2]
											v61_[v53_] = tonumber(v62_) or 0
										elseif v50_[v53_]:contains("-") then
											local v63_ = v50_[v53_]:split("-")
											if v63_[1] == "" then
												if v_u_16_.values[v63_[2]] == nil then
													v47_.values[v53_] = next(v_u_16_.values)
													v47_.factors[v53_] = 0
													local v64_ = v47_.additionals
													local v65_ = v50_[v53_]
													v64_[v53_] = tonumber(v65_)
												else
													v47_.values[v53_] = v63_[2]
													v47_.factors[v53_] = -1
													v47_.additionals[v53_] = 0
												end
											else
												v47_.values[v53_] = v63_[1]
												v47_.factors[v53_] = 1
												local v66_ = v47_.additionals
												local v67_ = v63_[2]
												v66_[v53_] = -(tonumber(v67_) or 0)
											end
										elseif v_u_16_.values[v50_[v53_]] == nil then
											local v68_ = v50_[v53_]
											if tonumber(v68_) ~= nil then
												v47_.values[v53_] = next(v_u_16_.values)
												v47_.factors[v53_] = 0
												local v69_ = v47_.additionals
												local v70_ = v50_[v53_]
												v69_[v53_] = tonumber(v70_)
											end
										else
											v47_.values[v53_] = v50_[v53_]
											v47_.factors[v53_] = 1
											v47_.additionals[v53_] = 0
										end
										if v47_.values[v53_] == nil or (v47_.values[v53_] == "" or v_u_16_.values[v47_.values[v53_]] == nil) then
											v47_.values[v53_] = nil
											v47_.factors[v53_] = nil
											v47_.additionals[v53_] = nil
											Logging.xmlWarning(self.xmlFile, "Failed to validate target value \'%s\' of \'%s\' in \'%s\'", v50_[v53_], v49_, p46_)
										else
											v47_.toSourceValue[v53_] = v_u_16_.values[v47_.values[v53_]]
										end
									end
								end
							end
							local v71_ = v_u_16_.targets
							table.insert(v71_, v47_)
						end
					else
						return
					end
				end
			end
		end)
		if #v_u_16_.sources >= 1 and #v_u_16_.targets >= 1 then
			local v72_ = v_u_11_.attributes
			table.insert(v72_, v_u_16_)
			if v_u_16_.isActiveDirty then
				local v73_ = v_u_11_.dirtyAttributes
				table.insert(v73_, v_u_16_)
			end
		end
	end)
	if #v_u_11_.attributes == 0 then
		SpecializationUtil.removeEventListener(self, "onLoadFinished", ConnectedAttributes)
		SpecializationUtil.removeEventListener(self, "onUpdate", ConnectedAttributes)
	elseif #v_u_11_.dirtyAttributes == 0 then
		SpecializationUtil.removeEventListener(self, "onUpdate", ConnectedAttributes)
	end
	if not v_u_12_ then
		SpecializationUtil.removeEventListener(self, "onPlayAnimation", ConnectedAttributes)
	end
	if not v_u_13_ then
		SpecializationUtil.removeEventListener(self, "onUpdateAnimation", ConnectedAttributes)
	end
	if not v_u_14_ then
		SpecializationUtil.removeEventListener(self, "onFinishAnimation", ConnectedAttributes)
	end
end

-- Local values: spec, _, attribute
function ConnectedAttributes:onLoadFinished(savegame)
	local v75_ = self.spec_connectedAttributes
	for _, v76_ in ipairs(v75_.attributes) do
		ConnectedAttributes.updateAttribute(v76_, true)
	end
end

-- Local values: spec, i, attribute
function ConnectedAttributes:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v78_ = self.spec_connectedAttributes
	for v79_ = 1, #v78_.dirtyAttributes do
		local v80_ = v78_.dirtyAttributes[v79_]
		if v80_.maxUpdateDistance == nil or self.currentUpdateDistance < v80_.maxUpdateDistance then
			ConnectedAttributes.updateAttribute(v80_)
		end
	end
end

function ConnectedAttributes:onUpdateEnd(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	ConnectedAttributes.onUpdate(self, 99999, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
end

-- Local values: spec, _, attribute, _, updateByAnimationData
function ConnectedAttributes:onPlayAnimation(animationName)
	local v87_ = self.spec_connectedAttributes
	for _, v88_ in ipairs(v87_.attributes) do
		for _, v89_ in ipairs(v88_.updateByAnimations) do
			if v89_.onStart and v89_.animationName == animationName then
				ConnectedAttributes.updateAttribute(v88_, true)
				break
			end
		end
	end
end

-- Local values: spec, _, attribute, _, updateByAnimationData
function ConnectedAttributes:onUpdateAnimation(animationName)
	local v92_ = self.spec_connectedAttributes
	for _, v93_ in ipairs(v92_.attributes) do
		for _, v94_ in ipairs(v93_.updateByAnimations) do
			if v94_.onRun and v94_.animationName == animationName then
				ConnectedAttributes.updateAttribute(v93_, true)
				break
			end
		end
	end
end

-- Local values: spec, _, attribute, _, updateByAnimationData
function ConnectedAttributes:onFinishAnimation(animationName)
	local v97_ = self.spec_connectedAttributes
	for _, v98_ in ipairs(v97_.attributes) do
		for _, v99_ in ipairs(v98_.updateByAnimations) do
			if v99_.onStop and v99_.animationName == animationName then
				ConnectedAttributes.updateAttribute(v98_, true)
				break
			end
		end
	end
end

-- Local values: isActive, i, values, hasChanged, sourceIndex, source, object, index, name, value, i, combination, sum, j, sum, j, value, j, value, j, value, j, targetIndex, target, object, data, factors, additionals, index, name
function ConnectedAttributes.updateAttribute(attribute, forceUpdate)
	local v102_ = true
	for v103_ = 1, #attribute.prerequisites do
		if not attribute.prerequisites[v103_]() then
			v102_ = false
			break
		end
	end
	if v102_ then
		local v104_ = attribute.values
		local v105_ = attribute.isActive ~= v102_ and true or forceUpdate
		for v106_ = 1, #attribute.sources do
			local v107_ = attribute.sources[v106_]
			local v108_ = v107_.object
			v108_:get()
			for v109_, v110_ in pairs(v107_.values) do
				local v111_ = v108_.data[v109_]
				if v111_ ~= v104_[v110_] then
					v104_[v110_] = v111_
					v105_ = true
				end
			end
		end
		for v112_ = 1, #attribute.combinations do
			local v113_ = attribute.combinations[v112_]
			if v113_.operation == ConnectedAttributes.COMBINE_OPERATION.AVERAGE then
				local v114_ = 0
				for v115_ = 1, v113_.numValues do
					v114_ = v114_ + v104_[v113_.values[v115_]]
				end
				v104_[v113_.value] = v114_ / v113_.numValues
			elseif v113_.operation == ConnectedAttributes.COMBINE_OPERATION.SUM then
				local v116_ = 0
				for v117_ = 1, v113_.numValues do
					v116_ = v116_ + v104_[v113_.values[v117_]]
				end
				v104_[v113_.value] = v116_
			elseif v113_.operation == ConnectedAttributes.COMBINE_OPERATION.SUBTRACT then
				local v118_ = v104_[v113_.values[1]]
				for v119_ = 2, v113_.numValues do
					v118_ = v118_ - v104_[v113_.values[v119_]]
				end
				v104_[v113_.value] = v118_
			elseif v113_.operation == ConnectedAttributes.COMBINE_OPERATION.MULTIPLY then
				local v120_ = v104_[v113_.values[1]]
				for v121_ = 2, v113_.numValues do
					v120_ = v120_ * v104_[v113_.values[v121_]]
				end
				v104_[v113_.value] = v120_
			elseif v113_.operation == ConnectedAttributes.COMBINE_OPERATION.DIVIDE then
				local v122_ = v104_[v113_.values[1]]
				for v123_ = 2, v113_.numValues do
					v122_ = v122_ / v104_[v113_.values[v123_]]
				end
				v104_[v113_.value] = v122_
			end
		end
		if v105_ then
			for v124_ = 1, #attribute.targets do
				local v125_ = attribute.targets[v124_]
				local v126_ = v125_.object
				local v127_ = v126_.data
				local v128_ = v125_.factors
				local v129_ = v125_.additionals
				for v130_, v131_ in pairs(v125_.values) do
					v127_[v130_] = v104_[v131_] * v128_[v130_] + v129_[v130_]
				end
				v126_:set()
			end
		end
	end
	attribute.isActive = v102_
end

-- Local values: connectedAttributeIndices
function ConnectedAttributes:loadExtraDependentParts(superFunc, xmlFile, baseName, entry)
	if not superFunc(self, xmlFile, baseName, entry) then
		return false
	end
	local v137_ = xmlFile:getValue(baseName .. "#connectedAttributeIndices", nil, true)
	if v137_ ~= nil and #v137_ > 0 then
		entry.connectedAttributeIndices = v137_
	end
	return true
end

-- Local values: spec, i, index
function ConnectedAttributes:updateExtraDependentParts(superFunc, part, dt)
	superFunc(self, part, dt)
	if part.connectedAttributeIndices ~= nil then
		local v142_ = self.spec_connectedAttributes
		for v143_ = 1, #part.connectedAttributeIndices do
			local v144_ = part.connectedAttributeIndices[v143_]
			if v142_.attributes[v144_] ~= nil then
				ConnectedAttributes.updateAttribute(v142_.attributes[v144_])
			end
		end
	end
end

-- Local values: spec, i, attribute, i, sourceIndex, source, object, valueStr, _, value, valuesStr, name, value, targetIndex, target, object, valueStr, _, value
function ConnectedAttributes:updateDebugValues(values)
	local v147_ = self.spec_connectedAttributes
	for v148_ = 1, #v147_.attributes do
		local v149_ = v147_.attributes[v148_]
		if v148_ > 1 then
			table.insert(values, {
				["name"] = "-",
				["value"] = "-"
			})
		end
		for v150_ = 1, #v149_.prerequisites do
			local v151_ = {
				["name"] = string.format("prerequisite %d", v150_),
				["value"] = string.format("%s", v149_.prerequisites[v150_]())
			}
			table.insert(values, v151_)
		end
		for v152_ = 1, #v149_.sources do
			local v153_ = v149_.sources[v152_].object
			local v154_ = ""
			for _, v155_ in pairs(v153_.data) do
				v154_ = string.format("%s %.2f", v154_, MathUtil.round(v155_, 2))
			end
			local v156_ = {
				["name"] = string.format("source %d (%s)", v152_, v153_.NAME),
				["value"] = v154_
			}
			table.insert(values, v156_)
		end
		local v157_ = ""
		for v158_, v159_ in pairs(v149_.values) do
			v157_ = string.format("%s (%s: %.2f)", v157_, v158_, MathUtil.round(v159_, 2))
		end
		table.insert(values, {
			["name"] = "current values",
			["value"] = v157_
		})
		for v160_ = 1, #v149_.targets do
			local v161_ = v149_.targets[v160_].object
			local v162_ = ""
			for _, v163_ in pairs(v161_.data) do
				v162_ = string.format("%s %.2f", v162_, MathUtil.round(v163_, 2))
			end
			local v164_ = {
				["name"] = string.format("target %d (%s)", v160_, v161_.NAME),
				["value"] = v162_
			}
			table.insert(values, v164_)
		end
	end
end
ConnectedAttributes.TYPES = {}
ConnectedAttributes.TYPES_BY_NAME = {}
ConnectedAttributes.TYPES_STRING = ""
function ConnectedAttributes.addType(p165_)
	ConnectedAttributes.TYPES_BY_NAME[p165_.NAME] = p165_
	if ConnectedAttributes.TYPES_STRING ~= "" then
		ConnectedAttributes.TYPES_STRING = ConnectedAttributes.TYPES_STRING .. ", "
	end
	ConnectedAttributes.TYPES_STRING = ConnectedAttributes.TYPES_STRING .. p165_.NAME
	local v166_ = ConnectedAttributes.TYPES
	table.insert(v166_, p165_)
end
local v167_ = {}
local v_u_168_ = Class(v167_)
v167_.NAME = "LOCAL_OFFSET"
v167_.NUM_VALUES = 3








function v167_.registerSourceXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".localOffset#node", "Reference node to measure the offset to the defined source node")
end








function v167_.registerTargetXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".localOffset#node", "Node to set to the offset position that is calculated from the defined target node")
end

-- Upvalues: LocalOffset_mt
-- Local values: self

-- Upvalues: ShaderParameter_mt, ShaderParameter
-- Local values: self, prevName

-- Upvalues: ShaderParameterPrev_mt
-- Local values: self, prevName

-- Upvalues: Translation_mt, Translation
-- Local values: self

-- Upvalues: Rotation_mt, Rotation
-- Local values: self

-- Upvalues: JointLimitRot_mt
-- Local values: self, i, componentJoint

-- Upvalues: JointLimitTrans_mt
-- Local values: self, i, componentJoint

-- Upvalues: AnimationTime_mt, AnimationTime
-- Local values: self
function v167_.new(vehicle, node, xmlFile, key, components, i3dMappings)
	-- upvalues: (copy) v_u_168_
	local v178_ = {}
	local v179_ = v_u_168_
	setmetatable(v178_, v179_)
	v178_.parentNode = node
	v178_.node = xmlFile:getValue(key .. ".localOffset#node", nil, components, i3dMappings)
	if v178_.node == nil then
		Logging.xmlWarning(xmlFile, "Invalid shaderParameter \'%s\' for node \'%s\'", v178_.name, getName(node))
		return nil
	else
		v178_.data = { 0, 0, 0 }
		return v178_
	end
end

function v167_:get()
	local v181_ = self.data
	local v182_ = self.data
	local v183_ = self.data
	local v184_, v185_, v186_ = localToLocal(self.node, self.parentNode, 0, 0, 0)
	v181_[1] = v184_
	v182_[2] = v185_
	v183_[3] = v186_
end

-- Local values: x, y, z
function v167_:set()
	local v188_, v189_, v190_ = localToLocal(self.parentNode, getParent(self.node), self.data[1], self.data[2], self.data[3])
	setTranslation(self.node, v188_, v189_, v190_)
end
ConnectedAttributes.addType(v167_)
local v_u_191_ = {}
local v_u_192_ = Class(v_u_191_)
v_u_191_.NAME = "SHADER_PARAMETER"
v_u_191_.NUM_VALUES = 4
function v_u_191_.registerSourceXMLPaths(p193_, p194_)
	p193_:register(XMLValueType.STRING, p194_ .. ".shaderParameter#name", "Name of shader parameter of the source node that is used")
	p193_:register(XMLValueType.STRING, p194_ .. "#shaderParameterName", "Name of shader parameter of the source node that is used")
end
function v_u_191_.registerTargetXMLPaths(p195_, p196_)
	p195_:register(XMLValueType.STRING, p196_ .. ".shaderParameter#name", "Name of shader parameter of the target node that is used")
	p195_:register(XMLValueType.STRING, p196_ .. "#shaderParameterName", "Name of shader parameter of the target node that is used")
end
function v_u_191_.new(_, p197_, p198_, p199_, _, _)
	-- upvalues: (copy) v_u_192_, (copy) v_u_191_
	local v200_ = {}
	local v201_ = v_u_192_
	setmetatable(v200_, v201_)
	v200_.parentNode = p197_
	v200_.name = p198_:getValue(p199_ .. ".shaderParameter#name") or p198_:getValue(p199_ .. "#shaderParameterName")
	if v200_.name == nil or not getHasShaderParameter(p197_, v200_.name) then
		Logging.xmlWarning(p198_, "Invalid shaderParameter \'%s\' for node \'%s\'", v200_.name, getName(p197_))
		return nil
	end
	v200_.data = {
		0,
		0,
		0,
		0
	}
	local v202_ = string.upper
	local v203_ = v200_.name
	local v204_ = v202_((string.sub(v203_, 1, 1)))
	local v205_ = v200_.name
	local v206_ = "prev" .. v204_ .. string.sub(v205_, 2)
	if getHasShaderParameter(p197_, v206_) then
		v200_.prevName = v206_
		v200_.set = v_u_191_.prev_set
	end
	v200_.numMaterials = getNumOfMaterials(v200_.parentNode)
	return v200_
end

function v_u_191_:get()
	local v208_ = self.data
	local v209_ = self.data
	local v210_ = self.data
	local v211_ = self.data
	local v212_, v213_, v214_, v215_ = getShaderParameter(self.parentNode, self.name)
	v208_[1] = v212_
	v209_[2] = v213_
	v210_[3] = v214_
	v211_[4] = v215_
end

function v_u_191_:set()
	setShaderParameter(self.parentNode, self.name, self.data[1], self.data[2], self.data[3], self.data[4], false)
end

function v_u_191_:prev_set()
	g_animationManager:setPrevShaderParameter(self.parentNode, self.name, self.data[1], self.data[2], self.data[3], self.data[4], false, self.prevName)
end
ConnectedAttributes.addType(v_u_191_)
local v218_ = {}
local v_u_219_ = Class(v218_)
v218_.NAME = "SHADER_PARAMETER_PREV"
v218_.NUM_VALUES = 8
function v218_.registerSourceXMLPaths(p220_, p221_)
	p220_:register(XMLValueType.STRING, p221_ .. ".shaderParameter#name", "Name of shader parameter of the source node that is used")
	p220_:register(XMLValueType.STRING, p221_ .. "#shaderParameterName", "Name of shader parameter of the source node that is used")
end
function v218_.registerTargetXMLPaths(p222_, p223_)
	p222_:register(XMLValueType.STRING, p223_ .. ".shaderParameter#name", "Name of shader parameter of the target node that is used")
	p222_:register(XMLValueType.STRING, p223_ .. "#shaderParameterName", "Name of shader parameter of the target node that is used")
end
function v218_.new(_, p224_, p225_, p226_, _, _)
	-- upvalues: (copy) v_u_219_
	local v227_ = {}
	local v228_ = v_u_219_
	setmetatable(v227_, v228_)
	v227_.parentNode = p224_
	v227_.name = p225_:getValue(p226_ .. ".shaderParameter#name") or p225_:getValue(p226_ .. "#shaderParameterName")
	if v227_.name == nil or not getHasShaderParameter(p224_, v227_.name) then
		Logging.xmlWarning(p225_, "Invalid shaderParameter \'%s\' for node \'%s\'", v227_.name, getName(p224_))
		return nil
	end
	v227_.data = {
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0
	}
	local v229_ = string.upper
	local v230_ = v227_.name
	local v231_ = v229_((string.sub(v230_, 1, 1)))
	local v232_ = v227_.name
	local v233_ = "prev" .. v231_ .. string.sub(v232_, 2)
	if not getHasShaderParameter(p224_, v233_) then
		return nil
	end
	v227_.prevName = v233_
	return v227_
end

function v218_:get()
	local v235_ = self.data
	local v236_ = self.data
	local v237_ = self.data
	local v238_ = self.data
	local v239_, v240_, v241_, v242_ = getShaderParameter(self.parentNode, self.name)
	v235_[1] = v239_
	v236_[2] = v240_
	v237_[3] = v241_
	v238_[4] = v242_
	local v243_ = self.data
	local v244_ = self.data
	local v245_ = self.data
	local v246_ = self.data
	local v247_, v248_, v249_, v250_ = getShaderParameter(self.parentNode, self.prevName)
	v243_[5] = v247_
	v244_[6] = v248_
	v245_[7] = v249_
	v246_[8] = v250_
end

function v218_:set()
	setShaderParameter(self.parentNode, self.name, self.data[1], self.data[2], self.data[3], self.data[4], false)
	setShaderParameter(self.parentNode, self.prevName, self.data[5], self.data[6], self.data[7], self.data[8], false)
end
ConnectedAttributes.addType(v218_)
local v_u_252_ = {}
local v_u_253_ = Class(v_u_252_)
v_u_252_.NAME = "TRANSLATION"
v_u_252_.NUM_VALUES = 3
function v_u_252_.registerSourceXMLPaths(_, _) end
function v_u_252_.registerTargetXMLPaths(_, _) end
function v_u_252_.new(p_u_254_, p_u_255_, _, _, _, _)
	-- upvalues: (copy) v_u_253_, (copy) v_u_252_
	local v_u_256_ = {}
	local v257_ = v_u_253_
	setmetatable(v_u_256_, v257_)
	v_u_256_.parentNode = p_u_255_
	v_u_256_.data = { 0, 0, 0 }
	if p_u_254_.setMovingToolDirty ~= nil then
		function v_u_256_.set()
			-- upvalues: (ref) v_u_252_, (copy) v_u_256_, (copy) p_u_254_, (copy) p_u_255_
			v_u_252_.set(v_u_256_)
			p_u_254_:setMovingToolDirty(p_u_255_)
		end
	end
	return v_u_256_
end

function v_u_252_:get()
	local v259_ = self.data
	local v260_ = self.data
	local v261_ = self.data
	local v262_, v263_, v264_ = getTranslation(self.parentNode)
	v259_[1] = v262_
	v260_[2] = v263_
	v261_[3] = v264_
end
function v_u_252_.set(p265_)
	setTranslation(p265_.parentNode, p265_.data[1], p265_.data[2], p265_.data[3])
end
ConnectedAttributes.addType(v_u_252_)
local v_u_266_ = {}
local v_u_267_ = Class(v_u_266_)
v_u_266_.NAME = "ROTATION"
v_u_266_.NUM_VALUES = 3
function v_u_266_.registerSourceXMLPaths(_, _) end
function v_u_266_.registerTargetXMLPaths(_, _) end
function v_u_266_.new(p_u_268_, p_u_269_, _, _, _, _)
	-- upvalues: (copy) v_u_267_, (copy) v_u_266_
	local v_u_270_ = {}
	local v271_ = v_u_267_
	setmetatable(v_u_270_, v271_)
	v_u_270_.parentNode = p_u_269_
	v_u_270_.data = { 0, 0, 0 }
	if p_u_268_.setMovingToolDirty ~= nil then
		function v_u_270_.set()
			-- upvalues: (ref) v_u_266_, (copy) v_u_270_, (copy) p_u_268_, (copy) p_u_269_
			v_u_266_.set(v_u_270_)
			p_u_268_:setMovingToolDirty(p_u_269_)
		end
	end
	return v_u_270_
end

-- Local values: rx, ry, rz
function v_u_266_:get()
	local v273_, v274_, v275_ = getRotation(self.parentNode)
	local v276_ = self.data
	local v277_ = self.data
	local v278_ = self.data
	local v279_ = math.deg(v273_)
	local v280_ = math.deg(v274_)
	local v281_ = math.deg(v275_)
	v276_[1] = v279_
	v277_[2] = v280_
	v278_[3] = v281_
end
function v_u_266_.set(p282_)
	local v283_ = setRotation
	local v284_ = p282_.parentNode
	local v285_ = p282_.data[1]
	local v286_ = math.rad(v285_)
	local v287_ = p282_.data[2]
	local v288_ = math.rad(v287_)
	local v289_ = p282_.data[3]
	v283_(v284_, v286_, v288_, (math.rad(v289_)))
end
ConnectedAttributes.addType(v_u_266_)
local v290_ = {}
local v_u_291_ = Class(v290_)
v290_.NAME = "JOINT_LIMIT_ROT"
v290_.NUM_VALUES = 6
function v290_.registerSourceXMLPaths(_, _) end
function v290_.registerTargetXMLPaths(_, _) end


function v290_.isAvailable(vehicle)
	return vehicle.isServer
end
function v290_.new(p293_, p294_, p295_, p296_, _, _)
	-- upvalues: (copy) v_u_291_
	local v297_ = {}
	local v298_ = v_u_291_
	setmetatable(v297_, v298_)
	v297_.parentNode = p294_
	for v299_ = 1, #p293_.componentJoints do
		local v300_ = p293_.componentJoints[v299_]
		if v300_.jointNode == p294_ then
			v297_.componentJoint = v300_
			if v297_.componentJoint ~= nil then
				v297_.data = {
					0,
					0,
					0,
					0,
					0,
					0
				}
				v297_.vehicle = p293_
				return v297_
			end
		end
	end
	Logging.xmlWarning(p295_, "Unable to find component joint in \'%s\' for node \'%s\'", p296_, getName(p294_))
	return nil
end

-- Local values: componentJoint
function v290_:get()
	local v302_ = self.componentJoint
	local v303_ = self.data
	local v304_ = self.data
	local v305_ = self.data
	local v306_ = v302_.rotMinLimit[1]
	local v307_ = math.deg(v306_)
	local v308_ = v302_.rotMinLimit[2]
	local v309_ = math.deg(v308_)
	local v310_ = v302_.rotMinLimit[3]
	local v311_ = math.deg(v310_)
	v303_[1] = v307_
	v304_[2] = v309_
	v305_[3] = v311_
	local v312_ = self.data
	local v313_ = self.data
	local v314_ = self.data
	local v315_ = v302_.rotLimit[1]
	local v316_ = math.deg(v315_)
	local v317_ = v302_.rotLimit[2]
	local v318_ = math.deg(v317_)
	local v319_ = v302_.rotLimit[3]
	local v320_ = math.deg(v319_)
	v312_[4] = v316_
	v313_[5] = v318_
	v314_[6] = v320_
end
function v290_.set(p321_)
	local v322_ = p321_.vehicle
	local v323_ = p321_.componentJoint
	local v324_ = p321_.data[1]
	local v325_ = math.rad(v324_)
	local v326_ = p321_.data[4]
	v322_:setComponentJointRotLimit(v323_, 1, v325_, (math.rad(v326_)))
	local v327_ = p321_.vehicle
	local v328_ = p321_.componentJoint
	local v329_ = p321_.data[2]
	local v330_ = math.rad(v329_)
	local v331_ = p321_.data[5]
	v327_:setComponentJointRotLimit(v328_, 2, v330_, (math.rad(v331_)))
	local v332_ = p321_.vehicle
	local v333_ = p321_.componentJoint
	local v334_ = p321_.data[3]
	local v335_ = math.rad(v334_)
	local v336_ = p321_.data[6]
	v332_:setComponentJointRotLimit(v333_, 3, v335_, (math.rad(v336_)))
end
ConnectedAttributes.addType(v290_)
local v337_ = {}
local v_u_338_ = Class(v337_)
v337_.NAME = "JOINT_LIMIT_TRANS"
v337_.NUM_VALUES = 6
function v337_.registerSourceXMLPaths(_, _) end
function v337_.registerTargetXMLPaths(_, _) end
function v337_.isAvailable(p339_)
	return p339_.isServer
end
function v337_.new(p340_, p341_, p342_, p343_, _, _)
	-- upvalues: (copy) v_u_338_
	local v344_ = {}
	local v345_ = v_u_338_
	setmetatable(v344_, v345_)
	v344_.parentNode = p341_
	for v346_ = 1, #p340_.componentJoints do
		local v347_ = p340_.componentJoints[v346_]
		if v347_.jointNode == p341_ then
			v344_.componentJoint = v347_
			if v344_.componentJoint ~= nil then
				v344_.data = {
					0,
					0,
					0,
					0,
					0,
					0
				}
				v344_.vehicle = p340_
				return v344_
			end
		end
	end
	Logging.xmlWarning(p342_, "Unable to find component joint in \'%s\' for node \'%s\'", p343_, getName(p341_))
	return nil
end

-- Local values: componentJoint
function v337_:get()
	local v349_ = self.componentJoint
	local v350_ = self.data
	local v351_ = self.data
	local v352_ = self.data
	local v353_ = v349_.transMinLimit[1]
	local v354_ = v349_.transMinLimit[2]
	local v355_ = v349_.transMinLimit[3]
	v350_[1] = v353_
	v351_[2] = v354_
	v352_[3] = v355_
	local v356_ = self.data
	local v357_ = self.data
	local v358_ = self.data
	local v359_ = v349_.transLimit[1]
	local v360_ = v349_.transLimit[2]
	local v361_ = v349_.transLimit[3]
	v356_[4] = v359_
	v357_[5] = v360_
	v358_[6] = v361_
end
function v337_.set(p362_)
	p362_.vehicle:setComponentJointTransLimit(p362_.componentJoint, 1, p362_.data[1], p362_.data[4])
	p362_.vehicle:setComponentJointTransLimit(p362_.componentJoint, 2, p362_.data[2], p362_.data[5])
	p362_.vehicle:setComponentJointTransLimit(p362_.componentJoint, 3, p362_.data[3], p362_.data[6])
end
ConnectedAttributes.addType(v337_)
local v_u_363_ = {}
local v_u_364_ = Class(v_u_363_)
v_u_363_.NAME = "ANIMATION_TIME"
v_u_363_.NUM_VALUES = 1
function v_u_363_.registerSourceXMLPaths(p365_, p366_)
	p365_:register(XMLValueType.STRING, p366_ .. ".animation#name", "Name of animation from which the time is used")
end
function v_u_363_.registerTargetXMLPaths(p367_, p368_)
	p367_:register(XMLValueType.STRING, p368_ .. ".animation#name", "Name of animation onto which the value is applied as time")
	p367_:register(XMLValueType.STRING, p368_ .. ".animation#minValue", "Min. reference value (when input value is at this point, animation time \'0\' is used)")
	p367_:register(XMLValueType.STRING, p368_ .. ".animation#maxValue", "Max. reference value (when input value is at this point, animation time \'1\' is used)")
end
function v_u_363_.new(p369_, p370_, p371_, p372_, _, _)
	-- upvalues: (copy) v_u_364_, (copy) v_u_363_
	local v373_ = {}
	local v374_ = v_u_364_
	setmetatable(v373_, v374_)
	v373_.parentNode = p370_
	if p369_.getAnimationExists == nil then
		Logging.xmlWarning(p371_, "Vehicle does not have animations for \'%s\'", p372_)
		return nil
	end
	v373_.name = p371_:getValue(p372_ .. ".animation#name")
	if v373_.name == nil or not p369_:getAnimationExists(v373_.name) then
		Logging.xmlWarning(p371_, "Invalid animation \'%s\' in \'%s\'", v373_.name, p372_)
		return nil
	end
	v373_.minValue = p371_:getValue(p372_ .. ".animation#minValue")
	v373_.maxValue = p371_:getValue(p372_ .. ".animation#maxValue")
	if v373_.minValue ~= nil ~= (v373_.maxValue ~= nil) then
		Logging.xmlWarning(p371_, "Invalid animation values for \'%s\' in \'%s\' (minValue and maxValue need to be defined, or non of them)", v373_.name, p372_)
		return nil
	end
	if v373_.minValue ~= nil and v373_.maxValue ~= nil then
		v373_.set = v_u_363_.range_set
	end
	v373_.data = { 0 }
	v373_.vehicle = p369_
	return v373_
end

function v_u_363_:get()
	self.data[1] = self.vehicle:getAnimationTime(self.name)
end
function v_u_363_.set(p376_)
	p376_.vehicle:setAnimationTime(p376_.name, p376_.data[1], true)
end

-- Local values: t
function v_u_363_:range_set()
	local v378_ = (self.data[1] - self.minValue) / (self.maxValue - self.minValue)
	self.vehicle:setAnimationTime(self.name, v378_, true)
end
ConnectedAttributes.addType(v_u_363_)
