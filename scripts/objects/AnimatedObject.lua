-- Local values: AnimatedObject_mt, AnimatedObjectBuilder_mt
source("dataS/scripts/objects/AnimatedObjectActivatable.lua")
source("dataS/scripts/objects/AnimatedObjectEvent.lua")
AnimatedObject = {}
local AnimatedObject_mt = Class(AnimatedObject, Object)
InitStaticObjectClass(AnimatedObject, "AnimatedObject")

-- Upvalues: AnimatedObject_mt
-- Local values: self

-- Upvalues: AnimatedObjectBuilder_mt
-- Local values: self, modName, baseDirectory
function AnimatedObject.new(animatedObject, xmlFilename, saveId)
	-- upvalues: (copy) AnimatedObject_mt
	local v5_ = Object.new(animatedObject, xmlFilename, saveId or AnimatedObject_mt)
	v5_.nodeId = 0
	v5_.isMoving = false
	v5_.controls = {}
	v5_.controls.wasPressed = false
	v5_.controls.posAction = nil
	v5_.controls.negAction = nil
	v5_.controls.posText = nil
	v5_.controls.negText = nil
	v5_.controls.posActionEventId = nil
	v5_.controls.negActionEventId = nil
	v5_.networkTimeInterpolator = InterpolationTime.new(1.2)
	v5_.networkAnimTimeInterpolator = InterpolatorValue.new(0)
	v5_.activatable = AnimatedObjectActivatable.new(v5_)
	return v5_
end

