Crawlers = {}
Crawlers.VRAM_PER_CRAWLER = 1572864
Crawlers.MAX_UPDATE_DISTANCE = 300
Crawlers.MAX_UPDATE_DISTANCE_ALIGNMENT = 50
Crawlers.xmlSchema = nil

function Crawlers.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Wheels, specializations)
end
function Crawlers.initSpecialization()
	g_storeManager:addVRamUsageFunction(Crawlers.getVRamUsageFromXML)
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("Crawlers")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)#linkNode", "Link node")
	v2_:register(XMLValueType.NODE_INDICES, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)#linkWheelNodes", "Back and front wheels which are used to link the crawler. Wheels are also used for speed reference.")
	v2_:register(XMLValueType.BOOL, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)#isLeft", "Is left crawler", false)
	v2_:register(XMLValueType.FLOAT, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)#trackWidth", "Track width", 1)
	v2_:register(XMLValueType.BOOL, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)#hasShallowWaterObstacle", "Crawler has a shallow water obstacle between the defined wheels")
	v2_:register(XMLValueType.STRING, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)#filename", "Crawler filename")
	v2_:register(XMLValueType.VECTOR_TRANS, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)#offset", "Crawler position offset")
	v2_:register(XMLValueType.INT, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)#wheelIndex", "Speed reference wheel index")
	v2_:register(XMLValueType.VECTOR_N, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)#wheelIndices", "Multiple speed reference wheels. The average speed of the wheels WITH ground contact is used")
	v2_:register(XMLValueType.NODE_INDICES, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)#wheelNodes", "Multiple speed reference wheels (defined by any node of the wheel). The average speed of the wheels WITH ground contact is used")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)#speedReferenceNode", "Speed reference node")
	v2_:register(XMLValueType.FLOAT, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)#fieldDirtMultiplier", "Field dirt multiplier", 75)
	v2_:register(XMLValueType.FLOAT, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)#streetDirtMultiplier", "Street dirt multiplier", -150)
	v2_:register(XMLValueType.FLOAT, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)#waterWetnessFactor", "Factor for crawler wetness while driving in water", 20)
	v2_:register(XMLValueType.FLOAT, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)#minDirtPercentage", "Min. dirt while getting clean on non field ground", 0.35)
	v2_:register(XMLValueType.FLOAT, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)#maxDirtOffset", "Max. dirt amount offset to global dirt node", 0.5)
	v2_:register(XMLValueType.FLOAT, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)#dirtColorChangeSpeed", "Defines speed to change the dirt color (sec)", 20)
	VehicleMaterial.registerXMLPaths(v2_, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?).rimMaterial")
	v2_:setXMLSpecializationType()
	local v3_ = XMLSchema.new("crawler")
	v3_:shareDelayedRegistrationFuncs(v2_)
	v3_:register(XMLValueType.STRING, "crawler.file#name", "Crawler i3d filename")
	v3_:register(XMLValueType.NODE_INDEX, "crawler.file#leftNode", "Crawler left node in i3d")
	v3_:register(XMLValueType.NODE_INDEX, "crawler.file#rightNode", "Crawler right node in i3d")
	v3_:register(XMLValueType.NODE_INDEX, "crawler.scrollerNodes.scrollerNode(?)#node", "Scroller node")
	v3_:register(XMLValueType.FLOAT, "crawler.scrollerNodes.scrollerNode(?)#scrollSpeed", "Scroll speed", 1)
	v3_:register(XMLValueType.FLOAT, "crawler.scrollerNodes.scrollerNode(?)#scrollLength", "Scroll length", 1)
	v3_:register(XMLValueType.STRING, "crawler.scrollerNodes.scrollerNode(?)#shaderParameterName", "Shader parameter name", "offsetUV")
	v3_:register(XMLValueType.STRING, "crawler.scrollerNodes.scrollerNode(?)#shaderParameterNamePrev", "Shader parameter name (Prev)", "#shaderParameterName prefixed with \'prev\'")
	v3_:register(XMLValueType.INT, "crawler.scrollerNodes.scrollerNode(?)#shaderParameterComponent", "Shader paramater component", 1)
	v3_:register(XMLValueType.FLOAT, "crawler.scrollerNodes.scrollerNode(?)#maxSpeed", "Max. speed in m/s", "unlimited")
	v3_:register(XMLValueType.FLOAT, "crawler.scrollerNodes.scrollerNode(?)#isTrackPart", "Is part of track (Track width is set as scale X)")
	v3_:register(XMLValueType.NODE_INDEX, "crawler.rotatingParts.rotatingPart(?)#node", "Rotating node")
	v3_:register(XMLValueType.FLOAT, "crawler.rotatingParts.rotatingPart(?)#radius", "Radius")
	v3_:register(XMLValueType.FLOAT, "crawler.rotatingParts.rotatingPart(?)#speedScale", "Speed scale")
	v3_:register(XMLValueType.NODE_INDEX, "crawler.dirtNodes.dirtNode(?)#node", "Nodes that act the same way as wheels and get dirty faster when on field. If not defined everything gets dirty faster.")
	v3_:register(XMLValueType.BOOL, "crawler.animations.animation(?)#isLeft", "Load for left crawler", false)
	AnimatedVehicle.registerAnimationXMLPaths(v3_, "crawler.animations.animation(?)")
	ObjectChangeUtil.registerObjectChangeSingleXMLPaths(v3_, "crawler")
	Crawlers.xmlSchema = v3_
