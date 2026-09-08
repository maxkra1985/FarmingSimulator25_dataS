PlaceableRollercoaster = {}
PlaceableRollercoaster.SEAT_INDEX_NUM_BITS = 4
PlaceableRollercoaster.SEAT_MAX_NUM = 2 ^ PlaceableRollercoaster.SEAT_INDEX_NUM_BITS - 1
PlaceableRollercoaster.INSTANCE = nil
PlaceableRollercoaster.INPUT_CONTEXT_ROLLERCOASTER = "ROLLERCOASTER"
source("dataS/scripts/placeables/specializations/rollercoaster/RollercoasterActivatable.lua")
source("dataS/scripts/placeables/specializations/rollercoaster/RollercoasterHotspot.lua")
source("dataS/scripts/placeables/specializations/rollercoaster/RollercoasterPassengerEnterRequestEvent.lua")
source("dataS/scripts/placeables/specializations/rollercoaster/RollercoasterPassengerEnterResponseEvent.lua")
source("dataS/scripts/placeables/specializations/rollercoaster/RollercoasterStateRideWaiting.lua")
source("dataS/scripts/placeables/specializations/rollercoaster/RollercoasterStateRiding.lua")

function PlaceableRollercoaster.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(PlaceableConstructible, specializations)
end

function PlaceableRollercoaster.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "onSharedAnimationFileLoaded", PlaceableRollercoaster.onSharedAnimationFileLoaded)
	SpecializationUtil.registerFunction(placeableType, "getCanEnter", PlaceableRollercoaster.getCanEnter)
	SpecializationUtil.registerFunction(placeableType, "getFreeSeatIndex", PlaceableRollercoaster.getFreeSeatIndex)
	SpecializationUtil.registerFunction(placeableType, "getCanStart", PlaceableRollercoaster.getCanStart)
	SpecializationUtil.registerFunction(placeableType, "startRide", PlaceableRollercoaster.startRide)
	SpecializationUtil.registerFunction(placeableType, "endRide", PlaceableRollercoaster.endRide)
	SpecializationUtil.registerFunction(placeableType, "getAnimation", PlaceableRollercoaster.getAnimation)
	SpecializationUtil.registerFunction(placeableType, "setAnimationTime", PlaceableRollercoaster.setAnimationTime)
	SpecializationUtil.registerFunction(placeableType, "updateFxModifierValues", PlaceableRollercoaster.updateFxModifierValues)
	SpecializationUtil.registerFunction(placeableType, "tryEnterRide", PlaceableRollercoaster.tryEnterRide)
	SpecializationUtil.registerFunction(placeableType, "enterRide", PlaceableRollercoaster.enterRide)
	SpecializationUtil.registerFunction(placeableType, "exitRide", PlaceableRollercoaster.exitRide)
	SpecializationUtil.registerFunction(placeableType, "onUserRemoved", PlaceableRollercoaster.onUserRemoved)
	SpecializationUtil.registerFunction(placeableType, "registerRidersChangedListener", PlaceableRollercoaster.registerRidersChangedListener)
	SpecializationUtil.registerFunction(placeableType, "unregisterRidersChangedListener", PlaceableRollercoaster.unregisterRidersChangedListener)
	SpecializationUtil.registerFunction(placeableType, "getParentComponent", PlaceableRollercoaster.getParentComponent)
	SpecializationUtil.registerFunction(placeableType, "passengerCharacterLoaded", PlaceableRollercoaster.passengerCharacterLoaded)
	SpecializationUtil.registerFunction(placeableType, "playerTriggerCallback", PlaceableRollercoaster.playerTriggerCallback)
	SpecializationUtil.registerFunction(placeableType, "setPlayerTriggerState", PlaceableRollercoaster.setPlayerTriggerState)
	SpecializationUtil.registerFunction(placeableType, "getNumRides", PlaceableRollercoaster.getNumRides)
end

