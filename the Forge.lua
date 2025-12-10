

local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
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
    Forge = ReplicatedStorage.Shared.Packages.Knit.Services.ForgeService,
}

-- Load NatHub UI Library
local success, NatHub = pcall(function()
    local uiCode = game:HttpGet("https://raw.githubusercontent.com/dy1zn4t/bmF0dWk-/refs/heads/main/ui.lua")
    if not uiCode or uiCode == "" then
        error("Failed to fetch UI library")
    end
    return loadstring(uiCode)()
end)

if not success or not NatHub then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "UI Load Error";
        Text = "Failed to load NatHub UI. Please check your internet connection.";
        Duration = 10;
    })
    error("Failed to load NatHub UI Library: " .. tostring(NatHub))
end

local Window = NatHub:CreateWindow({
	Title = "Nathub",
	Icon = "rbxassetid://113216930555884",
	Author = "By Mons",
	Folder = "TheForge",
	Size = UDim2.fromOffset(580, 460),
	LiveSearchDropdown = true,
    AutoSave = true,
    FileSaveName = "TheForge_Config.json",
    ShowMinimizeButton = true,
})

-- Track UI visibility with keybind
local UIS = game:GetService("UserInputService")
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        isUIVisible = not isUIVisible
    end
end)

-- Create Tabs (NatHub format)
local Tabs = {
    InfoTab = Window:Tab({ Title = "Info", Icon = "info" }),
	FarmTab = Window:Tab({ Title = "Farm", Icon = "pickaxe" }),
	CombatTab = Window:Tab({ Title = "Combat", Icon = "sword" }),
	MiscTab = Window:Tab({ Title = "Misc", Icon = "tool" }),
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
local isUIVisible = false
local autoForge = false
local selectedOre = "Stone"
local selectedNPC = "Zombie"
local selectedSellCategory = "All Items"
local flySpeed = 30
local miningRange = 15
local autoForgeEnabled = false
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

-- Anti-Cheat Bypass Settings
local useAntiCheat = true
local humanizedSpeed = true
local randomDelays = true

-- Ore Names List (Must match game exactly)
local oreNames = {
    "Rock", "Earth Crystal", "Basalt Rock", "Cyan Crystal", "Light Crystal", 
    "Violet Crystal", "BasaltVein", "Boulder", "Volcanic Rock", "Pebble", 
    "Basalt Core", "Lucky Block"
}

-- NPC Names List for Auto Kill
local npcNames = {
    "Delver Zombie", "Deathaxe", "Skeleton", "Axe Skeleton", "Reaper", 
    "Skeleton Rogue", "Blazing Slime", "Bomber", "Slime", "Elite Deathaxe Skeleton", 
    "Elite Zombie", "Brute Zombie", "Elite", "Rogue Skeleton", "Blight Pyromancer", "Zombie"
}

-- Sell by Rarity Categories
local sellCategories = {
    "All Items",
    "Common",
    "Uncommon",
    "Rare",
    "Epic",
    "Legendary",
    "Mythic",
    "Exotic",
    "Ancient",
    "Divine",
    "Exclusive",
    "Limited",
    "Event",
    "Artifact",
    "Quest Item"
}

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

local flying = false

local function enableNoclip()
    if noclipConnection then return end
    flying = true
    noclipConnection = RunService.Stepped:Connect(function()
        if flying then
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
    flying = false
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

-- Tool Activation via ToolService
local function activateTool()
    pcall(function()
        Services.Tool.RF.ToolActivated:InvokeServer()
    end)
end

-- Auto tool loop connections
local miningToolConnection = nil
local killToolConnection = nil

-- Ghost Tap Variables
local ghostTapEnabled = false
local ghostTapSpeed = 10 -- Default: 10 taps per second
local ghostTapConnection = nil

local function performGhostTap()
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local screenSize = camera.ViewportSize
    local centerX = screenSize.X / 2
    local centerY = screenSize.Y / 2
    
    -- Simulate tap at screen center
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
    task.wait(0.01) -- Small delay
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
end

local function startGhostTap()
    if ghostTapConnection then return end
    
    ghostTapConnection = RunService.Heartbeat:Connect(function()
        if ghostTapEnabled then
            performGhostTap()
            task.wait(1 / ghostTapSpeed) -- Delay based on taps per second
        end
    end)
end

local function stopGhostTap()
    if ghostTapConnection then
        ghostTapConnection:Disconnect()
        ghostTapConnection = nil
    end
end

local function startMiningTool()
    if miningToolConnection then miningToolConnection:Disconnect() end
    
    miningToolConnection = RunService.Heartbeat:Connect(function()
        if not autoMining then return end
        if isUIVisible then return end
        
        local ore = findNearestOre()
        if ore then
            local hrp = getHumanoidRootPart()
            if hrp and ore then
                local dist = (hrp.Position - ore.Position).Magnitude
                if dist <= miningRange then
                    equipPickaxe()
                    activateTool()
                end
            end
        end
    end)
end

local function stopMiningTool()
    if miningToolConnection then
        miningToolConnection:Disconnect()
        miningToolConnection = nil
    end
end

local function startKillTool()
    if killToolConnection then killToolConnection:Disconnect() end
    
    killToolConnection = RunService.Heartbeat:Connect(function()
        if not autoKillZombie then return end
        if isUIVisible then return end
        
        if currentTarget then
            local hrp = getHumanoidRootPart()
            local mobHrp = currentTarget:FindFirstChild("HumanoidRootPart")
            if hrp and mobHrp then
                local dist = (hrp.Position - mobHrp.Position).Magnitude
                if dist <= 10 then
                    equipWeapon()
                    activateTool()
                end
            end
        end
    end)
end

local function stopKillTool()
    if killToolConnection then
        killToolConnection:Disconnect()
        killToolConnection = nil
    end
end

local function equipPickaxe()
    local char = getCharacter()
    if not char then return false end
    
    -- Check if already holding pickaxe
    local cur = char:FindFirstChildOfClass("Tool")
    if cur then
        local n = cur.Name:lower()
        if n:find("pick") or n:find("drill") or n:find("mine") then
            return true
        end
    end
    
    -- Try to find and equip pickaxe from backpack
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, t in pairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                local n = t.Name:lower()
                if n:find("pick") or n:find("drill") or n:find("mine") then
                    -- Try using game's Character service first
                    local success = pcall(function()
                        Services.Character.RF.EquipItem:InvokeServer(t.Name)
                    end)
                    if success then
                        task.wait(0.1)
                        return true
                    end
                    
                    -- Fallback to Humanoid:EquipTool
                    local h = getHumanoid()
                    if h then
                        h:EquipTool(t)
                        task.wait(0.1)
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function equipWeapon()
    local char = getCharacter()
    if not char then return false end
    
    -- Check if already holding weapon
    local cur = char:FindFirstChildOfClass("Tool")
    if cur then
        local n = cur.Name:lower()
        if not n:find("pick") and (n:find("sword") or n:find("blade") or n:find("axe") or n:find("hammer") or n:find("spear") or n:find("dagger") or n:find("weapon")) then
            return true
        end
    end
    
    -- Try to find and equip weapon from backpack
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, t in pairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                local n = t.Name:lower()
                -- Weapon keywords, exclude pickaxe
                if not n:find("pick") and not n:find("drill") and (n:find("sword") or n:find("blade") or n:find("axe") or n:find("hammer") or n:find("spear") or n:find("dagger") or n:find("weapon")) then
                    -- Try using game's Character service first
                    local success = pcall(function()
                        Services.Character.RF.EquipItem:InvokeServer(t.Name)
                    end)
                    if success then
                        task.wait(0.1)
                        return true
                    end
                    
                    -- Fallback to Humanoid:EquipTool
                    local h = getHumanoid()
                    if h then
                        h:EquipTool(t)
                        task.wait(0.1)
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function findNearestOre()
    local hrp = getHumanoidRootPart()
    if not hrp then return nil end
    
    local nearestOre = nil
    local nearestDistance = math.huge
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local n = obj.Name:lower()
            -- Skip tools and equipment
            if n:find("pickaxe") or n:find("sword") or n:find("weapon") or n:find("tool") or n:find("stonewakes") then
                continue
            end
            
            -- Skip player stuff
            local p = obj.Parent
            if p and (p.Name == LocalPlayer.Name or p:FindFirstChild("Humanoid")) then
                continue
            end
            
            -- Match selected ore
            if obj.Name:find(selectedOre) then
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
    
    return nearestOre
end

local function findNearestSellNPC()
    local hrp = getHumanoidRootPart()
    if not hrp then return nil end
    
    local nearestNPC = nil
    local nearestDistance = math.huge
    
    -- Prioritize Marbles as sell NPC
    for _, npc in pairs(workspace:GetDescendants()) do
        if npc:IsA("Model") and npc.Name == "Marbles" then
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
    
    -- Fallback to other merchant NPCs if Marbles not found
    if not nearestNPC then
        local npcNames = {"Merchant", "Shop", "Trader", "Vendor", "Brakk", "Lira", "Oskar", "Tolin"}
        
        for _, npc in pairs(workspace:GetDescendants()) do
            if npc:IsA("Model") then
                local found = false
                for _, name in pairs(npcNames) do
                    if npc.Name:lower():find(name:lower()) then
                        found = true
                        break
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
    end
    
    return nearestNPC
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
                
                -- Check for specific selected NPC only
                if npc.Name:lower():find(selectedNPC:lower()) then
                    isEnemy = true
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

-- Anti-Cheat Bypass: Random delay generator
local function getRandomDelay(min, max)
    if not randomDelays then return min end
    return math.random(min * 100, max * 100) / 100
end

-- Anti-Cheat Bypass: Add random offset to position
local function humanizePosition(pos)
    if not humanizedSpeed then return pos end
    local offset = Vector3.new(
        math.random(-2, 2),
        math.random(-1, 1),
        math.random(-2, 2)
    )
    return pos + offset
end

-- Anti-Cheat Bypass: Variable speed
local function getHumanizedSpeed()
    if not humanizedSpeed then return flySpeed end
    return flySpeed + math.random(-5, 5)
end

local function tweenTo(targetPos, speed)
    local hrp = getHumanoidRootPart()
    if not hrp then return end
    
    -- Add random offset to look more human
    if useAntiCheat then
        targetPos = humanizePosition(targetPos)
        speed = getHumanizedSpeed()
    end
    
    local distance = (hrp.Position - targetPos).Magnitude
    
    -- Enable noclip for any distance movement or underground
    if distance > 10 or targetPos.Y < 0 then
        enableNoclip()
    end
    
    -- Don't tween if too close (looks suspicious)
    if distance < 5 then
        hrp.CFrame = CFrame.new(targetPos)
        if not autoMining and not autoKillZombie then
            disableNoclip()
        end
        return
    end
    
    local duration = distance / speed
    
    -- Add slight delay before starting tween
    if useAntiCheat then
        wait(getRandomDelay(0.1, 0.3))
    end
    
    local TweenService = game:GetService("TweenService")
    -- Use Sine easing for more natural movement
    local easingStyle = useAntiCheat and Enum.EasingStyle.Sine or Enum.EasingStyle.Linear
    
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(duration, easingStyle),
        {CFrame = CFrame.new(targetPos)}
    )
    
    tween:Play()
    tween.Completed:Connect(function()
        -- Don't disable noclip immediately if still farming
        if not autoMining and not autoKillZombie then
            disableNoclip()
        end
        -- Add small delay after arriving
        if useAntiCheat then
            wait(getRandomDelay(0.1, 0.2))
        end
    end)
    
    return tween
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

-- Auto Functions
local lastMine = 0
local cd = 0.5

local function startAutoMining()
    if farmConnection then
        farmConnection:Disconnect()
    end
    
    startMiningTool()
    equipPickaxe()
    
    farmConnection = RunService.Heartbeat:Connect(function()
        if not autoMining then return end
        
        local t = tick()
        if t - lastMine < cd then return end
        
        -- Keep pickaxe equipped
        equipPickaxe()
        
        local ore = findNearestOre()
        if ore then
            local hrp = getHumanoidRootPart()
            if hrp then
                local distance = (hrp.Position - ore.Position).Magnitude
                
                if distance > 300 then return end
                
                if distance > miningRange then
                    local targetPos = ore.Position + Vector3.new(0, 3, 0)
                    tweenTo(targetPos, flySpeed)
                end
                
                pcall(function()
                    Services.Proximity.RF.Forge:InvokeServer(ore.Parent)
                end)
                
                statsCollected = statsCollected + 1
                lastMine = t
            end
        end
        
        task.wait(0.3)
    end)
end

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
                    -- Stop and interact
                    disableNoclip()
                    
                    openDialogue(npc)
                    wait(0.5)
                    
                    -- Sell items by category
                    if selectedSellCategory == "All Items" then
                        runDialogueCommand("Sell All")
                        runDialogueCommand("Sell")
                    else
                        -- Sell by rarity category
                        runDialogueCommand("Sell " .. selectedSellCategory)
                    end
                    
                    itemsSold = itemsSold + 1
                    
                    if useAntiCheat then
                        wait(getRandomDelay(1.0, 2.0))
                    else
                        wait(2)
                    end
                end
            end
        end
        
        wait(useAntiCheat and getRandomDelay(0.5, 1.0) or 0.5)
    end)
