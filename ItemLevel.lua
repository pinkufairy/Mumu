local f = CreateFrame("Frame")

local pendingInspects = {}
local cachedItemLevels = {}
local cachedMythicScores = {}
local cachedSpecs = {}
local tiers = {
	-- myth
	[1] = { ["score"] = 289, ["color"] = { 1.00, 0.50, 0.00 } },		-- #ff8000
	[2] = { ["score"] = 286, ["color"] = { 0.98, 0.47, 0.19 } },		-- #fb7831
	[3] = { ["score"] = 282, ["color"] = { 0.96, 0.44, 0.29 } },		-- #f6714a
	[4] = { ["score"] = 279, ["color"] = { 0.95, 0.41, 0.38 } },		-- #f16960
	[5] = { ["score"] = 276, ["color"] = { 0.92, 0.38, 0.45 } },		-- #eb6274
	[6] = { ["score"] = 272, ["color"] = { 0.89, 0.35, 0.53 } },		-- #e45a87


	-- hero
	[7] = { ["score"] = 269, ["color"] = { 0.86, 0.33, 0.61 } },		-- #dc539b
	[8] = { ["score"] = 266, ["color"] = { 0.82, 0.29, 0.68 } },		-- #d24bae
	[9] = { ["score"] = 263, ["color"] = { 0.78, 0.27, 0.76 } },		-- #c744c1
	[10] = { ["score"] = 259, ["color"] = { 0.73, 0.24, 0.83 } },		-- #ba3dd4

	-- champion
	[11] = { ["score"] = 256, ["color"] = { 0.66, 0.22, 0.91 } },		-- #a937e7
	[12] = { ["score"] = 253, ["color"] = { 0.59, 0.26, 0.93 } },		-- #9742ec
	[13] = { ["score"] = 250, ["color"] = { 0.51, 0.32, 0.91 } },		-- #8351e8
	[14] = { ["score"] = 246, ["color"] = { 0.43, 0.36, 0.90 } },		-- #6d5de5

	-- Veteran
	[15] = { ["score"] = 243, ["color"] = { 0.32, 0.40, 0.89 } },		-- #5266e2
	[16] = { ["score"] = 240, ["color"] = { 0.15, 0.43, 0.87 } },		-- #276ede
	[17] = { ["score"] = 237, ["color"] = { 0.13, 0.46, 0.84 } },		-- #2275d7
	[18] = { ["score"] = 233, ["color"] = { 0.22, 0.49, 0.81 } },		-- #377dcf

	-- advanture
	[19] = { ["score"] = 230, ["color"] = { 0.27, 0.52, 0.78 } },		-- #4485c7
	[20] = { ["score"] = 227, ["color"] = { 0.30, 0.55, 0.75 } },		-- #4d8dbe
	[21] = { ["score"] = 224, ["color"] = { 0.33, 0.58, 0.71 } },		-- #5495b6
	[22] = { ["score"] = 220, ["color"] = { 0.35, 0.62, 0.68 } },		-- #50a0bd
	[23] = { ["score"] = 214, ["color"] = { 0.26, 0.61, 0.68 } },		-- #419CAC
	[24] = { ["score"] = 200, ["color"] = { 0.20, 0.60, 0.60 } },		-- #32989A

	-- misc
	[25] = { ["score"] = 0, ["color"] = { 0.33, 0.39, 0.45 } },			-- #566573
}

