-- The Forge - Complete Script
-- Features: Anti AFK, Auto Mining, Auto Kill Zombie
-- Game ID: 76558904092080

local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Services
local Services = {
    Inventory = ReplicatedStorage.Shared.Packages.Knit.Services.InventoryService,
    Proximity = ReplicatedStorage.Shared.Packages.Knit.Services.ProximityService,
    Dialogue = ReplicatedStorage.Shared.Packages.Knit.Services.DialogueService,
    Quest = ReplicatedStorage.Shared.Packages.Knit.Services.QuestService,
    Status = ReplicatedStorage.Shared.Packages.Knit.Services.StatusService,
    Character = ReplicatedStorage.Shared.Packages.Knit.Services.CharacterService,
    Tool = ReplicatedStorage.Shared.Packages.Knit.Services.ToolService,
}

-- Load UI Library
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/dy1zn4t/bmF0dWk-/refs/heads/main/ui.lua"))()
local Window = WindUI:CreateWindow({
	Title = "The Forge - Complete Hub",
	Icon = "rbxassetid://113216930555884",
	Author = "Script Hub",
	Folder = "TheForge",
	Size = UDim2.fromOffset(580, 460),
	LiveSearchDropdown = true,
    AutoSave = true,
    FileSaveName = "TheForge_Config.json",
})

-- Create Tabs
local Tabs = {
	MainTab = Window:Tab({ Title = "Anti AFK", Icon = "clock", Desc = "Bypass Roblox 20 minute AFK detection." }),
	FarmTab = Window:Tab({ Title = "Auto Farm", Icon = "pickaxe", Desc = "Auto mining and farming features." }),
	CombatTab = Window:Tab({ Title = "Combat", Icon = "sword", Desc = "Auto kill zombie and combat features." }),
	MiscTab = Window:Tab({ Title = "Misc", Icon = "settings", Desc = "Miscellaneous settings." }),
	InfoTab = Window:Tab({ Title = "Info", Icon = "info", Desc = "Information about the script." }),
}

Window:SelectTab(1)

-- Anti AFK Variables
local antiAFKEnabled = false
local afkConnection = nil
local lastAction = tick()
local actionCount = 0

-- Auto Farm Variables
local autoMining = false
local autoKillZombie = false
local flySpeed = 50
local miningRange = 20
local farmConnection = nil
local killConnection = nil
local statsCollected = 0
local zombiesKilled = 0

-- Anti AFK Function
local function performAntiAFK()
	if not antiAFKEnabled then return end
	
	-- Simulate user input to prevent AFK kick
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
	
	actionCount = actionCount + 1
	lastAction = tick()
	
	-- Optional: Move character slightly
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
		local humanoid = LocalPlayer.Character.Humanoid
		if humanoid.MoveDirection == Vector3.new(0, 0, 0) then
			-- Character is idle, send a small movement
			humanoid:Move(Vector3.new(0.01, 0, 0))
			wait(0.1)
			humanoid:Move(Vector3.new(0, 0, 0))
		end
	end
end

-- Auto Farm Functions
local function getCharacter()
    return LocalPlayer.Character
end

local function getHumanoidRootPart()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChild("Humanoid")
end

local function findNearestOre()
    local hrp = getHumanoidRootPart()
    if not hrp then return nil end
    
    local nearestOre = nil
    local nearestDistance = math.huge
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("ore") or obj.Name:lower():find("rock") or obj.Name:lower():find("stone")) then
            local orePart = obj:FindFirstChild("Part") or obj:FindFirstChildWhichIsA("BasePart")
            if orePart then
                local distance = (hrp.Position - orePart.Position).Magnitude
                if distance < nearestDistance and distance < 500 then
                    nearestDistance = distance
                    nearestOre = orePart
                end
            end
        end
    end
    
    return nearestOre
end

