-- Local values: ConnectionHoseManager_mt
ConnectionHoseType = nil
ConnectionHoseManager = {}
ConnectionHoseManager.DEFAULT_HOSES_FILENAME = "data/shared/connectionHoses/connectionHoses.xml"
ConnectionHoseManager.xmlSchema = nil
local ConnectionHoseManager_mt = Class(ConnectionHoseManager, AbstractManager)

-- Upvalues: ConnectionHoseManager_mt
-- Local values: self
function ConnectionHoseManager.new(customMt)
	-- upvalues: (copy) ConnectionHoseManager_mt
	local v3_ = AbstractManager.new(customMt or ConnectionHoseManager_mt)
	v3_:initDataStructures()
	ConnectionHoseManager.xmlSchema = XMLSchema.new("connectionHoses")
	ConnectionHoseManager:registerXMLPaths(ConnectionHoseManager.xmlSchema)
	return v3_
end

function ConnectionHoseManager:initDataStructures()
	self.xmlFiles = {}
	self.typeByName = {}
	ConnectionHoseType = self.typeByName
	self.basicHoses = {}
	self.sockets = {}
	self.sharedLoadRequestIds = {}
	self.modConnectionHosesToLoad = {}
end

-- Local values: i, modConnectionHoseToLoad
function ConnectionHoseManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	ConnectionHoseManager:superClass().loadMapData(self)
	self.baseDirectory = baseDirectory
	self:loadConnectionHosesFromXML(ConnectionHoseManager.DEFAULT_HOSES_FILENAME, nil, self.baseDirectory)
	for v7_ = #self.modConnectionHosesToLoad, 1, -1 do
		local v8_ = self.modConnectionHosesToLoad[v7_]
		self:loadConnectionHosesFromXML(v8_.xmlFilename, v8_.customEnvironment, v8_.baseDirectory)
		self.modConnectionHosesToLoad[v7_] = nil
	end
end

-- Local values: _, entry, _, hoseType, _, adapter, _, hose, _, entry, i, sharedLoadRequestId, xmlFile, _
function ConnectionHoseManager:unloadMapData()
	for _, v10_ in ipairs(self.basicHoses) do
		delete(v10_.node)
	end
	for _, v11_ in pairs(self.typeByName) do
		for _, v12_ in pairs(v11_.adapters) do
			delete(v12_.node)
			delete(v12_.detachedNode)
		end
		for _, v13_ in pairs(v11_.hoses) do
			delete(v13_.materialNode)
		end
	end
	for _, v14_ in pairs(self.sockets) do
		delete(v14_.node)
	end
	for v15_ = 1, #self.sharedLoadRequestIds do
		local v16_ = self.sharedLoadRequestIds[v15_]
		g_i3DManager:releaseSharedI3DFile(v16_)
	end
	for v17_, _ in pairs(self.xmlFiles) do
		self.xmlFiles[v17_] = nil
		v17_:delete()
	end
	ConnectionHoseManager:superClass().unloadMapData(self)
end

function ConnectionHoseManager:addModConnectionHoses(xmlFilename, customEnvironment, baseDirectory)
	local v22_ = self.modConnectionHosesToLoad
	table.insert(v22_, {
		["xmlFilename"] = xmlFilename,
		["customEnvironment"] = customEnvironment,
		["baseDirectory"] = baseDirectory
	})
end

