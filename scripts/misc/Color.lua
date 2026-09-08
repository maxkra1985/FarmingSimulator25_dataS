-- Local values: Color_mt
Color = {}
local Color_mt = Class(Color)

-- Local values: value
function Color_mt.__index(color, key)
	local v4_ = rawget(color, key)
	if v4_ == nil then
		local v5_ = Color[key]
		if v5_ == nil then
			if type(key) == "number" and (key > 0 and key <= 4) then
				if key == 1 then
					return color.r
				elseif key == 2 then
					return color.g
				elseif key == 3 then
					return color.b
				else
					return color.a
				end
			else
				return Color.swizzle(color, key)
			end
		else
			return v5_
		end
	else
		return v4_
	end
end

-- Local values: i, r, g, b, a
function Color_mt.__mul(left, right)
	if type(left) == "table" and type(right) == "table" then
		for v8_ = 1, 3 do
			if left[v8_] == nil or right[v8_] == nil then
				Assert.fail("Cannot multiply between two tables that do not both have indices 1, 2, and 3!")
			end
		end
		local v9_ = left[1] * right[1]
		local v10_ = math.clamp(v9_, 0, 1)
		local v11_ = left[2] * right[2]
		local v12_ = math.clamp(v11_, 0, 1)
		local v13_ = left[3] * right[3]
		local v14_ = math.clamp(v13_, 0, 1)
		local v15_
		if left[4] == nil or right[4] == nil then
			v15_ = left[4] or right[4] or 1
		else
			local v16_ = left[4] * right[4]
			v15_ = math.clamp(v16_, 0, 1)
		end
		return Color.new(v10_, v12_, v14_, v15_)
	end
	if type(left) == "number" then
		local v17_ = Color.new
		local v18_ = right[1] * left
		local v19_ = math.clamp(v18_, 0, 1)
		local v20_ = right[2] * left
		local v21_ = math.clamp(v20_, 0, 1)
		local v22_ = right[3] * left
		local v23_ = math.clamp(v22_, 0, 1)
		local v24_ = (right[4] or 1) * left
		return v17_(v19_, v21_, v23_, (math.clamp(v24_, 0, 1)))
	end
	if type(right) ~= "number" then
		Assert.fail("attempt to perform arithmetic (mul) on %s and %s", type(left), (type(right)))
		return nil
	end
	local v25_ = Color.new
	local v26_ = left[1] * right
	local v27_ = math.clamp(v26_, 0, 1)
	local v28_ = left[2] * right
	local v29_ = math.clamp(v28_, 0, 1)
	local v30_ = left[3] * right
	local v31_ = math.clamp(v30_, 0, 1)
	local v32_ = (left[4] or 1) * right
	return v25_(v27_, v29_, v31_, (math.clamp(v32_, 0, 1)))
end

-- Upvalues: Color_mt
-- Local values: self
function Color.new(r, g, b, a)
	-- upvalues: (copy) Color_mt
	local v37_ = Color_mt
	local v38_ = setmetatable({}, v37_)
	v38_.r = r or 0
	v38_.g = g or 0
	v38_.b = b or 0
	v38_.a = a or 1
	return v38_
end

function Color:copy()
	return Color.new(self.r, self.g, self.b, self.a)
end

function Color:copyTo(color)
	local v42_ = self.r
	local v43_ = self.g
	local v44_ = self.b
	local v45_ = self.a
	color.r = v42_
	color.g = v43_
	color.b = v44_
	color.a = v45_
end

-- Local values: color, vector
function Color.parseFromString(inputString, ignoreAlpha)
	if type(inputString) == "string" then
		if string.startsWith(inputString, "#") then
			return Color.fromHex(inputString)
		else
			local v48_ = Color.fromPackedValue(inputString)
			if v48_ == nil then
				local v49_ = string.split(inputString, " ", tonumber)
				if #v49_ >= 3 then
					if ignoreAlpha then
						return Color.new(v49_[1], v49_[2], v49_[3])
					else
						return Color.new(v49_[1], v49_[2], v49_[3], v49_[4])
					end
				else
					if g_vehicleMaterialManager ~= nil then
						local v50_ = Color.fromVector(g_vehicleMaterialManager:getMaterialTemplateColorByName(inputString), nil, 3)
						if v50_ ~= nil then
							if ignoreAlpha then
								v50_.a = 1
							end
							return v50_
						end
					end
					local v51_ = Color.fromPresetName(inputString)
					if v51_ == nil then
						return nil
					end
					if ignoreAlpha then
						v51_.a = 1
					end
					return v51_
				end
			else
				if ignoreAlpha then
					v48_.a = 1
				end
				return v48_
			end
		end
	else
		return nil
	end
