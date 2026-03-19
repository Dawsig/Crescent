local Crescent = {
    Flags = {},
    Windows = {},
    ActiveDropdown = nil,
    Open = true,
    Theme = {
        Accent = Color3.fromRGB(255, 65, 65),
        Background = Color3.fromRGB(10, 10, 10),
        Panel = Color3.fromRGB(16, 16, 16),
        Panel2 = Color3.fromRGB(22, 22, 22),
        Panel3 = Color3.fromRGB(30, 30, 30),
        Hover = Color3.fromRGB(60, 60, 60),
        Idle = Color3.fromRGB(40, 40, 40),
        Text = Color3.fromRGB(255, 255, 255),
        Muted = Color3.fromRGB(160, 160, 160)
    },
    LoadingDefaults = {
        Title = "Crescent",
        Subtitle = "Loading interface...",
        Duration = 1.0
    }
}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local MouseButton1 = Enum.UserInputType.MouseButton1
local TouchInput = Enum.UserInputType.Touch

local function isPointer(input)
    return input.UserInputType == MouseButton1 or input.UserInputType == TouchInput
end

local function isMouseMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
end

local function create(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties or {}) do
        instance[property] = value
    end
    return instance
end

local function tween(instance, info, goal)
    return TweenService:Create(instance, info, goal)
end

local function clamp(n, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, n))
end

local function roundTo(n, step)
    step = step or 1
    return math.floor((n / step) + ((n >= 0) and 0.5 or -0.5)) * step
end

local function toColor3(value, fallback)
    if typeof(value) == "Color3" then
        return value
    end
    if typeof(value) == "table" then
        local r = tonumber(value[1] or value.r or value.R)
        local g = tonumber(value[2] or value.g or value.G)
        local b = tonumber(value[3] or value.b or value.B)
        if r and g and b then
            return Color3.new(clamp(r, 0, 1), clamp(g, 0, 1), clamp(b, 0, 1))
        end
    end
    return fallback or Color3.new(1, 1, 1)
end

local function addCorner(parent, radius)
    return create("UICorner", {
        CornerRadius = radius or UDim.new(0, 10),
        Parent = parent
    })
end

local function addStroke(parent, color, transparency, thickness)
    return create("UIStroke", {
        Color = color or Color3.fromRGB(255, 255, 255),
        Transparency = transparency or 0.85,
        Thickness = thickness or 1,
        Parent = parent
    })
end

local function setListPadding(parent, top, bottom, left, right)
    return create("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        Parent = parent
    })
end

local function protectGui(gui)
    if syn and syn.protect_gui then
        syn.protect_gui(gui)
    elseif gethui then
        gui.Parent = gethui()
        return
    end
    gui.Parent = game:GetService("CoreGui")
end

local function alphaLerp(current, target, speed)
    return current + ((target - current) * clamp(speed, 0, 1))
end

local function getPointerPosition(input)
    return Vector2.new(input.Position.X, input.Position.Y)
end

local function bindHover(button, onHover, onLeave)
    button.MouseEnter:Connect(function()
        if not UserInputService.TouchEnabled then
            onHover()
        end
    end)
    button.MouseLeave:Connect(function()
        if not UserInputService.TouchEnabled then
            onLeave()
        end
    end)
end

local function closeActiveDropdown()
    if Crescent.ActiveDropdown and Crescent.ActiveDropdown.Close then
        Crescent.ActiveDropdown:Close()
    end
end

local function safePress(guiObject, callback)
    local pressed = false
    local startPos

    guiObject.InputBegan:Connect(function(input)
        if not isPointer(input) then
            return
        end
        pressed = true
        startPos = input.Position
    end)

    guiObject.InputEnded:Connect(function(input)
        if not pressed or not isPointer(input) then
            return
        end
        pressed = false
        local delta = Vector2.new(input.Position.X - startPos.X, input.Position.Y - startPos.Y)
        if delta.Magnitude <= 10 then
            callback()
        end
    end)
end

function Crescent:Create(className, properties)
    return create(className, properties)
end

function Crescent:SetTheme(themeTable)
    for key, value in pairs(themeTable or {}) do
        if self.Theme[key] ~= nil then
            self.Theme[key] = value
        end
    end
end

