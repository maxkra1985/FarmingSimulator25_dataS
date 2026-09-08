PlaceableGreenhouse = {}
PlaceableGreenhouse.GROWTH_INTERVAL_MIN = 25200000
PlaceableGreenhouse.GROWTH_INTERVAL_MAX = 28800000
PlaceableGreenhouse.WATERING_INTERVAL_MIN = 10800000
PlaceableGreenhouse.WATERING_INTERVAL_MAX = 14400000
PlaceableGreenhouse.WATERING_DURATION = 600000
function PlaceableGreenhouse.getRandomGrowthInterval()
	return math.random(PlaceableGreenhouse.GROWTH_INTERVAL_MIN, PlaceableGreenhouse.GROWTH_INTERVAL_MAX)
end
function PlaceableGreenhouse.getRandomWateringInterval()
	return math.random(PlaceableGreenhouse.WATERING_INTERVAL_MIN, PlaceableGreenhouse.WATERING_INTERVAL_MAX)
end
PlaceableGreenhouse.plantXmlSchema = nil

function PlaceableGreenhouse.prerequisitesPresent(specializations)
	return true
end
function PlaceableGreenhouse.initSpecialization()
	local v1_ = XMLSchema.new("greenhousePlant")
	v1_:register(XMLValueType.STRING, "greenhousePlant.i3dFilename", "i3d file of plant")
	v1_:register(XMLValueType.NODE_INDEX, "greenhousePlant.stages.growing(?)#node", "Growing mesh")
	v1_:register(XMLValueType.NODE_INDEX, "greenhousePlant.stages.withered#node", "Withered mesh")
	I3DUtil.registerI3dMappingXMLPaths(v1_, "greenhousePlant")
	PlaceableGreenhouse.plantXmlSchema = v1_
end

function PlaceableGreenhouse.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "loadPlantFromXml", PlaceableGreenhouse.loadPlantFromXml)
	SpecializationUtil.registerFunction(placeableType, "plantI3DLoadedCallback", PlaceableGreenhouse.plantI3DLoadedCallback)
	SpecializationUtil.registerFunction(placeableType, "addPlantPlace", PlaceableGreenhouse.addPlantPlace)
	SpecializationUtil.registerFunction(placeableType, "updatePlantDistribution", PlaceableGreenhouse.updatePlantDistribution)
	SpecializationUtil.registerFunction(placeableType, "setPlantAtPlace", PlaceableGreenhouse.setPlantAtPlace)
	SpecializationUtil.registerFunction(placeableType, "updatePlantsStage", PlaceableGreenhouse.updatePlantsStage)
end

function PlaceableGreenhouse.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableGreenhouse)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableGreenhouse)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableGreenhouse)
	SpecializationUtil.registerEventListener(placeableType, "onOutputFillTypesChanged", PlaceableGreenhouse)
	SpecializationUtil.registerEventListener(placeableType, "onProductionStatusChanged", PlaceableGreenhouse)
	SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableGreenhouse)
end

function PlaceableGreenhouse.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Greenhouse")
	schema:register(XMLValueType.STRING, basePath .. ".greenhouse.plants.plant(?)#fillType", "FillType of plant")
	schema:register(XMLValueType.STRING, basePath .. ".greenhouse.plants.plant(?)#xmlFilename", "xml file of greenhouse plant")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".greenhouse.plantSpaces.space(?)#node", "node where plant is placed")
	schema:register(XMLValueType.BOOL, basePath .. ".greenhouse.plantSpaces.space(?)#useRandomYRot", "node is randomly rotated on the y axis", true)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".greenhouse.plantSpaces.spacesParent(?)#node", "parent node of nodes where plants are placed")
	schema:register(XMLValueType.BOOL, basePath .. ".greenhouse.plantSpaces.spacesParent(?)#useRandomYRot", "node is randomly rotated on the y axis", true)
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".greenhouse.sounds", "watering")
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".greenhouse.effectNodes")
	schema:setXMLSpecializationType()
end

