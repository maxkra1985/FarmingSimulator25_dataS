-- Local values: FootballField_mt
FootballField = {}
source("dataS/scripts/objects/football/Football.lua")
source("dataS/scripts/objects/football/FootballFieldActivatable.lua")
source("dataS/scripts/objects/football/FootballFieldGoalEvent.lua")
source("dataS/scripts/objects/football/FootballFieldResetBallEvent.lua")
source("dataS/scripts/objects/football/FootballFieldResetEvent.lua")
source("dataS/scripts/objects/football/FootballShootEvent.lua")
local FootballField_mt = Class(FootballField, Object)
InitStaticObjectClass(FootballField, "FootballField")
g_xmlManager:addCreateSchemaFunction(function()
	FootballField.xmlSchema = XMLSchema.new("footballField")
end)
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = FootballField.xmlSchema
	I3DUtil.registerI3dMappingXMLPaths(v2_, "footballField")
	v2_:register(XMLValueType.NODE_INDEX, "footballField.field#spawnPointNode", "Football spawn point node")
	v2_:register(XMLValueType.NODE_INDEX, "footballField.field#gameAreaNode", "Football field game area")
	v2_:register(XMLValueType.NODE_INDEX, "footballField.field#resetTriggerNode", "Field reset trigger")
	v2_:register(XMLValueType.NODE_INDEX, "footballField.field.teamBlue.goal#triggerNode", "Goal trigger for team blue")
	v2_:register(XMLValueType.NODE_INDEX, "footballField.field.teamBlue.scoreboard#node", "Scoreboard node for team blue")
	v2_:register(XMLValueType.NODE_INDEX, "footballField.field.teamRed.goal#triggerNode", "Goal trigger for team red")
	v2_:register(XMLValueType.NODE_INDEX, "footballField.field.teamRed.scoreboard#node", "Scoreboard node for team red")
	SoundManager.registerSampleXMLPaths(v2_, "footballField.field.sounds", "goalBlue")
	SoundManager.registerSampleXMLPaths(v2_, "footballField.field.sounds", "goalRed")
	SoundManager.registerSampleXMLPaths(v2_, "footballField.field.sounds", "goal")
	SoundManager.registerSampleXMLPaths(v2_, "footballField.field.sounds", "whistle")
	Football.registerXMLPaths(v2_, "footballField.football")
end)

-- Local values: footballField
function FootballField.onCreate(_, id)
	local v4_ = FootballField.new(g_server ~= nil, g_client ~= nil)
	if v4_:load(id) then
		g_currentMission.onCreateObjectSystem:add(v4_)
		v4_:register(true)
	else
		v4_:delete()
	end
end

-- Upvalues: FootballField_mt
-- Local values: self
function FootballField.new(isServer, isClient, customMt)
	-- upvalues: (copy) FootballField_mt
	local v8_ = Object.new(isServer, isClient, customMt or FootballField_mt)
	registerObjectClassName(v8_, "FootballField")
	v8_.i3dMappings = {}
	v8_.components = {}
	return v8_
end

