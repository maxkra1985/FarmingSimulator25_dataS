-- Local values: AIDriveStrategyFieldCourse_mt
AIDriveStrategyFieldCourse = {}
source("dataS/scripts/vehicles/ai/AICollisionTriggerHandler.lua")
local AIDriveStrategyFieldCourse_mt = Class(AIDriveStrategyFieldCourse, AIDriveStrategy)

-- Upvalues: AIDriveStrategyFieldCourse_mt
-- Local values: self
function AIDriveStrategyFieldCourse.new(reconstructionData, customMt)
	-- upvalues: (copy) AIDriveStrategyFieldCourse_mt
	local v4_ = AIDriveStrategy.new(reconstructionData, customMt or AIDriveStrategyFieldCourse_mt)
	v4_.collisionHandler = AICollisionTriggerHandler.new()
	v4_.isBlocked = false
	v4_.hasStaticCollision = false
	v4_.hasStaticCollisionTimer = 0
	v4_.collisionDistance = math.huge
	v4_.lastContinueWorkState = false
	v4_.lastContinueWorkBlockedTime = -math.huge
	v4_.reconstructionData = reconstructionData
	return v4_
end

-- Local values: _, implement, rootVehicle
function AIDriveStrategyFieldCourse:delete()
	AIDriveStrategyFieldCourse:superClass().delete(self)
	for _, v6_ in ipairs(self.vehicle:getAttachedAIImplements()) do
		v6_.object:aiImplementEndLine()
		v6_.object.rootVehicle:raiseStateChange(VehicleStateChange.AI_END_LINE)
	end
end

-- Local values: doFieldDetection, vx, _, vz, notOwned
function AIDriveStrategyFieldCourse:setAIVehicle(vehicle)
	AIDriveStrategyFieldCourse:superClass().setAIVehicle(self, vehicle)
	self.collisionHandler:init(vehicle, self)
	self.vehicleAISteeringNode = self.vehicle:getAISteeringNode()
	self.vehicleAISteeringNodeReverse = self.vehicle:getAIReverserNode()
	self.reverserDirectionNode = AIVehicleUtil.getAIToolReverserDirectionNode(self.vehicle)
	self.reverserDirectionNodeRefNode = self.reverserDirectionNode
	if self.reverserDirectionNodeRefNode == nil then
		if self.vehicle.getAIToolReverserDirectionNode ~= nil then
			self.reverserDirectionNodeRefNode = self.vehicle:getAIToolReverserDirectionNode()
		end
		if self.reverserDirectionNodeRefNode == nil and self.vehicleAISteeringNodeReverse ~= self.vehicleAISteeringNode then
			self.reverserDirectionNodeRefNode = self.vehicleAISteeringNodeReverse
		end
	end
	self.vehicle.aiDriveDirection = { 0, 1 }
	self.vehicle.aiDriveTarget = { 0, 0 }
	self.lastVehiclePosition = { 0, 0, 0 }
	self.lastTargetPosition = { 0, 0, 1 }
	self.lastMovingDirection = 1
	self.lastSegmentIsTurn = false
	self.nextSegmentTurnSide = nil
	self.lastSegmentTurnSide = nil
	self.vehicle:initializeLoadedAIModeUserSettings()
	self.fieldCourseSettings = self.vehicle:getAIModeFieldCourseSettings()
	if self.fieldCourseSettings == nil then
		local v9_, v10_ = FieldCourseSettings.generate(self.vehicle)
		self.fieldCourseSettings = v9_
		self.implementData = v10_
	else
		self.implementData = self.fieldCourseSettings:resetDynamicSettings(self.vehicle)
	end
	self.fieldCourseSettings:print(self.debugPrint, self)
	local v11_
	if self.reconstructionData == nil or self.reconstructionData.aiFieldCourseReconstructionData == nil then
		v11_ = true
	else
		Logging.devInfo("Using field course data from savegame")
		local v12_, _, v13_ = localToWorld(self.vehicle:getAIDirectionNode(), 0, 0, 0)
		self.fieldDetectionInProgress = true
		if self.reconstructionData.aiFieldCourseReconstructionData:apply(self, self.onFieldCourseLoadedCallback, v12_, v13_) then
			v11_ = false
		else
			self.fieldDetectionInProgress = nil
			v11_ = true
		end
	end
	if v11_ then
		local v14_ = false
		if AIDriveStrategyFieldCourse.fieldDetectionPosition == nil then
			local v15_, v16_
			v15_, v16_, v14_ = FieldCourse.findClosestField(nil, nil, nil, nil, self.vehicle:getAIJobFarmId(), self.vehicle, 2, self.fieldCourseSettings)
			self.fieldDetectionX = v15_
			self.fieldDetectionZ = v16_
		else
			local v17_ = AIDriveStrategyFieldCourse.fieldDetectionPosition[1]
			local v18_ = AIDriveStrategyFieldCourse.fieldDetectionPosition[2]
			self.fieldDetectionX = v17_
			self.fieldDetectionZ = v18_
		end
		if self.fieldDetectionX == nil or v14_ ~= false then
			if v14_ then
				self.fieldNotOwned = true
			end
		else
			self.fieldDetectionInProgress = true
			g_fieldCourseManager:generateFieldCourseAtWorldPos(self.fieldDetectionX, self.fieldDetectionZ, self.fieldCourseSettings, self.onFieldCourseLoadedCallback, self)
		end
	end
	self.collisionHandler:setStaticCollisionCallback(function(p19_)
		-- upvalues: (copy) self
		self.hasStaticCollision = p19_
	end)
	self.collisionHandler:setIsBlockedCallback(function(p20_)
		-- upvalues: (copy) self
		self.isBlocked = p20_
		if g_server ~= nil then
			g_server:broadcastEvent(AIVehicleIsBlockedEvent.new(self.vehicle, p20_), true, nil, self.vehicle)
		end
	end)
	self.collisionHandler:setCollisionDistanceCallback(function(p21_)
		-- upvalues: (copy) self
		self.collisionDistance = p21_
	end)
