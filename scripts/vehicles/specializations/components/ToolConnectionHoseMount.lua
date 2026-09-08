-- Local values: ToolConnectionHoseMount_mt
ToolConnectionHoseMount = {}
local ToolConnectionHoseMount_mt = Class(ToolConnectionHoseMount)

-- Upvalues: ToolConnectionHoseMount_mt
-- Local values: self
function ToolConnectionHoseMount.new(vehicle, customMt)
	-- upvalues: (copy) ToolConnectionHoseMount_mt
	local v4_ = customMt or ToolConnectionHoseMount_mt
	local v5_ = setmetatable({}, v4_)
	v5_.vehicle = vehicle
	v5_.components = {}
	v5_.i3dMappings = {}
	return v5_
end

function ToolConnectionHoseMount:delete()
	if self.xmlFile ~= nil then
		self.xmlFile:delete()
		self.xmlFile = nil
	end
	if self.node ~= nil then
		delete(self.node)
		self.node = nil
	end
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
		self.sharedLoadRequestId = nil
	end
end

function ToolConnectionHoseMount:setCallback(callback, callbackTarget)
	self.callback = callback
	self.callbackTarget = callbackTarget
end

function ToolConnectionHoseMount:onFinished(success)
	if self.callback ~= nil then
		if self.callbackTarget ~= nil then
			self.callback(self.callbackTarget, success)
			return
		end
		self.callback(success)
	end
end

-- Local values: toolConnectionHose
function ToolConnectionHoseMount:setReferenceTargets(startTarget, endTarget)
	self.startTarget = startTarget
	self.endTarget = endTarget
	self.parentToolConnectionHose = self.vehicle.spec_connectionHoses.targetNodeToToolConnection[startTarget.index]
end

function ToolConnectionHoseMount:setLinkNode(linkNode, x, y, z, rx, ry, rz)
	self.linkNode = linkNode
	self.translation = { x or 0, y or 0, z or 0 }
	self.rotation = { rx or 0, ry or 0, rz or 0 }
end

-- Local values: filename
function ToolConnectionHoseMount:loadFromXML(xmlFilename, baseDirectory)
	if self.startTarget == nil or self.endTarget == nil then
		Logging.warning("Missing start or end target for tool connection hose mount!")
		self:onFinished(false)
		return false
	end
	if self.linkNode == nil then
		Logging.warning("Missing link node for tool connection hose mount!")
		self:onFinished(false)
		return false
	end
	self.xmlFile = XMLFile.loadIfExists("toolConnectionHoseMount", xmlFilename, ToolConnectionHoseMount.xmlSchema)
	if self.xmlFile == nil then
		Logging.warning("Failed to load tool connection hose mount XML file: %s", xmlFilename)
		self:onFinished(false)
		return false
	end
	local v26_ = self.xmlFile:getValue("toolConnectionHoseMount.filename")
	if v26_ ~= nil then
		self.filename = Utils.getFilename(v26_, baseDirectory)
		if self.vehicle == nil or self.vehicle.loadSubSharedI3DFile == nil then
			self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.filename, false, false, self.onI3DLoaded, self, nil)
		else
			self.sharedLoadRequestId = self.vehicle:loadSubSharedI3DFile(self.filename, false, false, self.onI3DLoaded, self, nil)
		end
		return true
	end
	Logging.xmlWarning(self.xmlFile, "Missing toolConnectionHoseMount i3d filename!")
	self.xmlFile:delete()
	self.xmlFile = nil
	self:onFinished(false)
	return false
end