end

function Color.fromPresetName(presetName)
	if type(presetName) == "string" then
		return Color.PRESETS[string.upper(presetName)]
	else
		return nil
	end
end

-- Local values: r, g, b, a
function Color.fromPackedValue(packedValue)
	if type(packedValue) == "string" then
		packedValue = tonumber(packedValue)
	end
	if type(packedValue) ~= "number" then
		return nil
	end
	local v54_ = bit32.band(packedValue, 255) / 255
	local v55_ = bit32.band(packedValue, 65280)
	local v56_ = bit32.rshift(v55_, 8) / 255
	local v57_ = bit32.band(packedValue, 16711680)
	local v58_ = bit32.rshift(v57_, 16) / 255
	local v59_ = bit32.band(packedValue, 4278190080)
	local v60_ = bit32.rshift(v59_, 24) / 255
	return Color.new(v54_, v56_, v58_, v60_)
end

-- Local values: packedValue
function Color:toPackedValue()
	local v62_ = self.r * 255
	local v63_ = math.ceil(v62_)
	local v64_ = self.g * 255
	local v65_ = math.ceil(v64_)
	local v66_ = bit32.lshift(v65_, 8)
	local v67_ = bit32.bor(v63_, v66_)
	local v68_ = self.b * 255
	local v69_ = math.ceil(v68_)
	local v70_ = bit32.lshift(v69_, 16)
	local v71_ = bit32.bor(v67_, v70_)
	local v72_ = self.a * 255
	local v73_ = math.ceil(v72_)
	local v74_ = bit32.lshift(v73_, 24)
	return bit32.bor(v71_, v74_)
end

-- Local values: packedValue
function Color.fromHex(hexString)
	if type(hexString) == "string" then
		if type(hexString) == "string" and string.startsWith(hexString, "#") then
			hexString = string.sub(hexString, 2)
		end
		local v76_ = tonumber(hexString, 16)
		if v76_ == nil then
			return nil
		else
			return Color.fromPackedValue(v76_)
		end
	else
		return nil
	end
end

-- Local values: packedValue
function Color:toHex(includeHash)
	local v79_ = self:toPackedValue()
	return string.format("%s%x", includeHash and "#" or "", v79_)
end

function Color.fromVector(vector, minLength, maxLength)
	if type(vector) ~= "table" or minLength ~= nil and #vector < minLength then
		return nil
	end
	local v83_ = maxLength or #vector
	return Color.new(v83_ >= 1 and (vector[1] or 0) or 0, v83_ >= 2 and (vector[2] or 0) or 0, v83_ >= 3 and (vector[3] or 0) or 0, v83_ >= 4 and vector[4] or 1)
end

function Color:unpack()
	return self.r, self.g, self.b, self.a
end

function Color:unpack3()
	return self.r, self.g, self.b
end

function Color:toVector3()
	return { self.r, self.g, self.b }
end

function Color:toVector4()
	return {
		self.r,
		self.g,
		self.b,
		self.a
	}
end

function Color.fromRGBA(r, g, b, a)
	return Color.new((r or 0) / 255, (g or 0) / 255, (b or 0) / 255, (a or 255) / 255)
end

function Color:unpackRGBA()
	local v93_ = self.r * 255
	local v94_ = math.ceil(v93_)
	local v95_ = self.g * 255
	local v96_ = math.ceil(v95_)
	local v97_ = self.b * 255
	local v98_ = math.ceil(v97_)
	local v99_ = self.a * 255
	return v94_, v96_, v98_, math.ceil(v99_)
end

function Color.fromVectorRGBA(vector, minLength, maxLength)
	if type(vector) ~= "table" or minLength ~= nil and #vector < minLength then
		return nil
	end
	local v103_ = maxLength or #vector
	return Color.fromRGBA(v103_ >= 1 and (vector[1] or 0) or 0, v103_ >= 2 and (vector[2] or 0) or 0, v103_ >= 3 and (vector[3] or 0) or 0, v103_ >= 4 and vector[4] or 255)
end

function Color:toVectorRGB()
	local v105_ = {}
	local v106_ = self.r * 255
	local v107_ = math.ceil(v106_)
	local v108_ = self.g * 255
	local v109_ = math.ceil(v108_)
	local v110_ = self.b * 255
	__set_list(v105_, 1, {v107_, v109_, (math.ceil(v110_))})
	return v105_
