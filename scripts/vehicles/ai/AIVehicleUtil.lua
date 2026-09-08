AIVehicleUtil = {}
AIVehicleUtil.VALID_AREA_THRESHOLD = 0.02
AIVehicleUtil.AREA_OVERLAP = 0.26

-- Local values: tX_2, tZ_2, d1X, d1Z, hit, _, f2, rotTime, radius, targetRotTime, steerDiff, fac, speedReduction
function AIVehicleUtil:driveToPoint(dt, acceleration, allowedToDrive, moveForwards, tX, tZ, maxSpeed, doNotSteer)
	if self.finishedFirstUpdate then
		if allowedToDrive then
			local v10_ = tX * 0.5
			local v11_ = tZ * 0.5
			local v12_ = -v10_
			local v13_
			if tX > 0 then
				v13_ = -v11_
				v12_ = v10_
			else
				v13_ = v11_
			end
			local v14_, _, v15_ = MathUtil.getLineLineIntersection2D(v10_, v11_, v13_, v12_, 0, 0, tX, 0)
			if doNotSteer == nil or not doNotSteer then
				local v16_
				if v14_ and math.abs(v15_) < 100000 then
					v16_ = self:getSteeringRotTimeByCurvature(1 / (tX * v15_))
					if self:getReverserDirection() < 0 then
						v16_ = -v16_
					end
				else
					v16_ = 0
				end
				local v17_
				if v16_ >= 0 then
					local v18_ = self.maxRotTime
					v17_ = math.min(v16_, v18_)
				else
					local v19_ = self.minRotTime
					v17_ = math.max(v16_, v19_)
				end
				if self.rotatedTime < v17_ then
					local v20_ = self.rotatedTime + dt * self:getAISteeringSpeed()
					self.rotatedTime = math.min(v20_, v17_)
				else
					local v21_ = self.rotatedTime - dt * self:getAISteeringSpeed()
					self.rotatedTime = math.max(v21_, v17_)
				end
				local v22_ = v17_ - self.rotatedTime
				local v23_ = math.abs(v22_)
				local v24_ = self.maxRotTime
				local v25_ = -self.minRotTime
				local v26_ = v23_ / math.max(v24_, v25_)
				local v27_ = 1 - math.pow(v26_, 0.25)
				if maxSpeed * v27_ < 1 then
					v27_ = 1 / maxSpeed
					acceleration = 0
				end
				maxSpeed = maxSpeed * v27_
			end
		end
		self:getMotor():setSpeedLimit((math.min(maxSpeed, self:getCruiseControlSpeed())))
		if self:getCruiseControlState() ~= Drivable.CRUISECONTROL_STATE_ACTIVE then
			self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_ACTIVE)
		end
		local v28_ = not allowedToDrive and 0 or acceleration
		if not moveForwards then
			v28_ = -v28_
		end
		WheelsUtil.updateWheelsPhysics(self, dt, self.lastSpeedReal * self.movingDirection, v28_, not allowedToDrive, true)
	end
end

-- Local values: targetRotTime, acc
function AIVehicleUtil:driveAlongCurvature(dt, curvature, maxSpeed, acceleration)
	local v34_ = maxSpeed or math.huge
	self.rotatedTime = -(self:getSteeringRotTimeByCurvature(curvature) * self:getSteeringDirection())
	if self.finishedFirstUpdate then
		if v34_ > 0 then
			if self:getCruiseControlState() ~= Drivable.CRUISECONTROL_STATE_ACTIVE then
				self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_ACTIVE)
			end
		else
			acceleration = 0
		end
		self:getMotor():setSpeedLimit(v34_)
		WheelsUtil.updateWheelsPhysics(self, dt, self.lastSpeedReal * self.movingDirection, acceleration, v34_ > 0, true)
	end
end

