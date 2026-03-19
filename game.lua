local Crescent = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dawsig/Crescent/refs/heads/main/main.lua"))()

local placeData = Crescent.Places[game.PlaceId]

if placeData and placeData.url ~= "" then
    print("Loading:", placeData.game, "-", placeData.place)
    loadstring(game:HttpGet(placeData.url))()
else
    print("Loading universal script")
    loadstring(game:HttpGet(Crescent.Universal))()
end
