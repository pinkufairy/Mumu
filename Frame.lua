-- Cache global variables --
local _G = _G
local pairs = pairs
local ipairs = ipairs
local UnitIsPlayer = UnitIsPlayer
local UnitIsConnected = UnitIsConnected
local UnitIsTapDenied = UnitIsTapDenied
local UnitClass = UnitClass
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitReaction = UnitReaction
local UnitExists = UnitExists
local UnitPowerType = UnitPowerType
local GetCVar = GetCVar
local LocalKoKR = true

--  Hatred		#cc5438
--  Unfriend	#bf4500
--  Neutral	#e6b300
--  Friend		#00991a

-- Define Name Colour
local function GetNameColors(unit)
	local r, g, b
	if not UnitIsPlayer(unit) and not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) or UnitIsTapDenied(unit) then
		r, g, b = 0.5, 0.5, 0.5
	elseif UnitIsPlayer(unit) then
		local _, class = UnitClass(unit)
		local classColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
		if classColor then
			r, g, b = classColor.r, classColor.g, classColor.b
		else
			if UnitIsFriend("player", unit) then
				r, g, b = 0.0, 1.0, 0.0
			else
				r, g, b = 1.0, 0.0, 0.0
			end
		end
	else
		local _, class = UnitClass(unit)
		local factionColor = FACTION_BAR_COLORS[UnitReaction(unit, "player")] or CUSTOM_CLASS_COLORS
		if factionColor then
			r, g, b = factionColor.r, factionColor.g, factionColor.b or UnitSelectionColor(unit)
		else
			if UnitIsFriend("player", unit) then
				r, g, b = 0.0, 1.0, 0.0
			else
				r, g, b = 1.0, 0.0, 0.0
			end
		end
	end
	return r, g, b
end

-- Define Power Colour
local function GetPowerColors(unit)
	local r, g, b
	if not UnitIsPlayer(unit) and not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) or UnitIsTapDenied(unit) then
	   r, g, b = 0.5, 0.5, 0.5
	else
		local powerType, powerToken, altR, altG, altB = UnitPowerType(unit)
		local info = PowerBarColor[powerToken]
		if info then
			r, g, b = info.r, info.g, info.b
		else
			if not altR then
				info = PowerBarColor[powerType] or PowerBarColor["MANA"]
				r, g, b = info.r, info.g, info.b
			else
				r, g, b = altR, altG, altB
			end
		end
		if powerToken == "MANA" then --- hooksecurefunc mana text
			r, g, b = 0.0, 0.55, 1.0
		end
	end
	return r, g, b
end


local function UpdateBarTextColorPets()
	PetFrameHealthBarTextLeft:SetText(nil)
	PetFrameHealthBarTextRight:SetText(nil)
	PetFrameManaBarTextLeft:SetText(nil)
	PetFrameManaBarTextRight:SetText(nil)
end

