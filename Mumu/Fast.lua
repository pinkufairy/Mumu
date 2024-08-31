local addonName, addonTable = ...
local FastItemLevel = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")

local printdebug = function() end  -- Debug pring On/Off

local defaults = {
    global = {
        cacheSize = 2500,
        shiftKeyRequired = false,
        inspectDelay = 0.025
    }
}

local _G = _G
local pairs = pairs
local time = time
local tostring = tostring
local strsub = strsub
local UnitGUID = UnitGUID
local UnitIsPlayer = UnitIsPlayer
local UnitClass = UnitClass
local GetInspectSpecialization = GetInspectSpecialization
local GetSpecializationInfoByID = GetSpecializationInfoByID
local C_PaperDollInfo = C_PaperDollInfo
local GameTooltip_SetTooltipWaitingForData = GameTooltip_SetTooltipWaitingForData
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local GetNumGroupMembers = GetNumGroupMembers

local function GetUnitIDFromGUID(guid)
	local _, _, _, _, _, name = GetPlayerInfoByGUID(guid)
	if UnitExists(name) then -- unit is in our group and can use its name as a unit ID
		return name, name
	elseif UnitGUID("mouseover") == guid then -- unit is under our cursor
		return "mouseover", name
	elseif UnitGUID("target") == guid then -- unit is our target
		return "target", name
	elseif GetCVar("nameplateShowFriends") == "1" then -- friendly nameplates are visible
		for i = 1, 30 do
			local unitID = "nameplate" .. i
			local nameplateGUID = UnitGUID(unitID)
			if nameplateGUID then
				if nameplateGUID == guid then
					return unitID, name
				end
			else
				break
			end
		end
	else -- scan every group member's target (this is probably overkill)
		local numMembers = GetNumGroupMembers()
		if numMembers > 0 then
			local unitPrefix = IsInRaid() and "raid" or "party"
			if unitPrefix == "party" then
				numMembers = numMembers - 1
			end
			for i = 1, numMembers do
				local unitID = unitPrefix .. i .. "-target"
				local targetGUID = UnitGUID(unitID)
				if targetGUID == guid then
					return unitID, name
				end
			end
		end
	end
	-- no convenient unit ID is available, we tried
	return nil, name
end

local tiers = {
	[1] = { ["score"] = 630, ["color"] = { 1.00, 0.50, 0.00 } },		-- |cffff80003550+|r
	[2] = { ["score"] = 625, ["color"] = { 0.96, 0.43, 0.33 } },		-- |cfff46e543295+|r
	[3] = { ["score"] = 620, ["color"] = { 0.89, 0.35, 0.55 } },		-- |cffe3598b3055+|r
	[4] = { ["score"] = 615, ["color"] = { 0.78, 0.27, 0.75 } },		-- |cffc845bf2815+|r
	[5] = { ["score"] = 610, ["color"] = { 0.64, 0.21, 0.93 } },		-- |cffa335ee2600+|r
	[6] = { ["score"] = 605, ["color"] = { 0.58, 0.27, 0.92 } },		-- |cff9544eb2505+|r
	[7] = { ["score"] = 600, ["color"] = { 0.51, 0.32, 0.91 } },		-- |cff8252e82410+|r
	[8] = { ["score"] = 595, ["color"] = { 0.42, 0.36, 0.90 } },		-- |cff6b5de52315+|r
	[9] = { ["score"] = 590, ["color"] = { 0.00, 0.44, 0.87 } },		-- |cff0070dd2100+|r
	[10] = { ["score"] = 585, ["color"] = { 0.31, 0.56, 0.74 } },		-- |cff4e8ebd1785+|r
	[11] = { ["score"] = 580, ["color"] = { 0.37, 0.67, 0.62 } },		-- |cff5eaa9f1545+|r
	[12] = { ["score"] = 570, ["color"] = { 0.37, 0.78, 0.49 } },		-- |cff5ec77d1305+|r
	[13] = { ["score"] = 550, ["color"] = { 0.31, 0.89, 0.33 } },		-- |cff4ee4551065+|r
	[14] = { ["score"] = 500, ["color"] = { 0.12, 1.00, 0.00 } },		-- |cff1eff00850+|r
	[15] = { ["score"] = 400, ["color"] = { 0.49, 1.00, 0.37 } },		-- |cff7cff5f700+|r
	[16] = { ["score"] = 200, ["color"] = { 0.78, 1.00, 0.70 } },		-- |cffc6ffb2450+|r
	[17] = { ["score"] = 0, ["color"] = { 1.00, 1.00, 1.00 } },		-- |cffffffff200+|r
}