-- Local values: angle, dot, turnLeft, targetRotTime, acc
function AIVehicleUtil:driveInDirection(dt, steeringAngleLimit, acceleration, slowAcceleration, slowAngleLimit, allowedToDrive, moveForwards, lx, lz, maxSpeed, slowDownFactor)
	local v47_
	if lx == nil or lz == nil then
		v47_ = 0
	else
		local v48_ = math.acos(lz)
		v47_ = math.deg(v48_)
		if v47_ < 0 then
			v47_ = v47_ + 180
		end
		local v49_ = lx > 0.00001
		if not moveForwards then
			v49_ = not v49_
		end
		local v50_
		if v49_ then
			local v51_ = self.maxRotTime
			local v52_ = v47_ / steeringAngleLimit
			v50_ = v51_ * math.min(v52_, 1)
		else
			local v53_ = self.minRotTime
			local v54_ = v47_ / steeringAngleLimit
			v50_ = v53_ * math.min(v54_, 1)
		end
		if self.rotatedTime < v50_ then
			local v55_ = self.rotatedTime + dt * self:getAISteeringSpeed()
			self.rotatedTime = math.min(v55_, v50_)
		else
			local v56_ = self.rotatedTime - dt * self:getAISteeringSpeed()
			self.rotatedTime = math.max(v56_, v50_)
		end
	end
	if self.finishedFirstUpdate then
		if maxSpeed == nil or maxSpeed == 0 then
			if slowAngleLimit > math.abs(v47_) then
				slowAcceleration = acceleration
			end
		else
			if slowAngleLimit <= math.abs(v47_) then
				maxSpeed = maxSpeed * slowDownFactor
			end
			self.motor:setSpeedLimit(maxSpeed)
			if self.cruiseControl.state == Drivable.CRUISECONTROL_STATE_ACTIVE then
				slowAcceleration = acceleration
			else
				self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_ACTIVE)
				slowAcceleration = acceleration
			end
		end
		local v57_ = not allowedToDrive and 0 or slowAcceleration
		if not moveForwards then
			v57_ = -v57_
		end
		WheelsUtil.updateWheelsPhysics(self, dt, self.lastSpeedReal * self.movingDirection, v57_, not allowedToDrive, true)
	end
end

-- Local values: lx, _, lz, length
function AIVehicleUtil.getDriveDirection(refNode, x, y, z)
	local v62_, _, v63_ = worldToLocal(refNode, x, y, z)
	local v64_ = MathUtil.vector2Length(v62_, v63_)
	if v64_ > 0.00001 then
		local v65_ = 1 / v64_
		v62_ = v62_ * v65_
		v63_ = v63_ * v65_
	end
	return v62_, v63_
end

-- Local values: lx, _, lz, length
function AIVehicleUtil.getAverageDriveDirection(refNode, x, y, z, x2, y2, z2)
	local v73_, _, v74_ = worldToLocal(refNode, (x + x2) * 0.5, (y + y2) * 0.5, (z + z2) * 0.5)
	local v75_ = MathUtil.vector2Length(v73_, v74_)
	if v75_ > 0.00001 then
		v73_ = v73_ / v75_
		v74_ = v74_ / v75_
	end
	return v73_, v74_, v75_
end

-- Local values: _, implement, object
function AIVehicleUtil.getAttachedImplementsAllowTurnBackward(vehicle)
	if vehicle.getAIAllowTurnBackward ~= nil and not vehicle:getAIAllowTurnBackward() then
		return false
	end
	if vehicle.getAttachedImplements ~= nil then
		for _, v77_ in pairs(vehicle:getAttachedImplements()) do
			local v78_ = v77_.object
			if v78_ ~= nil then
				if v78_.getAIAllowTurnBackward ~= nil and not v78_:getAIAllowTurnBackward() then
					return false
				end
				if not AIVehicleUtil.getAttachedImplementsAllowTurnBackward(v78_) then
					return false
				end
			end
		end
	end
	return true
end

-- Local values: _, implement, object
function AIVehicleUtil.getAttachedImplementsBlockTurnBackward(vehicle)
	if vehicle.getAIBlockTurnBackward ~= nil and vehicle:getAIBlockTurnBackward() then
		return true
	end
	if vehicle.getAttachedImplements ~= nil then
		for _, v80_ in pairs(vehicle:getAttachedImplements()) do
			local v81_ = v80_.object
			if v81_ ~= nil then
				if v81_.getAIBlockTurnBackward ~= nil and v81_:getAIBlockTurnBackward() then
					return true
				end
				if AIVehicleUtil.getAttachedImplementsBlockTurnBackward(v81_) then
					return true
				end
			end
		end
	end
	return false