-- Local values: spec, xmlFile, key, _, plantKey, fillTypeName, fillType, plantXmlFilename, plant, _, plantSpaceKey, plantPlaceNode, useRandomYRot, _, plantParentKey, parentNode, useRandomYRot, numChildren, i
function PlaceableGreenhouse:onLoad(savegame)
	local v_u_7_ = self.spec_greenhouse
	local v8_ = self.xmlFile
	v_u_7_.filltypeIdToPlant = {}
	v_u_7_.plantPlaces = {}
	v_u_7_.activeFilltypes = {}
	v_u_7_.hasWater = true
	v_u_7_.plantXMLFiles = {}
	for _, v9_ in v8_:iterator("placeable.greenhouse.plants.plant") do
		local v10_ = v8_:getValue(v9_ .. "#fillType")
		local v11_ = g_fillTypeManager:getFillTypeIndexByName(v10_)
		if v11_ == nil then
			Logging.xmlWarning(v8_, "Unknown fillType \'%s\' for plant \'%s\'", v10_, v9_)
		else
			local v12_ = v8_:getValue(v9_ .. "#xmlFilename")
			if v12_ ~= nil then
				local v13_ = self:loadPlantFromXml((Utils.getFilename(v12_, self.baseDirectory)))
				if v13_ ~= nil then
					v_u_7_.filltypeIdToPlant[v11_] = v13_
				end
			end
		end
	end
	for _, v14_ in v8_:iterator("placeable.greenhouse.plantSpaces.space") do
		local v15_ = self.xmlFile:getValue(v14_ .. "#node", nil, self.components, self.i3dMappings)
		local v16_ = self.xmlFile:getValue(v14_ .. "#useRandomYRot", true)
		if v15_ ~= nil then
			self:addPlantPlace(v15_, v16_)
		end
	end
	for _, v17_ in v8_:iterator("placeable.greenhouse.plantSpaces.spacesParent") do
		local v18_ = self.xmlFile:getValue(v17_ .. "#node", nil, self.components, self.i3dMappings)
		local v19_ = self.xmlFile:getValue(v17_ .. "#useRandomYRot", true)
		local v20_ = getNumOfChildren(v18_)
		if v20_ > 0 then
			for v21_ = 0, v20_ - 1 do
				self:addPlantPlace(getChildAt(v18_, v21_), v19_)
			end
		else
			Logging.xmlWarning(v8_, "No i3d child nodes for \'%s\'", v17_)
		end
	end
	if self.isClient then
		v_u_7_.samples = {}
		v_u_7_.samples.watering = g_soundManager:loadSampleFromXML(v8_, "placeable.greenhouse.sounds", "watering", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, nil)
		v_u_7_.effects = g_effectManager:loadEffect(v8_, "placeable.greenhouse.effectNodes", self.components, self, self.i3dMappings)
	end
	v_u_7_.growthTimer = Timer.new(PlaceableGreenhouse.getRandomGrowthInterval())
	v_u_7_.growthTimer:setFinishCallback(function(p22_)
		-- upvalues: (copy) self
		p22_:setDuration(PlaceableGreenhouse.getRandomGrowthInterval())
		self:updatePlantsStage()
	end)
	v_u_7_.growthTimer:setScaleFunction(function()
		return g_currentMission:getEffectiveTimeScale()
	end)
	v_u_7_.wateringTimer = Timer.new(PlaceableGreenhouse.getRandomWateringInterval())
	v_u_7_.wateringTimer:setFinishCallback(function(p23_)
		-- upvalues: (copy) v_u_7_
		if v_u_7_.hasWater then
			g_effectManager:startEffects(v_u_7_.effects)
			g_soundManager:playSample(v_u_7_.samples.watering)
			Timer.createOneshot(PlaceableGreenhouse.WATERING_DURATION, function()
				-- upvalues: (ref) v_u_7_
				g_effectManager:stopEffects(v_u_7_.effects)
				g_soundManager:stopSample(v_u_7_.samples.watering)
			end, function()
				return g_currentMission:getEffectiveTimeScale()
			end)
			p23_:start()
		end
	end)
	v_u_7_.wateringTimer:setScaleFunction(function()
		return g_currentMission:getEffectiveTimeScale()
	end)
end