end

-- Local values: aiFieldCourse, _, aiRootNode, dx, _, dz, attachedAIImplements
function AIDriveStrategyFieldCourse:onFieldCourseLoadedCallback(fieldCourse)
	if self.vehicle.isDeleted or self.vehicle.isDeleting then
		return
	elseif fieldCourse == nil then
		self.vehicle:stopCurrentAIJob(AIMessageErrorNoFieldFound.new())
		self:debugPrint("Stopping AIVehicle - Field boundary not detected")
		return
	else
		local v_u_24_
		if ClassUtil.getClassObjectByObject(fieldCourse) == FieldCourse then
			v_u_24_ = AIFieldCourse.new(fieldCourse)
		else
			local v25_ = fieldCourse.fieldCourse
			v_u_24_ = fieldCourse
			fieldCourse = v25_
		end
		if fieldCourse.isVineyardCourse then
			self.vehicle:stopCurrentAIJob(AIMessageErrorVineyardNotSupported.new())
			self:debugPrint("Stopping AIVehicle - Vineyard course not supported")
		else
			local v26_ = self.vehicle:getAIDirectionNode()
			local v27_, _, v28_ = localToWorld(v26_, 0, 0, 0)
			self.startX = v27_
			self.startZ = v28_
			local v29_, _, v30_ = localDirectionToWorld(v26_, 0, 0, 1)
			self.startYRot = MathUtil.getYRotationFromDirection(v29_, v30_)
			local v_u_31_ = self.vehicle:getAttachedAIImplements()
			v_u_24_:setStartPosition(self.startX, self.startZ, self.startYRot)
			local v32_ = self.startX
			local v33_ = self.startZ
			local v34_ = self.startYRot
			self:debugPrint("  Start Position: %.3f %.3f (%.3f\194\176)", v32_, v33_, (math.deg(v34_)))
			self.aiFieldCourse = v_u_24_
			v_u_24_:setInitialSegmentCallback(function()
				-- upvalues: (copy) self
				self.initialSegmentFinished = true
				if not self.fieldCourseSettings.workInitialSegment then
					self.vehicle:raiseAIEvent("onAIFieldWorkerPrepareForWork", "onAIImplementPrepareForWork")
				end
			end)
			v_u_24_:setSegmentAreaValidityFunction(function(p35_, p36_, p37_, p38_, p39_, p40_)
				-- upvalues: (copy) v_u_31_
				for _, v41_ in ipairs(v_u_31_) do
					local v42_, v43_ = AIVehicleUtil.getAIAreaOfVehicle(v41_.object, p35_, p36_, p37_, p38_, p39_, p40_)
					if v43_ > 0 and v42_ / v43_ > 0 then
						return true
					end
				end
				return false
			end)
			if self.fieldCourseSettings.workInitialSegment then
				self.vehicle:raiseAIEvent("onAIFieldWorkerPrepareForWork", "onAIImplementPrepareForWork")
			end
			v_u_24_:finalize(function()
				-- upvalues: (ref) v_u_24_, (copy) self
				if #v_u_24_.fieldCourse.segments == 0 then
					self.vehicle:stopCurrentAIJob(AIMessageErrorFieldNotReady.new())
				else
					self.fieldDetectionInProgress = false
				end
			end)
		end
	end
