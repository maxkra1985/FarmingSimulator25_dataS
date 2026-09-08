-- Local values: calculateBitVectorArity
NetworkUtil = {}

function NetworkUtil.getObject(id)
	if g_server == nil then
		return g_client:getObject(id)
	else
		return g_server:getObject(id)
	end
end

function NetworkUtil.getObjectId(object)
	if g_server == nil then
		return g_client:getObjectId(object)
	else
		return g_server:getObjectId(object)
	end
end

function NetworkUtil.writeNodeObject(streamId, object)
	if g_showDevelopmentWarnings then
		if object == nil then
			Logging.devError("Trying to write nil object")
			printCallstack()
		elseif not object.isRegistered then
			Logging.devError("Trying to write unregistered object")
			printCallstack()
		end
	end
	NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(object))
end

function NetworkUtil.readNodeObject(streamId)
	return NetworkUtil.getObject(NetworkUtil.readNodeObjectId(streamId))
end

function NetworkUtil.writeNodeObjectId(streamId, objectId)
	streamWriteUIntN(streamId, objectId or 0, NetworkNode.OBJECT_SEND_NUM_BITS)
end

function NetworkUtil.readNodeObjectId(streamId)
	return streamReadUIntN(streamId, NetworkNode.OBJECT_SEND_NUM_BITS)
end

-- Local values: maxValueScaled, params
function NetworkUtil.createWorldPositionCompressionParams(worldSize, worldOffset, scale)
	local v12_ = worldSize / scale
	return {
		["scale"] = scale,
		["worldSize"] = worldSize,
		["worldOffset"] = worldOffset,
		["numBits"] = MathUtil.getNumRequiredBits(v12_)
	}
end

-- Local values: scaledPos
function NetworkUtil.simWriteCompressedWorldPosition(pos, params)
	local v15_ = pos + params.worldOffset
	local v16_ = params.worldSize
	local v17_ = math.clamp(v15_, 0, v16_) / params.scale
	return math.floor(v17_) * params.scale - params.worldOffset
end

-- Local values: scaledPos
function NetworkUtil.writeCompressedWorldPosition(streamId, pos, params)
	local v21_ = pos + params.worldOffset
	local v22_ = params.worldSize
	local v23_ = math.clamp(v21_, 0, v22_) / params.scale
	streamWriteUIntN(streamId, math.floor(v23_), params.numBits)
end

function NetworkUtil.getIsWorldPositionInCompressionRange(pos, params)
	local v26_
	if -params.worldOffset <= pos then
		v26_ = pos <= params.worldSize - params.worldOffset
	else
		v26_ = false
	end
	return v26_
end

function NetworkUtil.readCompressedWorldPosition(streamId, params)
	return streamReadUIntN(streamId, params.numBits) * params.scale - params.worldOffset
end

function NetworkUtil.writeCompressedAngle(streamId, angle)
	local v31_ = angle % 6.283185307179586
	local v32_ = streamWriteUIntN
	local v33_ = v31_ * 2047.5 / 3.141592653589793
	v32_(streamId, math.floor(v33_), 12)
end

-- Local values: angle
function NetworkUtil.readCompressedAngle(streamId)
	return streamReadUIntN(streamId, 12) / 2047.5 * 3.141592653589793
end

-- Local values: maxSendValue
function NetworkUtil.writeCompressedRange(streamId, value, minValue, maxValue, numBits)
	local v40_ = 2 ^ numBits - 1
	local v41_ = minValue == maxValue and 0 or (math.clamp(value, minValue, maxValue) - minValue) / (maxValue - minValue)
	local v42_ = streamWriteUIntN
	local v43_ = v41_ * v40_
	v42_(streamId, math.floor(v43_), numBits)
end

-- Local values: maxSendValue, value
function NetworkUtil.readCompressedRange(streamId, minValue, maxValue, numBits)
	local v48_ = 2 ^ numBits - 1
	return streamReadUIntN(streamId, numBits) / v48_ * (maxValue - minValue) + minValue
end

-- Local values: maxBitValue, value
function NetworkUtil.writeCompressedPercentages(streamId, floatValue, numBits)
	local v52_ = numBits or 7
	local v53_ = 2 ^ v52_ - 1
	local v54_ = floatValue * v53_
	local v55_ = math.clamp(v54_, 0, v53_)
	streamWriteUIntN(streamId, v55_, v52_)
end

-- Local values: value, maxBitValue
function NetworkUtil.readCompressedPercentages(streamId, numBits)
	local v58_ = numBits or 7
	return streamReadUIntN(streamId, v58_) / (2 ^ v58_ - 1)
end

-- Local values: modFilename, isMod, isDlc, _
function NetworkUtil.convertToNetworkFilename(filename)
	local v60_, v61_, v62_, _ = Utils.removeModDirectory(string.trim(filename))
	if v61_ then
		return "$moddir$" .. v60_
	end
	if v62_ then
		filename = "$pdlcdir$" .. v60_
	end
	return filename
end

