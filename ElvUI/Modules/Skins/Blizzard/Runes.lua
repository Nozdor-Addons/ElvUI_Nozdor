local E, L, V, P, G = unpack(select(2, ...))
local S = E:GetModule('Skins')

local _G = _G
local type = type
local unpack = unpack
local pairs = pairs


S:AddCallbackForAddon('Blizzard_TalentUI', 'Runes_UlduarSecrets_AlwaysSkin_PerButton', function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.talent then return end

	-- Pin the rune window to a fixed size instead of snapshotting the current
	-- (non-rune) talent size. With override=false the snapshot captures whatever
	-- the talent view happens to be — and on a dual-spec character ElvUI's
	-- talent-frame width offset inflates that, so the forced rune host comes out
	-- wide and the circle stretches into an oval. Force the tuned size so the
	-- circle stays round regardless of spec count / offset state.
	local PTF_SIZE = {
		override = true,
		width  = 584,
		height = 652,
	}

	local RUNEHOST = {
		left   = 11,
		top    = 12,
		right  = 32,
		bottom = 76,
		x = 0,
		y = -20,
	}

	local ULD = {

		mode  = 'scale',
		scale = 0.90,

		width  = 520,
		height = 520,

		point    = 'CENTER',
		relPoint = 'CENTER',
		x = 0,
		y = 0,
	}

	local ULD_SKIN = {
		template    = 'Transparent',
		borderColor = { 0, 0, 0, 0.90 },
		inset       = 0,

		fill = {
			enabled = false,
			texture = 'Interface\\Buttons\\WHITE8X8',
			color   = { 0.05, 0.05, 0.05 },
			alpha   = 0.35,
		},
	}

	local RUNE_BUTTONS = {

		[1] = { x = 0, y = -17, scale = 1.33 },
		[2] = { x = -11, y = -21, scale = 1.33 },
		[3] = { x = -15, y = -31, scale = 1.33 },
		[4] = { x = -11, y = -43, scale = 1.33 },
		[5] = { x = 0, y = -45, scale = 1.33 },
		[6] = { x = 10, y = -43, scale = 1.33 },
		[7] = { x = 11, y = -30, scale = 1.33 },
		[8] = { x = 10, y = -21, scale = 1.33 },

	}

	local NUM_BUTTONS = 8

	local noop = E.noop or function() end

	local function NextFrame(func)
		local f = CreateFrame('Frame')
		f:SetScript('OnUpdate', function(self)
			self:SetScript('OnUpdate', nil)
			self:Hide()
			func()
		end)
	end

	local function GetPTF() return _G.PlayerTalentFrame end
	local function GetRuneHost() return _G.PlayerTalentFrameRuneHost end
	local function GetUld() return _G.UlduarSecretsFrame end

	local function SaveAndHidePTF()
		local ptf = GetPTF()
		if not ptf or ptf.__ElvUI_RunesPTFHidden then return end

		ptf.__ElvUI_RunesPTFHidden = true
		ptf.__ElvUI_RunesPTFSaved = ptf.__ElvUI_RunesPTFSaved or { regions = {} }
		local saved = ptf.__ElvUI_RunesPTFSaved

		if ptf.backdrop then
			if not saved.backdrop then
				saved.backdrop = {
					frame = ptf.backdrop,
					alpha = (ptf.backdrop.GetAlpha and ptf.backdrop:GetAlpha()) or 1,
					shown = (ptf.backdrop.IsShown and ptf.backdrop:IsShown()) or false,
					Show  = ptf.backdrop.Show,
					SetAlpha = ptf.backdrop.SetAlpha,
					bg = (ptf.backdrop.GetBackdropColor and { ptf.backdrop:GetBackdropColor() }) or nil,
					border = (ptf.backdrop.GetBackdropBorderColor and { ptf.backdrop:GetBackdropBorderColor() }) or nil,
					SetBackdropColor = ptf.backdrop.SetBackdropColor,
					SetBackdropBorderColor = ptf.backdrop.SetBackdropBorderColor,
				}
			end

			if ptf.backdrop.SetBackdropColor then ptf.backdrop:SetBackdropColor(0,0,0,0) end
			if ptf.backdrop.SetBackdropBorderColor then ptf.backdrop:SetBackdropBorderColor(0,0,0,0) end
			if ptf.backdrop.SetAlpha then ptf.backdrop:SetAlpha(0) end
			if ptf.backdrop.Hide then ptf.backdrop:Hide() end

			ptf.backdrop.Show = noop
			ptf.backdrop.SetAlpha = noop
			if ptf.backdrop.SetBackdropColor then ptf.backdrop.SetBackdropColor = noop end
			if ptf.backdrop.SetBackdropBorderColor then ptf.backdrop.SetBackdropBorderColor = noop end
		end

		if ptf.GetRegions then
			local regions = { ptf:GetRegions() }
			for i = 1, #regions do
				local r = regions[i]
				if r and r.GetObjectType and r:GetObjectType() == 'Texture' then
					if not saved.regions[r] then
						saved.regions[r] = {
							alpha = (r.GetAlpha and r:GetAlpha()) or 1,
							shown = (r.IsShown and r:IsShown()) or false,
							Show  = r.Show,
							SetAlpha = r.SetAlpha,
						}
					end
					if r.SetAlpha then r:SetAlpha(0) end
					if r.Hide then r:Hide() end
					r.Show = noop
					r.SetAlpha = noop
				end
			end
		end
	end

	local function RestorePTF()
		local ptf = GetPTF()
		if not ptf or not ptf.__ElvUI_RunesPTFHidden then return end

		ptf.__ElvUI_RunesPTFHidden = nil
		local saved = ptf.__ElvUI_RunesPTFSaved
		if not saved then return end

		if saved.backdrop and saved.backdrop.frame then
			local bd = saved.backdrop.frame
			if saved.backdrop.Show then bd.Show = saved.backdrop.Show end
			if saved.backdrop.SetAlpha then bd.SetAlpha = saved.backdrop.SetAlpha end
			if saved.backdrop.SetBackdropColor and bd.SetBackdropColor then bd.SetBackdropColor = saved.backdrop.SetBackdropColor end
			if saved.backdrop.SetBackdropBorderColor and bd.SetBackdropBorderColor then bd.SetBackdropBorderColor = saved.backdrop.SetBackdropBorderColor end
			if saved.backdrop.bg and bd.SetBackdropColor then bd:SetBackdropColor(unpack(saved.backdrop.bg)) end
			if saved.backdrop.border and bd.SetBackdropBorderColor then bd:SetBackdropBorderColor(unpack(saved.backdrop.border)) end
			if bd.SetAlpha then bd:SetAlpha(saved.backdrop.alpha or 1) end
			if saved.backdrop.shown and bd.Show then bd:Show() end
		end

		if saved.regions then
			for tex, st in pairs(saved.regions) do
				if tex and st then
					if st.Show then tex.Show = st.Show end
					if st.SetAlpha then tex.SetAlpha = st.SetAlpha end
					if tex.SetAlpha then tex:SetAlpha(st.alpha or 1) end
					if st.shown and tex.Show then tex:Show() elseif tex.Hide then tex:Hide() end
				end
			end
		end
	end

	local function SnapshotNormalPTFSize()
		local ptf = GetPTF()
		if not ptf then return end
		local w, h = ptf:GetSize()
		if w and h and w > 0 and h > 0 then
			ptf.__ElvUI_RunesNormalSize = { w, h }
		end
	end

	local function ForcePTFSizeForRunes()
		local ptf = GetPTF()
		if not ptf then return end

		local w, h
		if PTF_SIZE.override then
			w, h = PTF_SIZE.width, PTF_SIZE.height
		elseif ptf.__ElvUI_RunesNormalSize then
			w, h = ptf.__ElvUI_RunesNormalSize[1], ptf.__ElvUI_RunesNormalSize[2]
		end

		if not (w and h and w > 0 and h > 0) then return end

		ptf:SetSize(w, h)
		if UIPanelWindows and UIPanelWindows.PlayerTalentFrame then
			UIPanelWindows.PlayerTalentFrame.width = w
			UIPanelWindows.PlayerTalentFrame.height = h
		end
		if UpdateUIPanelPositions then UpdateUIPanelPositions() end
	end

	local function ReanchorRuneHost()
		local ptf = GetPTF()
		local host = GetRuneHost()
		if not ptf or not host then return end
		if not (host.IsShown and host:IsShown()) then return end

		host:ClearAllPoints()
		host:SetPoint('TOPLEFT', ptf, 'TOPLEFT', (RUNEHOST.left or 11) + (RUNEHOST.x or 0), -((RUNEHOST.top or 12)) + (RUNEHOST.y or 0))
		host:SetPoint('BOTTOMRIGHT', ptf, 'BOTTOMRIGHT', -((RUNEHOST.right or 32)) + (RUNEHOST.x or 0), (RUNEHOST.bottom or 76) + (RUNEHOST.y or 0))
	end

	local function FindUldCloseButton(uld)
		if not uld then return nil end
		local name = uld.GetName and uld:GetName()
		if name and _G[name..'CloseButton'] then return _G[name..'CloseButton'] end
		if _G.UlduarSecretsFrameCloseButton then return _G.UlduarSecretsFrameCloseButton end
		if uld.CloseButton then return uld.CloseButton end
		if uld.closeButton then return uld.closeButton end
		return nil
	end

	local function IsBlizzardBorderTexture(tex)
		if not tex or not tex.GetTexture then return false end
		local t = tex:GetTexture()
		if type(t) ~= 'string' then return false end
		t = t:lower()

		if t:find([[interface\tooltips\ui%-tooltip%-border]]) then return true end
		if t:find([[interface\tooltips\ui%-tooltip%-background]]) then return true end
		if t:find([[interface\framegeneral\ui%-dialogbox]]) then return true end
		if t:find([[interface\framegeneral\ui%-dialogbox%-header]]) then return true end
		if t:find([[interface\framegeneral\ui%-panel]]) then return true end
		if t:find([[interface\uiframe\]]) then return true end
		if t:find([[interface\characterframe\ui%-]]) then return true end
		if t:find([[interface\common\ui%-]]) then return true end
		if t:find([[interface\glues\common\]]) then return true end

		return false
	end

	local function HideUldBorderTextures(uld)
		if not uld or uld.__ElvUI_UldBorderHidden then return end
		if not uld.GetRegions then return end

		uld.__ElvUI_UldBorderHidden = true

		local hw, hh = (uld.GetWidth and uld:GetWidth()) or 0, (uld.GetHeight and uld:GetHeight()) or 0
		local regions = { uld:GetRegions() }

		for i = 1, #regions do
			local r = regions[i]
			if r and r.GetObjectType and r:GetObjectType() == 'Texture' and r.GetDrawLayer then
				local layer = r:GetDrawLayer()
				local kill = (layer == 'BORDER' or layer == 'OVERLAY')

				if not kill and (layer == 'ARTWORK' or layer == 'BACKGROUND') and IsBlizzardBorderTexture(r) and hw > 0 and hh > 0 and r.GetWidth and r.GetHeight then
					local w, h = r:GetWidth() or 0, r:GetHeight() or 0
					local thin = (h > 0 and h <= 64) or (w > 0 and w <= 64) or (w > 0 and w <= hw * 0.18) or (h > 0 and h <= hh * 0.18)
					if thin then
						kill = true
					end
				end

				if kill then
					if r.SetAlpha then r:SetAlpha(0) end
					if r.Hide then r:Hide() end
					r.Show = noop
					r.SetAlpha = noop
				end
			end
		end
	end

	local function EnsureUldBorder(uld)
		if not uld then return end
		if uld.__ElvUI_UldBorder then return end

		HideUldBorderTextures(uld)

		local b = CreateFrame('Frame', nil, uld)
		b:EnableMouse(false)
		b:SetFrameStrata(uld:GetFrameStrata() or 'MEDIUM')

		local lvl = uld:GetFrameLevel() or 1
		b:SetFrameLevel(lvl + 10)

		b:CreateBackdrop(ULD_SKIN.template or 'Transparent')
		b.__Fill = b:CreateTexture(nil, 'BACKGROUND', nil, -8)

		uld.__ElvUI_UldBorder = b

		local close = FindUldCloseButton(uld)
		if close and not close.__ElvUI_UldCloseSkinned then
			S:HandleCloseButton(close)
			close.__ElvUI_UldCloseSkinned = true
		end
	end

	local function UpdateUldBorder(uld)
		if not uld then return end
		EnsureUldBorder(uld)

		local close = FindUldCloseButton(uld)
		if close and not close.__ElvUI_UldCloseSkinned then
			S:HandleCloseButton(close)
			close.__ElvUI_UldCloseSkinned = true
		end

		local b = uld.__ElvUI_UldBorder
		if not b then return end

		local inset = ULD_SKIN.inset or 0
		b:ClearAllPoints()
		b:SetPoint('TOPLEFT', uld, 'TOPLEFT', inset, -inset)
		b:SetPoint('BOTTOMRIGHT', uld, 'BOTTOMRIGHT', -inset, inset)

		if b.backdrop and b.backdrop.SetBackdropBorderColor then
			local bc = ULD_SKIN.borderColor or {0,0,0,0.9}
			b.backdrop:SetBackdropBorderColor(bc[1] or 0, bc[2] or 0, bc[3] or 0, bc[4] or 0.9)
		end

		if ULD_SKIN.fill and ULD_SKIN.fill.enabled then
			local f = ULD_SKIN.fill
			b.__Fill:SetAllPoints(b)
			b.__Fill:SetTexture(f.texture or 'Interface\\Buttons\\WHITE8X8')
			local col = f.color or {0,0,0}
			b.__Fill:SetVertexColor(col[1] or 0, col[2] or 0, col[3] or 0)
			b.__Fill:SetAlpha(f.alpha or 0.35)
			b.__Fill:Show()
		else
			b.__Fill:Hide()
		end

		b:Show()
	end

	local function ApplyButton(i, uld)
		local b = _G['UlduarSecretsFrameBrightRunes'..i]
		if not b then return end

		local cfg = RUNE_BUTTONS[i] or {}
		local scale = (b.GetScale and b:GetScale()) or 1

		if not b.__ElvUI_SavedPoints then
			b.__ElvUI_SavedPoints = {}
			if b.GetNumPoints and b.GetPoint then
				local n = b:GetNumPoints()
				for p = 1, n do
					local point, rel, relPoint, xOfs, yOfs = b:GetPoint(p)
					b.__ElvUI_SavedPoints[p] = { point, rel, relPoint, xOfs, yOfs }
				end
			end
		end

		if cfg.width and cfg.height and b.SetSize then
			b:SetSize(cfg.width, cfg.height)
		end
		if cfg.scale and b.SetScale then
			b:SetScale(cfg.scale)
			scale = cfg.scale
		end

		if cfg.useAbsolute and b.SetPoint then
			b:ClearAllPoints()
			local pt = cfg.point or 'CENTER'
			local rpt = cfg.relPoint or pt
			b:SetPoint(pt, uld, rpt, cfg.x or 0, cfg.y or 0)
		else
			local dx = cfg.x or 0
			local dy = cfg.y or 0

			local s = (uld and uld.GetScale and uld:GetScale()) or 1
			if s and s > 0 then
				dx = dx / s
				dy = dy / s
			end

			b:ClearAllPoints()
			for _, t in pairs(b.__ElvUI_SavedPoints) do
				if t and t[1] then
					b:SetPoint(t[1], t[2], t[3], (t[4] or 0) + dx, (t[5] or 0) + dy)
				end
			end
		end

		local lvl = (uld and uld.GetFrameLevel and uld:GetFrameLevel()) or 1
		if b.SetFrameStrata and uld and uld.GetFrameStrata then
			b:SetFrameStrata(uld:GetFrameStrata())
		end
		if b.SetFrameLevel then
			b:SetFrameLevel(lvl + 30)
		end
	end

	local function ApplyAllButtons(uld)
		for i = 1, NUM_BUTTONS do
			ApplyButton(i, uld)
		end
	end

	local function ApplyUldLayout()
		local uld = GetUld()
		local host = GetRuneHost()
		if not uld or not host then return end

		uld:ClearAllPoints()
		uld:SetPoint(ULD.point or 'CENTER', host, ULD.relPoint or 'CENTER', ULD.x or 0, ULD.y or 0)

		if ULD.mode == 'size' and uld.SetSize then
			if ULD.width and ULD.height then
				uld:SetSize(ULD.width, ULD.height)
			end
		end
		if uld.SetScale and ULD.scale then
			uld:SetScale(ULD.scale)
		end

		UpdateUldBorder(uld)
		ApplyAllButtons(uld)
	end

	local function IsRunesShown()
		local host = GetRuneHost()
		return host and host.IsShown and host:IsShown()
	end

	local function UpdateState()
		if IsRunesShown() then
			SaveAndHidePTF()
			ForcePTFSizeForRunes()
			ReanchorRuneHost()
			ApplyUldLayout()

			NextFrame(function()
				if IsRunesShown() then
					ForcePTFSizeForRunes()
					ReanchorRuneHost()
					ApplyUldLayout()
				end
			end)
		else
			local uld = GetUld()
			if uld and uld.__ElvUI_UldBorder then
				uld.__ElvUI_UldBorder:Hide()
			end
			RestorePTF()
			NextFrame(SnapshotNormalPTFSize)
		end
	end

	hooksecurefunc('PanelTemplates_SetTab', function(frame)
		if frame == _G.PlayerTalentFrame then
			NextFrame(UpdateState)
		end
	end)

	local ptf = GetPTF()
	if ptf and ptf.HookScript then
		ptf:HookScript('OnShow', function()
			NextFrame(function()
				SnapshotNormalPTFSize()
				UpdateState()
			end)
		end)
		ptf:HookScript('OnHide', function()
			local uld = GetUld()
			if uld and uld.__ElvUI_UldBorder then uld.__ElvUI_UldBorder:Hide() end
			RestorePTF()
		end)
	end

	NextFrame(function()
		SnapshotNormalPTFSize()
		UpdateState()
	end)
end)
