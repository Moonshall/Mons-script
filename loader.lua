-- The Forge Loader
-- Universal loader for executing the Anti AFK script

local function loadScript()
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/the%20Forge.lua"))()
    end)
    
    if not success then
        warn("Failed to load script: " .. tostring(result))
        
        -- Fallback: Load from alternative source or local
        local fallbackSuccess, fallbackResult = pcall(function()
            return loadstring(game:HttpGet("https://pastebin.com/raw/YOUR_PASTE_ID"))()
        end)
        
        if not fallbackSuccess then
            warn("Fallback also failed: " .. tostring(fallbackResult))
        end
    end
end

-- Execute the loader
loadScript()