-- Local values: modName, baseDirectory, success, animKey, _, partKey, node, checkStaticCol, part, _, frameKey, keyframe, _, shaderKey, node, parameterName, shader, _, frameKey, keyTime, shaderValuesStr, values, keyframe, _, part, _, frame, _, shader, _, frame, clipRootNode, clipName, clipFilename, _, rollingGateAnimationKey, rollingGateAnimation, initialTime, time, startTime, endTime, disableIfClosed, closedText, triggerId, i, posAction, posText, negText, negAction, soundsKey
function AnimatedObject:load(rootNode, xmlFile, key, xmlFilename, i3dMappings)
	self.xmlFilename = xmlFilename
	local v12_, v13_ = Utils.getModNameAndBaseDirectory(xmlFilename)
	self.baseDirectory = v13_
	self.customEnvironment = v12_
	self.nodeId = rootNode
	if type(rootNode) == "table" then
		self.nodeId = rootNode[1].node
	end
	self.saveId = xmlFile:getString(key .. "#saveId") or "AnimatedObject_" .. getName(self.nodeId)
	local v14_ = key .. ".animation"
	self.animation = {}
	self.animation.parts = {}
	self.animation.shaderAnims = nil
	self.animation.clipRootNode = nil
	self.animation.clipName = nil
	self.animation.clipTrack = nil
	self.animation.duration = xmlFile:getFloat(v14_ .. "#duration")
	self.animation.time = 0
	self.animation.direction = 0
	self.animation.maxTime = 0
	local v15_ = true
	for _, v_u_16_ in xmlFile:iterator(v14_ .. ".part") do
		local v17_ = xmlFile:getNode(v_u_16_ .. "#node", nil, rootNode, i3dMappings)
		if v17_ ~= nil and I3DUtil.iterateRecursively(v17_, function(p18_)
			-- upvalues: (copy) xmlFile, (copy) self, (copy) v_u_16_
			if getRigidBodyType(p18_) == RigidBodyType.STATIC and getHasClassId(p18_, ClassIds.SHAPE) then
				Logging.xmlWarning(xmlFile, "Animated node %q at %q is a static rigid body, ignoring", I3DUtil.getNodePath(p18_, self.nodeId), v_u_16_)
				return false
			end
		end, true) ~= false then
			local v19_ = {
				["node"] = v17_,
				["frames"] = {}
			}
			for _, v20_ in xmlFile:iterator(v_u_16_ .. ".keyFrame") do
				local v21_ = {
					self:loadFrameValues(xmlFile, v20_, v17_),
					["time"] = xmlFile:getFloat(v20_ .. "#time")
				}
				local v22_ = self.animation
				local v23_ = v21_.time
				local v24_ = self.animation.maxTime
				v22_.maxTime = math.max(v23_, v24_)
				local v25_ = v19_.frames
				table.insert(v25_, v21_)
			end
			if #v19_.frames > 0 then
				local v26_ = self.animation.parts
				table.insert(v26_, v19_)
			end
		end
	end
	for _, v27_ in xmlFile:iterator(v14_ .. ".shader") do
		local v28_ = xmlFile:getNode(v27_ .. "#node", nil, rootNode, i3dMappings)
		if v28_ ~= nil then
			local v29_ = xmlFile:getString(v27_ .. "#parameterName")
			if v29_ ~= nil and getHasShaderParameter(v28_, v29_) then
				local v30_ = {
					["node"] = v28_,
					["parameterName"] = v29_,
					["frames"] = {}
				}
				for _, v31_ in xmlFile:iterator(v27_ .. ".keyFrame") do
					local v32_ = xmlFile:getFloat(v31_ .. "#time")
					local v33_ = xmlFile:getString(v31_ .. "#values", nil)
					if v33_ ~= nil then
						local v34_ = string.split(v33_, " ")
						if #v34_ > 4 then
							Logging.xmlWarning(xmlFile, "More than 4 values (%q) given for shader parameters at %q", v33_, v31_ .. "#values")
						end
						local v35_ = v34_[1]
						v34_[1] = tonumber(v35_)
						local v36_ = v34_[2]
						v34_[2] = tonumber(v36_)
						local v37_ = v34_[3]
						v34_[3] = tonumber(v37_)
						local v38_ = v34_[4]
						v34_[4] = tonumber(v38_)
						v34_.time = v32_
						local v39_ = v30_.frames
						table.insert(v39_, v34_)
					end
				end
				if #v30_.frames > 0 then
					self.animation.shaderAnims = self.animation.shaderAnims or {}
					local v40_ = self.animation.shaderAnims
					table.insert(v40_, v30_)
				end
			end
		end
	end
	for _, v41_ in ipairs(self.animation.parts) do
		v41_.animCurve = AnimCurve.new(linearInterpolatorN)
		for _, v42_ in ipairs(v41_.frames) do
			v42_.time = v42_.time / self.animation.maxTime
			v41_.animCurve:addKeyframe(v42_)
		end
		v41_.frames = nil
	end
	if self.animation.shaderAnims ~= nil then
		for _, v43_ in ipairs(self.animation.shaderAnims) do
			v43_.animCurve = AnimCurve.new(linearInterpolatorN)
			for _, v44_ in ipairs(v43_.frames) do
				v44_.time = v44_.time / self.animation.maxTime
				v43_.animCurve:addKeyframe(v44_)
			end
			v43_.frames = nil
		end
	end
	local v45_ = xmlFile:getNode(v14_ .. ".clip#rootNode", nil, rootNode, i3dMappings)
	local v46_ = xmlFile:getString(v14_ .. ".clip#name")
	if v45_ ~= nil and v46_ ~= nil then
		local v47_ = xmlFile:getString(v14_ .. ".clip#filename")
		self.animation.clipRootNode = v45_
		self.animation.clipName = v46_
		self.animation.clipTrack = 0
		if v47_ == nil then
			self:applyAnimation()
		else
			local v48_ = Utils.getFilename(v47_, self.baseDirectory)
			self.animation.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v48_, false, false, self.onSharedAnimationFileLoaded, self, nil)
			self.animation.clipFilename = v48_
		end
	end
	self.rollingGateAnimations = {}
	for _, v49_ in xmlFile:iterator(v14_ .. ".rollingGateAnimation") do
		local v50_ = RollingGateAnimation.new()
		if v50_:load(xmlFile, v49_, rootNode, i3dMappings) then
			if self.rollingGateAnimations == nil then
				self.rollingGateAnimations = {}
			end
			local v51_ = self.rollingGateAnimations
			table.insert(v51_, v50_)
		end
	end
	if self.animation.duration == nil then
		self.animation.duration = self.animation.maxTime
	end
	self.animation.duration = self.animation.duration * 1000
	local v52_ = xmlFile:getFloat(v14_ .. "#initialTime", 0) * 1000
	self:setAnimTime(self.animation.duration == 0 and 0 or v52_ / self.animation.duration, true)
	local v53_ = xmlFile:getFloat(key .. ".openingHours#startTime")
	local v54_ = xmlFile:getFloat(key .. ".openingHours#endTime")
	if v53_ ~= nil and v54_ ~= nil then
		self.openingHours = {
			["startTime"] = v53_,
			["endTime"] = v54_,
			["disableIfClosed"] = xmlFile:getBool(key .. ".openingHours#disableIfClosed", false),
			["closedText"] = xmlFile:getI18NValue(key .. ".openingHours#closedText", nil, self.customEnvironment)
		}
		g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self)
	end
	self.isEnabled = true
	local v55_ = xmlFile:getNode(key .. ".controls#triggerNode", nil, rootNode, i3dMappings)
	if v55_ ~= nil then
		self.triggerNode = v55_
		addTrigger(self.triggerNode, "triggerCallback", self)
		for v56_ = 0, getNumOfChildren(self.triggerNode) - 1 do
			addTrigger(getChildAt(self.triggerNode, v56_), "triggerCallback", self)
		end
		if InputAction ~= nil then
			local v57_ = xmlFile:getString(key .. ".controls#posAction")
			if v57_ ~= nil then
				if InputAction[v57_] then
					self.controls.posAction = v57_
					local v58_ = xmlFile:getString(key .. ".controls#posText")
					if v58_ ~= nil then
						if g_i18n:hasText(v58_, self.customEnvironment) then
							v58_ = g_i18n:getText(v58_, self.customEnvironment)
						end
						self.controls.posActionText = v58_
					end
					local v59_ = xmlFile:getString(key .. ".controls#negText")
					if v59_ ~= nil then
						if g_i18n:hasText(v59_, self.customEnvironment) then
							v59_ = g_i18n:getText(v59_, self.customEnvironment)
						end
						self.controls.negActionText = v59_
					end
					local v60_ = xmlFile:getString(key .. ".controls#negAction")
					if v60_ ~= nil then
						if InputAction[v60_] then
							self.controls.negAction = v60_
						else
							printWarning("Warning: Negative direction action \'" .. v60_ .. "\' not defined!")
						end
					end
				else
					printWarning("Warning: Positive direction action \'" .. v57_ .. "\' not defined!")
				end
			end
		end
	end
	if g_client ~= nil then
		local v61_ = key .. ".sounds"
		self.samplesMoving = g_soundManager:loadSamplesFromXML(xmlFile, v61_, "moving", self.baseDirectory, rootNode, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil)
		self.samplePosEnd = g_soundManager:loadSampleFromXML(xmlFile, v61_, "posEnd", self.baseDirectory, rootNode, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil)
		self.sampleNegEnd = g_soundManager:loadSampleFromXML(xmlFile, v61_, "negEnd", self.baseDirectory, rootNode, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil)
	end
	self.animatedObjectDirtyFlag = self:getNextDirtyFlag()
	return v15_
