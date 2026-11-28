--!nocheck
--[[
	Blossom UI (lite rewrite) - same API, lighter internals.
	local Blossom = loadstring(readfile("Blossom.luau"))()
	local Window = Blossom.new({ Title = "Blossom", Script = "blossom.lua", Build = "operation one" })
	Window:Category("Combat")
	local Rage = Window:Tab({ Name = "Rage", Icon = "target" })
	local Main = Rage:Section({ Name = "Main", Icon = "bot", Side = 1 })
	Main:Toggle({ Name = "Enabled", Default = true, Keybind = Enum.KeyCode.C, Callback = print })
	Elements: Toggle, Slider, RangeSlider, Dropdown, Colorpicker, Keybind, Button, Textbox, Label, Divider, Listbox
	Also: Tab:SubTab, Gear = true, Confirm = true, Obsidian API (AddTab/AddGroupbox/AddToggle...), Window.Toggles/Options.
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local HTTP = game:GetService("HttpService")

local Vec2, Dim2, Off, RGB = Vector2.new, UDim2.new, UDim2.fromOffset, Color3.fromRGB
local floor, round, abs, clamp = math.floor, math.round, math.abs, math.clamp
local FONT = "rbxassetid://12187365364"
local Fonts = {
	Inter = FONT, ["Builder Sans"] = "rbxasset://fonts/families/BuilderSans.json", Roboto = "rbxasset://fonts/families/Roboto.json",
	Montserrat = "rbxasset://fonts/families/Montserrat.json", ["Source Sans Pro"] = "rbxasset://fonts/families/SourceSansPro.json",
	Ubuntu = "rbxasset://fonts/families/Ubuntu.json", Nunito = "rbxasset://fonts/families/Nunito.json", Arimo = "rbxasset://fonts/families/Arimo.json",
}
local FULL = 99
local M = { Pad = 10, Gap = 6, Row = 16, Radius = 3, Card = 4, Pill = 5, Float = 6, SidebarW = 141, TabW = 121, TabH = 28, SliderH = 33, DropdownH = 47, InputH = 26, ButtonH = 28, ListRowH = 24 }

-------------------------------------------------------------------------------
-- Themes
-------------------------------------------------------------------------------
local function T(bg, tab, out, inl, txt, inact, acc, el, grad, hov, shadow)
	local h = Color3.fromHex
	return { Background = h(bg), Tab = h(tab), Outline = h(out), Inline = h(inl), Text = h(txt), InactiveText = h(inact), Accent = h(acc), Element = h(el), Gradient = h(grad), HoveredElement = h(hov), Shadow = shadow or RGB(0, 0, 0) }
end
local Themes = {
	["Blood Moon"] = T("22181c", "1c1216", "442e36", "2c1f24", "f4e8ea", "92787e", "de5c70", "281c21", "b0a6a8", "463038"),
	Blossom = T("2a2c34", "30323a", "414450", "383a44", "e8eaf5", "7e8294", "719fe2", "363944", "acbbd1", "484d5a"),
	Necro = T("1c1824", "16121d", "3a304a", "251f30", "ece8f4", "827896", "78d6a0", "221d2d", "a8a6b0", "383048"),
	Crypt = T("181c22", "12161c", "303a46", "1f252d", "e6ecf0", "768492", "68c4c8", "1c222a", "a4aab0", "2e3945"),
	["Grave Moss"] = T("181e1a", "121814", "2e3c32", "1e2621", "e8f0e6", "788a7a", "9ed068", "1c241f", "a6aea6", "2e3c32"),
	Wraith = T("1e1b28", "181521", "3e3856", "282436", "eeeaf8", "8880a2", "ac8eec", "242032", "aaa8b4", "3c3652"),
	Afterglow = T("221c19", "1e1714", "3c2e26", "2a211d", "f0e8e2", "8c7a6e", "ff913c", "31221b", "aca7a3", "46332a"),
	Frostbite = T("161e26", "101920", "2a3a48", "1b262f", "e4f0f8", "728898", "56dbff", "1c2734", "a4acb2", "2c3c4a"),
	Volt = T("181814", "12120e", "363628", "20201a", "f2f2e2", "868670", "fffa4c", "20201a", "aaaa9e", "3a3a2c"),
	Obsidian = T("101012", "0c0b0e", "2c2a34", "18181d", "eae8f4", "767286", "9f6dff", "18171f", "a6a4af", "ecf0f8"),
	Abyss = T("0c141c", "080f16", "1e303e", "121e28", "deecf6", "648094", "34b0ee", "101c26", "9ea9b0", "203343"),
	Porcelain = T("faf8f4", "eceae6", "d6d4d0", "ffffff", "2c2e36", "8c8e96", "85b0ff", "ffffff", "d6dae2", "ffffff", RGB(120, 120, 120)),
	Graphite = T("201e1e", "282828", "3a3c3e", "2a2d2e", "ececfa", "808086", "699fed", "2c2e2e", "bebebe", "434648"),
}
local ThemeOrder = { "Blood Moon", "Blossom", "Necro", "Crypt", "Grave Moss", "Wraith", "Afterglow", "Frostbite", "Volt", "Obsidian", "Abyss", "Porcelain", "Graphite" }
local ThemeKeys = { { "Background", "Background" }, { "Tab", "Tab" }, { "Outline", "Outline" }, { "Inline", "Inline" }, { "Text", "Text" }, { "Inactive Text", "InactiveText" }, { "Accent", "Accent" }, { "Element", "Element" }, { "Gradient", "Gradient" }, { "Hovered Element", "HoveredElement" } }
local Current = table.clone(Themes["Blood Moon"])

-------------------------------------------------------------------------------
-- Animator: ONE loop, runs only while something animates (zero cost when idle)
-------------------------------------------------------------------------------
local Anim, AnimConn = {}, nil
local function animStep(dt)
	local a = 1 - math.exp(-dt * 24)
	local any = false
	for t, props in Anim do
		for p, g in props do
			local cur, n, done = t[p], nil, false
			local k = typeof(g)
			if k == "number" then
				n = cur + (g - cur) * a
				done = abs(g - n) < 0.003
			elseif k == "Color3" then
				n = cur:Lerp(g, a)
				done = abs(g.R - n.R) + abs(g.G - n.G) + abs(g.B - n.B) < 0.006
			elseif k == "UDim2" then
				n = Dim2(cur.X.Scale + (g.X.Scale - cur.X.Scale) * a, round(cur.X.Offset + (g.X.Offset - cur.X.Offset) * a), cur.Y.Scale + (g.Y.Scale - cur.Y.Scale) * a, round(cur.Y.Offset + (g.Y.Offset - cur.Y.Offset) * a))
				done = abs(g.X.Scale - n.X.Scale) < 0.0005 and abs(g.X.Offset - n.X.Offset) < 1 and abs(g.Y.Scale - n.Y.Scale) < 0.0005 and abs(g.Y.Offset - n.Y.Offset) < 1
			else
				n = cur:Lerp(g, a)
				done = (g - n).Magnitude < 0.5
			end
			if done then t[p] = g; props[p] = nil else t[p] = n; any = true end
		end
		if next(props) == nil then Anim[t] = nil end
	end
	if not any and next(Anim) == nil and AnimConn then AnimConn:Disconnect(); AnimConn = nil end
end
local function tween(t, p, g)
	local props = Anim[t]
	if not props then props = {}; Anim[t] = props end
	props[p] = g
	if not AnimConn then AnimConn = RS.RenderStepped:Connect(animStep) end
end
local function set(t, p, v)
	local props = Anim[t]
	if props then props[p] = nil end
	t[p] = v
end
local function place(t, p, v, animated) if animated then tween(t, p, v) else set(t, p, v) end end

-------------------------------------------------------------------------------
-- Theme binding
-------------------------------------------------------------------------------
local Bound = {}
local function resolve(src) if type(src) == "function" then return src() end return Current[src] end
local function bind(inst, prop, src)
	local b = Bound[inst]
	if not b then
		b = {}; Bound[inst] = b
		inst.Destroying:Once(function() Bound[inst] = nil; Anim[inst] = nil end)
	end
	b[prop] = src
	inst[prop] = resolve(src)
end
local function refresh(inst, instant)
	local b = Bound[inst]
	if not b then return end
	for p, src in b do
		if instant then set(inst, p, resolve(src)) else tween(inst, p, resolve(src)) end
	end
end

-------------------------------------------------------------------------------
-- Instance helpers
-------------------------------------------------------------------------------
local TEXT = { TextLabel = true, TextButton = true, TextBox = true }
local function mk(class, props, parent)
	local i = Instance.new(class)
	if i:IsA("GuiObject") then i.BorderSizePixel = 0; i.BackgroundTransparency = 1 end
	if class == "TextButton" then i.AutoButtonColor = false; i.Text = "" end
	if TEXT[class] then
		i.FontFace = Font.new(FONT, Enum.FontWeight.SemiBold); i.TextSize = 13
		i.TextXAlignment = Enum.TextXAlignment.Left; i.TextYAlignment = Enum.TextYAlignment.Top
	end
	local bg, fg, radius, border
	for k, v in props or {} do
		if k == "Bg" then bg = v elseif k == "Fg" then fg = v elseif k == "Radius" then radius = v elseif k == "Border" then border = v
		elseif k == "Weight" then i.FontFace = Font.new(FONT, v)
		else i[k] = v end
	end
	if bg then
		if not (props and props.BackgroundTransparency) then i.BackgroundTransparency = 0 end
		bind(i, "BackgroundColor3", bg)
	end
	if fg then bind(i, "TextColor3", fg) end
	if radius then
		local c = Instance.new("UICorner")
		c.CornerRadius = radius >= FULL and UDim.new(0.5, 0) or UDim.new(0, radius)
		c.Parent = i
	end
	if border then
		local s = Instance.new("UIStroke")
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Thickness = 1
		bind(s, "Color", border)
		s.Parent = i
	end
	if parent then i.Parent = parent end
	return i
end

local function capOffset(rowH, size) return math.ceil((rowH - round(size * 0.7)) / 2 - round(size * 0.16)) end
local function lbl(parent, o)
	local size, rowH, x = o.Size or 12, o.RowH or M.Row, o.X or 0
	return mk("TextLabel", {
		Fg = o.Fg or "Text", Text = o.Text or "", TextSize = size, Weight = o.Weight, TextTruncate = Enum.TextTruncate.AtEnd,
		Position = Off(x, (o.Y or 0) + capOffset(rowH, size)),
		Size = o.W and Off(o.W, rowH) or Dim2(1, -x - (o.Right or 0), 0, rowH), ZIndex = o.ZIndex or 1,
	}, parent)
end
local function centered(parent, text, rowH, size, fg)
	local l = lbl(parent, { Text = text, RowH = rowH, Size = size or 13, Fg = fg })
	l.Size = Dim2(1, -8, 0, rowH); l.Position = Off(4, l.Position.Y.Offset)
	l.TextXAlignment = Enum.TextXAlignment.Center
	return l
end
local function grad(inst)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	bind(g, "Color", function() return ColorSequence.new(Color3.new(1, 1, 1), Current.Gradient) end)
	g.Parent = inst
end
local function fire(cb, ...) if cb then task.spawn(cb, ...) end end
local function isClick(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function mousePos() return UIS:GetMouseLocation() end
local function inside(f, p, m)
	m = m or 0
	local a, s = f.AbsolutePosition, f.AbsoluteSize
	return p.X >= a.X - m and p.X <= a.X + s.X + m and p.Y >= a.Y - m and p.Y <= a.Y + s.Y + m
end
local function hover(inst, on, off)
	inst.MouseEnter:Connect(on); inst.MouseLeave:Connect(off)
end
local function drag(onMove, onEnd)
	local last
	local c = RS.RenderStepped:Connect(function()
		local p = mousePos()
		if p ~= last then last = p; onMove(p) end
	end)
	local e
	e = UIS.InputEnded:Connect(function(i)
		if isClick(i) then c:Disconnect(); e:Disconnect(); if onEnd then onEnd() end end
	end)
end
local function interactive(target, base, hov, press, handle)
	local st = { H = false, P = false }
	bind(target, "BackgroundColor3", function()
		if st.P and press then return Current[press] end
		if st.H then return Current[hov or "HoveredElement"] end
		return Current[base]
	end)
	local src = handle or target
	hover(src, function() st.H = true; refresh(target) end, function() st.H, st.P = false, false; refresh(target) end)
	if src:IsA("GuiButton") then
		src.MouseButton1Down:Connect(function() st.P = true; refresh(target) end)
		src.MouseButton1Up:Connect(function() st.P = false; refresh(target) end)
	end
end

-------------------------------------------------------------------------------
-- Lucide icons: SVG -> cached segments. Segments are scale-based, so one geometry serves any size.
-------------------------------------------------------------------------------
local IconBase = { "https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/", "https://cdn.jsdelivr.net/gh/lucide-icons/lucide@main/icons/" }
local IconAliases = { robot = "bot", gear = "settings", layout = "layout-template", cube = "box", reset = "rotate-ccw", logo = "flower", bullet = "crosshair" }
local IconSVG = { ["blossom-resize"] = '<path d="M21 15l-6 6"/><path d="M21 8L8 21"/>' }
local IconSegs, IconWait = {}, {}

local function parsePath(d, out)
	local pos, len = 1, #d
	local function num()
		local s, e = d:find("^[%s,]*[-+]?%d*%.?%d+", pos)
		if not s then return nil end
		local str = (d:sub(s, e):gsub("[%s,]", ""))
		pos = e + 1
		return tonumber(str)
	end
	local function flag()
		local s, e = d:find("^[%s,]*[01]", pos)
		if not s then return nil end
		pos = e + 1
		return tonumber(d:sub(e, e))
	end
	local cx, cy, sx, sy, cur, lcx, lcy = 0, 0, 0, 0, nil, nil, nil
	local function lineTo(x, y)
		if not cur then cur = { cx, cy }; table.insert(out, cur) end
		cx, cy = x, y
		cur[#cur + 1] = x; cur[#cur + 1] = y
	end
	local function cubic(x1, y1, x2, y2, x, y)
		local x0, y0 = cx, cy
		for s = 1, 5 do
			local t = s / 5; local u = 1 - t
			lineTo(u*u*u*x0 + 3*u*u*t*x1 + 3*u*t*t*x2 + t*t*t*x, u*u*u*y0 + 3*u*u*t*y1 + 3*u*t*t*y2 + t*t*t*y)
		end
		lcx, lcy = x2, y2
	end
	local function arc(rx, ry, deg, large, sweep, x, y)
		local x0, y0 = cx, cy
		if x0 == x and y0 == y then return end
		rx, ry = abs(rx), abs(ry)
		if rx == 0 or ry == 0 then lineTo(x, y) return end
		local phi = math.rad(deg); local cp, sp = math.cos(phi), math.sin(phi)
		local dx, dy = (x0 - x) / 2, (y0 - y) / 2
		local x1, y1 = cp * dx + sp * dy, -sp * dx + cp * dy
		local lam = x1*x1/(rx*rx) + y1*y1/(ry*ry)
		if lam > 1 then local g = math.sqrt(lam); rx, ry = rx * g, ry * g end
		local sign = large == sweep and -1 or 1
		local num_ = rx*rx*ry*ry - rx*rx*y1*y1 - ry*ry*x1*x1
		local den = rx*rx*y1*y1 + ry*ry*x1*x1
		local co = sign * math.sqrt(math.max(0, num_ / den))
		local cxp, cyp = co * rx * y1 / ry, -co * ry * x1 / rx
		local mx, my = cp * cxp - sp * cyp + (x0 + x) / 2, sp * cxp + cp * cyp + (y0 + y) / 2
		local st = math.atan2((y1 - cyp) / ry, (x1 - cxp) / rx)
		local dl = math.atan2((-y1 - cyp) / ry, (-x1 - cxp) / rx) - st
		if sweep == 0 and dl > 0 then dl -= math.pi * 2 elseif sweep == 1 and dl < 0 then dl += math.pi * 2 end
		local steps = math.max(1, math.ceil(abs(dl) / math.rad(30)))
		for s = 1, steps do
			if s == steps then lineTo(x, y) else
				local an = st + dl * s / steps; local ca, sa = math.cos(an), math.sin(an)
				lineTo(mx + rx * ca * cp - ry * sa * sp, my + rx * ca * sp + ry * sa * cp)
			end
		end
	end
	local cmd
	while true do
		local s = d:find("[^%s,]", pos)
		if not s then break end
		pos = s
		local c = d:sub(pos, pos)
		if c:find("%a") then
			cmd = c; pos += 1
			if cmd == "z" or cmd == "Z" then
				if cur then lineTo(sx, sy) end
				cx, cy, cur, cmd = sx, sy, nil, nil
				continue
			end
		elseif not cmd then break end
		local rel = cmd == cmd:lower()
		local op = cmd:upper()
		local ox, oy = rel and cx or 0, rel and cy or 0
		if op ~= "C" and op ~= "S" then lcx = nil end
		local function args(n) local l = {}; for i = 1, n do local v = num(); if not v then return nil end; l[i] = v end; return l end
		if op == "M" then local v = args(2); if not v then break end
			cx, cy = v[1] + ox, v[2] + oy; sx, sy, cur = cx, cy, nil; cmd = rel and "l" or "L"
		elseif op == "L" then local v = args(2); if not v then break end; lineTo(v[1] + ox, v[2] + oy)
		elseif op == "H" then local v = args(1); if not v then break end; lineTo(v[1] + ox, cy)
		elseif op == "V" then local v = args(1); if not v then break end; lineTo(cx, v[1] + oy)
		elseif op == "C" then local v = args(6); if not v then break end
			cubic(v[1] + ox, v[2] + oy, v[3] + ox, v[4] + oy, v[5] + ox, v[6] + oy)
		elseif op == "S" then local v = args(4); if not v then break end
			local x1, y1 = cx, cy
			if lcx then x1, y1 = 2 * cx - lcx, 2 * cy - lcy end
			cubic(x1, y1, v[1] + ox, v[2] + oy, v[3] + ox, v[4] + oy)
		elseif op == "Q" then local v = args(4); if not v then break end
			local x0, y0 = cx, cy
			for st = 1, 4 do local t = st / 4; local u = 1 - t
				lineTo(u*u*x0 + 2*u*t*(v[1]+ox) + t*t*(v[3]+ox), u*u*y0 + 2*u*t*(v[2]+oy) + t*t*(v[4]+oy)) end
		elseif op == "A" then
			local rx, ry, rot = num(), num(), num(); local lg, sw = flag(), flag(); local x, y = num(), num()
			if not (rx and ry and rot and lg and sw and x and y) then break end
			arc(rx, ry, rot, lg, sw, x + ox, y + oy)
		else break end
	end
end

local function parseSVG(text)
	local polys = {}
	for tag, attrs in text:gmatch("<(%a+)%s([^>]*)>") do
		local a = {}
		for k, v in attrs:gmatch('([%w%-:]+)%s*=%s*"([^"]*)"') do a[k] = v end
		local function n(k) return tonumber(a[k]) or 0 end
		if tag == "path" and a.d then parsePath(a.d, polys)
		elseif tag == "circle" or tag == "ellipse" then
			local x, y = n("cx"), n("cy")
			local rx = tag == "circle" and n("r") or n("rx")
			local ry = tag == "circle" and n("r") or n("ry")
			parsePath(("M%f %fa%f %f 0 1 0 %f 0a%f %f 0 1 0 %f 0z"):format(x - rx, y, rx, ry, rx * 2, rx, ry, -rx * 2), polys)
		elseif tag == "rect" then
			local x, y, w, h = n("x"), n("y"), n("width"), n("height")
			local rx = a.rx and n("rx") or n("ry"); local ry = a.ry and n("ry") or rx
			rx, ry = math.min(rx, w / 2), math.min(ry, h / 2)
			if rx > 0 and ry > 0 then
				parsePath(("M%f %fH%fA%f %f 0 0 1 %f %fV%fA%f %f 0 0 1 %f %fH%fA%f %f 0 0 1 %f %fV%fA%f %f 0 0 1 %f %fZ"):format(
					x + rx, y, x + w - rx, rx, ry, x + w, y + ry, y + h - ry, rx, ry, x + w - rx, y + h,
					x + rx, rx, ry, x, y + h - ry, y + ry, rx, ry, x + rx, y), polys)
			else parsePath(("M%f %fH%fV%fH%fZ"):format(x, y, x + w, y + h, x), polys) end
		elseif tag == "line" then parsePath(("M%f %fL%f %f"):format(n("x1"), n("y1"), n("x2"), n("y2")), polys)
		elseif (tag == "polyline" or tag == "polygon") and a.points then
			local d, i = "", 0
			for v in a.points:gmatch("[-+]?%d*%.?%d+") do
				i += 1
				d = d .. (i == 1 and "M" or (i % 2 == 1 and "L" or " ")) .. v
				if i == 1 then d = d .. " " end
			end
			parsePath(d .. (tag == "polygon" and "Z" or ""), polys)
		end
	end
	-- polylines -> merged segment list in 24-unit space
	local segs = {}
	for _, p in polys do
		local px, py = p[1], p[2]
		for i = 3, #p, 2 do
			local x, y = p[i], p[i + 1]
			local dx, dy = x - px, y - py
			local len = math.sqrt(dx * dx + dy * dy)
			if len > 0.05 then
				segs[#segs + 1] = { (px + x) / 2, (py + y) / 2, len, math.deg(math.atan2(dy, dx)) }
				px, py = x, y
			end
		end
	end
	return segs
end

local function httpGet(url)
	local ok, body = pcall(function() return game:HttpGet(url) end)
	if ok and type(body) == "string" then return body end
	return nil
end
local function iconSource(name)
	if IconSVG[name] then return IconSVG[name] end
	local path = "Blossom/icons/" .. name .. ".svg"
	if typeof(isfile) == "function" and isfile(path) then
		local ok, t = pcall(readfile, path)
		if ok and t:find("<svg", 1, true) then return t end
	end
	for _, base in IconBase do
		local t = httpGet(base .. name .. ".svg")
		if t and t:find("<svg", 1, true) then
			if typeof(writefile) == "function" then
				if typeof(makefolder) == "function" then pcall(makefolder, "Blossom"); pcall(makefolder, "Blossom/icons") end
				pcall(writefile, path, t)
			end
			return t
		end
	end
end
local function loadIcon(name, cb)
	if IconSegs[name] then return cb(IconSegs[name]) end
	if IconWait[name] then return table.insert(IconWait[name], cb) end
	IconWait[name] = { cb }
	task.spawn(function()
		local text = name:match("^[%w%-_]+$") and iconSource(name)
		local segs = text and parseSVG(text) or {}
		IconSegs[name] = segs
		local list = IconWait[name]; IconWait[name] = nil
		for _, f in list do f(segs) end
	end)
end
local function icon(parent, name, size, color, props)
	props = props or {}
	local root = mk("Frame", { Name = "Icon", Size = Off(size, size), Position = props.Position, AnchorPoint = props.AnchorPoint }, parent)
	local ic = { Root = root, Parts = {} }
	function ic.Update() for _, p in ic.Parts do refresh(p) end end
	local key = tostring(name or "box"):lower()
	key = IconAliases[key] or key
	loadIcon(key, function(segs)
		if not root.Parent then return end
		local thick = 2 / 24
		for _, s in segs do
			local f = mk("Frame", {
				Bg = color, AnchorPoint = Vec2(0.5, 0.5), Radius = FULL, Position = Dim2(s[1] / 24, 0, s[2] / 24, 0),
				Size = Dim2((s[3] / 24) + thick, 0, thick, 0), Rotation = s[4],
			}, root)
			ic.Parts[#ic.Parts + 1] = f
		end
	end)
	return ic
end

-------------------------------------------------------------------------------
-- Classes
-------------------------------------------------------------------------------
local Window, Tab, Section = {}, {}, {}
Window.__index, Tab.__index, Section.__index = Window, Tab, Section
local SubTab = {}; SubTab.__index = SubTab
local Gear = setmetatable({}, { __index = Section }); Gear.__index = Gear
local ModeOrder = { "Toggle", "Hold", "Press" }

local function keyName(k)
	if k == nil then return "-" end
	local s = { LeftShift = "LS", RightShift = "RS", LeftControl = "LC", RightControl = "RC", LeftAlt = "LA", RightAlt = "RA", MouseButton1 = "M1", MouseButton2 = "M2", MouseButton3 = "M3", Return = "Ent", Backspace = "Bk", One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9", Zero = "0" }
	return s[k.Name] or k.Name
end
local function fmt(v, dec) if dec and dec > 0 then return ("%." .. dec .. "f"):format(v) end return tostring(floor(v + 0.5)) end

-- Column ---------------------------------------------------------------------
local function colLayout(col)
	local y = 0
	for _, s in col.Sections do
		s.Y = y
		s.Root.Position = Off(0, y)
		y += s.TotalH + M.Pad
	end
	col.ContentH = math.max(0, y - M.Pad)
	col.Scroll.CanvasSize = Off(0, col.ContentH)
end

-- Section layout -------------------------------------------------------------
function Section:Layout()
	local y = M.Pad
	for _, it in self.Items do
		it.Y = y
		it.Frame.Position = Off(0, y)
		y += it.Height + M.Gap
	end
	if #self.Items > 0 then y -= M.Gap end
	self.CardH = y + M.Pad
	self.TotalH = self.HeaderH + self.CardH
	self.Card.Size = Dim2(1, -2, 0, self.CardH - 2)
	self.Root.Size = Dim2(1, 0, 0, self.TotalH)
	colLayout(self.Column)
end

function Section:_item(height, kind, name)
	local frame = mk("Frame", { Size = Dim2(1, 0, 0, height) }, self.Body)
	local it = { Frame = frame, Height = height, Kind = kind, Name = name, Section = self }
	table.insert(self.Items, it)
	if name and kind ~= "Label" and kind ~= "Listbox" then table.insert(self.Win.Index, it) end
	self:Layout()
	return it
end

-- right-aligned inline slots (toggle track, colour swatch, keybind chip, gear) laid out by UIListLayout
local function slots(it)
	if it.Slots then return it.Slots end
	local f = mk("Frame", { AnchorPoint = Vec2(1, 0), Position = Dim2(1, -1, 0, 0), Size = Off(0, M.Row), AutomaticSize = Enum.AutomaticSize.X }, it.Frame)
	local l = Instance.new("UIListLayout")
	l.FillDirection = Enum.FillDirection.Horizontal; l.HorizontalAlignment = Enum.HorizontalAlignment.Right
	l.VerticalAlignment = Enum.VerticalAlignment.Center; l.SortOrder = Enum.SortOrder.LayoutOrder; l.Padding = UDim.new(0, 8)
	l.Parent = f
	it.Slots, it.SlotN = f, 0
	f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if it.Label then it.Label.Size = Dim2(1, -(f.AbsoluteSize.X + M.Gap), 0, M.Row) end
	end)
	return f
end
local function addSlot(it, obj)
	local f = slots(it)
	it.SlotN += 1
	obj.LayoutOrder = -it.SlotN
	obj.Parent = f
end

local function chip(text, h)
	h = h or 16
	local c = mk("Frame", { Bg = "Element", Radius = M.Radius, Border = "Outline", Size = Off(0, h - 2), AutomaticSize = Enum.AutomaticSize.X }, nil)
	grad(c)
	local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 4); pad.PaddingRight = UDim.new(0, 4); pad.Parent = c
	local mc = Instance.new("UISizeConstraint"); mc.MinSize = Vector2.new(18, 0); mc.Parent = c
	local t = mk("TextLabel", { Fg = "InactiveText", Text = text, TextSize = 11, Size = Off(0, h - 2), AutomaticSize = Enum.AutomaticSize.X, TextYAlignment = Enum.TextYAlignment.Center, TextXAlignment = Enum.TextXAlignment.Center }, c)
	return c, t
end

-- registry ----------------------------------------------------------------------
local function register(sec, obj, o, it)
	local win = sec.Win
	function obj:SetValue(...) return self:Set(...) end
	function obj:OnChanged(cb)
		local k = self.Chip and "OnKeyChanged" or "Callback"
		local prev = self[k]
		self[k] = prev and function(...) prev(...); fire(cb, ...) end or cb
	end
	if o.NoSave then return end
	local base = o.Flag or (sec.TabName .. "/" .. sec.Name .. "/" .. tostring(o.Name or it.Kind))
	local flag, n = base, 1
	while win.Flags[flag] do n += 1; flag = base .. "#" .. n end
	win.Flags[flag] = obj
	;(it.Kind == "Toggle" and win.Toggles or win.Options)[flag] = obj
	obj.Flag = flag
	return flag
end

-- Keybind ---------------------------------------------------------------------
local function attachKeybind(sec, it, o)
	local win = sec.Win
	local kb = { Key = o.Key, Mode = "Toggle", Name = o.Name, OnPress = o.OnPress, Listening = false }
	if o.Modes then kb.Modes = {}; for _, m in (type(o.Modes) == "string" and { o.Modes } or o.Modes) do kb.Modes[m] = true end end
	if table.find(ModeOrder, o.Mode) then kb.Mode = o.Mode
	elseif kb.Modes then for _, m in ModeOrder do if kb.Modes[m] then kb.Mode = m break end end end
	local c, t = chip(keyName(kb.Key))
	local btn = mk("TextButton", { Size = Dim2(1, 0, 1, 0), ZIndex = 2 }, c)
	interactive(c, "Element", nil, nil, btn)
	bind(t, "TextColor3", function() return kb.Listening and Current.Accent or Current.InactiveText end)
	addSlot(it, c)
	function kb.Refresh()
		t.Text = kb.Listening and "..." or keyName(kb.Key)
		refresh(t, true)
		if kb.OnKeyChanged then fire(kb.OnKeyChanged) end
		win:_hk()
	end
	function kb:Set(k) kb.Key = k; kb.Refresh() end
	function kb:SetMode(m)
		if not table.find(ModeOrder, m) or (kb.Modes and not kb.Modes[m]) then return false end
		kb.Mode = m
		if kb.OnModeChanged then fire(kb.OnModeChanged, m) end
		win:_hk()
		return true
	end
	btn.MouseButton1Click:Connect(function() kb.Listening = true; win.Listening = kb; kb.Refresh() end)
	btn.MouseButton2Click:Connect(function() win:_keyMenu(c, kb) end)
	kb.Chip, kb.Label = c, t
	table.insert(win.Binds, kb)
	return kb
end

-- Colour ----------------------------------------------------------------------
local function attachColor(sec, it, o)
	local win = sec.Win
	local col = { Value = o.Default or Color3.new(1, 1, 1), Alpha = o.Alpha or 0, Callback = o.Callback }
	local sw = mk("TextButton", { Size = Off(12, 12), Radius = M.Radius, BackgroundTransparency = 0, BackgroundColor3 = col.Value, Border = "Outline" }, nil)
	addSlot(it, sw)
	col.Swatch = sw
	function col:Set(v, a, silent)
		if type(a) == "boolean" then a, silent = nil, a end
		col.Value = v
		if a ~= nil then col.Alpha = a end
		sw.BackgroundColor3 = v
		if win.Picker.Target == col and not win.Picker.Dragging then win.Picker.Sync() end
		if not silent then fire(col.Callback, v, col.Alpha) end
	end
	sw.MouseButton1Click:Connect(function() win:_picker(sw, col) end)
	return col
end

-- Gear popup ------------------------------------------------------------------
function Gear:Layout()
	local y = M.Pad
	for _, it in self.Items do it.Frame.Position = Off(0, y); y += it.Height + M.Gap end
	self.Popup.Size = Off(self.Win.ColumnW, (#self.Items > 0 and y - M.Gap or y) + M.Pad)
end
function Gear:_item(height, kind, name)
	local frame = mk("Frame", { Size = Dim2(1, 0, 0, height) }, self.Body)
	local it = { Frame = frame, Height = height, Kind = kind, Name = name, Section = self }
	table.insert(self.Items, it)
	self:Layout()
	return it
end
local function attachGear(sec, it, name)
	local win = sec.Win
	local popup = mk("TextButton", { Bg = "Background", Size = Off(win.ColumnW, 20), Radius = 5, Border = "Outline", Visible = false }, win.Popups)
	local gear = setmetatable({ Win = win, TabName = sec.TabName, Name = sec.Name .. "/" .. tostring(name), Popup = popup, Items = {}, Index = {},
		Body = mk("Frame", { Position = Off(M.Pad, 0), Size = Dim2(1, -M.Pad * 2, 1, 0) }, popup) }, Gear)
	local btn = mk("TextButton", { Size = Off(M.Row, M.Row) }, nil)
	local hov = false
	local ic = icon(btn, "settings", 14, function() return hov and Current.Text or Current.InactiveText end, { Position = Off(1, 1) })
	addSlot(it, btn)
	hover(btn, function() hov = true; ic.Update() end, function() hov = false; ic.Update() end)
	local turns = 0
	btn.MouseButton1Click:Connect(function()
		turns += 1; tween(ic.Root, "Rotation", turns * 180)
		win:_popup(popup, btn)
	end)
	local reset = {}
	function gear:ResetButton(n)
		local b = self:Button({ Name = n or "Reset to Default", Callback = function()
			for _, e in reset do pcall(function() e.O:Set(e.V) end) end
		end })
		return b
	end
	for _, kind in { "Toggle", "Slider", "RangeSlider", "Dropdown", "Textbox" } do
		local make = Section[kind]
		gear[kind] = function(self2, o)
			local obj = make(self2, o)
			local v = obj.Value
			table.insert(reset, { O = obj, V = type(v) == "table" and table.clone(v) or v })
			return obj
		end
	end
	return gear
end

local function inline(sec, it, o, name)
	local kb, col, gear
	if o.Color then col = attachColor(sec, it, { Default = o.Color, Alpha = o.ColorAlpha, Callback = o.ColorCallback }) end
	if o.Keybind ~= nil then kb = attachKeybind(sec, it, { Key = o.Keybind, Mode = o.KeybindMode, Modes = o.KeybindModes, Name = o.KeybindName or name }) end
	if o.Gear then gear = attachGear(sec, it, o.Name or name); if o.Reset then gear:ResetButton() end end
	return kb, col, gear
end

-- Elements ----------------------------------------------------------------------
function Section:Toggle(o)
	local win, name = self.Win, o.Name
	local it = self:_item(M.Row, "Toggle", name)
	local tg = { Value = o.Default == true, Item = it, Callback = o.Callback, Always = false }
	local hit = mk("TextButton", { Position = Off(0, -3), Size = Dim2(1, 0, 1, 6) }, it.Frame)
	local hov = false
	local text = lbl(it.Frame, { Text = name, Fg = function()
		if tg.Value then return Current.Text end
		return hov and Current.InactiveText:Lerp(Current.Text, 0.45) or Current.InactiveText
	end })
	it.Label = text
	local track = mk("Frame", { Bg = function() return tg.Value and Current.Accent or Current.Element end, Size = Off(26, 14), Radius = FULL, Border = "Outline" }, nil)
	grad(track)
	local knob = mk("Frame", { Bg = function() return tg.Value and Current.Text or Current.InactiveText end, Size = Off(10, 10), Radius = FULL }, track)
	addSlot(it, track)
	local function render(anim)
		place(knob, "Position", Off(tg.Value and 14 or 2, 2), anim)
		refresh(track, not anim); refresh(knob, not anim); refresh(text, not anim)
	end
	function tg:Set(v, silent)
		v = v == true
		if v == tg.Value then return end
		tg.Value = v
		if not v then tg.Always = false end
		render(true); win:_hk()
		if not silent then fire(tg.Callback, v) end
	end
	function tg:SetAlways(v) tg.Always = v == true; if v then tg:Set(true) end; win:_hk() end
	hover(hit, function() hov = true; refresh(text) end, function() hov = false; refresh(text) end)
	hit.MouseButton1Click:Connect(function() tg:Set(not tg.Value) end)
	local hkName = o.KeybindName or (name == "Enabled" and self.Name) or name
	tg.Keybind, tg.Color, tg.Gear = inline(self, it, o, hkName)
	if tg.Keybind then
		local kb = tg.Keybind
		kb.Toggle = tg
		kb.OnPress = function()
			if kb.Mode == "Press" then fire(o.PressCallback or tg.Callback, true)
			elseif tg.Always then return
			elseif kb.Mode == "Hold" then tg:Set(true)
			else tg:Set(not tg.Value) end
		end
		kb.OnRelease = function() if kb.Mode == "Hold" and not tg.Always then tg:Set(false) end end
		win:_hk()
	end
	render(false)
	local flag = register(self, tg, o, it)
	if flag and tg.Keybind then win.Flags[flag .. "/Key"] = tg.Keybind end
	if flag and tg.Color then win.Flags[flag .. "/Color"] = tg.Color end
	return tg
end

function Section:Label(o)
	local name = o.Name or o.Text
	local it = self:_item(M.Row, "Label", name)
	local t = lbl(it.Frame, { Text = name })
	it.Label = t
	local obj = { Item = it, Instance = t }
	function obj:Set(v) t.Text = v end
	obj.Keybind, obj.Color, obj.Gear = inline(self, it, o, name)
	return obj
end

function Section:Divider()
	local it = self:_item(9, "Divider")
	mk("Frame", { Bg = "Element", Position = Off(1, 1), Size = Dim2(1, -2, 1, -2), Radius = FULL, Border = "Outline" }, it.Frame)
	return it
end

function Section:Keybind(o)
	local it = self:_item(M.Row, "Keybind", o.Name)
	it.Label = lbl(it.Frame, { Text = o.Name })
	local kb = attachKeybind(self, it, { Key = o.Default, Mode = o.Mode, Modes = o.Modes, Name = o.Name })
	kb.Item, kb.Callback, kb.State = it, o.Callback, false
	kb.OnPress = function()
		if kb.Mode == "Press" then fire(kb.Callback, true)
		elseif kb.Mode == "Hold" then kb.State = true; fire(kb.Callback, true)
		else kb.State = not kb.State; fire(kb.Callback, kb.State); self.Win:_hk() end
	end
	kb.OnRelease = function() if kb.Mode == "Hold" and kb.State then kb.State = false; fire(kb.Callback, false) end end
	register(self, kb, o, it)
	if o.Hotkey ~= false then kb.InList = true; self.Win:_hk() end
	return kb
end

function Section:Colorpicker(o)
	local it = self:_item(M.Row, "Colorpicker", o.Name)
	it.Label = lbl(it.Frame, { Text = o.Name })
	local col = attachColor(self, it, o)
	col.Item = it
	register(self, col, o, it)
	return col
end

local function track(parent)
	local tr = mk("Frame", { Bg = "Element", Position = Off(1, 25), Size = Dim2(1, -2, 0, 7), Radius = FULL, Border = "Outline" }, parent)
	grad(tr)
	local fill = mk("Frame", { Bg = "Accent", Radius = FULL, Size = Dim2(0, 0, 1, 0) }, tr)
	grad(fill)
	local hit = mk("TextButton", { Position = Off(-4, 16), Size = Dim2(1, 8, 0, 17), ZIndex = 4 }, parent)
	return tr, fill, hit
end
local function knobOf(tr) return mk("Frame", { Bg = "Text", Size = Off(11, 11), Radius = FULL, ZIndex = 3, AnchorPoint = Vec2(0.5, 0.5) }, tr) end
local function alphaAt(tr, p) return clamp((p.X - tr.AbsolutePosition.X - 5) / math.max(1, tr.AbsoluteSize.X - 10), 0, 1) end
local function valueChip(parent)
	local c = mk("Frame", { Bg = "Element", Radius = M.Radius, Border = "Outline", Size = Off(0, 15), AutomaticSize = Enum.AutomaticSize.X }, parent)
	grad(c)
	local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 4); pad.PaddingRight = UDim.new(0, 4); pad.Parent = c
	local mc = Instance.new("UISizeConstraint"); mc.MinSize = Vector2.new(24, 0); mc.Parent = c
	local box = mk("TextBox", { Fg = "Text", TextSize = 11, Size = Off(0, 15), AutomaticSize = Enum.AutomaticSize.X, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, c)
	return c, box
end
local function barPos(tr, alpha) return Dim2(alpha, 0, 0.5, 0) end

function Section:Slider(o)
	local it = self:_item(M.SliderH, "Slider", o.Name)
	local cap = lbl(it.Frame, { Text = o.Name })
	local min, max, dec, suf = o.Min or 0, o.Max or 100, o.Decimals or 0, o.Suffix or ""
	local s = { Value = min, Item = it, Callback = o.Callback }
	local c, box = valueChip(it.Frame)
	c.AnchorPoint = Vec2(1, 0); c.Position = Dim2(1, -1, 0, 1)
	c:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() cap.Size = Dim2(1, -(c.AbsoluteSize.X + M.Gap), 0, M.Row) end)
	local tr, fill, hit = track(it.Frame)
	local knob = knobOf(tr)
	local scale = 10 ^ dec
	local function render(anim)
		local a = max == min and 0 or (s.Value - min) / (max - min)
		place(knob, "Position", Dim2(a, 0, 0.5, 0), anim)
		place(fill, "Size", Dim2(a, 0, 1, 0), anim)
	end
	function s:Set(v, silent, anim)
		v = clamp(floor(v * scale + 0.5) / scale, min, max)
		local changed = v ~= s.Value
		s.Value = v
		box.Text = fmt(v, dec) .. suf
		render(anim ~= false)
		if changed and not silent then fire(s.Callback, v) end
	end
	box.Focused:Connect(function() box.Text = fmt(s.Value, dec) end)
	box.FocusLost:Connect(function()
		local n = tonumber(box.Text:match("%-?%d*%.?%d+") or "")
		if n then s:Set(n) else box.Text = fmt(s.Value, dec) .. suf end
		box.Text = fmt(s.Value, dec) .. suf
	end)
	local function fromMouse(p) s:Set(min + (max - min) * alphaAt(tr, p), nil, false) end
	hit.InputBegan:Connect(function(i) if isClick(i) then fromMouse(mousePos()); drag(fromMouse) end end)
	s:Set(o.Default or min, true, false)
	register(self, s, o, it)
	return s
end

function Section:RangeSlider(o)
	local it = self:_item(M.SliderH, "Range Slider", o.Name)
	local cap = lbl(it.Frame, { Text = o.Name })
	local min, max, dec, suf = o.Min or 0, o.Max or 100, o.Decimals or 0, o.Suffix or ""
	local d = o.Default or { min, max }
	local r = { Value = { d[1], d[2] }, Item = it, Callback = o.Callback }
	local holder = mk("Frame", { AnchorPoint = Vec2(1, 0), Position = Dim2(1, -1, 0, 1), Size = Off(0, 15), AutomaticSize = Enum.AutomaticSize.X }, it.Frame)
	local l = Instance.new("UIListLayout"); l.FillDirection = Enum.FillDirection.Horizontal; l.Padding = UDim.new(0, 2); l.SortOrder = Enum.SortOrder.LayoutOrder; l.Parent = holder
	local lc, lbx = valueChip(holder); lc.LayoutOrder = 1
	local hc, hbx = valueChip(holder); hc.LayoutOrder = 2
	holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() cap.Size = Dim2(1, -(holder.AbsoluteSize.X + M.Gap), 0, M.Row) end)
	local tr, fill, hit = track(it.Frame)
	local lk, hk = knobOf(tr), knobOf(tr)
	local scale = 10 ^ dec
	local function snapv(v) return clamp(floor(v * scale + 0.5) / scale, min, max) end
	local function al(v) return max == min and 0 or (v - min) / (max - min) end
	local function render(anim)
		local a, b = al(r.Value[1]), al(r.Value[2])
		place(lk, "Position", Dim2(a, 0, 0.5, 0), anim); place(hk, "Position", Dim2(b, 0, 0.5, 0), anim)
		place(fill, "Position", Dim2(a, 0, 0, 0), anim); place(fill, "Size", Dim2(b - a, 0, 1, 0), anim)
	end
	function r:Set(v, silent, anim)
		local lo, hi = snapv(math.min(v[1], v[2])), snapv(math.max(v[1], v[2]))
		local changed = lo ~= r.Value[1] or hi ~= r.Value[2]
		r.Value = { lo, hi }
		lbx.Text = fmt(lo, dec) .. suf; hbx.Text = fmt(hi, dec) .. suf
		render(anim ~= false)
		if changed and not silent then fire(r.Callback, r.Value) end
	end
	lbx.FocusLost:Connect(function() local n = tonumber(lbx.Text:match("%-?%d*%.?%d+") or ""); r:Set({ n and math.min(snapv(n), r.Value[2]) or r.Value[1], r.Value[2] }) end)
	hbx.FocusLost:Connect(function() local n = tonumber(hbx.Text:match("%-?%d*%.?%d+") or ""); r:Set({ r.Value[1], n and math.max(snapv(n), r.Value[1]) or r.Value[2] }) end)
	local active = 1
	local function valueAt(p) return snapv(min + (max - min) * alphaAt(tr, p)) end
	local function fromMouse(p)
		local v = valueAt(p)
		if active == 1 then r:Set({ math.min(v, r.Value[2]), r.Value[2] }, nil, false) else r:Set({ r.Value[1], math.max(v, r.Value[1]) }, nil, false) end
	end
	hit.InputBegan:Connect(function(i)
		if not isClick(i) then return end
		local p = mousePos(); local v = valueAt(p)
		local lo, hi = r.Value[1], r.Value[2]
		active = (lo == hi and v >= lo or lo ~= hi and abs(v - lo) > abs(v - hi)) and 2 or 1
		fromMouse(p); drag(fromMouse)
	end)
	r:Set(r.Value, true, false)
	register(self, r, o, it)
	return r
end

-- Dropdown (floating panel; follows its input only while open) ----------------------
local function buildDropdown(win, parent, o)
	local dd = { Options = o.Options or {}, Multi = o.Multi == true, Open = false, Value = o.Multi and {} or o.Default, Callback = o.Callback }
	if o.Multi and o.Default then for _, v in o.Default do dd.Value[v] = true end end
	local input = mk("TextButton", { Position = Off(1, (o.Y or 0) + 1), Size = Dim2(1, -2, 0, M.InputH - 2), Radius = M.Radius, BackgroundTransparency = 0 }, parent)
	interactive(input, "Element"); grad(input)
	local stroke = Instance.new("UIStroke"); stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; stroke.Thickness = 1; stroke.Parent = input
	bind(stroke, "Color", function() return dd.Open and Current.Accent or Current.Outline end)
	local val = lbl(input, { Fg = "InactiveText", Size = 13, X = 7, RowH = M.InputH - 2, Right = 28 })
	icon(input, "chevron-down", 14, "InactiveText", { AnchorPoint = Vec2(1, 0), Position = Dim2(1, -5, 0, 5) })
	local panel = mk("TextButton", { Bg = "Background", Radius = M.Radius, Border = "Outline", Visible = false, Size = Off(10, 0) }, win.Dropdowns)
	local list = mk("ScrollingFrame", { Size = Dim2(1, 0, 1, 0), ScrollBarThickness = 0, CanvasSize = Off(0, 0) }, panel)
	local rows, panelH = {}, 0
	local function sel(opt) if dd.Multi then return dd.Value[opt] == true end return dd.Value == opt end
	local function caption()
		if not dd.Multi then return dd.Value ~= nil and tostring(dd.Value) or "None" end
		local n = {}
		for _, opt in dd.Options do if dd.Value[opt] then n[#n + 1] = tostring(opt) end end
		return #n > 0 and table.concat(n, ", ") or "None"
	end
	local function paint()
		for _, r in rows do
			local s = sel(r.Opt)
			r.Bar.BackgroundTransparency = s and 0 or 1
			refresh(r.Text, true)
			r.Text.Position = Off(s and 17 or 8, r.TY)
		end
		val.Text = caption()
	end
	local function rebuild()
		for _, r in rows do r.Btn:Destroy() end
		rows = {}
		for i, opt in dd.Options do
			local r = { Opt = opt, H = false }
			r.Btn = mk("TextButton", { Bg = function() return r.H and Current.Inline or Current.Background end, BackgroundTransparency = 1, Position = Off(0, (i - 1) * M.ListRowH), Size = Dim2(1, 0, 0, M.ListRowH) }, list)
			r.Bar = mk("Frame", { Bg = "Accent", BackgroundTransparency = 1, Position = Off(7, 6), Size = Off(2, 12) }, r.Btn)
			r.Text = lbl(r.Btn, { Text = tostring(opt), X = 8, Size = 13, RowH = M.ListRowH, Right = 18, Fg = function() return sel(opt) and Current.Text or Current.InactiveText end })
			r.TY = r.Text.Position.Y.Offset
			hover(r.Btn, function() r.H = true; r.Btn.BackgroundTransparency = 0; refresh(r.Btn, true) end, function() r.H = false; r.Btn.BackgroundTransparency = 1 end)
			r.Btn.MouseButton1Click:Connect(function()
				if dd.Multi then
					dd.Value[opt] = not dd.Value[opt] or nil
					paint(); fire(dd.Callback, dd.Value)
				else dd:Set(opt); dd:Toggle(false) end
			end)
			rows[#rows + 1] = r
		end
		list.CanvasSize = Off(0, #dd.Options * M.ListRowH)
		paint()
	end
	local followConn
	local function follow()
		local p, s = input.AbsolutePosition, input.AbsoluteSize
		local scr = win.Screen.AbsoluteSize
		local flip = p.Y + s.Y + 6 + panelH > scr.Y - 8 and p.Y - 6 - panelH > 8
		panel.AnchorPoint = flip and Vec2(0, 1) or Vec2(0, 0)
		panel.Position = Off(p.X, flip and p.Y - 6 or p.Y + s.Y + 6)
		panel.Size = Off(s.X, panelH)
	end
	function dd:Toggle(open)
		if open == nil then open = not dd.Open end
		if open == dd.Open then return end
		dd.Open = open
		refresh(stroke, true)
		if open then
			if win.OpenDropdown and win.OpenDropdown ~= dd then win.OpenDropdown:Toggle(false) end
			win.OpenDropdown = dd
			panelH = clamp(#dd.Options, 1, o.MaxRows or 10) * M.ListRowH
			follow(); panel.Visible = true
			followConn = RS.RenderStepped:Connect(follow)
		else
			if win.OpenDropdown == dd then win.OpenDropdown = nil end
			if followConn then followConn:Disconnect(); followConn = nil end
			panel.Visible = false
		end
	end
	function dd:Set(v, silent)
		if dd.Multi then
			dd.Value = {}
			for k, opt in v do if opt then dd.Value[type(k) == "string" and k or opt] = true end end
		else dd.Value = v end
		paint()
		if not silent then fire(dd.Callback, dd.Value) end
	end
	function dd:SetOptions(n) dd.Options = n; rebuild() end
	dd.Input, dd.Panel = input, panel
	input.MouseButton1Click:Connect(function()
		if win.DropClosedBy == input and os.clock() - win.DropClosedAt < 0.25 then return end
		dd:Toggle()
	end)
	rebuild()
	return dd
end

function Section:Dropdown(o)
	local it = self:_item(M.DropdownH, "Dropdown", o.Name)
	lbl(it.Frame, { Text = o.Name })
	o.Y = M.DropdownH - M.InputH
	local dd = buildDropdown(self.Win, it.Frame, o)
	dd.Item = it
	register(self, dd, o, it)
	return dd
end

function Section:Button(o)
	local it = self:_item(M.ButtonH, "Button", o.Name)
	local b = mk("TextButton", { Position = Off(1, 1), Size = Dim2(1, -2, 0, M.ButtonH - 2), Radius = M.Radius, Border = "Outline", BackgroundTransparency = 0 }, it.Frame)
	interactive(b, "Element", "HoveredElement", "Inline"); grad(b)
	local armed
	local text = centered(b, o.Name, M.ButtonH - 2, 13, function() return armed and Current.Accent or Current.Text end)
	local obj = { Item = it, Instance = b, Callback = o.Callback }
	local confirm = o.Confirm or o.DoubleClick
	local function arm(v) armed = v; text.Text = v and (o.ConfirmText or "Are you sure?") or o.Name; refresh(text, true) end
	b.MouseButton1Click:Connect(function()
		if not confirm then return fire(obj.Callback) end
		if armed then arm(nil); return fire(obj.Callback) end
		local mark = {}; arm(mark)
		task.delay(o.ConfirmTime or 3, function() if armed == mark then arm(nil) end end)
	end)
	return obj
end

function Section:Textbox(o)
	local it = self:_item(M.InputH, "Textbox", o.Name or o.Placeholder)
	local f = mk("Frame", { Bg = "Element", Position = Off(1, 1), Size = Dim2(1, -2, 0, M.InputH - 2), Radius = M.Radius, Border = "Outline" }, it.Frame)
	grad(f)
	local box = mk("TextBox", { Fg = "Text", PlaceholderText = o.Placeholder or o.Name or "", Text = o.Default or "", TextSize = 13, Position = Off(7, capOffset(M.InputH - 2, 13)), Size = Dim2(1, -14, 0, 18), ClearTextOnFocus = false }, f)
	bind(box, "PlaceholderColor3", "InactiveText")
	local obj = { Item = it, Instance = box, Value = box.Text, Callback = o.Callback }
	function obj:Set(t, silent) box.Text = t; obj.Value = t; if not silent then fire(obj.Callback, t) end end
	local stroke = f:FindFirstChildOfClass("UIStroke")
	local focused = false
	bind(stroke, "Color", function() return focused and Current.Accent or Current.Outline end)
	box.Focused:Connect(function() focused = true; refresh(stroke, true) end)
	box.FocusLost:Connect(function() focused = false; refresh(stroke, true); obj:Set(box.Text) end)
	register(self, obj, o, it)
	return obj
end

function Section:Listbox(o)
	local h = o.Height or 177
	local it = self:_item(h, "Listbox", o.Name)
	local f = mk("ScrollingFrame", { Bg = "Inline", Position = Off(1, 1), Size = Dim2(1, -2, 0, h - 2), Radius = M.Radius, Border = "Outline", ScrollBarThickness = 0, CanvasSize = Off(0, 0) }, it.Frame)
	local lb = { Options = {}, Value = nil, Item = it, Callback = o.Callback }
	local rows = {}
	local empty = lbl(f, { Fg = "InactiveText", Text = o.Empty or "Nothing here yet", Size = 13, X = 10, Y = 2, RowH = M.ListRowH, Right = 8 })
	local function paint()
		for _, r in rows do
			local s = lb.Value == r.Opt
			r.Bar.BackgroundTransparency = s and 0 or 1
			r.Text.Position = Off(s and 17 or 8, r.TY); refresh(r.Text, true)
		end
	end
	function lb:Set(v, silent) lb.Value = v; paint(); if not silent then fire(lb.Callback, v) end end
	function lb:SetOptions(list)
		for _, r in rows do r.Btn:Destroy() end
		rows, lb.Options = {}, list
		for i, opt in list do
			local r = { Opt = opt }
			r.Btn = mk("TextButton", { Bg = "HoveredElement", BackgroundTransparency = 1, Position = Off(2, 2 + (i - 1) * M.ListRowH), Size = Dim2(1, -4, 0, M.ListRowH), Radius = 2 }, f)
			r.Bar = mk("Frame", { Bg = "Accent", BackgroundTransparency = 1, Position = Off(6, 6), Size = Off(2, 12) }, r.Btn)
			r.Text = lbl(r.Btn, { Text = opt, X = 8, Size = 13, RowH = M.ListRowH, Right = 18, Fg = function() return lb.Value == opt and Current.Text or Current.InactiveText end })
			r.TY = r.Text.Position.Y.Offset
			hover(r.Btn, function() r.Btn.BackgroundTransparency = 0.4 end, function() r.Btn.BackgroundTransparency = 1 end)
			r.Btn.MouseButton1Click:Connect(function() lb:Set(opt) end)
			rows[#rows + 1] = r
		end
		f.CanvasSize = Off(0, 4 + #list * M.ListRowH)
		empty.Visible = #list == 0
		paint()
	end
	lb:SetOptions(o.Options or {})
	return lb
end

-------------------------------------------------------------------------------
-- Tab / SubTab / Section
-------------------------------------------------------------------------------
local function buildColumns(win, owner, parent)
	owner.Columns = {}
	for i = 1, 2 do
		local scroll = mk("ScrollingFrame", { Position = Off(M.Pad + (i - 1) * (win.ColumnW + M.Pad), 0), Size = Dim2(0, win.ColumnW, 1, 0), ScrollBarThickness = 0, CanvasSize = Off(0, 0), ClipsDescendants = true }, parent)
		local col = { Scroll = scroll, Sections = {}, ContentH = 0, Index = i, Target = 0 }
		table.insert(win.Columns, col)
		owner.Columns[i] = col
	end
end

function Tab:Section(o)
	assert(not self.Subs, "This tab has sub-tabs: create its sections with SubTab:Section.")
	return self.Window:_section(self, self.Columns[o.Side or 1], o, self.Name)
end
SubTab.Section = function(self, o) return self.Window:_section(self, self.Columns[o.Side or 1], o, self.Name) end

function Window:_section(owner, col, o, tabName)
	local win = self
	local hH = o.Description and 40 or 24
	local root = mk("Frame", { Name = o.Name, Size = Dim2(1, 0, 0, hH) }, col.Scroll)
	local header = mk("Frame", { Size = Dim2(1, 0, 0, hH - 8) }, root)
	local hov = false
	local tc = function() return hov and Current.Text or Current.InactiveText end
	local ic = icon(header, o.Icon or "cube", 16, tc)
	local title = lbl(header, { Text = o.Name, X = 27, Fg = tc })
	if o.Description then lbl(header, { Fg = "InactiveText", Text = o.Description, Size = 11, RowH = 14, Y = 18 }) end
	local hb = mk("TextButton", { Size = Dim2(1, 0, 1, 0) }, header)
	hover(hb, function() hov = true; ic.Update(); refresh(title) end, function() hov = false; ic.Update(); refresh(title) end)
	local card = mk("Frame", { Bg = "Inline", Active = true, Position = Off(1, hH + 1), Size = Dim2(1, -2, 0, 0), Radius = M.Card, Border = "Outline" }, root)
	local body = mk("Frame", { Position = Off(M.Pad - 1, -1), Size = Dim2(1, -(M.Pad - 1) * 2, 1, 2) }, card)
	local s = setmetatable({ Win = win, Tab = owner, TabName = tabName, Column = col, Name = o.Name, Root = root, Card = card, Body = body, Items = {}, HeaderH = hH, TotalH = hH, Y = 0 }, Section)
	table.insert(col.Sections, s)
	table.insert(win.Sections, s)
	s:Layout()
	return s
end

function Tab:SubTab(o)
	local win = self.Window
	if not self.Subs then
		self.Subs, self.BarX = {}, 0
		for _, c in self.Columns do c.Scroll.Visible = false end
		self.Bar = mk("Frame", { Position = Off(M.Pad, 0), Size = Dim2(1, -M.Pad * 2, 0, 24) }, self.Page)
		self.Pill = mk("Frame", { Bg = "Accent", Size = Off(0, 22), Radius = M.Radius, Border = "Outline", Visible = false }, self.Bar)
		grad(self.Pill)
	end
	local sub = setmetatable({ Window = win, Parent = self, Name = self.Name .. "/" .. o.Name }, SubTab)
	sub.Page = mk("Frame", { Name = o.Name, Position = Off(0, 32), Size = Dim2(1, 0, 1, -32), Visible = false }, self.Page)
	buildColumns(win, sub, sub.Page)
	local w = math.max(60, #o.Name * 7 + 24)
	sub.X, sub.W = self.BarX, w
	self.BarX += w + M.Gap
	sub.Button = mk("TextButton", { Position = Off(sub.X, 0), Size = Off(w, 24), ZIndex = 2 }, self.Bar)
	local hov = false
	sub.Label = centered(sub.Button, o.Name, 24, 13, function() return (self.Sub == sub or hov) and Current.Text or Current.InactiveText end)
	hover(sub.Button, function() hov = true; refresh(sub.Label, true) end, function() hov = false; refresh(sub.Label, true) end)
	sub.Button.MouseButton1Click:Connect(function() self:SelectSub(sub) end)
	table.insert(self.Subs, sub)
	if not self.Sub then self:SelectSub(sub) end
	return sub
end
function Tab:SelectSub(sub)
	if self.Sub == sub then return end
	local prev = self.Sub
	self.Sub = sub
	self.Window:CloseFloating()
	if prev then prev.Page.Visible = false; refresh(prev.Label, true) end
	sub.Page.Visible = true; refresh(sub.Label, true)
	self.Pill.Visible = true
	place(self.Pill, "Position", Off(sub.X + 1, 1), prev ~= nil)
	place(self.Pill, "Size", Off(sub.W - 2, 22), prev ~= nil)
end

-------------------------------------------------------------------------------
-- Window
-------------------------------------------------------------------------------
function Window:Category(name)
	local y = self.SideY + (self.HasTabs and 8 or 0)
	lbl(self.Sidebar, { Fg = "InactiveText", Text = name, Size = 9, X = M.Pad, RowH = 12, Y = y, W = 120 })
	self.SideY = y + 18
end

function Window:Tab(o)
	local y = self.SideY
	self.SideY += 32; self.HasTabs = true
	local tab = setmetatable({ Window = self, Name = o.Name }, Tab)
	local btn = mk("TextButton", { Position = Off(M.Pad, y), Size = Off(M.TabW, M.TabH), ZIndex = 2 }, self.Sidebar)
	local pill = mk("Frame", { Bg = "Inline", Radius = M.Pill, Border = "Outline", Position = Off(1, 1), Size = Off(M.TabW - 2, M.TabH - 2), Visible = false }, btn)
	local hov = false
	local active = function() return self.CurrentTab == tab end
	local color = function() return (active() or hov) and Current.Text or Current.InactiveText end
	tab.Icon = icon(btn, o.Icon or "cube", 16, color, { Position = Off(6, 6) })
	tab.Label = lbl(btn, { Text = o.Name, X = 33, Size = 13, RowH = M.TabH, Fg = color, Right = 6 })
	tab.Pill, tab.Button = pill, btn
	tab.Page = mk("Frame", { Name = o.Name, Size = Dim2(1, 0, 1, 0), Visible = false }, self.Pages)
	buildColumns(self, tab, tab.Page)
	function tab.Paint() pill.Visible = active(); tab.Icon.Update(); refresh(tab.Label, true) end
	hover(btn, function() hov = true; tab.Paint() end, function() hov = false; tab.Paint() end)
	btn.MouseButton1Click:Connect(function() self:SelectTab(tab) end)
	table.insert(self.Tabs, tab)
	if not self.CurrentTab then self:SelectTab(tab) end
	return tab
end

function Window:Cols() local t = self.CurrentTab; return (t.Sub or t).Columns end
function Window:SelectTab(tab)
	local sub
	if tab.Parent then sub, tab = tab, tab.Parent end
	if sub then tab:SelectSub(sub) end
	if self.CurrentTab == tab then return end
	local prev = self.CurrentTab
	self.CurrentTab = tab
	self:CloseFloating()
	if prev then prev.Page.Visible = false; prev.Paint() end
	tab.Page.Visible = true; tab.Paint()
end

-- Popups ------------------------------------------------------------------------
function Window:CloseFloating()
	if self.OpenDropdown then self.OpenDropdown:Toggle(false) end
	for i = #self.PopupStack, 1, -1 do table.remove(self.PopupStack, i).Visible = false end
end
function Window:_popup(frame, anchor)
	if self.LastPopup == anchor and os.clock() - self.LastPopupT < 0.15 then return end
	while #self.PopupStack > 0 and not anchor:IsDescendantOf(self.PopupStack[#self.PopupStack]) do
		table.remove(self.PopupStack).Visible = false
	end
	if table.find(self.PopupStack, frame) then return end
	local p, s = anchor.AbsolutePosition, anchor.AbsoluteSize
	local scr = self.Screen.AbsoluteSize
	frame.ZIndex = #self.PopupStack + 1
	frame.Position = Off(clamp(floor(p.X - 8), 8, math.max(8, scr.X - frame.Size.X.Offset - 8)), clamp(floor(p.Y + s.Y + M.Pad), 8, math.max(8, scr.Y - frame.Size.Y.Offset - 8)))
	frame.Visible = true
	table.insert(self.PopupStack, frame)
end

function Window:_keyMenu(chipFrame, kb)
	local m = self.KeyMenu
	m.Target = kb
	m.Paint()
	self:_popup(m.Frame, chipFrame)
end
function Window:_buildKeyMenu()
	local w, rowH = 202, M.InputH
	local frame = mk("TextButton", { Bg = "Background", Size = Off(w, M.Pad * 2 + rowH * 2 + M.Gap), Radius = 5, Border = "Outline", Visible = false }, self.Popups)
	local menu = { Frame = frame }
	local bw = floor((w - M.Pad * 2 - M.Gap * 2) / 3)
	local pill = mk("Frame", { Bg = "Accent", Size = Off(bw - 2, rowH - 2), Radius = M.Radius, Border = "Outline" }, frame)
	grad(pill)
	local btns = {}
	for i, mode in ModeOrder do
		local b = mk("TextButton", { Position = Off(M.Pad + (i - 1) * (bw + M.Gap), M.Pad), Size = Off(bw, rowH), ZIndex = 2 }, frame)
		centered(b, mode, rowH)
		btns[mode] = b
		b.MouseButton1Click:Connect(function() if menu.Target and menu.Target:SetMode(mode) then menu.Paint() end end)
	end
	local reset = mk("TextButton", { Position = Off(M.Pad + 1, M.Pad + rowH + M.Gap + 1), Size = Off(w - M.Pad * 2 - 2, rowH - 2), Radius = M.Radius, Border = "Outline", BackgroundTransparency = 0 }, frame)
	interactive(reset, "Element"); grad(reset)
	centered(reset, "Reset", rowH - 2)
	reset.MouseButton1Click:Connect(function() if menu.Target then menu.Target:Set(nil) end; self:CloseFloating() end)
	function menu.Paint()
		local t = menu.Target
		for i, mode in ModeOrder do
			local ok = not t.Modes or t.Modes[mode]
			btns[mode].Visible = ok
			if mode == t.Mode then pill.Position = Off(M.Pad + (i - 1) * (bw + M.Gap) + 1, M.Pad + 1) end
		end
	end
	self.KeyMenu = menu
end

function Window:_picker(swatch, color)
	local p = self.Picker
	p.Target = color
	p.Sync()
	self:_popup(p.Frame, swatch)
end
function Window:_buildPicker()
	local pad, width = M.Pad, 216
	local svW, svH = width - pad * 3 - 12, 150
	local frame = mk("TextButton", { Bg = "Background", Size = Off(width, pad * 3 + svH + 12 + 4), Radius = 5, Border = "Outline", Visible = false }, self.Popups)
	local pk = { Frame = frame, H = 0, S = 0, V = 1, Alpha = 0, Dragging = false }
	local sv = mk("Frame", { BackgroundTransparency = 0, Position = Off(pad, pad), Size = Off(svW, svH), Radius = M.Radius }, frame)
	local wf = mk("Frame", { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), Size = Dim2(1, 0, 1, 0), Radius = M.Radius }, sv)
	Instance.new("UIGradient", wf).Transparency = NumberSequence.new(0, 1)
	local bf = mk("Frame", { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(0, 0, 0), Size = Dim2(1, 0, 1, 0), Radius = M.Radius }, sv)
	local bg = Instance.new("UIGradient", bf); bg.Rotation = 90; bg.Transparency = NumberSequence.new(1, 0)
	local function ring(parent)
		local k = mk("Frame", { BackgroundTransparency = 0, AnchorPoint = Vec2(0.5, 0.5), Size = Off(8, 8), Radius = FULL, ZIndex = 3 }, parent)
		local st = Instance.new("UIStroke"); st.Thickness = 2; st.Parent = k; bind(st, "Color", "Text")
		return k
	end
	local svk = ring(sv)
	local hue = mk("Frame", { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), Position = Off(pad * 2 + svW, pad), Size = Off(12, svH), Radius = M.Radius }, frame)
	local keys = {}
	for i = 0, 6 do keys[#keys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((i / 6) % 1, 1, 1)) end
	local hg = Instance.new("UIGradient", hue); hg.Rotation = 90; hg.Color = ColorSequence.new(keys)
	local hk = ring(hue)
	local ab = mk("Frame", { BackgroundTransparency = 0, BackgroundColor3 = RGB(190, 190, 190), Position = Off(pad, pad * 2 + svH), Size = Off(width - pad * 2, 12), Radius = M.Radius }, frame)
	local af = mk("Frame", { BackgroundTransparency = 0, Size = Dim2(1, 0, 1, 0), Radius = M.Radius }, ab)
	Instance.new("UIGradient", af).Transparency = NumberSequence.new(0, 1)
	local ak = ring(ab)
	local function paint()
		local c, pure = Color3.fromHSV(pk.H, pk.S, pk.V), Color3.fromHSV(pk.H, 1, 1)
		sv.BackgroundColor3 = pure; svk.BackgroundColor3 = c
		svk.Position = Dim2(pk.S, 0, 1 - pk.V, 0)
		hk.Position = Dim2(0.5, 0, pk.H, 0); hk.BackgroundColor3 = pure
		af.BackgroundColor3 = c; ak.Position = Dim2(pk.Alpha, 0, 0.5, 0); ak.BackgroundColor3 = c
	end
	local function commit()
		paint()
		if pk.Target then pk.Target:Set(Color3.fromHSV(pk.H, pk.S, pk.V), pk.Alpha) end
	end
	function pk.Sync()
		local t = pk.Target
		if not t then return end
		local h, s, v = t.Value:ToHSV()
		if s > 0 and v > 0 then pk.H = h end
		pk.S, pk.V, pk.Alpha = s, v, t.Alpha or 0
		paint()
	end
	local function area(a, upd)
		local hit = mk("TextButton", { Position = Off(-4, -4), Size = Dim2(1, 8, 1, 8), ZIndex = 5 }, a)
		hit.InputBegan:Connect(function(i)
			if not isClick(i) then return end
			pk.Dragging = true; upd(mousePos())
			drag(upd, function() pk.Dragging = false end)
		end)
	end
	area(sv, function(p) pk.S = clamp((p.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1); pk.V = 1 - clamp((p.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1); commit() end)
	area(hue, function(p) pk.H = math.min(clamp((p.Y - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 1), 0.9999); commit() end)
	area(ab, function(p) pk.Alpha = clamp((p.X - ab.AbsolutePosition.X) / ab.AbsoluteSize.X, 0, 1); commit() end)
	self.Picker = pk
end

-- Hotkey list: rebuilt only when a bind changes (small, cheap) --------------------
function Window:_hk()
	if not self.HotkeyBody then return end
	if self.HkPending then return end
	self.HkPending = true
	task.defer(function()
		self.HkPending = false
		if self.Destroyed then return end
		for _, c in self.HotkeyBody:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end
		local n = 0
		for _, kb in self.Binds do
			local inList = (kb.Toggle ~= nil) or kb.InList
			local assigned = kb.Key ~= nil and kb.Key ~= Enum.KeyCode.Unknown
			local on = (kb.Toggle and kb.Toggle.Value) or kb.State == true
			if inList and (not self.HkOnlyAssigned or assigned) and (not self.HkOnlyEnabled or on) then
				n += 1
				local row = mk("Frame", { Bg = "Background", Size = Off(0, 26), AutomaticSize = Enum.AutomaticSize.X, Radius = M.Float, Border = "Outline", LayoutOrder = n }, self.HotkeyBody)
				local l = Instance.new("UIListLayout"); l.FillDirection = Enum.FillDirection.Horizontal; l.VerticalAlignment = Enum.VerticalAlignment.Center; l.Padding = UDim.new(0, 8); l.SortOrder = Enum.SortOrder.LayoutOrder; l.Parent = row
				local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0, 10); p.PaddingRight = UDim.new(0, 8); p.Parent = row
				mk("Frame", { Bg = on and "Accent" or "Element", Size = Off(8, 8), Radius = FULL, LayoutOrder = 1 }, row)
				mk("TextLabel", { Fg = on and "Text" or "InactiveText", Text = kb.Name or "Key", TextSize = 12, Size = Off(0, 24), AutomaticSize = Enum.AutomaticSize.X, TextYAlignment = Enum.TextYAlignment.Center, LayoutOrder = 2 }, row)
				local c, t = chip(keyName(kb.Key), 18); c.LayoutOrder = 3; c.Parent = row
			end
		end
	end)
end
function Window:SetHotkeyFilter(a, b)
	if a ~= nil then self.HkOnlyAssigned = a == true end
	if b ~= nil then self.HkOnlyEnabled = b == true end
	self:_hk()
end

-- Notifications -----------------------------------------------------------------
function Window:Notify(o)
	if type(o) == "string" then o = { Text = o } end
	local text = o.Text or o.Description or o.Title or ""
	local f = mk("Frame", { Bg = "Background", Size = Off(0, 28), AutomaticSize = Enum.AutomaticSize.X, Radius = M.Float, Border = "Outline", BackgroundTransparency = 1 }, self.Notifications)
	f.LayoutOrder = -floor(os.clock() * 1000)
	local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 28); pad.PaddingRight = UDim.new(0, 10); pad.Parent = f
	icon(f, o.Icon or "check", 14, function() return RGB(112, 205, 132) end, { Position = Off(-20, 7) })
	local t = mk("TextLabel", { Fg = "Text", Text = text, TextSize = 12, Size = Off(0, 28), AutomaticSize = Enum.AutomaticSize.X, TextYAlignment = Enum.TextYAlignment.Center }, f)
	f.BackgroundTransparency = 0.2
	task.delay(o.Duration or o.Time or 3, function()
		if not f.Parent then return end
		tween(f, "BackgroundTransparency", 1); tween(t, "TextTransparency", 1)
		task.delay(0.3, function() f:Destroy() end)
	end)
	local kids = self.Notifications:GetChildren()
	local n = 0
	for _, c in kids do if c:IsA("Frame") then n += 1 end end
	if n > 6 then for _, c in kids do if c:IsA("Frame") then c:Destroy() break end end end
end

-- Theme -------------------------------------------------------------------------
function Window:ApplyTheme(name, silent)
	local th = Themes[name]
	if not th then return end
	for k, v in th do Current[k] = v end
	self.ThemeName = name
	for inst in Bound do refresh(inst, true) end
	for _, r in self.ThemeRows do r.Color:Set(Current[r.Key], nil, true) end
	if not silent then self:Notify(('Applied "%s" theme.'):format(name)) end
end
function Window:SetFont(name) end

-- Window visibility ---------------------------------------------------------------
function Window:SetVisible(v)
	if self.Visible == v then return end
	self.Visible = v
	self:CloseFloating()
	self.Holder.Visible = v
	self.ModalButton.Visible = v
end
function Window:Toggle() self:SetVisible(not self.Visible) end

function Window:_clampHolder()
	local scr, s = self.Screen.AbsoluteSize, self.Holder.AbsoluteSize
	local p = self.Holder.Position
	self.Holder.Position = Off(clamp(p.X.Offset, 60 - s.X / 2, scr.X - 60 + s.X / 2), clamp(p.Y.Offset, s.Y / 2, scr.Y - 30 + s.Y / 2))
end
function Window:_applySize(w, h)
	self.Width, self.Height = w, h
	self.ColumnW = (w - 142 - M.Pad * 3) / 2
	self.Holder.Size = Off(w, h)
	for _, c in self.Columns do
		c.Scroll.Position = Off(M.Pad + (c.Index - 1) * (self.ColumnW + M.Pad), 0)
		c.Scroll.Size = Dim2(0, self.ColumnW, 1, 0)
	end
end
function Window:SetSize(w, h) self:_applySize(math.max(w, self.MinSize.X), math.max(h, self.MinSize.Y)) end

-- Configs -----------------------------------------------------------------------
local ConfigMemory = {}
local function cfgPath(n) return "Blossom/" .. n .. ".json" end
local function clean(t) return (t:gsub('[\\/:*?"<>|]', ""):match("^%s*(.-)%s*$")) end
local function encode(o)
	if o.Swatch then return { Color = "#" .. o.Value:ToHex(), Alpha = o.Alpha }
	elseif o.Chip then return { Key = o.Key and o.Key.Name or "None", Mode = o.Mode }
	elseif o.Multi then local l = {}; for k, v in o.Value do if v then l[#l + 1] = k end end; table.sort(l); return l end
	return o.Value
end
local function applyV(o, v)
	if o.Swatch then
		local t = type(v) == "table"
		o:Set(Color3.fromHex(t and v.Color or v), t and v.Alpha or nil)
	elseif o.Chip then
		if v.Mode then o:SetMode(v.Mode) end
		local k
		if v.Key and v.Key ~= "None" then k = tostring(v.Key):find("MouseButton", 1, true) and Enum.UserInputType[v.Key] or Enum.KeyCode[v.Key] end
		o:Set(k)
	else o:Set(v) end
end
function Window:ExportConfig()
	local data = { _format = "Blossom config", _version = 2 }
	for flag, o in self.Flags do
		local v = encode(o)
		if v ~= nil then
			local tab, sec, name = flag:match("^([^/]+)/([^/]+)/(.+)$")
			if tab then data[tab] = data[tab] or {}; data[tab][sec] = data[tab][sec] or {}; data[tab][sec][name] = v
			else data._custom = data._custom or {}; data._custom[flag] = v end
		end
	end
	return HTTP:JSONEncode(data)
end
function Window:ImportConfig(json)
	local ok, data = pcall(HTTP.JSONDecode, HTTP, json)
	if not ok or type(data) ~= "table" then return false, 0 end
	local n = 0
	local function ap(flag, v) local o = self.Flags[flag]; if o and pcall(applyV, o, v) then n += 1 end end
	for k, v in data do
		if k == "_custom" then for f, x in v do ap(f, x) end
		elseif k:sub(1, 1) ~= "_" and type(v) == "table" then
			for sec, items in v do if type(items) == "table" then for name, x in items do ap(k .. "/" .. sec .. "/" .. name, x) end end end
		end
	end
	return n > 0, n
end
function Window:ListConfigs()
	local names = {}
	if typeof(listfiles) == "function" and typeof(isfolder) == "function" and isfolder("Blossom") then
		for _, p in listfiles("Blossom") do local n = p:match("([^/\\]+)%.json$"); if n then names[#names + 1] = n end end
	else for n in ConfigMemory do names[#names + 1] = n end end
	table.sort(names)
	return names
end
function Window:SearchConfigs(q)
	q = (q or ""):lower()
	local out = {}
	for _, n in self:ListConfigs() do if q == "" or n:lower():find(q, 1, true) then out[#out + 1] = n end end
	return out
end
function Window:GetConfigText(n)
	if typeof(readfile) == "function" and typeof(isfile) == "function" and isfile(cfgPath(n)) then return readfile(cfgPath(n)) end
	return ConfigMemory[n]
end
function Window:SaveConfig(n)
	local j = self:ExportConfig()
	if typeof(writefile) == "function" then
		if typeof(isfolder) == "function" and not isfolder("Blossom") then makefolder("Blossom") end
		writefile(cfgPath(n), j)
	else ConfigMemory[n] = j end
end
function Window:LoadConfig(n) local j = self:GetConfigText(n); if j then return self:ImportConfig(j) end; return false end
function Window:DeleteConfig(n)
	if typeof(delfile) == "function" and typeof(isfile) == "function" and isfile(cfgPath(n)) then delfile(cfgPath(n)) end
	ConfigMemory[n] = nil
end

local AUTO = "Blossom/autoload.txt"
local AutoMem
local function readAuto()
	if typeof(readfile) == "function" and typeof(isfile) == "function" then return isfile(AUTO) and readfile(AUTO) or nil end
	return AutoMem
end
local function writeAuto(n)
	if typeof(writefile) ~= "function" then AutoMem = n
	elseif n then if typeof(isfolder) == "function" and not isfolder("Blossom") then makefolder("Blossom") end; writefile(AUTO, n)
	elseif typeof(delfile) == "function" and isfile(AUTO) then delfile(AUTO) end
end

function Window:BuildSettings(tab)
	local selected
	local saved = readAuto()
	local autoOn, autoName = saved ~= nil, saved
	local autoList
	local menu = tab:Section({ Name = "Menu", Icon = "box", Side = 1 })
	local mk_ = menu:Keybind({ Name = "Menu Key", Default = self.MenuKey, NoSave = true, Hotkey = false })
	mk_.OnKeyChanged = function() self.MenuKey = mk_.Key end
	local wm = menu:Toggle({ Name = "Watermark", Default = true, NoSave = true, Callback = function(v) self.Watermark.Visible = v end })
	local hl = menu:Toggle({ Name = "Hotkey List", Default = true, Gear = true, Callback = function(v) self.Hotkeys.Visible = v end })
	hl.Gear:Toggle({ Name = "Only Assigned", Default = self.HkOnlyAssigned, Callback = function(v) self:SetHotkeyFilter(v, nil) end })
	hl.Gear:Toggle({ Name = "Only Enabled", Default = self.HkOnlyEnabled, Callback = function(v) self:SetHotkeyFilter(nil, v) end })
	if not self.HideUnload then menu:Button({ Name = "Unload", Confirm = true, Callback = function() self:Destroy() end }) end

	local prof = tab:Section({ Name = "Profiles", Icon = "box", Side = 1 })
	prof:Label({ Name = "Configs" })
	local sbox = prof:Textbox({ Placeholder = "Search configs", NoSave = true })
	local lb = prof:Listbox({ Height = 177, Empty = "No configs yet", Options = self:ListConfigs(), Callback = function(v) selected = v end })
	local nbox = prof:Textbox({ Placeholder = "Config name", NoSave = true })
	local function refreshList()
		lb:SetOptions(self:SearchConfigs(sbox.Instance.Text))
		autoList:SetOptions(self:ListConfigs())
	end
	sbox.Instance:GetPropertyChangedSignal("Text"):Connect(function() lb:SetOptions(self:SearchConfigs(sbox.Instance.Text)) end)
	prof:Button({ Name = "Create", Callback = function()
		local n = clean(nbox.Instance.Text)
		if n == "" then return self:Notify("Enter a config name first.") end
		self:SaveConfig(n); refreshList(); self:Notify(('Created "%s".'):format(n))
	end })
	prof:Button({ Name = "Load", Callback = function()
		if selected then self:Notify((self:LoadConfig(selected) and 'Loaded "%s".' or 'Could not load "%s".'):format(selected)) end
	end })
	prof:Button({ Name = "Delete", Callback = function()
		if not selected then return end
		self:DeleteConfig(selected)
		if selected == autoName then autoName = nil; autoList:Set(nil, true); writeAuto(nil) end
		self:Notify(('Deleted "%s".'):format(selected)); selected = nil; refreshList()
	end })
	prof:Button({ Name = "Overwrite", Callback = function()
		if selected then self:SaveConfig(selected); self:Notify(('Overwrote "%s".'):format(selected)) end
	end })
	local ibox = prof:Textbox({ Placeholder = "Paste config JSON", NoSave = true })
	prof:Button({ Name = "Export", Callback = function()
		local copy = setclipboard or toclipboard
		if typeof(copy) ~= "function" then return self:Notify("Clipboard is not available here.") end
		copy(selected and self:GetConfigText(selected) or self:ExportConfig())
		self:Notify("Copied to the clipboard.")
	end })
	prof:Button({ Name = "Import", Callback = function()
		local text = ibox.Instance.Text
		if text == "" and typeof(getclipboard) == "function" then text = getclipboard() end
		local ok, n = self:ImportConfig(text)
		if not ok then return self:Notify("That is not a valid Blossom config.") end
		ibox:Set("", true)
		local name = clean(nbox.Instance.Text)
		if name ~= "" then self:SaveConfig(name); refreshList() end
		self:Notify(("Imported %d settings."):format(n))
	end })

	local auto = tab:Section({ Name = "Autoload", Icon = "box", Side = 1 })
	auto:Toggle({ Name = "Load on start", Default = autoOn, NoSave = true, Callback = function(v) autoOn = v; writeAuto(autoOn and autoName or nil) end })
	autoList = auto:Dropdown({ Name = "Config", Options = self:ListConfigs(), Default = saved, NoSave = true, Callback = function(v) autoName = v; writeAuto(autoOn and autoName or nil) end })

	local th = tab:Section({ Name = "Theming", Icon = "box", Side = 2 })
	th:Dropdown({ Name = "Theme", Options = ThemeOrder, Default = self.ThemeName, MaxRows = 11, NoSave = true, Callback = function(v) self:ApplyTheme(v) end })
	th:Divider()
	for _, pair in ThemeKeys do
		local key = pair[2]
		local c = th:Colorpicker({ Name = pair[1], Default = Current[key], NoSave = true, Callback = function(v)
			Current[key] = v
			self.ThemePending = true
			self.ThemeDirty[key] = true
		end })
		table.insert(self.ThemeRows, { Key = key, Color = c })
	end
	if saved then task.defer(function() if self:LoadConfig(saved) then self:Notify(('Autoloaded "%s".'):format(saved)) end end) end
end

-- Search ------------------------------------------------------------------------
function Window:_buildSearch()
	local w, h, pad = 420, 340, M.Pad
	local overlay = mk("TextButton", { BackgroundTransparency = 0.45, BackgroundColor3 = Color3.new(0, 0, 0), Size = Dim2(1, 0, 1, 0), Visible = false, ZIndex = 20, Radius = 6 }, self.Root)
	local modal = mk("TextButton", { Bg = "Background", AnchorPoint = Vec2(0.5, 0.5), Position = Dim2(0.5, 0, 0.5, 0), Size = Off(w, h), Radius = 6, Border = "Outline" }, overlay)
	local title = lbl(modal, { Text = "Search", Size = 14, Weight = Enum.FontWeight.SemiBold, X = pad * 2, Y = pad + 2, RowH = 20 })
	local field = mk("Frame", { Bg = "Inline", Position = Off(pad * 2 + 1, 43), Size = Off(w - pad * 4 - 2, 34), Radius = M.Pill, Border = "Outline" }, modal)
	icon(field, "search", 14, "InactiveText", { Position = Off(10, 10) })
	local box = mk("TextBox", { Fg = "Text", PlaceholderText = "Type to search...", Position = Off(34, capOffset(34, 13)), Size = Dim2(1, -45, 0, 20), ClearTextOnFocus = false }, field)
	bind(box, "PlaceholderColor3", "InactiveText")
	local results = mk("ScrollingFrame", { Position = Off(pad * 2, 88), Size = Off(w - pad * 4 + 6, h - 88 - pad), CanvasSize = Off(0, 0), ScrollBarThickness = 2 }, modal)
	bind(results, "ScrollBarImageColor3", "Accent")
	local search = { Overlay = overlay, Open = false, Box = box, Order = {} }
	local function goTo(e)
		self:CloseSearch()
		local sec = e.Section or e
		self:SelectTab(sec.Tab)
		local col = sec.Column
		local y = sec.Y + (e.Section and sec.HeaderH + e.Y or 0) - 40
		col.Scroll.CanvasPosition = Vec2(0, math.max(0, y))
	end
	local function sync()
		for _, c in results:GetChildren() do c:Destroy() end
		local q = box.Text:lower()
		search.Order = {}
		if q ~= "" then
			local function add(e, name, sub)
				if #search.Order < 30 and name and name:lower():find(q, 1, true) then table.insert(search.Order, { e, name, sub }) end
			end
			for _, s in self.Sections do add(s, s.Name, s.TabName .. " / " .. s.Name .. "  ·  Section") end
			for _, it in self.Index do add(it, it.Name, it.Section.TabName .. " / " .. it.Section.Name .. "  ·  " .. it.Kind) end
		end
		for i, d in search.Order do
			local b = mk("TextButton", { Bg = "HoveredElement", BackgroundTransparency = 1, Position = Off(0, (i - 1) * 48), Size = Off(w - pad * 4, 44), Radius = M.Radius }, results)
			mk("Frame", { Bg = "Accent", Position = Off(4, 8), Size = Off(3, 28), Radius = 2 }, b)
			lbl(b, { Text = d[2], Size = 13, X = 14, Y = 5, RowH = 18, Right = 10 })
			lbl(b, { Fg = "InactiveText", Text = d[3], Size = 11, X = 14, Y = 22, RowH = 16, Right = 10 })
			hover(b, function() b.BackgroundTransparency = 0.4 end, function() b.BackgroundTransparency = 1 end)
			b.MouseButton1Click:Connect(function() goTo(d[1]) end)
		end
		results.CanvasSize = Off(0, #search.Order * 48)
		self.SearchLabel.Text = box.Text ~= "" and box.Text or "Search..."
		title.Text = box.Text ~= "" and box.Text or "Search"
	end
	box:GetPropertyChangedSignal("Text"):Connect(function() search.Dirty = true end)
	box.FocusLost:Connect(function(enter)
		if UIS:IsKeyDown(Enum.KeyCode.Escape) then self:CloseSearch()
		elseif enter then
			if search.Dirty then search.Dirty = false; sync() end
			if search.Order[1] then goTo(search.Order[1][1]) end
		end
	end)
	overlay.MouseButton1Click:Connect(function() self:CloseSearch() end)
	search.Sync = sync
	self.Search = search
end
function Window:OpenSearch()
	local s = self.Search
	if s.Open then return end
	s.Open = true; self:CloseFloating()
	s.Overlay.Visible = true; s.Box:CaptureFocus()
end
function Window:CloseSearch()
	local s = self.Search
	if not s.Open then return end
	s.Open = false; s.Box:ReleaseFocus(); s.Overlay.Visible = false
end

-- Watermark / hotkeys frames -----------------------------------------------------
function Window:_buildWatermark(o)
	local pl = Players.LocalPlayer
	local f = mk("Frame", { Bg = "Background", Size = Off(0, 28), AutomaticSize = Enum.AutomaticSize.X, Radius = M.Float, Border = "Outline", Active = true }, self.Screen)
	local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 31); pad.PaddingRight = UDim.new(0, 10); pad.Parent = f
	icon(f, "flower", 16, "Accent", { Position = Off(-23, 6) })
	local t = mk("TextLabel", { Fg = "Text", TextSize = 12, Size = Off(0, 28), AutomaticSize = Enum.AutomaticSize.X, TextYAlignment = Enum.TextYAlignment.Center }, f)
	self.Watermark = f
	local started, frames, acc, fps = os.clock(), 0, 0, 60
	local show = { Script = true, Build = true, Name = true, FPS = true, Ping = true }
	local order = { "Script", "Build", "Name", "FPS", "Ping", "Time", "Session" }
	local function ping() local ok, v = pcall(function() return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end); return ok and v or 0 end
	local prod = {
		Script = function() return o.Script or "blossom.lua" end, Build = function() return o.Build or "release" end,
		Name = function() return ("%s (@%s)"):format(pl.DisplayName, pl.Name) end,
		FPS = function() return fps .. " fps" end, Ping = function() return floor(ping()) .. " ms" end,
		Time = function() return os.date("%H:%M") end,
		Session = function() local s = floor(os.clock() - started); return ("%d:%02d:%02d"):format(s // 3600, s % 3600 // 60, s % 60) end,
	}
	local function update()
		local parts = {}
		for _, k in order do if show[k] then parts[#parts + 1] = prod[k]() end end
		t.Text = table.concat(parts, "  |  ")
	end
	function self:SetWatermarkItems(set)
		table.clear(show)
		for k, on in set do if on == true then show[k] = true elseif type(on) == "string" then show[on] = true end end
		update()
	end
	table.insert(self.Connections, RS.Heartbeat:Connect(function(dt)
		acc += dt; frames += 1
		if acc < 0.5 then return end
		fps, acc, frames = round(frames / acc), 0, 0
		update()
	end))
	update()
	self:_makeDraggable(f, f)
	local pressAt
	f.InputBegan:Connect(function(i) if isClick(i) then pressAt = mousePos() end end)
	f.InputEnded:Connect(function(i)
		if isClick(i) and pressAt then
			local moved = (mousePos() - pressAt).Magnitude; pressAt = nil
			if moved < 4 then self:Toggle() end
		end
	end)
end
function Window:_buildHotkeys()
	local holder = mk("Frame", { Size = Off(200, 300), AutomaticSize = Enum.AutomaticSize.Y }, self.Screen)
	local l = Instance.new("UIListLayout"); l.Padding = UDim.new(0, 5); l.SortOrder = Enum.SortOrder.LayoutOrder; l.Parent = holder
	local head = mk("Frame", { Bg = "Background", Size = Off(0, 25), AutomaticSize = Enum.AutomaticSize.X, Radius = M.Float, Border = "Outline", Active = true, LayoutOrder = -1 }, holder)
	local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 31); pad.PaddingRight = UDim.new(0, 10); pad.Parent = head
	icon(head, "keyboard", 14, "Accent", { Position = Off(-22, 5) })
	mk("TextLabel", { Fg = "Text", Text = "Hotkeys", TextSize = 12, Size = Off(0, 25), AutomaticSize = Enum.AutomaticSize.X, TextYAlignment = Enum.TextYAlignment.Center }, head)
	local body = mk("Frame", { Size = Off(200, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 0 }, holder)
	local bl = Instance.new("UIListLayout"); bl.Padding = UDim.new(0, 5); bl.SortOrder = Enum.SortOrder.LayoutOrder; bl.Parent = body
	self.Hotkeys, self.HotkeyBody = holder, body
	holder.Position = Off(14, 300)
	self:_makeDraggable(head, holder)
end

function Window:_makeDraggable(handle, target, allowed)
	handle.InputBegan:Connect(function(i)
		if not isClick(i) then return end
		local start, origin = mousePos(), target.Position
		if allowed and not allowed(start) then return end
		drag(function(p)
			local d = p - start
			if d.Magnitude < 1 then return end
			target.Position = Off(origin.X.Offset + d.X, origin.Y.Offset + d.Y)
			self.Moved[target] = true
		end)
	end)
end
function Window:_overControl(p)
	if self.Search.Open then return true end
	if self.OpenDropdown and inside(self.OpenDropdown.Panel, p) then return true end
	for _, f in self.PopupStack do if inside(f, p) then return true end end
	if inside(self.SearchButton, p) or inside(self.Grip, p) then return true end
	for _, t in self.Tabs do if inside(t.Button, p) then return true end end
	if self.CurrentTab then
		for _, s in self.CurrentTab.Subs or {} do if inside(s.Button, p) then return true end end
		for _, c in self:Cols() do
			if inside(c.Scroll, p) then for _, s in c.Sections do if inside(s.Root, p) then return true end end end
		end
	end
	return false
end

-- Destroy -----------------------------------------------------------------------
local Ghost
Ghost = setmetatable({}, { __index = function() return Ghost end, __call = function() return Ghost end })
local DeadMeta = { __index = function(_, k) if k == "Destroyed" then return true end; if k == "IsDestroyed" then return function() return true end end; return Ghost end }
function Window:IsDestroyed() return self.Destroyed == true end
function Window:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
	for _, cb in self.UnloadCallbacks do pcall(cb) end
	for _, c in self.Connections do c:Disconnect() end
	if AnimConn then AnimConn:Disconnect(); AnimConn = nil end
	table.clear(Anim)
	self.Screen:Destroy()
	for _, list in { self.Tabs, self.Sections } do for _, o in list do if type(o) == "table" then setmetatable(o, DeadMeta) end end end
	setmetatable(self, DeadMeta)
end

-------------------------------------------------------------------------------
-- Blossom.new
-------------------------------------------------------------------------------
local Blossom = { Themes = Themes, ThemeOrder = ThemeOrder, Metrics = M, Fonts = Fonts, GetThemeColor = function(k) return Current[k] end }
local LastWindow

local function guiParent(screen)
	local ok = false
	if typeof(gethui) == "function" then ok = pcall(function() screen.Parent = gethui() end) end
	if not ok then ok = pcall(function() screen.Parent = game:GetService("CoreGui") end) end
	if not ok or not screen.Parent then screen.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
end

function Blossom.new(o)
	o = o or {}
	local genv = typeof(getgenv) == "function" and getgenv() or nil
	local prev = LastWindow or (genv and genv.__BlossomWindow)
	if prev then pcall(prev.Destroy, prev) end
	if o.Theme and Themes[o.Theme] then for k, v in Themes[o.Theme] do Current[k] = v end end
	if o.Font then FONT = Fonts[o.Font] or (tostring(o.Font):find("rbx", 1, true) and o.Font) or FONT end
	if o.IconBase then IconBase = type(o.IconBase) == "table" and o.IconBase or { o.IconBase } end
	local minS = o.MinSize or Vec2(520, 380)
	local size = o.Size or Vec2(586, 466)
	local W, H = math.max(floor(size.X), minS.X), math.max(floor(size.Y), minS.Y)
	local win = setmetatable({
		Width = W, Height = H, MinSize = minS, ColumnW = (W - 142 - M.Pad * 3) / 2, Title = o.Title or "Blossom",
		Tabs = {}, Sections = {}, Columns = {}, Index = {}, Binds = {}, Flags = {}, Options = {}, Toggles = {}, ThemeRows = {}, ThemeDirty = {},
		Connections = {}, Moved = {}, UnloadCallbacks = {}, PopupStack = {}, SideY = 56, HasTabs = false,
		Visible = true, HideUnload = o.HideUnload == true, ThemeName = o.Theme or "Blood Moon", MenuKey = o.MenuKey or Enum.KeyCode.RightShift,
		LastPopupT = 0, DropClosedAt = 0, HkOnlyAssigned = o.HotkeyOnlyAssigned == true, HkOnlyEnabled = o.HotkeyOnlyEnabled == true,
	}, Window)
	LastWindow = win
	Blossom.Options, Blossom.Toggles = win.Options, win.Toggles
	if genv then genv.__BlossomWindow = win end

	local screen = mk("ScreenGui", { Name = "Blossom", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100 })
	guiParent(screen)
	win.Screen = screen

	local holder = mk("Frame", { Name = "Window", AnchorPoint = Vec2(0.5, 0.5), Size = Off(W, H), ZIndex = 10 }, screen)
	win.Holder = holder
	local root = mk("Frame", { Bg = "Background", Active = true, Size = Dim2(1, 0, 1, 0), Radius = 6, Border = "Outline" }, holder)
	win.Root = root
	win.ModalButton = mk("TextButton", { Modal = true, Size = Off(1, 1) }, holder)

	local sidebar = mk("Frame", { Size = Dim2(0, M.SidebarW, 1, 0) }, root)
	win.Sidebar = sidebar
	icon(sidebar, "flower", 20, "Accent", { Position = Off(20, 15) })
	lbl(sidebar, { Text = win.Title, Size = 16, Weight = Enum.FontWeight.Bold, X = 51, Y = 11, RowH = 28, W = 85 })
	local sb = mk("TextButton", { Position = Dim2(0, M.Pad + 1, 1, -(M.Pad + 28) + 1), Size = Off(M.TabW - 2, 26), Radius = M.Pill, Border = "Outline", BackgroundTransparency = 0 }, sidebar)
	interactive(sb, "Inline")
	win.SearchButton = sb
	icon(sb, "search", 14, "InactiveText", { Position = Off(6, 6) })
	win.SearchLabel = lbl(sb, { Fg = "InactiveText", Text = "Search...", X = 30, RowH = 26, Right = 6 })
	sb.MouseButton1Click:Connect(function() win:OpenSearch() end)

	mk("Frame", { Bg = "Outline", Position = Off(M.SidebarW, 0), Size = Dim2(0, 1, 1, 0) }, root)
	local content = mk("Frame", { Bg = "Tab", Position = Off(142, 0), Size = Dim2(1, -142, 1, 0), Radius = 6 }, root)
	mk("Frame", { Bg = "Tab", Size = Dim2(0, 12, 1, 0) }, content)
	win.Pages = mk("Frame", { Name = "Pages", Position = Off(0, M.Pad), Size = Dim2(1, 0, 1, -M.Pad * 2), ClipsDescendants = true }, content)

	win.Popups = mk("Frame", { Name = "Popups", Size = Dim2(1, 0, 1, 0), ZIndex = 40 }, screen)
	win.Dropdowns = mk("Frame", { Name = "Dropdowns", Size = Dim2(1, 0, 1, 0), ZIndex = 45 }, screen)
	win.Notifications = mk("Frame", { Name = "Notifications", Position = Off(16, 16), Size = Off(400, 600), ZIndex = 50 }, screen)
	local nl = Instance.new("UIListLayout"); nl.Padding = UDim.new(0, 8); nl.SortOrder = Enum.SortOrder.LayoutOrder; nl.Parent = win.Notifications

	win:_buildWatermark(o)
	win:_buildHotkeys()
	win:_buildKeyMenu()
	win:_buildPicker()
	win:_buildSearch()

	-- resize grip
	local grip = mk("TextButton", { AnchorPoint = Vec2(1, 1), Position = Dim2(1, -2, 1, -2), Size = Off(16, 16), ZIndex = 15 }, root)
	win.Grip = grip
	if o.Resizable ~= false then
		local gh = false
		icon(grip, "blossom-resize", 12, function() return gh and Current.InactiveText or Current.Outline end, { Position = Off(2, 2) })
		
		grip.MouseButton1Down:Connect(function()
			win:CloseFloating()
			local start, sw, sh = mousePos(), win.Width, win.Height
			local pos = holder.Position
			local left, top = pos.X.Offset - sw / 2, pos.Y.Offset - sh / 2
			drag(function(p)
				local d = p - start
				local w = math.max(floor(sw + d.X), win.MinSize.X); w -= w % 2
				local h = math.max(floor(sh + d.Y), win.MinSize.Y); h -= h % 2
				holder.Position = Off(left + w / 2, top + h / 2)
				win:_applySize(w, h)
			end)
		end)
	end

	local function place0()
		local s = screen.AbsoluteSize
		if s.X <= 0 then return end
		if not win.Moved[holder] then holder.Position = Off(floor(s.X / 2), floor(s.Y / 2)) end
		if not win.Moved[win.Watermark] then win.Watermark.Position = Off(floor(s.X / 2 - win.Watermark.AbsoluteSize.X / 2), s.Y - 44) end
		if not win.Moved[win.Hotkeys] then win.Hotkeys.Position = Off(14, floor((s.Y - 300) / 2)) end
	end
	place0()
	table.insert(win.Connections, screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(place0))
	table.insert(win.Connections, win.Watermark:GetPropertyChangedSignal("AbsoluteSize"):Connect(place0))
	win:_makeDraggable(root, holder, function(p) return not win:_overControl(p) end)

	-- input
	table.insert(win.Connections, UIS.InputBegan:Connect(function(input, processed)
		if isClick(input) then
			local p = mousePos()
			local dd = win.OpenDropdown
			local overDD = dd and inside(dd.Panel, p)
			if dd and not overDD then
				if inside(dd.Input, p) then win.DropClosedBy, win.DropClosedAt = dd.Input, os.clock() end
				dd:Toggle(false)
			end
			if not overDD then
				while #win.PopupStack > 0 do
					local top = win.PopupStack[#win.PopupStack]
					local over = false
					for _, f in win.PopupStack do if inside(f, p, 6) then over = true end end
					if over and inside(top, p, 6) then break end
					if over then win.LastPopup, win.LastPopupT = nil, 0; table.remove(win.PopupStack).Visible = false
					else win.LastPopupT = os.clock(); table.remove(win.PopupStack).Visible = false end
				end
			end
		end
		local l = win.Listening
		if l then
			local isKey = input.UserInputType == Enum.UserInputType.Keyboard
			local isMouse = input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3
			if isKey or isMouse then
				win.Listening = nil; l.Listening = false
				l.Key = (isKey and input.KeyCode == Enum.KeyCode.Escape) and nil or (isKey and input.KeyCode or input.UserInputType)
				l.Refresh()
			elseif isClick(input) then win.Listening = nil; l.Listening = false; l.Refresh() end
			return
		end
		if processed then return end
		if input.KeyCode == win.MenuKey or input.UserInputType == win.MenuKey then win:Toggle() end
		for _, b in win.Binds do
			if b.Key and (b.Key == input.KeyCode or b.Key == input.UserInputType) and b.OnPress then fire(b.OnPress) end
		end
	end))
	table.insert(win.Connections, UIS.InputEnded:Connect(function(input)
		for _, b in win.Binds do
			if b.Key and (b.Key == input.KeyCode or b.Key == input.UserInputType) and b.OnRelease then fire(b.OnRelease) end
		end
	end))
	table.insert(win.Connections, UIS.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseWheel or not win.Visible or win.Search.Open or not win.CurrentTab then return end
		local p = mousePos()
		if win.OpenDropdown then
			if inside(win.OpenDropdown.Panel, p) then return end
			win.OpenDropdown:Toggle(false)
		end
		for _, c in win:Cols() do
			if inside(c.Scroll, p) then
				local maxY = math.max(0, c.ContentH - c.Scroll.AbsoluteSize.Y)
				c.Target = clamp((c.Scroll.CanvasPosition.Y) - input.Position.Z * 60, 0, maxY)
				tween(c.Scroll, "CanvasPosition", Vec2(0, c.Target))
			end
		end
	end))
	-- light per-frame work: only batched theme-colour writes and search refresh
	local clock = 0
	table.insert(win.Connections, RS.Heartbeat:Connect(function(dt)
		if win.Search.Dirty then win.Search.Dirty = false; win.Search.Sync() end
		if win.ThemePending then
			clock += dt
			if clock >= 1 / 30 then
				clock = 0; win.ThemePending = false
				for inst in Bound do refresh(inst, true) end
				table.clear(win.ThemeDirty)
			end
		end
	end))

	win.Visible = true
	return win
end

-------------------------------------------------------------------------------
-- Obsidian / Linoria style API
-------------------------------------------------------------------------------
local function sideOf(s) if s == 2 or (type(s) == "string" and s:lower() == "right") then return 2 end return 1 end
local function keyOf(n)
	if n == "MB2" then return Enum.UserInputType.MouseButton2 end
	if n == "MB3" then return Enum.UserInputType.MouseButton3 end
	local ok, k = pcall(function() return Enum.KeyCode[n] end)
	return ok and k or nil
end
function Blossom.AddIcon(name, svg) IconSVG[name:lower()] = svg; IconSegs[name:lower()] = nil end
function Window:AddTab(name, ic) return self:Tab({ Name = name, Icon = ic }) end
function Window:OnUnload(cb) table.insert(self.UnloadCallbacks, cb) end
Window.Unload = Window.Destroy
function Tab:AddGroupbox(o) return self:Section({ Name = o.Name, Icon = o.IconName or o.Icon, Description = o.Description, Side = sideOf(o.Side) }) end
function Tab:AddLeftGroupbox(n, ic) return self:Section({ Name = n, Icon = ic, Side = 1 }) end
function Tab:AddRightGroupbox(n, ic) return self:Section({ Name = n, Icon = ic, Side = 2 }) end
function Tab:AddSubTab(n) return self:SubTab({ Name = n }) end
SubTab.AddGroupbox, SubTab.AddLeftGroupbox, SubTab.AddRightGroupbox = Tab.AddGroupbox, Tab.AddLeftGroupbox, Tab.AddRightGroupbox

local function chainable(sec, obj)
	function obj:AddColorPicker(index, o)
		local c = attachColor(sec, obj.Item, { Default = o.Default, Alpha = o.Transparency, Callback = o.Callback })
		c.Item = obj.Item
		register(sec, c, { Flag = index, Name = o.Title or index }, obj.Item)
		obj.Color = c
		return obj
	end
	function obj:AddKeyPicker(index, o)
		local cb = o.Callback
		local k = attachKeybind(sec, obj.Item, { Key = keyOf(o.Default), Mode = o.Mode, Modes = o.Modes, Name = o.Text or index, OnPress = cb and function() cb(true) end or nil })
		k.Item = obj.Item; k.InList = true
		register(sec, k, { Flag = index, Name = o.Text or index }, obj.Item)
		obj.Keybind = k
		sec.Win:_hk()
		return obj
	end
	return obj
end
function Section:AddToggle(index, o) return chainable(self, self:Toggle({ Name = o.Text, Default = o.Default, Callback = o.Callback, Flag = index })) end
Section.AddCheckbox = Section.AddToggle
function Section:AddSlider(index, o) return self:Slider({ Name = o.Text, Min = o.Min, Max = o.Max, Default = o.Default, Decimals = o.Rounding, Suffix = o.Suffix, Callback = o.Callback, Flag = index }) end
function Section:AddInput(index, o) return self:Textbox({ Name = o.Text, Placeholder = o.Placeholder, Default = o.Default, Callback = o.Callback, Flag = index }) end
function Section:AddDropdown(index, o)
	local values, def = o.Values or {}, o.Default
	if type(def) == "number" then def = values[def] end
	if o.Multi and def ~= nil and type(def) ~= "table" then def = { def } end
	return self:Dropdown({ Name = o.Text, Options = values, Default = def, Multi = o.Multi, Callback = o.Callback, Flag = index })
end
function Section:AddButton(o, fn)
	if type(o) == "string" then o = { Text = o, Func = fn } end
	return self:Button({ Name = o.Text, Callback = o.Func, Confirm = o.Confirm or o.DoubleClick, ConfirmText = o.ConfirmText })
end
function Section:AddLabel(text, extra) return chainable(self, self:Label({ Name = type(extra) == "table" and extra.Text or text })) end
Section.AddDivider = Section.Divider

return Blossom
