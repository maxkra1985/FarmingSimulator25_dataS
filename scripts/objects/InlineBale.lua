-- Local values: InlineBale_mt, InlineBaleActivatable_mt
InlineBale = {}
InlineBale.xmlSchema = nil
InlineBale.AMOUNT_NUM_BITS = 11
InlineBale.MAX_NUM_BALES = 2 ^ InlineBale.AMOUNT_NUM_BITS - 1
source("dataS/scripts/events/InlineBaleOpenEvent.lua")
InitStaticObjectClass(InlineBale, "InlineBale")
local InlineBale_mt = Class(InlineBale, Object)
g_xmlManager:addCreateSchemaFunction(function()
	InlineBale.xmlSchema = XMLSchema.new("inlineBale")
end)
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = InlineBale.xmlSchema
	v2_:register(XMLValueType.FLOAT, "inlineBale#maxOpenDistance", "Max. distance to player to allow opening of bale", 3)
	v2_:register(XMLValueType.STRING, "inlineBale.replacementBale#filename", "Filename of bale replacement")
	v2_:register(XMLValueType.STRING, "inlineBale.textures#diffuse", "Wrapping diffuse file to apply on bale")
	v2_:register(XMLValueType.STRING, "inlineBale.textures#normal", "Wrapping normal file to apply on bale")
	v2_:register(XMLValueType.FLOAT, "inlineBale.wrapping.key(?)#time", "Wrapping time")
	v2_:register(XMLValueType.FLOAT, "inlineBale.wrapping.key(?)#wrappingState", "Wrapping shader state")
	v2_:register(XMLValueType.VECTOR_ROT, "inlineBale.joint#startRotLimit", "Start rotation limit")
	v2_:register(XMLValueType.VECTOR_ROT, "inlineBale.joint#endRotLimit", "End rotation limit")
	v2_:register(XMLValueType.VECTOR_TRANS, "inlineBale.joint#startTransLimit", "Start translation limit")
	v2_:register(XMLValueType.VECTOR_TRANS, "inlineBale.joint#endTransLimit", "End translation limit")
	v2_:register(XMLValueType.INT, "inlineBale.joint#wrappingAxis", "Wrapping axis of bale", 1)
	v2_:register(XMLValueType.TIME, "inlineBale.joint#lockTime", "Time until joint is fully locked (sec)", 5)
	v2_:register(XMLValueType.STRING, "inlineBale.connector#filename", "Path to connector file")
	v2_:register(XMLValueType.INT, "inlineBale.connector#axis", "Connector axis index", 1)
	v2_:register(XMLValueType.FLOAT, "inlineBale.connector#offset", "Connection placement offset", 0.5)
	local v3_ = ItemSystem.xmlSchemaSavegame
	v3_:register(XMLValueType.STRING, "items.item(?)#filename", "Filename")
	v3_:register(XMLValueType.STRING, "items.item(?)#uniqueId", "Unique id of inline bale")
	v3_:register(XMLValueType.STRING, "items.item(?).bales.bale(?)#uniqueId", "Unique id of inline bales")
end)

-- Upvalues: InlineBale_mt
-- Local values: self
function InlineBale.new(isServer, isClient, customMt)
	-- upvalues: (copy) InlineBale_mt
	local v7_ = Object.new(isServer, isClient, customMt or InlineBale_mt)
	v7_.bales = {}
	v7_.baleJoints = {}
	v7_.pendingBale = nil
	v7_.wrappingColor = {
		1,
		1,
		1,
		1
	}
	v7_.wrappingState = 0
	v7_.uniqueId = nil
	v7_.configFileName = nil
	v7_.maxOpenDistance = 3
	v7_.connector = nil
	v7_.connectorAxis = 1
	v7_.connectorOffset = 0.5
	v7_.wrappingStateCurve = nil
	v7_.startRotLimit = { 0, 0, 0 }
	v7_.endRotLimit = { 0, 0, 0 }
	v7_.startTransLimit = { 0, 0, 0 }
	v7_.endTransLimit = { 0, 0, 0 }
	v7_.wrappingAxis = 1
	v7_.wrappingAxisScale = { 1, 0, 0 }
	v7_.lockTime = 5000
	v7_.balesToLoad = {}
	registerObjectClassName(v7_, "InlineBale")
	g_currentMission.itemSystem:addItem(v7_)
	v7_.activatable = InlineBaleActivatable.new(v7_)
	v7_.balesDirtyFlag = v7_:getNextDirtyFlag()
	v7_.wrapperDirtyFlag = v7_:getNextDirtyFlag()
	v7_.wakeUpDelay = 0
	return v7_