local function findNearestZombie()
    local hrp = getHumanoidRootPart()
    if not hrp then return nil end
    
    local nearestZombie = nil
    local nearestDistance = math.huge
    
    for _, npc in pairs(workspace:GetDescendants()) do
        if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc.Name:lower():find("zombie") then
            local npcHrp = npc:FindFirstChild("HumanoidRootPart")
            local npcHumanoid = npc:FindFirstChild("Humanoid")
            if npcHrp and npcHumanoid and npcHumanoid.Health > 0 then
                local distance = (hrp.Position - npcHrp.Position).Magnitude
                if distance < nearestDistance and distance < 500 then
                    nearestDistance = distance
                    nearestZombie = npc
                end
            end
        end
    end
    
    return nearestZombie
end

local function tweenTo(targetPos, speed)
    local hrp = getHumanoidRootPart()
    if not hrp then return end
    
    local distance = (hrp.Position - targetPos).Magnitude
    local duration = distance / speed
    
    local TweenService = game:GetService("TweenService")
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(targetPos)}
    )
    
    tween:Play()
    return tween
end

local function activateTool()
    pcall(function()
        Services.Tool.RF.ToolActivated:InvokeServer()
    end)
end

local function equipPickaxe()
    pcall(function()
        Services.Character.RF.EquipItem:InvokeServer("Pickaxe")
    end)
end

local function forge(target)
    pcall(function()
        Services.Proximity.RF.Forge:InvokeServer(target)
    end)
end

-- Auto Mining Function
local function startAutoMining()
    if farmConnection then
        farmConnection:Disconnect()
    end
    
    farmConnection = RunService.Heartbeat:Connect(function()
        if not autoMining then return end
        
        local ore = findNearestOre()
        if ore then
            local hrp = getHumanoidRootPart()
            if hrp then
                local distance = (hrp.Position - ore.Position).Magnitude
                
                if distance > miningRange then
                    tweenTo(ore.Position + Vector3.new(0, 5, 0), flySpeed)
                else
                    equipPickaxe()
                    wait(0.1)
                    activateTool()
                    forge(ore.Parent)
                    statsCollected = statsCollected + 1
                end
            end
        end
        
        wait(0.5)
    end)
end

-- Auto Kill Zombie Function
local function startAutoKill()
    if killConnection then
        killConnection:Disconnect()
    end
    
    killConnection = RunService.Heartbeat:Connect(function()
        if not autoKillZombie then return end
        
        local zombie = findNearestZombie()
        if zombie then
            local hrp = getHumanoidRootPart()
            local zombieHrp = zombie:FindFirstChild("HumanoidRootPart")
            
            if hrp and zombieHrp then
                local distance = (hrp.Position - zombieHrp.Position).Magnitude
                
                if distance > 10 then
                    tweenTo(zombieHrp.Position + Vector3.new(0, 3, 0), flySpeed)
                else
                    hrp.CFrame = CFrame.new(hrp.Position, zombieHrp.Position)
                    activateTool()
                    
                    local zombieHumanoid = zombie:FindFirstChild("Humanoid")
                    if zombieHumanoid and zombieHumanoid.Health <= 0 then
                        zombiesKilled = zombiesKilled + 1
                    end
                end
            end
        end
        
        wait(0.3)
    end)
end

-- Main Tab Content
Tabs.MainTab:Section({
	Title = "Anti AFK Status",
})

Tabs.MainTab:Paragraph{
	Title = "About Anti AFK",
	Desc = "This feature prevents Roblox from kicking you after 20 minutes of inactivity. The script simulates user input every few minutes to keep you active."
}

local statusParagraph = Tabs.MainTab:Paragraph{
	Title = "Status",
	Desc = "Anti AFK is currently disabled."
}

