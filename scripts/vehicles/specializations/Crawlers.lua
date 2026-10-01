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
	local schema = Vehicle.xmlSchema
	schema:setXMLSpecializationType("Crawlers")
	local crawlerKey = "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)"
	schema:register(XMLValueType.NODE_INDEX, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)" .. "#linkNode", "Link node")
	schema:register(XMLValueType.NODE_INDICES, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)" .. "#linkWheelNodes", "Back and front wheels which are used to link the crawler. Wheels are also used for speed reference.")
	schema:register(XMLValueType.BOOL, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)" .. "#isLeft", "Is left crawler", false)
	schema:register(XMLValueType.FLOAT, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)" .. "#trackWidth", "Track width", 1)
	schema:register(XMLValueType.BOOL, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)" .. "#hasShallowWaterObstacle", "Crawler has a shallow water obstacle between the defined wheels")
	schema:register(XMLValueType.STRING, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)" .. "#filename", "Crawler filename")
	schema:register(XMLValueType.VECTOR_TRANS, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)" .. "#offset", "Crawler position offset")
	schema:register(XMLValueType.INT, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)" .. "#wheelIndex", "Speed reference wheel index")
	schema:register(XMLValueType.VECTOR_N, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)" .. "#wheelIndices", "Multiple speed reference wheels. The average speed of the wheels WITH ground contact is used")
	schema:register(XMLValueType.NODE_INDICES, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)" .. "#wheelNodes", "Multiple speed reference wheels (defined by any node of the wheel). The average speed of the wheels WITH ground contact is used")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)" .. "#speedReferenceNode", "Speed reference node")
	schema:register(XMLValueType.FLOAT, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)" .. "#fieldDirtMultiplier", "Field dirt multiplier", 75)
	schema:register(XMLValueType.FLOAT, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)" .. "#streetDirtMultiplier", "Street dirt multiplier", -150)
	schema:register(XMLValueType.FLOAT, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)" .. "#waterWetnessFactor", "Factor for crawler wetness while driving in water", 20)
	schema:register(XMLValueType.FLOAT, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)" .. "#minDirtPercentage", "Min. dirt while getting clean on non field ground", 0.35)
	schema:register(XMLValueType.FLOAT, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)" .. "#maxDirtOffset", "Max. dirt amount offset to global dirt node", 0.5)
	schema:register(XMLValueType.FLOAT, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)" .. "#dirtColorChangeSpeed", "Defines speed to change the dirt color (sec)", 20)
	VehicleMaterial.registerXMLPaths(schema, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)" .. ".rimMaterial")
	schema:setXMLSpecializationType()
	local crawlerSchema = XMLSchema.new("crawler")
	crawlerSchema:shareDelayedRegistrationFuncs(schema)
	crawlerSchema:register(XMLValueType.STRING, "crawler.file#name", "Crawler i3d filename")
	crawlerSchema:register(XMLValueType.NODE_INDEX, "crawler.file#leftNode", "Crawler left node in i3d")
	crawlerSchema:register(XMLValueType.NODE_INDEX, "crawler.file#rightNode", "Crawler right node in i3d")
	crawlerSchema:register(XMLValueType.NODE_INDEX, "crawler.scrollerNodes.scrollerNode(?)#node", "Scroller node")
	crawlerSchema:register(XMLValueType.FLOAT, "crawler.scrollerNodes.scrollerNode(?)#scrollSpeed", "Scroll speed", 1)
	crawlerSchema:register(XMLValueType.FLOAT, "crawler.scrollerNodes.scrollerNode(?)#scrollLength", "Scroll length", 1)
	crawlerSchema:register(XMLValueType.STRING, "crawler.scrollerNodes.scrollerNode(?)#shaderParameterName", "Shader parameter name", "offsetUV")
	crawlerSchema:register(XMLValueType.STRING, "crawler.scrollerNodes.scrollerNode(?)#shaderParameterNamePrev", "Shader parameter name (Prev)", "#shaderParameterName prefixed with 'prev'")
	crawlerSchema:register(XMLValueType.INT, "crawler.scrollerNodes.scrollerNode(?)#shaderParameterComponent", "Shader paramater component", 1)
	crawlerSchema:register(XMLValueType.FLOAT, "crawler.scrollerNodes.scrollerNode(?)#maxSpeed", "Max. speed in m/s", "unlimited")
	crawlerSchema:register(XMLValueType.FLOAT, "crawler.scrollerNodes.scrollerNode(?)#isTrackPart", "Is part of track (Track width is set as scale X)")
	crawlerSchema:register(XMLValueType.NODE_INDEX, "crawler.rotatingParts.rotatingPart(?)#node", "Rotating node")
	crawlerSchema:register(XMLValueType.FLOAT, "crawler.rotatingParts.rotatingPart(?)#radius", "Radius")
	crawlerSchema:register(XMLValueType.FLOAT, "crawler.rotatingParts.rotatingPart(?)#speedScale", "Speed scale")
	crawlerSchema:register(XMLValueType.NODE_INDEX, "crawler.dirtNodes.dirtNode(?)#node", "Nodes that act the same way as wheels and get dirty faster when on field. If not defined everything gets dirty faster.")
	crawlerSchema:register(XMLValueType.BOOL, "crawler.animations.animation(?)#isLeft", "Load for left crawler", false)
	AnimatedVehicle.registerAnimationXMLPaths(crawlerSchema, "crawler.animations.animation(?)")
	ObjectChangeUtil.registerObjectChangeSingleXMLPaths(crawlerSchema, "crawler")
	Crawlers.xmlSchema = crawlerSchema
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
function Crawlers:onLoad(savegame)
	local spec = self.spec_crawlers
	local wheelConfigId = Utils.getNoNil(self.configurations.wheel, 1)
	local wheelKey = string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration(%d)", wheelConfigId - 1)
	spec.crawlers = {}
	spec.sharedLoadRequestIds = {}
	spec.xmlLoadingHandles = {}
	self.xmlFile:iterate(wheelKey .. ".crawlers.crawler", function(_, key)
		self:loadCrawlerFromXML(self.xmlFile, key)
	end)