end

function InlineBale:delete()
	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
	g_currentMission.itemSystem:removeItem(self)
	unregisterObjectClassName(self)
	InlineBale:superClass().delete(self)
end

-- Local values: _, baseDirectory, xmlFile, replacementBaleFilename, j, key2, t, wrappingState
function InlineBale:loadFromConfigXML(configFileName)
	self.configFileName = configFileName
	local _, v11_ = Utils.getModNameAndBaseDirectory(configFileName)
	self.baseDirectory = v11_
	local v12_ = XMLFile.load("inlineBaleXml", configFileName, InlineBale.xmlSchema)
	if v12_ == nil then
		Logging.error("Unable to create InlineBale from config file \'%s\'", configFileName)
		return false
	end
	self.maxOpenDistance = v12_:getValue("inlineBale#maxOpenDistance", self.maxOpenDistance)
	self.connectorFilename = Utils.getFilename(v12_:getValue("inlineBale.connector#filename"), self.baseDirectory)
	self.connectorAxis = v12_:getValue("inlineBale.connector#axis", self.connectorAxis)
	self.connectorOffset = v12_:getValue("inlineBale.connector#offset", self.connectorOffset)
	local v13_ = v12_:getValue("inlineBale.replacementBale#filename")
	if v13_ ~= nil then
		self.replacementBaleFilename = Utils.getFilename(v13_, self.baseDirectory)
		if not fileExists(self.replacementBaleFilename) then
			local v14_ = Logging.xmlWarning
			local v15_ = self.replacementBaleFilename
			v14_(v12_, "Unknown wrapper bale file \'%s\'", (tostring(v15_)))
			return false
		end
	end
	self.wrapDiffuse = Utils.getFilename(v12_:getValue("inlineBale.textures#diffuse"), self.baseDirectory)
	if self.wrapDiffuse == nil or not textureFileExists(self.wrapDiffuse) then
		local v16_ = Logging.xmlWarning
		local v17_ = self.wrapDiffuse
		v16_(v12_, "Missing wrap diffuse \'%s\'", (tostring(v17_)))
		return false
	end
	self.wrapNormal = Utils.getFilename(v12_:getValue("inlineBale.textures#normal"), self.baseDirectory)
	if self.wrapNormal == nil or not textureFileExists(self.wrapNormal) then
		local v18_ = Logging.xmlWarning
		local v19_ = self.wrapNormal
		v18_(v12_, "Missing wrap normal \'%s\'", (tostring(v19_)))
		return false
	end
	self.wrappingStateCurve = AnimCurve.new(linearInterpolator1)
	local v20_ = 0
	while true do
		local v21_ = string.format("inlineBale.wrapping.key(%d)", v20_)
		if not v12_:hasProperty(v21_) then
			break
		end
		local v22_ = v12_:getValue(v21_ .. "#time")
		local v23_ = {
			v12_:getValue(v21_ .. "#wrappingState"),
			["time"] = v22_
		}
		self.wrappingStateCurve:addKeyframe(v23_)
		v20_ = v20_ + 1
	end
	self.startRotLimit = v12_:getValue("inlineBale.joint#startRotLimit", nil, true) or self.startRotLimit
	self.endRotLimit = v12_:getValue("inlineBale.joint#endRotLimit", nil, true) or self.endRotLimit
	self.startTransLimit = v12_:getValue("inlineBale.joint#startTransLimit", nil, true) or self.startTransLimit
	self.endTransLimit = v12_:getValue("inlineBale.joint#endTransLimit", nil, true) or self.endTransLimit
	self.wrappingAxis = v12_:getValue("inlineBale.joint#wrappingAxis", self.wrappingAxis)
	self.wrappingAxisScale = { 0, 0, 0 }
	local v24_ = self.wrappingAxisScale
	local v25_ = self.wrappingAxis
	local v26_ = math.abs(v25_)
	local v27_ = self.wrappingAxis
	v24_[v26_] = math.clamp(v27_, -1, 1)
	self.lockTime = v12_:getValue("inlineBale.joint#lockTime", self.lockTime / 1000)
	v12_:delete()
	return true
