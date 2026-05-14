local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local DT = E:GetModule("DataTexts")

--Lua functions
local collectgarbage = collectgarbage
local floor = math.floor
local format = string.format
local tinsert, sort = table.insert, table.sort
--WoW API / Variables
local CopyTable = CopyTable
local GetAddOnCPUUsage = GetAddOnCPUUsage
local GetAddOnInfo = GetAddOnInfo
local GetAddOnMemoryUsage = GetAddOnMemoryUsage
local GetCVar = GetCVar
local GetFramerate = GetFramerate
local GetNetStats = GetNetStats
local GetNumAddOns = GetNumAddOns
local HideUIPanel = HideUIPanel
local IsAddOnLoaded = IsAddOnLoaded
local IsModifierKeyDown = IsModifierKeyDown
local IsShiftKeyDown = IsShiftKeyDown
local PlaySound = PlaySound
local ResetCPUUsage = ResetCPUUsage
local ShowUIPanel = ShowUIPanel
local UpdateAddOnCPUUsage = UpdateAddOnCPUUsage
local UpdateAddOnMemoryUsage = UpdateAddOnMemoryUsage

local cpuProfiling = GetCVar("scriptProfile") == "1"
local int = 5 -- initial delay
local statusColors = {
	"|cff0CD809",
	"|cffE8DA0F",
	"|cffFF9000",
	"|cffD80909"
}

local enteredFrame
local homeLatencyString = "%d ms"
local kiloByteString = "%d kb"
local megaByteString = "%.2f mb"
local system_display_latency = "LATENCY"
local system_display_memory = "MEMORY"

local memoryTable = {}
local cpuTable = {}
local lodTable = {}
local disabledTable = {}
local initialized

local function OnEvent(self, event, addonName)
	if event == "ADDON_LOADED" then
		if lodTable[addonName] then
			tinsert(memoryTable, lodTable[addonName])

			if cpuProfiling then
				tinsert(cpuTable, CopyTable(lodTable[addonName]))
			end

			lodTable[addonName] = nil
		elseif disabledTable[addonName] then
			tinsert(memoryTable, disabledTable[addonName])

			if cpuProfiling then
				tinsert(cpuTable, CopyTable(disabledTable[addonName]))
			end

			disabledTable[addonName] = nil
		end
	elseif not initialized and (event == "PLAYER_ENTERING_WORLD" or event == "ELVUI_FORCE_RUN") then
		local _, name, title, enabled, loadable

		for i = 1, GetNumAddOns() do
			name, title, _, enabled, loadable = GetAddOnInfo(i)

			if IsAddOnLoaded(i) then
				tinsert(memoryTable, {i, title, 0})

				if cpuProfiling then
					tinsert(cpuTable, {i, title, 0})
				end
			elseif loadable then
				lodTable[name] = {i, title, 0}
			elseif not enabled then
				disabledTable[name] = {i, title, 0}
			end
		end

		initialized = true
		self:UnregisterEvent(event)
	elseif initialized and event == "ELVUI_FORCE_RUN" then
		local name

		for i = 1, GetNumAddOns() do
			name = GetAddOnInfo(i)

			if (lodTable[name] or disabledTable[name]) and IsAddOnLoaded(i) then
				OnEvent(self, "ADDON_LOADED", name)
			end
		end
	end
end

local function formatMem(memory)
	if memory > 999 then
		return format(megaByteString, memory / 1024)
	else
		return format(kiloByteString, memory)
	end
end

local function sortByMemoryOrCPU(a, b)
	if a and b then
		return (a[3] == b[3] and a[2] < b[2]) or a[3] > b[3]
	end
end

local function UpdateMemory()
	UpdateAddOnMemoryUsage()

	local totalMemory = 0
	for i = 1, #memoryTable do
		memoryTable[i][3] = GetAddOnMemoryUsage(memoryTable[i][1])
		totalMemory = totalMemory + memoryTable[i][3]
	end

	sort(memoryTable, sortByMemoryOrCPU)

	return totalMemory
end

local function UpdateCPU()
	UpdateAddOnCPUUsage()

	local totalCPU = 0
	for i = 1, #cpuTable do
		cpuTable[i][3] = GetAddOnCPUUsage(cpuTable[i][1])
		totalCPU = totalCPU + cpuTable[i][3]
	end

	sort(cpuTable, sortByMemoryOrCPU)

	return totalCPU
end

local function ToggleGameMenuFrame()
	if GameMenuFrame:IsShown() then
		PlaySound("igMainMenuQuit")
		HideUIPanel(GameMenuFrame)
	else
		PlaySound("igMainMenuOpen")
		ShowUIPanel(GameMenuFrame)
	end
end

--- @brief Возвращает цветовую escape-строку для текущего FPS.
--- @param framerate number Текущее количество кадров в секунду.
--- @return string Цветовая escape-строка для значения FPS.
local function get_framerate_color(framerate)
	return statusColors[framerate >= 30 and 1 or (framerate >= 20 and framerate < 30) and 2 or (framerate >= 10 and framerate < 20) and 3 or 4]