-- Add various color of Mythic+ Dungeon score (The war within season 1)
local scoreTiers = {
	[1] = { ["score"] = 3500, ["color"] = { 1.00, 0.50, 0.00 } },		-- |cffff80003925+|r
	[2] = { ["score"] = 3450, ["color"] = { 1.00, 0.49, 0.08 } },		-- |cfffe7e143860+|r
	[3] = { ["score"] = 3400, ["color"] = { 0.99, 0.49, 0.12 } },		-- |cfffd7c1f3835+|r
	[4] = { ["score"] = 3350, ["color"] = { 0.99, 0.48, 0.16 } },		-- |cfffc7a283810+|r
	[5] = { ["score"] = 3300, ["color"] = { 0.98, 0.47, 0.19 } },		-- |cfffb79303785+|r
	[6] = { ["score"] = 3250, ["color"] = { 0.98, 0.47, 0.22 } },		-- |cfffa77373760+|r
	[7] = { ["score"] = 3200, ["color"] = { 0.98, 0.46, 0.24 } },		-- |cfff9753e3740+|r
	[8] = { ["score"] = 3175, ["color"] = { 0.97, 0.45, 0.27 } },		-- |cfff873443715+|r
	[9] = { ["score"] = 3150, ["color"] = { 0.96, 0.44, 0.29 } },		-- |cfff671493690+|r
	[10] = { ["score"] = 3125, ["color"] = { 0.96, 0.44, 0.31 } },		-- |cfff56f4f3665+|r
	[11] = { ["score"] = 3100, ["color"] = { 0.96, 0.43, 0.33 } },		-- |cfff46d543640+|r
	[12] = { ["score"] = 3075, ["color"] = { 0.95, 0.42, 0.35 } },		-- |cfff36c5a3620+|r
	[13] = { ["score"] = 3050, ["color"] = { 0.95, 0.42, 0.37 } },		-- |cfff16a5f3595+|r
	[14] = { ["score"] = 3025, ["color"] = { 0.94, 0.41, 0.39 } },		-- |cfff068643570+|r
	[15] = { ["score"] = 3000, ["color"] = { 0.93, 0.40, 0.41 } },		-- |cffee66693545+|r
	[16] = { ["score"] = 2975, ["color"] = { 0.93, 0.39, 0.43 } },		-- |cffed646e3520+|r
	[17] = { ["score"] = 2950, ["color"] = { 0.92, 0.38, 0.45 } },		-- |cffeb62733500+|r
	[18] = { ["score"] = 2925, ["color"] = { 0.92, 0.38, 0.47 } },		-- |cffea60773475+|r
	[19] = { ["score"] = 2900, ["color"] = { 0.91, 0.37, 0.49 } },		-- |cffe85f7c3450+|r
	[20] = { ["score"] = 2875, ["color"] = { 0.90, 0.36, 0.51 } },		-- |cffe65d813425+|r
	[21] = { ["score"] = 2850, ["color"] = { 0.90, 0.36, 0.53 } },		-- |cffe55b863400+|r
	[22] = { ["score"] = 2825, ["color"] = { 0.89, 0.35, 0.55 } },		-- |cffe3598b3380+|r
	[23] = { ["score"] = 2800, ["color"] = { 0.88, 0.34, 0.56 } },		-- |cffe1578f3355+|r
	[24] = { ["score"] = 2775, ["color"] = { 0.87, 0.33, 0.58 } },		-- |cffdf55943330+|r
	[25] = { ["score"] = 2750, ["color"] = { 0.87, 0.33, 0.60 } },		-- |cffdd53993305+|r
	[26] = { ["score"] = 2725, ["color"] = { 0.85, 0.32, 0.62 } },		-- |cffda529d3280+|r
	[27] = { ["score"] = 2700, ["color"] = { 0.85, 0.31, 0.64 } },		-- |cffd850a23260+|r
	[28] = { ["score"] = 2675, ["color"] = { 0.84, 0.31, 0.65 } },		-- |cffd64ea73235+|r
	[29] = { ["score"] = 2650, ["color"] = { 0.83, 0.30, 0.67 } },		-- |cffd34cac3210+|r
	[30] = { ["score"] = 2625, ["color"] = { 0.82, 0.29, 0.69 } },		-- |cffd14ab03185+|r
	[31] = { ["score"] = 2600, ["color"] = { 0.81, 0.29, 0.71 } },		-- |cffce49b53160+|r
	[32] = { ["score"] = 2575, ["color"] = { 0.80, 0.28, 0.73 } },		-- |cffcb47ba3140+|r
	[33] = { ["score"] = 2550, ["color"] = { 0.79, 0.27, 0.75 } },		-- |cffc945be3115+|r
	[34] = { ["score"] = 2525, ["color"] = { 0.78, 0.26, 0.76 } },		-- |cffc643c33090+|r
	[35] = { ["score"] = 2500, ["color"] = { 0.76, 0.26, 0.78 } },		-- |cffc242c83065+|r
	[36] = { ["score"] = 2480, ["color"] = { 0.75, 0.25, 0.80 } },		-- |cffbf40cd3040+|r
	[37] = { ["score"] = 2460, ["color"] = { 0.74, 0.24, 0.82 } },		-- |cffbc3ed13020+|r
	[38] = { ["score"] = 2440, ["color"] = { 0.72, 0.24, 0.84 } },		-- |cffb83dd62995+|r
	[39] = { ["score"] = 2420, ["color"] = { 0.71, 0.23, 0.86 } },		-- |cffb43bdb2970+|r
	[40] = { ["score"] = 2400, ["color"] = { 0.69, 0.23, 0.88 } },		-- |cffb03ae02945+|r
	[41] = { ["score"] = 2380, ["color"] = { 0.67, 0.22, 0.89 } },		-- |cffac38e42920+|r
	[42] = { ["score"] = 2360, ["color"] = { 0.66, 0.21, 0.91 } },		-- |cffa836e92900+|r
	[43] = { ["score"] = 2340, ["color"] = { 0.64, 0.21, 0.93 } },		-- |cffa335ee2875+|r
	[44] = { ["score"] = 2320, ["color"] = { 0.62, 0.24, 0.93 } },		-- |cff9d3ded2835+|r
	[45] = { ["score"] = 2300, ["color"] = { 0.59, 0.26, 0.93 } },		-- |cff9643ec2810+|r
	[46] = { ["score"] = 2280, ["color"] = { 0.56, 0.29, 0.92 } },		-- |cff8f49ea2790+|r
	[47] = { ["score"] = 2260, ["color"] = { 0.53, 0.31, 0.91 } },		-- |cff884ee92765+|r
	[48] = { ["score"] = 2240, ["color"] = { 0.51, 0.33, 0.91 } },		-- |cff8153e82740+|r
	[49] = { ["score"] = 2220, ["color"] = { 0.47, 0.34, 0.91 } },		-- |cff7957e72715+|r
	[50] = { ["score"] = 2200, ["color"] = { 0.44, 0.36, 0.90 } },		-- |cff715be52690+|r
	[51] = { ["score"] = 2180, ["color"] = { 0.41, 0.37, 0.89 } },		-- |cff695ee42670+|r
	[52] = { ["score"] = 2160, ["color"] = { 0.37, 0.38, 0.89 } },		-- |cff5f62e32645+|r
	[53] = { ["score"] = 2140, ["color"] = { 0.33, 0.40, 0.89 } },		-- |cff5565e22620+|r
	[54] = { ["score"] = 2120, ["color"] = { 0.29, 0.41, 0.88 } },		-- |cff4968e12595+|r
	[55] = { ["score"] = 2100, ["color"] = { 0.23, 0.42, 0.87 } },		-- |cff3b6bdf2570+|r
	[56] = { ["score"] = 2080, ["color"] = { 0.16, 0.43, 0.87 } },		-- |cff286dde2550+|r
	[57] = { ["score"] = 2060, ["color"] = { 0.00, 0.44, 0.87 } },		-- |cff0070dd2525+|r
	[58] = { ["score"] = 2040, ["color"] = { 0.08, 0.45, 0.86 } },		-- |cff1472db2440+|r
	[59] = { ["score"] = 2020, ["color"] = { 0.13, 0.46, 0.85 } },		-- |cff2075d82415+|r
	[60] = { ["score"] = 2000, ["color"] = { 0.16, 0.47, 0.84 } },		-- |cff2877d62390+|r
	[61] = { ["score"] = 1980, ["color"] = { 0.18, 0.47, 0.83 } },		-- |cff2e79d32370+|r
	[62] = { ["score"] = 1960, ["color"] = { 0.20, 0.48, 0.82 } },		-- |cff337bd12345+|r
	[63] = { ["score"] = 1940, ["color"] = { 0.22, 0.49, 0.81 } },		-- |cff387ecf2320+|r
	[64] = { ["score"] = 1920, ["color"] = { 0.24, 0.50, 0.80 } },		-- |cff3c80cc2295+|r
	[65] = { ["score"] = 1900, ["color"] = { 0.25, 0.51, 0.79 } },		-- |cff4082ca2270+|r
	[66] = { ["score"] = 1880, ["color"] = { 0.26, 0.52, 0.78 } },		-- |cff4384c72250+|r
	[67] = { ["score"] = 1860, ["color"] = { 0.27, 0.53, 0.77 } },		-- |cff4687c52225+|r
	[68] = { ["score"] = 1840, ["color"] = { 0.29, 0.54, 0.76 } },		-- |cff4989c22200+|r
	[69] = { ["score"] = 1820, ["color"] = { 0.29, 0.55, 0.75 } },		-- |cff4b8bc02175+|r
	[70] = { ["score"] = 1800, ["color"] = { 0.31, 0.56, 0.75 } },		-- |cff4e8ebe2150+|r
	[71] = { ["score"] = 1780, ["color"] = { 0.31, 0.56, 0.73 } },		-- |cff5090bb2130+|r
	[72] = { ["score"] = 1760, ["color"] = { 0.32, 0.57, 0.73 } },		-- |cff5292b92105+|r
	[73] = { ["score"] = 1740, ["color"] = { 0.33, 0.58, 0.71 } },		-- |cff5395b62080+|r
	[74] = { ["score"] = 1720, ["color"] = { 0.33, 0.59, 0.71 } },		-- |cff5597b42055+|r
	[75] = { ["score"] = 1700, ["color"] = { 0.34, 0.60, 0.69 } },		-- |cff5799b12030+|r
	[76] = { ["score"] = 1680, ["color"] = { 0.35, 0.61, 0.69 } },		-- |cff589caf2010+|r
	[77] = { ["score"] = 1660, ["color"] = { 0.35, 0.62, 0.67 } },		-- |cff599eac1985+|r
	[78] = { ["score"] = 1640, ["color"] = { 0.35, 0.63, 0.67 } },		-- |cff5aa0aa1960+|r
	[79] = { ["score"] = 1620, ["color"] = { 0.36, 0.64, 0.65 } },		-- |cff5ba3a71935+|r
	[80] = { ["score"] = 1600, ["color"] = { 0.36, 0.65, 0.64 } },		-- |cff5ca5a41910+|r
	[81] = { ["score"] = 1580, ["color"] = { 0.36, 0.66, 0.64 } },		-- |cff5da8a21890+|r
	[82] = { ["score"] = 1560, ["color"] = { 0.37, 0.67, 0.62 } },		-- |cff5eaa9f1865+|r
	[83] = { ["score"] = 1540, ["color"] = { 0.37, 0.67, 0.62 } },		-- |cff5eac9d1840+|r
	[84] = { ["score"] = 1520, ["color"] = { 0.37, 0.69, 0.60 } },		-- |cff5faf9a1815+|r
	[85] = { ["score"] = 1500, ["color"] = { 0.37, 0.69, 0.59 } },		-- |cff5fb1971790+|r
	[86] = { ["score"] = 1480, ["color"] = { 0.37, 0.70, 0.58 } },		-- |cff5fb3951770+|r
	[87] = { ["score"] = 1460, ["color"] = { 0.37, 0.71, 0.57 } },		-- |cff5fb6921745+|r
	[88] = { ["score"] = 1440, ["color"] = { 0.37, 0.72, 0.56 } },		-- |cff5fb88f1720+|r
	[89] = { ["score"] = 1420, ["color"] = { 0.37, 0.73, 0.55 } },		-- |cff5fbb8c1695+|r
	[90] = { ["score"] = 1400, ["color"] = { 0.37, 0.74, 0.54 } },		-- |cff5fbd8a1670+|r
	[91] = { ["score"] = 1380, ["color"] = { 0.37, 0.75, 0.53 } },		-- |cff5fbf871650+|r
	[92] = { ["score"] = 1360, ["color"] = { 0.37, 0.76, 0.52 } },		-- |cff5fc2841625+|r
	[93] = { ["score"] = 1340, ["color"] = { 0.37, 0.77, 0.51 } },		-- |cff5ec4811600+|r
	[94] = { ["score"] = 1320, ["color"] = { 0.37, 0.78, 0.49 } },		-- |cff5ec77e1575+|r
	[95] = { ["score"] = 1300, ["color"] = { 0.36, 0.79, 0.48 } },		-- |cff5dc97b1550+|r
	[96] = { ["score"] = 1280, ["color"] = { 0.36, 0.80, 0.47 } },		-- |cff5ccb781530+|r
	[97] = { ["score"] = 1260, ["color"] = { 0.36, 0.81, 0.46 } },		-- |cff5cce751505+|r
	[98] = { ["score"] = 1240, ["color"] = { 0.36, 0.82, 0.45 } },		-- |cff5bd0721480+|r
	[99] = { ["score"] = 1220, ["color"] = { 0.35, 0.83, 0.44 } },		-- |cff5ad36f1455+|r
	[100] = { ["score"] = 1200, ["color"] = { 0.35, 0.84, 0.42 } },		-- |cff58d56b1430+|r
	[101] = { ["score"] = 1180, ["color"] = { 0.34, 0.85, 0.41 } },		-- |cff57d8681410+|r
	[102] = { ["score"] = 1160, ["color"] = { 0.34, 0.85, 0.39 } },		-- |cff56da641385+|r
	[103] = { ["score"] = 1140, ["color"] = { 0.33, 0.86, 0.38 } },		-- |cff54dc611360+|r
	[104] = { ["score"] = 1120, ["color"] = { 0.32, 0.87, 0.36 } },		-- |cff52df5d1335+|r
	[105] = { ["score"] = 1100, ["color"] = { 0.31, 0.88, 0.35 } },		-- |cff50e1591310+|r
	[106] = { ["score"] = 1080, ["color"] = { 0.31, 0.89, 0.33 } },		-- |cff4ee4551290+|r
	[107] = { ["score"] = 1060, ["color"] = { 0.30, 0.90, 0.32 } },		-- |cff4ce6511265+|r
	[108] = { ["score"] = 1040, ["color"] = { 0.29, 0.91, 0.30 } },		-- |cff49e94d1240+|r
	[109] = { ["score"] = 1020, ["color"] = { 0.28, 0.92, 0.28 } },		-- |cff47eb481215+|r
	[110] = { ["score"] = 1000, ["color"] = { 0.27, 0.93, 0.26 } },		-- |cff44ee431190+|r
	[111] = { ["score"] = 980, ["color"] = { 0.25, 0.94, 0.24 } },		-- |cff40f03e1170+|r
	[112] = { ["score"] = 960, ["color"] = { 0.24, 0.95, 0.22 } },		-- |cff3cf3381145+|r
	[113] = { ["score"] = 940, ["color"] = { 0.22, 0.96, 0.20 } },		-- |cff38f5321120+|r
	[114] = { ["score"] = 920, ["color"] = { 0.20, 0.97, 0.16 } },		-- |cff33f82a1095+|r
	[115] = { ["score"] = 900, ["color"] = { 0.18, 0.98, 0.13 } },		-- |cff2efa221070+|r
	[116] = { ["score"] = 880, ["color"] = { 0.15, 0.99, 0.09 } },		-- |cff27fd161050+|r
	[117] = { ["score"] = 860, ["color"] = { 0.12, 1.00, 0.00 } },		-- |cff1eff001025+|r
	[118] = { ["score"] = 840, ["color"] = { 0.21, 1.00, 0.11 } },		-- |cff35ff1d1000+|r
	[119] = { ["score"] = 820, ["color"] = { 0.27, 1.00, 0.17 } },		-- |cff45ff2c975+|r
	[120] = { ["score"] = 800, ["color"] = { 0.32, 1.00, 0.22 } },		-- |cff52ff37950+|r
	[121] = { ["score"] = 780, ["color"] = { 0.36, 1.00, 0.25 } },		-- |cff5cff41925+|r
	[122] = { ["score"] = 760, ["color"] = { 0.40, 1.00, 0.29 } },		-- |cff66ff4a900+|r
	[123] = { ["score"] = 740, ["color"] = { 0.44, 1.00, 0.33 } },		-- |cff6fff53875+|r
	[124] = { ["score"] = 720, ["color"] = { 0.47, 1.00, 0.35 } },		-- |cff77ff5a850+|r
	[125] = { ["score"] = 700, ["color"] = { 0.49, 1.00, 0.38 } },		-- |cff7eff62825+|r
	[126] = { ["score"] = 680, ["color"] = { 0.53, 1.00, 0.41 } },		-- |cff86ff69800+|r
	[127] = { ["score"] = 660, ["color"] = { 0.55, 1.00, 0.44 } },		-- |cff8cff70775+|r
	[128] = { ["score"] = 640, ["color"] = { 0.58, 1.00, 0.47 } },		-- |cff93ff77750+|r
	[129] = { ["score"] = 620, ["color"] = { 0.60, 1.00, 0.49 } },		-- |cff99ff7e725+|r
	[130] = { ["score"] = 600, ["color"] = { 0.62, 1.00, 0.52 } },		-- |cff9fff84700+|r
	[131] = { ["score"] = 580, ["color"] = { 0.65, 1.00, 0.55 } },		-- |cffa5ff8b675+|r
	[132] = { ["score"] = 560, ["color"] = { 0.67, 1.00, 0.57 } },		-- |cffabff91650+|r
	[133] = { ["score"] = 540, ["color"] = { 0.69, 1.00, 0.59 } },		-- |cffb0ff97625+|r
	[134] = { ["score"] = 520, ["color"] = { 0.71, 1.00, 0.62 } },		-- |cffb6ff9e600+|r
	[135] = { ["score"] = 500, ["color"] = { 0.73, 1.00, 0.64 } },		-- |cffbbffa4575+|r
	[136] = { ["score"] = 480, ["color"] = { 0.75, 1.00, 0.67 } },		-- |cffc0ffaa550+|r
	[137] = { ["score"] = 460, ["color"] = { 0.77, 1.00, 0.69 } },		-- |cffc5ffb0525+|r
	[138] = { ["score"] = 440, ["color"] = { 0.79, 1.00, 0.71 } },		-- |cffcaffb6500+|r
	[139] = { ["score"] = 420, ["color"] = { 0.81, 1.00, 0.74 } },		-- |cffcfffbc475+|r
	[140] = { ["score"] = 400, ["color"] = { 0.83, 1.00, 0.76 } },		-- |cffd3ffc3450+|r
	[141] = { ["score"] = 380, ["color"] = { 0.85, 1.00, 0.79 } },		-- |cffd8ffc9425+|r
	[142] = { ["score"] = 360, ["color"] = { 0.87, 1.00, 0.81 } },		-- |cffddffcf400+|r
	[143] = { ["score"] = 340, ["color"] = { 0.88, 1.00, 0.84 } },		-- |cffe1ffd5375+|r
	[144] = { ["score"] = 320, ["color"] = { 0.90, 1.00, 0.86 } },		-- |cffe6ffdb350+|r
	[145] = { ["score"] = 300, ["color"] = { 0.92, 1.00, 0.88 } },		-- |cffeaffe1325+|r
	[146] = { ["score"] = 280, ["color"] = { 0.93, 1.00, 0.91 } },		-- |cffeeffe7300+|r
	[147] = { ["score"] = 260, ["color"] = { 0.95, 1.00, 0.93 } },		-- |cfff3ffed275+|r
	[148] = { ["score"] = 240, ["color"] = { 0.97, 1.00, 0.95 } },		-- |cfff7fff3250+|r
	[149] = { ["score"] = 220, ["color"] = { 0.98, 1.00, 0.98 } },		-- |cfffbfff9225+|r
	[150] = { ["score"] = 200, ["color"] = { 1.00, 1.00, 1.00 } },		-- |cffffffff200+|r
}

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