end

-- Local values: i, baseKey, entry
function InlineBale:loadFromXMLFile(xmlFile, key)
	self.configFileName = xmlFile:getValue(key .. "#filename")
	if self.configFileName == nil then
		Logging.error("Unable to load InlineBale from savegame. No filename given.")
		return false
	end
	self:setUniqueId(xmlFile:getValue(key .. "#uniqueId", nil))
	if not self:loadFromConfigXML(self.configFileName) then
		Logging.error("Unable to load InlineBale from savegame.")
		return false
	end
	local v31_ = 0
	while true do
		local v32_ = string.format("%s.bales.bale(%d)", key, v31_)
		if not xmlFile:hasProperty(v32_) then
			break
		end
		local v33_ = {
			["uniqueId"] = xmlFile:getValue(v32_ .. "#uniqueId")
		}
		if v33_.uniqueId ~= nil then
			local v34_ = self.balesToLoad
			table.insert(v34_, v33_)
		end
		v31_ = v31_ + 1
	end
	if #self.balesToLoad > 0 then
		self:raiseActive()
	else
		self.removeEmptyInlineBale = true
		self:raiseActive()
	end
	self.numBalesSent = 0
	return true
end

-- Local values: i, bale, baleKey
function InlineBale:saveToXMLFile(xmlFile, key)
	if #self.bales ~= 1 or self.pendingBale == nil then
		xmlFile:setValue(key .. "#filename", self.configFileName)
		xmlFile:setValue(key .. "#uniqueId", self.uniqueId)
		for v38_, v39_ in ipairs(self.bales) do
			xmlFile:setValue(string.format("%s.bales.bale(%d)#uniqueId", key, v38_ - 1), v39_:getUniqueId())
		end
	end
end

function InlineBale:readStream(streamId, connection)
	self.configFileName = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	self:loadFromConfigXML(self.configFileName)
	InlineBale:superClass().readStream(self, streamId, connection)
	g_currentMission.itemSystem:addItem(self)
	self:readBales(streamId, nil, connection)
end

function InlineBale:writeStream(streamId, connection)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.configFileName))
	InlineBale:superClass().writeStream(self, streamId, connection)
	self:writeBales(streamId, connection)
end

function InlineBale:readUpdateStream(streamId, timestamp, connection)
	if connection.isServer then
		if streamReadBool(streamId) then
			self:readBales(streamId, timestamp, connection)
		end
		if streamReadBool(streamId) then
			self.currentWrapper = NetworkUtil.readNodeObject(streamId)
		end
	end
end

function InlineBale:writeUpdateStream(streamId, connection, dirtyMask)
	if not connection.isServer then
		local v54_ = streamWriteBool
		local v55_ = self.balesDirtyFlag
		if v54_(streamId, bit32.band(dirtyMask, v55_) ~= 0) then
			self:writeBales(streamId, connection, dirtyMask)
		end
		local v56_ = streamWriteBool
		local v57_ = self.wrapperDirtyFlag
		if v56_(streamId, bit32.band(dirtyMask, v57_) ~= 0) then
			NetworkUtil.writeNodeObject(streamId, self.currentWrapper)
		end
	end
