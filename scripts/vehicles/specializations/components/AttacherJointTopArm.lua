-- Local values: AttacherJointTopArm_mt
AttacherJointTopArm = {}
AttacherJointTopArm.RENAMED_UPPER_LINKS = {}
AttacherJointTopArm.RENAMED_UPPER_LINKS.walterscheid01 = "walterscheidSO_65_460"
AttacherJointTopArm.RENAMED_UPPER_LINKS.walterscheid02 = "walterscheidSO_65_660"
AttacherJointTopArm.RENAMED_UPPER_LINKS.walterscheid03 = "walterscheidHO_90_600"
AttacherJointTopArm.RENAMED_UPPER_LINKS.walterscheid04 = "walterscheidHO_110_700"
AttacherJointTopArm.RENAMED_UPPER_LINKS.walterscheid05 = "walterscheidSO_65_1210"
AttacherJointTopArm.RENAMED_UPPER_LINKS.walterscheid06 = "walterscheidSO_65_560"
AttacherJointTopArm.RENAMED_UPPER_LINKS.walterscheid07 = "walterscheidHO_110_610"
AttacherJointTopArm.RENAMED_UPPER_LINKS.walterscheid08 = "walterscheidHO_110_735"
AttacherJointTopArm.RENAMED_UPPER_LINKS.walterscheid09 = "walterscheidHO_140_750"
local AttacherJointTopArm_mt = Class(AttacherJointTopArm)

-- Upvalues: AttacherJointTopArm_mt
-- Local values: self
function AttacherJointTopArm.new(vehicle, customMt)
	-- upvalues: (copy) AttacherJointTopArm_mt
	local v4_ = customMt or AttacherJointTopArm_mt
	local v5_ = setmetatable({}, v4_)
	v5_.vehicle = vehicle
	v5_.components = {}
	v5_.i3dMappings = {}
	v5_.zScale = -1
	v5_.toggleVisibility = false
	v5_.useMountArm = true
	v5_.useBrandDecal = true
	v5_.changeObjects = {}
	return v5_
end

function AttacherJointTopArm:delete()
	if self.node ~= nil then
		delete(self.node)
		self.node = nil
	end
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
		self.sharedLoadRequestId = nil
	end
end

function AttacherJointTopArm:setCallback(callback, callbackTarget)
	self.callback = callback
	self.callbackTarget = callbackTarget
end

function AttacherJointTopArm:onFinished(success)
	if self.xmlFile ~= nil then
		self.xmlFile:delete()
		self.xmlFile = nil
	end
	self:finalize()
	if self.callback ~= nil then
		if self.callbackTarget ~= nil then
			self.callback(self.callbackTarget, success)
			return
		end
		self.callback(success)
	end
end

