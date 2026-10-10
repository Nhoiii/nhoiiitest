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

local function rl(f, s, ks)
	local fc, mv, sq, nc = rv.FishingController, rv.RodController.Moveset, 0, 0
	while f.st == "Running" and not s.cr and not s.rr do
		local t = os.clock()
		if s.q and t >= s.q[2] then fc.FishQTEResponse:Fire(qk[s.q[1]]); s.q = nil end
		if not lp:GetAttribute("IsUsingSkill") then
			for _, x in ks do
				local c = s.cd[x[1]]
				if not c or c[1] == "Ready" or (c[1] == "Cooldown" or c[1] == "Pending") and t >= c[2] then
					mv:Fire(x[1], x[2])
					s.cd[x[1]], s.q = {"Pending", t + 1}, nil
					break
				end
			end
		end
		if t >= nc and t >= s.sw and t >= s.bs then
			sq = sq % 65535 + 1
			fc.FishReelPull:Fire(sq)
			nc = math.max(nc, t - 0.01) + 1 / 6 + 0.005
		end
		task.wait()
	end
	return nil
end

local ra = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Divine", "Huge"}

local function md(...)
	local x = game:GetService("ReplicatedStorage")
	for _, n in {...} do x = x:FindFirstChild(n) or error(`Module Missing: {n}`) end
	return require(x)
end

local function fl() return md("Shared", "Lib", "FishStorageRules").GetState(pd()).isFull end

local function ns(id, p)
	local b, bd, bx
	for _, x in game:GetService("CollectionService"):GetTagged("Interactive") do
		if x:GetAttribute("InteractiveId") == id then
			local q = x:IsA("Model") and x:GetPivot().Position or x:IsA("BasePart") and x.Position
			if q and (not bd or (q - p).Magnitude < bd) then b, bd, bx = q, (q - p).Magnitude, x end
		end
	end
	return b, bx
end

local sn = 0

local function sq(p, t)
	if sn >= 4 then return false end
	local dn = false
	sn += 1
	task.spawn(function()
		pcall(function() lp:RequestStreamAroundAsync(p, t) end)
		sn, dn = sn - 1, true
	end)
	local dl = os.clock() + t + 1
	repeat task.wait(0.1) until dn or os.clock() > dl
	return dn
end

local fz, cj, ut = {Enum.HumanoidStateType.Freefall, Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll}, nil, nil

local function lc()
	local c = lp.Character
	local r, h = c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
	if r and h and h.Health > 0 and r:IsA("BasePart") then return c, r, h end
	return nil
end

local function pz(p, cf)
	p.CFrame = cf
	p.AssemblyLinearVelocity, p.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
end

local function uc(j)
	if j.ca then j.ca:Disconnect(); j.cr:Disconnect() end
	for p, v in j.cc do pcall(function() p.CanCollide = v end) end
	for e, v in j.ss do pcall(function() j.h:SetStateEnabled(e, v) end) end
	j.c, j.h, j.ca, j.cr, j.cc, j.ss, j.pl = nil, nil, nil, nil, {}, {}, {}
end

local function ac(j, c, h)
	uc(j)
	j.c, j.h, j.pd = c, h, true
	for _, e in fz do j.ss[e] = h:GetStateEnabled(e); h:SetStateEnabled(e, false) end
	j.ca = c.DescendantAdded:Connect(function() j.pd = true end)
	j.cr = c.DescendantRemoving:Connect(function() j.pd = true end)
end

local function nx(j)
	local c, _, h = lc()
	if not c then return end
	if j.s >= 1e5 and j.oc and c ~= j.oc then error("Respawn", 0) end
	if c ~= j.c then ac(j, c, h) end
	if j.pd then
		j.pd, j.pl = false, {}
		for _, d in c:GetDescendants() do
			if d:IsA("BasePart") then
				if j.cc[d] == nil then j.cc[d] = d.CanCollide end
				table.insert(j.pl, d)
			end
		end
	end
	for _, p in j.pl do if p.CanCollide then p.CanCollide = false end end
	if h.Sit or h.SeatPart then h.Sit = false end
end

local function hx(j, dt)
	local c, r, h = lc()
	if not c then
		if j.c then uc(j) end
		j.st = "Respawn"
		return
	end
	if j.s >= 1e5 and j.oc and c ~= j.oc then error("Respawn", 0) end
	if c ~= j.c then ac(j, c, h) end
	local d = j.p - r.Position
	local ar, fd = d.Magnitude <= j.s * dt, Vector3.new(d.X, 0, d.Z)
	j.lk = ar and j.fk or fd.Magnitude > 1e-3 and fd.Unit or j.lk
	j.st = ar and "Arrived" or "Moving"
	pz(r, CFrame.lookAlong(ar and j.p or r.Position + d.Unit * j.s * dt, j.lk))
end

local function cz(j, st, why)
	if j.dn then return end
	j.dn = true
	j.cs:Disconnect(); j.ch:Disconnect()
	pcall(uc, j)
	pcall(function()
		local _, r = lc()
		if r then r.AssemblyLinearVelocity, r.AssemblyAngularVelocity = Vector3.zero, Vector3.zero end
		if r and not j.nl and r.Position.Y < -10 then pz(r, CFrame.new(ut(r.Position) or Vector3.new(r.Position.X, 12, r.Position.Z)) * r.CFrame.Rotation) end
	end)
	j.st, j.why = st, why
	if cj == j then cj = nil end
end

local function mo(p, s, fk)
	if typeof(p) ~= "Vector3" or p.Magnitude ~= p.Magnitude or p.Magnitude == math.huge then return nil, "Move Failed: Bad Point" end
	if typeof(fk) == "Vector3" and not (fk.Magnitude > 1e-3) then fk = nil end
	if cj then
		cj.nl = true
		cj:Stop()
	end
	local c, r, h = lc()
	if s < 1e5 and p.Y < -10 then p = ut(p) or Vector3.new(p.X, 12, p.Z) end
	if r and s < 1e5 and r.Position.Y < -10 then
		local u = ut(r.Position)
		if u then pz(r, CFrame.new(u) * r.CFrame.Rotation) end
	end
	local j = {st = "Moving", p = p, s = s, oc = c, cc = {}, ss = {}, pl = {}, lk = r and Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z).Unit or -Vector3.zAxis}
	j.fk = fk or j.lk
	function j.Stop(x) cz(x or j, "Stopped") end
	if c then ac(j, c, h) end
	local rs = game:GetService("RunService")
	j.cs = rs.Stepped:Connect(function()
		local ok, e = pcall(nx, j)
		if not ok then cz(j, "Failed", `Move Failed: {e}`) end
	end)
	j.ch = rs.Heartbeat:Connect(function(dt)
		local ok, e = pcall(hx, j, dt)
		if not ok then cz(j, "Failed", `Move Failed: {e}`) end
	end)
	cj = j
	return j
end

local ap, hv, aq

local function gf(f, p, fk)
	for _ = 1, 4 do
		local _, r = lc()
		if not r then return nil, "No Character" end
		local d = p - r.Position
		if Vector3.new(d.X, 0, d.Z).Magnitude <= 2 then return true end
		if f.st ~= "Running" then return nil end
		local j, e = mo(p, 30, fk)
		if not j then return nil, e end
		local dl = os.clock() + d.Magnitude / 30 + 5
		repeat task.wait() until j.st == "Arrived" or j.dn or f.st ~= "Running" or os.clock() > dl
		local why = j.why
		j:Stop()
		if why then return nil, why end
		if f.st ~= "Running" then return nil end
		task.wait(0.5)
	end
	return nil, "Move Timeout"
end

local go = gf

local function gd(c, p)
	local rp = RaycastParams.new()
	rp.FilterType, rp.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, {c}
	local r = workspace:Raycast(p + Vector3.new(0, 20, 0), Vector3.new(0, -60, 0), rp)
	return r and Vector3.new(p.X, r.Position.Y + 3, p.Z) or p
end

local function lk(sr, kp)
	local d, ct, sc, st, hl = pd(), md("Data", "Catalog"), rv.SellController, {}, {}
	for _, r in sr do st[r] = true end
	for u, x in d.Inventory.Fishes do
		local fi = ct.Fish.GetById(x.fishId)
		if x.locked ~= true and (kp[u] or not (fi and st[fi.rarity] and (not x.isHuge or st.Huge))) then
			local s, v = sc:ToggleLock(u)
			if s ~= 0 or v ~= true then return hl, `Lock Failed: {x.fishId}` end
			table.insert(hl, u)
		end
	end
	return hl, nil
end

local function zb(sr, kp)
	local d, ct, st, n = pd(), md("Data", "Catalog"), {}, 0
	for _, r in sr do st[r] = true end
	for u, x in d.Inventory.Fishes do
		local fi = ct.Fish.GetById(x.fishId)
		if x.locked ~= true and not kp[u] and fi and st[fi.rarity] and (not x.isHuge or st.Huge) then n += 1 end
	end
	return n
end

local function uk(hl)
	local d, sc = pd(), rv.SellController
	for _, u in hl do
		local x = d.Inventory.Fishes[u]
		if x then
			local s, v = sc:ToggleLock(u)
			if s == 0 and v == true then s, v = sc:ToggleLock(u) end
			if s ~= 0 or v ~= false then return nil, `Unlock Failed: {x.fishId}` end
		end
	end
	return true, nil
end

local function tr(f)
	local c = lp.Character
	local h = c and c:FindFirstChild("HumanoidRootPart")
	if not h then return nil, "No Character" end
	local o, sw = h.CFrame, rv.Swimming and rv.Swimming:IsSwimming()
	local np = ns("npc_fish_seller", o.Position)
	if not np then
		sq(o.Position, 5)
		np = ns("npc_fish_seller", o.Position)
	end
	if not np then return "Auto Fish Failed: No Fish Seller" end
	local hl, e = lk(f.sr(), f.kp())
	if e then
		local _, ue = uk(hl)
		return nil, ue or e
	end
	local hd = f.hf and f.hf() and not f.bu
	local mv, sp = hd and hv or go, hd and Vector3.new(np.X, math.max(6, np.Y - 18), np.Z) or aq(c, np, o.Position)
	local w, we, s
	for _ = 1, 3 do
		w, we = mv(f, sp, hd and Vector3.new(o.LookVector.X, 0, o.LookVector.Z).Unit or Vector3.new(np.X - sp.X, 0, np.Z - sp.Z).Unit, math.min(sp.Y, 10))
		if hd and not w and f.st == "Running" then zx(`[Hidden] Sell Move Failed: {we or "Unknown"}`) end
		if not w or f.st ~= "Running" then break end
		task.wait(0.5)
		s = rv.SellController:SellAll()
		zx(`[Sell] SellAll Answer {tostring(s)}`)
		if s ~= 1 then break end
	end
	local uo, ue = uk(hl)
	if f.st == "Running" and not sw then mv(f, hd and f.hp and f.hi == rv.IslandRegionController:GetCurrentIslandId() and f.hp or o.Position, Vector3.new(o.LookVector.X, 0, o.LookVector.Z).Unit, math.min(sp.Y, 10)) end
	if sw then f.rp = true end
	if f.st ~= "Running" then return nil, nil end
	if not uo then return nil, ue end
	if not w then return nil, we or "Move Failed" end
	if s == 3 then return "Auto Fish Failed: Satchel Full" end
	if s ~= 0 then return nil, `Sell Status {s}` end
	return nil, nil
end

local iz, ix, bn, bi = {}, {}, {}, {}
for _, x in {{"Starter Island", "island_starter"}, {"Jungle Island", "island_jungle"}, {"Desert Island", "island_desert"}, {"Snow Island", "island_snow"}, {"Volcanic Island", "island_volcano"}, {"Fossil Island", "island_fossil"}} do
	table.insert(iz, x[1])
	ix[x[1]] = x[2]
end
for _, x in {{"Truck", "truck"}, {"Red Truck", "red_truck"}} do
	table.insert(bn, x[1])
	bi[x[1]] = x[2]
end

local function ic() return rv.IslandRegionController:GetCurrentIslandId() end

local function rs(id, wd)
	local c, r = lc()
	local w = workspace:FindFirstChild("World")
	local il = w and w:FindFirstChild("Islands")
	local fo = il and il:FindFirstChild(id or ic())
	if not (c and fo) then return nil end
	local ip, o, rd, ct, rr, k = RaycastParams.new(), {}, Random.new(), r.Position, 150, 150
	ip.FilterType, ip.FilterDescendantsInstances = Enum.RaycastFilterType.Include, {il}
	if wd then
		for _, x in game:GetService("CollectionService"):GetTagged("IslandRegion") do
			if x:IsA("BasePart") and x:GetAttribute("islandId") == fo.Name then ct, rr, k = x.Position, x.Size.X / 2, 400 end
		end
	end
	for i = 1, k do
		if i % 50 == 0 then task.wait() end
		local a, d = rd:NextNumber(0, math.pi * 2), rd:NextNumber(10, rr)
		local h = workspace:Raycast(Vector3.new(ct.X + math.sin(a) * d, 150, ct.Z + math.cos(a) * d), Vector3.new(0, -200, 0), ip)
		if h and h.Instance:IsDescendantOf(fo) and h.Position.Y > 3.5 and h.Position.Y < 20 then
			local g = h.Position
			for i = 0, 7 do
				local b = math.rad(i * 45)
				if not workspace:Raycast(Vector3.new(g.X + math.sin(b) * 12, 103, g.Z + math.cos(b) * 12), Vector3.new(0, -100, 0), ip) and tg({Position = g}) then
					table.insert(o, g + Vector3.new(0, 3, 0))
					break
				end
			end
		end
	end
	return #o > 0 and o[rd:NextInteger(1, #o)] or nil
end

local function ul(id)
	local c, d = md("Data", "Config", "IslandConfig")[id], pd()
	return c and c.defaultUnlocked == true or d and d.UnlockedIslands and d.UnlockedIslands[id] == true or false
end

local function rg(id)
	for _, x in game:GetService("CollectionService"):GetTagged("IslandRegion") do
		if x:IsA("BasePart") and x:GetAttribute("islandId") == id then return x.Position end
	end
	return nil
end

local hs = game:GetService("HttpService")

local function vi(p)
	local id = ic()
	if id ~= "" then return id end
	for _, x in game:GetService("CollectionService"):GetTagged("IslandRegion") do
		if x:IsA("BasePart") and (x.Position - p).Magnitude < x.Size.X / 2 then return x:GetAttribute("islandId") end
	end
	return ""
end

local function uh(id)
	local c, r = lc()
	local w = workspace:FindFirstChild("World")
	local il = w and w:FindFirstChild("Islands")
	local fo = il and il:FindFirstChild(id)
	if not (c and fo) then return nil end
	local ct, rr = r.Position, 250
	for _, x in game:GetService("CollectionService"):GetTagged("IslandRegion") do
		if x:IsA("BasePart") and x:GetAttribute("islandId") == id then ct, rr = x.Position, x.Size.X / 2 end
	end
	local ip, o, rd = RaycastParams.new(), {}, Random.new()
	ip.FilterType, ip.FilterDescendantsInstances = Enum.RaycastFilterType.Include, {il}
	for _ = 1, 400 do
		local a, d = rd:NextNumber(0, math.pi * 2), math.sqrt(rd:NextNumber()) * rr
		local h = workspace:Raycast(Vector3.new(ct.X + math.sin(a) * d, 500, ct.Z + math.cos(a) * d), Vector3.new(0, -520, 0), ip)
		if h and h.Instance:IsDescendantOf(fo) and h.Position.Y > 3.5 then table.insert(o, h.Position) end
	end
	table.sort(o, function(a, b) return a.Y > b.Y end)
	for i, g in o do
		if i % 20 == 0 then task.wait() end
		local q = Vector3.new(g.X, -35, g.Z)
		if tg({Position = q}) then return q, g.Y end
	end
	return nil
end

ut = function(p)
	local w = workspace:FindFirstChild("World")
	local il, ip = w and w:FindFirstChild("Islands"), RaycastParams.new()
	if not il then return nil end
	ip.FilterType, ip.FilterDescendantsInstances = Enum.RaycastFilterType.Include, {il}
	local h = workspace:Raycast(Vector3.new(p.X, 500, p.Z), Vector3.new(0, -520, 0), ip)
	return h and h.Position + Vector3.new(0, 3, 0)
end

hv = function(f, p, fk, ty)
	for i = 1, 3 do
		local _, r = lc()
		if not r then return nil, "No Character" end
		local q = i == 1 and Vector3.new(r.Position.X, ty, r.Position.Z) or i == 2 and Vector3.new(p.X, ty, p.Z) or p
		local j, e = mo(q, i == 2 and 30 or 1e6, fk)
		if not j then return nil, e end
		local dl = os.clock() + (q - r.Position).Magnitude / 30 + 5
		repeat task.wait() until j.st == "Arrived" or j.dn or f.st ~= "Running" or os.clock() > dl
		if j.dn then return nil, j.why or "Move Failed" end
		if f.st ~= "Running" then return nil end
		if j.st ~= "Arrived" then return nil, "Move Timeout" end
	end
	return true
end

ap = function(c, np, p, d)
	if d == 0 then return np end
	local u = Vector3.new(p.X, np.Y, p.Z) - np
	return gd(c, np + (u.Magnitude > 0.1 and u.Unit or Vector3.xAxis) * (d or 6))
end

aq = function(c, np, p)
	local w = workspace:FindFirstChild("World")
	local il, ip = w and w:FindFirstChild("Islands"), RaycastParams.new()
	if il then
		ip.FilterType, ip.FilterDescendantsInstances = Enum.RaycastFilterType.Include, {il}
		local u = Vector3.new(p.X - np.X, 0, p.Z - np.Z)
		local a0 = u.Magnitude > 0.1 and math.atan2(u.X, u.Z) or 0
		for i = 0, 15 do
			local a = a0 + math.rad((i % 2 == 0 and 1 or -1) * math.ceil(i / 2) * 22.5)
			local q = np + Vector3.new(math.sin(a), 0, math.cos(a)) * 18
			local h = workspace:Raycast(q + Vector3.new(0, 20, 0), Vector3.new(0, -60, 0), ip)
			if h and math.abs(h.Position.Y + 3 - np.Y) <= 6 then return h.Position + Vector3.new(0, 3, 0) end
		end
	end
	return ap(c, np, p, 0)
end

local function an(f, c, np, p)
	if f.hf() then
		local sp = Vector3.new(np.X, math.max(6, np.Y - 18), np.Z)
		return hv(f, sp, nil, math.min(sp.Y, 10))
	end
	local sp = aq(c, np, p)
	return go(f, sp, Vector3.new(np.X - sp.X, 0, np.Z - sp.Z).Unit)
end

local function bv(k)
	local a = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
	local m = a and a:FindFirstChild("Cars")
	m = m and m:FindFirstChild(k)
	m = m and m:FindFirstChild("Model")
	return m and m:GetAttribute("Speed")
end

local function gb(f, k)
	local c, r = lc()
	local cf = workspace:FindFirstChild("Cars")
	if not c then return nil, "No Character" end
	if not cf then return nil, "No Cars Folder" end
	local nm = tostring(lp.UserId)
	local om = cf:FindFirstChild(nm)
	local ct = md("Data", "Catalog", "Car")
	local function pc() return ct[k] and ct[k].price or 0 end
	local function ok(x) return x and x:FindFirstChild("Main") and x:FindFirstChild("DSeat") and x:GetAttribute("Speed") == bv(k) and ((x.Main.Position - r.Position) * Vector3.new(1, 0, 1)).Magnitude < 500 end
	if ok(om) then return om end
	if pc() > (pd().Coin or 0) then k = "truck" end
	if ok(om) then return om end
	local mp, mx = ns("npc_car_merchant", r.Position)
	if not mp then return nil, "No Boat Merchant" end
	local g, e = go(f, ap(c, mp, r.Position))
	if not g then return nil, e end
	local P = md("Stardust").Packet
	P("SpawnCarEvent", P.String):Fire(`{k}/{mx:GetAttribute("IslandId")}`)
	local dl = os.clock() + 8
	repeat
		task.wait(0.2)
		local x = cf:FindFirstChild(nm)
		if x and x ~= om and x:FindFirstChild("Main") and x:FindFirstChild("DSeat") then return x end
	until os.clock() > dl or f.st ~= "Running"
	return nil, f.st == "Running" and "Boat Spawn Timeout" or nil
end

local function pq(m, v)
	for _, x in m and m:GetDescendants() or {} do
		if x:IsA("ProximityPrompt") then x.Enabled = v end
	end
end

local function sb(f, m)
	local c, r, h = lc()
	if not c then return nil, "No Character" end
	local ds = m:FindFirstChild("DSeat")
	local pp = ds and ds:FindFirstChildWhichIsA("ProximityPrompt", true)
	if not pp then return nil, "No Boat Seat" end
	pq(m, true)
	if ds.Occupant == h then return true end
	local q = (r.Position - ds.Position) * Vector3.new(1, 0, 1)
	local g, e = go(f, Vector3.new(ds.Position.X, r.Position.Y, ds.Position.Z) + (q.Magnitude > 0.1 and q.Unit or Vector3.xAxis) * 3)
	if not g then return nil, e end
	if cj then cj:Stop() end
	local dl, lc2 = os.clock() + 20, false
	repeat
		fireproximityprompt(pp)
		local d1 = os.clock() + 1
		repeat task.wait(0.1) until ds.Occupant == h or os.clock() > d1
		if ds.Occupant ~= h and not lc2 then
			lc2 = true
			rv.FishingController.FishLootConfirm:Fire()
			rv.FishingController.FishCancel:Fire()
		end
	until ds.Occupant == h or os.clock() > dl
	if ds.Occupant ~= h then return nil, "Sit Timeout" end
	return true
end

local function dv(f, m, id, pt)
	local _, _, h = lc()
	local mn, ds = m:FindFirstChild("Main"), m:FindFirstChild("DSeat")
	local ap, ao = mn and mn:FindFirstChild("AlignPosition"), mn and mn:FindFirstChild("AlignOrientation")
	local cp = rg(id)
	if not (h and ds and ap and ao) then return nil, "Bad Boat" end
	if not cp then return nil, "No Island Region" end
	local sp, y, cc, sx = m:GetAttribute("Speed") or 30, ap.Position.Y, {}, {}
	for _, x in {m, lp.Character} do
		for _, p in x:GetDescendants() do
			if p:IsA("BasePart") then cc[p] = p.CanCollide end
			if p:IsA("Seat") or p:IsA("VehicleSeat") then table.insert(sx, p) end
		end
	end
	local w = workspace:FindFirstChild("World")
	local il, rp = w and w:FindFirstChild("Islands"), RaycastParams.new()
	rp.FilterType, rp.FilterDescendantsInstances = Enum.RaycastFilterType.Include, {il}
	local tp, to, er, cn, on, sh = Vector3.new(mn.Position.X, 0, mn.Position.Z), pt and Vector3.new(pt.X, 0, pt.Z) or Vector3.new(cp.X, 0, cp.Z), nil, nil, false, nil
	local hd, hl = (to - tp).Unit, math.max(mn.Size.X, mn.Size.Z) / 2 + 3
	cn = game:GetService("RunService").Stepped:Connect(function(_, dt)
		local ok, e = pcall(function()
			for _, x in sx do
				local c = x.Occupant and x.Occupant.Parent
				if c and c ~= lp.Character then
					for _, p in c:GetDescendants() do
						if p:IsA("BasePart") and cc[p] == nil then cc[p] = p.CanCollide end
					end
				end
			end
			for p in cc do
				if p.CanCollide then p.CanCollide = false end
			end
			local q = to - tp
			if q.Magnitude > 0.05 and not sh then
				hd = q.Unit
				local nx2 = tp + hd * math.min(q.Magnitude, sp * dt)
				local r = not pt and on and il and workspace:Raycast(Vector3.new(nx2.X, 103, nx2.Z) + hd * hl, Vector3.new(0, -100, 0), rp)
				if r then sh = r.Position else tp = nx2 end
			end
			ap.Position, ao.CFrame = Vector3.new(tp.X, y, tp.Z), CFrame.Angles(0, math.atan2(-hd.X, -hd.Z), 0)
		end)
		if not ok then er = `Boat Drive Failed: {e}`; cn:Disconnect() end
	end)
	local lb, lt, dl, dn = math.huge, os.clock(), os.clock() + (to - tp).Magnitude / sp * 1.5 + 30, false
	while f.st == "Running" and not er do
		task.wait(0.25)
		if ds.Occupant ~= h then er = "Left Boat"; break end
		on = ic() == id
		if sh then
			task.wait(0.5)
			dn = true
			break
		end
		if on and not pt then
			local mp, mx = ns("npc_car_merchant", mn.Position)
			local nq = mp and mx:GetAttribute("IslandId") == id and Vector3.new(mp.X, 0, mp.Z)
			if nq and nq ~= to then to, lb = nq, math.huge end
		end
		local d = (Vector3.new(mn.Position.X, 0, mn.Position.Z) - to).Magnitude
		if d < lb - 1 then lb, lt = d, os.clock() end
		if d < (pt and 3 or 15) or on and not pt and os.clock() - lt > 2 then dn = true; break end
		if os.clock() - lt > 4 then er = "Boat Stuck" end
		if os.clock() > dl then er = "Boat Timeout" end
	end
	if cn.Connected then cn:Disconnect() end
	for p, v in cc do pcall(function() p.CanCollide = v end) end
	local dd = os.clock() + 3
	while ds.Occupant == h and os.clock() < dd do
		h.Sit, h.Jump = false, true
		task.wait(0.2)
	end
	local _, r = lc()
	local hj = r and mo(r.Position, 30)
	task.wait(1)
	if er or not dn then
		if hj then hj:Stop() end
		return nil, er
	end
	return true, sh
