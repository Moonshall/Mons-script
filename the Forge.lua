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
local NatHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/dy1zn4t/bmF0dWk-/refs/heads/main/ui.lua"))()
local Window = NatHub:CreateWindow({
	Title = "NatHub",
	Icon = "rbxassetid://113216930555884",
	Author = "Script Hub",
	Folder = "NatHub",
	Size = UDim2.fromOffset(580, 460),
	LiveSearchDropdown = true,
    AutoSave = true,
    FileSaveName = "NatHub_Config.json",
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

-- Noclip Function (only active during flying)
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

-- Auto Tap Functions for Mining
local function startMiningTap()
    if miningTapConnection then
        miningTapConnection:Disconnect()
    end
    miningTapConnection = RunService.Heartbeat:Connect(function()
        if autoMining then
            activateTool()
            task.wait(0.05) -- Small delay between taps
        end
    end)
end

local function stopMiningTap()
    if miningTapConnection then
        miningTapConnection:Disconnect()
        miningTapConnection = nil
    end
end

-- Auto Tap Functions for Killing
local function startKillTap()
    if killTapConnection then
        killTapConnection:Disconnect()
    end
    killTapConnection = RunService.Heartbeat:Connect(function()
        if autoKillZombie then
            activateTool()
            task.wait(0.05) -- Small delay between taps
        end
    end)
end

local function stopKillTap()
    if killTapConnection then
        killTapConnection:Disconnect()
        killTapConnection = nil
    end
end

local function findNearestOre()
    local hrp = getHumanoidRootPart()
    if not hrp then return nil end
    
    local nearestOre = nil
    local nearestDistance = math.huge
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local isOre = false
            
            -- Check if it's an ore
            if obj.Name:lower():find("ore") or obj.Name:lower():find("rock") or obj.Name:lower():find("stone") then
                isOre = true
            else
                -- Check against ore names list
                for _, oreName in pairs(oreNames) do
                    if obj.Name:find(oreName) then
                        isOre = true
                        break
                    end
                end
            end
            
            if isOre then
                -- Filter by selected ore type
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
                
                -- Check if it's an enemy NPC
                if selectedNPC == "All" then
                    -- Check against common enemy names
                    for _, enemyName in pairs(npcNames) do
                        if npc.Name:lower():find(enemyName:lower()) then
                            isEnemy = true
                            break
                        end
                    end
                else
                    -- Check for specific NPC
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
    
    -- Method 3: VirtualInputManager for mobile/PC
    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.01)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
    
    -- Method 4: UserInputService simulation
    pcall(function()
        local UIS = game:GetService("UserInputService")
        local mouse = LocalPlayer:GetMouse()
        if mouse and tool then
            mouse1press()
            task.wait(0.01)
            mouse1release()
        end
    end)
end

local function equipPickaxe()
    local char = getCharacter()
    if not char then return false end
    
    -- Check if already equipped
    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool and (currentTool.Name:lower():find("pick") or currentTool.Name:lower():find("drill")) then
        return true
    end
    
    -- Try to equip from backpack or inventory
    local pickaxeNames = {"Pickaxe", "Ember Pickaxe", "Titan Pick", "Crystal Carver", "Obsidian Drill", "Stone Pickaxe", "Iron Pickaxe"}
    
    -- Method 1: Check backpack
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
    
    -- Method 2: Use remote service
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
    
    -- Check if already equipped
    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool and (currentTool.Name:lower():find("sword") or currentTool.Name:lower():find("blade") or 
                        currentTool.Name:lower():find("axe") or currentTool.Name:lower():find("hammer") or
                        currentTool.Name:lower():find("cleaver")) then
        return true
    end
    
    -- Try to equip from backpack or inventory
    local weaponNames = {"Sword", "Frostbite Blade", "Shadow Cleaver", "Void Hammer", "Stormbreaker Axe", "Molten Warhammer", "Iron Sword", "Steel Blade"}
    
    -- Method 1: Check backpack
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
    
    -- Method 2: Use remote service
    for _, name in pairs(weaponNames) do
        pcall(function()
            Services.Character.RF.EquipItem:InvokeServer(name)
        end)
    end
    
    task.wait(0.2)
    return char:FindFirstChildOfClass("Tool") ~= nil
end

local function forge(target)
    pcall(function()
        Services.Proximity.RF.Forge:InvokeServer(target)
    end)
end

local function openDialogue(npc)
    pcall(function()
        Services.Proximity.RF.Dialogue:InvokeServer(npc)
    end)
end

local function runDialogueCommand(command)
    pcall(function()
        Services.Dialogue.RF.RunCommand:InvokeServer(command)
    end)
end

local function getPlayerEquipment()
    local success, result = pcall(function()
        return Services.Status.RF.GetPlayerEquipmentInfo:InvokeServer()
    end)
    return success and result or nil
end

local function findNearestSellNPC()
    local hrp = getHumanoidRootPart()
    if not hrp then return nil end
    
    local nearestNPC = nil
    local nearestDistance = math.huge
    
    -- NPC names from list
    local npcNames = {"Brakk", "Lira", "Oskar", "Tolin", "Mira", "Kaen", "Sela", "Drax", "Fynn", "Valeen", 
                      "Rudo", "Elwyn", "Jarrick", "Nora", "Taro", "Garm", "Vella", "Kard", "Myra", "Thorne"}
    
    for _, npc in pairs(workspace:GetDescendants()) do
        if npc:IsA("Model") then
            local found = npc.Name:lower():find("merchant") or npc.Name:lower():find("shop") or npc.Name:lower():find("sell")
            if not found then
                for _, name in pairs(npcNames) do
                    if npc.Name:find(name) then
                        found = true
                        break
                    end
                end
            end
            
            if found then
                local npcHrp = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart")
                if npcHrp then
                    local distance = (hrp.Position - npcHrp.Position).Magnitude
                    if distance < nearestDistance and distance < 1000 then
                        nearestDistance = distance
                        nearestNPC = npc
                    end
                end
            end
        end
    end
    
    return nearestNPC
end

local function findNearestForgeStation()
    local hrp = getHumanoidRootPart()
    if not hrp then return nil end
    
    local nearestForge = nil
    local nearestDistance = math.huge
    
    -- Check workspace for forge stations
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Part") then
            local isForge = false
            
            -- Check common forge names
            if obj.Name:lower():find("forge") or obj.Name:lower():find("anvil") or 
               obj.Name:lower():find("craft") or obj.Name:lower():find("furnace") or
               obj.Name:lower():find("smithing") or obj.Name:lower():find("workbench") then
                isForge = true
            end
            
            if isForge then
                local forgePart = obj:IsA("Part") and obj or obj:FindFirstChild("Part") or obj:FindFirstChildWhichIsA("BasePart")
                if forgePart then
                    local distance = (hrp.Position - forgePart.Position).Magnitude
                    if distance < nearestDistance and distance < 1000 then
                        nearestDistance = distance
                        nearestForge = obj
                    end
                end
            end
        end
    end
    
    return nearestForge
end

-- Auto Mining Function
local function startAutoMining()
    if farmConnection then
        farmConnection:Disconnect()
    end
    
    -- Start tapping first
    startMiningTap()
    
    -- Then equip pickaxe
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
                    -- Re-equip pickaxe if needed
                    local char = getCharacter()
                    if char and not char:FindFirstChildOfClass(\"Tool\") then
                        equipPickaxe()
                    end
                    
                    forge(ore.Parent)
                    
                    -- Check if ore still exists before incrementing
                    if ore and ore.Parent then
                        statsCollected = statsCollected + 1
                    end
                end
            end
        end
        
        wait(0.5)
    end)
end

-- Auto Kill Zombie Function
local currentTarget = nil

local function startAutoKill()
    if killConnection then
        killConnection:Disconnect()
    end
    
    currentTarget = nil
    
    -- Start tapping first
    startKillTap()
    
    -- Then equip weapon
    task.wait(0.2)
    equipWeapon()
    
    killConnection = RunService.Heartbeat:Connect(function()
        if not autoKillZombie then return end
        
        -- Check if current target is still valid and alive
        if currentTarget then
            local targetHumanoid = currentTarget:FindFirstChild("Humanoid")
            if not targetHumanoid or targetHumanoid.Health <= 0 or not currentTarget.Parent then
                -- Target is dead or invalid, increment kill counter
                if targetHumanoid and targetHumanoid.Health <= 0 then
                    zombiesKilled = zombiesKilled + 1
                end
                currentTarget = nil
            end
        end
        
        -- Find new target only if no current target
        if not currentTarget then
            currentTarget = findNearestZombie()
        end
        
        -- Attack current target
        if currentTarget then
            local hrp = getHumanoidRootPart()
            local zombieHrp = currentTarget:FindFirstChild("HumanoidRootPart")
            local zombieHumanoid = currentTarget:FindFirstChild("Humanoid")
            
            if hrp and zombieHrp and zombieHumanoid and zombieHumanoid.Health > 0 then
                local distance = (hrp.Position - zombieHrp.Position).Magnitude
                
                if distance > 8 then
                    tweenTo(zombieHrp.Position + Vector3.new(0, 2, 0), flySpeed)
                else
                    -- Face the target and stay close
                    hrp.CFrame = CFrame.new(hrp.Position, zombieHrp.Position)
                    
                    -- Re-equip weapon if needed
                    local char = getCharacter()
                    if char and not char:FindFirstChildOfClass("Tool") then
                        equipWeapon()
                    end
                end
            else
                -- Target became invalid during this frame
                currentTarget = nil
            end
        end
        
        wait(0.2)
    end)
end

-- Auto Sell Function
local function startAutoSell()
    if sellConnection then
        sellConnection:Disconnect()
    end
    
    sellConnection = RunService.Heartbeat:Connect(function()
        if not autoSell then return end
        
        local npc = findNearestSellNPC()
        if npc then
            local hrp = getHumanoidRootPart()
            local npcPart = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart")
            
            if hrp and npcPart then
                local distance = (hrp.Position - npcPart.Position).Magnitude
                
                if distance > 10 then
                    tweenTo(npcPart.Position + Vector3.new(0, 3, 0), flySpeed)
                else
                    openDialogue(npc)
                    wait(0.5)
                    
                    -- Sell specific item or all
                    if selectedSellItem == "All Items" then
                        runDialogueCommand("Sell All")
                        runDialogueCommand("Sell")
                    else
                        runDialogueCommand("Sell " .. selectedSellItem)
                    end
                    
                    itemsSold = itemsSold + 1
                    wait(2)
                end
            end
        end
        
        wait(1)
    end)
end

-- Auto Forge Function
local function startAutoForge()
    if forgeConnection then
        forgeConnection:Disconnect()
    end
    
    forgeConnection = RunService.Heartbeat:Connect(function()
        if not autoForge then return end
        
        local forgeStation = findNearestForgeStation()
        if forgeStation then
            local hrp = getHumanoidRootPart()
            local forgePart = forgeStation
            
            -- Get the proper part if it's a model
            if forgeStation:IsA("Model") then
                forgePart = forgeStation:FindFirstChild("Part") or forgeStation:FindFirstChildWhichIsA("BasePart")
            end
            
            if hrp and forgePart then
                local distance = (hrp.Position - forgePart.Position).Magnitude
                
                if distance > 15 then
                    tweenTo(forgePart.Position + Vector3.new(0, 5, 0), flySpeed)
                else
                    -- Try multiple forge methods
                    pcall(function()
                        -- Method 1: Direct forge call
                        Services.Proximity.RF.Forge:InvokeServer(forgeStation)
                    end)
                    
                    wait(0.3)
                    
                    pcall(function()
                        -- Method 2: Dialogue-based forge
                        Services.Proximity.RF.Dialogue:InvokeServer(forgeStation)
                    end)
                    
                    wait(0.5)
                    
                    pcall(function()
                        -- Method 3: Run forge commands
                        Services.Dialogue.RF.RunCommand:InvokeServer("Forge")
                        Services.Dialogue.RF.RunCommand:InvokeServer("Craft")
                        Services.Dialogue.RF.RunCommand:InvokeServer("Create")
                    end)
                    
                    itemsForged = itemsForged + 1
                    wait(3)
                end
            end
        else
            -- Debug: No forge station found
            print("No forge station found nearby")
        end
        
        wait(1)
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
			
		else
			statusParagraph:SetDesc("Anti AFK is currently disabled.")
			
			if afkConnection then
				afkConnection:Disconnect()
				afkConnection = nil
			end
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
		end
	end
})