-- Local values: topArm, baseNode, filename, oldName, newName, rotationNode
function AttacherJointTopArm.loadFromVehicleXML(vehicle, key)
	local v14_ = nil
	local v15_ = vehicle.xmlFile:getValue(key .. "#baseNode", nil, vehicle.components, vehicle.i3dMappings)
	local v16_ = vehicle.xmlFile:getValue(key .. "#filename", nil, vehicle.baseDirectory)
	if v15_ == nil or v16_ == nil then
		local v17_ = vehicle.xmlFile:getValue(key .. "#rotationNode", nil, vehicle.components, vehicle.i3dMappings)
		if v17_ ~= nil then
			v14_ = AttacherJointTopArm.new(vehicle)
			v14_.node = v17_
			v14_.translationNode = vehicle.xmlFile:getValue(key .. "#translationNode", nil, vehicle.components, vehicle.i3dMappings)
			v14_.referenceNodeTranslation = vehicle.xmlFile:getValue(key .. "#referenceNode", nil, vehicle.components, vehicle.i3dMappings)
			v14_:finalize()
		end
	else
		XMLUtil.checkDeprecatedXMLElements(vehicle.xmlFile, key .. "#color", key .. "#materialTemplateName")
		XMLUtil.checkDeprecatedXMLElements(vehicle.xmlFile, key .. "#color2", key .. "#materialTemplateName2")
		XMLUtil.checkDeprecatedXMLElements(vehicle.xmlFile, key .. "#decalColor", key .. "#decalMaterialTemplateName")
		if string.contains(v16_, ".i3d") then
			Logging.xmlWarning(vehicle.xmlFile, "Top arm filename is referring to the i3d file. Please use the xml file instead. (%s)", v16_)
			v16_ = string.gsub(v16_, ".i3d", ".xml")
		end
		for v18_, v19_ in pairs(AttacherJointTopArm.RENAMED_UPPER_LINKS) do
			if v16_ == string.format("data/shared/assets/upperLinks/%s.xml", v18_) then
				Logging.xmlWarning(vehicle.xmlFile, "Top arm has been renamed from \'%s\' to \'%s\' in \'%s\' (Names now include type, diameter and min. length)", v18_, v19_, key)
				v16_ = string.format("data/shared/assets/upperLinks/%s.xml", v19_)
			end
		end
		v14_ = AttacherJointTopArm.new(vehicle)
		if not v14_:loadFromXML(v15_, v16_, vehicle.baseDirectory) then
			v14_ = nil
		end
	end
	if v14_ ~= nil then
		v14_.zScale = vehicle.xmlFile:getValue(key .. "#zScale", -1)
		v14_.toggleVisibility = vehicle.xmlFile:getValue(key .. "#toggleVisibility", v14_.toggleVisibility)
		v14_.useMountArm = vehicle.xmlFile:getValue(key .. "#useMountArm", v14_.useMountArm)
		v14_.mountArmRotation = vehicle.xmlFile:getValue(key .. "#mountArmRotation", nil, true)
		v14_.useBrandDecal = vehicle.xmlFile:getValue(key .. "#useBrandDecal", v14_.useBrandDecal)
		v14_.material = vehicle.xmlFile:getValue(key .. "#materialTemplateName", nil, vehicle.customEnvironment)
		v14_.material2 = vehicle.xmlFile:getValue(key .. "#materialTemplateName2", nil, vehicle.customEnvironment)
		v14_.decalMaterial = vehicle.xmlFile:getValue(key .. "#decalMaterialTemplateName", nil, vehicle.customEnvironment)
		v14_.useMainColor = vehicle.xmlFile:getValue(key .. "#secondPartUseMainColor", true)
		ObjectChangeUtil.loadObjectChangeFromXML(vehicle.xmlFile, key, v14_.changeObjects, vehicle.components, vehicle)
		ObjectChangeUtil.setObjectChanges(v14_.changeObjects, false, vehicle, vehicle.setMovingToolDirty, true)
	end
	return v14_
end

-- Local values: filename
function AttacherJointTopArm:loadFromXML(linkNode, xmlFilename, baseDirectory)
	self.xmlFile = XMLFile.loadIfExists("AttacherJointTopArm", xmlFilename, AttacherJointTopArm.xmlSchema)
	if self.xmlFile == nil then
		if self.vehicle == nil then
			Logging.warning("Unable to load top arm from xml \'%s\'", xmlFilename)
		else
			Logging.xmlWarning(self.vehicle.xmlFile, "Unable to load top arm from xml \'%s\'", xmlFilename)
		end
		self:onFinished(false)
		return false
	end
	local v24_ = self.xmlFile:getValue("topArm.filename", nil, baseDirectory)
	if v24_ == nil then
		Logging.xmlWarning(self.xmlFile, "Missing top arm i3d filename!")
		self:onFinished(false)
		return false
	end
	self.filename = v24_
	self.linkNode = linkNode
	if self.vehicle == nil then
		self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.filename, false, false, self.onI3DLoaded, self, nil)
	else
		self.sharedLoadRequestId = self.vehicle:loadSubSharedI3DFile(self.filename, false, false, self.onI3DLoaded, self, nil)
	end
	return true
end

