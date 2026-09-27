local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

------------------------------------------------------------
-- 🎛 MAIN UI BUTTON
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local ImageButton = Instance.new("ImageButton")
ImageButton.Parent = ScreenGui
ImageButton.BackgroundColor3 = Color3.fromRGB(0,0,0)
ImageButton.BorderSizePixel = 0
ImageButton.Position = UDim2.new(0.1,0,0.15,0)
ImageButton.Size = UDim2.new(0,40,0,40)
ImageButton.Draggable = true
ImageButton.Image = "http://www.roblox.com/asset/?id=133060444314687"
local UICorner = Instance.new("UICorner")
UICorner.Parent = ImageButton
UICorner.CornerRadius = UDim.new(1,10)

-- Ghi chú: giữ nguyên script cũ, nhưng mình sẽ thêm toggle UI bên dưới

------------------------------------------------------------
-- 🔄 LOAD FLUENT
repeat task.wait() until game:IsLoaded()
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
	Title="DUCZ HUB",
	SubTitle="by realducz",
	TabWidth=157,
	Size=UDim2.fromOffset(450,300),
	Acrylic=true,
	Theme="Dark",
	MinimizeKey=Enum.KeyCode.End
})

-- THÊM: đổi tên window thành DUCZ HUB
Window.Title = "DUCZ HUB"

-- Tabs
local Tabs = {
	Main0=Window:AddTab({Title="Thông Tin"}),
	Main1=Window:AddTab({Title="Script Main"}),
	Main2=Window:AddTab({Title="Script Hop Sever"}),
	Main3=Window:AddTab({Title="Script PVP"})
}

-- Tab 0: Thông Tin
Tabs.Main0:AddButton({ Title="Youtuber", Description="Ducz ROBLOX", Callback=function() setclipboard("https://youtube.com/@DUCZGAMERNE") end })

-- Tab 1: Blox Fruits

Tabs.Main1:AddButton({
    Title="Tumadam Hub",
    Callback=function()
        loadstring(game:HttpGet("https://github.com/Tumadam/cwertyur/raw/refs/heads/main/TumadamEng.lua"))()
    end
})
Tabs.Main1:AddButton({
    Title="w-azure premium Hub",
    Callback=function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/LuaAnarchist/YeuEmNhieuLam/refs/heads/main/w-azure.luau"))()
    end
})
Tabs.Main1:AddButton({
    Title="NatAov HUB",
    Callback=function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Dev-AnhTuansitink/NatAov-Hub/refs/heads/main/ILoveYou.lua"))()
    end
})
Tabs.Main1:AddButton({
    Title="Apple Hub",
    Callback=function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/AlexHerrySeek/AppleHub/refs/heads/main/loader/main.lua"))()
    end
})
Tabs.Main1:AddButton({
    Title="Speed Hub X",
    Callback=function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/AhmadV99/Speed-Hub-X/main/Speed%20Hub%20X.lua", true))()
    end
})
Tabs.Main1:AddButton({
    Title="XETER Hub v1",
    Callback=function()
         getgenv().Version = "V1"
         getgenv().Team = "Marines"
         loadstring(game:HttpGet("https://raw.githubusercontent.com/TlDinhKhoi/Xeter/refs/heads/main/Main.lua"))()
    end
})
Tabs.Main1:AddButton({
    Title="Xete HUb V2",
    Callback=function()
        getgenv().Version = "V2"
        getgenv().Team = "Marines"
        loadstring(game:HttpGet("https://raw.githubusercontent.com/TlDinhKhoi/Xeter/refs/heads/main/Main.lua"))()
    end
})
Tabs.Main1:AddButton({
    Title="Xeter Hub V3",
    Callback=function()
        getgenv().Version = "V3"
        getgenv().Team = "Marines"
        loadstring(game:HttpGet("https://raw.githubusercontent.com/TlDinhKhoi/Xeter/refs/heads/main/Main.lua"))()
    end
})
Tabs.Main1:AddButton({
    Title="Teddy HUB MAIN",
    Callback=function()
        loadstring(game:HttpGet("https://api.luarmor.net/files/v4/loaders/e86ed284a22672d29e906214e7bbf8b9.lua"))()
    end
})
Tabs.Main1:AddButton({
    Title="HOHO Hub",
    Callback=function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/acsu123/HOHO_H/main/Loading_UI'))()
    end
})

Tabs.Main1:AddButton({
    Title="Tày hub premium",
    Callback=function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/VTDROBLOX/Animehub/refs/heads/main/Tayhub-PREMIUM.lua"))()
    end
})
Tabs.Main1:AddButton({
    Title="Xeter Hub V4",
    Callback=function()
        getgenv().Version = "V4"
        getgenv().Team = "Marines"
        loadstring(game:HttpGet("https://raw.githubusercontent.com/TlDinhKhoi/Xeter/refs/heads/main/Main.lua"))()
    end
})

-- Tab 2: Grow A Garden
Tabs.Main2:AddButton({
    Title="Teddy Hub",
    Callback=function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Teddyseetink/Haidepzai/refs/heads/main/TEDDYHUB-FREEMIUM"))()
    end
})


-- Tab 3: 99 Nights In The Forest


------------------------------------------------------------
-- THÊM TOGGLE UI BẰNG BUTTON VÀ PHÍM END (KHÔNG XÓA TAB Blox Fruits)
local UIS = game:GetService("UserInputService")
local DuczUIVisible = true

local function DuczToggleUI()
	DuczUIVisible = not DuczUIVisible
	if Window and Window.Root then
		Window.Root.Visible = DuczUIVisible
	end
end

-- Button tròn toggle UI
ImageButton.MouseButton1Click:Connect(function()
	DuczToggleUI()
end)

-- Phím End toggle UI
UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.End then
		DuczToggleUI()
	end
end)
