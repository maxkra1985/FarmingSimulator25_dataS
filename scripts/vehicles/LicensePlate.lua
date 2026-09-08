-- Local values: LicensePlate_mt
LicensePlate = {}
local LicensePlate_mt = Class(LicensePlate)

-- Upvalues: LicensePlate_mt
-- Local values: self
function LicensePlate.new(customMt)
	-- upvalues: (copy) LicensePlate_mt
	local v3_ = customMt or LicensePlate_mt
	local v4_ = setmetatable({}, v3_)
	v4_.variationIndex = 1
	v4_.position = LicensePlateManager.PLATE_POSITION.ANY
	v4_.characters = ""
	v4_.manager = g_licensePlateManager
	return v4_
end

-- Local values: typeStr
function LicensePlate:loadFromXML(node, filename, customEnvironment, xmlFile, key)
	local v11_ = xmlFile:getValue(key .. "#type", "ELONGATED")
	if v11_ ~= nil then
		self.type = LicensePlateManager.PLATE_TYPE[v11_]
		if self.type == nil then
			return false
		end
		self.node = node
		self.filename = filename
		self.width = xmlFile:getValue(key .. "#width", 1)
		self.height = xmlFile:getValue(key .. "#height", 0.3)
		self.fontSize = xmlFile:getValue(key .. ".font#size", 0.1)
		self.fontUseNormalMap = xmlFile:getValue(key .. ".font#useNormalMap", true)
		self.fontScaleX = xmlFile:getValue(key .. ".font#scaleX", 1)
		self.fontScaleY = xmlFile:getValue(key .. ".font#scaleY", 1)
		self.widthOffsetLeft = 0
		self.widthOffsetRight = 0
		self.heightOffsetTop = 0
		self.heightOffsetBot = 0
		self.font = g_licensePlateManager:getFont()
		if self.font == nil then
			Logging.error("LicensePlate: Unable to get font from LicensePlateManager, possibly not initialized/loaded yet")
			printCallstack()
			return false
		end
		self.fontMaxWidthRatio = self.font:getFontMaxWidthRatio()
		self.variations = {}
		xmlFile:iterate(key .. ".variations.variation", function(_, p12_)
			-- upvalues: (copy) xmlFile, (copy) self, (copy) customEnvironment
			local v_u_13_ = {
				["values"] = {}
			}
			local v_u_14_ = 0
			xmlFile:iterate(p12_ .. ".value", function(p15_, p16_)
				-- upvalues: (ref) v_u_14_, (ref) xmlFile, (ref) self, (copy) v_u_13_
				local v17_ = {
					["index"] = p15_,
					["realIndex"] = v_u_14_ + 1,
					["nodePath"] = xmlFile:getValue(p16_ .. "#node")
				}
				v17_.node = I3DUtil.indexToObject(self.node, v17_.nodePath)
				v17_.nextSection = xmlFile:getValue(p16_ .. "#nextSection", false)
				if v17_.nodePath ~= nil and v17_.node ~= nil then
					local v18_, v19_, v20_ = getTranslation(v17_.node)
					v17_.posX = xmlFile:getValue(p16_ .. "#posX", v18_)
					v17_.posY = xmlFile:getValue(p16_ .. "#posY", v19_)
					v17_.posZ = xmlFile:getValue(p16_ .. "#posZ", v20_)
					v17_.character = xmlFile:getValue(p16_ .. "#character")
					v17_.numerical = xmlFile:getValue(p16_ .. "#numerical", false)
					v17_.alphabetical = xmlFile:getValue(p16_ .. "#alphabetical", false)
					v17_.special = xmlFile:getValue(p16_ .. "#special", false)
					local v21_ = xmlFile
					local v22_ = p16_ .. "#isStatic"
					local v23_ = not (v17_.numerical or (v17_.alphabetical or v17_.special))
					if v23_ then
						v23_ = v17_.character == nil
					end
					v17_.isStatic = v21_:getValue(v22_, v23_)
					v17_.locked = xmlFile:getValue(p16_ .. "#locked", v17_.character ~= nil)
					v17_.maxWidthRatio = self.font:getFontMaxWidthRatio(v17_.alphabetical, v17_.numerical, v17_.special)
					local v24_ = xmlFile:getValue(p16_ .. "#position", "ANY")
					local v25_ = LicensePlateManager.PLATE_POSITION[string.upper(v24_)]
					if v25_ == nil then
						Logging.xmlError(xmlFile, "Unknown position \'%s\' in \'%s\'", v24_, p16_)
					end
					v17_.position = v25_ or LicensePlateManager.PLATE_POSITION.ANY
					if not v17_.isStatic then
						v_u_14_ = v_u_14_ + 1
					end
					I3DUtil.setShapeCastShadowmapRec(v17_.node, false)
					local v26_ = v_u_13_.values
					table.insert(v26_, v17_)
				end
			end)
			v_u_13_.materials = {}
			xmlFile:iterate(p12_ .. ".material", function(_, p27_)
				-- upvalues: (ref) xmlFile, (ref) customEnvironment, (copy) v_u_13_
				local v28_ = VehicleMaterial.new()
				if v28_:loadFromXML(xmlFile, p27_, customEnvironment) then
					local v29_ = xmlFile:getValue(p27_ .. "#position", "ANY")
					local v30_ = LicensePlateManager.PLATE_POSITION[string.upper(v29_)]
					if v30_ == nil then
						Logging.xmlError(xmlFile, "Unknown position \'%s\' in \'%s\'", v29_, p27_)
					end
					v28_.licensePlatePosition = v30_ or LicensePlateManager.PLATE_POSITION.ANY
					local v31_ = v_u_13_.materials
					table.insert(v31_, v28_)
				end
			end)
			if #v_u_13_.values > 0 then
				local v32_ = self.variations
				table.insert(v32_, v_u_13_)
			end
		end)
		self.frame = {}
		self.frame.node = xmlFile:getValue(key .. ".frame#node")
		self.frame.widthOffset = xmlFile:getValue(key .. ".frame#widthOffset", 0)
		self.frame.heightOffsetTop = xmlFile:getValue(key .. ".frame#heightOffsetTop", 0)
		self.frame.heightOffsetBot = xmlFile:getValue(key .. ".frame#heightOffsetBot", 0)
		if self.frame.node == nil or I3DUtil.indexToObject(self.node, self.frame.node) == nil then
			self.frame = nil
		end
	end
	return true