end

function Color:toVectorRGBA()
	local v112_ = {}
	local v113_ = self.r * 255
	local v114_ = math.ceil(v113_)
	local v115_ = self.g * 255
	local v116_ = math.ceil(v115_)
	local v117_ = self.b * 255
	local v118_ = math.ceil(v117_)
	local v119_ = self.a * 255
	__set_list(v112_, 1, {v114_, v116_, v118_, (math.ceil(v119_))})
	return v112_
end

function Color.blend(first, second, alpha)
	return Color.new(MathUtil.lerp(first.r, second.r, alpha), MathUtil.lerp(first.g, second.g, alpha), MathUtil.lerp(first.b, second.b, alpha), MathUtil.lerp(first.a, second.a, alpha))
end

-- Local values: swizzleLength, swizzleVector, i, swizzleValue
function Color:swizzle(key)
	if type(key) ~= "string" then
		return nil
	end
	local v125_ = string.len(key)
	if v125_ > 4 or v125_ <= 0 then
		return nil
	end
	local v126_ = {}
	for v127_ = 1, v125_ do
		local v128_ = string.sub(key, v127_, v127_)
		local v129_ = rawget(self, v128_)
		if v129_ == nil then
			return nil
		end
		v126_[v127_] = v129_
	end
	return v126_
end

function Color.writeStreamRGB(streamId, r, g, b)
	streamWriteUIntN(streamId, math.clamp(r, 0, 1) * 1023, 10)
	streamWriteUIntN(streamId, math.clamp(g, 0, 1) * 1023, 10)
	streamWriteUIntN(streamId, math.clamp(b, 0, 1) * 1023, 10)
end

function Color.readStreamRGB(streamId)
	return streamReadUIntN(streamId, 10) / 1023, streamReadUIntN(streamId, 10) / 1023, streamReadUIntN(streamId, 10) / 1023
end

-- Local values: max, min, h, s, l, d, hue_shifted
function Color.rgbToHsl(r, g, b, offset)
	local v139_ = math.max(r, g, b)
	local v140_ = math.min(r, g, b)
	local v141_ = offset or 0
	local v142_ = (v139_ + v140_) / 2
	local v143_, v144_
	if v139_ == v140_ then
		v143_ = 0
		v144_ = 0
	else
		local v145_ = v139_ - v140_
		v144_ = v142_ > 0.5 and v145_ / (2 - v139_ - v140_) or v145_ / (v139_ + v140_)
		local v146_
		if v139_ == r then
			v146_ = (g - b) / v145_ + (g < b and 6 or 0)
		elseif v139_ == g then
			v146_ = (b - r) / v145_ + 2
		else
			v146_ = (r - g) / v145_ + 4
		end
		v143_ = v146_ / 6
	end
	local v147_ = v143_ - v141_
	if v147_ < 0 then
		v147_ = v147_ + 1
	end
	return v147_ * 2 - 1, v144_ * 4, v142_ * 2