-- Local values: xmlFile, i, hoseKey, filename, arguments, sharedLoadRequestId, key, name, hoseType, j, adapterKey, adapterName, filename, arguments, sharedLoadRequestId, hoseKey, hoseName, filename, arguments, sharedLoadRequestId, socketKey, name, filename, arguments, sharedLoadRequestId
function ConnectionHoseManager:loadConnectionHosesFromXML(xmlFilename, customEnvironment, baseDirectory)
	Logging.info("Loading ConnectionHoses from \'%s\'", xmlFilename)
	local v27_ = XMLFile.load("TempHoses", xmlFilename, ConnectionHoseManager.xmlSchema)
	if v27_ ~= nil then
		self.xmlFiles[v27_] = true
		v27_.references = 1
		local v28_ = 0
		while true do
			local v29_ = string.format("connectionHoses.basicHoses.basicHose(%d)", v28_)
			if not v27_:hasProperty(v29_) then
				break
			end
			local v30_ = v27_:getValue(v29_ .. "#filename")
			if v30_ ~= nil then
				v27_.references = v27_.references + 1
				local v31_ = Utils.getFilename(v30_, baseDirectory)
				local v32_ = g_i3DManager:loadSharedI3DFileAsync(v31_, false, false, self.basicHoseI3DFileLoaded, self, {
					["xmlFile"] = v27_,
					["hoseKey"] = v29_
				})
				local v33_ = self.sharedLoadRequestIds
				table.insert(v33_, v32_)
			end
			v28_ = v28_ + 1
		end
		local v34_ = 0
		while true do
			local v35_ = string.format("connectionHoses.connectionHoseTypes.connectionHoseType(%d)", v34_)
			if not v27_:hasProperty(v35_) then
				break
			end
			local v36_ = v27_:getValue(v35_ .. "#name")
			if v36_ ~= nil then
				local v37_
				if self.typeByName[string.upper(v36_)] == nil then
					if customEnvironment ~= nil then
						v36_ = customEnvironment .. "." .. v36_
					end
					v37_ = {
						["name"] = v36_,
						["adapters"] = {},
						["hoses"] = {}
					}
					self.typeByName[string.upper(v36_)] = v37_
				else
					v37_ = self.typeByName[string.upper(v36_)]
				end
				local v38_ = 0
				while true do
					local v39_ = string.format("%s.adapter(%d)", v35_, v38_)
					if not v27_:hasProperty(v39_) then
						break
					end
					local v40_ = v27_:getValue(v39_ .. "#name", "DEFAULT")
					if customEnvironment ~= nil then
						v40_ = customEnvironment .. "." .. v40_
					end
					local v41_ = v27_:getValue(v39_ .. "#filename")
					if v41_ ~= nil then
						v27_.references = v27_.references + 1
						local v42_ = Utils.getFilename(v41_, baseDirectory)
						local v43_ = g_i3DManager:loadSharedI3DFileAsync(v42_, false, false, self.adapterI3DFileLoaded, self, {
							["hoseType"] = v37_,
							["adapterName"] = v40_,
							["xmlFile"] = v27_,
							["adapterKey"] = v39_
						})
						local v44_ = self.sharedLoadRequestIds
						table.insert(v44_, v43_)
					end
					v38_ = v38_ + 1
				end
				local v45_ = 0
				while true do
					local v46_ = string.format("%s.material(%d)", v35_, v45_)
					if not v27_:hasProperty(v46_) then
						break
					end
					local v47_ = v27_:getValue(v46_ .. "#name", "DEFAULT")
					if customEnvironment ~= nil then
						v47_ = customEnvironment .. "." .. v47_
					end
					local v48_ = v27_:getValue(v46_ .. "#filename")
					if v48_ ~= nil then
						v27_.references = v27_.references + 1
						local v49_ = Utils.getFilename(v48_, baseDirectory)
						local v50_ = g_i3DManager:loadSharedI3DFileAsync(v49_, false, false, self.materialI3DFileLoaded, self, {
							["hoseType"] = v37_,
							["hoseName"] = v47_,
							["xmlFile"] = v27_,
							["hoseKey"] = v46_
						})
						local v51_ = self.sharedLoadRequestIds
						table.insert(v51_, v50_)
					end
					v45_ = v45_ + 1
				end
			end
			v34_ = v34_ + 1
		end
		local v52_ = 0
		while true do
			local v53_ = string.format("connectionHoses.sockets.socket(%d)", v52_)
			if not v27_:hasProperty(v53_) then
				break
			end
			local v54_ = v27_:getValue(v53_ .. "#name")
			if customEnvironment ~= nil then
				v54_ = customEnvironment .. "." .. v54_
			end
			local v55_ = v27_:getValue(v53_ .. "#filename")
			if v54_ ~= nil and v55_ ~= nil then
				v27_.references = v27_.references + 1
				local v56_ = Utils.getFilename(v55_, baseDirectory)
				local v57_ = g_i3DManager:loadSharedI3DFileAsync(v56_, false, false, self.socketI3DFileLoaded, self, {
					["name"] = v54_,
					["xmlFile"] = v27_,
					["socketKey"] = v53_
				})
				local v58_ = self.sharedLoadRequestIds
				table.insert(v58_, v57_)
			end
			v52_ = v52_ + 1
		end
		v27_.references = v27_.references - 1
		if v27_.references == 0 then
			self.xmlFiles[v27_] = nil
			v27_:delete()
		end
	end