end

local wb = {on = true}
local zy = {on = false, rq = false, nt = 0, ss = 0, fr = {}, wl = {}, hu = {}, nm = {}, hp = -1e9}
local zj = `Avenoric/Configs/FishingMaster/{lp.Name}_Safe.json`
pcall(function()
	local d = hs:JSONDecode(readfile(zj))
	if type(d) ~= "table" or d.JobId ~= game.JobId then return end
	for k, t in {RealPlayers = zy.wl, HubUsers = zy.hu} do
		for _, x in type(d[k]) == "table" and d[k] or {} do
			if type(x) == "table" and tonumber(x.UserId) then t[tonumber(x.UserId)], zy.nm[tonumber(x.UserId)] = x.Seen or true, x.Name end
		end
	end
end)
local function zf()
	local o = {JobId = game.JobId, RealPlayers = {}, HubUsers = {}}
	for k, t in {RealPlayers = zy.wl, HubUsers = zy.hu} do
		for u in t do
			local p = game:GetService("Players"):GetPlayerByUserId(u)
			zy.nm[u] = p and p.Name or zy.nm[u]
			table.insert(o[k], {Name = zy.nm[u] or "?", UserId = u, Seen = type(t[u]) == "string" and t[u] or nil})
		end
	end
	pcall(function()
		for _, x in {"Avenoric", "Avenoric/Configs", "Avenoric/Configs/FishingMaster"} do
			if not isfolder(x) then makefolder(x) end
		end
		writefile(zj, hs:JSONEncode(o))
	end)
end
local wz = {island_starter = Vector3.new(-37.4, 11.1, 305.9), island_jungle = Vector3.new(-1161.1, 10.8, -61.9), island_desert = Vector3.new(-44.1, 10.1, -935.4), island_snow = Vector3.new(1171.7, 9.4, -266.5), island_volcano = Vector3.new(1772.5, 9.2, 1069.3), island_fossil = Vector3.new(-543.2, 10.6, 2172.3)}

local function wm(id)
	for _, x in game:GetService("CollectionService"):GetTagged("Interactive") do
		if x:GetAttribute("InteractiveId") == "npc_car_merchant" and x:GetAttribute("IslandId") == id then return x:IsA("Model") and x:GetPivot().Position or x:IsA("BasePart") and x.Position or wz[id] end
	end
	return wz[id]
end

local wv
if getgenv and getgenv().__FmW then pcall(getgenv().__FmW.Destroy, getgenv().__FmW) end
pcall(function()
	local pg, lt = lp:WaitForChild("PlayerGui"), rv.LoadingController
	local x = pg:WaitForChild("Loading", 10):Clone()
	local fr = x.Frame
	x.Name, x.Enabled, x.ResetOnSpawn, x.DisplayOrder = hs:GenerateGUID(false), false, false, 1000
	fr.BackgroundTransparency, fr.Background.Gradient.ImageTransparency, fr.Background.Rectangle.BackgroundTransparency, fr.ImageLabel.ImageTransparency = 0, 0, 0, 0
	fr.tips.Position, fr.Bar.Position = lt._originalTipsPos, lt._originalBarPos
	fr.Bar.MasteryText.Text = "Teleporting..."
	x.Parent = pg
	wv = x
end)
if getgenv then getgenv().__FmW = wv end

local wg, wk, wp, wo = 0, nil, 0, {}
local wt = {"Tips: Cast your bobber near ripple spots to catch rare fish!", "Tips: Different rods provide unique luck and strength boosts.", "Tips: Keep an eye on the tension bar to avoid snapping your line!", "Tips: Upgrade your bait at the bait shop to attract bigger fish.", "Tips: Perfect catches grant extra experience and rare materials.", "Tips: Check the weather! Some mythical fish only appear in storms.", "Tips: Visit the fish merchant to convert your catches into Coins & Gems.", "Tips: Explore distant islands once you discover their fast travel points.", "Tips: Rare auras and rod skins can be equipped to show off your style.", "Tips: Complete daily quests for bonus rewards and crates.", "Tips: Fill out your fish Index to track every species you've caught!"}

local function wc(v, ok)
	if not wv then return end
	wg += 1
	local g, fr, ts, lt = wg, wv.Frame, game:GetService("TweenService"), rv.LoadingController
	local b, bg = fr.Bar, fr.Background
	pcall(function()
		if v then
			if wk then wk:Disconnect() end
			for _, x in wo do x:Cancel() end
			fr.BackgroundTransparency, bg.Gradient.ImageTransparency, bg.Rectangle.BackgroundTransparency, fr.ImageLabel.ImageTransparency = 0, 0, 0, 0
			b.Position, fr.tips.Position = UDim2.new(lt._originalBarPos.X.Scale, lt._originalBarPos.X.Offset, 1.25, 0), UDim2.new(lt._originalTipsPos.X.Scale, lt._originalTipsPos.X.Offset, 1.35, 0)
			b.Fill.Size, b.MasteryText.Text, wp, wv.Enabled = UDim2.fromScale(0, 1), "Loading game...", 0, true
			local cp, tp = 0, 0
			wk = game:GetService("RunService").RenderStepped:Connect(function(dt)
				tp = wp
				if tp > cp then cp = math.min(cp + math.max((tp - cp) * math.clamp(dt * 10, 0, 1), 5e-4), tp) end
				local t = os.clock()
				b.Fill.Size, b.Fish.Position, b.Fish.Rotation = UDim2.fromScale(cp, 1), UDim2.new(cp, 0, 0.5, math.sin(t * 10) * 3), math.sin(t * 12) * 10
			end)
			wo = {ts:Create(b.Shine, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {ImageTransparency = 0.25})}
			wo[1]:Play()
			ts:Create(b, TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = lt._originalBarPos}):Play()
			task.delay(0.08, function() ts:Create(fr.tips, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = lt._originalTipsPos}):Play() end)
			local ti3, op = math.random(1, #wt), lt._originalTipsPos
			fr.tips.Text = wt[ti3]
			task.spawn(function()
				while true do
					task.wait(2.5)
					if wg ~= g then return end
					ti3 = ti3 % #wt + 1
					local x = ts:Create(fr.tips, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(op.X.Scale, op.X.Offset, op.Y.Scale - 0.035, op.Y.Offset)})
					x:Play()
					x.Completed:Wait()
					if wg ~= g then return end
					fr.tips.Text, fr.tips.Position = wt[ti3], UDim2.new(op.X.Scale, op.X.Offset, op.Y.Scale + 0.035, op.Y.Offset)
					ts:Create(fr.tips, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = op}):Play()
				end
			end)
			task.spawn(function()
				for k, x in {"Starting up...", "Building interface...", "Loading your data...", "Preparing gameplay..."} do
					task.wait(1)
					if wg ~= g then return end
					wp, b.MasteryText.Text = k * 0.22, x
				end
			end)
			return
		end
		if ok then wp = 1 end
		b.MasteryText.Text = ok and "Ready!" or "Teleport Failed"
		task.spawn(function()
			task.wait(ok and 0.4 or 1)
			if wg ~= g then return end
			ts:Create(fr.tips, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(lt._originalTipsPos.X.Scale, lt._originalTipsPos.X.Offset, 1.35, 0)}):Play()
			task.delay(0.06, function() ts:Create(b, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(lt._originalBarPos.X.Scale, lt._originalBarPos.X.Offset, 1.25, 0)}):Play() end)
			local q = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			ts:Create(bg.Gradient, q, {ImageTransparency = 1}):Play()
			ts:Create(bg.Rectangle, q, {BackgroundTransparency = 1}):Play()
			ts:Create(fr.ImageLabel, q, {ImageTransparency = 1}):Play()
			ts:Create(fr, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
			task.wait(1.5)
			if wg ~= g then return end
			if wk then wk:Disconnect() end
			for _, x in wo do x:Cancel() end
			wv.Enabled = false
		end)
	end)
end

local function wy(f, id, mp, h, o)
	if cj then cj:Stop() end
	local r = h.Parent and h.Parent:FindFirstChild("HumanoidRootPart")
	if not r then return nil, "Warp Failed: No Character" end
	local sp, cf, ok = md("Shared", "Lib", "SpawnPointDialogue"), CFrame.new(r.Position + Vector3.new(0, 1000, 0)), false
	o.hb = game:GetService("RunService").Heartbeat:Connect(function()
		if r.Parent then r.AssemblyLinearVelocity, r.CFrame = Vector3.zero, cf end
	end)
	task.wait(0.3)
	cf = CFrame.new(mp.X, 1000, mp.Z)
	task.wait(0.6)
	cf = CFrame.new(mp + Vector3.new(4, 3, 0))
	task.wait(0.2)
	local dl = os.clock() + 4.5
	while not ok and os.clock() < dl and f.st == "Running" do
		local b, dn = {}, false
		task.spawn(function() sp.CreateAction(true, b, b).on_select(function(x) ok, dn = x == true, true end) end)
		local d2 = os.clock() + 3
		repeat task.wait() until dn or os.clock() > d2
		if not ok then task.wait(0.1) end
	end
	if ok then
		local d3 = os.clock() + 3
		repeat task.wait() until (pd() or {}).SpawnIsland == id or os.clock() > d3 or f.st ~= "Running"
	end
	o.hb:Disconnect()
	if f.st ~= "Running" then return nil end
	if not ok then return nil, "Warp Failed: Spawn Not Set" end
	if (pd() or {}).SpawnIsland ~= id then return nil, "Warp Failed: Spawn Island Unchanged" end
	local bc, tk, d4 = md("Controllers", "BackpackController"), false, os.clock() + 10
	while f.st == "Running" and os.clock() < d4 do
		local s, v = pcall(function() return bc.TeleportToSpawn:Fire() end)
		tk = s and v == true
		if tk then break end
		task.wait(0.5)
	end
	if f.st ~= "Running" then return nil end
	if not tk then return nil, "Warp Failed: Respawn Refused" end
	dl = os.clock() + 8
	repeat task.wait(0.2) until ic() == id and lc() or os.clock() > dl
	if ic() ~= id then return nil, "Warp Failed: Not On Island" end
	return true
end

local function wx(f, id)
	if not (wb.on and ul(id)) then return nil end
	local mp = wm(id)
	if not mp then return nil, "Warp Failed: No Boat Merchant" end
	local ok, e = nil, nil
	wc(true)
	while f.st == "Running" do
		local dl, h = os.clock() + 8, nil
		repeat
			local _, _, x = lc()
			h = x
			if not h then task.wait(0.2) end
		until h or os.clock() > dl or f.st ~= "Running"
		if not h then continue end
		local o: {hb: RBXScriptConnection?} = {}
		local s
		s, ok, e = pcall(wy, f, id, mp, h, o)
		if o.hb then o.hb:Disconnect() end
		if not s then ok, e = nil, `Warp Failed: {ok}` end
		if ok or f.st ~= "Running" then break end
		zx(`[Warp] {id}: {e or "Warp Failed"}, Retrying`)
		task.wait(1)
	end
	wc(false, ok)
	zx(`[Warp] {id}: {ok and "Arrived" or e or "Stopped"}`)
	return ok, e
end

local function ti(f, id, k)
	if ic() == id then return true end
	local w, we = wx(f, id)
	if w or f.st ~= "Running" then return w end
	if we then f.nq = {Title = "Teleport", Text = `{we}, Sailing`} end
	local m, e = gb(f, k)
	if not m then return nil, e end
	local g
	g, e = sb(f, m)
	if not g then return nil, e end
	g, e = dv(f, m, id)
	if not g then return nil, e end
	local c, r = lc()
	if not c then return nil, "No Character" end
	local mp, mx = ns("npc_car_merchant", r.Position)
	local cp = mp and mx:GetAttribute("IslandId") == id and mp or e and e + ((e - r.Position) * Vector3.new(1, 0, 1)).Unit * 12 or rg(id)
	g, e = go(f, ap(c, cp, r.Position))
	if not g then return nil, e end
	task.wait(0.5)
	if ic() ~= id then return nil, "Not On Island" end
	return true
end

local function zm(p, wi)
	if zy.wl[p.UserId] then return true end
	local hm = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	local an = hm and hm:FindFirstChildOfClass("Animator")
	for _, t in an and an:GetPlayingAnimationTracks() or {} do
		if t.WeightCurrent > 0.05 and t.Animation and wi[t.Animation.AnimationId] then
			zy.wl[p.UserId] = wi[t.Animation.AnimationId]
			zf()
			return true
		end
	end
	return false
end

local function zg(p)
	if zy.hu[p.UserId] then return true end
	local hm = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	local an = hm and hm:FindFirstChildOfClass("Animator")
	for _, t in an and an:GetPlayingAnimationTracks() or {} do
		if t.Animation and t.Animation.AnimationId:match("%d+$") == "180435571" and math.abs(t.Speed - 0.37) < 0.01 and t.WeightTarget < 0.05 then
			zy.hu[p.UserId] = true
			zf()
			return true
		end
	end
	return false
end

local function zq(p)
	local hm = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	local an = hm and hm:FindFirstChildOfClass("Animator")
	for _, t in an and an:GetPlayingAnimationTracks() or {} do
		if t.Animation and t.Animation.AnimationId:match("%d+$") == "180435571" and math.abs(t.Speed - 0.41) < 0.01 and t.WeightTarget < 0.05 then return true end
	end
	return false
end

local function zw()
	local c, r = lc()
	local id = r and vi(r.Position) or ""
	local am = c and c:FindFirstChild("Animate")
	if not am then return false end
	local g = id ~= "" and os.clock() >= zy.ss and rg(id)
	if g then
		zy.ss = os.clock() + 10
		task.spawn(sq, Vector3.new(g.X, 2, g.Z), 5)
	end
	local wi, nr, cs = {}, false, game:GetService("CollectionService")
	for _, n in {"walk", "run", "jump"} do
		for _, x in am:FindFirstChild(n) and am[n]:GetChildren() or {} do
			if x:IsA("Animation") then wi[x.AnimationId] = n == "jump" and "Jump" or "Walk" end
		end
	end
	for _, p in game:GetService("Players"):GetPlayers() do
		local h = p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if h then
			if zy.fr[p.UserId] == nil then
				local ok, v = pcall(lp.IsFriendsWith, lp, p.UserId)
				zy.fr[p.UserId] = ok and v == true
			end
			for _, x in zy.fr[p.UserId] == false and not zg(p) and zm(p, wi) and id ~= "" and cs:GetTagged("IslandRegion") or {} do
				if x:IsA("BasePart") and x:GetAttribute("islandId") == id and (x.Position - h.Position).Magnitude < x.Size.X / 2 then nr, zy.by = true, {p.Name, p.UserId, id, zy.wl[p.UserId]} end
			end
		end
	end
	return nr
end