end

function LicensePlate:delete()
	delete(self.node)
end

-- Local values: licensePlateClone, i, variation, j, value, frameNode
function LicensePlate:clone(includeFrame)
	local v36_ = LicensePlate.new()
	v36_.node = clone(self.node, false, false, false)
	v36_.type = self.type
	v36_.filename = self.filename
	v36_.width = self.width
	v36_.height = self.height
	v36_.fontSize = self.fontSize
	v36_.fontUseNormalMap = self.fontUseNormalMap
	v36_.fontScaleX = self.fontScaleX
	v36_.fontScaleY = self.fontScaleY
	v36_.rawWidth = self.width
	v36_.rawHeight = self.height
	v36_.widthOffsetLeft = 0
	v36_.widthOffsetRight = 0
	v36_.heightOffsetTop = 0
	v36_.heightOffsetBot = 0
	v36_.font = self.font
	v36_.fontMaxWidthRatio = self.fontMaxWidthRatio
	v36_.variations = table.clone(self.variations, 10)
	for v37_ = 1, #v36_.variations do
		local v38_ = v36_.variations[v37_]
		for v39_ = 1, #v38_.values do
			local v40_ = v38_.values[v39_]
			v40_.node = I3DUtil.indexToObject(v36_.node, v40_.nodePath)
		end
	end
	v36_.frame = table.clone(self.frame, 10)
	if v36_.frame ~= nil then
		local v41_ = includeFrame == true
		local v42_ = I3DUtil.indexToObject(v36_.node, v36_.frame.node)
		if v42_ ~= nil then
			setVisibility(v42_, v41_)
			if v41_ then
				v36_.width = v36_.width + 2 * v36_.frame.widthOffset
				v36_.height = v36_.height + v36_.frame.heightOffsetTop + v36_.frame.heightOffsetBot
				v36_.widthOffsetLeft = v36_.frame.widthOffset
				v36_.widthOffsetRight = v36_.frame.widthOffset
				v36_.heightOffsetTop = v36_.frame.heightOffsetTop
				v36_.heightOffsetBot = v36_.frame.heightOffsetBot
			end
		end
	end
	v36_:setVariation(self.variationIndex, self.position)
	return v36_