end
function Crawlers:onLoadFinished(savegame)
	local spec = self.spec_crawlers
	if #spec.crawlers == 0 then
		SpecializationUtil.removeEventListener(self, "onUpdate", Crawlers)
	else
		for i, crawler in ipairs(spec.crawlers) do
			if crawler.rimMaterial ~= nil then
				crawler.rimMaterial:apply(crawler.loadedCrawler, "rim_inner_mat")
				crawler.rimMaterial:apply(crawler.loadedCrawler, "rim_outer_mat")
			end
			self:updateCrawler(crawler, 999)
		end
	end
end
function Crawlers:onDelete()
	local spec = self.spec_crawlers
	if spec.xmlLoadingHandles ~= nil then
		for xmlFile, _ in pairs(spec.xmlLoadingHandles) do
			xmlFile:delete()
		end
		table.clear(spec.xmlLoadingHandles)
	end
	if spec.crawlers ~= nil then
		for _, crawler in pairs(spec.crawlers) do
			if crawler.shallowWaterObstacle == nil then
				continue
			end
			g_currentMission.shallowWaterSimulation:removeObstacle(crawler.shallowWaterObstacle)
			crawler.shallowWaterObstacle = nil
		end
		table.clear(spec.crawlers)
	end
	if spec.sharedLoadRequestIds ~= nil then
		for _, sharedLoadRequestId in ipairs(spec.sharedLoadRequestIds) do
			g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
		end
		spec.sharedLoadRequestIds = nil
	end
end
function Crawlers:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_crawlers
	local updateCrawlers = self.currentUpdateDistance < Crawlers.MAX_UPDATE_DISTANCE
	for _, crawler in pairs(spec.crawlers) do
		if updateCrawlers then
			self:updateCrawler(crawler, dt)
		else
			if crawler.lastPosition == nil then
				continue
			end
			crawler.lastPosition = nil
		end
	end
end
function Crawlers:onWheelConfigurationChanged()
	local spec = self.spec_crawlers
	for _, crawler in pairs(spec.crawlers) do
		local washableNode = self:getWashableNodeByCustomIndex(crawler)
		if washableNode == nil then
			continue
		end
		self:setNodeDirtAmount(washableNode, 0, true)
	end
