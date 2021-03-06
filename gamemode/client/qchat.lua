if qchat and IsValid(qchat.pPanel) then
	qchat:Close()
end

qchat = {
	Author = "Q2F2 (/id/q2f2)",
	Contact = "notq2f2@gmail.com",
}

qchat.shortcut = {
	[".lenny"] = [[( ͡° ͜ʖ ͡°)]],
	[".iunno"] = [[¯\_(ツ)_/¯]],
	[".flip"] = [[(╯°□°）╯︵ ┻━┻]],
	[".unflip"] = [[┬─┬﻿ ノ( ゜-゜ノ)]],
}

local Legacy			= CreateClientConVar("qchat_legacymode", "1", true)
local HaxrCorp		= CreateClientConVar("qchat_use_haxrcorp", "0", true)
local FontSize		= CreateClientConVar("qchat_fontsize", HaxrCorp:GetBool() and "21" or "17", true)
local TransBack		= CreateClientConVar("qchat_use_transback", "0", true)

function qchat.CreateFonts()
	if Legacy then
		surface.CreateFont("QChatFont", {
			font = "Verdana",
			size = FontSize:GetInt(),
			weight = 600,
			shadow = true,
		})

		surface.CreateFont("QChatFont2", {
			font = "Verdana",
			size = FontSize:GetInt(),
			weight = 600,
			shadow = true,
		})
	end

	surface.CreateFont("QChatFont", {
		font = HaxrCorp:GetBool() and "HaxrCorp S8" or "Tahoma",
		size = FontSize:GetInt(),
		weight = HaxrCorp:GetBool() and 0 or 1000,
		shadow = true,
	})

	surface.CreateFont("QChatFont2", {
		font = HaxrCorp:GetBool() and "HaxrCorp S8" or "Tahoma",
		size = HaxrCorp:GetBool() and 16 or 15,
		weight = HaxrCorp:GetBool() and 0 or 500,
		shadow = true,
	})
end

qchat.CreateFonts()
cvars.AddChangeCallback("qchat_fontsize", qchat.CreateFonts)
cvars.AddChangeCallback("qchat_use_haxrcorp", qchat.CreateFonts)

local colors

function qchat.CreateColors()
	if Legacy:GetBool() then
		colors = {
			text						= Color(  0,   0,   0, 255),
			alpha						= Color(  0,   0,   0,   0),

			mainBack				= Color( 10,   0,  10, 100),
			barBack					= Color(255, 255, 255, 100),
			groupBack				= Color( 90,   0,  90, 255),
			textInputColor	= Color(  0,   0,   0, 200),

			highlightOne		= Color(255, 255, 255, 255),
		}
	else
		local a1 = TransBack:GetBool() and 195 or 255
		local a2 = TransBack:GetBool() and 175 or 255

		colors = {
			text						= Color(204, 204, 202,  a1),
			alpha						= Color(  0,   0,   0,   0),

			mainBack				= Color( 51,  51,  51,  a2),
			barBack					= Color( 45,  45,  45,  a1),
			groupBack				= Color( 45,  45,  45,  a1),
			textInputColor	= Color( 78,  78,  78,  a2),

			highlightOne		= Color(217, 191, 194,  a1),
		}
	end
end

qchat.CreateColors()
cvars.AddChangeCallback("qchat_use_transback", qchat.CreateColors)
cvars.AddChangeCallback("qchat_legacymode", qchat.CreateColors)

function qchat.LegacyFix()
	-- Fix fontsize for legacy mode
	if Legacy:GetBool() then
		HaxrCorp:SetBool(false)
		FontSize:SetInt(14)
	end
end
cvars.AddChangeCallback("qchat_legacymode", qchat.LegacyFix)

function qchat:CreateChatTab()
	-- The tab for the actual chat.
	self.chatTab 		= vgui.Create("DPanel", self.pPanel)
	self.chatTab.Paint 	= function(self, w, h)
		surface.SetDrawColor(colors.mainBack)
		surface.DrawRect(0, 0, w, h)
	end

	-- The text entry for the chat.
	self.chatTab.pTBase = vgui.Create("DPanel", self.chatTab)
	self.chatTab.pTBase.Paint 	= function(self, w, h)
	end

	self.chatTab.pTBase:Dock(BOTTOM)

	self.chatTab.pText 	= vgui.Create("DTextEntry", self.chatTab.pTBase)
	self.chatTab.pText:SetHistoryEnabled(true)

	self.chatTab.pGr 	= vgui.Create("DPanel", self.chatTab.pTBase)
	self.chatTab.pGr.Paint 	= function(self, w, h)
		surface.SetDrawColor(colors.groupBack)
		surface.DrawRect(0, 0, w, h)
	end

	self.chatTab.pText.OnKeyCodeTyped = function(pan, key)
		local txt = pan:GetText():Trim()
		hook.Run("ChatTextChanged", txt)

		if key == KEY_ENTER then
			if txt ~= "" then
				pan:AddHistory(txt)
				pan:SetText("")

				pan.HistoryPos = 0

				local team = self.isTeamChat

				if chatexp and hook.Run("ChatShouldHandle", "chatexp", txt, team and CHATMODE_TEAM or CHATMODE_DEFAULT) ~= false then
					chatexp.Say(txt, team and CHATMODE_TEAM or CHATMODE_DEFAULT)
				elseif chitchat and chitchat.Say and hook.Run("ChatShouldHandle", "chitchat", txt, team and 2 or 1) ~= false then
					chitchat.Say(txt, team and 2 or 1)
				else
					LocalPlayer():ConCommand((team and "say_team \"" or "say \"") .. txt .. "\"")
				end
			end

			self:Close()
		end

		if key == KEY_TAB then
			local tab = hook.Run("OnChatTab", txt)
			local split = txt:Split(" ")

			if tab and isstring(tab) and tab ~= txt then
				pan:SetText(tab)
			elseif qchat.shortcut[split[#split]] then
				split[#split] = qchat.shortcut[split[#split]]
				pan:SetText(table.concat(split, " "))
			end

			timer.Simple(0, function() pan:RequestFocus() pan:SetCaretPos(pan:GetText():len()) end)
		end

		if key == KEY_UP then
			pan.HistoryPos = pan.HistoryPos - 1
			pan:UpdateFromHistory()
		end

		if key == KEY_DOWN then
			pan.HistoryPos = pan.HistoryPos + 1
			pan:UpdateFromHistory()
		end
	end

	self.chatTab.pText.Paint = function(pan, w, h)
		surface.SetDrawColor(colors.barBack)
		surface.DrawRect(0, 0, w, h)

		pan:DrawTextEntryText(colors.text, colors.textInputColor, colors.textInputColor)
	end

	self.chatTab.pText.OnChange = function(pan)
		gamemode.Call("ChatTextChanged", pan:GetText() or "")
	end

	self.chatTab.pGr:Dock(LEFT)
	self.chatTab.pText:Dock(FILL)

	self.chatTab.pGr.OnMousePressed = function(pan)
		local mousex = math.Clamp(gui.MouseX(), 1, ScrW() - 1)
		local mousey = math.Clamp(gui.MouseY(), 1, ScrH() - 1)

		self.pPanel.Dragging = {mousex - self.pPanel.x, mousey - self.pPanel.y}
		self.pPanel:MouseCapture(true)
	end

	self.chatTab.pGrLab = vgui.Create("DLabel", self.chatTab.pGr)
	self.chatTab.pGrLab:SetPos(5, 2)

	self.chatTab.pGrLab:SetTextColor(colors.highlightOne)
	self.chatTab.pGrLab:SetFont("QChatFont2")

	-- The element to actually display the chat its-self.
	self.chatTab.pFeed 	= vgui.Create("RichText", self.chatTab)
	self.chatTab.pFeed:Dock(FILL)

	self.chatTab.pFeed.Font = "QChatFont"

	self.chatTab.pFeed.PerformLayout = function(pan)
		pan:SetFontInternal(pan.Font)
	end
end

function qchat:SaveCookies()
	local x, y, w, h = self.pPanel:GetBounds()

	self.pPanel:SetCookie("x", x)
	self.pPanel:SetCookie("y", y)
	self.pPanel:SetCookie("w", w)
	self.pPanel:SetCookie("h", h)
end

function qchat:BuildPanels()
	self.pPanel = vgui.Create("DFrame")
	self.pPanel:SetTitle("")
	self.pPanel.Paint = function(self, w, h) end

	self.pPanel:SetSizable(true)
	self.pPanel:ShowCloseButton(false)

	self.pPanel.Think = function(self)
		local mousex = math.Clamp(gui.MouseX(), 1, ScrW() - 1)
		local mousey = math.Clamp(gui.MouseY(), 1, ScrH() - 1)

		if self.Dragging then
			local x = mousex - self.Dragging[1]
			local y = mousey - self.Dragging[2]

			if self:GetScreenLock() then
				x = math.Clamp(x, 0, ScrW() - self:GetWide())
				y = math.Clamp(y, 0, ScrH() - self:GetTall())
			end

			self:SetPos(x, y)
		end

		if self.Sizing then
			local x = mousex - self.Sizing[1]
			local y = mousey - self.Sizing[2]
			local px, py = self:GetPos()

			if x < self.m_iMinWidth then x = self.m_iMinWidth elseif x > ScrW() - px and self:GetScreenLock() then x = ScrW() - px end
			if y < self.m_iMinHeight then y = self.m_iMinHeight elseif y > ScrH() - py and self:GetScreenLock() then y = ScrH() - py end

			self:SetSize(x, y)
			self:SetCursor("sizenwse")
		return end

		if self.Hovered and mousex > (self.x + self:GetWide() - 20) and mousey > (self.y + self:GetTall() - 20) then
			self:SetCursor("sizenwse")
		return end

		self:SetCursor("arrow")

		if self.y < 0 then
			self:SetPos(self.x, 0)
		end
	end

	self.pPanel.OnMousePressed = function(self)
		local mousex = math.Clamp(gui.MouseX(), 1, ScrW() - 1)
		local mousey = math.Clamp(gui.MouseY(), 1, ScrH() - 1)

		if mousex > (self.x + self:GetWide() - 20) and mousey > (self.y + self:GetTall() - 20) then
			self.Sizing = {mousex - self:GetWide(), mousey - self:GetTall()}
			self:MouseCapture(true)
		return end
	end

	self:CreateChatTab()
	self.chatTab:Dock(FILL)

	self.pPanel:SetCookieName("qchat")

	local x = self.pPanel:GetCookie("x", 20)
	local y = self.pPanel:GetCookie("y", 220)
	local w = self.pPanel:GetCookie("w", 800)
	local h = self.pPanel:GetCookie("h", 500)

	self.pPanel:SetPos(x, y)
	self.pPanel:SetSize(w, h)
end

function qchat:SetUpChat()
	if not self.pPanel or not ValidPanel(self.pPanel) then
		self:BuildPanels()
	else
		self.pPanel:SetVisible(true)
		self.pPanel:MakePopup()
	end

	self.chatTab.pGrLab:SetTextColor(colors.highlightOne)
	self.chatTab.pGrLab:SetText(qchat.isTeamChat and "(TEAM)" or "(GLOBAL)")
	self.chatTab.pText:SetText("")

	self.chatTab.pText:RequestFocus()

	gamemode.Call("StartChat")
end

function qchat:BuildIfNotExist()
	if not self.pPanel or not ValidPanel(self.pPanel) then
		self:BuildPanels()
		self.pPanel:SetVisible(false)
	end
end

-- Some of the link code is from EPOE.
local function CheckFor(tbl, a, b)
	local a_len = #a
	local res, endpos = true, 1

	while res and endpos < a_len do
		res, endpos = a:find(b, endpos)

		if res then
			tbl[#tbl + 1] = {res, endpos}
		end
	end
end

local function AppendTextLink(a, callback)
	local result = {}

	CheckFor(result, a, "https?://[^%s%\"]+")
	CheckFor(result, a, "ftp://[^%s%\"]+")
	CheckFor(result, a, "steam://[^%s%\"]+")

	if #result == 0 then return false end

	table.sort(result, function(a, b) return a[1] < b[1] end)

	-- Fix overlaps
	local _l, _r
	for k, tbl in ipairs(result) do
		local l, r = tbl[1], tbl[2]

		if not _l then
			_l, _r = tbl[1], tbl[2]
			continue
		end

		if l < _r then table.remove(result, k) end

		_l, _r = tbl[1], tbl[2]
	end

	local function TEX(str) callback(false, str) end
	local function LNK(str) callback(true, str) end

	local offset = 1
	local right

	for _, tbl in ipairs(result) do
		local l, r = tbl[1], tbl[2]
		local link = a:sub(l, r)
		local left = a:sub(offset, l - 1)
		right = a:sub(r + 1, -1)
		offset = r + 1

		TEX(left)
		LNK(link)
	end

	TEX(right)

	return true
end

function qchat:AppendText(txt)
	local function linkAppend(islink, text)
		if islink then
			self.chatTab.pFeed:InsertClickableTextStart(text)
				self.chatTab.pFeed:AppendText(text)
			self.chatTab.pFeed:InsertClickableTextEnd()
		return end

		self.chatTab.pFeed:AppendText(text)
	end

	local res = AppendTextLink(txt, linkAppend)

	if not res then
		self.chatTab.pFeed:AppendText(txt)
	end
end

ParseChatHudTags = ParseChatHudTags or function(a) return a end
function qchat:ParseChatLine(tbl)
	self:BuildIfNotExist()

	if isstring(tbl) then
		self.chatTab.pFeed:InsertColorChange(120, 240, 140, 255)

		self.chatTab.pFeed:AppendText(ParseChatHudTags(tbl))
		self.chatTab.pFeed:AppendText("\n")
	return end

	for i, v in pairs(tbl) do
		if IsColor(v) or istable(v) then
			self.chatTab.pFeed:InsertColorChange(v.r, v.g, v.b, 255)
		elseif isentity(v) and v:IsPlayer() then
			local col = GAMEMODE:GetTeamColor(v)
			self.chatTab.pFeed:InsertColorChange(col.r, col.g, col.b, 255)

			self.chatTab.pFeed:AppendText(ParseChatHudTags(v:Nick()))
		elseif v ~= nil then
			self:AppendText(ParseChatHudTags(tostring(v)))
		end
	end

	self.chatTab.pFeed:AppendText("\n")
end

function qchat.ChatBind(ply, bind)
	local isTeamChat = false

	if bind == "messagemode2" then
		isTeamChat = true
	elseif bind ~= "messagemode" then return end

	qchat.isTeamChat = isTeamChat
	qchat:SetUpChat()

	return true
end
hook.Add("PlayerBindPress", "qchat.ChatBind", qchat.ChatBind)

function qchat.PreRenderEscape()
	if gui.IsGameUIVisible() and qchat.pPanel and ValidPanel(qchat.pPanel) and qchat.pPanel:IsVisible() then
		if input.IsKeyDown(KEY_ESCAPE) then
			gui.HideGameUI()

			qchat:Close()
		elseif gui.IsConsoleVisible() then
			qchat:Close()
		end
	end
end
hook.Add("PreRender", "qchat.PreRenderEscape", qchat.PreRenderEscape)

function qchat:Close()
	self.pPanel:SetVisible(false)
	self.chatTab.pText.HistoryPos = 0

	gamemode.Call("FinishChat")
	self:SaveCookies()
end

if not chathud then

_G.oldAddText = _G.oldAddText or _G.chat.AddText
function chat.AddText(...)
	qchat:ParseChatLine({...})

	_G.oldAddText(...)
end

end

_G.oldGetChatBoxPos = _G.oldGetChatBoxPos or _G.chat.GetChatBoxPos
function chat.GetChatBoxPos()
	qchat:BuildIfNotExist()

	return qchat.pPanel:GetPos()
end

_G.oldGetChatBoxSize = _G.oldGetChatBoxSize or _G.chat.GetChatBoxSize
function chat.GetChatBoxSize()
	qchat:BuildIfNotExist()

	return qchat.pPanel:GetSize()
end

_G.oldChatOpen = _G.oldChatOpen or _G.chat.Open
function chat.Open(mode)
	local isTeam = mode and mode ~= 1
	qchat.isTeamChat = isTeam

	qchat:SetUpChat()
end

_G.oldChatClose = _G.oldChatClose or _G.chat.Close
function chat.Close()
	qchat:Close()
end

if chatsounds then
	local f = function()
		if chatsounds.ac.visible() then
			local x, y, w, h

			if chatgui then
				x, y = chatgui:GetPos()
				w, h = chatgui:GetSize()
				y, h = y + h, surface.ScreenHeight() - y - h
			else
				x, y = chat.GetChatBoxPos()
				w, h = chat.GetChatBoxSize()
				y, h = y + h, surface.ScreenHeight() - y - h
			end

			chatsounds.ac.render(x, y, w, h)
		end
	end

	hook.Add("PostRenderVGUI", "chatsounds_autocomplete", f)
end