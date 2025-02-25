local cursors = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}

local function replace_uri_with_hyperlink(message)
	if message then
		local pre, uri, post = message:match("^(.*)(https?://[^ ]+)(.*)$")
		if pre and uri and post then
			return true, string.format("%s|H%s:|h[%s]|h%s", pre, "item", uri, post)
		end
	end
	return false, message
end

local function transform_messages(frame)
	if not frame or not frame.historyBuffer or not frame.historyBuffer.headIndex or not frame.historyBuffer.elements then
		return nil
	end

	local id = frame:GetID()
	local index = frame.historyBuffer.headIndex
	local lines = frame.historyBuffer.elements
	local is_modified = false
	local should_refresh = false

	for at = cursors[id] + 1, index do
		local line = lines[at]

		if line and line.message:find("://") and line.message:find("|Hitem:|h%[.-%]|h") == nil then
			is_modified, line.message = replace_uri_with_hyperlink(line.message)

			if is_modified then
				should_refresh = true
			end
		end
	end

	cursors[id] = index

	if should_refresh then
		frame:RefreshLayout()
	end
end

local function ChatFrame_OnHyperlinkShow(self, link, text, button)
	if link:sub(1, 4) == "item" and text:find("://") then
		if ChatFrame1EditBox then
			ChatFrame1EditBox:Show()
			ChatFrame1EditBox:SetFocus()
			ChatFrame1EditBox:SetText(text:match("%[(.+)%]"))
			ChatFrame1EditBox:HighlightText()
		end
	end
end

local function tick()
	transform_messages(ChatFrame1)
	transform_messages(ChatFrame3)
	transform_messages(ChatFrame4)
	transform_messages(ChatFrame5)
	transform_messages(ChatFrame6)
	transform_messages(ChatFrame7)
	transform_messages(ChatFrame8)
	transform_messages(ChatFrame9)
	transform_messages(ChatFrame10)
end

local function PLAYER_LOGIN(self)
	C_Timer.NewTicker(1, tick)

	hooksecurefunc("ChatFrame_OnHyperlinkShow", ChatFrame_OnHyperlinkShow)
end

local function OnEvent(self, event, ...)
	if event == "PLAYER_LOGIN" then
		PLAYER_LOGIN(self)
	end
end

local function run()
	local agent = CreateFrame("Frame")
	agent:RegisterEvent("PLAYER_LOGIN")
	agent:SetScript("OnEvent", OnEvent)
end

run()