end

-- Local values: variation, stringPos, i, value, samePosition, targetChar
function LicensePlate:updateData(variationIndex, position, characters, validate)
	if variationIndex ~= self.variationIndex or position ~= self.position then
		self:setVariation(variationIndex, position)
	end
	self.position = position or self.position
	if validate == true then
		characters = self:validateLicensePlateCharacters(characters)
	end
	self.characters = characters
	local v48_ = self.variations[self.variationIndex]
	if v48_ ~= nil then
		local v49_ = 1
		for v50_ = 1, #v48_.values do
			local v51_ = v48_.values[v50_]
			if v51_.node ~= nil then
				setTranslation(v51_.node, v51_.posX, v51_.posY, v51_.posZ)
				local v52_
				if v51_.position == LicensePlateManager.PLATE_POSITION.ANY or v51_.position == position then
					v52_ = v51_.position ~= LicensePlateManager.PLATE_POSITION.NONE
				else
					v52_ = false
				end
				local v53_ = v51_.character
				if not v51_.locked then
					v53_ = characters:sub(v49_, v49_) or v53_
				end
				if v51_.isStatic or (v53_ == "" or (v53_ == "_" or not v52_)) then
					if v51_.isStatic and v52_ then
						setVisibility(v51_.node, true)
					else
						setVisibility(v51_.node, false)
					end
				else
					v51_.characterLine:setText(v53_)
					setVisibility(v51_.node, true)
				end
				if not v51_.isStatic then
					v49_ = v49_ + 1
				end
			end
		end
	end
end

-- Local values: variation, oldVariation, i, value, j, i, value, i, material
function LicensePlate:setVariation(variationIndex, position)
	local v57_ = self.variations[variationIndex]
	if v57_ ~= nil then
		local v58_ = self.variations[self.variationIndex]
		for v59_ = 1, #v58_.values do
			local v60_ = v58_.values[v59_]
			if not v60_.isStatic then
				for v61_ = 1, getNumOfChildren(v60_.node) do
					delete(getChildAt(v60_.node, v61_ - 1))
				end
			end
		end
		self.variationIndex = variationIndex
		for v62_ = 1, #v57_.values do
			local v63_ = v57_.values[v62_]
			if not v63_.isStatic then
				v63_.characterLine = CharacterLine.new(v63_.node, self.font, 1)
				v63_.characterLine:setSizeAndScale(self.fontSize, self.fontScaleX, self.fontScaleY)
				v63_.characterLine:setTextAlignment(RenderText.ALIGN_CENTER)
				v63_.characterLine:setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
				v63_.characterLine:setUseNormalMap(self.fontUseNormalMap)
			end
		end
		for v64_ = 1, #v57_.materials do
			local v65_ = v57_.materials[v64_]
			if position == nil or (v65_.licensePlatePosition == LicensePlateManager.PLATE_POSITION.ANY or v65_.licensePlatePosition == position) then
				v65_:apply(self.node)
			end
		end
	end
end

function LicensePlate:getFontSize()
	return self.fontSize * self.fontMaxWidthRatio, self.fontSize
end

-- Local values: colors, _, colorData
function LicensePlate:setColorIndex(colorIndex)
	local v69_, _ = self.manager:getAvailableColors()
	local v70_ = v69_[colorIndex]
	if v70_ ~= nil then
		self:setColor(v70_.color[1], v70_.color[2], v70_.color[3])
	end
end

-- Local values: colors, _, colorData
function LicensePlate:getColor(colorIndex)
	local v73_, _ = self.manager:getAvailableColors()
	local v74_ = v73_[colorIndex]
	if v74_ == nil then
		return nil
	else
		return v74_.color
	end
end

-- Local values: material, j, i, value
function LicensePlate:setColor(r, g, b)
	local v79_ = VehicleMaterial.new()
	v79_:setColor(r, g, b)
	v79_:apply(self.node, g_licensePlateManager.materialNamePlate)
	for v80_ = 1, #self.variations do
		for v81_ = 1, #self.variations[v80_].values do
			local v82_ = self.variations[v80_].values[v81_]
			if not v82_.isStatic and v82_.node ~= nil then
				I3DUtil.setShaderParameterRec(v82_.node, g_licensePlateManager.shaderParameterCharacters, r, g, b)
			end
		end
	end