function PlaceableRollercoaster.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getHotspot", PlaceableRollercoaster.getHotspot)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "finalizeConstruction", PlaceableRollercoaster.finalizeConstruction)
end

function PlaceableRollercoaster.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableRollercoaster)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableRollercoaster)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableRollercoaster)
	SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableRollercoaster)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableRollercoaster)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableRollercoaster)
end

function PlaceableRollercoaster.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Rollercoaster")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".rollercoaster.animation.clip#rootNode", "Animation root node")
	schema:register(XMLValueType.STRING, basePath .. ".rollercoaster.animation.clip#name", "Animation clip name")
	schema:register(XMLValueType.STRING, basePath .. ".rollercoaster.animation.clip#filename", "Animation filename")
	schema:register(XMLValueType.FLOAT, basePath .. ".rollercoaster.animation#speedScale", "Animation speed scale")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".rollercoaster.movingSounds.sound(?)#node", "")
	schema:register(XMLValueType.STRING, basePath .. ".rollercoaster.movingSounds.sound(?)#filename", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".rollercoaster.movingSounds.sound(?)#innerRadius", "Audio source inner radius")
	schema:register(XMLValueType.FLOAT, basePath .. ".rollercoaster.movingSounds.sound(?)#radius", "Audio source radius")
	schema:register(XMLValueType.FLOAT, basePath .. ".rollercoaster.movingSounds.sound(?)#volume", "Audio source volume")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".rollercoaster.sounds", "driving1")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".rollercoaster.sounds", "driving2")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".rollercoaster.sounds", "driving3")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".rollercoaster.sounds", "driving4")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".rollercoaster.sounds", "driving5")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".rollercoaster.playerTrigger#node", "Player trigger for entering the ride")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".rollercoaster.exitPoints.exitPoint(?)#node", "Node where players exit the rollercoaster")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".rollercoaster.hotspot#linkNode", "Node where hotspot is linked to")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".rollercoaster.hotspot#teleportNode", "Node where player is teleported to. Teleporting is only available if this is set")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".rollercoaster.carts.cart(?)#node", "Cart node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".rollercoaster.carts.cart(?).seat(?)#node", "Seat reference node to calculate entering distance to")
	VehicleCamera.registerCameraXMLPaths(schema, basePath .. ".rollercoaster.carts.cart(?).seat(?).camera")
	VehicleCharacter.registerCharacterXMLPaths(schema, basePath .. ".rollercoaster.carts.cart(?).seat(?).characterNode")
	schema:setXMLSpecializationType()
end

function PlaceableRollercoaster.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. ".state#index", "")
	schema:register(XMLValueType.FLOAT, basePath .. "#splineTime", "")
	schema:register(XMLValueType.STRING, basePath .. ".player(?)#uniqueUserId", "")
	schema:register(XMLValueType.INT, basePath .. ".player(?)#rideCount", 0)
end