function ToolConnectionHoseMount:onI3DLoaded(i3dNode, failedReason, args)
	if i3dNode ~= 0 then
		I3DUtil.loadI3DComponents(i3dNode, self.components)
		I3DUtil.loadI3DMapping(self.xmlFile, "toolConnectionHoseMount", self.components, self.i3dMappings)
		self.node = self.xmlFile:getValue("toolConnectionHoseMount.rootNode#node", "0", self.components, self.i3dMappings)
		if self.node ~= nil then
			self.length = self.xmlFile:getValue("toolConnectionHoseMount.rootNode#length", 3)
			self.targetNodes = {}
			self.xmlFile:iterate("toolConnectionHoseMount.target", function(_, p29_)
				-- upvalues: (copy) self
				local v30_ = {
					["backNode"] = self.xmlFile:getValue(p29_ .. "#backNode", nil, self.components, self.i3dMappings),
					["frontNode"] = self.xmlFile:getValue(p29_ .. "#frontNode", nil, self.components, self.i3dMappings),
					["mountingNode"] = self.xmlFile:getValue(p29_ .. "#mountingNode", nil, self.components, self.i3dMappings)
				}
				if v30_.backNode == nil or v30_.frontNode == nil then
					Logging.xmlWarning(self.xmlFile, "Missing back or front node for tool connection hose mount target at \'%s\'!", p29_)
					return
				else
					v30_.typeName = self.xmlFile:getValue(p29_ .. "#typeName")
					if v30_.typeName == nil then
						Logging.xmlWarning(self.xmlFile, "Missing type name for tool connection hose mount target at \'%s\'!", p29_)
					else
						v30_.createHose = self.xmlFile:getValue(p29_ .. "#createHose", true)
						v30_.moveNodes = self.xmlFile:getValue(p29_ .. "#moveNodes", true)
						v30_.hoseOffset = self.xmlFile:getValue(p29_ .. "#hoseOffset", 0)
						local v31_ = self.targetNodes
						table.insert(v31_, v30_)
					end
				end
			end)
			self.additionalHoses = {}
			self.xmlFile:iterate("toolConnectionHoseMount.hose", function(_, p32_)
				-- upvalues: (copy) self
				local v33_ = {
					["startNode"] = self.xmlFile:getValue(p32_ .. "#startNode", nil, self.components, self.i3dMappings),
					["endNode"] = self.xmlFile:getValue(p32_ .. "#endNode", nil, self.components, self.i3dMappings)
				}
				if v33_.startNode == nil or v33_.endNode == nil then
					Logging.xmlWarning(self.xmlFile, "Missing start or end node for tool connection hose mount hose at \'%s\'!", p32_)
				else
					local v34_ = self.additionalHoses
					table.insert(v34_, v33_)
				end
			end)
			self.adjustNodes = {}
			self.xmlFile:iterate("toolConnectionHoseMount.adjustNodes", function(_, p35_)
				-- upvalues: (copy) self
				local v36_ = {
					["node"] = self.xmlFile:getValue(p35_ .. "#node", nil, self.components, self.i3dMappings)
				}
				if v36_.node ~= nil then
					v36_.startTranslation = { getTranslation(v36_.node) }
					local v37_ = self.adjustNodes
					table.insert(v37_, v36_)
				end
			end)
			self.scaleNodes = {}
			self.xmlFile:iterate("toolConnectionHoseMount.scaleNodes", function(_, p38_)
				-- upvalues: (copy) self
				local v39_ = {
					["node"] = self.xmlFile:getValue(p38_ .. "#node", nil, self.components, self.i3dMappings)
				}
				if v39_.node ~= nil then
					local v40_ = self.scaleNodes
					table.insert(v40_, v39_)
				end
			end)
			link(self.linkNode, self.node)
			setTranslation(self.node, self.translation[1], self.translation[2], self.translation[3])
			setRotation(self.node, self.rotation[1], self.rotation[2], self.rotation[3])
			self:createToolConnectionHoses()
			if self.lengthToSet ~= nil then
				self:setLength(self.lengthToSet)
			end
		end
		delete(i3dNode)
	end
	self.xmlFile:delete()
	self.xmlFile = nil
	self:onFinished(self.node ~= nil)
end

-- Local values: scale, _, adjustNode, _, scaleNode
function ToolConnectionHoseMount:setLength(length)
	if self.node == nil then
		self.lengthToSet = length
	else
		self.lengthToSet = nil
		local v43_ = length / self.length
		for _, v44_ in ipairs(self.adjustNodes) do
			setTranslation(v44_.node, v44_.startTranslation[1], v44_.startTranslation[2], v44_.startTranslation[3] * v43_)
		end
		for _, v45_ in ipairs(self.scaleNodes) do
			setScale(v45_.node, 1, 1, v43_)
		end
	end
end

