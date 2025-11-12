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

local function UpdateTextStringWithValues(textString, value, valueMin, valueMax)
	if( self.LeftText and self.RightText ) then
		self.LeftText:SetText("");
		self.RightText:SetText("");
		self.LeftText:Hide();
		self.RightText:Hide();
	end
	
	-- Max value is valid and updates aren't paused
	if ( ( tonumber(valueMax) ~= valueMax or valueMax > 0 ) and not ( self.pauseUpdates ) ) then
		self:Show();
		
		if ( (self.cvar and GetCVar(self.cvar) == "1" and self.textLockable) or self.forceShow ) then
			textString:Show();
		elseif ( self.lockShow > 0 and (not self.forceHideText) ) then
			textString:Show();
		else
			textString:SetText("");
			textString:Hide();
			return;
		end

		-- Display zero text
		if ( value == 0 and self.zeroText ) then
			textString:SetText(self.zeroText);
			self.isZero = 1;
			textString:Show();
			return;
		end

		self.isZero = nil;

		local valueDisplay = value;
		local valueMaxDisplay = valueMax;

		-- If custom text transform func provided, use that
		if ( self.numericDisplayTransformFunc ) then
			valueDisplay, valueMaxDisplay = self.numericDisplayTransformFunc(value, valueMax);
		-- Otherwise just the usual large number handling
		else
			if ( self.capNumericDisplay ) then
				valueDisplay = AbbreviateLargeNumbers(value);
				valueMaxDisplay = AbbreviateLargeNumbers(valueMax);
			else
				valueDisplay = BreakUpLargeNumbers(value);
				valueMaxDisplay = BreakUpLargeNumbers(valueMax);
			end
		end

		local shouldUsePrefix = self.prefix and (self.alwaysPrefix or not (self.cvar and GetCVar(self.cvar) == "1" and self.textLockable) );

		local displayMode = GetCVar("statusTextDisplay");
		-- Evaluate display mode overrides in priority order
		if ( self.showNumeric ) then
			displayMode = STATUS_TEXT_DISPLAY_MODE.NUMERIC;
		elseif ( self.showPercentage ) then
			displayMode = STATUS_TEXT_DISPLAY_MODE.PERCENT;
		end

		-- If percent-only mode and percentages disabled, fall back on numeric-only
		if ( self.disablePercentages and displayMode == STATUS_TEXT_DISPLAY_MODE.PERCENT ) then
			displayMode = STATUS_TEXT_DISPLAY_MODE.NUMERIC;
		end

		-- Numeric only
		if ( valueMax <= 0 or displayMode == STATUS_TEXT_DISPLAY_MODE.NUMERIC or displayMode == STATUS_TEXT_DISPLAY_MODE.NONE) then
			if ( shouldUsePrefix ) then
				textString:SetText(self.prefix.." "..valueDisplay.." / "..valueMaxDisplay);
			else
				textString:SetText(valueDisplay.." / "..valueMaxDisplay);
			end
		-- Numeric + Percentage
		elseif ( displayMode == STATUS_TEXT_DISPLAY_MODE.BOTH ) then
			if ( self.LeftText and self.RightText ) then
				-- Unless explicitly disabled, only display percentage on left if displaying mana or a non-power value (legacy behavior that should eventually be revisited)
				if ( not self.disablePercentages and (not self.powerToken or self.powerToken == "MANA") ) then
					self.LeftText:SetText(math.ceil((value / valueMax) * 100) .. "%");
					self.LeftText:Show();
				end
				self.RightText:SetText(valueDisplay);
				self.RightText:Show();
				textString:Hide();
			else
				valueDisplay = valueDisplay .. " / " .. valueMaxDisplay;
				if ( not self.disablePercentages ) then
					valueDisplay = "(" .. math.ceil((value / valueMax) * 100) .. "%) " .. valueDisplay;
				end
			end
			textString:SetText(valueDisplay);
		-- Percentage Only
		elseif ( displayMode == STATUS_TEXT_DISPLAY_MODE.PERCENT ) then
			valueDisplay = math.ceil((value / valueMax) * 100) .. "%";
			if ( shouldUsePrefix ) then
				textString:SetText(self.prefix .. " " .. valueDisplay);
			else
				textString:SetText(valueDisplay);
			end
		end
	-- Max value is invalid or updates are paused
	else
		textString:Hide();
		textString:SetText("");
		if ( not self.alwaysShow ) then
			self:Hide();
		else
			self:SetValue(0);
		end
	end
end

