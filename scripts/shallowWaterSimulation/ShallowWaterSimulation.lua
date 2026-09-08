-- Local values: ShallowWaterSimulation_mt
ShallowWaterSimulation = {}
ShallowWaterSimulation.SHADER_CUSTOMMAP_NAME = "shallowWaterSimulationResult"
ShallowWaterSimulation.SHADER_CUSTOMMAP_VELOCITYU_NAME = "shallowWaterSimulationVelocityU"
ShallowWaterSimulation.SHADER_CUSTOMMAP_VELOCITYV_NAME = "shallowWaterSimulationVelocityV"
ShallowWaterSimulation.SHADER_PARAMETER_NAME = "simulationOffsetSize"
local ShallowWaterSimulation_mt = Class(ShallowWaterSimulation)
ShallowWaterSimulation.PROFILES = {
	["HIGH"] = { 512, 96 },
	["MEDIUM"] = { 256, 64 },
	["LOW"] = { 128, 64 }
}
function ShallowWaterSimulation.new()
	-- upvalues: (copy) ShallowWaterSimulation_mt
	local v2_ = ShallowWaterSimulation_mt
	local v3_ = setmetatable({}, v2_)
	v3_.waterSim = nil
	v3_.waterSimPos = { 0, 0 }
	v3_.waterPlanes = {}
	v3_.areaGeometries = {}
	v3_.obstacles = {}
	v3_.numActiveObstacles = 0
	v3_.waterSimulationTexture = nil
	v3_.waterSimulationVelocityUTexture = nil
	v3_.waterSimulationVelocityVTexture = nil
	return v3_
end

-- Local values: profileClass, profileSetting, allowSpilling
function ShallowWaterSimulation:load()
	self.foamAccumulationRate = 0.35
	self.foamDecayRate = 0.05
	local v5_ = Utils.getPerformanceClassId()
	local v6_
	if v5_ <= GS_PROFILE_LOW then
		v6_ = ShallowWaterSimulation.PROFILES.LOW
		if v5_ <= GS_PROFILE_MEDIUM then
			self.foamAccumulationRate = 0
		end
	elseif GS_PROFILE_HIGH <= v5_ then
		v6_ = ShallowWaterSimulation.PROFILES.HIGH
	else
		v6_ = ShallowWaterSimulation.PROFILES.MEDIUM
	end
	local v7_ = v6_[1]
	local v8_ = v6_[1]
	self.gridSizeX = v7_
	self.gridSizeZ = v8_
	local v9_ = v6_[2]
	local v10_ = v6_[2]
	self.sizeX = v9_
	self.sizeZ = v10_
	self.offsetDistance = self.sizeX / 3
	self.waterSim = createShallowWaterSimulation("shallowWaterSimulation", self.gridSizeX, self.gridSizeZ, self.sizeX, self.sizeZ, false)
	self.updateStepTime = 0.016666666666666666
	self.externalAcceleration = 1
	self.dampening = 0.998
	self.fakeExtraDepth = 5
	self.pmlDampeningFactor = 1
	self.pmlDampeningUpdateFactor = 0.5
	self.pmlDampeningDecay = 0.95
	self.pmlNumBorderCells = 16
	self:updateParameters()
	self.waterSimulationTexture = getShallowWaterSimulationOutputTexture(self.waterSim)
	self.waterSimulationVelocityUTexture = getShallowWaterSimulationOutputVelocityUTexture(self.waterSim)
	self.waterSimulationVelocityVTexture = getShallowWaterSimulationOutputVelocityVTexture(self.waterSim)
	addConsoleCommand("gsShallowWaterSimDebug", "Toggle shallow water simulation debug mode", "consoleCommandDebugToggle", self)
	addConsoleCommand("gsShallowWaterSimReset", "Reset water simulation", "consoleCommandReset", self)
	addConsoleCommand("gsShallowWaterSimParamSet", "Set water simulation parameters", "consoleCommandParamSet", self, "updateStepTime; externalAcceleration; dampening")
	addConsoleCommand("gsShallowWaterSimExtraDepthSet", "Set water simulation extra depth", "consoleCommandSetExtraDepth", self, "extraDepth")
	addConsoleCommand("gsShallowWaterSimPaint", "Paint shape on simulation", "consoleCommandPaint", self, "[circle|rect]; [velocityScale]; [radiusOrWidth]; [height]")
	addConsoleCommand("gsShallowWaterSimFoamParamSet", "Set water simulation foam parameters", "consoleCommandFoamParamSet", self, "accumulationRate; decayRate")
	addConsoleCommand("gsShallowWaterSimSizeSet", "Set water simulation size", "consoleCommandSizeSet", self, "simulation size in meters")
	addConsoleCommand("gsShallowWaterSimPMLParamSet", "Set perfectly matched layer boundary condition params", "consoleCommandPMLSet", self, "dampeningFactor; dampeningUpdateFactor; dampeningDecay; numBorderCells")
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.FRAME_LIMIT], self.updateParameters, self)
	return self