end

function AnimatedObject:builder(xmlFilename, saveId)
	return AnimatedObjectBuilder.new(self, xmlFilename, saveId)
end

-- Local values: rx, ry, rz, x, y, z, sx, sy, sz, isVisible, visibility
function AnimatedObject:loadFrameValues(xmlFile, key, node)
	local v68_, v69_, v70_ = xmlFile:getRotation(key .. "#rotation")
	if v68_ == nil then
		v68_, v69_, v70_ = getRotation(node)
	end
	local v71_, v72_, v73_ = xmlFile:getTranslation(key .. "#translation")
	if v71_ == nil then
		v71_, v72_, v73_ = getTranslation(node)
	end
	local v74_, v75_, v76_ = xmlFile:getScale(key .. "#scale")
	if v74_ == nil then
		v74_, v75_, v76_ = getScale(node)
	end
	return v71_, v72_, v73_, v68_, v69_, v70_, v74_, v75_, v76_, xmlFile:getBool(key .. "#visibility", true) and 1 or 0
end

-- Local values: animNode
function AnimatedObject:onSharedAnimationFileLoaded(node, failedReason, args)
	if node ~= 0 and node ~= nil then
		if not self.isDeleted then
			local v79_ = getChildAt(node, 0)
			cloneAnimCharacterSet(v79_, getParent(self.animation.clipRootNode))
			self:applyAnimation()
		end
		delete(node)
	end