-- Define English Unit(K,M) or Korean Unit(만,억,조).
-- 12.0 patch secret value
local function UpdateBarTextFormat(self, _, value, _, maxValue)
	--[[
	-- If you set your preferences to show percentages and numbers together
	if self.RightText and value and maxValue and not self.showPercentage and GetCVar("statusTextDisplay") == "BOTH" then
		if LocalKoKR then    -- Display numbers together in preferences
			local v =
				(value >= 1e9 and format("%.1f 억", value / 1e8)) or 
				(value >= 1e8 and format("%.2f 억", value / 1e8)) or 
				(value >= 1e6 and format("%.0f 만", value / 1e4)) or 
				(value >= 1e5 and format("%.1f 만", value / 1e4)) or 
				value
			if value >= 1e5 then
				self.RightText:SetText(v)
			elseif value >= 1000 then
				self.RightText:SetText(BreakUpLargeNumbers(value)) --- Separate numbers 10,000 and under with commas
			end
		else 
			local v =
				((value >= 1e8 and format("%.0f M", value / 1e6)) or (value >= 1e5 and format("%.0f K", value / 1e3)) or value)
			if value >= 1e5 then
				self.RightText:SetText(v)
			elseif value >= 1000 then
				self.RightText:SetText(BreakUpLargeNumbers(value)) --- Separate numbers 10,000 and under with commas
			end
		end
	end]]
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

-- hooking
hooksecurefunc(PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar, "UpdateTextStringWithValues", UpdateBarTextFormat)
hooksecurefunc(PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar, "UpdateTextStringWithValues", UpdateBarTextFormat)
hooksecurefunc(AlternatePowerBar, "UpdateTextStringWithValues", UpdateBarTextFormat)
hooksecurefunc(FocusFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar, "UpdateTextStringWithValues", UpdateBarTextFormat)
hooksecurefunc(FocusFrame.TargetFrameContent.TargetFrameContentMain.ManaBar, "UpdateTextStringWithValues", UpdateBarTextFormat)
hooksecurefunc(TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar, "UpdateTextStringWithValues", UpdateBarTextFormat)
hooksecurefunc(TargetFrame.TargetFrameContent.TargetFrameContentMain.ManaBar, "UpdateTextStringWithValues", UpdateBarTextFormat)
hooksecurefunc(PetFrameHealthBar,"UpdateTextStringWithValues",UpdateBarTextColorPets)
hooksecurefunc(PetFrameManaBar,"UpdateTextStringWithValues",UpdateBarTextColorPets)

for i = 1, MAX_BOSS_FRAMES do
	local bossTargetFrame = _G["Boss" .. i .. "TargetFrame"]
	hooksecurefunc(bossTargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar, "UpdateTextStringWithValues", UpdateBarTextFormat)
end

-- Remove Hit Indicator of Player Portrait.
PetHitIndicator:SetText(nil)
PetHitIndicator.SetText = function() end

-- Remove Tooltip <Right click for Frame Settings>
--[[
hooksecurefunc("UnitFrame_UpdateTooltip",function(self)
        for i = GameTooltip:NumLines(), 3, -1 do
            local line = _G["GameTooltipTextLeft" .. i]
            local text = line and line:GetText()
            if text and text == UNIT_POPUP_RIGHT_CLICK then
                GameTooltip:SetUnit(self.unit, self.hideStatusOnTooltip)
                break
            end
        end
    end
)]]

-- remove Realm Names 
hooksecurefunc("CompactUnitFrame_UpdateName",function(frame)
        if frame and not frame:IsForbidden() then
            local frame_name = frame:GetName()
            if
                frame_name and
                    (frame_name:match("^PartyMemberFrame%d") or frame_name:match("^CompactRaidFrame%d") or
                        frame_name:match("^CompactRaidGroup%dMember%d") or
                        frame_name:match("^CompactPartyFrameMember%d")) and
                    frame.unit and
                    frame.name
             then
                if UnitIsPlayer(frame.unit) then
                    local unit_name = GetUnitName(frame.unit, true)
                    if unit_name then
                        frame.name:SetText(unit_name:match("[^-]+"))
                    end
                end
            end
        end
    end
)

hooksecurefunc("UnitFrame_Update",function(frame)
        for frame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
            local unit_name = GetUnitName(frame.unit, true)
            if unit_name then
                frame.name:SetText(unit_name:match("[^-]+"))
            end
        end
    end
)

hooksecurefunc("CompactUnitFrame_UpdateName",function(frame)
        local isInInstance, instanceType = IsInInstance()
        if UnitIsPlayer(frame.unit) then
            if not isInInstance or instanceType == "none" and ShouldShowName(frame) then
                if frame.optionTable.colorNameBySelection then
                    frame.name:SetText(GetUnitName(frame.unit))
                end
            end
        end
    end
)
