-- Local values: InlineBaleSingle_mt
InlineBaleSingle = {}
local InlineBaleSingle_mt = Class(InlineBaleSingle, Bale)
InitStaticObjectClass(InlineBaleSingle, "InlineBaleSingle")

-- Upvalues: InlineBaleSingle_mt
-- Local values: self
function InlineBaleSingle.new(isServer, isClient, customMt)
	-- upvalues: (copy) InlineBaleSingle_mt
	local v5_ = Bale.new(isServer, isClient, customMt or InlineBaleSingle_mt)
	registerObjectClassName(v5_, "InlineBaleSingle")
	v5_.connectedInlineBale = nil
	return v5_
end

function InlineBaleSingle:getBaleSupportsBaleLoader()
	return false
end

function InlineBaleSingle:getCanBeOpened()
	return false
end

function InlineBaleSingle:setConnectedInlineBale(inlineBale)
	self.connectedInlineBale = inlineBale
end

function InlineBaleSingle:getConnectedInlineBale()
	return self.connectedInlineBale
end

-- Local values: rootNode, sharedLoadRequestId, startNode, endNode, skinnedMesh, translation, r, g, b, _
function InlineBaleSingle:setConnector(connectedBale, filename, axis, offset)
	local v14_ = NetworkUtil.convertFromNetworkFilename(filename)
	local v15_, v16_ = g_i3DManager:loadSharedI3DFile(v14_, false, false)
	if v15_ == 0 then
		return false
	end
	local v17_ = getChildAt(v15_, 0)
	local v18_ = getChildAt(v15_, 1)
	local v19_ = getChildAt(v15_, 2)
	link(connectedBale.nodeId, v18_)
	link(self.nodeId, v17_)
	link(self.nodeId, v19_)
	local v20_ = {
		0,
		0,
		0,
		[axis] = offset
	}
	setTranslation(v17_, unpack(v20_))
	v20_[axis] = -offset
	setTranslation(v18_, unpack(v20_))
	delete(v15_)
	self.inlineConnector = {
		["filename"] = v14_,
		["sharedLoadRequestId"] = v16_,
		["mesh"] = v19_,
		["joint1"] = v17_,
		["joint2"] = v18_,
		["isDirty"] = true
	}
	setVisibility(v19_, self.wrappingState > 0)
	if getHasShaderParameter(v19_, "colorScale") then
		local v21_ = connectedBale.wrappingColor
		local v22_, v23_, v24_, _ = unpack(v21_)
		setShaderParameter(v19_, "colorScale", v22_, v23_, v24_, 1, false)
	end
	if getHasShaderParameter(v19_, "scratches_dirt_snow_wetness") then
		setShaderParameter(v19_, "scratches_dirt_snow_wetness", 0, 0, 0, 0, false)
	end
	return true
end

function InlineBaleSingle:setConnectorVisibility(state)
	if self:getHasConnector() then
		setVisibility(self.inlineConnector.mesh, state)
	end
end

function InlineBaleSingle:getHasConnector()
	return self.inlineConnector ~= nil
end

-- Local values: connector
function InlineBaleSingle:removeConnector()
	local v29_ = self.inlineConnector
	if v29_ ~= nil then
		if entityExists(v29_.joint1) then
			delete(v29_.joint1)
		end
		if entityExists(v29_.joint2) then
			delete(v29_.joint2)
		end
		if entityExists(v29_.mesh) then
			delete(v29_.mesh)
		end
		if v29_.sharedLoadRequestId ~= nil then
			g_i3DManager:releaseSharedI3DFile(v29_.sharedLoadRequestId)
		end
		self.inlineConnector = nil
	end
end

function InlineBaleSingle:setWrappingState(wrappingState, noEventSend)
	self:setConnectorVisibility(wrappingState > 0)
	InlineBaleSingle:superClass().setWrappingState(self, wrappingState, noEventSend)
end