local scoreTiers = {
	[1] = { ["score"] = 3300, ["color"] = { 1.00, 0.50, 0.00 } },		-- #ff8000
	[2] = { ["score"] = 3200, ["color"] = { 0.98, 0.47, 0.19 } },		-- #fb7831
	[3] = { ["score"] = 3100, ["color"] = { 0.96, 0.44, 0.29 } },		-- #f6714a
	[4] = { ["score"] = 3000, ["color"] = { 0.95, 0.41, 0.38 } },		-- #f16960
	[5] = { ["score"] = 2900, ["color"] = { 0.92, 0.38, 0.45 } },		-- #eb6274
	[6] = { ["score"] = 2800, ["color"] = { 0.89, 0.35, 0.53 } },		-- #e45a87
	[7] = { ["score"] = 2700, ["color"] = { 0.86, 0.33, 0.61 } },		-- #dc539b
	[8] = { ["score"] = 2600, ["color"] = { 0.82, 0.29, 0.68 } },		-- #d24bae
	[9] = { ["score"] = 2500, ["color"] = { 0.78, 0.27, 0.76 } },		-- #c744c1
	[10] = { ["score"] = 2400, ["color"] = { 0.73, 0.24, 0.83 } },		-- #ba3dd4
	[11] = { ["score"] = 2300, ["color"] = { 0.66, 0.22, 0.91 } },		-- #a937e7
	[12] = { ["score"] = 2200, ["color"] = { 0.59, 0.26, 0.93 } },		-- #9742ec
	[13] = { ["score"] = 2100, ["color"] = { 0.51, 0.32, 0.91 } },		-- #8351e8
	[14] = { ["score"] = 2000, ["color"] = { 0.43, 0.36, 0.90 } },		-- #6d5de5
	[15] = { ["score"] = 1900, ["color"] = { 0.32, 0.40, 0.89 } },		-- #5266e2
	[16] = { ["score"] = 1800, ["color"] = { 0.15, 0.43, 0.87 } },		-- #276ede
	[17] = { ["score"] = 1700, ["color"] = { 0.13, 0.46, 0.84 } },		-- #2275d7
	[18] = { ["score"] = 1600, ["color"] = { 0.22, 0.49, 0.81 } },		-- #377dcf
	[19] = { ["score"] = 1500, ["color"] = { 0.27, 0.52, 0.78 } },		-- #4485c7
	[20] = { ["score"] = 1400, ["color"] = { 0.30, 0.55, 0.75 } },		-- #4d8dbe
	[21] = { ["score"] = 1300, ["color"] = { 0.33, 0.58, 0.71 } },		-- #5495b6
	[22] = { ["score"] = 1200, ["color"] = { 0.35, 0.62, 0.68 } },		-- #50a0bd
	[23] = { ["score"] = 1100, ["color"] = { 0.26, 0.61, 0.68 } },		-- #419CAC
	[24] = { ["score"] = 1000, ["color"] = { 0.20, 0.60, 0.60 } },		-- #32989A
	[25] = { ["score"] = 0, ["color"] = { 0.33, 0.39, 0.45 } },			-- #566573
}

local function CalculateAverageItemLevel(unit)
	-- Do a fast scan, but it's an integer.
	local a = C_PaperDollInfo.GetInspectItemLevel(unit)

	-- Depending on server conditions, inventory scans are not accurate.
	-- especially for heirloom gear, which does not properly load item levels.
	-- 12.0 patch 

	--[[
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
	if count > 1 then
		ilvl = total / count
		if (ilvl < a + 2) and (ilvl > a - 2) then
			return ilvl
		else
			return a
		end
	else
		return nil
	end
	]]
	return a
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
	return 0.33, 0.39, 0.45
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
	return 0.33, 0.39, 0.45
end

local function GetItemLevelAndInfo(unit, callback)
	local guid

	if canaccessvalue(UnitGUID(unit)) then
		guid = UnitGUID(unit)
	end

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

		for i = tooltip:NumLines(), 1, -1 do
			local line = _G[tooltip:GetName().."TextLeft"..i]

			if line and line:GetText() and line:GetText() == "불러오는 중" or line:GetText() == "평점" or line:GetText() == "\124cFF999999\124r" then
				--print("\124cFFB0BEC5line: \124r"..line:GetText())
				line:SetText(nil)
			end
		end

		if avgItemLevel == "reading" then
			tooltip:AddLine("불러오는 중", 0.33, 0.39, 0.45)
		else
			-- Item Level and Specialization
			local className = UnitClassBase(unit) or "PRIEST"
			local classColor = C_ClassColor.GetClassColor(className)
			local r1, g1, b1 = classColor.r, classColor.g, classColor.b
			local r2, g2, b2 = GetItemLevelColor(avgItemLevel)
			if avgItemLevel then
				tooltip:AddDoubleLine("\124cFF999999\124r"..spec, string.format("%.1f", avgItemLevel), r1, g1, b1, r2, g2, b2)
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
					mythicLabel = mythicScore .. " +" .. bestRun
				end

				local r, g, b = GetScoreColor(mythicScore)
				tooltip:AddDoubleLine("평점", mythicLabel, 0.33, 0.39, 0.45, r, g, b)
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
				if canaccessvalue(UnitGUID(unitType)) then
					if UnitGUID(unitType) == guid then
						unit = unitType
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

C_Timer.NewTicker(1800, ClearCache)