-- Anti AFK Toggle
local antiAFKToggle = Tabs.MainTab:Toggle({
	Title = "Enable Anti AFK",
	Icon = "shield-check",
	Default = false,
	Callback = function(state) 
		antiAFKEnabled = state
		
		if state then
			statusParagraph:SetDesc("Anti AFK is enabled. You will not be kicked for inactivity.")
			
			-- Start Anti AFK loop
			if afkConnection then
				afkConnection:Disconnect()
			end
			
			-- Perform anti AFK action every 60 seconds
			afkConnection = game:GetService("RunService").Heartbeat:Connect(function()
				if tick() - lastAction >= 60 then
					performAntiAFK()
				end
			end)
			
			-- Also hook into Idled event
			LocalPlayer.Idled:connect(function()
				if antiAFKEnabled then
					VirtualUser:CaptureController()
					VirtualUser:ClickButton2(Vector2.new())
				end
			end)
			
			WindUI:Notify({
				Title = "Anti AFK Enabled",
				Content = "You will no longer be kicked for inactivity.",
				Icon = "shield-check",
				Duration = 5,
			})
		else
			statusParagraph:SetDesc("Anti AFK is currently disabled.")
			
			if afkConnection then
				afkConnection:Disconnect()
				afkConnection = nil
			end
			
			WindUI:Notify({
				Title = "Anti AFK Disabled",
				Content = "Anti AFK protection has been turned off.",
				Icon = "shield-off",
				Duration = 5,
			})
		end
	end
})

Tabs.MainTab:Section({
	Title = "Statistics",
})

-- Statistics Display
local statsText = Tabs.MainTab:Paragraph{
	Title = "Session Statistics",
	Desc = "Actions performed: 0\nLast action: Never"
}

-- Update stats every 5 seconds
spawn(function()
	while wait(5) do
		if antiAFKEnabled then
			local timeSince = math.floor(tick() - lastAction)
			statsText:SetDesc(string.format("Actions performed: %d\nLast action: %d seconds ago", actionCount, timeSince))
		end
	end
end)

-- Manual Action Button
Tabs.MainTab:Button({
	Title = "Perform Manual Action",
	Desc = "Manually trigger anti AFK action",
	Callback = function() 
		if antiAFKEnabled then
			performAntiAFK()
			WindUI:Notify({
				Title = "Manual Action",
				Content = "Anti AFK action performed manually.",
				Icon = "mouse-pointer-2",
				Duration = 3,
			})
		else
			WindUI:Notify({
				Title = "Error",
				Content = "Please enable Anti AFK first.",
				Icon = "alert-circle",
				Duration = 3,
			})
		end
	end
})

-- Farm Tab
Tabs.FarmTab:Section({
    Title = "Auto Mining",
})

Tabs.FarmTab:Paragraph{
    Title = "Auto Mining",
    Desc = "Automatically fly to ores and mine them. The script will detect nearby ores and farm them automatically."
}

local miningToggle = Tabs.FarmTab:Toggle({
    Title = "Enable Auto Mining",
    Icon = "pickaxe",
    Default = false,
    Callback = function(state)
        autoMining = state
        
        if state then
            startAutoMining()
            WindUI:Notify({
                Title = "Auto Mining Enabled",
                Content = "Bot will now automatically mine ores.",
                Icon = "pickaxe",
                Duration = 3,
            })
        else
            if farmConnection then
                farmConnection:Disconnect()
                farmConnection = nil
            end
            WindUI:Notify({
                Title = "Auto Mining Disabled",
                Content = "Auto mining has been stopped.",
                Icon = "x",
                Duration = 3,
            })
        end
    end
})

Tabs.FarmTab:Slider({
    Title = "Fly Speed",
    Value = {
        Min = 20,
        Max = 150,
        Default = 50,
    },
    Callback = function(value)
        flySpeed = value
    end
})

Tabs.FarmTab:Slider({
    Title = "Mining Range",
    Value = {
        Min = 5,
        Max = 50,
        Default = 20,
    },
    Callback = function(value)
        miningRange = value
    end
})

-- Combat Tab
Tabs.CombatTab:Section({
    Title = "Auto Kill",
})

Tabs.CombatTab:Paragraph{
    Title = "Auto Kill Zombie",
    Desc = "Automatically detect and kill nearby zombies. The bot will fly to zombies and attack them."
}

local killToggle = Tabs.CombatTab:Toggle({
    Title = "Enable Auto Kill Zombie",
    Icon = "sword",
    Default = false,
    Callback = function(state)
        autoKillZombie = state
        
        if state then
            startAutoKill()
            WindUI:Notify({
                Title = "Auto Kill Enabled",
                Content = "Bot will now automatically kill zombies.",
                Icon = "sword",
                Duration = 3,
            })
        else
            if killConnection then
                killConnection:Disconnect()
                killConnection = nil
            end
            WindUI:Notify({
                Title = "Auto Kill Disabled",
                Content = "Auto kill has been stopped.",
                Icon = "x",
                Duration = 3,
            })
        end
    end
})