local function zh()
	zy.nt = os.clock() + 30
	local b = zy.by or {}
	zx(`[Safe] Hop From {game.JobId:sub(1, 8)} | Real Player {b[1] or "?"} ({b[2] or "?"}) | Seen {b[4] == "Jump" and "Jumping" or "Walking"} | {b[3] or "?"} | {#game:GetService("Players"):GetPlayers()} Players`, true)
	local ok, r = pcall(function() return hs:JSONDecode((game :: any):HttpGet(`https://games.roblox.com/v1/games/{game.PlaceId}/servers/Public?sortOrder=Asc&limit=100`)) end)
	if not ok or type(r) ~= "table" or type(r.data) ~= "table" then return nil, "Hop Failed: Server List" end
	local o = {}
	for _, s in r.data do
		if type(s) == "table" and type(s.id) == "string" and s.id ~= game.JobId and tonumber(s.playing) and tonumber(s.maxPlayers) and s.playing < s.maxPlayers then table.insert(o, s.id) end
	end
	if #o == 0 then return nil, "Hop Failed: No Server" end
	local tp = game:GetService("TeleportService")
	local ds = o[math.random(1, math.min(5, #o))]
	zy.hp = os.clock()
	zx(`[Safe] Teleporting To {ds:sub(1, 8)}`, true)
	local tk, e = pcall(tp.TeleportToPlaceInstance, tp, game.PlaceId, ds, lp)
	if not tk then return nil, `Hop Failed: {e}` end
	task.wait(15)
	return nil, "Hop Failed: Teleport Timeout"
end

local function sa()
	local cs, n = game:GetService("CollectionService"), 0
	for _, x in cs:GetTagged("IslandRegion") do
		if x:IsA("BasePart") then sq(Vector3.new(x.Position.X, 2, x.Position.Z), 10) end
	end
	for _, x in cs:GetTagged("BossRegion") do
		if x:IsA("BasePart") then n += 1 end
	end
	return n
end

local function br(f)
	local ev = rv.EventController and rv.EventController._active_events
	if type(ev) ~= "table" or next(ev) == nil then
		f.bx = nil
		return nil
	end
	local function fd()
		local n = 0
		for _, x in game:GetService("CollectionService"):GetTagged("BossRegion") do
			local fx = x:IsA("BasePart") and x:FindFirstChild("BossSpawnerFX")
			n += 1
			if fx and fx:GetAttribute("BossSpawnerFXActive") == true and x ~= f.bx then return x, n end
		end
		return nil, n
	end
	local x, n = fd()
	if x or n >= 12 or os.clock() < (f.sc or 0) then return x end
	f.sc = os.clock() + 20
	sa()
	return (fd())
end

local function zd(m)
	local mn = m and m:FindFirstChild("Main")
	if not mn then return nil end
	local cf, sz, rp, st, pt, bn = mn.CFrame, mn.Size, RaycastParams.new(), {}, {}, {}
	rp.FilterType, rp.FilterDescendantsInstances = Enum.RaycastFilterType.Include, {m}
	for _, x in m:GetDescendants() do
		if x:IsA("Seat") or x:IsA("VehicleSeat") then table.insert(st, x) end
	end
	for z = 0, sz.Z / 2, 0.5 do
		for x = -sz.X / 2, sz.X / 2, 0.5 do
			local o = cf:PointToWorldSpace(Vector3.new(x, 0, z))
			local h = workspace:Raycast(Vector3.new(o.X, cf.Position.Y + 20, o.Z), Vector3.new(0, -40, 0), rp)
			if h and h.Instance.CanCollide and h.Normal.Y > 0.95 then
				local k = math.floor(h.Position.Y * 2 + 0.5)
				bn[k] = (bn[k] or 0) + 1
				table.insert(pt, {h.Position, k})
			end
		end
	end
	local fk, fn = nil, 0
	for k, n in bn do
		if n > fn then fk, fn = k, n end
	end
	local c, b, bd = cf:PointToWorldSpace(Vector3.new(0, 0, sz.Z / 4)), nil, math.huge
	for _, v in pt do
		if math.abs(v[2] - fk) <= 1 then
			local fr = true
			for _, q in st do
				local l = q.CFrame:PointToObjectSpace(v[1])
				if math.abs(l.X) < q.Size.X / 2 + 0.75 and math.abs(l.Z) < q.Size.Z / 2 + 0.75 then fr = false; break end
			end
			local d = ((v[1] - c) * Vector3.new(1, 0, 1)).Magnitude
			if fr and d < bd then b, bd = v[1], d end
		end
	end
	return b
end

local function oz(m)
	local _, r, h = lc()
	if not (r and m and m.Parent) or h.SeatPart or rv.Swimming and rv.Swimming:IsSwimming() then return false end
	local rp = RaycastParams.new()
	rp.FilterType, rp.FilterDescendantsInstances = Enum.RaycastFilterType.Include, {m}
	return workspace:Raycast(r.Position, Vector3.new(0, -6, 0), rp) ~= nil
end

local function sd(f, m)
	local p = zd(m)
	if not p then return false end
	local g = gf(f, p + Vector3.new(0, 3, 0))
	if not g or f.st ~= "Running" then return false end
	if not mo(p + Vector3.new(0, 3, 0), 30) then return false end
	task.wait(1)
	return oz(m)
end

local function bw(f)
	local _, r = lc()
	if not r then return nil, "No Character" end
	local id = ic()
	local np = ns("npc_fish_seller", r.Position)
	if not np and rg(id) then
		sq(Vector3.new(rg(id).X, 2, rg(id).Z), 10)
		np = ns("npc_fish_seller", r.Position)
	end
	if not np then return nil, "No Fish Seller" end
	local w = workspace:FindFirstChild("World")
	local il, ip = w and w:FindFirstChild("Islands"), RaycastParams.new()
	ip.FilterType, ip.FilterDescendantsInstances = Enum.RaycastFilterType.Include, {il}
	local d = (r.Position - np) * Vector3.new(1, 0, 1)
	local u, pt = d.Magnitude > 1 and d.Unit or Vector3.xAxis, nil
	for k = 10, math.max(300, d.Magnitude), 5 do
		local q = np + u * k
		if not workspace:Raycast(Vector3.new(q.X, 103, q.Z), Vector3.new(0, -100, 0), ip) then
			pt = q
			break
		end
	end
	if not pt then return nil, "No Water Near Fish Seller" end
	local m, e = gb(f, f.bk())
	if not m then return nil, e end
	local ok
	ok, e = sb(f, m)
	if not ok then return nil, e end
	ok, e = dv(f, m, id, pt)
	if ok then sd(f, m) end
	return ok, e
end

local function hz(f, y)
	local _, r = lc()
	if not r then return nil, "No Character" end
	local function sw() return rv.Swimming and rv.Swimming:IsSwimming() end
	if cj and not cj.dn and not sw() and r.Position.Y > y - 2 then return true end
	local j, e = mo(Vector3.new(r.Position.X, y, r.Position.Z), 30)
	if not j then return nil, e end
	local dl = os.clock() + 4
	repeat task.wait(0.1) until j.st == "Arrived" and not sw() or j.dn or f.st ~= "Running" or os.clock() > dl
	if j.dn then return nil, j.why or "Hover Failed" end
	if f.st ~= "Running" then return nil end
	if sw() then return nil, "Hover Failed: Still Swimming" end
	return true
end

local function bo(f)
	local ev = rv.EventController and rv.EventController._active_events
	if type(ev) ~= "table" or next(ev) == nil then f.s.bc = false end
	if f.s.bc or (tonumber(pd().LastBossKillSlot) or 0) >= workspace:GetServerTimeNow() // 2400 * 2400 then return nil end
	if os.clock() < (f.bl or 0) then return nil end
	local x = br(f)
	if not x then return nil end
	local id, q = x.Parent and x.Parent.Parent and x.Parent.Parent.Name, Vector3.new(x.Position.X, 3, x.Position.Z)
	local _, r, h = lc()
	if not r then return nil, "No Character" end
	f.br = x
	local sw = rv.Swimming and rv.Swimming:IsSwimming()
	local cm = workspace:FindFirstChild("Cars")
	cm = cm and cm:FindFirstChild(tostring(lp.UserId))
	local cn = cm and cm:FindFirstChild("Main") and ((cm.Main.Position - q) * Vector3.new(1, 0, 1)).Magnitude <= 50
	if (((r.Position - q) * Vector3.new(1, 0, 1)).Magnitude <= 45 or cn and oz(cm)) and not h.SeatPart then
		if cn and (oz(cm) and cj and not cj.dn or sd(f, cm)) then
			f.bm = cm
			pq(cm, false)
			return q
		end
		if f.st ~= "Running" then return nil end
		local ok, e = hz(f, q.Y + 9)
		if not ok then return nil, e end
		return q
	end
	if not (f.hm or f.bb or sw or h.SeatPart) and ic() ~= "" and f.ao() and zb(f.sr(), f.kp()) > 0 then
		local hd, sf = tr(f)
		zx(`[Boss] Sell Before Boss: {hd or sf or "Done"}`)
		if f.st ~= "Running" then return nil end
		_, r, h = lc()
		if not r then return nil, "No Character" end
	end
	if not (f.hm or f.bb or sw or h.SeatPart) and ic() ~= "" then f.hm = {r.CFrame, ic()} end
	if f.bg ~= x then
		f.bg = x
		zx(`[Boss] Going To {x.Name} On {id or "?"}`)
	end
	if id and ic() ~= id and wx(f, id) then
		_, r, h = lc()
		if not r then return nil, "No Character" end
	end
	if f.st ~= "Running" then return nil end
	local d = (r.Position - q) * Vector3.new(1, 0, 1)
	local m, e = gb(f, f.bk())
	if not m then return nil, e end
	local ok
	ok, e = sb(f, m)
	if not ok then return nil, e end
	local w, cs = workspace:FindFirstChild("World"), workspace:FindFirstChild("Cars")
	local il, ip, a0, pt = w and w:FindFirstChild("Islands"), RaycastParams.new(), math.floor(lp.UserId * 0.6180339887 % 1 * 8), nil
	ip.FilterType, ip.FilterDescendantsInstances = Enum.RaycastFilterType.Include, {il}
	for i = 0, 7 do
		local p, fr = q + Vector3.new(math.sin((a0 + i) * math.pi / 4), 0, math.cos((a0 + i) * math.pi / 4)) * 40, true
		for _, x in cs and cs:GetChildren() or {} do
			local mn = x.Name ~= tostring(lp.UserId) and x:FindFirstChild("Main")
			if mn and ((mn.Position - p) * Vector3.new(1, 0, 1)).Magnitude < 28 then fr = false; break end
		end
		if fr and (not il or not workspace:Raycast(p + Vector3.new(0, 100, 0), Vector3.new(0, -100, 0), ip)) then pt = p; break end
	end
	ok, e = dv(f, m, id, pt or q + (d.Magnitude > 1 and d.Unit or Vector3.xAxis) * 40)
	if not ok then return nil, e end
	f.bb = true
	if sd(f, m) then
		f.bm = m
		pq(m, false)
		return q
	end
	if f.st ~= "Running" then return nil end
	ok, e = hz(f, q.Y + 9)
	if not ok then return nil, e end
	return q
end

local qd = {
	{"unlock_island_2", "island_starter", "island_jungle", "Jungle Island", {RequiredCoin = 40000}},
	{"unlock_island_3", "island_jungle", "island_desert", "Desert Island", {RequiredCoin = 180000}},
	{"unlock_island_4", "island_desert", "island_snow", "Snow Island", {RequiredCoin = 900000, RequiredFish = 3}, {"Legendary", "island_desert"}},
	{"unlock_island_5", "island_snow", "island_volcano", "Volcanic Island", {RequiredCoin = 4000000, RequiredFishes = {frozen_crown_dragonfish = 1, frosttusk_seal = 1, frostmaw_monster = 1}}},
	{"unlock_island_6", "island_volcano", "island_fossil", "Fossil Island", {RequiredCoin = 15000000, RequiredFishes = {ancient_trihorn_fish = 1, stormblade_shark = 1, lavascale_dragonfish = 1}}},
}

local qt, qz, qm = {
	{"crimson_bead_rod", "island_volcano", "island_volcano", "Crimson Bead Rod", {RequiredFished = 0}, nil, "legacy_rod"},
	{"bamboo_rod", "island_volcano", "island_volcano", "Bamboo Rod", {RequiredBamboo = 0}, nil, "crimson_bead_rod", "island_jungle"},
	{"heaven_piercer_turtle_rod", "island_fossil", "island_fossil", "Heaven Piercer Turtle Rod", {RequiredFish = 0}, {"Legendary", "island_fossil"}, nil, "island_fossil"},
	{"zen_staff_rod", "island_fossil", "island_fossil", "Zen Staff Rod", {RequiredFish = 0}, nil, nil, "island_fossil"},
	{"dread_fish_rod", "island_fossil", "island_fossil", "Dread Fish Rod", {RequiredFish = 0}, {"Mythical", "island_fossil"}, nil, "island_fossil"},
	{"taiji_hooking_art_v2", "island_snow", "island_snow", "Taiji Hooking Art V2 Upgrade", {RequiredKills = 0}},
}, {}, {}
for _, q in qt do
	table.insert(qz, q[4])
	qm[q[4]] = q
end

local qg, qgz = {
	{"white_tiger", "island_desert", "island_desert", "White Tiger Soul", {RequiredFish = 3}, {"Legendary", "island_desert", 1000}, nil, "island_desert", true},
	{"phoenix", "island_snow", "island_snow", "Phoenix Soul", {RequiredFish = 3}, {"Legendary", "island_snow"}, nil, "island_snow", true},
	{"azure_dragon", "island_volcano", "island_volcano", "Azure Dragon Soul", {RequiredFish = 0, CatchWithSkill = 0}, {"Legendary", "island_volcano"}, nil, "island_volcano", true},
	{"supreme_king", "island_fossil", "island_fossil", "Supreme King Soul", {CatchWithSkill = 0, RequiredBooks = {}}, nil, nil, "island_fossil", true},
}, {}
for _, q in qg do table.insert(qgz, q[4]) end

local function qc(q, d, pr)
	local ct, n, ks, df, id, rr = md("Data", "Catalog"), {}, {}, {}, q[1], q[6]
	local wk = id == "unlock_island_6" and md("Data", "Config", "QuestConfig").UnlockIsland6MinWeightKg or {}
	if rr then
		for _, x in (ct.Island.GetById(rr[2]) or {}).fishes or {} do df[x.fishId] = true end
	end
	local rf = rr and {["*"] = pr.RequiredFish or 1} or pr.RequiredFishes or {}
	for u, x in d.Inventory and d.Inventory.Fishes or {} do
		local fi = ct.Fish.GetById(x.fishId)
		local k = rr and fi and fi.rarity == rr[1] and df[x.fishId] and (x.weight or 0) >= (rr[3] or 0) and "*" or not rr and rf[x.fishId] and (id ~= "unlock_island_6" or wk[x.fishId] and (x.weight or 0) >= wk[x.fishId]) and x.fishId
		if k and (n[k] or 0) < rf[k] then n[k], ks[u] = (n[k] or 0) + 1, true end
	end
	local ok = (d.Coin or 0) >= (pr.RequiredCoin or 0)
	for k, v in rf do
		if (n[k] or 0) < v then ok = false end
	end
	if id == "crimson_bead_rod" and (pr.CurrentFished or 0) < (pr.RequiredFished or 1) then ok = false end
	if id == "zen_staff_rod" and (pr.CurrentFish or 0) < (pr.RequiredFish or 1) then ok = false end
	if id == "bamboo_rod" and md("Shared", "getItemCount")(d, "bamboo_fragment") < (pr.RequiredBamboo or 1) then ok = false end
	if id == "taiji_hooking_art_v2" and ((pr.CurrentKills or 0) < (pr.RequiredKills or 1) or (((d.Inventory or {}).Books or {}).taiji_hooking_art or 0) < (pr.RequiredBookCount or 1)) then ok = false end
	if (id == "azure_dragon" or id == "supreme_king") and (pr.CurrentUsedSkill or 0) < (pr.CatchWithSkill or (id == "azure_dragon" and 100 or 5)) then ok = false end
	if id == "phoenix" or id == "supreme_king" then
		local ba = md("Utils", "skillBookAvailability")
		for b, v in id == "phoenix" and md("Data", "Config", "QuestConfig").PhoenixRequiredBooks or pr.RequiredBooks or {rod_gate_20_percent = 1} do
			if ba.GetCounts(d, b).available < v then ok = false end
		end
	end
	return ok, ks
end

local function qn(f)
	for _, q in qd do
		if not ul(q[3]) then return ul(q[2]) and not f.qx[q[1]] and q or nil end
	end
	return nil
end

local function qw(f, k, t, h)
	if f.qw[k] then return end
	f.qw[k], f.nq = true, {Title = h or "Rod Quest", Text = t}
end

local function qp(f)
	local q, d = f.qs(), pd()
	if not q or f.qx[q[1]] then return nil end
	if d.Quest and d.Quest.Done and d.Quest.Done[q[1]] then
		f.qx[q[1]], f.nq = true, {Title = "Rod Quest", Text = `{q[4]} Already Done`}
		return nil
	end
	if not ul(q[2]) then return qw(f, `i{q[1]}`, `Rod Quest Waiting: Island Locked`) end
	if q[7] and not (d.Rods and d.Rods[q[7]]) then return qw(f, `r{q[1]}`, `Rod Quest Waiting: No {q[7] == "legacy_rod" and "Legacy Rod" or "Crimson Bead Rod"}`) end
	if q[1] == "taiji_hooking_art_v2" and (((d.Inventory or {}).Books or {}).taiji_hooking_art or 0) < 1 then return qw(f, `b{q[1]}`, "Rod Quest Waiting: No Taiji Hooking Art Book") end
	return q
end

local function qk(d, ys)
	local r, dn, so = {}, (d.Quest or {}).Done or {}, (d.Inventory or {}).Souls or {}
	for _, q in qg do
		if table.find(ys or {}, q[4]) and not dn[q[1]] and so[q[1]] ~= true then table.insert(r, q) end
	end
	return r
end

local function qy(f)
	local d = pd()
	local cq = (d.Quest or {}).Current or {}
	local ls, hb = qk(d, f.ys()), {}
	for _, x in ((d.Rods or {})[d.RodEquip] or {}).BookSlots or {} do hb[x] = true end
	for i, q in ls do
		if q[1] == cq.Id then table.insert(ls, 1, table.remove(ls, i)); break end
	end
	for _, q in ls do
		local id, pr = q[1], cq.Id == q[1] and cq.Progress or {}
		local fb = (pr.CurrentUsedSkill or 0) < (pr.CatchWithSkill or (id == "azure_dragon" and 100 or 5))
		local ba, mb = md("Utils", "skillBookAvailability"), {}
		for b, v in id == "phoenix" and md("Data", "Config", "QuestConfig").PhoenixRequiredBooks or id == "supreme_king" and not fb and (pr.RequiredBooks or {rod_gate_20_percent = 1}) or {} do
			if ba.GetCounts(d, b).available < v then table.insert(mb, (md("Data", "Catalog").Skill.GetById(b) or {}).name or b) end
		end
		table.sort(mb)
		if f.qx[id] then
			continue
		elseif not ul(q[2]) then
			qw(f, `yi{id}`, `Soul Quest Waiting: {q[4]} Island Locked`, "Soul Quest")
		elseif #mb > 0 then
			qw(f, `yb{id}`, `Soul Quest Waiting: {q[4]} Needs Unequipped {table.concat(mb, ", ")}`, "Soul Quest")
		elseif fb and (id == "azure_dragon" or id == "supreme_king") and not hb[id == "azure_dragon" and "one_hook_supreme" or "rod_gate_20_percent"] then
			qw(f, `ye{id}`, `Soul Quest Waiting: Equip {id == "azure_dragon" and "One Hook Supreme" or "Rod Gate 20%"}`, "Soul Quest")
		else
			return q
		end
	end
	return nil
end

local function qv(q)
	local d = pd()
	if not q then return {} end
	local cq = d.Quest and d.Quest.Current
	local _, ks = qc(q, d, cq and cq.Id == q[1] and cq.Progress or q[5])
	return ks
end

local function gn(q)
	local id, g = `npc_{q[1]}`, rg(q[3])
	local p = ns(id, Vector3.zero)
	if not p and g then
		sq(Vector3.new(g.X, 2, g.Z), 10)
		p = ns(id, Vector3.zero)
	end
	return p
end

local function ub()
	local d, n = pd(), 0
	for _, r in d.Rods or {} do
		for _, id in r.BookSlots or {} do
			if id == "taiji_hooking_art" then n += 1 end
		end
	end
	if (((d.Inventory or {}).Books or {}).taiji_hooking_art or 0) - n >= 1 then return true end
	local re = d.Rods and d.Rods[d.RodEquip]
	for s, id in re and re.BookSlots or {} do
		if id == "taiji_hooking_art" then
			local i = tonumber(tostring(s):match("%d+"))
			local x = i and rv.EquipmentsController.EquipMoveset:Fire("", i)
			if x ~= "Success" then return nil, `Unequip Book Failed: {x or "No Response"}` end
			local dl = os.clock() + 3
			repeat task.wait(0.2) until (((pd().Rods or {})[d.RodEquip] or {}).BookSlots or {})[s] ~= "taiji_hooking_art" or os.clock() > dl
			return true, nil, i
		end
	end
	return nil, "Unequip Book Failed: Book On Another Rod"
end

local function ug(f, q, ac)
	local ok, e = ti(f, q[3], f.bk())
	if not ok then return nil, e or f.st == "Running" and "Move Failed" or nil end
	local c, rt = lc()
	if not rt then return nil, "No Character" end
	local np = gn(q)
	if not np then return nil, "No Island Guide" end
	ok, e = an(f, c, np, rt.Position)
	if not ok then return nil, e or f.st == "Running" and "Move Failed" or nil end
	if f.st ~= "Running" then return nil end
	local qr, iu = rv.QuestController, q[1]:find("^unlock_island_") ~= nil
	local tt, px = iu and "Island Guide" or q[9] and "Soul Quest" or "Rod Quest", iu and "Unlock Island Failed" or q[9] and "Soul Quest Failed" or "Rod Quest Failed"
	local function vb() return ((pd().Inventory or {}).Books or {}).taiji_hooking_art_v2 or 0 end
	local v0 = vb()
	local function dn() return ((pd().Quest or {}).Done or {})[q[1]] == true or q[1] == "taiji_hooking_art_v2" and vb() > v0 or q[9] and ((pd().Inventory or {}).Souls or {})[q[1]] == true end
	if not ac then
		local a, m = qr:Accept(q[1])
		zx(`[Quest] Accept {q[1]}: {tostring(a)} {m or ""}`)
		if a ~= true then
			f.qx[q[1]], f.nq = true, {Title = tt, Text = `{px}: {m or "Accept Refused"}`}
			return true
		end
		local dl = os.clock() + 3
		repeat task.wait(0.2) until (pd().Quest or {}).Current and pd().Quest.Current.Id == q[1] or os.clock() > dl
		local cq = (pd().Quest or {}).Current
		if not (cq and cq.Id == q[1]) then return nil, "Quest Not Saved" end
		if not qc(q, pd(), cq.Progress or {}) then
			f.nq = {Title = tt, Text = `{q[4]} Quest Accepted, Requirements Not Met`}
			return true
		end
	end
	local cq = (pd().Quest or {}).Current
	local _, ks = qc(q, pd(), cq and cq.Id == q[1] and cq.Progress or q[5])
	for u in ks do
		local x = pd().Inventory.Fishes[u]
		if x and x.locked == true then
			local s, v = rv.SellController:ToggleLock(u)
			if s ~= 0 or v ~= false then
				f.qx[q[1]], f.nq = true, {Title = tt, Text = `{px}: Unlock Fish Failed`}
				return true
			end
		end
	end
	local bi2
	if q[1] == "taiji_hooking_art_v2" then
		local bo2, be2
		bo2, be2, bi2 = ub()
		if not bo2 then
			f.qx[q[1]], f.nq = true, {Title = tt, Text = `{px}: {be2}`}
			return true
		end
	end
	local cp, m = qr:Complete(q[1])
	zx(`[Quest] Complete {q[1]}: {tostring(cp)} {m or ""}`)
	if cp ~= true then
		f.qx[q[1]], f.nq = true, {Title = tt, Text = `{px}: {m or "Complete Refused"}`}
		return true
	end
	local dl = os.clock() + 5
	repeat task.wait(0.2) until dn() or os.clock() > dl
	if not dn() then
		f.qx[q[1]], f.nq = true, {Title = tt, Text = `{px}: Not Completed`}
		return true
	end
	if q[1] == "taiji_hooking_art_v2" then
		f.qx[q[1]] = true
		local d2 = pd()
		for sl, x in ((d2.Rods or {})[d2.RodEquip] or {}).BookSlots or {} do
			if not bi2 and x == "taiji_hooking_art" then bi2 = tonumber(tostring(sl):match("%d+")) end
		end
		local x = bi2 and rv.EquipmentsController.EquipMoveset:Fire("taiji_hooking_art_v2", bi2)
		if bi2 and x ~= "Success" then
			f.nq = {Title = tt, Text = `Got {q[4]}, Equip V2 Failed: {x or "No Response"}`}
			return true
		end
	end
	if q[9] and ({human = true, [""] = true})[pd().SoulEquip or ""] then
		local eo = rv.EquipmentsController.EquipmentEquip:Fire("soul", q[1])
		f.nq = {Title = tt, Text = eo == true and `Got {q[4]}, Equipped` or `Got {q[4]}, Equip Soul Failed`}
		return true
	end
	f.nq = {Title = tt, Text = `{iu and "Unlocked" or "Got"} {q[4]}`}
	return true
end

local function uq(f, q)
	if not q then return nil end
	local d = pd()
	local cq = d.Quest and d.Quest.Current
	local ci = cq and cq.Id or ""
	if ci ~= "" and ci ~= q[1] then return nil end
	if not qc(q, d, ci == q[1] and cq.Progress or q[5]) then return nil end
	local _, rt = lc()
	if not rt then return nil, "No Character" end
	local o, oi = rt.CFrame, ic()
	local ok, e = ug(f, q, ci == q[1])
	local hk, he = true, nil
	if f.st == "Running" and oi ~= "" and ic() ~= oi then hk, he = ti(f, oi, f.bk()) end
	if hk and f.st == "Running" and ic() == oi and not f.hf() then hk, he = go(f, o.Position, Vector3.new(o.LookVector.X, 0, o.LookVector.Z).Unit) end
	f.rp = f.rp or not hk
	return true, not ok and e or not hk and f.st == "Running" and (he or "Return Failed") or nil
end

local function dy(f)
	local d, du = pd(), md("Shared", "Lib", "DailyQuestUtil")
	local dq = d.DailyQuest
	if type(dq) ~= "table" or type(dq.Active) ~= "table" then return nil end
	local a = dq.Active
	if a.Template ~= "" then
		if not du.IsSkillGachaQuest(a) or f.qw.dp then return nil end
		local sc = rv.SkillGachaController
		local q = sc.GetQuote:Fire(1)
		if type(q) ~= "table" or not q.ok then return nil, `Daily Quest Pull Failed: {type(q) == "table" and q.reason or "No Quote"}` end
		if (d.Coin or 0) < q.coin_cost then
			if not f.qw.dc then f.qw.dc, f.nq = true, {Title = "Daily Quest", Text = "Daily Quest Waiting: Not Enough Coin"} end
			return nil
		end
		f.qw.dc = nil
		sc._requestId = (tonumber(sc._requestId) or 0) + 1
		local r, p0 = sc.Pull:Fire("Coin", 1, sc._requestId), a.Progress or 0
		if type(r) ~= "table" or not r.ok then return nil, `Daily Quest Pull Failed: {type(r) == "table" and r.reason or "No Response"}` end
		local function mv()
			local x = pd().DailyQuest.Active
			return x.Template == "" or (x.Progress or 0) > p0
		end
		local dl = os.clock() + 5
		repeat task.wait(0.2) until mv() or os.clock() > dl
		if not mv() then f.qw.dp, f.nq = true, {Title = "Daily Quest", Text = "Daily Quest Failed: Pull Not Counted"} end
		return true
	end
	if os.clock() < (f.dx or 0) or (((d.Quest or {}).Current or {}).Id or "") ~= "" then return nil end
	if du.AcceptsLeft(dq, md("Shared", "Lib", "DailyRewardUtil").get_now()) <= 0 then
		if not f.qw.dd then f.qw.dd, f.nq = true, {Title = "Daily Quest", Text = "Daily Quest Done For Today"} end
		return nil
	end
	local id = f.fi() or ic()
	if id == "" or not ul(id) then return nil end
	local ok, e = ti(f, id, f.bk())
	if not ok then return true, e or f.st == "Running" and "Move Failed" or nil end
	local w = workspace:FindFirstChild("World")
	local fo = w and w:FindFirstChild("Islands") and w.Islands:FindFirstChild(id)
	local function nf()
		for _, x in game:GetService("CollectionService"):GetTagged("Interactive") do
			if fo and x:GetAttribute("InteractiveId") == "npc_daily_quest" and x:IsDescendantOf(fo) then return x:IsA("Model") and x:GetPivot().Position or x:IsA("BasePart") and x.Position or nil end
		end
		return nil
	end
	local np, g = nf(), rg(id)
	if not np and g then
		sq(Vector3.new(g.X, 2, g.Z), 10)
		np = nf()
	end
	if not np then
		f.dx = os.clock() + 60
		return true, "Daily Quest Failed: No Quest NPC"
	end
	local c, rt = lc()
	if not rt then return nil, "No Character" end
	ok, e = an(f, c, np, rt.Position)
	if not ok then return true, e or f.st == "Running" and "Move Failed" or nil end
	if f.st ~= "Running" then return true end
	local ak, m = rv.QuestController:AcceptDaily()
	f.rp = true
	if ak ~= true then f.dx = os.clock() + 60 end
	f.nq = {Title = "Daily Quest", Text = ak == true and `Daily Quest: {m}` or `Daily Quest Failed: {m ~= "" and m or "Accept Refused"}`}
	return true
end

local function ss(f)
	local s, fc = f.s, rv.FishingController
	local ks = sk()
	if #ks == 0 then return "Auto Fish Failed: No Skill Equipped" end
	local bp, be
	if f.ab() then bp, be = bo(f) end
	f.bu = bp ~= nil
	if not bp and f.bm then
		pq(f.bm, true)
		f.bm, f.rp = nil, true
		if cj then cj:Stop() end
	end
	if be then return nil, be end
	if not bp and f.bb then f.bb, f.rp = false, true end
	if not bp and f.hm then
		local o, oi = f.hm[1], f.hm[2]
		local ok, e = true, nil
		if ic() ~= oi then ok, e = ti(f, oi, f.bk()) end
		if ok and f.st == "Running" and not f.hf() then ok, e = go(f, o.Position, Vector3.new(o.LookVector.X, 0, o.LookVector.Z).Unit) end
		if f.st ~= "Running" then return nil end
		if not ok then return nil, e or "Return Failed" end
		f.hm, f.rp = nil, false
		return nil
	end
	if not bp then
		for _, q in {f.au() and qn(f) or false, f.qa() and qp(f) or false, f.ya() and qy(f) or false} do
			local u, ue = uq(f, q or nil)
			if u or ue then return nil, ue end
		end
		if f.dq() then
			local u, ue = dy(f)
			if u or ue then return nil, ue end
		end
	end
	local rq = not bp and f.qa() and qp(f)
	local rc = rq and rq[8] and (pd().Quest or {}).Current
	local da = not bp and f.dq() and (pd().DailyQuest or {}).Active
	local yq = not bp and f.ya() and qy(f)
	local fi = not bp and (rc and rc.Id == rq[1] and rq[8] or da and da.Template ~= "" and da.IslandId ~= "" and da.IslandId or yq and yq[8] or f.fi())
	if fi and ic() ~= fi then
		if not ul(fi) then return "Auto Fish Failed: Island Locked" end
		local ok, e = ti(f, fi, f.bk())
		if not ok then return nil, e end
		f.rp = true
		return nil
	end
	if f.ao() and fl() then
		if bp then
			local ok, e = bw(f)
			if not ok then return nil, e end
		end
		local hd, sf = tr(f)
		if hd or sf or f.st ~= "Running" then return hd, sf end
		task.wait(1)
		if fl() then return "Auto Fish Failed: Satchel Full" end
		if bp then return nil end
	end
	local ok, e = eq()
	if not ok then return nil, e end
	local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
	if not h then return nil, "No Character" end
	if f.hp and not f.hf() then
		if cj and cj.p == f.hp then cj:Stop() end
		f.hp, f.rp = nil, true
	end
	local hi = not bp and f.hf()
	if hi then
		local id = vi(h.Position)
		if f.rp or not f.hp or f.hi ~= id then
			local gy
			f.hp, f.hi = nil, id
			if id ~= "" then f.hp, gy = uh(id) end
			if f.hp then
				f.rp = false
				zx(`[Hidden] Spot {math.floor(f.hp.X)}, {math.floor(f.hp.Z)} Under Ground Y {math.floor(gy)} On {id}`)
			elseif id ~= "" then
				zx(`[Hidden] No Spot On {id}, Normal Spot`)
			end
		end
		if f.hp and not (cj and not cj.dn and cj.p == f.hp) then
			local q = tg({Position = f.hp})
			local fk = q and ((q - f.hp) * Vector3.new(1, 0, 1)).Unit
			local u = h.Position.Y < -10 and ut(h.Position)
			if u then
				mo(u, 1e6)
				task.wait(0.1)
			end
			local mk, me = go(f, ut(f.hp) or Vector3.new(f.hp.X, 12, f.hp.Z), fk)
			if f.st ~= "Running" then return nil end
			if not mk then return nil, me or "Move Failed" end
			local j = mo(f.hp, 1e6, fk)
			local dl = os.clock() + 2
			repeat task.wait() until not j or j.st == "Arrived" or j.dn or os.clock() > dl
			if not (j and j.st == "Arrived") then return nil, j and j.why or "Hide Failed" end
		end
	end
	if not bp and not (hi and f.hp) and (f.rp or rv.Swimming and rv.Swimming:IsSwimming() or not tg(h)) then
		f.rp = false
		local g = rs(vi(h.Position)) or vi(h.Position) ~= "" and rs(vi(h.Position), true)
		if not g and vi(h.Position) == "" then
			local nb, nd = nil, math.huge
			for _, x in game:GetService("CollectionService"):GetTagged("IslandRegion") do
				local id = x:GetAttribute("islandId")
				if x:IsA("BasePart") and type(id) == "string" and ul(id) and (x.Position - h.Position).Magnitude < nd then nb, nd = id, (x.Position - h.Position).Magnitude end
			end
			if nb then
				f.rp = true
				local ok, e = ti(f, nb, f.bk())
				return nil, not ok and (e or "Move Failed") or nil
			end
		end
		if not g then return "Auto Fish Failed: No Open Water" end
		local q = tg({Position = g})
		local mk, me = go(f, g, q and ((q - g) * Vector3.new(1, 0, 1)).Unit)
		if not mk then return nil, me end
	end
	if not bp and rv.Swimming and rv.Swimming:IsSwimming() then
		f.rp = true
		return nil, "Swimming"
	end
	local p = bp or tg(h)
	if not p then return "Auto Fish Failed: No Open Water" end
	s.wa, s.fp, s.rl, s.q, s.cr, s.rr, s.sw, s.bs, s.id = nil, nil, nil, nil, nil, nil, 0, 0, nil
	fc.FishCast:Fire(1, p)
	local dl = os.clock() + 3
	repeat task.wait() until s.wa or s.fp or s.rl or s.cr or s.rr or f.st ~= "Running" or os.clock() > dl
	if not (s.wa or s.fp or s.rl or s.cr or s.rr) then
		if f.st == "Running" then fc.FishLootConfirm:Fire() end
		return nil, "No Cast Ack"
	end
	dl = os.clock() + 25
	repeat task.wait() until s.fp or s.rl or s.cr or s.rr or f.st ~= "Running" or os.clock() > dl
	if s.fp and not (s.rl or s.cr or s.rr) and f.st == "Running" then
		fp(s)
		repeat task.wait() until s.rl or s.cr or s.rr or f.st ~= "Running" or os.clock() > dl
	end
	local fo = s.id and md("Data", "Catalog").Fish.GetById(s.id)
	local bf = fo and fo.kind == "Boss"
	local zq, zk, zc = not bp and f.qa() and qp(f), ks, (pd().Quest or {}).Current or {}
	local zp = zc.Progress or {}
	local zs = zq and zc.Id == zq[1] and (zq[1] == "zen_staff_rod" and fo and fo.rarity == "Legendary" and ic() == "island_fossil" and "taiji_hooking_art_v2" or zq[1] == "taiji_hooking_art_v2" and "taiji_hooking_art") or not bp and f.ya() and (zp.CurrentUsedSkill or 0) < (zp.CatchWithSkill or 1) and (zc.Id == "azure_dragon" and "one_hook_supreme" or zc.Id == "supreme_king" and fo and fo.rarity == "Legendary" and ic() == "island_fossil" and "rod_gate_20_percent")
	if zs then
		zk = {}
		for _, x in ks do
			if x[2] == zs then table.insert(zk, x) end
		end
		if #zk == 0 then
			local rq2 = zs:find("^taiji") ~= nil
			zk = ks
			qw(f, `z{zs}`, `{rq2 and "Rod" or "Soul"} Quest Waiting: Equip {({taiji_hooking_art = "Taiji Hooking Art", taiji_hooking_art_v2 = "Taiji Hooking Art V2", one_hook_supreme = "One Hook Supreme", rod_gate_20_percent = "Rod Gate 20%"})[zs]}`, rq2 and "Rod Quest" or "Soul Quest")
		end
	end
	local up = hi and f.hp and s.rl and f.st == "Running" and cj and not cj.dn and cj.p == f.hp and cj.fk
	local uj = up and mo(Vector3.new(f.hp.X, 1000, f.hp.Z), 1e6, up)
	local re = s.rl and f.st == "Running" and rl(f, s, zk) or not (s.cr or s.rr) and f.st == "Running" and "Bite Timeout"
	if uj and not uj.dn then mo(f.hp, 1e6, up) end
	if bf and not (s.cr and s.cr[1]) then
		f.bl = os.clock() + 180
		zx(`[Boss] Fight Ended Without Catch ({s.rr or "No Reset"}), Lockout 180 s`)
	end
	if f.st ~= "Running" or re then
		if s.cr and s.cr[1] and not s.cr[2] then task.wait(0.75); fc.FishLootConfirm:Fire() end
		if not (s.cr or s.rr) then fc.FishCancel:Fire(); task.wait(1) end
		return nil, re
	end
	if bp and s.rr == "IslandLocked" then
		f.bx, f.bb, f.rp = f.br, false, true
		zx("[Boss] Region On A Locked Island, Skipped")
		return nil
	end
	if s.rr == "NoSkillEquipped" then return "Auto Fish Failed: No Skill Equipped" end
	if s.rr == "SatchelFull" and not f.ao() then return "Auto Fish Failed: Satchel Full" end
	if s.rr == "SessionActive" then
		fc.FishLootConfirm:Fire()
		fc.FishCancel:Fire()
		task.wait(1)
	end
	if s.rr then return nil, s.rr end
	if s.cr[1] then
		f.c += 1
		if not s.cr[2] then task.wait(0.75); fc.FishLootConfirm:Fire() end
	end
	task.wait(0.6)
	return nil
end

local function rn(f)
	local n = 0
	while f.st == "Running" do
		if f.fq then
			f.st = "Stopped"
			break
		end
		if f.iw() then
			task.wait(0.5)
			continue
		end
		if zy.on and zy.rq and not (f.bu or f.bb or f.hm) then
			zy.rq = false
			local _, e = zh()
			if e then zx(`[Safe] {e}`, true) end
			f.nq = {Title = "Safe", Text = e}
			continue
		end
		f.bz = true
		local hd, sf = ss(f)
		f.bz = false
		if hd then f.why = hd; return end
		n = sf and n + 1 or 0
		if n >= 5 then
			n, f.rp, f.nq = 0, true, {Title = "Auto Fish", Text = `Auto Fish Retry: {sf}`}
			if cj then cj:Stop() end
			task.wait(1)
		elseif sf then
			task.wait(1)
		end
	end
end

local L = (function()
local ps, uis, tws, gs, hs, rs, cp = game:GetService("Players"), game:GetService("UserInputService"), game:GetService("TweenService"), game:GetService("GuiService"), game:GetService("HttpService"), game:GetService("RunService"), game:GetService("ContentProvider")
local ge = getgenv and getgenv() or _G
local ff, fi = Font.new("rbxassetid://12187375422", Enum.FontWeight.Bold), Font.new("rbxassetid://12187375422", Enum.FontWeight.Bold, Enum.FontStyle.Italic)
local c = {wh = Color3.new(1, 1, 1), bk = Color3.new(0, 0, 0), tx = Color3.fromRGB(232, 238, 255), dm = Color3.fromRGB(150, 165, 200), bl = Color3.fromRGB(85, 170, 255), gn = Color3.fromRGB(0, 249, 0), kf = Color3.fromRGB(204, 205, 209), er = Color3.fromRGB(235, 64, 52), nv = Color3.fromRGB(10, 16, 40), sk = Color3.fromRGB(20, 20, 30)}
local A = {rc = "rbxassetid://125251722298900", bd = "rbxassetid://136433490436465", pt = "rbxassetid://121067803898821", bn = "rbxassetid://93002040112047", cl = "rbxassetid://111107150082609", dv = "rbxassetid://136287431693380", tb = "rbxassetid://125130865636154", kp = "rbxassetid://135029838989371", ib = "rbxassetid://93542270748747", gb = "rbxassetid://78615923342985"}
local ww, wh = 500, 322
local mb, tc, mm = Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch, Enum.UserInputType.MouseMovement
local L, tf, fx, bad = {Flags = {}, Lg = nil :: any}, nil, {}, {}

local function mk(k, p, ch)
	local o = Instance.new(k)
	for i, v in p do
		if i ~= "Parent" then o[i] = v end
	end
	for _, x in ch or {} do x.Parent = o end
	o.Parent = p.Parent
	return o
end

local function rc(r)
	return mk("UICorner", {CornerRadius = UDim.new(0, r or 6)})
end

local function pd(l, r, t, b)
	return mk("UIPadding", {PaddingLeft = UDim.new(0, l), PaddingRight = UDim.new(0, r or l), PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or t or 0)})
end

local function fire(f, ...)
	if type(f) ~= "function" then return end
	task.spawn(function(...)
		local tb
		local ok, e = xpcall(f, function(x)
			tb = debug.traceback(tostring(x), 2)
			return x
		end, ...)
		if ok then return end
		warn(`Callback Failed: {e}`)
		if L.Lg then pcall(L.Lg, `Callback Failed: {tb or e}`) end
		if tf then tf(tostring(e)) end
	end, ...)
end

local function ck(q, k)
	if type(q) ~= "table" or type(q.Name) ~= "string" then error(`{k} Failed: No Name`) end
	if q.Flag ~= nil and type(q.Flag) ~= "string" then error(`{k} Failed: Bad Flag`) end
end

local function dg(h, cs, st, mv, en)
	local a, p0
	local function me(i)
		return i == a or (a.UserInputType == mb and i.UserInputType == mb)
	end

	table.insert(cs, h.InputBegan:Connect(function(i)
		if a or (i.UserInputType ~= mb and i.UserInputType ~= tc) then return end
		a, p0 = i, i.Position
		st(i)
	end))
	table.insert(cs, uis.InputChanged:Connect(function(i)
		if a and (i == a or (a.UserInputType == mb and i.UserInputType == mm)) then mv(Vector2.new(i.Position.X - p0.X, i.Position.Y - p0.Y)) end
	end))
	table.insert(cs, uis.InputEnded:Connect(function(i)
		if not a or not me(i) then return end
		local d = Vector2.new(i.Position.X - p0.X, i.Position.Y - p0.Y)
		a = nil
		if en then en(d) end
	end))
end

local function gr(p, k, r)
	local q = {}
	for i, x in k do q[i] = ColorSequenceKeypoint.new((i - 1) / (#k - 1), Color3.fromHex(x)) end
	return mk("UIGradient", {Parent = p, Color = ColorSequence.new(q), Rotation = r or 90})
end

local function fb(o, k)
	if bad[k] then o.BackgroundTransparency = 0 else table.insert(fx, {o, k}) end
	return o
end

task.spawn(function()
	local ls = {}
	for _, v in A do table.insert(ls, v) end
	pcall(cp.PreloadAsync, cp, ls, function(id, st)
		if st ~= Enum.AssetFetchStatus.Failure then return end
		for k, v in A do
			if v == id then bad[k] = true end
		end
		for _, x in fx do
			if bad[x[2]] and x[1].Parent then x[1].BackgroundTransparency = 0 end
		end
	end)
end)

local function tl(p, z, t, f, sc)
	return mk("TextLabel", {Parent = p, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, FontFace = f or ff, TextSize = z, TextColor3 = c.wh, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = t}, {mk("UIStroke", {Color = sc or c.sk, Thickness = 1.2})})
end

local function bt(x)
	local k = x:FindFirstChildOfClass("UIStroke")
	k.Color, k.Transparency, k.Thickness, k.LineJoinMode = c.bk, 0.25, 2, Enum.LineJoinMode.Round
	x.AnchorPoint, x.Position, x.Size, x.TextTruncate, x.TextXAlignment, x.TextScaled = Vector2.new(0.5, 0.5), UDim2.fromScale(0.58, 0.63), UDim2.fromScale(0.6, 0.32), Enum.TextTruncate.None, Enum.TextXAlignment.Center, true
	return x
end

local function hg(o)
	local w, g = Color3.new(1, 1, 1), Color3.fromRGB(126, 126, 126)
	mk("UIGradient", {Parent = o, Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, w), ColorSequenceKeypoint.new(0.38, w), ColorSequenceKeypoint.new(0.59, g), ColorSequenceKeypoint.new(0.72, w), ColorSequenceKeypoint.new(1, w)})})
	return o
end

local function im(p, i, q)
	q.Parent, q.Image, q.BackgroundTransparency = p, i, q.BackgroundTransparency or 1
	return mk("ImageLabel", q)
end

local function pn(p, ss)
	local f, s = mk("Frame", {Parent = p, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1}), Rect.new(256, 256, 256, 256)
	fb(mk("Frame", {Parent = f, Size = UDim2.fromScale(1, 1), BackgroundColor3 = c.nv, BackgroundTransparency = 1, BorderSizePixel = 0}, {rc(10)}), "rc")
	im(f, A.rc, {Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Slice, SliceCenter = s, SliceScale = ss, ImageColor3 = c.bk, ImageTransparency = 0.2, ZIndex = 2})
	im(f, A.pt, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -8, 1, -8), ScaleType = Enum.ScaleType.Crop, ImageColor3 = Color3.fromHex("9fa1a1"), ImageTransparency = 0.5, ZIndex = 2})
	gr(im(f, A.rc, {Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Slice, SliceCenter = s, SliceScale = ss, ImageTransparency = 0.5, ZIndex = 3}), {"0433ff", "000000"}, -90)
	gr(im(f, A.bd, {Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Slice, SliceCenter = s, SliceScale = ss, ImageColor3 = Color3.fromHex("f4f7ff"), ZIndex = 5}), {"f4f7ff", "7c8088", "7c8088"}, 73)
	return f