end

-- Local values: xmlFile, hoseKey, node, entry, length, realLength, diameter
function ConnectionHoseManager:basicHoseI3DFileLoaded(i3dNode, failedReason, args)
	local v62_ = args.xmlFile
	local v63_ = args.hoseKey
	if i3dNode ~= nil and i3dNode ~= 0 then
		local v64_ = v62_:getValue(v63_ .. "#node", nil, i3dNode)
		if v64_ ~= nil then
			unlink(v64_)
			local v65_ = {
				["node"] = v64_,
				["startStraightening"] = v62_:getValue(v63_ .. "#startStraightening", 2),
				["endStraightening"] = v62_:getValue(v63_ .. "#endStraightening", 2),
				["minCenterPointAngle"] = v62_:getValue(v63_ .. "#minCenterPointAngle", 90)
			}
			local v66_ = v62_:getValue(v63_ .. "#length")
			if v66_ == nil then
				printWarning(string.format("Warning: Missing length attribute in \'%s\'", v63_))
			end
			local v67_ = v62_:getValue(v63_ .. "#realLength")
			if v67_ == nil then
				printWarning(string.format("Warning: Missing realLength attribute in \'%s\'", v63_))
			end
			local v68_ = v62_:getValue(v63_ .. "#diameter")
			if v68_ == nil then
				printWarning(string.format("Warning: Missing diameter attribute in \'%s\'", v63_))
			end
			if v66_ ~= nil and (v67_ ~= nil and v68_ ~= nil) then
				v65_.length = v66_
				v65_.realLength = v67_
				v65_.diameter = v68_
				local v69_ = self.basicHoses
				table.insert(v69_, v65_)
			end
		end
		delete(i3dNode)
	end
	v62_.references = v62_.references - 1
	if v62_.references == 0 then
		self.xmlFiles[v62_] = nil
		v62_:delete()
	end
end

-- Local values: hoseType, adapterName, xmlFile, adapterKey, node, hoseReferenceNode, detachedNode, entry
function ConnectionHoseManager:adapterI3DFileLoaded(i3dNode, failedReason, args)
	local v73_ = args.hoseType
	local v74_ = args.adapterName
	local v75_ = args.xmlFile
	local v76_ = args.adapterKey
	if i3dNode ~= nil and i3dNode ~= 0 then
		local v77_ = v75_:getValue(v76_ .. "#node", nil, i3dNode)
		local v78_ = getChildAt(v77_, 0)
		unlink(v77_)
		local v79_ = v75_:getValue(v76_ .. "#detachedNode", nil, i3dNode)
		if v79_ ~= nil then
			unlink(v79_)
		end
		if v78_ == 0 then
			printWarning(string.format("Warning: Missing hose reference node as child from adapter \'%s\' in connection type \'%s\'", v74_, v73_.name))
		else
			v73_.adapters[string.upper(v74_)] = {
				["node"] = v77_,
				["detachedNode"] = v79_,
				["hoseReferenceNode"] = v78_
			}
		end
		delete(i3dNode)
	end
	v75_.references = v75_.references - 1
	if v75_.references == 0 then
		self.xmlFiles[v75_] = nil
		v75_:delete()
	end
end