end

function Crawlers.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "updateCrawler", Crawlers.updateCrawler)
	SpecializationUtil.registerFunction(vehicleType, "loadCrawlerFromXML", Crawlers.loadCrawlerFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadCrawlerFromConfigFile", Crawlers.loadCrawlerFromConfigFile)
	SpecializationUtil.registerFunction(vehicleType, "onCrawlerI3DLoaded", Crawlers.onCrawlerI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "getCrawlerWheelMovedDistance", Crawlers.getCrawlerWheelMovedDistance)
end

function Crawlers.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "validateWashableNode", Crawlers.validateWashableNode)
end

function Crawlers.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Crawlers)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Crawlers)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Crawlers)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Crawlers)
	SpecializationUtil.registerEventListener(vehicleType, "onWheelConfigurationChanged", Crawlers)
end

-- Local values: spec, wheelConfigId, wheelKey
function Crawlers:onLoad(savegame)
	local v8_ = self.spec_crawlers
	local v9_ = Utils.getNoNil(self.configurations.wheel, 1)
	local v10_ = string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration(%d)", v9_ - 1)
	v8_.crawlers = {}
	v8_.sharedLoadRequestIds = {}
	v8_.xmlLoadingHandles = {}
	self.xmlFile:iterate(v10_ .. ".crawlers.crawler", function(_, p11_)
		-- upvalues: (copy) self
		self:loadCrawlerFromXML(self.xmlFile, p11_)
	end)
end

-- Local values: spec, i, crawler
function Crawlers:onLoadFinished(savegame)
	local v13_ = self.spec_crawlers
	if #v13_.crawlers == 0 then
		SpecializationUtil.removeEventListener(self, "onUpdate", Crawlers)
	else
		for _, v14_ in ipairs(v13_.crawlers) do
			if v14_.rimMaterial ~= nil then
				v14_.rimMaterial:apply(v14_.loadedCrawler, "rim_inner_mat")
				v14_.rimMaterial:apply(v14_.loadedCrawler, "rim_outer_mat")
			end
			self:updateCrawler(v14_, 999)
		end
	end
end

-- Local values: spec, xmlFile, _, _, crawler, _, sharedLoadRequestId
function Crawlers:onDelete()
	local v16_ = self.spec_crawlers
	if v16_.xmlLoadingHandles ~= nil then
		for v17_, _ in pairs(v16_.xmlLoadingHandles) do
			v17_:delete()
		end
		table.clear(v16_.xmlLoadingHandles)
	end
	if v16_.crawlers ~= nil then
		for _, v18_ in pairs(v16_.crawlers) do
			if v18_.shallowWaterObstacle ~= nil then
				g_currentMission.shallowWaterSimulation:removeObstacle(v18_.shallowWaterObstacle)
				v18_.shallowWaterObstacle = nil
			end
		end
		table.clear(v16_.crawlers)
	end
	if v16_.sharedLoadRequestIds ~= nil then
		for _, v19_ in ipairs(v16_.sharedLoadRequestIds) do
			g_i3DManager:releaseSharedI3DFile(v19_)
		end
		v16_.sharedLoadRequestIds = nil
	end
end

-- Local values: spec, updateCrawlers, _, crawler
function Crawlers:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v22_ = self.spec_crawlers
	local v23_ = self.currentUpdateDistance < Crawlers.MAX_UPDATE_DISTANCE
	for _, v24_ in pairs(v22_.crawlers) do
		if v23_ then
			self:updateCrawler(v24_, dt)
		elseif v24_.lastPosition ~= nil then
			v24_.lastPosition = nil
		end
	end
end

-- Local values: spec, _, crawler, washableNode
function Crawlers:onWheelConfigurationChanged()
	local v26_ = self.spec_crawlers
	for _, v27_ in pairs(v26_.crawlers) do
		local v28_ = self:getWashableNodeByCustomIndex(v27_)
		if v28_ ~= nil then
			self:setNodeDirtAmount(v28_, 0, true)
		end
	end