end
function Crawlers:updateCrawler(crawler, dt)
	crawler.movedDistance = 0
	if crawler.speedReferenceNode ~= nil then
		local newX, newY, newZ = getWorldTranslation(crawler.speedReferenceNode)
		if crawler.lastPosition == nil then
			crawler.lastPosition = { newX, newY, newZ }
		end
		local dx, dy, dz = worldDirectionToLocal(crawler.speedReferenceNode, newX - crawler.lastPosition[1], newY - crawler.lastPosition[2], newZ - crawler.lastPosition[3])
		local movingDirection = 0
		if 0.0001 < dz then
			movingDirection = 1
		elseif dz < -0.0001 then
			movingDirection = -1
		end
		crawler.movedDistance = MathUtil.vector3Length(dx, dy, dz) * movingDirection
		crawler.lastPosition[1] = newX
		crawler.lastPosition[2] = newY
		crawler.lastPosition[3] = newZ
	else
		crawler.movedDistance = self:getCrawlerWheelMovedDistance(crawler, "lastRotationScroll", false)
	end
	for _, scrollerNode in pairs(crawler.scrollerNodes) do
		local movedDistance = crawler.movedDistance * scrollerNode.scrollSpeed
		local moveDirection = math.sign(movedDistance)
		movedDistance = math.min(math.abs(movedDistance), scrollerNode.maxSpeed) * moveDirection
		scrollerNode.scrollPosition = (scrollerNode.scrollPosition + movedDistance) % scrollerNode.scrollLength
		for _, node in pairs(scrollerNode.nodes) do
			local x, y, z, w = getShaderParameter(node, scrollerNode.shaderParameterName)
			if scrollerNode.shaderParameterComponent == 1 then
				x = scrollerNode.scrollPosition
			else
				y = scrollerNode.scrollPosition
			end
			if scrollerNode.shaderParameterNamePrev ~= nil then
				g_animationManager:setPrevShaderParameter(node, scrollerNode.shaderParameterName, x, y, z, w, false, scrollerNode.shaderParameterNamePrev)
			else
				setShaderParameter(node, scrollerNode.shaderParameterName, x, y, z, w, false)
			end
		end
	end
	local rotationDifference = self:getCrawlerWheelMovedDistance(crawler, "lastRotationRot", true)
	for _, rotatingPart in pairs(crawler.rotatingParts) do
		if crawler.wheel ~= nil then
			if rotatingPart.speedScale == nil then
				rotate(rotatingPart.node, rotationDifference, 0, 0)
			else
				if rotatingPart.speedScale == nil then
					continue
				end
				rotate(rotatingPart.node, rotatingPart.speedScale * crawler.movedDistance, 0, 0)
			end
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
			local x, y, z = getWorldTranslation(crawler.positionReferenceNode)
			local refX, refY, refZ = getWorldTranslation(crawler.referenceNode)
			local dx, dy, dz = MathUtil.vector3Normalize(refX - x, refY - y, refZ - z)
			local upX, upY, upZ = localDirectionToWorld(crawler.referenceFrame, 0, 1, 0)
			setWorldTranslation(crawler.linkNode, x, y, z)
			setWorldDirection(crawler.linkNode, dx, dy, dz, upX, upY, upZ)
		end
	end