-- Hooking Bar Colour
local UpdateColor = CreateFrame("Frame")
UpdateColor:RegisterEvent("ADDON_LOADED")			-- /reload
UpdateColor:RegisterEvent("PLAYER_ENTERING_WORLD")	-- entering world / loading scene
UpdateColor:RegisterEvent("UNIT_FACTION")			-- faction (Alliance, Horde, Enemy, Friendly)
--UpdateColor:RegisterEvent("UNIT_FLAGS") 			-- flags (revive, repair)
UpdateColor:RegisterEvent("UNIT_TARGET")			-- Target Unit (target/focus)
UpdateColor:RegisterEvent("UNIT_ENTERED_VEHICLE")
UpdateColor:RegisterEvent("UNIT_EXITED_VEHICLE")
UpdateColor:RegisterEvent("PLAYER_TARGET_CHANGED")	-- Target Unit (target)
UpdateColor:RegisterEvent("PLAYER_FOCUS_CHANGED")	-- Target Unit (focus)
UpdateColor:RegisterEvent("PLAYER_TALENT_UPDATE")
UpdateColor:RegisterEvent("UPDATE_SHAPESHIFT_FORM")	-- Druid
UpdateColor:SetScript("OnEvent",function(_, event)
	if PlayerFrame.state == "vehicle" then
		_G["PlayerName"]:SetTextColor(1.00, 0.82, 0.00)
		PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar:SetStatusBarDesaturated(true)
		PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar:SetStatusBarColor(GetNameColors("vehicle"))
		PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBarText:SetTextColor(GetNameColors("vehicle"))
		PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.LeftText:SetTextColor(GetNameColors("vehicle"))
		PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.RightText:SetTextColor(GetNameColors("vehicle"))
		PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBarText:SetTextColor(GetNameColors("vehicle"))
		PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar.LeftText:SetTextColor(GetPowerColors("vehicle"))
		PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar.RightText:SetTextColor(GetPowerColors("vehicle"))
	else
		_G["PlayerName"]:SetTextColor(GetNameColors("player"))
		PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar:SetStatusBarDesaturated(true)
		PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar:SetStatusBarColor(GetNameColors("player"))
		PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.LeftText:SetTextColor(GetNameColors("player"))
		PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.RightText:SetTextColor(GetNameColors("player"))
		PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBarText:SetTextColor(GetNameColors("player"))
		PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar.LeftText:SetTextColor(GetPowerColors("player"))
		PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar.RightText:SetTextColor(GetPowerColors("player"))
		PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar.ManaBarText:SetTextColor(GetPowerColors("player"))
		AlternatePowerBar.LeftText:SetTextColor(0.00, 0.50, 1.00)
		AlternatePowerBar.RightText:SetTextColor(0.00, 0.50, 1.00)
		AlternatePowerBar.TextString:SetTextColor(0.00, 0.50, 1.00)
	end

	if UnitExists("target") then
		TargetFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor:Hide()
		TargetFrame.TargetFrameContent.TargetFrameContentMain.Name:SetTextColor(GetNameColors("target"))
		TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar:SetStatusBarDesaturated(true)
		TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar:SetStatusBarColor(GetNameColors("target"))
		TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.LeftText:SetTextColor(GetNameColors("target"))
		TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.RightText:SetTextColor(GetNameColors("target"))
		TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBarText:SetTextColor(GetNameColors("target"))
		TargetFrame.TargetFrameContent.TargetFrameContentMain.ManaBar.LeftText:SetTextColor(GetPowerColors("target"))
		TargetFrame.TargetFrameContent.TargetFrameContentMain.ManaBar.RightText:SetTextColor(GetPowerColors("target"))
		TargetFrame.TargetFrameContent.TargetFrameContentMain.ManaBar.ManaBarText:SetTextColor(GetPowerColors("target"))

		if not UnitIsPlayer("target") and not UnitIsConnected("target") or (UnitIsDeadOrGhost("target")) or UnitIsTapDenied("target") then
			TargetFrame.TargetFrameContent.TargetFrameContentMain.ManaBar:SetStatusBarDesaturated(true)
			TargetFrame.TargetFrameContent.TargetFrameContentMain.ManaBar:SetStatusBarColor(GetPowerColors("target"))
		end

		if UnitExists("targettarget") then
			TargetFrameToT.Name:SetTextColor(GetNameColors("targettarget"))
			TargetFrameToT.HealthBar:SetStatusBarDesaturated(true)
			TargetFrameToT.HealthBar:SetStatusBarColor(GetNameColors("targettarget"))
		end
	end

	if UnitExists("Focus") then
		FocusFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor:Hide()
		FocusFrame.TargetFrameContent.TargetFrameContentMain.Name:SetTextColor(GetNameColors("focus"))
		FocusFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar:SetStatusBarDesaturated(true)
		FocusFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar:SetStatusBarColor(GetNameColors("focus"))
		FocusFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.LeftText:SetTextColor(GetNameColors("focus"))
		FocusFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.RightText:SetTextColor(GetNameColors("focus"))
		FocusFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBarText:SetTextColor(GetNameColors("focus"))
		FocusFrame.TargetFrameContent.TargetFrameContentMain.ManaBar.LeftText:SetTextColor(GetPowerColors("focus"))
		FocusFrame.TargetFrameContent.TargetFrameContentMain.ManaBar.RightText:SetTextColor(GetPowerColors("focus"))
		FocusFrame.TargetFrameContent.TargetFrameContentMain.ManaBar.ManaBarText:SetTextColor(GetPowerColors("focus"))

		if not UnitIsPlayer("focus") and not UnitIsConnected("focus") or (UnitIsDeadOrGhost("focus")) or UnitIsTapDenied("focus") then
			FocusFrame.TargetFrameContent.TargetFrameContentMain.ManaBar:SetStatusBarDesaturated(true)
			FocusFrame.TargetFrameContent.TargetFrameContentMain.ManaBar:SetStatusBarColor(GetPowerColors("focus"))
		end

		if UnitExists("focustarget") then
			FocusFrameToT.Name:SetTextColor(GetNameColors("focustarget"))
			FocusFrameToT.HealthBar:SetStatusBarDesaturated(true)
			FocusFrameToT.HealthBar:SetStatusBarColor(GetNameColors("focustarget"))
		end
	end
   
	for i = 1, MAX_BOSS_FRAMES do
		local bossTargetFrame = _G["Boss" .. i .. "TargetFrame"]
		if UnitExists("Boss" .. i) then
			bossTargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar:SetStatusBarDesaturated(true)
			bossTargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar:SetStatusBarColor(GetNameColors("Boss" .. i))
			bossTargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.LeftText:SetTextColor(GetNameColors("Boss" .. i))
			bossTargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.RightText:SetTextColor(GetNameColors("Boss" .. i))
			bossTargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBarText:SetTextColor(GetNameColors("Boss" .. i))
			bossTargetFrame.TargetFrameContent.TargetFrameContentMain.ManaBar.LeftText:SetTextColor(GetPowerColors("Boss" .. i))
			bossTargetFrame.TargetFrameContent.TargetFrameContentMain.ManaBar.RightText:SetTextColor(GetPowerColors("Boss" .. i))
			bossTargetFrame.TargetFrameContent.TargetFrameContentMain.ManaBar.ManaBarText:SetTextColor(GetPowerColors("Boss" .. i))
			bossTargetFrame.TargetFrameContent.TargetFrameContentMain.Name:SetTextColor(GetNameColors("Boss" .. i))
			bossTargetFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor:Hide()
		end
	end
end)

