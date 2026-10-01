NetworkUtil = {}
function NetworkUtil.getObject(id)
	if g_server ~= nil then
		return g_server:getObject(id)
	else
		return g_client:getObject(id)
	end
end
function NetworkUtil.getObjectId(object)
	if g_server ~= nil then
		return g_server:getObjectId(object)
	else
		return g_client:getObjectId(object)
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
function NetworkUtil.createWorldPositionCompressionParams(worldSize, worldOffset, scale)
	local maxValueScaled = worldSize / scale
	local params = { scale = scale, worldSize = worldSize, worldOffset = worldOffset, numBits = MathUtil.getNumRequiredBits(maxValueScaled) }
	return params
end
function NetworkUtil.simWriteCompressedWorldPosition(pos, params)
	local scaledPos = math.clamp(pos + params.worldOffset, 0, params.worldSize) / params.scale
	return math.floor(scaledPos) * params.scale - params.worldOffset
end
function NetworkUtil.writeCompressedWorldPosition(streamId, pos, params)
	local scaledPos = math.clamp(pos + params.worldOffset, 0, params.worldSize) / params.scale
	streamWriteUIntN(streamId, math.floor(scaledPos), params.numBits)
end
function NetworkUtil.getIsWorldPositionInCompressionRange(pos, params)
	return -params.worldOffset <= pos and pos <= params.worldSize - params.worldOffset
end
function NetworkUtil.readCompressedWorldPosition(streamId, params)
	return streamReadUIntN(streamId, params.numBits) * params.scale - params.worldOffset
end
function NetworkUtil.writeCompressedAngle(streamId, angle)
	angle = angle % 6.283185307179586
	streamWriteUIntN(streamId, math.floor(angle * 2047.5 / 3.141592653589793), 12)
end
function NetworkUtil.readCompressedAngle(streamId)
	local angle = streamReadUIntN(streamId, 12) / 2047.5 * 3.141592653589793
	return angle
end
function NetworkUtil.writeCompressedRange(streamId, value, minValue, maxValue, numBits)
	local maxSendValue = 2 ^ numBits - 1
	if minValue == maxValue then
		value = 0
	else
		value = (math.clamp(value, minValue, maxValue) - minValue) / (maxValue - minValue)
	end
	streamWriteUIntN(streamId, math.floor(value * maxSendValue), numBits)
end
function NetworkUtil.readCompressedRange(streamId, minValue, maxValue, numBits)
	local maxSendValue = 2 ^ numBits - 1
	local value = streamReadUIntN(streamId, numBits) / maxSendValue * (maxValue - minValue) + minValue
	return value
end
function NetworkUtil.writeCompressedPercentages(streamId, floatValue, numBits)
	numBits = numBits or 7
	local maxBitValue = 2 ^ numBits - 1
	local value = math.clamp(floatValue * maxBitValue, 0, maxBitValue)
	streamWriteUIntN(streamId, value, numBits)
end
function NetworkUtil.readCompressedPercentages(streamId, numBits)
	numBits = numBits or 7
	local value = streamReadUIntN(streamId, numBits)
	local maxBitValue = 2 ^ numBits - 1
	return value / maxBitValue
end
function NetworkUtil.convertToNetworkFilename(filename)
	local modFilename, isMod, isDlc, _ = Utils.removeModDirectory(string.trim(filename))
	if isMod then
		filename = "$moddir$" .. modFilename
		return filename
	else
		if isDlc then
			filename = "$pdlcdir$" .. modFilename
		end
		return filename
	end