end
Color.PRESETS = {
	["TRANSPARENT"] = Color.fromPackedValue(0),
	["ALICEBLUE"] = Color.fromPackedValue(4294965488),
	["ANTIQUEWHITE"] = Color.fromPackedValue(4292340730),
	["AQUA"] = Color.fromPackedValue(4294967040),
	["AQUAMARINE"] = Color.fromPackedValue(4292149119),
	["AZURE"] = Color.fromPackedValue(4294967280),
	["BEIGE"] = Color.fromPackedValue(4292670965),
	["BISQUE"] = Color.fromPackedValue(4291093759),
	["BLACK"] = Color.fromPackedValue(4278190080),
	["BLANCHEDALMOND"] = Color.fromPackedValue(4291685375),
	["BLUE"] = Color.fromPackedValue(4294901760),
	["BLUEVIOLET"] = Color.fromPackedValue(4293012362),
	["BROWN"] = Color.fromPackedValue(4280953509),
	["BURLYWOOD"] = Color.fromPackedValue(4287084766),
	["CADETBLUE"] = Color.fromPackedValue(4288716383),
	["CHARTREUSE"] = Color.fromPackedValue(4278255487),
	["CHOCOLATE"] = Color.fromPackedValue(4280183250),
	["CORAL"] = Color.fromPackedValue(4283465727),
	["CORNFLOWERBLUE"] = Color.fromPackedValue(4293760356),
	["CORNSILK"] = Color.fromPackedValue(4292671743),
	["CRIMSON"] = Color.fromPackedValue(4282127580),
	["CYAN"] = Color.fromPackedValue(4294967040),
	["DARKBLUE"] = Color.fromPackedValue(4287299584),
	["DARKCYAN"] = Color.fromPackedValue(4287335168),
	["DARKGOLDENROD"] = Color.fromPackedValue(4278945464),
	["DARKGRAY"] = Color.fromPackedValue(4289309097),
	["DARKGREEN"] = Color.fromPackedValue(4278215680),
	["DARKKHAKI"] = Color.fromPackedValue(4285249469),
	["DARKMAGENTA"] = Color.fromPackedValue(4287299723),
	["DARKOLIVEGREEN"] = Color.fromPackedValue(4281297749),
	["DARKORANGE"] = Color.fromPackedValue(4278226175),
	["DARKORCHID"] = Color.fromPackedValue(4291572377),
	["DARKRED"] = Color.fromPackedValue(4278190219),
	["DARKSALMON"] = Color.fromPackedValue(4286224105),
	["DARKSEAGREEN"] = Color.fromPackedValue(4287347855),
	["DARKSLATEBLUE"] = Color.fromPackedValue(4287315272),
	["DARKSLATEGRAY"] = Color.fromPackedValue(4283387695),
	["DARKTURQUOISE"] = Color.fromPackedValue(4291939840),
	["DARKVIOLET"] = Color.fromPackedValue(4292018324),
	["DEEPPINK"] = Color.fromPackedValue(4287829247),
	["DEEPSKYBLUE"] = Color.fromPackedValue(4294950656),
	["DIMGRAY"] = Color.fromPackedValue(4285098345),
	["DODGERBLUE"] = Color.fromPackedValue(4294938654),
	["FIREBRICK"] = Color.fromPackedValue(4280427186),
	["FLORALWHITE"] = Color.fromPackedValue(4293982975),
	["FORESTGREEN"] = Color.fromPackedValue(4280453922),
	["FUCHSIA"] = Color.fromPackedValue(4294902015),
	["GAINSBORO"] = Color.fromPackedValue(4292664540),
	["GHOSTWHITE"] = Color.fromPackedValue(4294965496),
	["GOLD"] = Color.fromPackedValue(4278245375),
	["GOLDENROD"] = Color.fromPackedValue(4280329690),
	["GRAY"] = Color.fromPackedValue(4286611584),
	["GREEN"] = Color.fromPackedValue(4278222848),
	["GREENYELLOW"] = Color.fromPackedValue(4281335725),
	["HONEYDEW"] = Color.fromPackedValue(4293984240),
	["HOTPINK"] = Color.fromPackedValue(4290013695),
	["INDIANRED"] = Color.fromPackedValue(4284243149),
	["INDIGO"] = Color.fromPackedValue(4286709835),
	["IVORY"] = Color.fromPackedValue(4293984255),
	["KHAKI"] = Color.fromPackedValue(4287424240),
	["LAVENDER"] = Color.fromPackedValue(4294633190),
	["LAVENDERBLUSH"] = Color.fromPackedValue(4294308095),
	["LAWNGREEN"] = Color.fromPackedValue(4278254716),
	["LEMONCHIFFON"] = Color.fromPackedValue(4291689215),
	["LIGHTBLUE"] = Color.fromPackedValue(4293318829),
	["LIGHTCORAL"] = Color.fromPackedValue(4286611696),
	["LIGHTCYAN"] = Color.fromPackedValue(4294967264),
	["LIGHTGOLDENRODYELLOW"] = Color.fromPackedValue(4292016890),
	["LIGHTGRAY"] = Color.fromPackedValue(4292072403),
	["LIGHTGREEN"] = Color.fromPackedValue(4287688336),
	["LIGHTPINK"] = Color.fromPackedValue(4290885375),
	["LIGHTSALMON"] = Color.fromPackedValue(4286226687),
	["LIGHTSEAGREEN"] = Color.fromPackedValue(4289376800),
	["LIGHTSKYBLUE"] = Color.fromPackedValue(4294626951),
	["LIGHTSLATEGRAY"] = Color.fromPackedValue(4288252023),
	["LIGHTSTEELBLUE"] = Color.fromPackedValue(4292789424),
	["LIGHTYELLOW"] = Color.fromPackedValue(4292935679),
	["LIME"] = Color.fromPackedValue(4278255360),
	["LIMEGREEN"] = Color.fromPackedValue(4281519410),
	["LINEN"] = Color.fromPackedValue(4293325050),
	["MAGENTA"] = Color.fromPackedValue(4294902015),
	["MAROON"] = Color.fromPackedValue(4278190208),
	["MEDIUMAQUAMARINE"] = Color.fromPackedValue(4289383782),
	["MEDIUMBLUE"] = Color.fromPackedValue(4291624960),
	["MEDIUMORCHID"] = Color.fromPackedValue(4292040122),
	["MEDIUMPURPLE"] = Color.fromPackedValue(4292571283),
	["MEDIUMSEAGREEN"] = Color.fromPackedValue(4285641532),
	["MEDIUMSLATEBLUE"] = Color.fromPackedValue(4293814395),
	["MEDIUMSPRINGGREEN"] = Color.fromPackedValue(4288346624),
	["MEDIUMTURQUOISE"] = Color.fromPackedValue(4291613000),
	["MEDIUMVIOLETRED"] = Color.fromPackedValue(4286911943),
	["MIDNIGHTBLUE"] = Color.fromPackedValue(4285536537),
	["MINTCREAM"] = Color.fromPackedValue(4294639605),
	["MISTYROSE"] = Color.fromPackedValue(4292994303),
	["MOCCASIN"] = Color.fromPackedValue(4290110719),
	["NAVAJOWHITE"] = Color.fromPackedValue(4289584895),
	["NAVY"] = Color.fromPackedValue(4286578688),
	["OLDLACE"] = Color.fromPackedValue(4293326333),
	["OLIVE"] = Color.fromPackedValue(4278222976),
	["OLIVEDRAB"] = Color.fromPackedValue(4280520299),
	["ORANGE"] = Color.fromPackedValue(4278232575),
	["ORANGERED"] = Color.fromPackedValue(4278207999),
	["ORCHID"] = Color.fromPackedValue(4292243674),
	["PALEGOLDENROD"] = Color.fromPackedValue(4289390830),
	["PALEGREEN"] = Color.fromPackedValue(4288215960),
	["PALETURQUOISE"] = Color.fromPackedValue(4293848751),
	["PALEVIOLETRED"] = Color.fromPackedValue(4287852763),
	["PAPAYAWHIP"] = Color.fromPackedValue(4292210687),
	["PEACHPUFF"] = Color.fromPackedValue(4290370303),
	["PERU"] = Color.fromPackedValue(4282353101),
	["PINK"] = Color.fromPackedValue(4291543295),
	["PLUM"] = Color.fromPackedValue(4292714717),
	["POWDERBLUE"] = Color.fromPackedValue(4293320880),
	["PURPLE"] = Color.fromPackedValue(4286578816),
	["RED"] = Color.fromPackedValue(4278190335),
	["ROSYBROWN"] = Color.fromPackedValue(4287598524),
	["ROYALBLUE"] = Color.fromPackedValue(4292962625),
	["SADDLEBROWN"] = Color.fromPackedValue(4279453067),
	["SALMON"] = Color.fromPackedValue(4285694202),
	["SANDYBROWN"] = Color.fromPackedValue(4284523764),
	["SEAGREEN"] = Color.fromPackedValue(4283927342),
	["SEASHELL"] = Color.fromPackedValue(4293850623),
	["SIENNA"] = Color.fromPackedValue(4281160352),
	["SILVER"] = Color.fromPackedValue(4290822336),
	["SKYBLUE"] = Color.fromPackedValue(4293643911),
	["SLATEBLUE"] = Color.fromPackedValue(4291648106),
	["SLATEGRAY"] = Color.fromPackedValue(4287660144),
	["SNOW"] = Color.fromPackedValue(4294638335),
	["SPRINGGREEN"] = Color.fromPackedValue(4286578432),
	["STEELBLUE"] = Color.fromPackedValue(4290019910),
	["TAN"] = Color.fromPackedValue(4287411410),
	["TEAL"] = Color.fromPackedValue(4286611456),
	["THISTLE"] = Color.fromPackedValue(4292394968),
	["TOMATO"] = Color.fromPackedValue(4282868735),
	["TURQUOISE"] = Color.fromPackedValue(4291878976),
	["VIOLET"] = Color.fromPackedValue(4293821166),
	["WHEAT"] = Color.fromPackedValue(4289978101),
	["WHITE"] = Color.fromPackedValue(4294967295),
	["WHITESMOKE"] = Color.fromPackedValue(4294309365),
	["YELLOW"] = Color.fromPackedValue(4278255615),
	["YELLOWGREEN"] = Color.fromPackedValue(4281519514)
}
