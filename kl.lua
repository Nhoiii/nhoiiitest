
local genv, Players, ReplicatedStorage, HttpService, TeleportService, CollectionService, localPlayer, tbl, tbl2, text
local lib, client, packet, data, FishingPackets, FishingConfig, FishingEnums, SellEnums, AuraGachaConfig, SkillGachaConfig
local CrateConfig, RodShopConfig, IslandConfig, RarityEnums, Catalog, PlayerDataV2Controller, FishingController, LootController, v, v2
local ClaimAll, BossSpawnSound, tbl3, tbl4, flag, resumeSoldFish, flag2, flag3, flag4, flag5
local flag6, n, n2, flag7, n3, n4, n5, n6, n7, flag8
local n8, tbl5, flag9, flag10, flag11, flag12, n9, flag13, n10, n11
local flag14, cFrame, flag15, tbl6, flag16, flag17, flag18, flag19, cFrame2, cFrame3
local flag20, now, n12, n13, flag21, flag22, n14, n15, flag23, n16
local flag24, idling, v3, now2, n17, tbl7, fn, fn2, tbl8, v4
local fn3, tbl9, tbl10, fn4, fn5, fn6, fn7, fn8, fn9, fn10
local fn11, tbl11, tbl12, walkTo, tweenTo, fn12, fn13, fn14, fn15, fn16
local fn17, fn18, fn19, fn20, fn21, fn22, fn23, fn24, fn25
do
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end
	genv = getgenv and getgenv() or _G
	genv.HuneHubPreviousSession = type(genv.HuneHubFishingMaster) == "table"
	if type(genv.FishFilterQuickTest) == "table" and type(genv.FishFilterQuickTest.Stop) == "function" then
		pcall(genv.FishFilterQuickTest.Stop)
	end
	if type(genv.HuneHubFishingMaster) == "table" and type(genv.HuneHubFishingMaster.Unload) == "function" then
		pcall(genv.HuneHubFishingMaster.Unload)
	end
	Players = game:GetService("Players")
	ReplicatedStorage = game:GetService("ReplicatedStorage")
	local PathfindingService = game:GetService("PathfindingService")
	local UserInputService = game:GetService("UserInputService")
	HttpService = game:GetService("HttpService")
	TeleportService = game:GetService("TeleportService")
	game:GetService("GuiService")
	CollectionService = game:GetService("CollectionService")
	local VirtualInputManager = game:GetService("VirtualInputManager")
	local RunService = game:GetService("RunService")
	localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	tbl = {
		path = "Hune Hub/" .. localPlayer.Name:lower():gsub("[^%w_%-]", "_") .. ".json",
		read = function()
			local ok, result = pcall(function()
				if type(readfile) ~= "function" then
					return nil
				end
				if type(isfile) ~= "function" or isfile(tbl.path) then
					return HttpService:JSONDecode(readfile(tbl.path))
				end
				if isfile("Hune Hub/Language.json") then
					local data2 = HttpService:JSONDecode(readfile("Hune Hub/Language.json"))
					if type(data2) == "table" then
						return { language = { mode = data2.mode } }
					end
				end
				return nil
			end)
			return ok and type(result) == "table" and result or {}
		end,
		update = function(arg)
			local ok, result = pcall(function()
				if type(writefile) ~= "function" or type(readfile) ~= "function" then
					error("file access unavailable")
				end
				local result = tbl.read()
				if type(isfile) == "function" and isfile(tbl.path) then
					local ok
					ok, result = pcall(function()
						return HttpService:JSONDecode(readfile(tbl.path))
					end)
					if not ok or type(result) ~= "table" then
						error("existing config JSON is invalid")
					end
				end
				result.version = 1
				arg(result)
				if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder("Hune Hub") then
					makefolder("Hune Hub")
				end
				local json = HttpService:JSONEncode(result)
				writefile(tbl.path, json)
				if readfile(tbl.path) ~= json then
					error("config save verification failed")
				end
				return true
			end)
			return ok and result == true
		end,
		profiles = function(arg)
			local v5 = tbl.read()[arg]
			return type(v5) == "table" and type(v5.profiles) == "table" and v5.profiles or {}
		end,
		saveProfile = function(arg, arg2, arg3, arg4)
			local tbl13 = {}
			local v5 = pairs
			local pendingFlags = arg3.PendingFlags or {}
			for k, pendingFlag in v5(pendingFlags) do
				local parser = arg4 and arg4.Parser and arg4.Parser[pendingFlag.__type]
				if parser and parser.Save then
					local ok, result = pcall(parser.Save, pendingFlag)
					if ok and result ~= nil then
						tbl13[k] = result
					end
				end
			end
			if next(tbl13) == nil then
				error("no config controls available")
			end
			if not tbl.update(function(arg5)
				arg5[arg] = type(arg5[arg]) == "table" and arg5[arg] or {}
				arg5[arg].profiles = type(arg5[arg].profiles) == "table" and arg5[arg].profiles or {}
				arg5[arg].profiles[arg2] = { flags = tbl13 }
			end) then
				error("could not save profile")
			end
		end,
		loadProfile = function(arg, arg2, arg3, arg4)
			local v5 = tbl.profiles(arg)[arg2]
			if type(v5) ~= "table" or type(v5.flags) ~= "table" then
				error("profile not found")
			end
			local n18 = 0
			for k, flag25 in pairs(v5.flags) do
				local pendingFlags = arg3.PendingFlags and arg3.PendingFlags[k]
				local parser = pendingFlags and arg4 and arg4.Parser and arg4.Parser[pendingFlags.__type]
				if parser and parser.Load then
					if pcall(parser.Load, pendingFlags, flag25) then
						n18 += 1
					end
				end
			end
			if n18 == 0 and next(v5.flags) then
				error("profile has no compatible controls")
			end
		end,
		migrateLegacyProfiles = function(arg, arg2)
			if not arg2 or type(arg2.Path) ~= "string" then
				return
			end
			local v5 = tbl.read()[arg]
			if type(v5) == "table" and v5.migratedLegacy then
				return
			end
			local tbl13 = {}
			pcall(function()
				for _, v6 in ipairs(arg2:AllConfigs()) do
					local str = arg2.Path .. v6 .. ".json"
					if isfile(str) then
						local data2 = HttpService:JSONDecode(readfile(str))
						local elements = type(data2) == "table" and (data2.__elements or data2)
						if type(elements) == "table" then
							tbl13[v6] = { flags = elements }
						end
					end
				end
			end)
			tbl.update(function(arg3)
				arg3[arg] = type(arg3[arg]) == "table" and arg3[arg] or {}
				arg3[arg].profiles = type(arg3[arg].profiles) == "table" and arg3[arg].profiles or {}
				for k, v6 in pairs(tbl13) do
					if arg3[arg].profiles[k] == nil then
						arg3[arg].profiles[k] = v6
					end
				end
				if arg == "fishingMaster" and arg3[arg].autoload == nil then
					pcall(function()
						if isfile("LunarX Hub/FishingMaster_Autoload.txt") then
							arg3[arg].autoload = tostring(readfile("Hune Hub/FishingMaster_Autoload.txt")):match("^%s*(.-)%s*$")
						end
					end)
				end
				arg3[arg].migratedLegacy = true
			end)
		end,
	}
	tbl2 = {
		mode = "auto",
		code = "en",
		vi = {
			Main = "Chính",
			["Misc & Player"] = "Khác & Nhân Vật",
			Settings = "Cài Đặt",
			Visual = "Hiệu Ứng",
			["Rod Skin"] = "Skin Cần Câu",
			Aura = "Hào Quang",
			["Visual Effect (Client-side)"] = "Hiệu Ứng Hình Ảnh (Client-side)",
			["Client-side Rod Skin changer with custom animations"] = "Đổi Skin Cần Câu phía máy bạn kèm Animation",
			["Client-side Aura changer with particles & effects"] = "Đổi Hào Quang phía máy bạn kèm hiệu ứng hạt",
			Info = "Thông Tin",
			["Auto Farm"] = "Tự Động Câu",
			["Auto Sell"] = "Tự Động Bán",
			Island = "Đảo",
			Quest = "Nhiệm Vụ",
			Boss = "Boss",
			Shop = "Cửa Hàng",
			Rewards = "Phần Thưởng",
			["Local Player"] = "Nhân Vật",
			Config = "Cấu Hình",
			Information = "Thông Tin",
			["Discord Community"] = "Cộng Đồng Discord",
			["Join Discord"] = "Vào Discord",
			Owner = "Chủ Sở Hữu",
			["Copy Owner ID"] = "Sao Chép ID Chủ Sở Hữu",
			["Server: "] = "Máy Chủ: ",
			Unknown = "Không Rõ",
			["Main Features"] = "Tính Năng Chính",
			["Auto Skill + Low HP"] = "Tự Dùng Kỹ Năng + Máu Thấp",
			["Fish Rarity Filter"] = "Lọc Độ Hiếm Cá",
			["Auto Spam Skill"] = "Tự Spam Kỹ Năng",
			["Skill Combo (Z,X,C,V)"] = "Thứ Tự Combo Skill (Z,X,C,V)",
			["Enter Skills In Order, Separated By Commas. Omit A Key To Skip It."] = "Nhập Thứ Tự Skill, Ngăn Cách Bằng Dấu Phẩy. Bỏ Phím Để Không Dùng.",
			["Target Rarities"] = "Độ Hiếm Mục Tiêu",
			["Filter Fish by Rarity"] = "Lọc Cá Theo Độ Hiếm",
			["Speed Settings"] = "Cài Đặt Tốc Độ",
			["Farm Delay (Seconds)"] = "Độ Trễ Câu (Giây)",
			["Position Settings"] = "Cài Đặt Vị Trí",
			["Stop Farm If Moved"] = "Dừng Câu Khi Di Chuyển",
			["Save Fishing Position"] = "Lưu Vị Trí Câu",
			["Return To Fishing Position"] = "Trở Về Vị Trí Câu",
			["Automatic Fish Selling"] = "Bán Cá Tự Động",
			["Sell Travel Method"] = "Cách Di Chuyển Đi Bán",
			["Sell Tween Speed (Studs/Second)"] = "Tốc Độ Tween Đi Bán (Stud/Giây)",
			["Sell Wait Delay (Seconds)"] = "Thời Gian Đợi Trước Khi Bán (Giây)",
			["Teleport Instant"] = "Dịch Chuyển Tức Thì",
			["Auto Lock Fish by Rarity"] = "Tự Khóa Cá Theo Độ Hiếm",
			["Rarities to Lock"] = "Độ Hiếm Cần Khóa",
			["Auto Lock Fish"] = "Tự Khóa Cá",
			["Auto Sell When Bag Full"] = "Tự Bán Khi Túi Đầy",
			["Auto Sell On Timer"] = "Tự Bán Theo Giờ",
			["Sell Interval (Seconds)"] = "Chu Kỳ Bán (Giây)",
			["Sell All Fish Now"] = "Bán Tất Cả Cá Ngay",
			["Island Unlock"] = "Mở Khóa Đảo",
			["Select Island"] = "Chọn Đảo",
			["Unlock Requirements"] = "Điều Kiện Mở Khóa",
			["Start Island Unlock Quest"] = "Bắt Đầu Nhiệm Vụ Mở Đảo",
			["Unlock Selected Island"] = "Mở Khóa Đảo Đã Chọn",
			["Island Travel"] = "Di Chuyển Giữa Các Đảo",
			["Island Travel Method"] = "Cách Dịch Chuyển Đảo",
			["Gamepass Local Movement"] = "Di Chuyển Cục Bộ Khi Dùng Gamepass",
			["Only for Gamepass: approach the portal and restore the destination position."] = "Chỉ cho Gamepass: đi tới cổng và vị trí đích.",
			["Gamepass Tween Speed (Studs/Second)"] = "Tốc Độ Tween Gamepass (Stud/Giây)",
			Boat = "Thuyền",
			["Boat Type"] = "Loại Thuyền",
			["Boat Driving Mode"] = "Cách Lái Thuyền",
			["Allow Paid Boat Spawn"] = "Cho Phép Gọi Thuyền Mất Phí",
			["Truck Is Free; Red Truck Spawn Costs 100,000 Coins."] = "Truck miễn phí; gọi Red Truck mất 100.000 Coins.",
			["Travel Speed (Studs/s)"] = "Tốc Độ Di Chuyển (Stud/Giây)",
			["Instant Teleport"] = "Dịch Chuyển Tức Thì",
			["Fast Travel Gamepass"] = "Fast Travel Gamepass",
			["Travel To Island"] = "Đi Đến Đảo",
			["Stop Island Travel"] = "Dừng Di Chuyển",
			["Auto Island"] = "Tự Động Đi Đảo",
			["Travel Method"] = "Cách Di Chuyển",
			["Transition Screen"] = "Màn Chuyển Cảnh",
			["Auto Unlock Island"] = "Tự Động Mở Đảo",
			["Fast Travel (Instant Warp)"] = "Dịch Chuyển Tức Thì (Warp)",
			["Boat Travel"] = "Đi Bằng Thuyền",
			["Auto (Warp / Boat)"] = "Tự Động (Warp / Thuyền)",
			["Align (Smooth Direct)"] = "Bay Thẳng (Align)",
			["Player (Steer)"] = "Lái Thuyền (Player)",
			["Travel Stopped"] = "Đã Dừng Di Chuyển",
			["Island travel was cancelled."] = "Đã Hủy Di Chuyển Đảo.",
			["Select Quest"] = "Chọn Nhiệm Vụ",
			["Travel To Quest Island"] = "Đi Đến Đảo Nhiệm Vụ",
			["Boss Alerts"] = "Thông Báo Boss",
			["Notify Boss"] = "Báo Khi Có Boss",
			["ESP Boss"] = "Hiện Vị Trí Boss",
			Cost = "Chi Phí",
			["Auto Spin "] = "Tự Quay ",
			[" Gacha"] = " Gacha",
			[" Stop At Or Above Rarity"] = " Dừng Ở Độ Hiếm Tối Thiểu",
			[" Maximum Spins"] = " Số Lần Quay Tối Đa",
			[" Gems Per Spin"] = " Gem Mỗi Lần Quay",
			[" Coins Per Spin"] = " Xu Mỗi Lần Quay",
			[" Per Spin"] = " Mỗi Lần Quay",
			["Coin Price Is Quoted Before Every Spin"] = "Giá Bằng Xu Được Báo Trước Mỗi Lần Quay",
			["Buy Fishing Rods"] = "Mua Cần Câu",
			["Select Rod To Buy"] = "Chọn Cần Câu Cần Mua",
			["Buy Selected Rod"] = "Mua Cần Câu Đã Chọn",
			["Daily Login"] = "Đăng Nhập Hằng Ngày",
			["Claim Daily Reward"] = "Nhận Thưởng Hằng Ngày",
			["Auto Claim Daily Reward"] = "Tự Nhận Thưởng Hằng Ngày",
			["Group & Gift Inbox"] = "Nhóm & Hộp Quà",
			["Claim Group Reward"] = "Nhận Thưởng Nhóm",
			["Claim All Gift Inbox Items"] = "Nhận Tất Cả Quà",
			["Redeem Code"] = "Đổi Mã",
			Code = "Mã",
			["Enter game code"] = "Nhập mã game",
			["Session Statistics"] = "Thống Kê Phiên",
			["Fish Caught: 0 | Coins Earned: 0 | Time: 0m 00s"] = "Cá Đã Câu: 0 | Xu Kiếm Được: 0 | Thời Gian: 0p 00s",
			Movement = "Di Chuyển",
			["Anti-AFK"] = "Chống AFK",
			["Freeze Character"] = "Đóng Băng Nhân Vật",
			["System Utilities"] = "Tiện Ích Hệ Thống",
			["Fix Lag Pro (Boost FPS)"] = "Giảm Lag Pro (Tăng FPS)",
			["Rejoin Server"] = "Vào Lại Máy Chủ",
			["Unload Hub"] = "Tắt Hub",
			["Interface Settings"] = "Cài Đặt Giao Diện",
			Theme = "Giao Diện",
			["Custom Rainbow Name"] = "Tên Rainbow Tùy Chỉnh",
			["All Players Rainbow Name"] = "Tên Rainbow Cho Mọi Người Chơi",
			["Local Overhead Names Only. Applies To All Players. Leave Blank For LunarX Hub. Maximum 24 Characters."] = "Chỉ Đổi Tên Trên Đầu Ở Máy Bạn Cho Mọi Người Chơi. Để Trống Dùng LunarX Hub. Tối Đa 24 Ký Tự.",
			["Leave Blank To Use LunarX Hub. Maximum 24 Characters."] = "Để Trống Để Dùng LunarX Hub. Tối Đa 24 Ký Tự.",
			["Profile Management System"] = "Quản Lý Cấu Hình",
			["New Config Name"] = "Tên Cấu Hình Mới",
			["e.g. AutoFarm"] = "Ví dụ: AutoFarm",
			["Save Config"] = "Lưu Cấu Hình",
			["Select Config To Load/Delete"] = "Chọn Cấu Hình Để Tải/Xóa",
			["Load Config"] = "Tải Cấu Hình",
			["Delete Config"] = "Xóa Cấu Hình",
			["Select Auto Load Config"] = "Chọn Cấu Hình Tự Tải",
			["Set Auto Load Config"] = "Đặt Cấu Hình Tự Tải",
			Language = "Ngôn Ngữ",
			["Select Language"] = "Chọn Ngôn Ngữ",
			["Language updated and saved."] = "Đã Đổi Và Lưu Ngôn Ngữ.",
			["Language updated for this session, but could not be saved."] = "Đã Đổi Ngôn Ngữ Cho Phiên Này Nhưng Không Thể Lưu Vào File.",
			["Checking Key..."] = "Đang Kiểm Tra Key...",
			["No Key"] = "Không Có Key",
			["Key Unavailable"] = "Không Kiểm Tra Được Key",
			["Invalid Key"] = "Key Không Hợp Lệ",
			Lifetime = "Vĩnh Viễn",
			Expired = "Đã Hết Hạn",
			["Fish Sold"] = "Đã Bán Cá",
			["Returning To Fishing Spot"] = "Đang Về Vị Trí Câu",
			["Return To Fishing Spot Pending"] = "Đang Chờ Về Vị Trí Câu",
			["No Fish To Sell"] = "Không Có Cá Để Bán",
			["Merchant Out Of Range"] = "Ở Quá Xa Người Bán Cá",
			["Sell Request Busy"] = "Đang Xử Lý Bán Cá",
			["Fish Merchant Not Found"] = "Không Tìm Thấy Người Bán Cá",
			["No Walking Route"] = "Không Có Đường Đi Bộ",
			["Movement Busy"] = "Đang Di Chuyển",
			["Return Pending"] = "Đang Chờ Quay Lại",
			["Fish Filter"] = "Lọc Cá",
			["Sell Request Failed"] = "Bán Cá Thất Bại",
			["Selling Fish"] = "Đang Bán Cá",
			["Sell Pending"] = "Đang Chờ Xác Nhận Bán Cá",
			["Moving to the nearest Fish Merchant."] = "Đang Đến Người Bán Cá Gần Nhất.",
			["The sale has not been confirmed. The script will retry."] = "Chưa Xác Nhận Bán Cá. Script Sẽ Thử Lại.",
			["No safe position was found near the Fish Merchant."] = "Không Tìm Thấy Vị Trí An Toàn Gần Người Bán Cá.",
			["The game moved the character away from the Fish Merchant."] = "Game Đã Đưa Nhân Vật Ra Xa Người Bán Cá.",
			["The sale could not be completed."] = "Không Thể Hoàn Tất Bán Cá.",
			["Finishing Current Fish"] = "Đang Câu Xong Cá Hiện Tại",
			["The sale will start when the current fight ends."] = "Sẽ Bắt Đầu Bán Khi Lượt Câu Hiện Tại Kết Thúc.",
			["Fishing Area Left"] = "Đã Rời Khu Vực Câu",
			["Fishing Position Restored"] = "Đã Về Vị Trí Câu",
			["Bag Full"] = "Túi Đã Đầy",
			["Auto Farm Enabled"] = "Đã Bật Tự Động Câu",
			["Auto Farm Disabled"] = "Đã Tắt Tự Động Câu",
			["Fishing Area Saved"] = "Đã Lưu Khu Vực Câu",
			["Position Not Saved"] = "Chưa Lưu Vị Trí",
			["Position Saved"] = "Đã Lưu Vị Trí",
			["Position Reached"] = "Đã Đến Vị Trí",
			["Safe Route Unavailable"] = "Không Có Đường An Toàn",
			["No Saved Position"] = "Chưa Có Vị Trí Đã Lưu",
			["Sell In Progress"] = "Đang Bán Cá",
			["Island Unlocked"] = "Đã Mở Khóa Đảo",
			["Previous Island Locked"] = "Đảo Trước Chưa Mở Khóa",
			["Quest Active"] = "Nhiệm Vụ Đang Hoạt Động",
			["Another Quest Active"] = "Đang Có Nhiệm Vụ Khác",
			["Unlock Quest Started"] = "Đã Bắt Đầu Nhiệm Vụ Mở Đảo",
			["Unlock Quest Failed"] = "Không Thể Bắt Đầu Mở Đảo",
			["Unlock Requirements Missing"] = "Thiếu Điều Kiện Mở Đảo",
			["Quest Required"] = "Cần Làm Nhiệm Vụ",
			["Travel Complete"] = "Đã Đến Đảo",
			["Travel Stopped"] = "Đã Dừng Di Chuyển",
			["Destination Not Loaded"] = "Đảo Đích Chưa Tải",
			["Already At Destination"] = "Đã Ở Đảo Đích",
			["Travel Failed"] = "Di Chuyển Thất Bại",
			["Auto Quest Complete"] = "Đã Hoàn Thành Nhiệm Vụ",
			["Quest Started"] = "Đã Bắt Đầu Nhiệm Vụ",
			["Quest Completed"] = "Đã Hoàn Thành Nhiệm Vụ",
			["Boss Spotted: "] = "Phát Hiện Boss: ",
			["Rod Shop"] = "Cửa Hàng Cần Câu",
			["Daily Reward"] = "Thưởng Hằng Ngày",
			["Group Reward"] = "Thưởng Nhóm",
			["Gift Inbox"] = "Hộp Quà",
			["Fix Lag"] = "Giảm Lag",
			["Fix Lag Pro"] = "Giảm Lag Pro",
			["Walk On Water"] = "Đi Trên Nước",
			["Walk on water surface (Invisible platform)"] = "Đi trên mặt nước (Bục tàng hình)",
			["Walk on water surface when Auto Sell (Walk) is active"] = "Đi trên mặt nước khi tự động bán bằng chế độ đi bộ",
			["Walk on water surface when selling with Walk method"] = "Đi trên mặt nước khi bán cá bằng chế độ đi bộ",
			["Movement & Safety"] = "Di Chuyển & An Toàn",
			["LunarX Hub Ready"] = "LunarX Hub Sẵn Sàng",
			["Fishing Master is ready. Enable Auto Farm to begin."] = "Fishing Master Đã Sẵn Sàng. Bật Tự Động Câu Để Bắt Đầu.",
			["Join Discord For More Update New!!!"] = "Vào Discord Để Nhận Thông Tin Cập Nhật Mới!",
			["The complete fishing cycle has stopped."] = "Chu Kỳ Câu Cá Đã Dừng.",
			["The current fishing position has been saved."] = "Đã Lưu Vị Trí Câu Hiện Tại.",
			["Character position is not ready yet."] = "Vị Trí Nhân Vật Chưa Sẵn Sàng.",
			["Save a fishing position first."] = "Hãy Lưu Vị Trí Câu Trước.",
			["The current merchant sale is still running."] = "Lượt Bán Cá Hiện Tại Vẫn Đang Chạy.",
			["Returned to the saved fishing spot."] = "Đã Trở Về Vị Trí Câu Đã Lưu.",
			["All fish are locked; unlock fish to make room."] = "Tất Cả Cá Đã Bị Khóa; Hãy Mở Khóa Một Số Cá Để Có Chỗ Trống.",
			["Please enter config name first!"] = "Hãy Nhập Tên Cấu Hình Trước!",
			["Discord invite copied!"] = "Đã Sao Chép Lời Mời Discord!",
			["Clipboard is not supported by this executor."] = "Executor Này Không Hỗ Trợ Clipboard.",
			["Auto Quest"] = "Tự Động Làm Nhiệm Vụ",
			Gacha = "Gacha",
			["Gacha "] = "Gacha ",
			["Quest Status"] = "Trạng Thái Nhiệm Vụ",
			["Auto Quest Off"] = "Auto Quest Đang Tắt",
			["No Available Quest"] = "Không Có Nhiệm Vụ Phù Hợp",
			["Player Data Unavailable"] = "Chưa Đọc Được Dữ Liệu Người Chơi",
			["Waiting To Accept Quest"] = "Chờ Nhận Nhiệm Vụ",
			["Accepting Quest"] = "Đang Gửi Yêu Cầu Nhận Nhiệm Vụ",
			["Accept Quest Failed"] = "Nhận Nhiệm Vụ Thất Bại",
			["Confirming Accepted Quest"] = "Chờ Dữ Liệu Xác Nhận Đã Nhận Nhiệm Vụ",
			["Cannot Verify Quest Requirements"] = "Chưa Xác Minh Được Yêu Cầu Nhiệm Vụ",
			["Paused: Selling Fish"] = "Tạm Dừng: Đang Bán Cá",
			["Paused: Returning To Fishing Spot"] = "Tạm Dừng: Đang Về Vị Trí Câu",
			["Paused: Character Moving"] = "Tạm Dừng: Đang Di Chuyển",
			["Paused: Auto Boss Has Priority"] = "Tạm Dừng: Ưu Tiên Auto Boss",
			["Quest Island Is Locked"] = "Đảo Làm Nhiệm Vụ Chưa Mở Khóa",
			["Travel To Quest Island Is Off"] = "Đang Tắt Tự Đi Đến Đảo Làm Nhiệm Vụ",
			["Traveling To Quest Island"] = "Đang Đi Đến Đảo Làm Nhiệm Vụ",
			["Quest Travel Failed"] = "Đi Đến Đảo Làm Nhiệm Vụ Thất Bại",
			["Waiting To Retry Quest Travel"] = "Chờ Thử Đi Đảo Lại",
			["Fishing For Quest"] = "Đang Câu Cá Cho Nhiệm Vụ",
			["Could Not Start Auto Farm"] = "Chưa Bật Được Auto Farm",
			["Waiting For Quest Materials"] = "Chờ Đủ Vật Phẩm Nhiệm Vụ",
			["Quest Requirements Ready"] = "Đã Đủ Yêu Cầu Nhiệm Vụ",
			["Completing Quest"] = "Đang Gửi Yêu Cầu Hoàn Thành",
			["Confirming Quest Completion"] = "Chờ Dữ Liệu Xác Nhận Hoàn Thành",
			["Complete Quest Failed"] = "Hoàn Thành Nhiệm Vụ Thất Bại",
			["Quest Request Still Pending"] = "Yêu Cầu Nhiệm Vụ Chưa Phản Hồi",
			["Auto Quest Error"] = "Lỗi Auto Quest",
			["Current Island"] = "Đảo Hiện Tại",
			["Quest Island"] = "Đảo Làm Nhiệm Vụ",
			["Retry In"] = "Thử Lại Sau",
			["Requirements Are Available After Accepting The Quest."] = "Tiến Độ Yêu Cầu Có Sau Khi Nhận Nhiệm Vụ.",
			["Server Accepted The Request; Waiting For Player Data."] = "Server Đã Chấp Nhận Yêu Cầu; Chờ Dữ Liệu Xác Nhận.",
			["Server Request Succeeded But Player Data Did Not Confirm The Change."] = "Server Báo Thành Công Nhưng Dữ Liệu Chưa Xác Nhận Thay Đổi.",
			["Waiting For Server Response; No Duplicate Request Will Be Sent."] = "Đang Chờ Server Phản Hồi; Không Gửi Trùng Yêu Cầu.",
			["Collect Coins Or Unequipped Books; See Requirements Below."] = "Cần Thêm Tiền Hoặc Sách Chưa Gắn Vào Cần; Xem Yêu Cầu Bên Dưới.",
			["Equipped Rod"] = "Cần Đang Trang Bị",
			["Auto Quest Does Not Change Your Rod Or Skill Books."] = "Auto Quest Không Tự Đổi Cần Hoặc Sách Kỹ Năng.",
			["Refresh Unlock Status"] = "Làm Mới Trạng Thái Mở Khóa",
			["No unlocked fish are available."] = "Không Có Cá Chưa Khóa Để Bán.",
			["Staying at the merchant until the next sell attempt."] = "Đang Ở Chỗ Người Bán Cá Để Thử Bán Lại.",
			["Auto Sell resumed after a stuck fishing restart."] = "Tự Động Bán Đã Tiếp Tục Sau Khi Khởi Động Lại Câu Cá Bị Kẹt.",
			["Retrying Auto Sell. Unlock fish if the whole bag is locked."] = "Đang Thử Bán Lại. Hãy Mở Khóa Cá Nếu Cả Túi Đều Bị Khóa.",
			["Cannot walk back to the saved spot. Auto Farm will re-pin at the current position."] = "Không Thể Đi Về Vị Trí Đã Lưu. Auto Farm Sẽ Ghim Lại Tại Vị Trí Hiện Tại.",
			["Please try again in a moment."] = "Vui Lòng Thử Lại Sau Chốc Lát.",
			["Wait for the island NPC to load, then try again."] = "Hãy Đợi NPC Trên Đảo Tải Xong Rồi Thử Lại.",
			["The character stopped outside the merchant's sell radius."] = "Nhân Vật Đã Dừng Ngoài Phạm Vi Bán Của NPC.",
			["Move closer to a Fish Merchant or select Tween in Auto Sell."] = "Hãy Đến Gần Người Bán Cá Hoặc Chọn Tween Trong Tab Tự Động Bán.",
			["Wait for the current travel action to finish."] = "Hãy Đợi Lượt Di Chuyển Hiện Tại Kết Thúc.",
			["Wait for the current movement to finish."] = "Hãy Đợi Nhân Vật Di Chuyển Xong.",
			["The saved fishing position has not been reached. Auto Farm remains paused."] = "Chưa Về Tới Vị Trí Câu Đã Lưu. Tự Động Câu Vẫn Tạm Dừng.",
			["Could not confirm protected fish are locked. Sale postponed."] = "Chưa Xác Nhận Cá Cần Giữ Đã Được Khóa. Đã Hoãn Bán.",
			["Sale was not confirmed, so the character will not return yet."] = "Chưa Xác Nhận Bán Thành Công Nên Nhân Vật Chưa Quay Lại.",
			["Auto Farm stopped because the character moved away from the saved position."] = "Đã Dừng Tự Động Câu Vì Nhân Vật Rời Vị Trí Đã Lưu.",
			["Returned to the saved spot. Auto Farm can resume."] = "Đã Về Vị Trí Câu Đã Lưu. Có Thể Tiếp Tục Tự Động Câu.",
			["The fishing position will be saved when movement finishes."] = "Vị Trí Câu Sẽ Được Lưu Khi Di Chuyển Xong.",
			["The current fishing position and facing direction were saved."] = "Đã Lưu Vị Trí Và Hướng Đứng Khi Câu.",
			["Auto Farm will stop if you move more than 8 studs away."] = "Tự Động Câu Sẽ Dừng Nếu Bạn Rời Xa Hơn 8 Stud.",
			["Walked to the saved fishing position."] = "Đã Đi Đến Vị Trí Câu Đã Lưu.",
			["Player Data Is Not Ready."] = "Dữ Liệu Người Chơi Chưa Sẵn Sàng.",
			["Player data is not ready."] = "Dữ Liệu Người Chơi Chưa Sẵn Sàng.",
			["Select An Island."] = "Hãy Chọn Một Đảo.",
			[" Is Unlocked."] = " Đã Được Mở Khóa.",
			["Quest Not Started"] = "Nhiệm Vụ Chưa Bắt Đầu",
			["Level "] = "Cấp ",
			["; Cost: "] = "; Giá: ",
			[" Coins"] = " Xu",
			[". Status: "] = ". Trạng Thái: ",
			[" Is Already Unlocked."] = " Đã Được Mở Khóa.",
			["Unlock "] = "Mở Khóa ",
			[" First."] = " Trước.",
			[" Unlock Quest Is Already Active."] = " Đang Có Nhiệm Vụ Mở Khóa.",
			["Complete Or Cancel "] = "Hoàn Thành Hoặc Hủy ",
			["Collect The Requirements For "] = "Thu Thập Đủ Điều Kiện Cho ",
			["Requirements Not Met."] = "Chưa Đủ Điều Kiện.",
			["Start The "] = "Hãy Bắt Đầu Nhiệm Vụ ",
			[" Unlock Quest First."] = " Để Mở Đảo Trước.",
			["Check The Quest Requirements."] = "Hãy Kiểm Tra Điều Kiện Nhiệm Vụ.",
			[" Is Now Unlocked."] = " Đã Được Mở Khóa.",
			["Tweening to "] = "Đang Tween Đến ",
			[" at "] = " Với Tốc Độ ",
			[" studs per second."] = " Stud Mỗi Giây.",
			["Arrived at "] = "Đã Đến ",
			["Island tween was cancelled."] = "Đã Hủy Tween Giữa Các Đảo.",
			["The destination island has no loaded landing point yet."] = "Đảo Đích Chưa Tải Điểm Đến.",
			["You are already on the selected island."] = "Bạn Đã Ở Trên Đảo Đã Chọn.",
			["The island did not confirm arrival."] = "Game Chưa Xác Nhận Đã Đến Đảo.",
			["Start A Quest In Game Or Select One In This Tab."] = "Hãy Nhận Nhiệm Vụ Trong Game Hoặc Chọn Một Nhiệm Vụ Ở Tab Này.",
			["Finish Or Cancel "] = "Hoàn Thành Hoặc Hủy ",
			["Tween to "] = "Tween Đến ",
			[" failed: "] = " Thất Bại: ",
			["Quest Island Not Found."] = "Không Tìm Thấy Đảo Của Nhiệm Vụ.",
			["Fishing For "] = "Đang Câu Cho Nhiệm Vụ ",
			["Requirements Ready; Claiming Quest."] = "Đã Đủ Điều Kiện; Đang Nhận Thưởng Nhiệm Vụ.",
			["Requirements Not Ready."] = "Chưa Đủ Điều Kiện.",
			["Distance unavailable"] = "Không Đo Được Khoảng Cách",
			[" studs away"] = " Stud Cách Xa",
			["Unknown Island"] = "Đảo Không Rõ",
			["Bought "] = "Đã Mua ",
			["Purchase failed; check balance and requirements."] = "Mua Thất Bại; Hãy Kiểm Tra Số Dư Và Điều Kiện.",
			["You already own this rod."] = "Bạn Đã Sở Hữu Cần Câu Này.",
			["Unlock the rod's island first."] = "Hãy Mở Khóa Đảo Của Cần Câu Trước.",
			["Not enough "] = "Không Đủ ",
			["Next claim in "] = "Có Thể Nhận Tiếp Sau ",
			["Claimed day "] = "Đã Nhận Thưởng Ngày ",
			["Claim rejected by game."] = "Game Đã Từ Chối Nhận Thưởng.",
			["Group reward is unavailable."] = "Thưởng Nhóm Hiện Không Khả Dụng.",
			["Already claimed."] = "Đã Nhận Rồi.",
			["Join the game's group, then claim again."] = "Hãy Vào Nhóm Của Game Rồi Nhận Lại.",
			["Claimed group reward."] = "Đã Nhận Thưởng Nhóm.",
			["Claim failed."] = "Nhận Thưởng Thất Bại.",
			["Claim request sent. Check your gift inbox."] = "Đã Gửi Yêu Cầu Nhận Quà. Hãy Kiểm Tra Hộp Quà.",
			["Claim request failed."] = "Yêu Cầu Nhận Quà Thất Bại.",
			["Code redeemed."] = "Đã Đổi Mã Thành Công.",
			["Invalid code."] = "Mã Không Hợp Lệ.",
			["Code expired."] = "Mã Đã Hết Hạn.",
			["Code already redeemed."] = "Mã Đã Được Dùng.",
			["Requirements not met."] = "Chưa Đủ Điều Kiện.",
			["Save failed; retry later."] = "Lưu Thất Bại; Hãy Thử Lại Sau.",
			["Redemption is busy."] = "Hệ Thống Đổi Mã Đang Bận.",
			["Migrated game passes added."] = "Đã Thêm Game Pass Được Chuyển Đổi.",
			["Unknown response."] = "Phản Hồi Không Rõ.",
			["Request failed."] = "Yêu Cầu Thất Bại.",
			["Pro Mode Applied To The Map And VFX."] = "Đã Áp Dụng Giảm Lag Pro Cho Bản Đồ Và VFX.",
			["Textures And VFX Have Been Reduced."] = "Đã Giảm Texture Và VFX.",
			["Pro Mode Is Already Active."] = "Giảm Lag Pro Đã Được Bật.",
			["Saved: "] = "Đã Lưu: ",
			["Save config failed: "] = "Lưu Cấu Hình Thất Bại: ",
			["Loaded: "] = "Đã Tải: ",
			["Load config failed: "] = "Tải Cấu Hình Thất Bại: ",
			["Deleted: "] = "Đã Xóa: ",
			["Delete config failed: "] = "Xóa Cấu Hình Thất Bại: ",
			["Auto load set to: "] = "Đã Đặt Tự Tải: ",
			["Auto Loaded Config ("] = "Đã Tự Tải Cấu Hình (",
			["The saved position is being retried ("] = "Đang Thử Trở Về Vị Trí Đã Lưu (",
			["Auto Detect Quest"] = "Tự Tìm Nhiệm Vụ",
			["Auto (Roblox)"] = "Tự Động (Roblox)",
			["Fish Caught: %d | Coins Earned: %s | Time: %s"] = "Cá Đã Câu: %d | Xu Kiếm Được: %s | Thời Gian: %s",
			["BOSS: "] = "BOSS: ",
			["LAST SEEN: "] = "THẤY LẦN CUỐI: ",
			[" studs"] = " Stud",
			Confirmed = "Đã Xác Nhận",
			["Boss Encounter"] = "Vùng Boss",
			["Boss Zone Active"] = "Vùng Boss Đang Hoạt Động",
			["Spawn Preview"] = "Dự Kiến Khi Xuất Hiện",
			["Weather Preview"] = "Dự Kiến Theo Thời Tiết",
			["Observed Boss"] = "Boss Đã Được Quan Sát",
			["Your Boss Confirmed"] = "Đã Xác Nhận Boss Của Bạn",
			["Last Seen"] = "Thấy Lần Cuối",
			["+%s Coins (%d Fish) • %s"] = "+%s Xu (%d Cá) • %s",
			["Bring 3 Legendary Fish From Desert Island"] = "Mang 3 Cá Legendary Từ Đảo Sa Mạc",
			["Bring Frozen Crown Dragonfish, Frosttusk Seal, And Frostmaw Monster From Snow Island"] = "Mang Frozen Crown Dragonfish, Frosttusk Seal Và Frostmaw Monster Từ Đảo Tuyết",
			["Bring Ancient Trihorn Fish (1,200 Kg), Stormblade Shark (2,000 Kg), And Lavascale Dragonfish (2,500 Kg) From Volcanic Island"] = "Mang Ancient Trihorn Fish (1.200 Kg), Stormblade Shark (2.000 Kg) Và Lavascale Dragonfish (2.500 Kg) Từ Đảo Núi Lửa",
		},
	}
	local flag25 = false
	pcall(function()
		local language = tbl.read().language
		if type(language) == "table" then
			local mode = language.mode
			if mode == "auto" or mode == "vi" or mode == "en" then
				tbl2.mode = mode
				flag25 = true
			end
		end
	end)
	if not flag25 then
		local huneHubFishingLanguageMode = genv.HuneHubFishingLanguageMode
		if huneHubFishingLanguageMode == "auto" or huneHubFishingLanguageMode == "vi" or huneHubFishingLanguageMode == "en" then
			tbl2.mode = huneHubFishingLanguageMode
		end
	end
	tbl2.detect = function()
		local localeId = nil
		pcall(function()
			localeId = localPlayer.LocaleId
		end)
		if type(localeId) ~= "string" or localeId == "" then
			pcall(function()
				localeId = game:GetService("LocalizationService").RobloxLocaleId
			end)
		end
		return (type(localeId) == "string" and localeId:lower():match("^[a-z][a-z]") or nil) == "vi" and "vi" or "en"
	end
	tbl2.code = tbl2.mode == "auto" and tbl2.detect() or tbl2.mode
	tbl2.text = function(arg)
		if tbl2.code ~= "vi" or type(arg) ~= "string" then
			return arg
		end
		if tbl2.vi[arg] then
			return tbl2.vi[arg]
		end
		for k, v5 in pairs(tbl2.vi) do
			if k:sub(-1) == " " and arg:sub(1, #k) == k then
				return v5 .. arg:sub(#k + 1)
			end
		end
		return arg
	end
	tbl2.save = function(arg)
		if arg ~= "auto" and arg ~= "vi" and arg ~= "en" then
			return false
		end
		return tbl.update(function(arg2)
			arg2.language = { mode = arg }
		end)
	end
	tbl2.toEnglish = function(arg)
		if type(arg) ~= "string" then
			return arg
		end
		if not tbl2.reverse then
			local reverse = {}
			for k, v5 in pairs(tbl2.vi) do
				reverse[v5] = reverse[v5] or k
			end
			reverse["Thông Tin"] = "Info"
			tbl2.reverse = reverse
		end
		if tbl2.reverse[arg] then
			return tbl2.reverse[arg]
		end
		for k, v5 in pairs(tbl2.reverse) do
			if k:sub(-1) == " " and arg:sub(1, #k) == k then
				return v5 .. arg:sub(#k + 1)
			end
		end
		return arg
	end
	tbl2.refreshGui = function(arg)
		tbl2.originalText = tbl2.originalText or setmetatable({}, { __mode = "k" })
		for _, v5 in pairs({ arg.ScreenGui, arg.NotificationGui, arg.DropdownGui, arg.TooltipGui }) do
			if typeof(v5) == "Instance" then
				local function fn26(arg2)
					pcall(function()
						if arg2:IsA("TextLabel") or arg2:IsA("TextButton") then
							local v6 = tbl2.originalText[arg2]
							local flag26 = not v6
							local flag27
							if flag26 then
								flag27 = flag26
							else
								flag27 = arg2.Text ~= v6
								if flag27 then
									flag27 = arg2.Text ~= (tbl2.vi[v6] or v6)
								end
							end
							if flag27 then
								v6 = tbl2.toEnglish(arg2.Text)
								tbl2.originalText[arg2] = v6
							end
							local v7 = tbl2.text(v6)
							if v7 ~= arg2.Text then
								arg2.Text = v7
							end
						elseif arg2:IsA("TextBox") then
							local v6 = tbl2.originalText[arg2]
							local flag26 = not v6
							if not flag26 then
								flag26 = arg2.PlaceholderText ~= v6
								if flag26 then
									flag26 = arg2.PlaceholderText ~= (tbl2.vi[v6] or v6)
								end
							end
							if flag26 then
								v6 = tbl2.toEnglish(arg2.PlaceholderText)
								tbl2.originalText[arg2] = v6
							end
							local v7 = tbl2.text(v6)
							if v7 ~= arg2.PlaceholderText then
								arg2.PlaceholderText = v7
							end
						end
					end)
				end
				fn26(v5)
				pcall(function()
					for _, descendant in ipairs(v5:GetDescendants()) do
						fn26(descendant)
					end
				end)
			end
		end
	end
	text = tbl2.text
	lib = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
	pcall(function()
		lib:SetParent(playerGui)
	end)
	lib:AddTheme({
		Name = "Mocha",
		Accent = "#89b4fa",
		Background = "#1e1e2e",
		Outline = "#313244",
		Text = "#cdd6f4",
		PlaceholderText = "#a6adc8",
	})
	lib:AddTheme({
		Name = "Latte",
		Accent = "#1e66f5",
		Background = "#eff1f5",
		Outline = "#bcc0cc",
		Text = "#4c4f69",
		PlaceholderText = "#6c6f85",
	})
	lib:AddTheme({
		Name = "Aqua",
		Accent = "#06b6d4",
		Background = "#0f172a",
		Outline = "#1e293b",
		Text = "#f8fafc",
		PlaceholderText = "#94a3b8",
	})
	lib:AddTheme({
		Name = "Amethyst",
		Accent = "#a855f7",
		Background = "#1a1025",
		Outline = "#3b0764",
		Text = "#f3e8ff",
		PlaceholderText = "#d8b4fe",
	})
	lib:AddTheme({
		Name = "Transparent",
		Accent = "#888888",
		Background = "#444444",
		Outline = "#666666",
		Text = "#ffffff",
		PlaceholderText = "#bbbbbb",
	})
	local notify = lib.Notify
	lib.Notify = function(arg, arg2)
		if type(arg2) == "table" then
			pcall(function()
				arg2.Title = text(arg2.Title)
				arg2.Content = text(arg2.Content)
			end)
		end
		pcall(notify, arg, arg2)
	end
	local Stardust = require(ReplicatedStorage:WaitForChild("Stardust"))
	client = Stardust.Client
	packet = Stardust.Packet
	data = ReplicatedStorage:WaitForChild("Data")
	FishingPackets = require(data:WaitForChild("Packets"):WaitForChild("FishingPackets"))
	FishingConfig = require(data:WaitForChild("Config"):WaitForChild("FishingConfig"))
	FishingEnums = require(data:WaitForChild("Enums"):WaitForChild("FishingEnums"))
	local PullBarMath = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Lib"):WaitForChild("PullBarMath"))
	SellEnums = require(data:WaitForChild("Enums"):WaitForChild("SellEnums"))
	local FishStorageRules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Lib"):WaitForChild("FishStorageRules"))
	AuraGachaConfig = require(data:WaitForChild("Config"):WaitForChild("AuraGachaConfig"))
	SkillGachaConfig = require(data:WaitForChild("Config"):WaitForChild("SkillGachaConfig"))
	CrateConfig = require(data:WaitForChild("Config"):WaitForChild("CrateConfig"))
	RodShopConfig = require(data:WaitForChild("Config"):WaitForChild("RodShopConfig"))
	IslandConfig = require(data:WaitForChild("Config"):WaitForChild("IslandConfig"))
	RarityEnums = require(data:WaitForChild("Enums"):WaitForChild("RarityEnums"))
	Catalog = require(data:WaitForChild("Catalog"))
	PlayerDataV2Controller = require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("PlayerDataV2Controller"))
	FishingController = nil
	local RodController = nil
	LootController = nil
	pcall(function()
		FishingController = client.GetController("FishingController")
		RodController = client.GetController("RodController")
		LootController = client.GetController("LootController")
	end)
	local v5 = packet("SellAll"):Response(packet.NumberU8, packet.NumberF64, packet.NumberU16)
	v = packet("PurchaseRod", packet.String):Response(packet.Boolean8)
	v2 = packet("DailyReward/Claim"):Response(packet.Boolean8)
	ClaimAll = packet("GiftService/ClaimAll")
	local v6 = packet("SellToggleLock", packet.String):Response(packet.NumberU8, packet.Boolean8)
	BossSpawnSound = packet("BossSpawnSound")
	tbl3 = {}
	tbl4 = {}
	local function fn26()
		local tbl13 = {}
		pcall(function()
			for _, v7 in pairs(Catalog.Island.GetAll()) do
				local id = v7.id or v7.Id
				local name = v7.name or v7.Name
				if type(id) == "string" and type(name) == "string" then
					table.insert(tbl13, {
						id = id,
						name = name,
						order = tonumber(v7.order or v7.Order) or 999,
						defaultUnlocked = v7.defaultUnlocked == true,
					})
				end
			end
		end)
		if #tbl13 == 0 then
			tbl13 = {}
			local v7 = tbl13
			v7[1] = { id = "island_starter", name = "Starter Island", order = 1, defaultUnlocked = true }
			v7[2] = { id = "island_jungle", name = "Jungle Island", order = 2, defaultUnlocked = false }
			v7[3] = { id = "island_desert", name = "Desert Island", order = 3, defaultUnlocked = false }
			v7[4] = { id = "island_snow", name = "Snow Island", order = 4, defaultUnlocked = false }
			v7[5] = { id = "island_volcano", name = "Volcanic Island", order = 5, defaultUnlocked = false }
			v7[6] = { id = "island_fossil", name = "Fossil Island", order = 6, defaultUnlocked = false }
		end
		table.sort(tbl13, function(arg, arg2)
			if arg.order == arg2.order then
				return arg.name < arg2.name
			end
			return arg.order < arg2.order
		end)
		for _, v7 in ipairs(tbl13) do
			tbl3[v7.name] = v7
			table.insert(tbl4, v7.name)
		end
	end
	fn26()
	flag = true
	resumeSoldFish = false
	flag2 = false
	flag3 = false
	flag4 = false
	flag5 = false
	flag6 = false
	n = 0.35
	local n18 = 1 / math.max(FishingConfig.GetClickCps and FishingConfig.GetClickCps("Manual") or FishingConfig.Click and FishingConfig.Click.ManualCps or 6, 1)
	n2 = math.max((FishingConfig.Latency and FishingConfig.Latency.QteReactionFloor or 0.1) + 0.12, (FishingConfig.Counter and FishingConfig.Counter.StrictInputSettleTime or 0.08) + 0.1)
	flag7 = false
	n3 = 0
	n4 = 0
	local finisherPct = FishingConfig.Fight and FishingConfig.Fight.FinisherPct or 0.075
	n5 = 0
	n6 = 0
	n7 = 0
	flag8 = false
	n8 = 0
	local flag26 = false
	tbl5 = {
		nextIndex = 1,
		order = { "Slot1", "Slot2", "Slot3", "Slot4" },
		spamEnabled = false,
		spamNextIndex = 1,
		spamInterval = 0.15,
		spamOrder = { "Slot1", "Slot2", "Slot3", "Slot4" },
		isEnabled = function()
			return flag6 or tbl5.spamEnabled
		end,
		setOrder = function(arg)
			local order = {}
			local tbl13 = {}
			local tbl14 = { Z = "Slot1", X = "Slot2", C = "Slot3", V = "Slot4" }
			local str = tostring(arg or "")
			if str:match("^%s*$") then
				str = "Z,X,C,V"
			end
			for match in str:upper():gmatch("[^,%s>]+") do
				local v7 = tbl14[match]
				if not v7 then
					return false
				end
				if not tbl13[v7] then
					table.insert(order, v7)
					tbl13[v7] = true
				end
			end
			if #order == 0 then
				return false
			end
			tbl5.order = order
			tbl5.spamOrder = order
			tbl5.nextIndex = 1
			tbl5.spamNextIndex = 1
			return true
		end,
	}
	local fishingMaster = tbl.read().fishingMaster
	local skillComboOrder = type(fishingMaster) == "table" and fishingMaster.skillComboOrder
	tbl5.defaultOrder = type(skillComboOrder) == "string" and skillComboOrder or "Z,X,C,V"
	if not tbl5.setOrder(tbl5.defaultOrder) then
		tbl5.defaultOrder = "Z,X,C,V"
		tbl5.setOrder(tbl5.defaultOrder)
	end
	tbl5.saveOrderSoon = function(skillComboOrder2)
		tbl5.saveRevision = (tbl5.saveRevision or 0) + 1
		local saveRevision = tbl5.saveRevision
		task.delay(0.7, function()
			if saveRevision ~= tbl5.saveRevision then
				return
			end
			tbl.update(function(arg)
				arg.fishingMaster = type(arg.fishingMaster) == "table" and arg.fishingMaster or {}
				arg.fishingMaster.skillComboOrder = skillComboOrder2
			end)
		end)
	end
	local flag27 = false
	flag9 = false
	flag10 = false
	flag11 = false
	flag12 = false
	n9 = 0
	flag13 = false
	n10 = 60
	n11 = 0
	flag14 = false
	cFrame = nil
	flag15 = false
	tbl6 = {
		pending = false,
		attempts = 0,
		retryAt = 0,
		method = "Walk",
		tweenSpeed = 30,
		farmSpotPending = false,
		waterWalkEnabled = true,
		waitDelay = 3,
		lastUsedRouteId = nil,
		lastReturnReason = nil,
		lastFailureKey = nil,
		lastFailureAt = 0,
		saleAttempts = 0,
		saleRetryAt = 0,
		lastSaleReason = nil,
		resumeFarm = false,
		resumeStage = 0,
		resumeAt = 0,
		resumeCancelAt = 0,
		resumeTarget = nil,
		resumeCharacter = nil,
		resumeCastAt = 0,
		rodId = nil,
		bagRefreshAfter = 0,
		saleHadFish = false,
		resumeSoldFish = false,
		watchdogAt = 0,
		resumeFarmSince = 0,
		lastEmptyNotifyAt = 0,
		shouldSellFull = function()
			return flag10
		end,
	}
	flag16 = false
	flag17 = true
	flag18 = false
	flag19 = false
	cFrame2 = nil
	cFrame3 = nil
	flag20 = false
	genv.HuneHubTravelSpeed = 70
	now = tick()
	n12 = 0
	n13 = 0
	flag21 = false
	local n19 = 0
	flag22 = false
	n14 = 0
	n15 = 0
	flag23 = false
	n16 = 0
	flag24 = false
	idling = FishingEnums.State.Idling
	v3 = nil
	now2 = os.clock()
	n17 = 0
	tbl7 = {}
	fn = nil
	fn2 = function(arg)
		table.insert(tbl7, arg)
		return arg
	end
	tbl8 = {
		farmEnabled = false,
		farmRarities = { Legendary = true, Mythical = true, Divine = true },
		skipPending = false,
		skipAt = 0,
		lastCancelAt = -math.huge,
		currentFishId = nil,
		sellEnabled = false,
		sellRarities = { Legendary = true, Mythical = true, Divine = true },
		locking = false,
		lockQueued = false,
		lockAgain = false,
		lastLockAttempt = {},
		verifiedLocked = {},
		observedLocked = {},
		setSelected = function(arg, arg2, arg3)
			table.clear(arg2)
			if type(arg3) == "string" then
				arg2[arg3] = true
			elseif type(arg3) == "table" then
				for k, v7 in pairs(arg3) do
					local flag28 = type(k) == "number" and v7
					if flag28 then
						k = flag28
					else
						k = v7 == true and k or nil
					end
					if type(k) == "string" then
						arg2[k] = true
					end
				end
			end
		end,
		matches = function(arg, arg2, arg3)
			local flag28 = type(arg2) == "string" and Catalog.Fish.GetById(arg2)
			return flag28 and arg3[flag28.rarity] == true or false
		end,
		shouldSkip = function(arg, arg2)
			return resumeSoldFish and arg.farmEnabled and type(arg2) == "string" and arg2 ~= "" and not arg:matches(arg2, arg.farmRarities)
		end,
		skipCurrent = function(arg)
			if not arg.skipPending then
				arg.skipPending = true
				arg.skipAt = os.clock()
				n15 += 1
				flag23 = false
				n7 += 1
				flag8 = false
				flag21 = false
				n14 += 1
				flag22 = false
				n3 += 1
				flag7 = false
				n17 = os.clock() + math.max(n, 0.3)
			end
			local lastCancelAt = arg.lastCancelAt
			if os.clock() - lastCancelAt >= 0.3 then
				arg.lastCancelAt = os.clock()
				pcall(function()
					FishingPackets.FishCancel:Fire()
				end)
			end
		end,
		allowsCurrent = function(arg)
			if arg.skipPending then
				return false
			end
			if not (resumeSoldFish and arg.farmEnabled) then
				return true
			end
			local currentFishId = arg.currentFishId
			if not currentFishId and FishingController then
				pcall(function()
					currentFishId = FishingController:GetFishInfo()
				end)
				arg.currentFishId = currentFishId
			end
			if type(currentFishId) ~= "string" or currentFishId == "" then
				return false
			end
			if arg:shouldSkip(currentFishId) then
				arg:skipCurrent()
				return false
			end
			return true
		end,
		applyLocks = function(arg)
			if not arg.sellEnabled then
				return true
			end
			if not next(arg.sellRarities) then
				return true
			end
			local v7 = PlayerDataV2Controller:Fetch(localPlayer)
			local fishes = v7 and v7.Inventory and v7.Inventory.Fishes
			if type(fishes) ~= "table" then
				return false
			end
			local flag28 = true
			for k, fishe in pairs(fishes) do
				if not (not flag or not arg.sellEnabled) then
					if type(fishe) == "table" then
						local uid = fishe.uid or k
						if fishe.locked == true then
							arg.verifiedLocked[uid] = true
							arg.observedLocked[uid] = true
						elseif arg.observedLocked[uid] then
							arg.verifiedLocked[uid] = nil
							arg.observedLocked[uid] = false
						end
						if fishe.locked ~= true and not arg.verifiedLocked[uid] and arg:matches(fishe.fishId, arg.sellRarities) then
							if type(uid) == "string" then
								local now3 = os.clock()
								if now3 - (arg.lastLockAttempt[uid] or -math.huge) >= 2 then
									arg.lastLockAttempt[uid] = now3
									local ok, result, result2 = pcall(function()
										return v6:Fire(uid)
									end)
									if not ok or result ~= SellEnums.Status.Ok or result2 ~= true then
										flag28 = false
									else
										arg.verifiedLocked[uid] = true
									end
									task.wait(0.08)
								else
									flag28 = false
								end
							else
								flag28 = false
							end
						end
					end
					continue
				end
				break
			end
			return flag28
		end,
		queueLocks = function(arg)
			if not arg.sellEnabled or not flag then
				return
			end
			if not next(arg.sellRarities) then
				return
			end
			if arg.locking then
				arg.lockAgain = true
				return
			end
			if arg.lockQueued then
				return
			end
			arg.lockQueued = true
			task.delay(0.2, function()
				arg.lockQueued = false
				if not flag or not arg.sellEnabled then
					return
				end
				if arg.locking then
					arg.lockAgain = true
					return
				end
				arg.locking = true
				pcall(function()
					arg:applyLocks()
				end)
				arg.locking = false
				if arg.lockAgain then
					arg.lockAgain = false
					arg:queueLocks()
				end
			end)
		end,
	}
	fn2(PlayerDataV2Controller:Listen(localPlayer, function()
		tbl8:queueLocks()
	end))
	local function fn27()
		local tbl13 = {
			active = true,
			players = {},
			connections = {},
			folderConnections = {},
			folder = nil,
			revision = 0,
			saveRevision = 0,
			rendered = nil,
		}
		local tbl14 = { "#FF4D4D", "#FF9F1C", "#FFE66D", "#4ADE80", "#22D3EE", "#60A5FA", "#C084FC" }
		local tbl15 = {
			"天",
			"地",
			"人",
			"火",
			"水",
			"木",
			"金",
			"土",
			"龍",
			"虎",
			"風",
			"雷",
			"光",
			"闇",
			"刀",
			"剣",
			"魂",
			"力",
			"鬼",
			"神",
			"夢",
			"空",
			"心",
			"道",
			"月",
			"星",
			"影",
			"炎",
			"氷",
			"雪",
			"海",
			"山",
		}
		local function fn28()
			return flag and tbl13.active
		end
		local function fn29(arg, arg2, arg3)
			local connection = arg2:Connect(arg3)
			table.insert(arg, connection)
			return connection
		end
		local function fn30(arg)
			for _, v7 in ipairs(arg) do
				pcall(function()
					v7:Disconnect()
				end)
			end
			table.clear(arg)
		end
		local function fn31(arg, arg2)
			local tbl16 = {}
			return pcall(function()
				assert(utf8.len(arg) ~= nil, "Invalid UTF8 name")
				for k, v7 in utf8.graphemes(arg) do
					table.insert(tbl16, arg:sub(k, v7))
					if not (#tbl16 >= arg2) then
						continue
					end
					break
				end
			end) and tbl16 or nil
		end
		local function fn32(arg)
			local match = tostring(arg or ""):gsub("[%c]", " "):gsub("%s+", " "):match("^%s*(.-)%s*$") or ""
			if match == "" then
				return "LunarX Hub"
			end
			local v7 = fn31(match, 24)
			if not v7 or #v7 == 0 then
				return "LunarX Hub"
			end
			return table.concat(v7)
		end
		local fishingMaster2 = tbl.read().fishingMaster
		local v7 = fn32(type(fishingMaster2) == "table" and fishingMaster2.customRainbowName)
		local function fn33(arg)
			return arg:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
		end
		local function fn34(arg, arg2, arg3)
			local v8 = table.clone(tbl14)
			if arg3 then
				for i = #v8, 2, -1 do
					local n20 = math.random(1, i)
					local v9 = v8[i]
					v8[i] = v8[n20]
					v8[n20] = v9
				end
			end
			local tbl16 = {}
			local v9, v10, v11 = ipairs(arg)
			local n20 = 0
			for k, v12 in v9, v10, v11 do
				if v12 == " " then
					tbl16[k] = " "
				else
					n20 += 1
					tbl16[k] = string.format("<font color=\"%s\">%s</font>", v8[(n20 - 1 + arg2) % #v8 + 1], fn33(v12))
				end
			end
			return table.concat(tbl16)
		end
		local function fn35(arg)
			local label = arg.label
			if not fn28() or not label or not label.Parent then
				return
			end
			arg.writingLabel = true
			arg.lastText = tbl13.rendered or fn33(v7)
			pcall(function()
				label.RichText = true
				label.Text = arg.lastText
			end)
			arg.writingLabel = false
		end
		local function fn36(arg)
			fn30(arg.labelConnections)
			local label = arg.label
			if label then
				pcall(function()
					if label.Text == arg.lastText then
						label.RichText = arg.originalRichText
						label.Text = arg.originalText
					end
				end)
			end
			arg.label = nil
			arg.lastText = nil
		end
		local fn37 = nil
		fn37 = function(arg)
			local tag = arg.tag
			tag = tag and tag:FindFirstChild("PlrName")
			tag = tag and tag:FindFirstChild("Surface")
			tag = tag and tag:FindFirstChild("Label")
			if not tag or not tag:IsA("TextLabel") or arg.label == tag then
				return
			end
			fn36(arg)
			arg.label = tag
			local richText = tag.RichText
			arg.originalText = tag.Text
			arg.originalRichText = richText
			fn29(arg.labelConnections, tag:GetPropertyChangedSignal("Text"), function()
				if not fn28() or arg.writingLabel or arg.label ~= tag then
					return
				end
				if tag.Text ~= arg.lastText then
					arg.originalText = tag.Text
					fn35(arg)
				end
			end)
			fn29(arg.labelConnections, tag:GetPropertyChangedSignal("RichText"), function()
				if not fn28() or arg.writingLabel or arg.label ~= tag then
					return
				end
				if not tag.RichText then
					arg.originalRichText = false
					fn35(arg)
				end
			end)
			fn29(arg.labelConnections, tag.AncestryChanged, function()
				if arg.label == tag and (not arg.tag or not tag:IsDescendantOf(arg.tag)) then
					fn36(arg)
					if fn28() then
						fn37(arg)
					end
				end
			end)
			fn35(arg)
		end
		local function fn38(arg)
			fn30(arg.tagConnections)
			fn36(arg)
			arg.tag = nil
		end
		local fn39 = nil
		fn39 = function(arg)
			local folder = tbl13.folder and tbl13.folder:FindFirstChild(arg.player.Name)
			if folder == arg.tag then
				if folder then
					fn37(arg)
				end
				return
			end
			fn38(arg)
			if not fn28() or not folder then
				return
			end
			arg.tag = folder
			fn29(arg.tagConnections, folder.DescendantAdded, function()
				fn37(arg)
			end)
			fn29(arg.tagConnections, folder.AncestryChanged, function()
				if arg.tag == folder and folder.Parent ~= tbl13.folder then
					fn38(arg)
					if fn28() then
						fn39(arg)
					end
				end
			end)
			fn37(arg)
		end
		local function fn40(arg)
			fn30(arg.humanoidConnections)
			local humanoid = arg.humanoid
			if humanoid then
				pcall(function()
					if humanoid.DisplayName == arg.lastDisplayName then
						humanoid.DisplayName = arg.originalDisplayName
					end
				end)
			end
			arg.humanoid = nil
			arg.lastDisplayName = nil
		end
		local function fn41(arg)
			if not fn28() or not arg.humanoid then
				return
			end
			arg.writingHumanoid = true
			arg.lastDisplayName = v7
			pcall(function()
				arg.humanoid.DisplayName = v7
			end)
			arg.writingHumanoid = false
		end
		local function fn42(arg)
			local humanoid = arg.character and arg.character:FindFirstChildOfClass("Humanoid")
			if humanoid == arg.humanoid then
				return
			end
			fn40(arg)
			if not fn28() or not humanoid then
				return
			end
			arg.humanoid = humanoid
			arg.originalDisplayName = humanoid.DisplayName
			fn29(arg.humanoidConnections, humanoid:GetPropertyChangedSignal("DisplayName"), function()
				if not fn28() or arg.writingHumanoid or arg.humanoid ~= humanoid then
					return
				end
				if humanoid.DisplayName ~= arg.lastDisplayName then
					arg.originalDisplayName = humanoid.DisplayName
					fn41(arg)
				end
			end)
			fn41(arg)
		end
		local function fn43(arg, character)
			fn30(arg.characterConnections)
			fn40(arg)
			arg.character = character
			if not fn28() or not character then
				return
			end
			fn29(arg.characterConnections, character.ChildAdded, function(arg2)
				if arg2:IsA("Humanoid") then
					fn42(arg)
				end
			end)
			fn29(arg.characterConnections, character.ChildRemoved, function(arg2)
				if arg2 == arg.humanoid then
					fn42(arg)
				end
			end)
			fn42(arg)
		end
		local function fn44(arg)
			if not fn28() or tbl13.players[arg] then
				return
			end
			local tbl16 = {
				player = arg,
				connections = {},
				characterConnections = {},
				humanoidConnections = {},
				tagConnections = {},
				labelConnections = {},
			}
			tbl13.players[arg] = tbl16
			fn29(tbl16.connections, arg.CharacterAdded, function(arg2)
				fn43(tbl16, arg2)
				fn39(tbl16)
			end)
			fn29(tbl16.connections, arg.CharacterRemoving, function(arg2)
				if tbl16.character == arg2 then
					fn43(tbl16, nil)
				end
			end)
			fn43(tbl16, arg.Character)
			fn39(tbl16)
		end
		local function fn45(arg)
			local v8 = tbl13.players[arg]
			if not v8 then
				return
			end
			tbl13.players[arg] = nil
			fn30(v8.connections)
			fn30(v8.characterConnections)
			fn40(v8)
			fn38(v8)
		end
		local function fn46(folder)
			if folder == tbl13.folder then
				return
			end
			fn30(tbl13.folderConnections)
			for _, player in pairs(tbl13.players) do
				fn38(player)
			end
			tbl13.folder = folder
			if not fn28() or not folder then
				return
			end
			fn29(tbl13.folderConnections, folder.ChildAdded, function(arg)
				for k, player in pairs(tbl13.players) do
					if k.Name == arg.Name then
						fn39(player)
						break
					end
				end
			end)
			fn29(tbl13.folderConnections, folder.ChildRemoved, function(arg)
				for _, player in pairs(tbl13.players) do
					if player.tag == arg then
						fn38(player)
						fn39(player)
						break
					end
				end
			end)
			for _, player in pairs(tbl13.players) do
				fn39(player)
			end
		end
		local function fn47(arg, arg2, arg3, arg4)
			if not fn28() or arg4 ~= tbl13.revision then
				return false
			end
			tbl13.rendered = fn34(arg, arg2, arg3)
			for _, player in pairs(tbl13.players) do
				fn35(player)
			end
			return true
		end
		local function fn48(arg)
			local tbl16 = fn31(v7, 24) or {}
			local tbl17 = {}
			for i, v8 in ipairs(tbl16) do
				tbl17[i] = v8 == " " and " " or tbl15[math.random(1, #tbl15)]
			end
			local n20 = 0
			local function fn49()
				n20 = (n20 + 1) % #tbl14
				return fn47(tbl17, n20, false, arg)
			end
			if not fn49() then
				return
			end
			task.wait(0.3)
			for i, v8 in ipairs(tbl16) do
				if v8 ~= " " then
					for i2 = 1, math.random(4, 7) do
						tbl17[i] = tbl15[math.random(1, #tbl15)]
						if not fn49() then
							return
						end
						task.wait(0.055)
					end
				end
				tbl17[i] = v8
				if not fn49() then
					return
				end
				task.wait(0.1)
			end
			if not fn47(tbl16, 0, false, arg) then
				return
			end
			while fn28() and arg == tbl13.revision do
				task.wait(0.25)
				if not fn47(tbl16, 0, true, arg) then
					return
				end
			end
		end
		local function fn49(arg, arg2)
			local v8 = fn32(arg)
			if not fn28() then
				return v8
			end
			if v8 ~= v7 then
				v7 = v8
				tbl13.revision = tbl13.revision + 1
				tbl13.rendered = fn34(fn31(v7, 24), 0, false)
				for _, player in pairs(tbl13.players) do
					fn41(player)
					fn35(player)
				end
				task.spawn(fn48, tbl13.revision)
			end
			if arg2 then
				tbl13.saveRevision = tbl13.saveRevision + 1
				local saveRevision = tbl13.saveRevision
				local v9 = v7
				task.delay(0.5, function()
					if not fn28() or saveRevision ~= tbl13.saveRevision then
						return
					end
					tbl.update(function(arg3)
						arg3.fishingMaster = type(arg3.fishingMaster) == "table" and arg3.fishingMaster or {}
						arg3.fishingMaster.customRainbowName = v9
					end)
				end)
			end
			return v8
		end
		local function fn50()
			if not tbl13.active then
				return
			end
			tbl13.active = false
			local v8 = tbl13
			local saveRevision = tbl13.saveRevision + 1
			tbl13.revision = tbl13.revision + 1
			v8.saveRevision = saveRevision
			fn30(tbl13.connections)
			fn30(tbl13.folderConnections)
			for _, player in pairs(tbl13.players) do
				fn30(player.connections)
				fn30(player.characterConnections)
				fn40(player)
				fn38(player)
			end
			table.clear(tbl13.players)
			tbl13.folder = nil
		end
		tbl13.rendered = fn34(fn31(v7, 24), 0, false)
		fn29(tbl13.connections, Players.PlayerAdded, fn44)
		fn29(tbl13.connections, Players.PlayerRemoving, fn45)
		fn29(tbl13.connections, workspace.ChildAdded, function(arg)
			if arg.Name == "Nametags" then
				fn46(arg)
			end
		end)
		fn29(tbl13.connections, workspace.ChildRemoved, function(arg)
			if arg == tbl13.folder then
				fn46(workspace:FindFirstChild("Nametags"))
			end
		end)
		for _, player in ipairs(Players:GetPlayers()) do
			fn44(player)
		end
		fn46(workspace:FindFirstChild("Nametags"))
		task.spawn(fn48, tbl13.revision)
		fn2({ Disconnect = fn50 })
		return {
			Default = "Hune Hub",
			Get = function()
				return v7
			end,
			Set = fn49,
			Cleanup = fn50,
		}
	end
	v4 = fn27()
	local tbl13 = { Up = "W", Left = "A", Right = "D", W = "W", A = "A", D = "D" }
	local tbl14 = { A = true, W = true, D = true }
	fn3 = function(arg)
		local v7
		pcall(function()
			v7 = FishingConfig.Counter.DirectionToKey[arg]
		end)
		local v8 = v7 or tbl13[arg]
		return tbl14[v8] and v8 or nil
	end
	local tbl15 = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythical = 6, Divine = 7 }
	tbl9 = {
		Aura = {
			name = "Aura",
			enabled = false,
			running = false,
			amount = 10,
			rarity = "Legendary",
			spins = 0,
		},
		Skill = {
			name = "Skill",
			enabled = false,
			running = false,
			amount = 10,
			rarity = "Legendary",
			spins = 0,
		},
		Ocean = {
			name = "Ocean Chest",
			enabled = false,
			running = false,
			amount = 10,
			rarity = "Mythical",
			crateId = "crate_ocean_chest",
			spins = 0,
		},
		Dragon = {
			name = "Dragon Chest",
			enabled = false,
			running = false,
			amount = 10,
			rarity = "Mythical",
			crateId = "crate_dragon_chest",
			spins = 0,
		},
	}
	tbl10 = {
		requestBusy = false,
		controllers = {},
		getController = function(arg)
			local str
			if arg == "Aura" then
				str = "AuraGachaController"
			elseif arg == "Skill" then
				str = "SkillGachaController"
			else
				str = "CrateGachaController"
			end
			local v7 = tbl10.controllers[str]
			if v7 then
				return v7
			end
			local ok, result = pcall(function()
				return client.GetController(str)
			end)
			if not ok or not result then
				return nil
			end
			tbl10.controllers[str] = result
			return result
		end,
		getPacket = function(arg, arg2)
			local v7 = tbl10.getController(arg)
			if not v7 then
				return nil
			end
			local ok, result = pcall(function()
				return v7[arg2]
			end)
			if not ok or not result then
				return nil
			end
			return pcall(function()
				assert(type(result.Fire) == "function")
			end) and result or nil
		end,
	}
	fn4 = function(arg, arg2)
		local tbl16 = {}
		if arg2 then
			local v7 = ipairs
			local tbl17 = CrateConfig.GetPool(arg2) or {}
			for _, v8 in v7(tbl17) do
				local rarity = v8.Item and v8.Item.rarity
				if rarity then
					tbl16[rarity] = true
				end
			end
		else
			local v7 = pairs
			local tbl17 = arg or {}
			for k in v7(tbl17) do
				tbl16[k] = true
			end
		end
		local tbl17 = {}
		for _, v7 in ipairs(RarityEnums.Order) do
			if tbl16[v7] then
				table.insert(tbl17, v7)
			end
		end
		return tbl17
	end
	tbl10.pullOnce = function(arg)
		local Coin
		if arg == "Aura" then
			local v7 = tbl10.getPacket(arg, "Pull")
			if not v7 then
				return nil, "ControllerUnavailable"
			end
			Coin = v7:Fire(1)
		elseif arg == "Skill" then
			local v7 = tbl10.getPacket(arg, "GetQuote")
			local v8 = tbl10.getPacket(arg, "Pull")
			if not v7 or not v8 then
				return nil, "ControllerUnavailable"
			end
			local v9 = v7:Fire(1)
			if type(v9) ~= "table" or not v9.ok then
				return nil, type(v9) == "table" and v9.reason or "QuoteUnavailable"
			end
			Coin = v8:Fire("Coin", 1)
		else
			local v7 = tbl10.getPacket(arg, "OpenPacket")
			if not v7 then
				return nil, "ControllerUnavailable"
			end
			Coin = v7:Fire(tbl9[arg].crateId, 1)
		end
		if type(Coin) ~= "table" then
			return nil, "AmbiguousResponse"
		end
		if not Coin.ok then
			return nil, Coin.reason
		end
		if type(Coin.results) ~= "table" or #Coin.results == 0 then
			return nil, "NoResults"
		end
		return Coin
	end
	local function fn28(arg, arg2)
		arg.enabled = false
		arg.running = false
		if arg.toggle then
			pcall(function()
				if arg.toggle.Set then
					arg.toggle:Set(false)
				elseif arg.toggle.SetValue then
					arg.toggle:SetValue(false)
				end
			end)
		end
		if flag and arg2 then
			local name = arg.name
			lib:Notify({ Title = text("Gacha ") .. name, Content = arg2, Duration = 4 })
		end
	end
	local tbl16 = {
		insufficient_gem = "Not enough Gems.",
		insufficient_coin = "Not enough Coins.",
		storage_full = "Skill storage is full.",
		busy = "The shop is busy. Try again shortly.",
		ControllerUnavailable = "The native gacha controller is unavailable.",
		QuoteUnavailable = "Skill price is unavailable.",
		AmbiguousResponse = "The pull response was missing. Stopped without retry to avoid duplicate spending.",
		NoResults = "The shop returned no item.",
	}
	fn5 = function(arg)
		local v7 = tbl9[arg]
		if not v7 or v7.running or not v7.enabled then
			return
		end
		v7.running = true
		v7.spins = 0
		v7.lastFailure = nil
		task.spawn(function()
			task.wait(0.1)
			local spins = 0
			local exitTo = nil
			local ok, result, result2
			while true do
				local enabled = flag and v7.enabled
				if enabled then
					enabled = spins < math.max(1, math.floor(tonumber(v7.amount) or 10))
				end
				if enabled then
					while flag and v7.enabled and tbl10.requestBusy do
						task.wait(0.05)
					end
					if not flag or not v7.enabled then
						exitTo = 1
						break
					else
						tbl10.requestBusy = true
						ok, result, result2 = pcall(tbl10.pullOnce, arg)
						tbl10.requestBusy = false
						if not ok or not result then
							exitTo = 2
							break
						else
							spins += 1
							v7.spins = spins
							v7.lastFailure = nil
							local n20 = tbl15[v7.rarity] or 5
							local exitTo2 = nil
							for _, result3 in ipairs(result.results) do
								if n20 <= (tbl15[result3.rarity] or 0) then
									exitTo2 = 1
									break
								end
							end
							if exitTo2 ~= 1 then
								if spins < math.max(1, math.floor(tonumber(v7.amount) or 10)) then
									task.wait(0.7)
								end
								continue
							end
						end
					end
				else
					exitTo = 1
					break
				end
				break
			end
			if exitTo == 1 then
				fn28(v7, v7.enabled and ("Reached the %d-spin limit."):format(spins) or nil)
				return
			end
			if exitTo == 2 then
				local lastFailure = tostring(ok and result2 or result)
				v7.lastFailure = lastFailure
				fn28(v7, "Stopped: " .. (tbl16[lastFailure] or lastFailure))
				return
			end
			fn28(v7, string.format("%s (%s) after %d spins", tostring(t4_3.aura_id or t4_3.skill_id or t4_3.rod_skin_id or "?"), tostring(t4_3.rarity), spins))
		end)
	end
	tbl10.getStatus = function()
		local tbl17 = {
			requestBusy = tbl10.requestBusy,
			controllers = {
				Aura = tbl10.getPacket("Aura", "Pull") ~= nil,
				SkillQuote = tbl10.getPacket("Skill", "GetQuote") ~= nil,
				SkillPull = tbl10.getPacket("Skill", "Pull") ~= nil,
				Crate = tbl10.getPacket("Ocean", "OpenPacket") ~= nil,
			},
			modes = {},
		}
		for k, v7 in pairs(tbl9) do
			tbl17.modes[k] = {
				enabled = v7.enabled == true,
				running = v7.running == true,
				spins = v7.spins or 0,
				maximumSpins = v7.amount,
				targetRarity = v7.rarity,
				lastFailure = v7.lastFailure,
			}
		end
		return tbl17
	end
	tbl10.testOnce = function(arg)
		if not tbl9[arg] then
			return nil, "UnknownMode"
		end
		if tbl10.requestBusy then
			return nil, "busy"
		end
		tbl10.requestBusy = true
		local ok, result, result2 = pcall(tbl10.pullOnce, arg)
		tbl10.requestBusy = false
		if not ok then
			return nil, tostring(result)
		end
		return result, result2
	end
	fn6 = function()
		return (localPlayer.Character or localPlayer.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart", 5)
	end
	fn7 = function()
		if not FishingController then
			pcall(function()
				FishingController = client.GetController("FishingController")
			end)
		end
		local state = nil
		if FishingController then
			pcall(function()
				state = FishingController:GetState()
			end)
		end
		return state
	end
	local function fn29(arg)
		if not arg or not arg:IsA("Tool") then
			return false
		end
		local v7 = nil
		pcall(function()
			v7 = Catalog.Rod.GetById(arg.Name)
		end)
		return v7 ~= nil
	end
	fn8 = function(arg)
		local character = localPlayer.Character
		if not character then
			return false
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return false
		end
		if not RodController then
			pcall(function()
				RodController = client.GetController("RodController")
			end)
		end
		for _, child in ipairs(character:GetChildren()) do
			if fn29(child) then
				return true
			end
		end
		local backpack = localPlayer:FindFirstChildOfClass("Backpack")
		if not backpack then
			return false
		end
		local v7 = nil
		for _, child in ipairs(backpack:GetChildren()) do
			if fn29(child) then
				if child.Name == arg then
					v7 = child
					break
				else
					v7 = v7 or child
				end
			end
		end
		if v7 then
			if not pcall(function()
				humanoid:EquipTool(v7)
			end) then
				return false
			end
			local n20 = os.clock() + 0.75
			while true do
				task.wait(0.05)
				if v7.Parent == character then
					return true
				elseif n20 <= os.clock() then
					break
				end
			end
		end
		return false
	end
	local v7 = nil
	local v8 = nil
	local function fn30()
		if v7 and v8 then
			return v7, v8
		end
		if not FishingController then
			pcall(function()
				FishingController = client.GetController("FishingController")
			end)
		end
		if not FishingController or not FishingController.OnStart then
			return nil, nil
		end
		local getupvalues_ = getupvalues or debug and debug.getupvalues
		if not getupvalues_ then
			return nil, nil
		end
		local ok, result = pcall(getupvalues_, FishingController.OnStart)
		local v9 = ok and result and result[41]
		if typeof(v9) ~= "function" then
			return nil, nil
		end
		local ok2, result2 = pcall(getupvalues_, v9)
		if not ok2 or not result2 then
			return nil, nil
		end
		if typeof(result2[5]) ~= "function" or typeof(result2[6]) ~= "function" then
			return nil, nil
		end
		v7 = result2[5]
		v8 = result2[6]
		return v7, v8
	end
	tbl8.getBossCastFunctions = function(arg)
		if arg.bossCastFunctions then
			return arg.bossCastFunctions
		end
		local getupvalues_ = getupvalues or debug and debug.getupvalues
		if not getupvalues_ or not FishingController then
			return nil
		end
		local ok, bossCastFunctions = pcall(function()
			local v9 = getupvalues_(FishingController.OnTick)
			local tryAutoCast = v9.TryAutoCast or v9[14]
			for _, v10 in pairs(v9) do
				if type(v10) == "function" and debug.info(v10, "n") == "TryAutoCast" then
					tryAutoCast = v10
					break
				end
			end
			if type(tryAutoCast) ~= "function" then
				return nil
			end
			local v10 = getupvalues_(tryAutoCast)
			local tbl17 = {
				gates = v10.ResolveLocalCastGates or v10[4],
				setState = v10.SetState or v10[5],
				submit = v10.SubmitCast or v10[7],
			}
			local tbl18 = { ResolveLocalCastGates = "gates", SetState = "setState", SubmitCast = "submit" }
			for _, v11 in pairs(v10) do
				if type(v11) == "function" then
					local v12 = tbl18[debug.info(v11, "n")]
					if v12 then
						tbl17[v12] = v11
					end
				end
			end
			if type(tbl17.gates) ~= "function" or type(tbl17.setState) ~= "function" or type(tbl17.submit) ~= "function" then
				return nil
			end
			return tbl17
		end)
		if ok then
			arg.bossCastFunctions = bossCastFunctions
		end
		return arg.bossCastFunctions
	end
	local function fn31(arg)
		local v9 = fn6()
		if not v9 then
			return Vector3.zero
		end
		local cast = FishingConfig and FishingConfig.Cast or { BaitMinDist = 15, BaitMaxDist = 30 }
		local n20 = cast.BaitMinDist + (arg or 0) * (cast.BaitMaxDist - cast.BaitMinDist)
		local unit = Vector3.new(v9.CFrame.LookVector.X, 0, v9.CFrame.LookVector.Z).Unit
		local n21 = v9.Position.X + unit.X * n20
		local n22 = v9.Position.Z + unit.Z * n20
		local str = ""
		pcall(function()
			local IslandController = client.GetController("IslandController")
			if IslandController then
				str = IslandController:GetCurrentIslandId() or ""
			end
		end)
		local n23 = 3
		pcall(function()
			n23 = Catalog.Island.GetWaterY(str)
		end)
		return Vector3.new(n21, n23, n22)
	end
	fn9 = function()
		task.wait(0.08)
		if tbl6.isBoatTravelBusy and tbl6.isBoatTravelBusy() then
			return false
		end
		if flag20 or flag14 or flag15 or tbl6.pending then
			return false
		end
		local n20 = math.min(math.max((FishingConfig.LuckBar and FishingConfig.LuckBar.Threshold or 0.8) + 0.15, 0.95), 0.98)
		local v9, v10 = fn30()
		if v9 and v10 then
			if pcall(v9) then
				local now3 = os.clock()
				while flag and resumeSoldFish and not flag20 and os.clock() - now3 < 2 do
					local v11 = fn7()
					if v11 == FishingEnums.State.Throwing then
						local luckBarValue = nil
						pcall(function()
							luckBarValue = FishingController:GetLuckBarValue()
						end)
						if type(luckBarValue) == "number" and luckBarValue >= n20 then
							return pcall(v10)
						end
					else
						if v11 == FishingEnums.State.Idling and os.clock() - now3 > 0.3 then
							break
						end
						if v11 ~= FishingEnums.State.Idling and v11 ~= FishingEnums.State.Holding then
							break
						end
					end
					task.wait(0.02)
				end
				pcall(v10)
				return false
			end
		end
		local v11 = fn31(n20)
		return (pcall(function()
			FishingPackets.FishCast:Fire(n20, v11)
		end))
	end
	fn10 = function(arg)
		if not arg then
			return "0"
		end
		if arg >= 1e9 then
			return string.format("%.2fB", arg / 1e9)
		end
		if arg >= 1000000 then
			return string.format("%.2fM", arg / 1000000)
		end
		if arg >= 1000 then
			return string.format("%.1fK", arg / 1000)
		end
		return tostring(math.floor(arg))
	end
	fn11 = function(arg)
		local n20 = math.floor(arg / 3600)
		local n21 = math.floor(arg % 3600 / 60)
		local n22 = math.floor(arg % 60)
		if n20 > 0 then
			return string.format("%dh %02dm %02ds", n20, n21, n22)
		end
		return string.format("%dm %02ds", n21, n22)
	end
	tbl11 = nil
	tbl6.isPositionOverWater = function(arg)
		if not arg then
			return false
		end
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		if localPlayer.Character then
			raycastParams.FilterDescendantsInstances = { localPlayer.Character }
		end
		raycastParams.IgnoreWater = false
		local hit = workspace:Raycast(arg + Vector3.new(0, 5, 0), Vector3.new(0, -35, 0), raycastParams)
		if hit and hit.Material == Enum.Material.Water then
			return true
		end
		local hit2 = workspace:Raycast(arg + Vector3.new(0, 5, 0), Vector3.new(0, -12, 0), raycastParams)
		if not hit2 or hit2.Material == Enum.Material.Water then
			return true
		end
		return false
	end
	tbl6.hasSolidGroundUnder = function(arg, arg2)
		if tbl6.waterWalkActive or tbl11 and (tbl11.Enabled or tbl11.UserEnabled) then
			return true
		end
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = { arg2 or arg.Parent }
		raycastParams.RespectCanCollide = true
		local hit = workspace:Raycast(arg.Position + Vector3.new(0, 1, 0), Vector3.new(0, -10, 0), raycastParams)
		if not hit then
			hit = workspace:Spherecast(arg.Position + Vector3.new(0, 1, 0), 2, Vector3.new(0, -10, 0), raycastParams)
		end
		return hit ~= nil and hit.Material ~= Enum.Material.Water
	end
	tbl6.walkGap = function(arg, arg2)
		local n20 = arg - arg2
		return Vector3.new(n20.X, 0, n20.Z).Magnitude
	end
	tbl6.shouldJumpObstacle = function(arg, arg2, arg3, arg4)
		if not arg or not arg3 then
			return false
		end
		local humanoid = arg3:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return false
		end
		local v9 = arg4 or tbl6.walkContext(arg3, arg, humanoid)
		if v9.jumpHeight < 0.8 then
			return false
		end
		local vector = Vector3.new(arg2.X, 0, arg2.Z)
		if vector.Magnitude < 0.1 then
			return false
		end
		local unit = vector.Unit
		local n20 = arg.Position.Y - v9.lift
		local v10 = nil
		for _, v11 in ipairs({ 0.65, 1.6, 2.5 }) do
			local rays = v9.rays
			local hit = workspace:Raycast(Vector3.new(arg.Position.X, n20 + v11, arg.Position.Z), unit * 3.8, rays)
			if hit and hit.Normal.Y < 0.65 and (not v10 or hit.Distance < v10.Distance) then
				v10 = hit
			end
		end
		if not v10 then
			return false
		end
		local n21 = v10.Position + unit * 0.12
		local rays = v9.rays
		local hit = workspace:Raycast(Vector3.new(n21.X, n20 + v9.jumpHeight + 1, n21.Z), Vector3.new(0, -(v9.jumpHeight + 2), 0), rays)
		if not hit or hit.Normal.Y < 0.65 or hit.Material == Enum.Material.Water and not tbl6.waterWalkActive then
			return false
		end
		local n22 = hit.Position.Y - n20
		if n22 < 0.45 or n22 > v9.jumpHeight then
			return false
		end
		local v11 = workspace
		local bodySize = v9.bodySize
		local rays2 = v9.rays
		if v11:Blockcast(CFrame.new(arg.Position + Vector3.new(0, 0.7, 0)), bodySize, Vector3.new(0, v9.jumpHeight, 0), rays2) then
			return false
		end
		local n23 = math.min(9, humanoid.WalkSpeed * 2 * math.sqrt(2 * v9.jumpHeight / math.max(workspace.Gravity, 1)) * 0.8)
		for i = math.max(3, v10.Distance + 2), n23, 0.75 do
			local n24 = arg.Position + unit * i
			local rays3 = v9.rays
			local hit2 = workspace:Raycast(Vector3.new(n24.X, n20 + v9.jumpHeight + 1, n24.Z), Vector3.new(0, -(v9.jumpHeight + 6), 0), rays3)
			if hit2 and hit2.Normal.Y >= 0.65 and (tbl6.waterWalkActive or hit2.Material ~= Enum.Material.Water) and hit2.Position.Y - n20 <= v9.jumpHeight and hit2.Position.Y >= n20 - 4 then
				local n25 = hit2.Position + Vector3.new(0, v9.lift, 0)
				local n26 = arg.Position + Vector3.new(0, v9.jumpHeight, 0)
				if tbl6.walkFooting(hit2.Position, v9) and tbl6.walkStandingClear(n25, v9) and not workspace:Blockcast(CFrame.lookAt(n26, n26 + unit), v9.bodySize, unit * i, v9.rays) then
					return true
				end
			end
		end
		return false
	end
	tbl6.requestWalkJump = function(arg)
		if not arg or arg.FloorMaterial == Enum.Material.Air then
			return false
		end
		if not arg:GetStateEnabled(Enum.HumanoidStateType.Jumping) then
			arg:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		end
		arg.Jump = true
		arg:ChangeState(Enum.HumanoidStateType.Jumping)
		return true
	end
	tbl11 = {
		Enabled = true,
		UserEnabled = true,
		Platform = nil,
		SteppedConn = nil,
		DiedConn = nil,
		CharAddedConn = nil,
	}
	local function fn32(arg)
		local ok, result = pcall(function()
			local worldConfig = ReplicatedStorage:FindFirstChild("WorldConfig")
			if worldConfig then
				local module = require(worldConfig)
				if module and type(module.SEA_LEVEL) == "number" then
					return module.SEA_LEVEL
				end
			end
		end)
		if ok and type(result) == "number" then
			return result
		end
		local ok2, result2 = pcall(function()
			local IslandController = client and client.GetController and client.GetController("IslandController")
			if IslandController and Catalog and Catalog.Island and type(Catalog.Island.GetWaterY) == "function" then
				local currentIslandId = IslandController:GetCurrentIslandId()
				if currentIslandId then
					local v9 = Catalog.Island.GetWaterY(currentIslandId)
					if type(v9) == "number" then
						return v9
					end
				end
			end
		end)
		if ok2 and type(result2) == "number" then
			return result2
		end
		if arg then
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			local parent = arg.Parent
			if parent then
				raycastParams.FilterDescendantsInstances = { parent }
			end
			raycastParams.IgnoreWater = false
			local hit = workspace:Raycast(Vector3.new(arg.Position.X, 200, arg.Position.Z), Vector3.new(0, -400, 0), raycastParams)
			if hit and hit.Material == Enum.Material.Water then
				return hit.Position.Y
			end
		end
		for _, v9 in ipairs({ "Water", "Ocean", "Sea", "WaterBase-Plane", "WaterPlane" }) do
			local v10 = workspace:FindFirstChild(v9, true)
			if v10 and v10:IsA("BasePart") then
				return v10.Position.Y + v10.Size.Y / 2
			end
		end
		return _bossGameSeaLevel or 3
	end
	local function createPart(arg)
		if tbl11.Platform and tbl11.Platform.Parent then
			return tbl11.Platform
		end
		local part = Instance.new("Part")
		part.Name = "HuneHubWaterWalkPlatform"
		part.Size = Vector3.new(28, 2, 28)
		part.Transparency = 1
		part.CanCollide = true
		part.Anchored = true
		part.CastShadow = false
		part.Material = Enum.Material.SmoothPlastic
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.CFrame = CFrame.new(arg and arg.Position.X or 0, fn32(arg) - 1, arg and arg.Position.Z or 0)
		part.Parent = workspace
		tbl11.Platform = part
		return part
	end
	tbl11.StopPlatformOnly = function()
		if tbl11.SteppedConn then
			tbl11.SteppedConn:Disconnect()
			tbl11.SteppedConn = nil
		end
		if tbl11.DiedConn then
			tbl11.DiedConn:Disconnect()
			tbl11.DiedConn = nil
		end
		if tbl11.Platform and tbl11.Platform.Parent then
			pcall(function()
				tbl11.Platform:Destroy()
			end)
		end
		tbl11.Platform = nil
		for _, child in ipairs(workspace:GetChildren()) do
			if child.Name == "HuneHubWaterWalkPlatform" or child.Name == "HuneHub_Test_WaterPlatform" then
				pcall(function()
					child:Destroy()
				end)
			end
		end
		local character = localPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			pcall(function()
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
			end)
		end
	end
	tbl11.Start = function()
		tbl11.StopPlatformOnly()
		tbl11.Enabled = true
		tbl6.waterWalkActive = true
		local character = localPlayer.Character
		local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not character or not humanoidRootPart or not humanoid or humanoid.Health <= 0 then
			return
		end
		createPart(humanoidRootPart)
		local v9 = fn32(humanoidRootPart)
		pcall(function()
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
		end)
		if humanoidRootPart.Position.Y < v9 + 1 then
			local n20 = v9 + 3
			local rotation = humanoidRootPart.CFrame.Rotation
			humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position.X, n20, humanoidRootPart.Position.Z) * rotation
			humanoidRootPart.AssemblyLinearVelocity = Vector3.new(humanoidRootPart.AssemblyLinearVelocity.X, 0, humanoidRootPart.AssemblyLinearVelocity.Z)
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end
		tbl11.DiedConn = humanoid.Died:Connect(function()
			tbl11.StopPlatformOnly()
		end)
		tbl11.SteppedConn = RunService.Stepped:Connect(function()
			if not tbl11.Enabled then
				return
			end
			local character2 = localPlayer.Character
			local humanoidRootPart2 = character2 and character2:FindFirstChild("HumanoidRootPart")
			character2 = character2 and character2:FindFirstChildOfClass("Humanoid")
			if not humanoidRootPart2 or not character2 or character2.Health <= 0 then
				return
			end
			if character2.SeatPart or character2.Sit then
				local platform = tbl11.Platform
				if platform and platform.Parent then
					platform.CanCollide = false
				end
				return
			end
			local position = humanoidRootPart2.Position
			local v10 = fn32(humanoidRootPart2)
			local platform = tbl11.Platform
			if not platform or not platform.Parent then
				platform = createPart(humanoidRootPart2)
			end
			platform.CFrame = CFrame.new(position.X, v10 - 1, position.Z)
			platform.CanCollide = true
			if position.Y < v10 + 1.2 then
				local rotation = humanoidRootPart2.CFrame.Rotation
				humanoidRootPart2.CFrame = CFrame.new(position.X, v10 + 2.8, position.Z) * rotation
				local z = humanoidRootPart2.AssemblyLinearVelocity.Z
				humanoidRootPart2.AssemblyLinearVelocity = Vector3.new(humanoidRootPart2.AssemblyLinearVelocity.X, math.max(0, humanoidRootPart2.AssemblyLinearVelocity.Y), z)
				character2:ChangeState(Enum.HumanoidStateType.Running)
			end
			local swimming = Enum.HumanoidStateType.Swimming
			if character2:GetState() == swimming then
				character2:ChangeState(Enum.HumanoidStateType.Running)
			end
		end)
	end
	tbl11.Stop = function()
		tbl11.Enabled = false
		tbl11.UserEnabled = false
		tbl6.waterWalkActive = false
		tbl11.StopPlatformOnly()
	end
	tbl11.SetEnabled = function(userEnabled)
		tbl11.UserEnabled = userEnabled
		if userEnabled then
			tbl11.Start()
		else
			tbl11.Stop()
		end
	end
	if not tbl11.CharAddedConn then
		tbl11.CharAddedConn = localPlayer.CharacterAdded:Connect(function(character)
			if tbl11.UserEnabled then
				local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
				local humanoid = character:WaitForChild("Humanoid", 5)
				if humanoidRootPart and humanoid then
					task.wait(0.3)
					if tbl11.UserEnabled then
						tbl11.Start()
					end
				end
			end
		end)
		table.insert(tbl7, tbl11.CharAddedConn)
	end
	task.defer(function()
		pcall(function()
			tbl11.SetEnabled(true)
		end)
	end)
	tbl6.enableWaterWalk = function()
		if tbl6.waterWalkEnabled == false then
			return
		end
		tbl6.waterWalkActive = true
		tbl11.Start()
	end
	tbl6.disableWaterWalk = function()
		tbl6.waterWalkActive = false
		if not tbl11.UserEnabled then
			tbl11.Enabled = false
			tbl11.StopPlatformOnly()
		end
	end
	tbl12 = {
		connections = {},
		original = {},
		wanted = {},
		rodSkinAnimations = {},
		animator = nil,
		animTracks = {},
		playingTracks = {},
		rodSkinList = { "Default" },
		rodSkinMap = {},
		auraList = { "Default" },
		auraMap = {},
		Init = function()
			local ok, result, result2, result3 = pcall(function()
				local data2 = ReplicatedStorage:WaitForChild("Data", 5)
				local catalog = data2 and data2:WaitForChild("Catalog", 5)
				data2 = data2 and data2:WaitForChild("Config", 5)
				data2 = data2 and data2:WaitForChild("RodAnimationConfig", 5)
				catalog = catalog and require(catalog)
				data2 = data2 and require(data2)
				local tbl17 = {}
				if catalog and catalog.RodSkin and type(catalog.RodSkin.GetAll) == "function" then
					for _, v9 in pairs(catalog.RodSkin.GetAll()) do
						if type(v9) == "table" and type(v9.id) == "string" then
							tbl17[v9.id] = v9.animations
						end
					end
				end
				return catalog and catalog.RodSkin, catalog and catalog.Aura, { Resolve = data2 and data2.Resolve, skins = tbl17 }
			end)
			if ok and result and result2 then
				tbl12.rodSkinAnimations = result3.skins or {}
				tbl12.rodAnimResolve = result3.Resolve
				local tbl17 = {
					Common = 1,
					Uncommon = 2,
					Rare = 3,
					Epic = 4,
					Legendary = 5,
					Mythical = 6,
					Divine = 7,
					Huge = 8,
				}
				local function fn33(arg)
					local tbl18 = {}
					local tbl19 = {}
					local tbl20 = { "Default" }
					if arg and type(arg.GetAll) == "function" then
						for _, v9 in pairs(arg.GetAll()) do
							if type(v9) == "table" and type(v9.name) == "string" and type(v9.id) == "string" then
								table.insert(tbl18, v9)
								tbl19[v9.name] = v9.id
							end
						end
						table.sort(tbl18, function(arg2, arg3)
							local n20 = tbl17[arg2.rarity] or 0
							local n21 = tbl17[arg3.rarity] or 0
							if n20 ~= n21 then
								return n20 > n21
							end
							return arg2.name < arg3.name
						end)
						for _, v9 in ipairs(tbl18) do
							table.insert(tbl20, v9.name)
						end
					end
					return tbl20, tbl19
				end
				local v9 = tbl12
				local v10 = tbl12
				local v11, v12 = fn33(result)
				v9.rodSkinList = v11
				v10.rodSkinMap = v12
				local v13 = tbl12
				local v14 = tbl12
				local v15, v16 = fn33(result2)
				v13.auraList = v15
				v14.auraMap = v16
			end
			for _, v9 in ipairs({ "RodSkinId", "AuraCatalogId" }) do
				tbl12.original[v9] = localPlayer:GetAttribute(v9)
				local connection = localPlayer:GetAttributeChangedSignal(v9):Connect(function()
					local attribute = localPlayer:GetAttribute(v9)
					if attribute == tbl12.wanted[v9] then
						return
					end
					tbl12.original[v9] = attribute
					if tbl12.wanted[v9] then
						localPlayer:SetAttribute(v9, tbl12.wanted[v9])
					end
				end)
				table.insert(tbl12.connections, connection)
				table.insert(tbl7, connection)
			end
			local n20 = 0
			local connection = RunService.Heartbeat:Connect(function()
				if not tbl12.wanted.AuraCatalogId or os.clock() < n20 then
					return
				end
				n20 = os.clock() + 0.25
				local character = localPlayer.Character
				character = character and character:FindFirstChild("ClientAuraEffect")
				if character then
					for _, descendant in ipairs(character:GetDescendants()) do
						if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") or descendant:IsA("Trail") or descendant:IsA("Light") or descendant:IsA("Highlight") then
							if not descendant.Enabled then
								descendant.Enabled = true
							end
						elseif descendant:IsA("BasePart") and descendant.LocalTransparencyModifier ~= 0 then
							descendant.LocalTransparencyModifier = 0
						end
					end
				end
			end)
			table.insert(tbl12.connections, connection)
			table.insert(tbl7, connection)
			local function fn33(arg)
				local rodSkinId = tbl12.wanted.RodSkinId
				if not rodSkinId or not tbl12.rodAnimResolve or not tbl12.animator then
					return
				end
				local v9 = tbl12.rodAnimResolve(arg.Name, tbl12.rodSkinAnimations[rodSkinId])
				if not v9 or v9.id == arg.Animation.AnimationId then
					return
				end
				local v10 = tbl12.animTracks[v9.id]
				if not v10 then
					local animation = Instance.new("Animation")
					animation.AnimationId = v9.id
					local ok2, result4 = pcall(tbl12.animator.LoadAnimation, tbl12.animator, animation)
					if not ok2 or not result4 then
						return
					end
					v10 = result4
					tbl12.animTracks[v9.id] = result4
				end
				v10.Priority = v9.priority
				v10.Looped = v9.looped
				arg:AdjustWeight(0.001, 0)
				tbl12.playingTracks[arg] = v10
				v10:Play(v9.fadeTime, 1, v9.playbackSpeed)
				local connection2 = nil
				connection2 = arg.Stopped:Connect(function()
					connection2:Disconnect()
					if tbl12.playingTracks[arg] ~= v10 then
						return
					end
					tbl12.playingTracks[arg] = nil
					for _, playingTrack in pairs(tbl12.playingTracks) do
						if playingTrack == v10 then
							return
						end
					end
					v10:Stop(v9.fadeTime)
				end)
			end
			local function fn34(character)
				local humanoid = character and character:WaitForChild("Humanoid", 10)
				humanoid = humanoid and humanoid:WaitForChild("Animator", 10)
				if not humanoid then
					return
				end
				tbl12.animator = humanoid
				tbl12.animTracks = {}
				tbl12.playingTracks = {}
				local connection2 = humanoid.AnimationPlayed:Connect(fn33)
				table.insert(tbl12.connections, connection2)
				table.insert(tbl7, connection2)
			end
			local connection2 = localPlayer.CharacterAdded:Connect(fn34)
			table.insert(tbl12.connections, connection2)
			table.insert(tbl7, connection2)
			task.spawn(fn34, localPlayer.Character)
			tbl12.refreshAnimations = function()
				for k, playingTrack in pairs(tbl12.playingTracks) do
					pcall(function()
						playingTrack:Stop(0.15)
						k:AdjustWeight(1, 0.15)
					end)
				end
				tbl12.playingTracks = {}
				if tbl12.animator then
					for _, v9 in ipairs(tbl12.animator:GetPlayingAnimationTracks()) do
						if v9.WeightTarget > 0 then
							fn33(v9)
						end
					end
				end
			end
		end,
		SetEffect = function(arg, arg2)
			tbl12.wanted[arg] = arg2
			localPlayer:SetAttribute(arg, arg2 or tbl12.original[arg])
			if tbl12.refreshAnimations then
				tbl12.refreshAnimations()
			end
		end,
		Reset = function()
			for _, v9 in ipairs({ "RodSkinId", "AuraCatalogId" }) do
				tbl12.wanted[v9] = nil
				if tbl12.original[v9] ~= nil then
					localPlayer:SetAttribute(v9, tbl12.original[v9])
				end
			end
			if tbl12.refreshAnimations then
				tbl12.refreshAnimations()
			end
		end,
	}
	pcall(tbl12.Init)
	tbl6.walkContext = function(arg, arg2, arg3)
		local filterDescendantsInstances = { arg }
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character and player.Character ~= arg then
				table.insert(filterDescendantsInstances, player.Character)
			end
		end
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = filterDescendantsInstances
		raycastParams.RespectCanCollide = true
		raycastParams.IgnoreWater = false
		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude
		overlapParams.FilterDescendantsInstances = filterDescendantsInstances
		overlapParams.RespectCanCollide = true
		overlapParams.MaxParts = 8
		local n20 = arg3.HipHeight + arg2.Size.Y * 0.5
		if arg3.RigType == Enum.HumanoidRigType.R6 then
			local leftLeg = arg:FindFirstChild("Left Leg")
			n20 += leftLeg and leftLeg.Size.Y or 2
		end
		local jumpHeight = arg3.UseJumpPower and arg3.JumpPower * arg3.JumpPower / 2 * math.max(workspace.Gravity, 1) or arg3.JumpHeight
		return {
			rays = raycastParams,
			overlap = overlapParams,
			lift = math.max(n20, 2),
			jumpHeight = math.clamp(jumpHeight - 0.6, 0, 16),
			bodySize = Vector3.new(3.2, 3.2, 1.4),
		}
	end
	tbl6.walkStandingClear = function(arg, arg2)
		local v9 = workspace
		local overlap = arg2.overlap
		return #v9:GetPartBoundsInBox(CFrame.new(arg + Vector3.new(0, 0.4, 0)), Vector3.new(3.2, 3.6, 3.2), overlap) == 0
	end
	tbl6.walkSegmentClear = function(arg, arg2, arg3, arg4)
		local vector = Vector3.new(arg2.X - arg.X, 0, arg2.Z - arg.Z)
		if vector.Magnitude < 0.15 then
			return true
		end
		local n20 = math.max(1, math.ceil(vector.Magnitude))
		local v9 = arg
		for i = 1, n20 do
			local vector2 = arg:Lerp(arg2, i / n20)
			local rays = arg3.rays
			local hit = workspace:Raycast(vector2 + Vector3.new(0, 2, 0), Vector3.new(0, -(arg3.lift + 5), 0), rays)
			if hit and hit.Normal.Y >= 0.55 and (tbl6.waterWalkActive or hit.Material ~= Enum.Material.Water) then
				vector2 = Vector3.new(vector2.X, hit.Position.Y + arg3.lift, vector2.Z)
				if vector2.Y - v9.Y > 1.5 or v9.Y - vector2.Y > 2 then
					return false
				end
			elseif arg4 then
				return false
			end
			local n21 = v9 + Vector3.new(0, 0.7, 0)
			local n22 = vector2 - v9
			if n22.Magnitude > 0.05 then
				local v10 = workspace:Blockcast(CFrame.lookAt(n21, n21 + vector), arg3.bodySize, n22, arg3.rays)
				if v10 and v10.Normal.Y < 0.75 then
					return false, v10
				end
				v9 = vector2
				continue
			end
			v9 = vector2
		end
		return true
	end
	tbl6.walkFooting = function(arg, arg2)
		local hit = workspace:Raycast(arg + Vector3.new(0, 3, 0), Vector3.new(0, -8, 0), arg2.rays)
		local flag28 = not hit or hit.Normal.Y < 0.93 or math.abs(hit.Position.Y - arg.Y) > 3.5
		local flag29
		if flag28 then
			flag29 = flag28
		else
			flag29 = hit.Material == Enum.Material.Water and not tbl6.waterWalkActive
		end
		if flag29 then
			return nil
		end
		local vector = Vector3.new(arg.X, hit.Position.Y, arg.Z)
		for _, v9 in ipairs({
			Vector3.new(1.25, 0, 0),
			Vector3.new(-1.25, 0, 0),
			Vector3.new(0, 0, 1.25),
			Vector3.new(0, 0, -1.25),
		}) do
			local hit2 = workspace:Raycast(vector + v9 + Vector3.new(0, 2, 0), Vector3.new(0, -4, 0), arg2.rays)
			if not hit2 or hit2.Normal.Y < 0.75 or math.abs(hit2.Position.Y - vector.Y) > 1.5 or hit2.Material == Enum.Material.Water and not tbl6.waterWalkActive then
				return nil
			end
			local v10 = workspace
			local rays = arg2.rays
			if v10:Raycast(vector + Vector3.new(0, arg2.lift, 0), v9 * 1.2, rays) then
				return nil
			end
		end
		return vector
	end
	tbl6.walkWaypoints = function(arg, arg2)
		local tbl17 = {}
		local now3 = os.clock()
		local flag28 = true
		for i, v9 in ipairs(arg) do
			if os.clock() - now3 > 0.004 then
				task.wait()
				now3 = os.clock()
			end
			local position = tbl6.walkFooting(v9.Position, arg2)
			if not position and i > 1 and i < #arg then
				local n20 = arg[i + 1].Position - arg[i - 1].Position
				local vector = Vector3.new(n20.X, 0, n20.Z)
				if vector.Magnitude > 0.1 then
					local unit = Vector3.new(vector.Z, 0, -vector.X).Unit
					local v10, v11, v12 = ipairs({ 2, -2, 4, -4, 6, -6, 8, -8 })
					local huge = math.huge
					for _, v13 in v10, v11, v12 do
						local v14 = tbl6.walkFooting(v9.Position + unit * v13, arg2)
						if v14 then
							local n21 = math.abs(v13) + math.abs(v14.Y - v9.Position.Y) * 0.5
							local position2 = tbl17[i - 1] and tbl17[i - 1].Position
							local n22
							if position2 and not tbl6.walkSegmentClear(position2 + Vector3.new(0, arg2.lift, 0), v14 + Vector3.new(0, arg2.lift, 0), arg2, true) then
								n22 = n21 + 12
							else
								n22 = n21
							end
							if n22 < huge then
								huge = n22
								position = v14
							end
						end
					end
				end
			end
			if not position then
				flag28 = false
			end
			position = position or v9.Position
			local action = v9.Action
			local position2 = tbl17[i - 1] and tbl17[i - 1].Position
			if action == Enum.PathWaypointAction.Jump and position2 and tbl6.walkSegmentClear(position2 + Vector3.new(0, arg2.lift, 0), position + Vector3.new(0, arg2.lift, 0), arg2, true) then
				action = Enum.PathWaypointAction.Walk
			end
			tbl17[i] = { Position = position, Action = action }
			if position2 and action ~= Enum.PathWaypointAction.Jump and not tbl6.walkSegmentClear(position2 + Vector3.new(0, arg2.lift, 0), position + Vector3.new(0, arg2.lift, 0), arg2, true) then
				flag28 = false
			end
		end
		return tbl17, flag28
	end
	tbl6.walkSurfaceRoute = function(arg, arg2, arg3, arg4, arg5)
		local n20 = 3
		local n21 = math.min(arg.X, arg2.X) - 21
		local n22 = math.min(arg.Z, arg2.Z) - 21
		local n23 = math.ceil((math.abs(arg.X - arg2.X) + 42) / n20) + 1
		local n24 = math.ceil((math.abs(arg.Z - arg2.Z) + 42) / n20) + 1
		if n23 * n24 > 6000 then
			return nil
		end
		local n25 = math.max(arg.Y, arg2.Y) + 10
		local lift = arg4.lift
		local n26 = math.min(arg.Y, arg2.Y) - lift - 8
		local tbl17 = {}
		local tbl18 = {}
		local n27 = os.clock() + 4
		local now3 = os.clock()
		local function fn33(arg6, arg7)
			if arg6 < 0 or arg7 < 0 or arg6 >= n23 or arg7 >= n24 then
				return nil
			end
			local n28 = arg7 * n23 + arg6 + 1
			if tbl17[n28] ~= nil then
				return tbl17[n28] or nil
			end
			local rays = arg4.rays
			local hit = workspace:Raycast(Vector3.new(n21 + arg6 * n20, n25, n22 + arg7 * n20), Vector3.new(0, n26 - n25, 0), rays)
			local v9 = hit and tbl6.walkFooting(hit.Position, arg4)
			if not v9 then
				tbl17[n28] = false
				return nil
			end
			local tbl19 = { x = arg6, z = arg7, position = v9, g = math.huge }
			tbl17[n28] = tbl19
			return tbl19
		end
		local function fn34(arg6, arg7)
			local tbl19 = { node = arg6, priority = arg7 }
			local n28 = #tbl18 + 1
			while n28 > 1 do
				local n29 = math.floor(n28 / 2)
				if not (tbl18[n29].priority <= arg7) then
					tbl18[n28] = tbl18[n29]
					n28 = n29
					continue
				end
				break
			end
			tbl18[n28] = tbl19
		end
		local function fn35()
			local v9 = tbl18[1]
			local v10 = table.remove(tbl18)
			if #tbl18 > 0 then
				local n28 = 1
				while n28 * 2 <= #tbl18 do
					local n29 = n28 * 2
					if n29 + 1 <= #tbl18 and tbl18[n29 + 1].priority < tbl18[n29].priority then
						n29 += 1
					end
					if not (v10.priority <= tbl18[n29].priority) then
						tbl18[n28] = tbl18[n29]
						n28 = n29
						continue
					end
					break
				end
				tbl18[n28] = v10
			end
			return v9.node
		end
		local floor = math.floor
		local n28 = (arg.Z - n22) / n20 + 0.5
		local v9 = fn33(math.floor((arg.X - n21) / n20 + 0.5), floor(n28))
		if not v9 then
			return nil
		end
		v9.g = 0
		fn34(v9, (v9.position - arg2).Magnitude)
		local n29 = 0
		while #tbl18 > 0 and n29 < 1400 and os.clock() < n27 do
			if not flag or arg5 and not arg5() then
				return nil
			end
			if os.clock() - now3 > 0.004 then
				task.wait()
				now3 = os.clock()
			end
			local parent = fn35()
			if parent.closed then
				continue
			end
			parent.closed = true
			n29 += 1
			local n30 = parent.position + Vector3.new(0, arg4.lift, 0)
			if tbl6.walkGap(n30, arg2) <= n20 and math.abs(n30.Y - arg2.Y) <= 3 and tbl6.walkSegmentClear(n30, arg2, arg4, true) then
				local tbl19 = { { Position = arg2 - Vector3.new(0, arg4.lift, 0), Action = Enum.PathWaypointAction.Walk } }
				while parent do
					table.insert(tbl19, 1, { Position = parent.position, Action = parent.action or Enum.PathWaypointAction.Walk })
					parent = parent.parent
				end
				table.insert(tbl19, 1, { Position = arg - Vector3.new(0, arg4.lift, 0), Action = Enum.PathWaypointAction.Walk })
				return tbl19
			end
			for i = -1, 1 do
				for i2 = -1, 1 do
					if not (i == 0 and i2 == 0) then
						local v10 = fn33(parent.x + i, parent.z + i2)
						if not (not v10 or v10.closed) then
							local walk = Enum.PathWaypointAction.Walk
							if not tbl6.walkSegmentClear(n30, v10.position + Vector3.new(0, arg4.lift, 0), arg4, true) then
								v10 = fn33(parent.x + i * 2, parent.z + i2 * 2)
								local unit = Vector3.new(i, 0, i2).Unit
								local closed = not v10 or v10.closed
								if not closed then
									local jumpHeight = arg4.jumpHeight
									closed = math.abs(v10.position.Y - parent.position.Y) > jumpHeight
								end
								if closed or not tbl6.shouldJumpObstacle({ Position = n30 }, unit, arg3, arg4) then
									continue
								end
								walk = Enum.PathWaypointAction.Jump
							end
							local g = parent.g + (v10.position - parent.position).Magnitude + (walk == Enum.PathWaypointAction.Jump and 6 or 0)
							if g < v10.g then
								v10.g = g
								v10.parent = parent
								v10.action = walk
								fn34(v10, g + (v10.position + Vector3.new(0, arg4.lift, 0) - arg2).Magnitude * 1.05)
							end
						end
					end
				end
			end
		end
		return nil
	end
	walkTo = function(arg, arg2, arg3)
		local character = localPlayer.Character
		local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoidRootPart or not humanoid or humanoid.Health <= 0 then
			return false, "CharacterNotReady"
		end
		if typeof(arg) ~= "CFrame" and typeof(arg) ~= "Vector3" then
			return false, "InvalidTarget"
		end
		local position = typeof(arg) == "CFrame" and arg.Position or arg
		if arg2 and not arg2() then
			return false, "Cancelled"
		end
		local idling2 = FishingEnums.State.Idling
		if fn7() ~= idling2 or localPlayer:GetAttribute("IsUsingSkill") == true or humanoidRootPart.Anchored or humanoid.WalkSpeed <= 0 then
			return false, "MovementLocked"
		end
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		local magnitude = (humanoidRootPart.Position - position).Magnitude
		if magnitude <= (arg3 or 2.5) then
			return true, "AlreadyClose"
		end
		if magnitude > 2500 then
			return false, "NoSafeRoute"
		end
		pcall(function()
			humanoid:UnequipTools()
		end)
		humanoid.AutoRotate = true
		local v9 = tbl6.walkContext(character, humanoidRootPart, humanoid)
		local function fn33(arg4, arg5)
			local tbl17 = {}
			local n20 = math.clamp(math.floor((arg4 - arg5).Magnitude / 4), 1, 250)
			for i = 1, n20 do
				table.insert(tbl17, { Position = arg4:Lerp(arg5, i / n20), Action = Enum.PathWaypointAction.Walk })
			end
			return tbl17
		end
		local v10 = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 4 })
		if not pcall(function()
			v10:ComputeAsync(humanoidRootPart.Position, position)
		end) or v10.Status ~= Enum.PathStatus.Success then
			v10:Destroy()
			v10 = PathfindingService:CreatePath({ AgentRadius = 1.4, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 4 })
			pcall(function()
				v10:ComputeAsync(humanoidRootPart.Position, position)
			end)
		end
		local tbl17 = {}
		local flag28 = false
		if v10.Status == Enum.PathStatus.Success then
			tbl17 = v10:GetWaypoints()
			flag28 = #tbl17 >= 2
		end
		v10:Destroy()
		local v11
		if #tbl17 == 0 then
			local n20 = nil
			for i = 1, 15 do
				local rays = v9.rays
				local hit = workspace:Raycast(position:Lerp(humanoidRootPart.Position, i / 16) + Vector3.new(0, 20, 0), Vector3.new(0, -60, 0), rays)
				if hit and hit.Material ~= Enum.Material.Water and hit.Normal.Y >= 0.65 then
					n20 = hit.Position + Vector3.new(0, v9.lift or 2.5, 0)
					break
				end
			end
			if n20 then
				local v12 = PathfindingService:CreatePath({ AgentRadius = 1.6, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 4 })
				if pcall(function()
					v12:ComputeAsync(humanoidRootPart.Position, n20)
				end) and v12.Status == Enum.PathStatus.Success then
					tbl17 = v12:GetWaypoints()
					local v13 = ipairs
					local v14 = fn33(n20, position)
					for _, v15 in v13(v14) do
						table.insert(tbl17, v15)
					end
				end
				v12:Destroy()
			end
			if #tbl17 == 0 then
				tbl17 = fn33(humanoidRootPart.Position, position)
			end
			v11 = tbl17
		else
			v11 = tbl17
		end
		if #v11 == 0 then
			return false, "NoSafeRoute"
		end
		local tbl18 = { { id = "direct", waypoints = v11 } }
		local flag29 = not flag28
		if flag29 and magnitude >= 22 then
			local n20 = position - humanoidRootPart.Position
			local vector = Vector3.new(-n20.Z, 0, n20.X)
			if vector.Magnitude > 0.1 then
				local unit = vector.Unit
				local tbl19 = {}
				local tbl20 = {
					category = "left_shallow",
					dist = 8 + math.random() * 5,
					alpha = 0.4 + math.random() * 0.12,
				}
				local tbl21 = {
					category = "left_med",
					dist = 16 + math.random() * 7,
					alpha = 0.45 + math.random() * 0.12,
				}
				local tbl22 = {
					category = "left_wide",
					dist = 26 + math.random() * 10,
					alpha = 0.48 + math.random() * 0.12,
				}
				local tbl23 = {
					category = "right_shallow",
					dist = -(8 + math.random() * 5),
					alpha = 0.4 + math.random() * 0.12,
				}
				local tbl24 = {
					category = "right_med",
					dist = -(16 + math.random() * 7),
					alpha = 0.45 + math.random() * 0.12,
				}
				local tbl25 = {
					category = "right_wide",
					dist = -(26 + math.random() * 10),
					alpha = 0.48 + math.random() * 0.12,
				}
				local tbl26 = {
					category = "left_early",
					dist = 14 + math.random() * 6,
					alpha = 0.28 + math.random() * 0.08,
				}
				local tbl27 = {
					category = "right_early",
					dist = -(14 + math.random() * 6),
					alpha = 0.28 + math.random() * 0.08,
				}
				local tbl28 = {
					category = "left_late",
					dist = 14 + math.random() * 6,
					alpha = 0.64 + math.random() * 0.08,
				}
				local tbl29 = {
					category = "right_late",
					dist = -(14 + math.random() * 6),
					alpha = 0.64 + math.random() * 0.08,
				}
				tbl19[1] = tbl20
				tbl19[2] = tbl21
				tbl19[3] = tbl22
				tbl19[4] = tbl23
				tbl19[5] = tbl24
				tbl19[6] = tbl25
				tbl19[7] = tbl26
				tbl19[8] = tbl27
				tbl19[9] = tbl28
				tbl19[10] = tbl29
				if magnitude >= 45 then
					table.insert(tbl19, {
						category = "s_left_right",
						isS = true,
						d1 = 15 + math.random() * 8,
						a1 = 0.32 + math.random() * 0.06,
						d2 = -(15 + math.random() * 8),
						a2 = 0.68 + math.random() * 0.06,
					})
					table.insert(tbl19, {
						category = "s_right_left",
						isS = true,
						d1 = -(15 + math.random() * 8),
						a1 = 0.32 + math.random() * 0.06,
						d2 = 15 + math.random() * 8,
						a2 = 0.68 + math.random() * 0.06,
					})
				end
				for i = #tbl19, 2, -1 do
					local n21 = math.random(1, i)
					local v12 = tbl19[i]
					tbl19[i] = tbl19[n21]
					tbl19[n21] = v12
				end
				local raycastParams = RaycastParams.new()
				raycastParams.FilterType = Enum.RaycastFilterType.Exclude
				raycastParams.FilterDescendantsInstances = { character, localPlayer.Character }
				local v12, v13, v14 = ipairs(tbl19)
				local n21 = 0
				for _, v15 in v12, v13, v14 do
					if not (n21 >= 6) then
						if v15.isS then
							local n22 = unit * v15.d1
							local n23 = humanoidRootPart.Position:Lerp(position, v15.a1) + n22
							local n24 = unit * v15.d2
							local n25 = humanoidRootPart.Position:Lerp(position, v15.a2) + n24
							local hit = workspace:Raycast(n23 + Vector3.new(0, 20, 0), Vector3.new(0, -50, 0), v9.rays)
							local hit2 = workspace:Raycast(n25 + Vector3.new(0, 20, 0), Vector3.new(0, -50, 0), v9.rays)
							if hit and hit2 and hit.Normal.Y >= 0.65 and hit2.Normal.Y >= 0.65 then
								if (hit.Material ~= Enum.Material.Water or tbl6.waterWalkEnabled) and (hit2.Material ~= Enum.Material.Water or tbl6.waterWalkEnabled) then
									local n26 = hit.Position + Vector3.new(0, v9.lift or 2.5, 0)
									local n27 = hit2.Position + Vector3.new(0, v9.lift or 2.5, 0)
									local hit3 = workspace:Raycast(humanoidRootPart.Position + Vector3.new(0, 2, 0), n26 - humanoidRootPart.Position, raycastParams)
									local hit4 = workspace:Raycast(n26 + Vector3.new(0, 2, 0), n27 - n26, raycastParams)
									local hit5 = workspace:Raycast(n27 + Vector3.new(0, 2, 0), position - n27, raycastParams)
									if (not hit3 or hit3.Material == Enum.Material.Water) and (not hit4 or hit4.Material == Enum.Material.Water) and (not hit5 or hit5.Material == Enum.Material.Water) then
										local v16 = fn33(humanoidRootPart.Position, n26)
										local v17 = fn33(n26, n27)
										local v18 = fn33(n27, position)
										local tbl30 = {}
										for i = 1, #v16 do
											table.insert(tbl30, v16[i])
										end
										for i = 2, #v17 do
											table.insert(tbl30, v17[i])
										end
										for i = 2, #v18 do
											table.insert(tbl30, v18[i])
										end
										if #tbl30 >= 5 then
											table.insert(tbl18, { id = v15.category, waypoints = tbl30 })
											n21 += 1
										end
									end
								end
							end
						else
							local n22 = unit * v15.dist
							local rays = v9.rays
							local hit = workspace:Raycast(humanoidRootPart.Position:Lerp(position, v15.alpha) + n22 + Vector3.new(0, 20, 0), Vector3.new(0, -50, 0), rays)
							if hit and hit.Normal.Y >= 0.65 then
								if hit.Material ~= Enum.Material.Water or tbl11 and (tbl11.UserEnabled or tbl11.Enabled) or tbl6.waterWalkEnabled then
									local n23 = hit.Position + Vector3.new(0, v9.lift or 2.5, 0)
									if hit.Material ~= Enum.Material.Water then
										local v16 = PathfindingService:CreatePath({
											AgentRadius = 1.8,
											AgentHeight = 5,
											AgentCanJump = true,
											WaypointSpacing = 4,
										})
										if pcall(function()
											v16:ComputeAsync(humanoidRootPart.Position, n23)
										end) and v16.Status == Enum.PathStatus.Success then
											local v17 = PathfindingService:CreatePath({
												AgentRadius = 1.8,
												AgentHeight = 5,
												AgentCanJump = true,
												WaypointSpacing = 4,
											})
											if pcall(function()
												v17:ComputeAsync(n23, position)
											end) and v17.Status == Enum.PathStatus.Success then
												local waypoints = v16:GetWaypoints()
												local waypoints2 = v17:GetWaypoints()
												local tbl30 = {}
												for i = 1, #waypoints do
													table.insert(tbl30, waypoints[i])
												end
												for i = 2, #waypoints2 do
													table.insert(tbl30, waypoints2[i])
												end
												if #tbl30 >= 4 and #tbl30 <= #v11 * 1.7 then
													table.insert(tbl18, { id = v15.category, waypoints = tbl30 })
													n21 += 1
												end
											end
											v17:Destroy()
										end
										v16:Destroy()
									else
										local hit2 = workspace:Raycast(humanoidRootPart.Position + Vector3.new(0, 2, 0), n23 - humanoidRootPart.Position, raycastParams)
										local hit3 = workspace:Raycast(n23 + Vector3.new(0, 2, 0), position - n23, raycastParams)
										local flag30 = not hit2 or hit2.Material == Enum.Material.Water
										local flag31
										if flag30 then
											flag31 = not hit3 or hit3.Material == Enum.Material.Water
										else
											flag31 = flag30
										end
										if flag31 then
											local v16 = fn33(humanoidRootPart.Position, n23)
											local v17 = fn33(n23, position)
											local tbl30 = {}
											for i = 1, #v16 do
												table.insert(tbl30, v16[i])
											end
											for i = 2, #v17 do
												table.insert(tbl30, v17[i])
											end
											if #tbl30 >= 4 then
												table.insert(tbl18, { id = v15.category, waypoints = tbl30 })
												n21 += 1
											end
										end
									end
								end
							end
						end
						continue
					end
					break
				end
			end
		end
		local v12 = tbl18[1]
		if flag29 and #tbl18 > 1 then
			local tbl19 = {}
			for _, v13 in ipairs(tbl18) do
				if v13.id ~= tbl6.lastUsedRouteId then
					table.insert(tbl19, v13)
				end
			end
			if #tbl19 > 0 then
				v12 = tbl19[math.random(1, #tbl19)]
			else
				v12 = tbl18[math.random(1, #tbl18)]
			end
		end
		tbl6.lastUsedRouteId = v12.id
		local waypoints = v12.waypoints
		local position2 = humanoidRootPart.Position
		local now3 = os.clock()
		local clamp = math.clamp
		local n20 = os.clock() + clamp(magnitude / math.max(humanoid.WalkSpeed, 12) * 2.5 + 20, 20, 150)
		arg3 = arg3 or 2
		local n21 = 2
		local n22 = 0
		local n23 = -math.huge
		local n24 = 0
		while flag and os.clock() < n20 do
			if localPlayer.Character ~= character or not humanoidRootPart.Parent or not humanoid.Parent or humanoid.Health <= 0 or arg2 and not arg2() then
				humanoid:MoveTo(humanoidRootPart.Position)
				return false, "Cancelled"
			end
			if n21 > #waypoints then
				break
			end
			local v13 = waypoints[n21]
			humanoid:MoveTo(v13.Position)
			local now4 = os.clock()
			if v13.Action == Enum.PathWaypointAction.Jump or now4 >= n22 then
				n22 = now4 + 0.1
				if now4 - n23 >= 0.55 then
					local flag30 = v13.Action == Enum.PathWaypointAction.Jump or tbl6.shouldJumpObstacle(humanoidRootPart, v13.Position - humanoidRootPart.Position, character, v9)
					if not flag30 then
						local n25 = v13.Position - humanoidRootPart.Position
						local vector = Vector3.new(n25.X, 0, n25.Z)
						if vector.Magnitude > 0.2 then
							local unit = vector.Unit
							local rays = v9.rays
							local hit = workspace:Raycast(humanoidRootPart.Position + Vector3.new(0, -v9.lift + 1, 0), unit * 3.5, rays)
							if hit and hit.Instance and hit.Instance.CanCollide and hit.Normal.Y < 0.7 then
								local v14 = workspace
								local rays2 = v9.rays
								if not v14:Raycast(humanoidRootPart.Position, Vector3.new(0, v9.jumpHeight + 2, 0), rays2) then
									flag30 = true
								end
							end
						end
					end
					if flag30 and tbl6.requestWalkJump(humanoid) then
						n23 = now4
					end
				end
			end
			local position3 = humanoidRootPart.Position
			if Vector2.new(position3.X - v13.Position.X, position3.Z - v13.Position.Z).Magnitude <= (n21 == #waypoints and arg3 or 3.8) then
				n21 += 1
				now3 = os.clock()
			end
			if (position3 - position2).Magnitude > 0.35 then
				now3 = os.clock()
				position2 = position3
			elseif os.clock() - now3 > 0.45 then
				local n25 = os.clock() - now3
				if os.clock() - n23 >= 0.5 and tbl6.requestWalkJump(humanoid) then
					n23 = os.clock()
				end
				if n25 > 1.2 then
					local n26 = v13.Position - position3
					local vector = Vector3.new(-n26.Z, 0, n26.X)
					if vector.Magnitude > 0.1 then
						humanoid:MoveTo(position3 + vector.Unit * (math.random(0, 1) == 0 and 1 or -1) * 3.5 + n26.Unit * 2)
					end
				end
				if n25 > 2.2 and n21 < #waypoints then
					local flag30 = flag28 and n24 < 4
					local flag31 = false
					if flag30 then
						local v14 = PathfindingService:CreatePath({ AgentRadius = 1.6, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 4 })
						if pcall(function()
							v14:ComputeAsync(humanoidRootPart.Position, position)
						end) and v14.Status == Enum.PathStatus.Success then
							local waypoints2 = v14:GetWaypoints()
							if #waypoints2 >= 2 then
								n24 += 1
								now3 = os.clock()
								n21 = 2
								flag31 = true
								waypoints = waypoints2
								position2 = position3
							end
						end
						v14:Destroy()
					end
					if not flag31 then
						n21 += 1
						now3 = os.clock()
						position2 = position3
					end
				end
				if n25 > 3.2 and n21 <= #waypoints then
					local n26 = v13.Position - position3
					if n26.Magnitude > 0.1 then
						humanoidRootPart.CFrame = CFrame.new(position3 + n26.Unit * 2.5 + Vector3.new(0, 1.2, 0))
					end
					now3 = os.clock()
				end
			end
			task.wait(0.02)
		end
		local position3 = humanoidRootPart.Position
		if Vector2.new(position3.X - position.X, position3.Z - position.Z).Magnitude <= arg3 + 1.5 or n21 > #waypoints then
			humanoid:MoveTo(position3)
			return true, "WalkFinished"
		end
		return false, "ArrivalUnconfirmed"
	end
	tbl6.walkTo = walkTo
	tweenTo = function(arg, arg2, arg3, arg4)
		local TweenService = game:GetService("TweenService")
		local character = localPlayer.Character
		local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoidRootPart or not humanoid or humanoid.Health <= 0 then
			return false, "CharacterNotReady"
		end
		if arg2 and not arg2() then
			return false, "Cancelled"
		end
		local magnitude = (humanoidRootPart.Position - arg.Position).Magnitude
		if magnitude <= (arg4 and 0.15 or 6) then
			return true, "AlreadyClose"
		end
		local position = humanoidRootPart.Position
		local position2 = arg.Position
		local n20 = math.clamp(math.ceil(magnitude / (arg3 and 40 or 140)), 1, 150)
		local flag28 = magnitude > 160
		local tbl17 = {}
		for i = 1, n20 do
			local n21 = i / n20
			if i == n20 then
				tbl17[i] = arg
			else
				local vector = position:Lerp(position2, n21)
				if flag28 then
					vector = Vector3.new(vector.X, math.max(position.Y, position2.Y) + math.sin(n21 * 3.1415926535897931) * 25, vector.Z)
				end
				local rotation = humanoidRootPart.CFrame.Rotation
				tbl17[i] = CFrame.new(vector) * rotation
			end
		end
		local tbl18 = {}
		local function fn33(descendant)
			if descendant:IsA("BasePart") and tbl18[descendant] == nil then
				tbl18[descendant] = descendant.CanCollide
				descendant.CanCollide = false
			end
		end
		for _, descendant in ipairs(character:GetDescendants()) do
			fn33(descendant)
		end
		local connection = character.DescendantAdded:Connect(fn33)
		local connection2 = game:GetService("RunService").Stepped:Connect(function()
			for k in pairs(tbl18) do
				if k.Parent then
					k.CanCollide = false
				end
			end
		end)
		local platformStand = humanoid.PlatformStand
		humanoid.PlatformStand = true
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Name = "HuneHubTravelHold"
		bodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
		bodyVelocity.Velocity = Vector3.zero
		bodyVelocity.Parent = humanoidRootPart
		local tween = nil
		local connection3 = nil
		local ok, result, result2 = pcall(function()
			for _, v9 in ipairs(tbl17) do
				if not flag or localPlayer.Character ~= character or not humanoidRootPart.Parent or humanoid.Health <= 0 or arg2 and not arg2() then
					return false, "Cancelled"
				end
				local magnitude2 = (humanoidRootPart.Position - v9.Position).Magnitude
				local n21 = math.clamp(tonumber(arg3) or tonumber(genv.HuneHubTravelSpeed) or 70, 20, 300)
				local n22 = math.max(magnitude2 / n21, 0.01)
				tween = TweenService:Create(humanoidRootPart, TweenInfo.new(n22, Enum.EasingStyle.Linear), { CFrame = v9 })
				local v10 = nil
				connection3 = tween.Completed:Connect(function(playbackState)
					v10 = playbackState
				end)
				tween:Play()
				local position3 = humanoidRootPart.Position
				local now3 = os.clock()
				local n23 = now3 + n22 + 3
				while not v10 do
					local flag29 = not flag or localPlayer.Character ~= character or not humanoidRootPart.Parent or humanoid.Health <= 0
					local flag30
					if flag29 then
						flag30 = flag29
					else
						local v11 = arg2
						if arg2 then
							flag30 = not arg2()
						else
							flag30 = v11
						end
					end
					if flag30 then
						tween:Cancel()
						return false, "Cancelled"
					end
					task.wait(0.05)
					local now4 = os.clock()
					if now4 > n23 then
						tween:Cancel()
						return false, "TweenInterrupted"
					end
					local position4 = humanoidRootPart.Position
					local magnitude3 = (position4 - position3).Magnitude
					if not (math.max(12, n21 * (now4 - now3) * 3 + 4) < magnitude3) then
						position3 = position4
						now3 = now4
						continue
					end
					tween:Cancel()
					return false, "PositionCorrected"
				end
				connection3:Disconnect()
				connection3 = nil
				tween:Destroy()
				tween = nil
				if v10 ~= Enum.PlaybackState.Completed then
					return false, "TweenInterrupted"
				end
				if (humanoidRootPart.Position - v9.Position).Magnitude > 12 then
					return false, "PositionCorrected"
				end
			end
			return true, "TweenFinished"
		end)
		if tween then
			tween:Cancel()
			tween:Destroy()
		end
		if connection3 then
			connection3:Disconnect()
		end
		connection2:Disconnect()
		connection:Disconnect()
		bodyVelocity:Destroy()
		if humanoid.Parent then
			humanoid.PlatformStand = platformStand
		end
		if humanoidRootPart.Parent then
			humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
			humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
		end
		for k, v9 in pairs(tbl18) do
			if k.Parent then
				k.CanCollide = v9
			end
		end
		if not ok then
			return false, "TweenFailed"
		end
		if not result then
			return false, result2
		end
		local flag29 = not humanoidRootPart.Parent
		if not flag29 then
			flag29 = (humanoidRootPart.Position - arg.Position).Magnitude > (arg4 and 1.5 or 8)
		end
		if flag29 then
			return false, "ArrivalUnconfirmed"
		end
		return true, result2
	end
	tbl6.tweenTo = tweenTo
	local fn33 = nil
	fn33 = function(arg)
		if not arg then
			return nil
		end
		if arg:IsA("BasePart") then
			return arg.Position
		end
		if arg:IsA("Attachment") then
			return arg.WorldPosition
		end
		if arg:IsA("Model") then
			local ok, result = pcall(function()
				return arg:GetPivot()
			end)
			if ok and result then
				return result.Position
			end
		elseif arg:IsA("ProximityPrompt") then
			return fn33(arg.Parent)
		end
		local basePart = arg:FindFirstChildWhichIsA("BasePart", true)
		if basePart then
			return basePart.Position
		end
		local attachment = arg:FindFirstChildWhichIsA("Attachment", true)
		if attachment then
			return attachment.WorldPosition
		end
		return nil
	end
	local function fn34(arg)
		local lower = string.lower
		local str = tostring(arg):gsub("[^%w]", "")
		return lower(str)
	end
	fn12 = function(arg)
		local isProximityPrompt = arg:IsA("ProximityPrompt") and arg or arg:FindFirstChildWhichIsA("ProximityPrompt", true)
		return fn33(isProximityPrompt and isProximityPrompt.Parent or arg)
	end
	local function fn35(arg)
		local v9 = fn6()
		if not v9 then
			return nil, nil
		end
		local v10 = nil
		local v11 = nil
		local huge = math.huge
		local str = arg == "npc_fish_seller" and "fishmerchant" or fn34(arg)
		local function fn36(arg2, arg3)
			if not arg2:IsDescendantOf(workspace) then
				return
			end
			local flag28 = arg2:GetAttribute("InteractiveId") == arg
			if not flag28 and arg3 and (arg2:IsA("Model") or arg2:IsA("BasePart")) then
				local v12 = fn34(arg2.Name)
				flag28 = v12 == str
				if not flag28 then
					flag28 = arg == "npc_fish_seller"
					if flag28 then
						flag28 = v12 == "nana" or v12 == "seller" or v12 == "fishseller" or v12 == "npcfishseller"
					end
				end
				flag28 = flag28 and arg2:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil
			end
			if flag28 then
				local v12 = fn12(arg2)
				if v12 then
					local magnitude = (v9.Position - v12).Magnitude
					if magnitude < huge then
						v10 = arg2
						v11 = v12
						huge = magnitude
					end
				end
			end
		end
		local tbl17 = {}
		pcall(function()
			tbl17 = CollectionService:GetTagged("Interactive")
		end)
		for _, v12 in ipairs(tbl17) do
			fn36(v12, false)
		end
		if not v10 then
			local descendants = workspace:GetDescendants()
			for _, descendant in ipairs(descendants) do
				fn36(descendant, false)
			end
			if not v10 then
				for _, descendant in ipairs(descendants) do
					fn36(descendant, true)
				end
			end
		end
		return v10, v11
	end
	local function fn36(arg, arg2)
		local v9 = fn6()
		if not v9 then
			return nil
		end
		local vector = Vector3.new(v9.Position.X - arg.X, 0, v9.Position.Z - arg.Z)
		local vector2
		if vector.Magnitude < 0.1 then
			vector2 = Vector3.new(0, 0, 1)
		else
			vector2 = vector.Unit
		end
		local n20 = arg + vector2 * (arg2 or 6) + Vector3.new(0, 2.5, 0)
		local vector3 = Vector3.new(arg.X, n20.Y, arg.Z)
		return CFrame.lookAt(n20, vector3)
	end
	fn13 = function(arg, arg2, arg3)
		if arg3 and not arg3() then
			return false
		end
		local v9 = fn7()
		if arg2 then
			if v9 == FishingEnums.State.Caught and fn then
				pcall(fn)
			end
			if v9 ~= FishingEnums.State.Idling then
				pcall(function()
					FishingPackets.FishCancel:Fire()
				end)
			end
			local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				pcall(function()
					humanoid:UnequipTools()
				end)
			end
			v9 = fn7()
		end
		if not arg2 and v9 == FishingEnums.State.Reeling and resumeSoldFish then
			if arg then
				lib:Notify({
					Title = text("Finishing Current Fish"),
					Content = text("The sale will start when the current fight ends."),
					Duration = 4,
				})
			end
			local n20 = os.clock() + 35
			while flag and os.clock() < n20 do
				if arg3 and not arg3() then
					return false
				end
				local reeling = FishingEnums.State.Reeling
				if fn7() ~= reeling then
					break
				end
				task.wait(0.1)
			end
		end
		if arg3 and not arg3() then
			return false
		end
		local v10 = fn7()
		if v10 == FishingEnums.State.Caught then
			local n20 = os.clock() + 3
			while true do
				local flag28 = flag and os.clock() < n20
				if flag28 then
					local caught = FishingEnums.State.Caught
					flag28 = fn7() == caught
				end
				if flag28 then
					if arg3 and not arg3() then
						return false
					end
					if fn then
						fn()
					end
					task.wait(0.15)
					continue
				end
				break
			end
		elseif v10 ~= FishingEnums.State.Idling then
			pcall(function()
				FishingPackets.FishCancel:Fire()
			end)
		end
		local n20 = os.clock() + 2
		while true do
			local flag28 = flag and os.clock() < n20
			if flag28 then
				local idling2 = FishingEnums.State.Idling
				flag28 = fn7() ~= idling2
			end
			if flag28 then
				if arg3 and not arg3() then
					return false
				end
				local caught = FishingEnums.State.Caught
				if fn7() == caught and fn then
					fn()
				end
				task.wait(0.1)
				continue
			end
			break
		end
		if arg3 and not arg3() then
			return false
		end
		flag21 = false
		n14 += 1
		flag22 = false
		n15 += 1
		flag23 = false
		n16 += 1
		flag24 = false
		n3 += 1
		flag7 = false
		local character = localPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
		local LocalMovementLock = nil
		pcall(function()
			LocalMovementLock = require(ReplicatedStorage.Shared.Lib.LocalMovementLock)
		end)
		if humanoid then
			pcall(function()
				humanoid:UnequipTools()
			end)
			local n21 = os.clock() + 15
			local idling2
			repeat
				task.wait(0.1)
				if arg3 and not arg3() then
					return false
				end
				if localPlayer.Character ~= character or humanoid.Health <= 0 or not flag then
					return false
				end
				idling2 = FishingEnums.State.Idling
			until fn7() == idling2 and localPlayer:GetAttribute("IsUsingSkill") ~= true and (not LocalMovementLock or not LocalMovementLock.IsLocked()) or os.clock() >= n21
			local idling3 = FishingEnums.State.Idling
			if fn7() ~= idling3 or localPlayer:GetAttribute("IsUsingSkill") == true or LocalMovementLock and LocalMovementLock.IsLocked() then
				return false
			end
			local StarterPlayer = game:GetService("StarterPlayer")
			if humanoid.WalkSpeed <= 0 then
				humanoid.WalkSpeed = StarterPlayer.CharacterWalkSpeed
			end
			if humanoid.JumpPower <= 0 then
				humanoid.JumpPower = StarterPlayer.CharacterJumpPower
			end
			if humanoid.JumpHeight <= 0 then
				humanoid.JumpHeight = StarterPlayer.CharacterJumpHeight
			end
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			humanoid.AutoRotate = true
		end
		if humanoidRootPart then
			humanoidRootPart.Anchored = false
		end
		pcall(function()
			local playerModule = localPlayer.PlayerScripts:FindFirstChild("PlayerModule")
			if playerModule then
				require(playerModule):GetControls():Enable()
			end
		end)
		return true
	end
	local function fn37(arg, arg2, arg3)
		local n20 = tonumber(arg) or 0
		local n21 = tonumber(arg2) or 0
		n13 += n20
		lib:Notify({
			Title = text("Fish Sold"),
			Content = string.format(text("+%s Coins (%d Fish) • %s"), fn10(n20), n21, arg3),
			Duration = 3,
		})
		return true, SellEnums.Status.Ok, n20, n21, arg3
	end
	tbl6.teleportTo = function(cFrame4)
		local character = localPlayer.Character
		local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoidRootPart or not humanoid or humanoid.Health <= 0 then
			return false, "CharacterNotReady"
		end
		humanoidRootPart.CFrame = cFrame4
		humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
		humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
		task.wait(0.2)
		if localPlayer.Character ~= character or not humanoidRootPart.Parent or humanoid.Health <= 0 then
			return false, "CharacterNotReady"
		end
		if (humanoidRootPart.Position - cFrame4.Position).Magnitude > 4 then
			return false, "PositionCorrected"
		end
		if not tbl6.hasSolidGroundUnder(humanoidRootPart, character) then
			return false, "NoSafeRoute"
		end
		return true, "Teleported"
	end
	tbl6.moveTo = function(arg, arg2)
		if tbl6.method == "Teleport Instant" then
			tbl6.method = "Walk"
		end
		if tbl6.method == "Tween" then
			local v9, v10 = tweenTo(arg, nil, tbl6.tweenSpeed, arg2)
			if v9 or not arg2 then
				return v9, v10
			end
			local v11, v12 = walkTo(arg)
			if v11 then
				return true, "WalkReturn"
			end
			return false, v12 or v10
		end
		return walkTo(arg)
	end
	tbl6.merchantCandidates = function(arg)
		local v9 = fn6()
		if not v9 then
			return nil
		end
		local humanoid = v9.Parent:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return nil
		end
		local v10 = tbl6.walkContext(v9.Parent, v9, humanoid)
		local tbl17 = {}
		local vector = Vector3.new(v9.Position.X - arg.X, 0, v9.Position.Z - arg.Z)
		local n20 = vector.Magnitude > 0.1 and math.atan2(vector.Z, vector.X) or 0
		for _, v11 in ipairs({ 6, 9, 13, 17 }) do
			for i = 0, 7 do
				local n21 = n20 + i * 3.1415926535897931 / 4
				local hit = workspace:Raycast(arg + Vector3.new(math.cos(n21) * v11, 0, math.sin(n21) * v11) + Vector3.new(0, 3, 0), Vector3.new(0, -25, 0), v10.rays)
				if hit and hit.Material ~= Enum.Material.Water and hit.Normal.Y >= 0.75 then
					local n22 = hit.Position + Vector3.new(0, v10.lift, 0)
					local flag28 = tbl6.walkStandingClear(n22, v10)
					if flag28 then
						for _, v12 in ipairs({
							Vector3.new(1.2, 0, 0),
							Vector3.new(-1.2, 0, 0),
							Vector3.new(0, 0, 1.2),
							Vector3.new(0, 0, -1.2),
						}) do
							local rays = v10.rays
							local hit2 = workspace:Raycast(n22 + v12 + Vector3.new(0, 1, 0), Vector3.new(0, -(v10.lift + 3), 0), rays)
							if not hit2 or hit2.Material == Enum.Material.Water or hit2.Normal.Y < 0.65 or math.abs(hit2.Position.Y - hit.Position.Y) > 1.2 then
								flag28 = false
								break
							end
						end
					end
					if flag28 and (n22 - arg).Magnitude <= 20 then
						table.insert(tbl17, {
							cframe = CFrame.new(n22),
							distance = (v9.Position - n22).Magnitude,
							merchantDistance = (n22 - arg).Magnitude,
						})
					end
				end
			end
		end
		table.sort(tbl17, function(arg2, arg3)
			return arg2.distance < arg3.distance
		end)
		return tbl17
	end
	tbl6.walkToMerchant = function(arg, arg2)
		local v9 = fn6()
		if not v9 then
			return false, "CharacterNotReady"
		end
		if not arg or arg:GetAttribute("InteractiveId") ~= "npc_fish_seller" then
			local huge = math.huge
			arg = nil
			for _, v10 in ipairs(CollectionService:GetTagged("Interactive")) do
				if v10:GetAttribute("InteractiveId") == "npc_fish_seller" then
					local v11 = fn12(v10)
					local magnitude = v11 and (v11 - arg2).Magnitude or math.huge
					if magnitude < huge then
						huge = magnitude
						arg = v10
					end
				end
			end
		end
		if not arg then
			for _, descendant in ipairs(workspace:GetDescendants()) do
				if descendant:GetAttribute("InteractiveId") == "npc_fish_seller" then
					local flag28 = fn12(descendant)
					if flag28 then
						flag28 = not arg or (flag28 - arg2).Magnitude < (fn12(arg) - arg2).Magnitude
					end
					if flag28 then
						arg = descendant
					end
				end
			end
		end
		local position = arg2
		local cframe
		if arg then
			local pivot = arg:IsA("Model") and arg:GetPivot() or arg.CFrame
			position = pivot.Position
			local n20 = pivot.Position + pivot.LookVector * 4.2
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			raycastParams.FilterDescendantsInstances = { arg, localPlayer.Character }
			local hit = workspace:Raycast(n20 + Vector3.new(0, 6, 0), Vector3.new(0, -30, 0), raycastParams)
			hit = hit and hit.Position or n20
			cframe = CFrame.lookAt(hit + Vector3.new(0, 2.5, 0), Vector3.new(pivot.Position.X, hit.Y + 2.5, pivot.Position.Z))
		else
			cframe = CFrame.new(arg2)
		end
		if (v9.Position - position).Magnitude <= 5 then
			return true, "MerchantInRange"
		end
		local character = localPlayer.Character
		tbl6.enableWaterWalk(character, v9, character and character:FindFirstChildOfClass("Humanoid"))
		local v10, v11 = walkTo(cframe, function()
			local v10 = fn6()
			if v10 and (v10.Position - position).Magnitude <= 4.8 then
				return false
			end
			return true
		end, 2.5)
		tbl6.disableWaterWalk()
		local v12 = fn6()
		if v12 and (v12.Position - position).Magnitude <= 6.5 then
			v12.CFrame = CFrame.lookAt(v12.Position, Vector3.new(position.X, v12.Position.Y, position.Z))
			return true, "MerchantInRange"
		end
		return v10, v11
	end
	tbl6.teleportToMerchant = function(arg)
		local v9 = fn6()
		if not v9 then
			return false, "CharacterNotReady"
		end
		local tbl17 = tbl6.merchantCandidates(arg) or {}
		table.sort(tbl17, function(arg2, arg3)
			if math.abs(arg2.merchantDistance - arg3.merchantDistance) < 1 then
				return arg2.distance < arg3.distance
			end
			return arg2.merchantDistance < arg3.merchantDistance
		end)
		local n20 = 0
		for _, v10 in ipairs(tbl17) do
			local position = v10.cframe.Position
			if math.abs(position.Y - arg.Y) <= 8 then
				n20 += 1
				local teleportTo = tbl6.teleportTo
				local cframe = CFrame.lookAt
				local vector = Vector3.new(arg.X, position.Y, arg.Z)
				local v11, v12 = teleportTo(cframe(position, vector))
				if v9.Parent and (v9.Position - arg).Magnitude <= 20 and (v11 or v12 == "NoSafeRoute" or v12 == "PositionCorrected") then
					return true, "MerchantInRange"
				end
				if v12 == "PositionCorrected" or v12 == "CharacterNotReady" then
					return false, v12
				end
				if n20 >= 3 then
					return false, v12 or "MerchantOutOfRange"
				end
			end
		end
		local v10 = fn36(arg, 6)
		if not v10 then
			return false, "CharacterNotReady"
		end
		local v11, v12 = tbl6.teleportTo(v10)
		if v9.Parent and (v9.Position - arg).Magnitude <= 20 and (v11 or v12 == "NoSafeRoute" or v12 == "PositionCorrected") then
			return true, "MerchantInRange"
		end
		return false, v12 or "MerchantOutOfRange"
	end
	tbl6.deferReturn = function(lastReturnReason)
		tbl6.pending = true
		tbl6.resumeFarm = false
		tbl6.lastReturnReason = lastReturnReason or "ReturnFailed"
		tbl6.attempts = tbl6.attempts + 1
		tbl6.retryAt = os.clock() + math.min(1 + tbl6.attempts, 8)
		return false, tbl6.lastReturnReason
	end
	tbl6.waitForSale = function(lastSaleReason)
		tbl6.saleAttempts = tbl6.saleAttempts + 1
		tbl6.lastSaleReason = lastSaleReason or "SaleUnconfirmed"
		if tbl6.saleAttempts >= 3 then
			flag15 = false
			tbl6.saleAttempts = 0
			tbl6.saleRetryAt = 0
			pcall(function()
				tbl6.closeMerchantDialogue()
			end)
			tbl6.tryRestore()
			return false, lastSaleReason or "SaleMaxRetriesExceeded", 0, 0
		end
		flag15 = true
		tbl6.saleRetryAt = os.clock() + math.min(2 + tbl6.saleAttempts * 2, 15)
		return false, tbl6.lastSaleReason, 0, 0
	end
	tbl6.atSavedSpot = function(arg, arg2, arg3)
		if localPlayer.Character ~= arg2 or not arg.Parent then
			return false
		end
		local humanoid = arg2:FindFirstChildOfClass("Humanoid")
		local n20 = arg.Position - arg3.Position
		if tbl6.isPositionOverWater(arg3.Position) or tbl11 and (tbl11.UserEnabled or tbl11.Enabled) or tbl6.waterWalkActive then
			humanoid = humanoid and humanoid.Health > 0 and Vector3.new(n20.X, 0, n20.Z).Magnitude <= 5 and math.abs(n20.Y) <= 5
			return humanoid
		end
		local flag28 = humanoid and humanoid.Health > 0 and Vector3.new(n20.X, 0, n20.Z).Magnitude <= 4 and math.abs(n20.Y) <= 4 and math.abs(arg.AssemblyLinearVelocity.Y) <= 8
		if flag28 then
			local swimming = Enum.HumanoidStateType.Swimming
			flag28 = humanoid:GetState() ~= swimming
		end
		return flag28
	end
	tbl6.closeMerchantDialogue = function()
		pcall(function()
			local DialogueController = client.GetController("DialogueController")
			local activeSession = DialogueController and DialogueController:GetActiveSession()
			if activeSession then
				activeSession = tostring(activeSession.npc_id or "")
			end
			if activeSession and activeSession:find("npc_fish_seller", 1, true) then
				DialogueController:Cancel()
			end
		end)
	end
	tbl6.recoverResumePosition = function(arg)
		local resumeTarget = tbl6.resumeTarget or cFrame
		if not resumeTarget then
			return false
		end
		cFrame = resumeTarget
		tbl6.resumeStage = 0
		tbl6.resumeCharacter = nil
		tbl6.resumeCastAt = 0
		tbl6.deferReturn(arg or "ReturnPositionChanged")
		tbl6.retryAt = os.clock() + 0.5
		return true
	end
	tbl6.restore = function()
		local v9 = cFrame
		local character = localPlayer.Character
		local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not v9 or not humanoidRootPart or not humanoid or humanoid.Health <= 0 then
			return tbl6.deferReturn("ReturnPositionUnavailable")
		end
		tbl6.pending = true
		tbl6.closeMerchantDialogue()
		if not fn13() then
			return tbl6.deferReturn("MovementLocked")
		end
		if localPlayer.Character ~= character or not humanoidRootPart.Parent or humanoid.Health <= 0 then
			return tbl6.deferReturn("CharacterNotReady")
		end
		local flag28 = tbl6.method == "Walk"
		local userEnabled = tbl6.isPositionOverWater(v9.Position) or tbl11 and (tbl11.UserEnabled or tbl11.Enabled)
		if flag28 or userEnabled then
			tbl6.enableWaterWalk(character, humanoidRootPart, humanoid)
		end
		pcall(function()
			localPlayer:RequestStreamAroundAsync(v9.Position, 2)
		end)
		local ok, result, result2 = pcall(function()
			return tbl6.moveTo(v9, true)
		end)
		if not ok then
			tbl6.lastReturnError = tostring(result)
			warn("[Hune Hub] Return movement recovered: " .. tbl6.lastReturnError)
			result = false
			result2 = "ReturnMovementError"
		else
			tbl6.lastReturnError = nil
		end
		if result and (tbl6.method == "Walk" or result2 == "WalkReturn") then
			task.wait(0.2)
			if humanoidRootPart.Parent then
				humanoid:MoveTo(humanoidRootPart.Position)
			end
		end
		flag28 = flag28 and not userEnabled
		if flag28 then
			flag28 = not (tbl11 and tbl11.UserEnabled)
		end
		if flag28 then
			tbl6.disableWaterWalk()
		end
		if result then
			local n20 = os.clock() + 2.5
			local v10 = nil
			while true do
				if not flag or localPlayer.Character ~= character or not humanoidRootPart.Parent or humanoid.Health <= 0 then
					result2 = "CharacterNotReady"
					result = false
					break
				elseif tbl6.atSavedSpot(humanoidRootPart, character, v9) then
					local now3 = v10 or os.clock()
					if os.clock() - now3 >= 0.6 then
						result2 = nil
						result = true
						break
					else
						v10 = now3
						task.wait(0.1)
						result2 = nil
						result = false
						if not (n20 <= os.clock()) then
							continue
						end
					end
				else
					v10 = nil
					task.wait(0.1)
					result2 = nil
					result = false
					if not (n20 <= os.clock()) then
						continue
					end
				end
				break
			end
			if not result then
				result2 = result2 or "ReturnPositionChanged"
			end
			if result then
				local rotation = v9.Rotation
				humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position) * rotation
				humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
				humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
			end
		end
		if not result then
			return tbl6.deferReturn(result2)
		end
		cFrame3 = v9
		if flag19 then
			cFrame2 = v9
		end
		tbl6.farmSpotPending = false
		tbl6.pending = false
		tbl6.lastReturnReason = nil
		tbl6.attempts = 0
		tbl6.retryAt = 0
		flag15 = false
		cFrame = resumeSoldFish and v9 or nil
		flag13 = false
		flag11 = false
		flag12 = true
		n11 = 0
		tbl6.bagRefreshAfter = os.clock() + 4
		if tbl6.saleHadFish then
			tbl6.resumeSoldFish = resumeSoldFish
			tbl6.saleHadFish = false
		end
		v3 = nil
		n17 = os.clock() + math.max(tonumber(n) or 0.35, 0.3)
		tbl6.resumeFarm = resumeSoldFish
		tbl6.resumeFarmSince = resumeSoldFish and os.clock() or 0
		tbl6.resumeTarget = resumeSoldFish and v9 or nil
		tbl6.resumeCharacter = resumeSoldFish and character or nil
		tbl6.resumeStage = 0
		tbl6.resumeAt = os.clock() + 0.2
		tbl6.resumeCancelAt = 0
		tbl6.resumeCastAt = 0
		return true, "Returned"
	end
	tbl6.tryRestore = function()
		local ok, result, result2 = pcall(tbl6.restore)
		tbl6.disableWaterWalk()
		if ok then
			return result, result2
		end
		tbl6.lastReturnError = tostring(result)
		warn("[Hune Hub] Return worker recovered: " .. tbl6.lastReturnError)
		return tbl6.deferReturn("ReturnMovementError")
	end
	tbl6.resumeFishing = function(resumeCancelAt, arg, arg2)
		local humanoidRootPart = arg:FindFirstChild("HumanoidRootPart")
		local resumeTarget = tbl6.resumeTarget
		if not humanoidRootPart or arg ~= tbl6.resumeCharacter or not resumeTarget or not tbl6.atSavedSpot(humanoidRootPart, arg, resumeTarget) then
			tbl6.recoverResumePosition("ReturnPositionChanged")
			return
		end
		if resumeCancelAt < tbl6.resumeAt then
			return
		end
		local v9 = fn7()
		local flag28 = false
		for _, child in ipairs(arg:GetChildren()) do
			if fn29(child) then
				flag28 = true
				break
			end
		end
		local flag29 = tbl6.resumeStage >= 2 and flag28
		local flag30
		if flag29 then
			flag30 = v9 == FishingEnums.State.Waiting or v9 == FishingEnums.State.FirstPull or v9 == FishingEnums.State.Reeling or v9 == FishingEnums.State.Caught or v9 == FishingEnums.State.Escaped
		else
			flag30 = flag29
		end
		if flag30 then
			if tbl6.resumeSoldFish then
				flag11 = false
				tbl6.bagRefreshAfter = os.clock() + 3
			end
			tbl6.resumeSoldFish = false
			tbl6.resumeFarm = false
			tbl6.resumeTarget = nil
			tbl6.resumeCharacter = nil
			tbl6.rodId = nil
			cFrame = nil
			v3 = nil
			n17 = os.clock() + math.max(tonumber(n) or 0.35, 0.3)
			return
		end
		if tbl6.resumeStage == 0 then
			tbl6.closeMerchantDialogue()
			pcall(function()
				arg2:UnequipTools()
			end)
			tbl6.resumeStage = 1
			tbl6.resumeAt = os.clock() + 0.25
			v3 = nil
			return
		end
		if tbl6.resumeStage == 1 then
			if v9 ~= FishingEnums.State.Idling then
				if resumeCancelAt - tbl6.resumeCancelAt >= 2 then
					tbl6.resumeCancelAt = resumeCancelAt
					pcall(function()
						FishingPackets.FishCancel:Fire()
					end)
					pcall(function()
						arg2:UnequipTools()
					end)
				end
				tbl6.resumeAt = os.clock() + 0.25
				return
			end
			if localPlayer:GetAttribute("IsUsingSkill") == true then
				tbl6.resumeAt = resumeCancelAt + 0.25
				return
			end
			if fn8(tbl6.rodId) then
				tbl6.resumeStage = 2
				tbl6.resumeCastAt = os.clock()
				tbl6.resumeAt = os.clock() + 0.2
			else
				tbl6.resumeAt = os.clock() + 0.5
			end
			return
		end
		if tbl6.resumeStage == 2 and v9 == FishingEnums.State.Idling then
			if not flag28 then
				tbl6.resumeStage = 1
				tbl6.resumeAt = resumeCancelAt + 0.25
				return
			end
			tbl6.resumeStage = 3
			tbl6.resumeCastAt = os.clock()
			pcall(fn9)
			tbl6.resumeAt = os.clock() + 0.15
			return
		end
		if resumeCancelAt - tbl6.resumeCastAt >= 4 then
			local v10
			v10, v10 = fn30()
			if v10 then
				pcall(v10)
			end
			pcall(function()
				arg2:UnequipTools()
			end)
			tbl6.resumeStage = 0
			tbl6.resumeAt = os.clock() + 0.5
		else
			tbl6.resumeAt = resumeCancelAt + 0.15
		end
	end
	fn14 = function(arg)
		if flag20 or tbl6.isBoatTravelBusy and tbl6.isBoatTravelBusy() then
			return false, "MovementBusy", 0, 0
		end
		if tbl6.pending then
			flag20 = true
			local v9, v10 = tbl6.tryRestore()
			flag20 = false
			return v9, v9 and "ReturnCompleted" or v10, 0, 0
		end
		if tbl6.resumeFarm then
			return false, "ResumingFishing", 0, 0
		end
		local npcFishSeller, v9 = fn35("npc_fish_seller")
		if not v9 then
			if flag15 then
				return tbl6.waitForSale("MerchantNotFound")
			end
			return false, "MerchantNotFound", 0, 0
		end
		local v10 = fn6()
		if not v10 then
			if flag15 then
				return tbl6.waitForSale("CharacterNotReady")
			end
			return false, "CharacterNotReady", 0, 0
		end
		if not cFrame3 and not flag15 then
			cFrame3 = v10.CFrame
		end
		cFrame = cFrame or cFrame3 or v10.CFrame
		flag20 = true
		local flag28 = false
		local v11 = nil
		local flag29 = false
		flag26 = true
		pcall(function()
			local v12 = fn6()
			if v12 and (v12.Position - v9).Magnitude <= 4.5 then
				flag28 = true
				return
			end
			if not fn13(arg) then
				flag29 = true
				return
			end
			flag26 = false
			local v13 = fn6()
			if not v13 then
				return
			end
			if (v13.Position - v9).Magnitude > 4.5 then
				if tbl6.method == "Tween" then
					local v14 = fn36(v9, 6)
					if v14 then
						local v15, v16 = tweenTo(v14, nil, tbl6.tweenSpeed)
						flag28 = v15
						v11 = v16
					end
				else
					local v14, v15 = tbl6.walkToMerchant(npcFishSeller, v9)
					flag28 = v14
					v11 = v15
				end
			else
				flag28 = true
			end
		end)
		flag26 = false
		if flag29 and not flag28 then
			flag15 = false
			flag20 = false
			return false, "MovementLocked", 0, 0
		end
		local sellController = getrenv and getrenv().shared and getrenv().shared.SellController
		if not sellController and client and client.GetController then
			pcall(function()
				sellController = client.GetController("SellController")
			end)
		end
		local tbl17 = {}
		pcall(function()
			local v12 = PlayerDataV2Controller:Fetch(localPlayer)
			local fish = Catalog and Catalog.Fish
			local tbl18 = {}
			local v13 = pairs
			local sellRarities = tbl8.sellRarities or {}
			for k, sellRarity in v13(sellRarities) do
				if sellRarity then
					tbl18[k] = true
				end
			end
			local fishes = v12 and v12.Inventory and v12.Inventory.Fishes
			if type(fishes) == "table" and sellController and sellController.ToggleLock then
				for k, fishe in pairs(fishes) do
					if type(fishe) == "table" then
						local uid = fishe.uid or k
						local getById = fish and fish.GetById and fish.GetById(fishe.fishId)
						if fishe.locked ~= true and tbl8.sellEnabled and (tbl18[getById and getById.rarity or fishe.rarity or "Common"] or (fishe.isHuge == true or getById and getById.isHuge == true) and tbl18.Huge) then
							local v14, v15 = sellController:ToggleLock(uid)
							if v14 == 0 and v15 == true then
								table.insert(tbl17, uid)
							end
						end
					end
				end
			end
		end)
		local n20 = 0
		local n21 = 0
		pcall(function()
			local v12 = PlayerDataV2Controller:Fetch(localPlayer)
			n20 = v12 and v12.Coin or 0
			local fishes = v12 and v12.Inventory and v12.Inventory.Fishes
			if type(fishes) == "table" then
				for _, fishe in pairs(fishes) do
					if type(fishe) == "table" and fishe.locked ~= true then
						n21 += 1
					end
				end
			end
		end)
		local n22 = 0
		local n23 = 0
		local v12 = nil
		for i = 1, 3 do
			task.wait(0.3)
			if sellController and sellController.SellAll then
				v12, n22, n23 = sellController:SellAll()
			else
				v12, n22, n23 = v5:Fire()
			end
			if not (v12 ~= 1 and v12 ~= SellEnums.Status.Busy) then
				continue
			end
			break
		end
		pcall(function()
			if sellController and sellController.ToggleLock and #tbl17 > 0 then
				local v13 = PlayerDataV2Controller:Fetch(localPlayer)
				local fishes = v13 and v13.Inventory and v13.Inventory.Fishes or {}
				for _, v14 in ipairs(tbl17) do
					if fishes[v14] then
						local v15, v16 = sellController:ToggleLock(v14)
						if v15 == 0 and v16 == true then
							sellController:ToggleLock(v14)
						end
					end
				end
			end
		end)
		pcall(function()
			local v13 = PlayerDataV2Controller:Fetch(localPlayer)
			local coin = v13 and v13.Coin or 0
			local flag30 = not n22
			if not flag30 then
				flag30 = (tonumber(n22) or 0) <= 0
			end
			if flag30 and coin > n20 then
				n22 = coin - n20
			end
			local flag31 = not n23
			if not flag31 then
				flag31 = (tonumber(n23) or 0) <= 0
			end
			if flag31 then
				flag31 = (tonumber(n22) or 0) > 0
			end
			if flag31 then
				local fishes = v13 and v13.Inventory and v13.Inventory.Fishes
				local n24 = 0
				if type(fishes) == "table" then
					for _, fishe in pairs(fishes) do
						if type(fishe) == "table" and fishe.locked ~= true then
							n24 += 1
						end
					end
				end
				n23 = math.max(1, n21 - n24)
			end
		end)
		flag15 = false
		tbl6.saleAttempts = 0
		tbl6.saleRetryAt = 0
		tbl6.lastSaleReason = nil
		tbl6.saleHadFish = v12 == 0 or v12 == SellEnums.Status.Ok or n22 and n22 > 0 or n23 and n23 > 0
		if tbl6.saleHadFish then
			flag11 = false
			flag12 = true
			n11 = 0
			tbl6.bagRefreshAfter = os.clock() + 4
		end
		flag20 = true
		tbl6.tryRestore()
		flag20 = false
		if v12 == 0 or v12 == SellEnums.Status.Ok then
			return fn37(n22, n23, "Fish Merchant")
		end
		if v12 == 3 or v12 == SellEnums.Status.SatchelFull then
			return false, "SatchelFull", 0, 0
		end
		return false, tostring(v12 or "SaleCompleted"), 0, 0
	end
	fn15 = function()
		local ok, result = pcall(function()
			local v9 = PlayerDataV2Controller:Fetch(localPlayer)
			if type(v9) ~= "table" then
				return nil
			end
			return FishStorageRules.GetState(v9)
		end)
		if ok and type(result) == "table" then
			return result.isFull == true
		end
		return nil
	end
	fn16 = function(arg, arg2)
		if arg == "ResumingFishing" then
			if arg2 then
				lib:Notify({
					Title = text("Fishing Resume In Progress"),
					Content = text("Auto Farm is resuming. Try selling again in a moment."),
					Duration = 3,
				})
			end
			return
		end
		local flag28 = not arg2
		if flag28 and (arg == "PositionCorrected" or arg == "TweenInterrupted" or arg == "TweenFailed" or arg == "NoSafeRoute") then
			return
		end
		local lastFailureKey = tostring(arg) .. ":" .. tostring(tbl6.pending) .. ":" .. tostring(tbl6.lastReturnReason)
		local now3 = os.clock()
		if flag28 and lastFailureKey == tbl6.lastFailureKey and now3 - tbl6.lastFailureAt < 6 then
			return
		end
		tbl6.lastFailureKey = lastFailureKey
		tbl6.lastFailureAt = now3
		if tbl6.pending then
			local lastReturnReason = tbl6.lastReturnReason
			if not arg2 and (lastReturnReason == "NoSafeRoute" or lastReturnReason == "ReturnPositionChanged") then
				return
			end
			local str = tbl6.method == "Walk" and lastReturnReason == "NoSafeRoute" and "No safe walking route back to the saved fishing spot. Retrying automatically..." or "The saved fishing spot has not been reached. Retrying return automatically..."
			lib:Notify({ Title = text("Return To Fishing Spot Pending"), Content = str, Duration = 5 })
		elseif arg == SellEnums.Status.Empty then
			lib:Notify({
				Title = text("No Fish To Sell"),
				Content = text("No unlocked fish are available."),
				Duration = 3,
			})
		elseif arg == SellEnums.Status.OutOfRange then
			lib:Notify({
				Title = text("Merchant Out Of Range"),
				Content = text("Staying at the merchant until the next sell attempt."),
				Duration = 4,
			})
		elseif arg == SellEnums.Status.Busy then
			lib:Notify({
				Title = text("Sell Request Busy"),
				Content = text("Please try again in a moment."),
				Duration = 3,
			})
		elseif arg == "MerchantNotFound" then
			lib:Notify({
				Title = text("Fish Merchant Not Found"),
				Content = text("Wait for the island NPC to load, then try again."),
				Duration = 4,
			})
		elseif arg == "MerchantOutOfRange" then
			lib:Notify({
				Title = text("Merchant Out Of Range"),
				Content = text("The character stopped outside the merchant's sell radius."),
				Duration = 4,
			})
		elseif arg == "NoSafeRoute" then
			if not arg2 then
				return
			end
			lib:Notify({
				Title = text("Safe Route Unavailable"),
				Content = text("Retrying movement automatically..."),
				Duration = 3,
			})
		elseif arg == "PositionCorrected" then
			lib:Notify({
				Title = text("Sell Request Failed"),
				Content = text("The game moved the character away from the Fish Merchant."),
				Duration = 4,
			})
		elseif arg == "MovementBusy" or arg == "MovementLocked" then
			lib:Notify({
				Title = text("Movement Busy"),
				Content = text("Wait for the current travel action to finish."),
				Duration = 3,
			})
		elseif arg == "ReturnPositionChanged" or arg == "ReturnPositionUnavailable" or arg == "ReturnFailed" then
			lib:Notify({
				Title = text("Return Pending"),
				Content = text("The saved fishing position has not been reached. Auto Farm remains paused."),
				Duration = 4,
			})
		elseif arg == "FishLockBusy" or arg == "FishLockFailed" then
			lib:Notify({
				Title = text("Fish Filter"),
				Content = text("Could not confirm protected fish are locked. Sale postponed."),
				Duration = 4,
			})
		else
			lib:Notify({
				Title = text("Sell Request Failed"),
				Content = text("The sale could not be completed.") .. " (" .. tostring(arg) .. ")",
				Duration = 4,
			})
		end
	end
	fn17 = function(arg)
		task.spawn(function()
			local ok, result = pcall(arg)
			flag14 = false
			if not ok then
				flag20 = false
				warn("[Hune Hub] Auto Sell worker recovered: " .. tostring(result))
			end
		end)
	end
	fn18 = function()
		local currentIslandId
		pcall(function()
			local IslandRegionController = require(ReplicatedStorage.Controllers.IslandRegionController)
			currentIslandId = IslandRegionController and IslandRegionController:GetCurrentIslandId()
		end)
		return currentIslandId
	end
	local function fn38(arg)
		for _, v9 in ipairs(CollectionService:GetTagged("IslandRegion")) do
			if v9:IsA("BasePart") and v9:IsDescendantOf(workspace) and v9:GetAttribute("islandId") == arg then
				return v9
			end
		end
		return nil
	end
	fn19 = function(arg)
		local world = workspace:FindFirstChild("World")
		world = world and world:FindFirstChild("Islands")
		world = world and world:FindFirstChild(arg)
		if not world then
			return nil
		end
		local v9 = ipairs
		local v10 = table.pack(CollectionService:GetTagged("Interactive"))
		v10.n = 1 + v10.n - 1
		table.move(v10, 1, v10.n, 1, v10)
		for _, v11 in v9(table.unpack(v10, 1, v10.n)) do
			if v11:IsDescendantOf(world) then
				local attribute = v11:GetAttribute("InteractiveId")
				if type(attribute) == "string" and attribute:match("^npc_unlock_island_%d+$") then
					local v12 = fn12(v11)
					if v12 then
						return fn36(v12, 6)
					end
				end
			end
		end
		local spawnPoint = world:FindFirstChild("SpawnPoint")
		local v11 = fn33(spawnPoint)
		if v11 then
			return CFrame.new(v11 + Vector3.new(0, 4, 0))
		end
		local v12 = ipairs
		local v13 = table.pack(CollectionService:GetTagged("Interactive"))
		v13.n = 1 + v13.n - 1
		table.move(v13, 1, v13.n, 1, v13)
		for _, v14 in v12(table.unpack(v13, 1, v13.n)) do
			if v14:IsDescendantOf(world) then
				if v14:GetAttribute("InteractiveId") == "npc_fish_seller" then
					local v15 = fn12(v14)
					if v15 then
						return fn36(v15, 5)
					end
				end
			end
		end
		for _, descendant in ipairs(world:GetDescendants()) do
			if descendant:IsA("BasePart") then
				local v14 = fn34(descendant.Name)
				if v14 == "spawn" or v14 == "spawnpoint" or v14 == "teleportpoint" or v14 == "arrival" then
					return CFrame.new(descendant.Position + Vector3.new(0, 4, 0))
				end
			end
		end
		local v14 = fn38(arg)
		if v14 then
			local n20 = v14.Position + Vector3.new(0, v14.Size.Y * 0.5 + 80, 0)
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			raycastParams.RespectCanCollide = true
			local filterDescendantsInstances = { v14 }
			local zones = world:FindFirstChild("Zones")
			if zones then
				table.insert(filterDescendantsInstances, zones)
			end
			if localPlayer.Character then
				table.insert(filterDescendantsInstances, localPlayer.Character)
			end
			raycastParams.FilterDescendantsInstances = filterDescendantsInstances
			local hit = workspace:Raycast(n20, Vector3.new(0, -v14.Size.Y - 250, 0), raycastParams)
			if hit and hit.Instance:IsDescendantOf(world) and hit.Normal.Y > 0.5 then
				return CFrame.new(hit.Position + Vector3.new(0, 4, 0))
			end
		end
		return nil
	end
	fn20 = function()
		n7 += 1
		n5 = 0
		n6 = 0
		flag8 = false
		n8 = 0
	end
	local function fn39()
		if not RodController then
			pcall(function()
				RodController = client.GetController("RodController")
			end)
		end
		if RodController and not flag27 and RodController.ReplicatedSkillCooldown then
			local ok, result = pcall(function()
				return RodController.ReplicatedSkillCooldown.OnClientEvent:Connect(function(arg)
					if type(arg) ~= "table" then
						return
					end
					for k, v9 in pairs(arg) do
						if type(k) == "string" and type(v9) == "table" then
							if v9.phase == "Ready" then
								tbl5[k] = nil
							elseif v9.phase == "Cooldown" and type(v9.remaining) == "number" and v9.remaining > 0 then
								local remaining = v9.remaining
								tbl5[k] = { phase = "Cooldown", remaining = v9.remaining, expiresAt = os.clock() + remaining }
							elseif v9.phase == "Casting" then
								local v10 = tbl5[k]
								local v11 = tbl5
								local tbl17 = { phase = "Casting", remaining = v9.remaining }
								local expiresAt = type(v10) == "table" and v10.expiresAt
								local expiresAt2
								if expiresAt then
									expiresAt2 = expiresAt
								else
									expiresAt2 = os.clock() + math.max(tonumber(v9.remaining) or 0, 0.5) + 10
								end
								tbl17.expiresAt = expiresAt2
								v11[k] = tbl17
							else
								tbl5[k] = v9
							end
						end
					end
				end)
			end)
			if ok and result then
				flag27 = true
				fn2(result)
			end
		end
		return RodController
	end
	local function fn40()
		local v9 = nil
		pcall(function()
			v9 = PlayerDataV2Controller:Fetch(localPlayer)
		end)
		if not v9 then
			pcall(function()
				v9 = PlayerDataV2Controller:Fetch()
			end)
		end
		local rodEquip = v9 and v9.RodEquip
		local rods = rodEquip and v9.Rods and v9.Rods[rodEquip]
		rodEquip = rodEquip and Catalog.Rod.GetById(rodEquip)
		local v10 = nil
		if rods then
			pcall(function()
				v10 = require(ReplicatedStorage.Shared.Lib.getRequiredExp_Level).getLevel(rods.MasteryXp or 0)
			end)
		end
		return rods and rods.BookSlots or nil, rodEquip, v10
	end
	fn21 = function()
		return n6 > 0 and n5 > 0 and n5 <= n6 * finisherPct + 0.001
	end
	tbl5.sendSpamStep = function(arg, arg2, arg3, arg4)
		local n20 = math.clamp(tonumber(arg3 and arg3.skillSlots) or 4, 1, 4)
		local spamOrder = tbl5.spamOrder or { "Slot1", "Slot2", "Slot3", "Slot4" }
		local n21 = #spamOrder
		for i = 0, n21 - 1 do
			local n22 = (tbl5.spamNextIndex + i - 1) % n21 + 1
			local v9 = spamOrder[n22]
			local v10 = arg2[v9]
			local num = tonumber(v9 and v9:match("%d+")) or n22
			local slotUnlockLevels = arg3 and arg3.slotUnlockLevels and arg3.slotUnlockLevels[num]
			local flag28 = num <= n20
			local flag29
			if flag28 then
				local flag30 = not arg3
				if flag30 then
					flag29 = flag30
				else
					local flag31 = slotUnlockLevels ~= nil
					if flag31 then
						flag29 = arg4 == nil or arg4 >= slotUnlockLevels
					else
						flag29 = flag31
					end
				end
			else
				flag29 = flag28
			end
			flag29 = flag29 and type(v10) == "string" and v10 ~= ""
			if flag29 then
				tbl5.spamNextIndex = n22 % n21 + 1
				pcall(function()
					arg.Moveset:Fire(v9, v10)
				end)
				return true
			end
		end
		return false
	end
	fn22 = function()
		if flag8 or not flag or not flag21 or not tbl5.isEnabled() or not tbl8:allowsCurrent() then
			return
		end
		flag8 = true
		local v9 = n7
		task.spawn(function()
			local v10 = fn39()
			local v11, v12, v13 = fn40()
			if not v10 or type(v11) ~= "table" then
				if v9 == n7 then
					flag8 = false
				end
				return
			end
			local n20 = math.clamp(tonumber(v12 and v12.skillSlots) or 4, 1, 4)
			while true do
				if flag and flag21 and v9 == n7 and tbl5.isEnabled() and tbl8:allowsCurrent() then
					if flag7 or flag20 and not flag26 or flag14 and not flag26 or flag15 or tbl6.pending or tbl6.resumeFarm then
						task.wait(0.1)
						continue
					elseif tbl5.spamEnabled then
						if tbl5.sendSpamStep(v10, v11, v12, v13) then
							task.wait(tbl5.spamInterval)
							continue
						end
					elseif os.clock() < n8 or localPlayer:GetAttribute("IsUsingSkill") == true then
						task.wait(math.clamp(n8 - os.clock(), 0.05, 0.15))
						continue
					else
						local v14 = nil
						local v15 = nil
						local order = tbl5.order
						local n21 = #order
						local flag28 = false
						local n22 = nil
						for i = 0, n21 - 1 do
							n22 = ((tbl5.nextIndex or 1) + i - 1) % n21 + 1
							local v16 = order[n22]
							local num = tonumber(v16:match("%d+"))
							local v17 = v11[v16]
							local v18 = tbl5[v16]
							local slotUnlockLevels = v12 and v12.slotUnlockLevels and v12.slotUnlockLevels[num]
							local flag29 = num <= n20 and (not v12 or slotUnlockLevels ~= nil and (v13 == nil or v13 >= slotUnlockLevels))
							local str
							if type(v18) ~= "table" then
								str = "Ready"
							else
								local expiresAt = (v18.phase == "Cooldown" or v18.phase == "Casting") and v18.expiresAt
								if expiresAt then
									local expiresAt2 = v18.expiresAt
									expiresAt = os.clock() >= expiresAt2
								end
								if expiresAt then
									tbl5[v16] = nil
									str = "Ready"
								else
									str = v18.phase or "Ready"
								end
							end
							local cooldownActive = v10.CooldownActive and v10.CooldownActive[v16]
							if type(cooldownActive) == "table" then
								if cooldownActive.phase == "Casting" then
									str = "Casting"
								else
									local flag30 = cooldownActive.phase == "Cooldown"
									if flag30 then
										flag30 = not cooldownActive.endTick
										if not flag30 then
											local endTick = cooldownActive.endTick
											flag30 = tick() < endTick
										end
									end
									if flag30 then
										str = "Cooldown"
									end
								end
							end
							if flag29 and type(v17) == "string" and v17 ~= "" then
								if str == "Casting" or str == "Cooldown" then
									flag28 = true
									n22 = nil
								else
									v14 = v16
									v15 = v17
								end
								break
							else
								n22 = nil
							end
						end
						if not v14 then
							if flag28 then
								task.wait(0.1)
								continue
							end
						else
							local minCastTime = FishingConfig.Skill and FishingConfig.Skill.MinCastTime or 0.5
							local v16 = nil
							pcall(function()
								v16 = Catalog.Skill.GetById(v15)
							end)
							local n23 = math.max(tonumber(v16 and v16.castTime) or minCastTime, minCastTime)
							local n24 = math.max(tonumber(v16 and v16.cooldown) or 0, 0)
							tbl5[v14] = { phase = "Casting", expiresAt = os.clock() + n23 + n24 + 0.15 }
							if not pcall(function()
								v10.Moveset:Fire(v14, v15)
							end) then
								tbl5[v14] = nil
								task.wait(0.1)
							else
								tbl5.nextIndex = n22 % n21 + 1
								n8 = math.max(n8, os.clock() + n23 + 0.08)
								task.wait(0.05)
							end
							continue
						end
					end
				end
				break
			end
			if v9 == n7 then
				flag8 = false
			end
		end)
	end
	fn23 = function(arg, arg2)
		n7 += 1
		n14 += 1
		tbl5.nextIndex = 1
		tbl5.spamNextIndex = 1
		n5 = tonumber(arg) or 0
		n6 = tonumber(arg2) or 0
		flag8 = false
		flag22 = false
		n8 = 0
		flag21 = true
		idling = FishingEnums.State.Reeling
	end
	fn24 = function()
		local flag28 = flag22 or not tbl8:allowsCurrent()
		if not flag28 then
			flag28 = not (flag and flag3 and flag21)
		end
		if flag28 then
			return
		end
		flag22 = true
		local v9 = n14
		task.spawn(function()
			while true do
				if flag and flag3 and flag21 and v9 == n14 and tbl8:allowsCurrent() then
					local v10 = fn7()
					if v10 and v10 ~= FishingEnums.State.Reeling then
						flag21 = false
						break
					else
						if tbl5.isEnabled() and fn21() then
							fn22()
							task.wait(0.01)
						else
							if tbl5.isEnabled() then
								fn22()
							end
							if flag7 or os.clock() < n8 or localPlayer:GetAttribute("IsUsingSkill") == true then
								task.wait(0.01)
							else
								n19 = (n19 + 1) % 65536
								pcall(function()
									FishingPackets.FishReelPull:Fire(n19)
								end)
								task.wait(n18)
							end
						end
						continue
					end
				end
				break
			end
			if v9 == n14 then
				flag22 = false
			end
		end)
	end
	local function fn41()
		local zones = FishingConfig.PullBar and FishingConfig.PullBar.Zones or {}
		local n20 = 0
		for _, zone in ipairs(zones) do
			if zone.multiplier == 10 then
				return n20, zone.threshold
			end
			n20 = zone.threshold or n20
		end
		return 0.8769, 1
	end
	fn25 = function(arg, arg2)
		local flag28 = flag23
		if not flag23 then
			flag28 = not (flag and flag2)
		end
		if flag28 or not tbl8:allowsCurrent() then
			return
		end
		flag23 = true
		n15 += 1
		local v9 = n15
		idling = FishingEnums.State.FirstPull
		task.spawn(function()
			local v10, v11 = fn41()
			local n20 = v10 + 0.025
			local oscillateSpeed = FishingConfig.FirstPull and FishingConfig.FirstPull.OscillateSpeed or 2.4
			local num = tonumber(arg2)
			local timeLimit = tonumber(arg) or FishingConfig.FirstPull and FishingConfig.FirstPull.TimeLimit or 2
			if num then
				timeLimit -= workspace:GetServerTimeNow() - num
			end
			local n21 = os.clock() + math.max(timeLimit - 0.1, 0.05)
			task.wait(0.05)
			local v12 = nil
			while flag and flag2 and v9 == n15 and tbl8:allowsCurrent() and os.clock() < n21 do
				local v13 = fn7()
				if v13 == FishingEnums.State.FirstPull then
					local pullBarValue = nil
					local flag29
					if num then
						local n22 = workspace:GetServerTimeNow() - num
						local n23 = math.max(n22, 0) * oscillateSpeed % 2
						pullBarValue = PullBarMath.Position(n22, oscillateSpeed)
						flag29 = n23 <= 1
					else
						pcall(function()
							pullBarValue = FishingController:GetPullBarValue()
						end)
						flag29 = type(pullBarValue) == "number" and v12 and pullBarValue > v12 + 0.001
					end
					if type(pullBarValue) == "number" then
						flag29 = flag29 and pullBarValue >= n20 and pullBarValue <= v11
						if flag29 then
							pcall(function()
								FishingPackets.FishFirstPull:Fire()
							end)
							return
						end
						v12 = pullBarValue
					end
				elseif v13 and v13 ~= FishingEnums.State.Waiting then
					return
				end
				task.wait(0.015)
			end
			local flag29 = flag and flag2 and v9 == n15 and tbl8:allowsCurrent()
			if flag29 then
				local firstPull = FishingEnums.State.FirstPull
				flag29 = fn7() == firstPull
			end
			if flag29 then
				pcall(function()
					FishingPackets.FishFirstPull:Fire()
				end)
			end
		end)
	end
	local function fn42()
		local currentCamera = workspace.CurrentCamera
		currentCamera = currentCamera and currentCamera.ViewportSize or Vector2.new(1280, 720)
		local tbl17 = {}
		local vector2 = Vector2.new(currentCamera.X * 0.5, currentCamera.Y * 0.92)
		local vector22 = Vector2.new(currentCamera.X * 0.15, currentCamera.Y * 0.82)
		local vector23 = Vector2.new
		local n20 = currentCamera.X * 0.85
		local n21 = currentCamera.Y * 0.82
		tbl17[1] = vector2
		tbl17[2] = vector22
		do
			local values = table.pack(vector23(n20, n21))
			table.move(values, 1, values.n, 3, tbl17)
		end
		for _, v9 in ipairs(tbl17) do
			local tbl18 = {}
			pcall(function()
				tbl18 = playerGui:GetGuiObjectsAtPosition(v9.X, v9.Y)
			end)
			local flag28 = false
			for _, v10 in ipairs(tbl18) do
				while true do
					if v10 and v10 ~= playerGui then
						if v10:GetAttribute("LootItemCard") == true then
							flag28 = true
							break
						else
							v10 = v10.Parent
							continue
						end
					end
					break
				end
				if flag28 then
					break
				end
			end
			if not flag28 then
				return v9
			end
		end
		return tbl17[1]
	end
	fn = function()
		local v9 = fn42()
		if pcall(function()
			VirtualInputManager:SendMouseButtonEvent(v9.X, v9.Y, 0, true, game, 0)
			task.wait(0.02)
			VirtualInputManager:SendMouseButtonEvent(v9.X, v9.Y, 0, false, game, 0)
		end) then
			return true
		end
		return pcall(function()
			local VirtualUser = game:GetService("VirtualUser")
			local currentCamera = workspace.CurrentCamera
			VirtualUser:CaptureController()
			VirtualUser:Button1Down(v9, currentCamera and currentCamera.CFrame or CFrame.new())
			task.wait(0.02)
			VirtualUser:Button1Up(v9, currentCamera and currentCamera.CFrame or CFrame.new())
		end)
	end
	tbl8.confirmFishingLoot = function(arg)
		local v9 = LootController
		local sessionMaid = LootController
		if v9 then
			sessionMaid = v9._sessionMaid
		end
		if not sessionMaid or not sessionMaid.ConfirmInput then
			return false, false
		end
		local lootConfirmCache = arg.lootConfirmCache
		if not lootConfirmCache or lootConfirmCache.maid ~= sessionMaid or lootConfirmCache.controller ~= v9 then
			lootConfirmCache = { maid = sessionMaid, controller = v9, retryAt = 0 }
			arg.lootConfirmCache = lootConfirmCache
		end
		local flag28 = not lootConfirmCache.confirm
		if flag28 then
			local retryAt = lootConfirmCache.retryAt
			flag28 = os.clock() >= retryAt
		end
		if flag28 then
			lootConfirmCache.retryAt = os.clock() + 1
			local v10 = getconnections or get_signal_cons
			local getupvalues_ = getupvalues or debug and debug.getupvalues
			if v10 and getupvalues_ then
				local ok, result = pcall(v10, UserInputService.InputBegan)
				local v11 = pairs
				result = ok and type(result) == "table" and result or {}
				for _, v12 in v11(result) do
					local ok2, result2 = pcall(function()
						return v12.Function
					end)
					if ok2 and type(result2) == "function" then
						local ok3, result3 = pcall(getupvalues_, result2)
						if ok3 and type(result3) == "table" then
							for _, v13 in pairs(result3) do
								if type(v13) == "function" then
									local ok4, result4 = pcall(getupvalues_, v13)
									local v14, v15, v16 = pairs(ok4 and type(result4) == "table" and result4 or {})
									local flag29 = false
									local flag30 = false
									for _, v17 in v14, v15, v16 do
										if v17 == sessionMaid then
											flag29 = true
										end
										if v17 == v9 then
											flag30 = true
										end
									end
									if flag29 and flag30 then
										lootConfirmCache.confirm = v13
										break
									end
								end
							end
						end
					end
					if not lootConfirmCache.confirm then
						continue
					end
					break
				end
			end
		end
		if not lootConfirmCache.confirm then
			return false, false
		end
		if not pcall(lootConfirmCache.confirm) then
			lootConfirmCache.confirm = nil
			return false, false
		end
		return v9._sessionMaid ~= sessionMaid or sessionMaid.ConfirmInput == nil and sessionMaid.HidePromise ~= nil, true
	end
end
tbl8.lootHasClosed = function()
	if not LootController then
		pcall(function()
			LootController = client.GetController("LootController")
		end)
	end
	if not LootController then
		return true
	end
	local ok, result = pcall(function()
		return LootController:IsFishingLootActive()
	end)
	return not ok or not result
end
local function fn26(arg)
	if arg then
		tbl8.fastBossLoot = true
	end
	local flag25 = flag24
	if not flag24 then
		flag25 = not (flag and (flag5 or tbl8.fastBossLoot))
	end
	if flag25 then
		return
	end
	flag24 = true
	local v5 = n16
	local confirmReadyDelay = FishingConfig.Loot and FishingConfig.Loot.ConfirmReadyDelay or 0.75
	local lootCaughtAt = tbl8.lootCaughtAt or os.clock()
	task.spawn(function()
		local n18 = os.clock() + confirmReadyDelay + 8
		local flag26 = false
		local exitTo2 = nil
		local exitTo, v6
		while true do
			local fastBossLoot = flag and (flag5 or tbl8.fastBossLoot)
			exitTo = nil
			local wait, n19
			while true do
				if fastBossLoot and v5 == n16 and os.clock() < n18 then
					if not LootController then
						pcall(function()
							LootController = client.GetController("LootController")
						end)
					end
					local flag27 = false
					if LootController then
						pcall(function()
							flag27 = LootController:IsFishingLootActive()
						end)
					end
					v6 = fn7()
					if flag27 then
						local sessionMaid = LootController._sessionMaid
						if sessionMaid and sessionMaid.ConfirmInput == nil and sessionMaid.HidePromise ~= nil then
							exitTo = 2
							break
						else
							flag26 = true
							if not (lootCaughtAt + confirmReadyDelay <= os.clock()) then
								wait = task.wait
								n19 = tbl8.fastBossLoot and 0.1 or 0.15
								wait(n19)
								fastBossLoot = flag and (flag5 or tbl8.fastBossLoot)
								continue
							else
								local v7, v8 = tbl8:confirmFishingLoot()
								if v7 then
									exitTo = 3
									break
								elseif not v8 then
									fn()
									local sessionMaid2 = LootController and LootController._sessionMaid
									if sessionMaid2 and sessionMaid2.ConfirmInput == nil and sessionMaid2.HidePromise ~= nil then
										exitTo = 4
										break
									else
										wait = task.wait
										n19 = tbl8.fastBossLoot and 0.1 or 0.15
										wait(n19)
										fastBossLoot = flag and (flag5 or tbl8.fastBossLoot)
										continue
									end
								else
									wait = task.wait
									n19 = tbl8.fastBossLoot and 0.1 or 0.15
									wait(n19)
									fastBossLoot = flag and (flag5 or tbl8.fastBossLoot)
									continue
								end
							end
						end
					else
						exitTo = 1
						break
					end
				end
				break
			end
			if exitTo == 1 then
				if flag26 or v6 ~= FishingEnums.State.Caught and os.clock() - lootCaughtAt >= 1.5 then
					exitTo2 = 1
					break
				else
					wait = task.wait
					n19 = tbl8.fastBossLoot and 0.1 or 0.15
					wait(n19)
					continue
				end
			end
			break
		end
		if exitTo2 == 1 then
		elseif exitTo == 2 then
		elseif exitTo == 3 then
		elseif exitTo == 4 then
		end
		if v5 == n16 then
			flag24 = false
			tbl8.fastBossLoot = nil
		end
	end)
end
fn2(FishingPackets.FishWaitingAck.OnClientEvent:Connect(function()
	if not flag then
		return
	end
	tbl8.currentFishId = nil
	idling = FishingEnums.State.Waiting
end))
fn2(FishingPackets.FishFirstPullStart.OnClientEvent:Connect(function(currentFishId, arg, arg2, arg3, arg4)
	tbl8.currentFishId = currentFishId
	if flag and tbl8:shouldSkip(currentFishId) then
		tbl8:skipCurrent()
		return
	end
	fn25(arg3, arg4)
end))
fn2(FishingPackets.FishReelStartAck.OnClientEvent:Connect(function(currentFishId, arg, arg2)
	if not flag then
		return
	end
	tbl8.currentFishId = currentFishId
	if not tbl8:allowsCurrent() then
		return
	end
	fn23(arg, arg2)
	if tbl5.isEnabled() then
		fn22()
	end
	if not flag3 then
		return
	end
	fn24()
end))
fn2(FishingPackets.FishReelHPUpdate.OnClientEvent:Connect(function(arg)
	if not flag or not tbl8:allowsCurrent() then
		return
	end
	n5 = tonumber(arg) or n5
	if fn21() then
		if tbl5.isEnabled() then
			fn22()
		end
	end
end))
fn2(FishingPackets.FishReelPhaseHP.OnClientEvent:Connect(function(arg, arg2)
	if not flag or not tbl8:allowsCurrent() then
		return
	end
	n7 += 1
	n5 = tonumber(arg) or 0
	n6 = tonumber(arg2) or 0
	flag8 = false
	n8 = 0
	if tbl5.isEnabled() then
		fn22()
	end
end))
fn2(FishingPackets.FishQTEPrompt.OnClientEvent:Connect(function(arg, arg2)
	if not (flag and flag4) or not tbl8:allowsCurrent() then
		return
	end
	local v5 = fn3(arg)
	if not v5 then
		return
	end
	n3 += 1
	local v6 = n3
	local n18 = math.max(tonumber(arg2) or 0.5, 0.05)
	flag7 = true
	local n19 = math.max(n18 - 0.2, 0.02)
	task.delay(math.min(n2, n19), function()
		if not (flag and flag4 and flag7 and n3 == v6) or not tbl8:allowsCurrent() then
			return
		end
		local state = nil
		if not FishingController then
			pcall(function()
				FishingController = client.GetController("FishingController")
			end)
		end
		if FishingController then
			pcall(function()
				state = FishingController:GetState()
			end)
		end
		local flag25 = state ~= FishingEnums.State.Reeling
		if flag25 then
			flag25 = not (state == nil and flag21)
		end
		if flag25 then
			return
		end
		if n4 == v6 then
			return
		end
		n4 = v6
		if not pcall(function()
			FishingPackets.FishQTEResponse:Fire(v5)
		end) and n3 == v6 then
			n4 = 0
		end
	end)
	task.delay(n18, function()
		if n3 == v6 then
			flag7 = false
		end
	end)
end))
fn2(FishingPackets.FishQTEResult.OnClientEvent:Connect(function()
	n3 += 1
	flag7 = false
end))
fn2(FishingPackets.FishQTECancel.OnClientEvent:Connect(function()
	n3 += 1
	flag7 = false
end))
fn2(FishingPackets.FishCatchResult.OnClientEvent:Connect(function(arg, arg2, arg3, arg4, arg5, arg6)
	tbl8.lootCaughtAt = os.clock()
	tbl8.fastBossLoot = nil
	tbl8.skipPending = false
	tbl8.currentFishId = nil
	flag21 = false
	n14 += 1
	flag22 = false
	n15 += 1
	flag23 = false
	n16 += 1
	flag24 = false
	n3 += 1
	flag7 = false
	fn20()
	if arg then
		n12 += 1
		n13 += arg3 or 0
		local flag25 = arg6 == true
		if not flag25 then
			flag25 = (tbl8.fastLootPolicy and tbl8.fastLootPolicy()) == true
		end
		if flag5 then
			fn26(flag25)
		end
	end
	idling = FishingEnums.State.Caught
	n17 = os.clock() + n
end))
fn2(FishingPackets.FishReset.OnClientEvent:Connect(function()
	local v5 = tbl8
	local v6 = tbl8
	tbl8.fastBossLoot = nil
	v5.lootCaughtAt = nil
	v6.lootConfirmCache = nil
	tbl8.skipPending = false
	tbl8.currentFishId = nil
	flag21 = false
	n14 += 1
	flag22 = false
	n15 += 1
	flag23 = false
	n16 += 1
	flag24 = false
	n3 += 1
	flag7 = false
	fn20()
	idling = FishingEnums.State.Idling
	n17 = os.clock() + n
end))
fn2(FishingPackets.FishSkillWindow.OnClientEvent:Connect(function(arg)
	local n18 = math.max(tonumber(arg) or 0, 0)
	n8 = math.max(n8, os.clock() + n18)
end))
task.spawn(function()
	local state = 1
	local autoFishing, autoFishing2, autoFishing3, character, v5, v6, v7, pending, now3, character2, humanoid, flag25, flag26, farmSpotPending, humanoidRootPart, flag27, humanoidRootPart2, v8, flag28, flag29, currentFishId, n18, n19, v9, fastLootPolicy, v10, v11
	while true do
		if state == 1 then
			autoFishing = FishingConfig.AutoFishing
			if autoFishing then
				state = 2
			else
				state = 3
			end
		elseif state == 2 then
			autoFishing = FishingConfig.AutoFishing.RetryRate
			state = 3
		elseif state == 3 then
			if autoFishing then
				state = 5
			else
				state = 4
			end
		elseif state == 4 then
			autoFishing = 1
			state = 5
		elseif state == 5 then
			autoFishing2 = FishingConfig.AutoFishing
			if autoFishing2 then
				state = 6
			else
				state = 7
			end
		elseif state == 6 then
			autoFishing2 = FishingConfig.AutoFishing.RecastDelay
			state = 7
		elseif state == 7 then
			if autoFishing2 then
				state = 9
			else
				state = 8
			end
		elseif state == 8 then
			autoFishing2 = 1
			state = 9
		elseif state == 9 then
			autoFishing3 = FishingConfig.AutoFishing
			if autoFishing3 then
				state = 10
			else
				state = 11
			end
		elseif state == 10 then
			autoFishing3 = FishingConfig.AutoFishing.StallTimeoutSec
			state = 11
		elseif state == 11 then
			if autoFishing3 then
				state = 13
			else
				state = 12
			end
		elseif state == 12 then
			autoFishing3 = 30
			state = 13
		elseif state == 13 then
			if flag then
				state = 15
			else
				state = 14
			end
		elseif state == 14 then
			return
		elseif state == 15 then
			character = localPlayer.Character
			if character then
				state = 16
			else
				state = 17
			end
		elseif state == 16 then
			character:FindFirstChild("HumanoidRootPart")
			state = 17
		elseif state == 17 then
			v5 = flag14
			if flag14 then
				state = 19
			else
				state = 18
			end
		elseif state == 18 then
			v6 = flag20
			state = 20
		elseif state == 19 then
			v6 = v5
			state = 20
		elseif state == 20 then
			if v6 then
				state = 22
			else
				state = 21
			end
		elseif state == 21 then
			v7 = flag15
			state = 23
		elseif state == 22 then
			v7 = v6
			state = 23
		elseif state == 23 then
			if v7 then
				state = 25
			else
				state = 24
			end
		elseif state == 24 then
			pending = tbl6.pending
			state = 26
		elseif state == 25 then
			pending = v7
			state = 26
		elseif state == 26 then
			if pending then
				state = 31
			else
				state = 27
			end
		elseif state == 27 then
			pending = tbl6.shouldSellFull()
			if pending then
				state = 28
			else
				state = 29
			end
		elseif state == 28 then
			pending = flag11
			state = 29
		elseif state == 29 then
			if pending then
				state = 30
			else
				state = 31
			end
		elseif state == 30 then
			pending = not tbl6.resumeFarm
			state = 31
		elseif state == 31 then
			if pending then
				state = 120
			else
				state = 32
			end
		elseif state == 32 then
			if not resumeSoldFish then
				state = 119
			else
				state = 33
			end
		elseif state == 33 then
			now3 = os.clock()
			character2 = localPlayer.Character
			if character2 then
				state = 35
			else
				state = 34
			end
		elseif state == 34 then
			humanoid = character2
			state = 36
		elseif state == 35 then
			humanoid = character2:FindFirstChildOfClass("Humanoid")
			state = 36
		elseif state == 36 then
			flag25 = not character2
			if flag25 then
				state = 38
			else
				state = 37
			end
		elseif state == 37 then
			flag26 = not humanoid
			state = 39
		elseif state == 38 then
			flag26 = flag25
			state = 39
		elseif state == 39 then
			if flag26 then
				state = 41
			else
				state = 40
			end
		elseif state == 40 then
			flag26 = humanoid.Health <= 0
			state = 41
		elseif state == 41 then
			if flag26 then
				state = 118
			else
				state = 42
			end
		elseif state == 42 then
			if tbl6.resumeFarm then
				state = 115
			else
				state = 43
			end
		elseif state == 43 then
			farmSpotPending = tbl6.farmSpotPending
			if farmSpotPending then
				state = 45
			else
				state = 44
			end
		elseif state == 44 then
			farmSpotPending = not cFrame3
			state = 45
		elseif state == 45 then
			if farmSpotPending then
				state = 46
			else
				state = 50
			end
		elseif state == 46 then
			humanoidRootPart = character2:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				state = 47
			else
				state = 50
			end
		elseif state == 47 then
			cFrame3 = humanoidRootPart.CFrame
			if flag19 then
				state = 48
			else
				state = 49
			end
		elseif state == 48 then
			cFrame2 = cFrame3
			state = 49
		elseif state == 49 then
			tbl6.farmSpotPending = false
			state = 50
		elseif state == 50 then
			flag27 = flag19
			if flag19 then
				state = 51
			else
				state = 52
			end
		elseif state == 51 then
			flag27 = cFrame2
			state = 52
		elseif state == 52 then
			if flag27 then
				state = 53
			else
				state = 54
			end
		elseif state == 53 then
			flag27 = not flag20
			state = 54
		elseif state == 54 then
			if flag27 then
				state = 55
			else
				state = 58
			end
		elseif state == 55 then
			humanoidRootPart2 = character2:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart2 then
				state = 56
			else
				state = 57
			end
		elseif state == 56 then
			humanoidRootPart2 = (humanoidRootPart2.Position - cFrame2.Position).Magnitude > 8
			state = 57
		elseif state == 57 then
			if humanoidRootPart2 then
				state = 112
			else
				state = 58
			end
		elseif state == 58 then
			v8 = fn7()
			if v8 == v3 then
				state = 63
			else
				state = 59
			end
		elseif state == 59 then
			local v12 = v3
			v3 = v8
			now2 = now3
			flag28 = v12 == FishingEnums.State.FirstPull
			if flag28 then
				state = 60
			else
				state = 61
			end
		elseif state == 60 then
			flag28 = v8 ~= FishingEnums.State.FirstPull
			state = 61
		elseif state == 61 then
			if flag28 then
				state = 62
			else
				state = 63
			end
		elseif state == 62 then
			n15 += 1
			flag23 = false
			state = 63
		elseif state == 63 then
			if v8 == FishingEnums.State.Idling then
				state = 94
			else
				state = 64
			end
		elseif state == 64 then
			flag29 = v8 == FishingEnums.State.Holding
			if flag29 then
				state = 66
			else
				state = 65
			end
		elseif state == 65 then
			flag29 = v8 == FishingEnums.State.Throwing
			state = 66
		elseif state == 66 then
			if flag29 then
				state = 93
			else
				state = 67
			end
		elseif state == 67 then
			if v8 == FishingEnums.State.Waiting then
				state = 91
			else
				state = 68
			end
		elseif state == 68 then
			if v8 == FishingEnums.State.FirstPull then
				state = 88
			else
				state = 69
			end
		elseif state == 69 then
			if v8 == FishingEnums.State.Reeling then
				state = 77
			else
				state = 70
			end
		elseif state == 70 then
			if v8 == FishingEnums.State.Caught then
				state = 74
			else
				state = 71
			end
		elseif state == 71 then
			if v8 ~= FishingEnums.State.Escaped then
				state = 111
			else
				state = 72
			end
		elseif state == 72 then
			idling = v8
			if flag21 then
				state = 73
			else
				state = 111
			end
		elseif state == 73 then
			flag21 = false
			n14 += 1
			flag22 = false
			state = 111
		elseif state == 74 then
			idling = v8
			if flag21 then
				state = 75
			else
				state = 76
			end
		elseif state == 75 then
			flag21 = false
			n14 += 1
			flag22 = false
			state = 76
		elseif state == 76 then
			fn26()
			state = 111
		elseif state == 77 then
			idling = v8
			currentFishId = tbl8.currentFishId
			n18 = 0
			n19 = 0
			if FishingController then
				state = 78
			else
				state = 79
			end
		elseif state == 78 then
			pcall(function()
				local fishInfo, v12, v13 = FishingController:GetFishInfo()
				currentFishId = fishInfo or currentFishId
				n18 = v12
				n19 = v13
			end)
			state = 79
		elseif state == 79 then
			if currentFishId then
				state = 80
			else
				state = 81
			end
		elseif state == 80 then
			tbl8.currentFishId = currentFishId
			state = 81
		elseif state == 81 then
			if tbl8.skipPending then
				state = 87
			else
				state = 82
			end
		elseif state == 82 then
			if not tbl8:allowsCurrent() then
				state = 86
			else
				state = 83
			end
		elseif state == 83 then
			if not flag21 then
				state = 84
			else
				state = 85
			end
		elseif state == 84 then
			fn23(n18, n19)
			state = 85
		elseif state == 85 then
			fn24()
			state = 111
		elseif state == 86 then
			task.wait(0.05)
			state = 13
		elseif state == 87 then
			tbl8:skipCurrent()
			task.wait(0.05)
			state = 13
		elseif state == 88 then
			idling = v8
			if tbl8.skipPending then
				state = 90
			else
				state = 89
			end
		elseif state == 89 then
			fn25()
			state = 111
		elseif state == 90 then
			tbl8:skipCurrent()
			state = 111
		elseif state == 91 then
			idling = v8
			if not (autoFishing3 <= now3 - now2) then
				state = 111
			else
				state = 92
			end
		elseif state == 92 then
			pcall(function()
				FishingPackets.FishCancel:Fire()
			end)
			now2 = now3
			n17 = now3 + autoFishing2
			state = 111
		elseif state == 93 then
			idling = v8
			state = 111
		elseif state == 94 then
			idling = FishingEnums.State.Idling
			if tbl8.skipPending then
				state = 95
			else
				state = 98
			end
		elseif state == 95 then
			if now3 - tbl8.skipAt >= 0.5 then
				state = 97
			else
				state = 96
			end
		elseif state == 96 then
			task.wait(0.05)
			state = 13
		elseif state == 97 then
			tbl8.skipPending = false
			tbl8.currentFishId = nil
			state = 98
		elseif state == 98 then
			if flag21 then
				state = 99
			else
				state = 100
			end
		elseif state == 99 then
			flag21 = false
			n14 += 1
			flag22 = false
			state = 100
		elseif state == 100 then
			if not (n17 <= now3) then
				state = 111
			else
				state = 101
			end
		elseif state == 101 then
			if tbl8:lootHasClosed() then
				state = 105
			else
				state = 102
			end
		elseif state == 102 then
			v9 = fn26
			fastLootPolicy = tbl8.fastLootPolicy
			if fastLootPolicy then
				state = 103
			else
				state = 104
			end
		elseif state == 103 then
			fastLootPolicy = tbl8.fastLootPolicy()
			state = 104
		elseif state == 104 then
			v9(fastLootPolicy == true)
			state = 111
		elseif state == 105 then
			v10 = fn8()
			if v10 then
				state = 107
			else
				state = 106
			end
		elseif state == 106 then
			v11 = v10
			state = 108
		elseif state == 107 then
			v11 = fn9()
			state = 108
		elseif state == 108 then
			if v11 then
				state = 109
			else
				state = 110
			end
		elseif state == 109 then
			idling = FishingEnums.State.Throwing
			state = 110
		elseif state == 110 then
			n17 = os.clock() + math.max(autoFishing, 0.25)
			state = 111
		elseif state == 111 then
			task.wait(0.05)
			state = 13
		elseif state == 112 then
			resumeSoldFish = false
			if not pcall(function()
				FarmToggle:Set(false)
			end) then
				state = 113
			else
				state = 114
			end
		elseif state == 113 then
			pcall(function()
				FarmToggle:SetValue(false)
			end)
			state = 114
		elseif state == 114 then
			lib:Notify({
				Title = text("Fishing Area Left"),
				Content = text("Auto Farm stopped because the character moved away from the saved position."),
				Duration = 4,
			})
			task.wait(0.1)
			state = 13
		elseif state == 115 then
			if not pcall(tbl6.resumeFishing, now3, character2, humanoid) then
				state = 116
			else
				state = 117
			end
		elseif state == 116 then
			tbl6.resumeStage = 0
			tbl6.resumeAt = os.clock() + 1
			state = 117
		elseif state == 117 then
			task.wait(0.1)
			state = 13
		elseif state == 118 then
			task.wait(0.2)
			state = 13
		elseif state == 119 then
			v3 = nil
			task.wait(0.1)
			state = 13
		elseif state == 120 then
			v3 = nil
			task.wait(0.1)
			state = 13
		end
	end
end)
task.spawn(function()
	while flag do
		task.wait(1)
		local flag25 = tbl6.shouldSellFull()
		if flag25 then
			local bagRefreshAfter = tbl6.bagRefreshAfter
			flag25 = os.clock() >= bagRefreshAfter
		end
		if flag25 then
			local v5 = fn15()
			if v5 ~= nil then
				flag11 = v5
				if not v5 then
					flag12 = false
				elseif flag12 and os.clock() >= n9 then
					flag12 = false
				end
			end
		end
		local flag26 = tbl6.shouldSellFull() and flag11 and not flag14 and not flag20 and not tbl6.pending and not flag15
		if flag26 then
			flag26 = not (tbl6.isBoatTravelBusy and tbl6.isBoatTravelBusy())
		end
		flag26 = flag26 and os.clock() >= n9
		if flag26 then
			local watchdogAt = tbl6.watchdogAt
			flag26 = os.clock() >= watchdogAt
		end
		if flag26 then
			tbl6.watchdogAt = os.clock() + 30
			local resumeFarm = tbl6.resumeFarm
			if resumeFarm then
				resumeFarm = os.clock() - (tbl6.resumeFarmSince or os.clock()) > 25
			end
			if resumeFarm then
				tbl6.resumeFarm = false
				tbl6.resumeStage = 0
				tbl6.resumeCharacter = nil
				tbl6.resumeTarget = nil
				lib:Notify({
					Title = text("Bag Full"),
					Content = text("Auto Sell resumed after a stuck fishing restart."),
					Duration = 3,
				})
			end
			if flag12 then
				flag12 = false
			end
		end
		if tbl6.pending then
			local flag27 = flag and not flag14 and not flag20
			if flag27 then
				local retryAt = tbl6.retryAt
				flag27 = os.clock() >= retryAt
			end
			if flag27 then
				if (tbl6.attempts or 0) >= 15 then
					tbl6.pending = false
					tbl6.attempts = 0
					tbl6.resumeFarm = false
					tbl6.resumeStage = 0
					cFrame3 = nil
					cFrame = nil
					cFrame2 = nil
					flag12 = false
					lib:Notify({
						Title = text("Return To Fishing Spot Pending"),
						Content = text("Cannot walk back to the saved spot. Auto Farm will re-pin at the current position."),
						Duration = 5,
					})
				else
					flag14 = true
					flag20 = true
					fn17(function()
						local v5 = tbl6.tryRestore()
						flag20 = false
						if v5 then
							lib:Notify({
								Title = text("Fishing Position Restored"),
								Content = text("Returned to the saved spot. Auto Farm can resume."),
								Duration = 3,
							})
						end
					end)
				end
			end
		else
			local flag27 = flag15 and cFrame and not flag14 and not flag20 and not tbl6.resumeFarm
			if flag27 then
				local saleRetryAt = tbl6.saleRetryAt
				flag27 = os.clock() >= saleRetryAt
			end
			if flag27 then
				flag14 = true
				fn17(function()
					local ok, result, result2 = pcall(fn14, true)
					if not ok then
						flag20 = false
						result, result2 = tbl6.waitForSale("RequestFailed")
					end
					if result or result2 == SellEnums.Status.Empty then
						flag12 = true
					elseif result2 == "ResumingFishing" then
						tbl6.saleRetryAt = os.clock() + 2
					elseif not flag15 and not tbl6.pending then
						tbl6.tryRestore()
					end
				end)
			else
				local flag28 = tbl6.shouldSellFull() and flag11 and not flag12 and not flag13 and not flag14 and not flag20
				local flag29
				if flag28 then
					flag29 = not (tbl6.isBoatTravelBusy and tbl6.isBoatTravelBusy())
				else
					flag29 = flag28
				end
				flag29 = flag29 and not tbl6.resumeFarm and os.clock() >= n9
				if flag29 then
					flag14 = true
					fn17(function()
						local ok, result, result2 = pcall(fn14)
						if not ok then
							flag20 = false
							local flag30 = cFrame and not tbl6.pending
							result2 = "RequestFailed"
							result = false
							if flag30 then
								result, result2 = tbl6.waitForSale("RequestFailed")
							end
						end
						if result or result2 == SellEnums.Status.Empty then
							flag12 = true
							if result2 == SellEnums.Status.Empty then
								local n18 = tbl6.lastEmptyNotifyAt + 30
								if os.clock() >= n18 then
									tbl6.lastEmptyNotifyAt = os.clock()
									lib:Notify({
										Title = text("Bag Full"),
										Content = text("All fish are locked; unlock fish to make room."),
										Duration = 4,
									})
								end
							end
						else
							if not flag15 then
								fn16(result2)
							end
							n9 = os.clock() + (result2 == "ResumingFishing" and 2 or result2 == "MovementLocked" and 5 or 12)
						end
					end)
				else
					local flag30 = flag9 and not flag13 and not flag14 and not flag20
					if flag30 then
						flag30 = not (tbl6.isBoatTravelBusy and tbl6.isBoatTravelBusy())
					end
					if flag30 and not tbl6.resumeFarm then
						n11 += 1
						if n10 <= n11 then
							n11 = 0
							flag14 = true
							fn17(function()
								local ok, result, result2 = pcall(fn14)
								if not ok then
									flag20 = false
									local flag31 = cFrame and not tbl6.pending
									result2 = "RequestFailed"
									result = false
									if flag31 then
										result, result2 = tbl6.waitForSale("RequestFailed")
									end
								end
								if result or result2 == SellEnums.Status.Empty then
									flag12 = true
								end
								if not result and result2 ~= SellEnums.Status.Empty and not flag15 then
									fn16(result2)
								end
								if result2 == "ResumingFishing" then
									n11 = math.max(0, n10 - 2)
								end
							end)
						end
					end
				end
			end
		end
	end
end)
task.spawn(function()
	while flag do
		task.wait(50)
		if flag17 then
			pcall(function()
				local VirtualUser = game:GetService("VirtualUser")
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new(0, 0))
			end)
		end
	end
end)
local function fn27()
	if not flag then
		return
	end
	flag = false
	resumeSoldFish = false
	flag3 = false
	flag21 = false
	v4.Cleanup()
	if tbl11 and type(tbl11.Stop) == "function" then
		pcall(tbl11.Stop)
	end
	if tbl12 and type(tbl12.Reset) == "function" then
		pcall(tbl12.Reset)
	end
	for _, v5 in ipairs(tbl7) do
		pcall(function()
			v5:Disconnect()
		end)
	end
	table.clear(tbl7)
	local huneHubFishingMaster = genv.HuneHubFishingMaster
	if type(huneHubFishingMaster) == "table" and huneHubFishingMaster.Window then
		pcall(function()
			huneHubFishingMaster.Window:Destroy()
		end)
	end
	genv.HuneHubFishingMaster = nil
end
local str = "rbxthumb://type=Asset&id=121962960881141&w=150&h=150"
local function fn28()
	local ok, result = pcall(function()
		return lib:CreateWindow({
			Title = text("LunarX Hub | Fishing Master Free"),
			Icon = str,
			Author = "@LunarX",
			Folder = "Hune Hub",
			Size = UDim2.fromOffset(640, 460),
			MinSize = Vector2.new(560, 350),
			MaxSize = Vector2.new(850, 560),
			Transparent = true,
			Theme = "Dark",
			Resizable = true,
			SideBarWidth = 200,
			BackgroundImageTransparency = 0.42,
			HideSearchBar = true,
			ScrollBarEnabled = false,
			User = {
				Enabled = true,
				Anonymous = true,
				Callback = function()
				end,
			},
		})
	end)
	if not ok or not result then
		fn27()
		for _, v5 in ipairs({ lib.ScreenGui, lib.NotificationGui, lib.DropdownGui, lib.TooltipGui }) do
			pcall(function()
				if v5 then
					v5:Destroy()
				end
			end)
		end
		error("LunarX Hub UI could not open: " .. tostring(result), 0)
	end
	return result
end
local v5 = fn28()
v5:SetBackgroundImage("rbxthumb://type=Asset&id=121962960881141&w=150&h=150")
v5:SetToggleKey(Enum.KeyCode.RightControl)
local configManager = v5.ConfigManager
v5:Tag({ Title = text("2.0"), Icon = "code", Color = Color3.fromHex("#FFD84A"), Radius = 6 })
local function fn29(arg, arg2, arg3)
	local main = arg.UIElements and arg.UIElements.Main
	local topbar = main and main:FindFirstChild("Topbar", true)
	local left = topbar and topbar:FindFirstChild("Left")
	local center = topbar and topbar:FindFirstChild("Center")
	local right = topbar and topbar:FindFirstChild("Right")
	local holder = center and center:FindFirstChild("Holder")
	local title = left and left:FindFirstChild("Title")
	local title2 = title and title:FindFirstChild("Title")
	if not (topbar and left and center and right and holder and title2 and title2:IsA("TextLabel")) then
		warn("[LunarX Hub Free] Header tag layout unavailable.")
		return
	end
	local tbl13 = {}
	local flag25 = false
	local flag26 = false
	local flag27 = false
	local textTruncate = title2.TextTruncate
	local uiSizeConstraint = Instance.new("UISizeConstraint")
	uiSizeConstraint.Name = "LunarXFreeTitleLimit"
	uiSizeConstraint.Parent = title2
	title2.TextTruncate = Enum.TextTruncate.AtEnd
	local function fn30(arg4, arg5)
		local connection = arg4:Connect(arg5)
		tbl13[#tbl13 + 1] = connection
		if arg2 then
			arg2(connection)
		end
	end
	local function fn31()
		if flag25 then
			return
		end
		flag25 = true
		for _, v6 in ipairs(tbl13) do
			v6:Disconnect()
		end
		pcall(function()
			title2.TextTruncate = textTruncate
			uiSizeConstraint:Destroy()
		end)
	end
	local function fn32()
		if flag25 or not arg3() or not topbar.Parent or not center.Parent then
			fn31()
			return
		end
		if flag27 or topbar.AbsoluteSize.X < 1 or topbar.AbsoluteSize.Y < 1 then
			return
		end
		flag27 = true
		local ok, result = pcall(function()
			local n18 = math.max(topbar.Size.Y.Offset > 0 and topbar.AbsoluteSize.Y / topbar.Size.Y.Offset or 1, 0.01)
			local x = topbar.AbsoluteSize.X
			local n19 = 12 * n18
			local n20 = left.AbsolutePosition.X - topbar.AbsolutePosition.X
			local n21 = right.AbsolutePosition.X - topbar.AbsolutePosition.X - n19
			local n22 = 0
			local n23 = 0
			for _, child in ipairs(holder:GetChildren()) do
				if child:IsA("GuiObject") and child.Visible then
					n22 += child.AbsoluteSize.X
					n23 += 1
				end
			end
			local uiListLayout = holder:FindFirstChildWhichIsA("UIListLayout")
			local n24 = uiListLayout and uiListLayout.Padding.Offset * n18 or 7 * n18
			local vector2 = Vector2.new(math.max(60, (n21 - n20 - n19 - n22 + math.max(0, n23 - 1) * n24 + 4 * n18 - math.max(0, left.AbsoluteSize.X - title2.AbsoluteSize.X)) / n18), math.huge)
			if uiSizeConstraint.MaxSize ~= vector2 then
				uiSizeConstraint.MaxSize = vector2
			end
			local n25 = n20 + left.AbsoluteSize.X + n19
			local n26 = math.max(0, n21 - n25)
			local udim2 = UDim2.new(n25 / x, 0, 0.5, 0)
			local udim22 = UDim2.new(n26 / x, 0, 0, 26)
			if center.Position ~= udim2 then
				center.Position = udim2
			end
			if center.Size ~= udim22 then
				center.Size = udim22
			end
		end)
		flag27 = false
		if not ok then
			warn("[LunarX Hub Free] Header layout: " .. tostring(result))
		end
	end
	local function fn33()
		if flag25 or flag26 or flag27 then
			return
		end
		flag26 = true
		task.defer(function()
			flag26 = false
			fn32()
		end)
	end
	local function fn34(arg4)
		if arg4:IsA("GuiObject") then
			fn30(arg4:GetPropertyChangedSignal("AbsoluteSize"), fn33)
			fn30(arg4:GetPropertyChangedSignal("Visible"), fn33)
		end
	end
	for _, v6 in ipairs({
		{ topbar, "AbsoluteSize" },
		{ main, "Visible" },
		{ left, "AbsoluteSize" },
		{ left, "AbsolutePosition" },
		{ right, "AbsoluteSize" },
		{ right, "AbsolutePosition" },
		{ center, "Size" },
		{ center, "Position" },
		{ title2, "Text" },
	}) do
		fn30(v6[1]:GetPropertyChangedSignal(v6[2]), fn33)
	end
	for _, child in ipairs(holder:GetChildren()) do
		fn34(child)
	end
	fn30(holder.ChildAdded, function(arg4)
		fn34(arg4)
		fn33()
	end)
	fn30(holder.ChildRemoved, fn33)
	fn30(main.Destroying, fn31)
	fn33()
	return { Refresh = fn33, Stop = fn31 }
end
fn29(v5, fn2, function()
	return flag
end)
local color = Color3.fromHex
v5:EditOpenButton({
	Title = text("Hune Hub"),
	Icon = str,
	CornerRadius = UDim.new(0, 16),
	StrokeThickness = 2,
	Color = ColorSequence.new(Color3.fromHex("#7ED957"), color("#F28C28")),
	OnlyMobile = false,
	Enabled = true,
	Draggable = true,
})
genv.HuneHubFishingMaster = {
	Window = v5,
	Unload = fn27,
	Edition = "Free",
	GetFishingPosition = function()
		return cFrame3
	end,
	GetGachaStatus = tbl10.getStatus,
	TestGachaOnce = tbl10.testOnce,
	GetNameMask = v4.Get,
	SetNameMask = v4.Set,
}
MainSection = v5:Section({ Title = text("Main"), Icon = "house", Opened = true })
MiscSection = v5:Section({ Title = text("Misc & Player"), Icon = "badge-alert", Opened = true })
SettingsSection = v5:Section({ Title = text("Settings"), Icon = "settings", Opened = true })
AboutTab = MainSection:Tab({ Title = text("Info"), Icon = "info", Locked = false })
FarmTab = MainSection:Tab({ Title = text("Auto Farm"), Icon = "fish", Locked = false })
SellTab = MainSection:Tab({ Title = text("Auto Sell"), Icon = "coins", Locked = false })
TeleTab = MainSection:Tab({ Title = text("Island"), Icon = "map-pin", Locked = false })
BossTab = MainSection:Tab({ Title = text("Boss"), Icon = "swords", Locked = false })
GachaTab = MainSection:Tab({ Title = text("Gacha"), Icon = "dices", Locked = false })
ShopTab = MainSection:Tab({ Title = text("Shop"), Icon = "shopping-cart", Locked = false })
RewardTab = MainSection:Tab({ Title = text("Rewards"), Icon = "gift", Locked = false })
VisualTab = MiscSection:Tab({ Title = text("Visual"), Icon = "sparkles", Locked = false })
MiscTab = MiscSection:Tab({ Title = text("Local Player"), Icon = "user", Locked = false })
SettingsTab = SettingsSection:Tab({ Title = text("Config"), Icon = "file-cog", Locked = false })
LanguageTab = SettingsSection:Tab({ Title = text("Language"), Icon = "languages", Locked = false })
local function fn40()
	local ok, result = pcall(function()
		local request_ = syn and syn.request or http and http.request or request
		if not request_ then
			return nil
		end
		local v7 = request_({
			Url = "https://discord.com/api/v9/invites/fHdf4yXpVE?with_counts=true",
			Method = "GET",
			Timeout = 2,
		})
		if v7 and v7.StatusCode == 200 then
			return v7.Body
		end
		return nil
	end)
	if ok and result then
		local ok2, result2 = pcall(function()
			return HttpService:JSONDecode(result)
		end)
		if ok2 and result2 then
			return {
				serverName = (result2.guild or {}).name or "Hune Hub",
				members = result2.approximate_member_count or "Unknown",
				online = result2.approximate_presence_count or "Unknown",
			}
		end
	end
	return { serverName = "Hune Hub", members = "Unknown", online = "Unknown" }
end
local v7 = fn40()
AboutTab:Section({ Title = text("Information") })
AboutTab:Paragraph({
	Title = text("Discord Community"),
	Desc = text("Server: ") .. tostring(v7.serverName) .. "\nOnline: " .. tostring(v7.online) .. "\nMembers: " .. tostring(v7.members),
	Image = "users",
	ImageSize = 22,
	Buttons = {
		{
			Title = text("Join Discord"),
			Icon = "external-link",
			Callback = function()
				local ok = pcall(function()
					if not setclipboard then
						error("Clipboard is unavailable")
					end
					setclipboard("https://discord.gg/aXWW8hytgX")
				end)
				lib:Notify({
					Title = text("LunarX Hub"),
					Content = ok and "Discord invite copied!" or "Clipboard is not supported by this executor.",
					Duration = 3,
				})
			end,
		},
	},
})
AboutTab:Paragraph({
	Title = text("Owner"),
	Desc = text("Discord: LunarX"),
	Image = "crown",
	ImageSize = 24,
	Buttons = {
		{
			Title = text("Copy Owner ID"),
			Icon = "copy",
			Callback = function()
				pcall(function()
					if setclipboard then
						setclipboard("920035051033485353")
					end
				end)
			end,
		},
	},
})
FarmTab:Section({ Title = text("Main Features") })
FarmToggle = FarmTab:Toggle({
	Title = text("Auto Farm"),
	Default = false,
	Flag = "AutoFarm",
	Callback = function(arg)
		resumeSoldFish = arg
		flag2 = arg
		flag3 = arg
		flag4 = arg
		flag5 = arg
		n15 += 1
		flag23 = false
		n16 += 1
		flag24 = false
		if arg then
			local v10 = fn6()
			tbl6.farmSpotPending = true
			if v10 and not flag20 and not flag14 and not flag15 and not tbl6.pending then
				cFrame3 = v10.CFrame
				if flag19 then
					cFrame2 = cFrame3
				end
				tbl6.farmSpotPending = false
			end
			fn8()
			n17 = 0
			v3 = nil
			idling = fn7() or FishingEnums.State.Idling
			if idling == FishingEnums.State.Caught then
				fn26()
			end
			lib:Notify({
				Title = text("Auto Farm Enabled"),
				Content = tbl6.farmSpotPending and "The fishing position will be saved when movement finishes." or "The current fishing position and facing direction were saved.",
				Duration = 3,
			})
		else
			tbl6.farmSpotPending = false
			if tbl6.resumeTarget and not tbl6.pending then
				cFrame = nil
			end
			tbl6.resumeFarm = false
			tbl6.resumeTarget = nil
			tbl6.resumeCharacter = nil
			tbl6.resumeCastAt = 0
			tbl6.resumeSoldFish = false
			tbl6.rodId = nil
			tbl8.skipPending = false
			flag21 = false
			n14 += 1
			flag22 = false
			n3 += 1
			flag7 = false
			idling = fn7() or FishingEnums.State.Idling
			lib:Notify({
				Title = text("Auto Farm Disabled"),
				Content = text("The complete fishing cycle has stopped."),
				Duration = 2,
			})
		end
	end,
})
FarmTab:Toggle({
	Title = text("Auto Skill + Low HP"),
	Default = false,
	Flag = "AutoSkill",
	Callback = function(arg)
		flag6 = arg
		if arg and flag21 then
			fn22()
		end
	end,
})
FarmTab:Toggle({
	Title = text("Auto Spam Skill"),
	Default = false,
	Flag = "AutoSpamSkill",
	Callback = function(spamEnabled)
		tbl5.spamEnabled = spamEnabled
		tbl5.spamNextIndex = 1
		if spamEnabled and flag21 then
			fn22()
		end
	end,
})
FarmTab:Input({
	Title = text("Skill Combo (Z,X,C,V)"),
	Default = tbl5.defaultOrder,
	Placeholder = "Z,X,C,V",
	Flag = "SkillComboOrder",
	Callback = function(arg)
		if tbl5.setOrder(arg) then
			tbl5.saveOrderSoon(arg)
		end
	end,
})
FarmTab:Section({ Title = text("Fish Rarity Filter") })
FarmTab:Dropdown({
	Title = text("Target Rarities"),
	Values = RarityEnums.Order,
	Value = { "Legendary", "Mythical", "Divine" },
	Multi = true,
	AllowNone = true,
	Flag = "FarmTargetRarities",
	Callback = function(arg)
		tbl8:setSelected(tbl8.farmRarities, arg)
		local v10 = fn7()
		if v10 == FishingEnums.State.FirstPull or v10 == FishingEnums.State.Reeling then
			tbl8:allowsCurrent()
		end
	end,
})
FarmTab:Toggle({
	Title = text("Filter Fish by Rarity"),
	Default = false,
	Flag = "SkipUnselectedFish",
	Callback = function(farmEnabled)
		tbl8.farmEnabled = farmEnabled
		if farmEnabled then
			local v10 = fn7()
			if v10 == FishingEnums.State.FirstPull or v10 == FishingEnums.State.Reeling then
				tbl8:allowsCurrent()
			end
		else
			tbl8.skipPending = false
		end
	end,
})
FarmTab:Section({ Title = text("Speed Settings") })
FarmTab:Slider({
	Title = text("Farm Delay (Seconds)"),
	Value = { Min = 0.1, Max = 2, Default = 0.35 },
	Step = 0.01,
	Flag = "FarmDelay",
	Callback = function(arg)
		n = arg
	end,
})
FarmTab:Section({ Title = text("Position Settings") })
FarmTab:Toggle({
	Title = text("Stop Farm If Moved"),
	Default = false,
	Flag = "LockPosition",
	Callback = function(arg)
		flag19 = arg
		if arg then
			local v10 = fn6()
			if v10 then
				cFrame2 = v10.CFrame
				lib:Notify({
					Title = text("Fishing Area Saved"),
					Content = text("Auto Farm will stop if you move more than 8 studs away."),
					Duration = 3,
				})
			end
		else
			cFrame2 = nil
		end
	end,
})
FarmTab:Button({
	Title = text("Save Fishing Position"),
	Callback = function()
		if flag14 or flag20 or flag15 or tbl6.pending then
			lib:Notify({
				Title = text("Position Not Saved"),
				Content = text("Wait for the current movement to finish."),
				Duration = 3,
			})
			return
		end
		local v10 = fn6()
		if v10 then
			cFrame3 = v10.CFrame
			cFrame2 = cFrame3
			tbl6.farmSpotPending = false
			lib:Notify({
				Title = text("Position Saved"),
				Content = text("The current fishing position has been saved."),
				Duration = 2,
			})
		else
			lib:Notify({
				Title = text("Position Not Saved"),
				Content = text("Character position is not ready yet."),
				Duration = 3,
			})
		end
	end,
})
FarmTab:Button({
	Title = text("Return To Fishing Position"),
	Callback = function()
		if cFrame3 then
			if flag20 or flag14 or tbl6.pending or flag15 then
				return
			end
			task.spawn(function()
				flag20 = true
				fn13()
				local v10, v11 = tbl6.moveTo(cFrame3, true)
				flag20 = false
				lib:Notify({
					Title = v10 and text("Position Reached") or text("Safe Route Unavailable"),
					Content = v10 and text("Returned to the saved fishing position.") or tostring(v11),
					Duration = 3,
				})
			end)
		else
			lib:Notify({
				Title = text("No Saved Position"),
				Content = text("Save a fishing position first."),
				Duration = 3,
			})
		end
	end,
})
SellTab:Section({ Title = text("Automatic Fish Selling") })
SellTab:Dropdown({
	Title = text("Sell Travel Method"),
	Values = { "Walk", "Tween" },
	Default = "Walk",
	Multi = false,
	Flag = "SellTravelMethodV2",
	Callback = function(method)
		if method ~= "Walk" and method ~= "Tween" then
			method = "Walk"
		end
		tbl6.method = method
		flag13 = false
		n9 = 0
		if tbl6.pending then
			tbl6.attempts = 0
			tbl6.retryAt = 0
		end
	end,
})
SellTab:Slider({
	Title = text("Sell Tween Speed (Studs/Second)"),
	Value = { Min = 20, Max = 70, Default = 30 },
	Step = 1,
	Flag = "SellTweenSpeed",
	Callback = function(arg)
		local num = tonumber(arg)
		if num then
			tbl6.tweenSpeed = math.clamp(num, 20, 70)
		end
	end,
})
SellTab:Toggle({
	Title = text("Walk On Water"),
	Default = true,
	Flag = "SellWalkOnWater",
	Callback = function(waterWalkEnabled)
		tbl6.waterWalkEnabled = waterWalkEnabled
		if waterWalkEnabled and tbl6.active then
			tbl11.Start()
		elseif not waterWalkEnabled and not tbl11.UserEnabled then
			tbl11.StopPlatformOnly()
		end
	end,
})
SellTab:Slider({
	Title = text("Sell Wait Delay (Seconds)"),
	Value = { Min = 0, Max = 10, Default = 3 },
	Step = 0.5,
	Flag = "SellWaitDelay",
	Callback = function(arg)
		local num = tonumber(arg)
		if num then
			tbl6.waitDelay = math.clamp(num, 0, 10)
		end
	end,
})
SellTab:Section({ Title = text("Auto Lock Fish by Rarity") })
SellTab:Dropdown({
	Title = text("Rarities to Lock"),
	Values = RarityEnums.Order,
	Value = { "Legendary", "Mythical", "Divine" },
	Multi = true,
	AllowNone = true,
	Flag = "SellKeepRarities",
	Callback = function(arg)
		tbl8:setSelected(tbl8.sellRarities, arg)
		tbl8:queueLocks()
	end,
})
SellTab:Toggle({
	Title = text("Auto Lock Fish"),
	Default = false,
	Flag = "AutoLockProtectedFish",
	Callback = function(sellEnabled)
		tbl8.sellEnabled = sellEnabled
		tbl8:queueLocks()
	end,
})
SellTab:Toggle({
	Title = text("Auto Sell When Bag Full"),
	Default = false,
	Flag = "AutoSellWhenBagFull",
	Callback = function(arg)
		flag10 = arg
		flag13 = false
		flag11 = false
		flag12 = false
		n9 = 0
		if not arg and not flag9 and not flag14 and not tbl6.pending and not flag15 then
			flag15 = false
			cFrame = nil
		end
	end,
})
SellTab:Toggle({
	Title = text("Auto Sell On Timer"),
	Default = false,
	Flag = "AutoSellOnTimer",
	Callback = function(arg)
		flag9 = arg
		flag13 = false
		n11 = 0
		if not arg and not flag10 and not flag14 and not tbl6.pending and not flag15 then
			flag15 = false
			cFrame = nil
		end
	end,
})
SellTab:Slider({
	Title = text("Sell Interval (Seconds)"),
	Value = { Min = 15, Max = 300, Default = 60 },
	Step = 1,
	Flag = "SellInterval",
	Callback = function(arg)
		local num = tonumber(arg)
		if num then
			n10 = math.clamp(num, 15, 300)
		end
	end,
})
SellTab:Button({
	Title = text("Sell All Fish Now"),
	Callback = function()
		if flag14 then
			lib:Notify({
				Title = text("Sell In Progress"),
				Content = text("The current merchant sale is still running."),
				Duration = 3,
			})
			return
		end
		if tbl6.resumeFarm then
			fn16("ResumingFishing", true)
			return
		end
		flag14 = true
		lib:Notify({ Title = text("Selling Fish"), Content = text("Moving to the nearest Fish Merchant."), Duration = 2 })
		fn17(function()
			local ok, result, result2 = pcall(fn14, true)
			if not ok then
				flag20 = false
				local flag27 = cFrame and not tbl6.pending
				result2 = "RequestFailed"
				result = false
				if flag27 then
					result, result2 = tbl6.waitForSale("RequestFailed")
				end
			end
			if result2 == "ReturnCompleted" then
				lib:Notify({
					Title = text("Fishing Position Restored"),
					Content = text("Returned to the saved fishing spot."),
					Duration = 3,
				})
			elseif not result then
				if flag15 then
					lib:Notify({
						Title = text("Sell Pending"),
						Content = text("The sale has not been confirmed. The script will retry."),
						Duration = 4,
					})
				else
					fn16(result2, true)
				end
			end
		end)
	end,
})
local function fn41()
	local str4 = tbl3["Starter Island"] and "Starter Island" or tbl4[1]
	local function fn42(arg, arg2)
		local v10 = IslandConfig[arg.id]
		return arg.defaultUnlocked or v10 and v10.defaultUnlocked == true or arg2 and arg2.UnlockedIslands and arg2.UnlockedIslands[arg.id] == true
	end
	local tbl16 = {
		island_starter = Vector3.new(-111.63, 12.05, 328.32),
		island_jungle = Vector3.new(-1208.78, 10.11, -132.93),
		island_desert = Vector3.new(-24.45, 9.77, -1066.15),
		island_snow = Vector3.new(1240.44, 9.72, -309.4),
		island_volcano = Vector3.new(1874.55, 13.12, 1063.6),
		island_fossil = Vector3.new(-574.39, 13.87, 2296.03),
	}
	local function getIslandLandingPosition(arg)
		local v10 = tbl3[arg]
		return v10 and tbl16[v10.id] or nil
	end
	tbl6.getIslandLandingPosition = getIslandLandingPosition
	local function fn43()
		return function(arg)
			local player = arg.Player
			game:GetService("Players")
			local tbl17 = { DriverVersion = "2.3.15", phase = "Ready", settings = { boatId = "truck", playerMode = false } }
			local obj = setmetatable({}, { __index = function(arg2, arg3)
				local ok, result = pcall(function()
					return arg.Client.GetController(arg3)
				end)
				if ok and result then
					return result
				end
				if type(getrenv) == "function" then
					return (getrenv().shared or {})[arg3]
				end
			end })
			local function fn44()
				return arg.GetPlayerData()
			end
			local function fn45(...)
				local ReplicatedStorage2 = game:GetService("ReplicatedStorage")
				for _, v10 in { ... }, nil, nil do
					ReplicatedStorage2 = ReplicatedStorage2:FindFirstChild(v10) or error("Module Missing: " .. v10)
				end
				return require(ReplicatedStorage2)
			end
			local function fn46()
				return arg.GetCurrentIslandId() or ""
			end
			local function fn47(arg2)
				local v10 = arg.ResolveIsland(arg2)
				return v10 and arg.IsUnlocked(v10, fn44())
			end
			local tbl18 = {
				Enum.HumanoidStateType.Freefall,
				Enum.HumanoidStateType.FallingDown,
				Enum.HumanoidStateType.Ragdoll,
			}
			local v10 = nil
			local function fn48()
				local character = player.Character
				local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if humanoidRootPart and humanoid and humanoid.Health > 0 and humanoidRootPart:IsA("BasePart") then
					return character, humanoidRootPart, humanoid
				end
				return nil
			end
			local function fn49(arg2, cFrame4)
				arg2.CFrame = cFrame4
				arg2.AssemblyLinearVelocity = Vector3.zero
				arg2.AssemblyAngularVelocity = Vector3.zero
			end
			local function fn50(arg2)
				if arg2.ca then
					arg2.ca:Disconnect()
					arg2.cr:Disconnect()
				end
				for k, v11 in arg2.cc, nil, nil do
					pcall(function()
						k.CanCollide = v11
					end)
				end
				for k, v11 in arg2.ss, nil, nil do
					pcall(function()
						arg2.h:SetStateEnabled(k, v11)
					end)
				end
				arg2.c = nil
				arg2.h = nil
				arg2.ca = nil
				arg2.cr = nil
				arg2.cc = {}
				arg2.ss = {}
				arg2.pl = {}
			end
			local function fn51(arg2, c, h)
				fn50(arg2)
				arg2.c = c
				arg2.h = h
				arg2.pd = true
				for _, v11 in tbl18, nil, nil do
					arg2.ss[v11] = h:GetStateEnabled(v11)
					h:SetStateEnabled(v11, false)
				end
				arg2.ca = c.DescendantAdded:Connect(function()
					arg2.pd = true
				end)
				arg2.cr = c.DescendantRemoving:Connect(function()
					arg2.pd = true
				end)
			end
			local function fn52(arg2)
				local v11, v12, v13 = fn48()
				if not v11 then
					return
				end
				if v11 ~= arg2.c then
					fn51(arg2, v11, v13)
				end
				if arg2.pd then
					arg2.pd = false
					arg2.pl = {}
					for _, v14 in v11:GetDescendants() do
						if v14:IsA("BasePart") then
							if arg2.cc[v14] == nil then
								arg2.cc[v14] = v14.CanCollide
							end
							table.insert(arg2.pl, v14)
						end
					end
				end
				for _, v14 in arg2.pl, nil, nil do
					if v14.CanCollide then
						v14.CanCollide = false
					end
				end
				if v13.Sit or v13.SeatPart then
					v13.Sit = false
				end
			end
			local function fn53(arg2, arg3)
				local v11, v12, v13 = fn48()
				if not v11 then
					if arg2.c then
						fn50(arg2)
					end
					arg2.st = "Respawn"
					return
				end
				if v11 ~= arg2.c then
					fn51(arg2, v11, v13)
				end
				local n19 = arg2.p - v12.Position
				local flag27 = n19.Magnitude <= arg2.s * arg3
				local vector = Vector3.new(n19.X, 0, n19.Z)
				arg2.lk = flag27 and arg2.fk or vector.Magnitude > 0.001 and vector.Unit or arg2.lk
				arg2.st = flag27 and "Arrived" or "Moving"
				fn49(v12, CFrame.lookAlong(flag27 and arg2.p or v12.Position + n19.Unit * arg2.s * arg3, arg2.lk))
			end
			local function fn54(arg2, st, why)
				if arg2.dn then
					return
				end
				arg2.dn = true
				arg2.cs:Disconnect()
				arg2.ch:Disconnect()
				pcall(fn50, arg2)
				pcall(function()
					local v11
					v11, v11 = fn48()
					if v11 then
						v11.AssemblyLinearVelocity = Vector3.zero
						v11.AssemblyAngularVelocity = Vector3.zero
					end
				end)
				arg2.st = st
				arg2.why = why
				if v10 == arg2 then
					v10 = nil
				end
			end
			local function fn55(arg2, arg3, fk)
				if typeof(arg2) ~= "Vector3" or arg2.Magnitude ~= arg2.Magnitude or arg2.Magnitude == math.huge then
					return nil, "Move Failed: Bad Point"
				end
				if v10 then
					v10:Stop()
				end
				local v11, v12, v13 = fn48()
				local tbl19 = { st = "Moving", p = arg2, s = arg3, cc = {}, ss = {}, pl = {} }
				tbl19.lk = v12 and Vector3.new(v12.CFrame.LookVector.X, 0, v12.CFrame.LookVector.Z).Unit or -Vector3.new(0, 0, 1)
				tbl19.fk = fk or tbl19.lk
				tbl19.Stop = function(arg4)
					fn54(arg4 or tbl19, "Stopped")
				end
				if v11 then
					fn51(tbl19, v11, v13)
				end
				local RunService = game:GetService("RunService")
				tbl19.cs = RunService.Stepped:Connect(function()
					local ok, result = pcall(fn52, tbl19)
					if not ok then
						local v14 = fn54
						local str5 = ("Move Failed: %*"):format(result)
						v14(tbl19, "Failed", str5)
					end
				end)
				tbl19.ch = RunService.Heartbeat:Connect(function(deltaTime)
					local ok, result = pcall(fn53, tbl19, deltaTime)
					if not ok then
						local v14 = fn54
						local str5 = ("Move Failed: %*"):format(result)
						v14(tbl19, "Failed", str5)
					end
				end)
				v10 = tbl19
				return tbl19
			end
			local tbl19 = { on = false }
			local function fn56(arg2, arg3, arg4)
				for i = 1, 4 do
					local v11
					v11, v11 = fn48()
					if not v11 then
						return nil, "No Character"
					end
					local n19 = arg3 - v11.Position
					if n19.Magnitude <= 0.65 then
						return true
					end
					if arg2.st ~= "Running" then
						return nil, "Cancelled"
					end
					local v12, v13 = fn55(arg3, 30, arg4)
					if not v12 then
						return nil, v13
					end
					local n20 = n19.Magnitude / 30
					local n21 = os.clock() + n20 + 5
					while true do
						task.wait()
						if not (v12.st == "Arrived" or v12.dn or arg2.st ~= "Running" or os.clock() > n21) then
							continue
						end
						break
					end
					local why = v12.why
					v12:Stop()
					if why then
						return nil, why
					end
					if arg2.st ~= "Running" then
						return nil
					end
					task.wait(0.5)
				end
				return nil, "Move Timeout"
			end
			game:GetService("HttpService")
			local tbl20 = { j = false, active = true }
			task.spawn(function()
				local VirtualInputManager = game:GetService("VirtualInputManager")
				while tbl20.active and (not arg.ShouldContinue or arg.ShouldContinue()) do
					if tbl20.j then
						tbl20.j = false
						pcall(function()
							VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
							task.wait(0.15)
							VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
						end)
					end
					task.wait()
				end
			end)
			local tbl21 = nil
			local function fn57()
				local v11 = pairs
				local v12 = tbl21
				local tbl22
				if tbl21 then
					tbl22 = v12
				else
					tbl22 = {}
				end
				for k, v13 in v11(tbl22) do
					pcall(function()
						k.Disabled = v13
					end)
				end
				tbl21 = nil
			end
			local function fn58(arg2)
				fn57()
				tbl21 = {}
				for _, v11 in arg2:GetDescendants() do
					if v11:IsA("Seat") or v11:IsA("VehicleSeat") then
						tbl21[v11] = v11.Disabled
						v11.Disabled = true
					end
				end
			end
			local function stopHold()
				if v10 then
					v10:Stop()
				end
				fn57()
			end
			local tbl22 = {
				island_starter = Vector3.new(-37.4, 11.1, 305.9),
				island_jungle = Vector3.new(-1161.1, 10.8, -61.9),
				island_desert = Vector3.new(-44.1, 10.1, -935.4),
				island_snow = Vector3.new(1171.7, 9.4, -266.5),
				island_volcano = Vector3.new(1772.5, 9.2, 1069.3),
				island_fossil = Vector3.new(-543.2, 10.6, 2172.3),
			}
			local function fn59(arg2)
				for _, v11 in game:GetService("CollectionService"):GetTagged("Interactive") do
					if v11:GetAttribute("InteractiveId") == "npc_car_merchant" and v11:GetAttribute("IslandId") == arg2 then
						return v11:IsA("Model") and v11:GetPivot().Position or v11:IsA("BasePart") and v11.Position or tbl22[arg2]
					end
				end
				return tbl22[arg2]
			end
			local function fn60()
				return function(arg2)
					local v11 = nil
					local v12 = nil
					local connection = nil
					local v13 = nil
					local n19 = 0
					local n20 = 0
					local flag27 = false
					local flag28 = false
					local tbl23 = {}
					local str5 = nil
					local str6 = nil
					local v14 = nil
					local str7 = nil
					local flag29 = false
					local tbl24 = {
						"Tips: Cast your bobber near ripple spots to catch rare fish!",
						"Tips: Different rods provide unique luck and strength boosts.",
						"Tips: Keep an eye on the tension bar to avoid snapping your line!",
						"Tips: Upgrade your bait at the bait shop to attract bigger fish.",
						"Tips: Perfect catches grant extra experience and rare materials.",
						"Tips: Check the weather! Some mythical fish only appear in storms.",
						"Tips: Visit the fish merchant to convert your catches into Coins & Gems.",
						"Tips: Explore distant islands once you discover their fast travel points.",
						"Tips: Rare auras and rod skins can be equipped to show off your style.",
						"Tips: Complete daily quests for bonus rewards and crates.",
						"Tips: Fill out your fish Index to track every species you've caught!",
					}
					local function fn61()
						if connection then
							connection:Disconnect()
							connection = nil
						end
						for _, v15 in tbl23, nil, nil do
							pcall(function()
								v15:Cancel()
							end)
						end
						table.clear(tbl23)
					end
					local function fn62()
						local ok, result = pcall(function()
							local StarterGui = game:GetService("StarterGui")
							local coreGuiEnabled = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Health)
							if v14 == nil then
								v14 = coreGuiEnabled
							end
							if coreGuiEnabled then
								StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
							end
							flag29 = true
						end)
						str7 = not ok and tostring(result) or nil
					end
					local function fn63()
						if v14 == nil then
							return
						end
						local ok, result = pcall(function()
							game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Health, v14)
						end)
						if ok then
							v14 = nil
							flag29 = false
							str7 = nil
						else
							str7 = tostring(result)
						end
					end
					local tbl25 = { Abort = function(arg3)
						if arg3 and v13 ~= arg3 then
							return
						end
						n19 += 1
						fn61()
						if v11 then
							pcall(function()
								v11.Enabled = false
							end)
						end
						fn63()
						flag27 = false
						v13 = nil
					end }
					local function fn64()
						local screenGui = Instance.new("ScreenGui")
						local frame = Instance.new("Frame")
						local udim2 = UDim2.fromScale(1, 1)
						local color2 = Color3.fromRGB(12, 18, 25)
						frame.Name = "Frame"
						frame.Size = udim2
						frame.BackgroundColor3 = color2
						frame.BorderSizePixel = 0
						frame.Parent = screenGui
						local textLabel = Instance.new("TextLabel")
						local udim22 = UDim2.fromScale(0.8, 0.1)
						local udim23 = UDim2.fromScale(0.1, 0.45)
						textLabel.Name = "MasteryText"
						textLabel.Size = udim22
						textLabel.Position = udim23
						local color3 = Color3.fromRGB(255, 255, 255)
						local gothamMedium = Enum.Font.GothamMedium
						textLabel.BackgroundTransparency = 1
						textLabel.TextColor3 = color3
						textLabel.TextSize = 24
						textLabel.Font = gothamMedium
						textLabel.Parent = frame
						local frame2 = Instance.new("Frame")
						local udim24 = UDim2.fromScale(0.6, 0.015)
						local udim25 = UDim2.fromScale(0.2, 0.57)
						frame2.Name = "Bar"
						frame2.Size = udim24
						frame2.Position = udim25
						frame2.BorderSizePixel = 0
						frame2.BackgroundColor3 = Color3.fromRGB(35, 44, 53)
						frame2.Parent = frame
						local frame3 = Instance.new("Frame")
						local udim26 = UDim2.fromScale(0, 1)
						frame3.Name = "Fill"
						frame3.Size = udim26
						frame3.BorderSizePixel = 0
						frame3.BackgroundColor3 = Color3.fromRGB(255, 213, 55)
						frame3.Parent = frame2
						return screenGui, { frame = frame, bar = frame2, fill = frame3, text = textLabel }
					end
					local function fn65()
						if flag28 then
							return false
						end
						if v11 and v11.Parent then
							return true
						end
						local playerGui = arg2.Player:FindFirstChildOfClass("PlayerGui")
						if not playerGui then
							return false
						end
						local clone = nil
						local ok, result = pcall(function()
							local loading = playerGui:FindFirstChild("Loading")
							assert(loading and loading:IsA("ScreenGui"), "Loading template unavailable")
							clone = loading:Clone()
							local frame = clone.Frame
							local v15 = arg2.GetLoadingController()
							return {
								frame = frame,
								bar = frame.Bar,
								fill = frame.Bar.Fill,
								text = frame.Bar.MasteryText,
								fish = frame.Bar.Fish,
								shine = frame.Bar.Shine,
								tips = frame.tips,
								gradient = frame.Background.Gradient,
								rectangle = frame.Background.Rectangle,
								image = frame.ImageLabel,
								barPos = v15 and v15._originalBarPos or UDim2.fromScale(0.5, 0.93),
								tipsPos = v15 and v15._originalTipsPos or UDim2.fromScale(0.5, 0.85),
							}
						end)
						if ok then
							v12 = result
							str5 = "LoadingClone"
						else
							if clone then
								clone:Destroy()
							end
							str6 = tostring(result)
							local v15
							clone, v15 = fn64()
							v12 = v15
							str5 = "Fallback"
						end
						clone.Name = "HuneIslandLoading"
						clone.Enabled = false
						clone.ResetOnSpawn = false
						clone.IgnoreGuiInset = true
						clone.DisplayOrder = 2147483599
						local frame = v12.frame
						v12.frame.Visible = true
						frame.Active = true
						clone.Parent = playerGui
						v11 = clone
						return true
					end
					local function fn66(arg3)
						return not flag28 and flag27 and n19 == arg3 and v11 and v11.Parent ~= nil
					end
					local function fn67(arg3, arg4, arg5, arg6, arg7, arg8, arg9)
						local tween = game:GetService("TweenService"):Create(arg3, TweenInfo.new(arg4, arg5, arg6, arg8 or 0, arg9 or false), arg7)
						table.insert(tbl23, tween)
						tween:Play()
					end
					tbl25.Show = function(arg3)
						if flag28 then
							return false
						end
						tbl25.Abort()
						local ok, result = pcall(function()
							if not fn65() then
								return false
							end
							v13 = arg3
							flag27 = true
							n20 = 0
							local v15 = n19
							local v16 = v12
							local n21 = 0
							local frame = v16.frame
							local fill = v16.fill
							local text2 = v16.text
							local text3 = v16.text
							local udim2 = UDim2.fromScale(0, 1)
							frame.BackgroundTransparency = 0
							fill.Size = udim2
							text2.Text = "Loading game..."
							text3.TextTransparency = 0
							v11.Enabled = true
							fn62()
							if str5 == "LoadingClone" then
								local rectangle = v16.rectangle
								local image = v16.image
								v16.gradient.ImageTransparency = 0
								rectangle.BackgroundTransparency = 0
								image.ImageTransparency = 0
								v16.bar.Position = UDim2.new(v16.barPos.X.Scale, v16.barPos.X.Offset, 1.25, 0)
								v16.tips.Position = UDim2.new(v16.tipsPos.X.Scale, v16.tipsPos.X.Offset, 1.35, 0)
								fn67(v16.shine, 1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, { ImageTransparency = 0.25 }, -1, true)
								fn67(v16.bar, 0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Position = v16.barPos })
								task.delay(0.08, function()
									if fn66(v15) then
										fn67(v16.tips, 0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Position = v16.tipsPos })
									end
								end)
								local n22 = math.random(1, #tbl24)
								v16.tips.Text = tbl24[n22]
								task.spawn(function()
									while fn66(v15) do
										task.wait(2.5)
										if not fn66(v15) then
											return
										end
										fn67(v16.tips, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, {
											Position = UDim2.new(v16.tipsPos.X.Scale, v16.tipsPos.X.Offset, v16.tipsPos.Y.Scale - 0.035, v16.tipsPos.Y.Offset),
										})
										task.wait(0.5)
										if not fn66(v15) then
											return
										end
										n22 = n22 % #tbl24 + 1
										v16.tips.Text = tbl24[n22]
										v16.tips.Position = UDim2.new(v16.tipsPos.X.Scale, v16.tipsPos.X.Offset, v16.tipsPos.Y.Scale + 0.035, v16.tipsPos.Y.Offset)
										fn67(v16.tips, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Position = v16.tipsPos })
									end
								end)
							end
							connection = game:GetService("RunService").RenderStepped:Connect(function(deltaTime)
								if flag28 or not flag27 then
									return
								end
								if not v11 or not v11.Parent then
									tbl25.Abort(arg3)
									return
								end
								fn62()
								local ok, result = pcall(function()
									if n20 > n21 then
										n21 = math.min(n21 + math.max((n20 - n21) * math.clamp(deltaTime * 10, 0, 1), 0.0005), n20)
									end
									v16.fill.Size = UDim2.fromScale(n21, 1)
									if v16.fish then
										v16.fish.Position = UDim2.new(n21, 0, 0.5, math.sin(os.clock() * 10) * 3)
										v16.fish.Rotation = math.sin(os.clock() * 12) * 10
									end
								end)
								if not ok then
									str6 = tostring(result)
									tbl25.Abort(arg3)
								end
							end)
							task.spawn(function()
								for k, v17 in { "Starting up...", "Building interface...", "Loading your data...", "Preparing gameplay..." }, nil, nil do
									task.wait(1)
									if not fn66(v15) then
										return
									end
									local text4 = v16.text
									n20 = math.max(n20, k * 0.22)
									text4.Text = v17
								end
							end)
							return true
						end)
						if not ok then
							str6 = tostring(result)
							tbl25.Abort(arg3)
						end
						return ok and result == true
					end
					tbl25.Update = function(text2, arg3, arg4)
						if not flag27 or v13 ~= arg4 then
							return
						end
						if text2 then
							v12.text.Text = text2
						end
						if arg3 then
							n20 = math.max(n20, math.clamp(arg3, 0, 0.95))
						end
					end
					tbl25.Finish = function(arg3, arg4)
						if not flag27 or v13 ~= arg4 then
							return
						end
						n19 += 1
						local v15 = n19
						local v16 = v12
						if arg3 then
							n20 = 1
						end
						v16.text.Text = arg3 and "Ready!" or "Teleport Failed"
						task.spawn(function()
							task.wait(arg3 and 0.4 or 1)
							if not fn66(v15) then
								return
							end
							local ok, result = pcall(function()
								if str5 == "LoadingClone" then
									fn67(v16.tips, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In, { Position = UDim2.new(v16.tipsPos.X.Scale, v16.tipsPos.X.Offset, 1.35, 0) })
									fn67(v16.bar, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In, { Position = UDim2.new(v16.barPos.X.Scale, v16.barPos.X.Offset, 1.25, 0) })
									fn67(v16.gradient, 1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { ImageTransparency = 1 })
									fn67(v16.rectangle, 1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = 1 })
									fn67(v16.image, 1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { ImageTransparency = 1 })
								else
									fn67(v16.text, 1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { TextTransparency = 1 })
								end
								fn67(v16.frame, 1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = 1 })
							end)
							if not ok then
								str6 = tostring(result)
								tbl25.Abort(arg4)
								return
							end
							task.wait(1.5)
							if fn66(v15) then
								tbl25.Abort(arg4)
							end
						end)
					end
					tbl25.GetStatus = function()
						return {
							visible = flag27,
							mode = str5,
							progress = n20,
							disposed = flag28,
							lastError = str6,
							connected = connection ~= nil,
							enabled = v11 and v11.Enabled or false,
							healthHidden = flag29,
							healthError = str7,
						}
					end
					tbl25.Shutdown = function()
						tbl25.Abort()
						flag28 = true
						if v11 then
							v11:Destroy()
							v11 = nil
						end
					end
					return tbl25
				end
			end
			local v11 = fn60()({
				Player = player,
				GetLoadingController = function()
					return obj.LoadingController
				end,
			})
			local function fn61(arg2, step)
				arg2.teleport.step = step
				tbl17.phase = step
				tbl17.lastTeleport = arg2.teleport
			end
			local function fn62(arg2)
				if arg2.st ~= "Running" then
					return false
				end
				if arg.ShouldContinue and not arg.ShouldContinue() then
					arg2.st = "Stopped"
					arg2.why = "Shutdown"
					return false
				end
				if arg2.guard and not arg2.guard() then
					arg2.st = "Stopped"
					arg2.why = "Cancelled"
					return false
				end
				local deadline = arg2.deadline
				if deadline then
					local deadline2 = arg2.deadline
					deadline = os.clock() > deadline2
				end
				if deadline then
					arg2.st = "Stopped"
					arg2.why = "TravelTimeout"
					return false
				end
				return true
			end
			local function fn63(arg2, arg3, arg4, arg5, arg6)
				stopHold()
				local v12 = nil
				fn61(arg2, "Respawning")
				arg2.respawning = true
				local connection = player.CharacterAdded:Connect(function(character)
					v12 = character
					arg2.character = character
					if arg.OnCharacter then
						arg.OnCharacter(character)
					end
				end)
				arg2.respawnConnection = connection
				pcall(function()
					arg5.Parent.HumanoidRootPart.Died.Volume = 0
				end)
				arg5.Health = 0
				local n19 = os.clock() + 10
				while true do
					task.wait(0.1)
					if not (v12 or os.clock() > n19 or arg2.st ~= "Running") then
						continue
					end
					break
				end
				connection:Disconnect()
				arg2.respawnConnection = nil
				local humanoidRootPart = v12 and v12:WaitForChild("HumanoidRootPart", 5)
				if not humanoidRootPart then
					return nil, arg2.st == "Running" and "Warp Failed: No Respawn" or nil
				end
				arg2.respawning = false
				if arg2.st ~= "Running" then
					return nil, "Cancelled"
				end
				fn61(arg2, "SettingSpawn")
				local Shared = fn45("Shared", "Lib", "SpawnPointDialogue")
				local cframe = CFrame.new(arg4 + Vector3.new(4, 3, 0))
				local flag27 = false
				arg6.hb = game:GetService("RunService").Heartbeat:Connect(function()
					if humanoidRootPart.Parent then
						local v13 = humanoidRootPart
						local v14 = cframe
						humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
						v13.CFrame = v14
					end
				end)
				arg2.pinConnection = arg6.hb
				local n20 = os.clock() + 4.5
				while not flag27 and os.clock() < n20 and arg2.st == "Running" do
					local tbl23 = {}
					local flag28 = false
					task.spawn(function()
						if arg2.st ~= "Running" then
							return
						end
						Shared.CreateAction(true, tbl23, tbl23).on_select(function(arg7)
							flag27 = arg7 == true
							flag28 = true
						end)
					end)
					local n21 = os.clock() + 3
					while true do
						task.wait()
						if not (flag28 or os.clock() > n21 or arg2.st ~= "Running") then
							continue
						end
						break
					end
					if not flag27 then
						task.wait(0.1)
					end
				end
				arg6.hb:Disconnect()
				arg2.pinConnection = nil
				if arg2.st ~= "Running" then
					return nil
				end
				if not flag27 then
					return nil, "Warp Failed: Spawn Not Set"
				end
				fn61(arg2, "Teleporting")
				local Controllers = fn45("Controllers", "BackpackController")
				local flag28 = false
				for i = 1, 10 do
					task.wait(1)
					if arg2.st ~= "Running" then
						return nil
					end
					local ok, result = pcall(function()
						return Controllers.TeleportToSpawn:Fire()
					end)
					flag28 = ok and result == true
					if flag28 then
						break
					end
				end
				if not flag28 then
					return nil, "Warp Failed: Respawn Refused"
				end
				fn61(arg2, "CheckingArrival")
				local n21 = os.clock() + 8
				while true do
					task.wait(0.2)
					if not (fn46() == arg3 and fn48() or os.clock() > n21 or arg2.st ~= "Running") then
						continue
					end
					break
				end
				if arg2.st ~= "Running" then
					return nil, "Cancelled"
				end
				if fn46() ~= arg3 then
					return nil, "Warp Failed: Not On Island"
				end
				return true
			end
			local function fn64(arg2, arg3)
				if not fn47(arg3) then
					return nil, "IslandLocked"
				end
				local v12 = fn59(arg3)
				if not v12 then
					return nil, "Warp Failed: No Boat Merchant"
				end
				if not fn62(arg2) then
					return nil, arg2.why or "Cancelled"
				end
				arg2.teleport = { islandId = arg3, attempts = 0, step = "PreparingCharacter", startedAt = os.clock(), failures = {} }
				tbl17.lastTeleport = arg2.teleport
				v11.Show(arg2)
				local exitTo = nil
				while true do
					if fn62(arg2) then
						fn61(arg2, "PreparingCharacter")
						local n19 = os.clock() + 8
						local v13, v14, v15 = fn48()
						while not v15 and fn62(arg2) and os.clock() < n19 do
							task.wait(0.2)
							local v16
							v13, v16, v15 = fn48()
						end
						if not fn62(arg2) then
							exitTo = 1
							break
						elseif v15 then
							arg2.character = v13
							arg2.respawning = false
							local teleport = arg2.teleport
							teleport.attempts = teleport.attempts + 1
							local tbl23 = {}
							local ok, result, lastError = pcall(fn63, arg2, arg3, v12, v15, tbl23)
							if tbl23.hb then
								tbl23.hb:Disconnect()
							end
							arg2.pinConnection = nil
							if not fn62(arg2) then
								exitTo = 1
								break
							elseif not (ok and result == true) then
								local teleport2 = arg2.teleport
								if ok then
									lastError = lastError or "TeleportUnconfirmed"
								else
									lastError = tostring(result)
								end
								teleport2.lastError = lastError
								table.insert(arg2.teleport.failures, {
									attempt = arg2.teleport.attempts,
									step = arg2.teleport.step,
									reason = arg2.teleport.lastError,
								})
								if #arg2.teleport.failures > 12 then
									table.remove(arg2.teleport.failures, 1)
								end
								fn61(arg2, "RetryingTeleport")
								v11.Update("Retrying teleport... (" .. tostring(arg2.teleport.attempts) .. ")", nil, arg2)
								task.wait(1)
								continue
							end
						else
							arg2.teleport.lastError = "CharacterNotReady"
							fn61(arg2, "RetryingTeleport")
							v11.Update("Retrying teleport... (" .. tostring(arg2.teleport.attempts) .. ")", nil, arg2)
							task.wait(1)
							continue
						end
						break
					else
						exitTo = 1
						break
					end
				end
				if exitTo == 1 then
					arg2.teleport.success = false
					arg2.teleport.stopReason = arg2.why or "Cancelled"
					arg2.teleport.completedAt = os.clock()
					fn61(arg2, "Stopped")
					v11.Abort(arg2)
					return nil, arg2.why or "Cancelled"
				end
				arg2.respawning = false
				arg2.teleport.success = true
				arg2.teleport.completedAt = os.clock()
				fn61(arg2, "Arrived")
				v11.Finish(true, arg2)
				return true
			end
			local function fn65(arg2, arg3)
				if not fn62(arg2) then
					return nil, arg2.why or "Cancelled"
				end
				if fn46() == arg3 then
					return true
				end
				return fn64(arg2, arg3)
			end
			local function fn66(arg2)
				local main = arg2 and arg2:FindFirstChild("Main")
				if not main then
					return nil
				end
				local cFrame4 = main.CFrame
				local size = main.Size
				local raycastParams = RaycastParams.new()
				local tbl23 = {}
				local tbl24 = {}
				local tbl25 = {}
				raycastParams.FilterType = Enum.RaycastFilterType.Include
				raycastParams.FilterDescendantsInstances = { arg2 }
				for _, v12 in arg2:GetDescendants() do
					if v12:IsA("Seat") or v12:IsA("VehicleSeat") then
						table.insert(tbl23, v12)
					end
				end
				for i = 0, size.Z / 2, 0.5 do
					for i2 = -size.X / 2, size.X / 2, 0.5 do
						local v12 = cFrame4:PointToWorldSpace(Vector3.new(i2, 0, i))
						local hit = workspace:Raycast(Vector3.new(v12.X, cFrame4.Position.Y + 20, v12.Z), Vector3.new(0, -40, 0), raycastParams)
						if hit and hit.Instance.CanCollide and hit.Normal.Y > 0.95 then
							local n19 = math.floor(hit.Position.Y * 2 + 0.5)
							tbl25[n19] = (tbl25[n19] or 0) + 1
							table.insert(tbl24, { hit.Position, n19 })
						end
					end
				end
				if #tbl24 == 0 then
					return nil
				end
				local n19 = 0
				local v12 = nil
				for k, v13 in tbl25, nil, nil do
					if n19 < v13 then
						n19 = v13
						v12 = k
					end
				end
				local v13 = cFrame4:PointToWorldSpace(Vector3.new(0, 0, size.Z / 4))
				local huge = math.huge
				local v14 = nil
				for _, v15 in tbl24, nil, nil do
					if math.abs(v15[2] - v12) <= 1 then
						local flag27 = true
						for _, v16 in tbl23, nil, nil do
							local v17 = v16.CFrame:PointToObjectSpace(v15[1])
							local n20 = v16.Size.X / 2 + 0.75
							local flag28 = math.abs(v17.X) < n20
							if flag28 then
								local n21 = v16.Size.Z / 2 + 0.75
								flag28 = math.abs(v17.Z) < n21
							end
							if flag28 then
								flag27 = false
								break
							end
						end
						local magnitude = ((v15[1] - v13) * Vector3.new(1, 0, 1)).Magnitude
						if flag27 and magnitude < huge then
							v14 = v15[1]
							huge = magnitude
						end
					end
				end
				return v14
			end
			local function fn67(arg2)
				local v12, v13, v14 = fn48()
				if not (v13 and arg2 and arg2.Parent) or v14.SeatPart or v14.Sit or obj.Swimming and obj.Swimming:IsSwimming() then
					return false
				end
				local raycastParams = RaycastParams.new()
				raycastParams.FilterType = Enum.RaycastFilterType.Include
				raycastParams.FilterDescendantsInstances = { arg2 }
				return workspace:Raycast(v13.Position, Vector3.new(0, -6, 0), raycastParams) ~= nil
			end
			local function fn68(arg2, arg3)
				local v12 = fn66(arg3)
				if not v12 then
					return false, "Boat Deck Unavailable"
				end
				arg2.deckPoint = v12
				local v13 = fn56(arg2, v12 + Vector3.new(0, 3, 0))
				if v10 then
					v10:Stop()
				end
				if not v13 or arg2.st ~= "Running" then
					return false
				end
				task.wait(1)
				local v14 = fn67(arg3)
				local str5
				if v14 then
					str5 = nil
				else
					str5 = "Boat Deck Unconfirmed"
				end
				return v14, str5
			end
			local function fn69(arg2)
				if arg2.st ~= "Running" then
					return false
				end
				if arg.ShouldContinue and not arg.ShouldContinue() then
					arg2.st = "Stopped"
					arg2.why = "Shutdown"
					return false
				end
				if arg2.guard and not arg2.guard() then
					arg2.st = "Stopped"
					arg2.why = "Cancelled"
					return false
				end
				local deadline = arg2.deadline
				if deadline then
					local deadline2 = arg2.deadline
					deadline = os.clock() > deadline2
				end
				if deadline then
					arg2.st = "Stopped"
					arg2.why = "TravelTimeout"
					return false
				end
				if not arg2.respawning and player.Character ~= arg2.character then
					arg2.st = "Stopped"
					arg2.why = "CharacterChanged"
					return false
				end
				return true
			end
			local function fn70(arg2, arg3, arg4)
				if not arg4 then
					v11.Abort(arg2)
				end
				if arg2.watch then
					arg2.watch:Disconnect()
					arg2.watch = nil
				end
				if arg2.respawnConnection then
					arg2.respawnConnection:Disconnect()
					arg2.respawnConnection = nil
				end
				if arg2.pinConnection then
					arg2.pinConnection:Disconnect()
					arg2.pinConnection = nil
				end
				if arg2.driveCleanup then
					pcall(arg2.driveCleanup)
					arg2.driveCleanup = nil
				end
				if not arg3 then
					stopHold()
				end
				arg2.respawning = false
			end
			local function fn71(arg2)
				arg2.watch = game:GetService("RunService").Heartbeat:Connect(function()
					if not fn69(arg2) then
						fn70(arg2, false)
					end
				end)
			end
			local function fn72()
				return tbl17.active ~= nil or tbl17.deckPreparing ~= nil or tbl17.localMovement ~= nil
			end
			local function fn73(arg2, arg3)
				local v12 = fn48()
				if not v12 then
					return nil, "No Character"
				end
				return { st = "Running", character = v12, guard = arg2, deadline = os.clock() + (arg3 or 150) }
			end
			local function fn74(arg2)
				stopHold()
				if arg.SettleFishing then
					local settleFishing = arg.SettleFishing
					local function fn75()
						return fn69(arg2)
					end
					return settleFishing(fn75, arg2.options or {})
				end
				return true
			end
			local function fn75(arg2)
				if not fn69(arg2) then
					return false, arg2.why
				end
				local v12, v13 = fn74(arg2)
				if not v12 then
					return false, v13
				end
				tbl17.phase = "TravelingToIsland"
				local v14, v15 = fn65(arg2, arg2.islandId, arg2.boatId)
				if not v14 or not fn69(arg2) then
					return false, arg2.why or v15
				end
				if arg2.landingCFrame then
					tbl17.phase = "RestoringPosition"
					local v16, v17 = fn56(arg2, arg2.landingCFrame.Position, arg2.landingCFrame.LookVector)
					if not v16 or not fn69(arg2) then
						return false, arg2.why or v17
					end
					local v18, v19, v20 = fn48()
					if not v19 or (v19.Position - arg2.landingCFrame.Position).Magnitude > 2 or v20.SeatPart or v20.Sit or obj.Swimming and obj.Swimming:IsSwimming() then
						return false, "LandingPositionUnconfirmed"
					end
					local rotation = arg2.landingCFrame.Rotation
					v19.CFrame = CFrame.new(v19.Position) * rotation
				end
				local islandId = arg2.islandId
				if fn46() ~= islandId then
					return false, "Not On Island"
				end
				local why = arg2.why
				return fn69(arg2), why
			end
			tbl17.Start = function(arg2, arg3, landingCFrame, arg4, arg5)
				if fn72() then
					return false, "TravelBusy"
				end
				if arg.IsMovementBusy and arg.IsMovementBusy() then
					return false, "MovementBusy"
				end
				local v12 = table.clone(arg5 or {})
				v12.interruptFishing = arg4 == true
				if v12.targetPosition and typeof(v12.targetPosition) ~= "Vector3" then
					return false, "InvalidTarget"
				end
				if landingCFrame and typeof(landingCFrame) ~= "CFrame" then
					return false, "InvalidLanding"
				end
				local v13 = arg.ResolveIsland(arg2)
				if not v13 then
					return false, "UnknownIsland"
				end
				if not arg.IsUnlocked(v13, fn44()) then
					return false, "IslandLocked"
				end
				local v14 = fn73
				local guard = v12.guard
				local timeout = v12.timeout
				if timeout then
					timeout = math.clamp(tonumber(v12.timeout) or 600, 30, 900)
				end
				local v15, v16 = v14(guard, timeout or math.huge)
				if not v15 then
					return false, v16
				end
				v15.islandId = v13.id
				v15.options = v12
				v15.landingCFrame = landingCFrame
				v15.boatId = v12.boatId or tbl17.settings.boatId
				if v15.boatId ~= "truck" and v15.boatId ~= "red_truck" then
					return false, "InvalidBoat"
				end
				v15.forceNewBoat = v12.forceNewBoat == true
				v15.onBoatSpawned = v12.onBoatSpawned
				local v17 = tbl19
				local playerMode
				if v12.playerMode == nil then
					playerMode = tbl17.settings.playerMode
				else
					playerMode = v12.playerMode == true
				end
				v17.on = playerMode
				v15.playerMode = tbl19.on
				local v18 = tbl17
				tbl17.active = v15
				v18.lastError = nil
				fn71(v15)
				task.spawn(function()
					local n19 = math.clamp(tonumber(v12.maxAttempts) or 1, 1, 3)
					local flag27 = false
					local result = nil
					for i = 1, n19 do
						v15.attempt = i
						local ok, result2
						ok, result2, result = pcall(fn75, v15)
						flag27 = ok and result2 == true and fn69(v15)
						result = not ok and tostring(result2) or v15.why or result
						if not (flag27 or not fn69(v15)) then
							if v15.driveCleanup then
								pcall(v15.driveCleanup)
								v15.driveCleanup = nil
							end
							stopHold()
							if i < n19 then
								task.wait(1)
							end
							continue
						end
						break
					end
					fn70(v15, false, flag27)
					if tbl17.active == v15 then
						tbl17.active = nil
						tbl17.phase = flag27 and "Arrived" or "Failed"
						local v19 = tbl17
						local lastError
						if flag27 then
							lastError = nil
						else
							lastError = result or "TravelFailed"
						end
						v19.lastError = lastError
						tbl17.lastResult = { success = flag27, message = result, islandId = v15.islandId }
					end
					if arg.OnBusyChanged then
						arg.OnBusyChanged(false)
					end
					if arg3 then
						pcall(arg3, flag27, result, v15.islandId)
					end
				end)
				return true
			end
			tbl17.Cancel = function()
				local active = tbl17.active or tbl17.deckPreparing or tbl17.localMovement
				if not active then
					v11.Abort()
					stopHold()
					return false
				end
				active.st = "Stopped"
				active.why = "Cancelled"
				fn70(active, false)
				return true
			end
			tbl17.StandOnDeck = function()
				if fn72() then
					return false
				end
				local heldBoat = tbl17.heldBoat
				if not heldBoat or not heldBoat.Parent then
					return false
				end
				local v12 = fn73(nil, 18)
				if not v12 then
					return false
				end
				local v13 = tbl17
				tbl17.deckPreparing = v12
				v13.deckResult = nil
				fn71(v12)
				task.spawn(function()
					fn58(heldBoat)
					local ok, result, result2 = pcall(fn68, v12, heldBoat)
					local flag27 = ok and result == true and fn69(v12)
					fn70(v12, flag27)
					if tbl17.deckPreparing == v12 then
						tbl17.deckResult = { success = flag27, reason = ok and (v12.why or result2) or tostring(result), point = v12.deckPoint }
						tbl17.deckPreparing = nil
					end
				end)
				return true
			end
			tbl17.HoverAt = function(arg2)
				if fn72() then
					return nil, "TravelBusy"
				end
				return fn55(arg2, 30)
			end
			tbl17.IsReady = function(arg2)
				local v12, v13, v14 = fn48()
				local seatPart = not v13 or not arg2 or v14.SeatPart or v14.Sit or v14.PlatformStand
				local flag27
				if seatPart then
					flag27 = seatPart
				else
					local swimming = Enum.HumanoidStateType.Swimming
					flag27 = v14:GetState() == swimming
				end
				if flag27 or obj.Swimming and obj.Swimming:IsSwimming() then
					return false
				end
				if ((v13.Position - arg2) * Vector3.new(1, 0, 1)).Magnitude > 45 or (v13.Position - arg2).Magnitude > 60 or math.abs(v13.AssemblyLinearVelocity.Y) > 3 then
					return false
				end
				return fn67(tbl17.heldBoat) or v10 and not v10.dn and v10.st == "Arrived" and v13.Position.Y >= arg2.Y + 7 or false
			end
			tbl17.MoveLocal = function(arg2, arg3)
				if fn72() then
					return false, "TravelBusy"
				end
				local v12, v13 = fn73(arg3, 120)
				if not v12 then
					return false, v13
				end
				tbl17.localMovement = v12
				fn71(v12)
				local ok, result, result2 = pcall(function()
					stopHold()
					local v14
					v14, v14 = fn48()
					if v14 then
						v14.Anchored = false
					end
					return fn56(v12, arg2.Position, arg2.LookVector)
				end)
				local flag27 = ok and result == true and fn69(v12)
				fn70(v12, false)
				tbl17.localMovement = nil
				if arg.OnBusyChanged then
					arg.OnBusyChanged(false)
				end
				return flag27, ok and (v12.why or result2) or tostring(result)
			end
			tbl17.StopHold = stopHold
			tbl17.SetPlayerMode = function(arg2)
				if fn72() then
					return false, "TravelBusy"
				end
				tbl17.settings.playerMode = arg2 == true
				tbl19.on = tbl17.settings.playerMode
				return true
			end
			tbl17.GetDeckPosition = function()
				local cars = workspace:FindFirstChild("Cars")
				local heldBoat = tbl17.heldBoat or cars and cars:FindFirstChild(tostring(player.UserId))
				return heldBoat and fn66(heldBoat) or nil
			end
			tbl17.GetStatus = function()
				local active = tbl17.active or tbl17.deckPreparing or tbl17.localMovement
				local tbl23 = {
					active = fn72(),
					busy = fn72(),
					driverVersion = tbl17.DriverVersion,
					phase = tbl17.phase,
					islandId = active and active.islandId,
					boatId = active and active.boatId or tbl17.settings.boatId,
					attempt = active and active.attempt,
				}
				local playerMode
				if active then
					playerMode = active.playerMode
				else
					playerMode = tbl17.settings.playerMode
				end
				tbl23.playerMode = playerMode
				tbl23.expectedRespawn = active and active.respawning == true
				tbl23.holdingDeck = fn67(tbl17.heldBoat)
				tbl23.holdingWater = v10 ~= nil and not v10.dn
				tbl23.deckPreparing = tbl17.deckPreparing ~= nil
				tbl23.deckResult = tbl17.deckResult
				tbl23.lastError = tbl17.lastError
				tbl23.lastResult = tbl17.lastResult
				tbl23.spawnPending = tbl17.pendingSpawn ~= nil
				tbl23.currentIslandId = fn46()
				tbl23.loading = v11.GetStatus()
				tbl23.teleport = active and active.teleport or tbl17.lastTeleport
				return tbl23
			end
			tbl17.Shutdown = function()
				v11.Shutdown()
				tbl20.active = false
				tbl17.Cancel()
				stopHold()
				pcall(function()
					game:GetService("RunService"):UnbindFromRenderStep("HuneAutoIslandPlayerMove")
				end)
			end
			return tbl17
		end
	end
	local flag27 = false
	local tbl17 = {
		Player = localPlayer,
		Client = client,
		Catalog = Catalog,
		GetPlayerData = function()
			return PlayerDataV2Controller:Fetch(localPlayer)
		end,
		GetCurrentIslandId = fn18,
		ResolveIsland = function(arg)
			if tbl3[arg] then
				return tbl3[arg]
			end
			for _, v10 in pairs(tbl3) do
				if v10.id == arg then
					return v10
				end
			end
		end,
		IsUnlocked = fn42,
		IsMovementBusy = function()
			return not flag or flag20 or flag14 or tbl6.pending or tbl6.resumeFarm or flag15 or tbl10.requestBusy or tbl6.bossBoatTravel and tbl6.bossBoatTravel.GetStatus().active or tbl6.nativeIslandTravel and tbl6.nativeIslandTravel.GetStatus().active
		end,
		OnBusyChanged = function(arg)
			if not arg and flag27 then
				flag27 = false
				flag20 = false
			end
		end,
		SettleFishing = function(arg, arg2)
			if flag27 then
				return arg()
			end
			if not arg() or flag20 or flag14 then
				return false, "Movement busy."
			end
			if arg2.waitForIdle then
				local n19 = os.clock() + 180
				while true do
					local attribute = arg()
					if attribute then
						local idling2 = FishingEnums.State.Idling
						attribute = fn7() ~= idling2 or localPlayer:GetAttribute("IsUsingSkill") or tbl6.instantFarmOwns and tbl6.instantFarmOwns()
					end
					if attribute then
						tbl6.ngaoIslandTravel.phase = "FinishingCurrentAction"
						if n19 <= os.clock() then
							return false, "CurrentActionTimeout"
						end
						task.wait(0.1)
						continue
					end
					break
				end
				if not arg() or flag20 or flag14 then
					return false, "MovementBusy"
				end
			end
			local v10 = fn7()
			if v10 ~= FishingEnums.State.Idling then
				if arg2.interruptFishing ~= true then
					return false, "Fishing action is still active."
				end
				if v10 == FishingEnums.State.Caught and fn then
					pcall(fn)
				end
				pcall(function()
					FishingPackets.FishCancel:Fire()
				end)
				local n19 = os.clock() + 3
				while true do
					task.wait(0.1)
					if not arg() then
						return false, "Travel cancelled."
					else
						local caught = FishingEnums.State.Caught
						if fn7() == caught and fn then
							pcall(fn)
						end
						local idling2 = FishingEnums.State.Idling
						if fn7() == idling2 or os.clock() >= n19 then
							break
						end
					end
				end
				local idling2 = FishingEnums.State.Idling
				if fn7() ~= idling2 then
					return false, "Fishing action did not stop."
				end
			end
			local character = localPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			character = character and character:FindFirstChild("HumanoidRootPart")
			if humanoid then
				pcall(function()
					humanoid:UnequipTools()
				end)
			end
			if character then
				character.Anchored = false
			end
			flag27 = true
			flag20 = true
			return true
		end,
		ShouldContinue = function()
			return flag
		end,
	}
	local v10 = fn43()(tbl17)
	tbl6.ngaoIslandTravel = v10
	local function fn44()
		return function(arg)
			local player = arg.Player
			local tbl18 = { DriverVersion = "2.4", phase = "Ready" }
			local obj = setmetatable({}, { __index = function(arg2, arg3)
				local ok, result = pcall(function()
					return arg.Client.GetController(arg3)
				end)
				if ok and result then
					return result
				end
				if type(getrenv) == "function" then
					return (getrenv().shared or {})[arg3]
				end
			end })
			local function fn45()
				return arg.GetPlayerData()
			end
			local function fn46(...)
				local ReplicatedStorage2 = game:GetService("ReplicatedStorage")
				for _, v11 in { ... }, nil, nil do
					ReplicatedStorage2 = ReplicatedStorage2:FindFirstChild(v11) or error("Module Missing: " .. v11)
				end
				return require(ReplicatedStorage2)
			end
			local function fn47()
				return arg.GetCurrentIslandId() or ""
			end
			local function fn48(arg2)
				local v11 = arg.ResolveIsland(arg2)
				return v11 and arg.IsUnlocked(v11, fn45())
			end
			local function fn49(arg2)
				for _, v11 in game:GetService("CollectionService"):GetTagged("IslandRegion") do
					if v11:IsA("BasePart") and v11:GetAttribute("islandId") == arg2 then
						return v11.Position
					end
				end
			end
			local function fn50(arg2)
				for _, v11 in game:GetService("CollectionService"):GetTagged("IslandRegion") do
					if v11:IsA("BasePart") then
						local v12 = v11.CFrame:PointToObjectSpace(arg2)
						local n19 = v11.Size.X / 2
						local flag28 = math.abs(v12.X) <= n19
						if flag28 then
							local n20 = v11.Size.Z / 2
							flag28 = math.abs(v12.Z) <= n20
						end
						if flag28 then
							return v11:GetAttribute("islandId") or ""
						end
					end
				end
				return ""
			end
			local function fn51(arg2, arg3)
				local magnitude = nil
				local v11 = nil
				local v12 = nil
				for _, v13 in game:GetService("CollectionService"):GetTagged("Interactive") do
					if v13:GetAttribute("InteractiveId") == arg2 then
						local position = v13:IsA("Model") and v13:GetPivot().Position or v13:IsA("BasePart") and v13.Position
						if position and (not magnitude or (position - arg3).Magnitude < magnitude) then
							magnitude = (position - arg3).Magnitude
							v11 = position
							v12 = v13
						end
					end
				end
				return v11, v12
			end
			local tbl19 = {
				Enum.HumanoidStateType.Freefall,
				Enum.HumanoidStateType.FallingDown,
				Enum.HumanoidStateType.Ragdoll,
			}
			local v11 = nil
			local function fn52()
				local character = player.Character
				local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if humanoidRootPart and humanoid and humanoid.Health > 0 and humanoidRootPart:IsA("BasePart") then
					return character, humanoidRootPart, humanoid
				end
				return nil
			end
			local function fn53(arg2, cFrame4)
				arg2.CFrame = cFrame4
				arg2.AssemblyLinearVelocity = Vector3.zero
				arg2.AssemblyAngularVelocity = Vector3.zero
			end
			local function fn54(arg2)
				if arg2.ca then
					arg2.ca:Disconnect()
					arg2.cr:Disconnect()
				end
				for k, v12 in arg2.cc, nil, nil do
					pcall(function()
						k.CanCollide = v12
					end)
				end
				for k, v12 in arg2.ss, nil, nil do
					pcall(function()
						arg2.h:SetStateEnabled(k, v12)
					end)
				end
				arg2.c = nil
				arg2.h = nil
				arg2.ca = nil
				arg2.cr = nil
				arg2.cc = {}
				arg2.ss = {}
				arg2.pl = {}
			end
			local function fn55(arg2, c, h)
				fn54(arg2)
				arg2.c = c
				arg2.h = h
				arg2.pd = true
				for _, v12 in tbl19, nil, nil do
					arg2.ss[v12] = h:GetStateEnabled(v12)
					h:SetStateEnabled(v12, false)
				end
				arg2.ca = c.DescendantAdded:Connect(function()
					arg2.pd = true
				end)
				arg2.cr = c.DescendantRemoving:Connect(function()
					arg2.pd = true
				end)
			end
			local function fn56(arg2)
				local v12, v13, v14 = fn52()
				if not v12 then
					return
				end
				if v12 ~= arg2.c then
					fn55(arg2, v12, v14)
				end
				if arg2.pd then
					arg2.pd = false
					arg2.pl = {}
					for _, v15 in v12:GetDescendants() do
						if v15:IsA("BasePart") then
							if arg2.cc[v15] == nil then
								arg2.cc[v15] = v15.CanCollide
							end
							table.insert(arg2.pl, v15)
						end
					end
				end
				for _, v15 in arg2.pl, nil, nil do
					if v15.CanCollide then
						v15.CanCollide = false
					end
				end
				if v14.Sit or v14.SeatPart then
					v14.Sit = false
				end
			end
			local function fn57(arg2, arg3)
				local v12, v13, v14 = fn52()
				if not v12 then
					if arg2.c then
						fn54(arg2)
					end
					arg2.st = "Respawn"
					return
				end
				if v12 ~= arg2.c then
					fn55(arg2, v12, v14)
				end
				local n19 = arg2.p - v13.Position
				local flag28 = n19.Magnitude <= arg2.s * arg3
				local vector = Vector3.new(n19.X, 0, n19.Z)
				arg2.lk = flag28 and arg2.fk or vector.Magnitude > 0.001 and vector.Unit or arg2.lk
				arg2.st = flag28 and "Arrived" or "Moving"
				fn53(v13, CFrame.lookAlong(flag28 and arg2.p or v13.Position + n19.Unit * arg2.s * arg3, arg2.lk))
			end
			local function fn58(arg2, st, why)
				if arg2.dn then
					return
				end
				arg2.dn = true
				arg2.cs:Disconnect()
				arg2.ch:Disconnect()
				pcall(fn54, arg2)
				pcall(function()
					local v12
					v12, v12 = fn52()
					if v12 then
						v12.AssemblyLinearVelocity = Vector3.zero
						v12.AssemblyAngularVelocity = Vector3.zero
					end
				end)
				arg2.st = st
				arg2.why = why
				if v11 == arg2 then
					v11 = nil
				end
			end
			local function fn59(arg2, arg3, fk)
				if typeof(arg2) ~= "Vector3" or arg2.Magnitude ~= arg2.Magnitude or arg2.Magnitude == math.huge then
					return nil, "Move Failed: Bad Point"
				end
				if v11 then
					v11:Stop()
				end
				local v12, v13, v14 = fn52()
				local tbl20 = { st = "Moving", p = arg2, s = arg3, cc = {}, ss = {}, pl = {} }
				tbl20.lk = v13 and Vector3.new(v13.CFrame.LookVector.X, 0, v13.CFrame.LookVector.Z).Unit or -Vector3.new(0, 0, 1)
				tbl20.fk = fk or tbl20.lk
				tbl20.Stop = function(arg4)
					fn58(arg4 or tbl20, "Stopped")
				end
				if v12 then
					fn55(tbl20, v12, v14)
				end
				local RunService = game:GetService("RunService")
				tbl20.cs = RunService.Stepped:Connect(function()
					local ok, result = pcall(fn56, tbl20)
					if not ok then
						local v15 = fn58
						local str5 = ("Move Failed: %*"):format(result)
						v15(tbl20, "Failed", str5)
					end
				end)
				tbl20.ch = RunService.Heartbeat:Connect(function(deltaTime)
					local ok, result = pcall(fn57, tbl20, deltaTime)
					if not ok then
						local v15 = fn58
						local str5 = ("Move Failed: %*"):format(result)
						v15(tbl20, "Failed", str5)
					end
				end)
				v11 = tbl20
				return tbl20
			end
			local tbl20 = { on = false }
			local fn60 = nil
			local function fn61(arg2, arg3, arg4)
				for i = 1, 4 do
					local v12
					v12, v12 = fn52()
					if not v12 then
						return nil, "No Character"
					end
					local n19 = arg3 - v12.Position
					if n19.Magnitude <= 0.65 then
						return true
					end
					if arg2.st ~= "Running" then
						return nil, "Cancelled"
					end
					local v13, v14 = fn59(arg3, 30, arg4)
					if not v13 then
						return nil, v14
					end
					local n20 = n19.Magnitude / 30
					local n21 = os.clock() + n20 + 5
					while true do
						task.wait()
						if not (v13.st == "Arrived" or v13.dn or arg2.st ~= "Running" or os.clock() > n21) then
							continue
						end
						break
					end
					local why = v13.why
					v13:Stop()
					if why then
						return nil, why
					end
					if arg2.st ~= "Running" then
						return nil
					end
					task.wait(0.5)
				end
				return nil, "Move Timeout"
			end
			local function fn62(arg2, arg3, arg4)
				if tbl20.on and fn60 then
					return fn60(arg2, arg3)
				end
				return fn61(arg2, arg3, arg4)
			end
			local function fn63(arg2, arg3)
				local raycastParams = RaycastParams.new()
				raycastParams.FilterType = Enum.RaycastFilterType.Exclude
				raycastParams.FilterDescendantsInstances = { arg2 }
				local hit = workspace:Raycast(arg3 + Vector3.new(0, 20, 0), Vector3.new(0, -60, 0), raycastParams)
				return hit and Vector3.new(arg3.X, hit.Position.Y + 3, arg3.Z) or arg3
			end
			fn60 = function(arg2, arg3)
				return arg.WalkTo(CFrame.new(arg3), function()
					return arg2.st == "Running"
				end)
			end
			local function fn64(arg2, arg3, arg4)
				local n19 = Vector3.new(arg4.X, arg3.Y, arg4.Z) - arg3
				return fn63(arg2, arg3 + (n19.Magnitude > 0.1 and n19.Unit or Vector3.new(1, 0, 0)) * 6)
			end
			local tbl21 = nil
			local function fn65()
				local v12 = pairs
				local v13 = tbl21
				local tbl22
				if tbl21 then
					tbl22 = v13
				else
					tbl22 = {}
				end
				for k, v14 in v12(tbl22) do
					pcall(function()
						k.Disabled = v14
					end)
				end
				tbl21 = nil
			end
			local function fn66(arg2)
				fn65()
				tbl21 = {}
				for _, v12 in arg2:GetDescendants() do
					if v12:IsA("Seat") or v12:IsA("VehicleSeat") then
						tbl21[v12] = v12.Disabled
						v12.Disabled = true
					end
				end
			end
			local function stopHold()
				if v11 then
					v11:Stop()
				end
				fn65()
			end
			local function fn67(arg2, arg3)
				tbl18.pendingSpawn = nil
				arg2.forceNewBoat = false
				if arg2.onBoatSpawned then
					arg2.onBoatSpawned(arg3)
				end
				return arg3
			end
			local function fn68(arg2)
				local assets = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
				assets = assets and assets:FindFirstChild("Cars")
				assets = assets and assets:FindFirstChild(arg2)
				assets = assets and assets:FindFirstChild("Model")
				return assets and assets:GetAttribute("Speed")
			end
			local function fn69(arg2, arg3)
				local v12, v13 = fn52()
				local cars = workspace:FindFirstChild("Cars")
				if not v12 then
					return nil, "No Character"
				end
				if not cars then
					return nil, "No Cars Folder"
				end
				local str5 = tostring(player.UserId)
				local v14 = cars:FindFirstChild(str5)
				local Data = fn46("Data", "Catalog", "Car")
				local function fn70()
					return Data[arg3] and Data[arg3].price or 0
				end
				local function fn71(arg4)
					return arg4 and arg4:FindFirstChild("Main") and arg4:FindFirstChild("DSeat") and arg4:GetAttribute("Speed") == fn68(arg3) and ((arg4.Main.Position - v13.Position) * Vector3.new(1, 0, 1)).Magnitude < 500 and (not tbl20.on or fn70() > 0 or (arg4.Main.Position - v13.Position).Magnitude < 100)
				end
				if not arg2.forceNewBoat and fn71(v14) then
					return v14
				end
				local v15 = fn70()
				if (fn45().Coin or 0) < v15 then
					arg3 = "truck"
				end
				if not arg2.forceNewBoat and fn71(v14) then
					return v14
				end
				local pendingSpawn = tbl18.pendingSpawn
				if pendingSpawn then
					local n19 = os.clock() + 8
					repeat
						local v16 = cars:FindFirstChild(str5)
						if v16 and v16 ~= pendingSpawn.previous and v16:FindFirstChild("Main") and v16:FindFirstChild("DSeat") then
							return fn67(arg2, v16)
						end
						task.wait(0.2)
					until arg2.st ~= "Running" or os.clock() > n19
					return nil, "Boat Spawn Unconfirmed"
				end
				local npcCarMerchant, v16 = fn51("npc_car_merchant", v13.Position)
				if not npcCarMerchant then
					return nil, "No Boat Merchant"
				end
				local v17, v18 = fn62(arg2, fn64(v12, npcCarMerchant, v13.Position))
				if not v17 then
					return nil, v18
				end
				local packet2 = fn46("Stardust").Packet
				tbl18.pendingSpawn = { previous = v14, boatId = arg3, islandId = v16:GetAttribute("IslandId"), sentAt = os.clock() }
				local SpawnCarEvent = packet2("SpawnCarEvent", packet2.String)
				local fire = SpawnCarEvent.Fire
				local str6 = ("%*/%*"):format(arg3, v16:GetAttribute("IslandId"))
				fire(SpawnCarEvent, str6)
				local n19 = os.clock() + 8
				repeat
					task.wait(0.2)
					local v19 = cars:FindFirstChild(str5)
					if v19 and v19 ~= v14 and v19:FindFirstChild("Main") and v19:FindFirstChild("DSeat") then
						return fn67(arg2, v19)
					end
				until os.clock() > n19 or arg2.st ~= "Running"
				return nil, arg2.st == "Running" and "Boat Spawn Timeout" or nil
			end
			local function fn70(arg2, arg3)
				local v12, v13, v14 = fn52()
				if not v12 then
					return nil, "No Character"
				end
				local dSeat = arg3 and arg3:FindFirstChild("DSeat")
				if not dSeat or not dSeat:IsA("VehicleSeat") then
					return nil, "No Boat Seat"
				end
				local function fn71()
					return dSeat:FindFirstChildWhichIsA("ProximityPrompt", true)
				end
				local v15 = fn71()
				if not v15 then
					return nil, "No Boat Seat"
				end
				local lastBoarding = { attempts = 0, success = false, stage = "Approaching" }
				tbl18.lastBoarding = lastBoarding
				local function fn72()
					if arg2.boardingConnection then
						arg2.boardingConnection:Disconnect()
						arg2.boardingConnection = nil
					end
				end
				local function fn73(arg4, reason)
					fn72()
					local v16 = lastBoarding
					local v17 = lastBoarding
					local v18 = lastBoarding
					local success = arg4 == true
					local stage = arg4 and "Seated" or "Stopped"
					v16.success = success
					v17.reason = reason
					v18.stage = stage
					return arg4, reason
				end
				if arg2.st ~= "Running" then
					local v16, v17 = fn73(nil, arg2.why or "Cancelled")
					return v16, v17
				end
				if dSeat.Occupant == v14 then
					local v16, v17 = fn73(true)
					return v16, v17
				end
				stopHold()
				if tbl20.on and (v13.Position - dSeat.Position).Magnitude > 8 then
					fn60(arg2, fn64(v12, dSeat.Position, v13.Position))
				end
				local n19 = os.clock() + 20
				local function fn74(arg4)
					local parent = v15.Parent
					local worldPosition = parent and parent:IsA("Attachment") and parent.WorldPosition or parent and parent:IsA("BasePart") and parent.Position or dSeat.Position
					local n20 = (arg4.Position - dSeat.Position) * Vector3.new(1, 0, 1)
					local unit = n20.Magnitude > 0.1 and n20.Unit or Vector3.new(1, 0, 0)
					local n21 = math.max(0.5, tonumber(v15.MaxActivationDistance) or 8)
					local vector = Vector3.new
					return worldPosition + unit * math.min(2, n21 * 0.45) + vector(0, math.min(1.5, n21 * 0.35), 0)
				end
				local flag28 = false
				while true do
					if arg2.st ~= "Running" then
						local v16, v17 = fn73(nil, arg2.why or "Cancelled")
						return v16, v17
					else
						local v16, v17, v18 = fn52()
						if not v16 then
							local noCharacter, v19 = fn73(nil, "No Character")
							return noCharacter, v19
						end
						if not arg3.Parent or not dSeat.Parent then
							local boatRemoved, v19 = fn73(nil, "Boat Removed")
							return boatRemoved, v19
						end
						if dSeat.Occupant == v18 then
							local v19, v20 = fn73(true)
							return v19, v20
						end
						if dSeat.Occupant then
							local boatSeatOccupied, v19 = fn73(nil, "Boat Seat Occupied")
							return boatSeatOccupied, v19
						end
						v15 = fn71()
						if not v15 then
							local noBoatSeat, v19 = fn73(nil, "No Boat Seat")
							return noBoatSeat, v19
						end
						if v18.SeatPart == dSeat then
							task.wait(0.1)
						elseif dSeat.Disabled or not v15.Enabled then
							lastBoarding.stage = "WaitingForSeat"
							task.wait(0.2)
						else
							lastBoarding.stage = "Approaching"
							lastBoarding.gapBefore = (v17.Position - dSeat.Position).Magnitude
							local swimming = Enum.HumanoidStateType.Swimming
							lastBoarding.wasSwimming = v18:GetState() == swimming
							local v19 = fn61
							local v20 = fn74(v17)
							local v21, v22 = v19(arg2, v20)
							if not v21 then
								local v23, v24 = fn73(nil, v22 or arg2.why or "Boat Approach Failed")
								return v23, v24
							end
							stopHold()
							if arg2.st ~= "Running" then
								local v23, v24 = fn73(nil, arg2.why or "Cancelled")
								return v23, v24
							end
							local v23
							v23, v17, v18 = fn52()
							if not v23 then
								local noCharacter, v24 = fn73(nil, "No Character")
								return noCharacter, v24
							end
							if dSeat.Occupant == v18 then
								local v24, v25 = fn73(true)
								return v24, v25
							end
							lastBoarding.stage = "WaitingForSeat"
							local boatHoldFailed = nil
							local v24 = fn74(v17)
							arg2.boardingConnection = game:GetService("RunService").Heartbeat:Connect(function()
								if arg2.st ~= "Running" or not arg3.Parent or not dSeat.Parent or dSeat.Occupant == v18 or v18.SeatPart or v18.Sit then
									fn72()
									return
								end
								local ok, result = pcall(function()
									v24 = fn74(v17)
									local rotation = v17.CFrame.Rotation
									fn53(v17, CFrame.new(v24) * rotation)
								end)
								if not ok then
									boatHoldFailed = tostring(result)
									fn72()
								end
							end)
							lastBoarding.attempts = lastBoarding.attempts + 1
							local ok, result = pcall(fireproximityprompt, v15)
							if not ok then
								local v25, v26 = fn73(nil, "Boat Prompt Failed: " .. tostring(result))
								return v25, v26
							end
							local n20 = math.min(n19, os.clock() + 1)
							while true do
								task.wait(0.1)
								if not (dSeat.Occupant == v18 or boatHoldFailed or arg2.st ~= "Running" or os.clock() >= n20 or not arg3.Parent or not dSeat.Parent) then
									continue
								end
								break
							end
							fn72()
							if boatHoldFailed then
								local v25, v26 = fn73(nil, "Boat Hold Failed: " .. boatHoldFailed)
								return v25, v26
							end
							if arg2.st ~= "Running" then
								local v25, v26 = fn73(nil, arg2.why or "Cancelled")
								return v25, v26
							end
							if dSeat.Occupant == v18 then
								break
							end
							if not flag28 then
								flag28 = true
								if arg.SettleFishing then
									arg.SettleFishing(function()
										return arg2.st == "Running"
									end)
								end
							end
						end
						if not (n19 <= os.clock()) then
							continue
						end
						local str5 = dSeat.Disabled and "Boat Seat Disabled"
						local str6
						if str5 then
							str6 = str5
						else
							str6 = not v15.Enabled and "Boat Prompt Disabled"
						end
						str6 = str6 or "Sit Timeout"
						local v19, v20 = fn73(nil, str6)
						return v19, v20
					end
				end
				local v16, v17 = fn73(true)
				return v16, v17
			end
			local function fn71(arg2, arg3, arg4, arg5)
				local v12, v13, v14 = fn52()
				local main = arg3:FindFirstChild("Main")
				local dSeat = arg3:FindFirstChild("DSeat")
				local v15 = fn49(arg4)
				local CollectionService2 = game:GetService("CollectionService")
				if not (v14 and main and dSeat and dSeat:IsA("VehicleSeat")) then
					return nil, "Bad Boat"
				end
				if not v15 then
					return nil, "No Island Region"
				end
				local world = workspace:FindFirstChild("World")
				world = world and world:FindFirstChild("Islands")
				local raycastParams = RaycastParams.new()
				raycastParams.FilterType = Enum.RaycastFilterType.Include
				raycastParams.FilterDescendantsInstances = { world }
				local vector = Vector3.new(main.Position.X, 0, main.Position.Z)
				local vector2 = arg5 and Vector3.new(arg5.X, 0, arg5.Z) or Vector3.new(v15.X, 0, v15.Z)
				local tbl22 = {}
				local v16 = fn50(main.Position)
				local n19 = nil
				for _, v17 in CollectionService2:GetTagged("IslandRegion") do
					if v17:IsA("BasePart") and v16 ~= arg4 and v17:GetAttribute("islandId") == v16 then
						local vector3 = Vector3.new(v17.Position.X, 0, v17.Position.Z)
						local n20 = vector - vector3
						if n20.Magnitude > 1 and (vector2 - vector):Dot(vector3 - vector) > 0 then
							n19 = vector3 + n20.Unit * math.max(n20.Magnitude, v17.Size.X / 2 * 0.7 + 60)
						end
					end
				end
				local v17 = n19 or vector
				for _, v18 in CollectionService2:GetTagged("IslandRegion") do
					local attribute = v18:GetAttribute("islandId")
					if v18:IsA("BasePart") and attribute ~= arg4 and (n19 or attribute ~= v16) then
						local vector3 = Vector3.new(v18.Position.X, 0, v18.Position.Z)
						local n20 = v18.Size.X / 2 * 0.7
						local n21 = vector2 - v17
						local max = math.max
						local n22 = math.clamp((vector3 - v17):Dot(n21) / max(n21:Dot(n21), 1), 0, 1)
						local n23 = v17 + n21 * n22
						if (vector3 - n23).Magnitude < n20 then
							table.insert(tbl22, {
								n22,
								vector3 + ((n23 - vector3).Magnitude > 1 and (n23 - vector3).Unit or Vector3.new(-n21.Z, 0, n21.X).Unit) * (n20 + 60),
							})
						end
					end
				end
				table.sort(tbl22, function(arg6, arg7)
					return arg6[1] < arg7[1]
				end)
				local tbl23 = { n19 }
				for _, v18 in tbl22, nil, nil do
					table.insert(tbl23, v18[2])
				end
				table.insert(tbl23, vector2)
				local throttleFloat = 0
				local n20 = 0
				local n21 = math.max(main.Size.X, main.Size.Z) / 2 + 3
				local connection = game:GetService("RunService").Stepped:Connect(function()
					local v18 = dSeat
					local v19 = n20
					dSeat.ThrottleFloat = throttleFloat
					v18.SteerFloat = v19
				end)
				arg2.driveCleanup = function()
					if connection.Connected then
						connection:Disconnect()
					end
					pcall(function()
						local v18 = dSeat
						dSeat.ThrottleFloat = 0
						v18.SteerFloat = 0
					end)
				end
				local n22 = 0
				for k, v18 in tbl23, nil, nil do
					n22 += (v18 - (k > 1 and tbl23[k - 1] or vector)).Magnitude
				end
				local now3 = os.clock()
				local n23 = os.clock() + n22 / 15 + 60
				local function fn72(arg6, arg7, arg8)
					local v18 = CFrame.Angles(0, arg7, 0):VectorToWorldSpace(arg6)
					return workspace:Raycast(Vector3.new(main.Position.X, 5, main.Position.Z), v18 * arg8, raycastParams)
				end
				local n24 = 1
				local huge = math.huge
				local n25 = 0
				local n26 = 0
				local str5, flag28, hit
				while true do
					str5 = nil
					flag28 = false
					hit = nil
					if arg2.st ~= "Running" then
						break
					else
						task.wait(0.1)
						if dSeat.Occupant ~= v14 then
							str5 = "Left Boat"
							hit = nil
							break
						else
							local vector3 = Vector3.new(main.Position.X, 0, main.Position.Z)
							local flag29 = fn47() == arg4 or fn50(main.Position) == arg4
							if flag29 and not arg5 and n24 == #tbl23 then
								local npcCarMerchant, v18 = fn51("npc_car_merchant", main.Position)
								if npcCarMerchant and v18:GetAttribute("IslandId") == arg4 then
									local vector4 = Vector3.new(npcCarMerchant.X, 0, npcCarMerchant.Z)
									if (vector4 - tbl23[n24]).Magnitude > 1 then
										tbl23[n24] = vector4
										huge = math.huge
									end
								end
							end
							local n27 = tbl23[n24] - vector3
							if n24 < #tbl23 and n27.Magnitude < 40 then
								n24 += 1
								huge = math.huge
							else
								local unit = Vector3.new(main.CFrame.LookVector.X, 0, main.CFrame.LookVector.Z).Unit
								if arg5 and n27.Magnitude < 5 then
									str5 = nil
									flag28 = true
									hit = nil
									break
								else
									local n28, unit2, dot, v18, n29, flag30, flag31, v19, v20, n30, n31
									if not arg5 and flag29 and n24 == #tbl23 then
										hit = world and workspace:Raycast(Vector3.new(vector3.X, 103, vector3.Z) + unit * n21, Vector3.new(0, -100, 0), raycastParams)
										if hit or n27.Magnitude < 18 then
											hit = hit and hit.Position
											str5 = nil
											flag28 = true
											break
										else
											if n27.Magnitude < huge - 1 then
												huge = n27.Magnitude
												now3 = os.clock()
											end
											if not (os.clock() < n25) then
												if os.clock() - now3 > 4 then
													n26 += 1
													if n26 > 4 then
														str5 = "Boat Stuck"
														hit = nil
														break
													else
														throttleFloat = -1
														n28 = n26 % 2 == 0 and 1
														n20 = n28 or -1
														n25 = os.clock() + 1.5
														now3 = os.clock() + 1.5
													end
												else
													unit2 = n27.Unit
													dot = unit.Dot
													v18 = math.atan2(unit:Cross(unit2).Y, dot(unit, unit2))
													n20 = math.clamp(-v18 / 0.43633231299858238, -1, 1)
													n29 = math.abs(v18) > 1.2217304763960306 and 0.4
													if not n29 then
														flag30 = n27.Magnitude < 60
														n29 = flag30 and n24 == #tbl23 and 0.6
													end
													throttleFloat = n29 or 1
													flag29 = flag29 and n24 == #tbl23
													flag31 = not flag29 and fn72(unit, 0, 30)
													if flag31 then
														v19 = fn72(unit, 0.69813170079773179, 30) or fn72(unit, 1.3962634015954636, 20)
														v20 = fn72(unit, -0.69813170079773179, 30) or fn72(unit, -1.3962634015954636, 20)
														n30 = not v19 and v20 and -1 or v19 and not v20 and 1
														if n30 then
															n20 = n30
														else
															n31 = v18 > 0 and -1
															n20 = n31 or 1
														end
														throttleFloat = 0.5
													end
													if n23 < os.clock() then
														str5 = "Boat Timeout"
														hit = nil
														break
													end
												end
											end
										end
									else
										if n27.Magnitude < huge - 1 then
											huge = n27.Magnitude
											now3 = os.clock()
										end
										if not (os.clock() < n25) then
											if os.clock() - now3 > 4 then
												n26 += 1
												if n26 > 4 then
													str5 = "Boat Stuck"
													hit = nil
													break
												else
													throttleFloat = -1
													n28 = n26 % 2 == 0 and 1
													n20 = n28 or -1
													n25 = os.clock() + 1.5
													now3 = os.clock() + 1.5
												end
											else
												unit2 = n27.Unit
												dot = unit.Dot
												v18 = math.atan2(unit:Cross(unit2).Y, dot(unit, unit2))
												n20 = math.clamp(-v18 / 0.43633231299858238, -1, 1)
												n29 = math.abs(v18) > 1.2217304763960306 and 0.4
												if not n29 then
													flag30 = n27.Magnitude < 60
													n29 = flag30 and n24 == #tbl23 and 0.6
												end
												throttleFloat = n29 or 1
												flag31 = not (flag29 and n24 == #tbl23) and fn72(unit, 0, 30)
												if flag31 then
													v19 = fn72(unit, 0.69813170079773179, 30) or fn72(unit, 1.3962634015954636, 20)
													v20 = fn72(unit, -0.69813170079773179, 30) or fn72(unit, -1.3962634015954636, 20)
													n30 = not v19 and v20 and -1 or v19 and not v20 and 1
													if n30 then
														n20 = n30
													else
														n31 = v18 > 0 and -1
														n20 = n31 or 1
													end
													throttleFloat = 0.5
												end
												if n23 < os.clock() then
													str5 = "Boat Timeout"
													hit = nil
													break
												end
											end
										end
									end
								end
							end
						end
					end
				end
				throttleFloat = 0
				n20 = 0
				task.wait(0.8)
				connection:Disconnect()
				dSeat.ThrottleFloat = 0
				dSeat.SteerFloat = 0
				arg2.driveCleanup = nil
				if arg2.st ~= "Running" then
					return nil, "Cancelled"
				end
				fn66(arg3)
				local n27 = os.clock() + 3
				while dSeat.Occupant == v14 and os.clock() < n27 and arg2.st == "Running" do
					v14.Sit = false
					v14.Jump = true
					task.wait(0.2)
				end
				if arg2.st ~= "Running" then
					return nil, "Cancelled"
				end
				if dSeat.Occupant == v14 then
					return nil, "Boat Seat Release Failed"
				end
				local v18, v19 = fn52()
				local v20 = arg5 and v19 and fn59(v19.Position, 30)
				task.wait(arg5 and 1 or 0.3)
				if str5 or not flag28 then
					if v20 then
						v20:Stop()
					end
					return nil, str5
				end
				return true, hit
			end
			local function fn72(arg2, arg3, arg4, arg5)
				if tbl20.on then
					return fn71(arg2, arg3, arg4, arg5)
				end
				local v12, v13, v14 = fn52()
				local main = arg3:FindFirstChild("Main")
				local dSeat = arg3:FindFirstChild("DSeat")
				local alignPosition = main and main:FindFirstChild("AlignPosition")
				local alignOrientation = main and main:FindFirstChild("AlignOrientation")
				local v15 = fn49(arg4)
				if not (v14 and dSeat and alignPosition and alignOrientation) then
					return nil, "Bad Boat"
				end
				if not v15 then
					return nil, "No Island Region"
				end
				local attribute = arg3:GetAttribute("Speed") or 30
				local y = alignPosition.Position.Y
				local tbl22 = {}
				local tbl23 = {}
				for _, v16 in { arg3, player.Character }, nil, nil do
					for _, v17 in v16:GetDescendants() do
						if v17:IsA("BasePart") then
							tbl22[v17] = v17.CanCollide
						end
						if v17:IsA("Seat") or v17:IsA("VehicleSeat") then
							table.insert(tbl23, v17)
						end
					end
				end
				local world = workspace:FindFirstChild("World")
				local islands = world and world:FindFirstChild("Islands")
				local raycastParams = RaycastParams.new()
				raycastParams.FilterType = Enum.RaycastFilterType.Include
				raycastParams.FilterDescendantsInstances = { islands }
				local vector = Vector3.new(main.Position.X, 0, main.Position.Z)
				local vector2 = arg5 and Vector3.new(arg5.X, 0, arg5.Z) or Vector3.new(v15.X, 0, v15.Z)
				local str5 = nil
				local connection = nil
				local flag28 = false
				local position = nil
				local unit = (vector2 - vector).Magnitude > 0.01 and (vector2 - vector).Unit or Vector3.new(1, 0, 0)
				local n19 = math.max(main.Size.X, main.Size.Z) / 2 + 3
				local function driveCleanup()
					if connection and connection.Connected then
						connection:Disconnect()
					end
					for k, v16 in tbl22, nil, nil do
						pcall(function()
							k.CanCollide = v16
						end)
					end
				end
				arg2.driveCleanup = driveCleanup
				connection = game:GetService("RunService").Stepped:Connect(function(time, deltaTime)
					local ok, result = pcall(function()
						for _, v16 in tbl23, nil, nil do
							local parent = v16.Occupant and v16.Occupant.Parent
							if parent and parent ~= player.Character then
								for _, v17 in parent:GetDescendants() do
									if v17:IsA("BasePart") and tbl22[v17] == nil then
										tbl22[v17] = v17.CanCollide
									end
								end
							end
						end
						for k in tbl22, nil, nil do
							if k.CanCollide then
								k.CanCollide = false
							end
						end
						local n20 = vector2 - vector
						if n20.Magnitude > 0.05 and not position then
							unit = n20.Unit
							local n21 = vector + unit * math.min(n20.Magnitude, attribute * deltaTime)
							local flag29 = not arg5 and flag28 and islands
							if flag29 then
								local v16 = workspace
								local raycast = v16.Raycast
								local n22 = unit * n19
								flag29 = raycast(v16, Vector3.new(n21.X, 103, n21.Z) + n22, Vector3.new(0, -100, 0), raycastParams)
							end
							if flag29 then
								position = flag29.Position
							else
								vector = n21
							end
						end
						local v16 = alignPosition
						local v17 = alignOrientation
						local vector3 = Vector3.new(vector.X, y, vector.Z)
						local cframe = CFrame.Angles(0, math.atan2(-unit.X, -unit.Z), 0)
						v16.Position = vector3
						v17.CFrame = cframe
					end)
					if not ok then
						str5 = ("Boat Drive Failed: %*"):format(result)
						connection:Disconnect()
					end
				end)
				local now3 = os.clock()
				local n20 = (vector2 - vector).Magnitude / attribute * 1.5
				local n21 = os.clock() + n20 + 30
				local huge = math.huge
				local flag29
				while true do
					local flag30 = arg2.st == "Running" and not str5
					flag29 = false
					if flag30 then
						task.wait(0.25)
						if dSeat.Occupant ~= v14 then
							str5 = "Left Boat"
							break
						else
							flag28 = fn47() == arg4
							if position then
								task.wait(0.5)
								flag29 = true
								break
							else
								if flag28 and not arg5 then
									local npcCarMerchant, v16 = fn51("npc_car_merchant", main.Position)
									local vector3 = npcCarMerchant and v16:GetAttribute("IslandId") == arg4 and Vector3.new(npcCarMerchant.X, 0, npcCarMerchant.Z)
									if vector3 and vector3 ~= vector2 then
										vector2 = vector3
										huge = math.huge
									end
								end
								local magnitude = (Vector3.new(main.Position.X, 0, main.Position.Z) - vector2).Magnitude
								if magnitude < huge - 1 then
									now3 = os.clock()
									huge = magnitude
								end
								if magnitude < (arg5 and 3 or 15) or flag28 and not arg5 and os.clock() - now3 > 2 then
									flag29 = true
									break
								else
									if os.clock() - now3 > 4 then
										str5 = "Boat Stuck"
									end
									if n21 < os.clock() then
										str5 = "Boat Timeout"
									end
									continue
								end
							end
						end
					end
					break
				end
				driveCleanup()
				arg2.driveCleanup = nil
				if arg2.st ~= "Running" then
					return nil, "Cancelled"
				end
				fn66(arg3)
				local n22 = os.clock() + 3
				while dSeat.Occupant == v14 and os.clock() < n22 and arg2.st == "Running" do
					v14.Sit = false
					v14.Jump = true
					task.wait(0.2)
				end
				if arg2.st ~= "Running" then
					return nil, "Cancelled"
				end
				if dSeat.Occupant == v14 then
					return nil, "Boat Seat Release Failed"
				end
				local v16
				v16, v16 = fn52()
				v16 = v16 and fn59(v16.Position, 30)
				task.wait(1)
				if str5 or not flag29 then
					if v16 then
						v16:Stop()
					end
					return nil, str5
				end
				return true, position
			end
			local tbl22 = {
				island_starter = Vector3.new(-37.4, 11.1, 305.9),
				island_jungle = Vector3.new(-1161.1, 10.8, -61.9),
				island_desert = Vector3.new(-44.1, 10.1, -935.4),
				island_snow = Vector3.new(1171.7, 9.4, -266.5),
				island_volcano = Vector3.new(1772.5, 9.2, 1069.3),
				island_fossil = Vector3.new(-543.2, 10.6, 2172.3),
			}
			local function fn73(arg2)
				for _, v12 in game:GetService("CollectionService"):GetTagged("Interactive") do
					if v12:GetAttribute("InteractiveId") == "npc_car_merchant" and v12:GetAttribute("IslandId") == arg2 then
						return v12:IsA("Model") and v12:GetPivot().Position or v12:IsA("BasePart") and v12.Position or tbl22[arg2]
					end
				end
				return tbl22[arg2]
			end
			local function fn74(arg2, arg3, arg4, arg5, arg6)
				stopHold()
				local v12 = nil
				arg2.respawning = true
				local connection = player.CharacterAdded:Connect(function(character)
					v12 = character
					arg2.character = character
					if arg.OnCharacter then
						arg.OnCharacter(character)
					end
				end)
				arg2.respawnConnection = connection
				pcall(function()
					arg5.Parent.HumanoidRootPart.Died.Volume = 0
				end)
				arg5.Health = 0
				local n19 = os.clock() + 10
				while true do
					task.wait(0.1)
					if not (v12 or os.clock() > n19 or arg2.st ~= "Running") then
						continue
					end
					break
				end
				connection:Disconnect()
				arg2.respawnConnection = nil
				local humanoidRootPart = v12 and v12:WaitForChild("HumanoidRootPart", 5)
				if not humanoidRootPart then
					arg2.respawning = false
					return nil, arg2.st == "Running" and "Warp Failed: No Respawn" or nil
				end
				arg2.respawning = false
				if arg2.st ~= "Running" then
					return nil, "Cancelled"
				end
				local Shared = fn46("Shared", "Lib", "SpawnPointDialogue")
				local cframe = CFrame.new(arg4 + Vector3.new(4, 3, 0))
				local flag28 = false
				arg6.hb = game:GetService("RunService").Heartbeat:Connect(function()
					if humanoidRootPart.Parent then
						local v13 = humanoidRootPart
						local v14 = cframe
						humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
						v13.CFrame = v14
					end
				end)
				arg2.pinConnection = arg6.hb
				local n20 = os.clock() + 4.5
				while not flag28 and os.clock() < n20 and arg2.st == "Running" do
					local tbl23 = {}
					local flag29 = false
					task.spawn(function()
						if arg2.st ~= "Running" then
							return
						end
						Shared.CreateAction(true, tbl23, tbl23).on_select(function(arg7)
							flag28 = arg7 == true
							flag29 = true
						end)
					end)
					local n21 = os.clock() + 3
					while true do
						task.wait()
						if not (flag29 or os.clock() > n21 or arg2.st ~= "Running") then
							continue
						end
						break
					end
					if not flag28 then
						task.wait(0.1)
					end
				end
				arg6.hb:Disconnect()
				arg2.pinConnection = nil
				if arg2.st ~= "Running" then
					return nil
				end
				if not flag28 then
					return nil, "Warp Failed: Spawn Not Set"
				end
				local Controllers = fn46("Controllers", "BackpackController")
				local flag29 = false
				for i = 1, 10 do
					task.wait(1)
					if arg2.st ~= "Running" then
						return nil
					end
					local ok, result = pcall(function()
						return Controllers.TeleportToSpawn:Fire()
					end)
					flag29 = ok and result == true
					if flag29 then
						break
					end
				end
				if not flag29 then
					return nil, "Warp Failed: Respawn Refused"
				end
				local n21 = os.clock() + 8
				while true do
					task.wait(0.2)
					if not (fn47() == arg3 and fn52() or os.clock() > n21 or arg2.st ~= "Running") then
						continue
					end
					break
				end
				if arg2.st ~= "Running" then
					return nil, "Cancelled"
				end
				if fn47() ~= arg3 then
					return nil, "Warp Failed: Not On Island"
				end
				return true
			end
			local function fn75(arg2, arg3)
				if not fn48(arg3) then
					return nil, "IslandLocked"
				end
				local v12 = fn73(arg3)
				if not v12 then
					return nil, "Warp Failed: No Boat Merchant"
				end
				local n19 = os.clock() + 8
				local v13, v14, v15 = fn52()
				while not v15 and arg2.st == "Running" and os.clock() < n19 do
					task.wait(0.2)
					local v16, v17
					v16, v17, v15 = fn52()
				end
				if arg2.st ~= "Running" then
					return nil, "Cancelled"
				end
				if not v15 then
					return nil, "No Character"
				end
				local tbl23 = {}
				local ok, result, result2 = pcall(fn74, arg2, arg3, v12, v15, tbl23)
				if tbl23.hb then
					tbl23.hb:Disconnect()
				end
				arg2.pinConnection = nil
				arg2.respawning = false
				local flag28 = ok and result == true
				if not ok then
					result2 = tostring(result)
				end
				return flag28, result2
			end
			local function fn76(arg2)
				local main = arg2 and arg2:FindFirstChild("Main")
				if not main then
					return nil
				end
				local cFrame4 = main.CFrame
				local size = main.Size
				local raycastParams = RaycastParams.new()
				local tbl23 = {}
				local tbl24 = {}
				local tbl25 = {}
				raycastParams.FilterType = Enum.RaycastFilterType.Include
				raycastParams.FilterDescendantsInstances = { arg2 }
				for _, v12 in arg2:GetDescendants() do
					if v12:IsA("Seat") or v12:IsA("VehicleSeat") then
						table.insert(tbl23, v12)
					end
				end
				for i = 0, size.Z / 2, 0.5 do
					for i2 = -size.X / 2, size.X / 2, 0.5 do
						local v12 = cFrame4:PointToWorldSpace(Vector3.new(i2, 0, i))
						local hit = workspace:Raycast(Vector3.new(v12.X, cFrame4.Position.Y + 20, v12.Z), Vector3.new(0, -40, 0), raycastParams)
						if hit and hit.Instance.CanCollide and hit.Normal.Y > 0.95 then
							local n19 = math.floor(hit.Position.Y * 2 + 0.5)
							tbl25[n19] = (tbl25[n19] or 0) + 1
							table.insert(tbl24, { hit.Position, n19 })
						end
					end
				end
				if #tbl24 == 0 then
					return nil
				end
				local n19 = 0
				local v12 = nil
				for k, v13 in tbl25, nil, nil do
					if v13 > n19 then
						n19 = v13
						v12 = k
					end
				end
				local v13 = cFrame4:PointToWorldSpace(Vector3.new(0, 0, size.Z / 4))
				local huge = math.huge
				local v14 = nil
				for _, v15 in tbl24, nil, nil do
					if math.abs(v15[2] - v12) <= 1 then
						local flag28 = true
						for _, v16 in tbl23, nil, nil do
							local v17 = v16.CFrame:PointToObjectSpace(v15[1])
							local n20 = v16.Size.X / 2 + 0.75
							local flag29 = math.abs(v17.X) < n20
							if flag29 then
								local n21 = v16.Size.Z / 2 + 0.75
								flag29 = math.abs(v17.Z) < n21
							end
							if flag29 then
								flag28 = false
								break
							end
						end
						local magnitude = ((v15[1] - v13) * Vector3.new(1, 0, 1)).Magnitude
						if flag28 and magnitude < huge then
							v14 = v15[1]
							huge = magnitude
						end
					end
				end
				return v14
			end
			local function fn77(arg2)
				local v12, v13, v14 = fn52()
				local seatPart = not (v13 and arg2 and arg2.Parent) or v14.SeatPart or v14.Sit
				local swimming
				if seatPart then
					swimming = seatPart
				else
					swimming = obj.Swimming and obj.Swimming:IsSwimming()
				end
				if swimming then
					return false
				end
				local raycastParams = RaycastParams.new()
				raycastParams.FilterType = Enum.RaycastFilterType.Include
				raycastParams.FilterDescendantsInstances = { arg2 }
				return workspace:Raycast(v13.Position, Vector3.new(0, -6, 0), raycastParams) ~= nil
			end
			local function fn78(arg2, arg3)
				local v12 = fn76(arg3)
				if not v12 then
					return false, "Boat Deck Unavailable"
				end
				arg2.deckPoint = v12
				local v13 = fn61(arg2, v12 + Vector3.new(0, 3, 0))
				if v11 then
					v11:Stop()
				end
				if not v13 or arg2.st ~= "Running" then
					return false
				end
				task.wait(1)
				local v14 = fn77(arg3)
				local str5
				if v14 then
					str5 = nil
				else
					str5 = "Boat Deck Unconfirmed"
				end
				return v14, str5
			end
			local function fn79(arg2, arg3)
				local v12
				v12, v12 = fn52()
				if not v12 then
					return nil, "No Character"
				end
				local function fn80()
					return obj.Swimming and obj.Swimming:IsSwimming()
				end
				if v11 and not v11.dn and not fn80() and v12.Position.Y > arg3 - 2 then
					return true
				end
				local v13, v14 = fn59(Vector3.new(v12.Position.X, arg3, v12.Position.Z), 30)
				if not v13 then
					return nil, v14
				end
				local n19 = os.clock() + 4
				while true do
					task.wait(0.1)
					if not (v13.st == "Arrived" and not fn80() or v13.dn or arg2.st ~= "Running" or os.clock() > n19) then
						continue
					end
					break
				end
				if v13.dn then
					return nil, v13.why or "Hover Failed"
				end
				if arg2.st ~= "Running" then
					return nil
				end
				if fn80() then
					return nil, "Hover Failed: Still Swimming"
				end
				return true
			end
			local function fn80(arg2)
				if arg2.st ~= "Running" then
					return false
				end
				if arg.ShouldContinue and not arg.ShouldContinue() then
					arg2.st = "Stopped"
					arg2.why = "Shutdown"
					return false
				end
				if arg2.guard and not arg2.guard() then
					arg2.st = "Stopped"
					arg2.why = "Cancelled"
					return false
				end
				local deadline = arg2.deadline
				if os.clock() > deadline then
					arg2.st = "Stopped"
					arg2.why = "TravelTimeout"
					return false
				end
				if not arg2.respawning and player.Character ~= arg2.character then
					arg2.st = "Stopped"
					arg2.why = "CharacterChanged"
					return false
				end
				return true
			end
			local function fn81(arg2, arg3)
				if arg2.watch then
					arg2.watch:Disconnect()
					arg2.watch = nil
				end
				if arg2.respawnConnection then
					arg2.respawnConnection:Disconnect()
					arg2.respawnConnection = nil
				end
				if arg2.pinConnection then
					arg2.pinConnection:Disconnect()
					arg2.pinConnection = nil
				end
				if arg2.boardingConnection then
					arg2.boardingConnection:Disconnect()
					arg2.boardingConnection = nil
				end
				if arg2.driveCleanup then
					pcall(arg2.driveCleanup)
					arg2.driveCleanup = nil
				end
				if not arg3 then
					stopHold()
				end
				arg2.respawning = false
			end
			local function fn82(arg2)
				arg2.watch = game:GetService("RunService").Heartbeat:Connect(function()
					if not fn80(arg2) then
						fn81(arg2, false)
					end
				end)
			end
			local function fn83()
				return tbl18.active ~= nil or tbl18.deckPreparing ~= nil or tbl18.localMovement ~= nil
			end
			local function fn84(arg2, arg3)
				local v12 = fn52()
				if not v12 then
					return nil, "No Character"
				end
				return { st = "Running", character = v12, guard = arg2, deadline = os.clock() + (arg3 or 150) }
			end
			local function fn85(arg2)
				stopHold()
				if arg.SettleFishing then
					return arg.SettleFishing(function()
						return fn80(arg2)
					end)
				end
				return true
			end
			local function fn86(arg2)
				local v12, v13 = fn85(arg2)
				if not v12 then
					return false, v13
				end
				if arg2.options.returning then
					local islandId = arg2.islandId
					if fn47() ~= islandId then
						tbl18.phase = "ReturningBySpawn"
						local v14, v15 = fn75(arg2, arg2.islandId)
						if not v14 then
							return false, v15
						end
					end
					if arg2.landingCFrame then
						tbl18.phase = "RestoringPosition"
						local v14, v15 = fn61(arg2, arg2.landingCFrame.Position, arg2.landingCFrame.LookVector)
						if not v14 then
							return false, v15
						end
						local v16, v17, v18 = fn52()
						if not v17 or (v17.Position - arg2.landingCFrame.Position).Magnitude > 2 or v18.SeatPart or v18.Sit or obj.Swimming and obj.Swimming:IsSwimming() then
							return false, "Home Position Unconfirmed"
						end
						local rotation = arg2.landingCFrame.Rotation
						v17.CFrame = CFrame.new(v17.Position) * rotation
					end
					local why = arg2.why
					return fn80(arg2), why
				end
				local islandId = arg2.islandId
				if fn47() ~= islandId then
					tbl18.phase = "WarpingToBossIsland"
					fn75(arg2, arg2.islandId)
					if not fn80(arg2) then
						return false, arg2.why
					end
				end
				tbl18.phase = "GettingBoat"
				local v14, v15 = fn69(arg2, arg2.boatId)
				if not v14 then
					return false, v15
				end
				tbl18.heldBoat = v14
				tbl18.phase = "BoardingBoat"
				local v16, v17 = fn70(arg2, v14)
				if not v16 then
					return false, v17
				end
				tbl18.phase = "DrivingBoat"
				local v18, v19 = fn72(arg2, v14, arg2.islandId, arg2.options.targetPosition)
				if not v18 then
					return false, v19
				end
				if not fn80(arg2) then
					return false, arg2.why
				end
				if arg2.options.targetPosition then
					tbl18.phase = "StandingOnDeck"
					local v20, v21 = fn78(arg2, v14)
					tbl18.deckResult = { success = v20 == true, reason = v21, point = arg2.deckPoint }
					if not v20 then
						tbl18.phase = "PreparingWaterHold"
						local v22, v23 = fn79(arg2, (arg2.options.bossTarget or arg2.options.targetPosition).Y + 9)
						if not v22 then
							return false, v23
						end
					end
				else
					tbl18.phase = "LandingOnIsland"
					local v20, v21 = fn52()
					if not v20 then
						return false, "No Character"
					end
					local v22, v23 = fn62(arg2, fn64(v20, fn73(arg2.islandId) or fn49(arg2.islandId), v21.Position))
					local flag28 = not v22
					local flag29
					if flag28 then
						flag29 = flag28
					else
						local islandId2 = arg2.islandId
						flag29 = fn47() ~= islandId2
					end
					if flag29 then
						return false, v23 or "Not On Island"
					end
				end
				local why = arg2.why
				return fn80(arg2), why
			end
			tbl18.Start = function(arg2, arg3, landingCFrame, arg4, arg5)
				if fn83() then
					return false, "TravelBusy"
				end
				if arg.IsMovementBusy and arg.IsMovementBusy() then
					return false, "MovementBusy"
				end
				local v12 = table.clone(arg5 or {})
				if v12.targetPosition and typeof(v12.targetPosition) ~= "Vector3" then
					return false, "InvalidTarget"
				end
				if landingCFrame and typeof(landingCFrame) ~= "CFrame" then
					return false, "InvalidLanding"
				end
				local v13 = arg.ResolveIsland(arg2)
				if not v13 then
					return false, "UnknownIsland"
				end
				if not arg.IsUnlocked(v13, fn45()) then
					return false, "IslandLocked"
				end
				local v14, v15 = fn84(v12.guard, 150)
				if not v14 then
					return false, v15
				end
				v14.islandId = v13.id
				v14.options = v12
				v14.landingCFrame = landingCFrame
				v14.boatId = v12.boatId or "truck"
				if v14.boatId ~= "truck" and v14.boatId ~= "red_truck" then
					return false, "InvalidBoat"
				end
				v14.forceNewBoat = v12.forceNewBoat == true
				v14.onBoatSpawned = v12.onBoatSpawned
				tbl20.on = arg.GetPlayerMode and arg.GetPlayerMode() == true or false
				v14.playerMode = tbl20.on
				local v16 = tbl18
				tbl18.active = v14
				v16.lastError = nil
				fn82(v14)
				task.spawn(function()
					local ok, result, result2 = pcall(fn86, v14)
					local flag28 = ok and result == true and fn80(v14)
					local why = not ok and tostring(result) or v14.why or result2
					fn81(v14, flag28 and v12.targetPosition ~= nil)
					if tbl18.active == v14 then
						tbl18.active = nil
						tbl18.phase = flag28 and "Arrived" or "Failed"
						local v17 = tbl18
						local lastError
						if flag28 then
							lastError = nil
						else
							lastError = why or "TravelFailed"
						end
						v17.lastError = lastError
						tbl18.lastResult = { success = flag28, message = why, islandId = v14.islandId }
					end
					if arg.OnBusyChanged then
						arg.OnBusyChanged(false)
					end
					if arg3 then
						pcall(arg3, flag28, why, v14.islandId)
					end
				end)
				return true
			end
			tbl18.Cancel = function()
				local active = tbl18.active or tbl18.deckPreparing or tbl18.localMovement
				if not active then
					stopHold()
					return false
				end
				active.st = "Stopped"
				active.why = "Cancelled"
				fn81(active, false)
				return true
			end
			tbl18.StandOnDeck = function()
				if fn83() then
					return false
				end
				local heldBoat = tbl18.heldBoat
				if not heldBoat or not heldBoat.Parent then
					return false
				end
				local v12 = fn84(nil, 18)
				if not v12 then
					return false
				end
				local v13 = tbl18
				tbl18.deckPreparing = v12
				v13.deckResult = nil
				fn82(v12)
				task.spawn(function()
					fn66(heldBoat)
					local ok, result, result2 = pcall(fn78, v12, heldBoat)
					local flag28 = ok and result == true and fn80(v12)
					fn81(v12, flag28)
					if tbl18.deckPreparing == v12 then
						local v14 = tbl18
						local deckResult = { success = flag28 }
						local why
						if ok then
							why = v12.why or result2
						else
							why = ok
						end
						deckResult.reason = why or tostring(result)
						deckResult.point = v12.deckPoint
						v14.deckResult = deckResult
						tbl18.deckPreparing = nil
					end
				end)
				return true
			end
			tbl18.HoverAt = function(arg2)
				if fn83() then
					return nil, "TravelBusy"
				end
				return fn59(arg2, 30)
			end
			tbl18.IsReady = function(arg2)
				local v12, v13, v14 = fn52()
				local seatPart = not v13 or not arg2 or v14.SeatPart or v14.Sit or v14.PlatformStand
				local flag28
				if seatPart then
					flag28 = seatPart
				else
					local swimming = Enum.HumanoidStateType.Swimming
					flag28 = v14:GetState() == swimming
				end
				if flag28 or obj.Swimming and obj.Swimming:IsSwimming() then
					return false
				end
				if ((v13.Position - arg2) * Vector3.new(1, 0, 1)).Magnitude > 45 or (v13.Position - arg2).Magnitude > 60 or math.abs(v13.AssemblyLinearVelocity.Y) > 3 then
					return false
				end
				return fn77(tbl18.heldBoat) or v11 and not v11.dn and v11.st == "Arrived" and v13.Position.Y >= arg2.Y + 7 or false
			end
			tbl18.MoveLocal = function(arg2, arg3)
				if fn83() then
					return false, "TravelBusy"
				end
				local v12, v13 = fn84(arg3, 120)
				if not v12 then
					return false, v13
				end
				tbl18.localMovement = v12
				fn82(v12)
				local ok, result, result2 = pcall(function()
					stopHold()
					local v14
					v14, v14 = fn52()
					if v14 then
						v14.Anchored = false
					end
					return fn61(v12, arg2.Position, arg2.LookVector)
				end)
				local flag28 = ok and result == true and fn80(v12)
				fn81(v12, false)
				tbl18.localMovement = nil
				if arg.OnBusyChanged then
					arg.OnBusyChanged(false)
				end
				return flag28, ok and (v12.why or result2) or tostring(result)
			end
			tbl18.StopHold = stopHold
			tbl18.GetStatus = function()
				local active = tbl18.active or tbl18.deckPreparing or tbl18.localMovement
				return {
					active = fn83(),
					busy = fn83(),
					driverVersion = tbl18.DriverVersion,
					phase = tbl18.phase,
					islandId = active and active.islandId,
					boatId = active and active.boatId,
					playerMode = active and active.playerMode,
					expectedRespawn = active and active.respawning == true,
					holdingDeck = fn77(tbl18.heldBoat),
					holdingWater = v11 ~= nil and not v11.dn,
					deckPreparing = tbl18.deckPreparing ~= nil,
					boarding = tbl18.lastBoarding,
					deckResult = tbl18.deckResult,
					lastError = tbl18.lastError,
					lastResult = tbl18.lastResult,
					spawnPending = tbl18.pendingSpawn ~= nil,
					currentIslandId = fn47(),
				}
			end
			tbl18.Shutdown = function()
				tbl18.Cancel()
				stopHold()
			end
			return tbl18
		end
	end
	local flag28 = false
	local tbl18 = {
		Player = localPlayer,
		Client = client,
		Catalog = Catalog,
		GetPlayerData = function()
			return PlayerDataV2Controller:Fetch(localPlayer)
		end,
		GetCurrentIslandId = fn18,
		ResolveIsland = function(arg)
			if tbl3[arg] then
				return tbl3[arg]
			end
			for _, v11 in pairs(tbl3) do
				if v11.id == arg then
					return v11
				end
			end
		end,
		IsUnlocked = fn42,
		GetPlayerMode = function()
			return v10.settings.playerMode
		end,
		WalkTo = function(arg, arg2)
			return walkTo(arg, arg2, 3)
		end,
		IsMovementBusy = function()
			return not flag or flag20 or flag14 or flag15 or tbl6.pending or tbl6.resumeFarm or v10.active ~= nil or v10.deckPreparing ~= nil or v10.localMovement ~= nil or tbl6.nativeIslandTravel and tbl6.nativeIslandTravel.GetStatus().active
		end,
		SettleFishing = function(arg)
			if flag28 then
				return arg()
			end
			if not arg() or flag20 or flag14 then
				return false, "MovementBusy"
			end
			local idling2 = FishingEnums.State.Idling
			if fn7() ~= idling2 or localPlayer:GetAttribute("IsUsingSkill") then
				return false, "FinishingCurrentAction"
			end
			if tbl6.closeMerchantDialogue then
				tbl6.closeMerchantDialogue()
			end
			local v11 = fn6()
			local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
			if v11 then
				v11.Anchored = false
			end
			if humanoid then
				pcall(function()
					humanoid:UnequipTools()
				end)
			end
			flag28 = true
			flag20 = true
			return true
		end,
		OnBusyChanged = function(arg)
			if not arg and flag28 then
				flag28 = false
				flag20 = false
			end
		end,
		OnCharacter = function(character)
			local bossScan = tbl6.bossScan
			if bossScan and bossScan.session then
				bossScan.session.character = character
			end
		end,
		ShouldContinue = function()
			return flag
		end,
	}
	tbl6.bossBoatTravel = fn44()(tbl18)
	genv.HuneHubFishingMaster.BossBoatTravel = tbl6.bossBoatTravel
	genv.HuneHubFishingMaster.GetBossBoatStatus = tbl6.bossBoatTravel.GetStatus
	fn2({ Disconnect = tbl6.bossBoatTravel.Shutdown })
	tbl6.isNgaoTravelBusy = function()
		return v10.active ~= nil or v10.deckPreparing ~= nil or v10.localMovement ~= nil
	end
	genv.HuneHubFishingMaster.NgaoIslandTravel = v10
	genv.HuneHubFishingMaster.GetNgaoTravelStatus = v10.GetStatus
	fn2({ Disconnect = v10.Shutdown })
	local FastTravelController = nil
	pcall(function()
		FastTravelController = client.GetController("FastTravelController")
	end)
	local n19 = 1872033233
	pcall(function()
		local monets = game:GetService("ReplicatedFirst"):FindFirstChild("monets")
		monets = monets and require(monets)
		local passesBuyFastTravel = type(monets) == "table" and monets["passes.buy_fast_travel"]
		if type(passesBuyFastTravel) == "table" and type(passesBuyFastTravel.id) == "number" and passesBuyFastTravel.id > 0 then
			n19 = passesBuyFastTravel.id
		end
	end)
	local tbl19 = { owned = nil, source = "Unchecked", checkedAt = 0, lastError = nil }
	local function fn45(arg, arg2, checkedAt, arg3, arg4)
		if type(arg) == "table" and type(arg.Entitlements) == "table" and arg.Entitlements.fast_travel == true then
			arg2.owned = true
			arg2.source = "Entitlements"
			arg2.checkedAt = checkedAt
			arg2.lastError = nil
			return true, arg2.source
		end
		if type(arg4) == "function" then
			local ok, result = pcall(arg4)
			if ok and result == true then
				arg2.owned = true
				arg2.source = "ShopController"
				arg2.checkedAt = checkedAt
				arg2.lastError = nil
				return true, arg2.source
			end
		end
		if arg2.owned == true then
			return true, arg2.source
		end
		local n20 = arg2.lastError and 5 or 15
		local flag29 = arg2.owned == false
		if flag29 then
			flag29 = checkedAt - (arg2.checkedAt or 0) < n20
		end
		if flag29 then
			return false, arg2.source, arg2.lastError
		end
		local ok, result = pcall(arg3)
		arg2.checkedAt = checkedAt
		if ok then
			arg2.owned = result == true
			arg2.source = "MarketplaceService"
			arg2.lastError = nil
		else
			local lastError = tostring(result)
			arg2.owned = false
			arg2.source = "MarketplaceServiceError"
			arg2.lastError = lastError
		end
		return arg2.owned, arg2.source, arg2.lastError
	end
	local function hasFastTravelGamepass(arg, arg2)
		if arg2 then
			local v11 = tbl19
			tbl19.owned = nil
			v11.checkedAt = 0
		end
		return fn45(arg, tbl19, os.clock(), function()
			return MarketplaceService:UserOwnsGamePassAsync(localPlayer.UserId, n19)
		end, function()
			local ShopController = client.GetController("ShopController")
			local passesBuyFastTravel = ShopController and ShopController._owned_state and ShopController._owned_state["passes.buy_fast_travel"]
			return type(passesBuyFastTravel) == "function" and passesBuyFastTravel() == true
		end)
	end
	tbl6.hasFastTravelGamepass = hasFastTravelGamepass
	local function fn46(arg)
		local tbl20
		tbl20 = {
			label = arg or "Fast Travel",
			active = nil,
			lastResult = nil,
			movementMethod = "Walk",
			tweenSpeed = 30,
			findGate = function()
				local v11 = fn6()
				if not v11 then
					return nil, nil, math.huge
				end
				local huge = math.huge
				local v12 = nil
				local v13 = nil
				for _, v14 in ipairs(CollectionService:GetTagged("Interactive")) do
					if v14:IsDescendantOf(workspace) and v14:GetAttribute("InteractiveId") == "fast_travel" then
						local v15 = fn12(v14)
						local magnitude = v15 and (v11.Position - v15).Magnitude
						if magnitude and magnitude < huge then
							huge = magnitude
							v12 = v14
							v13 = v15
						end
					end
				end
				return v12, v13, huge
			end,
			isCurrent = function(arg2)
				local flag29 = flag and tbl20.active == arg2 and not arg2.cancelled
				local flag30
				if flag29 then
					flag30 = os.clock() < (arg2.deadline or math.huge)
				else
					flag30 = flag29
				end
				return flag30
			end,
			moveLocal = function(arg2, arg3)
				if typeof(arg2) ~= "CFrame" then
					return false, "Invalid local movement target."
				end
				local character = localPlayer.Character
				local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				local function fn47()
					return tbl20.isCurrent(arg3) and localPlayer.Character == character and humanoidRootPart and humanoidRootPart.Parent and humanoid and humanoid.Health > 0
				end
				if not fn47() or humanoidRootPart.Anchored or humanoid.WalkSpeed <= 0 then
					return false, "MovementLocked"
				end
				local movementMethod = arg3.movementMethod or tbl20.movementMethod or "Walk"
				if movementMethod == "Walk" then
					return walkTo(arg2, fn47, 3)
				end
				if movementMethod == "Tween" then
					return tweenTo(arg2, fn47, arg3.tweenSpeed or tbl20.tweenSpeed or 30, true)
				end
				return false, "Unknown Gamepass movement method."
			end,
			SetMovementMethod = function(movementMethod)
				if movementMethod ~= "Walk" and movementMethod ~= "Tween" then
					return false
				end
				tbl20.movementMethod = movementMethod
				return true
			end,
			enterGate = function(arg2)
				local v11, v12, v13 = tbl20.findGate()
				if not v11 or not v12 then
					return false, "No streamed fast_travel gate was found on the current island."
				end
				local character = localPlayer.Character
				local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if not humanoidRootPart or not humanoid or humanoid.Health <= 0 then
					return false, "Character is not ready."
				end
				arg2.phase = "WalkingToGate"
				if v13 > 18 then
					local vector = Vector3.new(humanoidRootPart.Position.X - v12.X, 0, humanoidRootPart.Position.Z - v12.Z)
					if vector.Magnitude < 0.1 then
						vector = Vector3.new(0, 0, 1)
					end
					local n20 = vector.Unit * 8
					local n21 = Vector3.new(v12.X, humanoidRootPart.Position.Y, v12.Z) + n20
					arg2.phase = (arg2.movementMethod or "Walk") .. "ToGate"
					local v14, v15 = tbl20.moveLocal(CFrame.new(n21), arg2)
					if not v14 then
						return false, "Could not approach the fast travel gate: " .. tostring(v15)
					end
				end
				if not tbl20.isCurrent(arg2) then
					return false, "Island travel cancelled or timed out."
				end
				if localPlayer.Character ~= character or not humanoidRootPart.Parent or humanoid.Health <= 0 then
					return false, "Character changed while entering the fast travel gate."
				end
				local magnitude = (humanoidRootPart.Position - v12).Magnitude
				if magnitude > 20 then
					return false, "Could not enter the server's 20-stud fast travel gate radius."
				end
				humanoid:MoveTo(humanoidRootPart.Position)
				task.wait(0.2)
				if not tbl20.isCurrent(arg2) then
					return false, "Island travel cancelled or timed out."
				end
				return true, { gate = v11:GetFullName(), distanceBefore = v13, distanceAfter = magnitude }
			end,
			confirmArrival = function(arg2, arg3)
				arg2.phase = "Verifying"
				local n20 = os.clock() + 12
				local IslandRegionController = client.GetController("IslandRegionController")
				local now3 = nil
				local v11
				while tbl20.isCurrent(arg2) and os.clock() < n20 do
					local character = localPlayer.Character
					local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
					local humanoid = character and character:FindFirstChildOfClass("Humanoid")
					local ok, result = pcall(function()
						return IslandRegionController and IslandRegionController.GetIslandSnapshot:Fire()
					end)
					if not tbl20.isCurrent(arg2) then
						return false, "The server did not confirm a stable arrival at the requested island/position."
					end
					arg2.serverIslandId = ok and result or nil
					ok = ok and result == arg2.islandId
					local flag29
					if ok then
						local islandId = arg2.islandId
						flag29 = fn18() == islandId
					else
						flag29 = ok
					end
					if flag29 and humanoidRootPart and not humanoidRootPart.Anchored and humanoid and humanoid.Health > 0 and (typeof(arg3) ~= "CFrame" or (humanoidRootPart.Position - arg3.Position).Magnitude <= 8) then
						local v12
						if v11 == character then
							v12 = now3
						else
							v12 = nil
							v11 = character
						end
						now3 = v12 or os.clock()
						if os.clock() - now3 >= 3 then
							return true, "ServerConfirmedArrival"
						end
					else
						v11 = nil
						now3 = nil
					end
					task.wait(0.5)
				end
				return false, "The server did not confirm a stable arrival at the requested island/position."
			end,
			placeAt = function(arg2, arg3)
				if typeof(arg2) ~= "CFrame" then
					return tbl20.confirmArrival(arg3)
				end
				arg3.phase = "WaitingForNativeRelease"
				task.spawn(function()
					pcall(function()
						localPlayer:RequestStreamAroundAsync(arg2.Position, 2)
					end)
				end)
				local n20 = os.clock() + 8
				local character, humanoidRootPart
				while true do
					if not tbl20.isCurrent(arg3) then
						return false, "Island travel cancelled or timed out."
					else
						character = localPlayer.Character
						humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
						character = character and character:FindFirstChildOfClass("Humanoid")
						local flag29 = humanoidRootPart and character and character.Health > 0 and not humanoidRootPart.Anchored and character.WalkSpeed > 0
						if flag29 then
							local idling2 = FishingEnums.State.Idling
							flag29 = fn7() == idling2
						end
						if flag29 and localPlayer:GetAttribute("IsUsingSkill") ~= true then
							break
						end
						task.wait(0.1)
						if not (n20 <= os.clock()) then
							continue
						end
						break
					end
				end
				local anchored = not humanoidRootPart or not character or character.Health <= 0 or humanoidRootPart.Anchored or character.WalkSpeed <= 0
				local flag29
				if anchored then
					flag29 = anchored
				else
					local idling2 = FishingEnums.State.Idling
					flag29 = fn7() ~= idling2
				end
				if flag29 or localPlayer:GetAttribute("IsUsingSkill") == true then
					return false, "Character was not ready at the destination island."
				end
				arg3.phase = (arg3.movementMethod or "Walk") .. "ToSavedPosition"
				local v11, v12 = tbl20.moveLocal(arg2, arg3)
				if not v11 then
					return false, "Could not reach the saved position: " .. tostring(v12)
				end
				if not tbl20.isCurrent(arg3) then
					return false, "Island travel cancelled or timed out."
				end
				local v13 = fn6()
				if not v13 then
					return false, "Character root is not ready."
				end
				pcall(function()
					local rotation = arg2.Rotation
					v13.CFrame = CFrame.new(v13.Position) * rotation
				end)
				return tbl20.confirmArrival(arg3, arg2)
			end,
			Start = function(arg2, arg3, arg4, arg5, arg6)
				if not flag then
					return false, "Travel unavailable."
				end
				if arg4 ~= nil and typeof(arg4) ~= "CFrame" then
					return false, "Invalid landing position."
				end
				if arg3 ~= nil and type(arg3) ~= "function" then
					return false, "Invalid travel callback."
				end
				if arg6 ~= nil and type(arg6) ~= "table" then
					return false, "Invalid travel options."
				end
				local movementMethod = arg6 and arg6.movementMethod or tbl20.movementMethod
				arg6 = arg6 and arg6.tweenSpeed or tbl20.tweenSpeed
				if movementMethod ~= "Walk" and movementMethod ~= "Tween" then
					return false, "Invalid movement method."
				end
				if type(arg6) ~= "number" or arg6 ~= arg6 or math.abs(arg6) == math.huge then
					return false, "Invalid movement speed."
				end
				local n20 = math.clamp(arg6, 20, 70)
				if tbl6.isNgaoTravelBusy and tbl6.isNgaoTravelBusy() then
					return false, "Boat travel is running."
				end
				if tbl20.active then
					return false, (tbl20.label or "Fast") .. " travel is already running."
				end
				if flag20 or flag14 or tbl6.pending or tbl6.resumeFarm or flag15 then
					return false, "Movement busy."
				end
				if not FastTravelController or not FastTravelController.TravelToIsland then
					pcall(function()
						FastTravelController = client.GetController("FastTravelController")
					end)
				end
				if not FastTravelController or not FastTravelController.TravelToIsland then
					return false, "FastTravelController is unavailable."
				end
				local v11 = tbl3[arg2]
				if not v11 then
					return false, "Destination island was not found."
				end
				local ok, result = pcall(function()
					return PlayerDataV2Controller:Fetch(localPlayer)
				end)
				if not ok or type(result) ~= "table" then
					return false, "Player data is not ready."
				end
				local v12, ownershipSource, v13 = hasFastTravelGamepass(result)
				local v14 = tbl20
				tbl20.ownershipSource = ownershipSource
				v14.ownershipError = v13
				if not v12 then
					ownershipSource = v13 and "ServerCheckAfterProbeError" or "ServerCheck"
				end
				if not fn42(v11, result) then
					return false, "Destination island is locked."
				end
				local active = {
					islandName = arg2,
					islandId = v11.id,
					callback = arg3,
					landingCFrame = arg4,
					cancelled = false,
					deadline = os.clock() + 180,
					phase = "FinishingFishing",
					movementMethod = movementMethod,
					tweenSpeed = n20,
					ownershipSource = ownershipSource,
				}
				tbl20.active = active
				flag20 = true
				task.defer(function()
					local function fn47(arg7, arg8, arg9)
						if tbl20.active ~= active then
							return
						end
						tbl20.active = nil
						flag20 = false
						tbl20.lastResult = { success = arg7, message = arg8, islandId = active.islandId, details = arg9 }
						if type(arg3) == "function" then
							task.defer(function()
								pcall(arg3, arg7, arg8)
							end)
						end
					end
					local ok2, result2 = pcall(function()
						if not fn13(nil, arg5 == true, function()
							return tbl20.isCurrent(active)
						end) then
							fn47(false, "Could not finish the current fishing action.")
							return
						end
						if tbl20.active ~= active or active.cancelled then
							return
						end
						local v15 = fn18()
						if v15 == active.islandId then
							local v16, v17 = tbl20.placeAt(arg4, active)
							if v16 then
								fn47(true, "Already on the expected island.", { beforeIslandId = v15, actualIslandId = v15, placement = v17 })
							else
								fn47(false, v17)
							end
							return
						end
						local v16, v17 = tbl20.enterGate(active)
						if not v16 then
							fn47(false, v17)
							return
						end
						active.phase = "Requesting"
						local ok2, result2 = pcall(function()
							return FastTravelController.TravelToIsland:Fire(active.islandId)
						end)
						if not ok2 then
							fn47(false, "Fast travel packet failed: " .. tostring(result2))
							return
						end
						if result2 ~= 0 then
							fn47(false, "The server rejected fast travel (response " .. tostring(result2) .. ").", { responseCode = result2 })
							return
						end
						local v18 = tbl19
						tbl19.owned = true
						v18.source = "ServerAccepted"
						local v19 = tbl19
						tbl19.checkedAt = os.clock()
						v19.lastError = nil
						local v20 = tbl20
						tbl20.ownershipSource = "ServerAccepted"
						v20.ownershipError = nil
						active.phase = "Arriving"
						local n21 = os.clock() + 12
						local v21 = fn18()
						while tbl20.active == active and not active.cancelled and os.clock() < n21 and v21 ~= active.islandId do
							task.wait(0.1)
							v21 = fn18()
						end
						if tbl20.active ~= active or active.cancelled then
							return
						end
						if v21 ~= active.islandId then
							fn47(false, "Native fast travel was not confirmed on the expected island.", { responseCode = result2, beforeIslandId = v15, actualIslandId = v21, gate = v17 })
							return
						end
						local v22, v23 = tbl20.placeAt(arg4, active)
						if not v22 then
							fn47(false, v23)
							return
						end
						fn47(true, "Native fast travel confirmed.", { responseCode = result2, beforeIslandId = v15, actualIslandId = v21, gate = v17, placement = v23 })
					end)
					if not ok2 then
						fn47(false, "Native travel error: " .. tostring(result2))
					end
				end)
				return true
			end,
			Cancel = function()
				local active = tbl20.active
				if not active then
					return false
				end
				active.cancelled = true
				tbl20.active = nil
				flag20 = false
				tbl20.lastResult = { success = false, message = "Island travel cancelled.", islandId = active.islandId }
				if type(active.callback) == "function" then
					task.defer(function()
						pcall(active.callback, false, "Island travel cancelled.")
					end)
				end
				return true
			end,
			GetStatus = function()
				return {
					active = tbl20.active ~= nil,
					islandId = tbl20.active and tbl20.active.islandId,
					phase = tbl20.active and tbl20.active.phase,
					serverIslandId = tbl20.active and tbl20.active.serverIslandId,
					movementMethod = tbl20.movementMethod,
					sessionMovementMethod = tbl20.active and tbl20.active.movementMethod,
					tweenSpeed = tbl20.tweenSpeed,
					gamepassId = n19,
					ownership = tbl19.owned,
					ownershipSource = tbl20.active and tbl20.active.ownershipSource or tbl20.ownershipSource,
					ownershipError = tbl20.ownershipError,
					lastResult = tbl20.lastResult,
				}
			end,
		}
		return tbl20
	end
	local Island = fn46("Island")
	tbl6.nativeIslandTravel = Island
	genv.HuneHubFishingMaster.NativeIslandTravel = Island
	local method = "Fast Travel Gamepass"
	local method2 = "Ngao Island"
	local method3 = "Ngao Island"
	local v11 = nil
	local v12 = nil
	genv.HuneHubFishingMaster.GetIslandTravelStatus = function()
		local v13 = v10.GetStatus()
		local flag29 = Island.GetStatus()
		if v13.active then
			v13.method = method2
			return v13
		end
		if flag29.active then
			flag29.method = method
			return flag29
		end
		flag29 = method3 == method and flag29 or v13
		flag29.method = method3
		return flag29
	end
	local function fn47()
		local v13 = fn6()
		if v13 then
			cFrame3 = v13.CFrame
			cFrame2 = flag19 and cFrame3 or nil
			tbl6.farmSpotPending = false
			local n20 = os.clock() + 0.5
			v3 = nil
			n17 = n20
		end
	end
	local function fn48()
		if tbl6.isBossAutomationBusy and tbl6.isBossAutomationBusy() then
			lib:Notify({
				Title = text("Auto Boss"),
				Content = text("Wait for Auto Boss to return before island travel."),
				Duration = 4,
			})
			return false
		end
		if genv.HuneHubFishingMaster.GetQuestStatus and genv.HuneHubFishingMaster.GetQuestStatus().autoQuest then
			lib:Notify({
				Title = text("Auto Quest"),
				Content = text("Turn off Auto Quest before manual island travel."),
				Duration = 4,
			})
			return false
		end
		return true
	end
	TeleTab:Section({ Title = text("Island") })
	TeleTab:Dropdown({
		Title = text("Select Island"),
		Values = tbl4,
		Default = str4,
		Multi = false,
		Flag = "SelectedIsland",
		Callback = function(arg)
			str4 = arg
		end,
	})
	TeleTab:Dropdown({
		Title = text("Boat Type"),
		Values = { "Truck", "Red Truck" },
		Value = "Truck",
		Default = "Truck",
		Multi = false,
		Flag = "IslandBoatType",
		Callback = function(arg)
			v10.settings.boatId = arg == "Red Truck" and "red_truck" or "truck"
		end,
	})
	TeleTab:Toggle({
		Title = text("Player Mode (Beta)"),
		Value = false,
		Flag = "NgaoIslandPlayerMode",
		Callback = function(arg)
			local v13, v14 = v10.SetPlayerMode(arg == true)
			if not v13 then
				lib:Notify({ Title = text("Player Mode (Beta)"), Content = tostring(v14), Duration = 3 })
			end
		end,
	})
	local v13 = TeleTab:Paragraph({ Title = text("Island Status"), Desc = text("Ready") })
	task.spawn(function()
		while flag do
			task.wait(0.5)
			if v13 and v13.SetDesc then
				local v14 = v10.GetStatus()
				local active = v14.active
				if active then
					active = text("Running: ") .. tostring(v14.phase) .. " (" .. tostring(v14.attempt or 1) .. "/3)"
				end
				local Ready = active or v14.lastError and text("Last error: ") .. tostring(v14.lastError) or text("Ready")
				pcall(function()
					v13:SetDesc(Ready)
				end)
			end
		end
	end)
	v11 = TeleTab:Toggle({
		Title = text("Auto Island"),
		Value = false,
		Flag = "AutoNgaoIsland",
		Callback = function(arg)
			if not arg then
				if v12 then
					v10.Cancel()
				end
				return
			end
			local function fn49()
				if type(setthreadidentity) == "function" then
					pcall(setthreadidentity, 8)
				end
				if v11 then
					v11:Set(false)
				end
			end
			if not fn48() then
				task.defer(fn49)
				return
			end
			local v14 = str4
			local tbl20 = {}
			local v15 = method2
			v12 = tbl20
			method3 = v15
			local v16, v17 = v10.Start(v14, function(content, arg2)
				if v12 ~= tbl20 then
					return
				end
				v12 = nil
				if not flag then
					return
				end
				if content then
					fn47()
				end
				fn49()
				local v16 = lib
				local notify = v16.Notify
				local tbl21 = { Title = content and text("Travel Complete") or text("Travel Failed") }
				if content then
					local str5 = v14 .. "."
					content = text("Arrived at ") .. str5
				end
				tbl21.Content = content or tostring(arg2)
				tbl21.Duration = 4
				notify(v16, tbl21)
			end, nil, false, { maxAttempts = 3, waitForIdle = true })
			if not v16 then
				v12 = nil
				task.defer(fn49)
				lib:Notify({ Title = text("Travel Failed"), Content = tostring(v17), Duration = 4 })
			end
		end,
	})
	TeleTab:Section({ Title = text("Fast Travel Gamepass") })
	TeleTab:Button({
		Title = text("Travel To Island (Gamepass)"),
		Callback = function()
			if not fn48() then
				return
			end
			local v14 = str4
			local v15 = getIslandLandingPosition(v14)
			method3 = method
			local start = Island.Start
			local function fn49(content, arg)
				if not flag then
					return
				end
				if content then
					fn47()
				end
				local v16 = lib
				local notify = v16.Notify
				local tbl20 = { Title = content and text("Travel Complete") or text("Travel Failed") }
				if content then
					local str5 = v14 .. "."
					content = text("Arrived at ") .. str5
				end
				tbl20.Content = content or tostring(arg)
				tbl20.Duration = 4
				notify(v16, tbl20)
			end
			local v16, v17 = start(v14, fn49, v15 and CFrame.new(v15))
			if not v16 then
				lib:Notify({ Title = text("Travel Failed"), Content = tostring(v17), Duration = 4 })
			end
		end,
	})
	TeleTab:Dropdown({
		Title = text("Gamepass Local Movement"),
		Values = { "Walk", "Tween" },
		Value = "Walk",
		Default = "Walk",
		Multi = false,
		Flag = "GamepassLocalMovementMethod",
		Callback = function(arg)
			Island.SetMovementMethod(arg)
		end,
	})
	TeleTab:Slider({
		Title = text("Gamepass Tween Speed (Studs/Second)"),
		Value = { Min = 20, Max = 70, Default = 30 },
		Step = 1,
		Flag = "GamepassLocalTweenSpeed",
		Callback = function(arg)
			local num = tonumber(arg)
			if num then
				Island.tweenSpeed = math.clamp(num, 20, 70)
			end
		end,
	})
	TeleTab:Button({
		Title = text("Stop Island Travel"),
		Callback = function()
			v10.Cancel()
			Island.Cancel()
			if v11 then
				v11:Set(false)
			end
		end,
	})
end
fn41()
local function fn42()
	local RegionConfig = require(data.Config.RegionConfig)
	local BossSpawnerFX = require(ReplicatedStorage.Shared.Lib.BossSpawnerFX)
	local v10 = assert(tbl6.getIslandLandingPosition)
	local v11 = nil
	local tbl16
	tbl16 = {
		observations = {},
		probes = {},
		lastStream = {},
		generation = 0,
		espRecords = {},
		regionWatchers = {},
		notifiedEffects = {},
		lastNotifiedAt = {},
		notifyEnabled = false,
		espEnabled = false,
		lastWorldScanAt = -math.huge,
		inactivePending = {},
		knownRegions = {},
		nextEpisode = 0,
		caughtRegions = {},
		effectVisuals = setmetatable({}, { __mode = "k" }),
		finishedEffects = setmetatable({}, { __mode = "k" }),
		fishConfig = require(data.Config.FishConfig),
		events = require(ReplicatedStorage.Controllers.EventController),
		zoneIcon = str,
		bossFish = function(arg)
			if type(arg) ~= "string" or arg == "" then
				return nil
			end
			local v12 = Catalog.Fish.GetById(arg)
			return v12 and v12.id == arg and v12.kind == "Boss" and v12 or nil
		end,
		captureSpawnPool = function()
			local ok, result = pcall(function()
				return tbl16.events:GetActiveEvents()
			end)
			if not ok or type(result) ~= "table" or not Catalog.Boss then
				return nil
			end
			local serverTimeNow = workspace:GetServerTimeNow()
			local id = nil
			local v12 = nil
			for k, v13 in pairs(result) do
				local flag27 = type(v13) == "table"
				if flag27 then
					flag27 = math.max(type(v13.expire_at) == "number" and v13.expire_at or 0, type(v13.admin_override_expire_at) == "number" and v13.admin_override_expire_at or 0)
				end
				local v14 = Catalog.Boss.GetPool(k)
				if v14 and type(flag27) == "number" and flag27 > serverTimeNow and (type(v13.started_at) ~= "number" or v13.started_at <= serverTimeNow) then
					for _, v15 in ipairs(v14) do
						if type(v15.weight) == "number" and v15.weight > 0 then
							if not tbl16.bossFish(v15.id) or id and id ~= v15.id then
								return nil
							end
							id = v15.id
							v12 = k
						end
					end
				end
			end
			return id, v12
		end,
		applySpawnPool = function(arg, poolFishId, poolWeatherId)
			if arg.identityConflict or arg.fishConfirmed or arg.poolFishId then
				return
			end
			local spawnPool = tbl16.spawnPool
			if spawnPool and spawnPool.fishId and arg.firstSeenAt and arg.firstSeenAt >= spawnPool.at - 0.75 and arg.firstSeenAt - spawnPool.at <= 15 then
				local fishId = spawnPool.fishId
				local weatherId = spawnPool.weatherId
				arg.poolFishId = fishId
				arg.poolWeatherId = weatherId
				arg.poolSource = "spawn"
			elseif not arg.poolInitialized then
				arg.poolInitialized = true
				if tbl16.bossFish(poolFishId) then
					arg.poolFishId = poolFishId
					arg.poolWeatherId = poolWeatherId
					arg.poolSource = "weather"
				end
			end
		end,
		fishIcon = function(arg)
			local v12 = tbl16.bossFish(arg)
			v12 = v12 and tbl16.fishConfig[v12.id]
			return v12 and type(v12.icon) == "string" and v12.icon or ""
		end,
		containsTarget = function(arg, arg2)
			if not arg or not arg:IsDescendantOf(workspace) or typeof(arg2) ~= "Vector3" then
				return false
			end
			for _, v12 in ipairs({ arg2.X, arg2.Y, arg2.Z }) do
				if v12 ~= v12 or math.abs(v12) == math.huge then
					return false
				end
			end
			local v12 = arg.CFrame:PointToObjectSpace(arg2)
			local n19 = arg.Size * 0.5
			local x = n19.X
			local flag27 = math.abs(v12.X) <= x
			local flag28
			if flag27 then
				local y = n19.Y
				flag28 = math.abs(v12.Y) <= y
			else
				flag28 = flag27
			end
			if flag28 then
				local z = n19.Z
				flag28 = math.abs(v12.Z) <= z
			end
			return flag28
		end,
		nativeFish = function()
			local FishingController2 = FishingController
			local flag27 = not FishingController2
			if flag27 then
				pcall(function()
					FishingController2 = client.GetController("FishingController")
				end)
			end
			if flag27 then
				return nil
			end
			local ok, result, result2 = pcall(function()
				local getState = FishingController2.GetState
				return FishingController2:GetFishInfo(), getState(FishingController2)
			end)
			if ok and type(result) == "string" and result ~= "" then
				return result, result2
			end
			return nil
		end,
		nativeCastRegion = function()
			local v12 = tbl8:getBossCastFunctions()
			local getupvalues_ = getupvalues or debug and debug.getupvalues
			if not v12 or not getupvalues_ then
				return nil
			end
			local ok, result = pcall(getupvalues_, v12.submit)
			if not ok then
				return nil
			end
			local v13 = nil
			for _, v14 in pairs(result) do
				if typeof(v14) == "Instance" and v14:IsA("BasePart") and v14:IsDescendantOf(workspace) and CollectionService:HasTag(v14, RegionConfig.BossTag) then
					if v13 and v13 ~= v14 then
						return nil
					end
					v13 = v14
				end
			end
			return v13
		end,
		setIdentity = function(arg, fishId, arg2)
			if not tbl16.bossFish(fishId) then
				return false
			end
			if arg2 then
				arg.fishId = fishId
				arg.fishConfirmed = true
				arg.ownFishConfirmed = true
			elseif not arg.ownFishConfirmed then
				if arg.identityConflict or arg.fishConfirmed and arg.fishId ~= fishId then
					arg.fishId = nil
					arg.fishConfirmed = false
					arg.identityConflict = true
				else
					arg.fishId = fishId
					arg.fishConfirmed = true
				end
			end
			arg.identityEffect = arg.effect
			tbl16.showEsp(arg)
			return true
		end,
		clearIdentity = function(arg)
			arg.fishId = nil
			arg.fishConfirmed = nil
			arg.ownFishConfirmed = nil
			arg.identityConflict = nil
			arg.identityEffect = nil
		end,
		syncLocalIdentity = function()
			local v12, v13 = tbl16.nativeFish()
			if not tbl16.bossFish(v12) then
				return false
			end
			if v13 == FishingEnums.State.Caught or v13 == FishingEnums.State.Escaped then
				for _, observation in pairs(tbl16.observations) do
					local pendingResult = observation.encounter and observation.encounter.pendingResult
					if pendingResult and pendingResult.fishId == v12 then
						tbl16.onCatchResult(pendingResult.success, pendingResult.fishId, true)
					end
				end
				return false
			end
			if v13 ~= FishingEnums.State.FirstPull and v13 ~= FishingEnums.State.Reeling then
				return false
			end
			local v14 = tbl16.nativeCastRegion()
			local attribute = v14 and v14:GetAttribute(RegionConfig.BossAttribute)
			local v15 = attribute and tbl16.observations[attribute]
			local v16 = v14 and BossSpawnerFX.GetForRegion(v14)
			if not v15 or v15.region ~= v14 or not v16 or not BossSpawnerFX.IsActive(v16) or tbl16.caughtRegions[attribute] or tbl16.finishedEffects[v16] then
				return false
			end
			if v15.fishId ~= v12 or not v15.ownFishConfirmed then
				tbl16.setIdentity(v15, v12, true)
			end
			if not v15.encounter or v15.encounter.fishId ~= v12 then
				v15.encounterFishId = v12
				v15.encounter = {
					fishId = v12,
					episode = v15.episode,
					region = v14,
					character = localPlayer.Character,
					resultProcessed = false,
				}
			end
			return true
		end,
		effectVisible = function(arg)
			if not arg then
				return nil
			end
			local v12 = tbl16.effectVisuals[arg]
			if not v12 then
				local tbl17 = {}
				for _, descendant in ipairs(arg:GetDescendants()) do
					if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
						tbl17[#tbl17 + 1] = descendant
					end
				end
				tbl16.effectVisuals[arg] = tbl17
				v12 = tbl17
			end
			local flag27 = false
			for _, v13 in ipairs(v12) do
				if v13:IsDescendantOf(arg) then
					flag27 = true
					if v13.Enabled then
						return true
					end
				end
			end
			if flag27 then
				return false
			end
			return nil
		end,
		effectActive = function(arg, arg2)
			if not arg or not arg:IsDescendantOf(workspace) or not arg2 or BossSpawnerFX.GetForRegion(arg) ~= arg2 or not BossSpawnerFX.IsActive(arg2) or tbl16.caughtRegions[arg:GetAttribute(RegionConfig.BossAttribute)] then
				return false
			end
			if tbl16.effectVisible(arg2) == true then
				tbl16.finishedEffects[arg2] = nil
				return true
			end
			if tbl16.finishedEffects[arg2] then
				return false
			end
			return false
		end,
		finishEffect = function(arg, arg2, arg3)
			local v12 = tbl16.observations[arg]
			if not v12 or v12.effect ~= arg2 then
				return
			end
			if arg2 then
				tbl16.finishedEffects[arg2] = true
			end
			tbl16.deactivate(arg, arg3)
		end,
		onCatchResult = function(arg, arg2, arg3)
			if type(arg) ~= "boolean" or not tbl16.bossFish(arg2) then
				return false
			end
			local v12 = nil
			for _, observation in pairs(tbl16.observations) do
				local encounter = observation.encounter
				if encounter and not encounter.resultProcessed and encounter.fishId == arg2 and encounter.character == localPlayer.Character and encounter.episode == observation.episode and encounter.region == observation.region then
					if v12 then
						return false
					end
					v12 = observation
				end
			end
			if not v12 then
				return false
			end
			local encounter = v12.encounter
			local v13, v14 = tbl16.nativeFish()
			if v13 ~= arg2 or v14 ~= (arg and FishingEnums.State.Caught or FishingEnums.State.Escaped) then
				if v13 == arg2 then
					encounter.pendingResult = { success = arg, fishId = arg2 }
				end
				if not arg3 then
					task.defer(function()
						if flag and v12.encounter == encounter then
							tbl16.onCatchResult(arg, arg2, true)
						end
					end)
				end
				return false
			end
			encounter.resultProcessed = true
			v12.encounterFishId = nil
			v12.encounter = nil
			if arg then
				tbl16.caughtRegions[v12.id] = true
				tbl16.finishEffect(v12.id, v12.effect, "Boss caught.")
			else
				tbl16.queueRefresh()
			end
			return true
		end,
		resetEncounter = function()
			for _, observation in pairs(tbl16.observations) do
				observation.encounterFishId = nil
				observation.encounter = nil
			end
		end,
		confirmFishAt = function(arg, arg2, arg3, arg4)
			if arg4 ~= FishingEnums.RemotePhase.Fight or typeof(arg3) ~= "Instance" or not arg3:IsA("Model") or not arg3:IsDescendantOf(workspace) or not tbl16.bossFish(arg2) then
				return false
			end
			local playerFromCharacter = Players:GetPlayerFromCharacter(arg3)
			if not playerFromCharacter or playerFromCharacter.Character ~= arg3 then
				return false
			end
			tbl16.observe()
			local v12 = nil
			for _, observation in pairs(tbl16.observations) do
				local region = observation.region
				if tbl16.containsTarget(region, arg) then
					local v13 = BossSpawnerFX.GetForRegion(region)
					if v13 and BossSpawnerFX.IsActive(v13) and not tbl16.finishedEffects[v13] and not tbl16.caughtRegions[observation.id] then
						if v12 then
							return false
						end
						v12 = observation
					end
				end
			end
			if not v12 then
				return false
			end
			return tbl16.setIdentity(v12, arg2, false)
		end,
		isInterested = function()
			return tbl16.notifyEnabled or tbl16.espEnabled
		end,
		observe = function()
			local now3 = os.clock()
			local v12, v13 = tbl16.captureSpawnPool()
			for _, v14 in ipairs(CollectionService:GetTagged(RegionConfig.BossTag)) do
				if v14:IsA("BasePart") and v14:IsDescendantOf(workspace) then
					local attribute = v14:GetAttribute(RegionConfig.BossAttribute)
					local flag27 = type(attribute) == "string" and Catalog.BossRegion.GetById(attribute)
					local v15 = flag27 and BossSpawnerFX.GetForRegion(v14)
					if flag27 then
						tbl16.knownRegions[attribute] = { position = v14.Position, islandId = flag27.fallbackIslandId }
					end
					if v15 then
						local v16 = tbl16.effectVisible(v15)
						if BossSpawnerFX.IsActive(v15) and v16 == true and not tbl16.caughtRegions[attribute] then
							tbl16.finishedEffects[v15] = nil
						end
						if BossSpawnerFX.IsActive(v15) and not tbl16.finishedEffects[v15] and not tbl16.caughtRegions[attribute] then
							tbl16.inactivePending[attribute] = nil
							local tbl17 = tbl16.observations[attribute]
							if not tbl17 then
								tbl16.nextEpisode = tbl16.nextEpisode + 1
								tbl17 = {
									id = attribute,
									islandId = flag27.fallbackIslandId,
									firstSeenAt = now3,
									episode = tbl16.nextEpisode,
								}
								tbl16.observations[attribute] = tbl17
							end
							if tbl17 then
								if tbl17.identityEffect and tbl17.identityEffect ~= v15 then
									tbl16.clearIdentity(tbl17)
								end
								tbl17.position = v15.Position
								tbl17.region = v14
								tbl17.effect = v15
								tbl17.seenAt = now3
								tbl16.applySpawnPool(tbl17, v12, v13)
							end
						elseif v15:GetAttribute(BossSpawnerFX.ActiveAttribute) == false then
							tbl16.finishedEffects[v15] = nil
							tbl16.caughtRegions[attribute] = nil
							local v17 = tbl16.observations[attribute]
							if v17 and v17.region == v14 and v17.effect == v15 then
								tbl16.deactivate(attribute)
							elseif v17 then
								local v18 = tbl16.inactivePending[attribute]
								if not v18 or v18.effect ~= v15 then
									local tbl17 = { effect = v15, region = v14, at = now3 }
									tbl16.inactivePending[attribute] = tbl17
									task.delay(1.1, function()
										if flag and tbl16.inactivePending[attribute] == tbl17 then
											tbl16.queueRefresh()
										end
									end)
								elseif now3 - v18.at >= 1 then
									tbl16.deactivate(attribute)
								end
							end
						elseif tbl16.observations[attribute] then
							tbl16.markUnloaded(attribute, v14, v15)
						end
					end
				end
			end
		end,
		probe = function(arg)
			if tbl16.probes[arg] then
				return tbl16.probes[arg]
			end
			local v12 = Catalog.Island.GetById(arg)
			local v13 = v12 and v10(v12.name)
			if v13 then
				tbl16.probes[arg] = v13
				return v13
			end
			local v14 = fn19(arg)
			if v14 then
				tbl16.probes[arg] = v14.Position
				return v14.Position
			end
			local v15 = ipairs
			local v16 = table.pack(CollectionService:GetTagged(RegionConfig.IslandTag))
			v16.n = 1 + v16.n - 1
			table.move(v16, 1, v16.n, 1, v16)
			for _, v17 in v15(table.unpack(v16, 1, v16.n)) do
				if v17:IsA("BasePart") and v17:GetAttribute(RegionConfig.IslandAttribute) == arg then
					tbl16.probes[arg] = v17.Position
					return v17.Position
				end
			end
			local world = workspace:FindFirstChild("World")
			world = world and world:FindFirstChild("Islands")
			world = world and world:FindFirstChild(arg)
			if world and world:IsA("Model") and world:FindFirstChildWhichIsA("BasePart", true) then
				tbl16.probes[arg] = world:GetPivot().Position
			end
			return tbl16.probes[arg]
		end,
	}
	local function fn43(arg, arg2)
		if not arg then
			tbl16.observe()
		end
		local humanoidRootPart = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
		local huge = math.huge
		local v12 = nil
		for k, observation in pairs(tbl16.observations) do
			if not arg2 or arg2(observation) then
				local region = observation.region
				local v13 = region and region:IsDescendantOf(workspace) and BossSpawnerFX.GetForRegion(region)
				if tbl16.effectActive(region, v13, false) then
					local magnitude = humanoidRootPart and (humanoidRootPart.Position - observation.position).Magnitude or 0
					if magnitude < huge then
						huge = magnitude
						v12 = observation
					end
				elseif v13 and BossSpawnerFX.IsActive(v13) then
					if not tbl16.finishedEffects[v13] and tbl16.effectVisible(v13) == nil then
						local magnitude = humanoidRootPart and (humanoidRootPart.Position - observation.position).Magnitude or 0
						if magnitude < huge then
							huge = magnitude
							v12 = observation
						end
					end
				else
					tbl16.markUnloaded(k, region, v13)
					local magnitude = humanoidRootPart and (humanoidRootPart.Position - observation.position).Magnitude or 0
					if magnitude < huge then
						huge = magnitude
						v12 = observation
					end
				end
			end
		end
		return v12
	end
	local now3 = nil
	local str4 = "Not detected"
	local str5 = "None"
	local str6 = "None"
	local str7 = "Boss radar is waiting for a spawn signal."
	local now4 = nil
	tbl16.clearEsp = function(arg)
		local v12 = tbl16.espRecords[arg]
		if not v12 then
			return
		end
		tbl16.espRecords[arg] = nil
		if v12.gui then
			v12.gui:Destroy()
		end
		if v12.anchor then
			v12.anchor:Destroy()
		end
	end
	tbl16.markUnloaded = function(arg, arg2, arg3)
		if arg2 and arg3 and arg2:IsDescendantOf(workspace) then
			local v12 = BossSpawnerFX.GetForRegion(arg2)
			if v12 and v12 ~= arg3 then
				return
			end
		end
		local v12 = tbl16.observations[arg]
		if v12 and (not arg2 or v12 and v12.region == arg2) then
			v12.region = nil
			v12.effect = nil
		end
		local v13 = tbl16.espRecords[arg]
		if v13 and v12 and v12.position and v13.anchor and v13.anchor.Parent then
			v13.anchor.Position = v12.position
			v13.effect = nil
		end
	end
	tbl16.deactivate = function(arg)
		if not tbl16.observations[arg] and not tbl16.notifiedEffects[arg] and not tbl16.espRecords[arg] then
			return
		end
		tbl16.observations[arg] = nil
		tbl16.inactivePending[arg] = nil
		tbl16.notifiedEffects[arg] = nil
		tbl16.clearEsp(arg)
		if v11 and v11.id == arg then
			v11 = nil
		end
		now4 = os.time()
		str7 = "Boss marker cleared. Waiting for a spawn signal."
	end
	tbl16.distanceText = function(arg, arg2, arg3, arg4, arg5)
		local n19 = arg5 or fn6()
		n19 = n19 and math.floor((n19.Position - arg.Position).Magnitude + 0.5)
		return text(arg4 and "LAST SEEN: " or "BOSS: ") .. arg2 .. "\n" .. arg3 .. " | " .. (n19 and n19 .. text(" studs") or text("Distance unavailable")), n19
	end
	tbl16.startDistanceLoop = function()
		if tbl16.distanceConnection then
			return
		end
		local n19 = 0
		tbl16.distanceConnection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
			if not flag or not tbl16.espEnabled or not next(tbl16.espRecords) then
				if tbl16.distanceConnection then
					tbl16.distanceConnection:Disconnect()
				end
				tbl16.distanceConnection = nil
				return
			end
			n19 += deltaTime
			if n19 < 0.05 then
				return
			end
			n19 = 0
			local humanoidRootPart = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
			for k, espRecord in pairs(tbl16.espRecords) do
				if espRecord.gui.Parent ~= localPlayer:FindFirstChildOfClass("PlayerGui") or not espRecord.anchor.Parent or not espRecord.label.Parent or not espRecord.image.Parent or not espRecord.distanceLabel.Parent or not espRecord.note.Parent then
					local v12 = tbl16.observations[k]
					tbl16.clearEsp(k)
					if v12 then
						tbl16.showEsp(v12)
					end
				else
					if espRecord.gui.Adornee ~= espRecord.anchor then
						espRecord.gui.Adornee = espRecord.anchor
					end
					if not espRecord.gui.Enabled then
						espRecord.gui.Enabled = true
					end
					if tbl16.espRecords[k] == espRecord then
						pcall(tbl16.renderEsp, k, espRecord, humanoidRootPart, 0.05)
					end
				end
			end
		end)
	end
	tbl16.renderEsp = function(arg, arg2, arg3, arg4)
		local v12 = tbl16.observations[arg]
		if not v12 then
			tbl16.clearEsp(arg)
			return
		end
		local region = v12.region
		local v13 = region and region:IsDescendantOf(workspace) and BossSpawnerFX.GetForRegion(region)
		if v13 and BossSpawnerFX.IsActive(v13) and not tbl16.caughtRegions[arg] and not tbl16.finishedEffects[v13] then
			v12.position = v13.Position
			arg2.effect = v13
			arg2.anchor.Position = v13.Position
		else
			arg2.effect = nil
			if v12.position then
				arg2.anchor.Position = v12.position
			end
		end
		local fishConfirmed = v12.fishConfirmed and tbl16.bossFish(v12.fishId)
		local flag27 = not v12.identityConflict and tbl16.bossFish(v12.poolFishId)
		local v14 = fishConfirmed or flag27
		local zoneIcon = v14 and tbl16.fishIcon(v14.id) or tbl16.zoneIcon
		if arg2.image.Image ~= zoneIcon then
			arg2.image.Image = zoneIcon
		end
		arg2.image.Visible = zoneIcon ~= ""
		local name = v14 and v14.name or arg2.bossName or text("Boss Encounter")
		if arg2.label.Text ~= name then
			arg2.label.Text = name
		end
		local distanceUnavailable = text("Distance unavailable")
		if arg3 then
			local magnitude = (arg3.Position - arg2.anchor.Position).Magnitude
			local displayDistance = arg2.displayDistance or magnitude
			arg2.displayDistance = displayDistance + (magnitude - displayDistance) * (1 - math.exp(-arg4 / 0.1))
			if math.abs(arg2.displayDistance - magnitude) < 0.1 then
				arg2.displayDistance = magnitude
			end
			distanceUnavailable = math.floor(arg2.displayDistance + 0.5) .. text(" studs")
		else
			arg2.displayDistance = nil
		end
		if arg2.distanceLabel.Text ~= distanceUnavailable then
			arg2.distanceLabel.Text = distanceUnavailable
		end
		local flag28 = arg2.effect == nil
		local str8
		if flag28 then
			local floor = math.floor
			local seenAt = v12.seenAt
			str8 = text("Last Seen") .. " · " .. floor(os.clock() - seenAt) .. "s"
		else
			str8 = flag28
		end
		local v15
		if str8 then
			v15 = str8
		else
			v15 = text(fishConfirmed and (v12.ownFishConfirmed and "Your Boss Confirmed" or "Observed Boss") or flag27 and (v12.poolSource == "weather" and "Weather Preview" or "Spawn Preview") or "Boss Zone Active")
		end
		if arg2.note.Text ~= v15 then
			arg2.note.Text = v15
		end
		fishConfirmed = not flag28 and fishConfirmed and Color3.fromRGB(94, 236, 170) or Color3.fromRGB(255, 202, 99)
		if arg2.note.TextColor3 ~= fishConfirmed then
			arg2.note.TextColor3 = fishConfirmed
		end
	end
	tbl16.showEsp = function(arg)
		if not tbl16.espEnabled then
			return
		end
		local region = arg.region
		local v12 = region and region:IsDescendantOf(workspace) and BossSpawnerFX.GetForRegion(region)
		if not (v12 and BossSpawnerFX.IsActive(v12) and not tbl16.caughtRegions[arg.id] and not tbl16.finishedEffects[v12]) then
			v12 = nil
		end
		local position = v12 and v12.Position or arg.position
		if not position then
			return
		end
		local v13 = tbl16.espRecords[arg.id]
		local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
		if v13 and v13.gui.Parent == playerGui and v13.anchor.Parent and v13.label.Parent and v13.image.Parent and v13.distanceLabel.Parent and v13.note.Parent then
			v13.anchor.Position = position
			v13.effect = v12
			v13.gui.Enabled = true
			tbl16.renderEsp(arg.id, v13, localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart"), 0.05)
			tbl16.startDistanceLoop()
			return
		end
		tbl16.clearEsp(arg.id)
		local name = Catalog.BossRegion.GetById(arg.id)
		local name2 = name and Catalog.Island.GetById(name.fallbackIslandId)
		name = name and name.name or arg.id
		name2 = name2 and name2.name or "Unknown Island"
		if not playerGui then
			return
		end
		local part = Instance.new("Part")
		part.Name = "HuneHubBossESPAnchor"
		part.Size = Vector3.one
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Transparency = 1
		part.Position = position
		part.Parent = workspace
		local billboardGui = Instance.new("BillboardGui")
		billboardGui.Name = "HuneHubBossESP"
		pcall(function()
			billboardGui.ResetOnSpawn = false
		end)
		billboardGui.Adornee = part
		billboardGui.AlwaysOnTop = true
		billboardGui.LightInfluence = 0
		billboardGui.MaxDistance = 0
		billboardGui.Size = UDim2.fromOffset(228, 136)
		billboardGui.StudsOffsetWorldSpace = Vector3.new(0, 8, 0)
		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundColor3 = Color3.fromRGB(15, 26, 35)
		frame.BackgroundTransparency = 0.04
		frame.BorderSizePixel = 0
		frame.Parent = billboardGui
		local uiCorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(0, 12)
		uiCorner.Parent = frame
		local uiStroke = Instance.new("UIStroke")
		uiStroke.Color = Color3.fromRGB(94, 236, 170)
		uiStroke.Transparency = 0.35
		uiStroke.Parent = frame
		local uiGradient = Instance.new("UIGradient")
		local color2 = Color3.fromRGB
		uiGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), color2(160, 182, 196))
		uiGradient.Rotation = 90
		uiGradient.Parent = frame
		local textLabel = Instance.new("TextLabel")
		textLabel.Name = "HubTitle"
		textLabel.Position = UDim2.fromOffset(10, 7)
		textLabel.Size = UDim2.new(1, -20, 0, 16)
		textLabel.BackgroundTransparency = 1
		textLabel.Font = Enum.Font.GothamBold
		textLabel.TextSize = 11
		textLabel.TextColor3 = Color3.fromRGB(124, 246, 199)
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.Text = "LunarX Hub"
		textLabel.Parent = frame
		local frame2 = Instance.new("Frame")
		frame2.Name = "BossPortrait"
		frame2.Position = UDim2.fromOffset(8, 29)
		frame2.Size = UDim2.fromOffset(78, 68)
		frame2.BackgroundColor3 = Color3.fromRGB(23, 41, 51)
		frame2.BackgroundTransparency = 0.12
		frame2.BorderSizePixel = 0
		frame2.Parent = frame
		local uiCorner2 = Instance.new("UICorner")
		uiCorner2.CornerRadius = UDim.new(0, 8)
		uiCorner2.Parent = frame2
		local imageLabel = Instance.new("ImageLabel")
		imageLabel.Name = "BossFishImage"
		imageLabel.BackgroundTransparency = 1
		imageLabel.Position = UDim2.fromOffset(9, 29)
		imageLabel.Size = UDim2.fromOffset(76, 68)
		imageLabel.ScaleType = Enum.ScaleType.Fit
		imageLabel.Parent = frame
		local textLabel2 = Instance.new("TextLabel")
		textLabel2.Name = "BossLocation"
		textLabel2.Position = UDim2.fromOffset(92, 32)
		textLabel2.Size = UDim2.fromOffset(128, 34)
		textLabel2.BackgroundTransparency = 1
		textLabel2.TextColor3 = Color3.fromRGB(248, 252, 255)
		textLabel2.TextStrokeColor3 = Color3.fromRGB(4, 10, 15)
		textLabel2.TextStrokeTransparency = 0.35
		textLabel2.TextSize = 14
		textLabel2.TextWrapped = true
		textLabel2.Font = Enum.Font.GothamBold
		textLabel2.Text = ""
		textLabel2.Parent = frame
		local clone = textLabel2:Clone()
		clone.Name = "BossDistance"
		clone.Position = UDim2.fromOffset(92, 72)
		clone.Size = UDim2.fromOffset(128, 22)
		clone.TextColor3 = Color3.fromRGB(124, 246, 199)
		clone.TextSize = 16
		clone.Parent = frame
		local clone2 = textLabel2:Clone()
		clone2.Name = "BossRegion"
		clone2.Position = UDim2.fromOffset(8, 103)
		clone2.Size = UDim2.new(1, -16, 0, 14)
		clone2.TextColor3 = Color3.fromRGB(188, 207, 218)
		clone2.TextStrokeTransparency = 0.7
		clone2.TextSize = 10
		clone2.TextWrapped = false
		clone2.TextTruncate = Enum.TextTruncate.AtEnd
		clone2.Font = Enum.Font.Gotham
		clone2.Text = name .. " | " .. name2
		clone2.Parent = frame
		local clone3 = clone2:Clone()
		clone3.Name = "BossStatus"
		clone3.Position = UDim2.fromOffset(8, 119)
		clone3.Size = UDim2.new(1, -16, 0, 13)
		clone3.Font = Enum.Font.GothamMedium
		clone3.Text = ""
		clone3.Parent = frame
		billboardGui.Parent = playerGui
		local tbl17 = {
			effect = v12,
			anchor = part,
			gui = billboardGui,
			label = textLabel2,
			image = imageLabel,
			distanceLabel = clone,
			note = clone3,
			bossName = name,
			islandName = name2,
		}
		tbl16.espRecords[arg.id] = tbl17
		tbl16.renderEsp(arg.id, tbl17, localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart"), 0.05)
		tbl16.startDistanceLoop()
	end
	tbl16.announce = function(arg, arg2)
		if not tbl16.notifyEnabled or tbl16.notifiedEffects[arg.id] == arg.episode then
			return
		end
		local now5 = os.clock()
		tbl16.notifiedEffects[arg.id] = arg.episode
		tbl16.lastNotifiedAt[arg.id] = now5
		local name = Catalog.BossRegion.GetById(arg.id)
		local v12 = name and Catalog.Island.GetById(name.fallbackIslandId)
		name = name and name.name or arg.id
		local name2 = v12 and v12.name or "Unknown Island"
		local v13, v14 = tbl16.distanceText(arg2, name, name2)
		now3 = os.time()
		str5 = name
		str6 = name2
		now4 = nil
		str7 = "Boss location detected."
		lib:Notify({
			Title = text("Boss Spotted: ") .. name,
			Content = string.format("%s | %s | X: %.0f, Z: %.0f", name2, v14 and v14 .. text(" studs away") or text("Distance unavailable"), arg2.Position.X, arg2.Position.Z),
			Duration = 6,
		})
	end
	tbl16.refreshEsp = function()
		tbl16.observe()
		tbl16.syncLocalIdentity()
		for k in pairs(tbl16.notifiedEffects) do
			if not tbl16.observations[k] then
				tbl16.deactivate(k)
			end
		end
		for k in pairs(tbl16.espRecords) do
			if not tbl16.observations[k] then
				tbl16.deactivate(k)
			end
		end
		for k, observation in pairs(tbl16.observations) do
			local region = observation.region and observation.region:IsDescendantOf(workspace) and BossSpawnerFX.GetForRegion(observation.region)
			if tbl16.effectActive(observation.region, region, false) then
				tbl16.announce(observation, region)
			elseif not region or not BossSpawnerFX.IsActive(region) then
				tbl16.markUnloaded(k, observation.region, region)
			end
			tbl16.showEsp(observation)
		end
		v11 = fn43(true)
	end
	tbl16.queueRefresh = function()
		if tbl16.refreshQueued or not tbl16.isInterested() then
			return
		end
		tbl16.refreshQueued = true
		task.delay(0.15, function()
			tbl16.refreshQueued = false
			if flag and tbl16.isInterested() then
				tbl16.refreshEsp()
			end
		end)
	end
	local fn44 = nil
	fn44 = function(arg)
		if not flag or not tbl16.isInterested() then
			return
		end
		str4 = arg or "Server Broadcast"
		if tbl16.signalScanRunning then
			if arg == "Server Broadcast: BossSpawnSound" then
				tbl16.rescanRequested = true
			end
			return
		end
		tbl16.signalScanRunning = true
		local radarGeneration = tbl16.radarGeneration or 0
		local flag27 = arg == "Server Broadcast: BossSpawnSound" or arg == "Boss Spawn Follow-Up"
		local flag28 = arg == "ESP Enabled" or arg == "Notify Enabled"
		local lastWorldScanAt = tbl16.lastWorldScanAt
		local n19 = 45 - os.clock() - lastWorldScanAt
		local flag29 = (flag27 or flag28) and n19 > 0
		local flag30
		if flag29 then
			flag30 = not tbl16.worldScanQueued or tbl16.worldScanQueued.generation ~= radarGeneration
		else
			flag30 = flag29
		end
		if flag30 then
			local worldScanQueued = { generation = radarGeneration }
			tbl16.worldScanQueued = worldScanQueued
			task.delay(n19 + 0.2, function()
				if tbl16.worldScanQueued ~= worldScanQueued then
					return
				end
				tbl16.worldScanQueued = false
				local flag31 = flag
				if flag then
					flag31 = radarGeneration == (tbl16.radarGeneration or 0)
				end
				if flag31 and tbl16.isInterested() then
					fn44("Boss Spawn Follow-Up")
				end
			end)
		end
		flag27 = (flag27 or flag28) and workspace.StreamingEnabled
		local flag31
		if flag27 then
			local lastWorldScanAt2 = tbl16.lastWorldScanAt
			flag31 = os.clock() - lastWorldScanAt2 >= 45
		else
			flag31 = flag27
		end
		task.spawn(function()
			pcall(function()
				v11 = fn43()
				if flag31 then
					tbl16.lastWorldScanAt = os.clock()
					for _, v12 in ipairs(Catalog.Island.GetAll()) do
						local flag32 = not flag
						local flag33
						if flag32 then
							flag33 = flag32
						else
							flag33 = radarGeneration ~= (tbl16.radarGeneration or 0)
						end
						flag33 = flag33 or not tbl16.isInterested()
						if not flag33 then
							local ok, result = pcall(tbl16.probe, v12.id)
							if ok and result then
								pcall(function()
									localPlayer:RequestStreamAroundAsync(result, 1)
								end)
								tbl16.refreshEsp()
								for _, knownRegion in pairs(tbl16.knownRegions) do
									if not (not flag or not tbl16.isInterested()) then
										if knownRegion.islandId == v12.id and (knownRegion.position - result).Magnitude > 100 then
											pcall(function()
												localPlayer:RequestStreamAroundAsync(knownRegion.position, 1)
											end)
											tbl16.refreshEsp()
											task.wait(0.3)
										end
										continue
									end
									break
								end
							end
							task.wait(3)
							continue
						end
						break
					end
				end
				local flag32 = flag
				if flag then
					flag32 = radarGeneration == (tbl16.radarGeneration or 0)
				end
				if flag32 and tbl16.isInterested() then
					tbl16.refreshEsp()
					if not v11 then
						str7 = "Waiting for a boss spawn signal."
					end
				end
			end)
			tbl16.signalScanRunning = false
			if tbl16.rescanRequested then
				tbl16.rescanRequested = false
				if flag and tbl16.isInterested() then
					task.delay(1, function()
						fn44("Boss Spawn Follow-Up")
					end)
				end
			elseif arg == "Server Broadcast: BossSpawnSound" and not v11 then
				task.delay(2, function()
					local flag32 = flag
					if flag then
						flag32 = radarGeneration == (tbl16.radarGeneration or 0)
					end
					if flag32 and tbl16.isInterested() then
						tbl16.refreshEsp()
					end
				end)
			end
		end)
	end
	tbl16.unwatchRegion = function(arg)
		local v12 = tbl16.regionWatchers[arg]
		if not v12 then
			return
		end
		tbl16.regionWatchers[arg] = nil
		for _, v13 in ipairs({
			"attributeConnection",
			"idConnection",
			"childConnection",
			"removedConnection",
			"destroyConnection",
			"visualAddedConnection",
			"visualRemovedConnection",
		}) do
			if v12[v13] then
				v12[v13]:Disconnect()
			end
		end
		local v13 = pairs
		local visualConnections = v12.visualConnections or {}
		for _, visualConnection in v13(visualConnections) do
			visualConnection:Disconnect()
		end
		local attribute = arg:GetAttribute(RegionConfig.BossAttribute)
		if type(attribute) == "string" then
			tbl16.markUnloaded(attribute, arg, v12.effect)
		end
		tbl16.queueRefresh()
	end
	tbl16.onEffectActivityChanged = function(arg, arg2)
		if not flag then
			return
		end
		tbl16.finishedEffects[arg2] = nil
		local attribute = arg:GetAttribute(RegionConfig.BossAttribute)
		if type(attribute) == "string" and arg2:GetAttribute(BossSpawnerFX.ActiveAttribute) == false then
			tbl16.caughtRegions[attribute] = nil
		end
		local v12 = attribute and tbl16.observations[attribute]
		if v12 and v12.effect == arg2 and arg:IsDescendantOf(workspace) and BossSpawnerFX.GetForRegion(arg) == arg2 and arg2:GetAttribute(BossSpawnerFX.ActiveAttribute) == false then
			tbl16.deactivate(attribute)
		else
			tbl16.queueRefresh()
		end
	end
	tbl16.onVisualsChanged = function(arg, arg2)
		if not flag or BossSpawnerFX.GetForRegion(arg) ~= arg2 then
			return
		end
		if tbl16.effectVisible(arg2) == true and BossSpawnerFX.IsActive(arg2) and not tbl16.caughtRegions[arg:GetAttribute(RegionConfig.BossAttribute)] then
			tbl16.finishedEffects[arg2] = nil
		end
		tbl16.queueRefresh()
	end
	tbl16.watchRegion = function(arg)
		if not arg:IsA("BasePart") or tbl16.regionWatchers[arg] then
			return
		end
		local tbl17 = {}
		tbl16.regionWatchers[arg] = tbl17
		tbl17.attach = function(effect)
			if not effect or not effect:IsA("BasePart") or tbl17.effect == effect then
				return
			end
			if tbl17.attributeConnection then
				tbl17.attributeConnection:Disconnect()
			end
			if tbl17.visualAddedConnection then
				tbl17.visualAddedConnection:Disconnect()
			end
			if tbl17.visualRemovedConnection then
				tbl17.visualRemovedConnection:Disconnect()
			end
			local v12 = pairs
			local visualConnections = tbl17.visualConnections or {}
			for _, visualConnection in v12(visualConnections) do
				visualConnection:Disconnect()
			end
			tbl17.visualConnections = {}
			tbl17.effect = effect
			tbl17.attributeConnection = effect:GetAttributeChangedSignal(BossSpawnerFX.ActiveAttribute):Connect(function()
				tbl16.onEffectActivityChanged(arg, effect)
			end)
			local function fn45(arg2)
				if not (arg2:IsA("ParticleEmitter") or arg2:IsA("Beam")) or tbl17.visualConnections[arg2] then
					return
				end
				tbl17.visualConnections[arg2] = arg2:GetPropertyChangedSignal("Enabled"):Connect(function()
					tbl16.onVisualsChanged(arg, effect)
				end)
			end
			tbl17.visualAddedConnection = effect.DescendantAdded:Connect(function(descendant)
				tbl16.effectVisuals[effect] = nil
				fn45(descendant)
				tbl16.queueRefresh()
			end)
			tbl17.visualRemovedConnection = effect.DescendantRemoving:Connect(function(descendant)
				if tbl17.visualConnections[descendant] then
					tbl17.visualConnections[descendant]:Disconnect()
					tbl17.visualConnections[descendant] = nil
				end
				tbl16.effectVisuals[effect] = nil
				tbl16.queueRefresh()
			end)
			tbl16.effectVisible(effect)
			for _, v13 in ipairs(tbl16.effectVisuals[effect]) do
				fn45(v13)
			end
			if BossSpawnerFX.IsActive(effect) then
				tbl16.queueRefresh()
			end
		end
		tbl17.childConnection = arg.ChildAdded:Connect(function(child)
			if child.Name == BossSpawnerFX.RootName then
				tbl17.attach(child)
			end
		end)
		tbl17.idConnection = arg:GetAttributeChangedSignal(RegionConfig.BossAttribute):Connect(tbl16.queueRefresh)
		tbl17.removedConnection = arg.ChildRemoved:Connect(function(child)
			if child ~= tbl17.effect then
				return
			end
			if tbl17.attributeConnection then
				tbl17.attributeConnection:Disconnect()
				tbl17.attributeConnection = nil
			end
			if tbl17.visualAddedConnection then
				tbl17.visualAddedConnection:Disconnect()
				tbl17.visualAddedConnection = nil
			end
			if tbl17.visualRemovedConnection then
				tbl17.visualRemovedConnection:Disconnect()
				tbl17.visualRemovedConnection = nil
			end
			local v12 = pairs
			local visualConnections = tbl17.visualConnections or {}
			for _, visualConnection in v12(visualConnections) do
				visualConnection:Disconnect()
			end
			tbl17.visualConnections = {}
			tbl16.effectVisuals[child] = nil
			tbl16.markUnloaded(arg:GetAttribute(RegionConfig.BossAttribute), arg, child)
			tbl17.effect = nil
			tbl16.queueRefresh()
		end)
		tbl17.destroyConnection = arg.Destroying:Connect(function()
			tbl16.unwatchRegion(arg)
		end)
		tbl17.attach(BossSpawnerFX.GetForRegion(arg))
	end
	for _, v12 in ipairs(CollectionService:GetTagged(RegionConfig.BossTag)) do
		tbl16.watchRegion(v12)
	end
	fn2(CollectionService:GetInstanceAddedSignal(RegionConfig.BossTag):Connect(tbl16.watchRegion))
	fn2(CollectionService:GetInstanceRemovedSignal(RegionConfig.BossTag):Connect(tbl16.unwatchRegion))
	fn2(localPlayer.CharacterAdded:Connect(function()
		task.delay(1, function()
			if flag and tbl16.espEnabled then
				tbl16.refreshEsp()
			end
		end)
	end))
	fn2(localPlayer.ChildAdded:Connect(function(child)
		if child:IsA("PlayerGui") and flag and tbl16.espEnabled then
			tbl16.queueRefresh()
		end
	end))
	fn2(FishingPackets.FishPhase.OnClientEvent:Connect(function(arg, arg2, arg3, arg4)
		if flag and tbl16.isInterested() and arg2 == FishingEnums.RemotePhase.Fight then
			tbl16.confirmFishAt(arg3, arg4, arg, arg2)
		end
	end))
	fn2(FishingPackets.FishFirstPullStart.OnClientEvent:Connect(function()
		if flag and tbl16.isInterested() then
			task.defer(function()
				if flag then
					tbl16.syncLocalIdentity()
				end
			end)
		end
	end))
	fn2(FishingPackets.FishReelStartAck.OnClientEvent:Connect(function()
		if flag and tbl16.isInterested() then
			task.defer(function()
				if flag then
					tbl16.syncLocalIdentity()
				end
			end)
		end
	end))
	fn2(FishingPackets.FishCatchResult.OnClientEvent:Connect(function(arg, arg2)
		if flag then
			tbl16.onCatchResult(arg, arg2)
		end
	end))
	fn2(FishingPackets.FishReset.OnClientEvent:Connect(function()
		if flag then
			tbl16.resetEncounter()
		end
	end))
	pcall(function()
		fn2((FishingController or client.GetController("FishingController")).StateChanged:Connect(function()
			if flag and tbl16.isInterested() then
				task.defer(function()
					if not flag then
						return
					end
					local idling2 = FishingEnums.State.Idling
					if fn7() == idling2 then
						tbl16.resetEncounter()
					end
					tbl16.syncLocalIdentity()
					tbl16.queueRefresh()
				end)
			end
		end))
	end)
	task.spawn(function()
		while flag do
			task.wait(2)
			if flag and tbl16.isInterested() then
				pcall(tbl16.refreshEsp)
			end
		end
	end)
	fn2({ Disconnect = function()
		if tbl16.distanceConnection then
			tbl16.distanceConnection:Disconnect()
			tbl16.distanceConnection = nil
		end
		for k, regionWatcher in pairs(tbl16.regionWatchers) do
			if regionWatcher.attributeConnection then
				regionWatcher.attributeConnection:Disconnect()
			end
			if regionWatcher.idConnection then
				regionWatcher.idConnection:Disconnect()
			end
			if regionWatcher.childConnection then
				regionWatcher.childConnection:Disconnect()
			end
			if regionWatcher.removedConnection then
				regionWatcher.removedConnection:Disconnect()
			end
			if regionWatcher.destroyConnection then
				regionWatcher.destroyConnection:Disconnect()
			end
			if regionWatcher.visualAddedConnection then
				regionWatcher.visualAddedConnection:Disconnect()
			end
			if regionWatcher.visualRemovedConnection then
				regionWatcher.visualRemovedConnection:Disconnect()
			end
			local v12 = pairs
			local visualConnections = regionWatcher.visualConnections or {}
			for _, visualConnection in v12(visualConnections) do
				visualConnection:Disconnect()
			end
			tbl16.regionWatchers[k] = nil
		end
		for k in pairs(tbl16.espRecords) do
			tbl16.clearEsp(k)
		end
	end })
	pcall(function()
		fn2(BossSpawnSound.OnClientEvent:Connect(function()
			local spawnPool = { at = os.clock() }
			tbl16.spawnPool = spawnPool
			local v12, v13 = tbl16.captureSpawnPool()
			task.delay(0.35, function()
				if not flag or tbl16.spawnPool ~= spawnPool then
					return
				end
				local v14, v15 = tbl16.captureSpawnPool()
				if not v12 or v12 == v14 and v13 == v15 then
					local v16 = spawnPool
					spawnPool.fishId = v14
					v16.weatherId = v15
				end
				tbl16.queueRefresh()
			end)
			table.clear(tbl16.caughtRegions)
			for _, observation in pairs(tbl16.observations) do
				if not observation.encounter then
					tbl16.clearIdentity(observation)
				end
			end
			fn44("Server Broadcast: BossSpawnSound")
		end))
	end)
	BossTab:Section({ Title = text("Boss Alerts") })
	BossTab:Toggle({
		Title = text("Notify Boss"),
		Default = false,
		Flag = "NotifyBoss",
		Callback = function(notifyEnabled)
			tbl16.notifyEnabled = notifyEnabled
			if notifyEnabled then
				tbl16.refreshEsp()
				fn44("Notify Enabled")
			else
				table.clear(tbl16.notifiedEffects)
				if not tbl16.espEnabled then
					tbl16.generation = tbl16.generation + 1
					tbl16.radarGeneration = (tbl16.radarGeneration or 0) + 1
				end
			end
		end,
	})
	BossTab:Toggle({
		Title = text("ESP Boss"),
		Default = false,
		Flag = "ESPBoss",
		Callback = function(espEnabled)
			tbl16.espEnabled = espEnabled
			if espEnabled then
				tbl16.refreshEsp()
				fn44("ESP Enabled")
			else
				for k in pairs(tbl16.espRecords) do
					tbl16.clearEsp(k)
				end
				if tbl16.distanceConnection then
					tbl16.distanceConnection:Disconnect()
					tbl16.distanceConnection = nil
				end
				if not tbl16.notifyEnabled then
					tbl16.generation = tbl16.generation + 1
					tbl16.radarGeneration = (tbl16.radarGeneration or 0) + 1
				end
			end
		end,
	})
	genv.HuneHubFishingMaster.GetBossStatus = function()
		local tbl17 = {}
		for k, observation in pairs(tbl16.observations) do
			tbl17[#tbl17 + 1] = {
				id = k,
				episode = observation.episode,
				visible = observation.effect and tbl16.effectVisible(observation.effect),
				active = observation.effect and BossSpawnerFX.IsActive(observation.effect),
				fishId = observation.fishId,
				confirmed = observation.fishConfirmed == true,
				ownEncounter = observation.ownFishConfirmed == true,
				identityConflict = observation.identityConflict == true,
			}
		end
		return {
			edition = "Free",
			esp = tbl16.espEnabled,
			notify = tbl16.notifyEnabled,
			action = str7,
			regions = tbl17,
			caughtRegions = table.clone(tbl16.caughtRegions),
		}
	end
end
fn42()
local function fn43(arg, arg2, arg3)
	local v10 = tbl9[arg]
	GachaTab:Section({ Title = v10.name .. text(" Gacha") })
	local str4
	if arg == "Aura" then
		str4 = fn10(AuraGachaConfig.Pull.CostGem) .. text(" Gems Per Spin")
	elseif arg == "Skill" then
		str4 = text("Coin Price Is Quoted Before Every Spin")
	else
		local v11 = CrateConfig.GetCrate(v10.crateId)
		str4 = fn10(CrateConfig.GetPrice(v10.crateId, 1)) .. " " .. (v11 and v11.Currency or "Coins") .. text(" Per Spin")
	end
	GachaTab:Paragraph({ Title = text("Cost"), Desc = str4 })
	local name = v10.name
	v10.toggle = GachaTab:Toggle({
		Title = text("Auto Spin ") .. name,
		Default = false,
		Flag = arg3.toggle,
		Callback = function(enabled)
			v10.enabled = enabled
			if enabled then
				fn5(arg)
			end
		end,
	})
	GachaTab:Dropdown({
		Title = v10.name .. text(" Stop At Or Above Rarity"),
		Values = arg2,
		Default = v10.rarity,
		Multi = false,
		Flag = arg3.rarity,
		Callback = function(rarity)
			v10.rarity = rarity
		end,
	})
	GachaTab:Slider({
		Title = v10.name .. text(" Maximum Spins"),
		Value = { Min = 1, Max = 100, Default = 10 },
		Step = 1,
		Flag = arg3.amount,
		Callback = function(amount)
			v10.amount = amount
		end,
	})
end
fn43("Aura", fn4(AuraGachaConfig.RarityOdds), { toggle = "AutoSpinAuraGacha", rarity = "GachaStopRarity", amount = "MaximumGachaSpins" })
fn43("Skill", fn4(SkillGachaConfig.RarityOdds), {
	toggle = "AutoSpinSkillGacha",
	rarity = "SkillGachaStopRarity",
	amount = "MaximumSkillGachaSpins",
})
fn43("Ocean", fn4(nil, "crate_ocean_chest"), {
	toggle = "AutoSpinOceanChest",
	rarity = "OceanChestStopRarity",
	amount = "MaximumOceanChestSpins",
})
fn43("Dragon", fn4(nil, "crate_dragon_chest"), {
	toggle = "AutoSpinDragonChest",
	rarity = "DragonChestStopRarity",
	amount = "MaximumDragonChestSpins",
})
ShopTab:Section({ Title = text("Buy Fishing Rods") })
local tbl16 = {}
for k, v10 in pairs(RodShopConfig) do
	local v11 = Catalog.Rod.GetById(k)
	if v11 then
		table.insert(tbl16, { id = k, rod = v11, listing = v10 })
	end
end
table.sort(tbl16, function(arg, arg2)
	return arg.listing.price < arg2.listing.price
end)
local tbl17 = {}
local tbl18 = {}
for _, v10 in ipairs(tbl16) do
	local str4 = string.format("%s [%s] - %s %s", v10.rod.name, v10.rod.rarity, fn10(v10.listing.price), v10.listing.currency or "Coin")
	tbl17[str4] = v10
	table.insert(tbl18, str4)
end
local v10 = tbl16[1]
local flag27 = false
ShopTab:Dropdown({
	Title = text("Select Rod To Buy"),
	Values = tbl18,
	Default = tbl18[1],
	Multi = false,
	Flag = "ShopSelectedRod",
	Callback = function(arg)
		v10 = tbl17[arg] or tbl16[1]
	end,
})
ShopTab:Button({
	Title = text("Buy Selected Rod"),
	Callback = function()
		if flag27 then
			return
		end
		local v11 = v10
		if not v11 then
			return
		end
		local ok, result = pcall(function()
			return PlayerDataV2Controller:Fetch(localPlayer)
		end)
		if not ok or type(result) ~= "table" then
			lib:Notify({ Title = text("Rod Shop"), Content = text("Player data is not ready."), Duration = 3 })
			return
		end
		if result.Rods and result.Rods[v11.id] then
			lib:Notify({ Title = text("Rod Shop"), Content = text("You already own this rod."), Duration = 3 })
			return
		end
		local islandId = v11.listing.islandId
		local v12 = islandId and IslandConfig[islandId]
		local flag28
		if islandId then
			flag28 = not (v12 and v12.defaultUnlocked)
		else
			flag28 = islandId
		end
		if flag28 then
			flag28 = not (result.UnlockedIslands and result.UnlockedIslands[islandId] == true)
		end
		if flag28 then
			lib:Notify({ Title = text("Rod Shop"), Content = text("Unlock the rod's island first."), Duration = 3 })
			return
		end
		local currency = v11.listing.currency or "Coin"
		local n19 = tonumber(v11.listing.price) or 0
		if (tonumber(result[currency]) or 0) < n19 then
			lib:Notify({ Title = text("Rod Shop"), Content = text("Not enough ") .. currency .. ".", Duration = 3 })
			return
		end
		flag27 = true
		local ok2, result2 = pcall(function()
			return v:Fire(v11.id)
		end)
		flag27 = false
		lib:Notify({
			Title = text("Rod Shop"),
			Content = ok2 and result2 and "Bought " .. v11.rod.name .. "." or "Purchase failed; check balance and requirements.",
			Duration = 4,
		})
	end,
})
local function fn44()
	local DailyRewardUtil = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Lib"):WaitForChild("DailyRewardUtil"))
	local v11 = packet("GroupReward/Claim"):Response({
		ok = packet.Boolean8,
		reason = packet.String,
		group_id = packet.NumberU32,
		joined = packet.Boolean8,
		claimed = packet.Boolean8,
		rarity = packet.String,
		is_new = packet.Boolean8,
	})
	local v12 = packet("GroupReward/GetState"):Response({ enabled = packet.Boolean8, group_id = packet.NumberU32, joined = packet.Boolean8, claimed = packet.Boolean8 })
	local v13 = packet("RedeemCode", packet.String):Response(packet.NumberU8)
	local str4 = ""
	local flag28 = false
	local n19 = 0
	local function fn45(arg)
		if flag28 then
			return
		end
		if arg and os.clock() < n19 then
			return
		end
		local dailyReward = PlayerDataV2Controller:Fetch(localPlayer)
		dailyReward = dailyReward and dailyReward.DailyReward
		if type(dailyReward) ~= "table" then
			return
		end
		local v14 = DailyRewardUtil.compute_state(dailyReward, DailyRewardUtil.get_now())
		if not v14.ClaimableDay then
			if not arg then
				local v15 = math.ceil(DailyRewardUtil.seconds_until_next_claim(dailyReward))
				lib:Notify({
					Title = text("Daily Reward"),
					Content = text("Next claim in ") .. fn11(v15) .. ".",
					Duration = 3,
				})
			end
			return
		end
		flag28 = true
		local ok, result = pcall(function()
			return v2:Fire()
		end)
		flag28 = false
		if ok and result == true then
			n19 = 0
			lib:Notify({
				Title = text("Daily Reward"),
				Content = text("Claimed day ") .. tostring(v14.ClaimableDay) .. ".",
				Duration = 3,
			})
		else
			n19 = os.clock() + 300
			if not arg then
				lib:Notify({ Title = text("Daily Reward"), Content = text("Claim rejected by game."), Duration = 3 })
			end
		end
	end
	RewardTab:Section({ Title = text("Daily Login") })
	RewardTab:Button({
		Title = text("Claim Daily Reward"),
		Callback = function()
			fn45(false)
		end,
	})
	RewardTab:Toggle({
		Title = text("Auto Claim Daily Reward"),
		Default = false,
		Flag = "AutoDailyReward",
		Callback = function(arg)
			flag16 = arg
			if arg then
				task.spawn(function()
					pcall(function()
						fn45(true)
					end)
				end)
			end
		end,
	})
	RewardTab:Section({ Title = text("Group & Gift Inbox") })
	RewardTab:Button({
		Title = text("Claim Group Reward"),
		Callback = function()
			local ok, result = pcall(function()
				return v12:Fire()
			end)
			if not ok or type(result) ~= "table" or not result.enabled then
				lib:Notify({ Title = text("Group Reward"), Content = text("Group reward is unavailable."), Duration = 3 })
				return
			end
			if result.claimed then
				lib:Notify({ Title = text("Group Reward"), Content = text("Already claimed."), Duration = 3 })
				return
			end
			if not result.joined then
				local ok2, result2 = pcall(function()
					return game:GetService("GroupService"):PromptJoinAsync(result.group_id)
				end)
				if not ok2 or result2 ~= Enum.GroupMembershipStatus.Joined and result2 ~= Enum.GroupMembershipStatus.AlreadyMember then
					lib:Notify({
						Title = text("Group Reward"),
						Content = text("Join the game's group, then claim again."),
						Duration = 3,
					})
					return
				end
			end
			local ok2, result2 = pcall(function()
				return v11:Fire()
			end)
			lib:Notify({
				Title = text("Group Reward"),
				Content = ok2 and type(result2) == "table" and result2.ok and "Claimed group reward." or type(result2) == "table" and result2.reason or "Claim failed.",
				Duration = 3,
			})
		end,
	})
	RewardTab:Button({
		Title = text("Claim All Gift Inbox Items"),
		Callback = function()
			local ok = pcall(function()
				ClaimAll:Fire()
			end)
			lib:Notify({
				Title = text("Gift Inbox"),
				Content = ok and "Claim request sent. Check your gift inbox." or "Claim request failed.",
				Duration = 3,
			})
		end,
	})
	RewardTab:Section({ Title = text("Redeem Code") })
	RewardTab:Input({
		Title = text("Code"),
		Value = "",
		Placeholder = text("Enter game code"),
		Callback = function(arg)
			str4 = tostring(arg or "")
		end,
	})
	RewardTab:Button({
		Title = text("Redeem Code"),
		Callback = function()
			local match = str4:match("^%s*(.-)%s*$")
			if match == "" then
				return
			end
			local ok, result = pcall(function()
				return v13:Fire(match)
			end)
			local tbl19 = {
				[0] = "Code redeemed.",
				"Invalid code.",
				"Code expired.",
				"Code already redeemed.",
				"Requirements not met.",
				"Save failed; retry later.",
				"Redemption is busy.",
				"Migrated game passes added.",
			}
			lib:Notify({
				Title = text("Redeem Code"),
				Content = ok and (tbl19[result] or "Unknown response.") or "Request failed.",
				Duration = 3,
			})
		end,
	})
	task.spawn(function()
		while flag do
			task.wait(30)
			if flag16 then
				pcall(function()
					fn45(true)
				end)
			end
		end
	end)
	RewardTab:Section({ Title = text("Session Statistics") })
	local v14 = RewardTab:Paragraph({ Title = text("Session Statistics"), Desc = text("Fish Caught: 0 | Coins Earned: 0 | Time: 0m 00s") })
	task.spawn(function()
		while flag do
			task.wait(2)
			if v14 and v14.SetDesc then
				pcall(function()
					local v15 = n12
					local v16 = fn11
					v14:SetDesc(string.format(text("Fish Caught: %d | Coins Earned: %s | Time: %s"), v15, fn10(n13), v16(tick() - now)))
				end)
			end
		end
	end)
end
fn44()
VisualTab:Section({ Title = text("Visual Effect (Client-side)") })
VisualTab:Dropdown({
	Title = text("Rod Skin"),
	Values = tbl12.rodSkinList,
	Default = "Default",
	Flag = "VisualRodSkin",
	Callback = function(arg)
		tbl12.SetEffect("RodSkinId", tbl12.rodSkinMap[arg])
	end,
})
VisualTab:Dropdown({
	Title = text("Aura"),
	Values = tbl12.auraList,
	Default = "Default",
	Flag = "VisualAura",
	Callback = function(arg)
		tbl12.SetEffect("AuraCatalogId", tbl12.auraMap[arg])
	end,
})
MiscTab:Section({ Title = text("Movement") })
MiscTab:Toggle({
	Title = text("Walk On Water"),
	Default = true,
	Flag = "MiscWalkOnWater",
	Callback = function(arg)
		if tbl11 then
			tbl11.SetEnabled(arg)
		end
	end,
})
MiscTab:Toggle({
	Title = text("Anti-AFK"),
	Default = true,
	Flag = "AntiAFK",
	Callback = function(arg)
		flag17 = arg
	end,
})
MiscTab:Toggle({
	Title = text("Freeze Character"),
	Default = false,
	Flag = "FreezeCharacter",
	Callback = function(anchored)
		flag18 = anchored
		local v11 = fn6()
		if v11 then
			v11.Anchored = anchored
		end
	end,
})
MiscTab:Section({ Title = text("System Utilities") })
local function fn45()
	local flag28 = false
	local flag29 = false
	local Lighting = game:GetService("Lighting")
	local numberSequence = NumberSequence.new(1)
	local debris = workspace:FindFirstChild("Debris")
	local world = workspace:FindFirstChild("World")
	local islands = world and world:FindFirstChild("Islands")
	local color2 = Color3.fromRGB(145, 145, 145)
	local tbl19 = {
		"tree",
		"leaf",
		"leaves",
		"palm",
		"caydua",
		"duwa",
		"bush",
		"grass",
		"foliage",
		"plant",
		"vine",
		"flower",
	}
	local function fn46(arg)
		return debris and arg:IsDescendantOf(debris) or arg:FindFirstAncestor("ClientAuraEffect") ~= nil
	end
	local function fn47(descendant)
		pcall(function()
			if descendant:FindFirstAncestor("BossSpawnerFX") then
				return
			end
			if descendant:IsA("ParticleEmitter") then
				descendant.Enabled = false
				descendant.Rate = 0
				descendant.Transparency = numberSequence
				descendant:Clear()
			elseif descendant:IsA("Beam") or descendant:IsA("Trail") then
				descendant.Enabled = false
				descendant.Transparency = numberSequence
			elseif descendant:IsA("Fire") then
				descendant.Enabled = false
				descendant.Size = 0
				descendant.Heat = 0
			elseif descendant:IsA("Smoke") then
				descendant.Enabled = false
				descendant.Opacity = 0
				descendant.Size = 0
			elseif descendant:IsA("Sparkles") then
				descendant:Destroy()
			elseif descendant:IsA("Highlight") then
				descendant.Enabled = false
				descendant.FillTransparency = 1
				descendant.OutlineTransparency = 1
			elseif descendant:IsA("PointLight") or descendant:IsA("SurfaceLight") or descendant:IsA("SpotLight") then
				descendant.Enabled = false
				descendant.Brightness = 0
			elseif descendant:IsA("PostEffect") then
				descendant.Enabled = false
			elseif descendant:IsA("Explosion") then
				descendant.Visible = false
			elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
				descendant.Transparency = 1
				descendant.Texture = ""
			elseif descendant:IsA("SurfaceAppearance") then
				descendant:Destroy()
			elseif descendant:IsA("SpecialMesh") then
				descendant.TextureId = ""
			elseif descendant:IsA("BasePart") then
				descendant.Material = Enum.Material.SmoothPlastic
				pcall(function()
					descendant.MaterialVariant = ""
				end)
				descendant.Reflectance = 0
				descendant.CastShadow = false
				if fn46(descendant) then
					descendant.LocalTransparencyModifier = 1
				end
				if descendant:IsA("MeshPart") then
					descendant.TextureID = ""
					descendant.RenderFidelity = Enum.RenderFidelity.Performance
				elseif descendant:IsA("UnionOperation") then
					descendant.RenderFidelity = Enum.RenderFidelity.Performance
				end
			elseif descendant:IsA("Sky") then
				descendant:Destroy()
			elseif descendant:IsA("Atmosphere") then
				descendant.Density = 0
				descendant.Haze = 0
				descendant.Glare = 0
			end
		end)
	end
	local function fn48(arg)
		if arg.CanCollide then
			return false
		end
		local parent = arg
		while parent and parent ~= islands do
			local v11 = string.lower(parent.Name)
			for _, v12 in ipairs(tbl19) do
				if string.find(v11, v12, 1, true) then
					return true
				end
			end
			parent = parent.Parent
		end
		local color3 = arg.Color
		return color3.G > 0.25 and color3.G > color3.R * 1.15 and color3.G > color3.B * 1.15
	end
	local function fn49(arg)
		local parent = arg.Parent
		while parent and parent ~= islands do
			if parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then
				return true
			end
			parent = parent.Parent
		end
		return false
	end
	local function fn50(arg)
		pcall(function()
			if arg:IsA("Clouds") then
				arg.Cover = 0
				arg.Density = 0
			elseif arg:IsA("BasePart") and islands and arg:IsDescendantOf(islands) and arg.Anchored and not fn49(arg) then
				local v11 = fn48(arg)
				arg.Color = color2
				if v11 then
					arg.LocalTransparencyModifier = 1
				end
			end
		end)
	end
	local function fn51(descendant)
		if descendant.Name == "Debris" and descendant.Parent == workspace then
			debris = descendant
		elseif descendant.Name == "World" and descendant.Parent == workspace then
			world = descendant
		elseif descendant.Name == "Islands" and world and descendant.Parent == world then
			islands = descendant
		end
		fn47(descendant)
		if flag29 then
			fn50(descendant)
		end
	end
	local function fn52()
		pcall(function()
			Lighting.EnvironmentDiffuseScale = 0
			Lighting.EnvironmentSpecularScale = 0
			Lighting.GlobalShadows = false
			Lighting.Ambient = Color3.fromRGB(150, 150, 150)
			Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
		end)
		local terrain = workspace.Terrain
		if sethiddenproperty then
			pcall(function()
				sethiddenproperty(terrain, "Decoration", false)
			end)
		end
		pcall(function()
			for _, v11 in ipairs({ "Grass", "LeafyGrass", "Ground", "Rock", "Slate", "Sand", "Snow", "Mud" }) do
				local v12 = Enum.Material[v11]
				if v12 then
					pcall(function()
						terrain:SetMaterialColor(v12, color2)
					end)
				end
			end
			local clouds = terrain:FindFirstChildOfClass("Clouds")
			if clouds then
				fn50(clouds)
			end
		end)
	end
	local function fn53()
		if flag28 then
			return false
		end
		flag28 = true
		task.spawn(function()
			pcall(function()
				packet("SetSettings", packet.String, packet.Any):Response(packet.Boolean8):Fire("Show VFX (Other Players)", false)
			end)
		end)
		pcall(function()
			local EffectController = client.GetController("EffectController")
			local effect = EffectController.Effect
			local function effect2(arg, arg2, arg3, arg4, ...)
				if type(arg2) == "string" and arg2:sub(1, 9) == "Movesets/" and typeof(arg4) == "Instance" and arg4:IsA("Player") and arg4 ~= localPlayer then
					return
				end
				return effect(arg, arg2, arg3, arg4, ...)
			end
			EffectController.Effect = effect2
			fn2({ Disconnect = function()
				if EffectController.Effect == effect2 then
					EffectController.Effect = effect
				end
			end })
		end)
		pcall(function()
			local level01 = Enum.QualityLevel.Level01
			settings().Rendering.QualityLevel = level01
		end)
		pcall(function()
			game:GetService("MaterialService").Use2022Materials = false
		end)
		pcall(function()
			Lighting.GlobalShadows = false
			Lighting.ShadowSoftness = 0
		end)
		pcall(function()
			local terrain = workspace.Terrain
			terrain.WaterWaveSize = 0
			terrain.WaterWaveSpeed = 0
			terrain.WaterReflectance = 0
			terrain.WaterTransparency = 1
			terrain.CastShadow = false
		end)
		fn2(workspace.DescendantAdded:Connect(fn51))
		fn2(Lighting.DescendantAdded:Connect(fn47))
		task.spawn(function()
			local n19 = 0
			for _, descendant in ipairs(workspace:GetDescendants()) do
				if not flag then
					return
				end
				fn51(descendant)
				n19 += 1
				if n19 % 250 == 0 then
					task.wait()
				end
			end
			for _, descendant in ipairs(Lighting:GetDescendants()) do
				if not flag then
					return
				end
				fn47(descendant)
			end
			lib:Notify({
				Title = text("Fix Lag"),
				Content = flag29 and "Pro Mode Applied To The Map And VFX." or "Textures And VFX Have Been Reduced.",
				Duration = 3,
			})
		end)
		return true
	end
	MiscTab:Button({
		Title = text("Fix Lag Pro (Boost FPS)"),
		Callback = function()
			if flag29 then
				lib:Notify({ Title = text("Fix Lag Pro"), Content = text("Pro Mode Is Already Active."), Duration = 3 })
				return
			end
			flag29 = true
			fn53()
			fn52()
		end,
	})
end
fn45()
MiscTab:Button({
	Title = text("Rejoin Server"),
	Callback = function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
	end,
})
MiscTab:Button({ Title = text("Unload Hub"), Callback = fn27 })
local function fn46()
	tbl.migrateLegacyProfiles("fishingMaster", configManager)
	local function fn47(arg)
		return tbl.update(function(arg2)
			arg2.fishingMaster = type(arg2.fishingMaster) == "table" and arg2.fishingMaster or {}
			local fishingMaster = arg2.fishingMaster
			local v11 = tostring
			local v12 = arg
			local str4
			if arg then
				str4 = v12
			else
				str4 = "None"
			end
			fishingMaster.autoload = v11(str4)
		end)
	end
	local function fn48()
		local fishingMaster = tbl.read().fishingMaster
		return type(fishingMaster) == "table" and type(fishingMaster.autoload) == "string" and fishingMaster.autoload ~= "" and fishingMaster.autoload or "None"
	end
	local function fn49(arg)
		if not arg then
			return ""
		end
		return tostring(arg):gsub("[%c%s]+", "")
	end
	local function fn50()
		local tbl19 = {}
		for k in pairs(tbl.profiles("fishingMaster")) do
			table.insert(tbl19, k)
		end
		table.sort(tbl19)
		if #tbl19 == 0 then
			table.insert(tbl19, "Default")
		end
		return tbl19
	end
	local function fn51(arg)
		local tbl19 = { "None" }
		local v11 = ipairs
		local tbl20 = arg or {}
		for _, v12 in v11(tbl20) do
			table.insert(tbl19, v12)
		end
		return tbl19
	end
	local v11 = nil
	local v12 = nil
	local str4 = ""
	local v13 = fn50()
	local str5 = v13[1] or "Default"
	local str6 = fn48()
	local str7 = str6
	local flag28 = false
	local function fn52()
		local v14 = fn50()
		if v11 then
			pcall(function()
				v11:Refresh(v14)
			end)
		end
		if v12 then
			pcall(function()
				v12:Refresh(fn51(v14))
			end)
		end
	end
	SettingsTab:Section({ Title = text("Interface Settings") })
	SettingsTab:Dropdown({
		Title = text("Theme"),
		Values = { "Dark", "Light", "Aqua", "Amethyst", "Mocha", "Latte", "Transparent" },
		Default = "Dark",
		Flag = "Theme",
		Callback = function(arg)
			pcall(function()
				lib:SetTheme(arg)
			end)
		end,
	})
	SettingsTab:Input({
		Title = text("All Players Rainbow Name"),
		Value = v4.Get(),
		Default = v4.Get(),
		Placeholder = v4.Default,
		Callback = function(arg)
			v4.Set(arg, true)
		end,
	})
	SettingsTab:Section({ Title = text("Movement & Safety") })
	SettingsTab:Toggle({
		Title = text("Walk On Water"),
		Default = false,
		Flag = "WalkOnWater",
		Callback = function(arg)
			if tbl11 then
				tbl11.SetEnabled(arg)
			end
		end,
	})
	local v14 = LanguageTab
	local dropdown = v14.Dropdown
	local tbl19 = { Title = text("Select Language"), Values = { "Auto / Tự Động (Roblox)", "Tiếng Việt", "English" } }
	local default = tbl2.mode == "auto" and "Auto / Tự Động (Roblox)"
	if not default then
		default = tbl2.mode == "vi" and "Tiếng Việt" or "English"
	end
	tbl19.Default = default
	tbl19.Callback = function(arg)
		local mode = arg == "Tiếng Việt" and "vi" or arg == "English" and "en" or "auto"
		tbl2.mode = mode
		tbl2.code = mode == "auto" and tbl2.detect() or mode
		genv.HuneHubFishingLanguageMode = mode
		local v15 = tbl2.save(mode)
		task.defer(function()
			tbl2.refreshGui(lib)
		end)
		lib:Notify({
			Title = text("Language"),
			Content = v15 and text("Language updated and saved.") or text("Language updated for this session, but could not be saved."),
			Duration = 4,
		})
	end
	dropdown(v14, tbl19)
	SettingsTab:Section({ Title = text("Profile Management System") })
	SettingsTab:Input({
		Title = text("New Config Name"),
		Default = str4,
		Placeholder = text("e.g. AutoFarm"),
		Callback = function(arg)
			str4 = fn49(arg)
		end,
	})
	SettingsTab:Button({
		Title = text("Save Config"),
		Callback = function()
			if flag28 then
				return
			end
			flag28 = true
			local v15 = str4
			if v15 == "" then
				lib:Notify({ Title = text("LunarX Hub"), Content = text("Please enter config name first!"), Duration = 4 })
				flag28 = false
				return
			end
			local ok, result = pcall(function()
				tbl.saveProfile("fishingMaster", v15, v5, configManager)
			end)
			if ok then
				str5 = v15
				lib:Notify({ Title = text("LunarX Hub"), Content = text("Saved: ") .. v15, Duration = 3 })
				fn52()
			else
				lib:Notify({ Title = text("LunarX Hub"), Content = text("Save config failed: ") .. tostring(result), Duration = 5 })
			end
			flag28 = false
		end,
	})
	v11 = SettingsTab:Dropdown({
		Title = text("Select Config To Load/Delete"),
		Values = v13,
		Default = str5,
		Callback = function(arg)
			str5 = arg
		end,
	})
	SettingsTab:Button({
		Title = text("Load Config"),
		Callback = function()
			if not str5 or str5 == "" then
				return
			end
			local ok, result = pcall(function()
				tbl.loadProfile("fishingMaster", str5, v5, configManager)
			end)
			if ok then
				lib:Notify({ Title = text("LunarX Hub"), Content = text("Loaded: ") .. str5, Duration = 3 })
			else
				lib:Notify({ Title = text("LunarX Hub"), Content = text("Load config failed: ") .. tostring(result), Duration = 5 })
			end
		end,
	})
	SettingsTab:Button({
		Title = text("Delete Config"),
		Callback = function()
			if not str5 or str5 == "" then
				return
			end
			local v15 = str5
			local ok, result = pcall(function()
				if not tbl.profiles("fishingMaster")[v15] then
					error("profile not found")
				end
				if not tbl.update(function(arg)
					arg.fishingMaster.profiles[v15] = nil
					if arg.fishingMaster.autoload == v15 then
						arg.fishingMaster.autoload = "None"
					end
				end) then
					error("could not delete profile")
				end
			end)
			if ok then
				if v15 == str6 then
					str6 = "None"
					str7 = "None"
					fn47("None")
				end
				lib:Notify({ Title = text("LunarX Hub"), Content = text("Deleted: ") .. v15, Duration = 3 })
				fn52()
			else
				lib:Notify({
					Title = text("LunarX Hub"),
					Content = text("Delete config failed: ") .. tostring(result),
					Duration = 5,
				})
			end
		end,
	})
	v12 = SettingsTab:Dropdown({
		Title = text("Select Auto Load Config"),
		Values = fn51(v13),
		Default = str6,
		Callback = function(arg)
			str7 = arg
		end,
	})
	SettingsTab:Button({
		Title = text("Set Auto Load Config"),
		Callback = function()
			str6 = str7 or "None"
			if not fn47(str6) then
				lib:Notify({ Title = text("LunarX Hub"), Content = text("Save failed; retry later."), Duration = 5 })
				return
			end
			lib:Notify({ Title = text("LunarX Hub"), Content = text("Auto load set to: ") .. str6, Duration = 4 })
		end,
	})
	task.spawn(function()
		task.wait(2)
		if type(genv.HuneHubReloadSnapshot) == "table" and genv.HuneHubReloadSnapshot.pending then
			return
		end
		local v15 = fn48()
		if v15 == "None" or v15 == "" then
			return
		end
		local flag29 = false
		for i = 1, 5 do
			if pcall(function()
				tbl.loadProfile("fishingMaster", v15, v5, configManager)
			end) then
				flag29 = true
				break
			else
				task.wait(1)
			end
		end
		if flag29 then
			lib:Notify({ Title = text("LunarX Hub"), Content = text("Auto Loaded Config (") .. v15 .. ")", Duration = 5 })
		end
	end)
	AboutTab:Select()
	lib:Notify({ Title = text("LunarX Hub"), Content = text("Join Discord For More Update New!!!"), Duration = 5 })
	lib:Notify({
		Title = text("LunarX Hub Ready"),
		Content = text("Fishing Master is ready. Enable Auto Farm to begin."),
		Duration = 4,
	})
end
fn46()
