# Welcome To Crescent UI.

## We present to you our own library source.

> **This Lib Is Currently Unavailable To Use**

# THIS IS FOR ENTERTAINMENT PURPOSE ONLY!

# FULL SET UP
```lua
local Crescent = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dawsig/Crescent/main/Lib.lua"))()

local Window = Crescent:CreateWindow({
    Title = "Crescent UI",
    LoadingTitle = "Crescent",
    LoadingSubtitle = "Initializing interface...",
    LoadingDuration = 2.5
})

local MainFolder = Window:AddFolder("Main")
local CombatFolder = Window:AddFolder("Combat")

MainFolder:AddToggle({
    Text = "Auto Farm",
    Default = false,
    Flag = "autofarm",
    Callback = function(state)
        print("Auto Farm:", state)
    end
})

MainFolder:AddButton({
    Text = "Teleport",
    Callback = function()
        print("Teleporting")
    end
})

MainFolder:AddLabel("Player Options")

MainFolder:AddSlider({
    Text = "WalkSpeed",
    Min = 0,
    Max = 100,
    Default = 16,
    Flag = "ws",
    Callback = function(value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end
})

MainFolder:AddDropdown({
    Text = "Select Weapon",
    Options = {"Sword", "Gun", "Magic"},
    Default = "Sword",
    Flag = "weapon",
    Callback = function(choice)
        print("Selected:", choice)
    end
})

MainFolder:AddColor({
    Text = "ESP Color",
    Default = Color3.fromRGB(255, 0, 0),
    Flag = "esp_color",
    Callback = function(color)
        print(color)
    end
})

MainFolder:AddKeybind({
    Text = "Toggle UI",
    Default = Enum.KeyCode.RightControl,
    Callback = function()
        Crescent:ToggleUI()
    end
})
```


# EXTRAS
**CHANGING THEME**
```lua
Crescent.Theme.Accent = Color3.fromRGB(0, 170, 255)
Crescent.Theme.Background = Color3.fromRGB(15, 15, 15)
```

# Destroy
```lua
Crescent:ToggleUI()
Crescent:Destroy()
```

[Crescent](hub.com)