end

-- Auto Forge Minigame
local forgeMinigameConnection = nil
local isForging = false

local function completeForgeMinigame()
    if isForging then return end
    isForging = true
    
    task.wait(0.2)
    
    -- Auto Melt Phase
    local meltAttempts = 0
    while autoForgeEnabled and meltAttempts < 15 do
        meltAttempts = meltAttempts + 1
        
        pcall(function()
            Services.Forge.RF.ChangeSequence:InvokeServer("Melt")
        end)
        
        task.wait(0.1)
        
        local forgeUI = LocalPlayer.PlayerGui:FindFirstChild("ForgeUI") or LocalPlayer.PlayerGui:FindFirstChild("Forge")
        if not forgeUI or not forgeUI.Enabled then break end
    end
    
    task.wait(0.15)
    
    -- Auto Pour Phase
    local pourAttempts = 0
    while autoForgeEnabled and pourAttempts < 15 do
        pourAttempts = pourAttempts + 1
        
        pcall(function()
            Services.Forge.RF.ChangeSequence:InvokeServer("Pour")
        end)
        
        task.wait(0.1)
        
        local forgeUI = LocalPlayer.PlayerGui:FindFirstChild("ForgeUI") or LocalPlayer.PlayerGui:FindFirstChild("Forge")
        if not forgeUI or not forgeUI.Enabled then break end
    end
    
    task.wait(0.15)
    
    -- Auto Hammer Phase
    local hammerAttempts = 0
    while autoForgeEnabled and hammerAttempts < 15 do
        hammerAttempts = hammerAttempts + 1
        
        pcall(function()
            Services.Forge.RF.ChangeSequence:InvokeServer("Hammer")
        end)
        
        task.wait(0.1)
        
        local forgeUI = LocalPlayer.PlayerGui:FindFirstChild("ForgeUI") or LocalPlayer.PlayerGui:FindFirstChild("Forge")
        if not forgeUI or not forgeUI.Enabled then break end
    end
    
    -- Complete forge
    task.wait(0.2)
    pcall(function()
        Services.Forge.RF.EndForge:InvokeServer()
    end)
    
    itemsForged = itemsForged + 1
    isForging = false