function Crescent:ShowLoading(title, subtitle, duration)
    duration = duration or self.LoadingDefaults.Duration
    title = title or self.LoadingDefaults.Title
    subtitle = subtitle or self.LoadingDefaults.Subtitle

    if self._loadingGui and self._loadingGui.Parent then
        self._loadingGui:Destroy()
    end

    local gui = create("ScreenGui", {
        Name = "CrescentLoading",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    protectGui(gui)

    local backdrop = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Parent = gui
    })

    local card = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.52),
        Size = UDim2.new(0, 360, 0, 170),
        BackgroundColor3 = self.Theme.Panel,
        BackgroundTransparency = 1,
        Parent = backdrop
    })
    addCorner(card, UDim.new(0, 18))
    addStroke(card, Color3.fromRGB(255, 255, 255), 0.9, 1)

    local accent = create("Frame", {
        Size = UDim2.new(1, 0, 0, 4),
        BackgroundColor3 = self.Theme.Accent,
        BackgroundTransparency = 1,
        Parent = card
    })
    addCorner(accent, UDim.new(1, 0))

    local titleLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 22, 0, 26),
        Size = UDim2.new(1, -44, 0, 32),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextSize = 28,
        TextColor3 = self.Theme.Text,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card
    })

    local subtitleLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 22, 0, 64),
        Size = UDim2.new(1, -44, 0, 40),
        Font = Enum.Font.Gotham,
        Text = subtitle,
        TextSize = 16,
        TextWrapped = true,
        TextColor3 = self.Theme.Muted,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = card
    })

    local bar = create("Frame", {
        Position = UDim2.new(0, 22, 1, -36),
        Size = UDim2.new(1, -44, 0, 8),
        BackgroundColor3 = self.Theme.Panel3,
        BackgroundTransparency = 1,
        Parent = card
    })
    addCorner(bar, UDim.new(1, 0))

    local fill = create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = self.Theme.Accent,
        BackgroundTransparency = 1,
        Parent = bar
    })
    addCorner(fill, UDim.new(1, 0))

    task.spawn(function()
        TweenService:Create(backdrop, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.25}):Play()
        TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
        TweenService:Create(titleLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
        TweenService:Create(subtitleLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
        TweenService:Create(accent, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
        TweenService:Create(bar, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
        TweenService:Create(fill, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)}):Play()
        task.wait(duration + 0.15)
        TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
        TweenService:Create(backdrop, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
        TweenService:Create(titleLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
        TweenService:Create(subtitleLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
        task.wait(0.22)
        gui:Destroy()
    end)

    self._loadingGui = gui
    return gui
end

local function createWindowContainer(window, parent)
    local main = create("Frame", {
        Name = window.Title,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, ((window.Position - 1) * (window.Width + 18)), 0.5, 0),
        Size = UDim2.new(0, window.Width, 0, 52),
        BackgroundColor3 = Crescent.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = parent
    })
    addCorner(main, UDim.new(0, 14))
    addStroke(main, Color3.fromRGB(255, 255, 255), 0.92, 1)

    create("Frame", {
        Size = UDim2.new(1, 0, 0, 3),
        BackgroundColor3 = Crescent.Theme.Accent,
        BorderSizePixel = 0,
        Parent = main
    })

    local topbar = create("TextButton", {
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        Size = UDim2.new(1, 0, 0, 52),
        Parent = main
    })

    local title = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 6),
        Size = UDim2.new(1, -92, 0, 22),
        Font = Enum.Font.GothamBold,
        Text = window.Title,
        TextSize = 18,
        TextColor3 = Crescent.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topbar
    })

    local subtitle = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 26),
        Size = UDim2.new(1, -92, 0, 16),
        Font = Enum.Font.Gotham,
        Text = window.Subtitle or "",
        TextSize = 13,
        TextColor3 = Crescent.Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topbar
    })

    local collapseButton = create("ImageButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.new(0, 26, 0, 26),
        BackgroundTransparency = 1,
        Image = "rbxassetid://4918373417",
        ImageColor3 = Color3.fromRGB(80, 80, 80),
        AutoButtonColor = false,
        Rotation = 90,
        Parent = topbar
    })

    local closeButton = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -46, 0.5, 0),
        Size = UDim2.new(0, 26, 0, 26),
        BackgroundColor3 = Crescent.Theme.Panel3,
        AutoButtonColor = false,
        Text = "×",
        TextColor3 = Crescent.Theme.Text,
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        Parent = topbar
    })
    addCorner(closeButton, UDim.new(1, 0))

    local contentHolder = create("ScrollingFrame", {
        Position = UDim2.new(0, 0, 0, 52),
        Size = UDim2.new(1, 0, 1, -52),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Crescent.Theme.Panel3,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        ClipsDescendants = true,
        Parent = main
    })

    setListPadding(contentHolder, 10, 10, 10, 10)
    local contentLayout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = contentHolder
    })

    local state = {
        Title = window.Title,
        Subtitle = window.Subtitle or "",
        Main = main,
        Topbar = topbar,
        Content = contentHolder,
        ContentLayout = contentLayout,
        Open = true,
        Collapsed = false,
        Width = window.Width,
        TargetPosition = main.Position,
        Options = {}
    }

    local function resize()
        local height = state.Collapsed and 52 or (52 + contentLayout.AbsoluteContentSize.Y + 12)
        main:TweenSize(UDim2.new(0, state.Width, 0, math.max(52, height)), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.18, true)
    end

    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if not state.Collapsed and state.Open then
            resize()
        end
    end)

    local dragging = false
    local dragStart
    local startPos

    topbar.InputBegan:Connect(function(input)
        if not isPointer(input) then return end
        dragging = true
        dragStart = getPointerPosition(input)
        startPos = main.Position
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= TouchInput then
            return
        end
        local delta = getPointerPosition(input) - dragStart
        local nx = startPos.X.Offset + delta.X
        local ny = math.max(-36, startPos.Y.Offset + delta.Y)
        state.TargetPosition = UDim2.new(startPos.X.Scale, nx, startPos.Y.Scale, ny)
    end)

    UserInputService.InputEnded:Connect(function(input)
        if isPointer(input) then
            dragging = false
        end
    end)

    RunService.RenderStepped:Connect(function()
        if dragging then
            local current = main.Position
            main.Position = UDim2.new(
                alphaLerp(current.X.Scale, state.TargetPosition.X.Scale, 0.18),
                alphaLerp(current.X.Offset, state.TargetPosition.X.Offset, 0.28),
                alphaLerp(current.Y.Scale, state.TargetPosition.Y.Scale, 0.18),
                alphaLerp(current.Y.Offset, state.TargetPosition.Y.Offset, 0.28)
            )
        end
    end)

    local function setCollapsed(v)
        state.Collapsed = v
        contentHolder.Visible = not v
        resize()
        tween(collapseButton, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Rotation = v and 180 or 90,
            ImageColor3 = v and Color3.fromRGB(45, 45, 45) or Color3.fromRGB(80, 80, 80)
        }):Play()
    end

    safePress(collapseButton, function()
        setCollapsed(not state.Collapsed)
    end)

    safePress(closeButton, function()
        state.Open = false
        main.Visible = false
    end)

    function state:SetTitle(newTitle)
        self.Title = tostring(newTitle)
        title.Text = self.Title
        main.Name = self.Title
    end

    function state:SetSubtitle(newSubtitle)
        self.Subtitle = tostring(newSubtitle or "")
        subtitle.Text = self.Subtitle
    end

    function state:Refresh()
        resize()
    end

    function state:Close()
        self.Open = false
        main.Visible = false
    end

    function state:OpenWindow()
        self.Open = true
        main.Visible = true
    end

    return state
end