-- Local values: hoseType, hoseName, xmlFile, hoseKey, materialNode, entry
function ConnectionHoseManager:materialI3DFileLoaded(i3dNode, failedReason, args)
	local v83_ = args.hoseType
	local v84_ = args.hoseName
	local v85_ = args.xmlFile
	local v86_ = args.hoseKey
	if i3dNode ~= nil and i3dNode ~= 0 then
		local v87_ = v85_:getValue(v86_ .. "#materialNode", nil, i3dNode)
		unlink(v87_)
		if v87_ ~= nil then
			local v88_ = {
				["materialNode"] = v87_,
				["uvMinMax"] = v85_:getValue(v86_ .. "#uvMinMax", nil, true),
				["uvLengthScale"] = v85_:getValue(v86_ .. "#uvLengthScale", 1),
				["uvRandomOffset"] = v85_:getValue(v86_ .. "#uvRandomOffset", "0 0", true),
				["materialTemplate"] = v85_:getValue(v86_ .. "#materialTemplateName")
			}
			v83_.hoses[string.upper(v84_)] = v88_
		end
		delete(i3dNode)
	end
	v85_.references = v85_.references - 1
	if v85_.references == 0 then
		self.xmlFiles[v85_] = nil
		v85_:delete()
	end
end

-- Local values: name, xmlFile, socketKey, node, entry, j, capKey, cap
function ConnectionHoseManager:socketI3DFileLoaded(i3dNode, failedReason, args)
	local v92_ = args.name
	local v93_ = args.xmlFile
	local v94_ = args.socketKey
	if i3dNode ~= nil and i3dNode ~= 0 then
		local v95_ = v93_:getValue(v94_ .. "#node", nil, i3dNode)
		if v95_ ~= nil then
			unlink(v95_)
			local v96_ = {
				["node"] = v95_,
				["referenceNode"] = v93_:getValue(v94_ .. "#referenceNode"),
				["caps"] = {}
			}
			local v97_ = 0
			while true do
				local v98_ = string.format(v94_ .. ".cap(%d)", v97_)
				if not v93_:hasProperty(v98_) then
					break
				end
				local v99_ = {
					["node"] = v93_:getValue(v98_ .. "#node")
				}
				if v99_.node ~= nil then
					v99_.openedRotation = v93_:getValue(v98_ .. "#openedRotation", nil, true)
					v99_.closedRotation = v93_:getValue(v98_ .. "#closedRotation", nil, true)
					v99_.openedVisibility = v93_:getValue(v98_ .. "#openedVisibility", true)
					v99_.closedVisibility = v93_:getValue(v98_ .. "#closedVisibility", true)
					local v100_ = v96_.caps
					table.insert(v100_, v99_)
				end
				v97_ = v97_ + 1
			end
			if self.sockets[string.upper(v92_)] == nil then
				self.sockets[string.upper(v92_)] = v96_
			else
				Logging.xmlError(v93_, "Socket \'%s\' already exists", v92_)
			end
		end
		delete(i3dNode)
	end
	v93_.references = v93_.references - 1
	if v93_.references == 0 then
		self.xmlFiles[v93_] = nil
		v93_:delete()
	end
end

-- Local values: customTypeName
function ConnectionHoseManager:getHoseTypeByName(typeName, customEnvironment)
	if typeName == nil then
		return nil
	end
	if customEnvironment ~= nil then
		local v104_ = string.upper(customEnvironment .. "." .. typeName)
		if self.typeByName[v104_] ~= nil then
			return self.typeByName[v104_]
		end
	end
	return self.typeByName[string.upper(typeName)]
end

-- Local values: customTypeName
function ConnectionHoseManager:getHoseAdapterByName(hoseType, adapterName, customEnvironment)
	if hoseType == nil or adapterName == nil then
		return nil
	end
	if customEnvironment ~= nil then
		local v108_ = string.upper(customEnvironment .. "." .. adapterName)
		if hoseType.adapters[v108_] ~= nil then
			return hoseType.adapters[v108_]
		end
	end
	return hoseType.adapters[string.upper(adapterName)]
end