end

-- Local values: characters, firstNumericCharacter, variation, i, value, random, sourceCharacters, index
function LicensePlate:getRandomCharacters(variationIndex)
	local v85_ = {}
	local v86_ = true
	local v87_ = self.variations[variationIndex]
	if v87_ ~= nil then
		for v88_ = 1, #v87_.values do
			local v89_ = v87_.values[v88_]
			if not v89_.isStatic then
				if v89_.character == nil then
					local v90_ = math.random()
					local v91_ = self.font.characters
					if v89_.alphabetical then
						v91_ = self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL]
					elseif v89_.numerical then
						v91_ = self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.NUMERICAL]
					elseif v89_.special then
						v91_ = self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.SPECIAL]
					end
					if v91_ == nil or #v91_ <= 0 then
						table.insert(v85_, "0")
					else
						local v92_ = v90_ * #v91_
						local v93_ = math.floor(v92_)
						local v94_ = math.max(v93_, 1)
						if v89_.numerical and v86_ then
							v94_ = v94_ == 1 and #v91_ > 1 and 2 or v94_
							v86_ = false
						end
						local v95_ = v91_[v94_].value
						table.insert(v85_, v95_)
					end
				else
					local v96_ = v89_.character
					table.insert(v85_, v96_)
				end
			end
		end
	end
	return v85_
end

-- Local values: str, isTbl, length, variation, i, replacement, old, value, sourceCharacters
function LicensePlate:validateLicensePlateCharacters(characters)
	local v99_ = type(characters) == "table"
	local v100_, v101_
	if v99_ then
		v100_ = table.concat(characters, "")
		v101_ = #characters
	else
		v101_ = characters:len()
		v100_ = characters
	end
	local v102_ = self.variations[self.variationIndex]
	local v103_ = filterText(v100_, false, false)
	for v104_ = 1, v101_ do
		local v105_ = v103_:sub(v104_, v104_)
		local v106_
		if v99_ then
			v106_ = characters[v104_]
		else
			v106_ = characters:sub(v104_, v104_)
		end
		if v105_ ~= v106_ then
			local v107_ = v102_.values[v104_]
			if v107_ ~= nil then
				local v108_ = self.font.characters
				if v107_.alphabetical then
					v108_ = self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL]
				elseif v107_.numerical then
					v108_ = self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.NUMERICAL]
				elseif v107_.special then
					v108_ = self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.SPECIAL]
				end
				if v99_ then
					characters[v104_] = v108_[1].value
				else
					characters = v103_:sub(1, v104_ - 1) .. v108_[1].value .. v103_:sub(v104_ + 1)
				end
			end
		end
	end
	return characters
end

-- Local values: variation, value, currentCharacter, sourceCharactersSources, newSource, newIndex, j, source, i, sourceCharacter, nextSource, prevSource
function LicensePlate:changeCharacter(variationIndex, currentCharacters, valueIndex, direction)
	local v114_ = self.variations[variationIndex]
	if v114_ ~= nil then
		local v115_ = v114_.values[valueIndex]
		local v116_ = currentCharacters[v115_.realIndex]
		local v117_ = {}
		if v115_.alphabetical then
			local v118_ = self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL]
			table.insert(v117_, v118_)
		end
		if v115_.numerical then
			local v119_ = self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.NUMERICAL]
			table.insert(v117_, v119_)
		end
		if v115_.special then
			local v120_ = self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.SPECIAL]
			table.insert(v117_, v120_)
		end
		local v121_ = nil
		local v122_ = 1
		for v123_ = 1, #v117_ do
			local v124_ = v117_[v123_]
			for v125_ = 1, #v124_ do
				if v124_[v125_].value == v116_ then
					v122_ = v125_ + direction
					if #v124_ < v122_ then
						v121_ = v117_[v123_ + 1]
						if v121_ == nil then
							v122_ = #v124_
							v121_ = v124_
						else
							v122_ = 1
						end
					elseif v122_ < 1 then
						v121_ = v117_[v123_ - 1]
						if v121_ == nil then
							v121_ = v124_
							v122_ = 1
						else
							v122_ = #v121_
						end
					else
						v121_ = v124_
					end
				end
			end
		end
		if v121_ ~= nil and v121_[v122_] ~= nil then
			currentCharacters[v115_.realIndex] = v121_[v122_].value
		end
	end
	return currentCharacters
