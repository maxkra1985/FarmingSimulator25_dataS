Assert = {}
Assert.doErrorOnFail = false
Assert.doCallstackOnFail = true
function Assert.assert(p1_, p2_, p3_, ...)
	if p1_ then
		return
	else
		local v4_ = p3_ or ""
		if Assert.doErrorOnFail then
			error(string.format("Assertion failed! (%s) - " .. tostring(v4_), p2_, ...), 3)
		else
			Logging.error("Assertion failed! (%s) - " .. tostring(v4_), p2_, ...)
			if Assert.doCallstackOnFail then
				printCallstack()
			end
		end
	end
end
function Assert.areEqual(p5_, p6_, p7_, ...)
	Assert.assert(p6_ == p5_, string.format("expected: %s, actual: %s", tostring(p6_), (tostring(p5_))), p7_, ...)
end
function Assert.areNotEqual(p8_, p9_, p10_, ...)
	Assert.assert(p9_ ~= p8_, string.format("expected: %s, actual: %s", tostring(p9_), (tostring(p8_))), p10_, ...)
end
function Assert.areRoughlyEqual(p11_, p12_, p13_, p14_, ...)
	local v15_ = p13_ or 0.001
	local v16_ = string.format("%%.%df", MathUtil.getIndexOfFirstNonZeroFractionDigit(v15_) + 1)
	local v17_ = string.format("expected: %s, actual: %s, difference: %s, allowed difference: %s", v16_, v16_, v16_, v16_)
	local v18_ = Assert.assert
	local v19_ = p11_ - p12_
	local v20_ = math.abs(v19_) <= v15_
	local v21_ = string.format
	local v22_ = tostring(p12_)
	local v23_ = tostring(p11_)
	local v24_ = p11_ - p12_
	v18_(v20_, v21_(v17_, v22_, v23_, math.abs(v24_), v15_), p14_, ...)
end
function Assert.isBetween(p25_, p26_, p27_, p28_, p29_, p30_, ...)
	local v31_ = p28_ == nil and true or p28_
	local v32_ = p29_ == nil and true or p29_
	if v31_ then
		Assert.greaterThanOrEqualTo(p25_, p26_, p30_, ...)
	else
		Assert.greaterThan(p25_, p26_, p30_, ...)
	end
	if v32_ then
		Assert.lessThanOrEqualTo(p25_, p27_, p30_, ...)
	else
		Assert.lessThan(p25_, p27_, p30_, ...)
	end
end
function Assert.greaterThan(p33_, p34_, p35_, ...)
	Assert.assert(p34_ < p33_, string.format("lower limit: %s, actual: %s", tostring(p34_), (tostring(p33_))), p35_, ...)
end
function Assert.greaterThanOrEqualTo(p36_, p37_, p38_, ...)
	Assert.assert(p37_ <= p36_, string.format("lower limit: %s, actual: %s", tostring(p37_), (tostring(p36_))), p38_, ...)
end
function Assert.lessThan(p39_, p40_, p41_, ...)
	Assert.assert(p39_ < p40_, string.format("upper limit: %s, actual: %s", tostring(p40_), (tostring(p39_))), p41_, ...)
end
function Assert.lessThanOrEqualTo(p42_, p43_, p44_, ...)
	Assert.assert(p42_ <= p43_, string.format("upper limit: %s, actual: %s", tostring(p43_), (tostring(p42_))), p44_, ...)
end
function Assert.isClass(p45_, p46_, p47_, ...)
	Assert.isType(p46_, "table", "Tried to assert a non-table value as the expected class", ...)
	Assert.isType(p45_, "table", p47_, ...)
	Assert.isNotNil(p45_.isa, p47_, ...)
	Assert.assert(p45_:isa(p46_), "table is not of the given class", p47_, ...)
end
function Assert.isNilOrClass(p48_, p49_, p50_, ...)
	if p48_ ~= nil then
		Assert.isClass(p48_, p49_, p50_, ...)
	end
end
function Assert.isType(p51_, p52_, p53_, ...)
	Assert.assert(type(p51_) == p52_, string.format("expected: %s, actual: %s", p52_, p51_ and type(p51_) or "nil"), p53_, ...)
end
function Assert.isNilOrType(p54_, p55_, p56_, ...)
	Assert.assert(p54_ == nil and true or type(p54_) == p55_, string.format("or nil expected: %s, actual: %s", p55_, p54_ and type(p54_) or "nil"), p56_, ...)
end
function Assert.isNil(p57_, p58_, ...)
	Assert.assert(p57_ == nil, "value was not nil", p58_, ...)
end
function Assert.isNotNil(p59_, p60_, ...)
	Assert.assert(p59_ ~= nil, "value was nil", p60_, ...)
end
function Assert.isStringNotNilOrEmpty(p61_, p62_, ...)
	Assert.assert(p61_ == nil and true or type(p61_) == "string", string.format("object %s was not nil or a string", (tostring(p61_))), p62_, ...)
	Assert.assert(not string.isNilOrWhitespace(p61_), string.format("string %q was nil or whitespace", (tostring(p61_))), p62_, ...)
end
function Assert.isInteger(p63_, p64_, ...)
	local v65_ = Assert.assert
	local v66_
	if type(p63_) == "number" then
		v66_ = p63_ == math.floor(p63_)
	else
		v66_ = false
	end
	v65_(v66_, string.format("value %s is not an integer", (tostring(p63_))), p64_, ...)
end
function Assert.entityExists(p67_, p68_, ...)
	Assert.isNotNil(p67_, p68_, ...)
	Assert.isType(p67_, "number", ...)
	Assert.greaterThan(p67_, 0, p68_, ...)
	Assert.isTrue(entityExists(p67_), p68_, ...)
end
function Assert.isTrue(p69_, p70_, ...)
	Assert.assert(p69_ == true, "value was not true", p70_, ...)
end
function Assert.isFalse(p71_, p72_, ...)
	Assert.assert(p71_ == false, "value was not false", p72_, ...)
end
function Assert.throwsError(p73_, p74_, ...)
	local v75_ = pcall(p73_)
	Assert.assert(not v75_, "function threw no error", p74_, ...)
end
function Assert.hasKey(p76_, p77_, p78_, ...)
	Assert.isType(p76_, "table", p78_)
	Assert.isNotNil(p77_, p78_)
	Assert.assert(p76_[p77_] ~= nil, string.format("table was missing element with key %s", (tostring(p77_))), p78_, ...)
end
function Assert.hasNoKey(p79_, p80_, p81_, ...)
	Assert.isType(p79_, "table", p81_)
	Assert.isNotNil(p80_, p81_)
	Assert.assert(p79_[p80_] == nil, string.format("table has element with key %s", (tostring(p80_))), p81_, ...)
end
function Assert.fail(p82_, ...)
	Assert.assert(false, "force failed", p82_, ...)
end
