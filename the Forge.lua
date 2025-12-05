-- The Forge - Complete Script (NatHub UI)
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

-- Load NatHub UI Library
local NatHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/dy1zn4t/bmF0dWk-/refs/heads/main/ui.lua"))()

local Window = NatHub:CreateWindow({
	Title = "NatHub",
	Icon = "rbxassetid://113216930555884",
	Author = "Script Hub",
	Folder = "TheForgeHub",
	Size = UDim2.fromOffset(580, 460),
	LiveSearchDropdown = true,
    AutoSave = true,
    FileSaveName = "TheForge_Config.json",
})

-- Create Tabs (NatHub format)
local Tabs = {
    InfoTab = Window:Tab({ Title = "Info", Icon = "info", Desc = "Information about the script." }),
	FarmTab = Window:Tab({ Title = "Auto Farm", Icon = "pickaxe", Desc = "Auto mining and farming features." }),
	CombatTab = Window:Tab({ Title = "Combat", Icon = "sword", Desc = "Auto kill zombie and combat features." }),
	MiscTab = Window:Tab({ Title = "Misc", Icon = "settings", Desc = "Miscellaneous settings." }),
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
local selectedOre = "Stone"
local selectedNPC = "Zombie"
local selectedSellItem = "All Items"
local flySpeed = 35 -- Reduced speed to avoid anti-cheat (was 50)
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

-- Anti-Cheat Bypass Settings
local useAntiCheat = true
local humanizedSpeed = true
local randomDelays = true

-- Ore Names List
local oreNames = {"Stone", "Emberstone", "Frost Ore", "Ironcore", "Shadow Shard", "Glimmer Crystal", 
                  "Nova Ore", "Titan Rock", "Luminite", "Darksteel Chunk", "Magma Fragment",
                  "Storm Quartz", "Ancient Relic Stone", "Void Ore", "Copperlite", "Starfall Gem",
                  "Dragonstone", "Rune Ore", "Crystaline Rock", "Obsidian Core", "Radiant Gem"}

-- NPC Names List for Auto Kill
local npcNames = {"Zombie", "Skeleton", "Goblin", "Orc", "Troll", "Dragon", "Spider", "Wolf",
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

-- Ghost Tap - Creates invisible click at screen center
local function ghostTap()
    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        local Camera = workspace.CurrentCamera
        local ViewportSize = Camera.ViewportSize
        
        -- Center of screen
        local centerX = ViewportSize.X / 2
        local centerY = ViewportSize.Y / 2
        
        -- Send click at center
        VIM:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
        task.wait(0.01)
        VIM:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
    end)
end

-- Mobile Touch Simulation
local function mobileTouch()
    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        local Camera = workspace.CurrentCamera
        local ViewportSize = Camera.ViewportSize
        
        local centerX = ViewportSize.X / 2
        local centerY = ViewportSize.Y / 2
        
        -- Simulate touch
        VIM:SendTouchEvent(0, centerX, centerY, true, game, 0)
        task.wait(0.01)
        VIM:SendTouchEvent(0, centerX, centerY, false, game, 0)
    end)
end

-- Tool Activation with Multiple Methods
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
    
    -- Method 3: Ghost tap at screen center (PC)
    ghostTap()
    
    -- Method 4: Mobile touch simulation
    mobileTouch()
    
    -- Method 5: Legacy mouse simulation
    pcall(function()
        mouse1click()
    end)
end

-- Auto Tap Functions with Improved Timing
local lastTapTime = 0
local tapDelay = 0.08 -- Optimal delay for both PC and mobile