end
function Crawlers:loadCrawlerFromXML(xmlFile, key)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#crawlerIndex", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#length", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#shaderParameterComponent", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#shaderParameterName", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#scrollLength", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#scrollSpeed", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".rotatingPart", "Moved to external crawler config file")
	local crawler = {}
	crawler.vehicle = self
	crawler.wheels = {}
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#linkIndex", key .. "#linkNode")
	local linkNode = xmlFile:getValue(key .. "#linkNode", nil, self.components, self.i3dMappings)
	local linkWheelNodes = xmlFile:getValue(key .. "#linkWheelNodes", nil, self.components, self.i3dMappings, true)
	if linkWheelNodes ~= nil then
		local numLinkWheelNodes = #linkWheelNodes
		if numLinkWheelNodes == 2 then
			local backWheel = self:getWheelByWheelNode(linkWheelNodes[1])
			local frontWheel = self:getWheelByWheelNode(linkWheelNodes[2])
			if backWheel ~= nil then
				if frontWheel ~= nil then
					if linkNode == nil then
						linkNode = createTransformGroup("crawlerLinkNode")
					end
					link(backWheel.repr, linkNode)
					setWorldTranslation(linkNode, getWorldTranslation(backWheel.driveNode))
					setWorldRotation(linkNode, getWorldRotation(backWheel.driveNode))
					crawler.positionReferenceNode = backWheel.driveNode
					crawler.referenceNode = frontWheel.driveNode
					crawler.referenceFrame = backWheel.repr
					crawler.positionReferenceWheel = backWheel
					crawler.referenceWheel = frontWheel
					table.insert(crawler.wheels, { wheel = backWheel })
					table.insert(crawler.wheels, { wheel = frontWheel })
				else
					Logging.xmlWarning(self.xmlFile, "Unknown link wheel nodes found in '%s'", key)
				end
			end
		elseif numLinkWheelNodes ~= 0 then
			Logging.xmlWarning(self.xmlFile, "The 'linkWheelNodes' attribute in crawlers requires exactly two nodes! '%s'", key)
		end
	end
	if linkNode == nil then
		Logging.xmlWarning(self.xmlFile, "Missing link node for crawler '%s'", key)
	else
		crawler.linkNode = linkNode
		crawler.isLeft = xmlFile:getValue(key .. "#isLeft", false)
		crawler.trackWidth = xmlFile:getValue(key .. "#trackWidth", 1)
		crawler.translationOffset = xmlFile:getValue(key .. "#offset", "0 0 0", true)
		XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#speedRefWheel", key .. "#wheelIndex")
		local wheelIndex = xmlFile:getValue(key .. "#wheelIndex")
		local wheelIndices = xmlFile:getValue(key .. "#wheelIndices", nil, true)
		local wheelNodes = xmlFile:getValue(key .. "#wheelNodes", nil, self.components, self.i3dMappings, true)
		if wheelIndex ~= nil or wheelIndices ~= nil or 0 < #wheelNodes then
			if wheelIndex ~= nil then
				wheelIndices = wheelIndices or {}
				table.insert(wheelIndices, wheelIndex)
			end
			if wheelIndices ~= nil then
				for _, wheelIndex in ipairs(wheelIndices) do
					local wheel = self:getWheelFromWheelIndex(wheelIndex)
					if wheel == nil then
						continue
					end
					table.insert(crawler.wheels, { wheel = wheel })
				end
			end
			if wheelNodes ~= nil then
				for _, wheelNode in ipairs(wheelNodes) do
					local wheel = self:getWheelByWheelNode(wheelNode)
					if wheel == nil then
						continue
					end
					table.insert(crawler.wheels, { wheel = wheel })
				end
			end
		end
		local numWheels = #crawler.wheels
		if 0 < numWheels then
			local crawlerLength = 0
			for _, wheelData in ipairs(crawler.wheels) do
				for _, otherWheelData in ipairs(crawler.wheels) do
					if wheelData == otherWheelData then
						continue
					end
					local distance = calcDistanceFrom(wheelData.wheel.driveNode, otherWheelData.wheel.driveNode)
					crawlerLength = math.max(crawlerLength, distance)
				end
			end
			for wheelIndex, wheelData in ipairs(crawler.wheels) do
				wheelData.wheel.syncContactState = true
				wheelData.wheel.transRatio = 1
				if wheelData.wheel.physics.showSteeringAngle == nil then
					wheelData.wheel.physics.showSteeringAngle = false
				end
				local hasWaterEffects = false
				if 1 < numWheels then
					if wheelIndex == 1 then
						wheelData.wheel.effects.waterParticleDirection = -1
						hasWaterEffects = true
					elseif wheelIndex == 2 then
						wheelData.wheel.effects.waterParticleDirection = 1
						hasWaterEffects = true
					end
					wheelData.wheel.effects.waterEffectReferenceRadius = math.min(crawlerLength * 0.5, 1)
				else
					hasWaterEffects = true
				end
				if hasWaterEffects then
					if wheelData.wheel.effects.hasWaterParticles == nil then
						wheelData.wheel.effects:addWaterEffectsToPhysicsData()
					end
				else
					wheelData.wheel.effects:removeWaterEffects()
				end
				if wheelData.wheel.physics.isSynchronized then
					continue
				end
				Logging.xmlWarning(self.xmlFile, "Wheel '%s' for crawler '%s' in not synchronized! It won't rotate on the client side.", getName(wheelData.wheel.repr), key)
			end
			crawler.wheel = crawler.wheels[1].wheel
			crawler.hasShallowWaterObstacle = xmlFile:getValue(key .. "#hasShallowWaterObstacle", true)
			if crawler.hasShallowWaterObstacle and self.propertyState ~= VehiclePropertyState.SHOP_CONFIG then
				local minX = math.huge
				local minY = math.huge
				local minZ = math.huge
				local maxX = -math.huge
				local maxY = -math.huge
				local maxZ = -math.huge
				for _, wheelData in ipairs(crawler.wheels) do
					local wheel = wheelData.wheel
					local x1, y1, z1 = localToLocal(wheel.driveNode, linkNode, wheel.physics.wheelShapeWidth * 0.5 + wheel.physics.wheelShapeWidthOffset, wheel.physics.radius, wheel.physics.radius)
					local x2, y2, z2 = localToLocal(wheel.driveNode, linkNode, -(wheel.physics.wheelShapeWidth * 0.5 - wheel.physics.wheelShapeWidthOffset), -wheel.physics.radius, -wheel.physics.radius)
					minX = math.min(minX, x1, x2)
					minY = math.min(minY, y1, y2)
					minZ = math.min(minZ, z1, z2)
					maxX = math.max(maxX, x1, x2)
					maxY = math.max(maxY, y1, y2)
					maxZ = math.max(maxZ, z1, z2)
				end
				local sizeX = maxX - minX
				local sizeY = maxY - minY
				local sizeZ = maxZ - minZ
				local cx = (minX + maxX) * 0.5
				local cy = (minY + maxY) * 0.5
				local cz = (minZ + maxZ) * 0.5
				crawler.shallowWaterObstacle = g_currentMission.shallowWaterSimulation:addObstacle(linkNode, sizeX, sizeY, sizeZ, Crawlers.getShallowWaterParameters, crawler, { cx, cy, cz })
			end
		end
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#speedRefNode", key .. "#speedReferenceNode")
		crawler.speedReferenceNode = xmlFile:getValue(key .. "#speedReferenceNode", nil, self.components, self.i3dMappings)
		crawler.movedDistance = 0
		crawler.fieldDirtMultiplier = xmlFile:getValue(key .. "#fieldDirtMultiplier", 75)
		crawler.streetDirtMultiplier = xmlFile:getValue(key .. "#streetDirtMultiplier", -150)
		crawler.waterWetnessFactor = xmlFile:getValue(key .. "#waterWetnessFactor", 20)
		crawler.minDirtPercentage = xmlFile:getValue(key .. "#minDirtPercentage", 0.35)
		crawler.maxDirtOffset = xmlFile:getValue(key .. "#maxDirtOffset", 0.5)
		crawler.dirtColorChangeSpeed = 1 / (xmlFile:getValue(key .. "#dirtColorChangeSpeed", 20) * 1000)
		local rimMaterial = VehicleMaterial.new(self.baseDirectory)
		if rimMaterial:loadFromXML(xmlFile, key .. ".rimMaterial", self.customEnvironment) then
			crawler.rimMaterial = rimMaterial
		end
		local filename = xmlFile:getValue(key .. "#filename")
		self:loadCrawlerFromConfigFile(crawler, filename, linkNode)
	end
