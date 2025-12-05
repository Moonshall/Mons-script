# The Forge - Anti AFK Script

## 🚀 Quick Start

### Method 1: Simple Loader (Recommended)
Copy and paste this into your Roblox executor:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/the%20Forge.lua"))()
```

### Method 2: Alternative Hosts

**Pastebin:**
```lua
loadstring(game:HttpGet("https://pastebin.com/raw/YOUR_PASTE_ID"))()
```

**GitHub Gist:**
```lua
loadstring(game:HttpGet("https://gist.githubusercontent.com/YOUR_USERNAME/YOUR_GIST_ID/raw"))()
```

**Pastefy:**
```lua
loadstring(game:HttpGet("https://pastefy.app/YOUR_PASTE_ID/raw"))()
```

## 📋 Setup Instructions

### Step 1: Upload Script
Upload `the Forge.lua` to one of these services:
- GitHub Repository (recommended)
- Pastebin
- GitHub Gist
- Pastefy

### Step 2: Get Raw URL
- **GitHub**: Click "Raw" button on the file
- **Pastebin**: Add `/raw/` after pastebin.com
- **Gist**: Click "Raw" button
- **Pastefy**: Add `/raw` at the end

### Step 3: Update Loader
Replace `YOUR_USERNAME/YOUR_REPO` or `YOUR_PASTE_ID` with your actual URL

### Step 4: Execute
Copy the loader code and paste it into your executor

## ✨ Features

- ✅ Bypass Roblox 20-minute AFK detection
- ✅ Automatic input simulation every 60 seconds
- ✅ Idle event hook for instant response
- ✅ Session statistics tracking
- ✅ Manual action trigger
- ✅ Clean WindUI interface
- ✅ Enable/disable toggle
- ✅ Notification system

## 🎮 Usage

1. Execute the loader in your Roblox game
2. The UI will appear automatically
3. Navigate to "Anti AFK" tab
4. Toggle "Enable Anti AFK"
5. You're now protected from AFK kicks!

## 📊 Statistics

The script tracks:
- Number of anti-AFK actions performed
- Time since last action
- Current status (enabled/disabled)

## ⚠️ Requirements

- Roblox executor with HTTP support
- Executor must support `VirtualUser` service
- `loadstring` must be enabled

## 🔧 Troubleshooting

**Script won't load:**
- Check if HTTP requests are enabled in your executor
- Verify the URL is correct and accessible
- Try an alternative hosting service

**Anti AFK not working:**
- Make sure the toggle is enabled
- Check if your executor supports `VirtualUser`
- Look for error messages in console (F9)

**UI not appearing:**
- Ensure WindUI library can load from the URL
- Check your internet connection
- Try rejoining the game

## 📝 Notes

- This script is for educational purposes
- Use responsibly
- Some games may have additional anti-AFK measures
- The script is lightweight and won't lag your game

## 🔄 Updates

To update the script:
1. Re-upload the new version to your hosting service
2. The loader will automatically fetch the latest version
3. No need to change the loader code

## 💡 Tips

- Keep the UI minimized when not in use
- Check statistics periodically to ensure it's working
- Use manual action button to test functionality
- Enable before stepping away from keyboard

---

**Version:** 1.0  
**Last Updated:** December 2025  
**Author:** Script Hub