end

-- Local values: newX, newY, newZ, dx, dy, dz, movingDirection, _, scrollerNode, movedDistance, moveDirection, _, node, x, y, z, w, rotationDifference, _, rotatingPart, x, y, z, refX, refY, refZ, dx, dy, dz, upX, upY, upZ
function Crawlers:updateCrawler(crawler, dt)
	crawler.movedDistance = 0
	if crawler.speedReferenceNode == nil then
		crawler.movedDistance = self:getCrawlerWheelMovedDistance(crawler, "lastRotationScroll", false)
	else
		local v31_, v32_, v33_ = getWorldTranslation(crawler.speedReferenceNode)
		if crawler.lastPosition == nil then
			crawler.lastPosition = { v31_, v32_, v33_ }
		end
		local v34_, v35_, v36_ = worldDirectionToLocal(crawler.speedReferenceNode, v31_ - crawler.lastPosition[1], v32_ - crawler.lastPosition[2], v33_ - crawler.lastPosition[3])
		local v37_ = v36_ > 0.0001 and 1 or (v36_ < -0.0001 and -1 or 0)
		crawler.movedDistance = MathUtil.vector3Length(v34_, v35_, v36_) * v37_
		crawler.lastPosition[1] = v31_
		crawler.lastPosition[2] = v32_
		crawler.lastPosition[3] = v33_
	end
	for _, v38_ in pairs(crawler.scrollerNodes) do
		local v39_ = crawler.movedDistance * v38_.scrollSpeed
		local v40_ = math.sign(v39_)
		local v41_ = math.abs(v39_)
		local v42_ = v38_.maxSpeed
		local v43_ = math.min(v41_, v42_) * v40_
		v38_.scrollPosition = (v38_.scrollPosition + v43_) % v38_.scrollLength
		for _, v44_ in pairs(v38_.nodes) do
			local v45_, v46_, v47_, v48_ = getShaderParameter(v44_, v38_.shaderParameterName)
			if v38_.shaderParameterComponent == 1 then
				v45_ = v38_.scrollPosition
			else
				v46_ = v38_.scrollPosition
			end
			if v38_.shaderParameterNamePrev == nil then
				setShaderParameter(v44_, v38_.shaderParameterName, v45_, v46_, v47_, v48_, false)
			else
				g_animationManager:setPrevShaderParameter(v44_, v38_.shaderParameterName, v45_, v46_, v47_, v48_, false, v38_.shaderParameterNamePrev)
			end
		end
	end
	local v49_ = self:getCrawlerWheelMovedDistance(crawler, "lastRotationRot", true)
	for _, v50_ in pairs(crawler.rotatingParts) do
		if crawler.wheel == nil or v50_.speedScale ~= nil then
			if v50_.speedScale ~= nil then
				rotate(v50_.node, v50_.speedScale * crawler.movedDistance, 0, 0)
			end
		else
			rotate(v50_.node, v49_, 0, 0)
		end
	end
	if crawler.referenceNode ~= nil then
		if crawler.positionReferenceWheel ~= nil then
			crawler.positionReferenceNode = crawler.positionReferenceWheel:getFirstTireNode() or crawler.positionReferenceNode
			crawler.positionReferenceWheel = nil
		end
		if crawler.referenceWheel ~= nil then
			crawler.referenceNode = crawler.referenceWheel:getFirstTireNode() or crawler.referenceNode
			crawler.referenceWheel = nil
		end
		if self.currentUpdateDistance < Crawlers.MAX_UPDATE_DISTANCE_ALIGNMENT then
			local v51_, v52_, v53_ = getWorldTranslation(crawler.positionReferenceNode)
			local v54_, v55_, v56_ = getWorldTranslation(crawler.referenceNode)
			local v57_, v58_, v59_ = MathUtil.vector3Normalize(v54_ - v51_, v55_ - v52_, v56_ - v53_)
			local v60_, v61_, v62_ = localDirectionToWorld(crawler.referenceFrame, 0, 1, 0)
			setWorldTranslation(crawler.linkNode, v51_, v52_, v53_)
			setWorldDirection(crawler.linkNode, v57_, v58_, v59_, v60_, v61_, v62_)
		end
	end
end

