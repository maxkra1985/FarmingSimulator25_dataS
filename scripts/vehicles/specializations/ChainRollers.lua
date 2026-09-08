ChainRollers = {}

function ChainRollers.prerequisitesPresent(specializations)
	return true
end
function ChainRollers.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("ChainRollers")
	v1_:register(XMLValueType.FLOAT, "vehicle.chainRollers#maxUpdateDistance", "If the player is more than this distance away the nodes will no longer be updated", 100)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.chainRollers.chainRoller(?)#elementsNode", "Root node that contains every chain link")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.chainRollers.chainRoller(?)#endReferenceNode", "Reference node for the alignment of the last chain link")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.chainRollers.chainRoller(?).splineNode(?)#node", "Regular transform group(s) that define the spline (at least two have to be defined)")
	v1_:addDelayedRegistrationFunc("Cylindered:movingTool", function(p2_, p3_)
		p2_:register(XMLValueType.NODE_INDICES, p3_ .. ".chainRollers#splineNodes", "Spline nodes to update")
	end)
	v1_:addDelayedRegistrationFunc("Cylindered:movingPart", function(p4_, p5_)
		p4_:register(XMLValueType.NODE_INDICES, p5_ .. ".chainRollers#splineNodes", "Spline nodes to update")
	end)
	v1_:setXMLSpecializationType()
end

function ChainRollers.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadChainRollerFromXML", ChainRollers.loadChainRollerFromXML)
	SpecializationUtil.registerFunction(vehicleType, "updateChainRoller", ChainRollers.updateChainRoller)
end

function ChainRollers.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadExtraDependentParts", ChainRollers.loadExtraDependentParts)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", ChainRollers.updateExtraDependentParts)
end

function ChainRollers.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ChainRollers)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", ChainRollers)
	SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", ChainRollers)
end

-- Local values: spec
function ChainRollers:onLoad(savegame)
	local v_u_10_ = self.spec_chainRollers
	if self.xmlFile:hasProperty("vehicle.chainRollers") then
		v_u_10_.maxUpdateDistance = self.xmlFile:getValue("vehicle.chainRollers#maxUpdateDistance", 100)
		v_u_10_.chainRollers = {}
		v_u_10_.chainRollerSplineNodeToSpline = {}
		self.xmlFile:iterate("vehicle.chainRollers.chainRoller", function(_, p11_)
			-- upvalues: (copy) self, (copy) v_u_10_
			local v12_ = {}
			if self:loadChainRollerFromXML(self.xmlFile, p11_, v12_) then
				local v13_ = v_u_10_.chainRollers
				table.insert(v13_, v12_)
			end
		end)
		if #v_u_10_.chainRollers == 0 then
			SpecializationUtil.removeEventListener(self, "onLoadFinished", ChainRollers)
			SpecializationUtil.removeEventListener(self, "onPostUpdate", ChainRollers)
		end
	else
		SpecializationUtil.removeEventListener(self, "onLoadFinished", ChainRollers)
		SpecializationUtil.removeEventListener(self, "onPostUpdate", ChainRollers)
	end
end

function ChainRollers:onLoadFinished(savegame)
	ChainRollers.onPostUpdate(self, 99999, false, false, false)
end

-- Local values: spec, splineNode, splineData, _, chainRoller, _, chainRoller, i, x1, y1, z1, x2, y2, z2, i, t, x1, y1, z1, x2, y2, z2
function ChainRollers:onPostUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v17_ = self.spec_chainRollers
	if self.currentUpdateDistance < v17_.maxUpdateDistance then
		for v18_, v19_ in pairs(v17_.chainRollerSplineNodeToSpline) do
			if v19_.isDirty then
				setSplineCV(v19_.spline, v19_.index, localToLocal(v18_, v19_.spline, 0, 0, 0))
				v19_.isDirty = false
				v19_.chainRoller.isDirty = true
			end
		end
		for _, v20_ in pairs(v17_.chainRollers) do
			if v20_.isDirty then
				self:updateChainRoller(v20_, dt)
				v20_.isDirty = false
			end
		end
		if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
			for _, v21_ in pairs(v17_.chainRollers) do
				for v22_ = 1, #v21_.splineNodes - 1 do
					local v23_, v24_, v25_ = getWorldTranslation(v21_.splineNodes[v22_])
					local v26_, v27_, v28_ = getWorldTranslation(v21_.splineNodes[v22_ + 1])
					drawDebugLine(v23_, v24_, v25_, 1, 0, 0, v26_, v27_, v28_, 1, 0, 0, false)
					drawDebugPoint(v23_, v24_, v25_, 1, 0, 0, 1, false)
					drawDebugPoint(v26_, v27_, v28_, 1, 0, 0, 1, false)
				end
				for v29_ = 0, 99 do
					local v30_ = v29_ / 100
					local v31_, v32_, v33_ = getSplinePosition(v21_.spline, v30_)
					local v34_, v35_, v36_ = getSplinePosition(v21_.spline, v30_ + 0.01)
					drawDebugLine(v31_, v32_, v33_, 0, 1, 0, v34_, v35_, v36_, 0, 1, 0, false)
				end
			end
		end
	end
end