-- Local values: brightness, decalMaterial
function AttacherJointTopArm:onI3DLoaded(i3dNode, failedReason, args)
	if i3dNode ~= 0 then
		I3DUtil.loadI3DComponents(i3dNode, self.components)
		I3DUtil.loadI3DMapping(self.xmlFile, "topArm", self.components, self.i3dMappings)
		self.node = self.xmlFile:getValue("topArm.rootNode#node", "0", self.components, self.i3dMappings)
		if self.node ~= nil then
			link(self.linkNode, self.node)
			setTranslation(self.node, 0, 0, 0)
			setRotation(self.node, 0, self.zScale < 0 and 3.141592653589793 or 0, 0)
			self.translationNode = self.xmlFile:getValue("topArm.translation#node", nil, self.components, self.i3dMappings)
			self.referenceNodeTranslation = self.xmlFile:getValue("topArm.translation#referenceNode", nil, self.components, self.i3dMappings)
			self.scaleNode = self.xmlFile:getValue("topArm.scale#node", nil, self.components, self.i3dMappings)
			self.referenceNodeScale = self.xmlFile:getValue("topArm.scale#referenceNode", nil, self.components, self.i3dMappings)
			self.brandDecal = self.xmlFile:getValue("topArm.brandDecal#node", nil, self.components, self.i3dMappings)
			if not self.useBrandDecal and self.brandDecal ~= nil then
				setVisibility(self.brandDecal, false)
			end
			self.mountArmNode = self.xmlFile:getValue("topArm.mountArm#node", nil, self.components, self.i3dMappings)
			if self.mountArmNode ~= nil then
				if self.useMountArm then
					self.mountArmRotationDefault = { getRotation(self.mountArmNode) }
				else
					setVisibility(self.mountArmNode, false)
					self.mountArmNode = nil
				end
			end
			if self.decalMaterial == nil and self.material ~= nil then
				local v27_ = self.material:getBrightness()
				if v27_ ~= nil then
					local v28_ = v27_ > 0.075 and 1 or 0
					VehicleMaterial.new():setColor(1 - v28_, 1 - v28_, 1 - v28_)
				end
			end
			if self.material ~= nil then
				self.material:apply(self.node, "upperLink_main_mat")
			end
			if self.material2 ~= nil then
				self.material2:apply(self.node, "upperLink_base_mat")
			end
			if self.useMainColor then
				if self.material ~= nil then
					self.material:apply(self.node, "upperLink_head_mat")
				end
			elseif self.material2 ~= nil then
				self.material2:apply(self.node, "upperLink_head_mat")
			end
			if self.decalMaterial ~= nil then
				self.decalMaterial:apply(self.node, "upperLink_decal_mat")
			end
		end
		delete(i3dNode)
	end
	if self.node ~= nil then
		self:setIsActive(false)
	end
	self:onFinished(self.node ~= nil)
end

-- Local values: _, _, zOffset
function AttacherJointTopArm:finalize()
	if self.translationNode ~= nil and self.referenceNodeTranslation ~= nil then
		self.referenceDistance = calcDistanceFrom(self.referenceNodeTranslation, self.translationNode)
		self.translationDefault = { getTranslation(self.translationNode) }
	end
	if self.scaleNode ~= nil and self.referenceNodeScale ~= nil then
		local _, _, v30_ = localToLocal(self.referenceNodeScale, self.scaleNode, 0, 0, 0)
		self.scaleReferenceDistance = v30_
	end
end

-- Local values: rotation
function AttacherJointTopArm:setIsActive(isActive)
	if self.mountArmNode ~= nil and self.mountArmRotation ~= nil then
		local v33_ = isActive and self.mountArmRotationDefault or self.mountArmRotation
		setRotation(self.mountArmNode, v33_[1], v33_[2], v33_[3])
	end
	if self.toggleVisibility then
		setVisibility(self.node, isActive)
	end
	if not isActive then
		setRotation(self.node, 0, self.zScale < 0 and 3.141592653589793 or 0, 0)
		if self.translationDefault ~= nil then
			setTranslation(self.translationNode, self.translationDefault[1], self.translationDefault[2], self.translationDefault[3])
		end
		if self.scaleNode ~= nil then
			setScale(self.scaleNode, 1, 1, 1)
		end
	end
	ObjectChangeUtil.setObjectChanges(self.changeObjects, isActive, self.vehicle, self.vehicle.setMovingToolDirty, true)
end

-- Local values: ax, ay, az, bx, by, bz, dirX, dirY, dirZ, alpha, _, _, lz, dx, dy, dz, upX, upY, upZ, distance, translation
function AttacherJointTopArm:update(dt, targetNode)
	local v36_, v37_, v38_ = getWorldTranslation(self.node)
	local v39_, v40_, v41_ = getWorldTranslation(targetNode)
	local v42_, v43_, v44_ = worldDirectionToLocal(getParent(self.node), v39_ - v36_, v40_ - v37_, v41_ - v38_)
	local _, _, v45_ = worldToLocal(self.vehicle.rootNode, v36_, v37_, v38_)
	local v46_ = v45_ < 0 and 1.5707963267948966 or -1.5707963267948966
	local v47_, v48_, v49_ = localDirectionToLocal(self.node, getParent(self.node), 0, 0, 1)
	local v50_ = math.cos(v46_) * v48_ - math.sin(v46_) * v49_
	local v51_ = math.sin(v46_) * v48_ + math.cos(v46_) * v49_
	setDirection(self.node, v42_, v43_, v44_, v47_, v50_, v51_)
	if self.referenceDistance ~= nil then
		local v52_ = MathUtil.vector3Length(v42_, v43_, v44_) - self.referenceDistance
		setTranslation(self.translationNode, 0, 0, v52_)
		if self.scaleReferenceDistance ~= nil then
			local v53_ = setScale
			local v54_ = self.scaleNode
			local v55_ = (v52_ + self.scaleReferenceDistance) / self.scaleReferenceDistance
			v53_(v54_, 1, 1, (math.max(v55_, 0)))
		end
	end