-- Local values: crawler, linkNode, linkWheelNodes, numLinkWheelNodes, backWheel, frontWheel, wheelIndex, wheelIndices, wheelNodes, _, wheelIndex, wheel, _, wheelNode, wheel, numWheels, crawlerLength, _, wheelData, _, otherWheelData, distance, wheelIndex, wheelData, hasWaterEffects, minX, minY, minZ, maxX, maxY, maxZ, _, wheelData, wheel, x1, y1, z1, x2, y2, z2, sizeX, sizeY, sizeZ, cx, cy, cz, rimMaterial, filename
function Crawlers:loadCrawlerFromXML(xmlFile, key)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#crawlerIndex", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#length", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#shaderParameterComponent", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#shaderParameterName", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#scrollLength", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#scrollSpeed", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".rotatingPart", "Moved to external crawler config file")
	local v66_ = {
		["vehicle"] = self,
		["wheels"] = {}
	}
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#linkIndex", key .. "#linkNode")
	local v67_ = xmlFile:getValue(key .. "#linkNode", nil, self.components, self.i3dMappings)
	local v68_ = xmlFile:getValue(key .. "#linkWheelNodes", nil, self.components, self.i3dMappings, true)
	if v68_ ~= nil then
		local v69_ = #v68_
		if v69_ == 2 then
			local v70_ = self:getWheelByWheelNode(v68_[1])
			local v71_ = self:getWheelByWheelNode(v68_[2])
			if v70_ == nil or v71_ == nil then
				Logging.xmlWarning(self.xmlFile, "Unknown link wheel nodes found in \'%s\'", key)
			else
				if v67_ == nil then
					v67_ = createTransformGroup("crawlerLinkNode")
				end
				link(v70_.repr, v67_)
				setWorldTranslation(v67_, getWorldTranslation(v70_.driveNode))
				setWorldRotation(v67_, getWorldRotation(v70_.driveNode))
				v66_.positionReferenceNode = v70_.driveNode
				v66_.referenceNode = v71_.driveNode
				v66_.referenceFrame = v70_.repr
				v66_.positionReferenceWheel = v70_
				v66_.referenceWheel = v71_
				local v72_ = v66_.wheels
				table.insert(v72_, {
					["wheel"] = v70_
				})
				local v73_ = v66_.wheels
				table.insert(v73_, {
					["wheel"] = v71_
				})
			end
		elseif v69_ ~= 0 then
			Logging.xmlWarning(self.xmlFile, "The \'linkWheelNodes\' attribute in crawlers requires exactly two nodes! \'%s\'", key)
		end
	end
	if v67_ == nil then
		Logging.xmlWarning(self.xmlFile, "Missing link node for crawler \'%s\'", key)
	else
		v66_.linkNode = v67_
		v66_.isLeft = xmlFile:getValue(key .. "#isLeft", false)
		v66_.trackWidth = xmlFile:getValue(key .. "#trackWidth", 1)
		v66_.translationOffset = xmlFile:getValue(key .. "#offset", "0 0 0", true)
		XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#speedRefWheel", key .. "#wheelIndex")
		local v74_ = xmlFile:getValue(key .. "#wheelIndex")
		local v75_ = xmlFile:getValue(key .. "#wheelIndices", nil, true)
		local v76_ = xmlFile:getValue(key .. "#wheelNodes", nil, self.components, self.i3dMappings, true)
		if v74_ ~= nil or (v75_ ~= nil or #v76_ > 0) then
			if v74_ ~= nil then
				v75_ = v75_ or {}
				table.insert(v75_, v74_)
			end
			if v75_ ~= nil then
				for _, v77_ in ipairs(v75_) do
					local v78_ = self:getWheelFromWheelIndex(v77_)
					if v78_ ~= nil then
						local v79_ = v66_.wheels
						table.insert(v79_, {
							["wheel"] = v78_
						})
					end
				end
			end
			if v76_ ~= nil then
				for _, v80_ in ipairs(v76_) do
					local v81_ = self:getWheelByWheelNode(v80_)
					if v81_ ~= nil then
						local v82_ = v66_.wheels
						table.insert(v82_, {
							["wheel"] = v81_
						})
					end
				end
			end
		end
		local v83_ = #v66_.wheels
		if v83_ > 0 then
			local v84_ = 0
			for _, v85_ in ipairs(v66_.wheels) do
				for _, v86_ in ipairs(v66_.wheels) do
					if v85_ ~= v86_ then
						local v87_ = calcDistanceFrom(v85_.wheel.driveNode, v86_.wheel.driveNode)
						v84_ = math.max(v84_, v87_)
					end
				end
			end
			for v88_, v89_ in ipairs(v66_.wheels) do
				v89_.wheel.syncContactState = true
				v89_.wheel.transRatio = 1
				if v89_.wheel.physics.showSteeringAngle == nil then
					v89_.wheel.physics.showSteeringAngle = false
				end
				local v90_ = false
				if v83_ > 1 then
					if v88_ == 1 then
						v89_.wheel.effects.waterParticleDirection = -1
						v90_ = true
					elseif v88_ == 2 then
						v89_.wheel.effects.waterParticleDirection = 1
						v90_ = true
					end
					local v91_ = v89_.wheel.effects
					local v92_ = v84_ * 0.5
					v91_.waterEffectReferenceRadius = math.min(v92_, 1)
				else
					v90_ = true
				end
				if v90_ then
					if v89_.wheel.effects.hasWaterParticles == nil then
						v89_.wheel.effects:addWaterEffectsToPhysicsData()
					end
				else
					v89_.wheel.effects:removeWaterEffects()
				end
				if not v89_.wheel.physics.isSynchronized then
					Logging.xmlWarning(self.xmlFile, "Wheel \'%s\' for crawler \'%s\' in not synchronized! It won\'t rotate on the client side.", getName(v89_.wheel.repr), key)
				end
			end
			v66_.wheel = v66_.wheels[1].wheel
			v66_.hasShallowWaterObstacle = xmlFile:getValue(key .. "#hasShallowWaterObstacle", true)
			if v66_.hasShallowWaterObstacle and self.propertyState ~= VehiclePropertyState.SHOP_CONFIG then
				local v93_ = math.huge
				local v94_ = math.huge
				local v95_ = math.huge
				local v96_ = -math.huge
				local v97_ = -math.huge
				local v98_ = -math.huge
				for _, v99_ in ipairs(v66_.wheels) do
					local v100_ = v99_.wheel
					local v101_, v102_, v103_ = localToLocal(v100_.driveNode, v67_, v100_.physics.wheelShapeWidth * 0.5 + v100_.physics.wheelShapeWidthOffset, v100_.physics.radius, v100_.physics.radius)
					local v104_, v105_, v106_ = localToLocal(v100_.driveNode, v67_, -(v100_.physics.wheelShapeWidth * 0.5 - v100_.physics.wheelShapeWidthOffset), -v100_.physics.radius, -v100_.physics.radius)
					v93_ = math.min(v93_, v101_, v104_)
					v94_ = math.min(v94_, v102_, v105_)
					v95_ = math.min(v95_, v103_, v106_)
					v96_ = math.max(v96_, v101_, v104_)
					v97_ = math.max(v97_, v102_, v105_)
					v98_ = math.max(v98_, v103_, v106_)
				end
				local v107_ = v96_ - v93_
				local v108_ = v97_ - v94_
				local v109_ = v98_ - v95_
				local v110_ = { (v93_ + v96_) * 0.5, (v94_ + v97_) * 0.5, (v95_ + v98_) * 0.5 }
				v66_.shallowWaterObstacle = g_currentMission.shallowWaterSimulation:addObstacle(v67_, v107_, v108_, v109_, Crawlers.getShallowWaterParameters, v66_, v110_)
			end
		end
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#speedRefNode", key .. "#speedReferenceNode")
		v66_.speedReferenceNode = xmlFile:getValue(key .. "#speedReferenceNode", nil, self.components, self.i3dMappings)
		v66_.movedDistance = 0
		v66_.fieldDirtMultiplier = xmlFile:getValue(key .. "#fieldDirtMultiplier", 75)
		v66_.streetDirtMultiplier = xmlFile:getValue(key .. "#streetDirtMultiplier", -150)
		v66_.waterWetnessFactor = xmlFile:getValue(key .. "#waterWetnessFactor", 20)
		v66_.minDirtPercentage = xmlFile:getValue(key .. "#minDirtPercentage", 0.35)
		v66_.maxDirtOffset = xmlFile:getValue(key .. "#maxDirtOffset", 0.5)
		v66_.dirtColorChangeSpeed = 1 / (xmlFile:getValue(key .. "#dirtColorChangeSpeed", 20) * 1000)
		local v111_ = VehicleMaterial.new(self.baseDirectory)
		if v111_:loadFromXML(xmlFile, key .. ".rimMaterial", self.customEnvironment) then
			v66_.rimMaterial = v111_
		end
		self:loadCrawlerFromConfigFile(v66_, xmlFile:getValue(key .. "#filename"), v67_)
	end
end

-- Local values: xmlFile, filename, spec, arguments, sharedLoadRequestId
function Crawlers:loadCrawlerFromConfigFile(crawler, xmlFilename, linkNode)
	local v115_ = Utils.getFilename(xmlFilename, self.baseDirectory)
	local v116_ = XMLFile.load("crawlerXml", v115_, Crawlers.xmlSchema)
	if v116_ == nil then
		Logging.xmlWarning(self.xmlFile, "Failed to open crawler config file \'%s\'", v115_)
		return
	else
		local v117_ = v116_:getValue("crawler.file#name")
		if v117_ == nil then
			Logging.xmlWarning(v116_, "Failed to open crawler i3d file \'%s\' in \'%s\'", v117_, v115_)
			v116_:delete()
		else
			local v118_ = self.spec_crawlers
			v118_.xmlLoadingHandles[v116_] = true
			crawler.filename = Utils.getFilename(v117_, self.baseDirectory)
			local v119_ = self:loadSubSharedI3DFile(crawler.filename, false, false, self.onCrawlerI3DLoaded, self, {
				["xmlFile"] = v116_,
				["crawler"] = crawler
			})
			local v120_ = v118_.sharedLoadRequestIds
			table.insert(v120_, v119_)
		end
	end
end

-- Local values: xmlFile, crawler, spec, leftRightKey, j, key, entry, prevName, key, entry, key, node, i, key, animation
function Crawlers:onCrawlerI3DLoaded(i3dNode, failedReason, args)
	local v124_ = args.xmlFile
	local v125_ = args.crawler
	local v126_ = self.spec_crawlers
	if i3dNode == 0 then
		if not (self.isDeleted or self.isDeleting) then
			Logging.xmlWarning(v124_, "Failed to find crawler in i3d file \'%s\'", v125_.filename)
		end
	else
		v125_.loadedCrawler = v124_:getValue("crawler.file#" .. (v125_.isLeft and "leftNode" or "rightNode"), nil, i3dNode)
		if v125_.loadedCrawler ~= nil then
			link(v125_.linkNode, v125_.loadedCrawler)
			if v125_.translationOffset ~= nil then
				local v127_ = setTranslation
				local v128_ = v125_.loadedCrawler
				local v129_ = v125_.translationOffset
				v127_(v128_, unpack(v129_))
			end
			setRotation(v125_.loadedCrawler, 0, 0, 0)
			v125_.scrollerNodes = {}
			local v130_ = 0
			while true do
				local v131_ = string.format("crawler.scrollerNodes.scrollerNode(%d)", v130_)
				if not v124_:hasProperty(v131_) then
					break
				end
				local v132_ = {
					["node"] = v124_:getValue(v131_ .. "#node", nil, v125_.loadedCrawler)
				}
				if v132_.node ~= nil then
					v132_.scrollSpeed = v124_:getValue(v131_ .. "#scrollSpeed", 1)
					v132_.scrollLength = v124_:getValue(v131_ .. "#scrollLength", 1)
					v132_.shaderParameterName = v124_:getValue(v131_ .. "#shaderParameterName", "offsetUV")
					v132_.shaderParameterNamePrev = v124_:getValue(v131_ .. "#shaderParameterNamePrev")
					if v132_.shaderParameterNamePrev == nil then
						local v133_ = string.upper
						local v134_ = v132_.shaderParameterName
						local v135_ = v133_((string.sub(v134_, 1, 1)))
						local v136_ = v132_.shaderParameterName
						local v137_ = "prev" .. v135_ .. string.sub(v136_, 2)
						if getHasShaderParameter(v132_.node, v137_) then
							v132_.shaderParameterNamePrev = v137_
						end
					elseif not getHasShaderParameter(v132_.node, v132_.shaderParameterNamePrev) then
						Logging.xmlWarning(v124_, "Node \'%s\' has no shader parameter \'%s\' (prev) for crawler node \'%s\'!", getName(v132_.node), v132_.shaderParameterNamePrev, v131_)
						return
					end
					v132_.nodes = {}
					I3DUtil.getNodesByShaderParam(v125_.loadedCrawler, v132_.shaderParameterName, v132_.nodes)
					v132_.shaderParameterComponent = v124_:getValue(v131_ .. "#shaderParameterComponent", 1)
					v132_.maxSpeed = v124_:getValue(v131_ .. "#maxSpeed", math.huge) / 1000
					v132_.scrollPosition = 0
					if v125_.trackWidth ~= 1 and v124_:getValue(v131_ .. "#isTrackPart", true) then
						setScale(v132_.node, v125_.trackWidth, 1, 1)
					end
					local v138_ = v125_.scrollerNodes
					table.insert(v138_, v132_)
				end
				v130_ = v130_ + 1
			end
			v125_.rotatingParts = {}
			local v139_ = 0
			while true do
				local v140_ = string.format("crawler.rotatingParts.rotatingPart(%d)", v139_)
				if not v124_:hasProperty(v140_) then
					break
				end
				local v141_ = {
					["node"] = v124_:getValue(v140_ .. "#node", nil, v125_.loadedCrawler)
				}
				if v141_.node ~= nil then
					v141_.radius = v124_:getValue(v140_ .. "#radius")
					v141_.speedScale = v124_:getValue(v140_ .. "#speedScale")
					if v141_.speedScale == nil and v141_.radius ~= nil then
						v141_.speedScale = 1 / v141_.radius
					end
					local v142_ = v125_.rotatingParts
					table.insert(v142_, v141_)
				end
				v139_ = v139_ + 1
			end
			v125_.hasDirtNodes = false
			v125_.dirtNodes = {}
			local v143_ = 0
			while true do
				local v144_ = string.format("crawler.dirtNodes.dirtNode(%d)", v143_)
				if not v124_:hasProperty(v144_) then
					break
				end
				local v145_ = v124_:getValue(v144_ .. "#node", nil, v125_.loadedCrawler)
				if v145_ ~= nil then
					v125_.dirtNodes[v145_] = v145_
					v125_.hasDirtNodes = true
				end
				v143_ = v143_ + 1
			end
			v125_.objectChanges = {}
			ObjectChangeUtil.loadObjectChangeFromXML(v124_, "crawler", v125_.objectChanges, v125_.loadedCrawler, self)
			ObjectChangeUtil.setObjectChanges(v125_.objectChanges, true)
			local v146_ = 0
			while true do
				local v147_ = string.format("crawler.animations.animation(%d)", v146_)
				if not v124_:hasProperty(v147_) then
					break
				end
				if v125_.isLeft == v124_:getValue(v147_ .. "#isLeft", false) then
					local v148_ = {}
					if self:loadAnimation(v124_, v147_, v148_, v125_.loadedCrawler) then
						self.spec_animatedVehicle.animations[v148_.name] = v148_
					end
				end
				v146_ = v146_ + 1
			end
			local v149_ = self.spec_crawlers.crawlers
			table.insert(v149_, v125_)
		end
		delete(i3dNode)
	end
	v124_:delete()
	v126_.xmlLoadingHandles[v124_] = nil
end

-- Local values: minMovedDistance, direction, i, wheelData, newX, _, _, lastRotation, distance
function Crawlers:getCrawlerWheelMovedDistance(crawler, lastName, useOnlyRotation)
	local v153_ = math.huge
	local v154_ = 1
	for v155_ = 1, #crawler.wheels do
		local v156_ = crawler.wheels[v155_]
		if v156_.wheel.physics.contact ~= WheelContactType.NONE or #crawler.wheels == 1 then
			local v157_, _, _ = getRotation(v156_.wheel.driveNode)
			if v156_[lastName] == nil then
				v156_[lastName] = v157_
			end
			local v158_ = v156_[lastName]
			if v157_ - v158_ < -3.141592653589793 then
				v158_ = v158_ - 6.283185307179586
			elseif v157_ - v158_ > 3.141592653589793 then
				v158_ = v158_ + 6.283185307179586
			end
			local v159_ = v156_.wheel.physics.radius * (v157_ - v158_)
			local v160_ = v156_.wheel.physics.steeringAngle
			if math.abs(v160_) > 1.5707963267948966 then
				v159_ = -v159_
			end
			if useOnlyRotation then
				v159_ = v157_ - v158_
			end
			if v159_ < 0 then
				if -v153_ < v159_ then
					v153_ = -v159_
					v154_ = -1
				end
			elseif v159_ < v153_ then
				v153_ = v159_
				v154_ = 1
			end
			v156_[lastName] = v157_
		end
	end
	return v153_ == math.huge and 0 or v153_ * v154_
end

-- Local values: spec, _, crawler, crawlerNodes, nodeData, nodeData
function Crawlers:validateWashableNode(superFunc, node)
	local v164_ = self.spec_crawlers
	for _, v_u_165_ in pairs(v164_.crawlers) do
		if v_u_165_.wheel ~= nil then
			local v166_ = v_u_165_.dirtNodes
			if not v_u_165_.hasDirtNodes then
				I3DUtil.getNodesByShaderParam(v_u_165_.loadedCrawler, "scratches_dirt_snow_wetness", v166_)
			end
			if v_u_165_.crawlerMudMeshes == nil then
				v_u_165_.crawlerMudMeshes = {}
				I3DUtil.getNodesByShaderParam(v_u_165_.loadedCrawler, "mudAmount", v_u_165_.crawlerMudMeshes)
			end
			if v166_[node] ~= nil then
				local v_u_176_ = {
					["wheel"] = v_u_165_.wheel,
					["fieldDirtMultiplier"] = v_u_165_.fieldDirtMultiplier,
					["streetDirtMultiplier"] = v_u_165_.streetDirtMultiplier,
					["minDirtPercentage"] = v_u_165_.minDirtPercentage,
					["maxDirtOffset"] = v_u_165_.maxDirtOffset,
					["dirtColorChangeSpeed"] = v_u_165_.dirtColorChangeSpeed,
					["waterWetnessFactor"] = v_u_165_.waterWetnessFactor,
					["isSnowNode"] = true,
					["loadFromSavegameFunc"] = function(p167_, p168_)
						-- upvalues: (copy) v_u_176_, (copy) self, (copy) v_u_165_
						v_u_176_.wheel.physics.snowScale = p167_:getValue(p168_ .. "#snowScale", 0)
						local v169_, v170_ = g_currentMission.environment:getDirtColors()
						local v171_, v172_, v173_ = MathUtil.vector3ArrayLerp(v169_, v170_, v_u_176_.wheel.physics.snowScale)
						self:setNodeDirtColor(self:getWashableNodeByCustomIndex(v_u_165_), v171_, v172_, v173_, true)
					end,
					["saveToSavegameFunc"] = function(p174_, p175_)
						-- upvalues: (copy) v_u_176_
						p174_:setValue(p175_ .. "#snowScale", v_u_176_.wheel.physics.snowScale)
					end
				}
				return false, self.updateWheelDirtAmount, v_u_165_, v_u_176_
			end
			if v_u_165_.crawlerMudMeshes[node] ~= nil then
				local v177_ = {
					["wheel"] = v_u_165_.wheel,
					["fieldDirtMultiplier"] = v_u_165_.fieldDirtMultiplier,
					["streetDirtMultiplier"] = v_u_165_.streetDirtMultiplier,
					["minDirtPercentage"] = v_u_165_.minDirtPercentage,
					["maxDirtOffset"] = v_u_165_.maxDirtOffset,
					["dirtColorChangeSpeed"] = v_u_165_.dirtColorChangeSpeed,
					["waterWetnessFactor"] = v_u_165_.waterWetnessFactor,
					["isSnowNode"] = true,
					["cleaningMultiplier"] = 4
				}
				return false, self.updateWheelMudAmount, v_u_165_.crawlerMudMeshes, v177_
			end
		end
	end
	return superFunc(self, node)
end

-- Local values: defaultConfigKey, visualCrawlerCount, usedCrawlers
function Crawlers.getVRamUsageFromXML(xmlFile)
	if not xmlFile:hasProperty("vehicle.wheels") then
		return 0, 0
	end
	local v_u_179_ = nil
	xmlFile:iterate("vehicle.wheels.wheelConfigurations.wheelConfiguration", function(_, p180_)
		-- upvalues: (copy) xmlFile, (ref) v_u_179_
		local v181_ = p180_ .. ".crawlers"
		if xmlFile:hasProperty(v181_) then
			v_u_179_ = v181_
			return false
		end
	end)
	if v_u_179_ == nil then
		return 0, 0
	end
	local v_u_182_ = 0
	local v_u_183_ = {}
	xmlFile:iterate(v_u_179_ .. ".crawler", function(_, p184_)
		-- upvalues: (copy) xmlFile, (copy) v_u_183_, (ref) v_u_182_
		local v185_ = xmlFile:getString(p184_ .. "#filename")
		if v185_ ~= nil and v_u_183_[v185_] == nil then
			v_u_182_ = v_u_182_ + 1
			v_u_183_[v185_] = true
		end
	end)
	return v_u_182_ * Crawlers.VRAM_PER_CRAWLER, 0
end

-- Local values: velocity, ox, oz, slip, dx, _, dz, yRot
function Crawlers.getShallowWaterParameters(crawler)
	local v187_ = crawler.vehicle.lastSignedSpeed * 1000
	local v188_ = 0
	local v189_ = 0
	if crawler.wheel.physics ~= nil then
		local v190_ = crawler.wheel.physics.netInfo.slip
		if v190_ > 0.1 then
			v188_ = math.random() * 2 - 1 * v190_
			v189_ = math.random() * 2 - 1 * v190_
		end
	end
	if v188_ == 0 and math.abs(v187_) > 0.27 then
		v188_ = math.random() * 2 - 1
		v189_ = math.random() * 2 - 1
	end
	local v191_, _, v192_ = localDirectionToWorld(crawler.linkNode, 0, 0, 1)
	local v193_ = MathUtil.getYRotationFromDirection(v191_, v192_)
	local v194_ = v191_ * v187_
	local v195_ = v192_ * v187_
	return v194_ + v188_, v195_ + v189_, v193_
end