local function createFolder(option, window)
    local holder = create("Frame", {
        LayoutOrder = option.Position,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Crescent.Theme.Panel2,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = option.ParentOverride or window.Content
    })
    addCorner(holder, UDim.new(0, 10))
    addStroke(holder, Color3.fromRGB(255, 255, 255), 0.93, 1)

    local header = create("TextButton", {
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        Size = UDim2.new(1, 0, 0, 34),
        Parent = holder
    })

    local title = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -40, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = option.Title,
        TextSize = 16,
        TextColor3 = Crescent.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header
    })

    local arrow = create("ImageLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 16, 0, 16),
        BackgroundTransparency = 1,
        Image = "rbxassetid://4918373417",
        ImageColor3 = Crescent.Theme.Muted,
        Rotation = 90,
        Parent = header
    })

    local content = create("Frame", {
        Position = UDim2.new(0, 0, 0, 34),
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = holder
    })

    local layout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = content
    })
    setListPadding(content, 10, 10, 10, 10)

    local open = false
    local function refresh()
        local h = layout.AbsoluteContentSize.Y + 20
        content.Size = UDim2.new(1, 0, 0, h)
        holder.Size = open and UDim2.new(1, 0, 0, h + 34) or UDim2.new(1, 0, 0, 34)
    end

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refresh)

    safePress(header, function()
        open = not open
        content.Visible = open
        tween(arrow, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = open and 270 or 90}):Play()
        holder:TweenSize(open and UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 34 + 20) or UDim2.new(1, 0, 0, 34), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.16, true)
    end)

    option.Instance = holder
    option.Content = content
    option.Layout = layout
    option.Open = open
    option.SetOpen = function(_, state)
        open = state and true or false
        content.Visible = open
        tween(arrow, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = open and 270 or 90}):Play()
        refresh()
    end
    option.AddLabel = function(_, v) return window:AddLabel(v, content) end
    option.AddSeparator = function(_, v) return window:AddSeparator(v, content) end
    option.AddParagraph = function(_, v) return window:AddParagraph(v, content) end
    option.AddToggle = function(_, v) return window:AddToggle(v, content) end
    option.AddButton = function(_, v) return window:AddButton(v, content) end
    option.AddTextbox = function(_, v) return window:AddTextbox(v, content) end
    option.AddBind = function(_, v) return window:AddBind(v, content) end
    option.AddSlider = function(_, v) return window:AddSlider(v, content) end
    option.AddDropdown = function(_, v) return window:AddDropdown(v, content) end
    option.AddColor = function(_, v) return window:AddColor(v, content) end

    if option.Children then
        for _, child in ipairs(option.Children) do
            child.ParentOverride = content
            if child.Type == "label" then
                createLabel(child, window)
            elseif child.Type == "separator" then
                createSeparator(child, window)
            elseif child.Type == "paragraph" then
                createParagraph(child, window)
            elseif child.Type == "toggle" then
                createToggle(child, window)
            elseif child.Type == "button" then
                createButton(child, window)
            elseif child.Type == "textbox" then
                createTextbox(child, window)
            elseif child.Type == "bind" then
                createBind(child, window)
            elseif child.Type == "slider" then
                createSlider(child, window)
            elseif child.Type == "dropdown" then
                createDropdown(child, window)
            elseif child.Type == "color" then
                createColorPicker(child, window)
            end
        end
        refresh()
    end

    return option
end

local function createLabel(option, window)
    local label = create("TextLabel", {
        LayoutOrder = option.Position,
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = option.Text,
        TextSize = 16,
        Font = Enum.Font.GothamMedium,
        TextColor3 = Crescent.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = option.ParentOverride or window.Content
    })
    option.Instance = label
    function option:SetText(newText)
        self.Text = tostring(newText)
        label.Text = self.Text
    end
    return option
end

local function createSeparator(option, window)
    local holder = create("Frame", {
        LayoutOrder = option.Position,
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Parent = option.ParentOverride or window.Content
    })
    create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Crescent.Theme.Panel3,
        BorderSizePixel = 0,
        Parent = holder
    })
    option.Instance = holder
    return option
end

local function createParagraph(option, window)
    local holder = create("Frame", {
        LayoutOrder = option.Position,
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = Crescent.Theme.Panel2,
        BorderSizePixel = 0,
        Parent = option.ParentOverride or window.Content
    })
    addCorner(holder, UDim.new(0, 10))
    addStroke(holder, Color3.fromRGB(255, 255, 255), 0.93, 1)

    local title = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(1, -24, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = option.Title,
        TextSize = 15,
        TextColor3 = Crescent.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder
    })

    local body = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 26),
        Size = UDim2.new(1, -24, 0, 22),
        Font = Enum.Font.Gotham,
        Text = option.Text,
        TextSize = 13,
        TextWrapped = true,
        TextColor3 = Crescent.Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = holder
    })

    option.Instance = holder
    option.TitleInstance = title
    option.BodyInstance = body
    function option:SetText(newText)
        self.Text = tostring(newText)
        body.Text = self.Text
    end
    function option:SetTitle(newTitle)
        self.Title = tostring(newTitle)
        title.Text = self.Title
    end
    return option
end

local function createButton(option, window)
    local button = create("TextButton", {
        LayoutOrder = option.Position,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Crescent.Theme.Panel2,
        AutoButtonColor = false,
        Text = option.Text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextColor3 = Crescent.Theme.Text,
        Parent = option.ParentOverride or window.Content
    })
    addCorner(button, UDim.new(0, 10))
    addStroke(button, Color3.fromRGB(255, 255, 255), 0.93, 1)

    safePress(button, function()
        option.Callback()
    end)

    bindHover(button,
        function() tween(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Crescent.Theme.Panel3}):Play() end,
        function() tween(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Crescent.Theme.Panel2}):Play() end
    )

    option.Instance = button
    function option:SetText(newText)
        self.Text = tostring(newText)
        button.Text = self.Text
    end
    return option
end

local function createToggle(option, window)
    local row = create("TextButton", {
        LayoutOrder = option.Position,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Crescent.Theme.Panel2,
        AutoButtonColor = false,
        Text = "",
        Parent = option.ParentOverride or window.Content
    })
    addCorner(row, UDim.new(0, 10))
    addStroke(row, Color3.fromRGB(255, 255, 255), 0.93, 1)

    local label = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -60, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = option.Text,
        TextSize = 16,
        TextColor3 = Crescent.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row
    })

    local switch = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 44, 0, 22),
        BackgroundColor3 = option.State and Crescent.Theme.Accent or Crescent.Theme.Idle,
        BorderSizePixel = 0,
        Parent = row
    })
    addCorner(switch, UDim.new(1, 0))

    local knob = create("Frame", {
        Position = option.State and UDim2.new(1, -20, 0.5, -8) or UDim2.new(0, 4, 0.5, -8),
        Size = UDim2.new(0, 16, 0, 16),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = switch
    })
    addCorner(knob, UDim.new(1, 0))

    local function apply(state, silent)
        option.State = state
        Crescent.Flags[option.Flag] = state
        tween(switch, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = state and Crescent.Theme.Accent or Crescent.Theme.Idle}):Play()
        tween(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = state and UDim2.new(1, -20, 0.5, -8) or UDim2.new(0, 4, 0.5, -8)}):Play()
        if not silent then
            option.Callback(state)
        end
    end

    safePress(row, function()
        apply(not option.State, false)
    end)

    bindHover(row,
        function() tween(row, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Crescent.Theme.Panel3}):Play() end,
        function() tween(row, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Crescent.Theme.Panel2}):Play() end
    )

    option.Instance = row
    option.Switch = switch
    option.Knob = knob
    option.SetState = apply
    apply(option.State, true)
    return option
