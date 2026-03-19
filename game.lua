local Crescent = loadstring(game:HttpGet("https://yourdomain.com/CrescentModule.lua"))()

local placeData = Crescent.Places[game.PlaceId]

if placeData and placeData.url ~= "" then
    print("Loading:", placeData.game, "-", placeData.place)
    loadstring(game:HttpGet(placeData.url))()
else
    print("Loading universal script")
    loadstring(game:HttpGet(Crescent.Universal))()
end