end

local function startAutoForge()
    if forgeMinigameConnection then
        forgeMinigameConnection:Disconnect()
    end
    
    -- Listen for forge minigame start
    forgeMinigameConnection = RunService.Heartbeat:Connect(function()
        if not autoForgeEnabled then return end
        
        -- Check if forge UI is visible
        local forgeUI = LocalPlayer.PlayerGui:FindFirstChild("ForgeUI") or LocalPlayer.PlayerGui:FindFirstChild("Forge")
        if forgeUI and forgeUI.Enabled and not isForging then
            completeForgeMinigame()
        end
    end)
    
    -- Also hook into forge service signal
    pcall(function()
        Services.Forge.RF.StartForge.OnClientInvoke = function()
            if autoForgeEnabled then
                task.spawn(completeForgeMinigame)
            end
        end
    end)
end

local function stopAutoForge()
    if forgeMinigameConnection then
        forgeMinigameConnection:Disconnect()
        forgeMinigameConnection = nil
    end
    isForging = false
end

local lastAttackTime = 0
local attackCooldown = 0.3

local function startAutoKill()
    if killConnection then
        killConnection:Disconnect()
    end
    
    currentTarget = nil
    startKillTool()
    equipWeapon()
    
    killConnection = RunService.Heartbeat:Connect(function()
        if not autoKillZombie then return end
        
        local t = tick()
        if t - lastAttackTime < attackCooldown then return end
        
        -- Keep weapon equipped
        equipWeapon()
        
        -- Check current target
        if currentTarget then
            local targetHumanoid = currentTarget:FindFirstChild("Humanoid")
            if not targetHumanoid or targetHumanoid.Health <= 0 or not currentTarget.Parent then
                if targetHumanoid and targetHumanoid.Health <= 0 then
                    zombiesKilled = zombiesKilled + 1
                end
                currentTarget = nil
            end
        end
        
        -- Find new target
        if not currentTarget then
            currentTarget = findNearestZombie()
        end
        
        if currentTarget then
            local hrp = getHumanoidRootPart()
            local zombieHrp = currentTarget:FindFirstChild("HumanoidRootPart")
            local zombieHumanoid = currentTarget:FindFirstChild("Humanoid")
            
            if hrp and zombieHrp and zombieHumanoid and zombieHumanoid.Health > 0 then
                local distance = (hrp.Position - zombieHrp.Position).Magnitude
                
                if distance > 200 then
                    currentTarget = nil
                    return
                end
                
                if distance > 8 then
                    local targetPos = zombieHrp.Position + Vector3.new(0, 3, 0)
                    tweenTo(targetPos, flySpeed)
                end
                
                -- Face target
                hrp.CFrame = CFrame.new(hrp.Position, zombieHrp.Position)
                
                lastAttackTime = t
            else
                currentTarget = nil
            end
        end
        
        task.wait(0.2)
    end)