end

local function createTextbox(option, window)
    local holder = create("Frame", {
        LayoutOrder = option.Position,
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = Crescent.Theme.Panel2,
        BorderSizePixel = 0,
        Parent = option.ParentOverride or window.Content
    })
    addCorner(holder, UDim.new(0, 10))
    addStroke(holder, Color3.fromRGB(255, 255, 255), 0.93, 1)

    local label = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(1, -24, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = option.Text,
        TextSize = 14,
        TextColor3 = Crescent.Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder
    })

    local box = create("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 24),
        Size = UDim2.new(1, -24, 0, 22),
        ClearTextOnFocus = false,
        Text = option.Value,
        PlaceholderText = option.Placeholder or "",
        Font = Enum.Font.Gotham,
        TextSize = 16,
        TextColor3 = Crescent.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder
    })

    box.FocusLost:Connect(function(enterPressed)
        option.Value = box.Text
        Crescent.Flags[option.Flag] = box.Text
        option.Callback(box.Text, enterPressed)
    end)

    option.Instance = box
    function option:SetValue(value)
        self.Value = tostring(value)
        box.Text = self.Value
        Crescent.Flags[self.Flag] = self.Value
        self.Callback(self.Value, false)
    end
    return option
end

local function createBind(option, window)
    local holder = create("Frame", {
        LayoutOrder = option.Position,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Crescent.Theme.Panel2,
        BorderSizePixel = 0,
        Parent = option.ParentOverride or window.Content
    })
    addCorner(holder, UDim.new(0, 10))
    addStroke(holder, Color3.fromRGB(255, 255, 255), 0.93, 1)

    local label = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -98, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = option.Text,
        TextSize = 16,
        TextColor3 = Crescent.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder
    })

    local keyButton = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 78, 0, 22),
        BackgroundColor3 = Crescent.Theme.Panel3,
        AutoButtonColor = false,
        Text = "",
        Parent = holder
    })
    addCorner(keyButton, UDim.new(1, 0))

    local keyLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = typeof(option.Key) == "EnumItem" and option.Key.Name or tostring(option.Key),
        TextSize = 14,
        TextColor3 = Crescent.Theme.Text,
        Parent = keyButton
    })

    local waiting = false

    safePress(keyButton, function()
        waiting = true
        keyLabel.Text = "..."
        tween(keyButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Crescent.Theme.Accent}):Play()
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if waiting then
            local keyToUse = nil
            if input.UserInputType.Name:match("^MouseButton") then
                keyToUse = input.UserInputType
            elseif input.KeyCode ~= Enum.KeyCode.Unknown then
                keyToUse = input.KeyCode
            end
            if keyToUse then
                waiting = false
                option.Key = keyToUse
                Crescent.Flags[option.Flag] = keyToUse.Name
                keyLabel.Text = keyToUse.Name
                tween(keyButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Crescent.Theme.Panel3}):Play()
                return
            end
        end

        if UserInputService:GetFocusedTextBox() then return end
        local current = option.Key
        if current and (input.KeyCode == current or input.UserInputType == current) then
            if option.Hold then
                option._holding = true
                task.spawn(function()
                    while option._holding do
                        option.Callback(true)
                        task.wait()
                    end
                end)
            else
                option.Callback()
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if option.Hold and option._holding then
            local current = option.Key
            if current and (input.KeyCode == current or input.UserInputType == current) then
                option._holding = false
            end
        end
    end)

    bindHover(keyButton,
        function() if not waiting then tween(keyButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Crescent.Theme.Hover}):Play() end end,
        function() if not waiting then tween(keyButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Crescent.Theme.Panel3}):Play() end end
    )

    option.Instance = holder
    function option:SetKey(newKey)
        self.Key = newKey
        Crescent.Flags[self.Flag] = typeof(newKey) == "EnumItem" and newKey.Name or tostring(newKey)
        keyLabel.Text = typeof(newKey) == "EnumItem" and newKey.Name or tostring(newKey)
    end

    return option
end