end

function L:Window(o)
	o = o or {}
	if type(o) ~= "table" then error("Window Failed: Bad Options") end
	if o.Key ~= nil and o.Key ~= false and typeof(o.Key) ~= "EnumItem" then error("Window Failed: Bad Key") end
	if o.Config ~= nil and (type(o.Config) ~= "string" or (o.Config .. "/"):gsub("[%w _%-]+/", "") ~= "") then error("Window Failed: Bad Config") end
	if ge.__AvW then pcall(ge.__AvW.Destroy, ge.__AvW) end

	local W, cs, tb, ov = {}, {}, {}, nil
	local key = o.Key == nil and Enum.KeyCode.LeftControl or o.Key
	local sg = mk("ScreenGui", {Name = hs:GenerateGUID(false), ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999})
	if not pcall(function() sg.Parent = gethui and gethui() or game:GetService("CoreGui") end) then sg.Parent = ps.LocalPlayer:WaitForChild("PlayerGui") end

	local w = mk("Frame", {Parent = sg, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(ww, wh), BackgroundTransparency = 1, Active = true})
	local us = mk("UIScale", {Parent = w})
	pn(w, 0.3)
	local tp = mk("Frame", {Parent = w, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Active = true, ZIndex = 2})
	local ta = tostring(o.Title or "Avenoric")
	local t1 = ta:match("^(.-)%s*|")
	local bn = fb(im(w, A.bn, {Position = UDim2.fromOffset(-14, -30), Size = UDim2.fromOffset(300, 80), BackgroundColor3 = c.bl, ScaleType = Enum.ScaleType.Fit, Active = true, ZIndex = 3}), "bn")
	local tt = hg(tl(bn, 18, t1 or ta, fi))
	bt(tt)
	local xb = fb(mk("ImageButton", {Parent = w, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(34, 38), BackgroundColor3 = c.er, BackgroundTransparency = 1, AutoButtonColor = false, Image = A.cl, ScaleType = Enum.ScaleType.Fit, ZIndex = 4}), "cl")
	local xu = mk("UIScale", {Parent = xb})
	local nb = mk("TextButton", {Parent = w, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -32, 0, 18), Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 1, AutoButtonColor = false, Text = "", ZIndex = 4})
	mk("Frame", {Parent = nb, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 3), BackgroundColor3 = c.wh, BorderSizePixel = 0, ZIndex = 4}, {rc(2), mk("UIStroke", {Color = c.sk, Thickness = 1.2})})
	local bar = mk("ScrollingFrame", {Parent = w, Position = UDim2.fromOffset(12, 48), Size = UDim2.new(0, 46, 1, -60), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 2}, {mk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3), HorizontalAlignment = Enum.HorizontalAlignment.Center}), pd(0, 0, 3, 3)})
	mk("Frame", {Parent = w, Position = UDim2.fromOffset(64, 48), Size = UDim2.new(0, 1, 1, -60), BackgroundColor3 = c.dm, BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 2})
	local hd = hg(tl(w, 20, "", fi))
	hd.Position, hd.Size, hd.ZIndex = UDim2.fromOffset(78, 44), UDim2.new(1, -92, 0, 26), 2
	local bd = mk("Frame", {Parent = w, Position = UDim2.fromOffset(72, 74), Size = UDim2.new(1, -82, 1, -84), BackgroundTransparency = 1, ZIndex = 2})
	local gz = mk("TextButton", {Parent = w, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -4, 1, -4), Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1, AutoButtonColor = false, Text = "", ZIndex = 6})
	for _, q in {{10, 10}, {6, 10}, {10, 6}, {2, 10}, {6, 6}, {10, 2}} do mk("Frame", {Parent = gz, Position = UDim2.fromOffset(q[1], q[2]), Size = UDim2.fromOffset(2, 2), BackgroundColor3 = c.dm, BorderSizePixel = 0, ZIndex = 6}) end
	local hu = (function()
		local ok, b = pcall(function() return ps.LocalPlayer.PlayerGui:WaitForChild("HUD", 5).Frame.Buttons end)
		return ok and b or nil
	end)()
	local hb = hu and hu:FindFirstAncestorOfClass("ScreenGui")
	local sh = mk("ScreenGui", {Name = hs:GenerateGUID(false), ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 998})
	if hb then
		sh.IgnoreGuiInset = hb.IgnoreGuiInset
		pcall(function() sh.ScreenInsets = hb.ScreenInsets end)
	end
	if not pcall(function() sh.Parent = gethui and gethui() or game:GetService("CoreGui") end) then sh.Parent = ps.LocalPlayer:WaitForChild("PlayerGui") end
	local se = hu and hu:FindFirstChild("Settings")
	local fl
	if se then
		fl = se:Clone()
		for _, d in fl:GetDescendants() do
			if d:IsA("LuaSourceContainer") or d.Name == "HasNotification" then d:Destroy() end
		end
		local t = fl:FindFirstChild("Title", true)
		if t and t:IsA("TextLabel") then t.Text = "LunarX" end
		if type(o.Icon) == "string" then
			for _, d in fl:GetDescendants() do
				if d:IsA("ImageLabel") and d.Name == "Icon" then
					d.Image = o.Icon
					mk("UICorner", {Parent = d, CornerRadius = UDim.new(1, 0)})
				end
			end
		end
		fl.Name, fl.AnchorPoint, fl.LayoutOrder, fl.Parent = "LunarX", Vector2.zero, 0, sh
	else
		fl = mk("ImageButton", {Parent = sh, Name = "LunarX", Size = UDim2.fromOffset(44, 44), BackgroundColor3 = Color3.fromRGB(18, 18, 21), BackgroundTransparency = 0.08, AutoButtonColor = false, Image = type(o.Icon) == "string" and o.Icon or ""}, {rc(22)})
	end
	local fu = fl:FindFirstChildOfClass("UIScale") or mk("UIScale", {Parent = fl})
	local hz, ht = se ~= nil, 0
	local tq = mk("Frame", {Parent = sg, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -12), Size = UDim2.new(0, 250, 1, -80), BackgroundTransparency = 1}, {mk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 8)})})
	local qs, act, tn = mk("UIScale", {Parent = tq}), {}, 0

	local function vs()
		local v = sg.AbsoluteSize
		if v.X < 1 then v = workspace.CurrentCamera.ViewportSize end
		return v, gs:GetGuiInset().Y
	end

	local function cl(p, z)
		local v, t = vs()
		local hx, hy = z.X / 2, z.Y / 2
		return Vector2.new(math.clamp(p.X, hx, math.max(hx, v.X - hx)), math.clamp(p.Y, t + hy, math.max(t + hy, v.Y - hy)))
	end

	local v0, t0 = vs()
	local wp, zm = Vector2.new(v0.X / 2, (v0.Y + t0) / 2), nil
	local function put()
		wp = cl(wp, Vector2.new(ww + 24, wh + 36) * us.Scale)
		w.Position = UDim2.fromOffset(wp.X, wp.Y)
	end

	local function zs()
		local v, t = vs()
		return zm or math.clamp(math.min((v.X - 24) / (ww + 24), (v.Y - t - 24) / (wh + 36), 1.2), 0.5, 1.2)
	end

	local function fit()
		us.Scale = zs()
		qs.Scale = us.Scale
		put()
	end

	local function toast(q)
		tn += 1
		local o = #act >= 4 and table.remove(act, 1)
		if o then o:Destroy() end
		local h = mk("Frame", {Parent = tq, LayoutOrder = tn, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1})
		local k = mk("Frame", {Parent = h, Position = UDim2.fromOffset(270, 0), Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1})
		local pf = pn(k, 0.12)
		mk("Frame", {Parent = pf, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0), Size = UDim2.new(0, 3, 1, -18), BackgroundColor3 = q.Err and c.er or c.bl, BorderSizePixel = 0, ZIndex = 6}, {rc(2)})
		local x = mk("Frame", {Parent = k, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 2}, {pd(20, 12, 10), mk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3)})})
		local function rz() pf.Size = UDim2.new(1, 0, 0, x.AbsoluteSize.Y / math.max(qs.Scale, 0.01)) end
		x:GetPropertyChangedSignal("AbsoluteSize"):Connect(rz)
		rz()
		hg(mk("TextLabel", {Parent = x, LayoutOrder = 1, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, FontFace = fi, TextSize = 15, TextColor3 = c.wh, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Text = q.Title}, {mk("UIStroke", {Color = c.sk, Thickness = 1.2})}))
		if q.Text ~= "" then mk("TextLabel", {Parent = x, LayoutOrder = 2, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, FontFace = ff, TextSize = 13, TextColor3 = c.tx, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Text = q.Text}, {mk("UIStroke", {Color = c.sk, Thickness = 1})}) end
		table.insert(act, h)
		tws:Create(k, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Position = UDim2.new()}):Play()
		task.delay(q.Time, function()
			local i = table.find(act, h)
			if not i then return end
			table.remove(act, i)
			local tw = tws:Create(k, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.fromOffset(270, 0)})
			tw:Play()
			tw.Completed:Wait()
			h:Destroy()
		end)
	end

	local function ef(e)
		toast({Title = "Callback Failed", Text = e, Time = 6, Err = true})
	end

	local cf, dt, pv = o.Config and `Avenoric/Configs/{o.Config}.json`, {}, false
	if cf then
		local ok, r = pcall(function() return isfile(cf) and hs:JSONDecode(readfile(cf)) or {} end)
		if ok and type(r) == "table" then
			dt = r
		else
			pcall(function() writefile(`{cf}.bad`, readfile(cf)) end)
			toast({Title = "Config Load Failed", Text = "Invalid Json", Time = 6, Err = true})
		end
	end

	local function wr()
		if not pv then return end
		pv = false
		local ok, e = pcall(function()
			if not isfolder("Avenoric") then makefolder("Avenoric") end
			local fp = "Avenoric/Configs"
			if not isfolder(fp) then makefolder(fp) end
			for x in o.Config:gmatch("([^/]+)/") do
				fp ..= `/{x}`
				if not isfolder(fp) then makefolder(fp) end
			end
			writefile(cf, hs:JSONEncode(dt))
		end)
		if not ok then toast({Title = "Config Save Failed", Text = tostring(e), Time = 6, Err = true}) end
	end

	local function sf(f, v, e)
		if f == nil then return end
		L.Flags[f] = v
		if not cf then return end
		if e == nil then dt[f] = v else dt[f] = e end
		if pv then return end
		pv = true
		task.delay(0.5, wr)
	end

	local function lv(f)
		if f == nil then return nil end
		return dt[f]
	end
	local zv = tonumber(lv("_z"))
	zm = zv and math.clamp(zv, 0.5, 10) or nil

	local function tg()
		w.Visible = not w.Visible
	end

	fit()
	local function hp()
		if hz and not (hu and hu.Parent and hu:IsDescendantOf(game)) and os.clock() - ht > 1 then
			ht = os.clock()
			local ok, b = pcall(function() return ps.LocalPlayer.PlayerGui.HUD.Frame.Buttons end)
			hu = ok and b or nil
			hb = hu and hu:FindFirstAncestorOfClass("ScreenGui")
		end
		local s, i = hz and hu and hu:FindFirstChild("Settings"), hz and hu and hu:FindFirstChild("Index")
		if s and i and hb then
			local u, g = s:FindFirstChildOfClass("UIScale"), sh.AbsolutePosition
			local z, c1 = s.AbsoluteSize / math.max(u and u.Scale or 1, 0.01), s.AbsolutePosition + s.AbsoluteSize / 2
			local p = c1 * 2 - (i.AbsolutePosition + i.AbsoluteSize / 2) - z / 2 - g
			fl.Size, fl.Position = UDim2.fromOffset(z.X, z.Y), UDim2.fromOffset(p.X, p.Y)
			fl.Visible = hb.Enabled and hu.Parent.Visible and hu.Visible and s.Visible
		else
			fl.Size, fl.Position, fl.Visible = UDim2.fromOffset(44, 44), UDim2.fromOffset(16, select(2, vs()) + 8), true
		end
	end
	hp()
	table.insert(cs, rs.RenderStepped:Connect(hp))
	table.insert(cs, sg:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local v, t = vs()
		wp = Vector2.new(v.X / 2, (v.Y + t) / 2)
		fit()
	end))
	local w0
	for _, h in {tp, bn} do
		dg(h, cs, function() w0 = wp end, function(d)
			wp = w0 + d
			put()
		end)
	end
	local z0, s0
	dg(gz, cs, function()
		z0, s0 = us.Scale, Vector2.new(ww, wh) * us.Scale
	end, function(d)
		zm = math.clamp(z0 * (1 + (d.X / s0.X + d.Y / s0.Y) / 2), 0.5, 10)
		us.Scale = zs()
		qs.Scale = us.Scale
		put()
	end, function() sf("_z", zm) end)
	local fm, fv = fl:FindFirstChild("Image"), false
	local fk = fm and fm:FindFirstChild("Icon")
	local function fa(x, ro)
		tws:Create(fu, TweenInfo.new(0.12, Enum.EasingStyle.Back), {Scale = x}):Play()
		if fk and ro then tws:Create(fk, TweenInfo.new(0.12, Enum.EasingStyle.Back), {Rotation = ro}):Play() end
	end
	table.insert(cs, fl.MouseEnter:Connect(function()
		fv = true
		fa(1.05, 5)
	end))
	table.insert(cs, fl.MouseLeave:Connect(function()
		fv = false
		fa(1, 0)
	end))
	table.insert(cs, fl.MouseButton1Down:Connect(function() fa(0.9) end))
	table.insert(cs, fl.MouseButton1Up:Connect(function() fa(fv and 1.05 or 1) end))
	table.insert(cs, fl.Activated:Connect(tg))
	table.insert(cs, nb.Activated:Connect(function() w.Visible = false end))
	local xa, xn = false, 0
	local function xs(a)
		xa = a
		tws:Create(xu, TweenInfo.new(0.12), {Scale = a and 1.2 or 1}):Play()
	end

	table.insert(cs, xb.Activated:Connect(function()
		if xa then
			(W :: any):Destroy()
			return
		end
		xn += 1
		local n = xn
		xs(true)
		task.delay(3, function()
			if xa and xn == n then xs(false) end
		end)
	end))
	table.insert(cs, uis.InputBegan:Connect(function(i)
		if key and i.KeyCode == key and not uis:GetFocusedTextBox() then tg() end
	end))

	local function sel(T)
		hd.Text = T.nm
		for _, x in tb do
			local on = x == T
			x.cg.Visible = on
			tws:Create(x.bt, TweenInfo.new(0.15), {BackgroundColor3 = on and c.bl or c.bk, BackgroundTransparency = on and 0.2 or 0.5}):Play()
			x.sk.Transparency = on and 0 or 1
		end
	end

	local function ox()
		local x = ov
		ov = nil
		if not x then return end
		x.f:Destroy()
		if x.cb then x.cb() end
	end

	local function oo(nm, ls, has, pick, cb)
		ox()
		local f = mk("TextButton", {Parent = w, Size = UDim2.fromScale(1, 1), BackgroundColor3 = c.bk, BackgroundTransparency = 0.45, AutoButtonColor = false, Text = "", ZIndex = 20})
		f.Activated:Connect(ox)
		local p = mk("Frame", {Parent = f, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53), Size = UDim2.new(1, -60, 1, -56), BackgroundTransparency = 1, Active = true})
		pn(p, 0.2)
		local t = hg(tl(p, 17, nm, fi))
		t.Position, t.Size, t.ZIndex = UDim2.fromOffset(14, 6), UDim2.new(1, -60, 0, 26), 2
		local x = fb(mk("ImageButton", {Parent = p, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(28, 31), BackgroundColor3 = c.er, BackgroundTransparency = 1, AutoButtonColor = false, Image = A.cl, ScaleType = Enum.ScaleType.Fit, ZIndex = 3}), "cl")
		x.Activated:Connect(ox)
		local y, sb = 36, nil
		if #ls > 8 then
			local bx = mk("Frame", {Parent = p, Position = UDim2.fromOffset(12, 36), Size = UDim2.new(1, -24, 0, 30), BackgroundColor3 = c.bk, BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 2})
			im(bx, A.ib, {Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(80, 80, 432, 432), SliceScale = 0.15, ZIndex = 3})
			sb = mk("TextBox", {Parent = bx, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1, ClearTextOnFocus = false, FontFace = ff, TextSize = 14, TextColor3 = c.wh, PlaceholderColor3 = Color3.fromRGB(128, 128, 128), PlaceholderText = "SEARCH", TextXAlignment = Enum.TextXAlignment.Left, Text = "", ZIndex = 4})
			y = 72
		end
		local cv = mk("CanvasGroup", {Parent = p, Position = UDim2.fromOffset(12, y), Size = UDim2.new(1, -24, 1, -y - 10), BackgroundTransparency = 1, ZIndex = 2})
		local fg = mk("UIGradient", {Parent = cv, Rotation = 90})
		local sc = mk("ScrollingFrame", {Parent = cv, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = c.bl, ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, {mk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3)}), pd(0, 6, 0, 0)})
		local function fe()
			local q = sc.CanvasPosition.Y
			local u, d = q > 1, q < sc.AbsoluteCanvasSize.Y - sc.AbsoluteWindowSize.Y - 1
			fg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, u and 1 or 0), NumberSequenceKeypoint.new(0.1, 0), NumberSequenceKeypoint.new(0.9, 0), NumberSequenceKeypoint.new(1, d and 1 or 0)})
		end
		for _, n in {"CanvasPosition", "AbsoluteCanvasSize", "AbsoluteWindowSize"} do sc:GetPropertyChangedSignal(n):Connect(fe) end
		fe()
		local bs = {}
		for i, s in ls do
			local b = mk("TextButton", {Parent = sc, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = c.bl, BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = ""}, {rc(6)})
			local l = tl(b, 14, s)
			l.Position, l.Size = UDim2.fromOffset(10, 0), UDim2.new(1, -40, 1, 0)
			local k = mk("Frame", {Parent = b, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = c.gn, BackgroundTransparency = 1, BorderSizePixel = 0}, {rc(4), mk("UIStroke", {Color = c.wh, Thickness = 1.2})})
			bs[s] = {b, k}
			b.Activated:Connect(function()
				if pick(s) then ox() end
			end)
		end
		local function rf()
			for s, z in bs do
				local on = has(s)
				z[1].BackgroundTransparency, z[2].BackgroundTransparency = on and 0.55 or 1, on and 0 or 1
			end
		end
		if sb then
			sb:GetPropertyChangedSignal("Text"):Connect(function()
				local q = sb.Text:lower()
				for s, z in bs do z[1].Visible = q == "" or s:lower():find(q, 1, true) ~= nil end
			end)
		end
		rf()
		ov = {f = f, cb = cb}
		return rf
	end

	function W:Tab(q)
		if type(q) ~= "table" or type(q.Name) ~= "string" then error("Tab Failed: No Name") end
		if q.Icon ~= nil and type(q.Icon) ~= "string" then error("Tab Failed: Bad Icon") end
		if q.IconRect ~= nil and (type(q.IconRect) ~= "table" or #q.IconRect ~= 4) then error("Tab Failed: Bad Icon Rect") end
		local T, n = {nm = q.Name}, 0
		T.bt = mk("TextButton", {Parent = bar, LayoutOrder = #tb + 1, Size = UDim2.fromOffset(34, 34), BackgroundColor3 = c.bk, BackgroundTransparency = 0.5, BorderSizePixel = 0, AutoButtonColor = false, Text = ""}, {rc(10)})
		T.sk = mk("UIStroke", {Parent = T.bt, Color = c.wh, Thickness = 1.5, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
		if q.Icon then
			local x = im(T.bt, q.Icon, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(26, 26), ScaleType = Enum.ScaleType.Fit})
			if q.IconRect then x.ImageRectOffset, x.ImageRectSize = Vector2.new(q.IconRect[1], q.IconRect[2]), Vector2.new(q.IconRect[3], q.IconRect[4]) end
		else
			tl(T.bt, 18, q.Name:sub(1, 1), fi).TextXAlignment = Enum.TextXAlignment.Center
		end
		T.cg = mk("CanvasGroup", {Parent = bd, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false})
		local fg = mk("UIGradient", {Parent = T.cg, Rotation = 90})
		T.pg = mk("ScrollingFrame", {Parent = T.cg, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = c.bl, ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, {pd(0, 8, 2, 6), mk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})})
		local function fe()
			local y = T.pg.CanvasPosition.Y
			local a, z = y > 1, y < T.pg.AbsoluteCanvasSize.Y - T.pg.AbsoluteWindowSize.Y - 1
			fg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, a and 1 or 0), NumberSequenceKeypoint.new(0.1, 0), NumberSequenceKeypoint.new(0.9, 0), NumberSequenceKeypoint.new(1, z and 1 or 0)})
		end
		for _, p in {"CanvasPosition", "AbsoluteCanvasSize", "AbsoluteWindowSize"} do table.insert(cs, T.pg:GetPropertyChangedSignal(p):Connect(fe)) end
		fe()
		table.insert(tb, T)
		table.insert(cs, T.bt.Activated:Connect(function() sel(T) end))
		if #tb == 1 then sel(T) end

		local function od()
			n += 1
			return n
		end

		local function row(k, h)
			local r = mk(k, {Parent = T.pg, LayoutOrder = od(), Size = UDim2.new(1, 0, 0, h or 38), BackgroundColor3 = c.bk, BorderSizePixel = 0})
			if r:IsA("TextButton") then r.AutoButtonColor, r.Text = false, "" end
			mk("UIGradient", {Parent = r, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.1, 0.4), NumberSequenceKeypoint.new(0.9, 0.4), NumberSequenceKeypoint.new(1, 1)})})
			return r
		end

		local function lb(p, s, wd)
			local x = tl(p, 15, s, ff, Color3.fromHex("303030"))
			x.Position, x.Size = UDim2.fromOffset(14, 0), UDim2.new(1, -14 - wd, 1, 0)
			gr(x, {"d9daff", "55ffff", "4f87ff", "55aaff"})
			return x
		end

		function T:Section(q)
			if type(q) ~= "table" or type(q.Name) ~= "string" then error("Section Failed: No Name") end
			local r = mk("Frame", {Parent = T.pg, LayoutOrder = od(), Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1})
			gr(im(r, A.dv, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.9, 0, 0, 5), ScaleType = Enum.ScaleType.Stretch}), {"fdffff", "f7fafa", "929294", "dfe1e1", "fdffff"}, 0)
			local x = tl(r, 18, q.Name, fi)
			x.TextXAlignment, x.TextTruncate, x.ZIndex = Enum.TextXAlignment.Center, Enum.TextTruncate.None, 2
			return {Set = function(_, s) x.Text = tostring(s) end, Get = function() return x.Text end}
		end

		function T:Label(q)
			if type(q) ~= "table" or q.Text == nil then error("Label Failed: No Text") end
			local r = row("Frame")
			r.AutomaticSize = Enum.AutomaticSize.Y
			local x = mk("TextLabel", {Parent = r, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, FontFace = ff, TextSize = 14, TextColor3 = c.tx, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Text = tostring(q.Text)}, {pd(14, 14, 9), mk("UIStroke", {Color = c.sk, Thickness = 1})})
			return {Set = function(_, s) x.Text = tostring(s) end, Get = function() return x.Text end}
		end

		function T:Button(q)
			if type(q) ~= "table" or type(q.Name) ~= "string" then error("Button Failed: No Name") end
			local r = row("TextButton")
			local x = lb(r, q.Name, 96)
			local g = fb(mk("ImageButton", {Parent = r, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(78, 26), BackgroundColor3 = c.gn, BackgroundTransparency = 1, AutoButtonColor = false, Image = A.gb, ScaleType = Enum.ScaleType.Fit}, {rc(6)}), "gb")
			gr(g, {"00f900", "76ff4d"})
			hg(tl(g, 14, "Run", fi)).TextXAlignment = Enum.TextXAlignment.Center
			local u = mk("UIScale", {Parent = g})
			local function go()
				u.Scale = 0.9
				tws:Create(u, TweenInfo.new(0.2), {Scale = 1}):Play()
				fire(q.Callback)
			end
			table.insert(cs, r.Activated:Connect(go))
			table.insert(cs, g.Activated:Connect(go))
			return {Set = function(_, s) x.Text = tostring(s) end, Get = function() return x.Text end}
		end

		function T:Toggle(q)
			ck(q, "Toggle")
			local r, v = row("TextButton"), nil
			lb(r, q.Name, 70)
			local k = mk("Frame", {Parent = r, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(54, 24), BackgroundColor3 = c.bl, BorderSizePixel = 0}, {rc(12)})
			rc(12).Parent = im(k, A.tb, {Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(7, 7), ImageColor3 = c.bk, ImageTransparency = 0.85})
			local d = mk("Frame", {Parent = k, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.05, 0.5), Size = UDim2.fromScale(0.45, 0.8), BackgroundColor3 = c.kf, BorderSizePixel = 0}, {rc(10), mk("UIStroke", {Color = c.bk, Thickness = 1.5})})
			rc(10).Parent = im(d, A.kp, {Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Crop, ImageColor3 = c.bk, ImageTransparency = 0.5})
			local function set(x, cb)
				x = x == true
				if x == v then return end
				v = x
				sf(q.Flag, v)
				tws:Create(d, TweenInfo.new(0.15), {Position = UDim2.fromScale(v and 0.5 or 0.05, 0.5), BackgroundColor3 = v and c.gn or c.kf}):Play()
				if cb then fire(q.Callback, v) end
			end

			local sv = lv(q.Flag)
			set(q.Default)
			if type(sv) == "boolean" then
				set(sv)
				task.defer(fire, q.Callback, v)
			end
			table.insert(cs, r.Activated:Connect(function() set(not v, true) end))
			return {Set = function(_, x) set(x, true) end, Get = function() return v end}
		end

		function T:Dropdown(q)
			ck(q, "Dropdown")
			local mu, v, rd, rf = q.Multi == true, nil, false, nil
			local function po(o, k)
				if type(o) ~= "table" then error(`{k} Failed: Bad Options`) end
				local t = {}
				for _, s in o do
					if type(s) ~= "string" then error(`{k} Failed: Bad Options`) end
					if not table.find(t, s) then table.insert(t, s) end
				end
				return t
			end

			local op = po(q.Options or {}, "Dropdown")
			local r = row("TextButton")
			lb(r, q.Name, 160)
			local vl = tl(r, 13, "")
			vl.AnchorPoint, vl.Position, vl.Size, vl.TextXAlignment, vl.TextColor3 = Vector2.new(1, 0.5), UDim2.new(1, -30, 0.5, 0), UDim2.fromOffset(140, 20), Enum.TextXAlignment.Right, c.dm
			local cv = mk("Frame", {Parent = r, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(12, 6), BackgroundTransparency = 1})
			mk("Frame", {Parent = cv, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(8, 2), Rotation = 45, BackgroundColor3 = c.bl, BorderSizePixel = 0})
			mk("Frame", {Parent = cv, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(9, 3), Size = UDim2.fromOffset(8, 2), Rotation = -45, BackgroundColor3 = c.bl, BorderSizePixel = 0})

			local function has(x)
				return mu and table.find(v, x) ~= nil or v == x
			end

			local function draw()
				vl.Text = mu and (#v > 0 and table.concat(v, ", ") or "None") or v or "None"
				if rf then rf() end
			end

			local function nv(x)
				if not mu then return table.find(op, x) and x or nil end
				local o = {}
				if type(x) == "table" then
					for _, s in op do
						if table.find(x, s) then table.insert(o, s) end
					end
				end
				return o
			end

			local function same(a, b)
				if not mu then return a == b end
				if #a ~= #b then return false end
				for i = 1, #a do
					if a[i] ~= b[i] then return false end
				end
				return true
			end

			local function set(x, cb)
				x = nv(x)
				if rd and same(x, v) then return end
				rd, v = true, x
				sf(q.Flag, mu and table.clone(v) or v, mu and table.clone(v) or v or false)
				draw()
				if cb then fire(q.Callback, mu and table.clone(v) or v) end
			end

			local sv = lv(q.Flag)
			set(q.Default)
			if mu and type(sv) == "table" or not mu and (sv == false or type(sv) == "string") then
				set(sv or nil)
				task.defer(fire, q.Callback, mu and table.clone(v) or v)
			end
			table.insert(cs, r.Activated:Connect(function()
				rf = oo(q.Name, op, has, function(x)
					if not mu then
						set(x, true)
						return true
					end
					local n = table.clone(v)
					local j = table.find(n, x)
					if j then table.remove(n, j) else table.insert(n, x) end
					set(n, true)
					return false
				end, function() rf = nil end)
			end))
			return {Set = function(_, x)
				if mu and type(x) ~= "table" then error("Dropdown Set Failed: Not A Table") end
				if not mu and x ~= nil and not table.find(op, x) then error("Dropdown Set Failed: Unknown Option") end
				set(x, true)
			end, Get = function() return mu and table.clone(v) or v end, Refresh = function(_, o)
				op = po(o, "Dropdown Refresh")
				if rf then ox() end
				set(v, true)
				draw()
			end}
		end

		return T
	end

	function W:Notify(q)
		if type(q) ~= "table" or (q.Title == nil and q.Text == nil) then error("Notify Failed: No Text") end
		if q.Time ~= nil and (type(q.Time) ~= "number" or not (q.Time > 0)) then error("Notify Failed: Bad Time") end
		toast({Title = tostring(q.Title or "Avenoric"), Text = q.Text == nil and "" or tostring(q.Text), Time = q.Time or 4})
	end

	function W:Destroy()
		for _, x in cs do x:Disconnect() end
		table.clear(cs)
		table.clear(act)
		wr()
		sg:Destroy()
		sh:Destroy()
		if tf == ef then tf = nil end
		if ge.__AvW == W then ge.__AvW = nil end
	end

	tf, ge.__AvW = ef, W
	return W
end

L.Sk = {bt = bt, mk = mk, rc = rc, gr = gr, fb = fb, tl = tl, hg = hg, im = im, pn = pn, A = A, c = c, ff = ff, fi = fi}

return L
end)()

