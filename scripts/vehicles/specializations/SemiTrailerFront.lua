SemiTrailerFront = {}

function SemiTrailerFront.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(AttacherJoints, specializations)
end

function SemiTrailerFront.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed", SemiTrailerFront.isDetachAllowed)
end

function SemiTrailerFront.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SemiTrailerFront)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SemiTrailerFront)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", SemiTrailerFront)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetachImplement", SemiTrailerFront)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", SemiTrailerFront)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", SemiTrailerFront)
end

-- Local values: spec
function SemiTrailerFront:onLoad(savegame)
	local v5_ = self.spec_semiTrailerFront
	v5_.inputAttacherCurFade = 1
	v5_.inputAttacherFadeDir = 1
	v5_.inputAttacherFadeDuration = 1000
	v5_.joint = self.spec_attachable.inputAttacherJoints[1]
	v5_.joint.lowerRotLimitScaleBackup = { v5_.joint.lowerRotLimitScale[1], v5_.joint.lowerRotLimitScale[2], v5_.joint.lowerRotLimitScale[3] }
	v5_.attachedSemiTrailerBack = nil
	v5_.inputAttacherImplement = nil
	v5_.doSemiTrailerLockCheck = true
end

-- Local values: spec, lowerRotLimitScale, lowerRotLimitScaleBackup, attacherVehicle, attacherJoints, jointDesc, lowerRotLimit, x, y, z
function SemiTrailerFront:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v8_ = self.spec_semiTrailerFront
	if v8_.doSemiTrailerLockCheck then
		v8_.doSemiTrailerLockCheck = false
		if v8_.attachedSemiTrailerBack == nil then
			v8_.inputAttacherFadeDir = -1
		end
	end
	if self.isServer and v8_.inputAttacherImplement ~= nil and (v8_.inputAttacherCurFade > 0 and v8_.inputAttacherFadeDir < 0 or v8_.inputAttacherCurFade < 1 and v8_.inputAttacherFadeDir > 0) then
		local v9_ = v8_.inputAttacherCurFade + v8_.inputAttacherFadeDir * dt / v8_.inputAttacherFadeDuration
		v8_.inputAttacherCurFade = math.clamp(v9_, 0, 1)
		local v10_ = v8_.joint.lowerRotLimitScale
		local v11_ = v8_.joint.lowerRotLimitScaleBackup
		v10_[1] = v11_[1] * v8_.inputAttacherCurFade
		v10_[2] = v11_[2] * v8_.inputAttacherCurFade
		v10_[3] = v11_[3] * v8_.inputAttacherCurFade
		local v12_ = self:getAttacherVehicle()
		if v12_ ~= nil then
			local v13_ = v12_:getAttacherJoints()[v8_.inputAttacherImplement.jointDescIndex]
			local v14_ = v8_.inputAttacherImplement.lowerRotLimit
			if v14_ ~= nil then
				local v15_ = v14_[1] * v10_[1]
				local v16_ = v14_[2] * v10_[2]
				local v17_ = v14_[3] * v10_[3]
				setJointRotationLimit(v13_.jointIndex, 0, true, -v15_, v15_)
				setJointRotationLimit(v13_.jointIndex, 1, true, -v16_, v16_)
				setJointRotationLimit(v13_.jointIndex, 2, true, -v17_, v17_)
			end
		end
	end
end

-- Local values: canBeDatached, warning, spec
function SemiTrailerFront:isDetachAllowed(superFunc)
	local v20_, v21_ = superFunc(self)
	if v20_ then
		return self.spec_semiTrailerFront.attachedSemiTrailerBack ~= nil, nil
	else
		return false, v21_
	end
end

-- Local values: spec
function SemiTrailerFront:onPostAttachImplement(attachable, inputJointDescIndex, jointDescIndex, loadFromSavegame)
	local v24_ = self.spec_semiTrailerFront
	v24_.attachedSemiTrailerBack = attachable
	v24_.inputAttacherFadeDir = 1000
end

-- Local values: spec
function SemiTrailerFront:onPreDetachImplement(implement)
	local v26_ = self.spec_semiTrailerFront
	v26_.attachedSemiTrailerBack = nil
	v26_.inputAttacherFadeDir = -1
end

-- Local values: spec
function SemiTrailerFront:onPreDetach(attacherVehicle, implement)
	self.spec_semiTrailerFront.inputAttacherImplement = nil
end

-- Local values: spec
function SemiTrailerFront:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	self.spec_semiTrailerFront.inputAttacherImplement = attacherVehicle:getImplementByObject(self)
end
