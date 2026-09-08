-- Local values: FontMaterial_mt
FontMaterial = {}
local FontMaterial_mt = Class(FontMaterial)

-- Upvalues: FontMaterial_mt
-- Local values: self
function FontMaterial.new(customMt)
	-- upvalues: (copy) FontMaterial_mt
	local v3_ = customMt or FontMaterial_mt
	return setmetatable({}, v3_)
end

-- Local values: name, filename, node, noNormalNode, characterShapePath, arguments
function FontMaterial:loadFromXML(xmlFile, key, customEnvironment, baseDirectory, callback)
	local v10_ = xmlFile:getValue(key .. "#name")
	local v11_ = xmlFile:getValue(key .. "#filename")
	local v12_ = xmlFile:getValue(key .. "#node")
	local v13_ = xmlFile:getValue(key .. "#noNormalNode")
	local v14_ = xmlFile:getValue(key .. "#characterShape")
	if v10_ == nil or (v11_ == nil or v12_ == nil) then
		if callback ~= nil then
			callback(false)
		end
	else
		if customEnvironment ~= nil and customEnvironment ~= "" then
			v10_ = customEnvironment .. "." .. v10_
		end
		self.name = v10_
		self.node = v12_
		self.noNormalNode = v13_
		self.characterShapePath = v14_
		local v15_ = Utils.getFilename(v11_, baseDirectory)
		self.callback = callback
		self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v15_, false, false, self.onI3DFileLoaded, self, {
			["xmlFile"] = xmlFile,
			["key"] = key
		})
	end
end

-- Local values: xmlFile, key, materialNode
function FontMaterial:onI3DFileLoaded(i3dNode, failedReason, arguments, loadingId)
	local v_u_19_ = arguments.xmlFile
	local v20_ = arguments.key
	if i3dNode ~= 0 then
		local v21_ = I3DUtil.indexToObject(i3dNode, self.node)
		if v21_ ~= nil then
			self.materialId = getMaterial(v21_, 0)
			self.materialNode = v21_
			if self.noNormalNode ~= nil then
				self.materialNodeNoNormal = I3DUtil.indexToObject(i3dNode, self.noNormalNode)
				self.materialIdNoNormal = getMaterial(self.materialNodeNoNormal, 0)
			end
			if self.characterShapePath ~= nil then
				self.characterShape = I3DUtil.indexToObject(i3dNode, self.characterShapePath)
			end
			unlink(self.materialNodeNoNormal)
			unlink(self.characterShape)
			unlink(v21_)
			self.spacingX = v_u_19_:getValue(v20_ .. ".spacing#x", 0)
			self.spacingY = v_u_19_:getValue(v20_ .. ".spacing#y", 0)
			self.charToCharSpace = v_u_19_:getValue(v20_ .. ".spacing#charToChar", 0.05)
			self.characters = {}
			self.characterToCharacterData = {}
			self.charactersByType = {}
			self.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.NUMERICAL] = {}
			self.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL] = {}
			self.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.SPECIAL] = {}
			v_u_19_:iterate(v20_ .. ".character", function(_, p22_)
				-- upvalues: (copy) v_u_19_, (copy) self
				local v23_ = {
					["uvIndex"] = v_u_19_:getValue(p22_ .. "#uvIndex", 0),
					["value"] = v_u_19_:getValue(p22_ .. "#value")
				}
				local v24_ = v_u_19_:getValue(p22_ .. "#type", "alphabetical")
				v23_.type = MaterialManager.FONT_CHARACTER_TYPE[string.upper(v24_)] or MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL
				local v25_ = v_u_19_:getValue(p22_ .. "#spacingX", self.spacingX)
				v23_.spacingX = math.max(v25_, 0.0001)
				local v26_ = v_u_19_:getValue(p22_ .. "#spacingY", self.spacingY)
				v23_.spacingY = math.max(v26_, 0.0001)
				v23_.offsetX = v_u_19_:getValue(p22_ .. "#offsetX", 0)
				v23_.offsetY = v_u_19_:getValue(p22_ .. "#offsetY", 0)
				local v27_ = v_u_19_:getValue(p22_ .. "#realSpacingX", v23_.spacingX)
				v23_.realSpacingX = math.max(v27_, 0.0001)
				if v23_.value ~= nil then
					self.characterToCharacterData[v23_.value] = v23_
					local v28_ = string.lower(v23_.value)
					local v29_ = string.upper(v23_.value)
					if self.characterToCharacterData[v28_] == nil then
						self.characterToCharacterData[v28_] = v23_
					end
					if self.characterToCharacterData[v29_] == nil then
						self.characterToCharacterData[v29_] = v23_
					end
					local v30_ = self.characters
					table.insert(v30_, v23_)
					local v31_ = self.charactersByType[v23_.type]
					table.insert(v31_, v23_)
				end
			end)
		end
		delete(i3dNode)
	end
	if self.callback ~= nil then
		self.callback(self.materialNode ~= nil)
	end
end

-- Local values: i
function FontMaterial:getCharacterIndexByCharacter(char)
	for v34_ = 1, #self.characters do
		if string.lower(self.characters[v34_].value) == string.lower(char) then
			return v34_
		end
	end
	return 0
