-- Global Variables
local LSM = LibStub("LibSharedMedia-3.0")

local _G = _G
local ipairs, select, tostring = ipairs, select, tostring
local GetCVar, SetCVar = GetCVar, SetCVar
local locale = GetLocale()
local IsInGroup = IsInGroup
local IsInGuild = IsInGuild
local IsInInstance = IsInInstance
local IsInRaid = IsInRaid
local IsShiftKeyDown = IsShiftKeyDown
local width, height = GetPhysicalScreenSize()

-- _G["UNIT_POPUP_RIGHT_CLICK"] = "상세 메뉴: 우클릭"

-- Create Frame/event handler
Mumu = CreateFrame("Frame", "Mumu")
Mumu:SetScript(
	"OnEvent",
	function(self, event, ...)
		if self[event] then
			return self[event](self, event, ...)
		end
	end
)
Mumu:RegisterEvent("ADDON_LOADED")

-- Register events
function Mumu:ADDON_LOADED(...)
	self:UnregisterEvent("ADDON_LOADED")
	self:SetScreenshotQuality()
	self:SetCameraIndirectVisibility()
	self:SetUIErrorsFrame()
	self:SetDefaultSpacing()
	self:ChangeWoWFonts()
	self.ADDON_LOADED = nil
end

-- event: screenshot quality
function Mumu:SetScreenshotQuality()
	local value = GetCVar("screenshotQuality")
	if value ~= 10 then
		SetCVar("screenshotQuality", 10) -- 10: Max quality
	end
end

function Mumu:SetCameraIndirectVisibility()
	local value = GetCVar("cameraIndirectVisibility")
	if value ~= 1 then
		SetCVar("cameraIndirectVisibility", 1) -- 1: Turn on
		SetCVar("cameraIndirectOffset", 10) -- 1-10: set 10 to cameraIndirectOffset.
	end
end


-- event: Adjust/Modify UI ErrorFrames
function Mumu:SetUIErrorsFrame()
	UIErrorsFrame:ClearAllPoints()
	UIErrorsFrame:SetPoint("TOP", "UIParent", "TOP", 0, -60) -- Relocate UI ErrorFrames
	UIErrorsFrame.SetPoint = function()
	end
end

-- event: swiching chatting Tab
local cycles = {
	{
		chatType = "SAY",
		use = function(self, editbox)
			return 1
		end
	},
	{
		chatType = "PARTY",
		use = function(self, editbox)
			return IsInGroup()
		end
	},
	{
		chatType = "RAID",
		use = function(self, editbox)
			return IsInRaid()
		end
	},
	{
		chatType = "INSTANCE_CHAT",
		use = function(self, editbox)
			return select(2, IsInInstance()) == "party"
		end
	},
	{
		chatType = "GUILD",
		use = function(self, editbox)
			return IsInGuild()
		end
	},
	{
		chatType = "CHANNEL",
		use = function(self, editbox, currChatType)
			local currNum
			if currChatType ~= "CHANNEL" then
				currNum = IsShiftKeyDown() and 21 or 0
			else
				currNum = editbox:GetAttribute("channelTarget")
			end
			local h, r, step = currNum + 1, 20, 1
			if IsShiftKeyDown() then
				h, r, step = currNum - 1, 1, -1
			end
			for i = h, r, step do
				local channelNum, channelName = GetChannelName(i)
				if channelNum > 0 and not channelName:find("공개 %-") then
					editbox:SetAttribute("channelTarget", i)
					return true
				end
			end
		end
	},
	{
		chatType = "SAY",
		use = function(self, editbox)
			return 1
		end
	}
}

local function CustomTabPressed(self)
	if strsub(tostring(self:GetText()), 1, 1) == "/" then
		return
	end
	local currChatType = self:GetAttribute("chatType")
	for i, curr in ipairs(cycles) do
		if curr.chatType == currChatType then
			local h, r, step = i + 1, #cycles, 1
			if IsShiftKeyDown() then
				h, r, step = i - 1, 1, -1
			end
			if currChatType == "CHANNEL" then
				h = i
			end
			for j = h, r, step do
				if cycles[j]:use(self, currChatType) then
					self:SetAttribute("chatType", cycles[j].chatType)
					ChatEdit_UpdateHeader(self)
					return
				end
			end
		end
	end