-- Local values: customTypeName
function ConnectionHoseManager:getHoseMaterialByName(hoseType, materialName, customEnvironment)
	if hoseType == nil or materialName == nil then
		return nil
	end
	if customEnvironment ~= nil then
		local v112_ = string.upper(customEnvironment .. "." .. materialName)
		if hoseType.hoses[v112_] ~= nil then
			return hoseType.hoses[v112_]
		end
	end
	return hoseType.hoses[string.upper(materialName)]
end

-- Local values: customTypeName
function ConnectionHoseManager:getSocketByName(socketName, customEnvironment)
	if socketName == nil then
		return nil
	end
	if customEnvironment ~= nil then
		local v116_ = string.upper(customEnvironment .. "." .. socketName)
		if self.sockets[v116_] ~= nil then
			return self.sockets[v116_]
		end
	end
	return self.sockets[string.upper(socketName)]
end

-- Local values: hoseType, adapter, adapterNodeClone, hoseReferenceNodeClone, detachedNodeClone
function ConnectionHoseManager:getClonedAdapterNode(typeName, adapterName, customEnvironment, detached)
	local v122_ = self:getHoseTypeByName(typeName, customEnvironment)
	if v122_ ~= nil then
		local v123_ = self:getHoseAdapterByName(v122_, adapterName, customEnvironment)
		if v123_ ~= nil then
			if not detached then
				local v124_ = clone(v123_.node, true)
				setTranslation(v124_, 0, 0, 0)
				setRotation(v124_, 0, 0, 0)
				return v124_, getChildAt(v124_, 0)
			end
			if v123_.detachedNode ~= nil then
				local v125_ = clone(v123_.detachedNode, true)
				setTranslation(v125_, 0, 0, 0)
				setRotation(v125_, 0, 0, 0)
				return v125_
			end
		end
	end
	return nil
end

-- Local values: hoseType, material, hoseNodeClone, realLength, startStraightening, endStraightening, minCenterPointAngle, closestDiameter, mat, newMat, scale, xOffset, yOffset
function ConnectionHoseManager:getClonedHoseNode(typeName, hoseName, length, diameter, vehicleMaterial, customEnvironment)
	local v133_ = self:getHoseTypeByName(typeName, customEnvironment)
	if v133_ ~= nil then
		local v134_ = self:getHoseMaterialByName(v133_, hoseName, customEnvironment)
		if v134_ ~= nil then
			local v135_, v136_, v137_, v138_, v139_, v140_ = self:getClonedBasicHose(length, diameter)
			if v135_ ~= nil then
				local v141_ = getMaterial(v134_.materialNode, 0)
				setMaterial(v135_, v141_, 0)
				if v134_.materialTemplate ~= nil then
					v134_.materialTemplate:apply(v135_)
				end
				if vehicleMaterial ~= nil then
					local v142_ = setMaterialDiffuseMapFromFile(v141_, "data/shared/detailLibrary/metallic/clear_diffuse.dds", true, true, false)
					setMaterial(v135_, v142_, 0)
					vehicleMaterial:apply(v135_)
				end
				setShaderParameter(v135_, "lengthAndDiameter", v136_, diameter / v140_, nil, nil, false)
				if v134_.uvMinMax ~= nil then
					local v143_ = v134_.uvMinMax[2] - v134_.uvMinMax[1]
					setShaderParameter(v135_, "uvScale", length / v136_ * v134_.uvLengthScale, v143_, nil, nil, false)
					local v144_ = v134_.uvRandomOffset[1]
					local v145_ = v134_.uvRandomOffset[2]
					if v144_ ~= 0 then
						v144_ = math.random() * v144_
					end
					if v145_ ~= 0 then
						v145_ = math.random() * v145_
					end
					setShaderParameter(v135_, "offsetUV", v144_, v134_.uvMinMax[1] + v145_, nil, nil, false)
				end
				return v135_, v137_, v138_, v139_
			end
		end
	end
	return nil, nil, nil, nil
end