local ge = getgenv()
local gi = (function()
	local dc, p = crypt and crypt.base64decode or base64_decode, "Avenoric/Assets/NgaoLogo.png"
	if not (dc and getcustomasset and writefile) then return nil end
	local ok, r = pcall(function()
		if not isfolder("Avenoric") then makefolder("Avenoric") end
		if not isfolder("Avenoric/Assets") then makefolder("Avenoric/Assets") end
		writefile(p, dc("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"))
		return getcustomasset(p)
	end)
	return ok and type(r) == "string" and r or nil
end)()
local kf, ky, ex, kl = "Avenoric/Key.txt", "LunarX-EC2F-86PQ", 1791903600
local kc = {t = 0, v = false}
local function kv()
	if os.clock() < kc.t then return kc.v end
	local o, s = pcall(readfile, kf)
	kc.v, kc.t = o and type(s) == "string" and s:match("^%s*(.-)%s*$") == ky, os.clock() + 30
	return kc.v
end
do
	local function xp() return workspace:GetServerTimeNow() >= ex end
	local o, s = pcall(readfile, kf)
	if ge.__FmD then pcall(function() ge.__FmD:Destroy() end) end
	ge.__FmD = nil
	if xp() or not (o and type(s) == "string" and s:match("^%s*(.-)%s*$") == ky) then
		local tws, S = game:GetService("TweenService"), L.Sk
		local mi, c, A, ff, fi = S.mk, S.c, S.A, S.ff, S.fi
		local function lb(q)
			q.BackgroundTransparency, q.FontFace, q.TextXAlignment, q.TextTruncate = 1, q.FontFace or ff, q.TextXAlignment or Enum.TextXAlignment.Left, Enum.TextTruncate.AtEnd
			return mi("TextLabel", q, {mi("UIStroke", {Color = c.bk, Thickness = 1.2, Transparency = 0.3})})
		end
		local function bn(q, g, t, z)
			q.BackgroundColor3, q.BackgroundTransparency, q.AutoButtonColor, q.Image, q.ScaleType, q.SliceCenter, q.SliceScale = c.gn, 1, false, A.gb, Enum.ScaleType.Slice, Rect.new(60, 60, 196, 196), 0.35
			local b = S.fb(mi("ImageButton", q), "gb")
			S.gr(b, g)
			lb({Parent = b, Size = UDim2.fromScale(1, 1), FontFace = fi, TextSize = z, TextColor3 = c.wh, TextXAlignment = Enum.TextXAlignment.Center, Text = t, ZIndex = q.ZIndex + 1})
			return b
		end
		local sg, ch = mi("ScreenGui", {Name = game:GetService("HttpService"):GenerateGUID(false), ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1000}), nil
		ge.__FmD = sg
		if not pcall(function() sg.Parent = gethui() end) then sg.Parent = lp:WaitForChild("PlayerGui") end
		local fw, fh = 380, 494
		local fr = mi("Frame", {Parent = sg, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(fw, fh), BackgroundTransparency = 1})
		local us = mi("UIScale", {Parent = fr, Scale = 0.5})
		S.pn(fr, 0.25)
		local hb = S.fb(S.im(fr, A.bn, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -26), Size = UDim2.fromOffset(300, 74), BackgroundColor3 = c.bl, ScaleType = Enum.ScaleType.Fit, ZIndex = 7}), "bn")
		local ht = S.bt(S.tl(hb, 16, "LunarX Hub", fi))
		ht.Position, ht.Size, ht.ZIndex = UDim2.fromScale(0.58, 0.62), UDim2.fromScale(0.62, 0.34), 8
		local xb = S.fb(mi("ImageButton", {Parent = fr, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(36, 40), BackgroundColor3 = c.er, BackgroundTransparency = 1, AutoButtonColor = false, Image = A.cl, ScaleType = Enum.ScaleType.Fit, ZIndex = 8}), "cl")
		local xu = mi("UIScale", {Parent = xb})
		local lo = S.im(fr, gi or "", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 58), Size = UDim2.fromOffset(88, 88), BackgroundColor3 = c.nv, BackgroundTransparency = 0, ZIndex = 6})
		S.rc(44).Parent = lo
		mi("UIStroke", {Parent = lo, Color = c.bl, Thickness = 3})
		S.gr(lb({Parent = fr, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 152), Size = UDim2.new(1, -40, 0, 26), FontFace = fi, TextSize = 22, TextColor3 = c.wh, TextXAlignment = Enum.TextXAlignment.Center, Text = "Fishing Master", ZIndex = 6}), {"d9daff", "55ffff", "4f87ff"})
		local function cd(y, h, n, t)
			local k = mi("Frame", {Parent = fr, Position = UDim2.fromOffset(22, y), Size = UDim2.new(1, -44, 0, h), BackgroundColor3 = Color3.fromHex("0a1640"), BackgroundTransparency = 0.25, ZIndex = 6}, {S.rc(10)})
			local ks = mi("UIStroke", {Parent = k, Color = Color3.fromHex("4f87ff"), Thickness = 1.2, Transparency = 0.35, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
			local kn = lb({Parent = k, Position = UDim2.fromOffset(14, 8), Size = UDim2.fromOffset(200, 16), TextSize = 13, TextColor3 = Color3.fromHex("55ffff"), Text = n, ZIndex = 7})
			lb({Parent = k, Position = UDim2.fromOffset(14, 24), Size = UDim2.new(1, -28, 0, 22), FontFace = fi, TextSize = 18, TextColor3 = c.wh, Text = t, ZIndex = 7})
			return {k, ks, kn, n}
		end
		local b1 = cd(192, 66, "STEP 1", "Get The Key Link")
		local gk = bn({Parent = b1[1], AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(118, 42), ZIndex = 8}, {"55aaff", "4f87ff"}, "Get Key", 17)
		local b2 = cd(270, 108, "STEP 2", "Paste The Key")
		local bx = mi("Frame", {Parent = b2[1], Position = UDim2.fromOffset(12, 54), Size = UDim2.new(1, -24, 0, 42), BackgroundColor3 = c.bk, BackgroundTransparency = 0.35, ZIndex = 7}, {S.rc(8)})
		S.im(bx, A.ib, {Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(80, 80, 432, 432), SliceScale = 0.15, ZIndex = 8})
		local tb = mi("TextBox", {Parent = bx, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), BackgroundTransparency = 1, ClearTextOnFocus = false, ClipsDescendants = true, FontFace = ff, TextSize = 17, TextColor3 = c.wh, PlaceholderColor3 = Color3.fromRGB(140, 150, 175), PlaceholderText = "LunarX-XXXX-XXXX", Text = "", ZIndex = 9})
		tb:GetPropertyChangedSignal("Text"):Connect(function() if #tb.Text > 32 then tb.Text = tb.Text:sub(1, 32) end end)
		local sm = bn({Parent = fr, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 390), Size = UDim2.new(1, -44, 0, 46), ZIndex = 7}, {"00f900", "76ff4d"}, "Submit", 20)
		local st = lb({Parent = fr, Position = UDim2.fromOffset(22, 442), Size = UDim2.new(1, -44, 0, 18), TextSize = 14, TextColor3 = c.er, TextXAlignment = Enum.TextXAlignment.Center, Text = xp() and "Key Expired, Get The New Key" or "", ZIndex = 6})
		local pl = mi("Frame", {Parent = fr, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 464), Size = UDim2.fromOffset(190, 20), BackgroundColor3 = c.bk, BackgroundTransparency = 0.45, ZIndex = 6}, {S.rc(10)})
		local ft = lb({Parent = pl, Size = UDim2.fromScale(1, 1), TextSize = 13, TextColor3 = Color3.fromHex("96a5c8"), TextXAlignment = Enum.TextXAlignment.Center, Text = "", ZIndex = 7})
		local function sx(t, q) st.Text, st.TextColor3 = t, q or c.er end
		local function dn(b) b[2].Color, b[2].Transparency, b[3].Text, b[3].TextColor3 = c.gn, 0, `{b[4]} - DONE`, c.gn end
		local function sk()
			local p = fr.Position
			for _, d in {-8, 8, -5, 5, 0} do
				fr.Position = p + UDim2.fromOffset(d, 0)
				task.wait(0.04)
			end
			fr.Position = p
		end
		local function dj()
			local q = request or http_request or (syn and syn.request)
			if not q then return end
			local h = game:GetService("HttpService")
			for pt = 6463, 6472 do
				local ok, r = pcall(q, {Url = `http://127.0.0.1:{pt}/rpc?v=1`, Method = "POST", Headers = {["Content-Type"] = "application/json", Origin = "https://discord.com"}, Body = h:JSONEncode({cmd = "INVITE_BROWSER", nonce = h:GenerateGUID(false), args = {code = "fTQF5TvfEJ"}})})
				if ok and type(r) == "table" and r.StatusCode == 200 then return end
			end
		end
		local function sb()
			local t = tb.Text:match("^%s*(.-)%s*$")
			local e = t == "" and "Key Check Failed: Empty Key" or t ~= ky and "Key Check Failed: Wrong Key" or xp() and "Key Check Failed: Key Expired" or nil
			if e then
				sx(e)
				task.spawn(sk)
				return
			end
			pcall(function()
				if not isfolder("Avenoric") then makefolder("Avenoric") end
				writefile(kf, ky)
			end)
			dn(b2)
			sx("Key Accepted", c.gn)
			task.spawn(dj)
			task.wait(0.4)
			ch = ch or "k"
		end
		sm.Activated:Connect(sb)
		local xa, xn = false, 0
		xb.Activated:Connect(function()
			if xa then
				ch = ch or "c"
				return
			end
			xn += 1
			local n = xn
			xa = true
			tws:Create(xu, TweenInfo.new(0.12), {Scale = 1.2}):Play()
			task.delay(3, function()
				if xa and xn == n then
					xa = false
					tws:Create(xu, TweenInfo.new(0.12), {Scale = 1}):Play()
				end
			end)
		end)
		tb.FocusLost:Connect(function(e) if e then sb() end end)
		task.spawn(function()
			while sg.Parent and not ch do
				local r = ex - workspace:GetServerTimeNow()
				ft.Text = r > 0 and string.format("Key Expires In %dh %02dm", r // 3600, r % 3600 // 60) or "Key Expired"
				task.wait(20)
			end
		end)
		local v = workspace.CurrentCamera.ViewportSize
		local sc = math.min(math.max(v.Y * 0.42 / fh, 0.75), (v.Y - 24) / (fh + 26), (v.X - 24) / fw)
		us.Scale = sc * 0.9
		tws:Create(us, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Scale = sc}):Play()
		repeat task.wait() until ch or ge.__FmD ~= sg
		if ge.__FmD ~= sg then error("Key Gate Replaced", 0) end
		ge.__FmD = nil
		sg:Destroy()
		if ch ~= "k" then error("Key Gate Closed", 0) end
	end