end
function Crawlers:loadCrawlerFromConfigFile(crawler, xmlFilename, linkNode)
	xmlFilename = Utils.getFilename(xmlFilename, self.baseDirectory)
	local xmlFile = XMLFile.load("crawlerXml", xmlFilename, Crawlers.xmlSchema)
	if xmlFile ~= nil then
		local filename = xmlFile:getValue("crawler.file#name")
		if filename ~= nil then
			local spec = self.spec_crawlers
			spec.xmlLoadingHandles[xmlFile] = true
			crawler.filename = Utils.getFilename(filename, self.baseDirectory)
			local arguments = { xmlFile = xmlFile, crawler = crawler }
			local sharedLoadRequestId = self:loadSubSharedI3DFile(crawler.filename, false, false, self.onCrawlerI3DLoaded, self, arguments)
			table.insert(spec.sharedLoadRequestIds, sharedLoadRequestId)
			return
		else
			Logging.xmlWarning(xmlFile, "Failed to open crawler i3d file '%s' in '%s'", filename, xmlFilename)
			xmlFile:delete()
			return
		end
	end
	Logging.xmlWarning(self.xmlFile, "Failed to open crawler config file '%s'", xmlFilename)
end
function Crawlers:onCrawlerI3DLoaded(i3dNode, failedReason, args)
	local xmlFile = args.xmlFile
	local crawler = args.crawler
	local spec = self.spec_crawlers
	if i3dNode ~= 0 then
		local leftRightKey = crawler.isLeft and "leftNode" or "rightNode"
		crawler.loadedCrawler = xmlFile:getValue("crawler.file#" .. leftRightKey, nil, i3dNode)
		if crawler.loadedCrawler ~= nil then
			link(crawler.linkNode, crawler.loadedCrawler)
			if crawler.translationOffset ~= nil then
				setTranslation(crawler.loadedCrawler, unpack(crawler.translationOffset))
			end
			setRotation(crawler.loadedCrawler, 0, 0, 0)
			crawler.scrollerNodes = {}
			local j = 0
			while true do
				local key = string.format("crawler.scrollerNodes.scrollerNode(%d)", j)
				if not xmlFile:hasProperty(key) then
					break
				end
				local entry = {}
				entry.node = xmlFile:getValue(key .. "#node", nil, crawler.loadedCrawler)
				if entry.node ~= nil then
					entry.scrollSpeed = xmlFile:getValue(key .. "#scrollSpeed", 1)
					entry.scrollLength = xmlFile:getValue(key .. "#scrollLength", 1)
					entry.shaderParameterName = xmlFile:getValue(key .. "#shaderParameterName", "offsetUV")
					entry.shaderParameterNamePrev = xmlFile:getValue(key .. "#shaderParameterNamePrev")
					if entry.shaderParameterNamePrev ~= nil then
						if not getHasShaderParameter(entry.node, entry.shaderParameterNamePrev) then
							Logging.xmlWarning(xmlFile, "Node '%s' has no shader parameter '%s' (prev) for crawler node '%s'!", getName(entry.node), entry.shaderParameterNamePrev, key)
							return
						end
					else
						local prevName = "prev" .. string.upper(string.sub(entry.shaderParameterName, 1, 1)) .. string.sub(entry.shaderParameterName, 2)
						if getHasShaderParameter(entry.node, prevName) then
							entry.shaderParameterNamePrev = prevName
						end
					end
					entry.nodes = {}
					I3DUtil.getNodesByShaderParam(crawler.loadedCrawler, entry.shaderParameterName, entry.nodes)
					entry.shaderParameterComponent = xmlFile:getValue(key .. "#shaderParameterComponent", 1)
					entry.maxSpeed = xmlFile:getValue(key .. "#maxSpeed", math.huge) / 1000
					entry.scrollPosition = 0
					if crawler.trackWidth ~= 1 and xmlFile:getValue(key .. "#isTrackPart", true) then
						setScale(entry.node, crawler.trackWidth, 1, 1)
					end
					table.insert(crawler.scrollerNodes, entry)
				end
				j = j + 1
			end
			crawler.rotatingParts = {}
			j = 0
			while true do
				local key = string.format("crawler.rotatingParts.rotatingPart(%d)", j)
				if not xmlFile:hasProperty(key) then
					break
				end
				local entry = {}
				entry.node = xmlFile:getValue(key .. "#node", nil, crawler.loadedCrawler)
				if entry.node ~= nil then
					entry.radius = xmlFile:getValue(key .. "#radius")
					entry.speedScale = xmlFile:getValue(key .. "#speedScale")
					if entry.speedScale == nil and entry.radius ~= nil then
						entry.speedScale = 1 / entry.radius
					end
					table.insert(crawler.rotatingParts, entry)
				end
				j = j + 1
			end
			crawler.hasDirtNodes = false
			crawler.dirtNodes = {}
			j = 0
			while true do
				local key = string.format("crawler.dirtNodes.dirtNode(%d)", j)
				if not xmlFile:hasProperty(key) then
					break
				end
				local node = xmlFile:getValue(key .. "#node", nil, crawler.loadedCrawler)
				if node ~= nil then
					crawler.dirtNodes[node] = node
					crawler.hasDirtNodes = true
				end
				j = j + 1
			end
			crawler.objectChanges = {}
			ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, "crawler", crawler.objectChanges, crawler.loadedCrawler, self)
			ObjectChangeUtil.setObjectChanges(crawler.objectChanges, true)
			local i = 0
			while true do
				local key = string.format("crawler.animations.animation(%d)", i)
				if not xmlFile:hasProperty(key) then
					break
				end
				if crawler.isLeft == xmlFile:getValue(key .. "#isLeft", false) then
					local animation = {}
					if self:loadAnimation(xmlFile, key, animation, crawler.loadedCrawler) then
						self.spec_animatedVehicle.animations[animation.name] = animation
					end
				end
				i = i + 1
			end
			table.insert(self.spec_crawlers.crawlers, crawler)
		end
		delete(i3dNode)
	elseif not self.isDeleted then
		if not self.isDeleting then
			Logging.xmlWarning(xmlFile, "Failed to find crawler in i3d file '%s'", crawler.filename)
		end
	end
	xmlFile:delete()
	spec.xmlLoadingHandles[xmlFile] = nil
