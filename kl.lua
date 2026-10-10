if not game:IsLoaded() then game.Loaded:Wait() end

local ps = game:GetService("Players")
repeat task.wait() until ps.LocalPlayer

local lp, rv = ps.LocalPlayer, getrenv().shared
while lp:GetAttribute("IsLoaded") ~= true do lp:GetAttributeChangedSignal("IsLoaded"):Wait() end
repeat task.wait(0.1) until rv.LoadingController and rv.LoadingController:IsLoaded()

local qk = {Right = "D", Left = "A", Up = "W"}

local function pd() return rv.PlayerDataV2Controller:Fetch() end

local function zx(t, nw)
	local fp, g = `Avenoric/Configs/FishingMaster/{lp.Name}_Log.txt`, getgenv().__FmLg
	if not g then
		g = {ls = {}, dt = false}
		getgenv().__FmLg = g
		pcall(function()
			for l in (isfile(fp) and readfile(fp) or ""):gmatch("[^\n]+") do table.insert(g.ls, l) end
		end)
	end
	local m = (tostring(t):gsub("%s*\n%s*", " <- "))
	local la = g.ls[#g.ls] or ""
	local lm, n = la:match("^[^|]+| (.-) x(%d+)$")
	local ts = os.date("%Y-%m-%d %H:%M:%S")
	if (lm or la:match("^[^|]+| (.*)$")) == m then
		g.ls[#g.ls] = `{ts} | {m} x{(tonumber(n) or 1) + 1}`
	else
		table.insert(g.ls, `{ts} | {m}`)
	end
	while #g.ls > 1000 do table.remove(g.ls, 1) end
	local function wr()
		g.dt = false
		pcall(function()
			for _, x in {"Avenoric", "Avenoric/Configs", "Avenoric/Configs/FishingMaster"} do
				if not isfolder(x) then makefolder(x) end
			end
			writefile(fp, table.concat(g.ls, "\n") .. "\n")
		end)
	end
	if nw then
		wr()
		return
	end
	if g.dt then return end
	g.dt = true
	task.delay(2, wr)
end

local function sk()
	local d, o = pd(), {}
	local r = d and d.Rods and d.Rods[d.RodEquip]
	for s, id in r and r.BookSlots or {} do
		if type(id) == "string" and id ~= "" and id ~= "None" then table.insert(o, {s, id}) end
	end
	table.sort(o, function(a, b) return a[1] < b[1] end)
	return o
end

local function eq()
	local d, c = pd(), lp.Character
	local rd = d and d.RodEquip
	if type(rd) ~= "string" or rd == "" or rd == "None" then return nil, "No Rod" end
	if not c then return nil, "No Character" end
	local function hd() return c:FindFirstChild(rd) and c[rd]:IsA("Tool") end
	if hd() then return true end
	rv.HeldToolController.SetHeldSlot:Fire(1)
	local dl = os.clock() + 5
	repeat task.wait(0.1) until hd() or os.clock() > dl
	if hd() then return true end
	return nil, "Equip Timeout"
end

local function tg(h)
	local w = workspace:FindFirstChild("World")
	local il, ip = w and w:FindFirstChild("Islands"), RaycastParams.new()
	ip.FilterType, ip.FilterDescendantsInstances = Enum.RaycastFilterType.Include, {il}
	for i = 0, 15 do
		local a = math.rad(i * 22.5)
		for _, r in {60, 50, 40, 30} do
			local p = Vector3.new(h.Position.X + math.sin(a) * r, 3, h.Position.Z + math.cos(a) * r)
			if not il or not workspace:Raycast(p + Vector3.new(0, 100, 0), Vector3.new(0, -100, 0), ip) then return p end
		end
	end
	return nil
end

local function fp(s)
	local lm, st = s.fp[1], s.fp[2]
	local el = workspace:GetServerTimeNow() - st
	local pk = (2 * math.max(0, math.ceil((el * 2.4 - 1) / 2)) + 1) / 2.4
	if pk < lm then task.wait(pk - el) end
	rv.FishingController.FishFirstPull:Fire()
end