local function createSlider(option, window)
    local holder = create("Frame", {
        LayoutOrder = option.Position,
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = Crescent.Theme.Panel2,
        BorderSizePixel = 0,
        Parent = option.ParentOverride or window.Content
    })
    addCorner(holder, UDim.new(0, 10))
    addStroke(holder, Color3.fromRGB(255, 255, 255), 0.93, 1)

    local label = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(1, -24, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = option.Text,
        TextSize = 14,
        TextColor3 = Crescent.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder
    })

    local valueText = create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 8),
        Size = UDim2.new(0, 64, 0, 16),
        Font = Enum.Font.Gotham,
        Text = tostring(option.Value),
        TextSize = 13,
        TextColor3 = Crescent.Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = holder
    })

    local bar = create("Frame", {
        Position = UDim2.new(0, 12, 1, -18),
        Size = UDim2.new(1, -24, 0, 8),
        BackgroundColor3 = Crescent.Theme.Idle,
        BorderSizePixel = 0,
        Parent = holder
    })
    addCorner(bar, UDim.new(1, 0))

    local fill = create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Crescent.Theme.Accent,
        BorderSizePixel = 0,
        Parent = bar
    })
    addCorner(fill, UDim.new(1, 0))

    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = bar
    })
    addCorner(knob, UDim.new(1, 0))

    local dragging = false

    local function updateFromX(x, silent)
        local alpha = clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local value = option.Min + ((option.Max - option.Min) * alpha)
        value = roundTo(value, option.Float)
        value = clamp(value, option.Min, option.Max)
        option.Value = value
        Crescent.Flags[option.Flag] = value
        local pct = (value - option.Min) / (option.Max - option.Min)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        valueText.Text = tostring(value)
        if not silent then
            option.Callback(value)
        end
    end

    bar.InputBegan:Connect(function(input)
        if isPointer(input) then
            dragging = true
            updateFromX(input.Position.X, false)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == TouchInput then
            updateFromX(input.Position.X, false)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if isPointer(input) then
            dragging = false
        end
    end)

    option.Instance = holder
    option.SetValue = function(_, value, silent)
        value = clamp(roundTo(tonumber(value) or option.Value, option.Float), option.Min, option.Max)
        option.Value = value
        Crescent.Flags[option.Flag] = value
        local pct = (value - option.Min) / (option.Max - option.Min)
        fill:TweenSize(UDim2.new(pct, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.12, true)
        knob:TweenPosition(UDim2.new(pct, 0, 0.5, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.12, true)
        valueText.Text = tostring(value)
        if not silent then
            option.Callback(value)
        end
    end

    option.SetValue(option, option.Value, true)
    return option
end

local function createDropdown(option, window)
    local holder = create("Frame", {
        LayoutOrder = option.Position,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Crescent.Theme.Panel2,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = option.ParentOverride or window.Content
    })
    addCorner(holder, UDim.new(0, 10))
    addStroke(holder, Color3.fromRGB(255, 255, 255), 0.93, 1)

    local title = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -24, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = option.Text,
        TextSize = 14,
        TextColor3 = Crescent.Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder
    })

    local valueLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 14),
        Size = UDim2.new(1, -24, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = option.Value,
        TextSize = 16,
        TextColor3 = Crescent.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder
    })

    local arrow = create("ImageLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 16, 0, 16),
        BackgroundTransparency = 1,
        Image = "rbxassetid://4918373417",
        ImageColor3 = Crescent.Theme.Muted,
        Rotation = 90,
        Parent = holder
    })

    local dropdownFrame = create("Frame", {
        ZIndex = 20,
        Visible = false,
        Size = UDim2.new(0, 240, 0, 34),
        BackgroundColor3 = Crescent.Theme.Panel2,
        BorderSizePixel = 0,
        Parent = window.Main.Parent
    })
    addCorner(dropdownFrame, UDim.new(0, 10))
    addStroke(dropdownFrame, Color3.fromRGB(255, 255, 255), 0.92, 1)

    local dropdownList = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Crescent.Theme.Panel3,
        Parent = dropdownFrame
    })
    setListPadding(dropdownList, 6, 6, 6, 6)
    local layout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = dropdownList
    })

    local open = false

    local function rebuild()
        for _, child in ipairs(dropdownList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        for _, value in ipairs(option.Values) do
            local item = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundColor3 = Crescent.Theme.Panel3,
                AutoButtonColor = false,
                Text = tostring(value),
                TextSize = 14,
                Font = Enum.Font.GothamBold,
                TextColor3 = Crescent.Theme.Text,
                Parent = dropdownList
            })
            addCorner(item, UDim.new(0, 8))
            item.Activated:Connect(function()
                option.Value = tostring(value)
                Crescent.Flags[option.Flag] = option.Value
                valueLabel.Text = option.Value
                option.Callback(option.Value)
                if Crescent.ActiveDropdown and Crescent.ActiveDropdown.Close then
                    Crescent.ActiveDropdown:Close()
                end
            end)
            bindHover(item,
                function() tween(item, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Crescent.Theme.Hover}):Play() end,
                function() tween(item, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Crescent.Theme.Panel3}):Play() end
            )
        end
    end

    local function openDropdown()
        if Crescent.ActiveDropdown and Crescent.ActiveDropdown.Close then
            Crescent.ActiveDropdown:Close()
        end
        open = true
        Crescent.ActiveDropdown = {
            Close = function()
                open = false
                dropdownFrame.Visible = false
                tween(arrow, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 90}):Play()
                Crescent.ActiveDropdown = nil
            end
        }
        local pos = holder.AbsolutePosition
        dropdownFrame.Position = UDim2.new(0, pos.X, 0, pos.Y + holder.AbsoluteSize.Y + 4)
        dropdownFrame.Visible = true
        rebuild()
        tween(arrow, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 270}):Play()
        dropdownFrame.Size = UDim2.new(0, 240, 0, 34)
        tween(dropdownFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 240, 0, math.min(220, 12 + layout.AbsoluteContentSize.Y))
        }):Play()
    end

    safePress(holder, function()
        if open then
            if Crescent.ActiveDropdown and Crescent.ActiveDropdown.Close then
                Crescent.ActiveDropdown:Close()
            end
        else
            openDropdown()
        end
    end)

    option.Instance = holder
    option.Close = function()
        open = false
        dropdownFrame.Visible = false
    end
    option.SetValue = function(_, value)
        option.Value = tostring(value)
        Crescent.Flags[option.Flag] = option.Value
        valueLabel.Text = option.Value
        option.Callback(option.Value)
    end
    rebuild()
    option:SetValue(option.Value)
    return option
end