end
function Crawlers:getCrawlerWheelMovedDistance(crawler, lastName, useOnlyRotation)
	local minMovedDistance = math.huge
	local direction = 1
	for i = 1, #crawler.wheels do
		local wheelData = crawler.wheels[i]
		if wheelData.wheel.physics.contact ~= WheelContactType.NONE or #crawler.wheels == 1 then
			local newX, _, _ = getRotation(wheelData.wheel.driveNode)
			if wheelData[lastName] == nil then
				wheelData[lastName] = newX
			end
			local lastRotation = wheelData[lastName]
			if newX - lastRotation < -3.141592653589793 then
				lastRotation = lastRotation - 6.283185307179586
			elseif 3.141592653589793 < newX - lastRotation then
				lastRotation = lastRotation + 6.283185307179586
			end
			local distance = wheelData.wheel.physics.radius * (newX - lastRotation)
			if 1.5707963267948966 < math.abs(wheelData.wheel.physics.steeringAngle) then
				distance = -distance
			end
			if useOnlyRotation then
				distance = newX - lastRotation
			end
			if distance < 0 then
				if -minMovedDistance < distance then
					minMovedDistance = -distance
					direction = -1
				end
			elseif distance < minMovedDistance then
				minMovedDistance = distance
				direction = 1
			end
			wheelData[lastName] = newX
		end
	end
	if minMovedDistance ~= math.huge then
		return minMovedDistance * direction
	else
		return 0
	end
