-- Original Source: Fastitemlevel (BloodDragon2580)
-- https://github.com/BloodDragon2580/FastItemLevel

local f = CreateFrame("Frame")

local pendingInspects = {}
local cachedItemLevels = {}
local cachedMythicScores = {}
local cachedSpecs = {}
local tiers = {
	[1] = { ["score"] = 639, ["color"] = { 1.00, 0.50, 0.00 } },		-- #ff8000  Myth 6
	[2] = { ["score"] = 636, ["color"] = { 0.98, 0.47, 0.19 } },		-- #fb7930  Myth 5
	[3] = { ["score"] = 632, ["color"] = { 0.96, 0.44, 0.31 } },		-- #f56f4f  Myth 4
	[4] = { ["score"] = 629, ["color"] = { 0.93, 0.40, 0.41 } },		-- #ee6669  Myth 3
	[5] = { ["score"] = 626, ["color"] = { 0.90, 0.36, 0.51 } },		-- #e65d81  Myth 2
	[6] = { ["score"] = 623, ["color"] = { 0.87, 0.33, 0.60 } },		-- #dd5399  Myth 1
	[7] = { ["score"] = 619, ["color"] = { 0.82, 0.29, 0.69 } },		-- #d14ab0  Hero 4
	[8] = { ["score"] = 616, ["color"] = { 0.76, 0.26, 0.78 } },		-- #c242c8  Hero 3
	[9] = { ["score"] = 613, ["color"] = { 0.69, 0.23, 0.88 } },		-- #b03ae0  Hero 2
	[10] = { ["score"] = 610, ["color"] = { 0.57, 0.27, 0.92 } },		-- #9246eb  Hero 1
	[11] = { ["score"] = 606, ["color"] = { 0.38, 0.38, 0.89 } },		-- #6062e3  Champion 4
	[12] = { ["score"] = 603, ["color"] = { 0.09, 0.45, 0.85 } },		-- #1773da  Champion 3
	[13] = { ["score"] = 600, ["color"] = { 0.24, 0.50, 0.80 } },		-- #3d80cc  Champion 2
	[14] = { ["score"] = 597, ["color"] = { 0.31, 0.56, 0.74 } },		-- #4e8ebd  Champion 1
	[15] = { ["score"] = 593, ["color"] = { 0.35, 0.61, 0.68 } },		-- #589cae  Veteran 4
	[16] = { ["score"] = 590, ["color"] = { 0.37, 0.67, 0.62 } },		-- #5eaa9f  Veteran 3
	[17] = { ["score"] = 587, ["color"] = { 0.37, 0.73, 0.56 } },		-- #5fb98f  Veteran 2
	[18] = { ["score"] = 584, ["color"] = { 0.37, 0.78, 0.49 } },		-- #5ec77d  Veteran 1
	[19] = { ["score"] = 580, ["color"] = { 0.35, 0.84, 0.42 } },		-- #58d66b  Adventure 4
	[20] = { ["score"] = 577, ["color"] = { 0.31, 0.89, 0.33 } },		-- #4ee455  Adventure 3
	[21] = { ["score"] = 574, ["color"] = { 0.24, 0.95, 0.22 } },		-- #3cf337  Adventure 2
	[22] = { ["score"] = 571, ["color"] = { 0.41, 1.00, 0.30 } },		-- #68ff4c  Adventure 1
	[23] = { ["score"] = 567, ["color"] = { 0.64, 1.00, 0.54 } },		-- #a4ff8a  Explorer 4
	[24] = { ["score"] = 564, ["color"] = { 0.82, 1.00, 0.75 } },		-- #d1ffc0  Explorer 3
	[25] = { ["score"] = 0, ["color"] = { 0.97, 1.00, 0.96 } },		    -- #f8fff5
}

