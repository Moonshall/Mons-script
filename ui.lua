-- local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/dy1zn4t/bmF0dWk-/refs/heads/main/ui.lua"))()
local Window = require(NatHub["3e"]):CreateWindow({
	Title = "NatHub",
	Icon = "rbxassetid://113216930555884",
	Author = "UI Development Test",
	Folder = "CloudHub",
	Size = UDim2.fromOffset(580, 460),
	LiveSearchDropdown = true,
    AutoSave = true,
    FileSaveName = "NatHub Config.json", -- wajib ada .json
})


local Tabs = {
	ButtonTab = Window:Tab({ Title = "Button", Icon = "mouse-pointer-2", Desc = "Contains interactive buttons for various actions." }),
	CodeTab = Window:Tab({ Title = "Code", Icon = "code", Desc = "Displays and manages code snippets." }),
	NotificationTab = Window:Tab({ Title = "Notification", Icon = "bell", Desc = "Configure and view notifications." }),
	ToggleTab = Window:Tab({ Title = "Toggle", Icon = "toggle-left", Desc = "Switch settings on and off." }),
	SliderTab = Window:Tab({ Title = "Slider", Icon = "sliders-horizontal", Desc = "Adjust values smoothly with sliders." }),
	InputTab = Window:Tab({ Title = "Input", Icon = "keyboard", Desc = "Accept text and numerical input." }),
	DropdownTab = Window:Tab({ Title = "Dropdown", Icon = "", Desc = "Select from multiple options." }),
	b = Window:Divider(),
	WindowTab = Window:Tab({ Title = "Window and File Configuration", Icon = "settings", Desc = "Manage window settings and file configurations." }),
	be = Window:Divider(),
	LongTab = Window:Tab({ Title = "Long and empty tab. Looong and empty.. tab.", Icon = "frown", Desc = "Long Description" }),
}

Window:SelectTab(1)

Tabs.ButtonTab:Section({
	Title = "Paragraph Test",
})

Tabs.ButtonTab:Paragraph{
	Title = "Confidential",
	Desc = "This UI library belongs to NataX."
}

Tabs.ButtonTab:Section({
	Title = "Button Tests",
})

Tabs.ButtonTab:Button({
	Title = "Click Me",
	Desc = "This is a simple button",
	Callback = function() print("Button Clicked!") end
})

Tabs.ButtonTab:Button({
	Title = "Tes gapake deskripsi",
	Callback = function() print("Button Clicked!") end
})

Tabs.ButtonTab:Section({
	Title = "Lock/Unlock Button Test",
})

local teslock = Tabs.ButtonTab:Button({
	Title = "Locked Button",
	Desc = "This button is locked",
	Locked = true,
	Callback = function() warn("Clicked when unlocked!") end
})

Tabs.ButtonTab:Button({
	Title = "unlock",
	Callback = function() teslock:Unlock() teslock:SetTitle("Unlocked Button") teslock:SetDesc("This Button is unlocked") end,
	Locked = false
})

Tabs.ButtonTab:Button({
	Title = "lock",
	Callback = function() teslock:Lock() teslock:SetTitle("Relocked Button") teslock:SetDesc("This Button is relocked") end,
	Locked = false
})

Tabs.ButtonTab:Button({
	Title = "Submit",
	Desc = "Click to submit",
	Callback = function() print("Submitted!") end,
	--Locked = false
})


Tabs.CodeTab:Code({
	Title = "Example Code",
	Code = [[
local message = "Hello"
print(message)

if message == "Hello" then
    print("Greetings!")
end]],
})

Tabs.CodeTab:Code({
	Title = "Another Code Example",
	Code = [[
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "WindUI Example",
    Icon = "image",
    Author = ".ftgs",
    Folder = "CloudHub",
    Size = UDim2.fromOffset(580, 460),
})]],
})

Tabs.NotificationTab:Button({
	Title = "Click to get Notified",
	Callback = function() 
		WindUI:Notify({
			Title = "Notification Example",
			Content = "Content\nhi\nHI",
			Icon = "droplet-off",
			Duration = 5,
		})
	end
})