end

-- Local values: char
function FontMaterial:getCharacterByCharacterIndex(index)
	local v37_ = self.characters[index]
	if v37_ == nil then
		return nil
	else
		return v37_.value
	end
end

-- Local values: materialId
function FontMaterial:assignFontMaterialToNode(node, hasNormal)
	if node ~= nil then
		local v41_ = self.materialId
		if hasNormal == false then
			v41_ = self.materialIdNoNormal or v41_
		end
		setMaterial(node, v41_, 0)
		setShaderParameter(node, "spacing", self.spacingX, self.spacingY, 0, 0, false)
	end
end

-- Local values: foundCharacter
function FontMaterial:setFontCharacter(node, targetCharacter, color, hiddenColor)
	if node == nil then
		return nil
	end
	if hiddenColor ~= nil then
		if targetCharacter == " " then
			self:setFontCharacterColor(node, hiddenColor[1], hiddenColor[2], hiddenColor[3])
			targetCharacter = "0"
		else
			self:setFontCharacterColor(node, color[1], color[2], color[3])
		end
	end
	local v47_ = self.characterToCharacterData[targetCharacter]
	if v47_ == nil then
		v47_ = self.characterToCharacterData[string.lower(targetCharacter)]
	end
	if v47_ == nil then
		setVisibility(node, false)
		return v47_
	end
	setVisibility(node, true)
	setShaderParameter(node, "index", v47_.uvIndex, 0, 0, 0, false)
	setShaderParameter(node, "spacing", v47_.spacingX or self.spacingX, v47_.spacingY or self.spacingY, 0, 0, false)
	return v47_
end

function FontMaterial:setFontCharacterColor(node, r, g, b, a, emissive)
	if node ~= nil then
		setShaderParameter(node, "colorScale", r, g, b, a, false)
		if emissive ~= nil then
			setShaderParameter(node, "lightControl", emissive, nil, nil, nil, false)
		end
	end
end

-- Local values: maxRatio, i, character, spacingX, spacingY, ratio
function FontMaterial:getFontMaxWidthRatio(alphabetical, numerical, special)
	local v58_ = 0
	for v59_ = 1, #self.characters do
		local v60_ = self.characters[v59_]
		if v60_.type == MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL and alphabetical ~= false or (v60_.type == MaterialManager.FONT_CHARACTER_TYPE.NUMERICAL and numerical ~= false or v60_.type == MaterialManager.FONT_CHARACTER_TYPE.SPECIAL and special ~= false) then
			local v61_ = v60_.spacingX or self.spacingX
			local v62_ = v60_.spacingY or self.spacingY
			local v63_ = (1 - v61_ * 2) / (1 - v62_ * 2)
			v58_ = math.max(v63_, v58_)
		end
	end
	return v58_
end

-- Local values: char
function FontMaterial:getClonedShape(linkNode, hasNormal)
	local v67_ = clone(self.characterShape, false, false, false)
	link(linkNode, v67_)
	self:assignFontMaterialToNode(v67_, hasNormal)
	return v67_
end

function FontMaterial.registerXMLPaths(schema)
	schema:register(XMLValueType.STRING, "fonts.font(?)#name", "Name if font")
	schema:register(XMLValueType.STRING, "fonts.font(?)#filename", "Path to i3d file")
	schema:register(XMLValueType.STRING, "fonts.font(?)#node", "Path to material node")
	schema:register(XMLValueType.STRING, "fonts.font(?)#characterShape", "Path to character mesh")
	schema:register(XMLValueType.STRING, "fonts.font(?)#noNormalNode", "Path to material node without normal map")
	schema:register(XMLValueType.FLOAT, "fonts.font(?).spacing#x", "X Spacing", 0)
	schema:register(XMLValueType.FLOAT, "fonts.font(?).spacing#y", "Y Spacing", 0)
	schema:register(XMLValueType.FLOAT, "fonts.font(?).spacing#charToChar", "Spacing from character to character in percentage", 0.1)
	schema:register(XMLValueType.INT, "fonts.font(?).character(?)#uvIndex", "Index on uv map", 0)
	schema:register(XMLValueType.STRING, "fonts.font(?).character(?)#value", "Character value")
	schema:register(XMLValueType.STRING, "fonts.font(?).character(?)#type", "Character type", "alphabetical")
	schema:register(XMLValueType.FLOAT, "fonts.font(?).character(?)#spacingX", "Custom spacing X")
	schema:register(XMLValueType.FLOAT, "fonts.font(?).character(?)#spacingY", "Custom spacing Y")
	schema:register(XMLValueType.FLOAT, "fonts.font(?).character(?)#offsetX", "Custom X offset for created char lines (percentage)", 0)
	schema:register(XMLValueType.FLOAT, "fonts.font(?).character(?)#offsetY", "Custom Y offset for created char lines (percentage)", 0)
	schema:register(XMLValueType.FLOAT, "fonts.font(?).character(?)#realSpacingX", "Real spacing from border to visual beginning")
end