end

-- Local values: maxRadius, _, implement, object, radius, radius
function AIVehicleUtil.getAttachedImplementsMaxTurnRadius(vehicle)
	local v83_ = -1
	if vehicle.getAttachedImplements ~= nil then
		for _, v84_ in pairs(vehicle:getAttachedImplements()) do
			local v85_ = v84_.object
			if v85_ ~= nil then
				local v86_
				if v85_.getAITurnRadiusLimitation == nil then
					v86_ = v83_
				else
					v86_ = v85_:getAITurnRadiusLimitation()
					if v86_ == nil then
						v86_ = v83_
					elseif v83_ >= v86_ then
						v86_ = v83_
					end
				end
				v83_ = AIVehicleUtil.getAttachedImplementsMaxTurnRadius(v85_)
				if v86_ >= v83_ then
					v83_ = v86_
				end
			end
		end
	end
	return v83_
end

-- Local values: _, implement, reverserNode, attachedReverserNode
function AIVehicleUtil.getAIToolReverserDirectionNode(vehicle)
	for _, v88_ in pairs(vehicle:getAttachedImplements()) do
		if v88_.object ~= nil and v88_.object.getAIToolReverserDirectionNode ~= nil then
			local v89_ = v88_.object:getAIToolReverserDirectionNode() or AIVehicleUtil.getAIToolReverserDirectionNode(v88_.object)
			if v89_ ~= nil then
				return v89_
			end
		end
	end
	return nil
end

-- Local values: radius, _, rotationNode, wheels, rotLimitFactor, rootVehicle, retRadius, activeInputAttacherJoint, refNode, _, inputAttacherJoint, rx, _, rz, _, wheel, nx, _, nz, x, z, cx, cz, rotMax, attacherVehicle, jointDesc, _, compJoint, x1, z1, dx, dz, tmpx, tmpz, hit, f1, _
function AIVehicleUtil.getMaxToolRadius(implement)
	local _, v91_, v92_, v93_ = implement.object:getAITurnRadiusLimitation()
	local v94_ = implement.object.rootVehicle
	local v95_ = AIVehicleUtil.getAttachedImplementsMaxTurnRadius(v94_)
	local v96_ = v95_ == -1 and 0 or v95_
	if v91_ then
		local v97_ = implement.object:getActiveInputAttacherJoint()
		for _, v98_ in pairs(implement.object:getInputAttacherJoints()) do
			if v91_ == v98_.node then
				v91_ = v97_.node
				break
			end
		end
		local v99_, _, v100_ = localToLocal(v91_, implement.object.components[1].node, 0, 0, 0)
		for _, v101_ in pairs(v92_) do
			local v102_, _, v103_ = localToLocal(v101_.repr, implement.object.components[1].node, 0, 0, 0)
			local v104_ = v102_ - v99_
			local v105_ = v103_ - v100_
			local v106_ = nil
			if v91_ == v97_.node then
				local v107_ = implement.object:getAttacherVehicle():getAttacherJointDescFromObject(implement.object)
				local v108_ = v107_.upperRotLimit[2]
				local v109_ = v107_.lowerRotLimit[2]
				v106_ = math.max(v108_, v109_) * v97_.lowerRotLimitScale[2]
			else
				for _, v110_ in pairs(implement.object.componentJoints) do
					if v91_ == v110_.jointNode then
						local v111_ = v110_.rotLimit[1]
						local v112_ = math.max(v106_ or 0, v111_) or 0
						local v113_ = v110_.rotLimit[2]
						local v114_ = math.max(v112_, v113_) or 0
						local v115_ = v110_.rotLimit[3]
						v106_ = math.max(v114_, v115_)
						break
					end
				end
			end
			if v106_ == nil then
				Logging.warning("AI rotation node \'%s\' could not be found as component joint or attacher joint on \'%s\'", getName(v91_), implement.object.configFileName)
			else
				local v116_ = v106_ * v93_
				local v117_ = v104_ * math.cos(v116_) - v105_ * math.sin(v116_)
				local v118_ = v104_ * math.sin(v116_) + v105_ * math.cos(v116_)
				local v119_ = -v118_
				local v120_, v121_
				if v101_.steering.steeringAxleScale == 0 or v101_.steering.steeringAxleRotMax == 0 then
					v120_ = v117_
					v121_ = v119_
				else
					local v122_ = v101_.steering.steeringAxleRotMax
					local v123_ = v119_ * math.cos(v122_)
					local v124_ = v101_.steering.steeringAxleRotMax
					v121_ = v123_ - v117_ * math.sin(v124_)
					local v125_ = v101_.steering.steeringAxleRotMax
					local v126_ = v119_ * math.sin(v125_)
					local v127_ = v101_.steering.steeringAxleRotMax
					v120_ = v126_ + v117_ * math.cos(v127_)
				end
				local v128_, v129_, _ = MathUtil.getLineLineIntersection2D(0, 0, 1, 0, v117_, v118_, v121_, v120_)
				if v128_ then
					local v130_ = math.abs(v129_)
					v96_ = math.max(v96_, v130_)
				end
			end
		end
	end
	return v96_