-- Local values: spec, i, node, editPoints, _, splineNode, x, y, z, index, splineNode
function ChainRollers:loadChainRollerFromXML(xmlFile, key, chainRoller)
	local v41_ = self.spec_chainRollers
	chainRoller.elementsNode = xmlFile:getValue(key .. "#elementsNode", nil, self.components, self.i3dMappings)
	if chainRoller.elementsNode == nil then
		Logging.xmlWarning(xmlFile, "Missing \'elementsNode\' for chainRoller \'%s\'!", key)
		return false
	end
	chainRoller.elements = {}
	for v42_ = 1, getNumOfChildren(chainRoller.elementsNode) do
		local v43_ = getChildAt(chainRoller.elementsNode, v42_ - 1)
		local v44_ = chainRoller.elements
		table.insert(v44_, v43_)
	end
	chainRoller.numElements = #chainRoller.elements
	if chainRoller.numElements == 0 then
		Logging.xmlWarning(xmlFile, "Missing elements inside \'elementsNode\' for chainRoller \'%s\'!", key)
		return false
	end
	chainRoller.endReferenceNode = xmlFile:getValue(key .. "#endReferenceNode", nil, self.components, self.i3dMappings)
	chainRoller.splineNodes = {}
	xmlFile:iterate(key .. ".splineNode", function(_, p45_)
		-- upvalues: (copy) xmlFile, (copy) self, (copy) chainRoller
		local v46_ = xmlFile:getValue(p45_ .. "#node", nil, self.components, self.i3dMappings)
		if v46_ == nil then
			Logging.xmlWarning(xmlFile, "Missing \'node\' for chainRoller spline \'%s\'!", p45_)
			return false
		end
		local v47_ = chainRoller.splineNodes
		table.insert(v47_, v46_)
	end)
	if #chainRoller.splineNodes < 2 then
		Logging.xmlWarning(xmlFile, "Missing spline nodes for chainRoller \'%s\', at least two are required!", key)
		return false
	end
	local v48_ = {}
	for _, v49_ in pairs(chainRoller.splineNodes) do
		local v50_, v51_, v52_ = getTranslation(v49_)
		table.insert(v48_, v50_)
		table.insert(v48_, v51_)
		table.insert(v48_, v52_)
	end
	chainRoller.spline = createSplineFromEditPoints(getParent(chainRoller.splineNodes[1]), v48_, false, false)
	setVisibility(chainRoller.spline, false)
	for v53_, v54_ in pairs(chainRoller.splineNodes) do
		v41_.chainRollerSplineNodeToSpline[v54_] = {
			["chainRoller"] = chainRoller,
			["spline"] = chainRoller.spline,
			["index"] = v53_ - 1,
			["isDirty"] = false
		}
	end
	chainRoller.isDirty = true
	return true
end

-- Local values: lastX, lastY, lastZ, lastElementNode, i, elementNode, t, x, y, z, dx, dy, dz, lastElement, x, y, z, dx, dy, dz
function ChainRollers:updateChainRoller(chainRoller, dt)
	local v56_ = nil
	local v57_ = nil
	local v58_ = nil
	local v59_ = nil
	for v60_ = 1, chainRoller.numElements do
		local v61_ = chainRoller.elements[v60_]
		local v62_ = (v60_ - 1) / (chainRoller.numElements - 1)
		local v63_, v64_, v65_ = getSplinePosition(chainRoller.spline, v62_)
		setWorldTranslation(v61_, v63_, v64_, v65_)
		if v56_ ~= nil then
			local v66_, v67_, v68_ = MathUtil.vector3Normalize(v63_ - v56_, v64_ - v57_, v65_ - v58_)
			local v69_, v70_, v71_ = worldDirectionToLocal(chainRoller.elementsNode, v66_, v67_, v68_)
			setDirection(v59_, v69_, v70_, v71_, 0, 1, 0)
		end
		v59_ = v61_
		v58_ = v65_
		v57_ = v64_
		v56_ = v63_
	end
	if chainRoller.endReferenceNode ~= nil then
		local v72_ = chainRoller.elements[chainRoller.numElements]
		local v73_, v74_, v75_ = getWorldTranslation(chainRoller.endReferenceNode)
		local v76_, v77_, v78_ = MathUtil.vector3Normalize(v73_ - v56_, v74_ - v57_, v75_ - v58_)
		local v79_, v80_, v81_ = worldDirectionToLocal(chainRoller.elementsNode, v76_, v77_, v78_)
		setDirection(v72_, v79_, v80_, v81_, 0, 1, 0)
	end
end

-- Local values: splineNodes
function ChainRollers:loadExtraDependentParts(superFunc, xmlFile, baseName, entry)
	if not superFunc(self, xmlFile, baseName, entry) then
		return false
	end
	local v87_ = xmlFile:getValue(baseName .. ".chainRollers#splineNodes", nil, self.components, self.i3dMappings, true)
	if v87_ ~= nil and #v87_ > 0 then
		entry.chainRollerSplineNodes = v87_
	end
	return true
end

-- Local values: spec, i, splineNode, splineData
function ChainRollers:updateExtraDependentParts(superFunc, part, dt)
	superFunc(self, part, dt)
	if part.chainRollerSplineNodes ~= nil then
		local v92_ = self.spec_chainRollers
		for v93_ = 1, #part.chainRollerSplineNodes do
			local v94_ = part.chainRollerSplineNodes[v93_]
			local v95_ = v92_.chainRollerSplineNodeToSpline[v94_]
			if v95_ ~= nil then
				v95_.isDirty = true
			end
		end
	end
end