-- Farm Tab
Tabs.FarmTab:Section({
    Title = "Auto Mining",
})

Tabs.FarmTab:Paragraph{
    Title = "Auto Mining",
    Desc = "Automatically fly to ores and mine them. Select specific ore type or mine all ores."
}

Tabs.FarmTab:Dropdown({
    Title = "Select Ore Type",
    Values = oreNames,
    Value = "All",
    Callback = function(value)
        selectedOre = value
    end
})

local miningToggle = Tabs.FarmTab:Toggle({
    Title = "Enable Auto Mining",
    Icon = "pickaxe",
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

Tabs.FarmTab:Section({
    Title = "Auto Sell",
})

Tabs.FarmTab:Paragraph{
    Title = "Auto Sell Items",
    Desc = "Automatically fly to merchant/shop NPC and sell your items. Select specific item or sell all."
}

Tabs.FarmTab:Dropdown({
    Title = "Select Item to Sell",
    Values = sellItemNames,
    Value = "All Items",
    Callback = function(value)
        selectedSellItem = value
    end
})

local sellToggle = Tabs.FarmTab:Toggle({
    Title = "Enable Auto Sell",
    Icon = "dollar-sign",
    Default = false,
    Callback = function(state)
        autoSell = state
        
        if state then
            startAutoSell()
        else
            if sellConnection then
                sellConnection:Disconnect()
                sellConnection = nil
            end
            disableNoclip()
        end
    end
})

Tabs.FarmTab:Button({
    Title = "Sell Items Once",
    Desc = "Manually sell items at nearest merchant",
    Callback = function()
        local npc = findNearestSellNPC()
        if npc then
            local npcPart = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart")
            if npcPart then
                local hrp = getHumanoidRootPart()
                if hrp then
                    tweenTo(npcPart.Position, flySpeed)
                    wait(2)
                    openDialogue(npc)
                    wait(0.5)
                    runDialogueCommand("Sell")
                end
            end

        end
    end
})

Tabs.FarmTab:Section({
    Title = "Auto Forge",
})

Tabs.FarmTab:Paragraph{
    Title = "Auto Forge Items",
    Desc = "Automatically fly to forge station and craft items."
}

local forgeToggle = Tabs.FarmTab:Toggle({
    Title = "Enable Auto Forge",
    Icon = "flame",
    Default = false,
    Callback = function(state)
        autoForge = state
        
        if state then
            startAutoForge()
        else
            if forgeConnection then
                forgeConnection:Disconnect()
                forgeConnection = nil
            end
            disableNoclip()
        end
    end
})

-- Combat Tab
Tabs.CombatTab:Section({
    Title = "Auto Kill",
})

Tabs.CombatTab:Paragraph{
    Title = "Auto Kill NPC",
    Desc = "Automatically detect and kill nearby NPCs/enemies. Select specific NPC type or kill all."
}

Tabs.CombatTab:Dropdown({
    Title = "Select NPC Type",
    Values = npcNames,
    Value = "All",
    Callback = function(value)
        selectedNPC = value
    end
})

local killToggle = Tabs.CombatTab:Toggle({
    Title = "Enable Auto Kill Zombie",
    Icon = "sword",
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
        itemsSold = 0
        itemsForged = 0
    end
})

Tabs.MiscTab:Button({
    Title = "Check Equipment",
    Desc = "Get player equipment information",
    Callback = function()
        local equipment = getPlayerEquipment()
        if equipment then
            print("Equipment Info:", equipment)
        end
    end
})

Tabs.MiscTab:Button({
    Title = "Teleport to Spawn",
    Desc = "Teleport back to spawn point",
    Callback = function()
        local hrp = getHumanoidRootPart()
        if hrp then
            hrp.CFrame = CFrame.new(0, 50, 0)
        end
    end
})

-- Info Tab
Tabs.InfoTab:Section({
	Title = "Script Information",
})

Tabs.InfoTab:Paragraph{
	Title = "Hi",
	Desc = "Version: 2.0\nGame ID: 76558904092080\n\nAll-in-one script with Anti AFK, Auto Mining, and Auto Kill features."
}

Tabs.InfoTab:Section({
	Title = "Statistics",
})

local allStatsText = Tabs.InfoTab:Paragraph{
	Title = "Session Statistics",
	Desc = "Anti AFK Actions: 0\nOres Collected: 0\nZombies Killed: 0\nItems Sold: 0\nItems Forged: 0"
}

-- Update all stats
spawn(function()
	while wait(2) do
		allStatsText:SetDesc(string.format("Anti AFK Actions: %d\nOres Collected: %d\nZombies Killed: %d\nItems Sold: %d\nItems Forged: %d", actionCount, statsCollected, zombiesKilled, itemsSold, itemsForged))
	end
end)

Tabs.InfoTab:Section({
	Title = "Features",
})

Tabs.InfoTab:Paragraph{
	Title = "Complete Feature List",
	Desc = "• Anti AFK with auto input simulation\n• Auto Mining with noclip & auto-tap\n• Auto Kill NPC with weapon & auto-tap\n• Auto Sell to Merchant/Shop\n• Auto Forge crafting\n• Fixed fly speed (50)\n• Noclip enabled during farming\n• Session statistics\n• Remote service integration"
}

Tabs.InfoTab:Paragraph{
	Title = "Remote Services Used",
	Desc = "• ToolService (Tool activation)\n• CharacterService (Equip items)\n• ProximityService (Dialogue, Forge)\n• DialogueService (Run commands)\n• StatusService (Equipment info)\n• All official game services"
}

-- Load notification
NatHub:Notify({
	Title = "NatHub",
	Content = "Script loaded successfully!",
	Icon = "check-circle",
	Duration = 3,
})

print("NatHub script loaded successfully!")

