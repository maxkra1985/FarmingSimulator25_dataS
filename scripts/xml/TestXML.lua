TestXML = {}
function TestXML.init()
	local v1_ = nil
	local v2_ = nil
	local v3_ = nil
	v1_ = XMLFile.load("testXml", "../tools/studio/Farming_Simulator_25_Dev.xml")
	v2_ = 0
	v3_ = {}
	local v4_ = v2_
	local v_u_5_ = v1_
	local v_u_6_ = v3_
	for _ = 0, 200 do
		local v7_ = openIntervalTimer()
		v_u_5_:iterate("scriptBinding.function", function(_, p8_)
			-- upvalues: (ref) v_u_6_, (ref) v_u_5_
			local v9_ = v_u_6_
			local v10_ = v_u_5_
			local v11_ = p8_ .. "#name"
			table.insert(v9_, v10_:getString(v11_))
			v_u_5_:iterate(p8_ .. ".input.param", function(_, p12_)
				-- upvalues: (ref) v_u_6_, (ref) v_u_5_
				local v13_ = v_u_6_
				local v14_ = v_u_5_
				local v15_ = p12_ .. "#type"
				table.insert(v13_, v14_:getString(v15_))
			end)
		end)
		v2_ = v4_ + readIntervalTimerMs(v7_)
		closeIntervalTimer(v7_)
		v4_ = v2_
	end
	log(v4_, "closure", "numOuputs", #v_u_6_)
	v_u_5_:delete()
	v1_ = XMLFile.load("testXml", "../tools/studio/Farming_Simulator_25_Dev.xml")
	v2_ = 0
	v3_ = {}
	local v16_ = v2_
	local v17_ = v3_
	local v18_ = v1_
	for _ = 0, 200 do
		local v19_ = openIntervalTimer()
		for _, v20_ in v18_:iterator("scriptBinding.function") do
			local v21_ = v20_ .. "#name"
			table.insert(v17_, v18_:getString(v21_))
			for _, v22_ in v18_:iterator(v20_ .. ".input.param") do
				local v23_ = v22_ .. "#type"
				table.insert(v17_, v18_:getString(v23_))
			end
		end
		v2_ = v16_ + readIntervalTimerMs(v19_)
		closeIntervalTimer(v19_)
		v16_ = v2_
	end
	log(v16_, "iterator", "numOuputs", #v17_)
	v18_:delete()
	v1_ = XMLFile.load("testXml", "../tools/studio/Farming_Simulator_25_Dev.xml")
	v2_ = 0
	v3_ = {}
	local v24_ = v2_
	local v25_ = v3_
	local v26_ = v1_
	for _ = 0, 200 do
		local v27_ = openIntervalTimer()
		for _, v28_, v29_ in v26_:iteratorChildren("scriptBinding") do
			if v29_ == "function" then
				local v30_ = v28_ .. "#name"
				table.insert(v25_, v26_:getString(v30_))
				for _, v31_, _ in v26_:iteratorChildren(v28_ .. ".input") do
					local v32_ = v31_ .. "#type"
					table.insert(v25_, v26_:getString(v32_))
				end
			end
		end
		v2_ = v24_ + readIntervalTimerMs(v27_)
		closeIntervalTimer(v27_)
		v24_ = v2_
	end
	log(v24_, "iteratorChildren", "numOuputs", #v25_)
	v26_:delete()
end

function TestXML.update(dt) end
function TestXML.draw() end

function TestXML.mouseEvent(posX, posY, isDown, isUp, button) end

function TestXML.keyEvent(unicode, sym, modifier, isDown) end