-- Local values: minDiameterDiff, closestDiameter, _, hose, diff, foundHoses, _, hose, diff, minLengthDiff, foundHose, _, hose, diff
function ConnectionHoseManager:getClonedBasicHose(length, diameter)
	local v149_ = math.huge
	local v150_ = math.huge
	for _, v151_ in pairs(self.basicHoses) do
		local v152_ = v151_.diameter - diameter
		local v153_ = math.abs(v152_)
		if v153_ < v149_ then
			v150_ = v151_.diameter
			v149_ = v153_
		end
	end
	local v154_ = {}
	for _, v155_ in pairs(self.basicHoses) do
		local v156_ = v155_.diameter - v150_
		if math.abs(v156_) <= 0.0001 then
			table.insert(v154_, v155_)
		end
	end
	local v157_ = math.huge
	local v158_ = nil
	for _, v159_ in pairs(v154_) do
		local v160_ = v159_.length - length
		local v161_ = math.abs(v160_)
		if v161_ < v157_ then
			v158_ = v159_
			v157_ = v161_
		end
	end
	if v158_ == nil then
		return nil
	else
		return clone(v158_.node, true), v158_.realLength, v158_.startStraightening, v158_.endStraightening, v158_.minCenterPointAngle, v150_
	end
end

-- Local values: socket, linkedSocket, _, cap, clonedCap, i, v
function ConnectionHoseManager:linkSocketToNode(socketName, node, customEnvironment, socketMaterial)
	local v167_ = self:getSocketByName(socketName, customEnvironment)
	if v167_ == nil or node == nil then
		return nil
	end
	local v168_ = {
		["node"] = clone(v167_.node, true)
	}
	setTranslation(v168_.node, 0, 0, 0)
	setRotation(v168_.node, 0, 0, 0)
	v168_.referenceNode = I3DUtil.indexToObject(v168_.node, v167_.referenceNode)
	v168_.caps = {}
	for _, v169_ in ipairs(v167_.caps) do
		local v170_ = {}
		for v171_, v172_ in pairs(v169_) do
			v170_[v171_] = v172_
		end
		v170_.node = I3DUtil.indexToObject(v168_.node, v170_.node)
		local v173_ = v168_.caps
		table.insert(v173_, v170_)
	end
	if socketMaterial ~= nil then
		socketMaterial:apply(v168_.node, "connector_color_mat")
	end
	link(node, v168_.node)
	self:closeSocket(v168_)
	return v168_
end

function ConnectionHoseManager:getSocketTarget(socket, defaultTarget)
	if socket == nil or socket.referenceNode == nil then
		return defaultTarget
	else
		return socket.referenceNode
	end
end

-- Local values: _, cap
function ConnectionHoseManager:openSocket(socket)
	if socket ~= nil and #socket.caps > 0 then
		for _, v177_ in ipairs(socket.caps) do
			if v177_.openedRotation ~= nil then
				local v178_ = setRotation
				local v179_ = v177_.node
				local v180_ = v177_.openedRotation
				v178_(v179_, unpack(v180_))
			end
			setVisibility(v177_.node, v177_.openedVisibility)
		end
	end
end

-- Local values: _, cap
function ConnectionHoseManager:closeSocket(socket)
	if socket ~= nil and #socket.caps > 0 then
		for _, v182_ in ipairs(socket.caps) do
			if v182_.openedRotation ~= nil then
				local v183_ = setRotation
				local v184_ = v182_.node
				local v185_ = v182_.closedRotation
				v183_(v184_, unpack(v185_))
			end
			setVisibility(v182_.node, v182_.closedVisibility)
		end
	end
end