end

-- Local values: aiImplements, segmentIsTurn, segmentIsInitial, segmentPosition, _, _, _, isInitial, sideOffset, nextSegmentTurnSide, i, implement, data, doAreaCheck, leftMarker, rightMarker, backMarker, markersInverted, lookAheadDistance, _, _, areaLength, safetyOffset, size, getAreaDimensions, leftNode, rightNode, zOffset, areaSize, xOffsetLeft, xOffsetRight, sX, _, sZ, hX, _, hZ, wX, _, wZ, sX, sZ, wX, wZ, hX, hZ, area, totalArea, x, z, widthX, widthZ, heightX, heightZ, currentData, isCornerCutOutActive, i, implement, data, rootVehicle, rootVehicle, vX, vY, vZ, tX, tY, tZ, dx, dz, r, g, b
function AIDriveStrategyFieldCourse:update(dt)
	self.collisionHandler:update(dt, self.lastMovingDirection)
	if self.aiFieldCourse ~= nil then
		self.aiFieldCourse:update(dt)
		if VehicleDebug.state == VehicleDebug.DEBUG_AI and self.vehicle.isActiveForInputIgnoreSelectionIgnoreAI then
			self.aiFieldCourse:draw()
			self.fieldCourseSettings:draw()
		end
		local v46_ = self.vehicle:getAttachedAIImplements()
		local v47_, v48_, v49_, _, _, _ = self.aiFieldCourse:getActiveSegmentData()
		if v47_ ~= nil then
			local v50_, v51_ = self.aiFieldCourse:getNextSegmentData()
			if not v50_ and v51_ ~= nil then
				local v52_ = v51_ > 0
				if v52_ ~= self.nextSegmentTurnSide then
					self.vehicle:aiFieldWorkerSideOffsetChanged(v52_, v48_)
					self.nextSegmentTurnSide = v52_
				end
			end
			if not v48_ or self.fieldCourseSettings.workInitialSegment then
				if v47_ == self.lastSegmentIsTurn then
					if v47_ then
						self.vehicle:aiFieldWorkerTurnProgress(v49_, self.lastSegmentTurnSide, self.lastMovingDirection)
					end
				else
					if v47_ then
						self.lastSegmentTurnSide = self.nextSegmentTurnSide
						self.vehicle:aiFieldWorkerStartTurn(self.lastSegmentTurnSide, nil)
					else
						self.vehicle:aiFieldWorkerEndTurn(self.lastSegmentTurnSide, nil)
					end
					self.lastSegmentIsTurn = v47_
				end
				for v53_, v54_ in ipairs(v46_) do
					local v55_ = self.implementData[v53_]
					if self.fieldCourseSettings.toolAlwaysActive then
						local v56_ = not v47_
						if v56_ then
							v56_ = self.lastMovingDirection >= 0
						end
						v55_.isLowered = v56_
					else
						local v57_ = false
						local v58_
						if v47_ or self.lastMovingDirection < 0 then
							v55_.isLowered = false
							v58_ = (not (self.fieldCourseSettings.canTurnBackward or self.fieldCourseSettings.allowStraightReversing) or self.fieldCourseSettings.workInitialSegment and (v48_ and self.lastMovingDirection > 0)) and true or v57_
						else
							v58_ = g_time - self.lastContinueWorkBlockedTime > 1000
						end
						if v58_ then
							local v59_, v60_, v61_, v62_ = v54_.object:getAIMarkers()
							local v63_ = v54_.object:getAILookAheadSize()
							local _, _, v64_ = localToLocal(v59_, v61_, 0, 0, 0)
							local v65_ = v63_ + v64_
							local v66_ = -v64_
							local v67_ = 0.2
							local v68_ = -0.2
							if v62_ then
								v68_ = -v68_
								v67_ = -v67_
							end
							local v69_, _, v70_ = localToWorld(v59_, v68_, 0, v66_)
							local v71_, _, v72_ = localToWorld(v59_, v68_, 0, v66_ + v65_)
							local v73_, _, v74_ = localToWorld(v60_, v67_, 0, v66_)
							local v75_, v76_ = AIVehicleUtil.getAIAreaOfVehicle(v54_.object, v69_, v70_, v73_, v74_, v71_, v72_)
							if v76_ > 0 and v75_ / v76_ > 0 then
								v55_.isLowered = true
							else
								v55_.isLowered = false
							end
							if VehicleDebug.state == VehicleDebug.DEBUG_AI then
								local v77_, v78_, v79_, v80_, v81_, v82_ = MathUtil.getXZWidthAndHeight(v69_, v70_, v73_, v74_, v71_, v72_)
								DebugUtil.drawDebugParallelogram(v77_, v78_, v79_, v80_, v81_, v82_, 0.2, v55_.isLowered and 0 or 1, v55_.isLowered and 1 or 0, 0, 1)
							end
						end
					end
					while v55_.parentAIImplement ~= nil do
						if v55_.isLowered and not v55_.parentAIImplement.isLowered then
							v55_.parentAIImplement.isLowered = true
						end
						v55_ = v55_.parentAIImplement
					end
				end
			end
		end
		self.vehicle:setAIFieldWorkerIsTurning(v47_)
		local v83_ = self.aiFieldCourse:getIsCornerCutOutActive()
		self.vehicle:setAIFieldWorkerIsCornerCutOutActive(v83_)
		for v84_, v85_ in ipairs(v46_) do
			local v86_ = self.implementData[v84_]
			if v86_.isLowered then
				if v86_.wasLowered ~= true then
					v85_.object:aiImplementStartLine()
					v85_.object:getRootVehicle():raiseStateChange(VehicleStateChange.AI_START_LINE)
				end
			elseif v86_.wasLowered ~= false then
				v85_.object:aiImplementEndLine()
				v85_.object:getRootVehicle():raiseStateChange(VehicleStateChange.AI_END_LINE)
			end
			v86_.wasLowered = v86_.isLowered
		end
		local v87_ = self.lastVehiclePosition[1]
		local v88_ = self.lastVehiclePosition[2]
		local v89_ = self.lastVehiclePosition[3]
		local v90_ = self.lastTargetPosition[1]
		local v91_ = self.lastTargetPosition[2]
		local v92_ = self.lastTargetPosition[3]
		local v93_, v94_ = MathUtil.vector2Normalize(v90_ - v87_, v92_ - v89_)
		local v95_, v96_, v97_
		if self.lastMovingDirection < 0 then
			v95_ = 1
			v96_ = 0
			v97_ = 0
		else
			v95_ = 0
			v96_ = 1
			v97_ = 0
		end
		drawDebugTriangle(v87_ + v94_ * 0.25, v88_ + 4, v89_ - v93_ * 0.25, v87_ - v94_ * 0.25, v88_ + 4, v89_ + v93_ * 0.25, v90_, v91_ + 4, v92_, v95_, v96_, v97_, 0.2, true)
		if self.hasStaticCollision and self.lastContinueWorkState then
			if self.vehicle:getLastSpeed() >= 1 then
				self.hasStaticCollisionTimer = 0
				return
			end
			self.hasStaticCollisionTimer = self.hasStaticCollisionTimer + dt
			if self.hasStaticCollisionTimer > 5000 then
				self.hasStaticCollisionTimer = 0
				self.aiFieldCourse:skipCurrentSubSegment(25)
				self:debugPrint("AIVehicle blocked - skip current sub segment")
				return
			end
		else
			self.hasStaticCollisionTimer = 0
		end
	end
