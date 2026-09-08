ManureBarrel = {}

function ManureBarrel.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(Sprayer, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(AttacherJoints, specializations)
	end
	return v2_
end
function ManureBarrel.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("ManureBarrel")
	v3_:register(XMLValueType.INT, "vehicle.manureBarrel#attacherJointIndex", "Attacher joint index")
	v3_:setXMLSpecializationType()
end

function ManureBarrel.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreEffectsVisible", ManureBarrel.getAreEffectsVisible)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", ManureBarrel.getIsWorkAreaActive)
end

function ManureBarrel.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ManureBarrel)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", ManureBarrel)
	SpecializationUtil.registerEventListener(vehicleType, "onPostDetachImplement", ManureBarrel)
end

-- Local values: spec
function ManureBarrel:onLoad(savegame)
	local v7_ = self.spec_manureBarrel
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.manureBarrel#toolAttachAnimName", "vehicle.attacherJoints.attacherJoint.objectChange")
	v7_.attachToolJointIndex = self.xmlFile:getValue("vehicle.manureBarrel#attacherJointIndex")
end

-- Local values: spec
function ManureBarrel:onPostAttachImplement(attachable, inputJointDescIndex, jointDescIndex, loadFromSavegame)
	local v11_ = self.spec_manureBarrel
	if jointDescIndex == v11_.attachToolJointIndex then
		v11_.attachedTool = attachable
	end
end

-- Local values: spec, object, attachedImplements
function ManureBarrel:onPostDetachImplement(implementIndex)
	local v14_ = self.spec_manureBarrel
	local v15_
	if self.getObjectFromImplementIndex == nil then
		v15_ = nil
	else
		v15_ = self:getObjectFromImplementIndex(implementIndex)
	end
	if v15_ ~= nil and self:getAttachedImplements()[implementIndex].jointDescIndex == v14_.attachToolJointIndex then
		v14_.attachedTool = nil
	end
end

-- Local values: spec
function ManureBarrel:getAreEffectsVisible(superFunc)
	if self.spec_manureBarrel.attachedTool == nil then
		return superFunc(self)
	else
		return false
	end
end

-- Local values: spec
function ManureBarrel:getIsWorkAreaActive(superFunc, workArea)
	if self.spec_manureBarrel.attachedTool == nil then
		return superFunc(self, workArea)
	else
		return false
	end
end