-- Local values: spec, hoseTarget
function ToolConnectionHoseMount:addHoseTarget(node, sourceTarget, newType)
	local v50_ = self.vehicle.spec_connectionHoses
	local v51_ = {
		["node"] = node,
		["attacherJointIndices"] = sourceTarget.attacherJointIndices,
		["type"] = newType,
		["straighteningFactor"] = sourceTarget.straighteningFactor,
		["adapterName"] = sourceTarget.adapterName,
		["adapter"] = {}
	}
	v51_.adapter.node = node
	v51_.adapter.refNode = node
	v51_.objectChanges = {}
	local v52_ = v50_.targetNodes
	table.insert(v52_, v51_)
	v51_.index = #v50_.targetNodes
	if v50_.targetNodesByType[v51_.type] == nil then
		v50_.targetNodesByType[v51_.type] = {}
	end
	local v53_ = v50_.targetNodesByType[v51_.type]
	table.insert(v53_, v51_)
	return v51_.index
end

-- Local values: spec, _, target, frontTargetIndex, backTargetIndex, newToolConnectionHose
function ToolConnectionHoseMount:createToolConnectionHoses()
	local v55_ = self.vehicle.spec_connectionHoses
	for _, v56_ in ipairs(self.targetNodes) do
		local v57_ = {
			["startTargetNodeIndex"] = self:addHoseTarget(v56_.frontNode, self.startTarget, v56_.typeName),
			["endTargetNodeIndex"] = self:addHoseTarget(v56_.backNode, self.endTarget, v56_.typeName),
			["mountingNode"] = v56_.mountingNode or self.node,
			["moveNodes"] = v56_.moveNodes,
			["additionalHose"] = v56_.createHose,
			["additionalHoseOffset"] = v56_.hoseOffset,
			["parentToolConnectionHose"] = self.parentToolConnectionHose,
			["objectChanges"] = {},
			["objectChangesTarget"] = self.vehicle,
			["additionalHoses"] = self.additionalHoses
		}
		setVisibility(v57_.mountingNode, false)
		local v58_ = v55_.toolConnectorHoses
		table.insert(v58_, v57_)
		v55_.targetNodeToToolConnection[v57_.startTargetNodeIndex] = v57_
		v55_.targetNodeToToolConnection[v57_.endTargetNodeIndex] = v57_
	end
end

function ToolConnectionHoseMount.registerExternalXMLPaths(schema)
	schema:register(XMLValueType.STRING, "toolConnectionHoseMount.filename", "Path to i3d file", nil, true)
	schema:register(XMLValueType.NODE_INDEX, "toolConnectionHoseMount.rootNode#node", "Node index", "0")
	schema:register(XMLValueType.FLOAT, "toolConnectionHoseMount.rootNode#length", "Length of the mount inside the file", 3)
	schema:register(XMLValueType.NODE_INDEX, "toolConnectionHoseMount.target(?)#backNode", "Node for the back tool to connection to")
	schema:register(XMLValueType.NODE_INDEX, "toolConnectionHoseMount.target(?)#frontNode", "Node for the front tool to connection to")
	schema:register(XMLValueType.NODE_INDEX, "toolConnectionHoseMount.target(?)#mountingNode", "Custom node that is hidden when not active")
	schema:register(XMLValueType.STRING, "toolConnectionHoseMount.target(?)#typeName", "Name of the hose type")
	schema:register(XMLValueType.BOOL, "toolConnectionHoseMount.target(?)#createHose", "Create local hose between the front and back node")
	schema:register(XMLValueType.BOOL, "toolConnectionHoseMount.target(?)#moveNodes", "Move nodes up by the radius of the hose")
	schema:register(XMLValueType.FLOAT, "toolConnectionHoseMount.target(?)#hoseOffset", "Offset for the hose creation", 0)
	schema:register(XMLValueType.NODE_INDEX, "toolConnectionHoseMount.hose(?)#startNode", "Start node of the local hose")
	schema:register(XMLValueType.NODE_INDEX, "toolConnectionHoseMount.hose(?)#endNode", "End node of the local hose")
	schema:register(XMLValueType.NODE_INDEX, "toolConnectionHoseMount.adjustNodes(?)#node", "Node that is adjusted to the length of the mount")
	schema:register(XMLValueType.NODE_INDEX, "toolConnectionHoseMount.scaleNodes(?)#node", "Node that is scaled based on the length of the mount")
	I3DUtil.registerI3dMappingXMLPaths(schema, "toolConnectionHoseMount")
end
g_xmlManager:addCreateSchemaFunction(function()
	ToolConnectionHoseMount.xmlSchema = XMLSchema.new("toolConnectionHoseMount")
end)
g_xmlManager:addInitSchemaFunction(function()
	ToolConnectionHoseMount.registerExternalXMLPaths(ToolConnectionHoseMount.xmlSchema)
end)
