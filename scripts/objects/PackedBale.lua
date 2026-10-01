PackedBale = {}
PackedBale.MAX_UNPACK_DISTANCE = 4
source("dataS/scripts/events/BaleUnpackEvent.lua")
local PackedBale_mt = Class(PackedBale, Bale)
InitStaticObjectClass(PackedBale, "PackedBale")
function PackedBale.new(isServer, isClient, customMt)
	local self = Bale.new(isServer, isClient, customMt or PackedBale_mt)
	registerObjectClassName(self, "PackedBale")
	self.singleBaleNodes = {}
	self.packedBaleActivatable = PackedBaleActivatable.new(self)
	self.maxUnpackDistance = PackedBale.MAX_UNPACK_DISTANCE
	return self
end
function PackedBale:delete()
	g_currentMission.activatableObjectsSystem:removeActivatable(self.packedBaleActivatable)
	PackedBale:superClass().delete(self)
end
function PackedBale:loadBaleAttributesFromXML(xmlFile)
	if not PackedBale:superClass().loadBaleAttributesFromXML(self, xmlFile) then
		return false
	else
		self.singleBaleFilename = xmlFile:getValue("bale.packedBale#singleBale")
		self.singleBaleFilename = Utils.getFilename(self.singleBaleFilename, self.baseDirectory)
		if self.singleBaleFilename == nil or not fileExists(self.singleBaleFilename) then
			Logging.xmlError(xmlFile, "Could not find single bale reference for bale (%s)", self.singleBaleFilename)
			return false
		end
		xmlFile:iterate("bale.packedBale.singleBale", function(_, key)
			local node = xmlFile:getValue(key .. "#node", nil, self.nodeId)
			if node ~= nil then
				table.insert(self.singleBaleNodes, node)
			end
		end)
		g_currentMission.activatableObjectsSystem:addActivatable(self.packedBaleActivatable)
		return true
	end
end
function PackedBale:unpack(noEventSend)
	g_currentMission.activatableObjectsSystem:removeActivatable(self.packedBaleActivatable)
	if self.isServer then
		for i = 1, #self.singleBaleNodes do
			local singleBaleNode = self.singleBaleNodes[i]
			if 1 < self.fillLevel then
				local baleObject = Bale.new(self.isServer, self.isClient)
				local x, y, z = getWorldTranslation(singleBaleNode)
				local rx, ry, rz = getWorldRotation(singleBaleNode)
				if baleObject:loadFromConfigXML(self.singleBaleFilename, x, y, z, rx, ry, rz) then
					baleObject:setFillType(self.fillType)
					baleObject:setFillLevel(math.min(self.fillLevel, baleObject:getCapacity()))
					baleObject:setOwnerFarmId(self.ownerFarmId, true)
					baleObject:register()
					self.fillLevel = self.fillLevel - baleObject:getFillLevel()
				end
			end
		end
		self:delete()
	else
		g_client:getServerConnection():sendEvent(BaleUnpackEvent.new(self))
	end
end
function PackedBale:getCanInteract()
	local x1, y1, z1 = self:getInteractionPosition()
	if x1 ~= nil then
		local x2, y2, z2 = getWorldTranslation(self.nodeId)
		local distance = MathUtil.vector3Length(x1 - x2, y1 - y2, z1 - z2)
		if distance < self.maxUnpackDistance then
			return true
		end
	end
	return false
end
function PackedBale:getInteractionPosition()
	if g_localPlayer:getIsInVehicle() then
		return
	elseif g_currentMission.accessHandler:canPlayerAccess(self) then
		return g_localPlayer:getPosition()
	end
end
PackedBaleActivatable = {}
local PackedBaleActivatable_mt = Class(PackedBaleActivatable)
function PackedBaleActivatable.new(packedBale)
	local self = setmetatable({}, PackedBaleActivatable_mt)
	self.packedBale = packedBale
	self.activateText = g_i18n:getText("action_cutBale")
	return self
end
function PackedBaleActivatable:getIsActivatable()
	if self.packedBale:getCanInteract() then
		return true
	else
		return false
	end
end
function PackedBaleActivatable:run()
	self.packedBale:unpack()
end