end

-- UI ELEMENTS

-- Info Tab
Tabs.InfoTab:Section({
	Title = "Welcome to The Forge Hub",
})

Tabs.InfoTab:Paragraph{
	Title = "About",
	Desc = "Premium auto-farming script for The Forge game. Features include Auto Mining, Auto Kill, Auto Sell, Auto Forge, Ghost Tap, and Anti-AFK protection. Made by Mons."
}

Tabs.InfoTab:Paragraph{
	Title = "Features",
	Desc = "✓ Auto Mining (12 ore types)\n✓ Auto Kill (16 mob types)\n✓ Auto Sell (rarity-based)\n✓ Auto Forge (Melt/Pour/Hammer)\n✓ Ghost Tap (1-30 taps/sec)\n✓ Anti-AFK Bypass"
}

Tabs.InfoTab:Section({
	Title = "Support & Updates",
})

Tabs.InfoTab:Button({
	Title = "Join Discord",
	Desc = "Get support, updates, and join our community",
	Callback = function()
		setclipboard("discord.gg/nathub")
		game.StarterGui:SetCore("SendNotification", {
			Title = "Discord";
			Text = "Link copied to clipboard!";
			Duration = 3;
		})
	end
})

Tabs.InfoTab:Paragraph{
	Title = "How to Use",
	Desc = "1. Enable desired features in Farm/Combat tabs\n2. Adjust speed and range settings\n3. Enable Ghost Tap for faster farming\n4. Enable Anti-AFK to prevent disconnects\n5. Press Right Control to minimize UI"
}