end

-- Local values: frameRateLimit
function ShallowWaterSimulation:updateParameters()
	self.updateStepTime = 1 / (g_gameSettings:getValue(GameSettings.SETTING.FRAME_LIMIT) or 60)
	if self.waterSim ~= nil then
		setShallowWaterSimulationParameters(self.waterSim, self.updateStepTime, self.externalAcceleration, self.dampening)
		setShallowWaterSimulationFakeExtraDepth(self.waterSim, self.fakeExtraDepth)
		setShallowWaterSimulationFoamAccumulationRate(self.waterSim, self.foamAccumulationRate)
		setShallowWaterSimulationFoamDecayRate(self.waterSim, self.foamDecayRate)
		setShallowWaterSimulationPerfectlyMatchedLayerParameters(self.waterSim, self.pmlDampeningFactor, self.pmlDampeningUpdateFactor, self.pmlDampeningDecay, self.pmlNumBorderCells, false, true, true, true, true)
	end
end

function ShallowWaterSimulation:delete()
	g_messageCenter:unsubscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.FRAME_LIMIT], self)
	if self.waterSim ~= nil then
		delete(self.waterSim)
		self.waterSim = nil
	end
	removeConsoleCommand("gsShallowWaterSimDebug")
	removeConsoleCommand("gsShallowWaterSimReset")
	removeConsoleCommand("gsShallowWaterSimParamSet")
	removeConsoleCommand("gsShallowWaterSimExtraDepthSet")
	removeConsoleCommand("gsShallowWaterSimPaint")
	removeConsoleCommand("gsShallowWaterSimFoamParamSet")
	removeConsoleCommand("gsShallowWaterSimSizeSet")
	removeConsoleCommand("gsShallowWaterSimPMLParamSet")
end

function ShallowWaterSimulation:onTerrainLoad(terrainRootNode, filename)
	setShallowWaterSimulationGroundHeightTextureFromTerrain(self.waterSim, terrainRootNode)
	Logging.devInfo("setShallowWaterSimulationGroundHeightTextureFromTerrain")
end