-- Local values: filenameLower, modPrefix, mapPrefix, startIndex, modName, f, l, modDir, mapDir, startIndex, pdlcPrefix, startIndex, prefixIndex, f, l, modName, modDir
function NetworkUtil.convertFromNetworkFilename(filename)
	local v64_ = string.lower(filename)
	if string.startsWith(v64_, "$moddir$") then
		local v65_ = 9
		local v66_, v67_ = string.find(filename, "/", 9)
		local v68_
		if v66_ == nil or (v67_ == nil or v65_ >= v66_ - 1) then
			v68_ = filename
		else
			local v69_ = v66_ - 1
			v68_ = string.sub(filename, v65_, v69_)
		end
		local v70_ = g_modNameToDirectory[v68_]
		if v70_ == nil then
			return g_modsDirectory .. v68_
		end
		local v71_ = v66_ + 1
		return v70_ .. string.sub(filename, v71_)
	elseif string.startsWith(v64_, "$mapdir$") then
		local v72_ = g_currentMission.missionInfo.baseDirectory
		return Utils.getFilename(string.sub(filename, 10), v72_)
	else
		if string.startsWith(v64_, "$pdlcdir") then
			local v73_ = nil
			local v74_ = 9
			if string.sub(v64_, v74_, v74_) == "$" then
				v73_ = v74_ + 1
			else
				local v75_ = v74_ + 1
				if string.sub(v64_, v75_, v75_) == "$" then
					v73_ = v75_ + 1
				end
			end
			if v73_ ~= nil then
				local v76_, v77_ = string.find(filename, "/", v73_)
				if v76_ ~= nil and (v77_ ~= nil and v73_ < v76_ - 1) then
					local v78_ = v76_ - 1
					local v79_ = string.sub(filename, v73_, v78_)
					if g_dlcModNameHasPrefix[v79_] then
						v79_ = g_uniqueDlcNamePrefix .. v79_
					end
					local v80_ = g_modNameToDirectory[v79_]
					if v80_ ~= nil then
						local v81_ = v76_ + 1
						filename = v80_ .. string.sub(filename, v81_)
					end
				end
			end
		end
		return filename
	end
end
function NetworkUtil.packBits(...)
	local v82_ = { ... }
	local v83_ = 0
	for v84_ = 1, #v82_ do
		if v82_[v84_] then
			v83_ = v83_ + 2 ^ (v84_ - 1)
		end
	end
	return v83_
end

-- Local values: number, n, arity, result, i, value, isBitSet
function NetworkUtil.readBits(number, arity)
	local v87_
	if arity == nil then
		if number == 0 then
			return
		end
		local v88_ = number >= 0
		assert(v88_)
		v87_ = number
		local v89_ = 1
		local v90_ = 1
		while v89_ <= number do
			v89_ = 2 * v89_
			v90_ = v90_ + 1
		end
		arity = v90_ - 1
	else
		v87_ = number
	end
	local v91_ = {}
	for v92_ = arity, 1, -1 do
		local v93_ = 2 ^ (v92_ - 1)
		local v94_ = v93_ <= v87_
		v91_[v92_] = v94_
		if v94_ then
			v87_ = v87_ - v93_
		end
	end
	return v91_
end

-- Local values: number, n, arity, i, value, isBitSet, value
function NetworkUtil.readBit(number, bitPosition, arity)
	local v98_
	if arity == nil then
		if number == 0 then
			return
		end
		local v99_ = number >= 0
		assert(v99_)
		v98_ = number
		local v100_ = 1
		local v101_ = 1
		while v100_ <= number do
			v100_ = 2 * v100_
			v101_ = v101_ + 1
		end
		arity = v101_ - 1
	else
		v98_ = number
	end
	for v102_ = arity - 1, bitPosition + 1, -1 do
		local v103_ = 2 ^ v102_
		if v103_ <= v98_ then
			v98_ = v98_ - v103_
		end
	end
	return 2 ^ bitPosition <= v98_
end

-- Local values: number, n, arity, isBitSet, bitNumber
function NetworkUtil.writeBit(number, bitPosition, bitValue, arity)
	local v108_
	if arity == nil then
		if number == 0 then
			return
		end
		local v109_ = number >= 0
		assert(v109_)
		v108_ = number
		local v110_ = 1
		local v111_ = 1
		while v110_ <= number do
			v110_ = 2 * v110_
			v111_ = v111_ + 1
		end
		arity = v111_ - 1
	else
		v108_ = number
	end
	local v112_ = NetworkUtil.readBit(v108_, bitPosition, arity)
	local v113_ = 2 ^ bitPosition
	if v112_ then
		v108_ = v108_ - v113_
	end
	if bitValue then
		v108_ = v108_ + v113_
	end
	return v108_
end

function NetworkUtil.writeCompressedColor(streamId, r, g, b)
	streamWriteUInt8(streamId, r * 255)
	streamWriteUInt8(streamId, g * 255)
	streamWriteUInt8(streamId, b * 255)
end

-- Local values: r, g, b
function NetworkUtil.readCompressedColor(streamId)
	return streamReadUInt8(streamId) / 255, streamReadUInt8(streamId) / 255, streamReadUInt8(streamId) / 255
end