-- Local values: xmlFilename, baseDirectory, xmlFile, scoreboardBlueNode, scoreboardRedNode
function FootballField:load(id)
	self.rootNode = id
	local v11_ = getUserAttribute(id, "xmlFilename")
	if v11_ == nil then
		Logging.warning("Missing config \'xmlFilename\' for FootballField")
		return false
	end
	local v12_ = g_currentMission.baseDirectory
	local v13_ = Utils.getFilename(v11_, v12_)
	local v14_ = XMLFile.load("footballField", v13_, FootballField.xmlSchema)
	if v14_ == nil then
		Logging.warning("Could not load football field xml file %q", v13_)
		return false
	end
	local v15_ = self.components
	table.insert(v15_, {
		["node"] = id
	})
	I3DUtil.loadI3DMapping(v14_, "footballField", self.components, self.i3dMappings)
	self.football = Football.new(self.isServer, self.isClient)
	if not self.football:load(v14_, "footballField.football", self.components, self.i3dMappings) then
		self.football:delete()
		Logging.xmlWarning(v14_, "Could not load football for FootballField")
		v14_:delete()
		return false
	end
	self.football:register(true)
	self.footballSpawnPointNode = v14_:getValue("footballField.field#spawnPointNode", nil, self.components, self.i3dMappings)
	if self.footballSpawnPointNode == nil then
		Logging.xmlWarning(v14_, "Invalid spawnPointNode for FootballField")
		v14_:delete()
		return false
	end
	self.gameAreaNode = v14_:getValue("footballField.field#gameAreaNode", nil, self.components, self.i3dMappings)
	if self.gameAreaNode == nil then
		Logging.xmlWarning(v14_, "Invalid gameAreaNode for FootballField")
		v14_:delete()
		return false
	end
	self.resetTriggerNode = v14_:getValue("footballField.field#resetTriggerNode", nil, self.components, self.i3dMappings)
	if self.resetTriggerNode == nil then
		Logging.xmlWarning(v14_, "Invalid resetTriggerNode for FootballField")
		v14_:delete()
		return false
	end
	self.goalTriggerBlueNode = v14_:getValue("footballField.field.teamBlue.goal#triggerNode", nil, self.components, self.i3dMappings)
	if self.goalTriggerBlueNode == nil then
		Logging.xmlWarning(v14_, "Invalid team blue goalTriggerNode for FootballField")
		v14_:delete()
		return false
	end
	self.goalTriggerRedNode = v14_:getValue("footballField.field.teamRed.goal#triggerNode", nil, self.components, self.i3dMappings)
	if self.goalTriggerRedNode == nil then
		Logging.xmlWarning(v14_, "Invalid team red goalTriggerNode for FootballField")
		v14_:delete()
		return false
	end
	local v16_ = v14_:getValue("footballField.field.teamBlue.scoreboard#node", nil, self.components, self.i3dMappings)
	if v16_ == nil then
		Logging.xmlWarning(v14_, "Invalid team blue scoreboard node for FootballField")
		v14_:delete()
		return false
	end
	local v17_ = v14_:getValue("footballField.field.teamRed.scoreboard#node", nil, self.components, self.i3dMappings)
	if v17_ == nil then
		Logging.xmlWarning(v14_, "Invalid team red scoreboard node for FootballField")
		v14_:delete()
		return false
	end
	self.scoreboardBlue = self:createScoreboard(v16_)
	self.scoreboardRed = self:createScoreboard(v17_)
	self.scoreBlue = 0
	self.scoreRed = 0
	self.samples = {}
	self.samples.goal = g_soundManager:loadSampleFromXML(v14_, "footballField.field.sounds", "goal", v12_, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
	self.samples.goalBlue = g_soundManager:loadSampleFromXML(v14_, "footballField.field.sounds", "goalBlue", v12_, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
	self.samples.goalRed = g_soundManager:loadSampleFromXML(v14_, "footballField.field.sounds", "goalRed", v12_, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
	self.samples.whistle = g_soundManager:loadSampleFromXML(v14_, "footballField.field.sounds", "whistle", v12_, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
	self:updateScoreboards()
	if self.isServer then
		addTrigger(self.goalTriggerBlueNode, "goalBlueCallback", self)
		addTrigger(self.goalTriggerRedNode, "goalRedCallback", self)
		addTrigger(self.gameAreaNode, "gameAreaCallback", self)
		self.ballResetTimer = Timer.new(3000)
		self.ballResetTimer:setFinishCallback(function()
			-- upvalues: (copy) self
			self:resetBall()
		end)
	end
	addTrigger(self.resetTriggerNode, "resetTriggerCallback", self)
	self.resetActivatable = FootballFieldResetActivatable.new(self)
	v14_:delete()
	return true
end

function FootballField:delete()
	if self.football ~= nil then
		self.football:delete()
	end
	if self.goalTriggerBlueNode ~= nil then
		removeTrigger(self.goalTriggerBlueNode)
	end
	if self.goalTriggerRedNode ~= nil then
		removeTrigger(self.goalTriggerRedNode)
	end
	if self.gameAreaNode ~= nil then
		removeTrigger(self.gameAreaNode)
	end
	if self.resetTriggerNode ~= nil then
		removeTrigger(self.resetTriggerNode)
	end
	if self.ballResetTimer ~= nil then
		self.ballResetTimer:reset()
	end
	g_soundManager:deleteSamples(self.samples)
	g_currentMission.activatableObjectsSystem:removeActivatable(self.resetActivatable)
	removeConsoleCommand("gsFootballFieldReload")
	unregisterObjectClassName(self)
	FootballField:superClass().delete(self)
end

-- Local values: footballId, scoreBlue, scoreRed
function FootballField:readStream(streamId, connection)
	FootballField:superClass().readStream(self, streamId, connection)
	if connection:getIsServer() then
		local v22_ = NetworkUtil.readNodeObjectId(streamId)
		self.football:readStream(streamId, connection)
		g_client:finishRegisterObject(self.football, v22_)
		self:setScore(streamReadUInt8(streamId), (streamReadUInt8(streamId)))
	end
end

function FootballField:writeStream(streamId, connection)
	FootballField:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.football))
		self.football:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.football)
		streamWriteUInt8(streamId, self.scoreBlue)
		streamWriteUInt8(streamId, self.scoreRed)
	end
end

-- Local values: x, y, z
function FootballField:resetBall()
	if self.football ~= nil then
		local v27_, v28_, v29_ = getWorldTranslation(self.footballSpawnPointNode)
		self.football:resetToWorldPosition(v27_, v28_, v29_, 0, 0, 0)
	end
end

function FootballField:onResetBall()
	g_soundManager:playSample(self.samples.whistle)
end

function FootballField:reset()
	g_soundManager:playSample(self.samples.whistle)
	self:setScore(0, 0)
	if self.isServer then
		self:resetBall()
	else
		g_client:getServerConnection():sendEvent(FootballFieldResetEvent.new(self))
	end
end

function FootballField:onGoal(isBlueGoal, scoreBlue, scoreRed)
	self:setScore(scoreBlue, scoreRed)
	g_soundManager:playSample(self.samples.whistle)
	g_soundManager:playSample(self.samples.goal)
	if isBlueGoal then
		g_soundManager:playSample(self.samples.goalBlue)
	else
		g_soundManager:playSample(self.samples.goalRed)
	end
end

function FootballField:onGoalBlue()
	g_server:broadcastEvent(FootballFieldGoalEvent.new(self, true, self.scoreBlue + 1, self.scoreRed), true)
end

function FootballField:onGoalRed()
	g_server:broadcastEvent(FootballFieldGoalEvent.new(self, false, self.scoreBlue, self.scoreRed + 1), true)
end

-- Local values: object
function FootballField:goalBlueCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if onEnter and otherId ~= 0 then
		local v41_ = g_currentMission:getNodeObject(otherId)
		if v41_ ~= nil and (v41_ == self.football and not self.ballResetTimer:getIsRunning()) then
			self.ballResetTimer:start()
			self:onGoalRed()
		end
	end
end

-- Local values: object
function FootballField:goalRedCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if onEnter and otherId ~= 0 then
		local v45_ = g_currentMission:getNodeObject(otherId)
		if v45_ ~= nil and (v45_ == self.football and not self.ballResetTimer:getIsRunning()) then
			self.ballResetTimer:start()
			self:onGoalBlue()
		end
	end
end

-- Local values: object
function FootballField:gameAreaCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if onLeave and otherId ~= 0 then
		local v49_ = g_currentMission:getNodeObject(otherId)
		if v49_ ~= nil and v49_ == self.football then
			self.ballResetTimer:startIfNotRunning()
			if self.isServer then
				g_server:broadcastEvent(FootballFieldResetBallEvent.new(self), true)
			end
		end
	end
end

function FootballField:resetTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if (onEnter or onLeave) and (g_localPlayer and g_localPlayer.rootNode == otherId) then
		if onEnter then
			g_currentMission.activatableObjectsSystem:addActivatable(self.resetActivatable)
			if g_isDevelopmentVersion then
				addConsoleCommand("gsFootballFieldReload", "Reload football field", "debugReloadField", self)
			end
		end
		if onLeave then
			g_currentMission.activatableObjectsSystem:removeActivatable(self.resetActivatable)
			removeConsoleCommand("gsFootballFieldReload")
		end
	end
end

-- Local values: fontMaterial, scoreboard, size, scaleX, scaleY, mask, emissiveScale, color, hiddenColor, characterLine, characters, _, char
function FootballField:createScoreboard(node)
	local v55_ = g_materialManager:getFontMaterial("GENERIC_BOLD", nil)
	if v55_ == nil then
		return nil
	end
	local v56_ = {
		["displayNode"] = node
	}
	local v57_, v58_ = Utils.maskToFormat("00")
	v56_.formatStr = v57_
	v56_.formatPrecision = v58_
	v56_.fontMaterial = v55_
	local v59_ = CharacterLine.new(v56_.displayNode, v55_, ("00"):len())
	v59_:setTextAlignment(RenderText.ALIGN_CENTER)
	v59_:setSizeAndScale(0.7, 1, 1)
	v59_:setColor({
		1,
		1,
		1,
		1
	}, {
		0.5,
		0.5,
		0.5,
		1
	}, 0, nil)
	v56_.characterLine = v59_
	local v60_ = v56_.characterLine.characters
	for _, v61_ in ipairs(v60_) do
		setClipDistance(v61_, 150)
	end
	return v56_
end

-- Local values: blue, red
function FootballField:updateScoreboards()
	self.scoreboardBlue.characterLine:setText(string.format("%02d", self.scoreBlue))
	self.scoreboardRed.characterLine:setText(string.format("%02d", self.scoreRed))
end

function FootballField:setScore(blue, red)
	self.scoreBlue = blue
	self.scoreRed = red
	self:updateScoreboards()
end

-- Local values: rootNode, footballField
function FootballField:debugReloadField()
	local v67_ = self.rootNode
	self:delete()
	local v68_ = FootballField.new(g_server ~= nil, g_client ~= nil)
	if v68_:load(v67_) then
		v68_:register(true)
		return "Reloaded football field"
	else
		v68_:delete()
		return "Could not reload football field. Please restart the game"
	end
end