local function createColorPicker(option, window)
    local holder = create("Frame", {
        LayoutOrder = option.Position,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Crescent.Theme.Panel2,
        BorderSizePixel = 0,
        Parent = option.ParentOverride or window.Content
    })
    addCorner(holder, UDim.new(0, 10))
    addStroke(holder, Color3.fromRGB(255, 255, 255), 0.93, 1)

    local label = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -54, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = option.Text,
        TextSize = 16,
        TextColor3 = Crescent.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder
    })

    local swatch = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 24, 0, 24),
        BackgroundColor3 = option.Color,
        BorderSizePixel = 0,
        Parent = holder
    })
    addCorner(swatch, UDim.new(1, 0))

    local popup = create("Frame", {
        ZIndex = 30,
        Visible = false,
        Size = UDim2.new(0, 260, 0, 220),
        BackgroundColor3 = Crescent.Theme.Panel2,
        BorderSizePixel = 0,
        Parent = window.Main.Parent
    })
    addCorner(popup, UDim.new(0, 12))
    addStroke(popup, Color3.fromRGB(255, 255, 255), 0.92, 1)

    local sat = create("Frame", {
        Position = UDim2.new(0, 10, 0, 10),
        Size = UDim2.new(0, 156, 0, 156),
        BackgroundColor3 = option.Color,
        BorderSizePixel = 0,
        Parent = popup
    })
    addCorner(sat, UDim.new(0, 10))

    create("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Image = "rbxassetid://4155801252",
        Parent = sat
    })

    local satCursor = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = sat
    })
    addCorner(satCursor, UDim.new(1, 0))
    addStroke(satCursor, Color3.fromRGB(255, 255, 255), 0.2, 2)

    local hueBar = create("Frame", {
        Position = UDim2.new(0, 10, 1, -34),
        Size = UDim2.new(0, 156, 0, 14),
        BackgroundTransparency = 1,
        Parent = popup
    })
    addCorner(hueBar, UDim.new(1, 0))
    create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
        }),
        Parent = hueBar
    })

    local hueCursor = create("Frame", {
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 2, 1, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = hueBar
    })

    local preview = create("Frame", {
        Position = UDim2.new(1, -84, 0, 10),
        Size = UDim2.new(0, 64, 0, 64),
        BackgroundColor3 = option.Color,
        BorderSizePixel = 0,
        Parent = popup
    })
    addCorner(preview, UDim.new(0, 10))
    addStroke(preview, Color3.fromRGB(255, 255, 255), 0.9, 1)

    local reset = create("TextButton", {
        Position = UDim2.new(1, -84, 0, 82),
        Size = UDim2.new(0, 64, 0, 26),
        BackgroundColor3 = Crescent.Theme.Panel3,
        AutoButtonColor = false,
        Text = "Reset",
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextColor3 = Crescent.Theme.Text,
        Parent = popup
    })
    addCorner(reset, UDim.new(0, 8))

    local confirm = create("TextButton", {
        Position = UDim2.new(1, -84, 0, 114),
        Size = UDim2.new(0, 64, 0, 26),
        BackgroundColor3 = Crescent.Theme.Accent,
        AutoButtonColor = false,
        Text = "Set",
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Parent = popup
    })
    addCorner(confirm, UDim.new(0, 8))

    local rainbow = create("TextButton", {
        Position = UDim2.new(1, -84, 0, 146),
        Size = UDim2.new(0, 64, 0, 26),
        BackgroundColor3 = Crescent.Theme.Panel3,
        AutoButtonColor = false,
        Text = "Rainbow",
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextColor3 = Crescent.Theme.Text,
        Parent = popup
    })
    addCorner(rainbow, UDim.new(0, 8))

    local open = false
    local draggingSat = false
    local draggingHue = false
    local rainbowEnabled = false
    local hue, satValue, valValue = Color3.toHSV(option.Color)
    local originalColor = option.Color
    local currentColor = option.Color

    local function refresh(color)
        color = color or currentColor
        currentColor = color
        local h, s, v = Color3.toHSV(color)
        hue, satValue, valValue = h, s, v
        sat.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        preview.BackgroundColor3 = color
        swatch.BackgroundColor3 = color
        hueCursor.Position = UDim2.new(1 - hue, 0, 0, 0)
        satCursor.Position = UDim2.new(satValue, 0, 1 - valValue, 0)
    end

    local function setColor(color, silent)
        option.Color = color
        Crescent.Flags[option.Flag] = color
        refresh(color)
        if not silent then
            option.Callback(color)
        end
    end

    local function openPopup()
        if Crescent.ActiveDropdown and Crescent.ActiveDropdown.Close then
            Crescent.ActiveDropdown:Close()
        end
        open = true
        popup.Visible = true
        local pos = holder.AbsolutePosition
        popup.Position = UDim2.new(0, pos.X, 0, pos.Y + holder.AbsoluteSize.Y + 6)
        refresh(option.Color)
    end

    local function closePopup()
        open = false
        popup.Visible = false
    end

    safePress(holder, function()
        if open then
            closePopup()
        else
            openPopup()
        end
    end)

    local function updateSatFromInput(input)
        local x = clamp((input.Position.X - sat.AbsolutePosition.X) / sat.AbsoluteSize.X, 0, 1)
        local y = clamp((input.Position.Y - sat.AbsolutePosition.Y) / sat.AbsoluteSize.Y, 0, 1)
        satValue = x
        valValue = 1 - y
        setColor(Color3.fromHSV(hue, satValue, valValue), false)
    end

    local function updateHueFromInput(input)
        local x = clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
        hue = 1 - x
        setColor(Color3.fromHSV(hue, satValue, valValue), false)
    end

    sat.InputBegan:Connect(function(input)
        if isPointer(input) then
            draggingSat = true
            updateSatFromInput(input)
        end
    end)

    hueBar.InputBegan:Connect(function(input)
        if isPointer(input) then
            draggingHue = true
            updateHueFromInput(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingSat and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == TouchInput) then
            updateSatFromInput(input)
        elseif draggingHue and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == TouchInput) then
            updateHueFromInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if isPointer(input) then
            draggingSat = false
            draggingHue = false
        end
    end)

    safePress(reset, function()
        setColor(originalColor, false)
    end)

    safePress(confirm, function()
        originalColor = currentColor
        setColor(currentColor, false)
    end)

    safePress(rainbow, function()
        rainbowEnabled = not rainbowEnabled
        if rainbowEnabled then
            task.spawn(function()
                while rainbowEnabled do
                    local c = Color3.fromHSV((tick() % 5) / 5, 1, 1)
                    setColor(c, false)
                    rainbow.TextColor3 = c
                    task.wait()
                end
            end)
        else
            rainbow.TextColor3 = Crescent.Theme.Text
        end
    end)

    option.Instance = holder
    option.SetColor = function(_, color, silent)
        setColor(color, silent)
    end
    option.Close = function()
        closePopup()
    end
    refresh(option.Color)
    return option
end

local function renderOption(option, window, parentOverride)
    option.ParentOverride = parentOverride or option.ParentOverride
    if option.Type == "label" then
        return createLabel(option, window)
    elseif option.Type == "separator" then
        return createSeparator(option, window)
    elseif option.Type == "paragraph" then
        return createParagraph(option, window)
    elseif option.Type == "toggle" then
        return createToggle(option, window)
    elseif option.Type == "button" then
        return createButton(option, window)
    elseif option.Type == "textbox" then
        return createTextbox(option, window)
    elseif option.Type == "bind" then
        return createBind(option, window)
    elseif option.Type == "slider" then
        return createSlider(option, window)
    elseif option.Type == "dropdown" then
        return createDropdown(option, window)
    elseif option.Type == "color" then
        return createColorPicker(option, window)
    elseif option.Type == "folder" then
        return createFolder(option, window)
    end
end