end

-- Local values: sum, _, bale, i
function InlineBale:readBales(streamId, timestamp, connection)
	local v60_ = streamReadUIntN(streamId, InlineBale.AMOUNT_NUM_BITS)
	for _, v61_ in ipairs(self.bales) do
		if entityExists(v61_.nodeId) then
			self:removeBaleConnector(v61_)
		end
	end
	self.bales = {}
	for _ = 1, v60_ do
		local v62_ = self.balesToLoad
		local v63_ = NetworkUtil.readNodeObjectId
		table.insert(v62_, v63_(streamId))
	end
	if v60_ > 0 then
		g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
	end
	if #self.balesToLoad > 0 then
		self:raiseActive()
	end
end

-- Local values: numToSend, i
function InlineBale:writeBales(streamId, connection, dirtyMask)
	local v66_ = #self.bales
	if self.pendingBale ~= nil then
		v66_ = v66_ - 1
	end
	streamWriteUIntN(streamId, v66_, InlineBale.AMOUNT_NUM_BITS)
	for v67_ = 1, v66_ do
		NetworkUtil.writeNodeObject(streamId, self.bales[v67_])
	end
	self.numBalesSent = v66_
end

function InlineBale:update(dt) end

-- Local values: allBalesAvailable, _, bale, _, bale, baleObject, wx, _, wz, globalWrappingState, i, bale, halfWidth, sx, sy, sz, ex, ey, ez, dirX, dirZ, x, z, dot, y, length1, pos, s2x, s2y, s2z, length2, wrappingState, readyToAdd, i, baleObjectId, i, baleObjectId, baleObject, i
function InlineBale:updateTick(dt)
	if self.isServer then
		if #self.balesToLoad > 0 then
			local v70_ = true
			for _, v71_ in ipairs(self.balesToLoad) do
				if g_currentMission.itemSystem:getItemByUniqueId(v71_.uniqueId) == nil then
					v70_ = false
				end
			end
			if v70_ then
				for _, v72_ in ipairs(self.balesToLoad) do
					local v73_ = g_currentMission.itemSystem:getItemByUniqueId(v72_.uniqueId)
					if v73_:isa(InlineBaleSingle) then
						self:addBale(v73_)
						self:connectPendingBale(self.connectorFilename)
						self:updateBaleJoints(9999)
					else
						Logging.error("Invalid inline bale found")
					end
				end
				self.balesToLoad = {}
			end
			self:raiseActive()
		end
		self:updateBaleJoints(dt)
		if self.wrappingNode ~= nil and self.wrappingState < 1 then
			local v74_, _, v75_ = getWorldTranslation(self.wrappingNode)
			local v76_ = 0
			for _, v77_ in ipairs(self.bales) do
				if v77_ ~= self.pendingBale then
					local v78_ = v77_.width / 2
					local v79_, v80_, v81_ = localToWorld(v77_.nodeId, self.wrappingAxisScale[1] * v78_, self.wrappingAxisScale[2] * v78_, self.wrappingAxisScale[3] * v78_)
					local v82_, v83_, v84_ = localToWorld(v77_.nodeId, self.wrappingAxisScale[1] * -v78_, self.wrappingAxisScale[2] * -v78_, self.wrappingAxisScale[3] * -v78_)
					local v85_, v86_ = MathUtil.vector2Normalize(v79_ - v82_, v81_ - v84_)
					local v87_, v88_ = MathUtil.projectOnLine(v74_, v75_, v79_, v81_, v85_, v86_)
					local v89_ = MathUtil.getProjectOnLineParameter(v74_, v75_, v79_, v81_, v85_, v86_)
					local v90_ = math.clamp(v89_, 0, 1)
					local v91_ = v80_ * v90_ + v83_ * (1 - v90_)
					local v92_ = MathUtil.vector3Length(v79_ - v87_, v80_ - v91_, v81_ - v88_)
					local v93_ = v92_ / v77_.width
					local v94_ = math.clamp(v93_, 0, 1)
					local v95_, v96_, v97_ = localToWorld(v77_.nodeId, self.wrappingAxisScale[1] * (v78_ + 0.1), self.wrappingAxisScale[2] * (v78_ + 0.1), self.wrappingAxisScale[3] * (v78_ + 0.1))
					local v98_ = MathUtil.vector3Length(v95_ - v87_, v96_ - v91_, v97_ - v88_) < v92_ and 0 or v94_
					if self.wrappingStateCurve ~= nil then
						local v99_ = self.wrappingStateCurve:get(v98_)
						local v100_ = v77_.wrappingState
						local v101_ = math.max(v99_, v100_)
						v77_:setWrappingState(v101_)
						v76_ = v76_ + v101_
					end
				end
			end
			self.wrappingState = v76_ / #self.bales
			self:raiseActive()
		end
		if self.pendingBale == nil and #self.bales ~= self.numBalesSent then
			self:raiseDirtyFlags(self.balesDirtyFlag)
		end
		if self.removeEmptyInlineBale then
			self:delete()
		end
		if self.wakeUpDelay > 0 then
			self.wakeUpDelay = self.wakeUpDelay - dt
			if self.wakeUpDelay <= 0 then
				self:wakeUp()
			end
			self:raiseActive()
			return
		end
	elseif #self.balesToLoad > 0 then
		local v102_ = true
		for _, v103_ in ipairs(self.balesToLoad) do
			if NetworkUtil.getObject(v103_) == nil then
				v102_ = false
			end
		end
		if v102_ then
			for _, v104_ in ipairs(self.balesToLoad) do
				local v105_ = NetworkUtil.getObject(v104_)
				if v105_ ~= nil then
					self:addBale(v105_)
				end
			end
			self.balesToLoad = {}
			for v106_ = 1, #self.bales - 1 do
				if self.bales[v106_] ~= nil and self.bales[v106_ + 1] ~= nil then
					self:loadBaleConnector(self.bales[v106_], self.bales[v106_ + 1], self.connectorFilename)
				end
			end
		end
		self:raiseActive()
	end