local scoreTiers = {
	[1] = { ["score"] = 3000, ["color"] = { 1.00, 0.50, 0.00 } },		-- #ff8000
	[2] = { ["score"] = 2900, ["color"] = { 0.98, 0.47, 0.19 } },		-- #fb7930
	[3] = { ["score"] = 2800, ["color"] = { 0.96, 0.44, 0.31 } },		-- #f56f4f
	[4] = { ["score"] = 2700, ["color"] = { 0.93, 0.40, 0.41 } },		-- #ee6669
	[5] = { ["score"] = 2600, ["color"] = { 0.90, 0.36, 0.51 } },		-- #e65d81
	[6] = { ["score"] = 2500, ["color"] = { 0.87, 0.33, 0.60 } },		-- #dd5399
	[7] = { ["score"] = 2400, ["color"] = { 0.82, 0.29, 0.69 } },		-- #d14ab0
	[8] = { ["score"] = 2300, ["color"] = { 0.76, 0.26, 0.78 } },		-- #c242c8
	[9] = { ["score"] = 2200, ["color"] = { 0.69, 0.23, 0.88 } },		-- #b03ae0
	[10] = { ["score"] = 2100, ["color"] = { 0.57, 0.27, 0.92 } },		-- #9246eb
	[11] = { ["score"] = 2000, ["color"] = { 0.38, 0.38, 0.89 } },		-- #6062e3
	[12] = { ["score"] = 1900, ["color"] = { 0.09, 0.45, 0.85 } },		-- #1773da
	[13] = { ["score"] = 1800, ["color"] = { 0.24, 0.50, 0.80 } },		-- #3d80cc
	[14] = { ["score"] = 1700, ["color"] = { 0.31, 0.56, 0.74 } },		-- #4e8ebd
	[15] = { ["score"] = 1600, ["color"] = { 0.35, 0.61, 0.68 } },		-- #589cae
	[16] = { ["score"] = 1500, ["color"] = { 0.37, 0.67, 0.62 } },		-- #5eaa9f
	[17] = { ["score"] = 1400, ["color"] = { 0.37, 0.73, 0.56 } },		-- #5fb98f
	[18] = { ["score"] = 1300, ["color"] = { 0.37, 0.78, 0.49 } },		-- #5ec77d
	[19] = { ["score"] = 1200, ["color"] = { 0.35, 0.84, 0.42 } },		-- #58d66b
	[20] = { ["score"] = 1100, ["color"] = { 0.31, 0.89, 0.33 } },		-- #4ee455
	[21] = { ["score"] = 1000, ["color"] = { 0.24, 0.95, 0.22 } },		-- #3cf337
	[22] = { ["score"] = 800, ["color"] = { 0.41, 1.00, 0.30 } },		-- #68ff4c
	[23] = { ["score"] = 600, ["color"] = { 0.64, 1.00, 0.54 } },		-- #a4ff8a
	[24] = { ["score"] = 400, ["color"] = { 0.82, 1.00, 0.75 } },		-- #d1ffc0
	[25] = { ["score"] = 0, ["color"] = { 0.97, 1.00, 0.96 } },		-- #f8fff5
}

local function CalculateAverageItemLevel(unit)
	-- Do a fast scan, but it's an integer.
	local a = C_PaperDollInfo.GetInspectItemLevel(unit)

	-- Depending on server conditions, inventory scans are not accurate.
	-- especially for heirloom gear, which does not properly load item levels.
	local total, count, ilvl = 0, 0, 0
	for i = 1, 17 do
		if i ~= 4 then
			local itemLink = GetInventoryItemLink(unit, i)
			if itemLink then
				local _, _, _, itemLevel = C_Item.GetItemInfo(itemLink)
					if itemLevel and itemLevel > 0 then
					total = total + itemLevel
					count = count + 1
				end
			end
		end
	end
	if count > 0 then
		ilvl = total / count
		if (ilvl < a + 2) and (ilvl > a - 2) then
			--print("C_Item.GetItemInfo: "..ilvl)
			return ilvl
		else
			--print("C_PaperDollInfo: "..a)
			return a
		end
	else
		return nil
	end
end

local function GetTiersData()
	return tiers
end

local function GetScoreTiersData()
	return scoreTiers
end

local function GetItemLevelColor(score)
	local colors = GetTiersData()

	if not score or score == 0 then
		return 1, 1, 1
	end

	for i = 1, #colors do
		local tier = colors[i]
		if score >= tier.score then
			return tier.color[1], tier.color[2], tier.color[3]
		end
	end
	return 0.62, 0.62, 0.62
end

local function GetScoreColor(score)
	local colors = GetScoreTiersData()

	if not score or score == 0 then
		return 1, 1, 1
	end

	for i = 1, #colors do
		local tier = colors[i]
		if score >= tier.score then
			return tier.color[1], tier.color[2], tier.color[3]
		end
	end
	return 0.62, 0.62, 0.62
