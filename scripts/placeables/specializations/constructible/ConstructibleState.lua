-- Local values: ConstructibleState_mt
ConstructibleState = {}
local ConstructibleState_mt = Class(ConstructibleState)

function ConstructibleState.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".toggleMesh(?)#node", "")
	schema:register(XMLValueType.BOOL, basePath .. ".toggleMesh(?)#active", "")
	schema:register(XMLValueType.BOOL, basePath .. ".toggleMesh(?)#updatePhysics", "", false)
	schema:register(XMLValueType.INT, basePath .. ".toggleHotspot(?)#index", "")
	schema:register(XMLValueType.BOOL, basePath .. ".toggleHotspot(?)#isVisible", "")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "active")
end

-- Upvalues: ConstructibleState_mt
-- Local values: self
function ConstructibleState.new(constructible, dirtyFlag, customMt)
	-- upvalues: (copy) ConstructibleState_mt
	local v7_ = customMt or ConstructibleState_mt
	local v8_ = setmetatable({}, v7_)
	v8_.constructible = constructible
	v8_.dirtyFlag = dirtyFlag
	v8_.toggleMeshes = {}
	v8_.isSoundPlaying = false
	return v8_
end

-- Local values: baseDirecory, _, nodeKey, hotspotIndex, isVisible, _, nodeKey, node, active, physics, collision
function ConstructibleState:load(xmlFile, key)
	local v12_ = self.constructible.baseDirectory
	self.name = string.upper(xmlFile:getValue(key .. "#name", ""))
	if self.constructible.isClient then
		self.samples = {}
		self.samples.active = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "active", v12_, self.constructible.components, 0, AudioGroup.ENVIRONMENT, self.constructible.i3dMappings, self)
	end
	for _, v13_ in xmlFile:iterator(key .. ".toggleHotspot") do
		local v14_ = xmlFile:getInt(v13_ .. "#index")
		local v15_ = xmlFile:getBool(v13_ .. "#isVisible")
		if v14_ ~= nil and v15_ ~= nil then
			if self.toggleHotspots == nil then
				self.toggleHotspots = {}
			end
			local v16_ = self.toggleHotspots
			table.insert(v16_, {
				["index"] = v14_,
				["isVisible"] = v15_
			})
		end
	end
	for _, v17_ in xmlFile:iterator(key .. ".toggleMesh") do
		local v18_ = xmlFile:getValue(v17_ .. "#node", nil, self.constructible.components, self.constructible.i3dMappings)
		if v18_ ~= nil then
			local v19_ = {
				["node"] = v18_,
				["active"] = xmlFile:getValue(v17_ .. "#active", true),
				["physics"] = xmlFile:getValue(v17_ .. "#updatePhysics", false)
			}
			local v20_ = self.toggleMeshes
			table.insert(v20_, v19_)
		end
	end
	self.objectChanges = ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, nil, self.constructible.components, self.constructible)
end

function ConstructibleState:delete()
	if self.samples ~= nil then
		g_soundManager:deleteSamples(self.samples)
	end
end

function ConstructibleState:saveToXMLFile(xmlFile, key, usedModNames) end

function ConstructibleState:loadFromXMLFile(xmlFile, key) end

function ConstructibleState:onReadStream(streamId, connection) end

function ConstructibleState:onWriteStream(streamId, connection) end

function ConstructibleState:onReadUpdateStream(streamId, timestamp, timestamp) end

function ConstructibleState:onWriteUpdateStream(streamId, connection, dirtyMask) end

function ConstructibleState:update(dt)
	if self.constructible.isClient and (self.samples ~= nil and self.samples.active ~= nil) then
		if self:getPlaySound() then
			if not self.isSoundPlaying then
				g_soundManager:playSample(self.samples.active)
				self.isSoundPlaying = true
				return
			end
		elseif self.isSoundPlaying then
			g_soundManager:stopSample(self.samples.active)
			self.isSoundPlaying = false
		end
	end
end

-- Local values: _, toggleMesh, _, hotspot
function ConstructibleState:activate()
	self.isSoundPlaying = false
	for _, v24_ in ipairs(self.toggleMeshes) do
		if v24_.active then
			if v24_.physics then
				addToPhysics(v24_.node)
			end
			setVisibility(v24_.node, true)
		else
			if v24_.physics then
				removeFromPhysics(v24_.node)
			end
			setVisibility(v24_.node, false)
		end
	end
	if self.toggleHotspots ~= nil and self.constructible.setHotspotVisible ~= nil then
		for _, v25_ in ipairs(self.toggleHotspots) do
			self.constructible:setHotspotVisible(v25_.index, v25_.isVisible)
		end
		self.constructible:updateHotspots()
	end
	ObjectChangeUtil.setObjectChanges(self.objectChanges, true)
end

function ConstructibleState:deactivate()
	if self.constructible.isClient and (self.samples ~= nil and self.samples.active ~= nil) then
		g_soundManager:stopSample(self.samples.active)
	end
end

-- Local values: _, toggleMesh
function ConstructibleState:reset()
	for _, v28_ in ipairs(self.toggleMeshes) do
		if v28_.active then
			if v28_.physics then
				removeFromPhysics(v28_.node)
			end
			setVisibility(v28_.node, false)
		else
			if v28_.physics then
				addToPhysics(v28_.node)
			end
			setVisibility(v28_.node, true)
		end
	end
end

function ConstructibleState:isDone()
	return false
end

function ConstructibleState:raiseActive()
	return false
end

function ConstructibleState:getPlaySound()
	return true
end

function ConstructibleState:getIsConstructibleState()
	return true
end