end
local gw = L:Window({Title = "LunarX Hub | Fishing Master", Config = `FishingMaster/{lp.Name}`, Icon = gi})
do
	local on = gw.Notify
	gw.Notify = function(s, q)
		if type(q) == "table" then zx(`[{q.Title or "Hub"}] {q.Text or ""}`) end
		return on(s, q)
	end
	L.Lg = function(e) zx(`[Hub] {e}`) end
	zx(`[Hub] Loaded | Place {game.PlaceVersion} | Server {game.JobId:sub(1, 8)} | {#ps:GetPlayers()} Players`)
end
local gt, ft = gw:Tab({Name = "General", Icon = "rbxassetid://135753849387222"}), nil

local xl: {[any]: any} = {}

local function xt()
	local d, r = pd(), lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
	local n, f, i = 0, ge.__FmF, ic()
	for _ in (d.Inventory or {}).Fishes or {} do n += 1 end
	local fu = md("Shared", "Lib", "FishStorageRules").GetState(d).isFull
	local p = r and `{math.floor(r.Position.X)}, {math.floor(r.Position.Y)}, {math.floor(r.Position.Z)}` or "None"
	return `[State] Island {i ~= "" and i or "Sea"} | Pos {p} | Coin {d.Coin or 0} | Satchel {n}{fu and " Full" or ""} | Quest {((d.Quest or {}).Current or {}).Id or ""} | Daily {((d.DailyQuest or {}).Active or {}).Template or ""} | Rod {d.RodEquip or "?"} | Farm {f and f.st or "Off"}{f and f.bu and " At Boss" or ""}`
end

local function cx(fn, ...)
	if not kv() then return false, "Key Check Failed: No Valid Key" end
	local r, dn
	task.spawn(function(...)
		local tb
		r = table.pack(xpcall(fn, function(x)
			tb = debug.traceback(tostring(x), 2)
			return x
		end, ...))
		if not r[1] and not xl[r[2]] and (tb ~= xl.lt or os.clock() - (xl.tt or 0) > 60) then
			xl.lt, xl.tt = tb, os.clock()
			zx(`[Error] {tb or r[2]}`)
			local ok, s = pcall(xt)
			if ok then zx(s) end
		end
		dn = true
	end, ...)
	repeat task.wait() until dn
	return table.unpack(r, 1, r.n)
end

local function fb(f)
	local s, fc = f.s, rv.FishingController
	for n, cb in {
		FishWaitingAck = function() s.wa = true end,
		FishFirstPullStart = function(id, _, _, lm, st) s.fp, s.id = {lm, st}, id end,
		FishFirstPullResult = function(m) s.pm = m end,
		FishReelStartAck = function(id) s.rl, s.id = true, s.id or id end,
		FishQTEPrompt = function(d) s.q = {d, os.clock() + 0.2 + math.random() * 0.15} end,
		FishQTECancel = function() s.q = nil end,
		FishSkillWindow = function(w) s.sw = os.clock() + w end,
		FishBossStun = function(w) s.bs = os.clock() + w end,
		FishCatchResult = function(ok, _, _, _, _, sp) s.cr = {ok, sp} end,
		FishReset = function(r) s.rr = r end,
	} do table.insert(f.cs, fc[n].OnClientEvent:Connect(cb)) end
	table.insert(f.cs, rv.BossRegionController.BossSpawnClaimed.OnClientEvent:Connect(function(v) s.bc = v == true end))
	table.insert(f.cs, md("Data", "Packets", "DailyQuestPackets").Completed.OnClientEvent:Connect(function(g, c)
		if f.dq() then f.nq = {Title = "Daily Quest", Text = `Daily Quest Done: +{g} Gem, +{c} Coin`} end
	end))
	table.insert(f.cs, rv.RodController.ReplicatedSkillCooldown.OnClientEvent:Connect(function(t)
		if typeof(t) ~= "table" then return end
		for k, v in t do
			if type(v) == "table" and type(v.phase) == "string" then s.cd[k] = {v.phase, os.clock() + (tonumber(v.remaining) or 0)} end
		end
	end))
	local tb
	local ok, e = xpcall(rn, function(x)
		tb = debug.traceback(tostring(x), 2)
		return x
	end, f)
	for _, c in f.cs do c:Disconnect() end
	local _, hr = lc()
	local hq = (f.hp or f.hf()) and hr and hr.Position.Y > -10 and ut(hr.Position)
	if hq and (hr.Position.Y < hq.Y - 4 or hr.Position.Y > 500) then
		mo(hq, 1e6)
		task.wait(0.1)
	end
	if cj then cj:Stop() end
	if not ok then
		zx(`[Auto Fish] Crash: {tb or e}`)
		xl[e] = true
		error(e, 0)
	end
end

local function fs()
	local o = ge.__FmF
	if o then
		o.st = "Stopped"
		local dl = os.clock() + 5
		repeat task.wait(0.1) until o.dn or os.clock() > dl
	end
	local f = {st = "Running", s = {cd = {}, sw = 0, bs = 0}, cs = {}, c = 0, rp = true, dn = false, bu = false, qx = {}, qw = {}, nq = false}
	function f.ao() return L.Flags.as == true end
	function f.au() return L.Flags.au == true end
	function f.qa() return L.Flags.qa == true end
	function f.qs() return qm[L.Flags.qs] end
	function f.ya() return L.Flags.ya == true end
	function f.ys() return L.Flags.ys or {} end
	function f.kp()
		local k = f.au() and qv(qn(f)) or {}
		for u in f.qa() and qv(qp(f)) or {} do k[u] = true end
		local d = pd()
		local cq = (d.Quest or {}).Current or {}
		for _, q in f.ya() and qk(d, f.ys()) or {} do
			for u in select(2, qc(q, d, cq.Id == q[1] and cq.Progress or {RequiredFish = 3})) do k[u] = true end
		end
		return k
	end
	function f.sr() return L.Flags.sr or {} end
	function f.fi() return ix[L.Flags.fi] end
	function f.ab() return L.Flags.ab == true end
	function f.hf() return L.Flags.hf == true end
	function f.dq() return L.Flags.dq == true end
	function f.bk() return bi[L.Flags.sb] or "truck" end
	function f.iw()
		local j, id, g, b, t, u = ge.__FmI, ix[L.Flags.si], ge.__FmG, ge.__FmR, ge.__FmT, ge.__FmU
		return g and not g.dn and (g.bz or g.rq and not f.bu) or b and not b.dn and (b.bz or b.rq and not f.bu) or j and not j.dn and (j.bz or id and ic() ~= id) or t and not t.dn and t.bz or u and not u.dn and (u.bz or u.rq and not f.bu) or false
	end
	ge.__FmF = f
	task.spawn(function()
		while not f.dn do
			local x = f.nq
			if x then
				f.nq = false
				gw:Notify(x)
			end
			task.wait(0.5)
		end
	end)
	local ok, e = cx(fb, f)
	if not ok then f.why = `Auto Fish Failed: {e}` end
	f.dn = true
	if ge.__FmF ~= f or not f.why then return end
	task.spawn(function()
		local sk, sv = pcall(xt)
		if sk then zx(sv) end
	end)
	gw:Notify({Title = "Auto Fish", Text = f.why})
	ft:Set(false)
end

local function ib(j)
	local n = 0
	while j.st == "Running" do
		local id, fm = ix[L.Flags.si], ge.__FmF
		if not id then j.why = "Auto Island Failed: No Island Selected"; return end
		if ic() == id then j.ar = true; return end
		if not (fm and not fm.dn and fm.bz or ge.__FmG and not ge.__FmG.dn and ge.__FmG.bz) then
			j.bz = true
			local ok, e = ti(j, id, bi[L.Flags.sb] or "truck")
			j.bz = false
			if ok then j.ar = true; return end
			n = j.st == "Running" and n + 1 or n
			if n >= 3 then j.why = `Auto Island Failed: {e}`; return end
		end
		task.wait(1)
	end
end

local it
local function is()
	local o = ge.__FmI
	if o then
		o.st = "Stopped"
		local dl = os.clock() + 5
		repeat task.wait(0.1) until o.dn or os.clock() > dl
	end
	local j = {st = "Running", ar = false}
	ge.__FmI = j
	local ok, e = cx(ib, j)
	if not ok then j.why = `Auto Island Failed: {e}` end
	j.dn = true
	if ge.__FmI ~= j or not (j.why or j.ar) then return end
	if j.why then gw:Notify({Title = "Auto Island", Text = j.why}) end
	it:Set(false)
end

local nz, nl, nj = {
	{"Fish Merchant - Starter Island", "npc_fish_seller", "island_starter"},
	{"Rod Merchant - Starter Island", "npc_rod_shop", "island_starter"},
	{"Boat Merchant - Starter Island", "npc_car_merchant", "island_starter"},
	{"Skill Master", "npc_gacha_book", "island_starter"},
	{"Auras Dealer", "npc_gacha_aura", "island_starter"},
	{"Unit Summoner", "npc_gacha_unit", "island_starter"},
	{"Skill Market", "npc_premium_skill", "island_starter"},
	{"Daily Quests - Starter Island", "npc_daily_quest", "island_starter"},
	{"Jungle Island Guide", "npc_unlock_island_2", "island_jungle"},
	{"Fish Merchant - Jungle Island", "npc_fish_seller", "island_jungle"},
	{"Rod Merchant - Jungle Island", "npc_rod_shop", "island_jungle"},
	{"Boat Merchant - Jungle Island", "npc_car_merchant", "island_jungle"},
	{"Daily Quests - Jungle Island", "npc_daily_quest", "island_jungle"},
	{"Desert Island Guide", "npc_unlock_island_3", "island_desert"},
	{"Fish Merchant - Desert Island", "npc_fish_seller", "island_desert"},
	{"Rod Merchant - Desert Island", "npc_rod_shop", "island_desert"},
	{"Boat Merchant - Desert Island", "npc_car_merchant", "island_desert"},
	{"Daily Quests - Desert Island", "npc_daily_quest", "island_desert"},
	{"White Tiger Guardian", "npc_white_tiger", "island_desert"},
	{"Snow Island Guide", "npc_unlock_island_4", "island_snow"},
	{"Fish Merchant - Snow Island", "npc_fish_seller", "island_snow"},
	{"Rod Merchant - Snow Island", "npc_rod_shop", "island_snow"},
	{"Boat Merchant - Snow Island", "npc_car_merchant", "island_snow"},
	{"Daily Quests - Snow Island", "npc_daily_quest", "island_snow"},
	{"Phoenix Guardian", "npc_phoenix", "island_snow"},
	{"Taiji Master", "npc_taiji_hooking_art_v2", "island_snow"},
	{"Volcanic Island Guide", "npc_unlock_island_5", "island_volcano"},
	{"Fish Merchant - Volcanic Island", "npc_fish_seller", "island_volcano"},
	{"Boat Merchant - Volcanic Island", "npc_car_merchant", "island_volcano"},
	{"Daily Quests - Volcanic Island", "npc_daily_quest", "island_volcano"},
	{"Crimson Bead Craftsman", "npc_crimson_bead_rod", "island_volcano"},
	{"Bamboo Rod Craftsman", "npc_bamboo_rod", "island_volcano"},
	{"Azure Dragon Guardian", "npc_azure_dragon", "island_volcano"},
	{"Fossil Island Guide", "npc_unlock_island_6", "island_fossil"},
	{"Fish Merchant - Fossil Island", "npc_fish_seller", "island_fossil"},
	{"Daily Quests - Fossil Island", "npc_daily_quest", "island_fossil"},
	{"Heaven Piercer Craftsman", "npc_heaven_piercer_turtle_rod", "island_fossil"},
	{"Zen Staff Craftsman", "npc_zen_staff_rod", "island_fossil"},
	{"Dread Fish Craftsman", "npc_dread_fish_rod", "island_fossil"},
	{"Supreme King Guardian", "npc_supreme_king", "island_fossil"},
}, {}, {}
for _, v in nz do
	table.insert(nl, v[1])
	nj[v[1]] = v
end

local function ne(v)
	local w = workspace:FindFirstChild("World")
	local fo = w and w:FindFirstChild("Islands") and w.Islands:FindFirstChild(v[3])
	if not fo then return nil end
	for _, x in game:GetService("CollectionService"):GetTagged("Interactive") do
		if x:GetAttribute("InteractiveId") == v[2] and x:IsDescendantOf(fo) then
			return x:IsA("Model") and x:GetPivot().Position or x:IsA("BasePart") and x.Position or nil
		end
	end
	return nil
end

local function nw(j)
	local v, n = nj[L.Flags.sv], 0
	if not v then j.why = "Teleport Failed: No NPC Selected"; return end
	while j.st == "Running" do
		local fm = ge.__FmF
		if not (fm and not fm.dn and fm.bz or ge.__FmG and not ge.__FmG.dn and ge.__FmG.bz) then
			j.bz = true
			local ok, e = ti(j, v[3], bi[L.Flags.sb] or "truck")
			local c, r = lc()
			local np = ok and r and ne(v)
			if ok and r and not np then
				local g = rg(v[3])
				sq(g and Vector3.new(g.X, 2, g.Z) or r.Position, 10)
				np = ne(v)
			end
			if ok and not r then ok, e = nil, "No Character" end
			if ok and not np then ok, e = nil, "NPC Not Found" end
			if ok and j.st == "Running" then
				local sp = ap(c, np, r.Position, 0)
				ok, e = (v[2] == "npc_zen_staff_rod" and gf or go)(j, sp, Vector3.new(np.X - sp.X, 0, np.Z - sp.Z).Unit)
			end
			j.bz = false
			if ok and j.st == "Running" then j.ar = true; return end
			if e == "NPC Not Found" then j.why = `Teleport Failed: {e}`; return end
			n = j.st == "Running" and n + 1 or n
			if n >= 3 then j.why = `Teleport Failed: {e or "Move Failed"}`; return end
		end
		task.wait(1)
	end
end

local nk
local function ny()
	local o = ge.__FmT
	if o then
		o.st = "Stopped"
		local dl = os.clock() + 5
		repeat task.wait(0.1) until o.dn or os.clock() > dl
	end
	local j = {st = "Running", ar = false}
	ge.__FmT = j
	local ok, e = cx(nw, j)
	if not ok then j.why = `Teleport Failed: {e}` end
	j.dn = true
	if ge.__FmT ~= j or not (j.why or j.ar) then return end
	if j.why then gw:Notify({Title = "Teleport", Text = j.why}) end
	nk:Set(false)
end

local ga, gm = {"Skill Master", "Ocean Chest", "Dragon Chest", "Aura", "Unit"}, {["Ocean Chest"] = "crate_ocean_chest", ["Dragon Chest"] = "crate_dragon_chest"}

local function gl(j)
	local sc = rv.SkillGachaController
	while j.st == "Running" do
		local k, cr = L.Flags.gr == "x10" and 10 or 1, gm[L.Flags.gk]
		local cc = cr and md("Data", "Config", "CrateConfig").GetCrate(cr)
		if cr and not cc then
			j.why = "Auto Roll Failed: No Chest"
			return
		end
		local ag, ut = L.Flags.gk == "Aura" and md("Data", "Config", "AuraGachaConfig").Pull, L.Flags.gk == "Unit" and rv.UnitGachaController
		local nm = cc and cc.DisplayName or ag and "Aura" or ut and "Unit" or "Skill Master"
		local function ca()
			local d = pd()
			if cc then return (((d.CrateGacha or {}).Credits or {})[cr] or 0) >= k or ((cc.Currency == "Coin" and d.Coin or d.Gem) or 0) >= (cc.Prices[k] or math.huge) end
			if ag then return ((d.AuraGacha or {}).Credits or 0) >= k or (d.Gem or 0) >= math.ceil(ag.CostGem * k * (ag.BulkDiscount[k] or 1)) end
			local q = (ut or sc).GetQuote:Fire(k)
			if type(q) ~= "table" or not q.ok then return nil, type(q) == "table" and q.reason or "No Quote" end
			if ut and (q.storage_available or 0) < k then return nil, "Storage Full" end
			return (d.Coin or 0) >= q.coin_cost
		end
		local af, ae = ca()
		if ae then
			j.why = `Auto Roll Failed: {ae}`
			return
		end
		if not af then
			task.wait(5)
			continue
		end
		local fm = ge.__FmF
		j.rq = true
		while j.st == "Running" and fm and not fm.dn and (fm.bz or fm.bu) do task.wait(0.5) end
		if j.st ~= "Running" then return end
		j.bz, j.rq = true, false
		local r
		while j.st == "Running" do
			local rc = ut or not (cc or ag) and sc
			if rc then rc._requestId = (tonumber(rc._requestId) or 0) + 1 end
			r = cc and rv.CrateGachaController.OpenPacket:Fire(cr, k) or ag and rv.AuraGachaController.Pull:Fire(k) or ut and ut.Pull:Fire(k, ut._requestId) or not (cc or ag or ut) and sc.Pull:Fire("Coin", k, sc._requestId)
			for _ = 1, ut and type(r) == "table" and r.reason == "pending" and 5 or 0 do
				task.wait(3)
				local x = ut.Recover:Fire(ut._requestId)
				if type(x) == "table" and x.reason ~= "pending" and x.reason ~= "none" then r = x; break end
			end
			if type(r) ~= "table" or not r.ok then break end
			local ct, t = md("Data", "Catalog"), {}
			for _, x in r.results or {} do
				local sv = cc and ct.RodSkin.GetById(x.rod_skin_id) or ag and ct.Aura.GetById(x.aura_id) or ut and ct.Unit.GetById(x.unit_id) or not (cc or ag or ut) and ct.Skill.GetById(x.skill_id)
				table.insert(t, `{sv and sv.name or x.rod_skin_id or x.aura_id or x.unit_id or x.skill_id} ({x.rarity})`)
			end
			j.nt = {Title = nm, Text = table.concat(t, ", ")}
			task.wait(1)
			if not ca() then break end
		end
		j.bz = false
		if j.st ~= "Running" then return end
		if type(r) ~= "table" then
			j.why = "Auto Roll Failed: No Response"
			return
		end
		if not r.ok and r.reason ~= "insufficient_coin" and r.reason ~= "insufficient_gem" then
			j.why = `Auto Roll Failed: {r.reason}`
			return
		end
		task.wait(1)
	end
end

local gs
local function gg()
	local o = ge.__FmG
	if o then
		o.st = "Stopped"
		local dl = os.clock() + 5
		repeat task.wait(0.1) until o.dn or os.clock() > dl
	end
	local j = {st = "Running", dn = false, nt = false, bz = false, rq = false}
	ge.__FmG = j
	task.spawn(function()
		while not j.dn do
			local x = j.nt
			if x then
				j.nt = false
				gw:Notify(x)
			end
			task.wait(0.5)
		end
	end)
	local ok, e = cx(gl, j)
	if not ok then j.why = `Auto Roll Failed: {e}` end
	j.dn = true
	if ge.__FmG ~= j or not j.why then return end
	gw:Notify({Title = "Auto Roll", Text = j.why})
	gs:Set(false)
end

local mz, mi = {}, {}
pcall(function()
	local ct, t = md("Data", "Catalog"), {}
	for id, v in md("Data", "Config", "SkillMarketConfig").Listings do
		local x = ct.Skill.GetById(id)
		table.insert(t, {x and x.name or id, id, v.price or 0})
	end
	table.sort(t, function(a, b) return a[3] < b[3] or a[3] == b[3] and a[1] < b[1] end)
	for _, x in t do
		table.insert(mz, x[1])
		mi[x[1]] = x[2]
	end
end)

local function ml(j)
	local rp, mc = game:GetService("ReplicatedStorage"), rv.SkillMarketController
	local cf, ba, en, sx = md("Data", "Config", "SkillMarketConfig"), md("Utils", "skillBookAvailability"), md("Data", "Config", "EntitlementConfig"), {}
	while j.st == "Running" do
		local st, ea = rp:GetAttribute("SkillMarketStock"), rp:GetAttribute("SkillMarketEndsAt")
		local sl, kl = type(ea) == "number" and ea - cf.IntervalSeconds or 0, type(st) == "string" and st:split(",") or {}
		for _, nm in L.Flags.mm or {} do
			if j.st ~= "Running" then return end
			local id, d = mi[nm], pd()
			local sm = type(d.SkillMarket) == "table" and d.SkillMarket or {}
			if id and table.find(kl, id) and not sx[`{sl}{id}`] and not (sm.SlotStart == sl and (sm.Bought or {})[id]) and (d.Gem or 0) >= (cf.Price(id) or math.huge) and ba.GetCounts(d, id).owned < en.BookStackCap(d) then
				local r = mc.BuyDirect:Fire(id)
				if type(r) ~= "table" then
					j.why = "Auto Buy Skill Market Failed: No Response"
					return
				end
				if r.reason == "ok" then
					j.nt = {Title = "Skill Market", Text = `Bought {nm}`}
				elseif r.reason == "bought" or r.reason == "out_of_stock" or r.reason == "full" then
					sx[`{sl}{id}`] = true
				elseif r.reason ~= "insufficient" and r.reason ~= "busy" then
					j.why = `Auto Buy Skill Market Failed: {r.reason}`
					return
				end
				task.wait(1)
			end
		end
		task.wait(5)
	end
end

local function xu(j)
	local uc, uo, ct = rv.UnitController, md("Shared", "Units", "UnitCore"), md("Data", "Catalog")
	while j.st == "Running" do
		local d, rr, q = pd(), {}, {}
		for _, r in L.Flags.ur or {} do rr[r] = true end
		for id, u in type(d.Units) == "table" and type(d.Units.Owned) == "table" and d.Units.Owned or {} do
			if type(u) == "table" and rr[u.Rarity] and not uo.IsEquipped(d.Units, id) then table.insert(q, id) end
		end
		if #q > 0 then
			local fm = ge.__FmF
			j.rq = true
			while j.st == "Running" and fm and not fm.dn and (fm.bz or fm.bu) do task.wait(0.5) end
			if j.st ~= "Running" then return end
			j.bz, j.rq = true, false
			local t = {}
			for _, id in q do
				if j.st ~= "Running" then break end
				local u = (pd().Units.Owned or {})[id]
				if u and not uo.IsEquipped(pd().Units, id) then
					local ok, e = uc:RemoveUnit(id)
					if ok ~= true and e ~= "fishing_locked" then
						j.bz = false
						j.why = `Auto Delete Unit Failed: {e or "No Response"}`
						return
					end
					if ok ~= true then break end
					local x = ct.Unit.GetById(u.UnitId)
					table.insert(t, `{x and x.name or u.UnitId} ({u.Rarity})`)
					task.wait(0.5)
				end
			end
			j.bz = false
			if #t > 0 then j.nt = {Title = "Unit", Text = `Deleted {table.concat(t, ", ")}`} end
		end
		task.wait(5)
	end
end