end
function Crawlers:validateWashableNode(superFunc, node)
	local spec = self.spec_crawlers
	for _, crawler in pairs(spec.crawlers) do
		if crawler.wheel == nil then
			continue
		end
		local crawlerNodes = crawler.dirtNodes
		if not crawler.hasDirtNodes then
			I3DUtil.getNodesByShaderParam(crawler.loadedCrawler, "scratches_dirt_snow_wetness", crawlerNodes)
		end
		if crawler.crawlerMudMeshes == nil then
			crawler.crawlerMudMeshes = {}
			I3DUtil.getNodesByShaderParam(crawler.loadedCrawler, "mudAmount", crawler.crawlerMudMeshes)
		end
		if crawlerNodes[node] ~= nil then
			local nodeData = {}
			nodeData.wheel = crawler.wheel
			nodeData.fieldDirtMultiplier = crawler.fieldDirtMultiplier
			nodeData.streetDirtMultiplier = crawler.streetDirtMultiplier
			nodeData.minDirtPercentage = crawler.minDirtPercentage
			nodeData.maxDirtOffset = crawler.maxDirtOffset
			nodeData.dirtColorChangeSpeed = crawler.dirtColorChangeSpeed
			nodeData.waterWetnessFactor = crawler.waterWetnessFactor
			nodeData.isSnowNode = true
			function nodeData.loadFromSavegameFunc(xmlFile, key)
				nodeData.wheel.physics.snowScale = xmlFile:getValue(key .. "#snowScale", 0)
				local defaultColor, snowColor = g_currentMission.environment:getDirtColors()
				local r, g, b = MathUtil.vector3ArrayLerp(defaultColor, snowColor, nodeData.wheel.physics.snowScale)
				local washableNode = self:getWashableNodeByCustomIndex(crawler)
				self:setNodeDirtColor(washableNode, r, g, b, true)
			end
			function nodeData.saveToSavegameFunc(xmlFile, key)
				xmlFile:setValue(key .. "#snowScale", nodeData.wheel.physics.snowScale)
			end
			return false, self.updateWheelDirtAmount, crawler, nodeData
		end
		if crawler.crawlerMudMeshes[node] == nil then
			continue
		end
		local nodeData = {}
		nodeData.wheel = crawler.wheel
		nodeData.fieldDirtMultiplier = crawler.fieldDirtMultiplier
		nodeData.streetDirtMultiplier = crawler.streetDirtMultiplier
		nodeData.minDirtPercentage = crawler.minDirtPercentage
		nodeData.maxDirtOffset = crawler.maxDirtOffset
		nodeData.dirtColorChangeSpeed = crawler.dirtColorChangeSpeed
		nodeData.waterWetnessFactor = crawler.waterWetnessFactor
		nodeData.isSnowNode = true
		nodeData.cleaningMultiplier = 4
		return false, self.updateWheelMudAmount, crawler.crawlerMudMeshes, nodeData
	end
	return superFunc(self, node)