-- Local values: spec, key, clipRootNode, clipName, _, baseDirectory, clipFilename, loadingTask, arguments, cartIndex, cartKey, cart, _, seatKey, seatEntry, camera, _, pointKey, exitPoint, index, soundKey, movingSoundNode, soundFilename, innerRadius, radius, volume, audioSource, sample
function PlaceableRollercoaster:onLoad(savegame)
	local v10_ = self.spec_rollercoaster
	local v11_ = self.xmlFile:getValue("placeable.rollercoaster.animation.clip#rootNode", nil, self.components, self.i3dMappings)
	local v12_ = self.xmlFile:getValue("placeable.rollercoaster.animation.clip#name")
	local _, v13_ = Utils.getModNameAndBaseDirectory(self.xmlFile:getFilename())
	if v11_ ~= nil and v12_ ~= nil then
		local v14_ = self.xmlFile:getValue("placeable.rollercoaster.animation.clip#filename")
		v10_.animation = {}
		v10_.animation.clipRootNode = v11_
		v10_.animation.clipName = v12_
		v10_.animation.clipTrack = 0
		v10_.animation.speedScale = self.xmlFile:getValue("placeable.rollercoaster.animation#speedScale", 1)
		if v14_ ~= nil then
			local v15_ = Utils.getFilename(v14_, v13_)
			local v16_ = {
				["loadingTask"] = self:createLoadingTask()
			}
			v10_.animation.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v15_, false, false, self.onSharedAnimationFileLoaded, self, v16_)
			v10_.animation.clipFilename = v15_
		end
		setVisibility(v11_, false)
		v10_.animationTimeInterpolator = InterpolationTime.new(1.3)
		v10_.animationInterpolator = InterpolatorValue.new(0)
	end
	v10_.playerTrigger = self.xmlFile:getValue("placeable.rollercoaster.playerTrigger#node", nil, self.components, self.i3dMappings)
	addTrigger(v10_.playerTrigger, "playerTriggerCallback", self)
	self:setPlayerTriggerState(false)
	v10_.activatable = RollercoasterActivatable.new(self)
	v10_.carts = {}
	v10_.seats = {}
	for _, v17_ in self.xmlFile:iterator("placeable.rollercoaster.carts.cart") do
		local v18_ = {
			["node"] = self.xmlFile:getValue(v17_ .. "#node", nil, self.components, self.i3dMappings),
			["slope"] = 0,
			["angleChange"] = 0
		}
		local v19_, v20_, v21_ = localDirectionToWorld(v18_.node, 0, 0, 1)
		v18_.dirX = v19_
		v18_.dirY = v20_
		v18_.dirZ = v21_
		for _, v22_ in self.xmlFile:iterator(v17_ .. ".seat") do
			local v23_ = {
				["cart"] = v18_,
				["node"] = self.xmlFile:getValue(v22_ .. "#node", nil, self.components, self.i3dMappings)
			}
			if v23_.node ~= nil then
				local v24_ = VehicleCamera.new(self)
				if v24_:loadFromXML(self.xmlFile, v22_ .. ".camera", nil, 1) then
					v23_.camera = v24_
				end
				v23_.vehicleCharacter = VehicleCharacter.new(self)
				if v23_.vehicleCharacter ~= nil and not v23_.vehicleCharacter:load(self.xmlFile, v22_ .. ".characterNode") then
					v23_.vehicleCharacter = nil
				end
			end
			v23_.characterSpineLastRotationX = 0
			v23_.characterSpineLastRotationZ = 0
			v23_.randomFactor = math.random()
			v23_.smoothingFactor = 1 - math.random(10, 40) / 100
			v23_.smoothingFactorInv = 1 - v23_.smoothingFactor
			local v25_ = v10_.seats
			table.insert(v25_, v23_)
		end
		local v26_ = v10_.carts
		table.insert(v26_, v18_)
	end
	v10_.centerCart = v10_.carts[MathUtil.round(#v10_.carts / 2)]
	v10_.localSeatIndex = nil
	v10_.numRiders = 0
	v10_.ridersChangedListeners = {}
	v10_.exitPoints = {}
	for _, v27_ in self.xmlFile:iterator("placeable.rollercoaster.exitPoints.exitPoint") do
		local v28_ = self.xmlFile:getValue(v27_ .. "#node", nil, self.components, self.i3dMappings)
		if v28_ ~= nil then
			local v29_ = v10_.exitPoints
			table.insert(v29_, v28_)
		end
	end
	if #v10_.exitPoints < #v10_.seats then
		Logging.xmlWarning(self.xmlFile, "Only %d exitPoints defined for %d seats", #v10_.exitPoints, #v10_.seats)
	end
	v10_.rollercoasterHotspot = RollercoasterHotspot.new()
	v10_.hotSpotLinkNode = self.xmlFile:getValue("placeable.rollercoaster.hotspot#linkNode", nil, self.components, self.i3dMappings)
	v10_.hotSpotTeleportNode = self.xmlFile:getValue("placeable.rollercoaster.hotspot#teleportNode", nil, self.components, self.i3dMappings)
	if self.isClient then
		v10_.soundsMoving = {}
		for v30_, v31_ in self.xmlFile:iterator("placeable.rollercoaster.movingSounds.sound") do
			local v32_ = self.xmlFile:getValue(v31_ .. "#node", nil, self.components, self.i3dMappings)
			local v33_ = Utils.getFilename(self.xmlFile:getValue(v31_ .. "#filename"), v13_)
			local v34_ = self.xmlFile:getValue(v31_ .. "#innerRadius")
			local v35_ = self.xmlFile:getValue(v31_ .. "#radius")
			local v36_ = self.xmlFile:getValue(v31_ .. "#volume", 1)
			local v37_ = createAudioSource("rollercoaster_" .. tostring(v30_), v33_, v35_, v34_, v36_, 0)
			local v38_ = getAudioSourceSample(v37_)
			setSampleGroup(v38_, AudioGroup.ENVIRONMENT)
			link(getChildAt(v32_, 1), v37_)
			local v39_ = v10_.soundsMoving
			table.insert(v39_, {
				["node"] = v32_,
				["movingSound"] = nil
			})
		end
		v10_.sounds = {}
		v10_.sounds.driving1 = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.rollercoaster.sounds", "driving1", v13_, self.components, 0, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
		v10_.sounds.driving2 = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.rollercoaster.sounds", "driving2", v13_, self.components, 0, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
		v10_.sounds.driving3 = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.rollercoaster.sounds", "driving3", v13_, self.components, 0, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
		v10_.sounds.driving4 = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.rollercoaster.sounds", "driving4", v13_, self.components, 0, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
		v10_.sounds.driving5 = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.rollercoaster.sounds", "driving5", v13_, self.components, 0, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
		v10_.speed = 0
		local v40_, v41_, v42_ = getWorldTranslation(v10_.centerCart.node)
		v10_.posX = v40_
		v10_.posY = v41_
		v10_.posZ = v42_
		self.currentUpdateDistance = math.huge
	end
	g_messageCenter:subscribe(MessageType.USER_REMOVED, self.onUserRemoved, self)
end

-- Local values: spec, animNode, characterSet, clipIndex, _, state
function PlaceableRollercoaster:onSharedAnimationFileLoaded(node, failedReason, args)
	local v46_ = self.spec_rollercoaster
	if node ~= 0 and node ~= nil then
		if not self.isDeleted then
			local v47_ = getChildAt(getChildAt(node, 0), 0)
			if cloneAnimCharacterSet(v47_, v46_.animation.clipRootNode) then
				local v48_ = getAnimCharacterSet(v46_.animation.clipRootNode)
				local v49_ = getAnimClipIndex(v48_, v46_.animation.clipName)
				if v49_ == -1 then
					Logging.error("Animation clip with name \'%s\' does not exist in \'%s\'", v46_.animation.clipName, v46_.animation.clipFilename or self.xmlFilename)
				else
					assignAnimTrackClip(v48_, v46_.animation.clipTrack, v49_)
					setAnimTrackLoopState(v48_, v46_.animation.clipTrack, false)
					v46_.animation.clipDuration = getAnimClipDuration(v48_, v49_)
					v46_.animation.clipIndex = v49_
					v46_.animation.clipCharacterSet = v48_
					setAnimTrackSpeedScale(v48_, v49_, v46_.animation.speedScale)
				end
			end
		end
		delete(node)
	end
	v46_.playerRideCounter = {}
	for _, v50_ in pairs(self.spec_constructible.stateMachine) do
		if v50_.init ~= nil then
			v50_:init()
		end
	end
	self:finishLoadingTask(args.loadingTask)
end

-- Local values: spec, x, y, z, _
function PlaceableRollercoaster:onFinalizePlacement(savegame)
	local v52_ = self.spec_rollercoaster
	v52_.rollercoasterHotspot:setPlaceable(self)
	v52_.rollercoasterHotspot:setOwnerFarmId(nil)
	local v53_, _, v54_ = getWorldTranslation(v52_.hotSpotLinkNode)
	v52_.rollercoasterHotspot:setWorldPosition(v53_, v54_)
	local v55_, v56_, v57_ = getWorldTranslation(v52_.hotSpotTeleportNode)
	v52_.rollercoasterHotspot:setTeleportWorldPosition(v55_, v56_, v57_)
	g_currentMission:addMapHotspot(v52_.rollercoasterHotspot)
	if PlaceableRollercoaster.INSTANCE == nil then
		PlaceableRollercoaster.INSTANCE = self
	end
end

-- Local values: spec, _, seat, _, sound
function PlaceableRollercoaster:onDelete()
	local v59_ = self.spec_rollercoaster
	g_messageCenter:unsubscribeAll(self)
	g_currentMission:removeMapHotspot(v59_.rollercoasterHotspot)
	v59_.rollercoasterHotspot:delete()
	if v59_.animation ~= nil and v59_.animation.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(v59_.animation.sharedLoadRequestId)
		v59_.animation.sharedLoadRequestId = nil
	end
	for _, v60_ in ipairs(v59_.seats) do
		if v60_.vehicleCharacter ~= nil then
			v60_.vehicleCharacter:delete()
		end
		if v60_.camera ~= nil then
			v60_.camera:delete()
		end
	end
	if v59_.soundsMoving ~= nil then
		for _, v61_ in ipairs(v59_.soundsMoving) do
			if v61_.movingSound ~= nil then
				g_currentMission.ambientSoundSystem:removeMovingSound(v61_.movingSound)
				v61_.movingSound = nil
			end
		end
	end
	if v59_.sounds ~= nil then
		g_soundManager:deleteSamples(v59_.sounds)
	end
	if v59_.playerTrigger ~= nil then
		removeTrigger(v59_.playerTrigger)
		v59_.playerTrigger = nil
	end
	if PlaceableRollercoaster.INSTANCE == self then
		PlaceableRollercoaster.INSTANCE = nil
	end
end

-- Local values: spec, i, uniqueUserId, rideCount, counterKey
function PlaceableRollercoaster:saveToXMLFile(xmlFile, key, usedModNames)
	local v65_ = self.spec_rollercoaster
	local v66_ = 0
	for v67_, v68_ in pairs(v65_.playerRideCounter) do
		local v69_ = string.format("%s.player(%d)", key, v66_)
		xmlFile:setValue(v69_ .. "#uniqueUserId", v67_)
		xmlFile:setValue(v69_ .. "#rideCount", v68_)
		v66_ = v66_ + 1
	end
end

-- Local values: spec, _, counterKey, uniqueUserId, rideCount
function PlaceableRollercoaster:loadFromXMLFile(xmlFile, key)
	local v73_ = self.spec_rollercoaster
	for _, v74_ in xmlFile:iterator(key .. ".player") do
		local v75_ = xmlFile:getValue(v74_ .. "#uniqueUserId")
		local v76_ = xmlFile:getValue(v74_ .. "#rideCount")
		if v75_ ~= nil and v76_ ~= nil then
			v73_.playerRideCounter[v75_] = v76_
		end
	end
end

-- Local values: spec, seatIndex, seat, player
function PlaceableRollercoaster:onReadStream(streamId, connection)
	local v79_ = self.spec_rollercoaster
	for v80_, _ in ipairs(v79_.seats) do
		if streamReadBool(streamId) then
			self:enterRide(v80_, (NetworkUtil.readNodeObject(streamId)))
		end
	end
end

-- Local values: spec, seatIndex, seat
function PlaceableRollercoaster:onWriteStream(streamId, connection)
	local v83_ = self.spec_rollercoaster
	for _, v84_ in ipairs(v83_.seats) do
		if streamWriteBool(streamId, v84_.player ~= nil) then
			NetworkUtil.writeNodeObject(streamId, v84_.player)
		end
	end
end

-- Local values: spec, _, seat, randomDeviation
function PlaceableRollercoaster:onUpdate(dt)
	local v87_ = self.spec_rollercoaster
	if self.isClient then
		if v87_.localSeatIndex ~= nil then
			v87_.seats[v87_.localSeatIndex].camera:update(dt)
			self:raiseActive()
		end
		for _, v88_ in ipairs(v87_.seats) do
			if v88_.player ~= nil and v88_.player ~= g_localPlayer then
				local v89_ = 1 - v88_.randomFactor
				local v90_ = g_time / 500 + v88_.randomFactor
				local v91_ = v89_ + math.sin(v90_) * (v88_.randomFactor / 5)
				v88_.characterSpineLastRotationX = v88_.smoothingFactor * v88_.characterSpineLastRotationX + v88_.smoothingFactorInv * ((v88_.cart.slope + v91_ / 2) / 5)
				v88_.characterSpineLastRotationZ = v88_.smoothingFactor * v88_.characterSpineLastRotationZ + v88_.smoothingFactorInv * ((v88_.cart.angleChange - v91_) / 20)
				setRotation(v88_.vehicleCharacter.characterNode, v88_.characterSpineLastRotationX, 0, v88_.characterSpineLastRotationZ)
				v88_.vehicleCharacter:updateVisibility()
				v88_.vehicleCharacter:update(dt)
			end
		end
		if v87_.numRiders > 0 then
			self:raiseActive()
			self.currentUpdateDistance = calcDistanceFrom(v87_.centerCart.node, getCamera())
		end
	end
end

-- Local values: spec, _, sound
function PlaceableRollercoaster:finalizeConstruction(superFunc)
	superFunc(self)
	local v94_ = self.spec_rollercoaster
	if v94_.soundsMoving ~= nil then
		for _, v95_ in ipairs(v94_.soundsMoving) do
			if v95_.node and v95_.movingSound == nil then
				v95_.movingSound = g_currentMission.ambientSoundSystem:addMovingSound(v95_.node)
			end
		end
	end
	v94_.rollercoasterHotspot:changeToRollercoaster()
end

-- Local values: spec, currentState, waitingState, isInWaitingState
function PlaceableRollercoaster:getCanEnter()
	local v97_ = self.spec_rollercoaster
	local v98_ = self:getConstructibleStateIndex() == self:getConstructibleStateIndexByName("RIDE_WAITING")
	if v98_ then
		if v97_.animation.clipCharacterSet == nil or v97_.localSeatIndex ~= nil then
			v98_ = false
		else
			v98_ = v97_.numRiders < #v97_.seats
		end
	end
	return v98_
end

-- Local values: spec, seatIndex, seat
function PlaceableRollercoaster:getFreeSeatIndex()
	local v100_ = self.spec_rollercoaster
	for v101_, v102_ in ipairs(v100_.seats) do
		if v102_.player == nil then
			return v101_
		end
	end
	return nil
end

-- Local values: spec
function PlaceableRollercoaster:getCanStart()
	return self.spec_rollercoaster.numRiders > 0
end

-- Local values: spec
function PlaceableRollercoaster:startRide()
	local v105_ = self.spec_rollercoaster
	if v105_.animation.clipCharacterSet ~= nil then
		local _ = v105_.localSeatIndex == nil
		if self.isClient then
			v105_.animationInterpolator:setValue(0)
			v105_.animationTimeInterpolator:reset()
		end
		setAnimTrackTime(v105_.animation.clipCharacterSet, v105_.animation.clipTrack, 0, true)
		enableAnimTrack(v105_.animation.clipCharacterSet, v105_.animation.clipTrack)
		if self.isClient then
			g_soundManager:playSamples(v105_.sounds)
		end
	end
end

-- Local values: spec, seatIndex, seat
function PlaceableRollercoaster:endRide()
	local v107_ = self.spec_rollercoaster
	if self.isClient then
		g_soundManager:stopSamples(v107_.sounds)
	end
	for v108_, v109_ in ipairs(v107_.seats) do
		if v109_.player ~= nil then
			self:exitRide(v108_)
		end
	end
end

-- Local values: seatIndex, userId
function PlaceableRollercoaster:tryEnterRide(connection, player)
	local v112_ = self:getFreeSeatIndex()
	if v112_ ~= nil then
		local v113_ = g_currentMission.userManager:getUserIdByConnection(connection)
		g_server:broadcastEvent(RollercoasterPassengerEnterResponseEvent.new(self, v113_, v112_), true, nil, self, false, nil, true)
	end
end

-- Local values: spec, playerStyle, target, func
function PlaceableRollercoaster:enterRide(seatIndex, player)
	local v117_ = self.spec_rollercoaster
	if player == g_localPlayer then
		v117_.localSeatIndex = seatIndex
		v117_.seats[seatIndex].camera:onActivate()
	else
		local v118_ = player.graphicsComponent:getStyle()
		v117_.seats[seatIndex].vehicleCharacter:loadCharacter(v118_, self, PlaceableRollercoaster.passengerCharacterLoaded, {
			["seat"] = v117_.seats[seatIndex]
		})
	end
	v117_.numRiders = v117_.numRiders + 1
	for _, v119_ in pairs(v117_.ridersChangedListeners) do
		v119_(v117_.numRiders, 1, player)
	end
	if v117_.numRiders >= #v117_.seats then
		self:setPlayerTriggerState(false)
	end
	v117_.seats[seatIndex].player = player
	self:raiseActive()
end

-- Local values: spec, isOwner, player, target, func, userId, user, uniqueUserId, stats
function PlaceableRollercoaster:exitRide(seatIndex)
	local v122_ = self.spec_rollercoaster
	local v123_ = v122_.localSeatIndex == seatIndex
	v122_.seats[seatIndex].vehicleCharacter:unloadCharacter()
	local v124_ = v122_.seats[seatIndex].player
	if v123_ then
		v122_.seats[seatIndex].camera:onDeactivate()
		g_currentMission.hud:setIsVisible(true)
		v122_.localSeatIndex = nil
	end
	v124_:onLeaveRollercoaster()
	v122_.numRiders = v122_.numRiders - 1
	for _, v125_ in pairs(v122_.ridersChangedListeners) do
		v125_(v122_.numRiders, -1, v122_.seats[seatIndex].player)
	end
	if self.isServer and v124_ ~= nil then
		local v126_ = v124_.userId
		local v127_ = g_currentMission.userManager:getUserByUserId(v126_)
		if v127_ ~= nil then
			local v128_ = v127_:getUniqueUserId()
			if v122_.playerRideCounter[v128_] == nil then
				v122_.playerRideCounter[v128_] = 0
			end
			v122_.playerRideCounter[v128_] = v122_.playerRideCounter[v128_] + 1
		end
		if v124_ == g_localPlayer then
			g_currentMission:farmStats(g_localPlayer.farmId)
		end
	end
	v122_.seats[seatIndex].player = nil
end

-- Local values: spec, userId, seatIndex, seat
function PlaceableRollercoaster:onUserRemoved(user)
	local v131_ = self.spec_rollercoaster
	local v132_ = user:getId()
	for v133_, v134_ in ipairs(v131_.seats) do
		if v134_.player ~= nil and v134_.player.userId == v132_ then
			self:exitRide(v133_)
			return
		end
	end
end

-- Local values: spec
function PlaceableRollercoaster:registerRidersChangedListener(target, func)
	self.spec_rollercoaster.ridersChangedListeners[target] = func
end

-- Local values: spec
function PlaceableRollercoaster:unregisterRidersChangedListener(target)
	self.spec_rollercoaster.ridersChangedListeners[target] = nil
end

-- Local values: spec
function PlaceableRollercoaster:getAnimation()
	return self.spec_rollercoaster.animation
end

-- Local values: spec
function PlaceableRollercoaster:setAnimationTime(animationTime)
	local v143_ = self.spec_rollercoaster
	setAnimTrackTime(v143_.animation.clipCharacterSet, v143_.animation.clipTrack, animationTime, true)
end

-- Local values: spec, x, y, z, distance, _, cart, dx, dy, dz, angleChange, slope
function PlaceableRollercoaster:updateFxModifierValues(dt)
	local v146_ = self.spec_rollercoaster
	local v147_, v148_, v149_ = getWorldTranslation(v146_.centerCart.node)
	local v150_ = MathUtil.vector3Length(v147_ - v146_.posX, v148_ - v146_.posY, v149_ - v146_.posZ)
	v146_.posX = v147_
	v146_.posY = v148_
	v146_.posZ = v149_
	v146_.speed = 0.2 * v146_.speed + 0.8 * v150_ / (dt / 1000)
	for _, v151_ in ipairs(v146_.carts) do
		local v152_, v153_, v154_ = localDirectionToWorld(v151_.node, 0, 0, 1)
		local v155_ = MathUtil.getVectorAngleDifference(v152_, 0, v154_, v151_.dirX, 0, v151_.dirZ)
		local v156_ = MathUtil.isNan(v155_) and 0 or v155_
		v151_.angleChange = 0.6 * v151_.angleChange + 0.4 * (v156_ * 100)
		v151_.dirX = v152_
		v151_.dirY = v153_
		v151_.dirZ = v154_
		local v157_, v158_, v159_ = localDirectionToWorld(v151_.node, 1, 0, 0)
		local v160_ = v158_ / MathUtil.vector3Length(v157_, v158_, v159_)
		local v161_ = math.acos(v160_) - 1.5707963267948966
		v151_.slope = 0.7 * v151_.slope + 0.3 * v161_
	end
end

function PlaceableRollercoaster:getParentComponent(node)
	return getParent(node)
end

-- Local values: seat
function PlaceableRollercoaster:passengerCharacterLoaded(success, arguments)
	if success then
		local v165_ = arguments.seat
		if v165_ ~= nil then
			v165_.vehicleCharacter:updateVisibility()
			v165_.vehicleCharacter:updateIKChains()
		end
	end
end

-- Local values: spec
function PlaceableRollercoaster:playerTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if (onEnter or onLeave) and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
		local v170_ = self.spec_rollercoaster
		if onEnter then
			if Platform.isMobile and v170_.activatable:getIsActivatable() then
				v170_.activatable:run()
				return
			end
			g_currentMission.activatableObjectsSystem:addActivatable(v170_.activatable)
		end
		if onLeave then
			g_currentMission.activatableObjectsSystem:removeActivatable(v170_.activatable)
		end
	end
end

-- Local values: spec
function PlaceableRollercoaster:setPlayerTriggerState(state)
	local v173_ = self.spec_rollercoaster
	setVisibility(v173_.playerTrigger, state)
end

-- Local values: spec
function PlaceableRollercoaster:getNumRides(uniqueUserId)
	return self.spec_rollercoaster.playerRideCounter[uniqueUserId] or 0
end

-- Local values: spec
function PlaceableRollercoaster:getHotspot(index)
	return self.spec_rollercoaster.rollercoasterHotspot
end

-- Local values: spec
function PlaceableRollercoaster:getSpeedSoundModifier()
	return self.spec_rollercoaster.speed
end
g_soundManager:registerModifierType("ROLLERCOASTER_SPEED", PlaceableRollercoaster.getSpeedSoundModifier)

-- Local values: spec
function PlaceableRollercoaster:getCurveSoundModifier()
	local v179_ = self.spec_rollercoaster
	if v179_.localSeatIndex == nil then
		local v180_ = v179_.centerCart.angleChange
		return math.abs(v180_)
	else
		local v181_ = v179_.seats[v179_.localSeatIndex].cart.angleChange
		return math.abs(v181_)
	end
end
g_soundManager:registerModifierType("ROLLERCOASTER_CURVE", PlaceableRollercoaster.getCurveSoundModifier)