end

function AttacherJointTopArm.registerVehicleXMLPaths(schema, baseKey)
	schema:register(XMLValueType.FILENAME, baseKey .. "#filename", "Path to top arm i3d file")
	schema:register(XMLValueType.NODE_INDEX, baseKey .. "#baseNode", "Link node for upper link")
	schema:register(XMLValueType.INT, baseKey .. "#zScale", "Inverts top arm direction", 1)
	schema:register(XMLValueType.BOOL, baseKey .. "#toggleVisibility", "Top arm will be hidden on detach", false)
	schema:register(XMLValueType.BOOL, baseKey .. "#useMountArm", "Defines if the mount arm is visible or not", true)
	schema:register(XMLValueType.VECTOR_ROT, baseKey .. "#mountArmRotation", "Defines a custom mount arm rotation while no tool is attached")
	schema:register(XMLValueType.VEHICLE_MATERIAL, baseKey .. "#materialTemplateName", "Top arm material (applied to \'upperLink_main_mat\')")
	schema:registerAutoCompletionDataSource(baseKey .. "#materialTemplateName", "$data/shared/brandMaterialTemplates.xml", "templates.template#name")
	schema:register(XMLValueType.VEHICLE_MATERIAL, baseKey .. "#materialTemplateName2", "Top arm material 2 (applied to \'upperLink_base_mat\')")
	schema:registerAutoCompletionDataSource(baseKey .. "#materialTemplateName2", "$data/shared/brandMaterialTemplates.xml", "templates.template#name")
	schema:register(XMLValueType.VEHICLE_MATERIAL, baseKey .. "#decalMaterialTemplateName", "Top arm decal color (applied to \'upperLink_decal_mat\')")
	schema:registerAutoCompletionDataSource(baseKey .. "#decalMaterialTemplateName", "$data/shared/brandMaterialTemplates.xml", "templates.template#name")
	schema:register(XMLValueType.BOOL, baseKey .. "#secondPartUseMainColor", "Defines if the material \'upperLink_head_mat\' uses the \'material\' or \'material2\' value", true)
	schema:register(XMLValueType.BOOL, baseKey .. "#useBrandDecal", "Defines if the brand decal on the top arm is allowed or not", true)
	schema:register(XMLValueType.NODE_INDEX, baseKey .. "#rotationNode", "Rotation node if top arm not loaded from i3d")
	schema:register(XMLValueType.NODE_INDEX, baseKey .. "#translationNode", "Translation node if top arm not loaded from i3d")
	schema:register(XMLValueType.NODE_INDEX, baseKey .. "#referenceNode", "Reference node if top arm not loaded from i3d")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, baseKey)
end

function AttacherJointTopArm.registerXMLPaths(schema)
	schema:register(XMLValueType.FILENAME, "topArm.filename", "Path to top arm i3d file")
	schema:register(XMLValueType.NODE_INDEX, "topArm.rootNode#node", "Root node of the top arm")
	schema:register(XMLValueType.NODE_INDEX, "topArm.translation#node", "Translating part of the top arm")
	schema:register(XMLValueType.NODE_INDEX, "topArm.translation#referenceNode", "Reference node at the end of the top arm")
	schema:register(XMLValueType.NODE_INDEX, "topArm.scale#node", "Node that is scaled")
	schema:register(XMLValueType.NODE_INDEX, "topArm.scale#referenceNode", "Reference node at the end of the scale part")
	schema:register(XMLValueType.NODE_INDEX, "topArm.brandDecal#node", "Branded decal on the top arm")
	schema:register(XMLValueType.NODE_INDEX, "topArm.mountArm#node", "Mount arm node that can be adjusted from the vehicle")
	I3DUtil.registerI3dMappingXMLPaths(schema, "topArm")
end
g_xmlManager:addCreateSchemaFunction(function()
	AttacherJointTopArm.xmlSchema = XMLSchema.new("attacherJointTopArm")
end)
g_xmlManager:addInitSchemaFunction(function()
	AttacherJointTopArm.registerXMLPaths(AttacherJointTopArm.xmlSchema)
end)