-- Local values: spec
function PlaceableGreenhouse:addPlantPlace(node, useRandomYRot)
	local v27_ = self.spec_greenhouse
	if Utils.getNoNil(useRandomYRot, true) then
		setRotation(node, 0, math.random() * 3.141592653589793 * 2, 0)
	end
	local v28_ = v27_.plantPlaces
	table.insert(v28_, {
		["node"] = node,
		["fillType"] = nil,
		["stage"] = nil
	})
end

-- Local values: plant, plantXmlFile, spec, i3dFilename, loadingTask, arguments
function PlaceableGreenhouse:loadPlantFromXml(xmlFilename)
	local v31_ = {
		["i3dFilename"] = "",
		["i3dNode"] = nil,
		["stages"] = {
			["growing"] = {},
			["first"] = nil,
			["last"] = nil,
			["withered"] = nil
		}
	}
	local v32_ = XMLFile.load("plantXml", xmlFilename, PlaceableGreenhouse.plantXmlSchema)
	if v32_ ~= nil then
		self.spec_greenhouse.plantXMLFiles[v32_] = true
		local v33_ = v32_:getValue("greenhousePlant.i3dFilename")
		if v33_ ~= nil then
			v31_.i3dFilename = Utils.getFilename(v33_, self.baseDirectory)
			local v34_ = {
				["plant"] = v31_,
				["plantXmlFile"] = v32_,
				["loadingTask"] = self:createLoadingTask()
			}
			v31_.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v31_.i3dFilename, false, false, self.plantI3DLoadedCallback, self, v34_)
		end
	end
	return v31_
end