end
function NetworkUtil.convertFromNetworkFilename(filename)
	local filenameLower = string.lower(filename)
	local modPrefix = "$moddir$"
	local mapPrefix = "$mapdir$"
	if string.startsWith(filenameLower, "$moddir$") then
		local startIndex = 9
		local modName = filename
		local f, l = string.find(filename, "/", 9)
		if f ~= nil and (l ~= nil and startIndex < f - 1) then
			modName = string.sub(filename, startIndex, f - 1)
		end
		local modDir = g_modNameToDirectory[modName]
		if modDir ~= nil then
			filename = modDir .. string.sub(filename, f + 1)
			return filename
		else
			filename = g_modsDirectory .. modName
			return filename
		end
	elseif string.startsWith(filenameLower, "$mapdir$") then
		local mapDir = g_currentMission.missionInfo.baseDirectory
		local startIndex = 9
		filename = Utils.getFilename(string.sub(filename, 10), mapDir)
		return filename
	else
		local pdlcPrefix = "$pdlcdir"
		if string.startsWith(filenameLower, "$pdlcdir") then
			local startIndex = nil
			local prefixIndex = 9
			if string.sub(filenameLower, prefixIndex, prefixIndex) == "$" then
				startIndex = prefixIndex + 1
			else
				prefixIndex = prefixIndex + 1
				if string.sub(filenameLower, prefixIndex, prefixIndex) == "$" then
					startIndex = prefixIndex + 1
				end
			end
			if startIndex ~= nil then
				local f, l = string.find(filename, "/", startIndex)
				if f ~= nil and (l ~= nil and startIndex < f - 1) then
					local modName = string.sub(filename, startIndex, f - 1)
					if g_dlcModNameHasPrefix[modName] then
						modName = g_uniqueDlcNamePrefix .. modName
					end
					local modDir = g_modNameToDirectory[modName]
					if modDir ~= nil then
						filename = modDir .. string.sub(filename, f + 1)
					end
				end
			end
		end
		return filename
	end
end
function NetworkUtil.packBits(...)
	local args = { ... }
	local result = 0
	for i = 1, #args do
		local currentBit = args[i]
		if currentBit then
			result = result + 2 ^ (i - 1)
		end
	end
	return result
end
local calculateBitVectorArity = function(number)
	assert(0 <= number)
	local n = 1
	local arity = 1
	while n <= number do
		n = 2 * n
		arity = arity + 1
	end
	arity = arity - 1
	return arity
end
function NetworkUtil.readBits(number, arity)
	if arity == nil then
		if number == 0 then
			return
		end
		local number = number
		assert(0 <= number)
		local n = 1
		local arity = 1
		while n <= number do
			n = 2 * n
			arity = arity + 1
		end
		arity = arity - 1
		arity = arity
	end
	local result = {}
	for i = arity, 1, -1 do
		local value = 2 ^ (i - 1)
		local isBitSet = value <= number
		result[i] = isBitSet
		if isBitSet then
			number = number - value
		end
	end
	return result
end
function NetworkUtil.readBit(number, bitPosition, arity)
	if arity == nil then
		if number == 0 then
			return
		end
		local number = number
		assert(0 <= number)
		local n = 1
		local arity = 1
		while n <= number do
			n = 2 * n
			arity = arity + 1
		end
		arity = arity - 1
		arity = arity
	end
	for i = arity - 1, bitPosition + 1, -1 do
		local value = 2 ^ i
		local isBitSet = value <= number
		if isBitSet then
			number = number - value
		end
	end
	local value = 2 ^ bitPosition
	return value <= number
end
function NetworkUtil.writeBit(number, bitPosition, bitValue, arity)
	if arity == nil then
		if number == 0 then
			return
		end
		local number = number
		assert(0 <= number)
		local n = 1
		local arity = 1
		while n <= number do
			n = 2 * n
			arity = arity + 1
		end
		arity = arity - 1
		arity = arity
	end
	local isBitSet = NetworkUtil.readBit(number, bitPosition, arity)
	local bitNumber = 2 ^ bitPosition
	if isBitSet then
		number = number - bitNumber
	end
	if bitValue then
		number = number + bitNumber
	end
	return number
end
function NetworkUtil.writeCompressedColor(streamId, r, g, b)
	streamWriteUInt8(streamId, r * 255)
	streamWriteUInt8(streamId, g * 255)
	streamWriteUInt8(streamId, b * 255)
end
function NetworkUtil.readCompressedColor(streamId)
	local r = streamReadUInt8(streamId) / 255
	local g = streamReadUInt8(streamId) / 255
	local b = streamReadUInt8(streamId) / 255
	return r, g, b
end