-- Local values: camera, camX, _, camZ, camDx, _, camDz, offsetX, offsetZ, waterPlane, obstacleIndex, obstacle, obstacleDistanceToCam, x, y, z, velocityX, velocityZ, obstacleHeight, rotY, xDir, _, zDir, text, text
function ShallowWaterSimulation:update(dt)
	if self.waterSim ~= nil then
		local v17_ = g_cameraManager:getActiveCamera()
		local v18_, _, v19_ = getWorldTranslation(v17_)
		local v20_, _, v21_ = localDirectionToWorld(v17_, 0, 0, -1)
		local v22_ = v18_ + self.offsetDistance * v20_
		local v23_ = v19_ + self.offsetDistance * v21_
		local v24_ = self.waterSimPos
		local v25_ = self.waterSimPos
		local v26_, v27_ = setShallowWaterSimulationWorldPosition(self.waterSim, v22_, v23_)
		v24_[1] = v26_
		v25_[2] = v27_
		local v28_ = self.waterSimPos[1] - self.sizeX / 2
		local v29_ = self.waterSimPos[2] - self.sizeZ / 2
		for v30_ in pairs(self.waterPlanes) do
			setShaderParameter(v30_, ShallowWaterSimulation.SHADER_PARAMETER_NAME, v28_, v29_, self.sizeX, self.sizeZ, false)
		end
		self.numActiveObstacles = 0
		for v31_, v32_ in ipairs(self.obstacles) do
			if calcDistanceFrom(v32_.node, v17_) <= self.sizeX then
				local v33_, v34_, v35_
				if v32_.offset == nil then
					v33_, v34_, v35_ = getWorldTranslation(v32_.node)
				else
					v33_, v34_, v35_ = localToWorld(v32_.node, v32_.offset[1] or 0, v32_.offset[2] or 0, v32_.offset[3] or 0)
				end
				local v36_ = v34_ - 0.05
				self.numActiveObstacles = self.numActiveObstacles + 1
				local v37_ = v36_ - v32_.sizeY / 2
				local v38_ = v32_.rotY
				local v39_, v40_
				if v32_.getXZVelocityAndRotYFunc == nil then
					v39_ = 0
					v40_ = 0
				else
					v39_, v40_, v38_ = v32_.getXZVelocityAndRotYFunc(v32_.getXZVelocityAndRotYFuncTarget)
				end
				if v38_ == nil then
					local v41_, _, v42_ = localDirectionToWorld(v32_.node, 0, 0, 1)
					v38_ = MathUtil.getYRotationFromDirection(v41_, v42_)
				end
				if v32_.obstacleType == ObstacleType.RECTANGLE then
					shallowWaterSimulationPaintCustomObstacle(self.waterSim, v31_, v33_, v35_, v32_.sizeX, v32_.sizeZ, v38_, v39_, v40_, v37_)
					if self.debugEnabled then
						self.debugBox:createWithWorldPosAndRot(v33_, v36_, v35_, 0, v38_, 0, v32_.sizeX, v32_.sizeY, v32_.sizeZ)
						local v43_ = DebugUtil.isPositionInCameraRange
						local v44_ = v32_.sizeX * 2
						local v45_ = v32_.sizeZ * 2
						if v43_(v33_, v36_, v35_, math.max(v44_, v45_, 25), v17_) then
							local v46_ = string.format("SWS obstacle %d %s\nvelX: %.3f velZ: %.3f\nrotY %d", v31_, getName(v32_.node), v39_, v40_, (math.deg(v38_)))
							self.debugBox:setText(v46_):setTextSize(0.012)
							DebugLine.renderBetweenPositions(v33_, v36_, v35_, v33_ + v39_ / 2, v36_, v35_ + v40_ / 2, nil, false)
						else
							self.debugBox:setText(nil)
						end
						self.debugBox:draw()
					end
				else
					shallowWaterSimulationPaintCustomObstacleEllipse(self.waterSim, v31_, v33_, v35_, v32_.sizeX, v32_.sizeZ, v38_, v39_, v40_, v37_)
					if self.debugEnabled then
						self.debugCylinder:createWithWorldPos(v33_, v36_, v35_, v32_.sizeX * 0.5, v32_.sizeY * 0.5, Axis.Y)
						local v47_ = DebugUtil.isPositionInCameraRange
						local v48_ = v32_.sizeX * 2
						local v49_ = v32_.sizeZ * 2
						if v47_(v33_, v36_, v35_, math.max(v48_, v49_, 25), v17_) then
							local v50_ = string.format("SWS obstacle %d %s\nvelX: %.3f velZ: %.3f\nrotY %d", v31_, getName(v32_.node), v39_, v40_, (math.deg(v38_)))
							self.debugCylinder:setText(v50_):setTextSize(0.012)
							DebugLine.renderBetweenPositions(v33_, v36_, v35_, v33_ + v39_ / 2, v36_, v35_ + v40_ / 2, nil, false)
						else
							self.debugCylinder:setText(nil)
						end
						self.debugCylinder:draw()
					end
				end
			end
		end
		updateShallowWaterSimulation(self.waterSim, dt)
	end
end