end
function Crawlers.getVRamUsageFromXML(xmlFile)
	if not xmlFile:hasProperty("vehicle.wheels") then
		return 0, 0
	end
	local defaultConfigKey = nil
	xmlFile:iterate("vehicle.wheels.wheelConfigurations.wheelConfiguration", function(configIndex, wheelConfigKey)
		local crawlerKey = wheelConfigKey .. ".crawlers"
		if xmlFile:hasProperty(crawlerKey) then
			defaultConfigKey = crawlerKey
			return false
		else
			return
		end
	end)
	if defaultConfigKey == nil then
		return 0, 0
	else
		local visualCrawlerCount = 0
		local usedCrawlers = {}
		xmlFile:iterate(defaultConfigKey .. ".crawler", function(index, key)
			local filename = xmlFile:getString(key .. "#filename")
			if filename ~= nil and usedCrawlers[filename] == nil then
				visualCrawlerCount = visualCrawlerCount + 1
				usedCrawlers[filename] = true
			end
		end)
		return visualCrawlerCount * Crawlers.VRAM_PER_CRAWLER, 0
	end
end
function Crawlers.getShallowWaterParameters(crawler)
	local velocity = crawler.vehicle.lastSignedSpeed * 1000
	local ox = 0
	local oz = 0
	if crawler.wheel.physics ~= nil then
		local slip = crawler.wheel.physics.netInfo.slip
		if 0.1 < slip then
			ox = math.random() * 2 - 1 * slip
			oz = math.random() * 2 - 1 * slip
		end
	end
	if ox == 0 and 0.27 < math.abs(velocity) then
		ox = math.random() * 2 - 1
		oz = math.random() * 2 - 1
	end
	local dx, _, dz = localDirectionToWorld(crawler.linkNode, 0, 0, 1)
	local yRot = MathUtil.getYRotationFromDirection(dx, dz)
	dx = dx * velocity
	dz = dz * velocity
	return dx + ox, dz + oz, yRot
end
