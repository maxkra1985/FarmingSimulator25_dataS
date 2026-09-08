PlaceableHeapSpawner = {}

function PlaceableHeapSpawner.prerequisitesPresent(specializations)
	return true
end

function PlaceableHeapSpawner.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHeapSpawner)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHeapSpawner)
	SpecializationUtil.registerEventListener(placeableType, "onUpdateTick", PlaceableHeapSpawner)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHeapSpawner)
end

function PlaceableHeapSpawner.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("PlaceableHeapSpawner")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".heapSpawner.spawnArea(?).area#startNode", "")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".heapSpawner.spawnArea(?).area#widthNode", "")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".heapSpawner.spawnArea(?).area#heightNode", "")
	schema:register(XMLValueType.STRING, basePath .. ".heapSpawner.spawnArea(?)#fillType", "Spawn fill type")
	schema:register(XMLValueType.FLOAT, basePath .. ".heapSpawner.spawnArea(?)#litersPerHour", "Spawn liters per ingame hour")
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".heapSpawner.spawnArea(?).effectNodes")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".heapSpawner.spawnArea(?).sounds", "work")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".heapSpawner.spawnArea(?).sounds", "work2")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".heapSpawner.spawnArea(?).sounds", "dropping")
	AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".heapSpawner.spawnArea(?).animationNodes")
	schema:setXMLSpecializationType()
end

-- Local values: spec, key, _, areaKey, startNode, widthNode, heightNode, fillTypeName, fillTypeIndex, litersPerHour, spawnArea
function PlaceableHeapSpawner:onLoad(savegame)
	local v5_ = self.spec_heapSpawner
	v5_.spawnAreas = {}
	for _, v6_ in self.xmlFile:iterator("placeable.heapSpawner.spawnArea") do
		local v7_ = self.xmlFile:getValue(v6_ .. ".area#startNode", nil, self.components, self.i3dMappings)
		if v7_ == nil then
			Logging.xmlError(self.xmlFile, "Missing startNode for spawnArea \'%s\'", v6_)
		else
			local v8_ = self.xmlFile:getValue(v6_ .. ".area#widthNode", nil, self.components, self.i3dMappings)
			if v8_ == nil then
				Logging.xmlError(self.xmlFile, "Missing widthNode for spawnArea \'%s\'", v6_)
			else
				local v9_ = self.xmlFile:getValue(v6_ .. ".area#heightNode", nil, self.components, self.i3dMappings)
				if v9_ == nil then
					Logging.xmlError(self.xmlFile, "Missing heightNode for spawnArea \'%s\'", v6_)
				else
					local v10_ = self.xmlFile:getValue(v6_ .. "#fillType", "")
					local v11_ = g_fillTypeManager:getFillTypeIndexByName(v10_)
					if v11_ == nil then
						Logging.xmlError(self.xmlFile, "Missing or invalid fillType (%s) for spawnArea \'%s\'", v10_, v6_)
					else
						local v12_ = self.xmlFile:getValue(v6_ .. "#litersPerHour", 150)
						if v12_ <= 0 then
							Logging.xmlError(self.xmlFile, "litersPerHour may not be 0 or negative for spawnArea \'%s\'", v6_)
						else
							local v13_ = {
								["start"] = v7_,
								["width"] = v8_,
								["height"] = v9_,
								["fillTypeIndex"] = v11_,
								["litersPerMs"] = v12_ / 3600000,
								["amountToTip"] = 0,
								["lineOffset"] = 0
							}
							if self.isClient then
								v13_.effects = g_effectManager:loadEffect(self.xmlFile, v6_ .. ".effectNodes", self.components, self, self.i3dMappings)
								g_effectManager:setEffectTypeInfo(v13_.effects, v11_)
								g_effectManager:startEffects(v13_.effects)
								v13_.samples = {}
								v13_.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, v6_ .. ".sounds", "work", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
								v13_.samples.work2 = g_soundManager:loadSampleFromXML(self.xmlFile, v6_ .. ".sounds", "work2", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
								v13_.samples.dropping = g_soundManager:loadSampleFromXML(self.xmlFile, v6_ .. ".sounds", "dropping", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
								g_soundManager:playSample(v13_.samples.work, 0)
								g_soundManager:playSample(v13_.samples.work2, 0)
								g_soundManager:playSample(v13_.samples.dropping, 0)
								v13_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, v6_ .. ".animationNodes", self.components, self, self.i3dMappings)
								g_animationManager:startAnimations(v13_.animationNodes)
							end
							local v14_ = v5_.spawnAreas
							table.insert(v14_, v13_)
						end
					end
				end
			end
		end
	end
end

function PlaceableHeapSpawner:onFinalizePlacement(savegame)
	if self.isServer then
		self:raiseActive()
	end
end

-- Local values: spec, _, spawnArea
function PlaceableHeapSpawner:onDelete()
	local v17_ = self.spec_heapSpawner
	if v17_.spawnAreas ~= nil then
		for _, v18_ in ipairs(v17_.spawnAreas) do
			g_effectManager:deleteEffects(v18_.effects)
			g_soundManager:deleteSamples(v18_.samples)
			g_animationManager:deleteAnimations(v18_.animationNodes)
		end
	end
end

-- Local values: spec, scaledDt, _, spawnArea, amountToTip, lsx, lsy, lsz, lex, ley, lez, radius, _, lineOffset
function PlaceableHeapSpawner:onUpdateTick(dt)
	if self.isServer then
		local v21_ = self.spec_heapSpawner
		local v22_ = dt * g_currentMission:getEffectiveTimeScale()
		for _, v23_ in ipairs(v21_.spawnAreas) do
			local v24_ = v22_ * v23_.litersPerMs
			v23_.amountToTip = v23_.amountToTip + v24_
			if v23_.amountToTip > g_densityMapHeightManager:getMinValidLiterValue(v23_.fillTypeIndex) then
				local v25_, v26_, v27_, v28_, v29_, v30_, v31_ = DensityMapHeightUtil.getLineByArea(v23_.start, v23_.width, v23_.height, false)
				local _, v32_ = DensityMapHeightUtil.tipToGroundAroundLine(nil, v23_.amountToTip, v23_.fillTypeIndex, v25_, v26_, v27_, v28_, v29_, v30_, v31_, v31_, v23_.lineOffset, nil, nil, nil)
				v23_.lineOffset = v32_
				v23_.amountToTip = 0
			end
		end
		self:raiseActive()
	end
end

-- Local values: _, spawnArea, fillTypesNamesString
function PlaceableHeapSpawner.loadSpecValueFillTypes(xmlFile, customEnvironment, baseDir, fillTypeNamesSet)
	for _, v35_ in xmlFile:iterator("placeable.heapSpawner.spawnArea") do
		local v36_ = xmlFile:getValue(v35_ .. "#fillType")
		if v36_ then
			fillTypeNamesSet = fillTypeNamesSet or {}
			fillTypeNamesSet[string.upper(v36_)] = true
		end
	end
	return fillTypeNamesSet
end