local function startMiningTap()
    if miningTapConnection then
        miningTapConnection:Disconnect()
    end
    
    lastTapTime = 0
    
    miningTapConnection = RunService.RenderStepped:Connect(function()
        if not autoMining then return end
        
        local currentTime = tick()
        if currentTime - lastTapTime >= tapDelay then
            activateTool()
            lastTapTime = currentTime
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
    
    lastTapTime = 0
    
    killTapConnection = RunService.RenderStepped:Connect(function()
        if not autoKillZombie then return end
        
        local currentTime = tick()
        if currentTime - lastTapTime >= tapDelay then
            activateTool()
            lastTapTime = currentTime
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
                -- Filter by selected ore type (must match)
                if not obj.Name:find(selectedOre) then
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
    
    -- Don't tween if too close (looks suspicious)
    if distance < 10 then
        hrp.CFrame = CFrame.new(targetPos)
        return
    end
    
    local duration = distance / speed
    
    -- Add slight delay before starting tween
    if useAntiCheat then
        wait(getRandomDelay(0.1, 0.3))
    end
    
    enableNoclip()
    
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
        disableNoclip()
        -- Add small delay after arriving
        if useAntiCheat then
            wait(getRandomDelay(0.1, 0.2))
        end
    end)
    
    return tween
end

-- Auto Functions
local lastMineTime = 0
local miningCooldown = 0.5

local function startAutoMining()
    if farmConnection then
        farmConnection:Disconnect()
    end
    
    startMiningTap()
    task.wait(0.2)
    equipPickaxe()
    
    farmConnection = RunService.Heartbeat:Connect(function()
        if not autoMining then return end
        
        -- Anti-cheat: Rate limiting
        local currentTime = tick()
        if currentTime - lastMineTime < miningCooldown then
            return
        end
        
        local ore = findNearestOre()
        if ore then
            local hrp = getHumanoidRootPart()
            if hrp then
                local distance = (hrp.Position - ore.Position).Magnitude
                
                -- Anti-cheat: Don't mine if too far (suspicious)
                if distance > 300 then
                    return
                end
                
                if distance > miningRange then
                    local targetPos = ore.Position + Vector3.new(0, 5, 0)
                    tweenTo(targetPos, flySpeed)
                    
                    -- Ensure flying/noclip is active
                    if not isFlying then
                        enableNoclip()
                    end
                else
                    local char = getCharacter()
                    if char and not char:FindFirstChildOfClass("Tool") then
                        equipPickaxe()
                        wait(getRandomDelay(0.3, 0.5))
                    end
                    
                    -- Add random delay before mining
                    if useAntiCheat then
                        wait(getRandomDelay(0.2, 0.4))
                    end
                    
                    pcall(function()
                        Services.Proximity.RF.Forge:InvokeServer(ore.Parent)
                    end)
                    
                    if ore and ore.Parent then
                        statsCollected = statsCollected + 1
                        lastMineTime = currentTime
                    end
                    
                    -- Add delay after mining
                    if useAntiCheat then
                        wait(getRandomDelay(0.3, 0.6))
                    end
                end
            end
        end
        
        wait(useAntiCheat and getRandomDelay(0.5, 1.0) or 0.5)
    end)
end

local lastAttackTime = 0
local attackCooldown = 0.3

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
        
        -- Anti-cheat: Rate limiting
        local currentTime = tick()
        if currentTime - lastAttackTime < attackCooldown then
            return
        end
        
        if currentTarget then
            local targetHumanoid = currentTarget:FindFirstChild("Humanoid")
            if not targetHumanoid or targetHumanoid.Health <= 0 or not currentTarget.Parent then
                if targetHumanoid and targetHumanoid.Health <= 0 then
                    zombiesKilled = zombiesKilled + 1
                    -- Add delay after kill
                    if useAntiCheat then
                        wait(getRandomDelay(0.5, 1.0))
                    end
                end
                currentTarget = nil
            end
        end
        
        if not currentTarget then
            currentTarget = findNearestZombie()
            -- Add delay before attacking new target
            if currentTarget and useAntiCheat then
                wait(getRandomDelay(0.3, 0.5))
            end
        end
        
        if currentTarget then
            local hrp = getHumanoidRootPart()
            local zombieHrp = currentTarget:FindFirstChild("HumanoidRootPart")
            local zombieHumanoid = currentTarget:FindFirstChild("Humanoid")
            
            if hrp and zombieHrp and zombieHumanoid and zombieHumanoid.Health > 0 then
                local distance = (hrp.Position - zombieHrp.Position).Magnitude
                
                -- Anti-cheat: Don't attack if too far
                if distance > 200 then
                    currentTarget = nil
                    return
                end
                
                if distance > 8 then
                    tweenTo(zombieHrp.Position + Vector3.new(0, 2, 0), flySpeed)
                else
                    -- More natural facing
                    if useAntiCheat then
                        local lookAt = CFrame.new(hrp.Position, zombieHrp.Position)
                        hrp.CFrame = hrp.CFrame:Lerp(lookAt, 0.5)
                    else
                        hrp.CFrame = CFrame.new(hrp.Position, zombieHrp.Position)
                    end
                    
                    local char = getCharacter()
                    if char and not char:FindFirstChildOfClass("Tool") then
                        equipWeapon()
                        wait(getRandomDelay(0.2, 0.4))
                    end
                    
                    lastAttackTime = currentTime
                end
            else
                currentTarget = nil
            end
        end
        
        wait(useAntiCheat and getRandomDelay(0.2, 0.4) or 0.2)
    end)
end

-- UI ELEMENTS

-- Farm Tab
Tabs.FarmTab:Section({
	Title = "Auto Mining",
})

Tabs.FarmTab:Paragraph{
	Title = "Auto Mining",
	Desc = "Automatically fly to ores and mine them."
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

Tabs.FarmTab:Slider({
	Title = "Fly Speed",
	Value = {
		Min = 20,
		Max = 60,
		Default = 35,
	},
	Callback = function(value)
		flySpeed = value
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
	Title = "Auto Kill",
})

Tabs.CombatTab:Paragraph{
	Title = "Auto Kill NPC",
	Desc = "Automatically detect and kill nearby NPCs/enemies."
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
			stopKillTap()
			currentTarget = nil
		end
	end
})

-- Misc Tab
Tabs.MiscTab:Section({
	Title = "Anti AFK",
})

Tabs.MiscTab:Paragraph{
	Title = "Anti AFK Bypass",
	Desc = "Prevents Roblox from kicking you after 20 minutes of inactivity."
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
	Title = "Testing",
})

Tabs.MiscTab:Button({
	Title = "Test Ghost Tap",
	Desc = "Test auto tap system",
	Callback = function()
		for i = 1, 5 do
			activateTool()
			wait(0.1)
		end
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "Ghost Tap Test";
			Text = "Sent 5 taps to screen center!";
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
	Desc = "AFK Actions: 0 | Ores: 0 | Kills: 0"
}

spawn(function()
	while wait(5) do
		pcall(function()
			statsLabel:SetDesc("AFK Actions: "..actionCount.." | Ores: "..statsCollected.." | Kills: "..zombiesKilled)
		end)
	end
end)
