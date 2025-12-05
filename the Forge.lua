-- The Forge - Complete Script (Orion UI)
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

-- Load Orion UI Library
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

local Window = OrionLib:MakeWindow({
    Name = "The Forge - Auto Farm Script",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "TheForgeConfig",
    IntroEnabled = false
})

OrionLib:MakeNotification({
	Name = "The Forge Script",
	Content = "Script loaded successfully!",
	Image = "rbxassetid://4483345998",
	Time = 5
})

-- Create Tabs
local MainTab = Window:MakeTab({
	Name = "Anti AFK",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local FarmTab = Window:MakeTab({
	Name = "Auto Farm",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local CombatTab = Window:MakeTab({
	Name = "Combat",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local MiscTab = Window:MakeTab({
	Name = "Misc",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local InfoTab = Window:MakeTab({
	Name = "Info",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

-- Anti AFK Variables
local antiAFKEnabled = false
local afkConnection = nil
local lastAction = tick()
local actionCount = 0

-- Auto Farm Variables
local autoMining = false
local autoKillZombie = false
local autoSell = false
local autoForge = false
local selectedOre = "All"
local selectedNPC = "All"
local selectedSellItem = "All Items"
local flySpeed = 50
local miningRange = 20
local farmConnection = nil
local killConnection = nil
local sellConnection = nil
local forgeConnection = nil
local noclipConnection = nil
local miningTapConnection = nil
local killTapConnection = nil
local statsCollected = 0
local zombiesKilled = 0
local itemsSold = 0
local itemsForged = 0
local currentTarget = nil

-- Ore Names List
local oreNames = {"All","Stone", "Emberstone", "Frost Ore", "Ironcore", "Shadow Shard", "Glimmer Crystal", 
                  "Nova Ore", "Titan Rock", "Luminite", "Darksteel Chunk", "Magma Fragment",
                  "Storm Quartz", "Ancient Relic Stone", "Void Ore", "Copperlite", "Starfall Gem",
                  "Dragonstone", "Rune Ore", "Crystaline Rock", "Obsidian Core", "Radiant Gem"}

-- NPC Names List for Auto Kill
local npcNames = {"All", "Zombie", "Skeleton", "Goblin", "Orc", "Troll", "Dragon", "Spider", "Wolf",
                  "Bear", "Bandit", "Ghost", "Demon", "Undead", "Monster", "Enemy"}

-- Item Names for Selling
local sellItemNames = {"All Items", "Iron Shard", "Crystal Powder", "Forge Catalyst", "Binding Alloy",
                        "Mystic Shard", "Dust Core", "Hardened Metal Plate", "Runic Essence",
                        "Ember Dust", "Luminite Powder"}

-- Anti AFK Function
local function performAntiAFK()
	if not antiAFKEnabled then return end
	
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
	
	actionCount = actionCount + 1
	lastAction = tick()
	
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
		local humanoid = LocalPlayer.Character.Humanoid
		if humanoid.MoveDirection == Vector3.new(0, 0, 0) then
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

-- Noclip Function
local isFlying = false

local function enableNoclip()
    if noclipConnection then return end
    isFlying = true
    noclipConnection = RunService.Stepped:Connect(function()
        if isFlying then
            local char = getCharacter()
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
end

local function disableNoclip()
    isFlying = false
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    local char = getCharacter()
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- Tool Activation
local function activateTool()
    local char = getCharacter()
    if not char then return end
    
    local tool = char:FindFirstChildOfClass("Tool")
    
    -- Method 1: Tool service remote
    pcall(function()
        Services.Tool.RF.ToolActivated:InvokeServer()
    end)
    
    -- Method 2: Direct tool activation
    if tool then
        pcall(function()
            tool:Activate()
        end)
    end
    
    -- Method 3: VirtualInputManager
    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.01)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
    
    -- Method 4: Mouse simulation
    pcall(function()
        if tool then
            mouse1press()
            task.wait(0.01)
            mouse1release()
        end
    end)
end

-- Auto Tap Functions
local function startMiningTap()
    if miningTapConnection then
        miningTapConnection:Disconnect()
    end
    miningTapConnection = RunService.Heartbeat:Connect(function()
        if autoMining then
            activateTool()
            task.wait(0.05)
        end
    end)
end

local function stopMiningTap()
    if miningTapConnection then
        miningTapConnection:Disconnect()
        miningTapConnection = nil
    end
end

local function startKillTap()
    if killTapConnection then
        killTapConnection:Disconnect()
    end
    killTapConnection = RunService.Heartbeat:Connect(function()
        if autoKillZombie then
            activateTool()
            task.wait(0.05)
        end
    end)
end

local function stopKillTap()
    if killTapConnection then
        killTapConnection:Disconnect()
        killTapConnection = nil
    end
end

-- Equipment Functions
local function equipPickaxe()
    local char = getCharacter()
    if not char then return false end
    
    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool and (currentTool.Name:lower():find("pick") or currentTool.Name:lower():find("drill")) then
        return true
    end
    
    local pickaxeNames = {"Pickaxe", "Ember Pickaxe", "Titan Pick", "Crystal Carver", "Obsidian Drill", "Stone Pickaxe", "Iron Pickaxe"}
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, pickaxeName in pairs(pickaxeNames) do
            local tool = backpack:FindFirstChild(pickaxeName)
            if tool and tool:IsA("Tool") then
                local humanoid = getHumanoid()
                if humanoid then
                    humanoid:EquipTool(tool)
                    return true
                end
            end
        end
    end
    
    for _, name in pairs(pickaxeNames) do
        pcall(function()
            Services.Character.RF.EquipItem:InvokeServer(name)
        end)
    end
    
    task.wait(0.2)
    return char:FindFirstChildOfClass("Tool") ~= nil
end

local function equipWeapon()
    local char = getCharacter()
    if not char then return false end
    
    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool and (currentTool.Name:lower():find("sword") or currentTool.Name:lower():find("blade") or 
                        currentTool.Name:lower():find("axe") or currentTool.Name:lower():find("hammer")) then
        return true
    end
    
    local weaponNames = {"Sword", "Frostbite Blade", "Shadow Cleaver", "Void Hammer", "Stormbreaker Axe", "Molten Warhammer", "Iron Sword", "Steel Blade"}
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, weaponName in pairs(weaponNames) do
            local tool = backpack:FindFirstChild(weaponName)
            if tool and tool:IsA("Tool") then
                local humanoid = getHumanoid()
                if humanoid then
                    humanoid:EquipTool(tool)
                    return true
                end
            end
        end
    end
    
    for _, name in pairs(weaponNames) do
        pcall(function()
            Services.Character.RF.EquipItem:InvokeServer(name)
        end)
    end
    
    task.wait(0.2)
    return char:FindFirstChildOfClass("Tool") ~= nil
end

-- Find Functions
local function findNearestOre()
    local hrp = getHumanoidRootPart()
    if not hrp then return nil end
    
    local nearestOre = nil
    local nearestDistance = math.huge
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local isOre = false
            
            if obj.Name:lower():find("ore") or obj.Name:lower():find("rock") or obj.Name:lower():find("stone") then
                isOre = true
            else
                for _, oreName in pairs(oreNames) do
                    if obj.Name:find(oreName) then
                        isOre = true
                        break
                    end
                end
            end
            
            if isOre then
                if selectedOre ~= "All" and not obj.Name:find(selectedOre) then
                    isOre = false
                end
                
                if isOre then
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
        if npc:IsA("Model") and npc:FindFirstChild("Humanoid") then
            local npcHumanoid = npc:FindFirstChild("Humanoid")
            if npcHumanoid and npcHumanoid.Health > 0 then
                local isEnemy = false
                
                if selectedNPC == "All" then
                    for _, enemyName in pairs(npcNames) do
                        if npc.Name:lower():find(enemyName:lower()) then
                            isEnemy = true
                            break
                        end
                    end
                else
                    if npc.Name:lower():find(selectedNPC:lower()) then
                        isEnemy = true
                    end
                end
                
                if isEnemy then
                    local npcHrp = npc:FindFirstChild("HumanoidRootPart")
                    if npcHrp then
                        local distance = (hrp.Position - npcHrp.Position).Magnitude
                        if distance < nearestDistance and distance < 500 then
                            nearestDistance = distance
                            nearestZombie = npc
                        end
                    end
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
    
    enableNoclip()
    
    local TweenService = game:GetService("TweenService")
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(targetPos)}
    )
    
    tween:Play()
    tween.Completed:Connect(function()
        disableNoclip()
    end)
    
    return tween
end

-- Auto Functions
local function startAutoMining()
    if farmConnection then
        farmConnection:Disconnect()
    end
    
    startMiningTap()
    task.wait(0.2)
    equipPickaxe()
    
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
                    local char = getCharacter()
                    if char and not char:FindFirstChildOfClass("Tool") then
                        equipPickaxe()
                    end
                    
                    pcall(function()
                        Services.Proximity.RF.Forge:InvokeServer(ore.Parent)
                    end)
                    
                    if ore and ore.Parent then
                        statsCollected = statsCollected + 1
                    end
                end
            end
        end
        
        wait(0.5)
    end)
end

local function startAutoKill()
    if killConnection then
        killConnection:Disconnect()
    end
    
    currentTarget = nil
    startKillTap()
    task.wait(0.2)
    equipWeapon()
    
    killConnection = RunService.Heartbeat:Connect(function()
        if not autoKillZombie then return end
        
        if currentTarget then
            local targetHumanoid = currentTarget:FindFirstChild("Humanoid")
            if not targetHumanoid or targetHumanoid.Health <= 0 or not currentTarget.Parent then
                if targetHumanoid and targetHumanoid.Health <= 0 then
                    zombiesKilled = zombiesKilled + 1
                end
                currentTarget = nil
            end
        end
        
        if not currentTarget then
            currentTarget = findNearestZombie()
        end
        
        if currentTarget then
            local hrp = getHumanoidRootPart()
            local zombieHrp = currentTarget:FindFirstChild("HumanoidRootPart")
            local zombieHumanoid = currentTarget:FindFirstChild("Humanoid")
            
            if hrp and zombieHrp and zombieHumanoid and zombieHumanoid.Health > 0 then
                local distance = (hrp.Position - zombieHrp.Position).Magnitude
                
                if distance > 8 then
                    tweenTo(zombieHrp.Position + Vector3.new(0, 2, 0), flySpeed)
                else
                    hrp.CFrame = CFrame.new(hrp.Position, zombieHrp.Position)
                    
                    local char = getCharacter()
                    if char and not char:FindFirstChildOfClass("Tool") then
                        equipWeapon()
                    end
                end
            else
                currentTarget = nil
            end
        end
        
        wait(0.2)
    end)
end

-- UI ELEMENTS

-- Main Tab
MainTab:AddSection({Name = "Anti AFK Status"})

MainTab:AddParagraph("About", "Prevents Roblox from kicking you after 20 minutes of inactivity.")

MainTab:AddToggle({
	Name = "Enable Anti AFK",
	Default = false,
	Callback = function(state)
		antiAFKEnabled = state
		
		if state then
			if afkConnection then
				afkConnection:Disconnect()
			end
			
			afkConnection = RunService.Heartbeat:Connect(function()
				if tick() - lastAction >= 60 then
					performAntiAFK()
				end
			end)
			
			LocalPlayer.Idled:connect(function()
				if antiAFKEnabled then
					VirtualUser:CaptureController()
					VirtualUser:ClickButton2(Vector2.new())
				end
			end)
		else
			if afkConnection then
				afkConnection:Disconnect()
				afkConnection = nil
			end
		end
	end
})

MainTab:AddButton({
	Name = "Perform Manual Action",
	Callback = function()
		if antiAFKEnabled then
			performAntiAFK()
		end
	end
})

-- Farm Tab
FarmTab:AddSection({Name = "Auto Mining"})

FarmTab:AddParagraph("Auto Mining", "Automatically fly to ores and mine them.")

FarmTab:AddDropdown({
	Name = "Select Ore Type",
	Default = "All",
	Options = oreNames,
	Callback = function(value)
		selectedOre = value
	end
})

FarmTab:AddToggle({
	Name = "Enable Auto Mining",
	Default = false,
	Callback = function(state)
		autoMining = state
		
		if state then
			startAutoMining()
		else
			if farmConnection then
				farmConnection:Disconnect()
				farmConnection = nil
			end
			disableNoclip()
			stopMiningTap()
		end
	end
})

FarmTab:AddSlider({
	Name = "Mining Range",
	Min = 5,
	Max = 50,
	Default = 20,
	Color = Color3.fromRGB(255,255,255),
	Increment = 1,
	ValueName = "studs",
	Callback = function(value)
		miningRange = value
	end
})

-- Combat Tab
CombatTab:AddSection({Name = "Auto Kill"})

CombatTab:AddParagraph("Auto Kill", "Automatically detect and kill nearby NPCs/enemies.")

CombatTab:AddDropdown({
	Name = "Select NPC Type",
	Default = "All",
	Options = npcNames,
	Callback = function(value)
		selectedNPC = value
	end
})

CombatTab:AddToggle({
	Name = "Enable Auto Kill",
	Default = false,
	Callback = function(state)
		autoKillZombie = state
		
		if state then
			startAutoKill()
		else
			if killConnection then
				killConnection:Disconnect()
				killConnection = nil
			end
			disableNoclip()
			stopKillTap()
			currentTarget = nil
		end
	end
})

-- Misc Tab
MiscTab:AddSection({Name = "Player Settings"})

MiscTab:AddButton({
	Name = "Reset Stats",
	Callback = function()
		statsCollected = 0
		zombiesKilled = 0
		actionCount = 0
		itemsSold = 0
		itemsForged = 0
		OrionLib:MakeNotification({
			Name = "Stats Reset",
			Content = "All statistics have been reset!",
			Image = "rbxassetid://4483345998",
			Time = 3
		})
	end
})

MiscTab:AddButton({
	Name = "Teleport to Spawn",
	Callback = function()
		local hrp = getHumanoidRootPart()
		if hrp then
			hrp.CFrame = CFrame.new(0, 50, 0)
		end
	end
})

-- Info Tab
InfoTab:AddSection({Name = "Script Information"})

InfoTab:AddParagraph("The Forge Script v2.1", "All-in-one script with Anti AFK, Auto Mining, and Auto Kill features.")

InfoTab:AddParagraph("Features", "• Anti AFK\n• Auto Mining\n• Auto Kill NPC\n• Noclip during farming\n• Auto-tap system\n• Session statistics")

InfoTab:AddLabel("Session Stats:")

spawn(function()
	while wait(5) do
		InfoTab:AddLabel("Actions: "..actionCount.." | Ores: "..statsCollected.." | Kills: "..zombiesKilled)
	end
end)

OrionLib:Init()