-- Remove Hit Indicator of Player Portrait.
PetHitIndicator:SetText(nil)
PetHitIndicator.SetText = function() end

local function UpdateBarTextFormat(self, _, value, _, maxValue)
	-- If you set your preferences to show percentages and numbers together
	if self.RightText and value and maxValue and not self.showPercentage and GetCVar("statusTextDisplay") == "BOTH" then

		--[[	
			Name = "AbbreviateLargeNumbers",
			Type = "Function",
			SecretArguments = "AllowedWhenTainted",
			Arguments =
			{
				{ Name = "number", Type = "number", Nilable = false },
				{ Name = "options", Type = "NumberAbbrevOptions", Nilable = true },
			},
			Returns =
			{
				{ Name = "result", Type = "string", Nilable = false },
			},
		
			Name = "NumberAbbrevOptions",
			Type = "Structure",
			Fields =
			{
				{ Name = "breakpointData", Type = "table", InnerType = "NumberAbbrevData", Nilable = true, Documentation = { "Order these from largest to smallest." } },
				{ Name = "locale", Type = "cstring", Nilable = true, Documentation = { "Locale controls whether standard asian abbreviation data will be used along with a small change in behavior for large number abbreviation when fractionDivisor is greater than zero." } },
				{ Name = "config", Type = "AbbreviateConfig", Nilable = true, Documentation = { "Provides a cached config object for optimal performance when calling abbreviation functions multiple times with the same options." } },
			},
		]]
		AbbreviateLargeNumbers(value)
	end
end

hooksecurefunc(PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar, "UpdateTextStringWithValues", UpdateBarTextFormat)
hooksecurefunc(PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar, "UpdateTextStringWithValues", UpdateBarTextFormat)
hooksecurefunc(AlternatePowerBar, "UpdateTextStringWithValues", UpdateBarTextFormat)
hooksecurefunc(FocusFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar, "UpdateTextStringWithValues", UpdateBarTextFormat)
hooksecurefunc(FocusFrame.TargetFrameContent.TargetFrameContentMain.ManaBar, "UpdateTextStringWithValues", UpdateBarTextFormat)
hooksecurefunc(TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar, "UpdateTextStringWithValues", UpdateBarTextFormat)
hooksecurefunc(TargetFrame.TargetFrameContent.TargetFrameContentMain.ManaBar, "UpdateTextStringWithValues", UpdateBarTextFormat)
hooksecurefunc(PetFrameHealthBar,"UpdateTextStringWithValues",UpdateBarTextColorPets)
hooksecurefunc(PetFrameManaBar,"UpdateTextStringWithValues",UpdateBarTextColorPets)