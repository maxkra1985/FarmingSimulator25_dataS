-- Local values: CharacterLine_mt
CharacterLine = {}
local CharacterLine_mt = Class(CharacterLine)

-- Upvalues: CharacterLine_mt
-- Local values: self, i, shape
function CharacterLine.new(linkNode, fontMaterial, numCharacters, customMt)
	-- upvalues: (copy) CharacterLine_mt
	local v6_ = customMt or CharacterLine_mt
	local v7_ = setmetatable({}, v6_)
	v7_.fontMaterial = fontMaterial
	v7_.rootNode = createTransformGroup("characterLine")
	link(linkNode, v7_.rootNode)
	v7_.characters = {}
	for _ = 1, numCharacters do
		local v8_ = fontMaterial:getClonedShape(v7_.rootNode)
		setShapeCastShadowmap(v8_, false)
		local v9_ = v7_.characters
		table.insert(v9_, v8_)
	end
	v7_.textSize = 1
	v7_.scaleX = 1
	v7_.scaleY = 1
	v7_.textAlignment = RenderText.ALIGN_RIGHT
	v7_.textVerticalAlignment = RenderText.VERTICAL_ALIGN_BOTTOM
	v7_.fontThickness = 1
	v7_.fontThicknessShader = (v7_.fontThickness - 1) / 8 + 1
	v7_.useNormalMap = true
	v7_.textColor = nil
	v7_.hiddenColor = nil
	v7_.textEmissiveScale = 0
	v7_.hiddenAlpha = 0
	v7_:setText("")
	return v7_
end

function CharacterLine:setSizeAndScale(textSize, scaleX, scaleY)
	self.textSize = textSize or self.textSize
	self.scaleX = scaleX or self.scaleX
	self.scaleY = scaleY or self.scaleY
end

function CharacterLine:setTextAlignment(textAlignment)
	self.textAlignment = textAlignment or self.textAlignment
end

function CharacterLine:setTextVerticalAlignment(textVerticalAlignment)
	self.textVerticalAlignment = textVerticalAlignment or self.textVerticalAlignment
end

-- Local values: _, shape
function CharacterLine:setFontThickness(fontThickness)
	self.fontThickness = fontThickness or self.fontThickness
	self.fontThicknessShader = (self.fontThickness - 1) / 8 + 1
	for _, v20_ in ipairs(self.characters) do
		setShaderParameter(v20_, "alphaErosion", 1 - self.fontThicknessShader, 0, 0, 0, false)
	end
end

-- Local values: r, g, b, _, shape
function CharacterLine:setColor(textColor, hiddenColor, textEmissiveScale, hiddenAlpha)
	self.textColor = textColor or self.textColor
	self.hiddenColor = hiddenColor or self.hiddenColor
	self.textEmissiveScale = textEmissiveScale or self.textEmissiveScale
	self.hiddenAlpha = hiddenAlpha or self.hiddenAlpha
	local v26_, v27_, v28_
	if self.textColor == nil then
		v26_ = nil
		v27_ = nil
		v28_ = nil
	else
		v26_ = self.textColor[1]
		v27_ = self.textColor[2]
		v28_ = self.textColor[3]
	end
	for _, v29_ in ipairs(self.characters) do
		self.fontMaterial:setFontCharacterColor(v29_, v26_, v27_, v28_, 1, self.textEmissiveScale)
	end
end

-- Local values: _, shape
function CharacterLine:setDecalLayer(decalLayer)
	for _, v32_ in ipairs(self.characters) do
		setShapeDecalLayer(v32_, decalLayer or 0)
	end
end

-- Local values: _, shape
function CharacterLine:setCastShadowmap(castShadowmap)
	for _, v35_ in ipairs(self.characters) do
		setShapeCastShadowmap(v35_, castShadowmap)
	end
end

-- Local values: _, shape
function CharacterLine:setUseNormalMap(useNormalMap)
	self.useNormalMap = Utils.getNoNil(useNormalMap, self.useNormalMap)
	for _, v38_ in ipairs(self.characters) do
		self.fontMaterial:assignFontMaterialToNode(v38_, self.useNormalMap)
	end
end

function CharacterLine:setCharacterSpacing(characterSpacing)
	self.characterSpacing = characterSpacing
end

-- Local values: realWidth, xPos, height, textLength, i, shape, targetCharacter, characterData, offsetX, offsetY, spacingX, spacingY, realSpacingX, ratio, scaleX, scaleY, charWidth, x, y, z
function CharacterLine:setText(text, updateAlignment)
	local v44_ = utf8Strlen(text)
	local v45_ = 0
	local v46_ = 0
	local v47_ = 0
	for v48_, v49_ in ipairs(self.characters) do
		local v50_ = v48_ > v44_ and " " or utf8Substr(text, v44_ - v48_, 1)
		local v51_ = self.fontMaterial:setFontCharacter(v49_, v50_, self.textColor, self.hiddenColor)
		if updateAlignment == nil or updateAlignment then
			local v52_ = self.fontMaterial.spacingX
			local v53_ = self.fontMaterial.spacingY
			local v54_ = self.fontMaterial.spacingX
			local v55_, v56_
			if v51_ == nil then
				v55_ = 0
				v56_ = 0
			else
				v52_ = v51_.spacingX or v52_
				v53_ = v51_.spacingY or v53_
				v54_ = v51_.realSpacingX or v53_
				v55_ = v51_.offsetX
				v56_ = v51_.offsetY
			end
			local v57_ = (1 - v52_ * 2) / (1 - v53_ * 2)
			local v58_ = self.textSize * v57_ * self.scaleX
			local v59_ = self.textSize * self.scaleY
			setScale(v49_, v58_, v59_, 1)
			local v60_ = v58_ + self.textSize * self.fontMaterial.charToCharSpace * (self.characterSpacing or 1) * (v52_ / v54_)
			setTranslation(v49_, v46_ - v60_ * 0.5 + v60_ * v55_, v59_ * 0.5 + v59_ * v56_, 0)
			v46_ = v46_ - v60_
			v45_ = math.max(v45_, v59_)
			if v50_ ~= " " and v50_ ~= "" then
				v47_ = v46_
			end
		end
	end
	if updateAlignment == nil or updateAlignment then
		local v61_ = 0
		local v62_ = 0
		if self.textAlignment == RenderText.ALIGN_LEFT then
			v61_ = -v47_
		elseif self.textAlignment == RenderText.ALIGN_CENTER then
			v61_ = -v47_ * 0.5
		end
		if self.textVerticalAlignment == RenderText.VERTICAL_ALIGN_MIDDLE then
			v62_ = -v45_ * 0.5
		elseif self.textVerticalAlignment == RenderText.VERTICAL_ALIGN_TOP then
			v62_ = -v45_
		end
		setTranslation(self.rootNode, v61_, v62_, 0)
	end
end