end

-- Local values: characterSet, clipIndex
function AnimatedObject:applyAnimation()
	if self.animation.clipRootNode == nil or self.animation.clipRootNode == 0 then
		Logging.error("Animation clipRootNode not set")
		return
	else
		local v81_ = getAnimCharacterSet(self.animation.clipRootNode)
		if v81_ == 0 then
			Logging.error("Animation character set not found for node \'%s\'", getName(self.animation.clipRootNode))
			return
		else
			local v82_ = getAnimClipIndex(v81_, self.animation.clipName)
			if v82_ == -1 then
				Logging.error("Animation clip with name \'%s\' does not exist in \'%s\'", self.animation.clipName, self.animation.clipFilename or self.xmlFilename)
			else
				assignAnimTrackClip(v81_, self.animation.clipTrack, v82_)
				setAnimTrackLoopState(v81_, self.animation.clipTrack, false)
				self.animation.clipDuration = getAnimClipDuration(v81_, v82_)
				self.animation.clipCharacterSet = v81_
				self:setAnimTime(self.animation.time, false)
			end
		end
	end
end

-- Local values: i
function AnimatedObject:delete()
	if self.triggerNode ~= nil then
		removeTrigger(self.triggerNode)
		for v84_ = 0, getNumOfChildren(self.triggerNode) - 1 do
			removeTrigger(getChildAt(self.triggerNode, v84_))
		end
		self.triggerNode = nil
	end
	if self.samplesMoving ~= nil then
		g_soundManager:deleteSamples(self.samplesMoving)
		self.samplesMoving = nil
	end
	if self.samplePosEnd ~= nil then
		g_soundManager:deleteSample(self.samplePosEnd)
		self.samplePosEnd = nil
	end
	if self.sampleNegEnd ~= nil then
		g_soundManager:deleteSample(self.sampleNegEnd)
		self.sampleNegEnd = nil
	end
	if self.animation ~= nil and self.animation.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.animation.sharedLoadRequestId)
		self.animation.sharedLoadRequestId = nil
	end
	if g_currentMission ~= nil then
		g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
	end
	if g_messageCenter ~= nil then
		g_messageCenter:unsubscribeAll(self)
	end
	self.isDeleted = true
	AnimatedObject:superClass().delete(self)
end

-- Local values: animTime, direction
function AnimatedObject:readStream(streamId, connection)
	AnimatedObject:superClass().readStream(self, streamId, connection)
	if connection:getIsServer() then
		local v88_ = streamReadFloat32(streamId)
		self:setAnimTime(v88_, true)
		local v89_ = streamReadUIntN(streamId, 2) - 1
		self.animation.direction = v89_
		self.networkAnimTimeInterpolator:setValue(v88_)
		self.networkTimeInterpolator:reset()
	end
end

function AnimatedObject:writeStream(streamId, connection)
	AnimatedObject:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() then
		streamWriteFloat32(streamId, self.animation.time)
		streamWriteUIntN(streamId, self.animation.direction + 1, 2)
	end
end