-- Farm Tab
Tabs.FarmTab:Section({
	Title = "Auto Mining Configuration",
})

Tabs.FarmTab:Paragraph{
	Title = "About Auto Mining",
	Desc = "Automatically flies to selected ore type and mines them. Supports 12 different ore types including Rock, Earth Crystal, Basalt Rock, and more. Enable Ghost Tap below for faster mining."
}

Tabs.FarmTab:Dropdown({
	Title = "Select Ore Type",
	Values = oreNames,
	Value = "Stone",
	Callback = function(value)
		selectedOre = value
	end
})

Tabs.FarmTab:Toggle({
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
			stopMiningTool()
		end
	end
})

Tabs.FarmTab:Slider({
	Title = "Fly Speed",
	Value = {
		Min = 10,
		Max = 100,
		Default = 30,
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
		Default = 15,
	},
	Callback = function(value)
		miningRange = value
	end
})

Tabs.FarmTab:Section({
	Title = "Ghost Tap Enhancement",
})

Tabs.FarmTab:Paragraph{
	Title = "Ghost Tap for Mining",
	Desc = "Automatically taps screen center at adjustable speed while mining. Increases mining efficiency. Adjust speed from 1-30 taps per second. Higher speed = faster farming but may be detectable."
}

Tabs.FarmTab:Slider({
	Title = "Tap Speed (per second)",
	Value = {
		Min = 1,
		Max = 30,
		Default = 10,
	},
	Callback = function(value)
		ghostTapSpeed = value
	end
})

