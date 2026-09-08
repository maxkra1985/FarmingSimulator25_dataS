-- Local values: EffectManager_mt
EffectManager = {}
local EffectManager_mt = Class(EffectManager, AbstractManager)

-- Upvalues: EffectManager_mt
-- Local values: self
function EffectManager.new(customMt)
	-- upvalues: (copy) EffectManager_mt
	return AbstractManager.new(customMt or EffectManager_mt)
end

function EffectManager:initDataStructures()
	self.runningEffects = {}
	self.registeredEffectClasses = {}
	self.delayedCommands = {}
	self.validCommands = 0
end

-- Local values: effects, i, key, effectClassName, effectClass, effect
function EffectManager:loadEffect(xmlFile, baseName, rootNode, parent, i3dMapping, maxUpdateDistance)
	local v11_ = {}
	for _, v12_ in xmlFile:iterator(baseName .. ".effectNode") do
		local v13_ = xmlFile:getValue(v12_ .. "#effectClass", "ShaderPlaneEffect")
		local v14_ = self:getEffectClass(v13_)
		if v14_ == nil then
			if parent.customEnvironment ~= nil and parent.customEnvironment ~= "" then
				v14_ = self:getEffectClass(parent.customEnvironment .. "." .. v13_)
			end
			if v14_ == nil then
				v14_ = ClassUtil.getClassObject(v13_)
			end
		end
		if v14_ == nil then
			Logging.xmlWarning(xmlFile, "Unknown effect class \'%s\'", v13_)
		else
			local v15_ = v14_.new()
			if v15_ ~= nil then
				table.insert(v11_, v15_:load(xmlFile, v12_, rootNode, parent, i3dMapping))
			end
		end
	end
	self:setUpdateDistance(v11_, maxUpdateDistance or Effect.DEFAULT_UPDATE_DISTANCE)
	return v11_
end

-- Local values: effects, i, child, effectClassName, effectClass, effect
function EffectManager:loadFromNode(node, parent, maxUpdateDistance)
	local v20_ = {}
	for v21_ = 0, getNumOfChildren(node) - 1 do
		local v22_ = getChildAt(node, v21_)
		local v23_ = Utils.getNoNil(getUserAttribute(v22_, "effectClass"), "ShaderPlaneEffect")
		local v24_ = self:getEffectClass(v23_)
		if v24_ == nil then
			if parent.customEnvironment ~= nil and parent.customEnvironment ~= "" then
				v24_ = self:getEffectClass(parent.customEnvironment .. "." .. v23_)
			end
			if v24_ == nil then
				v24_ = ClassUtil.getClassObject(v23_)
			end
		end
		if v24_ == nil then
			printWarning("Warning: Unknown effect \'" .. v23_ .. "\' in \'" .. getName(node) .. "\'")
		else
			local v25_ = v24_.new()
			if v25_ ~= nil then
				table.insert(v20_, v25_:loadFromNode(v22_, parent))
			end
		end
	end
	self:setUpdateDistance(v20_, maxUpdateDistance or Effect.DEFAULT_UPDATE_DISTANCE)
	return v20_
end

function EffectManager:registerEffectClass(className, effectClass)
	if ClassUtil.getIsValidClassName(className) then
		self.registeredEffectClasses[className] = effectClass
	else
		printError("Error: Invalid effect class name: " .. className)
	end
end

function EffectManager:getEffectClass(className)
	return self.registeredEffectClasses[className]
end

-- Local values: _, effect, i, commandSlot
function EffectManager:deleteEffects(effects)
	if effects ~= nil then
		for _, v33_ in pairs(effects) do
			self.runningEffects[v33_] = nil
			v33_:delete()
			for v34_ = 1, #self.delayedCommands do
				local v35_ = self.delayedCommands[v34_]
				if v35_.isValid and v35_.arg1 == v33_ then
					v35_.isValid = false
				end
			end
		end
	end
end

-- Local values: index, effect, allowUpdate, effectDt, i, commandSlot
function EffectManager:update(dt)
	for v38_, v39_ in pairs(self.runningEffects) do
		if v39_.maxUpdateDistance == nil then
			v39_:update(dt)
		else
			local v40_ = v39_:getAllowUpdate()
			if v40_ then
				local v41_
				if v39_.allowUpdate then
					v41_ = dt
				else
					v41_ = g_currentMission.time - v39_.lastUpdateTime
				end
				v39_:update(v41_)
				v39_.lastUpdateTime = g_currentMission.time
			end
			v39_.allowUpdate = v40_
		end
		if not v39_:isRunning() then
			self.runningEffects[v38_] = nil
		end
	end
	if self.validCommands > 0 then
		for v42_ = 1, #self.delayedCommands do
			local v43_ = self.delayedCommands[v42_]
			if v43_.isValid then
				v43_.delay = v43_.delay - dt
				if v43_.delay <= 0 then
					v43_.func(self, v43_.arg1, v43_.arg2)
					v43_.isValid = false
					self.validCommands = self.validCommands - 1
				end
			end
		end
	end
end

