--!nocheck
--[[
	Blossom UI Library (single file)

	local Blossom = loadstring(readfile("Blossom.luau"))()      -- executor
	local Blossom = require(path.to.Blossom)                    -- Studio

	local Window = Blossom.new({ Title = "Blossom", Script = "blossom.lua", Build = "operation one" })
	Window:Category("Combat")
	local Rage = Window:Tab({ Name = "Rage", Icon = "target" })
	local Main = Rage:Section({ Name = "Main", Icon = "robot", Side = 1 })
	Main:Toggle({ Name = "Enabled", Default = true, Keybind = Enum.KeyCode.C, Callback = print })

	Elements: Toggle, Slider, RangeSlider, Dropdown, Colorpicker, Keybind, Button,
	          Textbox, Label, Divider, Listbox.
	Toggle and Label also accept Keybind = and Color = for inline controls.
	Every element returns an object with .Value and :Set(value, silent).

	Confirm:    Section:Button({ Name = "Unload", Confirm = true, Callback = ... }) - first click turns the label into "Are you sure?".
	Sub-tabs:   local Players = Tab:SubTab({ Name = "Players" }); Players:Section({ Name = "ESP", Side = 1 })
	Gear:       local t = Section:Toggle({ Name = "Enabled", Gear = true }); t.Gear:Slider({ Name = "Hit Chance", ... })
	Obsidian style: Window:AddTab, Tab:AddGroupbox, Groupbox:AddToggle("Index", { Text = ... }), Window.Toggles / Window.Options
	            (also Blossom.Toggles / Blossom.Options), object:OnChanged(fn), object:SetValue(v), Window:OnUnload(fn).

	Icons:      Lucide icon names from lucide.dev/icons: Icon = "target", "bot", "settings", "swords".
	            Downloaded from GitHub on first use and cached in Blossom/icons. Blossom.AddIcon(name, svg) adds your own.
	            Blossom.new options: IconBase (another URL folder with <name>.svg), IconStroke (default 2).

	Hotkey list: lists every bind (also unassigned ones). Blossom.new options HotkeyOnlyAssigned = true (hide binds without a key)
	and HotkeyOnlyEnabled = true (show only binds that are on). Both can be changed in Menu > Hotkey List > gear,
	or from code: Window:SetHotkeyFilter(onlyAssigned, onlyEnabled).

	Options for Blossom.new: Title, Script, Build, Theme, MenuKey, Font (a font family string),
	Size and MinSize (Vector2), Resizable (default true). Window:SetSize(width, height) resizes from code.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local INTER = "rbxassetid://12187365364"
local Vec2, Dim2 = Vector2.new, UDim2.new
local Offset = UDim2.fromOffset
local RGB = Color3.fromRGB
local floor, round, abs = math.floor, math.round, math.abs
local FULL = 99

-- Spacing rule: Pad around every surface, Gap between stacked items. Sizes are even so centring stays on whole pixels.
local Metrics = {
	Pad = 10, Gap = 6, SectionGap = 10,
	Radius = 3, SmallRadius = 2, CardRadius = 4, PillRadius = 5, PopupRadius = 5, FloatRadius = 6, WindowRadius = 6,
	WindowW = 586, WindowH = 466, MinWindowW = 520, MinWindowH = 380, SidebarW = 141, ContentX = 142, ColumnW = 207,
	TabW = 121, TabH = 28, TabPitch = 32, CategoryToTab = 25, TabToCategory = 25, FirstCategory = 56, SearchH = 28,
	Row = 16, HeaderH = 24, HeaderDescH = 40,
	DividerH = 9, SliderH = 33, DropdownH = 47, InputH = 26, ButtonH = 28, ListRowH = 24,
	ToggleW = 28, ToggleH = 16, ToggleKnob = 10, Knob = 11, PickerKnob = 8, TrackH = 9, TrackY = 24, TrackInset = 5,
	ChipH = 16, ValueChipH = 17, Swatch = 14, ChipGap = 2,
}

local Themes = {
	Blossom = {
		Background = RGB(42, 44, 52), Tab = RGB(48, 50, 58), Outline = RGB(65, 68, 80), Inline = RGB(56, 58, 68),
		Text = RGB(232, 234, 245), InactiveText = RGB(126, 130, 148), Accent = RGB(113, 159, 226), Element = RGB(54, 57, 68),
		Gradient = RGB(172, 187, 209), Shadow = RGB(0, 0, 0), HoveredElement = RGB(72, 77, 90),
	},
	Afterglow = {
		Background = RGB(34, 28, 25), Tab = RGB(30, 23, 20), Outline = RGB(60, 46, 38), Inline = RGB(42, 33, 29),
		Text = RGB(240, 232, 226), InactiveText = RGB(140, 122, 110), Accent = RGB(255, 145, 60), Element = RGB(49, 34, 27),
		Gradient = RGB(172, 167, 163), Shadow = RGB(0, 0, 0), HoveredElement = RGB(70, 51, 42),
	},
	Frostbite = {
		Background = RGB(22, 30, 38), Tab = RGB(16, 25, 32), Outline = RGB(42, 58, 72), Inline = RGB(27, 38, 47),
		Text = RGB(228, 240, 248), InactiveText = RGB(114, 136, 152), Accent = RGB(86, 219, 255), Element = RGB(28, 39, 52),
		Gradient = RGB(164, 172, 178), Shadow = RGB(0, 0, 0), HoveredElement = RGB(44, 60, 74),
	},
	Volt = {
		Background = RGB(24, 24, 20), Tab = RGB(18, 18, 14), Outline = RGB(54, 54, 40), Inline = RGB(32, 32, 26),
		Text = RGB(242, 242, 226), InactiveText = RGB(134, 134, 112), Accent = RGB(255, 250, 76), Element = RGB(32, 32, 26),
		Gradient = RGB(170, 170, 158), Shadow = RGB(0, 0, 0), HoveredElement = RGB(58, 58, 44),
	},
	Obsidian = {
		Background = RGB(16, 16, 18), Tab = RGB(12, 11, 14), Outline = RGB(44, 42, 52), Inline = RGB(24, 24, 29),
		Text = RGB(234, 232, 244), InactiveText = RGB(118, 114, 134), Accent = RGB(159, 109, 255), Element = RGB(24, 23, 31),
		Gradient = RGB(166, 164, 175), Shadow = RGB(0, 0, 0), HoveredElement = RGB(236, 240, 248),
	},
	["Sakura Drift"] = {
		Background = RGB(38, 28, 34), Tab = RGB(32, 23, 29), Outline = RGB(70, 50, 62), Inline = RGB(48, 35, 43),
		Text = RGB(248, 234, 242), InactiveText = RGB(150, 122, 138), Accent = RGB(255, 155, 205), Element = RGB(44, 46, 48),
		Gradient = RGB(176, 166, 172), Shadow = RGB(0, 0, 0), HoveredElement = RGB(77, 53, 67),
	},
	["Neon Mirage"] = {
		Background = RGB(22, 16, 34), Tab = RGB(17, 12, 28), Outline = RGB(54, 40, 82), Inline = RGB(32, 23, 48),
		Text = RGB(238, 232, 252), InactiveText = RGB(128, 114, 160), Accent = RGB(255, 86, 255), Element = RGB(30, 21, 46),
		Gradient = RGB(144, 163, 182), Shadow = RGB(0, 0, 0), HoveredElement = RGB(56, 39, 84),
	},
	["Copper Dust"] = {
		Background = RGB(39, 30, 25), Tab = RGB(34, 25, 20), Outline = RGB(72, 54, 42), Inline = RGB(49, 36, 28),
		Text = RGB(244, 232, 220), InactiveText = RGB(148, 124, 104), Accent = RGB(243, 152, 86), Element = RGB(51, 34, 22),
		Gradient = RGB(173, 164, 155), Shadow = RGB(0, 0, 0), HoveredElement = RGB(77, 56, 42),
	},
	Abyss = {
		Background = RGB(12, 20, 28), Tab = RGB(8, 15, 22), Outline = RGB(30, 48, 62), Inline = RGB(18, 30, 40),
		Text = RGB(222, 236, 246), InactiveText = RGB(100, 128, 148), Accent = RGB(52, 176, 238), Element = RGB(16, 28, 38),
		Gradient = RGB(158, 169, 176), Shadow = RGB(0, 0, 0), HoveredElement = RGB(32, 51, 67),
	},
	Porcelain = {
		Background = RGB(250, 248, 244), Tab = RGB(236, 234, 230), Outline = RGB(214, 212, 208), Inline = RGB(255, 255, 255),
		Text = RGB(44, 46, 54), InactiveText = RGB(140, 142, 150), Accent = RGB(133, 176, 255), Element = RGB(255, 255, 255),
		Gradient = RGB(214, 218, 226), Shadow = RGB(120, 120, 120), HoveredElement = RGB(255, 255, 255),
	},
	Graphite = {
		Background = RGB(32, 30, 30), Tab = RGB(40, 40, 40), Outline = RGB(58, 60, 62), Inline = RGB(42, 45, 46),
		Text = RGB(236, 236, 250), InactiveText = RGB(128, 128, 134), Accent = RGB(105, 159, 237), Element = RGB(44, 46, 46),
		Gradient = RGB(190, 190, 190), Shadow = RGB(0, 0, 0), HoveredElement = RGB(67, 70, 72),
	},
}
local ThemeOrder = { "Blossom", "Afterglow", "Frostbite", "Volt", "Obsidian", "Sakura Drift", "Neon Mirage", "Copper Dust", "Abyss", "Porcelain", "Graphite" }
-- Built-in themes defined as JSON (same hex format as saved/exported theme files).
-- Blossom.AddThemeJSON(name, json) registers more; duplicates (same name or same colours) are skipped.
local BuiltInThemeJSON = {
	{ "Necro", [[
{
    "Background": "1c1824",
    "Tab": "16121d",
    "Outline": "3a304a",
    "Inline": "251f30",
    "Text": "ece8f4",
    "InactiveText": "827896",
    "Accent": "78d6a0",
    "Element": "221d2d",
    "Gradient": "a8a6b0",
    "Shadow": "000000",
    "HoveredElement": "383048"
}
]] },
	{ "Crypt", [[
{
    "Background": "181c22",
    "Tab": "12161c",
    "Outline": "303a46",
    "Inline": "1f252d",
    "Text": "e6ecf0",
    "InactiveText": "768492",
    "Accent": "68c4c8",
    "Element": "1c222a",
    "Gradient": "a4aab0",
    "Shadow": "000000",
    "HoveredElement": "2e3945"
}
]] },
	{ "Grave Moss", [[
{
    "Background": "181e1a",
    "Tab": "121814",
    "Outline": "2e3c32",
    "Inline": "1e2621",
    "Text": "e8f0e6",
    "InactiveText": "788a7a",
    "Accent": "9ed068",
    "Element": "1c241f",
    "Gradient": "a6aea6",
    "Shadow": "000000",
    "HoveredElement": "2e3c32"
}
]] },
	{ "Wraith", [[
{
    "Background": "1e1b28",
    "Tab": "181521",
    "Outline": "3e3856",
    "Inline": "282436",
    "Text": "eeeaf8",
    "InactiveText": "8880a2",
    "Accent": "ac8eec",
    "Element": "242032",
    "Gradient": "aaa8b4",
    "Shadow": "000000",
    "HoveredElement": "3c3652"
}
]] },
	{ "Blood Moon", [[
{
    "Background": "22181c",
    "Tab": "1c1216",
    "Outline": "442e36",
    "Inline": "2c1f24",
    "Text": "f4e8ea",
    "InactiveText": "92787e",
    "Accent": "de5c70",
    "Element": "281c21",
    "Gradient": "b0a6a8",
    "Shadow": "000000",
    "HoveredElement": "463038"
}
]] },
}

local function themeFromJSON(json)
	local ok, data = pcall(HttpService.JSONDecode, HttpService, json)
	if not ok or type(data) ~= "table" then return nil end
	local theme, found = table.clone(Themes.Blossom), 0
	for key, hex in data do
		if theme[key] ~= nil and type(hex) == "string" then
			local valid, color = pcall(Color3.fromHex, hex)
			if valid then theme[key], found = color, found + 1 end
		end
	end
	return found > 0 and theme or nil
end

local function sameTheme(a, b)
	for key, color in a do
		if b[key] ~= color then return false end
	end
	return true
end

-- Returns true when the theme was added; false for bad JSON, a taken name or a palette that already exists.
-- front = true puts it at the top of the Theme list.
local function addThemeJSON(name, json, front)
	if type(name) ~= "string" or name == "" or Themes[name] then return false end
	local theme = themeFromJSON(json)
	if not theme then return false end
	for _, existing in Themes do
		if sameTheme(theme, existing) then return false end
	end
	Themes[name] = theme
	table.insert(ThemeOrder, front and 1 or #ThemeOrder + 1, name)
	return true
end

for index = #BuiltInThemeJSON, 1, -1 do
	addThemeJSON(BuiltInThemeJSON[index][1], BuiltInThemeJSON[index][2], true)
end

-- Blood Moon is the default theme and sits at the top of the list.
do
	local index = table.find(ThemeOrder, "Blood Moon")
	if index then
		table.remove(ThemeOrder, index)
		table.insert(ThemeOrder, 1, "Blood Moon")
	end
end
local ThemeKeys = {
	{ "Background", "Background" }, { "Tab", "Tab" }, { "Outline", "Outline" }, { "Inline", "Inline" },
	{ "Text", "Text" }, { "Inactive Text", "InactiveText" }, { "Accent", "Accent" }, { "Element", "Element" },
	{ "Gradient", "Gradient" }, { "Shadow", "Shadow" }, { "Hovered Element", "HoveredElement" },
}
local Casings = { "Normal", "Lower Case", "Upper Case", "Bold Case" }
local Fonts = {
	Inter = INTER,
	["Builder Sans"] = "rbxasset://fonts/families/BuilderSans.json",
	Roboto = "rbxasset://fonts/families/Roboto.json",
	Montserrat = "rbxasset://fonts/families/Montserrat.json",
	["Source Sans Pro"] = "rbxasset://fonts/families/SourceSansPro.json",
	Ubuntu = "rbxasset://fonts/families/Ubuntu.json",
	Nunito = "rbxasset://fonts/families/Nunito.json",
	Arimo = "rbxasset://fonts/families/Arimo.json",
}
local FontOrder = { "Inter", "Builder Sans", "Roboto", "Montserrat", "Source Sans Pro", "Ubuntu", "Nunito", "Arimo" }
local WeightOrder = { "Regular", "Medium", "SemiBold", "Bold" }

local Current = table.clone(Themes["Blood Moon"] or Themes.Blossom)
local Casing = "Normal"
local FontFamily = INTER
local BodyWeight = Enum.FontWeight.SemiBold

local WatermarkOptions = { "Script", "Build", "Name", "FPS", "Ping", "Time", "Session" }
local WatermarkDefaults = { "Script", "Build", "Name", "FPS", "Ping" }

-------------------------------------------------------------------------------
-- Animator: one render-step loop driving springs. Retargeting keeps velocity,
-- so interrupted motion stays continuous, and it costs far less than TweenService.
-------------------------------------------------------------------------------

local Presets = {
	Fast = { W = 42, Z = 1 },      -- hover and colour feedback
	Knob = { W = 44, Z = 0.86 },   -- toggles and slider knobs
	Follow = { W = 34, Z = 1 },    -- things attached to the pointer
	Smooth = { W = 26, Z = 1 },    -- layout and popups
	Soft = { W = 19, Z = 1 },      -- page transitions, theme morphs
	Settle = { W = 24, Z = 0.8 },  -- small overshoot for reflow
}

local Active, Tracks, Jobs = {}, {}, {}
local EPS = { number = 0.0015, Color3 = 0.003, UDim2 = 0.4, Vector2 = 0.4 }

local function encode(v)
	local kind = typeof(v)
	if kind == "number" then return { v } end
	if kind == "Color3" then return { v.R, v.G, v.B } end
	if kind == "UDim2" then return { v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset } end
	if kind == "Vector2" then return { v.X, v.Y } end
	error("cannot animate " .. kind)
end

local function decode(kind, x)
	if kind == "number" then return x[1] end
	if kind == "Color3" then return Color3.new(math.clamp(x[1], 0, 1), math.clamp(x[2], 0, 1), math.clamp(x[3], 0, 1)) end
	if kind == "UDim2" then return Dim2(x[1], round(x[2]), x[3], round(x[4])) end
	return Vec2(round(x[1]), round(x[2]))
end

local function untrack(entry)
	entry.Dead = true
	local map = Tracks[entry.Target]
	if map and map[entry.Prop] == entry then
		map[entry.Prop] = nil
		if next(map) == nil then Tracks[entry.Target] = nil end
	end
end

local function animate(target, prop, goal, preset, opts)
	local map = Tracks[target]
	if not map then map = {}; Tracks[target] = map end
	local entry = map[prop]
	if not entry then
		local from = encode(target[prop])
		local vel = {}
		for i = 1, #from do vel[i] = 0 end
		entry = { Target = target, Prop = prop, Kind = typeof(goal), X = from, V = vel }
		map[prop] = entry
		table.insert(Active, entry)
	end
	entry.G, entry.Goal = encode(goal), goal
	entry.P = Presets[preset or "Smooth"]
	entry.Done = opts and opts.Done or nil
	entry.Step = opts and opts.Step or nil
end

local function snap(target, prop, value)
	local map = Tracks[target]
	local entry = map and map[prop]
	if entry then untrack(entry) end
	target[prop] = value
end

local function place(target, prop, value, animated, preset)
	if animated then animate(target, prop, value, preset) else snap(target, prop, value) end
end

local function stepAnimator(dt)
	if #Active == 0 then return end
	dt = math.min(dt, 1 / 20)
	local cache = {}
	local i = 1
	while i <= #Active do
		local e = Active[i]
		if e.Dead then
			Active[i] = Active[#Active]
			Active[#Active] = nil
		else
			local c = cache[e.P]
			if not c then
				local w, z = e.P.W, e.P.Z
				local t = dt
				if z >= 1 then
					local k = math.exp(-w * t)
					c = { k * (1 + w * t), k * t, -k * w * w * t, k * (1 - w * t) }
				else
					local wd = w * math.sqrt(1 - z * z)
					local k, co, si = math.exp(-z * w * t), math.cos(wd * t), math.sin(wd * t)
					c = { k * (co + z * w * si / wd), k * si / wd, -k * w * w * si / wd, k * (co - z * w * si / wd) }
				end
				cache[e.P] = c
			end
			local x, v, g = e.X, e.V, e.G
			local eps, settled = EPS[e.Kind], true
			local velEps = eps * e.P.W
			for n = 1, #x do
				local d = x[n] - g[n]
				local nv = c[3] * d + c[4] * v[n]
				local nd = c[1] * d + c[2] * v[n]
				x[n], v[n] = g[n] + nd, nv
				local channelEps = (e.Kind == "UDim2" and n % 2 == 1) and 0.0005 or eps
				if abs(nd) > channelEps or abs(nv) > velEps then settled = false end
			end
			if settled then
				e.Target[e.Prop] = e.Goal
				if e.Step then e.Step(e.Goal) end
				local done = e.Done
				untrack(e)
				Active[i] = Active[#Active]
				Active[#Active] = nil
				if done then task.spawn(done) end
			else
				local value = decode(e.Kind, x)
				if value ~= e.Last then
					e.Last = value
					e.Target[e.Prop] = value
					if e.Step then e.Step(value) end
				end
				i += 1
			end
		end
	end
end

local FrameConnection
local sweepHover
local function ensureLoop()
	if FrameConnection then return end
	FrameConnection = RunService.RenderStepped:Connect(function(dt)
		stepAnimator(dt)
		for job in Jobs do job(dt) end
		sweepHover()
	end)
end

-------------------------------------------------------------------------------
-- Theme, casing and font registries
-------------------------------------------------------------------------------

local Bound, ByKey, Dynamic, Cased, NoFade = {}, {}, {}, {}, {}

local function resolve(source)
	if type(source) == "function" then return source() end
	return Current[source]
end

local function forget(inst)
	local bindings = Bound[inst]
	if bindings then
		for prop, source in bindings do
			if type(source) == "string" then
				local set = ByKey[source]
				if set then set[inst] = nil end
			end
		end
	end
	for _, entry in Tracks[inst] or {} do entry.Dead = true end
	Bound[inst], Dynamic[inst], Cased[inst], Tracks[inst], NoFade[inst] = nil, nil, nil, nil, nil
end

local function bind(inst, prop, source)
	local bindings = Bound[inst]
	if not bindings then
		bindings = {}
		Bound[inst] = bindings
		inst.Destroying:Once(function() forget(inst) end)
	end
	bindings[prop] = source
	if type(source) == "string" then
		local set = ByKey[source]
		if not set then set = {}; ByKey[source] = set end
		set[inst] = prop
	else
		Dynamic[inst] = true
	end
	inst[prop] = resolve(source)
end

local function refresh(inst, preset)
	local bindings = Bound[inst]
	if not bindings then return end
	for prop, source in bindings do
		local value = resolve(source)
		if preset == false or typeof(value) == "ColorSequence" then
			snap(inst, prop, value)
		else
			animate(inst, prop, value, preset or "Fast")
		end
	end
end

local function applyCase(text)
	if Casing == "Lower Case" then return string.lower(text) end
	if Casing == "Upper Case" or Casing == "Bold Case" then return string.upper(text) end
	return text
end

local function fontOf(weight)
	if Casing == "Bold Case" then weight = Enum.FontWeight.Bold end
	return Font.new(FontFamily, weight or BodyWeight, Enum.FontStyle.Normal)
end

local function setText(inst, text, prop)
	prop = prop or "Text"
	local entry = Cased[inst]
	if not entry then entry = {}; Cased[inst] = entry end
	entry[prop] = text
	inst[prop] = applyCase(text)
end

local function applyTextSettings()
	for inst, entry in Cased do
		for prop, raw in entry do
			if prop == "Text" or prop == "PlaceholderText" then inst[prop] = applyCase(raw) end
		end
		inst.FontFace = fontOf(entry.Weight)
	end
end

local TEXT_CLASSES = { TextLabel = true, TextButton = true, TextBox = true }

local function new(class, props, parent)
	local inst = Instance.new(class)
	if inst:IsA("GuiObject") then
		inst.BorderSizePixel = 0
		inst.BackgroundTransparency = 1
	end
	if class == "TextButton" then
		inst.AutoButtonColor = false
		inst.Text = ""
	end
	if TEXT_CLASSES[class] then
		if class ~= "TextButton" then Cased[inst] = {} end
		inst.FontFace = fontOf(nil)
		inst.TextSize = 13
		inst.TextXAlignment = Enum.TextXAlignment.Left
		inst.TextYAlignment = Enum.TextYAlignment.Top
	end
	local bg, fg, radius, border
	if props then
		for key, value in props do
			if key == "Bg" then bg = value
			elseif key == "Fg" then fg = value
			elseif key == "Radius" then radius = value
			elseif key == "Border" then border = value
			elseif key == "Weight" then
				Cased[inst].Weight = value
				inst.FontFace = fontOf(value)
			elseif (key == "Text" and class ~= "TextBox" or key == "PlaceholderText") and TEXT_CLASSES[class] then
				setText(inst, value, key)
			else
				inst[key] = value
			end
		end
	end
	if bg then
		if not (props and props.BackgroundTransparency) then inst.BackgroundTransparency = 0 end
		bind(inst, "BackgroundColor3", bg)
	end
	if fg then bind(inst, "TextColor3", fg) end
	if radius then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = radius >= FULL and UDim.new(0.5, 0) or UDim.new(0, radius)
		corner.Parent = inst
	end
	if border then
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Thickness = 1
		bind(stroke, "Color", border)
		stroke.Parent = inst
	end
	if parent then inst.Parent = parent end
	return inst
end

-- Top-aligned text at a computed whole-pixel offset. Roblox blurs glyphs that land on half pixels,
-- which is what centred alignment produces when the free space is odd.
local function capOffset(rowH, size)
	local capHeight = round(size * 0.7)
	return math.ceil((rowH - capHeight) / 2 - round(size * 0.16))
end

local function label(parent, o)
	local size, rowH = o.TextSize or 12, o.RowH or Metrics.Row
	local x = o.X or 0
	return new("TextLabel", {
		Fg = o.Fg or "Text", Text = o.Text or "", TextSize = size, Weight = o.Weight, TextTruncate = o.Truncate,
		TextTransparency = o.TextTransparency, ZIndex = o.ZIndex,
		Position = Offset(x, (o.Y or 0) + capOffset(rowH, size)),
		Size = o.W and Offset(o.W, rowH) or Dim2(1, -x - (o.Right or 0), 0, rowH),
	}, parent)
end

-- Centres text inside a fixed width using its measured bounds, floored to a whole pixel.
local function centeredLabel(parent, width, o)
	o.Truncate = Enum.TextTruncate.AtEnd
	local text = label(parent, o)
	local y, rowH = text.Position.Y.Offset, o.RowH or Metrics.Row
	local function fit()
		-- The box keeps the full available width. Sizing a truncating label from its own
		-- bounds shrinks it further each time, because truncated text measures narrower.
		text.Size = Offset(width - 12, rowH)
		text.Position = Offset(floor((width - math.min(math.ceil(text.TextBounds.X), width - 12)) / 2), y)
	end
	text:GetPropertyChangedSignal("TextBounds"):Connect(fit)
	fit()
	return text, function(newWidth)
		width = newWidth
		fit()
	end
end

local function addGradient(inst)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	bind(gradient, "Color", function() return ColorSequence.new(Color3.new(1, 1, 1), Current.Gradient) end)
	gradient.Parent = inst
	return gradient
end

-- Native UIShadow styles, fitted to the original: a CSS-like blur (2 sigma) with Spread split across both sides.
local Shadows = {
	Large = { Blur = 10, Spread = 0, Transparency = 0.3 },    -- window and popup windows
	PickerKnob = { Blur = 6, Spread = 6, Transparency = 0.5 }, -- colour picker knobs only
}

-- UIShadow is still rolling out, so clients without it simply draw no shadow.
local ShadowsAvailable = pcall(function() Instance.new("UIShadow"):Destroy() end)

-- The window glow is stacked soft frames behind the window, not a live UIShadow: a blurred UIShadow is
-- re-rendered every frame while the window moves, which is what dropped FPS during dragging.
local GlowLayers = 5

local function addGlow(inst)
	local parent = inst.Parent
	if not parent then return nil end
	local corner = inst:FindFirstChildOfClass("UICorner")
	local radius = corner and corner.CornerRadius.Offset or 0
	local layers = {}
	for index = GlowLayers, 1, -1 do
		local grow = index * 2
		local layer = new("Frame", {
			Name = "Glow", Bg = "Shadow", BackgroundTransparency = 0.93, Radius = radius + grow,
			Position = Offset(-grow, -grow), Size = Dim2(1, grow * 2, 1, grow * 2), ZIndex = inst.ZIndex - 1,
		}, parent)
		layer.Active = false
		table.insert(layers, layer)
	end
	return layers
end

local function addShadow(inst, style)
	if style == "Large" then return addGlow(inst) end
	if not ShadowsAvailable then return nil end
	local preset = Shadows[style]
	local shadow = Instance.new("UIShadow")
	shadow.BlurRadius = UDim.new(0, preset.Blur)
	shadow.Spread = Offset(preset.Spread, preset.Spread)
	shadow.Transparency = preset.Transparency
	bind(shadow, "Color", "Shadow")
	shadow.Parent = inst
	return shadow
end

local function fire(callback, ...)
	if callback then task.spawn(callback, ...) end
end

local function clamp01(n) return math.clamp(n, 0, 1) end

local function isClick(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

-- AbsolutePosition and GetMouseLocation use different origins whenever a top bar inset exists.
-- Offsetting by the ScreenGui's own AbsolutePosition puts the pointer in AbsolutePosition space.
local ScreenRef

local function mousePos()
	local location = UserInputService:GetMouseLocation()
	if ScreenRef then return location + ScreenRef.AbsolutePosition end
	return location
end

local function toLayer(point)
	return ScreenRef and point - ScreenRef.AbsolutePosition or point
end

local function inside(frame, point, margin)
	margin = margin or 0
	local p, s = frame.AbsolutePosition, frame.AbsoluteSize
	return point.X >= p.X - margin and point.X <= p.X + s.X + margin and point.Y >= p.Y - margin and point.Y <= p.Y + s.Y + margin
end

-- Polls once per rendered frame, so dragging costs one update per frame however fast the mouse reports.
local function beginDrag(onMove, onEnd, onFrame)
	local last
	local function job(dt)
		local point = mousePos()
		if not last or point ~= last then
			last = point
			if onMove then onMove(point) end
		end
		if onFrame then onFrame(point, dt) end
	end
	Jobs[job] = true
	local ended
	ended = UserInputService.InputEnded:Connect(function(input)
		if isClick(input) then
			ended:Disconnect()
			Jobs[job] = nil
			local point = mousePos()
			if onMove and point ~= last then onMove(point) end
			if onEnd then onEnd(point) end
		end
	end)
end

-- Roblox skips MouseLeave on fast movement and fires MouseEnter for covered objects, so hover
-- is confirmed against the pointer every frame instead of trusting those events alone.
local Focus
local HoverSet = {}

local function isShown(inst)
	local node = inst
	while node and node:IsA("GuiObject") do
		if not node.Visible then return false end
		node = node.Parent
	end
	return true
end

local function covered(inst, point)
	local win = Focus
	if not win then return false end
	local dropdown = win.OpenDropdown
	if dropdown then
		if inst:IsDescendantOf(dropdown.Panel) then return false end
		if inside(dropdown.Panel, point) then return true end
	end
	local popup = win.ActivePopup
	if popup and not inst:IsDescendantOf(popup.Frame) then
		if inside(popup.Frame, point) then return true end
		for _, parent in win.PopupStack do
			if inside(parent.Frame, point) and not inst:IsDescendantOf(parent.Frame) then return true end
		end
	end
	if win.Search and win.Search.Open and not inst:IsDescendantOf(win.Search.Overlay) then return true end
	return false
end

local function hoverable(inst, onEnter, onLeave)
	local entered = false
	local function leave()
		if not entered then return end
		entered = false
		HoverSet[inst] = nil
		onLeave()
	end
	inst.MouseEnter:Connect(function()
		if entered or covered(inst, mousePos()) then return end
		entered = true
		HoverSet[inst] = leave
		onEnter()
	end)
	inst.MouseLeave:Connect(leave)
	inst.Destroying:Once(function() HoverSet[inst] = nil end)
end

function sweepHover()
	if next(HoverSet) == nil then return end
	if Focus and Focus.Moving then return end
	local point = mousePos()
	for inst, leave in HoverSet do
		if not inside(inst, point) or not isShown(inst) or covered(inst, point) then leave() end
	end
end

-------------------------------------------------------------------------------
-- Fader: one animated alpha drives every transparency beneath a root
-------------------------------------------------------------------------------

local Fader = {}
Fader.__index = Fader

local function newFader(root)
	return setmetatable({ Root = root, Alpha = 1, Entries = nil }, Fader)
end

local function captureFade(root)
	local entries = {}
	local function add(inst, prop)
		-- A value that's still animating would be restored stale when the fade ends.
		if NoFade[inst] or (Tracks[inst] and Tracks[inst][prop]) then return end
		local base = inst[prop]
		if base < 1 then table.insert(entries, { inst, prop, base }) end
	end
	local function visit(inst)
		if inst:IsA("GuiObject") then
			if inst ~= root and not inst.Visible then return end
			add(inst, "BackgroundTransparency")
			if TEXT_CLASSES[inst.ClassName] then add(inst, "TextTransparency") end
			if inst:IsA("ImageLabel") then add(inst, "ImageTransparency") end
		elseif inst:IsA("UIStroke") or inst.ClassName == "UIShadow" then
			add(inst, "Transparency")
		end
		for _, child in inst:GetChildren() do visit(child) end
	end
	visit(root)
	return entries
end

function Fader:_apply(alpha)
	local entries = self.Entries
	if not entries then return end
	for _, e in entries do
		e[1][e[2]] = 1 - (1 - e[3]) * alpha
	end
end

function Fader:Show(onDone, preset)
	if not self.Entries then
		self.Entries = captureFade(self.Root)
		self.Alpha = 0
		self:_apply(0)
	end
	self.Root.Visible = true
	animate(self, "Alpha", 1, preset or "Smooth", {
		Step = function(value) self:_apply(value) end,
		Done = function()
			self.Entries = nil
			if onDone then onDone() end
		end,
	})
end

function Fader:Hide(onDone, preset)
	if not self.Entries then
		self.Entries = captureFade(self.Root)
		self.Alpha = 1
	end
	animate(self, "Alpha", 0, preset or "Fast", {
		Step = function(value) self:_apply(value) end,
		Done = function()
			self.Root.Visible = false
			self:_apply(1)
			self.Entries = nil
			if onDone then onDone() end
		end,
	})
end

-------------------------------------------------------------------------------
-- Icons: Lucide (lucide.dev). An icon name is a Lucide file name: "target", "bot", "settings", "flower".
-- The SVG is downloaded from GitHub on first use, cached in Blossom/icons and drawn from frames,
-- so no uploaded decals or asset ids are needed. Old Blossom names still work through IconAliases.
-------------------------------------------------------------------------------

local IconBase = {
	"https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/",
	"https://cdn.jsdelivr.net/gh/lucide-icons/lucide@main/icons/",
}
local IconStroke = 2   -- Lucide's own stroke width on its 24 unit grid
local IconAliases = {
	robot = "bot", gear = "settings", layout = "layout-template", cube = "box",
	reset = "rotate-ccw", logo = "flower", bullet = "crosshair",
}
-- SVG text registered by name never touches the network (Blossom.AddIcon adds to this).
local IconSVG = {
	["blossom-resize"] = '<path d="M21 15l-6 6"/><path d="M21 8L8 21"/>',
}
local IconGeometry, IconPending = {}, {}

-- Flattens one SVG path string into polylines ({ x1, y1, x2, y2, ... }) on the 24 unit grid.
local function pathPolylines(d, out)
	local pos, len = 1, #d
	local function skip() pos = string.find(d, "[^%s,]", pos) or len + 1 end
	local function number()
		skip()
		local first, last = string.find(d, "^[-+]?%d*%.?%d*", pos)
		if not first or last < first then return nil end
		local exponent = select(2, string.find(d, "^[eE][-+]?%d+", last + 1))
		if exponent then last = exponent end
		local value = tonumber(string.sub(d, first, last))
		if not value then return nil end
		pos = last + 1
		return value
	end
	local function flag()
		skip()
		local c = string.sub(d, pos, pos)
		if c == "0" or c == "1" then
			pos += 1
			return tonumber(c)
		end
		return nil
	end
	local function args(count)
		local list = {}
		for index = 1, count do
			local value = number()
			if not value then return nil end
			list[index] = value
		end
		return list
	end

	local cx, cy, sx, sy = 0, 0, 0, 0
	local cubicX, cubicY, quadX, quadY
	local cur
	local function lineTo(x, y)
		if not cur then
			cur = { cx, cy }
			table.insert(out, cur)
		end
		cx, cy = x, y
		table.insert(cur, x)
		table.insert(cur, y)
	end
	local function cubic(x1, y1, x2, y2, x, y)
		local x0, y0 = cx, cy
		for step = 1, 8 do
			local t = step / 8
			local u = 1 - t
			lineTo(u * u * u * x0 + 3 * u * u * t * x1 + 3 * u * t * t * x2 + t * t * t * x,
				u * u * u * y0 + 3 * u * u * t * y1 + 3 * u * t * t * y2 + t * t * t * y)
		end
		cubicX, cubicY = x2, y2
	end
	local function quad(x1, y1, x, y)
		local x0, y0 = cx, cy
		for step = 1, 6 do
			local t = step / 6
			local u = 1 - t
			lineTo(u * u * x0 + 2 * u * t * x1 + t * t * x, u * u * y0 + 2 * u * t * y1 + t * t * y)
		end
		quadX, quadY = x1, y1
	end
	local function arc(rx, ry, degrees, large, sweep, x, y)
		local x0, y0 = cx, cy
		if x0 == x and y0 == y then return end
		rx, ry = abs(rx), abs(ry)
		if rx == 0 or ry == 0 then lineTo(x, y) return end
		local phi = math.rad(degrees)
		local cosP, sinP = math.cos(phi), math.sin(phi)
		local dx, dy = (x0 - x) / 2, (y0 - y) / 2
		local x1 = cosP * dx + sinP * dy
		local y1 = -sinP * dx + cosP * dy
		local lambda = x1 * x1 / (rx * rx) + y1 * y1 / (ry * ry)
		if lambda > 1 then
			local grow = math.sqrt(lambda)
			rx, ry = rx * grow, ry * grow
		end
		local sign = large == sweep and -1 or 1
		local numerator = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
		local denominator = rx * rx * y1 * y1 + ry * ry * x1 * x1
		local coef = sign * math.sqrt(math.max(0, numerator / denominator))
		local cxp, cyp = coef * rx * y1 / ry, -coef * ry * x1 / rx
		local centerX = cosP * cxp - sinP * cyp + (x0 + x) / 2
		local centerY = sinP * cxp + cosP * cyp + (y0 + y) / 2
		local start = math.atan2((y1 - cyp) / ry, (x1 - cxp) / rx)
		local delta = math.atan2((-y1 - cyp) / ry, (-x1 - cxp) / rx) - start
		if sweep == 0 and delta > 0 then delta -= math.pi * 2 elseif sweep == 1 and delta < 0 then delta += math.pi * 2 end
		local steps = math.max(1, math.ceil(abs(delta) / math.rad(18)))
		for step = 1, steps do
			if step == steps then
				lineTo(x, y)
			else
				local angle = start + delta * step / steps
				local ca, sa = math.cos(angle), math.sin(angle)
				lineTo(centerX + rx * ca * cosP - ry * sa * sinP, centerY + rx * ca * sinP + ry * sa * cosP)
			end
		end
	end

	local cmd
	while true do
		skip()
		if pos > len then break end
		local c = string.sub(d, pos, pos)
		if string.find(c, "%a") then
			cmd = c
			pos += 1
			if cmd == "z" or cmd == "Z" then
				if cur then lineTo(sx, sy) end
				cx, cy, cur, cmd = sx, sy, nil, nil
				continue
			end
		elseif not cmd or not string.find(c, "[%d%.%-%+]") then
			break
		end
		local relative = cmd == string.lower(cmd)
		local op = string.upper(cmd)
		local ox, oy = relative and cx or 0, relative and cy or 0
		if op ~= "C" and op ~= "S" then cubicX = nil end
		if op ~= "Q" and op ~= "T" then quadX = nil end
		if op == "M" then
			local v = args(2)
			if not v then break end
			cx, cy = v[1] + ox, v[2] + oy
			sx, sy, cur = cx, cy, nil
			cmd = relative and "l" or "L"
		elseif op == "L" then
			local v = args(2)
			if not v then break end
			lineTo(v[1] + ox, v[2] + oy)
		elseif op == "H" then
			local v = args(1)
			if not v then break end
			lineTo(v[1] + ox, cy)
		elseif op == "V" then
			local v = args(1)
			if not v then break end
			lineTo(cx, v[1] + oy)
		elseif op == "C" then
			local v = args(6)
			if not v then break end
			cubic(v[1] + ox, v[2] + oy, v[3] + ox, v[4] + oy, v[5] + ox, v[6] + oy)
		elseif op == "S" then
			local v = args(4)
			if not v then break end
			local x1, y1 = cx, cy
			if cubicX then x1, y1 = 2 * cx - cubicX, 2 * cy - cubicY end
			cubic(x1, y1, v[1] + ox, v[2] + oy, v[3] + ox, v[4] + oy)
		elseif op == "Q" then
			local v = args(4)
			if not v then break end
			quad(v[1] + ox, v[2] + oy, v[3] + ox, v[4] + oy)
		elseif op == "T" then
			local v = args(2)
			if not v then break end
			local x1, y1 = cx, cy
			if quadX then x1, y1 = 2 * cx - quadX, 2 * cy - quadY end
			quad(x1, y1, v[1] + ox, v[2] + oy)
		elseif op == "A" then
			local rx, ry, rotation = number(), number(), number()
			local large, sweep = flag(), flag()
			local x, y = number(), number()
			if not (rx and ry and rotation and large and sweep and x and y) then break end
			arc(rx, ry, rotation, large, sweep, x + ox, y + oy)
		else
			break
		end
	end
end

-- Reads the shapes of a Lucide SVG (path, circle, ellipse, rect, line, polyline, polygon).
local function parseSVG(text)
	local out = {}
	for tag, attrs in string.gmatch(text, "<(%a+)%s([^>]*)>") do
		local a = {}
		for key, value in string.gmatch(attrs, '([%w%-:]+)%s*=%s*"([^"]*)"') do a[key] = value end
		local function n(key) return tonumber(a[key]) or 0 end
		if tag == "path" and a.d then
			pathPolylines(a.d, out)
		elseif tag == "circle" or tag == "ellipse" then
			local x, y = n("cx"), n("cy")
			local rx = tag == "circle" and n("r") or n("rx")
			local ry = tag == "circle" and n("r") or n("ry")
			pathPolylines(string.format("M%f %fa%f %f 0 1 0 %f 0a%f %f 0 1 0 %f 0z", x - rx, y, rx, ry, rx * 2, rx, ry, -rx * 2), out)
		elseif tag == "rect" then
			local x, y, w, h = n("x"), n("y"), n("width"), n("height")
			local rx = a.rx and n("rx") or n("ry")
			local ry = a.ry and n("ry") or rx
			rx, ry = math.min(rx, w / 2), math.min(ry, h / 2)
			if rx > 0 and ry > 0 then
				pathPolylines(string.format("M%f %fH%fA%f %f 0 0 1 %f %fV%fA%f %f 0 0 1 %f %fH%fA%f %f 0 0 1 %f %fV%fA%f %f 0 0 1 %f %fZ",
					x + rx, y, x + w - rx, rx, ry, x + w, y + ry, y + h - ry, rx, ry, x + w - rx, y + h,
					x + rx, rx, ry, x, y + h - ry, y + ry, rx, ry, x + rx, y), out)
			else
				pathPolylines(string.format("M%f %fH%fV%fH%fZ", x, y, x + w, y + h, x), out)
			end
		elseif tag == "line" then
			pathPolylines(string.format("M%f %fL%f %f", n("x1"), n("y1"), n("x2"), n("y2")), out)
		elseif (tag == "polyline" or tag == "polygon") and a.points then
			local d = ""
			local index = 0
			for number in string.gmatch(a.points, "[-+]?%d*%.?%d+") do
				index += 1
				d = d .. (index == 1 and "M" or (index == 2 and " " or (index % 2 == 1 and "L" or " "))) .. number
			end
			pathPolylines(d .. (tag == "polygon" and "Z" or ""), out)
		end
	end
	return out
end

local function httpGet(url)
	local ok, body = pcall(function() return game:HttpGet(url) end)
	if ok and type(body) == "string" then return body end
	ok, body = pcall(HttpService.GetAsync, HttpService, url)
	if ok and type(body) == "string" then return body end
	return nil
end

local function iconSource(name)
	if IconSVG[name] then return IconSVG[name] end
	local path = "Blossom/icons/" .. name .. ".svg"
	if typeof(isfile) == "function" and typeof(readfile) == "function" and isfile(path) then
		local ok, text = pcall(readfile, path)
		if ok and type(text) == "string" and string.find(text, "<svg", 1, true) then return text end
	end
	for _, base in IconBase do
		local text = httpGet(base .. name .. ".svg")
		if text and string.find(text, "<svg", 1, true) then
			if typeof(writefile) == "function" then
				if typeof(makefolder) == "function" then
					pcall(makefolder, "Blossom")
					pcall(makefolder, "Blossom/icons")
				end
				pcall(writefile, path, text)
			end
			return text
		end
	end
	return nil
end

-- Calls back with the polylines of an icon; concurrent requests for one name share a single download.
local function loadIcon(name, callback)
	local ready = IconGeometry[name]
	if ready then callback(ready) return end
	local waiting = IconPending[name]
	if waiting then table.insert(waiting, callback) return end
	IconPending[name] = { callback }
	task.spawn(function()
		local text = string.match(name, "^[%w%-_]+$") and iconSource(name)
		local polylines = text and parseSVG(text) or {}
		if #polylines == 0 then warn("[Blossom] icon not found: " .. name) end
		IconGeometry[name] = polylines
		local list = IconPending[name]
		IconPending[name] = nil
		for _, fn in list do fn(polylines) end
	end)
end

-- Every segment is a rounded frame, so joins and caps are round like Lucide's. Colours follow the theme.
local function drawIcon(root, icon, polylines, size, color)
	local scale = size / 24
	local thick = IconStroke * scale
	local minStep = math.max(thick * 0.45, 0.3)
	for _, poly in polylines do
		local points = { poly[1] * scale, poly[2] * scale }
		for index = 3, #poly, 2 do
			local x, y = poly[index] * scale, poly[index + 1] * scale
			local last = #points
			local dx, dy = x - points[last - 1], y - points[last]
			if index + 1 >= #poly or dx * dx + dy * dy >= minStep * minStep then
				table.insert(points, x)
				table.insert(points, y)
			end
		end
		for index = 1, #points - 2, 2 do
			local x1, y1, x2, y2 = points[index], points[index + 1], points[index + 2], points[index + 3]
			local dx, dy = x2 - x1, y2 - y1
			local length = math.sqrt(dx * dx + dy * dy)
			local frame = new("Frame", {
				Bg = color, AnchorPoint = Vec2(0.5, 0.5), Radius = FULL,
				Position = Dim2((x1 + x2) / 2 / size, 0, (y1 + y2) / 2 / size, 0),
				Size = Dim2((length + thick) / size, 0, thick / size, 0),
				Rotation = math.deg(math.atan2(dy, dx)),
			}, root)
			table.insert(icon.Parts, frame)
		end
	end
end

local function makeIcon(parent, name, size, color, hole, props)
	props = props or {}
	local root = new("Frame", { Name = "Icon", Size = Offset(size, size), Position = props.Position, AnchorPoint = props.AnchorPoint, ZIndex = props.ZIndex }, parent)
	local icon = { Root = root, Parts = {} }
	function icon.Update(preset)
		for _, part in icon.Parts do refresh(part, preset) end
	end
	if type(name) == "string" and string.find(name, "rbxasset", 1, true) then
		local image = new("ImageLabel", { Size = Dim2(1, 0, 1, 0), Image = name }, root)
		bind(image, "ImageColor3", color)
		table.insert(icon.Parts, image)
	else
		local key = string.lower(tostring(name or "box"))
		key = IconAliases[key] or key
		loadIcon(key, function(polylines)
			if root.Parent then drawIcon(root, icon, polylines, size, color) end
		end)
	end
	return icon
end

-- Hover and press colours resolved through the theme, so a theme change can't strand a stale colour.
local function interactive(target, base, hover, press, handle)
	local state = { Hover = false, Press = false }
	local source = handle or target
	bind(target, "BackgroundColor3", function()
		if state.Press and press then return Current[press] end
		if state.Hover then return Current[hover or "HoveredElement"] end
		return Current[base]
	end)
	hoverable(source, function() state.Hover = true; refresh(target) end, function() state.Hover, state.Press = false, false; refresh(target) end)
	if source:IsA("GuiButton") then
		source.MouseButton1Down:Connect(function() state.Press = true; refresh(target) end)
		source.MouseButton1Up:Connect(function() state.Press = false; refresh(target) end)
	end
	return state
end

-------------------------------------------------------------------------------
-- Classes
-------------------------------------------------------------------------------

local Window, Tab, Section, Column = {}, {}, {}, {}
Window.__index, Tab.__index, Section.__index, Column.__index = Window, Tab, Section, Column
local SubTab = {}
SubTab.__index = SubTab

local function formatNumber(value, decimals)
	if decimals and decimals > 0 then return string.format("%." .. decimals .. "f", value) end
	return tostring(floor(value + 0.5))
end

local function keyName(key)
	if key == nil then return "-" end
	local short = {
		LeftShift = "LS", RightShift = "RS", LeftControl = "LC", RightControl = "RC", LeftAlt = "LA", RightAlt = "RA",
		MouseButton1 = "M1", MouseButton2 = "M2", MouseButton3 = "M3", Return = "Ent", Backspace = "Bk",
		One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9", Zero = "0",
	}
	return short[key.Name] or key.Name
end

local function makeChip(parent, text, anchorRight, outerHeight)
	local height = (outerHeight or Metrics.ChipH) - 2
	local chip = new("Frame", {
		Bg = "Element", Radius = Metrics.Radius, Border = "Outline", Size = Offset(16, height),
		AnchorPoint = anchorRight and Vec2(1, 0) or nil,
	}, parent)
	addGradient(chip)
	local caption = label(chip, { Fg = "InactiveText", Text = text, TextSize = 11, X = 4, RowH = height })
	return chip, caption
end

-- Sizes a chip around its text. Widths given to onFit are outer widths, borders included.
local function fitChip(chip, text, minimum, onFit)
	local height = chip.Size.Y.Offset
	local function apply(bounds)
		local width = math.max((minimum or 2) - 2, bounds + 8)
		chip.Size = Offset(width, height)
		text.Position = Offset(floor((width - bounds) / 2), text.Position.Y.Offset)
		if onFit then onFit(width + 2) end
		return width
	end
	local function fit() apply(math.ceil(text.TextBounds.X)) end
	text:GetPropertyChangedSignal("TextBounds"):Connect(fit)
	fit()
	return apply, fit
end

-- Click a slider amount to type a value; Enter or clicking away commits, anything non-numeric reverts.
local function makeEditable(chip, text, read, write, apply, fit)
	local height = chip.Size.Y.Offset
	local hit = new("TextButton", { Size = Dim2(1, 0, 1, 0), ZIndex = 2 }, chip)
	interactive(chip, "Element", nil, nil, hit)
	local editing = false
	local stroke = chip:FindFirstChildOfClass("UIStroke")
	bind(stroke, "Color", function() return editing and Current.Accent or Current.Outline end)
	local box = new("TextBox", {
		Fg = "Text", TextSize = 11, Visible = false, ZIndex = 3, ClearTextOnFocus = false,
		Position = Offset(4, capOffset(height, 11)), Size = Dim2(1, -8, 0, height),
	}, chip)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		if editing then apply(math.ceil(box.TextBounds.X)) end
	end)
	hit.MouseButton1Click:Connect(function()
		editing = true
		refresh(stroke)
		box.Text = read()
		text.Visible, box.Visible = false, true
		box:CaptureFocus()
		box.CursorPosition = #box.Text + 1
		box.SelectionStart = 1
	end)
	box.FocusLost:Connect(function()
		if not editing then return end
		editing = false
		refresh(stroke)
		local number = tonumber(string.match(box.Text, "%-?%d*%.?%d+") or "")
		box.Visible, text.Visible = false, true
		if number then write(number) end
		fit()
	end)
end

-------------------------------------------------------------------------------
-- Column
-------------------------------------------------------------------------------

function Column:Layout(animated)
	local y = 0
	for _, section in self.Sections do
		section.Y = y
		if not section.Dragging and not section.Dropping then
			place(section.Root, "Position", Offset(0, y), animated, "Settle")
		end
		y += section.TotalH + Metrics.SectionGap
	end
	self.ContentH = math.max(0, y - Metrics.SectionGap)
	self.Scroll.CanvasSize = Offset(0, self.ContentH)
	self:ClampScroll()
end

function Column:ClampScroll()
	-- Uses the window's own height so it's right on the same frame as a resize.
	self.Target = math.clamp(self.Target, 0, math.max(0, self.ContentH - (self.Tab.Window.Height - Metrics.Pad * 2 - (self.Tab.TopH or 0))))
end

function Column:ScrollTo(y)
	self.Target = y
	self:ClampScroll()
	animate(self.Scroll, "CanvasPosition", Vec2(0, self.Target), "Soft")
end

-------------------------------------------------------------------------------
-- Section
-------------------------------------------------------------------------------

function Section:Layout(animated)
	local y, any = Metrics.Pad, false
	for _, item in self.Items do
		if item.Visible then
			item.Y, any = y, true
			place(item.Frame, "Position", Offset(0, y), animated)
			y += item.Height + Metrics.Gap
		end
	end
	if any then y -= Metrics.Gap end
	self.CardH = y + Metrics.Pad
	self.TotalH = self.HeaderH + self.CardH
	place(self.Card, "Size", Dim2(1, -2, 0, self.CardH - 2), animated)
	if not self.Dragging then place(self.Root, "Size", Dim2(1, 0, 0, self.TotalH), animated) end
	if self.Column then self.Column:Layout(animated) end
end

function Section:_item(height, kind, name, indexed)
	local frame = new("Frame", { Size = Dim2(1, 0, 0, height) }, self.Body)
	local item = { Frame = frame, Height = height, Kind = kind, Name = name, Section = self, Slots = {}, Visible = true, Y = 0 }
	table.insert(self.Items, item)
	if name and indexed ~= false then table.insert(self.Window.Index, item) end
	self:Layout(false)
	return item
end

local function layoutSlots(item)
	local x = 0
	for _, slot in item.Slots do
		x += slot.Gap
		slot.Frame.Position = Dim2(1, -x - 1, 0, floor((Metrics.Row - slot.Height) / 2) + 1)
		x += slot.Width
	end
	if item.Label then item.Label.Size = Dim2(1, -(x + Metrics.Gap), 0, Metrics.Row) end
end

local function addSlot(item, frame, width, height, gap)
	local slot = { Frame = frame, Width = width, Height = height, Gap = #item.Slots == 0 and 0 or gap }
	frame.AnchorPoint = Vec2(1, 0)
	table.insert(item.Slots, slot)
	layoutSlots(item)
	return slot
end

-- Keybind modes: Toggle flips on each press, Hold is active while the key is down, Press fires once per press.
-- options.Modes limits which modes the right-click menu offers ({ "Press" } = only Press, nil = all of them).
local ModeOrder = { "Toggle", "Hold", "Press" }

local function allowedModes(list)
	if type(list) == "string" then list = { list } end
	if type(list) ~= "table" then return nil end
	local set, any = {}, false
	for _, mode in list do
		if table.find(ModeOrder, mode) then set[mode], any = true, true end
	end
	return any and set or nil
end

local function attachKeybind(section, item, options)
	local win = section.Window
	local object = {
		Key = options.Key, Mode = "Toggle", Modes = allowedModes(options.Modes), Listening = false,
		OnPress = options.OnPress, OnRelease = options.OnRelease, Name = options.Name,
	}
	if table.find(ModeOrder, options.Mode) and (not object.Modes or object.Modes[options.Mode]) then
		object.Mode = options.Mode
	elseif object.Modes then
		for _, mode in ModeOrder do
			if object.Modes[mode] then object.Mode = mode break end
		end
	end
	local chip, text = makeChip(item.Frame, keyName(object.Key))
	local button = new("TextButton", { Size = Dim2(1, 0, 1, 0), ZIndex = 2 }, chip)
	local slot = addSlot(item, chip, 18, Metrics.ChipH, Metrics.Gap + 2)
	fitChip(chip, text, 18, function(width)
		slot.Width = width
		layoutSlots(item)
	end)
	interactive(chip, "Element", nil, nil, button)
	bind(text, "TextColor3", function()
		if object.Listening then return Current.Accent end
		return Current.InactiveText
	end)
	function object.Refresh()
		setText(text, object.Listening and "..." or keyName(object.Key))
		refresh(text)
		if object.OnKeyChanged then object.OnKeyChanged() end
	end
	function object:Set(key)
		object.Key = key
		object.Refresh()
	end
	-- Returns false when the mode does not exist or this keybind does not allow it.
	function object:SetMode(mode)
		if not table.find(ModeOrder, mode) or (object.Modes and not object.Modes[mode]) then return false end
		object.Mode = mode
		if object.OnModeChanged then fire(object.OnModeChanged, mode) end
		return true
	end
	button.MouseButton1Click:Connect(function()
		object.Listening = true
		win.Listening = object
		object.Refresh()
	end)
	button.MouseButton2Click:Connect(function() win:OpenKeybindMenu(chip, object) end)
	object.Chip, object.Label = chip, text
	table.insert(win.Binds, object)
	return object
end

local function attachColor(section, item, options)
	local win = section.Window
	local color = {
		Value = options.Default or Color3.new(1, 1, 1), Alpha = options.Alpha or 0, Animation = "None",
		Callback = options.Callback, Flag = options.Flag, Phase = 0,
	}
	color.Base = color.Value
	local swatch = new("TextButton", {
		Size = Offset(Metrics.Swatch - 2, Metrics.Swatch - 2), Radius = Metrics.Radius, BackgroundTransparency = 0,
		BackgroundColor3 = color.Value, Border = "Outline",
	}, item.Frame)
	addSlot(item, swatch, Metrics.Swatch, Metrics.Swatch, Metrics.Gap + 2)
	color.Swatch = swatch
	function color:Set(value, alpha, silent)
		if type(alpha) == "boolean" then alpha, silent = nil, alpha end
		color.Value = value
		if not color.Animating then color.Base = value end
		if alpha ~= nil then color.Alpha = alpha end
		swatch.BackgroundColor3 = value
		if win.ActivePopup == win.Picker and win.Picker.Target == color and not win.Picker.Dragging then win.Picker.Sync(true) end
		if not silent then fire(color.Callback, value, color.Alpha) end
	end
	function color:SetAnimation(mode)
		mode = mode or "None"
		if mode == color.Animation then return end
		color.Animation, color.Phase = mode, 0
		if mode == "None" then color:Set(color.Base) end
	end
	-- Rainbow and Pulse start from the picked colour and ease in, so switching them on never jumps.
	function color:Step(dt)
		color.Phase += dt
		local h, s, v = color.Base:ToHSV()
		local ease = math.min(color.Phase / 0.8, 1)
		if color.Animation == "Rainbow" then
			s += (math.max(s, 0.6) - s) * ease
			v += (math.max(v, 0.75) - v) * ease
			h = (h + color.Phase * 0.1) % 1
		else
			v += (math.max(v, 0.6) - v) * ease
			v *= 0.55 + 0.45 * (0.5 + 0.5 * math.cos(color.Phase * 2.2))
		end
		color.Animating = true
		color:Set(Color3.fromHSV(h, s, v))
		color.Animating = false
	end
	swatch.MouseButton1Click:Connect(function() win:OpenPicker(swatch, color) end)
	table.insert(win.Colors, color)
	return color
end

-- A gear icon on a Toggle or Label opens a popup that takes the same elements as a Section.
local Gear = setmetatable({}, { __index = Section })
Gear.__index = Gear

function Gear:Layout()
	local y, any = Metrics.Pad, false
	-- items flagged Last (the reset button) always sit at the bottom, whatever order they were created in
	for pass = 1, 2 do
		for _, item in self.Items do
			if item.Visible ~= false and (item.Last == true) == (pass == 2) then
				item.Y, any = y, true
				item.Frame.Position = Offset(0, y)
				y += item.Height + Metrics.Gap
			end
		end
	end
	local height = any and y - Metrics.Gap + Metrics.Pad or Metrics.Pad * 2
	self.Popup.Frame.Size = Offset(self.Window.ColumnW, height)
end

function Gear:_item(height, kind, name)
	local frame = new("Frame", { Size = Dim2(1, 0, 0, height) }, self.Body)
	local item = { Frame = frame, Height = height, Kind = kind, Name = name, Section = self, Slots = {}, Visible = true, Y = 0 }
	table.insert(self.Items, item)
	table.insert(self.Controls, frame)
	self:Layout()
	return item
end

-- Every control made inside a gear remembers its starting value, so Gear:ResetButton() can put them all back.
local TRACKED_KINDS = { "Toggle", "Slider", "RangeSlider", "Dropdown", "Colorpicker", "Textbox", "Listbox" }

local function trackGear(gear)
	gear.Tracked = {}
	for _, kind in TRACKED_KINDS do
		local make = Section[kind]
		if make then
			gear[kind] = function(self, options)
				local object = make(self, options)
				if type(object) == "table" then
					local value = object.Value
					if type(value) == "table" then value = table.clone(value) end
					table.insert(self.Tracked, { Object = object, Value = value, Alpha = object.Alpha })
				end
				return object
			end
		end
	end
end

function Gear:ResetButton(name)
	local button = self:Button({
		Name = name or "Reset to Default",
		Callback = function()
			for _, entry in self.Tracked do
				local object, value = entry.Object, entry.Value
				if type(value) == "table" then value = table.clone(value) end
				pcall(function()
					if entry.Alpha ~= nil then object:Set(value, entry.Alpha) else object:Set(value) end
				end)
			end
		end,
	})
	local item = self.Items[#self.Items]
	if item then item.Last = true; self:Layout() end
	return button
end

local function attachGear(section, item, name)
	local win = section.Window
	local frame, body, controls = win:_popupFrame(win.ColumnW, Metrics.Pad * 2)
	local popup = { Frame = frame, Fader = newFader(frame) }
	local gear = setmetatable({
		Window = win, Tab = section.Tab, Name = section.Name .. "/" .. tostring(name), Popup = popup, Items = {}, Controls = controls,
		Body = new("Frame", { Position = Offset(Metrics.Pad, 0), Size = Dim2(1, -Metrics.Pad * 2, 1, 0) }, body),
	}, Gear)
	trackGear(gear)
	table.insert(win.Extras, gear)
	table.insert(win.ResizeJobs, function() gear:Layout() end)
	local button = new("TextButton", { Size = Offset(Metrics.Row, Metrics.Row) }, item.Frame)
	local hovering = false
	local icon = makeIcon(button, "gear", 14, function() return hovering and Current.Text or Current.InactiveText end, section.Popup and "Background" or "Inline", { Position = Offset(1, 1) })
	addSlot(item, button, Metrics.Row, Metrics.Row, Metrics.Gap + 2)
	hoverable(button, function() hovering = true; icon.Update() end, function() hovering = false; icon.Update() end)
	local turns = 0
	button.MouseButton1Click:Connect(function()
		-- Every click spins the gear half a turn with a small spring overshoot.
		turns += 1
		animate(icon.Root, "Rotation", turns * 180, "Settle")
		local p, s = button.AbsolutePosition, button.AbsoluteSize
		win:_openPopup(popup, button, Vec2(p.X - 8, p.Y + s.Y + Metrics.Pad))
	end)
	return gear
end

local function addInlineControls(section, item, options, name)
	local keybind, color, gear
	if options.Color then
		color = attachColor(section, item, { Default = options.Color, Alpha = options.ColorAlpha, Callback = options.ColorCallback })
	end
	if options.Keybind ~= nil then
		keybind = attachKeybind(section, item, { Key = options.Keybind, Mode = options.KeybindMode, Modes = options.KeybindModes, Name = options.KeybindName or name })
	end
	if options.Gear then
		gear = attachGear(section, item, options.Name or name)
		if options.Reset then gear:ResetButton() end
	end
	return keybind, color, gear
end

-- Every element joins configs automatically under Tab/Section/Name unless NoSave is set.
local function register(section, object, options, item)
	local win = section.Window
	function object:SetValue(...) return self:Set(...) end
	function object:OnChanged(callback)
		local key = self.Chip and "OnKeyChanged" or "Callback"
		local previous = self[key]
		self[key] = previous and function(...) previous(...); fire(callback, ...) end or callback
	end
	if options.NoSave then return nil end
	local base = options.Flag or (section.Tab.Name .. "/" .. section.Name .. "/" .. tostring(options.Name or item.Kind))
	local flag, count = base, 1
	while win.Flags[flag] do
		count += 1
		flag = base .. "#" .. count
	end
	win.Flags[flag] = object
	local registry = item.Kind == "Toggle" and win.Toggles or win.Options
	registry[flag] = object
	object.Flag = flag
	return flag
end

function Section:Toggle(options)
	local win, name = self.Window, options.Name
	local item = self:_item(Metrics.Row, "Toggle", name)
	local toggle = { Value = options.Default == true, Item = item, Callback = options.Callback }
	local hit = new("TextButton", { Position = Offset(0, -3), Size = Dim2(1, 0, 1, 6) }, item.Frame)
	local hovering = false
	local text = label(item.Frame, {
		Text = name, Truncate = Enum.TextTruncate.AtEnd,
		Fg = function()
			if toggle.Value then return Current.Text end
			return hovering and Current.InactiveText:Lerp(Current.Text, 0.45) or Current.InactiveText
		end,
	})
	item.Label = text
	local track = new("Frame", {
		Bg = function() return toggle.Value and Current.Accent or Current.Element end,
		Size = Offset(Metrics.ToggleW - 2, Metrics.ToggleH - 2), Radius = FULL, Border = "Outline",
	}, item.Frame)
	addGradient(track)
	local knob = new("Frame", {
		Bg = function() return toggle.Value and Current.Text or Current.InactiveText end,
		Size = Offset(Metrics.ToggleKnob, Metrics.ToggleKnob), Radius = FULL,
	}, track)
	addSlot(item, track, Metrics.ToggleW, Metrics.ToggleH, 0)

	local function render(animated)
		local x = toggle.Value and Metrics.ToggleW - 2 - Metrics.ToggleKnob - 2 or 2
		place(knob, "Position", Offset(x, 2), animated, "Knob")
		local preset = animated and "Fast" or false
		refresh(track, preset); refresh(knob, preset); refresh(text, preset)
	end
	local function syncHotkey()
		if toggle.Keybind then win:SetHotkeyActive(toggle.Keybind, toggle.Value) end
	end

	function toggle:Set(value, silent)
		value = value == true
		if value == toggle.Value then return end
		toggle.Value = value
		-- Turning the feature off by hand also drops the forced "Always" state.
		if not value and toggle.Always then toggle.Always = false end
		render(true)
		syncHotkey()
		if not silent then fire(toggle.Callback, value) end
	end

	-- "Always" switch of the hotkey list: feature stays on, the key is ignored until it is switched off.
	toggle.Always = false
	function toggle:SetAlways(value)
		value = value == true
		if toggle.Always == value then return end
		toggle.Always = value
		if value then toggle:Set(true) else toggle:Set(false) end
		toggle.Always = value
		syncHotkey()
	end

	hoverable(hit, function()
		hovering = true
		refresh(text)
	end, function()
		hovering = false
		refresh(text)
	end)
	hit.MouseButton1Click:Connect(function() toggle:Set(not toggle.Value) end)

	local hotkeyName = options.KeybindName or (name == "Enabled" and self.Name) or name
	toggle.Keybind, toggle.Color, toggle.Gear = addInlineControls(self, item, options, hotkeyName)
	if toggle.Keybind then
		toggle.Keybind.OnPress = function()
			local mode = toggle.Keybind.Mode
			if mode == "Press" then
				local entry = win.HotkeyEntries[toggle.Keybind]
				if entry then entry.Pulse() end
			elseif toggle.Always then
				return
			end
			if mode == "Hold" then
				toggle:Set(true)
			elseif mode == "Press" then
				-- One-shot: the toggle keeps its state. PressCallback runs, or Callback(true) when it is not set.
				fire(options.PressCallback or toggle.Callback, true)
			else
				toggle:Set(not toggle.Value)
			end
		end
		toggle.Keybind.OnRelease = function()
			if toggle.Keybind.Mode == "Hold" and not toggle.Always then toggle:Set(false) end
		end
		toggle.Keybind.OnKeyChanged = syncHotkey
		toggle.Keybind.OnModeChanged = function(mode)
			if mode == "Press" and toggle.Always then toggle:SetAlways(false) end
			syncHotkey()
		end
		win:RegisterHotkey(toggle.Keybind, toggle)
	end
	render(false)
	syncHotkey()
	local flag = register(self, toggle, options, item)
	if flag and toggle.Keybind then win.Flags[flag .. "/Key"] = toggle.Keybind end
	if flag and toggle.Color then win.Flags[flag .. "/Color"] = toggle.Color end
	return toggle
end

function Section:Label(options)
	local name = options.Name or options.Text
	local item = self:_item(Metrics.Row, "Label", name, false)
	local text = label(item.Frame, { Text = name, Truncate = Enum.TextTruncate.AtEnd })
	item.Label = text
	local object = { Item = item, Instance = text }
	function object:Set(value) setText(text, value) end
	object.Keybind, object.Color, object.Gear = addInlineControls(self, item, options, name)
	return object
end

function Section:Divider()
	local item = self:_item(Metrics.DividerH, "Divider", nil, false)
	new("Frame", { Bg = "Element", Position = Offset(1, 1), Size = Dim2(1, -2, 1, -2), Radius = FULL, Border = "Outline" }, item.Frame)
	return item
end

function Section:Keybind(options)
	local item = self:_item(Metrics.Row, "Keybind", options.Name)
	item.Label = label(item.Frame, { Text = options.Name, Truncate = Enum.TextTruncate.AtEnd })
	local object = attachKeybind(self, item, { Key = options.Default, Mode = options.Mode, Modes = options.Modes, Name = options.Name })
	object.Item, object.Callback, object.State = item, options.Callback, false
	-- Callback(state): Press gives true on every press, Toggle flips true/false, Hold gives true on press and false on release.
	object.OnPress = function()
		if object.Mode == "Press" then
			local entry = self.Window.HotkeyEntries[object]
			if entry then entry.Pulse() end
			fire(object.Callback, true)
		elseif object.Mode == "Hold" then
			object.State = true
			fire(object.Callback, true)
		else
			object.State = not object.State
			fire(object.Callback, object.State)
		end
	end
	object.OnRelease = function()
		if object.Mode == "Hold" and object.State then
			object.State = false
			fire(object.Callback, false)
		end
	end
	register(self, object, options, item)
	if options.Hotkey ~= false then self.Window:RegisterHotkey(object, nil) end
	return object
end

function Section:Colorpicker(options)
	local item = self:_item(Metrics.Row, "Colorpicker", options.Name, options.Indexed)
	item.Label = label(item.Frame, { Text = options.Name, Truncate = Enum.TextTruncate.AtEnd })
	local object = attachColor(self, item, options)
	object.Item = item
	register(self, object, options, item)
	return object
end

local function trackWidth(win)
	return win.ColumnW - Metrics.Pad * 2 - 2
end

local function makeTrack(parent)
	local track = new("Frame", {
		Bg = "Element", Position = Offset(1, Metrics.TrackY + 1), Size = Dim2(1, -2, 0, Metrics.TrackH - 2),
		Radius = FULL, Border = "Outline",
	}, parent)
	addGradient(track)
	local fill = new("Frame", { Name = "Fill", Bg = "Accent", Radius = FULL, Size = Dim2(0, 0, 1, 0) }, track)
	addGradient(fill)
	local hit = new("TextButton", { Position = Offset(-4, Metrics.Row), Size = Dim2(1, 8, 0, Metrics.Row + 1), ZIndex = 4 }, parent)
	return track, fill, hit
end

local function makeKnob(track)
	return new("Frame", { Name = "Knob", Bg = "Text", Size = Offset(Metrics.Knob, Metrics.Knob), Radius = FULL, ZIndex = 3 }, track)
end

local function knobPixels(alpha, width)
	return round(Metrics.TrackInset + alpha * (width - Metrics.TrackInset * 2))
end

-- Pixel positions keep the knob centred exactly: the same overhang above and below the track.
local function placeKnob(knob, pixels, animated)
	place(knob, "Position", Offset(pixels - floor(Metrics.Knob / 2), floor((Metrics.TrackH - 2 - Metrics.Knob) / 2)), animated, "Follow")
end

local function alphaAt(track, point)
	local inset = Metrics.TrackInset
	return clamp01((point.X - track.AbsolutePosition.X - inset) / (track.AbsoluteSize.X - inset * 2))
end

function Section:Slider(options)
	local item = self:_item(Metrics.SliderH, "Slider", options.Name)
	local caption = label(item.Frame, { Text = options.Name, Truncate = Enum.TextTruncate.AtEnd })
	local minimum, maximum = options.Min or 0, options.Max or 100
	local decimals, suffix = options.Decimals or 0, options.Suffix or ""
	local slider = { Value = minimum, Item = item, Callback = options.Callback }
	local chip, chipText = makeChip(item.Frame, "", true, Metrics.ValueChipH)
	chip.Position = Dim2(1, -1, 0, 0)
	local apply, fit = fitChip(chip, chipText, 24, function(width) caption.Size = Dim2(1, -(width + Metrics.Gap), 0, Metrics.Row) end)
	local track, fill, hit = makeTrack(item.Frame)
	local knob = makeKnob(track)

	local function render(animated)
		local alpha = maximum == minimum and 0 or (slider.Value - minimum) / (maximum - minimum)
		local pixels = knobPixels(alpha, trackWidth(self.Window))
		placeKnob(knob, pixels, animated)
		place(fill, "Size", Dim2(0, pixels, 1, 0), animated, "Follow")
	end

	local scale = 10 ^ decimals
	function slider:Set(value, silent, animated)
		value = math.clamp(floor(value * scale + 0.5) / scale, minimum, maximum)
		local changed = value ~= slider.Value
		slider.Value = value
		setText(chipText, formatNumber(value, decimals) .. suffix)
		render(animated ~= false)
		if changed and not silent then fire(slider.Callback, value) end
	end

	makeEditable(chip, chipText, function() return formatNumber(slider.Value, decimals) end, function(number) slider:Set(number) end, apply, fit)

	local function fromMouse(point)
		slider:Set(minimum + (maximum - minimum) * alphaAt(track, point))
	end
	hit.InputBegan:Connect(function(input)
		if not isClick(input) then return end
		fromMouse(mousePos())
		beginDrag(fromMouse)
	end)

	table.insert(self.Window.ResizeJobs, function() render(false) end)
	slider:Set(options.Default or minimum, true, false)
	register(self, slider, options, item)
	return slider
end

function Section:RangeSlider(options)
	local item = self:_item(Metrics.SliderH, "Range Slider", options.Name)
	local caption = label(item.Frame, { Text = options.Name, Truncate = Enum.TextTruncate.AtEnd })
	local minimum, maximum = options.Min or 0, options.Max or 100
	local decimals, suffix = options.Decimals or 0, options.Suffix or ""
	local default = options.Default or { minimum, maximum }
	local range = { Value = { default[1], default[2] }, Item = item, Callback = options.Callback }
	local highChip, highText = makeChip(item.Frame, "", true, Metrics.ValueChipH)
	local lowChip, lowText = makeChip(item.Frame, "", true, Metrics.ValueChipH)
	highChip.Position = Dim2(1, -1, 0, 0)
	local highWidth, lowWidth = 24, 24
	local function layoutChips()
		lowChip.Position = Dim2(1, -(highWidth + Metrics.ChipGap + 1), 0, 0)
		caption.Size = Dim2(1, -(highWidth + lowWidth + Metrics.ChipGap + Metrics.Gap), 0, Metrics.Row)
	end
	local applyHigh, fitHigh = fitChip(highChip, highText, 24, function(width) highWidth = width; layoutChips() end)
	local applyLow, fitLow = fitChip(lowChip, lowText, 24, function(width) lowWidth = width; layoutChips() end)
	local track, fill, hit = makeTrack(item.Frame)
	local lowKnob, highKnob = makeKnob(track), makeKnob(track)

	local scale = 10 ^ decimals
	local function snapped(value) return math.clamp(floor(value * scale + 0.5) / scale, minimum, maximum) end
	local function alphaOf(value) return maximum == minimum and 0 or (value - minimum) / (maximum - minimum) end

	local function render(animated)
		local width = trackWidth(self.Window)
		local low, high = knobPixels(alphaOf(range.Value[1]), width), knobPixels(alphaOf(range.Value[2]), width)
		placeKnob(lowKnob, low, animated)
		placeKnob(highKnob, high, animated)
		place(fill, "Position", Dim2(0, low, 0, 0), animated, "Follow")
		place(fill, "Size", Dim2(0, high - low, 1, 0), animated, "Follow")
	end

	function range:Set(value, silent, animated)
		local low, high = snapped(math.min(value[1], value[2])), snapped(math.max(value[1], value[2]))
		local changed = low ~= range.Value[1] or high ~= range.Value[2]
		range.Value = { low, high }
		setText(lowText, formatNumber(range.Value[1], decimals) .. suffix)
		setText(highText, formatNumber(range.Value[2], decimals) .. suffix)
		render(animated ~= false)
		if changed and not silent then fire(range.Callback, range.Value) end
	end

	makeEditable(lowChip, lowText, function() return formatNumber(range.Value[1], decimals) end, function(number)
		range:Set({ math.min(snapped(number), range.Value[2]), range.Value[2] })
	end, applyLow, fitLow)
	makeEditable(highChip, highText, function() return formatNumber(range.Value[2], decimals) end, function(number)
		range:Set({ range.Value[1], math.max(snapped(number), range.Value[1]) })
	end, applyHigh, fitHigh)

	local active = 1
	local function valueAt(point)
		return snapped(minimum + (maximum - minimum) * alphaAt(track, point))
	end
	local function fromMouse(point)
		local value, nextValue = valueAt(point), { range.Value[1], range.Value[2] }
		if active == 1 then
			nextValue[1] = math.min(value, nextValue[2])
		else
			nextValue[2] = math.max(value, nextValue[1])
		end
		range:Set(nextValue)
	end
	hit.InputBegan:Connect(function(input)
		if not isClick(input) then return end
		local point = mousePos()
		local value = valueAt(point)
		local low, high = range.Value[1], range.Value[2]
		active = (low == high and value >= low or low ~= high and abs(value - low) > abs(value - high)) and 2 or 1
		fromMouse(point)
		beginDrag(fromMouse)
	end)

	table.insert(self.Window.ResizeJobs, function() render(false) end)
	range:Set(range.Value, true, false)
	register(self, range, options, item)
	return range
end

-- The option list is its own floating panel above the UI, so opening it never moves the section.
local function buildDropdown(win, parent, options)
	local dropdown = {
		Options = options.Options or {}, Multi = options.Multi == true, Open = false,
		Value = options.Multi and {} or options.Default, Callback = options.Callback,
	}
	if options.Multi and options.Default then
		for _, value in options.Default do dropdown.Value[value] = true end
	end

	local input = new("TextButton", {
		Position = Offset(1, (options.Y or 0) + 1), Size = Dim2(1, -2, 0, Metrics.InputH - 2), Radius = Metrics.Radius, BackgroundTransparency = 0,
	}, parent)
	interactive(input, "Element")
	addGradient(input)
	local stroke = new("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1 }, input)
	bind(stroke, "Color", function() return dropdown.Open and Current.Accent or Current.Outline end)
	local value = label(input, { Fg = "InactiveText", TextSize = 13, X = 7, RowH = Metrics.InputH - 2, Right = 28, Truncate = Enum.TextTruncate.AtEnd })
	makeIcon(input, "layout", 14, "InactiveText", "Element", { AnchorPoint = Vec2(1, 0), Position = Dim2(1, -5, 0, 5) })

	local panel = new("TextButton", { Bg = "Background", BackgroundTransparency = 1, Radius = Metrics.Radius, Visible = false, Size = Offset(10, 0) }, win.Dropdowns)
	win:_registerScale(panel)
	local panelStroke = new("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1, Transparency = 1 }, panel)
	bind(panelStroke, "Color", "Outline")
	local list = new("ScrollingFrame", { Size = Dim2(1, 0, 1, 0), ScrollBarThickness = 0, CanvasSize = Offset(0, 0) }, panel)
	local rows, panelH, flipped = {}, 0, false
	local emptyText = label(panel, { Fg = "InactiveText", Text = options.Empty or "No options", TextSize = 13, X = 9, RowH = Metrics.ListRowH, Right = 8, TextTransparency = 1 })
	dropdown.Reveal = 0

	local function isSelected(option)
		if dropdown.Multi then return dropdown.Value[option] == true end
		return dropdown.Value == option
	end

	local function caption()
		if not dropdown.Multi then return dropdown.Value and tostring(dropdown.Value) or "None" end
		local names = {}
		for _, option in dropdown.Options do
			if dropdown.Value[option] then table.insert(names, tostring(option)) end
		end
		return #names > 0 and table.concat(names, ", ") or "None"
	end

	-- Selection, hover and the panel's reveal are separate numbers combined on every write.
	-- Nothing stores a transparency to restore later, so interrupted animations can't leave stale rows.
	local function applyRow(row)
		local reveal = dropdown.Reveal
		row.Button.BackgroundTransparency = 1 - math.max(row.Sel, row.Hov) * reveal
		row.Bar.BackgroundTransparency = 1 - row.Sel * reveal
		row.Text.TextTransparency = 1 - reveal
	end

	local function applyReveal()
		local reveal = dropdown.Reveal
		panel.BackgroundTransparency = 1 - reveal
		panelStroke.Transparency = 1 - reveal
		emptyText.TextTransparency = 1 - reveal
		for _, row in rows do applyRow(row) end
	end

	local function paint(animated)
		local preset = animated and "Fast" or false
		for _, row in rows do
			local selected = isSelected(row.Option)
			if animated then
				animate(row, "Sel", selected and 1 or 0, "Fast", { Step = function() applyRow(row) end })
			else
				snap(row, "Sel", selected and 1 or 0)
				applyRow(row)
			end
			place(row.Text, "Position", Offset(selected and 17 or 8, row.TextY), animated, "Smooth")
			refresh(row.Text, preset)
			refresh(row.Button, preset)
		end
		setText(value, caption())
	end

	local function rebuild()
		for _, row in rows do row.Button:Destroy() end
		rows = {}
		local count = #dropdown.Options
		for index, option in dropdown.Options do
			local row = { Option = option, Sel = 0, Hov = 0, Hovering = false }
			row.Button = new("TextButton", {
				Bg = function() return row.Hovering and Current.Inline or Current.Tab end,
				BackgroundTransparency = 1, Position = Offset(0, (index - 1) * Metrics.ListRowH), Size = Dim2(1, 0, 0, Metrics.ListRowH),
				Radius = (index == 1 or index == count) and Metrics.Radius or nil,
			}, list)
			row.Bar = new("Frame", { Bg = "Accent", BackgroundTransparency = 1, Position = Offset(7, 6), Size = Offset(2, 12) }, row.Button)
			row.Text = label(row.Button, {
				Text = tostring(option), X = 8, TextSize = 13, RowH = Metrics.ListRowH, Right = 18, Truncate = Enum.TextTruncate.AtEnd, TextTransparency = 1,
				Fg = function() return isSelected(option) and Current.Text or Current.InactiveText end,
			})
			row.TextY = row.Text.Position.Y.Offset
			local function step() applyRow(row) end
			hoverable(row.Button, function()
				row.Hovering = true
				refresh(row.Button)
				animate(row, "Hov", 1, "Fast", { Step = step })
			end, function()
				row.Hovering = false
				refresh(row.Button)
				animate(row, "Hov", 0, "Fast", { Step = step })
			end)
			row.Button.MouseButton1Click:Connect(function()
				if dropdown.Multi then
					dropdown.Value[option] = not dropdown.Value[option] or nil
					paint(true)
					fire(dropdown.Callback, dropdown.Value)
				else
					dropdown:Set(option)
					dropdown:Toggle(false)
				end
			end)
			table.insert(rows, row)
		end
		list.CanvasSize = Offset(0, count * Metrics.ListRowH)
		emptyText.Visible = count == 0
		paint(false)
	end

	local function measure()
		panelH = math.clamp(#dropdown.Options, 1, options.MaxRows or 10) * Metrics.ListRowH
	end

	-- Called each frame while open, so the panel stays attached while the page scrolls or the window moves.
	local function follow()
		local p, s = input.AbsolutePosition, input.AbsoluteSize
		local screen = win.Screen.AbsolutePosition.Y + win.Screen.AbsoluteSize.Y
		local realH = panelH * win.DPI
		flipped = p.Y + s.Y + 6 + realH > screen - 8 and p.Y - 6 - realH > win.Screen.AbsolutePosition.Y + 8
		local goal = toLayer(Vec2(p.X, flipped and p.Y - 6 or p.Y + s.Y + 6))
		panel.AnchorPoint = flipped and Vec2(0, 1) or Vec2(0, 0)
		panel.Position = Offset(goal.X, goal.Y)
	end
	dropdown.Follow = follow

	function dropdown:Toggle(open)
		if open == nil then open = not dropdown.Open end
		if open == dropdown.Open then return end
		dropdown.Open = open
		refresh(stroke)
		local width = input.AbsoluteSize.X / win.DPI
		if open then
			if win.OpenDropdown and win.OpenDropdown ~= dropdown then win.OpenDropdown:Toggle(false) end
			win.OpenDropdown = dropdown
			measure()
			follow()
			panel.Visible = true
			panel.Size = Offset(width, panelH)
			animate(dropdown, "Reveal", 1, "Fast", { Step = applyReveal })
			local selectedIndex = not dropdown.Multi and table.find(dropdown.Options, dropdown.Value)
			local furthest = math.max(0, #dropdown.Options * Metrics.ListRowH - panelH)
			list.CanvasPosition = Vec2(0, selectedIndex and math.clamp(floor((selectedIndex - 1) * Metrics.ListRowH - (panelH - Metrics.ListRowH) / 2), 0, furthest) or 0)
			for index, row in rows do
				local y = (index - 1) * Metrics.ListRowH
				row.Button.Position = Offset(0, y + 6)
				task.delay(math.min(index, 10) * 0.012, function()
					if row.Button.Parent then place(row.Button, "Position", Offset(0, y), dropdown.Open, "Smooth") end
				end)
			end
		else
			if win.OpenDropdown == dropdown then win.OpenDropdown = nil end
			animate(dropdown, "Reveal", 0, "Fast", {
				Step = applyReveal,
				Done = function() panel.Visible = false end,
			})
		end
	end

	function dropdown:Set(newValue, silent)
		if dropdown.Multi then
			dropdown.Value = {}
			for key, option in newValue do
				if option then dropdown.Value[type(key) == "string" and key or option] = true end
			end
		else
			dropdown.Value = newValue
		end
		paint(true)
		if not silent then fire(dropdown.Callback, dropdown.Multi and dropdown.Value or newValue) end
	end

	function dropdown:SetOptions(newOptions)
		dropdown.Options = newOptions
		rebuild()
		if dropdown.Open then
			measure()
			panel.Size = Offset(input.AbsoluteSize.X / win.DPI, panelH)
		end
	end

	dropdown.Input, dropdown.Panel = input, panel
	input.MouseButton1Click:Connect(function()
		-- The press that closes an open list must not reopen it on release.
		if win.DropdownClosedBy == input and os.clock() - win.DropdownClosedAt < 0.25 then return end
		dropdown:Toggle()
	end)
	rebuild()
	return dropdown
end

function Section:Dropdown(options)
	local item = self:_item(Metrics.DropdownH, "Dropdown", options.Name)
	label(item.Frame, { Text = options.Name, Truncate = Enum.TextTruncate.AtEnd })
	options.Y = Metrics.DropdownH - Metrics.InputH
	local dropdown = buildDropdown(self.Window, item.Frame, options)
	dropdown.Item = item
	register(self, dropdown, options, item)
	return dropdown
end

function Section:Button(options)
	local item = self:_item(Metrics.ButtonH, "Button", options.Name)
	local win = self.Window
	local button = new("TextButton", { Position = Offset(1, 1), Size = Dim2(1, -2, 0, Metrics.ButtonH - 2), Radius = Metrics.Radius, Border = "Outline", BackgroundTransparency = 0 }, item.Frame)
	interactive(button, "Element", "HoveredElement", "Inline")
	addGradient(button)
	local armed
	-- The label spans the whole button and centres itself, so changing the text never moves or re-measures it.
	local text = label(button, {
		Text = options.Name, TextSize = 13, RowH = Metrics.ButtonH - 2, X = 6, Right = 6, Truncate = Enum.TextTruncate.AtEnd,
		Fg = function() return armed and Current.Accent or Current.Text end,
	})
	text.TextXAlignment = Enum.TextXAlignment.Center
	local object = { Item = item, Instance = button, Callback = options.Callback }
	-- Confirm: the first click only rewrites this button's own label, the second one runs the callback.
	local confirm = options.Confirm or options.DoubleClick
	local function setArmed(state)
		armed = state
		setText(text, state and (options.ConfirmText or "Are you sure?") or options.Name)
		refresh(text, "Fast")
	end
	button.MouseButton1Click:Connect(function()
		if not confirm then fire(object.Callback); return end
		if armed then
			setArmed(nil)
			fire(object.Callback)
			return
		end
		local mark = {}
		setArmed(mark)
		task.delay(options.ConfirmTime or 3, function()
			if armed == mark then setArmed(nil) end
		end)
	end)
	return object
end

function Section:Textbox(options)
	local item = self:_item(Metrics.InputH, "Textbox", options.Name or options.Placeholder)
	local frame = new("Frame", { Bg = "Element", Position = Offset(1, 1), Size = Dim2(1, -2, 0, Metrics.InputH - 2), Radius = Metrics.Radius, Border = "Outline" }, item.Frame)
	addGradient(frame)
	local box = new("TextBox", {
		Fg = "Text", PlaceholderText = options.Placeholder or options.Name or "", Text = options.Default or "", TextSize = 13,
		Position = Offset(7, capOffset(Metrics.InputH - 2, 13)), Size = Dim2(1, -14, 0, 18), ClearTextOnFocus = false,
	}, frame)
	bind(box, "PlaceholderColor3", "InactiveText")
	local object = { Item = item, Instance = box, Value = box.Text, Callback = options.Callback }
	function object:Set(text, silent)
		box.Text = text
		object.Value = text
		if not silent then fire(object.Callback, text) end
	end
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	local focused = false
	bind(stroke, "Color", function() return focused and Current.Accent or Current.Outline end)
	box.Focused:Connect(function() focused = true; refresh(stroke) end)
	box.FocusLost:Connect(function()
		focused = false
		refresh(stroke)
		object:Set(box.Text)
	end)
	register(self, object, options, item)
	return object
end

function Section:Listbox(options)
	local height = options.Height or 177
	local item = self:_item(height, "Listbox", options.Name, false)
	local frame = new("ScrollingFrame", {
		Bg = "Inline", Position = Offset(1, 1), Size = Dim2(1, -2, 0, height - 2), Radius = Metrics.Radius, Border = "Outline",
		ScrollBarThickness = 0, CanvasSize = Offset(0, 0),
	}, item.Frame)
	local listbox = { Options = {}, Value = nil, Item = item, Callback = options.Callback }
	local rows = {}
	local emptyText = label(frame, { Fg = "InactiveText", Text = options.Empty or "Nothing here yet", TextSize = 13, X = 10, Y = 2, RowH = Metrics.ListRowH, Right = 8 })

	local function paint(animated)
		local preset = animated and "Fast" or false
		for _, row in rows do
			local selected = listbox.Value == row.Option
			refresh(row.Text, preset)
			place(row.Text, "Position", Offset(selected and 17 or 8, row.TextY), animated, "Smooth")
			place(row.Bar, "BackgroundTransparency", selected and 0 or 1, animated, "Fast")
		end
	end

	function listbox:Set(value, silent)
		listbox.Value = value
		paint(true)
		if not silent then fire(listbox.Callback, value) end
	end

	function listbox:SetOptions(optionsList)
		for _, row in rows do row.Button:Destroy() end
		rows, listbox.Options = {}, optionsList
		for index, option in optionsList do
			local row = { Option = option }
			row.Button = new("TextButton", {
				Bg = "HoveredElement", BackgroundTransparency = 1, Position = Offset(2, 2 + (index - 1) * Metrics.ListRowH),
				Size = Dim2(1, -4, 0, Metrics.ListRowH), Radius = Metrics.SmallRadius,
			}, frame)
			NoFade[row.Button] = true
			row.Bar = new("Frame", { Bg = "Accent", BackgroundTransparency = 1, Position = Offset(6, 6), Size = Offset(2, 12) }, row.Button)
			row.Text = label(row.Button, {
				Text = option, X = 8, TextSize = 13, RowH = Metrics.ListRowH, Right = 18, Truncate = Enum.TextTruncate.AtEnd,
				Fg = function() return listbox.Value == option and Current.Text or Current.InactiveText end,
			})
			row.TextY = row.Text.Position.Y.Offset
			hoverable(row.Button, function() animate(row.Button, "BackgroundTransparency", 0, "Fast") end, function() animate(row.Button, "BackgroundTransparency", 1, "Fast") end)
			row.Button.MouseButton1Click:Connect(function() listbox:Set(option) end)
			table.insert(rows, row)
		end
		frame.CanvasSize = Offset(0, 4 + #optionsList * Metrics.ListRowH)
		emptyText.Visible = #optionsList == 0
		paint(false)
	end

	listbox:SetOptions(options.Options or {})
	return listbox
end

function Section:_beginDrag()
	if self.Dropping then return end
	local win, start = self.Window, mousePos()
	local grab = start - self.Root.AbsolutePosition
	local stroke = self.Card:FindFirstChildOfClass("UIStroke")
	local lifted, ghost, ghostFader = false, nil, nil

	local function slotPosition(column)
		return column.Scroll.AbsolutePosition + Vec2(0, self.Y - column.Scroll.CanvasPosition.Y)
	end

	local function targetFor(point)
		local page = self.Tab
		local left, right = page.Columns[1], page.Columns[2]
		local boundary = (left.Scroll.AbsolutePosition.X + left.Scroll.AbsoluteSize.X + right.Scroll.AbsolutePosition.X) / 2
		local column = point.X < boundary and left or right
		local current = table.find(column.Sections, self)
		local index = 1
		for position, other in column.Sections do
			if other ~= self then
				local middle = column.Scroll.AbsolutePosition.Y - column.Scroll.CanvasPosition.Y + other.Y + other.TotalH / 2
				-- A dead zone either side of each midpoint stops sections trading places repeatedly.
				local bias = (current and position < current) and -14 or 14
				if point.Y > middle + bias then index += 1 end
			end
		end
		return column, index
	end

	local function lift()
		lifted = true
		self.Dragging = true
		win:CloseFloating()
		local absolute, size = self.Root.AbsolutePosition, self.Root.AbsoluteSize
		local layer = toLayer(absolute)
		self.Root.Parent = win.DragLayer
		self.Root.Size = Offset(size.X, self.TotalH)
		self.Root.Position = Offset(layer.X, layer.Y)
		refresh(stroke)
		ghost = new("Frame", {
			Bg = "Accent", BackgroundTransparency = 0.92, Radius = Metrics.CardRadius, Border = "Accent",
			Position = Offset(layer.X, layer.Y), Size = Offset(size.X, self.TotalH), ZIndex = -1,
		}, win.DragLayer)
		ghostFader = newFader(ghost)
		ghost.Visible = false
		ghostFader:Show(nil, "Fast")
	end

	local function move(point)
		if not lifted then
			if (point - start).Magnitude < 5 then return end
			lift()
		end
		local goal = toLayer(point - grab)
		animate(self.Root, "Position", Offset(goal.X, goal.Y), "Follow")
		local column, index = targetFor(point)
		local current = table.find(column.Sections, self)
		if column ~= self.Column or current ~= index then
			local previous = self.Column
			table.remove(previous.Sections, table.find(previous.Sections, self))
			table.insert(column.Sections, math.min(index, #column.Sections + 1), self)
			self.Column = column
			if previous ~= column then previous:Layout(true) end
			column:Layout(true)
		end
	end

	local function frame(point)
		if not lifted then return end
		-- Scroll the column while the pointer rests near its top or bottom edge.
		local column = self.Column
		local scroll = column.Scroll
		local top, bottom = scroll.AbsolutePosition.Y, scroll.AbsolutePosition.Y + scroll.AbsoluteSize.Y
		if point.X >= scroll.AbsolutePosition.X and point.X <= scroll.AbsolutePosition.X + scroll.AbsoluteSize.X then
			if point.Y < top + 36 then column:ScrollTo(column.Target - 8)
			elseif point.Y > bottom - 36 then column:ScrollTo(column.Target + 8) end
		end
		local slot = toLayer(slotPosition(column))
		animate(ghost, "Position", Offset(slot.X, slot.Y), "Smooth")
	end

	beginDrag(move, function()
		if not lifted then return end
		local column = self.Column
		column:Layout(true)
		self.Dragging = false
		self.Dropping = true
		refresh(stroke)
		local goal = toLayer(slotPosition(column))
		local doomed = ghost
		ghostFader:Hide(function() doomed:Destroy() end)
		animate(self.Root, "Position", Offset(goal.X, goal.Y), "Smooth", {
			Done = function()
				self.Dropping = false
				self.Root.Parent = column.Scroll
				self.Root.Size = Dim2(1, 0, 0, self.TotalH)
				self.Root.Position = Offset(0, self.Y)
			end,
		})
	end, frame)
end

-------------------------------------------------------------------------------
-- Tab
-------------------------------------------------------------------------------

function Tab:Section(options)
	assert(not self.Subs, "This tab has sub-tabs: create its sections with SubTab:Section.")
	local win = self.Window
	local column = self.Columns[options.Side or 1]
	local headerH = options.Description and Metrics.HeaderDescH or Metrics.HeaderH
	local root = new("Frame", { Name = options.Name, Size = Dim2(1, 0, 0, headerH) }, column.Scroll)
	local header = new("TextButton", { Size = Dim2(1, 0, 0, headerH - 8) }, root)
	local hovering = false
	local titleColor = function() return hovering and Current.Text or Current.InactiveText end
	local icon = makeIcon(header, options.Icon or "cube", 16, titleColor, "Tab")
	local title = label(header, { Text = options.Name, X = 27, Fg = titleColor, Truncate = Enum.TextTruncate.AtEnd })
	if options.Description then
		label(header, { Fg = "InactiveText", Text = options.Description, TextSize = 11, RowH = 14, Y = 18, Truncate = Enum.TextTruncate.AtEnd })
	end
	local section
	local card = new("Frame", {
		Bg = "Inline", Active = true, Position = Offset(1, headerH + 1), Size = Dim2(1, -2, 0, 0),
		Radius = Metrics.CardRadius,
	}, root)
	local stroke = new("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1 }, card)
	bind(stroke, "Color", function() return section and section.Dragging and Current.Accent or Current.Outline end)
	local body = new("Frame", { Position = Offset(Metrics.Pad - 1, -1), Size = Dim2(1, -(Metrics.Pad - 1) * 2, 1, 2) }, card)
	section = setmetatable({
		Window = win, Tab = self, Column = column, Name = options.Name, Root = root, Card = card, Body = body,
		Items = {}, HeaderH = headerH, TotalH = headerH, CardH = 0, Y = 0, Dragging = false, Dropping = false, Title = title,
	}, Section)
	table.insert(column.Sections, section)
	table.insert(win.Sections, section)
	hoverable(header, function() hovering = true; icon.Update(); refresh(title) end, function() hovering = false; icon.Update(); refresh(title) end)
	header.MouseButton1Down:Connect(function() section:_beginDrag() end)
	section:Layout(false)
	return section
end

local SUB_BAR, SUB_H = 24, 32

local function buildColumns(win, owner, parent)
	owner.Columns = {}
	for index = 1, 2 do
		local scroll = new("ScrollingFrame", {
			Position = Offset(Metrics.Pad + (index - 1) * (win.ColumnW + Metrics.Pad), 0),
			Size = Dim2(0, win.ColumnW, 1, 0), ScrollBarThickness = 0, CanvasSize = Offset(0, 0),
			ScrollingEnabled = not UserInputService.MouseEnabled, ClipsDescendants = true,
		}, parent)
		local column = setmetatable({ Scroll = scroll, Sections = {}, Target = 0, ContentH = 0, Tab = owner, Index = index, ShowTop = false, ShowBottom = false }, Column)
		local function edge(position, rotation)
			local frame = new("Frame", { Bg = "Tab", BackgroundTransparency = 1, Position = position, Size = Offset(win.ColumnW, 14), ZIndex = 4 }, parent)
			new("UIGradient", { Rotation = rotation, Transparency = NumberSequence.new(1, 0) }, frame)
			return frame
		end
		local edgeX = Metrics.Pad + (index - 1) * (win.ColumnW + Metrics.Pad)
		column.FadeTop, column.FadeBottom = edge(Offset(edgeX, 0), 270), edge(Dim2(0, edgeX, 1, -14), 90)
		table.insert(win.Columns, column)
		owner.Columns[index] = column
	end
end

SubTab.Section = Tab.Section

-- Sub-tabs split one tab into pages, each with its own sections: Tab:SubTab({ Name = "Players" }):Section({ ... })
function Tab:SubTab(options)
	local win = self.Window
	if not self.Subs then
		self.Subs, self.BarX = {}, 0
		for _, column in self.Columns do column.Scroll.Visible = false end
		self.Bar = new("Frame", { Name = "SubTabs", Position = Offset(Metrics.Pad, 0), Size = Dim2(1, -Metrics.Pad * 2, 0, SUB_BAR) }, self.Page)
		self.Pill = new("Frame", { Bg = "Accent", Size = Offset(0, SUB_BAR - 2), Radius = Metrics.Radius, Border = "Outline", Visible = false }, self.Bar)
		addGradient(self.Pill)
	end
	local sub = setmetatable({ Window = win, Parent = self, Name = self.Name .. "/" .. options.Name, TopH = SUB_H }, SubTab)
	table.insert(win.Extras, sub)
	sub.Page = new("Frame", { Name = options.Name, Position = Offset(0, SUB_H), Size = Dim2(1, 0, 1, -SUB_H), Visible = false }, self.Page)
	buildColumns(win, sub, sub.Page)
	local width = math.max(60, #options.Name * 7 + 24)
	sub.X, sub.W = self.BarX, width
	self.BarX += width + Metrics.Gap
	sub.Button = new("TextButton", { Position = Offset(sub.X, 0), Size = Offset(width, SUB_BAR), ZIndex = 2 }, self.Bar)
	local hovering = false
	sub.Label = centeredLabel(sub.Button, width, {
		Text = options.Name, RowH = SUB_BAR,
		Fg = function() return (self.Sub == sub or hovering) and Current.Text or Current.InactiveText end,
	})
	hoverable(sub.Button, function() hovering = true; refresh(sub.Label) end, function() hovering = false; refresh(sub.Label) end)
	sub.Button.MouseButton1Click:Connect(function() self:SelectSub(sub) end)
	table.insert(self.Subs, sub)
	if not self.Sub then self:SelectSub(sub, true) end
	return sub
end

function Tab:SelectSub(sub, instant)
	if self.Sub == sub then return end
	local previous = self.Sub
	self.Sub = sub
	self.Window:CloseFloating()
	if previous then
		previous.Page.Visible = false
		refresh(previous.Label)
	end
	sub.Page.Visible = true
	refresh(sub.Label)
	self.Pill.Visible = true
	place(self.Pill, "Position", Offset(sub.X + 1, 1), not instant, "Knob")
	place(self.Pill, "Size", Offset(sub.W - 2, SUB_BAR - 2), not instant, "Knob")
	if not instant then
		sub.Page.Position = Offset(0, SUB_H + 10)
		animate(sub.Page, "Position", Offset(0, SUB_H), "Soft")
	end
end

-------------------------------------------------------------------------------
-- Window
-------------------------------------------------------------------------------

local function guiParent(screen)
	local ok = false
	if typeof(gethui) == "function" then
		ok = pcall(function() screen.Parent = gethui() end)
	end
	if not ok then
		ok = pcall(function() screen.Parent = game:GetService("CoreGui") end)
	end
	if not ok or not screen.Parent then
		screen.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
end

function Window:Category(name)
	local y = self.SidebarY + (self.SidebarHasTabs and Metrics.TabToCategory or 0)
	label(self.Sidebar, { Fg = "InactiveText", Text = name, TextSize = 9, X = Metrics.Pad, RowH = 12, Y = y - 6, W = 120 })
	self.SidebarY = y
	self.SidebarAfterCategory = true
end

function Window:Tab(options)
	local y = self.SidebarY + (self.SidebarAfterCategory and Metrics.CategoryToTab or Metrics.TabPitch)
	self.SidebarAfterCategory, self.SidebarHasTabs = false, true
	self.SidebarY = y

	local tab = setmetatable({ Window = self, Name = options.Name, Y = y - Metrics.TabH / 2 }, Tab)
	local button = new("TextButton", { Position = Offset(Metrics.Pad, tab.Y), Size = Offset(Metrics.TabW, Metrics.TabH), ZIndex = 2 }, self.Sidebar)
	tab.Button = button
	local hovering = false
	local isActive = function() return self.CurrentTab == tab end
	local color = function() return (isActive() or hovering) and Current.Text or Current.InactiveText end
	local hole = function() return isActive() and Current.Inline or Current.Background end
	tab.Icon = makeIcon(button, options.Icon or "cube", 16, color, hole, { Position = Offset(6, 6) })
	tab.Label = label(button, { Text = options.Name, X = 33, TextSize = 13, RowH = Metrics.TabH, Fg = color, Right = 6, Truncate = Enum.TextTruncate.AtEnd })
	tab.LabelY = tab.Label.Position.Y.Offset

	tab.Page = new("Frame", { Name = options.Name, Size = Dim2(1, 0, 1, 0), Visible = false }, self.Pages)
	buildColumns(self, tab, tab.Page)

	local function paint()
		tab.Icon.Update()
		refresh(tab.Label)
		animate(tab.Label, "Position", Offset(hovering and not isActive() and 35 or 33, tab.LabelY), "Smooth")
	end
	tab.Paint = paint
	hoverable(button, function() hovering = true; paint() end, function() hovering = false; paint() end)
	button.MouseButton1Click:Connect(function() self:SelectTab(tab) end)
	table.insert(self.Tabs, tab)
	if not self.CurrentTab then self:SelectTab(tab, true) end
	return tab
end

function Window:Cols()
	local tab = self.CurrentTab
	return (tab.Sub or tab).Columns
end

function Window:SelectTab(tab, instant)
	local sub
	if tab.Parent then sub, tab = tab, tab.Parent end
	if sub then tab:SelectSub(sub, instant) end
	if self.CurrentTab == tab then return end
	local previous = self.CurrentTab
	self.CurrentTab = tab
	self:CloseFloating()
	if previous then
		previous.Page.Visible = false
		previous.Paint()
	end
	tab.Page.Visible = true
	tab.Paint()
	self.Indicator.Visible = true
	place(self.Indicator, "Position", Offset(Metrics.Pad + 1, tab.Y + 1), not instant, "Soft")
	if not instant then
		self.Veil.BackgroundTransparency = 0
		animate(self.Veil, "BackgroundTransparency", 1, "Soft")
		tab.Page.Position = Offset(0, 10)
		animate(tab.Page, "Position", Offset(0, 0), "Soft")
	end
end

local HK_H, HK_FIRST, HK_PITCH, HK_NAME_X = 26, 33, 31, 46

-- A bind counts as assigned when the player has set a real key on it.
local function hotkeyAssigned(object)
	return object.Key ~= nil and object.Key ~= Enum.KeyCode.Unknown
end

-- Re-sorts the visible rows and applies the "only assigned" / "only enabled" filters.
function Window:_layoutHotkeys()
	local row = 0
	for _, object in self.HotkeyOrder do
		local entry = self.HotkeyEntries[object]
		if entry then
			local want = true
			if self.HotkeyOnlyAssigned and not hotkeyAssigned(object) then want = false end
			if self.HotkeyOnlyEnabled and not entry.IsOn() then want = false end
			if want then
				row += 1
				local goal = Offset(1, HK_FIRST + HK_PITCH * (row - 1))
				if not entry.Shown then
					entry.Frame.Position = Offset(-14, goal.Y.Offset)
					entry.Frame.Visible = true
				end
				animate(entry.Frame, "Position", goal, "Settle")
			elseif entry.Shown then
				entry.Frame.Visible = false
			end
			entry.Shown = want
		end
	end
end

function Window:SetHotkeyFilter(onlyAssigned, onlyEnabled)
	if onlyAssigned ~= nil then self.HotkeyOnlyAssigned = onlyAssigned == true end
	if onlyEnabled ~= nil then self.HotkeyOnlyEnabled = onlyEnabled == true end
	self:_layoutHotkeys()
end

-- Every bind gets a permanent row: [switch | name | key]. The switch mirrors the state of the feature.
-- Press rows have a dot that flashes on each press.
function Window:RegisterHotkey(object, toggle)
	if self.HotkeyEntries[object] then return end
	local entry = { Object = object, Toggle = toggle, Flash = false, Shown = false }
	local frame = new("Frame", { Bg = "Background", Size = Offset(140, HK_H), Radius = Metrics.FloatRadius, Border = "Outline", Visible = false }, self.Hotkeys)
	entry.Frame = frame
	local function isOn()
		if toggle then return toggle.Value == true end
		return object.State == true
	end
	entry.IsOn = isOn
	local function usesSwitch() return object.Mode ~= "Press" end
	local function isActive()
		if object.Mode == "Press" then return entry.Flash end
		return isOn()
	end

	-- Always switch
	local track = new("Frame", {
		Bg = function() return isOn() and Current.Accent or Current.Element end,
		Position = Offset(11, 6), Size = Offset(Metrics.ToggleW - 2, Metrics.ToggleH - 2), Radius = FULL, Border = "Outline",
	}, frame)
	addGradient(track)
	local knob = new("Frame", {
		Bg = function() return isOn() and Current.Text or Current.InactiveText end,
		Size = Offset(Metrics.ToggleKnob, Metrics.ToggleKnob), Position = Offset(2, 2), Radius = FULL,
	}, track)

	-- Press dot
	local dot = new("Frame", {
		Bg = function() return entry.Flash and Current.Accent or Current.Element end,
		Position = Offset(20, 9), Size = Offset(8, 8), Radius = FULL,
	}, frame)

	local text = label(frame, {
		Text = object.Name or "Key", TextSize = 12, X = HK_NAME_X, RowH = HK_H, Weight = Enum.FontWeight.SemiBold,
		Fg = function() return isActive() and Current.Text or Current.InactiveText end,
	})
	local chip, caption = makeChip(frame, "", false, 18)
	chip.Position = Offset(0, 5)
	-- The key chip takes its fill straight from the theme (Inline), no gradient and no extra tint.
	for _, child in chip:GetChildren() do
		if child:IsA("UIGradient") then child:Destroy() end
	end
	bind(chip, "BackgroundColor3", "Inline")
	local chipStroke = chip:FindFirstChildOfClass("UIStroke")
	if chipStroke then bind(chipStroke, "Color", "Inline") end
	local chipW = 20

	local function layout()
		local nameW = math.ceil(text.TextBounds.X)
		chip.Position = Offset(HK_NAME_X + nameW + 8, 5)
		frame.Size = Offset(HK_NAME_X + nameW + 8 + chipW + 10, HK_H)
	end
	fitChip(chip, caption, 20, function(width) chipW = width; layout() end)
	text:GetPropertyChangedSignal("TextBounds"):Connect(layout)

	function entry.Update(animated)
		local sw = usesSwitch()
		track.Visible, dot.Visible = sw, not sw
		setText(caption, keyName(object.Key))
		local x = isOn() and (Metrics.ToggleW - 2 - Metrics.ToggleKnob - 2) or 2
		place(knob, "Position", Offset(x, 2), animated, "Knob")
		local preset = animated and "Fast" or false
		for _, inst in { track, knob, dot, text, chip, chipStroke } do refresh(inst, preset) end
		layout()
	end
	function entry.Pulse()
		entry.Flash = true
		entry.Update(true)
		task.delay(0.18, function()
			entry.Flash = false
			if frame.Parent then entry.Update(true) end
		end)
	end

	-- Follows key / mode / state changes of the bind by itself, whoever changes them.
	local lastKey, lastMode, lastOn = object.Key, object.Mode, isOn()
	table.insert(self.Connections, RunService.Heartbeat:Connect(function()
		if not frame.Parent then return end
		local on = isOn()
		if object.Key ~= lastKey or object.Mode ~= lastMode or on ~= lastOn then
			lastKey, lastMode, lastOn = object.Key, object.Mode, on
			entry.Update(true)
			self:_layoutHotkeys()
		end
	end))

	self.HotkeyEntries[object] = entry
	table.insert(self.HotkeyOrder, object)
	entry.Update(false)
	self:_layoutHotkeys()
end

-- Kept for the old call sites: updates the highlight of an existing row.
function Window:SetHotkeyActive(object, active)
	local entry = self.HotkeyEntries[object]
	if not entry then return end
	entry.Update(true)
	self:_layoutHotkeys()
end

function Window:Notify(options)
	if type(options) == "string" then options = { Text = options } end
	options = {
		Text = options.Text or (options.Title and options.Description and options.Title .. ": " .. options.Description) or options.Description or options.Title,
		Icon = options.Icon, Duration = options.Duration or options.Time,
	}
	local frame = new("Frame", { Bg = "Background", Size = Offset(60, 28), Radius = Metrics.FloatRadius, Border = "Outline", Visible = false }, self.Notifications)
	makeIcon(frame, options.Icon or "check", 14, function() return RGB(112, 205, 132) end, "Background", { Position = Offset(8, 7) })
	local text = label(frame, { Text = options.Text, TextSize = 12, X = 28, RowH = 28, W = 340, Truncate = Enum.TextTruncate.AtEnd })
	local entry = { Frame = frame, Fader = newFader(frame) }
	local function fit() frame.Size = Offset(math.min(math.ceil(text.TextBounds.X), 340) + 38, 28) end
	text:GetPropertyChangedSignal("TextBounds"):Connect(fit)
	fit()
	table.insert(self.NotifyStack, 1, entry)
	local function stack()
		local count = #self.NotifyStack
		for index, item in self.NotifyStack do
			local y = (count - index) * 36
			if not item.Placed then
				item.Placed = true
				item.Frame.Position = Offset(-36, y)
			end
			animate(item.Frame, "Position", Offset(0, y), "Settle")
		end
	end
	function entry.Dismiss()
		if entry.Gone then return end
		entry.Gone = true
		table.remove(self.NotifyStack, table.find(self.NotifyStack, entry))
		animate(frame, "Position", Offset(-36, frame.Position.Y.Offset), "Smooth")
		entry.Fader:Hide(function() frame:Destroy() end)
		stack()
	end
	stack()
	entry.Fader:Show()
	-- Rapid actions shouldn't bury the screen.
	if #self.NotifyStack > 6 then self.NotifyStack[#self.NotifyStack].Dismiss() end
	task.delay(options.Duration or 3, entry.Dismiss)
end

function Window:ApplyTheme(name, silent)
	local theme = Themes[name]
	if not theme then return end
	for key, value in theme do Current[key] = value end
	self.ThemeName = name
	-- Off-screen pages take the new colours immediately, so only what's visible animates.
	local hidden = {}
	for _, tab in self.Tabs do
		if tab ~= self.CurrentTab then
			for _, inst in tab.Page:GetDescendants() do hidden[inst] = true end
		end
	end
	for inst in Bound do refresh(inst, not hidden[inst] and "Soft" or false) end
	for _, row in self.ThemeRows do row.Color:Set(Current[row.Key], nil, true) end
	if not silent then self:Notify(('Applied "%s" theme.'):format(name)) end
end

-- Dragging a theme colour would otherwise repaint hundreds of instances per mouse movement.
function Window:SetThemeColor(key, color)
	Current[key] = color
	self.PendingThemeKeys[key] = true
end

function Window:_flushThemeColors(dt)
	self.ThemeClock += dt
	if next(self.PendingThemeKeys) == nil or self.ThemeClock < 1 / 30 then return end
	self.ThemeClock = 0
	for key in self.PendingThemeKeys do
		local set = ByKey[key]
		if set then
			for inst, prop in set do snap(inst, prop, Current[key]) end
		end
		self.PendingThemeKeys[key] = nil
	end
	for inst in Dynamic do refresh(inst, false) end
end

function Window:SetCasing(name, silent)
	Casing = name
	applyTextSettings()
	if not silent then self:Notify(('Set casing to "%s".'):format(name)) end
end

function Window:SetFont(name)
	FontFamily = Fonts[name] or name
	applyTextSettings()
end

function Window:SetTextWeight(name)
	BodyWeight = Enum.FontWeight[name]
	applyTextSettings()
end

function Window:CloseFloating()
	if self.OpenDropdown then self.OpenDropdown:Toggle(false) end
	self:ClosePopup()
end

local function hidePopup(win, popup)
	win.LastPopupAnchor, win.LastPopupTime = popup.Anchor, os.clock()
	if popup.OnClose then popup.OnClose() end
	local position = popup.Frame.Position
	animate(popup.Frame, "Position", Offset(position.X.Offset, position.Y.Offset - 4), "Fast")
	popup.Fader:Hide()
end

-- toParent closes only the top popup and hands focus back to the popup that opened it.
function Window:ClosePopup(toParent)
	local popup = self.ActivePopup
	if not popup then return end
	local stack = self.PopupStack
	hidePopup(self, popup)
	self.ActivePopup = toParent and table.remove(stack) or nil
	if not toParent then
		for index = #stack, 1, -1 do hidePopup(self, table.remove(stack, index)) end
	end
end

function Window:_openPopup(popup, anchor, absolute)
	if self.LastPopupAnchor == anchor and os.clock() - self.LastPopupTime < 0.2 then return false end
	local stack = self.PopupStack
	-- A popup opened from inside another popup (a colour picker in an Options menu) keeps its parent open.
	while self.ActivePopup and not anchor:IsDescendantOf(self.ActivePopup.Frame) do
		hidePopup(self, self.ActivePopup)
		self.ActivePopup = table.remove(stack)
	end
	if self.ActivePopup then table.insert(stack, self.ActivePopup) end
	popup.Frame.ZIndex = #stack + 1
	local point = toLayer(absolute)
	local viewport, size = self.Screen.AbsoluteSize, popup.Frame.Size
	local x = math.clamp(floor(point.X), 8, math.max(8, viewport.X - size.X.Offset * self.DPI - 8))
	local y = math.clamp(floor(point.Y), 8, math.max(8, viewport.Y - size.Y.Offset * self.DPI - 8))
	popup.Anchor = anchor
	popup.Frame.Position = Offset(x, y - 6)
	animate(popup.Frame, "Position", Offset(x, y), "Settle")
	popup.Fader:Show()
	self.ActivePopup = popup
	return true
end

function Window:OpenKeybindMenu(chip, object)
	local menu = self.KeybindMenu
	menu.Target = object
	menu.Paint(false)
	local p, s = chip.AbsolutePosition, chip.AbsoluteSize
	self:_openPopup(menu, chip, Vec2(p.X, p.Y + s.Y + Metrics.Gap))
end

function Window:OpenPicker(swatch, color)
	local picker = self.Picker
	if self.LastPopupAnchor == swatch and os.clock() - self.LastPopupTime < 0.2 then return end
	local p, s = swatch.AbsolutePosition, swatch.AbsoluteSize
	picker.Target = color
	picker.Sync()
	self:_openPopup(picker, swatch, Vec2(p.X - 8, p.Y + s.Y + Metrics.Pad))
end

function Window:_clamped(target, x, y, cachedSize, cachedScreen)
	local screen, size, anchor = cachedScreen or self.Screen.AbsoluteSize, cachedSize or target.AbsoluteSize, target.AnchorPoint
	local keep = math.min(60, size.X)
	local left = math.clamp(x - anchor.X * size.X, keep - size.X, math.max(keep - size.X, screen.X - keep))
	local top = math.clamp(y - anchor.Y * size.Y, 0, math.max(0, screen.Y - 30))
	return Offset(round(left + anchor.X * size.X), round(top + anchor.Y * size.Y))
end

function Window:_modalPosition(offsetY)
	return Offset(floor((self.Width - 420) / 2), floor((self.Height - 340) / 2) + offsetY)
end

-- Sizes stay even so a centre anchor still lands on whole pixels.
local function evenClamp(value, minimum, maximum)
	local clamped = math.clamp(floor(value), minimum, math.max(minimum, maximum))
	return clamped - clamped % 2
end

-- The tab list and search box must both fit, however many tabs were added.
function Window:_minHeight()
	local needed = math.ceil(self.SidebarY + Metrics.TabH / 2 + Metrics.Gap + Metrics.SearchH + Metrics.Pad)
	return evenClamp(math.max(self.MinSize.Y, needed + needed % 2), 0, math.huge)
end

function Window:_applySize(width, height)
	self.Width, self.Height = width, height
	self.ColumnW = (width - Metrics.ContentX - Metrics.Pad * 3) / 2
	self.Holder.Size = Offset(width, height)
	for _, column in self.Columns do
		local x = Metrics.Pad + (column.Index - 1) * (self.ColumnW + Metrics.Pad)
		column.Scroll.Position = Offset(x, 0)
		column.Scroll.Size = Dim2(0, self.ColumnW, 1, 0)
		column.FadeTop.Position, column.FadeTop.Size = Offset(x, 0), Offset(self.ColumnW, 14)
		column.FadeBottom.Position, column.FadeBottom.Size = Dim2(0, x, 1, -14), Offset(self.ColumnW, 14)
		column:ClampScroll()
		if column.Scroll.CanvasPosition.Y > column.Target then
			snap(column.Scroll, "CanvasPosition", Vec2(0, column.Target))
		end
	end
	for _, job in self.ResizeJobs do job() end
	if self.Search and not self.Search.Open then self.Search.Modal.Position = self:_modalPosition(0) end
end

-- Resizes from code, keeping the window's top-left corner where it is.
function Window:SetSize(width, height)
	width = evenClamp(width, self.MinSize.X, math.huge)
	height = evenClamp(height, self:_minHeight(), math.huge)
	local position = self.Holder.Position
	snap(self.Holder, "Position", Offset(position.X.Offset + (width - self.Width) * self.DPI / 2, position.Y.Offset + (height - self.Height) * self.DPI / 2))
	self.Moved[self.Holder] = true
	self:_applySize(width, height)
end

-- DPI scale: a UIScale on the window, and on every popup and dropdown panel so they match it.
-- At exactly 100% the UIScale objects are removed, so text is drawn at its native size.
function Window:_registerScale(frame)
	local scale = Instance.new("UIScale")
	scale.Scale = self.DPI
	scale.Parent = self.DPI ~= 1 and frame or nil
	table.insert(self.ScaleTargets, { Scale = scale, Frame = frame })
end

function Window:SetDPI(value)
	value = math.clamp(math.floor(value * 100 + 0.5) / 100, 0.5, 1.5)
	if value == self.DPI then return end
	self:CloseFloating()
	self.DPI = value
	for _, entry in self.ScaleTargets do
		if entry.Frame.Parent then
			entry.Scale.Scale = value
			entry.Scale.Parent = value ~= 1 and entry.Frame or nil
		end
	end
	if not self.Moved[self.Holder] then self:_placeOverlays() end
end

local PresetOrder = { "Default", "Compact", "Large", "Mobile" }
local Presets_ = {
	Default = { Size = Vec2(Metrics.WindowW, Metrics.WindowH), DPI = 1 },
	Compact = { Size = Vec2(Metrics.MinWindowW, Metrics.MinWindowH), DPI = 0.9 },
	Large = { Size = Vec2(720, 560), DPI = 1.15 },
}

-- Window size presets. "Mobile" is fitted to the phone's screen and lowers the minimum size.
function Window:ApplyPreset(name)
	local preset = Presets_[name]
	local minSize = self.BaseMinSize
	if name == "Mobile" then
		local camera = workspace.CurrentCamera
		local view = camera and camera.ViewportSize or Vec2(800, 360)
		minSize = Vec2(400, 260)
		preset = { Size = Vec2(math.clamp(view.X - 40, 400, 520), math.clamp(view.Y - 40, 260, 380)), DPI = 1 }
	end
	if not preset then return end
	self:CloseFloating()
	self.MinSize = minSize
	self:SetDPI(preset.DPI)
	local width = evenClamp(preset.Size.X, self.MinSize.X, math.huge)
	local height = evenClamp(preset.Size.Y, self:_minHeight(), math.huge)
	self.Moved[self.Holder] = nil
	self:_applySize(width, height)
	self:_placeOverlays()
end

function Window:_beginResize(axisX, axisY, onEnd)
	if self.Search.Open then return end
	self:CloseFloating()
	local start, startW, startH = mousePos(), self.Width, self.Height
	local minHeight = self:_minHeight()
	local position = self.Holder.Position
	local dpi = self.DPI
	local left, top = position.X.Offset - startW * dpi / 2, position.Y.Offset - startH * dpi / 2
	beginDrag(function(point)
		local delta, screen = point - start, self.Screen.AbsoluteSize
		local width = axisX == 1 and evenClamp(startW + delta.X / dpi, self.MinSize.X, (screen.X - left - 4) / dpi) or startW
		local height = axisY == 1 and evenClamp(startH + delta.Y / dpi, minHeight, (screen.Y - top - 4) / dpi) or startH
		if width == self.Width and height == self.Height then return end
		self.Moved[self.Holder] = true
		snap(self.Holder, "Position", Offset(left + width * dpi / 2, top + height * dpi / 2))
		self:_applySize(width, height)
	end, onEnd)
end

function Window:_buildResize()
	local hovering, resizing = 0, false
	local color = function() return (hovering > 0 or resizing) and Current.InactiveText or Current.Outline end
	local grip = makeIcon(self.Root, "blossom-resize", 12, color, "Tab", { AnchorPoint = Vec2(1, 1), Position = Dim2(1, -2, 1, -2), ZIndex = 15 })
	local function handle(name, position, size, anchor, axisX, axisY)
		local button = new("TextButton", { Name = name, AnchorPoint = anchor, Position = position, Size = size, ZIndex = 16 }, self.Root)
		hoverable(button, function() hovering += 1; grip.Update() end, function() hovering -= 1; grip.Update() end)
		button.MouseButton1Down:Connect(function()
			resizing = true
			grip.Update()
			self:_beginResize(axisX, axisY, function()
				resizing = false
				grip.Update()
			end)
		end)
		table.insert(self.ResizeHandles, button)
	end
	handle("ResizeRight", Dim2(1, 3, 0, 12), Dim2(0, 6, 1, -30), Vec2(1, 0), 1, 0)
	handle("ResizeBottom", Dim2(0, 12, 1, 3), Dim2(1, -30, 0, 6), Vec2(0, 1), 0, 1)
	handle("ResizeCorner", Dim2(1, 3, 1, 3), Offset(18, 18), Vec2(1, 1), 1, 1)
end

function Window:_makeDraggable(handle, target, allowed)
	handle.InputBegan:Connect(function(input)
		if not isClick(input) then return end
		local start, origin = mousePos(), target.Position
		if allowed and not allowed(start) then return end
		local dragSize, dragScreen = target.AbsoluteSize, self.Screen.AbsoluteSize
		local lastPosition = origin
		beginDrag(function(point)
			local delta = point - start
			if delta.Magnitude < 1 and not self.Moved[target] then return end
			self.Moved[target] = true
			-- Set directly (no spring): the window sticks to the pointer instead of trailing behind it.
			self.Moving = true
			local position = self:_clamped(target, origin.X.Offset + delta.X, origin.Y.Offset + delta.Y, dragSize, dragScreen)
			if position ~= lastPosition then
				lastPosition = position
				snap(target, "Position", position)
			end
		end, function()
			self.Moving = false
		end)
	end)
end

-- Input can reach the window background through anything above it, so check the pointer directly.
function Window:_overControl(point)
	if self.Search.Open then return true end
	if self.OpenDropdown and inside(self.OpenDropdown.Panel, point) then return true end
	if self.ActivePopup and inside(self.ActivePopup.Frame, point) then return true end
	for _, parent in self.PopupStack do
		if inside(parent.Frame, point) then return true end
	end
	if inside(self.SearchButton, point) then return true end
	for _, handle in self.ResizeHandles do
		if inside(handle, point) then return true end
	end
	for _, tab in self.Tabs do
		if inside(tab.Button, point) then return true end
	end
	if self.CurrentTab then
		for _, sub in self.CurrentTab.Subs or {} do
			if inside(sub.Button, point) then return true end
		end
		for _, column in self:Cols() do
			if inside(column.Scroll, point) then
				for _, section in column.Sections do
					if inside(section.Root, point) then return true end
				end
			end
		end
	end
	return false
end

function Window:_popupFrame(width, height)
	local wrapper = new("Frame", { Size = Offset(width, height), Visible = false, Active = true }, self.Popups)
	self:_registerScale(wrapper)
	-- A button, so nothing beneath the popup can take the click.
	local body = new("TextButton", { Bg = "Background", Size = Dim2(1, 0, 1, 0), Radius = Metrics.PopupRadius, Border = "Outline" }, wrapper)
	addShadow(body, "Large")
	local controls = {}
	self:_makeDraggable(body, wrapper, function(point)
		for _, control in controls do
			if inside(control, point, 6) then return false end
		end
		return true
	end)
	return wrapper, body, controls
end

function Window:_buildKeybindMenu()
	local pad, gap, rowH = Metrics.Pad, Metrics.Gap, Metrics.InputH
	local width = 202
	local inner = width - pad * 2
	local frame, body, controls = self:_popupFrame(width, pad * 2 + rowH * 2 + gap)
	local menu = { Frame = frame, Fader = newFader(frame), Target = nil }
	local pill = new("Frame", { Bg = "Accent", Size = Offset(inner / 3 - 2, rowH - 2), Position = Offset(pad + 1, pad + 1), Radius = Metrics.Radius, Border = "Outline" }, body)
	addGradient(pill)
	local buttons = {}
	for _, mode in ModeOrder do
		local button = new("TextButton", { Size = Offset(0, rowH), ZIndex = 2 }, body)
		local text = label(button, { Text = mode, TextSize = 13, RowH = rowH, X = 4, Right = 4, Truncate = Enum.TextTruncate.AtEnd })
		text.TextXAlignment = Enum.TextXAlignment.Center
		buttons[mode] = button
		table.insert(controls, button)
		button.MouseButton1Click:Connect(function()
			if menu.Target and menu.Target:SetMode(mode) then menu.Paint(true) end
		end)
	end
	local reset = new("TextButton", { Size = Offset(inner - 2, rowH - 2), Radius = Metrics.Radius, Border = "Outline", BackgroundTransparency = 0 }, body)
	interactive(reset, "Element")
	addGradient(reset)
	table.insert(controls, reset)
	local center = floor(inner / 2)
	makeIcon(reset, "reset", 14, "Text", "Element", { Position = Offset(center - 32, 5) })
	label(reset, { Text = "Reset", X = center - 12, RowH = rowH - 2, W = 50 })

	-- Only the modes this keybind allows are shown. With a single mode the row is hidden and only Reset remains.
	function menu.Paint(animated)
		local target = menu.Target
		if not target then return end
		local allowed = {}
		for _, mode in ModeOrder do
			buttons[mode].Visible, buttons[mode].Size = false, Offset(0, rowH)
			if not target.Modes or target.Modes[mode] then table.insert(allowed, mode) end
		end
		local count = #allowed
		local showModes = count > 1
		local w = showModes and floor((inner - gap * (count - 1)) / count) or 0
		pill.Visible = showModes
		for index, mode in allowed do
			local x = pad + (index - 1) * (w + gap)
			if showModes then
				buttons[mode].Visible = true
				buttons[mode].Position, buttons[mode].Size = Offset(x, pad), Offset(w, rowH)
			end
			if mode == target.Mode and showModes then
				pill.Size = Offset(w - 2, rowH - 2)
				place(pill, "Position", Offset(x + 1, pad + 1), animated, "Knob")
			end
		end
		local resetY = showModes and pad + rowH + gap or pad
		reset.Position = Offset(pad + 1, resetY + 1)
		frame.Size = Offset(width, resetY + rowH + pad)
	end
	reset.MouseButton1Click:Connect(function()
		if menu.Target then menu.Target:Set(nil) end
		self:ClosePopup()
	end)
	self.KeybindMenu = menu
end

local ColorClipboard

function Window:_buildPicker()
	local pad, gap = Metrics.Pad, Metrics.Gap
	local width = 216
	local svW, svH, barW = width - pad * 3 - 12, 168, 12
	local alphaY = pad + svH + pad
	local labelY = alphaY + barW + pad
	local inputY = labelY + Metrics.Row + gap
	local copyY = inputY + Metrics.InputH + gap
	local frame, body, controls = self:_popupFrame(width, copyY + Metrics.InputH + pad)
	local picker = { Frame = frame, Fader = newFader(frame), Target = nil, H = 0, S = 0, V = 1, Alpha = 0, Dragging = false }

	local sv = new("Frame", { BackgroundTransparency = 0, Position = Offset(pad + 1, pad + 1), Size = Offset(svW - 2, svH - 2), Radius = Metrics.Radius, Border = "Outline" }, body)
	local white = new("Frame", { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), Size = Dim2(1, 0, 1, 0), Radius = Metrics.Radius }, sv)
	new("UIGradient", { Transparency = NumberSequence.new(0, 1) }, white)
	local black = new("Frame", { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(0, 0, 0), Size = Dim2(1, 0, 1, 0), Radius = Metrics.Radius }, sv)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }, black)

	local function ringKnob(parent)
		local size = Metrics.PickerKnob
		local knob = new("Frame", { Name = "Knob", BackgroundTransparency = 0, AnchorPoint = Vec2(0.5, 0.5), Size = Offset(size, size), Radius = FULL, ZIndex = 3 }, parent)
		local ring = new("UIStroke", { Thickness = 2 }, knob)
		bind(ring, "Color", "Text")
		addShadow(knob, "PickerKnob")
		return knob
	end
	local svKnob = ringKnob(sv)
	picker.SVKnob = svKnob
	-- The knob's centre travels 6px inside each edge, matching the original.
	local INSET = (Metrics.PickerKnob + 4) / 2 - 1
	local function along(scale) return round(INSET - INSET * 2 * scale) end
	local function fromPointer(position, origin, length)
		return clamp01((position - origin - INSET) / (length - INSET * 2))
	end

	local hue = new("Frame", { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), Position = Offset(pad * 2 + svW + 1, pad + 1), Size = Offset(barW - 2, svH - 2), Radius = Metrics.Radius, Border = "Outline" }, body)
	local keys = {}
	for index = 0, 6 do
		table.insert(keys, ColorSequenceKeypoint.new(index / 6, Color3.fromHSV((index / 6) % 1, 1, 1)))
	end
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(keys) }, hue)
	local hueKnob = ringKnob(hue)

	local alphaBar = new("Frame", { Bg = "Background", Position = Offset(pad + 1, alphaY + 1), Size = Offset(width - pad * 2 - 2, barW - 2), Radius = Metrics.Radius, Border = "Outline" }, body)
	-- A CanvasGroup is the only container whose UICorner clips its children, so the square
	-- checker cells stay inside the rounded ends.
	local alphaClip = new("CanvasGroup", { Name = "AlphaClip", BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), Size = Dim2(1, 0, 1, 0), Radius = Metrics.Radius }, alphaBar)
	for column = 0, 48 do
		for row = 0, 2 do
			if (column + row) % 2 == 1 then
				new("Frame", { BackgroundTransparency = 0, BackgroundColor3 = RGB(190, 190, 190), Position = Offset(column * 4, row * 4), Size = Offset(4, 4) }, alphaClip)
			end
		end
	end
	local alphaFill = new("Frame", { BackgroundTransparency = 0, Size = Dim2(1, 0, 1, 0) }, alphaClip)
	new("UIGradient", { Transparency = NumberSequence.new(0, 1) }, alphaFill)
	local alphaKnob = ringKnob(alphaBar)

	label(body, { Text = "Animations", X = pad, Y = labelY })
	local holder = new("Frame", { Position = Offset(pad, inputY), Size = Offset(width - pad * 2, Metrics.InputH) }, body)
	for _, control in { sv, hue, alphaBar, holder } do table.insert(controls, control) end

	local half = (width - pad * 2 - gap) / 2
	local function pickerButton(text, x, click)
		local button = new("TextButton", { Position = Offset(x + 1, copyY + 1), Size = Offset(half - 2, Metrics.InputH - 2), Radius = Metrics.Radius, Border = "Outline", BackgroundTransparency = 0 }, body)
		interactive(button, "Element", "HoveredElement", "Inline")
		addGradient(button)
		centeredLabel(button, half - 2, { Text = text, RowH = Metrics.InputH - 2 })
		button.MouseButton1Click:Connect(click)
		table.insert(controls, button)
	end
	pickerButton("Copy", pad, function()
		local target = picker.Target
		if not target then return end
		ColorClipboard = { Value = target.Value, Alpha = target.Alpha }
		if typeof(setclipboard) == "function" then pcall(setclipboard, "#" .. target.Value:ToHex()) end
		self:Notify("Copied #" .. target.Value:ToHex())
	end)
	pickerButton("Paste", pad + half + gap, function()
		local saved = ColorClipboard
		if not saved and typeof(getclipboard) == "function" then
			local ok, text = pcall(getclipboard)
			local hex = ok and string.match(tostring(text), "#?(%x%x%x%x%x%x)")
			if hex then saved = { Value = Color3.fromHex(hex), Alpha = 0 } end
		end
		if not saved or not picker.Target then return end
		picker.Target:Set(saved.Value, saved.Alpha)
		picker.Sync()
	end)

	local function paint()
		local color = Color3.fromHSV(picker.H, picker.S, picker.V)
		local pure = Color3.fromHSV(picker.H, 1, 1)
		sv.BackgroundColor3 = pure
		svKnob.BackgroundColor3 = color
		svKnob.Position = Dim2(picker.S, along(picker.S), 1 - picker.V, along(1 - picker.V))
		hueKnob.Position = Dim2(0.5, 0, picker.H, along(picker.H))
		hueKnob.BackgroundColor3 = pure
		alphaFill.BackgroundColor3 = color
		alphaKnob.Position = Dim2(picker.Alpha, along(picker.Alpha), 0.5, 0)
		alphaKnob.BackgroundColor3 = color
	end

	local function commit()
		paint()
		if picker.Target then picker.Target:Set(Color3.fromHSV(picker.H, picker.S, picker.V), picker.Alpha) end
	end

	function picker.Sync(keepAnimation)
		local target = picker.Target
		if not target then return end
		-- While Rainbow/Pulse runs the knobs follow the live colour instead of the stored base.
		local source = (keepAnimation and target.Animation ~= "None") and target.Value or target.Base
		local h, s, v = source:ToHSV()
		if s > 0 and v > 0 then picker.H = h end
		picker.S, picker.V, picker.Alpha = s, v, target.Alpha or 0
		paint()
		if picker.Animation and not keepAnimation then picker.Animation:Set(target.Animation or "None", true) end
	end

	-- Each hit area overhangs its control so knobs resting on an edge can still be grabbed.
	local function dragArea(area, knob, update)
		local hit = new("TextButton", { Position = Offset(-6, -6), Size = Dim2(1, 12, 1, 12), ZIndex = 5 }, area)
		hit.InputBegan:Connect(function(input)
			if not isClick(input) then return end
			picker.Dragging = true
			update(mousePos())
			beginDrag(update, function() picker.Dragging = false end)
		end)
	end
	dragArea(sv, svKnob, function(point)
		picker.S = fromPointer(point.X, sv.AbsolutePosition.X, sv.AbsoluteSize.X)
		picker.V = 1 - fromPointer(point.Y, sv.AbsolutePosition.Y, sv.AbsoluteSize.Y)
		commit()
	end)
	dragArea(hue, hueKnob, function(point)
		picker.H = math.min(fromPointer(point.Y, hue.AbsolutePosition.Y, hue.AbsoluteSize.Y), 0.9999)
		commit()
	end)
	dragArea(alphaBar, alphaKnob, function(point)
		picker.Alpha = fromPointer(point.X, alphaBar.AbsolutePosition.X, alphaBar.AbsoluteSize.X)
		commit()
	end)

	self.Picker = picker
	picker.Animation = buildDropdown(self, holder, {
		Options = { "None", "Rainbow", "Pulse" }, Default = "None", MaxRows = 3,
		Callback = function(value)
			if picker.Target then picker.Target:SetAnimation(value) end
		end,
	})
	picker.OnClose = function() picker.Animation:Toggle(false) end
end

function Window:_buildSearch()
	local width, height, pad = 420, 340, Metrics.Pad
	local overlay = new("TextButton", {
		BackgroundTransparency = 0.45, BackgroundColor3 = Color3.new(0, 0, 0), Size = Dim2(1, 0, 1, 0), Visible = false,
		ZIndex = 20, Radius = Metrics.WindowRadius,
	}, self.Root)
	local modal = new("TextButton", {
		Bg = "Background", Position = self:_modalPosition(0), Size = Offset(width, height), Radius = Metrics.WindowRadius, Border = "Outline",
	}, overlay)
	local title = label(modal, { Text = "Search", TextSize = 14, Weight = Enum.FontWeight.SemiBold, X = pad * 2, Y = pad + 2, RowH = 20, Truncate = Enum.TextTruncate.AtEnd })
	local field = new("Frame", { Bg = "Inline", Position = Offset(pad * 2 + 1, 43), Size = Offset(width - pad * 4 - 2, 34), Radius = Metrics.PillRadius, Border = "Outline" }, modal)
	makeIcon(field, "search", 14, "InactiveText", "Inline", { Position = Offset(10, 10) })
	local box = new("TextBox", {
		Fg = "Text", PlaceholderText = "Type to search...", Position = Offset(34, capOffset(34, 13)), Size = Dim2(1, -45, 0, 20), ClearTextOnFocus = false,
	}, field)
	bind(box, "PlaceholderColor3", "InactiveText")
	local results = new("ScrollingFrame", {
		Position = Offset(pad * 2, 88), Size = Offset(width - pad * 4 + 6, height - 88 - pad), CanvasSize = Offset(0, 0),
		ScrollBarThickness = 2, ScrollBarImageTransparency = 0,
	}, modal)
	bind(results, "ScrollBarImageColor3", "Accent")

	local noResults = centeredLabel(modal, width, { Fg = "InactiveText", Text = "No results", Y = 170 })
	noResults.Visible = false
	local search = { Overlay = overlay, Modal = modal, Fader = newFader(overlay), Open = false, Rows = {}, Dirty = false, Box = box, Order = {} }

	local function goTo(entry)
		self:CloseSearch()
		local section = entry.Section or entry
		self:SelectTab(section.Tab)
		section.Column:ScrollTo(section.Y + (entry.Section and section.HeaderH + entry.Y or 0) - 40)
		if entry.Frame then
			local flash = new("Frame", {
				Bg = "Accent", BackgroundTransparency = 0.7, Position = Offset(-6, -3), Size = Dim2(1, 12, 1, 6), Radius = Metrics.Radius, ZIndex = 0,
			}, entry.Frame)
			task.delay(0.2, function()
				animate(flash, "BackgroundTransparency", 1, "Soft", { Done = function() flash:Destroy() end })
			end)
		end
	end

	local function retire(row)
		row.Retired = true
		row.Frame:Destroy()
	end

	local function makeRow(entry, name, sub, y)
		local frame = new("TextButton", {
			Bg = "HoveredElement", BackgroundTransparency = 1, Position = Offset(10, y), Size = Offset(width - pad * 4, 44), Radius = Metrics.Radius,
		}, results)
		NoFade[frame] = true
		local row = { Frame = frame, Y = y, Retired = false }
		row.Bar = new("Frame", { Bg = "Accent", BackgroundTransparency = 1, Position = Offset(4, 8), Size = Offset(3, 28), Radius = Metrics.SmallRadius }, frame)
		row.Name = label(frame, { Text = name, TextSize = 13, X = 14, Y = 5, RowH = 18, TextTransparency = 1, Right = 10, Truncate = Enum.TextTruncate.AtEnd })
		row.Sub = label(frame, { Fg = "InactiveText", Text = sub, TextSize = 11, X = 14, Y = 22, RowH = 16, TextTransparency = 1, Right = 10, Truncate = Enum.TextTruncate.AtEnd })
		hoverable(frame, function() animate(frame, "BackgroundTransparency", 0.4, "Fast") end, function() animate(frame, "BackgroundTransparency", 1, "Fast") end)
		frame.MouseButton1Click:Connect(function() goTo(entry) end)
		return row
	end

	-- Rows are matched to results and reused, so a keystroke only touches what actually changed.
	local function sync()
		local text = box.Text
		setText(title, text ~= "" and text or "Search")
		setText(self.SearchLabel, text ~= "" and text or "Search...")
		local wanted, order = {}, {}
		if text ~= "" then
			local needle = string.lower(text)
			local function add(entry, name, sub)
				if #order < 30 and name and string.find(string.lower(name), needle, 1, true) then
					wanted[entry] = true
					table.insert(order, { entry, name, sub })
				end
			end
			for _, section in self.Sections do
				add(section, section.Name, (section.Tab.Name:gsub("/", " / ")) .. " / " .. section.Name .. "  \u{00B7}  Section")
			end
			for _, item in self.Index do
				add(item, item.Name, (item.Section.Tab.Name:gsub("/", " / ")) .. " / " .. item.Section.Name .. "  \u{00B7}  " .. item.Kind)
			end
		end
		for entry, row in search.Rows do
			if not wanted[entry] then
				search.Rows[entry] = nil
				retire(row)
			end
		end
		local fresh = 0
		for index, data in order do
			local entry, y = data[1], (index - 1) * 48
			local row = search.Rows[entry]
			if row then
				row.Y = y
				animate(row.Frame, "Position", Offset(0, y), "Smooth")
			else
				row = makeRow(entry, data[2], data[3], y)
				search.Rows[entry] = row
				fresh += 1
				task.delay(math.min(fresh, 8) * 0.025, function()
					if row.Retired then return end
					animate(row.Frame, "Position", Offset(0, row.Y), "Smooth")
					animate(row.Bar, "BackgroundTransparency", 0, "Smooth")
					animate(row.Name, "TextTransparency", 0, "Smooth")
					animate(row.Sub, "TextTransparency", 0, "Smooth")
				end)
			end
		end
		results.CanvasSize = Offset(0, #order * 48)
		search.Order = order
		noResults.Visible = text ~= "" and #order == 0
	end

	box:GetPropertyChangedSignal("Text"):Connect(function() search.Dirty = true end)
	box.FocusLost:Connect(function(enterPressed)
		if UserInputService:IsKeyDown(Enum.KeyCode.Escape) then
			self:CloseSearch()
		elseif enterPressed then
			if search.Dirty then
				search.Dirty = false
				sync()
			end
			if search.Order[1] then goTo(search.Order[1][1]) end
		end
	end)
	overlay.MouseButton1Click:Connect(function() self:CloseSearch() end)
	search.Sync = sync
	self.Search = search
end

function Window:OpenSearch()
	local search = self.Search
	if search.Open then return end
	search.Open = true
	self:CloseFloating()
	search.Modal.Position = self:_modalPosition(10)
	animate(search.Modal, "Position", self:_modalPosition(0), "Smooth")
	search.Fader:Show()
	search.Box:CaptureFocus()
end

function Window:CloseSearch()
	local search = self.Search
	if not search.Open then return end
	search.Open = false
	search.Box:ReleaseFocus()
	animate(search.Modal, "Position", self:_modalPosition(7), "Fast")
	search.Fader:Hide()
end

function Window:SetVisible(visible)
	if self.Visible == visible then return end
	self.Visible = visible
	self:CloseFloating()
	self.ModalButton.Visible = visible
	-- Fade only: scaling the window resamples its text, which made the font look thin until the scale was removed.
	if visible then
		self.Fader:Show()
	else
		self.Fader:Hide()
	end
end

function Window:Toggle()
	self:SetVisible(not self.Visible)
end

local ConfigMemory = {}
local function configPath(name) return "Blossom/" .. name .. ".json" end

local function jsonKeyLess(a, b)
	local ua, ub = string.sub(a, 1, 1) == "_", string.sub(b, 1, 1) == "_"
	if ua ~= ub then return ua end
	return string.lower(a) < string.lower(b)
end

-- Human readable JSON: sorted keys, one setting per line, short lists and colours kept on one line.
local function prettyJson(value, indent)
	if type(value) ~= "table" then return HttpService:JSONEncode(value) end
	indent = indent or ""
	if next(value) == nil then return "[]" end
	local parts = {}
	if value[1] ~= nil then
		for _, item in value do table.insert(parts, prettyJson(item)) end
		return "[" .. table.concat(parts, ", ") .. "]"
	end
	local keys, flat = {}, true
	for key, item in value do
		table.insert(keys, key)
		if type(item) == "table" then flat = false end
	end
	table.sort(keys, jsonKeyLess)
	if flat and #keys <= 4 and #indent >= 2 then -- only single settings (colour, keybind) stay on one line
		for _, key in keys do table.insert(parts, HttpService:JSONEncode(key) .. ": " .. prettyJson(value[key])) end
		return "{ " .. table.concat(parts, ", ") .. " }"
	end
	local inner = indent .. "\t"
	for _, key in keys do table.insert(parts, inner .. HttpService:JSONEncode(key) .. ": " .. prettyJson(value[key], inner)) end
	return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
end

local function roundNumbers(value)
	if type(value) == "number" then return math.round(value * 10000) / 10000 end
	if type(value) == "table" then
		local copy = {}
		for key, item in value do copy[key] = roundNumbers(item) end
		return copy
	end
	return value
end

-- What one element looks like in the file: a bool, a number, a string, a list, or a small named object.
local function encodeValue(object)
	if object.Swatch then
		local value = { Color = "#" .. object.Base:ToHex(), Alpha = roundNumbers(object.Alpha) }
		if object.Animation ~= "None" then value.Animation = object.Animation end
		return value
	elseif object.Chip then
		return { Key = object.Key and object.Key.Name or "None", Mode = object.Mode }
	elseif object.Multi then
		local list = {}
		for option, enabled in object.Value do
			if enabled then table.insert(list, option) end
		end
		table.sort(list)
		return list
	end
	return roundNumbers(object.Value)
end

local function applyValue(object, value)
	if object.Swatch then
		local isTable = type(value) == "table"
		object:Set(Color3.fromHex(isTable and value.Color or value), isTable and value.Alpha or nil)
		object:SetAnimation(isTable and value.Animation or nil)
	elseif object.Chip then
		if value.Mode then object:SetMode(value.Mode) end
		local key = nil
		if value.Key and value.Key ~= "None" and value.Key ~= false then
			key = string.find(value.Key, "MouseButton", 1, true) and Enum.UserInputType[value.Key] or Enum.KeyCode[value.Key]
		end
		object:Set(key)
	else
		object:Set(value)
	end
end

-- Layout: { "Tab": { "Section": { "Element": value } } }. Flags without a Tab/Section/Name path go under "_custom".
function Window:_snapshot()
	local data = { _format = "Blossom config", _version = 2 }
	for flag, object in self.Flags do
		local value = encodeValue(object)
		if value ~= nil then
			local tab, section, name = string.match(flag, "^([^/]+)/([^/]+)/(.+)$")
			if tab then
				data[tab] = data[tab] or {}
				data[tab][section] = data[tab][section] or {}
				data[tab][section][name] = value
			else
				data._custom = data._custom or {}
				data._custom[flag] = value
			end
		end
	end
	return data
end

function Window:ExportConfig()
	return prettyJson(self:_snapshot())
end

function Window:_serialize()
	return self:ExportConfig()
end

-- Returns (ok, how many settings were applied). Also reads the old flat format.
function Window:_deserialize(json)
	local ok, data = pcall(HttpService.JSONDecode, HttpService, json)
	if not ok or type(data) ~= "table" then return false, 0 end
	local applied = 0
	local function apply(flag, value)
		local object = self.Flags[flag]
		if object and pcall(applyValue, object, value) then applied += 1 end
	end
	for key, value in data do
		if string.sub(key, 1, 1) ~= "_" or key == "_custom" then
			if self.Flags[key] then
				apply(key, value)
			elseif type(value) == "table" then
				for inner, item in value do
					if key == "_custom" then
						apply(inner, item)
					elseif type(item) == "table" then
						for name, entry in item do apply(key .. "/" .. inner .. "/" .. name, entry) end
					end
				end
			end
		end
	end
	return applied > 0, applied
end

function Window:ImportConfig(text)
	return self:_deserialize(text)
end

function Window:ListConfigs()
	local names = {}
	if typeof(listfiles) == "function" and typeof(isfolder) == "function" and isfolder("Blossom") then
		for _, path in listfiles("Blossom") do
			local name = string.match(path, "([^/\\]+)%.json$")
			if name then table.insert(names, name) end
		end
	else
		for name in ConfigMemory do table.insert(names, name) end
	end
	table.sort(names)
	return names
end

function Window:SearchConfigs(query)
	query = string.lower(query or "")
	if query == "" then return self:ListConfigs() end
	local found = {}
	for _, name in self:ListConfigs() do
		if string.find(string.lower(name), query, 1, true) then table.insert(found, name) end
	end
	return found
end

function Window:GetConfigText(name)
	if typeof(readfile) == "function" and typeof(isfile) == "function" and isfile(configPath(name)) then return readfile(configPath(name)) end
	return ConfigMemory[name]
end

function Window:SaveConfig(name)
	local json = self:_serialize()
	if typeof(writefile) == "function" then
		if typeof(isfolder) == "function" and not isfolder("Blossom") then makefolder("Blossom") end
		writefile(configPath(name), json)
	else
		ConfigMemory[name] = json
	end
end

function Window:LoadConfig(name)
	local json = self:GetConfigText(name)
	if json then return self:_deserialize(json) end
	return false
end

function Window:DeleteConfig(name)
	if typeof(delfile) == "function" and typeof(isfile) == "function" and isfile(configPath(name)) then
		delfile(configPath(name))
	end
	ConfigMemory[name] = nil
end

local THEME_DIR = "Blossom/Themes"
local ThemeMemory, UserThemes = {}, {}

local function cleanName(text)
	return (string.gsub(text, '[\\/:*?"<>|]', ""):match("^%s*(.-)%s*$"))
end

function Window:ListThemes()
	local names = {}
	if typeof(listfiles) == "function" and typeof(isfolder) == "function" and isfolder(THEME_DIR) then
		for _, path in listfiles(THEME_DIR) do
			local name = string.match(path, "([^/\\]+)%.json$")
			if name then table.insert(names, name) end
		end
	else
		for name in ThemeMemory do table.insert(names, name) end
	end
	table.sort(names)
	return names
end

function Window:SaveTheme(name)
	local data = {}
	for key, color in Current do data[key] = color:ToHex() end
	local json = HttpService:JSONEncode(data)
	if typeof(writefile) == "function" then
		if typeof(isfolder) == "function" then
			if not isfolder("Blossom") then makefolder("Blossom") end
			if not isfolder(THEME_DIR) then makefolder(THEME_DIR) end
		end
		writefile(THEME_DIR .. "/" .. name .. ".json", json)
	else
		ThemeMemory[name] = json
	end
	Themes[name], UserThemes[name], self.ThemeName = table.clone(Current), true, name
	if not table.find(ThemeOrder, name) then table.insert(ThemeOrder, name) end
end

-- Theme JSON uses the same simple hex-colour format as saved theme files.
-- Supplying a name exports that saved theme; omitting it exports the active theme.
function Window:ExportTheme(name)
	local theme = name and Themes[name] or Current
	if not theme then return nil end
	local data = {}
	for key in Current do
		local color = theme[key]
		if typeof(color) == "Color3" then data[key] = color:ToHex() end
	end
	return HttpService:JSONEncode(data)
end

-- Imports a theme JSON string, applies it, and optionally saves it under name.
-- Returns false for invalid JSON or a payload with no recognised theme colours.
function Window:ImportTheme(json, name)
	if type(json) ~= "string" or json == "" then return false, 0 end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, json)
	if not ok or type(data) ~= "table" then return false, 0 end

	local theme = table.clone(Current)
	local applied = 0
	for key, hex in data do
		if theme[key] ~= nil and type(hex) == "string" then
			local valid, color = pcall(Color3.fromHex, hex)
			if valid then
				theme[key] = color
				applied += 1
			end
		end
	end
	if applied == 0 then return false, 0 end

	local themeName = cleanName(name or "")
	if themeName ~= "" then
		if Themes[themeName] and not UserThemes[themeName] then return false, 0 end
		Themes[themeName], UserThemes[themeName] = theme, true
		if not table.find(ThemeOrder, themeName) then table.insert(ThemeOrder, themeName) end
		self.ThemeName = themeName
	else
		self.ThemeName = "Custom"
	end

	for key, color in theme do Current[key] = color end
	for inst in Bound do refresh(inst, "Soft") end
	for _, row in self.ThemeRows do row.Color:Set(Current[row.Key], nil, true) end
	if themeName ~= "" then
		self:SaveTheme(themeName)
	else
		self.ThemeName = "Custom"
	end
	return true, applied
end

-- apply = false only registers the theme so it shows up in the Theme list.
function Window:LoadTheme(name, apply)
	local path, json = THEME_DIR .. "/" .. name .. ".json", nil
	if typeof(readfile) == "function" and typeof(isfile) == "function" and isfile(path) then
		json = readfile(path)
	else
		json = ThemeMemory[name]
	end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, json or "")
	if not ok or type(data) ~= "table" then return false end
	local theme = table.clone(Current)
	for key, hex in data do
		if theme[key] ~= nil then pcall(function() theme[key] = Color3.fromHex(hex) end) end
	end
	Themes[name], UserThemes[name] = theme, true
	if not table.find(ThemeOrder, name) then table.insert(ThemeOrder, name) end
	if apply ~= false then self:ApplyTheme(name, true) end
	return true
end

function Window:DeleteTheme(name)
	local path = THEME_DIR .. "/" .. name .. ".json"
	if typeof(delfile) == "function" and typeof(isfile) == "function" and isfile(path) then delfile(path) end
	ThemeMemory[name] = nil
	if UserThemes[name] then
		UserThemes[name], Themes[name] = nil, nil
		local index = table.find(ThemeOrder, name)
		if index then table.remove(ThemeOrder, index) end
	end
end

local AUTOLOAD_PATH = "Blossom/autoload.txt"
local AutoloadMemory

local function readAutoload()
	if typeof(readfile) == "function" and typeof(isfile) == "function" then
		return isfile(AUTOLOAD_PATH) and readfile(AUTOLOAD_PATH) or nil
	end
	return AutoloadMemory
end

local function writeAutoload(name)
	if typeof(writefile) ~= "function" then
		AutoloadMemory = name
	elseif name then
		if typeof(isfolder) == "function" and not isfolder("Blossom") then makefolder("Blossom") end
		writefile(AUTOLOAD_PATH, name)
	elseif typeof(delfile) == "function" and isfile(AUTOLOAD_PATH) then
		delfile(AUTOLOAD_PATH)
	end
end

function Window:BuildSettings(tab)
	local selected
	local saved = readAutoload()
	local autoloadOn, autoloadName = saved ~= nil, saved
	local autoloadList
	local menu = tab:Section({ Name = "Menu", Icon = "cube", Side = 1 })
	local menuBind = menu:Keybind({ Name = "Menu Key", Default = self.MenuKey, NoSave = true, Hotkey = false })
	menuBind.OnKeyChanged = function() self.MenuKey = menuBind.Key end
	local watermark = menu:Toggle({ Name = "Watermark", Default = true, NoSave = true, Gear = true, Callback = function(value) self:_fadeOverlay(self.Watermark, value) end })
	watermark.Gear:Dropdown({ Name = "Show", Options = WatermarkOptions, Default = WatermarkDefaults, Multi = true, MaxRows = #WatermarkOptions, Callback = function(set) self:SetWatermarkItems(set) end })
	local hotkeyList = menu:Toggle({ Name = "Hotkey List", Default = true, Gear = true, Callback = function(value) self:_fadeOverlay(self.Hotkeys, value) end })
	hotkeyList.Gear:Toggle({ Name = "Only Assigned", Default = self.HotkeyOnlyAssigned, Callback = function(value) self:SetHotkeyFilter(value, nil) end })
	hotkeyList.Gear:Toggle({ Name = "Only Enabled", Default = self.HotkeyOnlyEnabled, Callback = function(value) self:SetHotkeyFilter(nil, value) end })
	local fontName = "Inter"
	for name, family in Fonts do if family == FontFamily then fontName = name end end
	menu:Dropdown({ Name = "Font", Options = FontOrder, Default = fontName, Callback = function(value) self:SetFont(value) end })
	menu:Dropdown({ Name = "Text Weight", Options = WeightOrder, Default = BodyWeight.Name, Callback = function(value) self:SetTextWeight(value) end })
	local dpiSlider
	menu:Dropdown({ Name = "Preset", Options = PresetOrder, Default = "Default", NoSave = true, Callback = function(value)
		self:ApplyPreset(value)
		if dpiSlider then dpiSlider:Set(self.DPI * 100, true) end
	end })
	local dpiToken = 0
	dpiSlider = menu:Slider({ Name = "DPI Scale", Min = 50, Max = 150, Default = 100, Suffix = "%", NoSave = true, Callback = function(value)
		-- Applied once the slider settles: rescaling mid-drag would move the track under the pointer.
		dpiToken += 1
		local token = dpiToken
		task.spawn(function()
			task.wait(0.3)
			while token == dpiToken and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do task.wait(0.1) end
			if token == dpiToken then self:SetDPI(value / 100) end
		end)
	end })
	if not self.HideUnload then menu:Button({ Name = "Unload", Confirm = true, Callback = function() self:Destroy() end }) end
	local profiles = tab:Section({ Name = "Profiles", Icon = "cube", Side = 1 })
	profiles:Label({ Name = "Configs" })
	local searchBox = profiles:Textbox({ Placeholder = "Search configs", NoSave = true })
	local listbox = profiles:Listbox({ Height = 177, Empty = "No configs yet", Options = self:ListConfigs(), Callback = function(value) selected = value end })
	local nameBox = profiles:Textbox({ Placeholder = "Config name", NoSave = true })
	local function refreshList()
		listbox:SetOptions(self:SearchConfigs(searchBox.Instance.Text))
		autoloadList:SetOptions(self:ListConfigs())
	end
	searchBox.Instance:GetPropertyChangedSignal("Text"):Connect(function()
		listbox:SetOptions(self:SearchConfigs(searchBox.Instance.Text))
	end)
	profiles:Button({ Name = "Create", Callback = function()
		local name = cleanName(nameBox.Instance.Text)
		if name == "" then self:Notify({ Text = "Enter a config name first." }); return end
		self:SaveConfig(name)
		refreshList()
		self:Notify(('Created "%s".'):format(name))
	end })
	profiles:Button({ Name = "Load", Callback = function()
		if not selected then return end
		self:Notify((self:LoadConfig(selected) and 'Loaded "%s".' or 'Could not load "%s".'):format(selected))
	end })
	profiles:Button({ Name = "Delete", Callback = function()
		if selected then
			self:DeleteConfig(selected)
			if selected == autoloadName then autoloadName = nil; autoloadList:Set(nil, true); writeAutoload(nil) end
			self:Notify(('Deleted "%s".'):format(selected))
			selected = nil
			refreshList()
		end
	end })
	profiles:Button({ Name = "Overwrite", Callback = function()
		if selected then
			self:SaveConfig(selected)
			self:Notify(('Overwrote "%s".'):format(selected))
		end
	end })
	local importBox = profiles:Textbox({ Placeholder = "Paste config JSON", NoSave = true })
	profiles:Button({ Name = "Export", Callback = function()
		local copy = setclipboard or toclipboard
		if typeof(copy) ~= "function" then self:Notify({ Text = "Clipboard is not available here." }); return end
		copy(selected and self:GetConfigText(selected) or self:ExportConfig())
		self:Notify(selected and ('Copied "%s" to the clipboard.'):format(selected) or "Copied the current settings to the clipboard.")
	end })
	profiles:Button({ Name = "Import", Callback = function()
		local text = importBox.Instance.Text
		if text == "" and typeof(getclipboard) == "function" then text = getclipboard() end
		local ok, count = self:ImportConfig(text)
		if not ok then self:Notify({ Text = "That is not a valid Blossom config." }); return end
		importBox:Set("", true)
		local name = cleanName(nameBox.Instance.Text)
		if name ~= "" then
			self:SaveConfig(name)
			refreshList()
		end
		self:Notify(("Imported %d settings."):format(count))
	end })

	local function storeAutoload() writeAutoload(autoloadOn and autoloadName or nil) end
	local autoload = tab:Section({ Name = "Autoload", Icon = "cube", Side = 1 })
	autoload:Toggle({ Name = "Load on start", Default = autoloadOn, NoSave = true, Callback = function(value)
		autoloadOn = value
		storeAutoload()
	end })
	autoloadList = autoload:Dropdown({ Name = "Config", Options = self:ListConfigs(), Default = saved, Empty = "No configs yet", NoSave = true, Callback = function(value)
		autoloadName = value
		storeAutoload()
	end })

	local theming = tab:Section({ Name = "Theming", Icon = "cube", Side = 2 })
	for _, name in self:ListThemes() do self:LoadTheme(name, false) end
	local themeDropdown = theming:Dropdown({ Name = "Theme", Options = ThemeOrder, Default = self.ThemeName, MaxRows = 11, NoSave = true, Callback = function(value) self:ApplyTheme(value) end })
	theming:Dropdown({ Name = "Casing", Options = Casings, Default = Casing, NoSave = true, Callback = function(value) self:SetCasing(value) end })
	theming:Divider()
	for _, pair in ThemeKeys do
		local key = pair[2]
		local color = theming:Colorpicker({ Name = pair[1], Default = Current[key], NoSave = true, Callback = function(value) self:SetThemeColor(key, value) end })
		table.insert(self.ThemeRows, { Key = key, Color = color })
	end

	theming:Divider()
	local themeName = theming:Textbox({ Placeholder = "Theme name", NoSave = true })
	local themeList = theming:Dropdown({ Name = "Saved themes", Options = self:ListThemes(), Empty = "No themes yet", NoSave = true })
	local function refreshThemes()
		themeList:SetOptions(self:ListThemes())
		themeDropdown:SetOptions(ThemeOrder)
	end
	theming:Button({ Name = "Save Theme", Callback = function()
		local name = cleanName(themeName.Instance.Text)
		if name == "" then name = themeList.Value or "" end
		if name == "" then self:Notify("Enter a theme name first."); return end
		if Themes[name] and not UserThemes[name] then self:Notify("That name belongs to a built-in theme."); return end
		self:SaveTheme(name)
		refreshThemes()
		themeDropdown:Set(name, true)
		self:Notify(('Saved theme "%s".'):format(name))
	end })
	theming:Button({ Name = "Load Theme", Callback = function()
		local name = themeList.Value
		if not name then return end
		if self:LoadTheme(name) then
			themeDropdown:Set(name, true)
			self:Notify(('Loaded theme "%s".'):format(name))
		else
			self:Notify(('Could not load "%s".'):format(name))
		end
	end })
	theming:Button({ Name = "Delete Theme", Callback = function()
		local name = themeList.Value
		if not name then return end
		self:DeleteTheme(name)
		themeList:Set(nil, true)
		refreshThemes()
		self:Notify(('Deleted theme "%s".'):format(name))
	end })

	local themeImportBox = theming:Textbox({ Placeholder = "Paste theme JSON", NoSave = true })
	theming:Button({ Name = "Export Theme JSON", Callback = function()
		local name = themeList.Value
		local json = self:ExportTheme(name)
		local copy = setclipboard or toclipboard
		if typeof(copy) ~= "function" then self:Notify("Clipboard is not available here."); return end
		if not json then self:Notify("Select a saved theme or use the active theme."); return end
		local ok = pcall(copy, json)
		if ok then
			self:Notify(name and ('Copied theme "%s" JSON.'):format(name) or "Copied the active theme JSON.")
		else
			self:Notify("Could not copy theme JSON.")
		end
	end })
	theming:Button({ Name = "Import Theme JSON", Callback = function()
		local json = themeImportBox.Instance.Text
		if json == "" and typeof(getclipboard) == "function" then
			local ok, value = pcall(getclipboard)
			if ok and type(value) == "string" then json = value end
		end
		local name = cleanName(themeName.Instance.Text)
		local ok, count = self:ImportTheme(json, name)
		if not ok then self:Notify("That is not a valid Blossom theme JSON."); return end
		themeImportBox:Set("", true)
		refreshThemes()
		if name ~= "" then
			themeList:Set(name, true)
			themeDropdown:Set(name, true)
		end
		self:Notify(("Imported %d theme colours."):format(count))
	end })

	if saved then
		task.defer(function()
			if self:LoadConfig(saved) then self:Notify(('Autoloaded "%s".'):format(saved)) end
		end)
	end
end

function Window:_buildWatermark(options)
	local player = Players.LocalPlayer
	local frame = new("Frame", { Bg = "Background", Size = Offset(298, 28), Radius = Metrics.FloatRadius, Border = "Outline", Active = true }, self.Screen)
	makeIcon(frame, "logo", 16, "Accent", "Background", { Position = Offset(8, 6) })
	self.Watermark = frame
	local show, order, parts, layout = {}, {}, {}
	for _, key in WatermarkDefaults do show[key] = true end

	local function add(key, size, weight, icon)
		local part = {
			Key = key,
			Sep = new("Frame", { Bg = "Outline", Position = Offset(0, 7), Size = Offset(1, 14), Visible = false }, frame),
			Text = label(frame, { Text = "", TextSize = size, Weight = weight, RowH = 28, W = 10 }),
			Icon = icon and makeIcon(frame, icon, 13, "Text", "Background"),
		}
		part.Text:GetPropertyChangedSignal("TextBounds"):Connect(function() if layout then layout() end end)
		table.insert(order, part)
		parts[key] = part
	end
	add("Script", 12, Enum.FontWeight.Medium)
	add("Build", 12, Enum.FontWeight.SemiBold)
	add("Name", 11, Enum.FontWeight.SemiBold, "user")
	add("FPS", 11, Enum.FontWeight.SemiBold)
	add("Ping", 11, Enum.FontWeight.SemiBold)
	add("Time", 11, Enum.FontWeight.SemiBold)
	add("Session", 11, Enum.FontWeight.SemiBold)

	local started, fps = os.clock(), 60
	local function ping()
		local ok, value = pcall(function() return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
		return ok and value or 0
	end
	local producers = {
		Script = function() return options.Script or "blossom.lua" end,
		Build = function() return options.Build or "release" end,
		Name = function() return ("%s (@%s)"):format(player.DisplayName, player.Name) end,
		FPS = function() return fps .. " fps" end,
		Ping = function() return floor(ping()) .. " ms" end,
		Time = function() return os.date("%H:%M") end,
		Session = function()
			local seconds = floor(os.clock() - started)
			return ("%d:%02d:%02d"):format(seconds // 3600, seconds % 3600 // 60, seconds % 60)
		end,
	}
	local function update()
		for key, part in parts do
			if show[key] then
				local value = producers[key]()
				if part.Text.Text ~= applyCase(value) then setText(part.Text, value) end
			end
		end
	end

	layout = function()
		local visible = {}
		for _, part in order do
			local on = show[part.Key] == true
			part.Text.Visible, part.Sep.Visible = on, false
			if part.Icon then part.Icon.Root.Visible = on end
			if on then table.insert(visible, part) end
		end
		local x = 31
		for index, part in visible do
			if part.Icon then
				part.Icon.Root.Position = Offset(x, 7)
				x += 20
			end
			local width = math.ceil(part.Text.TextBounds.X)
			part.Text.Size = Offset(width + 1, 28)
			part.Text.Position = Offset(x, part.Text.Position.Y.Offset)
			x += width
			if index < #visible then
				x += 8
				part.Sep.Position = Offset(x, 7)
				part.Sep.Visible = true
				x += 9
			end
		end
		frame.Size = Offset(x + Metrics.Pad, 28)
		self:_placeOverlays()
	end

	-- Takes the Multi dropdown's value ({ FPS = true }) or a plain list ({ "FPS" }).
	function self:SetWatermarkItems(set)
		table.clear(show)
		for key, on in set do
			if on == true and parts[key] then show[key] = true
			elseif type(on) == "string" and parts[on] then show[on] = true end
		end
		update()
		layout()
	end

	local accumulated, frames = 0, 0
	table.insert(self.Connections, RunService.Heartbeat:Connect(function(dt)
		accumulated += dt
		frames += 1
		if accumulated < 0.5 then return end
		fps, accumulated, frames = round(frames / accumulated), 0, 0
		update()
	end))

	update()
	layout()
	self.WatermarkLayout = layout
	self:_makeDraggable(frame, frame)
	-- A click on the watermark (not a drag) opens / closes the window.
	local pressAt
	frame.InputBegan:Connect(function(input)
		if isClick(input) then pressAt = mousePos() end
	end)
	frame.InputEnded:Connect(function(input)
		if not isClick(input) or not pressAt then return end
		local moved = (mousePos() - pressAt).Magnitude
		pressAt = nil
		if moved < 4 then self:Toggle() end
	end)
end

function Window:_buildHotkeys()
	local holder = new("Frame", { Size = Offset(200, 300) }, self.Screen)
	local head = new("Frame", { Bg = "Background", Position = Offset(1, 1), Size = Offset(88, 25), Radius = Metrics.FloatRadius, Border = "Outline", Active = true }, holder)
	makeIcon(head, "keyboard", 14, "Accent", "Background", { Position = Offset(9, 5) })
	local text = label(head, { Text = "Hotkeys", TextSize = 12, Weight = Enum.FontWeight.SemiBold, X = 31, RowH = 25 })
	local function fit() head.Size = Offset(math.ceil(text.TextBounds.X) + 41, 25) end
	text:GetPropertyChangedSignal("TextBounds"):Connect(fit)
	fit()
	self.Hotkeys = holder
	self:_makeDraggable(head, holder)
end

-- The watermark and hotkey list fade in and out with the same Fader as the window.
function Window:_fadeOverlay(frame, show)
	self.OverlayWanted[frame] = show
	if not self.OverlayReady or (self.OverlayState[frame] == true) == show then return end
	self.OverlayState[frame] = show
	local fader = self.OverlayFaders[frame]
	if not fader then
		fader = newFader(frame)
		self.OverlayFaders[frame] = fader
	end
	if show then fader:Show() else fader:Hide() end
end

-- Everything anchored to the screen is placed at whole pixels, the main defence against blurry text.
function Window:_placeOverlays()
	local size = self.Screen.AbsoluteSize
	if size.X <= 0 then return end
	if not self.Moved[self.Holder] then self.Holder.Position = Offset(floor(size.X / 2), floor(size.Y / 2)) end
	if self.Watermark and not self.Moved[self.Watermark] then
		self.Watermark.Position = Offset(floor((size.X - self.Watermark.Size.X.Offset) / 2), size.Y - 44)
	end
	if self.Hotkeys and not self.Moved[self.Hotkeys] then self.Hotkeys.Position = Offset(14, floor((size.Y - 300) / 2)) end
end

-- After Destroy every object answers every call with a harmless "ghost", so late callbacks, delayed
-- tasks or a forgotten Window:Notify never error. Window.Destroyed (or Window:IsDestroyed()) tells them apart.
local Ghost
Ghost = setmetatable({}, { __index = function() return Ghost end, __call = function() return Ghost end })
local DeadMeta = {
	__index = function(_, key)
		if key == "Destroyed" then return true end
		if key == "IsDestroyed" then return function() return true end end
		return Ghost
	end,
}

function Window:IsDestroyed() return self.Destroyed == true end

function Window:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
	for _, callback in self.UnloadCallbacks do pcall(callback) end
	for _, connection in self.Connections do connection:Disconnect() end
	table.clear(Jobs)
	table.clear(HoverSet)
	for _, entry in Active do entry.Dead = true end
	table.clear(Active)
	table.clear(Tracks)
	if FrameConnection then
		FrameConnection:Disconnect()
		FrameConnection = nil
	end
	if Focus == self then Focus = nil end
	if ScreenRef == self.Screen then ScreenRef = nil end
	self.Screen:Destroy()
	for _, list in { self.Tabs, self.Sections, self.Extras } do
		for _, object in list do
			if type(object) == "table" then setmetatable(object, DeadMeta) end
		end
	end
	setmetatable(self, DeadMeta)
end

local Blossom = { Themes = Themes, ThemeOrder = ThemeOrder, Metrics = Metrics, Fonts = Fonts, AddThemeJSON = function(name, json, front) return addThemeJSON(name, json, front) end, GetThemeColor = function(key) return Current[key] end }

local LastWindow

function Blossom.new(options)
	options = options or {}
	local globalEnv = typeof(getgenv) == "function" and getgenv() or nil
	local previous = LastWindow or (globalEnv and globalEnv.__BlossomWindow)
	if previous then pcall(previous.Destroy, previous) end
	if options.Theme and Themes[options.Theme] then
		for key, value in Themes[options.Theme] do Current[key] = value end
	end
	if options.Font then FontFamily = Fonts[options.Font] or options.Font end
	if options.IconBase then IconBase = type(options.IconBase) == "table" and options.IconBase or { options.IconBase } end
	if options.IconStroke then IconStroke = options.IconStroke end
	local minSize = options.MinSize or Vec2(Metrics.MinWindowW, Metrics.MinWindowH)
	minSize = Vec2(minSize.X - minSize.X % 2, minSize.Y - minSize.Y % 2)
	local startSize = options.Size or Vec2(Metrics.WindowW, Metrics.WindowH)
	local maxW, maxH = math.huge, math.huge
	-- Phones: shrink the window to fit the screen so it opens fully visible.
	local camera = workspace.CurrentCamera
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and camera then
		local view = camera.ViewportSize
		maxW, maxH = math.max(view.X - 20, 200), math.max(view.Y - 20, 200)
		minSize = Vec2(math.min(minSize.X, maxW), math.min(minSize.Y, maxH))
		minSize = Vec2(minSize.X - minSize.X % 2, minSize.Y - minSize.Y % 2)
	end
	local startW, startH = evenClamp(startSize.X, minSize.X, maxW), evenClamp(startSize.Y, minSize.Y, maxH)
	local win = setmetatable({
		Width = startW, Height = startH, MinSize = minSize, ColumnW = (startW - Metrics.ContentX - Metrics.Pad * 3) / 2,
		ResizeJobs = {}, ResizeHandles = {},
		Title = options.Title or "Blossom", Tabs = {}, Sections = {}, Columns = {}, Index = {}, Binds = {}, Colors = {}, Flags = {},
		ThemeRows = {}, HotkeyEntries = {}, HotkeyOrder = {}, NotifyStack = {}, Connections = {}, Moved = {}, PendingThemeKeys = {}, Options = {}, Toggles = {}, UnloadCallbacks = {},
		ThemeClock = 0, SidebarY = Metrics.FirstCategory, SidebarHasTabs = false, SidebarAfterCategory = false,
		DPI = 1, ScaleTargets = {}, BaseMinSize = minSize,
		Visible = true, HideUnload = options.HideUnload == true, ThemeName = options.Theme or (Themes["Blood Moon"] and "Blood Moon" or "Blossom"), MenuKey = options.MenuKey or Enum.KeyCode.RightShift,
		LastPopupTime = 0, DropdownClosedAt = 0, PopupStack = {},
		Extras = {}, OverlayState = {}, OverlayFaders = {}, OverlayWanted = {},
		HotkeyOnlyAssigned = options.HotkeyOnlyAssigned == true, HotkeyOnlyEnabled = options.HotkeyOnlyEnabled == true,
	}, Window)
	ensureLoop()
	LastWindow, Focus = win, win
	Blossom.Options, Blossom.Toggles = win.Options, win.Toggles
	if globalEnv then globalEnv.__BlossomWindow = win end

	local screen = new("ScreenGui", { Name = "Blossom", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100 })
	guiParent(screen)
	win.Screen = screen
	ScreenRef = screen

	local holder = new("Frame", {
		Name = "Window", AnchorPoint = Vec2(0.5, 0.5), Size = Offset(win.Width, win.Height), ZIndex = 10,
	}, screen)
	win.Holder = holder
	win:_registerScale(holder)
	local root = new("Frame", { Bg = "Background", Active = true, Size = Dim2(1, 0, 1, 0), Radius = Metrics.WindowRadius, Border = "Outline" }, holder)
	addShadow(root, "Large")
	win.Root = root
	win.Fader = newFader(holder)
	-- A Modal button frees the cursor from first-person camera lock while the menu is open.
	win.ModalButton = new("TextButton", { Modal = true, Size = Offset(1, 1) }, holder)

	local sidebar = new("Frame", { Size = Dim2(0, Metrics.SidebarW, 1, 0) }, root)
	win.Sidebar = sidebar
	makeIcon(sidebar, "logo", 20, "Accent", "Background", { Position = Offset(Metrics.Pad * 2, 15) })
	label(sidebar, { Text = win.Title, TextSize = 16, Weight = Enum.FontWeight.Bold, X = 51, Y = 11, RowH = 28, W = 85 })
	win.Indicator = new("Frame", { Bg = "Inline", Size = Offset(Metrics.TabW - 2, Metrics.TabH - 2), Radius = Metrics.PillRadius, Border = "Outline", Visible = false }, sidebar)
	local searchButton = new("TextButton", {
		Position = Dim2(0, Metrics.Pad + 1, 1, -(Metrics.Pad + Metrics.SearchH) + 1), Size = Offset(Metrics.TabW - 2, Metrics.SearchH - 2), Radius = Metrics.PillRadius, Border = "Outline", BackgroundTransparency = 0,
	}, sidebar)
	interactive(searchButton, "Inline")
	win.SearchButton = searchButton
	makeIcon(searchButton, "search", 14, "InactiveText", "Inline", { Position = Offset(6, 6) })
	win.SearchLabel = label(searchButton, { Fg = "InactiveText", Text = "Search...", X = 30, RowH = Metrics.SearchH - 2, Right = 6, Truncate = Enum.TextTruncate.AtEnd })
	searchButton.MouseButton1Click:Connect(function() win:OpenSearch() end)

	new("Frame", { Bg = "Outline", Position = Offset(Metrics.SidebarW, 0), Size = Dim2(0, 1, 1, 0) }, root)
	local content = new("Frame", { Bg = "Tab", Position = Offset(Metrics.ContentX, 0), Size = Dim2(1, -Metrics.ContentX, 1, 0), Radius = Metrics.WindowRadius }, root)
	new("Frame", { Name = "CornerPatch", Bg = "Tab", Size = Dim2(0, 12, 1, 0) }, content)
	win.Pages = new("Frame", {
		Name = "Pages", Position = Offset(0, Metrics.Pad), Size = Dim2(1, 0, 1, -Metrics.Pad * 2), ClipsDescendants = true,
	}, content)
	win.Veil = new("Frame", { Bg = "Tab", BackgroundTransparency = 1, Size = Dim2(1, 0, 1, 0), ZIndex = 5 }, win.Pages)

	win.DragLayer = new("Frame", { Name = "Drag", Size = Dim2(1, 0, 1, 0), ZIndex = 30 }, screen)
	win.Popups = new("Frame", { Name = "Popups", Size = Dim2(1, 0, 1, 0), ZIndex = 40 }, screen)
	win.Dropdowns = new("Frame", { Name = "Dropdowns", Size = Dim2(1, 0, 1, 0), ZIndex = 45 }, screen)
	win.Notifications = new("Frame", { Name = "Notifications", Position = Offset(16, 16), Size = Offset(400, 600), ZIndex = 50 }, screen)

	win:_buildWatermark(options)
	win:_buildHotkeys()
	win:_buildKeybindMenu()
	win:_buildPicker()
	win:_buildSearch()
	if options.Resizable ~= false then win:_buildResize() end
	win:_placeOverlays()
	win.WatermarkLayout()
	table.insert(win.Connections, screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() win:_placeOverlays() end))

	win:_makeDraggable(root, holder, function(point) return not win:_overControl(point) end)

	table.insert(win.Connections, UserInputService.InputBegan:Connect(function(input, processed)
		if isClick(input) then
			local point = mousePos()
			local dropdown = win.OpenDropdown
			local overDropdown = dropdown and inside(dropdown.Panel, point)
			if dropdown and not overDropdown then
				if inside(dropdown.Input, point) then
					win.DropdownClosedBy, win.DropdownClosedAt = dropdown.Input, os.clock()
				end
				dropdown:Toggle(false)
			end
			while win.ActivePopup and not overDropdown and not inside(win.ActivePopup.Frame, point, 6) do
				local overParent = false
				for _, parent in win.PopupStack do
					if inside(parent.Frame, point, 6) then overParent = true end
				end
				win:ClosePopup(overParent)
			end
		end
		local listening = win.Listening
		if listening then
			local isKey = input.UserInputType == Enum.UserInputType.Keyboard
			local isMouse = input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3
			if isKey or isMouse then
				win.Listening = nil
				listening.Listening = false
				if isKey and input.KeyCode == Enum.KeyCode.Escape then
					listening.Key = nil
				else
					listening.Key = isKey and input.KeyCode or input.UserInputType
				end
				listening.Refresh()
			elseif isClick(input) then
				win.Listening = nil
				listening.Listening = false
				listening.Refresh()
			end
			return
		end
		if processed then return end
		if input.KeyCode == win.MenuKey or input.UserInputType == win.MenuKey then win:Toggle() end
		for _, object in win.Binds do
			if object.Key and (object.Key == input.KeyCode or object.Key == input.UserInputType) and object.OnPress then
				fire(object.OnPress)
			end
		end
	end))

	table.insert(win.Connections, UserInputService.InputEnded:Connect(function(input)
		for _, object in win.Binds do
			if object.Key and (object.Key == input.KeyCode or object.Key == input.UserInputType) and object.OnRelease then
				fire(object.OnRelease)
			end
		end
	end))

	table.insert(win.Connections, UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseWheel or not win.Visible or win.Search.Open or not win.CurrentTab then return end
		local point = mousePos()
		local dropdown = win.OpenDropdown
		if dropdown then
			if inside(dropdown.Panel, point) then return end
			dropdown:Toggle(false)
		end
		for _, column in win:Cols() do
			if inside(column.Scroll, point) then
				column:ScrollTo(column.Target - input.Position.Z * 60)
			end
		end
	end))

	local function perFrame(dt)
		win:_flushThemeColors(dt)
		if win.OpenDropdown then win.OpenDropdown.Follow() end
		if win.CurrentTab and not win.Moving then
			for _, column in win:Cols() do
				local y = column.Scroll.CanvasPosition.Y
				local showTop, showBottom = y > 1, y < column.ContentH - column.Scroll.AbsoluteSize.Y - 1
				if showTop ~= column.ShowTop then
					column.ShowTop = showTop
					animate(column.FadeTop, "BackgroundTransparency", showTop and 0 or 1, "Fast")
				end
				if showBottom ~= column.ShowBottom then
					column.ShowBottom = showBottom
					animate(column.FadeBottom, "BackgroundTransparency", showBottom and 0 or 1, "Fast")
				end
			end
		end
		if win.Search.Dirty then
			win.Search.Dirty = false
			win.Search.Sync()
		end
		for _, color in win.Colors do
			if color.Animation ~= "None" then color:Step(dt) end
		end
	end
	Jobs[perFrame] = true

	holder.Visible, win.Visible = false, false
	win.Watermark.Visible, win.Hotkeys.Visible = false, false
	task.defer(function()
		if win.Screen.Parent == nil then return end
		win:SetVisible(true)
		win.OverlayReady = true
		for _, frame in { win.Watermark, win.Hotkeys } do win:_fadeOverlay(frame, win.OverlayWanted[frame] ~= false) end
	end)

	return win
end

-------------------------------------------------------------------------------
-- Obsidian / Linoria style API: Tab:AddGroupbox, Groupbox:AddToggle("Index", { Text = ... }), Toggles.Index:OnChanged(...)
-------------------------------------------------------------------------------

local function sideOf(side)
	if side == 2 or (type(side) == "string" and string.lower(side) == "right") then return 2 end
	return 1
end

local function keyOf(name)
	if name == "MB2" then return Enum.UserInputType.MouseButton2 end
	if name == "MB3" then return Enum.UserInputType.MouseButton3 end
	local ok, key = pcall(function() return Enum.KeyCode[name] end)
	return ok and key or nil
end

-- Registers your own SVG (the inside of an <svg> tag or a full file, 24x24 grid) under an icon name.
function Blossom.AddIcon(name, svg)
	IconSVG[string.lower(name)] = svg
	IconGeometry[string.lower(name)] = nil
end

function Window:AddTab(name, icon) return self:Tab({ Name = name, Icon = icon }) end
function Window:OnUnload(callback) table.insert(self.UnloadCallbacks, callback) end
Window.Unload = Window.Destroy

function Tab:AddGroupbox(o) return self:Section({ Name = o.Name, Icon = o.IconName or o.Icon, Description = o.Description, Side = sideOf(o.Side) }) end
function Tab:AddLeftGroupbox(name, icon) return self:Section({ Name = name, Icon = icon, Side = 1 }) end
function Tab:AddRightGroupbox(name, icon) return self:Section({ Name = name, Icon = icon, Side = 2 }) end
function Tab:AddSubTab(name) return self:SubTab({ Name = name }) end
SubTab.AddGroupbox, SubTab.AddLeftGroupbox, SubTab.AddRightGroupbox = Tab.AddGroupbox, Tab.AddLeftGroupbox, Tab.AddRightGroupbox

-- Toggles and Labels can chain :AddColorPicker / :AddKeyPicker, as in Obsidian.
local function chainable(section, object)
	function object:AddColorPicker(index, o)
		local color = attachColor(section, object.Item, { Default = o.Default, Alpha = o.Transparency, Callback = o.Callback })
		color.Item = object.Item
		register(section, color, { Flag = index, Name = o.Title or index }, object.Item)
		object.Color = color
		return object
	end
	function object:AddKeyPicker(index, o)
		local callback = o.Callback
		local key = attachKeybind(section, object.Item, { Key = keyOf(o.Default), Mode = o.Mode, Modes = o.Modes, Name = o.Text or index, OnPress = callback and function() callback(true) end or nil })
		key.Item = object.Item
		register(section, key, { Flag = index, Name = o.Text or index }, object.Item)
		object.Keybind = key
		return object
	end
	return object
end

function Section:AddToggle(index, o)
	return chainable(self, self:Toggle({ Name = o.Text, Default = o.Default, Callback = o.Callback, Flag = index }))
end
Section.AddCheckbox = Section.AddToggle

function Section:AddSlider(index, o)
	return self:Slider({ Name = o.Text, Min = o.Min, Max = o.Max, Default = o.Default, Decimals = o.Rounding, Suffix = o.Suffix, Callback = o.Callback, Flag = index })
end

function Section:AddInput(index, o)
	return self:Textbox({ Name = o.Text, Placeholder = o.Placeholder, Default = o.Default, Callback = o.Callback, Flag = index })
end

function Section:AddDropdown(index, o)
	local values, default = o.Values or {}, o.Default
	if type(default) == "number" then default = values[default] end
	if o.Multi and default ~= nil and type(default) ~= "table" then default = { default } end
	return self:Dropdown({ Name = o.Text, Options = values, Default = default, Multi = o.Multi, Callback = o.Callback, Flag = index })
end

function Section:AddButton(o, func)
	if type(o) == "string" then o = { Text = o, Func = func } end
	return self:Button({ Name = o.Text, Callback = o.Func, Confirm = o.Confirm or o.DoubleClick, ConfirmText = o.ConfirmText })
end

function Section:AddLabel(text, extra)
	return chainable(self, self:Label({ Name = type(extra) == "table" and extra.Text or text }))
end

Section.AddDivider = Section.Divider

return Blossom