Tabs.FarmTab:Toggle({
	Title = "Enable Ghost Tap",
	Icon = "mouse-pointer",
	Default = false,
	Callback = function(state)
		ghostTapEnabled = state
		
		if state then
			startGhostTap()
		else
			stopGhostTap()
		end
	end
})

Tabs.FarmTab:Section({
	Title = "Auto Sell Configuration",
})

Tabs.FarmTab:Paragraph{
	Title = "About Auto Sell",
	Desc = "Automatically flies to nearest merchant/shop and sells items based on selected rarity. Choose from Common, Uncommon, Rare, Epic, Legendary, or All Items. Helps manage inventory space."
}

Tabs.FarmTab:Dropdown({
	Title = "Select Rarity to Sell",
	Values = sellCategories,
	Value = "All Items",
	Callback = function(value)
		selectedSellCategory = value
	end
})

Tabs.FarmTab:Toggle({
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

Tabs.FarmTab:Section({
	Title = "Auto Tap Settings",
})

Tabs.FarmTab:Paragraph{
	Title = "Ghost Tap System",
	Desc = "Uses invisible clicks at screen center for better compatibility."
}

Tabs.FarmTab:Slider({
	Title = "Tap Speed",
	Value = {
		Min = 0.05,
		Max = 0.2,
		Default = 0.08,
	},
	Callback = function(value)
		tapDelay = value
	end
})

-- Combat Tab
Tabs.CombatTab:Section({
	Title = "Auto Kill Configuration",
})

Tabs.CombatTab:Paragraph{
	Title = "About Auto Kill",
	Desc = "Automatically detects, flies to, and kills selected mob type. Supports 16 different mob types including Delver Zombie, Deathaxe, Skeleton, Reaper, and more. Auto-equips weapon and uses continuous tool activation."
}

Tabs.CombatTab:Dropdown({
	Title = "Select NPC Type",
	Values = npcNames,
	Value = "Zombie",
	Callback = function(value)
		selectedNPC = value
	end
})

Tabs.CombatTab:Toggle({
	Title = "Enable Auto Kill",
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
			stopKillTool()
			currentTarget = nil
		end
	end
})

Tabs.CombatTab:Section({
	Title = "Ghost Tap Enhancement",
})

Tabs.CombatTab:Paragraph{
	Title = "Ghost Tap for Combat",
	Desc = "Automatically taps screen center during combat for faster attacks. Uses same speed setting configured in Farm tab (1-30 taps/sec). Enable for maximum DPS."
}

Tabs.CombatTab:Toggle({
	Title = "Enable Ghost Tap (Combat)",
	Icon = "mouse-pointer",
	Default = false,
	Callback = function(state)
		ghostTapEnabled = state
		
		if state then
			startGhostTap()
		else
			stopGhostTap()
		end
	end
})

-- Misc Tab
Tabs.MiscTab:Section({
	Title = "Auto Forge System",
})

Tabs.MiscTab:Paragraph{
	Title = "About Auto Forge",
	Desc = "Automatically completes the forge minigame phases (Melt, Pour, Hammer) when you start forging. Each phase is attempted up to 15 times for guaranteed success. Works seamlessly with Auto Mining."
}

Tabs.MiscTab:Toggle({
	Title = "Enable Auto Forge",
	Icon = "flame",
	Default = false,
	Callback = function(state)
		autoForgeEnabled = state
		
		if state then
			startAutoForge()
		else
			stopAutoForge()
		end
	end
})

Tabs.MiscTab:Section({
	Title = "Anti-AFK Protection",
})

Tabs.MiscTab:Paragraph{
	Title = "About Anti-AFK",
	Desc = "Prevents Roblox from automatically disconnecting you after 20 minutes of inactivity. Simulates user input every 60 seconds to keep your session active. Essential for long farming sessions."
}

Tabs.MiscTab:Toggle({
	Title = "Enable Anti AFK",
	Icon = "shield-check",
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

Tabs.MiscTab:Button({
	Title = "Manual AFK Action",
	Desc = "Trigger anti-AFK manually",
	Callback = function()
		if antiAFKEnabled then
			performAntiAFK()
		end
	end
})

Tabs.MiscTab:Section({
	Title = "Testing & Utilities",
})

Tabs.MiscTab:Paragraph{
	Title = "Debug Tools",
	Desc = "Test individual features to ensure they're working correctly before enabling full automation."
}

Tabs.MiscTab:Button({
	Title = "Test Ghost Tap",
	Desc = "Sends 5 test taps to verify tap system",
	Callback = function()
		for i = 1, 5 do
			performGhostTap()
			wait(0.1)
		end
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "Ghost Tap Test";
			Text = "Sent 5 test taps successfully!";
			Duration = 3;
		})
	end
})

Tabs.MiscTab:Button({
	Title = "Test Tool Activation",
	Desc = "Test all tap methods",
	Callback = function()
		local char = getCharacter()
		local tool = char and char:FindFirstChildOfClass("Tool")
		
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "Tool Check";
			Text = tool and "Tool equipped: "..tool.Name or "No tool equipped!";
			Duration = 3;
		})
		
		if tool then
			activateTool()
		end
	end
})