-- Local values: slotToUse, i, commandSlot
function EffectManager:addDelayedCommand(func, arg1, arg2, delay)
	local v49_ = nil
	for v50_ = 1, #self.delayedCommands do
		local v51_ = self.delayedCommands[v50_]
		if not v51_.isValid then
			v49_ = v51_
		end
	end
	if v49_ == nil then
		local v52_ = self.delayedCommands
		table.insert(v52_, {
			["func"] = func,
			["arg1"] = arg1,
			["arg2"] = arg2,
			["delay"] = delay,
			["isValid"] = true
		})
	else
		v49_.func = func
		v49_.arg1 = arg1
		v49_.arg2 = arg2
		v49_.delay = delay
		v49_.isValid = true
	end
	self.validCommands = self.validCommands + 1
end

-- Local values: _, effect
function EffectManager:startEffects(effects)
	if effects == nil then
		Logging.warning("Given effects were nil!")
		printCallstack()
	else
		for _, v55_ in pairs(effects) do
			self:startEffect(v55_)
		end
	end
end

-- Local values: success, delay
function EffectManager:startEffect(effect, skipDelay)
	if effect == nil then
		Logging.warning("Given effect was nil!")
		printCallstack()
		return
	else
		local v59_, v60_ = effect:start(skipDelay)
		if v59_ then
			self.runningEffects[effect] = effect
		elseif v60_ ~= nil then
			self:addDelayedCommand(self.startEffect, effect, true, v60_)
		end
	end
end

-- Local values: _, effect
function EffectManager:stopEffects(effects)
	if effects == nil then
		Logging.warning("Given effects were nil!")
		printCallstack()
	else
		for _, v63_ in pairs(effects) do
			self:stopEffect(v63_)
		end
	end
end

-- Local values: success, delay
function EffectManager:stopEffect(effect, skipDelay)
	if effect == nil then
		Logging.warning("Given effect was nil!")
		printCallstack()
		return
	else
		local v67_, v68_ = effect:stop(skipDelay)
		if v67_ then
			self.runningEffects[effect] = effect
		elseif v68_ ~= nil then
			self:addDelayedCommand(self.stopEffect, effect, true, v68_)
		end
	end
end

-- Local values: _, effect
function EffectManager:resetEffects(effects)
	if effects == nil then
		Logging.warning("Given effects were nil!")
		printCallstack()
	else
		for _, v71_ in pairs(effects) do
			self:resetEffect(v71_)
		end
	end
end

function EffectManager:resetEffect(effect)
	if effect == nil then
		Logging.warning("Given effect was nil!")
		printCallstack()
	else
		self.runningEffects[effect] = nil
		effect:reset()
	end
end

-- Local values: _, effect
function EffectManager:setEffectTypeInfo(effects, fillTypeIndex, fruitTypeIndex, growthState)
	if effects == nil then
		Logging.warning("Given effects were nil!")
		printCallstack()
	else
		for _, v78_ in pairs(effects) do
			if v78_.setEffectTypeInfo ~= nil then
				v78_:setEffectTypeInfo(fillTypeIndex, fruitTypeIndex, growthState)
			end
		end
	end
end

function EffectManager:setFillType(effects, fillType, growthState)
	Logging.error("EffectManager:setFillType is deprecated, use setEffectTypeInfo instead")
	printCallstack()
end

function EffectManager:setFruitType(effects, fruitType, growthState)
	Logging.error("EffectManager:setFruitType is deprecated, use setEffectTypeInfo instead")
	printCallstack()
end

-- Local values: _, effect
function EffectManager:setMinMaxWidth(effects, minWidth, maxWidth, minWidthNorm, maxWidthNorm, reset)
	if effects == nil then
		Logging.warning("Given effects were nil!")
		printCallstack()
	else
		for _, v85_ in pairs(effects) do
			if v85_.setMinMaxWidth ~= nil then
				v85_:setMinMaxWidth(minWidth, maxWidth, minWidthNorm, maxWidthNorm, reset)
			end
		end
	end
end

-- Local values: _, effect
function EffectManager:setDensity(effects, density)
	if effects == nil then
		Logging.warning("Given effects were nil!")
		printCallstack()
	else
		for _, v88_ in pairs(effects) do
			if v88_.setDensity ~= nil then
				v88_:setDensity(density)
			end
		end
	end
end

-- Local values: _, effect
function EffectManager:setUpdateDistance(effects, maxUpdateDistance)
	if effects == nil then
		Logging.warning("Given effects were nil!")
		printCallstack()
	else
		for _, v91_ in pairs(effects) do
			v91_:setUpdateDistance(maxUpdateDistance)
		end
	end
end

function EffectManager.registerEffectXMLPaths(schema, basePath)
	schema:setXMLSharedRegistration("EffectNode", basePath)
	schema:register(XMLValueType.STRING, basePath .. ".effectNode(?)#effectClass", "Effect class", "ShaderPlaneEffect")
	Effect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	ExhaustEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	LevelerEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	MorphPositionEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	ParticleEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	PipeEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	ShaderPlaneEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	SlurrySideToSideEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	WindrowerEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	TipEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	GrainTankEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	CutterMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	CultivatorMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	PlowMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	WindrowerMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	FertilizerMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	SnowPlowMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	MotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	VariableMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	CombinedEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	schema:resetXMLSharedRegistration("EffectNode", basePath)
end
g_effectManager = EffectManager.new()
