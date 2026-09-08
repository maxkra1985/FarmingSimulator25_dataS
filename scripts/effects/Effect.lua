-- Local values: Effect_mt
Effect = {}
Effect.DEFAULT_UPDATE_DISTANCE = 175
local Effect_mt = Class(Effect)

-- Upvalues: Effect_mt
-- Local values: self
function Effect.new(customMt)
	-- upvalues: (copy) Effect_mt
	local v3_ = customMt or Effect_mt
	local v4_ = setmetatable({}, v3_)
	v4_.deleteListeners = {}
	v4_.startRestriction = {}
	v4_.allowUpdate = true
	v4_.lastUpdateTime = 0
	return v4_
end

-- Local values: filename, arguments
function Effect:load(xmlFile, baseName, rootNodes, parent, i3dMapping)
	if xmlFile:hasProperty(baseName) then
		self.parent = parent
		self.rootNodes = rootNodes
		self.configFileName = Utils.getNoNil(parent.configFileName, parent.xmlFilename)
		self.baseDirectory = parent.baseDirectory
		local v11_ = xmlFile:getValue(baseName .. "#filename")
		if v11_ == nil then
			if self:loadEffectAttributes(xmlFile, baseName, nil, rootNodes, i3dMapping) then
				self:transformEffectNode(xmlFile, baseName, nil)
				return self
			else
				Logging.xmlWarning(xmlFile, "Failed to load effect \'%s\' from node", baseName)
				return nil
			end
		else
			local v12_ = Utils.getFilename(v11_, self.baseDirectory)
			self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v12_, false, false, self.effectI3DFileLoaded, self, {
				["xmlFile"] = xmlFile,
				["baseName"] = baseName,
				["i3dMapping"] = i3dMapping,
				["filename"] = v12_,
				["node"] = nil
			})
			return self
		end
	else
		return nil
	end
end

-- Local values: filename, arguments
function Effect:loadFromNode(node, parent)
	self.parent = parent
	self.baseDirectory = parent.baseDirectory
	self.configFileName = Utils.getNoNil(parent.configFileName, parent.xmlFilename)
	local v16_ = getUserAttribute(node, "filename")
	if v16_ == nil then
		if self:loadEffectAttributes(nil, nil, node) then
			self:transformEffectNode(nil, nil, node)
			return self
		else
			Logging.xmlWarning(parent.xmlFile, "Failed to load effect from node \'%s\'", getName(node))
			return nil
		end
	else
		local v17_ = Utils.getFilename(v16_, self.baseDirectory)
		self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v17_, false, false, self.effectI3DFileLoaded, self, {
			["xmlFile"] = nil,
			["baseName"] = nil,
			["i3dMapping"] = nil,
			["filename"] = v17_,
			["node"] = node
		})
		return self
	end
end

-- Local values: xmlFile, baseName, i3dMapping, node
function Effect:effectI3DFileLoaded(i3dNode, failedReason, args)
	if i3dNode ~= 0 then
		local v21_ = args.xmlFile
		local v22_ = args.baseName
		local v23_ = args.i3dMapping
		local v24_ = args.node
		self.filename = args.filename
		if not self:loadEffectAttributes(v21_, v22_, v24_, i3dNode, v23_) then
			Logging.xmlWarning(v21_, "Failed to load effect from file \'%s\'", v22_)
		end
		self:transformEffectNode(v21_, v22_, v24_)
		delete(i3dNode)
	end
end

-- Local values: useSelfAsEffectNode, effect
function Effect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	local v31_ = Utils.getNoNil(Effect.getValue(xmlFile, key, node, "useSelfAsEffectNode"), false)
	self.prio = Utils.getNoNil(Effect.getValue(xmlFile, key, node, "prio"), 0)
	local v32_ = I3DUtil.indexToObject(Utils.getNoNil(node, self.rootNodes), Effect.getValue(xmlFile, key, node, "effectNode"), i3dMapping)
	if v32_ == nil then
		if v31_ then
			v32_ = node
		end
	end
	if v32_ == nil then
		self.node = Effect.getValue(xmlFile, key, node, "node", nil, i3dNode, i3dMapping)
		self.linkNode = I3DUtil.indexToObject(Utils.getNoNil(node, self.rootNodes), Effect.getValue(xmlFile, key, node, "linkNode"), i3dMapping)
		if self.linkNode == nil then
			if node == nil then
				Logging.xmlWarning(xmlFile, "LinkNode is nil in \'%s\'", key)
			else
				Logging.xmlWarning(xmlFile, "LinkNode is nil in node attribute \'%s\'", getName(node))
			end
			return false
		end
		if self.node == nil then
			if node == nil then
				Logging.xmlWarning(xmlFile, "Node is nil in \'%s\'", key)
			else
				Logging.xmlWarning(xmlFile, "Node is nil in node attribute \'%s\'", getName(node))
			end
			return false
		end
		if self.node ~= nil and self.linkNode ~= nil then
			link(self.linkNode, self.node)
		end
	else
		self.node = v32_
	end
	return true
