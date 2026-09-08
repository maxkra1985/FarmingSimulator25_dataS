-- Local values: InAppPurchaseController_mt
InAppPurchaseController = {}
local InAppPurchaseController_mt = Class(InAppPurchaseController)
InAppPurchaseController.PENDING_DELAY = 1000
function InAppPurchaseController.new()
	-- upvalues: (copy) InAppPurchaseController_mt
	local v2_ = InAppPurchaseController_mt
	local v3_ = setmetatable({}, v2_)
	v3_.isLoaded = false
	v3_.isInitialized = false
	v3_.callbacks = {}
	v3_.pendingTimer = InAppPurchaseController.PENDING_DELAY
	v3_.lastNumOfPendingPurchases = 0
	v3_.ignoreNextPendingPurchaseChange = false
	v3_.pendingProductsToRestore = {}
	v3_.xmlPath = "dataS/inAppProducts.xml"
	return v3_
end

function InAppPurchaseController:load()
	if not self.isLoaded then
		self:loadProductsFromXML()
		if inAppInit ~= nil then
			inAppInit(self.xmlPath)
		end
		self.isLoaded = true
	end
end

-- Local values: xmlFile
function InAppPurchaseController:loadProductsFromXML()
	self.products = {}
	self.productIdToProduct = {}
	local v_u_6_ = XMLFile.load("products", self.xmlPath)
	if v_u_6_ ~= nil then
		v_u_6_:iterate("inAppPurchases.inAppPurchase", function(_, p7_)
			-- upvalues: (copy) v_u_6_, (copy) self
			local v8_ = v_u_6_:getInt(p7_ .. "#productId")
			if v8_ == nil then
				Logging.xmlWarning(v_u_6_, "Failed to load IAP Product. Missing productId. (%s)", p7_)
				return
			else
				local v9_ = v_u_6_:getBool(p7_ .. "#isConsumable", true)
				local v10_ = v_u_6_:getString(p7_ .. ".product#className")
				if v10_ == nil or v10_ == "" then
					Logging.xmlWarning(v_u_6_, "Failed to load IAP Product. Missing product #className (%s)", p7_)
					return
				else
					local v11_ = ClassUtil.getClassObject(v10_)
					if v11_ == nil then
						Logging.xmlWarning(v_u_6_, "Failed to load IAP Product. Unknown class \'%s\'. (%s)", v10_, p7_)
					else
						local v12_ = v11_.new(v8_, v9_)
						if v12_ ~= nil and v12_:loadFromXMLFile(v_u_6_, p7_ .. ".product") then
							local v13_ = self.products
							table.insert(v13_, v12_)
							self.productIdToProduct[v8_] = v12_
						end
					end
				end
			end
		end)
		v_u_6_:delete()
	end
end

function InAppPurchaseController:setMission(mission)
	self.mission = mission
end

function InAppPurchaseController:getIsAvailable()
	if self.isInitialized then
		return true
	end
	if inAppIsLoaded == nil or not inAppIsLoaded() then
		return false
	end
	self.isInitialized = true
	return true
end

function InAppPurchaseController:getProducts()
	return self.products
end

-- Local values: i, product
function InAppPurchaseController:getProductById(id)
	for v20_ = 1, #self.products do
		local v21_ = self.products[v20_]
		if v21_:getId() == id then
			return v21_
		end
	end
	return nil
end

function InAppPurchaseController:purchase(product, callback)
	local v25_
	if product == nil then
		v25_ = false
	else
		v25_ = callback ~= nil
	end
	assert(v25_)
	if self.mission ~= nil then
		self.callbacks[product] = callback
		inAppStartPurchase(product:getId(), "onPurchaseEnd", self)
	end
end

-- Local values: product
function InAppPurchaseController:onPurchaseEnd(errorCode, productId)
	local v_u_29_ = self.productIdToProduct[productId]
	if errorCode == InAppPurchase.ERROR_OK then
		if self.mission ~= nil then
			v_u_29_:onProductBought(function(p30_, _)
				-- upvalues: (copy) productId, (copy) self, (copy) v_u_29_, (copy) errorCode
				if p30_ then
					inAppFinishPurchase(productId)
					self.callbacks[v_u_29_](true, false, errorCode)
					self:onPendingPurchasesChanged(0)
				else
					self.callbacks[v_u_29_](false, true, InAppPurchase.ERROR_FAILED)
					self.ignoreNextPendingPurchaseChange = true
				end
			end)
			return
		end
	else
		self.callbacks[v_u_29_](false, errorCode == InAppPurchase.ERROR_CANCELLED, errorCode)
	end
end

-- Local values: numRecoverablePurchases, productId, i, pendingProductId
function InAppPurchaseController:getHasPendingPurchase(product)
	local v32_ = inAppGetNumPendingPurchases()
	local v33_ = product:getId()
	for v34_ = 0, v32_ - 1 do
		if inAppGetPendingPurchaseProductId(v34_) == v33_ then
			return true
		end
	end
	return false
end

function InAppPurchaseController:getHasAnyPendingPurchases()
	return inAppGetNumPendingPurchases() > 0