-- Local values: spec, plant, plantXmlFile, loadingTask, components, i3dMappings, witheredNode
function PlaceableGreenhouse:plantI3DLoadedCallback(i3dNode, failedReason, args)
	local v38_ = self.spec_greenhouse
	local v_u_39_ = args.plant
	local v_u_40_ = args.plantXmlFile
	local v41_ = args.loadingTask
	if i3dNode ~= 0 then
		local v_u_42_ = I3DUtil.loadI3DComponents(i3dNode)
		local v_u_43_ = I3DUtil.loadI3DMapping(v_u_40_, "greenhousePlant", v_u_42_)
		v_u_39_.i3dNode = i3dNode
		v_u_40_:iterate("greenhousePlant.stages.growing", function(_, p44_)
			-- upvalues: (copy) v_u_40_, (copy) v_u_42_, (copy) v_u_43_, (copy) v_u_39_
			local v45_ = v_u_40_:getValue(p44_ .. "#node", nil, v_u_42_, v_u_43_)
			if v45_ ~= nil then
				local v46_ = getChildIndex(v45_)
				local v47_ = v_u_39_.stages.growing
				table.insert(v47_, v46_)
			end
		end)
		v_u_39_.stages.first = v_u_39_.stages.growing[1]
		v_u_39_.stages.last = v_u_39_.stages.growing[#v_u_39_.stages.growing]
		local v48_ = v_u_40_:getValue("greenhousePlant.stages.withered#node", nil, v_u_42_, v_u_43_)
		if v48_ ~= nil then
			v_u_39_.stages.withered = getChildIndex(v48_)
		end
	end
	v_u_40_:delete()
	v38_.plantXMLFiles[v_u_40_] = nil
	self:finishLoadingTask(v41_)
end

-- Local values: spec, plantXMLFile, _, _, plant
function PlaceableGreenhouse:onDelete()
	local v50_ = self.spec_greenhouse
	if v50_.plantXMLFiles ~= nil then
		for v51_, _ in pairs(v50_.plantXMLFiles) do
			v51_:delete()
			v50_.plantXMLFiles[v51_] = nil
		end
	end
	if v50_.growthTimer ~= nil then
		v50_.growthTimer:delete()
	end
	if v50_.wateringTimer ~= nil then
		v50_.wateringTimer:delete()
	end
	if v50_.filltypeIdToPlant ~= nil then
		for _, v52_ in pairs(v50_.filltypeIdToPlant) do
			if v52_.sharedLoadRequestId ~= nil then
				g_i3DManager:releaseSharedI3DFile(v52_.sharedLoadRequestId)
			end
			if v52_.i3dNode ~= nil then
				delete(v52_.i3dNode)
				v52_.i3dNode = nil
			end
		end
	end
	g_effectManager:deleteEffects(v50_.effects)
	g_soundManager:deleteSamples(v50_.samples)
end

function PlaceableGreenhouse:onFinalizePlacement()
	self.plantDistributionDirty = true
	self.spec_greenhouse.wateringTimer:start()
end

function PlaceableGreenhouse:onUpdate()
	if self.plantDistributionDirty then
		self:updatePlantDistribution()
	end
end

-- Local values: spec, _, output, fillType
function PlaceableGreenhouse:onOutputFillTypesChanged(outputs, state)
	local v58_ = self.spec_greenhouse
	for _, v59_ in pairs(outputs) do
		local v60_ = v59_.type
		if state then
			if v58_.filltypeIdToPlant[v60_] ~= nil then
				v58_.activeFilltypes[v60_] = true
			end
		else
			v58_.activeFilltypes[v60_] = nil
		end
	end
	if self:getIsSynchronized() then
		self.plantDistributionDirty = true
	end
	self:raiseActive()
end

-- Local values: spec, hasWater
function PlaceableGreenhouse:onProductionStatusChanged(production, status)
	local v63_ = self.spec_greenhouse
	local v64_ = status ~= ProductionPoint.PROD_STATUS.MISSING_INPUTS
	if v63_.hasWater ~= v64_ then
		v63_.hasWater = v64_
		self:updatePlantsStage()
	end
	if v64_ and next(v63_.activeFilltypes) ~= nil then
		v63_.wateringTimer:startIfNotRunning()
	else
		v63_.wateringTimer:stop()
	end
end

-- Local values: spec, numActiveFilltypes, numPlaces, fillTypesList, i, fillType, plantPlace
function PlaceableGreenhouse:updatePlantDistribution()
	local v66_ = self.spec_greenhouse
	local v67_ = table.size(v66_.activeFilltypes)
	local v68_ = #v66_.plantPlaces
	local v69_ = table.toList(v66_.activeFilltypes)
	for v70_ = 1, v68_ do
		self:setPlantAtPlace(v69_[v70_ % v67_ + 1], v66_.plantPlaces[v70_])
	end
	self.plantDistributionDirty = false
	self:updatePlantsStage()
end

-- Local values: spec, i, plantStage, plant, plantClone, n, plantStage
function PlaceableGreenhouse:setPlantAtPlace(fillType, plantPlace)
	local v74_ = self.spec_greenhouse
	if plantPlace.fillType ~= fillType then
		if plantPlace.fillType ~= nil then
			for v75_ = getNumOfChildren(plantPlace.node) - 1, 0, -1 do
				local v76_ = getChildAt(plantPlace.node, v75_)
				delete(v76_)
			end
			plantPlace.fillType = nil
		end
		local v77_ = v74_.filltypeIdToPlant[fillType]
		if v77_ ~= nil then
			local v78_ = clone(getChildAt(v77_.i3dNode, 0), false, false, false)
			for v79_ = getNumOfChildren(v78_) - 1, 0, -1 do
				local v80_ = getChildAt(v78_, v79_)
				link(plantPlace.node, v80_, 0)
			end
			plantPlace.fillType = fillType
			plantPlace.stage = nil
			delete(v78_)
		end
	end
end

-- Local values: spec, i, plantPlace, plant, newStage, n, plantStage
function PlaceableGreenhouse:updatePlantsStage()
	local v82_ = self.spec_greenhouse
	if table.size(v82_.activeFilltypes) ~= 0 then
		if v82_.hasWater then
			v82_.growthTimer:start()
		else
			v82_.growthTimer:stop()
		end
		for v83_ = 1, #v82_.plantPlaces do
			local v84_ = v82_.plantPlaces[v83_]
			local v85_ = v82_.filltypeIdToPlant[v84_.fillType]
			local v86_
			if v82_.hasWater then
				v86_ = v84_.stage and v84_.stage + 1 or v85_.stages.first
				if v85_.stages.last < v86_ then
					v86_ = v85_.stages.first
				end
			else
				v86_ = v85_.stages.withered
			end
			if v84_.stage ~= v86_ then
				for v87_ = 0, getNumOfChildren(v84_.node) - 1 do
					local v88_ = getChildAt(v84_.node, v87_)
					setVisibility(v88_, v87_ == v86_)
				end
				v84_.stage = v86_
			end
		end
	end
end