end

local function GetItemLevelAndInfo(unit, callback)
	local guid = UnitGUID(unit)
	if not guid then
		callback(nil, nil, nil)
		return
	end

	if cachedItemLevels[guid] and cachedMythicScores[guid] and cachedSpecs[guid] then
		callback(cachedItemLevels[guid], cachedMythicScores[guid], cachedSpecs[guid])
		return
	end

	if not CanInspect(unit) then
		callback(nil, nil, nil)
		return
	end

	pendingInspects[guid] = callback
	NotifyInspect(unit)
	callback("reading", "reading", "reading")
end

local function AddInfoToTooltip(tooltip, unit)
	GetItemLevelAndInfo(unit, function(avgItemLevel, mythicScore, spec)
		if not tooltip or not tooltip.AddLine then return end

		-- Remove old lines
		for i = tooltip:NumLines(), 1, -1 do
			local line = _G[tooltip:GetName().."TextLeft"..i]
			if line and line:GetText() and (line:GetText():match("평점") or line:GetText() == "***") then --line:GetText():match(spec) or 
				line:SetText(nil)
			end
		end

		if avgItemLevel == "reading" then
			-- tooltip:AddLine("***", 0.5, 0.5, 0.5)
		else
			-- Item Level and Specialization
			local className = UnitClassBase(unit) or "PRIEST"
			local classColor = C_ClassColor.GetClassColor(className)
			local r1, g1, b1 = classColor.r, classColor.g, classColor.b
			local r2, g2, b2 = GetItemLevelColor(avgItemLevel)
			if avgItemLevel then
				tooltip:AddDoubleLine(spec, string.format("%.1f", avgItemLevel), r1, g1, b1, r2, g2, b2)
			end
			-- Mythic+ Score and Best Run
			if mythicScore and mythicScore > 0 then
				mythicPlus = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit) or {}
				local bestRun = 0
				for _, run in pairs(mythicPlus.runs or {}) do
					if run.finishedSuccess and run.bestRunLevel > bestRun then
						bestRun = run.bestRunLevel
					end
				end
	
				if bestRun > 0 then
					mythicLabel = mythicScore .. " " .. "+" .. bestRun
				end

				local r, g, b = GetScoreColor(mythicScore)
				tooltip:AddDoubleLine("평점", mythicLabel, 0.6, 0.6, 0.6, r, g, b)
			end
		end
		tooltip:Show()
	end)
end

local function HookTooltip()
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
		local _, unit = tooltip:GetUnit()
		if unit and UnitIsPlayer(unit) and UnitExists(unit) then
			AddInfoToTooltip(tooltip, unit)
		end
	end)
end

local function InitializeTooltipHooks()
	HookTooltip()
end

f:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_LOGIN" then
		InitializeTooltipHooks()
	elseif event == "INSPECT_READY" then
		local guid = ...
		if pendingInspects[guid] then
			local unit = nil
			for _, unitType in ipairs({"player", "target", "mouseover", "focus"}) do
				if UnitGUID(unitType) == guid then
					unit = unitType
					break
				end
			end
			if not unit then
				for i = 1, 40 do
					local partyUnit = (i <= 5) and ("party"..i) or ("raid"..i)
					if UnitGUID(partyUnit) == guid then
						unit = partyUnit
						break
					end
				end
			end
			if unit then
				local avgItemLevel = CalculateAverageItemLevel(unit)
				local mythicScore = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit)
				mythicScore = mythicScore and mythicScore.currentSeasonScore or nil
				local specID = GetInspectSpecialization(unit)
				local _, spec = GetSpecializationInfoByID(specID)

				cachedItemLevels[guid] = avgItemLevel
				cachedMythicScores[guid] = mythicScore
				cachedSpecs[guid] = spec

				if pendingInspects[guid] then
					pendingInspects[guid](avgItemLevel, mythicScore, spec)
					pendingInspects[guid] = nil
				end
			end
		end
	end
end)

f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("INSPECT_READY")

local function ClearCache()
	wipe(cachedItemLevels)
	wipe(cachedMythicScores)
	wipe(cachedSpecs)
end

C_Timer.NewTicker(300, ClearCache)