local xk
local function xy()
	local o = ge.__FmU
	if o then
		o.st = "Stopped"
		local dl = os.clock() + 5
		repeat task.wait(0.1) until o.dn or os.clock() > dl
	end
	local j = {st = "Running", dn = false, nt = false, bz = false, rq = false}
	ge.__FmU = j
	task.spawn(function()
		while not j.dn do
			local x = j.nt
			if x then
				j.nt = false
				gw:Notify(x)
			end
			task.wait(0.5)
		end
	end)
	local ok, e = cx(xu, j)
	if not ok then j.why = `Auto Delete Unit Failed: {e}` end
	j.dn = true
	if ge.__FmU ~= j or not j.why then return end
	gw:Notify({Title = "Unit", Text = j.why})
	xk:Set(false)
end

local mk
local function mg()
	local o = ge.__FmM
	if o then
		o.st = "Stopped"
		local dl = os.clock() + 5
		repeat task.wait(0.1) until o.dn or os.clock() > dl
	end
	local j = {st = "Running", dn = false, nt = false}
	ge.__FmM = j
	task.spawn(function()
		while not j.dn do
			local x = j.nt
			if x then
				j.nt = false
				gw:Notify(x)
			end
			task.wait(0.5)
		end
	end)
	local ok, e = cx(ml, j)
	if not ok then j.why = `Auto Buy Skill Market Failed: {e}` end
	j.dn = true
	if ge.__FmM ~= j or not j.why then return end
	gw:Notify({Title = "Skill Market", Text = j.why})
	mk:Set(false)
end

local rz, ri = {}, {}
for _, x in {{"Stone Rod", "stone_rod"}, {"Iron Rod", "iron_rod"}, {"Golden Rod", "golden_rod"}, {"Steel Rod", "steel_rod"}, {"Golden Steel Rod", "golden_steel_rod"}, {"Diamond Steel Rod", "diamond_steel_rod"}, {"Taoist Rod", "taoist_rod"}, {"Legacy Rod", "legacy_rod"}} do
	table.insert(rz, x[1])
	ri[x[1]] = x[2]
end

local function rm(id)
	for k = 1, 2 do
		for _, x in game:GetService("CollectionService"):GetTagged("Interactive") do
			if x:GetAttribute("InteractiveId") == "npc_rod_shop" and x:GetAttribute("IslandId") == id then
				local q = x:IsA("Model") and x:GetPivot().Position or x:IsA("BasePart") and x.Position
				if q then return q end
			end
		end
		local g = k == 1 and rg(id)
		if g then sq(Vector3.new(g.X, 2, g.Z), 10) end
	end
	return nil
end

local function ru(j, id, il)
	local ok, e = ti(j, il, bi[L.Flags.sb] or "truck")
	if not ok then return nil, e or j.st == "Running" and "Move Failed" or nil end
	local c, rt = lc()
	if not rt then return nil, "No Character" end
	local np = rm(il)
	if not np then return nil, "No Rod Merchant" end
	local sp = ap(c, np, rt.Position)
	ok, e = go(j, sp, Vector3.new(np.X - sp.X, 0, np.Z - sp.Z).Unit)
	if not ok then return nil, e or j.st == "Running" and "Move Failed" or nil end
	if j.st ~= "Running" then return nil end
	local r = rv.FishingRodShopController.PurchaseRod:Fire(id)
	if r == nil then return nil, "No Response" end
	if r ~= true then return nil, "Purchase Refused" end
	j.by = true
	if rv.EquipmentsController.EquipmentEquip:Fire("rod", id) ~= true then return nil, "Equip Refused" end
	local dl = os.clock() + 5
	repeat task.wait(0.1) until pd().RodEquip == id or os.clock() > dl
	if pd().RodEquip ~= id then return nil, "Equip Timeout" end
	return true
end

local function rj(j)
	local nm = L.Flags.rd
	local id = ri[nm]
	if not id then j.why = "Auto Buy Rod Failed: No Rod Selected"; return end
	local cf = md("Data", "Config", "RodShopConfig")[id]
	if not cf then j.why = "Auto Buy Rod Failed: No Price"; return end
	while j.st == "Running" do
		local d = pd()
		if d.Rods and d.Rods[id] then j.why = "Auto Buy Rod Failed: Already Owned"; return end
		if not ul(cf.islandId) then j.why = "Auto Buy Rod Failed: Island Locked"; return end
		if (d.Coin or 0) < cf.price then
			task.wait(5)
			continue
		end
		local fm = ge.__FmF
		j.rq = true
		while j.st == "Running" and (fm and not fm.dn and (fm.bz or fm.bu) or ge.__FmG and not ge.__FmG.dn and ge.__FmG.bz or ge.__FmI and not ge.__FmI.dn or ge.__FmT and not ge.__FmT.dn) do task.wait(0.5) end
		if j.st ~= "Running" then return end
		j.bz, j.rq = true, false
		local _, rt = lc()
		if not rt then j.why = "Auto Buy Rod Failed: No Character"; return end
		local o, oi = rt.CFrame, ic()
		local ok, e = ru(j, id, cf.islandId)
		local hk, he = true, nil
		if j.st == "Running" and oi ~= "" and ic() ~= oi then hk, he = ti(j, oi, bi[L.Flags.sb] or "truck") end
		if hk and j.st == "Running" and ic() == oi then hk, he = go(j, o.Position, Vector3.new(o.LookVector.X, 0, o.LookVector.Z).Unit) end
		j.bz = false
		if j.st ~= "Running" then return end
		local t = ok and `Bought {nm}` or j.by and `Bought {nm}, {e}` or `Auto Buy Rod Failed: {e}`
		j.why = hk and t or `{t}, Return Failed: {he or "Move Failed"}`
		return
	end
end

local rk
local function rh()
	local o = ge.__FmR
	if o then
		o.st = "Stopped"
		local dl = os.clock() + 5
		repeat task.wait(0.1) until o.dn or os.clock() > dl
	end
	local j = {st = "Running", dn = false, bz = false, rq = false, by = false}
	ge.__FmR = j
	local ok, e = cx(rj, j)
	if not ok then j.why = `Auto Buy Rod Failed: {e}` end
	j.dn = true
	if ge.__FmR ~= j or not j.why then return end
	gw:Notify({Title = "Rod Merchant", Text = j.why})
	rk:Set(false)
end

