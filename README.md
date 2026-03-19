# Welcome To Crescent UI.

## We present to you our own library source.

> **This Lib Is Currently Unavailable To Use**

# THIS IS FOR ENTERTAINMENT PURPOSE ONLY!

# FULL SET UP
```lua
local Crescent = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dawsig/Crescent/refs/heads/main/Lib.lua"))()

local Window = Crescent:CreateWindow({
    Title = "Demo UI",
    Subtitle = "Example",
    LoadingTitle = "Demo",
    LoadingSubtitle = "Starting...",
    LoadingDuration = 2
})

local Main = Window:AddFolder("Main")

Main:AddLabel("Player")

Main:AddToggle({
    Text = "Infinite Jump",
    Flag = "infjump",
    Callback = function(v)
        print("Infinite Jump:", v)
    end
})

Main:AddSlider({
    Text = "WalkSpeed",
    Min = 0,
    Max = 100,
    Default = 16,
    Callback = function(v)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
})

Main:AddDropdown({
    Text = "Team",
    Options = {"Red", "Blue", "Green"},
    Callback = function(team)
        print(team)
    end
})

Main:AddButton({
    Text = "Reset Character",
    Callback = function()
        game.Players.LocalPlayer.Character:BreakJoints()
    end
})

Crescent:Notify({
    Title = "Loaded",
    Text = "UI initialized successfully"
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