local FastItemLevelDebug = false
local throttleTime = 0.1
local cacheExpireTime = 600

local printDebug = FastItemLevelDebug and print or function()
end

local InspectCache = {}
local InspectCacheOrder = {}

local function UpdateCacheOrder(key)
    local order = InspectCacheOrder[key]
    if order then
        table.remove(InspectCacheOrder, order)
    end
    table.insert(InspectCacheOrder, key)
end

local function TrimCache()
    while #InspectCacheOrder > defaults.global.cacheSize do
        local key = table.remove(InspectCacheOrder, 1)
        InspectCache[key] = nil
        printDebug("Removed cache entry for " .. key .. " due to cache size limit")
    end
end

local function GetSpecNameByID(specID)
    local specName = select(2, GetSpecializationInfoByID(specID))
    return specName or "N/A"
end

local function GetInspectData(guid)
    local data = InspectCache[guid]
    if data then
        if time() - data.timestamp >= cacheExpireTime then
            InspectCache[guid] = nil
            printDebug("Removed cache entry for " .. guid .. " due to expiration")
            return nil
        else
            UpdateCacheOrder(guid)
        end
    end
    return data
end

local function SetInspectData(guid, data)
    if not InspectCache[guid] then
        if #InspectCacheOrder >= defaults.global.cacheSize then
            TrimCache()
        end
        UpdateCacheOrder(guid)
    end
    InspectCache[guid] = data
