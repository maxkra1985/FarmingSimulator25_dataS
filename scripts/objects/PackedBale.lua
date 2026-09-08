-- Local values: PackedBale_mt, PackedBaleActivatable_mt
PackedBale = {}
PackedBale.MAX_UNPACK_DISTANCE = 4
source("dataS/scripts/events/BaleUnpackEvent.lua")
local PackedBale_mt = Class(PackedBale, Bale)
InitStaticObjectClass(PackedBale, "PackedBale")

-- Upvalues: PackedBale_mt
-- Local values: self
function PackedBale.new(isServer, isClient, customMt)
	-- upvalues: (copy) PackedBale_mt
	local v5_ = Bale.new(isServer, isClient, customMt or PackedBale_mt)
	registerObjectClassName(v5_, "PackedBale")
	v5_.singleBaleNodes = {}
	v5_.packedBaleActivatable = PackedBaleActivatable.new(v5_)
	v5_.maxUnpackDistance = PackedBale.MAX_UNPACK_DISTANCE
	return v5_
end

function PackedBale:delete()
	g_currentMission.activatableObjectsSystem:removeActivatable(self.packedBaleActivatable)
	PackedBale:superClass().delete(self)
end

function PackedBale:loadBaleAttributesFromXML(xmlFile)
	if not PackedBale:superClass().loadBaleAttributesFromXML(self, xmlFile) then
		return false
	end
	self.singleBaleFilename = xmlFile:getValue("bale.packedBale#singleBale")
	self.singleBaleFilename = Utils.getFilename(self.singleBaleFilename, self.baseDirectory)
	if self.singleBaleFilename == nil or not fileExists(self.singleBaleFilename) then
		Logging.xmlError(xmlFile, "Could not find single bale reference for bale (%s)", self.singleBaleFilename)
		return false
	end
	xmlFile:iterate("bale.packedBale.singleBale", function(_, p9_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v10_ = xmlFile:getValue(p9_ .. "#node", nil, self.nodeId)
		if v10_ ~= nil then
			local v11_ = self.singleBaleNodes
			table.insert(v11_, v10_)
		end
	end)
	g_currentMission.activatableObjectsSystem:addActivatable(self.packedBaleActivatable)
	return true
end

-- Local values: i, singleBaleNode, baleObject, x, y, z, rx, ry, rz
function PackedBale:unpack(noEventSend)
	g_currentMission.activatableObjectsSystem:removeActivatable(self.packedBaleActivatable)
	if self.isServer then
		for v13_ = 1, #self.singleBaleNodes do
			local v14_ = self.singleBaleNodes[v13_]
			if self.fillLevel > 1 then
				local v15_ = Bale.new(self.isServer, self.isClient)
				local v16_, v17_, v18_ = getWorldTranslation(v14_)
				local v19_, v20_, v21_ = getWorldRotation(v14_)
				if v15_:loadFromConfigXML(self.singleBaleFilename, v16_, v17_, v18_, v19_, v20_, v21_) then
					v15_:setFillType(self.fillType)
					local v22_ = self.fillLevel
					v15_:setFillLevel((math.min(v22_, v15_:getCapacity())))
					v15_:setOwnerFarmId(self.ownerFarmId, true)
					v15_:register()
					self.fillLevel = self.fillLevel - v15_:getFillLevel()
				end
			end
		end
		self:delete()
	else
		g_client:getServerConnection():sendEvent(BaleUnpackEvent.new(self))
	end
end

-- Local values: x1, y1, z1, x2, y2, z2, distance
function PackedBale:getCanInteract()
	local v24_, v25_, v26_ = self:getInteractionPosition()
	if v24_ ~= nil then
		local v27_, v28_, v29_ = getWorldTranslation(self.nodeId)
		if MathUtil.vector3Length(v24_ - v27_, v25_ - v28_, v26_ - v29_) < self.maxUnpackDistance then
			return true
		end
	end
	return false
end

function PackedBale:getInteractionPosition()
	if not g_localPlayer:getIsInVehicle() then
		if g_currentMission.accessHandler:canPlayerAccess(self) then
			return g_localPlayer:getPosition()
		end
	end
end
PackedBaleActivatable = {}
local v_u_31_ = Class(PackedBaleActivatable)
function PackedBaleActivatable.new(p32_)
	-- upvalues: (copy) v_u_31_
	local v33_ = v_u_31_
	local v34_ = setmetatable({}, v33_)
	v34_.packedBale = p32_
	v34_.activateText = g_i18n:getText("action_cutBale")
	return v34_
end

function PackedBaleActivatable:getIsActivatable()
	return self.packedBale:getCanInteract() and true or false
end

function PackedBaleActivatable:run()
	self.packedBale:unpack()
end