Tabs.ToggleTab:Toggle({
	Title = "Enable Feature",
	Default = true,
	Callback = function(state) print("Feature enabled: " .. tostring(state)) end
})

Tabs.ToggleTab:Toggle({
	Title = "Activate Mode",
	Default = false,
	Callback = function(state) print("Mode activated: " .. tostring(state)) end
})
local lockedtoggle = Tabs.ToggleTab:Toggle({
	Title = "Toggle with icon",
	Icon = "check",
	Default = false,
	Locked = true,
	Callback = function(state) print("Toggle with icon activated: " .. tostring(state)) end
})

Tabs.ToggleTab:Toggle({
	Title = "Lock switch",
	Icon = "check",
	Default = false,
	Locked = false,
	Callback = function(state) if state == false then lockedtoggle:Unlock() else lockedtoggle:Lock() end end
})


local slider = Tabs.SliderTab:Slider({
	Title = "Volume Slider",
	Step = 0.5,
	Value = {
		Min = 0,
		Max = 100,
		Default = 50,
	},
	Callback = function(value) print("Volume set to: " .. value) end
})

local locked_slider = Tabs.SliderTab:Slider({
	Title = "Brightness Slider",
	Value = {
		Min = 1,
		Max = 5,
		Default = 2,
	},
	Locked = true,
	Callback = function(value) slider:Set(value) end
})

Tabs.SliderTab:Toggle{
	Title = "Lock switch",
	Icon = "check",
	Default = true,
	Callback = function(state) if state == false then locked_slider:Unlock() else locked_slider:Lock() end end
}

Tabs.InputTab:Input({
	Title = "Username",
	Default = "Guest",
	Placeholder = "Enter your username",
	MultiLine = false,
	Callback = function(input) print("Username: " .. input) end
})

Tabs.InputTab:Input({
	Title = "Password",
	Default = "",
	Placeholder = "Enter your password",
	MultiLine = false,
	Callback = function(input) print("Password entered.") end
})

Tabs.InputTab:Input({
	Title = "Multi Line test",
	Default = "",
	Placeholder = "testi aja",
	--MultiLine = false, -- defaultnya  true btw
	Callback = function(input) print("Password entered.") end
})

local locked_input = Tabs.InputTab:Input({
	Title = "locked test",
	Default = "",
	Locked = true,
	Placeholder = "hiiiiii",
	Callback = function(input) end
})

Tabs.InputTab:Toggle{
	Title = "Lock switch",
	Icon = "check",
	Default = true,
	Callback = function(state) if state == false then locked_input:Unlock() else locked_input:Lock() end end
}

Tabs.DropdownTab:Section({
	Title = "Dropdown Test",
})


local dd = Tabs.DropdownTab:Dropdown({
	Title = "Select an Option (Dropdown)",
	Values = { "Option 1", "Option 2", "Option 3" },
	Value = "Option 1",
	Callback = function(option) print("Selected: " .. option) end
})

Tabs.DropdownTab:Button({
	Title = "Select random Option",
	Callback = function()
		dd:Select(dd.Values[math.random(1, #dd.Values)])
	end,
})

Tabs.DropdownTab:Button({
	Title = "Refresh Option to 4, 5, 6",
	Callback = function()
		dd:Refresh({"Option 4", "Option 5", "Option 6"})
	end,
})

Tabs.DropdownTab:Section({
	Title = "Multi Dropdown Test",
})


local mdd = Tabs.DropdownTab:Dropdown({
	Title = "Choose few Fruits (Multi)",
	Values = { "Apple", "Banana", "Cherry", "Dragon Fruit"},
	Value = {"Apple","Dragon Fruit"},
	AllowNone = true, -- allow none cuma ada di multi dropdown aja
	Multi = true,
	Locked = true,
	Callback = function(option) print("Fruits selected: ", table.concat(option, ", ")) end
})
Tabs.DropdownTab:Toggle{
	Title = "Lock switch",
	Icon = "check",
	Default = true,
	Callback = function(state) if state == false then mdd:Unlock() else mdd:Lock() end end
}