-- Local values: animTime, direction
function AnimatedObject:readUpdateStream(streamId, timestamp, connection)
	AnimatedObject:superClass().readUpdateStream(self, streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		self.networkTimeInterpolator:startNewPhaseNetwork()
		local v97_ = streamReadFloat32(streamId)
		self.networkAnimTimeInterpolator:setTargetValue(v97_)
		local v98_ = streamReadUIntN(streamId, 2) - 1
		self.animation.direction = v98_
	end
end

function AnimatedObject:writeUpdateStream(streamId, connection, dirtyMask)
	AnimatedObject:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v103_ = streamWriteBool
		local v104_ = self.animatedObjectDirtyFlag
		if v103_(streamId, bit32.band(dirtyMask, v104_) ~= 0) then
			streamWriteFloat32(streamId, self.animation.timeSend)
			streamWriteUIntN(streamId, self.animation.direction + 1, 2)
		end
	end
end

-- Local values: animTime
function AnimatedObject:loadFromXMLFile(xmlFile, key)
	local v108_ = xmlFile:getFloat(key .. "#time")
	if v108_ ~= nil then
		self.animation.direction = xmlFile:getInt(key .. "#direction", 0)
		self:setAnimTime(v108_, true)
	end
	AnimatedObject.hourChanged(self)
	return true
end

function AnimatedObject:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setFloat(key .. "#time", self.animation.time)
	xmlFile:setInt(key .. "#direction", self.animation.direction)
end

function AnimatedObject:reset()
	self.animation.time = 0
end

function AnimatedObject:resetTime()
	self.animation.time = 0
	self.networkAnimTimeInterpolator:setValue(0)
	self.networkTimeInterpolator:reset()
end

function AnimatedObject:setDirection(direction)
	self.animation.direction = direction
	if self.animation.direction == 0 then
		if self.animation.time > 0 then
			self.animation.direction = -1
		else
			self.animation.direction = 1
		end
	end
	if g_server == nil then
		g_client:getServerConnection():sendEvent(AnimatedObjectEvent.new(self, self.animation.direction))
	else
		if self.aiBlockingRegion ~= nil and self.animation.time == 1 then
			g_currentMission.aiSystem:setBlockingRegionState(self.aiBlockingRegion.blockingRegionId, true)
		end
		self:raiseActive()
	end
end

-- Local values: finishedAnimation, newAnimTime, interpolationAlpha, animTime, newAnimTime
function AnimatedObject:update(dt)
	AnimatedObject:superClass().update(self, dt)
	local v118_ = false
	if self.animatedObject then
		if self.animation.direction ~= 0 then
			local v119_
			if self.animation.duration == 0 then
				v119_ = 0
			else
				local v120_ = self.animation.time + self.animation.direction * dt / self.animation.duration
				v119_ = math.clamp(v120_, 0, 1)
			end
			self:setAnimTime(v119_)
			if v119_ == 0 or v119_ == 1 then
				self.animation.direction = 0
				v118_ = true
				if self.aiBlockingRegion ~= nil then
					g_currentMission.aiSystem:setBlockingRegionState(self.aiBlockingRegion.blockingRegionId, v119_ == 0)
				end
			end
		end
		if self.animation.time ~= self.animation.timeSend then
			self.animation.timeSend = self.animation.time
			self:raiseDirtyFlags(self.animatedObjectDirtyFlag)
		end
	else
		self.networkTimeInterpolator:update(dt)
		local v121_ = self.networkTimeInterpolator:getAlpha()
		local v122_ = self:setAnimTime((self.networkAnimTimeInterpolator:getInterpolatedValue(v121_)))
		if self.animation.direction ~= 0 then
			if self.animation.direction > 0 then
				if v122_ == 1 then
					self.animation.direction = 0
					v118_ = true
				end
			elseif v122_ == 0 then
				self.animation.direction = 0
				v118_ = true
			end
		end
		if self.networkTimeInterpolator:isInterpolating() then
			self:raiseActive()
		end
	end
	if self.samplesMoving ~= nil then
		if self.isMoving and self.animation.direction ~= 0 then
			if not self.samplesMovingArePlaying then
				g_soundManager:playSamples(self.samplesMoving)
				self.samplesMovingArePlaying = true
			end
		elseif self.samplesMovingArePlaying then
			g_soundManager:stopSamples(self.samplesMoving)
			self.samplesMovingArePlaying = false
		end
	end
	if v118_ and self.animation.direction == 0 then
		if self.samplePosEnd == nil or self.animation.time ~= 1 then
			if self.sampleNegEnd ~= nil and self.animation.time == 0 then
				g_soundManager:playSample(self.sampleNegEnd)
			end
		else
			g_soundManager:playSample(self.samplePosEnd)
		end
	end
	self.isMoving = false
	if self.animation.direction ~= 0 then
		self:raiseActive()
	end
end

function AnimatedObject:getCanBeTriggered()
	return true
end

-- Local values: _, part, x, y, z, rx, ry, rz, sx, sy, sz, vis, _, shader, x, y, z, w, parameterName, characterSet, _, rollingGateAnimation
function AnimatedObject:setAnimTime(t, omitSound)
	local v125_ = math.clamp(t, 0, 1)
	for _, v126_ in pairs(self.animation.parts) do
		local v127_, v128_, v129_, v130_, v131_, v132_, v133_, v134_, v135_, v136_ = v126_.animCurve:get(v125_)
		setTranslation(v126_.node, v127_, v128_, v129_)
		setRotation(v126_.node, v130_, v131_, v132_)
		setScale(v126_.node, v133_, v134_, v135_)
		setVisibility(v126_.node, v136_ == 1)
	end
	if self.animation.shaderAnims ~= nil then
		for _, v137_ in pairs(self.animation.shaderAnims) do
			local v138_, v139_, v140_, v141_ = v137_.animCurve:get(v125_)
			local v142_ = v137_.parameterName
			setShaderParameter(v137_.node, v142_, v138_, v139_, v140_, v141_, false)
		end
	end
	local v143_ = self.animation.clipCharacterSet
	if v143_ ~= nil then
		enableAnimTrack(v143_, self.animation.clipTrack)
		setAnimTrackTime(v143_, self.animation.clipTrack, v125_ * self.animation.clipDuration, true)
		disableAnimTrack(v143_, self.animation.clipTrack)
	end
	if self.rollingGateAnimations ~= nil then
		for _, v144_ in pairs(self.rollingGateAnimations) do
			v144_:setState(v125_)
		end
	end
	self.animation.time = v125_
	self.isMoving = true
	return v125_
end

function AnimatedObject:setFrameValues(node, v)
	setTranslation(node, v[1], v[2], v[3])
	setRotation(node, v[4], v[5], v[6])
	setScale(node, v[7], v[8], v[9])
	setVisibility(node, v[10] == 1)
end

-- Local values: currentHour
function AnimatedObject:hourChanged()
	if self.animatedObject then
		if g_currentMission ~= nil and g_currentMission.environment ~= nil then
			if self.openingHours ~= nil then
				local v148_ = g_currentMission.environment.currentHour
				if self.openingHours.startTime <= v148_ and v148_ < self.openingHours.endTime then
					if not self.openingHours.isOpen then
						if self.animatedObject then
							self.animation.direction = 1
							self:raiseActive()
						end
						self.openingHours.isOpen = true
					end
					if self.openingHours.disableIfClosed then
						self.isEnabled = true
						return
					end
				else
					if self.openingHours.isOpen then
						if self.animatedObject then
							self.animation.direction = -1
							self:raiseActive()
						end
						self.openingHours.isOpen = false
					end
					if self.openingHours.disableIfClosed then
						self.isEnabled = false
					end
				end
			end
		end
	else
		return
	end
end

function AnimatedObject:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if g_currentMission.missionInfo:isa(FSCareerMissionInfo) and (onEnter or onLeave) and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
		if onEnter then
			g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
		else
			g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
		end
		self:raiseActive()
	end
end


function AnimatedObject.registerXMLPaths(schema, basePath)
	schema:setXMLSharedRegistration("AnimatedObject", basePath)
	local v155_ = basePath .. ".animatedObject(?)"
	schema:register(XMLValueType.STRING, v155_ .. "#saveId", "Save identifier", "AnimatedObject_[nodeName]")
	schema:register(XMLValueType.FLOAT, v155_ .. ".animation#duration", "Animation duration (sec.)", 3)
	schema:register(XMLValueType.NODE_INDEX, v155_ .. ".animation.part(?)#node", "Part node")
	schema:register(XMLValueType.FLOAT, v155_ .. ".animation.part(?).keyFrame(?)#time", "Key time")
	schema:register(XMLValueType.VECTOR_ROT, v155_ .. ".animation.part(?).keyFrame(?)#rotation", "Key rotation", "values read from i3d node")
	schema:register(XMLValueType.VECTOR_TRANS, v155_ .. ".animation.part(?).keyFrame(?)#translation", "Key translation", "values read from i3d node")
	schema:register(XMLValueType.VECTOR_SCALE, v155_ .. ".animation.part(?).keyFrame(?)#scale", "Key scale", "values read from i3d node")
	schema:register(XMLValueType.BOOL, v155_ .. ".animation.part(?).keyFrame(?)#visibility", "Key visibility", true)
	schema:register(XMLValueType.NODE_INDEX, v155_ .. ".animation.shader(?)#node", "Shader node")
	schema:register(XMLValueType.STRING, v155_ .. ".animation.shader(?)#parameterName", "Shader parameter name")
	schema:register(XMLValueType.FLOAT, v155_ .. ".animation.shader(?).keyFrame(?)#time", "Key time")
	schema:register(XMLValueType.STRING, v155_ .. ".animation.shader(?).keyFrame(?)#values", "Key shader parameter values. Use \'-\' to force using existing shader parameter value")
	schema:register(XMLValueType.NODE_INDEX, v155_ .. ".animation.clip#rootNode", "I3d animation rootnode")
	schema:register(XMLValueType.STRING, v155_ .. ".animation.clip#name", "I3d animation clipName")
	schema:register(XMLValueType.STRING, v155_ .. ".animation.clip#filename", "I3d animation external animation")
	RollingGateAnimation.registerXMLPaths(schema, v155_ .. ".animation.rollingGateAnimation(?)")
	schema:register(XMLValueType.FLOAT, v155_ .. ".animation#initialTime", "Animation time after loading", 0)
	schema:register(XMLValueType.FLOAT, v155_ .. ".openingHours#startTime", "Start day time")
	schema:register(XMLValueType.FLOAT, v155_ .. ".openingHours#endTime", "End day time")
	schema:register(XMLValueType.BOOL, v155_ .. ".openingHours#disableIfClosed", "Disabled if closed")
	schema:register(XMLValueType.L10N_STRING, v155_ .. ".openingHours#closedText", "Closed text")
	schema:register(XMLValueType.NODE_INDEX, v155_ .. ".controls#triggerNode", "Player trigger node")
	schema:register(XMLValueType.STRING, v155_ .. ".controls#posAction", "Positive direction action event name")
	schema:registerAutoCompletionDataSource(v155_ .. ".controls#posAction", "$dataS/inputActions.xml", "actions.action#name")
	schema:register(XMLValueType.STRING, v155_ .. ".controls#posText", "Positive direction text")
	schema:register(XMLValueType.STRING, v155_ .. ".controls#negText", "Negative direction text")
	schema:register(XMLValueType.STRING, v155_ .. ".controls#negAction", "Negative direction action event name")
	schema:registerAutoCompletionDataSource(v155_ .. ".controls#negAction", "$dataS/inputActions.xml", "actions.action#name")
	if SoundManager ~= nil then
		SoundManager.registerSampleXMLPaths(schema, v155_ .. ".sounds", "moving(?)")
		SoundManager.registerSampleXMLPaths(schema, v155_ .. ".sounds", "posEnd")
		SoundManager.registerSampleXMLPaths(schema, v155_ .. ".sounds", "negEnd")
	end
	schema:resetXMLSharedRegistration("AnimatedObject", v155_)
end

function AnimatedObject.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#time", "Animated object time")
	schema:register(XMLValueType.INT, basePath .. "#direction", "Animated object direction", 0)
end
AnimatedObjectBuilder = {}
local v_u_158_ = Class(AnimatedObjectBuilder)
function AnimatedObjectBuilder.registerXMLPaths(p159_, p160_)
	SoundManager.registerSampleXMLPaths(p159_, p160_ .. ".sounds", "moving(?)")
	SoundManager.registerSampleXMLPaths(p159_, p160_ .. ".sounds", "posEnd")
	SoundManager.registerSampleXMLPaths(p159_, p160_ .. ".sounds", "negEnd")
end
function AnimatedObjectBuilder.new(p161_, p162_, p163_)
	-- upvalues: (copy) v_u_158_
	local v164_ = v_u_158_
	local v165_ = setmetatable({}, v164_)
	v165_.animatedObject = p161_
	local v166_, v167_ = Utils.getModNameAndBaseDirectory(p162_)
	p161_.baseDirectory = v167_
	p161_.customEnvironment = v166_
	p161_.saveId = p163_
	p161_.animation = {}
	p161_.animation.parts = {}
	p161_.animation.time = 0
	p161_.animation.direction = 0
	p161_.animation.duration = 1000
	p161_.animation.shaderAnims = {}
	p161_.isEnabled = true
	return v165_
end

-- Local values: ao, node, i
function AnimatedObjectBuilder:build(rootNodeId)
	local v169_ = self.animatedObject
	v169_:setAnimTime(0, true)
	if v169_.openingHours ~= nil then
		g_messageCenter:subscribe(MessageType.HOUR_CHANGED, v169_.hourChanged, v169_)
	end
	if v169_.triggerNode ~= nil then
		local v170_ = v169_.triggerNode
		addTrigger(v170_, "triggerCallback", v169_)
		for v171_ = 0, getNumOfChildren(v170_) - 1 do
			addTrigger(getChildAt(v170_, v171_), "triggerCallback", v169_)
		end
	end
	v169_.animatedObjectDirtyFlag = v169_:getNextDirtyFlag()
	return true
end

function AnimatedObjectBuilder:setTrigger(node)
	self.animatedObject.triggerNode = node
end

-- Local values: ao
function AnimatedObjectBuilder:setActions(posAction, posText, negAction, negText)
	if posAction ~= nil then
		local v179_ = self.animatedObject
		if InputAction[posAction] then
			v179_.controls.posAction = posAction
			if posText ~= nil then
				if g_i18n:hasText(posText, v179_.customEnvironment) then
					posText = g_i18n:getText(posText, v179_.customEnvironment)
				end
				v179_.controls.posActionText = posText
			end
			if negText ~= nil then
				if g_i18n:hasText(negText, v179_.customEnvironment) then
					negText = g_i18n:getText(negText, v179_.customEnvironment)
				end
				v179_.controls.negActionText = negText
			end
			if negAction ~= nil then
				if InputAction[negAction] then
					v179_.controls.negAction = negAction
				else
					printWarning("Warning: Negative direction action \'" .. negAction .. "\' not defined!")
				end
			end
		else
			printWarning("Warning: Positive direction action \'" .. posAction .. "\' not defined!")
		end
	end
end

-- Local values: part, x, y, z, rx, ry, rz, sx, sy, sz
function AnimatedObjectBuilder:addSimplePart(node, openRotation, openTranslation)
	local v184_ = {
		["node"] = node,
		["animCurve"] = AnimCurve.new(linearInterpolatorN)
	}
	local v185_, v186_, v187_ = getTranslation(node)
	local v188_, v189_, v190_ = getRotation(node)
	local v191_, v192_, v193_ = getScale(node)
	v184_.animCurve:addKeyframe({
		v185_,
		v186_,
		v187_,
		v188_,
		v189_,
		v190_,
		v191_,
		v192_,
		v193_,
		1,
		["time"] = 0
	})
	if openTranslation ~= nil then
		v185_, v186_, v187_ = unpack(openTranslation)
	end
	if openRotation ~= nil then
		v188_, v189_, v190_ = unpack(openRotation)
	end
	v184_.animCurve:addKeyframe({
		v185_,
		v186_,
		v187_,
		v188_,
		v189_,
		v190_,
		v191_,
		v192_,
		v193_,
		1,
		["time"] = 1
	})
	local v194_ = self.animatedObject.animation.parts
	table.insert(v194_, v184_)
end

function AnimatedObjectBuilder:setDuration(duration)
	self.animatedObject.animation.duration = duration
end

-- Local values: i3dMappings
function AnimatedObjectBuilder:setSounds(xmlFile, key, rootNode)
	if g_client ~= nil then
		self.animatedObject.samplesMoving = g_soundManager:loadSamplesFromXML(xmlFile, key, "moving", self.animatedObject.baseDirectory, rootNode, 1, AudioGroup.ENVIRONMENT, nil, nil)
		self.animatedObject.samplePosEnd = g_soundManager:loadSampleFromXML(xmlFile, key, "posEnd", self.animatedObject.baseDirectory, rootNode, 1, AudioGroup.ENVIRONMENT, nil, nil)
		self.animatedObject.sampleNegEnd = g_soundManager:loadSampleFromXML(xmlFile, key, "negEnd", self.animatedObject.baseDirectory, rootNode, 1, AudioGroup.ENVIRONMENT, nil, nil)
	end
end

function AnimatedObjectBuilder:setOpeningTimes(startTime, endTime, disableIfClosed, closedText)
	if startTime ~= nil and endTime ~= nil then
		self.animatedObject.openingHours = {
			["startTime"] = startTime,
			["endTime"] = endTime,
			["disableIfClosed"] = disableIfClosed,
			["closedText"] = closedText
		}
	end
end