end

hooksecurefunc("ChatEdit_CustomTabPressed", CustomTabPressed)

function Mumu:SetDefaultSpacing()
	for i = 1, NUM_CHAT_WINDOWS do
		_G["ChatFrame" .. i]:SetSpacing(4)
	end
end

function Mumu:SetFont(fontFile, height, flags)
	self:SetFont(fontFile, height, flags)
end

function Mumu:ChangeWoWFonts()
	local SetFont = self.SetFont
	local NORMAL = "Fonts\\2002.ttf"
	local NUMBER = "Fonts\\ARIALN.ttf"
	local KENRIS = "Fonts\\K_Pagetext.ttf"
	local PANNO = "Fonts\\Panno.ttf"
	local SERIF = "Fonts\\K_Damage.ttf"
	
	-- Global font
	_G.UNIT_NAME_FONT = SERIF
	_G.DAMAGE_TEXT_FONT = KENRIS

	-- World zone text font, world map text font
	SetFont(ZoneTextFont, KENRIS, 32, "OUTLINE")
	SetFont(SubZoneTextFont, KENRIS, 26, "OUTLINE")
	SetFont(PVPInfoTextFont, KENRIS, 22, "THINOUTLINE")
	SetFont(WorldMapTextFont, KENRIS, 32, "THINOUTLINE")

	-- Action button counts, Stack counts, Buff/Debuff counts, Player money...
	SetFont(NumberFont_Outline_Med, NUMBER, 14, "OUTLINE")
	
	-- Action button cooldown text
	SetFont(SystemFont_Shadow_Large_Outline, SERIF, 18, "THINOUTLINE") 

	-- Unit frame Buff/Debuff counts...
	SetFont(NumberFontNormalSmall, NUMBER, 13, "OUTLINE")

	-- Chat font/Chat input textarea
	SetFont(NumberFont_Shadow_Med, NUMBER, 14, "")

	-- Community & Guild chat frame
	CommunitiesFrame.Chat.MessageFrame:SetFont(NUMBER, 14, "")

	-- Unit Frame Health/Mana, Action Bar
	SetFont(TextStatusBarText, PANNO, 11, "OUTLINE")

	-- Unit Frame Level
	SetFont(GameNormalNumberFont, PANNO, 11, "")

	-- Unit Frame Name/Text
	PlayerName:SetFont(PANNO, 11, "")
	PetName:SetFont(PANNO, 11, "")
	TargetFrame.TargetFrameContent.TargetFrameContentMain.Name:SetFont(PANNO, 11, "")
	FocusFrame.TargetFrameContent.TargetFrameContentMain.Name:SetFont(PANNO, 11, "")
	
	TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.DeadText:SetFont(PANNO, 11, "")
	TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.UnconsciousText:SetFont(PANNO, 11, "")
	FocusFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.DeadText:SetFont(PANNO, 11, "")
	FocusFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.UnconsciousText:SetFont(PANNO, 11, "")

	TargetFrameToT.Name:SetFont(PANNO, 11, "")
	FocusFrameToT.Name:SetFont(PANNO, 11, "")

	for i = 1, MAX_BOSS_FRAMES do
		local bossTargetFrame = _G["Boss" .. i .. "TargetFrame"]
		bossTargetFrame.TargetFrameContent.TargetFrameContentMain.Name:SetFont(PANNO, 11, "")
	end 

	-- Game Tooltip font
	if width > 2048 then
		GameTooltipText:SetFont(NORMAL, 15, "")
		GameTooltipHeaderText:SetFont(NORMAL, 15, "")
		GameTooltipTextSmall:SetFont(NORMAL, 15, "")
	else
		GameTooltipText:SetFont(NORMAL, 14, "")
		GameTooltipHeaderText:SetFont(NORMAL, 14, "")
		GameTooltipTextSmall:SetFont(NORMAL, 14, "")
	end

	-- Unit Frame HitIndicator Text
	PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HitIndicator.HitText:SetFont(KENRIS, 32, "THINOUTLINE")

	-- Money Frame Font
	SetFont(PriceFont, NUMBER, 14, "")

end

hooksecurefunc(TalkingHeadFrame, "PlayCurrent", function(self)
	self:Hide()
end)