function Crescent:Notify(config)
    config = typeof(config) == "table" and config or {Text = tostring(config or "Notification")}
    local gui = self._gui
    if not gui then
        self:Init()
        gui = self._gui
    end

    local host = self._notifyHost
    if not host then
        host = create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = gui
        })
        self._notifyHost = host
    end

    local toast = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -24),
        Size = UDim2.new(0, 320, 0, 54),
        BackgroundColor3 = Crescent.Theme.Panel,
        BorderSizePixel = 0,
        Parent = host
    })
    addCorner(toast, UDim.new(0, 12))
    addStroke(toast, Color3.fromRGB(255, 255, 255), 0.92, 1)

    local title = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 8),
        Size = UDim2.new(1, -28, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = tostring(config.Title or "Crescent"),
        TextSize = 15,
        TextColor3 = Crescent.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = toast
    })

    local body = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 24),
        Size = UDim2.new(1, -28, 0, 20),
        Font = Enum.Font.Gotham,
        Text = tostring(config.Text or config.Body or config.Message or "Done"),
        TextSize = 13,
        TextColor3 = Crescent.Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = toast
    })

    local bar = create("Frame", {
        Position = UDim2.new(0, 0, 1, -3),
        Size = UDim2.new(1, 0, 0, 3),
        BackgroundColor3 = Crescent.Theme.Accent,
        BorderSizePixel = 0,
        Parent = toast
    })

    toast.BackgroundTransparency = 1
    title.TextTransparency = 1
    body.TextTransparency = 1
    bar.BackgroundTransparency = 1

    local duration = tonumber(config.Duration or 2) or 2
    task.spawn(function()
        TweenService:Create(toast, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
        TweenService:Create(title, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
        TweenService:Create(body, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
        TweenService:Create(bar, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
        task.wait(duration)
        TweenService:Create(toast, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
        TweenService:Create(title, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
        TweenService:Create(body, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
        TweenService:Create(bar, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
        task.wait(0.2)
        toast:Destroy()
    end)
end

function Crescent:CreateWindow(config)
    config = typeof(config) == "table" and config or {}
    local window = {
        Title = tostring(config.Title or config.title or "Window"),
        Subtitle = tostring(config.Subtitle or config.subtitle or ""),
        Width = tonumber(config.Width or config.width or 250) or 250,
        LoadingTitle = config.LoadingTitle or config.loadingTitle or nil,
        LoadingSubtitle = config.LoadingSubtitle or config.loadingSubtitle or nil,
        LoadingDuration = tonumber(config.LoadingDuration or config.loadingDuration or 1) or 1,
        Options = {},
        Open = true,
        Position = #self.Windows + 1,
        Initialized = false
    }

    local function addOption(option, typ)
        option = typeof(option) == "table" and option or {}
        option.Type = typ
        option.Position = #window.Options + 1
        option.Flag = option.Flag or option.flag or tostring(option.Text or option.text or option.Title or option.title or HttpService:GenerateGUID(false))
        table.insert(window.Options, option)
        return option
    end

    function window:AddLabel(option, parentOverride)
        option = addOption(option, "label")
        option.Text = tostring(option.Text or option.text or "")
        option.ParentOverride = parentOverride
        return option
    end
    function window:AddSeparator(option, parentOverride)
        option = addOption(option, "separator")
        option.ParentOverride = parentOverride
        return option
    end
    function window:AddParagraph(option, parentOverride)
        option = addOption(option, "paragraph")
        option.Title = tostring(option.Title or option.title or "Paragraph")
        option.Text = tostring(option.Text or option.text or "")
        option.ParentOverride = parentOverride
        return option
    end
    function window:AddToggle(option, parentOverride)
        option = addOption(option, "toggle")
        option.Text = tostring(option.Text or option.text or "Toggle")
        option.State = typeof(option.State) == "boolean" and option.State or false
        option.Callback = typeof(option.Callback) == "function" and option.Callback or function() end
        option.ParentOverride = parentOverride
        Crescent.Flags[option.Flag] = option.State
        return option
    end
    function window:AddButton(option, parentOverride)
        option = addOption(option, "button")
        option.Text = tostring(option.Text or option.text or "Button")
        option.Callback = typeof(option.Callback) == "function" and option.Callback or function() end
        option.ParentOverride = parentOverride
        return option
    end
    function window:AddTextbox(option, parentOverride)
        option = addOption(option, "textbox")
        option.Text = tostring(option.Text or option.text or "Textbox")
        option.Value = tostring(option.Value or option.value or "")
        option.Placeholder = tostring(option.Placeholder or option.placeholder or "")
        option.Callback = typeof(option.Callback) == "function" and option.Callback or function() end
        option.ParentOverride = parentOverride
        Crescent.Flags[option.Flag] = option.Value
        return option
    end
    function window:AddBind(option, parentOverride)
        option = addOption(option, "bind")
        option.Text = tostring(option.Text or option.text or "Bind")
        option.Key = option.Key or option.key or Enum.KeyCode.F
        option.Hold = typeof(option.Hold) == "boolean" and option.Hold or false
        option.Callback = typeof(option.Callback) == "function" and option.Callback or function() end
        option.ParentOverride = parentOverride
        Crescent.Flags[option.Flag] = typeof(option.Key) == "EnumItem" and option.Key.Name or tostring(option.Key)
        return option
    end
    function window:AddSlider(option, parentOverride)
        option = addOption(option, "slider")
        option.Text = tostring(option.Text or option.text or "Slider")
        option.Min = tonumber(option.Min or option.min or 0) or 0
        option.Max = tonumber(option.Max or option.max or 100) or 100
        option.Float = tonumber(option.Float or option.float or 1) or 1
        option.Value = tonumber(option.Value or option.value or option.Min) or option.Min
        option.Value = clamp(option.Value, option.Min, option.Max)
        option.Callback = typeof(option.Callback) == "function" and option.Callback or function() end
        option.ParentOverride = parentOverride
        Crescent.Flags[option.Flag] = option.Value
        return option
    end
    function window:AddDropdown(option, parentOverride)
        option = addOption(option, "dropdown")
        option.Text = tostring(option.Text or option.text or "Dropdown")
        option.Values = typeof(option.Values) == "table" and option.Values or {}
        option.Value = tostring(option.Value or option.value or option.Values[1] or "")
        option.Callback = typeof(option.Callback) == "function" and option.Callback or function() end
        option.Open = false
        option.ParentOverride = parentOverride
        Crescent.Flags[option.Flag] = option.Value
        return option
    end
    function window:AddColor(option, parentOverride)
        option = addOption(option, "color")
        option.Text = tostring(option.Text or option.text or "Color")
        option.Color = toColor3(option.Color or option.color, Color3.fromRGB(255, 255, 255))
        option.Callback = typeof(option.Callback) == "function" and option.Callback or function() end
        option.Open = false
        option.ParentOverride = parentOverride
        Crescent.Flags[option.Flag] = option.Color
        return option
    end

    function window:AddFolder(option, parentOverride)
        option = addOption(option, "folder")
        option.Title = tostring(option.Title or option.title or "Folder")
        option.ParentOverride = parentOverride
        option.Children = option.Children or {}

        local function queueChild(child, typ)
            child = typeof(child) == "table" and child or {}
            child.Type = typ
            child.Position = #option.Children + 1
            child.Flag = child.Flag or child.flag or tostring(child.Text or child.text or child.Title or child.title or HttpService:GenerateGUID(false))
            table.insert(option.Children, child)
            return child
        end

        function option:AddLabel(child) child = queueChild(child, "label"); child.Text = tostring(child.Text or child.text or ""); return child end
        function option:AddSeparator(child) child = queueChild(child, "separator"); return child end
        function option:AddParagraph(child) child = queueChild(child, "paragraph"); child.Title = tostring(child.Title or child.title or "Paragraph"); child.Text = tostring(child.Text or child.text or ""); return child end
        function option:AddToggle(child) child = queueChild(child, "toggle"); child.Text = tostring(child.Text or child.text or "Toggle"); child.State = typeof(child.State) == "boolean" and child.State or false; child.Callback = typeof(child.Callback) == "function" and child.Callback or function() end; Crescent.Flags[child.Flag] = child.State; return child end
        function option:AddButton(child) child = queueChild(child, "button"); child.Text = tostring(child.Text or child.text or "Button"); child.Callback = typeof(child.Callback) == "function" and child.Callback or function() end; return child end
        function option:AddTextbox(child) child = queueChild(child, "textbox"); child.Text = tostring(child.Text or child.text or "Textbox"); child.Value = tostring(child.Value or child.value or ""); child.Placeholder = tostring(child.Placeholder or child.placeholder or ""); child.Callback = typeof(child.Callback) == "function" and child.Callback or function() end; Crescent.Flags[child.Flag] = child.Value; return child end
        function option:AddBind(child) child = queueChild(child, "bind"); child.Text = tostring(child.Text or child.text or "Bind"); child.Key = child.Key or child.key or Enum.KeyCode.F; child.Hold = typeof(child.Hold) == "boolean" and child.Hold or false; child.Callback = typeof(child.Callback) == "function" and child.Callback or function() end; Crescent.Flags[child.Flag] = typeof(child.Key) == "EnumItem" and child.Key.Name or tostring(child.Key); return child end
        function option:AddSlider(child) child = queueChild(child, "slider"); child.Text = tostring(child.Text or child.text or "Slider"); child.Min = tonumber(child.Min or child.min or 0) or 0; child.Max = tonumber(child.Max or child.max or 100) or 100; child.Float = tonumber(child.Float or child.float or 1) or 1; child.Value = tonumber(child.Value or child.value or child.Min) or child.Min; child.Value = clamp(child.Value, child.Min, child.Max); child.Callback = typeof(child.Callback) == "function" and child.Callback or function() end; Crescent.Flags[child.Flag] = child.Value; return child end
        function option:AddDropdown(child) child = queueChild(child, "dropdown"); child.Text = tostring(child.Text or child.text or "Dropdown"); child.Values = typeof(child.Values) == "table" and child.Values or {}; child.Value = tostring(child.Value or child.value or child.Values[1] or ""); child.Callback = typeof(child.Callback) == "function" and child.Callback or function() end; child.Open = false; Crescent.Flags[child.Flag] = child.Value; return child end
        function option:AddColor(child) child = queueChild(child, "color"); child.Text = tostring(child.Text or child.text or "Color"); child.Color = toColor3(child.Color or child.color, Color3.fromRGB(255, 255, 255)); child.Callback = typeof(child.Callback) == "function" and child.Callback or function() end; child.Open = false; Crescent.Flags[child.Flag] = child.Color; return child end

        return option
    end

    function window:Init()
        if self.Initialized then return self end
        local gui = Crescent._gui
        if not gui then
            gui = create("ScreenGui", {
                Name = "CrescentUI",
                ResetOnSpawn = false,
                IgnoreGuiInset = true,
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            })
            protectGui(gui)
            Crescent._gui = gui
        end

        Crescent._container = Crescent._container or create("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Parent = gui
        })

        if self.LoadingTitle or self.LoadingSubtitle then
            Crescent:ShowLoading(self.LoadingTitle or self.Title, self.LoadingSubtitle or self.Subtitle or "", self.LoadingDuration or 1)
        end

        local state = createWindowContainer(self, Crescent._container)
        self.State = state
        self.Main = state.Main
        self.Content = state.Content
        self.ContentLayout = state.ContentLayout
        self.Initialized = true

        for _, option in ipairs(self.Options) do
            renderOption(option, state)
        end

        state:Refresh()
        return self
    end

    function window:Refresh() if self.State and self.State.Refresh then self.State:Refresh() end end
    function window:Close() self.Open = false; if self.State and self.State.Main then self.State.Main.Visible = false end end
    function window:OpenWindow() self.Open = true; if self.State and self.State.Main then self.State.Main.Visible = true end end

    table.insert(self.Windows, window)

    if config.AutoInit ~= false then
        task.defer(function()
            if not window.Initialized then
                window:Init()
            end
        end)
    end

    return window
end

function Crescent:Init()
    if self._initialized then return self end
    self._initialized = true

    if not self._gui then
        local gui = create("ScreenGui", {
            Name = "CrescentUI",
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        })
        protectGui(gui)
        self._gui = gui
    end

    self._container = self._container or create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Parent = self._gui
    })

    for _, window in ipairs(self.Windows) do
        if not window.Initialized then
            window:Init()
        end
    end

    if self._antiIdleBound ~= true and LocalPlayer then
        self._antiIdleBound = true
        pcall(function()
            local VirtualUser = game:GetService("VirtualUser")
            LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end)
    end

    return self
end

function Crescent:Close()
    self.Open = not self.Open
    if self.ActiveDropdown and self.ActiveDropdown.Close then
        self.ActiveDropdown:Close()
    end
    for _, window in ipairs(self.Windows) do
        if window.State and window.State.Main then
            window.State.Main.Visible = self.Open and window.Open
        end
    end
end

pcall(function() Crescent:Init() end)

return Crescent