end

-- Local values: str, variation, i, value, char
function LicensePlate:getFormattedString()
	if self.characters == "" then
		return nil
	end
	local v127_ = ""
	local v128_ = self.variations[self.variationIndex]
	if v128_ ~= nil then
		for v129_ = 1, #v128_.values do
			local v130_ = v128_.values[v129_]
			if not v130_.isStatic then
				local v131_ = self.characters:sub(v129_, v129_) or ""
				if v131_ ~= "_" then
					if v130_.nextSection then
						v127_ = v127_ .. " " .. v131_
					else
						v127_ = v127_ .. v131_
					end
				end
			end
		end
	end
	return v127_
end

function LicensePlate.registerXMLPaths(schema, baseName)
	schema:register(XMLValueType.STRING, baseName .. "#filename", "License plate i3d filename")
	schema:register(XMLValueType.NODE_INDEX, baseName .. "#node", "License plate node")
	schema:register(XMLValueType.STRING, baseName .. "#type", "License plate type \'SQUARISH\' or \'ELONGATED\'", "ELONGATED")
	schema:register(XMLValueType.FLOAT, baseName .. "#width", "Width of license plate", 1)
	schema:register(XMLValueType.FLOAT, baseName .. "#height", "Height of license plate", 0.2)
	schema:register(XMLValueType.FLOAT, baseName .. ".font#size", "Size of font", 0.1)
	schema:register(XMLValueType.BOOL, baseName .. ".font#useNormalMap", "Use normal map for the characters", true)
	schema:register(XMLValueType.FLOAT, baseName .. ".font#scaleX", "Additional scaling of font X", 1)
	schema:register(XMLValueType.FLOAT, baseName .. ".font#scaleY", "Additional scaling of font Y", 1)
	schema:register(XMLValueType.STRING, baseName .. ".variations.variation(?).value(?)#node", "Value mesh index")
	schema:register(XMLValueType.FLOAT, baseName .. ".variations.variation(?).value(?)#posX", "X translation of value node")
	schema:register(XMLValueType.FLOAT, baseName .. ".variations.variation(?).value(?)#posY", "Y translation of value node")
	schema:register(XMLValueType.FLOAT, baseName .. ".variations.variation(?).value(?)#posZ", "Z translation of value node")
	schema:register(XMLValueType.BOOL, baseName .. ".variations.variation(?).value(?)#nextSection", "Is start character for next section", false)
	schema:register(XMLValueType.STRING, baseName .. ".variations.variation(?).value(?)#character", "Pre defined character of node")
	schema:register(XMLValueType.BOOL, baseName .. ".variations.variation(?).value(?)#numerical", "Node supports numeric characters", false)
	schema:register(XMLValueType.BOOL, baseName .. ".variations.variation(?).value(?)#alphabetical", "Node supports alphabetical characters", false)
	schema:register(XMLValueType.BOOL, baseName .. ".variations.variation(?).value(?)#special", "Node supports special characters", false)
	schema:register(XMLValueType.BOOL, baseName .. ".variations.variation(?).value(?)#isStatic", "Node is only static without applying of characters", "is static if \'numerical\' and \'alphabetical\' are both on false and no fixed character is given")
	schema:register(XMLValueType.BOOL, baseName .. ".variations.variation(?).value(?)#locked", "Character value can not be changed", "locked when character is defined")
	schema:register(XMLValueType.STRING, baseName .. ".variations.variation(?).value(?)#position", "Value will be hidden of position differs from placement position", "ANY")
	VehicleMaterial.registerXMLPaths(schema, baseName .. ".variations.variation(?).material(?)")
	schema:register(XMLValueType.STRING, baseName .. ".variations.variation(?).material(?)#position", "Value will be hidden of position differs from placement position", "ANY")
	schema:register(XMLValueType.STRING, baseName .. ".frame#node", "Frame node that can be toggled")
	schema:register(XMLValueType.FLOAT, baseName .. ".frame#widthOffset", "Width of frame on each side", 0)
	schema:register(XMLValueType.FLOAT, baseName .. ".frame#heightOffsetTop", "Height of frame on top", 0)
	schema:register(XMLValueType.FLOAT, baseName .. ".frame#heightOffsetBot", "Height of frame at bottom", 0)
end