end

local lastInspectTime = 0
local inspectQueue = {}

local function ProcessInspectQueue()
    if #inspectQueue > 0 then
        local guid = table.remove(inspectQueue, 1)
        local unit = "mouseover"
        if UnitGUID(unit) == guid and CanInspect(unit, true) then
            NotifyInspect(unit)
            printDebug("Inspecting " .. UnitName(unit))
        else
            printDebug("Cannot inspect, skipping")
        end
    end
end

local function UpdateMouseoverTooltip(self)
    if not UnitIsPlayer("mouseover") then
        return
    end

    local guid = UnitGUID("mouseover")
    local data = InspectCache[guid]

    if data then
        GameTooltip_SetTooltipWaitingForData(self, false)

        local addLine = true

        local specName = data.specName

        local unitID, name = GetUnitIDFromGUID(guid)
		local classDisplayName, class = UnitClass(unitID)
        local specColor = class and RAID_CLASS_COLORS[class]

        if not specName or specName == "" then
            specName = classDisplayName
        end

        local r1, g1, b1 = specColor.r, specColor.g, specColor.b
        local r2, g2, b2 = GetItemLevelColor(data.ilevel)

        for i = self:NumLines(), 1, -1 do
            local line = _G[self:GetName() .. "TextLeft" .. i]:GetText()
            if line and strsub(line, 1, 16) == specName then
                addLine = false
                break
            end
        end

        if not addLine then
            return
        end


        GameTooltip:AddDoubleLine(specName,data.ilevel, r1, g1, b1 , r2, g2, b2) 

		local mythicplusrating = data.mythicplusrating and data.mythicplusrating.currentSeasonScore or 0
        if mythicplusrating > 0 then
			local mythicLabel = mythicplusrating
			local bestRun = 0
			for _, run in pairs(data.mythicplusrating.runs or {}) do
				if run.finishedSuccess and run.bestRunLevel > bestRun then
					bestRun = run.bestRunLevel
				end
			end

			if bestRun > 0 then
				mythicLabel = mythicplusrating .. " " .. "+" .. bestRun .. "|r"
			end

			--local color = C_ChallengeMode.GetDungeonScoreRarityColor(mythicplusrating) or HIGHLIGHT_FONT_COLOR
			local r, g, b = GetScoreColor(mythicplusrating)
			local color = CreateColor(r, g, b) or HIGHLIGHT_FONT_COLOR
			GameTooltip:AddDoubleLine("평점", mythicLabel, 0.6, 0.6, 0.6, color:GetRGB())
		end

        GameTooltip:Show()
    else
        GameTooltip_SetTooltipWaitingForData(self, true)
    end