gt:Section({Name = "Farm"})
do
	local bl, tk = gt:Label({Text = "Next Boss: --"}), {}
	ge.__FmL = tk
	task.spawn(function()
		local ok, en, iv = cx(function()
			local d, n = md("Data", "Catalog", "Fish"), {}
			for k, v in md("Data", "Catalog", "Boss").Pools do
				if v[1] and d[v[1].id] then n[k] = d[v[1].id].name end
			end
			return n, md("Data", "Catalog", "Event").Constant.OCCURRENCE_INTERVAL
		end)
		if not ok or type(iv) ~= "number" then
			bl:Set("Next Boss: Unknown")
			return
		end
		while ge.__FmL == tk do
			local t, ek, ex = workspace:GetServerTimeNow(), nil, 0
			local ev = rv.EventController and rv.EventController._active_events
			for k, v in type(ev) == "table" and ev or {} do
				if en[k] then ek, ex = k, math.max(v.expire_at or 0, v.admin_override_expire_at or 0) end
			end
			local lf = math.max(0, math.floor((ek and ex or (t // iv + 1) * iv) - t))
			bl:Set(ek and `Boss Up: {en[ek]} - {lf // 60}:{string.format("%02d", lf % 60)} Left` or `Next Boss: {os.date("%H:%M", math.floor((t // iv + 1) * iv))} - In {lf // 60}:{string.format("%02d", lf % 60)}`)
			task.wait(1)
		end
	end)
end
gt:Dropdown({Name = "Select Farm Island", Options = {"Current Island", table.unpack(iz)}, Default = "Current Island", Flag = "fi"})
ft = gt:Toggle({Name = "Auto Fish", Flag = "af", Callback = function(v)
	local o = ge.__FmF
	if v then
		fs()
	elseif o then
		if o.bz and (o.s.fp or o.s.rl) and not (o.s.cr or o.s.rr) then o.fq = true else o.st = "Stopped" end
	end
end})
gt:Toggle({Name = "Auto Boss", Flag = "ab"})

gt:Section({Name = "Quest"})
gt:Dropdown({Name = "Select Rod Quest", Options = qz, Flag = "qs"})
gt:Toggle({Name = "Auto Rod Quest", Flag = "qa"})
gt:Toggle({Name = "Auto Unlock Island", Flag = "au"})
gt:Toggle({Name = "Auto Daily Quest", Flag = "dq"})

gt:Section({Name = "Soul"})
gt:Dropdown({Name = "Select Soul Quest", Options = qgz, Default = {}, Multi = true, Flag = "ys"})
gt:Toggle({Name = "Auto Soul Quest", Flag = "ya"})

gt:Section({Name = "Sell"})
gt:Dropdown({Name = "Sell Rarity", Options = ra, Default = {}, Multi = true, Flag = "sr"})
gt:Toggle({Name = "Auto Sell", Flag = "as"})

local tz, qtx = gw:Tab({Name = "Status", Icon = "rbxassetid://125235305885604"}), `Iq{game:GetService("HttpService"):GenerateGUID(false)}`
tz:Section({Name = "Island Quest"})
local iql = tz:Label({Text = qtx})
local rtx = `Rq{game:GetService("HttpService"):GenerateGUID(false)}`
tz:Section({Name = "Rod Quest"})
local rql = tz:Label({Text = rtx})
local ytx = `Yq{game:GetService("HttpService"):GenerateGUID(false)}`
tz:Section({Name = "Soul Quest"})
local yql = tz:Label({Text = ytx})
tz:Section({Name = "Skill Market"})
local kql = tz:Label({Text = "Loading..."})

local tm = gw:Tab({Name = "Misc", Icon = "rbxassetid://137813242924560"})
tm:Section({Name = "Unit"})
tm:Dropdown({Name = "Delete Rarity", Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical"}, Default = {}, Multi = true, Flag = "ur"})
xk = tm:Toggle({Name = "Auto Delete Unit", Flag = "ua", Callback = function(v)
	if v then xy() elseif ge.__FmU then ge.__FmU.st = "Stopped" end
end})

local tq = gw:Tab({Name = "Shop", Icon = "rbxassetid://95128643065405"})
tq:Section({Name = "Gacha"})
tq:Dropdown({Name = "Select Gacha", Options = ga, Default = "Skill Master", Flag = "gk"})
tq:Dropdown({Name = "Select Roll", Options = {"x1", "x10"}, Default = "x1", Flag = "gr"})
gs = tq:Toggle({Name = "Auto Roll", Flag = "gs", Callback = function(v)
	if v then gg() elseif ge.__FmG then ge.__FmG.st = "Stopped" end
end})
tq:Section({Name = "Skill Market"})
tq:Dropdown({Name = "Select Skills", Options = mz, Default = {}, Multi = true, Flag = "mm"})
mk = tq:Toggle({Name = "Auto Buy Skill Market", Flag = "ma", Callback = function(v)
	if v then mg() elseif ge.__FmM then ge.__FmM.st = "Stopped" end
end})
tq:Section({Name = "Rod"})
tq:Dropdown({Name = "Select Rod", Options = rz, Flag = "rd"})
rk = tq:Toggle({Name = "Auto Buy Rod", Flag = "rb", Callback = function(v)
	if v then
		if it then it:Set(false) end
		if nk then nk:Set(false) end
		rh()
	elseif ge.__FmR then ge.__FmR.st = "Stopped" end
end})

local tl = gw:Tab({Name = "Teleport", Icon = "rbxassetid://116165046950286"})
tl:Section({Name = "Island"})
tl:Dropdown({Name = "Select Island", Options = iz, Flag = "si"})
it = tl:Toggle({Name = "Auto Island", Flag = "ai", Callback = function(v)
	if v then
		if rk then rk:Set(false) end
		if nk then nk:Set(false) end
		is()
	elseif ge.__FmI then ge.__FmI.st = "Stopped" end
end})
tl:Section({Name = "NPC"})
tl:Dropdown({Name = "Select NPC", Options = nl, Flag = "sv"})
nk = tl:Toggle({Name = "Teleport To NPC", Flag = "tv", Callback = function(v)
	if v then
		if it then it:Set(false) end
		if rk then rk:Set(false) end
		ny()
	elseif ge.__FmT then ge.__FmT.st = "Stopped" end
end})

local ez, eo = {cs = {}, o = {}, w = {}}, nil
do
	local ov = ge.__FmV
	if ov then
		ov.w = {}
		if ov.rw then pcall(ov.rw) end
		for _, c in ov.cs do c:Disconnect() end
	end
	ge.__FmV = ez
	for _, n in {"RodSkinId", "AuraCatalogId"} do
		if ov then ez.o[n] = ov.o[n] else ez.o[n] = lp:GetAttribute(n) end
		table.insert(ez.cs, lp:GetAttributeChangedSignal(n):Connect(function()
			local v = lp:GetAttribute(n)
			if v == ez.w[n] then return end
			ez.o[n] = v
			if ez.w[n] then lp:SetAttribute(n, ez.w[n]) end
		end))
	end
	local et, an = 0, "AuraCatalogId"
	table.insert(ez.cs, game:GetService("RunService").Heartbeat:Connect(function()
		if not ez.w[an] or os.clock() < et then return end
		et = os.clock() + 0.25
		local c = lp.Character
		local fx = c and c:FindFirstChild("ClientAuraEffect")
		for _, d in fx and fx:GetDescendants() or {} do
			if d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") or d:IsA("Light") or d:IsA("Highlight") then
				if not d.Enabled then d.Enabled = true end
			elseif d:IsA("BasePart") and d.LocalTransparencyModifier ~= 0 then
				d.LocalTransparencyModifier = 0
			end
		end
	end))
	local sn, ac, ah, zo = "RodSkinId", {}, nil, {}
	local function rw(t)
		local sk, df, nm = ez.w[sn], eo and eo[3], ah
		local r = sk and df and nm and df[1](t.Name, df[2][sk])
		if not r or r.id == t.Animation.AnimationId then return end
		local n = ac[r.id]
		if not n then
			local an2 = Instance.new("Animation")
			an2.AnimationId = r.id
			local ok, x = pcall(nm.LoadAnimation, nm, an2)
			if not ok or not x then return end
			n, ac[r.id] = x, x
		end
		n.Priority, n.Looped = r.priority, r.looped
		t:AdjustWeight(0.001, 0)
		zo[t] = n
		n:Play(r.fadeTime, 1, r.playbackSpeed)
		local c1
		c1 = t.Stopped:Connect(function()
			c1:Disconnect()
			if zo[t] ~= n then return end
			zo[t] = nil
			for _, n2 in zo do
				if n2 == n then return end
			end
			n:Stop(r.fadeTime)
		end)
	end
	local function hk2(c)
		local h = c and c:WaitForChild("Humanoid", 10)
		local nm = h and h:WaitForChild("Animator", 10)
		if not nm or ge.__FmV ~= ez then return end
		ah, ac, zo = nm, {}, {}
		table.insert(ez.cs, nm.AnimationPlayed:Connect(rw))
	end
	table.insert(ez.cs, lp.CharacterAdded:Connect(hk2))
	task.spawn(hk2, lp.Character)
	ez.rw = function()
		for t, n in zo do
			pcall(function() n:Stop(0.15); t:AdjustWeight(1, 0.15) end)
		end
		zo = {}
		for _, t in ah and ah:GetPlayingAnimationTracks() or {} do
			if t.WeightTarget > 0 then rw(t) end
		end
	end
	local ok, a, b, rz2 = cx(function()
		local ct, rk, sa2 = md("Data", "Catalog"), {}, {}
		for _, v in ct.RodSkin.GetAll() do
			if type(v) == "table" and type(v.id) == "string" then sa2[v.id] = v.animations end
		end
		for i, r in ra do rk[r] = i end
		local function bl(t)
			local l, m, n = {}, {}, {"Default"}
			for _, v in t.GetAll() do
				if type(v) == "table" and type(v.name) == "string" and type(v.id) == "string" then table.insert(l, v); m[v.name] = v.id end
			end
			table.sort(l, function(x, y)
				local p, q = rk[x.rarity] or 0, rk[y.rarity] or 0
				if p ~= q then return p > q end
				return x.name < y.name
			end)
			for _, v in l do table.insert(n, v.name) end
			return {n, m}
		end
		return bl(ct.RodSkin), bl(ct.Aura), {md("Data", "Config", "RodAnimationConfig").Resolve, sa2}
	end)
	if ok then eo = {a, b, rz2} else gw:Notify({Title = "Visual", Text = "Effect List Failed: Catalog Error"}) end
end

local function ep(n, id)
	ez.w[n] = id
	lp:SetAttribute(n, id or ez.o[n])
	if ez.rw then ez.rw() end
end

if eo then
	local tv = gw:Tab({Name = "Visual", Icon = "rbxassetid://105107872623903"})
	tv:Section({Name = "Effect"})
	tv:Dropdown({Name = "Rod Skin", Options = eo[1][1], Default = "Default", Flag = "es", Callback = function(v) ep("RodSkinId", eo[1][2][v]) end})
	tv:Dropdown({Name = "Aura", Options = eo[2][1], Default = "Default", Flag = "ea", Callback = function(v) ep("AuraCatalogId", eo[2][2][v]) end})
end

local function zp()
	if ge.__FmP then return nil, "Already On" end
	ge.__FmP = true
	local sc, lt, tr, oc = rv.SettingsController, game:GetService("Lighting"), workspace.Terrain, workspace:FindFirstChild("Ocean")
	local ul = true
	for k, v in {ultra_low_graphic = true, show_others_vfx = false, show_my_vfx = false, show_cutscenes = false, show_damage_indicator = false, camera_shaking = false, auto_fishing_hide_vfx = true} do
		if not (sc and sc._SetLocal and pcall(sc._SetLocal, sc, k, v)) then ul = false end
	end
	local function ko(d)
		d.Enabled = false
		d:GetPropertyChangedSignal("Enabled"):Connect(function() if d.Enabled then d.Enabled = false end end)
	end
	local function lf()
		if lt.GlobalShadows then lt.GlobalShadows = false end
		if lt.FogEnd < 1e9 then lt.FogEnd = 1e9 end
	end
	local function kx(d)
		if d:IsA("PostEffect") then
			ko(d)
		elseif d:IsA("Atmosphere") then
			local function z() if d.Density ~= 0 or d.Haze ~= 0 or d.Glare ~= 0 then d.Density, d.Haze, d.Glare = 0, 0, 0 end end
			z()
			d.Changed:Connect(z)
		end
	end
	local function px(d)
		if d == tr or oc and d:IsDescendantOf(oc) then return end
		if d:IsA("ParticleEmitter") then
			d.Lifetime = NumberRange.new(0)
			ko(d)
		elseif d:IsA("Beam") or d:IsA("Trail") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") or d:IsA("Light") or d:IsA("Highlight") then
			ko(d)
		elseif d:IsA("Decal") then
			d.Transparency = 1
		elseif d:IsA("SurfaceAppearance") then
			task.defer(pcall, d.Destroy, d)
		elseif d:IsA("BasePart") and d.Material ~= Enum.Material.Water then
			d.Material, d.Reflectance, d.CastShadow = Enum.Material.SmoothPlastic, 0, false
		end
	end
	lf()
	lt:GetPropertyChangedSignal("GlobalShadows"):Connect(lf)
	lt:GetPropertyChangedSignal("FogEnd"):Connect(lf)
	for _, d in lt:GetChildren() do pcall(kx, d) end
	lt.ChildAdded:Connect(function(d) pcall(kx, d) end)
	pcall(function() tr.WaterWaveSize, tr.WaterWaveSpeed, tr.WaterReflectance = 0, 0, 0 end)
	workspace.DescendantAdded:Connect(function(d) pcall(px, d) end)
	task.spawn(function()
		for i, d in workspace:GetDescendants() do
			pcall(px, d)
			if i % 2000 == 0 then task.wait() end
		end
	end)
	if not ul then return nil, "Game Settings Failed: Settings Error" end
	return true
end

local ts = gw:Tab({Name = "Setting", Icon = "rbxassetid://138794268715403"})
ts:Section({Name = "Game"})
ts:Dropdown({Name = "Select Boat", Options = bn, Default = "Truck", Flag = "sb"})
ts:Toggle({Name = "Instant Teleport", Default = true, Flag = "wb", Callback = function(v) wb.on = v == true end})
ts:Toggle({Name = "Safe", Flag = "zy", Callback = function(v) zy.on = v == true end})
ts:Toggle({Name = "Hidden Fishing", Flag = "hf"})
local jr = false
pcall(function() ge.__FmJ:Disconnect() end)
ge.__FmJ = (game:GetService("GuiService") :: any).ErrorMessageChanged:Connect(function(m)
	if jr or type(m) ~= "string" or m == "" then return end
	if os.clock() - zy.hp < 30 then
		zx(`[Rejoin] Ignored During Hop: {m}`, true)
		return
	end
	jr = true
	zx(`[Rejoin] Kicked: {m}`, true)
	task.spawn(function()
		local tp = game:GetService("TeleportService")
		while true do
			pcall(tp.Teleport, tp, game.PlaceId, lp)
			task.wait(10)
		end
	end)
end)
local zl = {}
ge.__FmZ = zl
task.spawn(function()
	while ge.__FmZ == zl do
		task.wait(0.5)
		local sk, se = pcall(function()
			local f, ok, w = ge.__FmF, true, false
			if zy.on and os.clock() >= zy.nt then ok, w = cx(zw) end
			if not (ok and w) then
				zy.rq = false
			elseif f and not f.dn and f.st == "Running" then
				zy.rq = true
			else
				gw:Notify({Title = "Safe", Text = "Player On Island, Hopping"})
				local _, e = zh()
				if e then zx(`[Safe] {e}`, true) end
				gw:Notify({Title = "Safe", Text = e})
			end
		end)
		if not sk then zx(`[Safe] Loop Error: {se}`) end
	end
end)
ts:Button({Name = "FPS Booster", Callback = function()
	local ok, e = zp()
	gw:Notify({Title = "FPS Booster", Text = ok and "On Until Rejoin" or e})
end})

local rx = "LunarX-Hub"

local function nt()
	for _, c in ge.__FmN or {} do c:Disconnect() end
	local cs, tx, gr = {}, rx, {}
	ge.__FmN = cs
	local function hk(m)
		task.spawn(function()
			local p = m:WaitForChild("PlrName", 10)
			local s = p and p:WaitForChild("Surface", 10)
			local l = s and s:WaitForChild("Label", 10)
			if not l or ge.__FmN ~= cs then return end
			if m.Name == lp.Name then
				local o = `@{lp.Name}`
				if l.Text ~= o then l.Text = o end
				if l:FindFirstChild("Rb") then l.Rb:Destroy() end
				local lo = l
				lo.TextTransparency, lo.TextStrokeTransparency = 1, 1
				for _, n in {"TextTransparency", "TextStrokeTransparency"} do
					table.insert(cs, lo:GetPropertyChangedSignal(n):Connect(function() if lo[n] ~= 1 then lo[n] = 1 end end))
				end
				local fd = l:FindFirstChild("Fade")
				if fd and fd:IsA("GuiObject") then
					fd.Visible = false
					table.insert(cs, fd:GetPropertyChangedSignal("Visible"):Connect(function() if fd.Visible then fd.Visible = false end end))
				end
				if s:FindFirstChild("Rx") then s.Rx:Destroy() end
				local tp = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
				for _, n in {"UIs", "Prefabs", "Nametag", "PlrName", "Surface", "Label"} do tp = tp and tp:FindFirstChild(n) end
				local cl = (tp and tp:IsA("TextLabel") and tp or l):Clone()
				for _, x in cl:GetChildren() do
					if x.Name == "Rb" then x:Destroy() elseif x.Name == "Fade" and x:IsA("GuiObject") then x.Visible = true end
				end
				cl.Name, cl.TextTransparency, cl.TextStrokeTransparency, cl.Parent = "Rx", 0, 0, s
				l = cl
			end
			l.Text = tx
			table.insert(cs, l:GetPropertyChangedSignal("Text"):Connect(function() if l.Text ~= tx then l.Text = tx end end))
			local g = l:FindFirstChild("Rb") or Instance.new("UIGradient")
			g.Name, g.Parent = "Rb", l
			gr[g] = true
		end)
	end
	local nf = workspace:FindFirstChild("Nametags")
	if not nf then return end
	table.insert(cs, game:GetService("RunService").Heartbeat:Connect(function()
		local p, k = os.clock() * 0.25, {}
		for i = 0, 9 do k[i + 1] = ColorSequenceKeypoint.new(i / 9, Color3.fromHSV((i / 9 - p) % 1, 1, 1)) end
		local q = ColorSequence.new(k)
		for g in gr do
			if g.Parent then g.Color = q else gr[g] = nil end
		end
	end))
	table.insert(cs, nf.ChildAdded:Connect(hk))
	for _, m in nf:GetChildren() do hk(m) end
end

nt()

task.spawn(function()
	for _ = 1, 3 do
		if sa() >= 12 then return end
		task.wait(5)
	end
	gw:Notify({Title = "Auto Boss", Text = "Boss Scan Failed: Regions Missing"})
end)

if ge.__FmA then ge.__FmA:Disconnect() end
ge.__FmA = lp.Idled:Connect(function()
	local vu = game:GetService("VirtualUser")
	vu:CaptureController()
	vu:ClickButton2(Vector2.new())
end)

do
	local nc = rv.NotificationController
	if type(nc) == "table" and type(nc.Push) == "function" then
		local op = ge.__FmNo or nc.Push
		ge.__FmNo = op
		nc.Push = function(s, t, ...)
			if type(t) == "string" and (t == "Left the region" or t:sub(1, 8) == "Entered ") then return end
			return op(s, t, ...)
		end
	end
end

if ge.__FmTt then ge.__FmTt:Disconnect() end
lp:SetAttribute("PLR_TITLE", "tester")
ge.__FmTt = lp:GetAttributeChangedSignal("PLR_TITLE"):Connect(function()
	if lp:GetAttribute("PLR_TITLE") ~= "tester" then lp:SetAttribute("PLR_TITLE", "tester") end
end)

do
	local wk = {}
	ge.__FmW = wk
	task.spawn(function()
		local t0
		while ge.__FmW == wk do
			local h, ht = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid"), rv.HeldToolController
			if ht and h and h.Health > 0 and not ht:IsReady() then
				t0 = t0 or os.clock()
				if os.clock() - t0 >= 5 then
					t0 = nil
					pcall(function() ht.BackpackReady.OnClientEvent:Fire() end)
					zx("[Hotbar] Ready Flag Stuck, Repaired")
				end
			else
				t0 = nil
			end
			task.wait(1)
		end
	end)
end

do
	local o = ge.__FmS
	if o then
		o.on = false
		pcall(function() o.t:Stop(0) end)
		pcall(function() o.h:Stop(0) end)
	end
	local sk = {on = true, t = nil :: any, h = nil :: any}
	ge.__FmS = sk
	task.spawn(function()
		local an, ah
		while sk.on do
			local hm = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
			local a = hm and hm.Health > 0 and hm:FindFirstChildOfClass("Animator")
			if a and (a ~= an or not (sk.t and sk.t.IsPlaying)) then
				pcall(function()
					local x = Instance.new("Animation")
					x.AnimationId = "rbxassetid://180435571"
					if sk.t and an == a then sk.t:Destroy() end
					sk.t, an = a:LoadAnimation(x), a
					sk.t.Looped, sk.t.Priority = true, Enum.AnimationPriority.Core
					sk.t:Play(0, 0.01, 0.37)
				end)
			end
			local fm = ge.__FmF
			local hw = L.Flags.hf == true and fm and not fm.dn and fm.st == "Running"
			if hw and a and (a ~= ah or not (sk.h and sk.h.IsPlaying)) then
				pcall(function()
					local x = Instance.new("Animation")
					x.AnimationId = "rbxassetid://180435571"
					if sk.h and ah == a then sk.h:Destroy() end
					sk.h, ah = a:LoadAnimation(x), a
					sk.h.Looped, sk.h.Priority = true, Enum.AnimationPriority.Core
					sk.h:Play(0, 0.01, 0.41)
				end)
			elseif not hw and sk.h then
				pcall(function() sk.h:Stop(0) end)
				sk.h, ah = nil, nil
			end
			task.wait(0.5)
		end
	end)
end

do
	local o = ge.__FmHd
	if o then
		o.on = false
		o.rs()
	end
	local hh = {on = true, v = {}}
	function hh.rs()
		for d, v in hh.v do pcall(function() d[v[1]] = v[2] end) end
		hh.v = {}
	end
	ge.__FmHd = hh
	task.spawn(function()
		while hh.on do
			pcall(function()
				local nf, sn = workspace:FindFirstChild("Nametags"), {}
				for _, p in ps:GetPlayers() do
					if p ~= lp and zq(p) then
						for _, m in {p.Character, nf and nf:FindFirstChild(p.Name)} do
							for _, d in m and m:GetDescendants() or {} do
								local k = (d:IsA("BasePart") or d:IsA("Decal")) and "LocalTransparencyModifier" or (d:IsA("Beam") or d:IsA("Trail") or d:IsA("ParticleEmitter") or d:IsA("LayerCollector") or d:IsA("Highlight")) and "Enabled"
								if k then
									if not hh.v[d] then hh.v[d] = {k, d[k]} end
									d[k] = k ~= "Enabled" and 1 or false
									sn[d] = true
								end
							end
						end
					end
				end
				for d, v in hh.v do
					if not sn[d] then
						pcall(function() d[v[1]] = v[2] end)
						hh.v[d] = nil
					end
				end
			end)
			task.wait(0.25)
		end
	end)
end

local function bh()
	for _, x in ge.__FmB or {} do
		pcall(function() x:Disconnect() end)
		pcall(function() x:Destroy() end)
	end
	local cs, fc = {}, rv.FishingController
	ge.__FmB = cs
	local ok, en, bd = cx(function()
		local fs2, n, d = md("Data", "Catalog", "Fish"), {}, {}
		for id, v in fs2 do
			if type(v) == "table" and type(v.name) == "string" then d[id] = {v.name, v.kind == "Boss"} end
		end
		for k, v in md("Data", "Catalog", "Boss").Pools do
			if v[1] and d[v[1].id] then n[k] = d[v[1].id][1] end
		end
		return n, d
	end)
	if not ok then return end
	local sr = lp.PlayerGui:WaitForChild("SessionInfo", 10)
	if not (sr and sr:FindFirstChild("Holder")) then return end
	local sg = sr:Clone()
	for _, x in sg:GetDescendants() do
		if x:IsA("LuaSourceContainer") then x:Destroy() end
	end
	sg.Name, sg.ResetOnSpawn, sg.DisplayOrder, sg.Enabled = game:GetService("HttpService"):GenerateGUID(false), false, 10, true
	local h = sg.Holder
	local hp, fn = h:FindFirstChild("FishHP"), h:FindFirstChild("FishName")
	local fi, ht = hp and hp:FindFirstChild("Fill"), hp and hp:FindFirstChild("HealthText")
	if not (fn and fi and ht) then return end
	for _, n in {"Tension", "FinisherGate", "EscapeSign"} do
		local x = h:FindFirstChild(n)
		if x then x.Visible = false end
	end
	for _, n in {"MaxHealthReduced", "MaxHealthReducedGate"} do
		local x = hp:FindFirstChild(n)
		if x then x.Visible = false end
	end
	local g1, g2, f0, tw = fi:FindFirstChild("Normal"), fi:FindFirstChild("BossPhase2"), fi.BackgroundColor3, game:GetService("TweenService")
	local px, po, pv, sv, fs = h.Position.X.Scale, h.Position.X.Offset, h.Position.Y.Offset, false, -1
	h.Position, h.Visible, fn.Visible = UDim2.new(px, po, -0.2, pv), false, true
	if not pcall(function() sg.Parent = gethui() end) then sg.Parent = lp.PlayerGui end
	table.insert(cs, sg)
	local function sl(v)
		if v == sv then return end
		sv = v
		if v then h.Visible = true end
		local t = tw:Create(h, TweenInfo.new(0.35, Enum.EasingStyle.Quint, v and Enum.EasingDirection.Out or Enum.EasingDirection.In), {Position = UDim2.new(px, po, v and 0.1 or -0.2, pv)})
		t.Completed:Connect(function() if not sv then h.Visible = false end end)
		t:Play()
	end
	local st, im, nr, iy, kh = nil, nil, 0, {}, false
	for n, v in ix do iy[v] = n end
	local function nf(n)
		return (tostring(math.floor(n + 0.5)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
	end
	table.insert(cs, fc.FishFirstPullStart.OnClientEvent:Connect(function(id, hp, mx) st = {bd[id] and bd[id][1] or tostring(id), hp, mx, 1, bd[id] and bd[id][2]} end))
	table.insert(cs, fc.FishReelStartAck.OnClientEvent:Connect(function(id, hp, mx) if not st then st = {bd[id] and bd[id][1] or tostring(id), hp, mx, 1, bd[id] and bd[id][2]} end end))
	table.insert(cs, fc.FishReelHPUpdate.OnClientEvent:Connect(function(hp) if st then st[2] = hp end end))
	table.insert(cs, fc.FishReelPhaseHP.OnClientEvent:Connect(function(hp, mx) if st then st[2], st[3], st[4] = hp, mx, 2 end end))
	table.insert(cs, fc.FishCatchResult.OnClientEvent:Connect(function() st = nil end))
	table.insert(cs, fc.FishReset.OnClientEvent:Connect(function() st = nil end))
	table.insert(cs, game:GetService("RunService").RenderStepped:Connect(function()
		pcall(function()
			local ev, ek, ex = rv.EventController and rv.EventController._active_events, nil, 0
			for k, v in type(ev) == "table" and ev or {} do
				if en[k] then ek, ex = k, math.max(v.expire_at or 0, v.admin_override_expire_at or 0) end
			end
			local gh = sr.Parent and sr:FindFirstChild("Holder")
			sl((ek ~= nil or st ~= nil) and not (gh and gh.Visible))
			if not sv then return end
			if os.clock() >= nr then
				nr, im = os.clock() + 1, nil
				task.spawn(function()
					local o, v = pcall(function() return (tonumber(pd().LastBossKillSlot) or 0) >= workspace:GetServerTimeNow() // 2400 * 2400 end)
					kh = o and v == true
				end)
				for _, x in game:GetService("CollectionService"):GetTagged("BossRegion") do
					local fx = x:FindFirstChild("BossSpawnerFX")
					if fx and fx:GetAttribute("BossSpawnerFXActive") == true and x.Parent and x.Parent.Parent then im = iy[x.Parent.Parent.Name] or x.Parent.Parent.Name end
				end
			end
			local lf, bo2 = math.floor(ex - workspace:GetServerTimeNow()), ek ~= nil and (not st or st[5])
			fn.Text = (st and st[1] or en[ek] or "Boss") .. (bo2 and im and ` - {im}` or "")
			if st then
				local f = math.clamp(st[2] / math.max(st[3], 1), 0, 1)
				if f ~= fs then
					fs = f
					tw:Create(fi, TweenInfo.new(0.15), {Size = UDim2.fromScale(f, 1)}):Play()
				end
				fi.BackgroundColor3 = f0
				if g1 then g1.Enabled = st[4] < 2 end
				if g2 then g2.Enabled = st[4] >= 2 end
				ht.Text = `{nf(st[2])} / {nf(st[3])}`
			else
				if fs ~= 1 then
					fs = 1
					tw:Create(fi, TweenInfo.new(0.15), {Size = UDim2.fromScale(1, 1)}):Play()
				end
				local hd = kh and ek ~= nil
				fi.BackgroundColor3 = hd and Color3.fromRGB(96, 165, 110) or Color3.fromRGB(70, 70, 80)
				if g1 then g1.Enabled = false end
				if g2 then g2.Enabled = false end
				ht.Text = hd and "Hunted" or lf > 0 and string.format("Not Hooked - %d:%02d", lf // 60, lf % 60) or "Not Hooked"
			end
		end)
	end))
end

task.spawn(bh)

local function iq()
	local o = ge.__FmQ
	if o then
		o.on = false
		pcall(function() o.sg:Destroy() end)
	end
	local tk, lb, rb, ylb = {on = true}, nil, nil, nil
	ge.__FmQ = tk
	local ok0, hu = pcall(gethui)
	for _, rt in {ok0 and hu or lp.PlayerGui, lp.PlayerGui} do
		for _, x in rt:GetDescendants() do
			if x:IsA("TextLabel") and x.Text == qtx then lb = x end
			if x:IsA("TextLabel") and x.Text == rtx then rb = x end
			if x:IsA("TextLabel") and x.Text == ytx then ylb = x end
		end
		if lb then break end
	end
	if lb then lb.RichText = true end
	if rb then rb.RichText = true end
	if ylb then ylb.RichText = true end
	iql:Set("Loading...")
	rql:Set("Loading...")
	yql:Set("Loading...")
	local iy = {}
	for n, v in ix do iy[v] = n end
	local function nf(v)
		return (tostring(math.floor(v + 0.5)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
	end
	local function kg(v)
		return v >= 100 and `{nf(v)} kg` or `{string.format("%.1f", v)} kg`
	end
	local qf = {
		crimson_bead_rod = {RequiredFished = 100, RequiredCoin = 3000000},
		bamboo_rod = {RequiredBamboo = 20, RequiredCoin = 3600000},
		heaven_piercer_turtle_rod = {RequiredFish = 5, RequiredCoin = 5000000},
		zen_staff_rod = {RequiredFish = 5, RequiredCoin = 5000000},
		dread_fish_rod = {RequiredFish = 1, RequiredCoin = 10000000},
		taiji_hooking_art_v2 = {RequiredKills = 100, RequiredCoin = 1000000},
	}
	local function rd()
		local q = qm[L.Flags.qs]
		if not q then return nil end
		local d, ct = pd(), md("Data", "Catalog")
		local cq = d.Quest and d.Quest.Current
		local ac, id = cq and cq.Id == q[1], q[1]
		if ((d.Quest or {}).Done or {})[id] then return {`{q[4]} (Completed)`, {}} end
		local pr, df, ln = ac and cq.Progress or {}, qf[id] or {}, {}
		local function gv(k) return pr[k] or df[k] or 0 end
		local function ro(n, h, w, s) table.insert(ln, {`{n}: {nf(h)} / {nf(w)}`, h >= w, s}) end
		local na = not ac and "Counts only after accepting" or nil
		local u = ul(q[2])
		table.insert(ln, {`{iy[q[2]] or q[2]}: {u and "Unlocked" or "Locked"}`, u})
		if q[7] then
			local r, o = ct.Rod.GetById(q[7]), d.Rods and d.Rods[q[7]] ~= nil
			table.insert(ln, {`Own {r and r.name or q[7]}: {o and "Yes" or "No"}`, o})
		end
		ro("Coins", d.Coin or 0, gv("RequiredCoin"))
		if id == "crimson_bead_rod" then
			ro("Fish With Legacy Rod", ac and pr.CurrentFished or 0, gv("RequiredFished"), na)
		elseif id == "bamboo_rod" then
			ro("Bamboo Fragments", md("Shared", "getItemCount")(d, "bamboo_fragment"), gv("RequiredBamboo"), "10% drop while fishing on Jungle Island")
		elseif id == "zen_staff_rod" then
			ro("Final Blows With Taiji Hooking Art V2", ac and pr.CurrentFish or 0, gv("RequiredFish"), `Legendary fish from Fossil Island{na and `, {na:lower()}` or ""}`)
		elseif id == "taiji_hooking_art_v2" then
			ro("Final Blows With Taiji Hooking Art", ac and pr.CurrentKills or 0, gv("RequiredKills"), `Any fish, any island{na and `, {na:lower()}` or ""}`)
			local bk = ((d.Inventory or {}).Books or {}).taiji_hooking_art or 0
			table.insert(ln, {`Taiji Hooking Art Books: {bk}`, bk >= 1, "One book is turned into V2; the hub unequips it before completing"})
		elseif q[6] then
			local c = 0
			for _ in select(2, qc(q, d, {RequiredFish = gv("RequiredFish")})) do c += 1 end
			ro(`{q[6][1]} Fish`, c, gv("RequiredFish"), `Any {q[6][1]} fish from {iy[q[6][2]] or q[6][2]}`)
		end
		return {`{q[4]}{ac and " (Accepted)" or ""}`, ln}
	end
	local function rs(r)
		if not r then return "No Rod Quest Selected" end
		local t = {rb and `<b>{r[1]}</b>` or r[1]}
		for _, v in r[2] do
			local hn = v[3] and (rb and ` <font color="#96938C">- {v[3]}</font>` or ` - {v[3]}`) or ""
			table.insert(t, (rb and `<font color="#{v[2] and "78C882" or "D66A5E"}">{v[1]}</font>` or v[1]) .. hn)
		end
		return table.concat(t, "\n")
	end
	local function dt()
		local d, q = pd(), nil
		for _, x in qd do
			if not ul(x[3]) then q = x; break end
		end
		if not q then return {} end
		local ct, cq = md("Data", "Catalog"), d.Quest and d.Quest.Current
		local pr = cq and cq.Id == q[1] and cq.Progress or q[5]
		local _, ks = qc(q, d, pr)
		local ln, n, bw, fl = {{"Coins", d.Coin or 0, pr.RequiredCoin or 0}}, {}, {}, {}
		for u in ks do
			local x = d.Inventory.Fishes[u]
			if x then n[x.fishId] = (n[x.fishId] or 0) + 1 end
		end
		for _, x in d.Inventory.Fishes do bw[x.fishId] = math.max(bw[x.fishId] or 0, x.weight or 0) end
		for _, il in ix do
			for _, x in (ct.Island.GetById(il) or {}).fishes or {} do
				fl[x.fishId] = fl[x.fishId] and `{fl[x.fishId]}, {iy[il]}` or iy[il]
			end
		end
		if q[6] then
			local c = 0
			for _ in ks do c += 1 end
			table.insert(ln, {`{q[6][1]} Fish`, c, pr.RequiredFish or 1, `Any {q[6][1]} fish from {iy[q[6][2]] or q[6][2]}`})
		else
			local wk, fs = q[1] == "unlock_island_6" and md("Data", "Config", "QuestConfig").UnlockIsland6MinWeightKg or {}, {}
			for id, v in pr.RequiredFishes or {} do
				local fi = ct.Fish.GetById(id)
				local nm, rr, il = fi and fi.name or id, fi and fi.rarity or "?", fl[id] or "?"
				table.insert(fs, {nm, n[id] or 0, v, wk[id] and `Need {kg(wk[id])} - Best {bw[id] and kg(bw[id]) or "none"} - {rr} - {il}` or `{rr} - {il}`, wk[id] or 0})
			end
			table.sort(fs, function(x, y)
				if x[5] ~= y[5] then return x[5] < y[5] end
				return x[1] < y[1]
			end)
			for _, x in fs do table.insert(ln, x) end
		end
		return {q[4], ln, cq and cq.Id == q[1]}
	end
	local function yd()
		local d, ct, ba = pd(), md("Data", "Catalog"), md("Utils", "skillBookAvailability")
		local cq, so, dn, ps = (d.Quest or {}).Current or {}, (d.Inventory or {}).Souls or {}, (d.Quest or {}).Done or {}, L.Flags.ys or {}
		local se = ct.Soul.GetById(d.SoulEquip or "")
		local t = {{`Equipped Soul: {se and se.name or "Human"}`}}
		if #ps == 0 then table.insert(t, {"No Soul Quest Selected"}) end
		for _, q in qg do
			local id = q[1]
			if not table.find(ps, q[4]) then continue end
			if dn[id] or so[id] == true then
				table.insert(t, {`{q[4]} (Owned)`, true, nil, true})
				continue
			end
			local ac = cq.Id == id
			local pr, u = ac and cq.Progress or {}, ul(q[2])
			table.insert(t, {`{q[4]}{ac and " (Accepted)" or ""}`, nil, nil, true})
			table.insert(t, {`{iy[q[2]] or q[2]}: {u and "Unlocked" or "Locked"}`, u})
			if id == "azure_dragon" or id == "supreme_king" then
				local h, w = ac and pr.CurrentUsedSkill or 0, pr.CatchWithSkill or (id == "azure_dragon" and 100 or 5)
				table.insert(t, {`{id == "azure_dragon" and "Final Blows With One Hook Supreme" or "Legendary Final Blows With Rod Gate 20%"}: {nf(h)} / {nf(w)}`, h >= w, `{id == "azure_dragon" and "Any fish" or "Legendary fish from Fossil Island"}{ac and "" or ", counts only after accepting"}`})
			end
			if q[6] then
				local w, c = pr.RequiredFish or 3, 0
				for _ in select(2, qc(q, d, {RequiredFish = w})) do c += 1 end
				table.insert(t, {`{q[6][1]} Fish{q[6][3] and ` {nf(q[6][3])}+ kg` or ""}: {c} / {w}`, c >= w, `From {iy[q[6][2]] or q[6][2]}`})
			end
			for b, v in id == "phoenix" and md("Data", "Config", "QuestConfig").PhoenixRequiredBooks or id == "supreme_king" and (pr.RequiredBooks or {rod_gate_20_percent = 1}) or {} do
				local a = ba.GetCounts(d, b).available
				table.insert(t, {`Unequipped {(ct.Skill.GetById(b) or {}).name or b}: {math.min(a, v)} / {v}`, a >= v, id == "supreme_king" and "A copy besides the one on your rod" or "Skill book not on any rod"})
			end
		end
		return t
	end
	local function yr(r)
		local t = {}
		for _, v in r do
			local x = v[4] and (ylb and `<b>{v[1]}</b>` or v[1]) or v[2] ~= nil and ylb and `<font color="#{v[2] and "78C882" or "D66A5E"}">{v[1]}</font>` or v[1]
			table.insert(t, x .. (v[3] and (ylb and ` <font color="#96938C">- {v[3]}</font>` or ` - {v[3]}`) or ""))
		end
		return table.concat(t, "\n")
	end
	local function kd()
		local st, ct, t = game:GetService("ReplicatedStorage"):GetAttribute("SkillMarketStock"), md("Data", "Catalog"), {}
		for id in (type(st) == "string" and st or ""):gmatch("[^,]+") do
			local x = ct.Skill.GetById(id)
			table.insert(t, x and x.name or id)
		end
		return #t > 0 and table.concat(t, "\n") or "No Stock"
	end
	while ge.__FmQ == tk do
		local ok, r = cx(dt)
		if ok and r then
			local t = {r[1] and `Next Island: {r[1]}{r[3] and " (Accepted)" or ""}` or "All Islands Unlocked"}
			if lb then t[1] = `<b>{t[1]}</b>` end
			for _, v in r[2] or {} do
				local x = `{v[1]}: {nf(v[2])} / {nf(v[3])}`
				local hn = v[4] and (lb and ` <font color="#96938C">- {v[4]}</font>` or ` - {v[4]}`) or ""
				table.insert(t, (lb and `<font color="#{v[2] >= v[3] and "78C882" or "D66A5E"}">{x}</font>` or x) .. hn)
			end
			iql:Set(table.concat(t, "\n"))
		end
		local ok2, r2 = cx(rd)
		if ok2 then rql:Set(rs(r2)) end
		local ok4, r4 = cx(yd)
		if ok4 and r4 then yql:Set(yr(r4)) end
		local ok3, r3 = cx(kd)
		if ok3 then kql:Set(r3) end
		task.wait(1)
	end
end

task.spawn(iq)


-- ============================================================
-- LUNAR X HUB | DISCORD WEBHOOK
-- Chỉ gửi: tên Roblox, User ID, tên game và thời gian dùng (GMT+7).
-- ============================================================
local LunarXWebhookURL = "https://discord.com/api/webhooks/1558456988109901826/nyv51z9bOkUAwix3OtPwfnoCHAVo-6ARBb4ne2LXdZIP1eHvUr17Quon16mp-eH8w1YU"

local function LunarXSendWebhook()
    if type(LunarXWebhookURL) ~= "string"
        or LunarXWebhookURL == ""
        or LunarXWebhookURL == "PASTE_YOUR_DISCORD_WEBHOOK_URL_HERE" then
        warn("[LunarXHub] Chưa điền Discord Webhook URL.")
        return false
    end

    local requestFn =
        (syn and syn.request)
        or (http and http.request)
        or http_request
        or request

    if type(requestFn) ~= "function" then
        warn("[LunarXHub] Executor không hỗ trợ HTTP request.")
        return false
    end

    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    if not player then
        warn("[LunarXHub] Không tìm thấy LocalPlayer.")
        return false
    end

    local gameName = "Không xác định"
    pcall(function()
        gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or gameName
    end)

    -- Roblox/Lua os.date dùng giờ UTC ở định dạng !; cộng 7 giờ để hiển thị GMT+7.
    local nowGMT7 = os.date("!%Y-%m-%d %H:%M:%S", os.time() + 7 * 60 * 60)
    local isoGMT7 = os.date("!%Y-%m-%dT%H:%M:%S", os.time() + 7 * 60 * 60) .. "+07:00"

    local payload = {
        username = "Lunar X Hub Logs",
        embeds = {{
            title = "📜 LUNAR X HUB",
            color = 5793266,
            fields = {
                { name = "👤 Tên Roblox", value = tostring(player.Name), inline = true },
                { name = "🆔 User ID", value = tostring(player.UserId), inline = true },
                { name = "🎮 Tên game", value = tostring(gameName):sub(1, 250), inline = false },
                { name = "⏱️ Thời gian dùng (GMT+7)", value = nowGMT7, inline = false }
            },
            footer = { text = "Lunar X Hub" },
            timestamp = isoGMT7
        }}
    }

    local ok, result = pcall(function()
        return requestFn({
            Url = LunarXWebhookURL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
    end)

    if not ok then
        warn("[LunarXHub] Gửi webhook lỗi: " .. tostring(result))
        return false
    end

    local status = result and (result.StatusCode or result.Status or result.status_code)
    if status and tonumber(status) and tonumber(status) >= 300 then
        warn("[LunarXHub] Discord từ chối webhook. HTTP " .. tostring(status))
        return false
    end

    print("[LunarXHub] Đã gửi log webhook.")
    return true
end

-- Gửi log khi script bắt đầu; không gửi thêm thông tin/hoạt động khác.
task.spawn(function()
    task.wait(2)
    LunarXSendWebhook()
end)
