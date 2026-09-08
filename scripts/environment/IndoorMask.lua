-- Local values: IndoorMask_mt
IndoorMask = {}
IndoorMask.NUM_CHANNELS = 1
IndoorMask.FIRST_CHANNEL = 0
IndoorMask.INDOOR = 1
IndoorMask.OUTDOOR = 0
IndoorMask.COLORS = {
	[IndoorMask.INDOOR] = Color.new(1, 0, 0, 0.15),
	[IndoorMask.OUTDOOR] = Color.new(0, 1, 0, 0.15)
}
local IndoorMask_mt = Class(IndoorMask)

-- Upvalues: IndoorMask_mt
-- Local values: self
function IndoorMask.new(mission, isServer, customMt)
	-- upvalues: (copy) IndoorMask_mt
	local v5_ = customMt or IndoorMask_mt
	local v6_ = setmetatable({}, v5_)
	v6_.mission = mission
	v6_.isServer = isServer
	v6_.visualizeMask = false
	v6_.handle = nil
	v6_.layerName = "indoorMask"
	if g_addCheatCommands then
		addConsoleCommand("gsIndoorMaskToggle", "Toggle indoor mask visualization", "consoleCommandToggleMask", v6_)
	end
	return v6_
end

function IndoorMask:delete()
	g_messageCenter:unsubscribeAll(self)
	if g_addCheatCommands then
		removeConsoleCommand("gsIndoorMaskToggle")
	end
end

function IndoorMask:loadMapData(xmlFile, missionInfo, baseDirectory) end

function IndoorMask:onTerrainLoad(terrainRootNode)
	self.handle = getInfoLayerFromTerrain(terrainRootNode, self.layerName)
	if self.handle == nil or self.handle == 0 then
		self.handle = 0
		Logging.error("Layer \'%s\' is missing for current map!", self.layerName)
	end
	self.terrainSize = self.mission.terrainSize
	self.terrainSizeHalf = self.terrainSize / 2
	if self.handle ~= nil then
		self.maskSize = getBitVectorMapSize(self.handle)
		self.modifierValue = DensityMapModifier.new(self.handle, IndoorMask.FIRST_CHANNEL, IndoorMask.NUM_CHANNELS)
		self.filter = DensityMapFilter.new(self.modifierValue)
		self.worldToDensityMap = self.maskSize / self.terrainSize
		self.densityToWorldMap = self.terrainSize / self.maskSize
	end
end

-- Local values: terrainSizeHalf, worldToDensityMap, densityToWorldMap, sizePixelsHalf, x, _, z, vehicle, xI, zI, minXi, minZi, maxXi, maxZi, areaSize, zi, xi, v, color, xt, zt
function IndoorMask:drawDebug()
	if not g_gui:getIsGuiVisible() or g_gui.currentGuiName == "ConstructionScreen" then
		if self.handle ~= nil then
			local v11_ = self.terrainSizeHalf
			local v12_ = self.worldToDensityMap
			local v13_ = self.densityToWorldMap
			local v14_, _, v15_ = getWorldTranslation(g_cameraManager:getActiveCamera())
			local v16_ = g_localPlayer:getCurrentVehicle()
			if v16_ ~= nil then
				if v16_.selectedImplement ~= nil then
					v16_ = v16_.selectedImplement.object
				end
				local v17_
				v14_, v17_, v15_ = getWorldTranslation(v16_.components[1].node)
			end
			local v18_ = (v14_ + v11_) * v12_
			local v19_ = math.floor(v18_)
			local v20_ = (v15_ + v11_) * v12_
			local v21_ = math.floor(v20_)
			local v22_ = v19_ - 20
			local v23_ = math.max(v22_, 0)
			local v24_ = v21_ - 20
			local v25_ = math.max(v24_, 0)
			local v26_ = v19_ + 20
			local v27_ = self.maskSize - 1
			local v28_ = math.min(v26_, v27_)
			local v29_ = v21_ + 20
			local v30_ = self.maskSize - 1
			local v31_ = math.min(v29_, v30_)
			local v32_ = self.terrainSize / self.maskSize
			for v33_ = v25_, v31_ do
				for v34_ = v23_, v28_ do
					local v35_ = getBitVectorMapPoint(self.handle, v34_, v33_, IndoorMask.FIRST_CHANNEL, IndoorMask.NUM_CHANNELS)
					local v36_ = IndoorMask.COLORS[v35_]
					local v37_ = v34_ * v13_ - v11_
					local v38_ = v33_ * v13_ - v11_
					DebugPlane.renderWithPositions(v37_, 0, v38_, v37_, 0, v38_ + v32_, v37_ + v32_, 0, v38_, v36_, true, true)
				end
			end
		end
	end
end

function IndoorMask:hasMask()
	return self.handle ~= nil
end

function IndoorMask:getFilter(indoorOutdoor)
	if self.handle == nil then
		return nil
	end
	self.filter:setValueCompareParams(DensityValueCompareType.EQUAL, indoorOutdoor)
	return self.filter
end

-- Local values: x, z, value
function IndoorMask:getIsIndoorAtWorldPosition(wx, wz)
	if self.handle == nil then
		return false
	end
	local v45_ = (wx + self.terrainSizeHalf) * self.worldToDensityMap
	local v46_ = math.floor(v45_)
	local v47_ = (wz + self.terrainSizeHalf) * self.worldToDensityMap
	local v48_ = math.floor(v47_)
	return getBitVectorMapPoint(self.handle, v46_, v48_, IndoorMask.FIRST_CHANNEL, IndoorMask.NUM_CHANNELS) == IndoorMask.INDOOR
end

-- Local values: x, _, z, x1, _, z1, x2, _, z2
function IndoorMask:setStateByArea(area, indoor)
	if self.handle ~= nil then
		local v52_, _, v53_ = getWorldTranslation(area.start)
		local v54_, _, v55_ = getWorldTranslation(area.width)
		local v56_, _, v57_ = getWorldTranslation(area.height)
		self:setParallelogramUVCoords(self.modifierValue, v52_, v53_, v54_, v55_, v56_, v57_)
		self.modifierValue:executeSet(indoor)
	end
end

-- Local values: terrainSize
function IndoorMask:setParallelogramUVCoords(modifier, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v66_ = self.terrainSize
	modifier:setParallelogramUVCoords(startWorldX / v66_ + 0.5, startWorldZ / v66_ + 0.5, widthWorldX / v66_ + 0.5, widthWorldZ / v66_ + 0.5, heightWorldX / v66_ + 0.5, heightWorldZ / v66_ + 0.5, DensityCoordType.POINT_POINT_POINT)
end

function IndoorMask:getDensityMapData()
	return self.handle, IndoorMask.FIRST_CHANNEL, IndoorMask.NUM_CHANNELS
end

function IndoorMask:consoleCommandToggleMask()
	self.visualizeMask = not self.visualizeMask
	if self.visualizeMask then
		g_debugManager:addDrawable(self)
	else
		g_debugManager:removeDrawable(self)
	end
	local v69_ = self.visualizeMask
	return "visualizeMask=" .. tostring(v69_)
end