end

-- Local values: leftMarker, rightMarker, _, lX, _, _, rX, _, _
function AIVehicleUtil.updateInvertLeftRightMarkers(rootAttacherVehicle, vehicle)
	if vehicle.getAIMarkers ~= nil then
		local v133_, v134_, _ = vehicle:getAIMarkers()
		if v133_ ~= nil and v134_ ~= nil then
			local v135_, _, _ = localToLocal(v133_, rootAttacherVehicle:getAIDirectionNode(), 0, 0, 0)
			local v136_, _, _ = localToLocal(v134_, rootAttacherVehicle:getAIDirectionNode(), 0, 0, 0)
			if v135_ < v136_ then
				vehicle:setAIMarkersInverted()
			end
		end
	end
end

-- Local values: directionNode, attachedAIImplements, checkFrontDistance, leftAreaPercentage, rightAreaPercentage, minZ, maxZ, _, implement, leftMarker, rightMarker, backMarker, _, _, zl, _, _, zr, _, _, zb, sideDistance, minAreaWidth, _, implement, leftMarker, rightMarker, _, lx, _, _, rx, _, _, dx, dz, sx, sz, _, implement, leftMarker, rightMarker, _, lx, ly, lz, rx, ry, rz, width, length, lSX, lSZ, lWX, lWZ, lHX, lHZ, rSX, rSZ, rWX, rWZ, rHX, rHZ, lArea, lTotal, rArea, rTotal, lSY, lWY, lHY, rSY, rWY, rHY
function AIVehicleUtil.getValidityOfTurnDirections(vehicle, turnData)
	local v139_ = vehicle:getAIDirectionNode()
	local v140_ = vehicle:getAttachedAIImplements()
	local v141_ = math.huge
	local v142_ = -math.huge
	local v143_ = 5
	local v144_ = 0
	local v145_ = 0
	for _, v146_ in pairs(v140_) do
		local v147_, v148_, v149_ = v146_.object:getAIMarkers()
		local _, _, v150_ = localToLocal(v147_, v139_, 0, 0, 0)
		local _, _, v151_ = localToLocal(v148_, v139_, 0, 0, 0)
		local _, _, v152_ = localToLocal(v149_, v139_, 0, 0, 0)
		v141_ = math.min(v141_, v150_, v151_, v152_)
		v142_ = math.max(v142_, v150_, v151_, v152_)
	end
	local v153_
	if turnData == nil then
		v153_ = math.huge
		for _, v154_ in pairs(v140_) do
			local v155_, v156_, _ = v154_.object:getAIMarkers()
			local v157_, _, _ = localToLocal(v155_, v139_, 0, 0, 0)
			local v158_, _, _ = localToLocal(v156_, v139_, 0, 0, 0)
			local v159_ = v157_ - v158_
			local v160_ = math.abs(v159_)
			v153_ = math.min(v153_, v160_)
		end
	else
		local v161_ = turnData.sideOffsetRight - turnData.sideOffsetLeft
		v153_ = math.abs(v161_)
	end
	local v162_ = vehicle.aiDriveDirection[1]
	local v163_ = vehicle.aiDriveDirection[2]
	local v164_ = -v163_
	local v165_ = v162_
	for _, v166_ in pairs(v140_) do
		local v167_, v168_, _ = v166_.object:getAIMarkers()
		local v169_, v170_, _ = localToLocal(v167_, v139_, 0, 0, 0)
		local v171_, v172_, _ = localToLocal(v168_, v139_, 0, 0, 0)
		local v173_ = v169_ - v171_
		local v174_ = math.abs(v173_)
		local v175_ = v143_ + (v142_ - v141_)
		local v176_ = v153_ * 1.3 + 2
		local v177_ = v175_ + math.max(v176_, 5)
		local v178_, _, v179_ = localToWorld(v139_, v169_, v170_, v142_ + 5)
		local v180_, _, v181_ = localToWorld(v139_, v171_, v172_, v142_ + 5)
		local v182_ = v178_ - v164_ * v174_
		local v183_ = v179_ - v162_ * v174_
		local v184_ = v178_ - v165_ * v177_
		local v185_ = v179_ - v163_ * v177_
		local v186_ = v180_ + v164_ * v174_
		local v187_ = v181_ + v162_ * v174_
		local v188_ = v180_ - v165_ * v177_
		local v189_ = v181_ - v163_ * v177_
		local v190_, v191_ = AIVehicleUtil.getAIAreaOfVehicle(v166_.object, v178_, v179_, v182_, v183_, v184_, v185_)
		local v192_, v193_ = AIVehicleUtil.getAIAreaOfVehicle(v166_.object, v180_, v181_, v186_, v187_, v188_, v189_)
		if v191_ > 0 then
			v144_ = v144_ + v190_ / v191_
		end
		if v193_ > 0 then
			v145_ = v145_ + v192_ / v193_
		end
		if VehicleDebug.state == VehicleDebug.DEBUG_AI then
			local v194_ = getTerrainHeightAtWorldPos(g_terrainNode, v178_, 0, v179_) + 2
			local v195_ = getTerrainHeightAtWorldPos(g_terrainNode, v182_, 0, v183_) + 2
			local v196_ = getTerrainHeightAtWorldPos(g_terrainNode, v184_, 0, v185_) + 2
			local v197_ = getTerrainHeightAtWorldPos(g_terrainNode, v180_, 0, v181_) + 2
			local v198_ = getTerrainHeightAtWorldPos(g_terrainNode, v186_, 0, v187_) + 2
			vehicle:addAIDebugLine({ v178_, v194_, v179_ }, { v182_, v195_, v183_ }, { 0.5, 0.5, 0.5 })
			vehicle:addAIDebugLine({ v178_, v194_, v179_ }, { v184_, v196_, v185_ }, { 0.5, 0.5, 0.5 })
			vehicle:addAIDebugLine({ v180_, v197_, v181_ }, { v186_, v198_, v187_ }, { 0.5, 0.5, 0.5 })
			vehicle:addAIDebugLine({ v180_, v197_, v181_ }, { v188_, getTerrainHeightAtWorldPos(g_terrainNode, v188_, 0, v189_) + 2, v189_ }, { 0.5, 0.5, 0.5 })
		end
	end
	return v144_ / #v140_, v145_ / #v140_