end

-- Local values: success
function InlineBale:addBale(bale, baleType)
	local v110_ = false
	if self.isServer then
		if self.pendingBale == nil and self:getIsBaleAllowed(bale, baleType) then
			local v111_ = self.bales
			table.insert(v111_, bale)
			self.pendingBale = bale
			self.wrappingState = self.wrappingState / #self.bales * (#self.bales - 1)
			if bale:isa(InlineBaleSingle) then
				bale:setConnectedInlineBale(self)
			end
			bale:addDeleteListener(self, "onBaleDeleted")
			self:raiseActive()
			v110_ = true
		end
	else
		local v112_ = self.bales
		table.insert(v112_, bale)
		if bale:isa(InlineBaleSingle) then
			bale:setConnectedInlineBale(self)
			v110_ = true
		else
			v110_ = true
		end
	end
	if v110_ and bale.inlineWrapperToAdd ~= nil then
		self:setCurrentWrapperInfo(bale.inlineWrapperToAdd.wrapper, bale.inlineWrapperToAdd.wrappingNode)
		bale.inlineWrapperToAdd = nil
	end
	return v110_
end

function InlineBale:getIsBaleAllowed(bale, baleType)
	if #self.bales == 0 then
		return true
	elseif #self.bales >= InlineBale.MAX_NUM_BALES then
		return false
	else
		return baleType == nil or self.configFileName == baleType.inlineBaleFilename
	end
end