end

--- @brief Возвращает цветовую escape-строку для текущей задержки.
--- @param latency number Текущая домашняя задержка в миллисекундах.
--- @return string Цветовая escape-строка для значения задержки.
local function get_latency_color(latency)
	return statusColors[latency < 150 and 1 or (latency >= 150 and latency < 300) and 2 or (latency >= 300 and latency < 500) and 3 or 4]
end

--- @brief Обновляет основной текст системного дататекста согласно выбранному режиму отображения.
--- @param self frame Панель дататекста, текст которой нужно обновить.
--- @return nil
local function update_system_text(self)
	local framerate = floor(GetFramerate() + 0.5)
	local system_display = E.db.datatexts.system_display or system_display_latency

	if system_display == system_display_memory then
		self.text:SetFormattedText("FPS: %s%d|r MEM: %s", get_framerate_color(framerate), framerate, formatMem(UpdateMemory()))
	else
		local _, _, homeLatency = GetNetStats()

		self.text:SetFormattedText("FPS: %s%d|r MS: %s%d|r",
			get_framerate_color(framerate),
			framerate,
			get_latency_color(homeLatency),
			homeLatency)
	end
end

--- @brief Возвращает режим отображения списка аддонов в подсказке с учётом Shift.
--- @return string Режим отображения: LATENCY или MEMORY.
local function get_tooltip_display()
	local tooltip_display = E.db.datatexts.system_tooltip_display or system_display_latency

	if not cpuProfiling then
		return system_display_memory
	elseif IsShiftKeyDown() then
		return tooltip_display == system_display_memory and system_display_latency or system_display_memory
	else
		return tooltip_display
	end
end

--- @brief Добавляет в подсказку список аддонов с использованием памяти.
--- @param total_memory number Суммарное использование памяти всеми отслеживаемыми аддонами.
--- @return nil
local function add_memory_tooltip_lines(total_memory)
	local addon, red, green
	local color_total = total_memory > 0 and total_memory or 1

	for i = 1, #memoryTable do
		addon = memoryTable[i]
		red = addon[3] / color_total
		green = 1 - red
		DT.tooltip:AddDoubleLine(addon[2], formatMem(addon[3]), 1, 1, 1, red, green + .5, 0)
	end
end

--- @brief Добавляет в подсказку список аддонов с временем выполнения.
--- @param total_cpu number Суммарное время выполнения всех отслеживаемых аддонов.
--- @return nil
local function add_latency_tooltip_lines(total_cpu)
	local addon, red, green
	local color_total = total_cpu > 0 and total_cpu or 1

	for i = 1, #cpuTable do
		addon = cpuTable[i]
		red = addon[3] / color_total
		green = 1 - red
		DT.tooltip:AddDoubleLine(addon[2], format(homeLatencyString, addon[3]), 1, 1, 1, red, green + .5, 0)
	end
end

local function OnClick(_, btn)
	if IsModifierKeyDown() then
		collectgarbage("collect")
		ResetCPUUsage()
	elseif btn == "LeftButton" then
		ToggleGameMenuFrame()
	end
end

local function OnEnter(self)
	DT:SetupTooltip(self)

	local totalMemory = UpdateMemory()
	local _, _, homeLatency = GetNetStats()

	DT.tooltip:AddDoubleLine(L["Home Latency:"], format(homeLatencyString, homeLatency), 0.69, 0.31, 0.31, 0.84, 0.75, 0.65)
	DT.tooltip:AddDoubleLine(L["Total Memory:"], formatMem(totalMemory), 0.69, 0.31, 0.31, 0.84, 0.75, 0.65)

	local totalCPU
	if cpuProfiling then
		totalCPU = UpdateCPU()
		DT.tooltip:AddDoubleLine(L["Total CPU:"], format(homeLatencyString, totalCPU), 0.69, 0.31, 0.31, 0.84, 0.75, 0.65)
	end

	DT.tooltip:AddLine(" ")

	if get_tooltip_display() == system_display_memory then
		add_memory_tooltip_lines(totalMemory)
	else
		add_latency_tooltip_lines(totalCPU)
	end

	DT.tooltip:AddLine(L["(Modifer Click) Collect Garbage"])
	DT.tooltip:Show()
	enteredFrame = true
end

local function OnLeave()
	enteredFrame = nil
	DT.tooltip:Hide()
end

local function OnUpdate(self, t)
	int = int - t

	if int < 0 then
		update_system_text(self)
		int = 1

		if enteredFrame then
			OnEnter(self)
		end
	end
end

DT:RegisterDatatext("System", {"PLAYER_ENTERING_WORLD", "ADDON_LOADED"}, OnEvent, OnUpdate, OnClick, OnEnter, OnLeave, L["System"])