end

-- Local values: validGroundFound, _, implement, leftMarker, rightMarker, _, lX, _, lZ, rX, _, rZ, hX, hZ, area, areaTotal, lY, rY, hY
function AIVehicleUtil.checkImplementListForValidGround(vehicle, lookAheadDist, lookAheadSize)
	local v202_ = false
	for _, v203_ in pairs(vehicle:getAttachedAIImplements()) do
		local v204_, v205_, _ = v203_.object:getAIMarkers()
		local v206_, _, v207_ = getWorldTranslation(v204_)
		local v208_, _, v209_ = getWorldTranslation(v205_)
		local v210_ = v206_ + vehicle.aiDriveDirection[1] * lookAheadDist
		local v211_ = v207_ + vehicle.aiDriveDirection[2] * lookAheadDist
		local v212_ = v208_ + vehicle.aiDriveDirection[1] * lookAheadDist
		local v213_ = v209_ + vehicle.aiDriveDirection[2] * lookAheadDist
		local v214_ = v210_ + vehicle.aiDriveDirection[1] * lookAheadSize
		local v215_ = v211_ + vehicle.aiDriveDirection[2] * lookAheadSize
		local v216_, v217_ = AIVehicleUtil.getAIAreaOfVehicle(v203_.object, v210_, v211_, v212_, v213_, v214_, v215_)
		if VehicleDebug.state == VehicleDebug.DEBUG_AI then
			vehicle:addAIDebugText(string.format("area=%.1f areaTotal=%.1f", v216_, v217_))
			local v218_ = getTerrainHeightAtWorldPos(g_terrainNode, v210_, 0, v211_) + 2
			vehicle:addAIDebugLine({ v210_, v218_, v211_ }, { v212_, getTerrainHeightAtWorldPos(g_terrainNode, v212_, 0, v213_) + 2, v213_ }, { 1, 0, 0 })
			vehicle:addAIDebugLine({ v210_, v218_, v211_ }, { v214_, getTerrainHeightAtWorldPos(g_terrainNode, v214_, 0, v215_) + 2, v215_ }, { 1, 0, 0 })
		end
		v202_ = v202_ or v216_ > 0
	end
	return v202_