end

-- Local values: isTurning, _, tX, tZ, moveForwards, maxSpeed, distanceToStop, canContinueWork, stopAI, stopReason, aiImplements, i, implement, leftMarker, rightMarker, backMarker, _, lx, _, lz, rx, _, rz, leftOffset, rightOffset, _, _, maxZOffset, _, _, minZOffset, steeringOffset, rx, _, rz, revDistance, dirX1, _, dirZ1, length1, dirX2, _, dirZ2, length2, z, x, sDirX, sDirZ, angle, ltX, ltZ, _, _, segmentPosition, segmentLength, subSegmentPosition, subSegmentLength
function AIDriveStrategyFieldCourse:getDriveData(dt, vX, vY, vZ)
	if self.fieldDetectionInProgress == nil then
		if self.fieldNotOwned then
			self.vehicle:stopCurrentAIJob(AIMessageErrorFieldNotOwned.new())
			self:debugPrint("Stopping AIVehicle - Field not owned")
		else
			self.vehicle:stopCurrentAIJob(AIMessageErrorNoFieldFound.new())
			self:debugPrint("Stopping AIVehicle - Failed to start field detection")
		end
	else
		local v100_
		if self.aiFieldCourse == nil then
			v100_ = false
		else
			local v101_, v102_, v103_, v104_, v105_
			v100_, v101_, v102_, v103_, v104_, v105_ = self.aiFieldCourse:getActiveSegmentData()
		end
		local v106_ = 0
		local v107_ = 0
		local v108_ = true
		local v109_ = 0
		local v110_ = 0
		local v111_, v112_, v113_ = self.vehicle:getCanAIFieldWorkerContinueWork(v100_)
		if v111_ then
			self.lastContinueWorkState = true
			if VehicleDebug.state == VehicleDebug.DEBUG_AI then
				if self.aiFieldCourse ~= nil then
					self.aiFieldCourse:addDebugTexts(self.vehicle)
				end
				self.vehicle:addAIDebugText(string.format(" Has Static Collision: %s", self.hasStaticCollision))
				self.vehicle:addAIDebugText(string.format(" Collision Distance: dynamic: %.1f static: %.1f", self.collisionHandler.dynamicHitPointDistance, self.collisionHandler.staticHitPointDistance))
				self.vehicle:addAIDebugText(string.format(" Is Blocked: %s", self.isBlocked))
				self.vehicle:addAIDebugText(string.format(" Distance To Collision: %s", self.collisionDistance))
				if self.aiFieldCourse ~= nil then
					local v114_ = self.vehicle:getAttachedAIImplements()
					for _, v115_ in ipairs(v114_) do
						local v116_, v117_, v118_, _ = v115_.object:getAIMarkers()
						local v119_, _, v120_ = getWorldTranslation(v116_)
						local v121_, _, v122_ = getWorldTranslation(v117_)
						local v123_ = self.aiFieldCourse:getPositionOffsetToActiveSegment(v119_, v120_)
						local v124_ = self.aiFieldCourse:getPositionOffsetToActiveSegment(v121_, v122_)
						local _, _, v125_ = localToLocal(v116_, self.vehicleAISteeringNode, 0, 0, 0)
						local _, _, v126_ = localToLocal(v118_, self.vehicleAISteeringNode, 0, 0, 0)
						self.vehicle:addAIDebugText(string.format("%s", v115_.object:getName()))
						self.vehicle:addAIDebugText(string.format("    Side Drift: %.2fm | Width: %.2fm", (v123_ + v124_) * 0.5 * -1, calcDistanceFrom(v116_, v117_)))
						self.vehicle:addAIDebugText(string.format("    zOffset: %.2fm / %.2fm", v126_, v125_))
					end
					self.vehicle:addAIDebugText(string.format(" Segment Side Offset: %.2f", self.aiFieldCourse:getActiveSegmentSideOffset()))
				end
			end
			if self.isBlocked then
				return v106_, v107_, v108_, v109_, v110_
			end
			if self.aiFieldCourse ~= nil then
				local v127_, v128_, v129_ = getWorldTranslation(self.lastMovingDirection > 0 and self.vehicleAISteeringNode or self.vehicleAISteeringNodeReverse)
				v106_, v107_, v108_, v109_, v110_ = self.aiFieldCourse:getDriveData(dt, v127_, v128_, v129_, self.vehicle:getLastSpeed(), 4, self.reverserDirectionNodeRefNode)
				if v106_ ~= nil and (v106_ ~= 0 or v107_ ~= 0) then
					if not v108_ and self.reverserDirectionNode ~= nil then
						local v130_, _, v131_ = getWorldTranslation(self.reverserDirectionNode)
						local v132_ = MathUtil.vector2Length(v106_ - v130_, v107_ - v131_)
						local v133_, _, v134_ = localDirectionToWorld(self.vehicleAISteeringNodeReverse, 0, 0, 1)
						local v135_ = MathUtil.vector2Length(v133_, v134_)
						local v136_, _, v137_ = localDirectionToWorld(self.reverserDirectionNode, 0, 0, 1)
						local v138_ = MathUtil.vector2Length(v136_, v137_)
						if v135_ > 0 and v138_ > 0 then
							local v139_ = v133_ / v135_
							local v140_ = v134_ / v135_
							local v141_ = v136_ / v138_
							local v142_ = v137_ / v138_
							local v143_ = MathUtil.getProjectOnLineParameter(v106_, v107_, v130_, v131_, v141_, v142_)
							local v144_ = v132_ * v132_ - v143_ * v143_
							local v145_ = math.sqrt(v144_)
							local v146_, v147_ = MathUtil.vector2Normalize(v130_ - v106_, v131_ - v107_)
							local v148_ = MathUtil.dotProduct(-v142_, 0, v141_, v146_, 0, v147_)
							local v149_ = v145_ * math.sign(v148_)
							local v150_ = MathUtil.getSignedAngleBetweenVectors2D(v139_, v140_, v141_, v142_)
							local v151_ = math.cos(v150_) * v149_ - math.sin(v150_) * v143_
							local v152_ = math.sin(v150_) * v149_ + math.cos(v150_) * v143_
							if not (MathUtil.isNan(v151_) or MathUtil.isNan(v152_)) then
								local v153_
								v106_, v153_, v107_ = localToWorld(self.vehicleAISteeringNodeReverse, -v151_, 0, v152_)
							end
						end
					end
					if VehicleDebug.state == VehicleDebug.DEBUG_AI then
						local _, _, v154_, v155_, v156_, v157_ = self.aiFieldCourse:getActiveSegmentData()
						if v154_ ~= nil then
							self.vehicle:addAIDebugText(string.format("Segment Position: %.1f%% of %.1fm", v154_ * 100, v155_))
							if v157_ ~= v155_ then
								self.vehicle:addAIDebugText(string.format("Sub Segment Position: %.1f%% of %.1fm", v156_ * 100, v157_))
							end
						end
					end
					self.lastVehiclePosition[1] = v127_
					self.lastVehiclePosition[2] = v128_
					self.lastVehiclePosition[3] = v129_
					self.lastTargetPosition[1] = v106_
					self.lastTargetPosition[2] = v128_
					self.lastTargetPosition[3] = v107_
					self.lastMovingDirection = v108_ and 1 or -1
				end
			end
			if self.collisionDistance ~= math.huge and v108_ then
				local v158_ = self.collisionDistance * 2
				local v159_ = math.max(v158_, 1)
				v109_ = math.min(v109_, v159_)
			end
			return v106_, v107_, v108_, v109_, v110_
		else
			self.lastContinueWorkState = false
			self.lastContinueWorkBlockedTime = g_time
			if VehicleDebug.state == VehicleDebug.DEBUG_AI then
				self.vehicle:addAIDebugText("- Wait for turn on (getCanAIFieldWorkerContinueWork)")
			end
			local v160_ = 0
			if v112_ then
				self.vehicle:stopCurrentAIJob(v113_ or AIMessageErrorUnknown.new())
				self:debugPrint("Stopping AIVehicle - cannot continue work")
			end
			return v106_, v107_, v108_, v160_, v110_
		end
	end
end

function AIDriveStrategyFieldCourse:fillReconstructionData(data)
	if self.aiFieldCourse ~= nil then
		data.aiFieldCourseReconstructionData = AIFieldCourseReconstructionData.new()
		data.aiFieldCourseReconstructionData:setDataByAIFieldCourse(self.aiFieldCourse)
	end
end

function AIDriveStrategyFieldCourse.saveToXML(data, xmlFile, key)
	if data.aiFieldCourseReconstructionData ~= nil then
		data.aiFieldCourseReconstructionData:saveToXML(xmlFile, key .. ".strategyFieldCourse")
	end
end

function AIDriveStrategyFieldCourse.loadFromXML(data, xmlFile, key)
	data.aiFieldCourseReconstructionData = AIFieldCourseReconstructionData.new()
	if not data.aiFieldCourseReconstructionData:loadFromXML(xmlFile, key .. ".strategyFieldCourse") then
		data.aiFieldCourseReconstructionData = nil
	end
end

function AIDriveStrategyFieldCourse.registerSavegameXMLPaths(schema, basePath)
	AIFieldCourseReconstructionData.registerXMLPaths(schema, basePath .. ".strategyFieldCourse")
end