end

function FastItemLevel:OnShiftKeyDown()
    if not defaults.global.shiftKeyRequired then
        return
    end

    local unit = "mouseover"
    if UnitIsPlayer(unit) then
        self:UPDATE_MOUSEOVER_UNIT()
    end
end

function FastItemLevel:OnEnable()
    self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    self:RegisterEvent("INSPECT_READY")

    GameTooltip:HookScript("OnUpdate", function(self)
        if not UnitIsPlayer("mouseover") then
            return
        end

        local guid = UnitGUID("mouseover")
        local data = InspectCache[guid]

        if data then
            UpdateMouseoverTooltip(self)
        else
            GameTooltip_SetTooltipWaitingForData(self, true)
        end
    end)

    self:RegisterEvent("MODIFIER_STATE_CHANGED")
end

function FastItemLevel:MODIFIER_STATE_CHANGED(_, key, state)
    if key == "LSHIFT" and state == 1 then
        self:OnShiftKeyDown()
    end
end

function FastItemLevel:UPDATE_MOUSEOVER_UNIT()
    printDebug("UPDATE_MOUSEOVER_UNIT")
    local unit = "mouseover"
    if UnitIsPlayer(unit) then
        local guid = UnitGUID(unit)
        local data = GetInspectData(guid)
        local shiftKeyDown = IsShiftKeyDown()

        if not data or (time() - data.timestamp >= cacheExpireTime) then
            if (not defaults.global.shiftKeyRequired or shiftKeyDown) and CanInspect(unit, true) then
                C_Timer.After(defaults.global.inspectDelay, function()
                    if UnitGUID("mouseover") == guid then
                        table.insert(inspectQueue, 1, guid)
                        printDebug("Queued mouseover inspect for " .. UnitName(unit))
                        ProcessInspectQueue()
                    end
                end)
            else
                printDebug("Cannot inspect " .. UnitName(unit) .. ", skipping")
            end
        else
            printDebug("Using cached data for " .. UnitName(unit) .. ", last updated " .. (time() - data.timestamp) ..
                           " seconds ago")
            UpdateMouseoverTooltip(GameTooltip)
        end
    end
end

function FastItemLevel:INSPECT_READY(_, guid)
    if guid then
        local class, _, classId = UnitClass("mouseover")
        local spec = GetInspectSpecialization("mouseover")
        local specName = GetSpecNameByID(spec)
        local ilevel = C_PaperDollInfo.GetInspectItemLevel("mouseover")
		local mythicplusrating = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("mouseover") or {}

        if ilevel ~= 0 then
            local data = {
                class = class,
                spec = spec,
                specName = specName,
                ilevel = ilevel,
                mythicplusrating = mythicplusrating,
                timestamp = time()
            }

            SetInspectData(guid, data)
            printDebug("InspectUnit: " .. guid .. " " .. class .. " " .. spec .. " " .. ilevel)

            if UnitGUID("mouseover") == guid then
                printDebug("Refreshing mouseover tooltip for " .. UnitName("mouseover"))
                UpdateMouseoverTooltip(GameTooltip)
            end
        end
    end
end
