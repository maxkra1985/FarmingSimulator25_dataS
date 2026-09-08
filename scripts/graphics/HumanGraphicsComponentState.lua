-- Local values: HumanGraphicsComponentState_mt
HumanGraphicsComponentState = {}
local HumanGraphicsComponentState_mt = Class(HumanGraphicsComponentState)

-- Upvalues: HumanGraphicsComponentState_mt
-- Local values: self
function HumanGraphicsComponentState.new(customMt)
	-- upvalues: (copy) HumanGraphicsComponentState_mt
	local v3_ = customMt or HumanGraphicsComponentState_mt
	local v4_ = setmetatable({}, v3_)
	v4_:setDefault()
	return v4_
end

function HumanGraphicsComponentState:setDefault()
	self.absSpeed = 0
	self.relativeVelocityX = 0
	self.relativeVelocityY = 0
	self.relativeVelocityZ = 0
	self.rotationVelocity = 0
	self.movementDirX = 0
	self.movementDirZ = 1
	self.distanceToGround = 0
	self.isCloseToGround = true
	self.isIdling = true
	self.isWalking = false
	self.isRunning = false
	self.isCrouching = false
	self.isGrounded = true
	self.isInWater = false
	self.isSwimming = false
	self.isFirstPerson = false
	self.isNPC = false
	self.isHoldingChainsaw = false
	self.isCutting = false
	self.isVerticalCut = false
	self.isStrafeWalkMode = false
end

-- Local values: renderValue
function HumanGraphicsComponentState:drawDebug(posX, posY, textSize)
	local function v13_(p10_)
		-- upvalues: (copy) self, (copy) posX, (ref) posY, (copy) textSize
		local v11_ = self[p10_]
		local v12_
		if type(v11_) == "boolean" then
			v12_ = tostring(v11_)
		else
			v12_ = string.format("%.4f", v11_)
		end
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(posX, posY, textSize, p10_ .. " : ")
		setTextAlignment(RenderText.ALIGN_LEFT)
		renderText(posX, posY, textSize, v12_)
		posY = posY - textSize - 2 * g_pixelSizeY
	end
	v13_("absSpeed")
	v13_("movementDirX")
	v13_("movementDirZ")
	v13_("relativeVelocityX")
	v13_("relativeVelocityY")
	v13_("relativeVelocityZ")
	v13_("rotationVelocity")
	v13_("distanceToGround")
	v13_("isCloseToGround")
	v13_("isIdling")
	v13_("isWalking")
	v13_("isRunning")
	v13_("isCrouching")
	v13_("isGrounded")
	v13_("isInWater")
	v13_("isSwimming")
	v13_("isStrafeWalkMode")
	v13_("isNPC")
	v13_("isFirstPerson")
	v13_("isHoldingChainsaw")
	v13_("isCutting")
	v13_("isVerticalCut")
end