end

-- Local values: num
function InAppPurchaseController:checkPendingPurchasesChanged()
	self.pendingTimer = InAppPurchaseController.PENDING_DELAY
	local v36_ = inAppGetNumPendingPurchases()
	if v36_ ~= self.lastNumOfPendingPurchases then
		if self.ignoreNextPendingPurchaseChange then
			self.ignoreNextPendingPurchaseChange = false
		else
			self:onPendingPurchasesChanged(v36_ - self.lastNumOfPendingPurchases)
		end
		self.lastNumOfPendingPurchases = v36_
	end
end

-- Local values: numPendingPurchases, i, productId, product, restoreNextProduct
function InAppPurchaseController:onPendingPurchasesChanged(changeAmount)
	if self.pendingPurchaseCallback ~= nil then
		self.pendingPurchaseCallback()
	end
	if changeAmount > 0 then
		local v39_ = inAppGetNumPendingPurchases()
		if v39_ > 0 then
			self.pendingProductsToRestore = {}
			for v40_ = v39_ - changeAmount, v39_ - 1 do
				local v41_ = self:getProductById((inAppGetPendingPurchaseProductId(v40_)))
				if v41_ ~= nil then
					local v42_ = self.pendingProductsToRestore
					table.insert(v42_, v41_)
				end
			end
			local function v_u_50_()
				-- upvalues: (copy) self, (copy) v_u_50_
				if #self.pendingProductsToRestore > 0 then
					local v_u_43_ = self.pendingProductsToRestore[1]
					local function v48_(_, p44_)
						-- upvalues: (ref) self, (copy) v_u_43_, (ref) v_u_50_
						if p44_ then
							self:tryPerformPendingPurchase(v_u_43_, function(p45_, p46_)
								-- upvalues: (ref) v_u_50_
								local v47_ = g_i18n:getText(p45_ and "ui_iap_purchaseComplete" or "ui_iap_errorFailed")
								if p46_ ~= nil then
									v47_ = v47_ .. "\n" .. p46_
								end
								InfoDialog.show(v47_, function()
									-- upvalues: (ref) v_u_50_
									v_u_50_()
								end)
							end)
						else
							v_u_50_()
						end
					end
					local v49_ = string.format(g_i18n:getText("ui_iap_pendingPurchaseFound"), v_u_43_:getTitle())
					YesNoDialog.show(v48_, self, v49_)
					table.remove(self.pendingProductsToRestore, 1)
				end
			end
			v_u_50_()
		end
	end
end

function InAppPurchaseController:setPendingPurchaseCallback(callback)
	self.pendingPurchaseCallback = callback
end

-- Local values: numRecoverablePurchases, productId, i, pendingProductId
function InAppPurchaseController:tryPerformPendingPurchase(product, callback)
	local v55_
	if product == nil then
		v55_ = false
	else
		v55_ = callback ~= nil
	end
	assert(v55_)
	local v56_ = inAppGetNumPendingPurchases()
	local v57_ = product:getId()
	for v_u_58_ = 0, v56_ - 1 do
		if inAppGetPendingPurchaseProductId(v_u_58_) == v57_ then
			product:onProductBought(function(p59_, p60_)
				-- upvalues: (copy) callback, (copy) v_u_58_
				callback(p59_, p60_)
				if p59_ then
					inAppFinishPendingPurchase(v_u_58_)
				end
			end)
			return true
		end
	end
	return false
end

function InAppPurchaseController:getHasPurchasesToRestore()
	return inAppHasRestorePurchases == nil and true or inAppHasRestorePurchases()
end

function InAppPurchaseController:restorePurchases()
	inAppRestorePurchases("onPurchasesRestored", self)
end

-- Local values: k, v, i, product
function InAppPurchaseController:onPurchasesRestored(errorCode)
	if errorCode == InAppPurchaseResponse.OK then
		InfoDialog.show(g_i18n:getText("ui_iap_purchaseRestoreCompleted"), nil, nil, DialogElement.TYPE_INFO)
	elseif errorCode == InAppPurchaseResponse.PURCHASE_IN_PROGRESS then
		InfoDialog.show(g_i18n:getText("ui_iap_purchaseInProgress"), nil, nil, DialogElement.TYPE_INFO)
	else
		InfoDialog.show(g_i18n:getText("ui_iap_purchaseRestoreFailed"), nil, nil, DialogElement.TYPE_WARNING)
	end
	for v64_, v65_ in pairs(InAppPurchaseResponse) do
		if v65_ == errorCode then
			Logging.devInfo("Restored In-app purchases (%s):", v64_)
		end
	end
	for v66_ = 1, #self.products do
		local v67_ = self.products[v66_]
		Logging.devInfo("Product %d (%s) has been bought: %s", v67_:getId(), v67_:getTitle(), v67_:getHasBeenBought() and "Yes" or "No")
	end
end

function InAppPurchaseController:update(dt)
	if self.isLoaded and self.isInitialized then
		self.pendingTimer = self.pendingTimer - dt
		if self.pendingTimer < 0 then
			self:checkPendingPurchasesChanged()
		end
	end
end
