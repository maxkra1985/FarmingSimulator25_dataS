BezierTest = {}
function BezierTest.test_constructor()
	Assert.throwsError(BezierCurve.new, "Calling constructor with no arguments threw no error.")
	Assert.throwsError(function()
		BezierCurve.new(nil, 0, 0, 0)
	end, "X 1 was allowed to be invalid")
	Assert.throwsError(function()
		BezierCurve.new(0, nil, 0, 0)
	end, "Y 1 was allowed to be invalid")
	Assert.throwsError(function()
		BezierCurve.new(0, 0, nil, 0)
	end, "X 2 was allowed to be invalid")
	Assert.throwsError(function()
		BezierCurve.new(0, 0, 0, nil)
	end, "Y 2 was allowed to be invalid")
end
function BezierTest.test_setters()
	local v_u_1_ = BezierCurve.new(0.25, 0, 0.75, 1)
	Assert.throwsError(function()
		-- upvalues: (copy) v_u_1_
		v_u_1_:setPositionX1(nil)
	end, "X 1 was allowed to be invalid")
	Assert.throwsError(function()
		-- upvalues: (copy) v_u_1_
		v_u_1_:setPositionY1(nil)
	end, "Y 1 was allowed to be invalid")
	Assert.throwsError(function()
		-- upvalues: (copy) v_u_1_
		v_u_1_:setPositionX2(nil)
	end, "X 2 was allowed to be invalid")
	Assert.throwsError(function()
		-- upvalues: (copy) v_u_1_
		v_u_1_:setPositionY2(nil)
	end, "Y 2 was allowed to be invalid")
end
function BezierTest.test_solvers()
	local v_u_2_ = BezierCurve.new(0.25, 0, 0.75, 1)
	Assert.throwsError(function()
		-- upvalues: (ref) v_u_2_
		v_u_2_:sampleY(nil)
	end, "t was allowed to be invalid")
	Assert.throwsError(function()
		-- upvalues: (ref) v_u_2_
		v_u_2_:sampleX(nil)
	end, "t was allowed to be invalid")
	Assert.throwsError(function()
		-- upvalues: (ref) v_u_2_
		v_u_2_:sampleDerivativeX(nil)
	end, "t was allowed to be invalid")
	Assert.throwsError(function()
		-- upvalues: (ref) v_u_2_
		v_u_2_:solveX(nil)
	end, "t was allowed to be invalid")
	Assert.throwsError(function()
		-- upvalues: (ref) v_u_2_
		v_u_2_:solveX(0.5, {})
	end, "epsilon was allowed to be invalid")
	Assert.throwsError(function()
		-- upvalues: (ref) v_u_2_
		v_u_2_:solve(nil)
	end, "t was allowed to be invalid")
	Assert.throwsError(function()
		-- upvalues: (ref) v_u_2_
		v_u_2_:solve(0.5, {})
	end, "epsilon was allowed to be invalid")
	for v3_ = 0, 100 do
		v_u_2_ = BezierCurve.new(v3_ / 100, 0, 1 - v3_ / 100, 1)
		local v4_ = v_u_2_
		for v5_ = 0, 100 do
			local v6_ = v4_:solve(v5_ / 100)
			Assert.lessThanOrEqualTo(v6_, 1, "Value was greater than 1")
			Assert.greaterThanOrEqualTo(v6_, 0, "Value was less than 0")
		end
	end
end