Tabs.MiscTab:Section({
	Title = "Player Settings",
})

Tabs.MiscTab:Button({
	Title = "Reset Stats",
	Desc = "Reset all statistics",
	Callback = function()
		statsCollected = 0
		zombiesKilled = 0
		actionCount = 0
		itemsSold = 0
		itemsForged = 0
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "Stats Reset";
			Text = "All statistics have been reset!";
			Duration = 3;
		})
	end
})

Tabs.MiscTab:Button({
	Title = "Teleport to Spawn",
	Desc = "TP to spawn point",
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
	Title = "The Forge Script v2.2",
	Desc = "All-in-one farming script with anti-cheat protection."
}

Tabs.InfoTab:Paragraph{
	Title = "Features",
	Desc = "• Anti AFK bypass\n• Auto Mining with ore selection\n• Auto Kill with NPC selection\n• Anti-cheat protection\n• Humanized movements\n• Auto-tap system (4 methods)\n• Session statistics tracking"
}

Tabs.InfoTab:Section({
	Title = "Statistics",
})

local statsLabel = Tabs.InfoTab:Paragraph{
	Title = "Session Stats",
	Desc = " Ores: 0 | Kills: 0"
}

spawn(function()
	while wait(5) do
		pcall(function()
			statsLabel:SetDesc("AFK Actions: "..actionCount.." | Ores: "..statsCollected.." | Kills: "..zombiesKilled)
		end)
	end
end)

-- UI Toggle Detection (for auto tap)
local UserInputService = game:GetService("UserInputService")
local ToggleKey = Enum.KeyCode.RightShift -- Default toggle key for NatHub

-- Detect UI visibility changes
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == ToggleKey and not gameProcessed then
        isUIVisible = not isUIVisible
        
        -- Debug notification (optional - can be removed)
        if isUIVisible then
            print("UI Opened - Auto Tap Paused")
        else
            print("UI Closed - Auto Tap Active")
        end
    end
end)

-- Alternative: Monitor ScreenGui visibility
spawn(function()
    while wait(0.5) do
        pcall(function()
            local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
            local natHubGui = playerGui:FindFirstChild("NatHub") or playerGui:FindFirstChild("ScreenGui")
            
            if natHubGui then
                local mainFrame = natHubGui:FindFirstChildWhichIsA("Frame", true)
                if mainFrame and mainFrame.Visible ~= nil then
                    isUIVisible = mainFrame.Visible
                end
            end
        end)
    end
end)