end

-- Local values: x, y, z, rotX, rotY, rotZ, scaleX, scaleY, scaleZ
function Effect:transformEffectNode(xmlFile, key, node)
	local v37_, v38_, v39_ = Effect.getValue(xmlFile, key, node, "position")
	local v40_, v41_, v42_ = Effect.getValue(xmlFile, key, node, "rotation")
	local v43_, v44_, v45_ = Effect.getValue(xmlFile, key, node, "scale")
	if v37_ ~= nil and (v38_ ~= nil and v39_ ~= nil) then
		setTranslation(self.node, v37_, v38_, v39_)
	end
	if v40_ ~= nil and (v41_ ~= nil and v42_ ~= nil) then
		setRotation(self.node, v40_, v41_, v42_)
	end
	if v43_ ~= nil and (v44_ ~= nil and v45_ ~= nil) then
		setScale(self.node, v43_, v44_, v45_)
	end
	setVisibility(self.node, false)
end

-- Local values: i, listener
function Effect:delete()
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
		self.sharedLoadRequestId = nil
	end
	for v47_ = #self.deleteListeners, 1, -1 do
		local v48_ = self.deleteListeners[v47_]
		local v49_ = v48_.func
		local v50_ = v48_.args
		v49_(unpack(v50_))
		self.deleteListeners[v47_] = nil
	end
	self.parent = nil
end

function Effect:update(dt) end

function Effect:isRunning()
	return false
end

function Effect:setUpdateDistance(maxUpdateDistance)
	if self.parent == nil then
		return
	elseif self.parent.currentUpdateDistance ~= nil then
		if maxUpdateDistance == math.huge then
			maxUpdateDistance = nil
		end
		self.maxUpdateDistance = maxUpdateDistance
	end
end

function Effect:getAllowUpdate()
	return self.maxUpdateDistance == nil and true or self.parent.currentUpdateDistance < self.maxUpdateDistance
end

-- Local values: canTurnOn, i, restriction
function Effect:canStart()
	local v55_ = true
	for v56_ = #self.startRestriction, 1, -1 do
		local v57_ = self.startRestriction[v56_]
		if v55_ then
			local v58_ = v57_.func
			local v59_ = v57_.args
			v55_ = v58_(unpack(v59_))
		end
	end
	return v55_
end

function Effect:start()
	return false
end

function Effect:stop()
	return false
end

function Effect:reset() end

function Effect:getIsVisible()
	return true
end

function Effect:getIsFullyVisible()
	return true
end
function Effect.getValue(p60_, p61_, p62_, p63_, ...)
	if p62_ == nil then
		return p60_:getValue(p61_ .. "#" .. p63_, ...)
	else
		return getUserAttribute(p62_, p63_)
	end
end
function Effect.addDeleteListener(p64_, p65_, ...)
	local v66_ = p64_.deleteListeners
	table.insert(v66_, {
		["func"] = p65_,
		["args"] = { ... }
	})
end
function Effect.addStartRestriction(p67_, p68_, ...)
	local v69_ = p67_.startRestriction
	table.insert(v69_, {
		["func"] = p68_,
		["args"] = { ... }
	})
end

function Effect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#filename", "Effect from external i3d")
	schema:register(XMLValueType.BOOL, basePath .. "#shared", "Load i3d file as shared file")
	schema:register(XMLValueType.BOOL, basePath .. "#useSelfAsEffectNode", "Use root node as effect node", false)
	schema:register(XMLValueType.INT, basePath .. "#prio", "Prio", 0)
	schema:register(XMLValueType.STRING, basePath .. "#effectNode", "Effect node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Effect in i3d node")
	schema:register(XMLValueType.STRING, basePath .. "#linkNode", "Link node")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#position", "Translation")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. "#rotation", "Rotation")
	schema:register(XMLValueType.VECTOR_SCALE, basePath .. "#scale", "Scale")
end
