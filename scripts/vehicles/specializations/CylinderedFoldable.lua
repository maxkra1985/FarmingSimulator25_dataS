CylinderedFoldable = {}

function CylinderedFoldable.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(Cylindered, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(Foldable, specializations)
	end
	return v2_
end
function CylinderedFoldable.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("CylinderedFoldable")
	v3_:register(XMLValueType.BOOL, "vehicle.cylindered#loadMovingToolStatesAfterFolding", "Load moving tool states after folding state was loaded", false)
	v3_:register(XMLValueType.FLOAT, "vehicle.cylindered#loadMovingToolStatesFoldTime", "Fold time in which moving tool states should be loaded")
	v3_:setXMLSpecializationType()
end

function CylinderedFoldable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", CylinderedFoldable)
	SpecializationUtil.registerEventListener(vehicleType, "onPreInitComponentPlacement", CylinderedFoldable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", CylinderedFoldable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", CylinderedFoldable)
end

-- Local values: spec
function CylinderedFoldable:onLoad(savegame)
	local v6_ = self.spec_cylinderedFoldable
	v6_.loadMovingToolStatesAfterFolding = self.xmlFile:getValue("vehicle.cylindered#loadMovingToolStatesAfterFolding", false)
	v6_.loadMovingToolStatesFoldTime = self.xmlFile:getValue("vehicle.cylindered#loadMovingToolStatesFoldTime")
end

-- Local values: spec, targetFoldTime
function CylinderedFoldable:onPreInitComponentPlacement(savegame)
	local v9_ = self.spec_cylinderedFoldable
	if v9_.loadMovingToolStatesAfterFolding then
		local v10_ = v9_.loadMovingToolStatesFoldTime
		if v10_ == nil or self:getFoldAnimTime() == v10_ then
			Cylindered.onPostLoad(self, savegame)
		end
	end
end

-- Local values: i, tool
function CylinderedFoldable:onReadStream(streamId, connection)
	AnimatedVehicle.updateAnimations(self, 9999999)
	if streamReadBool(streamId) then
		Cylindered.onReadStream(self, streamId, connection)
	end
	if connection:getIsServer() then
		for v14_ = 1, #self.spec_cylindered.movingTools do
			local v15_ = self.spec_cylindered.movingTools[v14_]
			if v15_.dirtyFlag ~= nil then
				self:updateDependentAnimations(v15_, 9999)
			end
		end
	end
end

-- Local values: spec
function CylinderedFoldable:onWriteStream(streamId, connection)
	local v19_ = self.spec_cylinderedFoldable
	if streamWriteBool(streamId, v19_.loadMovingToolStatesFoldTime == nil and true or self:getFoldAnimTime() == v19_.loadMovingToolStatesFoldTime) then
		Cylindered.onWriteStream(self, streamId, connection)
	end
end