end

-- Local values: xOffsetLeft, xOffsetRight, lX, _, lZ, rX, _, rZ, sX, sZ, wX, wZ, hX, hZ
function AIVehicleUtil.getAreaDimensions(directionX, directionZ, leftNode, rightNode, xOffset, zOffset, areaSize, invertXOffset)
	local v227_
	if invertXOffset == nil or invertXOffset then
		v227_ = -xOffset
	else
		v227_ = xOffset
	end
	local v228_, _, v229_ = localToWorld(leftNode, v227_, 0, zOffset)
	local v230_, _, v231_ = localToWorld(rightNode, xOffset, 0, zOffset)
	return v228_ - 0.5 * directionX, v229_ - 0.5 * directionZ, v230_ - 0.5 * directionX, v231_ - 0.5 * directionZ, v228_ + areaSize * directionX, v229_ + areaSize * directionZ
end

-- Local values: farmId, centerX, centerZ
function AIVehicleUtil.getIsAreaOwned(vehicle, sX, sZ, wX, wZ, hX, hZ)
	local v237_ = vehicle:getAIJobFarmId()
	local v238_ = (sX + wX) * 0.5
	local v239_ = (sZ + wZ) * 0.5
	return g_farmlandManager:getIsOwnedByFarmAtWorldPosition(v237_, v238_, v239_) and true or (g_missionManager:getIsMissionWorkAllowed(v237_, v238_, v239_, nil, vehicle) and true or false)
end

-- Local values: useDensityHeightMap, query, isValid, densityHeightTypeRequirements
function AIVehicleUtil.getAIAreaOfVehicle(vehicle, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	if #vehicle:getAIDensityHeightTypeRequirements() > 0 then
		local v247_ = vehicle:getAIDensityHeightTypeRequirements()
		return AIVehicleUtil.getAIDensityHeightArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, v247_)
	else
		local v248_, v249_ = vehicle:getFieldCropsQuery()
		if v249_ then
			return AIVehicleUtil.getAIFruitArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, v248_)
		else
			return 0, 0
		end
	end
end

-- Local values: x, z, widthX, widthZ, heightX, heightZ
function AIVehicleUtil.getAIFruitArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, query)
	local v257_, v258_, v259_, v260_, v261_, v262_ = MathUtil.getXZWidthAndHeight(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	return query:getParallelogram(v257_, v258_, v259_, v260_, v261_, v262_, false)
end

-- Local values: _, detailArea, _, retArea, retTotalArea, _, densityHeightTypeRequirement, _, area, totalArea
function AIVehicleUtil.getAIDensityHeightArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, densityHeightTypeRequirements)
	local _, v270_, _ = FSDensityMapUtil.getFieldDensity(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	if v270_ == 0 then
		return 0, 0
	end
	local v271_ = 0
	local v272_ = 0
	for _, v273_ in pairs(densityHeightTypeRequirements) do
		if v273_.fillType ~= FillType.UNKNOWN then
			local v274_, v275_
			v274_, v275_, v272_ = DensityMapHeightUtil.getFillLevelAtArea(v273_.fillType, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
			v271_ = v271_ + v275_
		end
	end
	return v271_, v272_
end