Tabs.CombatTab:Button({
    Title = "Kill Nearest Zombie",
    Desc = "Manually kill the nearest zombie",
    Callback = function()
        local zombie = findNearestZombie()
        if zombie then
            local zombieHrp = zombie:FindFirstChild("HumanoidRootPart")
            if zombieHrp then
                local hrp = getHumanoidRootPart()
                if hrp then
                    tweenTo(zombieHrp.Position, flySpeed)
                end
            end
            WindUI:Notify({
                Title = "Targeting Zombie",
                Content = "Flying to nearest zombie.",
                Icon = "crosshair",
                Duration = 3,
            })
        else
            WindUI:Notify({
                Title = "No Zombie Found",
                Content = "No zombies detected nearby.",
                Icon = "alert-circle",
                Duration = 3,
            })
        end
    end
})

-- Misc Tab
Tabs.MiscTab:Section({
    Title = "Player Settings",
})

Tabs.MiscTab:Button({
    Title = "Reset Stats",
    Desc = "Reset collected stats and kills counter",
    Callback = function()
        statsCollected = 0
        zombiesKilled = 0
        actionCount = 0
        WindUI:Notify({
            Title = "Stats Reset",
            Content = "All statistics have been reset.",
            Icon = "refresh-ccw",
            Duration = 3,
        })
    end
})

Tabs.MiscTab:Button({
    Title = "Teleport to Spawn",
    Desc = "Teleport back to spawn point",
    Callback = function()
        local hrp = getHumanoidRootPart()
        if hrp then
            hrp.CFrame = CFrame.new(0, 50, 0)
            WindUI:Notify({
                Title = "Teleported",
                Content = "Teleported to spawn.",
                Icon = "home",
                Duration = 3,
            })
        end
    end
})

-- Info Tab
Tabs.InfoTab:Section({
	Title = "Script Information",
})

Tabs.InfoTab:Paragraph{
	Title = "The Forge - Complete Hub",
	Desc = "Version: 2.0\nGame ID: 76558904092080\n\nAll-in-one script with Anti AFK, Auto Mining, and Auto Kill features."
}

Tabs.InfoTab:Section({
	Title = "Statistics",
})

local allStatsText = Tabs.InfoTab:Paragraph{
	Title = "Session Statistics",
	Desc = "Anti AFK Actions: 0\nOres Collected: 0\nZombies Killed: 0"
}

-- Update all stats
spawn(function()
	while wait(2) do
		allStatsText:SetDesc(string.format("Anti AFK Actions: %d\nOres Collected: %d\nZombies Killed: %d", actionCount, statsCollected, zombiesKilled))
	end
end)

Tabs.InfoTab:Section({
	Title = "Features",
})

Tabs.InfoTab:Paragraph{
	Title = "Complete Feature List",
	Desc = "• Anti AFK with auto input simulation\n• Auto Mining with fly system\n• Auto Kill Zombie\n• Adjustable fly speed & range\n• Session statistics\n• Remote service integration"
}

Tabs.InfoTab:Paragraph{
	Title = "Remote Services Used",
	Desc = "• ToolService (Tool activation)\n• CharacterService (Equip items)\n• ProximityService (Forge/Mine)\n• All official game services"
}

Tabs.InfoTab:Button({
	Title = "Test Notification",
	Desc = "Click to test notification system",
	Callback = function() 
		WindUI:Notify({
			Title = "Test Notification",
			Content = "Notification system is working correctly!",
			Icon = "bell",
			Duration = 5,
		})
	end
})

-- Initial notification
WindUI:Notify({
	Title = "The Forge - Complete Hub",
	Content = "Script loaded successfully!\nAll features ready to use.",
	Icon = "check-circle",
	Duration = 6,
})

print("The Forge - Complete Hub script loaded successfully!")