-- Local values: waterPlane, x, y, z, r, y, text, sx, sz, wx, wz, hx, hz, startY, drawLine, text, text, text, text, text, text, text, text, text, text, text, terrainDisplacementUploadInProgress, text
function ShallowWaterSimulation:drawDebug()
	if not g_gui:getIsGuiVisible() then
		for v52_ in pairs(self.waterPlanes) do
			local v53_, v54_, v55_, v56_ = getShapeWorldBoundingSphere(v52_)
			if DebugUtil.isPositionInCameraRange(v53_, v54_, v55_, v56_ + self.sizeX) then
				DebugShapeOutline.render(v52_)
			end
		end
		if g_terrainNode ~= nil then
			local v57_ = getTerrainHeightAtWorldPos(g_terrainNode, self.waterSimPos[1], 0, self.waterSimPos[2])
			local v58_ = string.format("water sim\ncenter %.2f %.2f", self.waterSimPos[1], self.waterSimPos[2])
			DebugPoint.renderAtPosition(self.waterSimPos[1], v57_, self.waterSimPos[2], nil, false, v58_)
			local v59_ = self.waterSimPos[1] - self.sizeX / 2
			local v60_ = self.waterSimPos[2] - self.sizeZ / 2
			local v61_ = self.waterSimPos[1] - self.sizeX / 2
			local v62_ = self.waterSimPos[2] + self.sizeZ / 2
			local v63_ = self.waterSimPos[1] + self.sizeX / 2
			local v64_ = self.waterSimPos[2] - self.sizeZ / 2
			DebugPlane.renderWithPositions(v59_, v57_, v60_, v61_, v57_, v62_, v63_, v57_, v64_, nil, false, false, false, false)
		end
		local v65_ = 0.6
		renderText(0.01, v65_, 0.02, "ShallowWaterSimulation")
		v65_ = v65_ - 0.02
		local v66_ = string.format("entity:%d sim-texture:%d velU-texture:%d velV-texture:%d", self.waterSim, self.waterSimulationTexture, self.waterSimulationVelocityUTexture, self.waterSimulationVelocityVTexture)
		renderText(0.01, v65_, 0.016, v66_)
		v65_ = v65_ - 0.016
		local v67_ = string.format("gridSize:%dx%d(pixels) size:%.1fx%.1f(m) => pixelSize:%.1fx%.1f(cm)", self.gridSizeX, self.gridSizeZ, self.sizeX, self.sizeZ, self.sizeX / self.gridSizeX * 100, self.sizeZ / self.gridSizeZ * 100)
		renderText(0.01, v65_, 0.016, v67_)
		v65_ = v65_ - 0.016
		local v68_ = string.format("updateStepTime:%.2fms externalAcceleration:%.2fm/s\194\178 dampening:%.4f", self.updateStepTime * 1000, self.externalAcceleration, self.dampening)
		renderText(0.01, v65_, 0.016, v68_)
		v65_ = v65_ - 0.016
		local v69_ = string.format("extraFakeDepth:%.3fm", getShallowWaterSimulationFakeExtraDepth(self.waterSim))
		renderText(0.01, v65_, 0.016, v69_)
		v65_ = v65_ - 0.016
		local v70_ = string.format("foam accumulationRate:%.3f decayRate:%.3f", getShallowWaterSimulationFoamAccumulationRate(self.waterSim), getShallowWaterSimulationFoamDecayRate(self.waterSim))
		renderText(0.01, v65_, 0.016, v70_)
		v65_ = v65_ - 0.016
		renderText(0.01, v65_, 0.016, "perfectlyMatchedLayerParameters:")
		v65_ = v65_ - 0.016
		local v71_ = string.format("    dampeningFactor: %.2f", self.pmlDampeningFactor)
		renderText(0.01, v65_, 0.016, v71_)
		v65_ = v65_ - 0.016
		local v72_ = string.format("    dampeningUpdateFactor: %.2f", self.pmlDampeningUpdateFactor)
		renderText(0.01, v65_, 0.016, v72_)
		v65_ = v65_ - 0.016
		local v73_ = string.format("    dampeningDecay: %.2f", self.pmlDampeningDecay)
		renderText(0.01, v65_, 0.016, v73_)
		v65_ = v65_ - 0.016
		local v74_ = string.format("    numBorderCells: %d", self.pmlNumBorderCells)
		renderText(0.01, v65_, 0.016, v74_)
		v65_ = v65_ - 0.016
		local v75_ = string.format("numObstacles: %d registered, %d active/in range", #self.obstacles, self.numActiveObstacles)
		renderText(0.01, v65_, 0.016, v75_)
		v65_ = v65_ - 0.016
		local v76_ = string.format("numWaterPlanes: %d", table.size(self.waterPlanes))
		renderText(0.01, v65_, 0.016, v76_)
		v65_ = v65_ - 0.016
		local v77_ = getTerrainDisplacementUploadInProgress()
		if v77_ then
			setTextColor(1, 0, 0, 1)
		end
		local v78_ = string.format("terrainDisplacementUploadInProgress: %s", (tostring(v77_)))
		renderText(0.01, v65_, 0.016, v78_)
		v65_ = v65_ - 0.016
		setTextColor(1, 1, 1, 1)
	end
end

-- Local values: waterPlaneMat
function ShallowWaterSimulation:addWaterPlane(shapeId)
	if self.waterSimulationTexture == nil then
		Logging.error("ShallowWaterSimulation:addWaterPlane(): water simulation system / texture not initialized yet")
		return false
	end
	if self.waterSimulationVelocityUTexture == nil then
		Logging.error("ShallowWaterSimulation:addWaterPlane(): water simulation system / texture not initialized yet (velocity U texture missing)")
		return false
	end
	if self.waterSimulationVelocityVTexture == nil then
		Logging.error("ShallowWaterSimulation:addWaterPlane(): water simulation system / texture not initialized yet (velocity V texture missing)")
		return false
	end
	if not getHasShaderParameter(shapeId, ShallowWaterSimulation.SHADER_PARAMETER_NAME) then
		Logging.i3dWarning(shapeId, "ShallowWaterSimulation:addWaterPlane(): shape is missing \'%s\' shader parameter used by SWS. Ignoring", ShallowWaterSimulation.SHADER_PARAMETER_NAME)
		return false
	end
	local v81_ = getMaterial(shapeId, 0)
	setMaterialCustomMap(v81_, ShallowWaterSimulation.SHADER_CUSTOMMAP_NAME, self.waterSimulationTexture, true)
	setMaterialCustomMap(v81_, ShallowWaterSimulation.SHADER_CUSTOMMAP_VELOCITYU_NAME, self.waterSimulationVelocityUTexture, true)
	setMaterialCustomMap(v81_, ShallowWaterSimulation.SHADER_CUSTOMMAP_VELOCITYV_NAME, self.waterSimulationVelocityVTexture, true)
	self.waterPlanes[shapeId] = true
	if self.debugEnabled then
		self:enableWaterPlaneDebugMode(shapeId)
	end
	return true
end

function ShallowWaterSimulation:removeWaterPlane(shape)
	if self.waterPlanes[shape] == nil then
		Logging.warning("Cannot remove water plane \'%s\' (%d), not registered in simulation or already removed", getName(shape), shape)
	else
		self.waterPlanes[shape] = nil
	end
end

function ShallowWaterSimulation:addAreaGeometry(shape)
	if self.areaGeometries[shape] ~= nil then
		Logging.warning("Shape \'%s\' (%d) was already to shallow water simulation", getName(shape), shape)
		return false
	end
	shallowWaterSimulationAddWaterPlaneGeometry(self.waterSim, shape)
	self.areaGeometries[shape] = true
	return true
end

function ShallowWaterSimulation:removeAreaGeometry(shape)
	if self.areaGeometries[shape] == nil then
		Logging.warning("Cannot remove water area geometry \'%s\' (%d), not registered in simulation or already removed", getName(shape), shape)
	else
		shallowWaterSimulationRemoveWaterPlaneGeometry(self.waterSim, shape)
		self.areaGeometries[shape] = nil
	end
end

-- Local values: obstacle
function ShallowWaterSimulation:addObstacle(nodeId, sizeX, sizeY, sizeZ, getXZVelocityAndRotYFunc, getXZVelocityAndRotYFuncTarget, offset, rotY, obstacleType)
	if entityExists(nodeId) then
		if type(sizeX) == "number" and (type(sizeY) == "number" and type(sizeZ) == "number") then
			if offset == nil or type(offset) == "table" then
				local v98_ = {
					["obstacleType"] = obstacleType or ObstacleType.RECTANGLE,
					["node"] = nodeId,
					["sizeX"] = sizeX,
					["sizeY"] = sizeY,
					["sizeZ"] = sizeZ,
					["rotY"] = rotY,
					["getXZVelocityAndRotYFunc"] = getXZVelocityAndRotYFunc,
					["getXZVelocityAndRotYFuncTarget"] = getXZVelocityAndRotYFuncTarget,
					["offset"] = offset,
					["inRange"] = false
				}
				local v99_ = self.obstacles
				table.insert(v99_, v98_)
				return v98_
			end
			Logging.error("ShallowWaterSimulation:addObstacle(): Invalid \'offset\' given, must be table")
		else
			Logging.error("ShallowWaterSimulation:addObstacle(): Invalid size given given: %s %s %s", sizeX, sizeY, sizeZ)
		end
	else
		Logging.error("ShallowWaterSimulation:addObstacle(): Given nodeId %q does not exist", nodeId)
		return
	end
end

-- Local values: success
function ShallowWaterSimulation:removeObstacle(obstacle)
	local v102_ = table.removeElement(self.obstacles, obstacle)
	if not v102_ then
		Logging.warning("Unable to remove obstacle, not found")
	end
	return v102_
end

function ShallowWaterSimulation:paintCircle(x, y, z, radius, velocityX, velocityZ)
	shallowWaterSimulationPaintVelocityCircle(self.waterSim, x, z, radius, velocityX, velocityZ, y)
end

function ShallowWaterSimulation:paintRectangle(x, y, z, width, height, velocityX, velocityZ)
	shallowWaterSimulationPaintVelocityRect(self.waterSim, x, z, width, height, velocityX, velocityZ, y)
end

function ShallowWaterSimulation:reset()
	shallowWaterSimulationResetSimulation(self.waterSim)
end

function ShallowWaterSimulation:enableWaterPlaneDebugMode(waterPlane)
	self.debugWaterPlaneAlphaBackup = self.debugWaterPlaneAlphaBackup or {}
	self.debugWaterPlaneAlphaBackup[waterPlane] = getShaderParameter(waterPlane, "alpha")
	setShaderParameter(waterPlane, "alpha", 0.9, 0, 0, 0, false)
end

-- Local values: waterPlane, waterPlane, alpha
function ShallowWaterSimulation:consoleCommandDebugToggle()
	self.debugEnabled = not self.debugEnabled
	if self.debugEnabled then
		self.debugBox = DebugBox.new()
		self.debugCylinder = DebugCylinder.new()
		g_debugManager:addDrawable(self)
		for v122_ in pairs(self.waterPlanes) do
			self:enableWaterPlaneDebugMode(v122_)
		end
	else
		g_debugManager:removeDrawable(self)
		self.debugBox = nil
		self.debugCylinder = nil
		if self.debugWaterPlaneAlphaBackup ~= nil then
			for v123_, v124_ in pairs(self.debugWaterPlaneAlphaBackup) do
				setShaderParameter(v123_, "alpha", v124_, 0, 0, 0, false)
			end
			self.debugWaterPlaneAlphaBackup = nil
		end
	end
end

function ShallowWaterSimulation:consoleCommandReset()
	self:reset()
	return "Reset shallow water simulation"
end

function ShallowWaterSimulation:consoleCommandFoamParamSet(accumulationRate, decayRate)
	self.foamAccumulationRate = tonumber(accumulationRate) or self.foamAccumulationRate
	self.foamDecayRate = tonumber(decayRate) or self.foamDecayRate
	setShallowWaterSimulationFoamAccumulationRate(self.waterSim, self.foamAccumulationRate)
	setShallowWaterSimulationFoamDecayRate(self.waterSim, self.foamDecayRate)
	return "Updated shallow water simulation foam parameters"
end

function ShallowWaterSimulation:consoleCommandParamSet(updateStepTime, externalAcceleration, dampening)
	self.updateStepTime = tonumber(updateStepTime) or self.updateStepTime
	self.externalAcceleration = tonumber(externalAcceleration) or self.externalAcceleration
	self.dampening = tonumber(dampening) or self.dampening
	setShallowWaterSimulationParameters(self.waterSim, self.updateStepTime, self.externalAcceleration, self.dampening)
	return "Updated shallow water simulation parameters"
end

function ShallowWaterSimulation:consoleCommandSetExtraDepth(extraDepth)
	local v135_ = tonumber(extraDepth)
	if v135_ == nil then
		return string.format("Current shallow water simulation extraDepth %.3f", getShallowWaterSimulationFakeExtraDepth(self.waterSim))
	end
	setShallowWaterSimulationFakeExtraDepth(self.waterSim, v135_)
	return string.format("Updated shallow water simulation extraDepth %.3f", getShallowWaterSimulationFakeExtraDepth(self.waterSim))
end

function ShallowWaterSimulation:consoleCommandSizeSet(sizeM)
	local v138_ = tonumber(sizeM)
	if v138_ == nil then
		return string.format("Current shallow water simulation size %dx%dm", self.sizeX, self.sizeZ)
	end
	setShallowWaterSimulationPhysicalGridSize(self.waterSim, v138_, v138_)
	self.sizeX = v138_
	self.sizeZ = v138_
	return string.format("Updated shallow water simulation size to %dx%dm", v138_, v138_)
end

function ShallowWaterSimulation:consoleCommandPMLSet(dampeningFactor, dampeningUpdateFactor, dampeningDecay, numBorderCells)
	local v144_ = tonumber(dampeningFactor)
	local v145_ = tonumber(dampeningUpdateFactor)
	local v146_ = tonumber(dampeningDecay)
	local v147_ = tonumber(numBorderCells)
	if v144_ == nil or (v145_ == nil or (v146_ == nil or v147_ == nil)) then
		return string.format("Current shallow water simulation pml settings: %.4f %.4f %.4f %d", self.pmlDampeningFactor, self.pmlDampeningUpdateFactor, self.pmlDampeningDecay, self.pmlNumBorderCells)
	end
	self.pmlDampeningFactor = v144_
	self.pmlDampeningUpdateFactor = v145_
	self.pmlDampeningDecay = v146_
	self.pmlNumBorderCells = v147_
	setShallowWaterSimulationPerfectlyMatchedLayerParameters(self.waterSim, v144_, v145_, v146_, v147_, false, true, true, true, true)
	return string.format("Current shallow water simulation pml settings: %.4f%.4f%.4f%d", v144_, v145_, v146_, v147_)
end

-- Local values: usage, shapeTypes, x, y, z, dx, dy, dz, node, hx, hy, hz
function ShallowWaterSimulation:consoleCommandPaint(shapeType, velocityScale, radiusOrWidth, height)
	local v153_ = {
		["circle"] = true,
		["rect"] = true
	}
	local v154_ = tonumber(velocityScale) or 3
	local v155_ = shapeType or "circle"
	if v153_[v155_] ~= nil then
		local v156_ = tonumber(radiusOrWidth) or 2
		local v157_ = tonumber(height) or 2
		local v158_, v159_, v160_, v161_, v162_, v163_ = RaycastUtil.getCameraPickingRay(0.5, 0.6, g_cameraManager:getActiveCamera())
		local v164_, v165_, v166_, v167_ = RaycastUtil.raycastClosest(v158_, v159_, v160_, v161_, v162_, v163_, 200, CollisionFlag.WATER)
		if v164_ == nil then
			return "No water plane found"
		end
		if v155_ == "circle" then
			self:paintCircle(v165_, v166_ - 0.1, v167_, v156_, v161_ * v154_, v163_ * v154_)
		else
			self:paintRectangle(v165_, v166_ - 0.1, v167_, v156_, v157_, v161_ * v154_, v163_ * v154_)
		end
		return string.format("Painted \'%s\' at %f %f %f", v155_, v165_, v166_, v167_)
	end
	Logging.error("Error: unknown shapeType \'%s\', available shapes: %s", v155_, table.concatKeys(v153_, ", "))
	print("Usage: gsShallowWaterSimPaint circle|rect velocityScale radiusOrWidth height")
end
