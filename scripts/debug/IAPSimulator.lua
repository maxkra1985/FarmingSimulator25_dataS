IAPSimulator = {}
IAPSimulator.IS_LOADED = false
IAPSimulator.CURRENT_PURCHASE = nil
IAPSimulator.PRODUCTS = {}
IAPSimulator.PENDING_PURCHASES = {}
function IAPSimulator.init()
	local v_u_1_ = keyEvent
	function keyEvent(p2_, p3_, p4_, p5_)
		-- upvalues: (copy) v_u_1_
		if p5_ then
			if p3_ == Input.KEY_1 then
				Logging.devInfo("IAPSimulator: Finishing IAP with FAILED...")
				IAPSimulator.handleNextPurchase(InAppPurchase.ERROR_FAILED)
			elseif p3_ == Input.KEY_2 then
				Logging.devInfo("IAPSimulator: Finishing IAP with CANCELLED...")
				IAPSimulator.handleNextPurchase(InAppPurchase.ERROR_CANCELLED)
			elseif p3_ == Input.KEY_3 then
				Logging.devInfo("IAPSimulator: Finishing IAP with IN PROGRESS...")
				IAPSimulator.handleNextPurchase(InAppPurchase.ERROR_PURCHASE_IN_PROGRESS)
			elseif p3_ == Input.KEY_4 then
				Logging.devInfo("IAPSimulator: Finishing IAP with OK...")
				IAPSimulator.handleNextPurchase(InAppPurchase.ERROR_OK)
			elseif p3_ == Input.KEY_5 then
				Logging.devInfo("IAPSimulator: Finishing IAP with NETWORK_UNAVAILABLE...")
				IAPSimulator.handleNextPurchase(InAppPurchase.ERROR_NETWORK_UNAVAILABLE)
			elseif p3_ == Input.KEY_6 then
				Logging.devInfo("IAPSimulator: Adding pending IAP...")
				IAPSimulator.addPendingPurchase()
			end
		end
		v_u_1_(p2_, p3_, p4_, p5_)
	end
	function inAppInit(p6_)
		local v7_ = loadXMLFile("IAPProducts", p6_)
		if v7_ ~= 0 then
			local v8_ = 0
			while true do
				local v9_ = string.format("inAppPurchases.inAppPurchase(%d)", v8_)
				if not hasXMLProperty(v7_, v9_) then
					break
				end
				local v10_ = getXMLInt(v7_, v9_ .. "#productId")
				if v10_ ~= nil then
					local v11_ = {
						["productId"] = v10_,
						["coins"] = getXMLInt(v7_, v9_ .. "#coins"),
						["imageFilename"] = getXMLString(v7_, v9_ .. "#imageFilename")
					}
					IAPSimulator.PRODUCTS[v10_] = v11_
				end
				v8_ = v8_ + 1
			end
			delete(v7_)
		end
		IAPSimulator.IS_LOADED = true
	end
	function inAppIsLoaded()
		return IAPSimulator.IS_LOADED
	end
	function inAppGetProductPrice(p12_)
		if IAPSimulator.PRODUCTS[p12_] == nil then
			return nil
		else
			return "$ " .. p12_ .. ".00"
		end
	end
	function inAppGetProductDescription(p13_)
		if IAPSimulator.PRODUCTS[p13_] == nil then
			return nil
		else
			return "Product description " .. p13_
		end
	end
	function inAppStartPurchase(p14_, p15_, p16_)
		if IAPSimulator.CURRENT_PURCHASE == nil then
			IAPSimulator.CURRENT_PURCHASE = {
				["productId"] = p14_,
				["target"] = p16_,
				["callbackName"] = p15_
			}
		else
			p16_[p15_](p16_, InAppPurchase.ERROR_PURCHASE_IN_PROGRESS, p14_)
		end
	end
	function inAppFinishPurchase(_)
		IAPSimulator.CURRENT_PURCHASE = nil
	end
	function inAppGetNumPendingPurchases()
		return #IAPSimulator.PENDING_PURCHASES
	end
	function inAppGetPendingPurchaseProductId(p17_)
		return IAPSimulator.PENDING_PURCHASES[p17_ + 1].productId
	end
	function inAppFinishPendingPurchase(p18_)
		table.remove(IAPSimulator.PENDING_PURCHASES, p18_ + 1)
	end
	printWarning("\n\n  ##################   Warning: IAP Simulator active!   ##################\n\n")
end

-- Local values: purchase, target, callbackName, productId
function IAPSimulator.handleNextPurchase(err)
	local v20_ = IAPSimulator.CURRENT_PURCHASE
	if v20_ == nil then
		Logging.devInfo("IAPSimulator: No purchase active!")
	else
		local v21_ = v20_.target
		local v22_ = v20_.callbackName
		local v23_ = v20_.productId
		IAPSimulator.CURRENT_PURCHASE = nil
		v21_[v22_](v21_, err, v23_)
	end
end
function IAPSimulator.addPendingPurchase()
	local v24_ = {
		["productId"] = math.random(1, #IAPSimulator.PRODUCTS) - 1
	}
	local v25_ = IAPSimulator.PENDING_PURCHASES
	table.insert(v25_, v24_)
end
