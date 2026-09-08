-- Local values: BoatyardState_mt
BoatyardState = {}
local BoatyardState_mt = Class(BoatyardState)

function BoatyardState.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. ".animatedObject(?)#index", "Animated object index")
	schema:register(XMLValueType.INT, basePath .. ".animatedObject(?)#direction", "Animated object direction")
	schema:register(XMLValueType.INT, basePath .. ".animatedObject(?)#time", "Animated object time")
	schema:register(XMLValueType.BOOL, basePath .. ".animatedObject(?)#reset", "Animated object reset on state deactivate")
	schema:register(XMLValueType.STRING, basePath .. ".meshVisibility(?)#meshId", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".meshVisibility(?)#progress", "")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "active")
end

-- Upvalues: BoatyardState_mt
-- Local values: self
function BoatyardState.new(boatyard, customMt)
	-- upvalues: (copy) BoatyardState_mt
	local v6_ = customMt or BoatyardState_mt
	local v7_ = setmetatable({}, v6_)
	v7_.boatyard = boatyard
	v7_.dirtyFlag = boatyard:getNextDirtyFlag()
	v7_.spline = boatyard.spec_boatyard.spline
	v7_.splineLength = getSplineLength(v7_.spline)
	v7_.isSoundPlaying = false
	return v7_
end

-- Local values: baseDirectory, components, i3dMappings
function BoatyardState:load(xmlFile, key)
	self.meshObjects = {}
	xmlFile:iterate(key .. ".meshVisibility", function(_, p11_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v12_ = xmlFile:getValue(p11_ .. "#meshId")
		local v13_ = xmlFile:getValue(p11_ .. "#progress")
		local v14_ = self.meshObjects
		table.insert(v14_, {
			["meshId"] = v12_,
			["progress"] = v13_
		})
	end)
	self.samples = {}
	local v15_ = self.boatyard.baseDirectory
	local v16_ = self.boatyard.components
	local v17_ = self.boatyard.i3dMappings
	self.samples.active = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "active", v15_, v16_, 0, AudioGroup.ENVIRONMENT, v17_, self)
end

function BoatyardState:delete()
	if self.samples ~= nil then
		g_soundManager:deleteSamples(self.samples)
	end
end

function BoatyardState:saveToXMLFile(xmlFile, key, usedModNames) end

function BoatyardState:loadFromXMLFile(xmlFile, key) end

function BoatyardState:onReadStream(streamId, connection) end

function BoatyardState:onWriteStream(streamId, connection) end

function BoatyardState:onReadUpdateStream(streamId, timestamp, timestamp) end

function BoatyardState:onWriteUpdateStream(streamId, connection, dirtyMask) end

function BoatyardState:update(dt)
	if self.boatyard.isClient and self.samples.active ~= nil then
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

-- Local values: _, mesh
function BoatyardState:activate()
	for _, v21_ in ipairs(self.meshObjects) do
		self.boatyard:setMeshProgress(v21_.meshId, v21_.progress)
	end
	self.isSoundPlaying = false
end

function BoatyardState:deactivate()
	if self.boatyard.isClient and self.samples.active ~= nil then
		g_soundManager:stopSample(self.samples.active)
	end
end

function BoatyardState:isDone()
	return true
end

function BoatyardState:raiseActive()
	return true
end

function BoatyardState:getPlaySound()
	return true
end