function ConnectionHoseManager:registerXMLPaths(schema)
	schema:register(XMLValueType.STRING, "connectionHoses.basicHoses.basicHose(?)#filename", "I3d filename")
	schema:register(XMLValueType.NODE_INDEX, "connectionHoses.basicHoses.basicHose(?)#node", "Path to hose node")
	schema:register(XMLValueType.FLOAT, "connectionHoses.basicHoses.basicHose(?)#startStraightening", "Straightening factor on start side", 2)
	schema:register(XMLValueType.FLOAT, "connectionHoses.basicHoses.basicHose(?)#endStraightening", "Straightening factor on end side", 2)
	schema:register(XMLValueType.ANGLE, "connectionHoses.basicHoses.basicHose(?)#minCenterPointAngle", "Min. bending angle at the center of the hose", 90)
	schema:register(XMLValueType.FLOAT, "connectionHoses.basicHoses.basicHose(?)#length", "Reference length of hose")
	schema:register(XMLValueType.FLOAT, "connectionHoses.basicHoses.basicHose(?)#realLength", "Real length of hose in i3d")
	schema:register(XMLValueType.FLOAT, "connectionHoses.basicHoses.basicHose(?)#diameter", "Diameter of hose")
	schema:register(XMLValueType.STRING, "connectionHoses.connectionHoseTypes.connectionHoseType(?)#name", "Name of type")
	schema:register(XMLValueType.STRING, "connectionHoses.connectionHoseTypes.connectionHoseType(?).adapter(?)#name", "Name of adapter")
	schema:register(XMLValueType.STRING, "connectionHoses.connectionHoseTypes.connectionHoseType(?).adapter(?)#filename", "Path to i3d file")
	schema:register(XMLValueType.NODE_INDEX, "connectionHoses.connectionHoseTypes.connectionHoseType(?).adapter(?)#node", "Adapter node in i3d file")
	schema:register(XMLValueType.NODE_INDEX, "connectionHoses.connectionHoseTypes.connectionHoseType(?).adapter(?)#detachedNode", "Detached adapter node in i3d file")
	schema:register(XMLValueType.STRING, "connectionHoses.connectionHoseTypes.connectionHoseType(?).material(?)#name", "Name of material")
	schema:register(XMLValueType.STRING, "connectionHoses.connectionHoseTypes.connectionHoseType(?).material(?)#filename", "Path to i3d file")
	schema:register(XMLValueType.NODE_INDEX, "connectionHoses.connectionHoseTypes.connectionHoseType(?).material(?)#materialNode", "Material node in i3d file")
	schema:register(XMLValueType.VECTOR_2, "connectionHoses.connectionHoseTypes.connectionHoseType(?).material(?)#uvMinMax", "Min. and max. range of uv\'s in Y")
	schema:register(XMLValueType.FLOAT, "connectionHoses.connectionHoseTypes.connectionHoseType(?).material(?)#uvLengthScale", "Scale factor of the UV in X axis", 1)
	schema:register(XMLValueType.VECTOR_2, "connectionHoses.connectionHoseTypes.connectionHoseType(?).material(?)#uvRandomOffset", "Random offset range on x and y axis", "0 0")
	schema:register(XMLValueType.VEHICLE_MATERIAL, "connectionHoses.connectionHoseTypes.connectionHoseType(?).material(?)#materialTemplateName", "Material template to be applied by default")
	schema:register(XMLValueType.STRING, "connectionHoses.sockets.socket(?)#name", "Socket name")
	schema:register(XMLValueType.STRING, "connectionHoses.sockets.socket(?)#filename", "Path to i3d file")
	schema:register(XMLValueType.NODE_INDEX, "connectionHoses.sockets.socket(?)#node", "Socket node in i3d")
	schema:register(XMLValueType.STRING, "connectionHoses.sockets.socket(?)#referenceNode", "Index of reference node inside socket")
	schema:register(XMLValueType.STRING, "connectionHoses.sockets.socket(?).cap(?)#node", "Index of cap node inside socket")
	schema:register(XMLValueType.VECTOR_ROT, "connectionHoses.sockets.socket(?).cap(?)#openedRotation", "Opened rotation")
	schema:register(XMLValueType.VECTOR_ROT, "connectionHoses.sockets.socket(?).cap(?)#closedRotation", "Closed rotation")
	schema:register(XMLValueType.BOOL, "connectionHoses.sockets.socket(?).cap(?)#openedVisibility", "Opened visibility", true)
	schema:register(XMLValueType.BOOL, "connectionHoses.sockets.socket(?).cap(?)#closedVisibility", "Closed visibility", true)
end
g_connectionHoseManager = ConnectionHoseManager.new()