-- Local values: replaced, baleId, attributes, bale, x, y, z, rx, ry, rz, r, g, b
function InlineBale:replacePendingBale(spawnNode, color)
	local v118_ = false
	local v119_ = nil
	if self.pendingBale ~= nil then
		local v120_ = self.pendingBale:getBaleAttributes()
		local v121_ = InlineBaleSingle.new(self.isServer, self.isClient)
		local v122_, v123_, v124_ = getWorldTranslation(spawnNode)
		local v125_, v126_, v127_ = getWorldRotation(spawnNode)
		if v121_:loadFromConfigXML(self.replacementBaleFilename or v120_.xmlFilename, v122_, v123_, v124_, v125_, v126_, v127_, v120_.uniqueId) then
			v120_.wrapDiffuse = self.wrapDiffuse
			v120_.wrapNormal = self.wrapNormal
			v121_:applyBaleAttributes(v120_)
			v121_:register()
			self.pendingBale:delete()
			if color ~= nil then
				local v128_, v129_, v130_ = unpack(color)
				v121_:setColor(v128_, v129_, v130_)
			end
			v119_ = NetworkUtil.getObjectId(v121_)
			self.bales[#self.bales] = v121_
			self.pendingBale = v121_
			v121_:setConnectedInlineBale(self)
			v121_:addDeleteListener(self, "onBaleDeleted")
			v118_ = true
		end
	end
	return v118_, v119_
end

function InlineBale:getPendingBale()
	return self.pendingBale
end

function InlineBale:connectPendingBale()
	g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
	if self.pendingBale == nil then
		return false
	end
	if #self.bales >= 2 then
		self:connectBale(self.pendingBale)
	end
	self.pendingBale = nil
	return true
end

-- Local values: lastBale
function InlineBale:connectBale(bale)
	local v135_ = self.bales[#self.bales - 1]
	self:createBaleJoint(v135_, bale)
	self:loadBaleConnector(v135_, bale, self.connectorFilename)
	self:raiseActive()
end

-- Local values: constr, jointIndex, entry
function InlineBale:createBaleJoint(bale1, bale2)
	local v139_ = JointConstructor.new()
	v139_:setActors(bale1.nodeId, bale2.nodeId)
	v139_:setJointTransforms(bale1.nodeId, bale2.nodeId)
	v139_:setEnableCollision(true)
	v139_:setRotationLimit(0, -self.startRotLimit[1], self.startRotLimit[1])
	v139_:setRotationLimit(1, -self.startRotLimit[2], self.startRotLimit[2])
	v139_:setRotationLimit(2, -self.startRotLimit[3], self.startRotLimit[3])
	v139_:setTranslationLimit(0, true, -self.startTransLimit[1], self.startTransLimit[1])
	v139_:setTranslationLimit(1, true, -self.startTransLimit[2], self.startTransLimit[2])
	v139_:setTranslationLimit(2, true, -self.startTransLimit[3], self.startTransLimit[3])
	local v140_ = {
		["jointIndex"] = v139_:finalize(),
		["time"] = 0
	}
	self.baleJoints[bale1] = v140_
end

-- Local values: _, joint
function InlineBale:updateBaleJoints(dt)
	for _, v143_ in pairs(self.baleJoints) do
		if v143_.time < self.lockTime then
			v143_.time = v143_.time + dt
			local v144_ = v143_.jointIndex
			local v145_ = v143_.time / self.lockTime
			self:setBaleJointLimits(v144_, (math.clamp(v145_, 0, 1)))
			self:raiseActive()
		end
	end
end

-- Local values: x, y, z
function InlineBale:setBaleJointLimits(jointIndex, alpha)
	local v149_, v150_, v151_ = MathUtil.vector3ArrayLerp(self.startRotLimit, self.endRotLimit, alpha)
	setJointRotationLimit(jointIndex, 0, true, -v149_, v149_)
	setJointRotationLimit(jointIndex, 1, true, -v150_, v150_)
	setJointRotationLimit(jointIndex, 2, true, -v151_, v151_)
	local v152_, v153_, v154_ = MathUtil.vector3ArrayLerp(self.startTransLimit, self.endTransLimit, alpha)
	setJointTranslationLimit(jointIndex, 0, true, -v152_, v152_)
	setJointTranslationLimit(jointIndex, 1, true, -v153_, v153_)
	setJointTranslationLimit(jointIndex, 2, true, -v154_, v154_)
end

function InlineBale:loadBaleConnector(bale1, bale2, filename)
	if filename == nil or bale2:getHasConnector() then
		return false
	else
		return bale2:setConnector(bale1, filename, self.connectorAxis, self.connectorOffset) and true or false
	end
end

function InlineBale:removeBaleConnector(bale)
	if bale ~= nil then
		bale:removeConnector()
	end
end

function InlineBale:setCurrentWrapperInfo(wrapper, wrappingNode)
	self.wrappingNode = wrappingNode
	self:raiseActive()
	if wrapper ~= self.currentWrapper then
		self.currentWrapper = wrapper
		self:raiseDirtyFlags(self.wrapperDirtyFlag)
	end
end

function InlineBale:getNumberOfBales()
	return #self.bales
end

function InlineBale:getBales()
	return self.bales
end

function InlineBale:setUniqueId(uniqueId)
	self.uniqueId = uniqueId
end

function InlineBale:getUniqueId()
	return self.uniqueId
end

-- Local values: _, bale
function InlineBale:setWrappingState(state)
	for _, v170_ in ipairs(self:getBales()) do
		v170_:setWrappingState(state)
	end
	self.wrappingState = state
end

-- Local values: _, bale
function InlineBale:wakeUp(delay)
	if delay == nil or delay == 0 then
		for _, v173_ in ipairs(self:getBales()) do
			I3DUtil.wakeUpObject(v173_.nodeId)
		end
	else
		self.wakeUpDelay = delay
		self:raiseActive()
	end
end

-- Local values: x1, y1, z1, firstBale, x2, y2, z2, distance, lastBale
function InlineBale:getCanInteract()
	if #self.bales <= 0 then
		return false
	end
	if self.currentWrapper ~= nil then
		return false
	end
	local v175_, v176_, v177_ = self:getInteractionPosition()
	if v175_ ~= nil then
		local v178_ = self.bales[1]
		local v179_, v180_, v181_ = getWorldTranslation(v178_.nodeId)
		if MathUtil.vector3Length(v175_ - v179_, v176_ - v180_, v177_ - v181_) < self.maxOpenDistance then
			return true
		end
		local v182_ = self.bales[#self.bales]
		local v183_, v184_, v185_ = getWorldTranslation(v182_.nodeId)
		if MathUtil.vector3Length(v175_ - v183_, v176_ - v184_, v177_ - v185_) < self.maxOpenDistance then
			return true
		end
	end
	return false
end

function InlineBale:getInteractionPosition()
	if not g_localPlayer:getIsInVehicle() then
		if #self.bales <= 0 or g_currentMission.accessHandler:canPlayerAccess(self.bales[1]) then
			return g_localPlayer:getPosition()
		end
	end
end

-- Local values: _, bale
function InlineBale:getCanBeOpened()
	for _, v188_ in ipairs(self.bales) do
		if v188_.wrappingState < 1 or v188_:getIsFermenting() then
			return false
		end
	end
	return true
end

-- Local values: distance1, distance2, fristBale, lastBale, bx, by, bz
function InlineBale:openBaleAtPosition(x, y, z)
	local v193_ = self.bales[1]
	local v194_ = self.bales[#self.bales]
	local v195_, v196_
	if #self.bales > 1 then
		local v197_, v198_, v199_ = getWorldTranslation(v193_.nodeId)
		v195_ = MathUtil.vector3Length(x - v197_, y - v198_, z - v199_)
		local v200_, v201_, v202_ = getWorldTranslation(v194_.nodeId)
		v196_ = MathUtil.vector3Length(x - v200_, y - v201_, z - v202_)
	else
		v195_ = 0
		v196_ = 1
	end
	if v195_ < v196_ then
		self:openBale(v193_, true)
	else
		self:openBale(v194_, false)
	end
end

-- Local values: nextBale, joint, i, prevBale, joint, attributes, newBale, x, y, z, rx, ry, rz
function InlineBale:openBale(bale, isFirst, replaceBale)
	if isFirst then
		self:removeBaleConnector(self.bales[2])
		local v207_ = self.baleJoints[bale]
		if v207_ ~= nil then
			removeJoint(v207_.jointIndex)
		end
		for v208_ = 1, #self.bales - 1 do
			self.bales[v208_] = self.bales[v208_ + 1]
		end
	else
		self:removeBaleConnector(bale)
		local v209_ = self.bales[#self.bales - 1]
		if v209_ ~= nil then
			local v210_ = self.baleJoints[v209_]
			if v210_ ~= nil then
				removeJoint(v210_.jointIndex)
			end
		end
	end
	table.remove(self.bales, #self.bales)
	bale:setConnectedInlineBale(nil)
	if replaceBale == nil or replaceBale then
		local v211_ = bale:getBaleAttributes()
		local v212_ = Bale.new(self.isServer, self.isClient)
		local v213_, v214_, v215_ = getWorldTranslation(bale.nodeId)
		local v216_, v217_, v218_ = getWorldRotation(bale.nodeId)
		if v212_:loadFromConfigXML(v211_.xmlFilename, v213_, v214_, v215_, v216_, v217_, v218_, v211_.uniqueId) then
			v211_.wrapDiffuse = self.wrapDiffuse
			v211_.wrapNormal = self.wrapNormal
			v212_:applyBaleAttributes(v211_)
			v212_:register()
			v212_:open()
			bale:delete()
		end
	end
	if #self.bales == 0 then
		self:delete()
	end
	self:raiseActive()
end

-- Local values: baleIndex, i, bale2, i, i
function InlineBale:onBaleDeleted(bale)
	if self.pendingBale == nil then
		if self.bales[1] == bale then
			self:openBale(bale, true, false)
			return
		end
		if self.bales[#self.bales] == bale then
			self:openBale(bale, false, false)
			return
		end
		local v221_ = nil
		for v222_, v223_ in ipairs(self.bales) do
			if v223_ == bale then
				v221_ = v222_
			end
		end
		if v221_ ~= nil then
			if #self.bales - v221_ < v221_ then
				for v224_ = #self.bales, v221_ + 1, -1 do
					self:openBale(self.bales[v224_], false)
				end
				self:openBale(bale, false, false)
				return
			end
			for _ = 1, v221_ - 1 do
				self:openBale(self.bales[1], true)
			end
			self:openBale(bale, true, false)
		end
	end
end
InlineBaleActivatable = {}
local v_u_225_ = Class(InlineBaleActivatable)
function InlineBaleActivatable.new(p226_)
	-- upvalues: (copy) v_u_225_
	local v227_ = v_u_225_
	local v228_ = setmetatable({}, v227_)
	v228_.inlineBale = p226_
	v228_.activateText = g_i18n:getText("action_cutBale")
	return v228_
end

function InlineBaleActivatable:getIsActivatable()
	return self.inlineBale:getCanInteract() and self.inlineBale:getCanBeOpened() and true or false
end

-- Local values: ix, iy, iz
function InlineBaleActivatable:run()
	local v231_, v232_, v233_ = self.inlineBale:getInteractionPosition()
	if v231_ ~= nil then
		if g_server ~= nil then
			self.inlineBale:openBaleAtPosition(v231_, v232_, v233_)
			return
		end
		g_client:getServerConnection():sendEvent(InlineBaleOpenEvent.new(self.inlineBale, v231_, v232_, v233_))
	end
end
