
-- Framify Importer
-- Version: 2.0.0
-- This script contains the full, final, and completely refactored logic for the Framify Roblox Studio plugin.

local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local VERSION = "2.0.0"

local Config = {
    TARGET_SCREEN_GUI = "FramifyImport",
    ASSET_FOLDER_NAME = "FramifyAssets",
    CREATE_BEHAVIOR_SCRIPTS = true,
    SHOW_ANCHOR_POPUP = true,
    AUTO_SCALE = true,
    THEME = "Dracula"
}

local Themes = {
    ["Dracula"] = { BG=Color3.fromRGB(30,32,42), Text=Color3.fromRGB(248,248,242), TextSecondary=Color3.fromRGB(155,166,178), Primary=Color3.fromRGB(98,159,217), Surface=Color3.fromRGB(40,42,54), Border=Color3.fromRGB(60,63,81), Danger=Color3.fromRGB(255,107,107) },
    ["Solarized"] = { BG=Color3.fromRGB(0,43,54), Text=Color3.fromRGB(131,148,150), TextSecondary=Color3.fromRGB(88,110,117), Primary=Color3.fromRGB(38,139,210), Surface=Color3.fromRGB(7,54,66), Border=Color3.fromRGB(147,161,161), Danger=Color3.fromRGB(220,50,47) },
    ["Midnight"] = { BG=Color3.fromRGB(16,16,20), Text=Color3.fromRGB(220,220,220), TextSecondary=Color3.fromRGB(140,140,140), Primary=Color3.fromRGB(100,120,255), Surface=Color3.fromRGB(24,24,28), Border=Color3.fromRGB(45,45,50), Danger=Color3.fromRGB(255,100,100) },
    ["High Contrast"] = { BG=Color3.fromRGB(18,18,18), Text=Color3.fromRGB(255,255,255), TextSecondary=Color3.fromRGB(180,180,180), Primary=Color3.fromRGB(0,122,255), Surface=Color3.fromRGB(35,35,35), Border=Color3.fromRGB(70,70,70), Danger=Color3.fromRGB(220,60,60) },
    ["Green"] = { BG=Color3.fromRGB(18,25,21), Text=Color3.fromRGB(200,255,220), TextSecondary=Color3.fromRGB(150,200,170), Primary=Color3.fromRGB(76,175,80), Surface=Color3.fromRGB(25,35,28), Border=Color3.fromRGB(45,85,60), Danger=Color3.fromRGB(180,80,80) },
    ["Light"] = { BG=Color3.fromRGB(250,250,250), Text=Color3.fromRGB(20,20,20), TextSecondary=Color3.fromRGB(100,100,100), Primary=Color3.fromRGB(0,122,255), Surface=Color3.fromRGB(240,240,240), Border=Color3.fromRGB(200,200,200), Danger=Color3.fromRGB(220,60,60) },
    ["Cyberpunk"] = { BG=Color3.fromRGB(18,18,25), Text=Color3.fromRGB(0,255,255), TextSecondary=Color3.fromRGB(160,160,180), Primary=Color3.fromRGB(255,0,255), Surface=Color3.fromRGB(25,25,35), Border=Color3.fromRGB(100,0,200), Danger=Color3.fromRGB(255,100,100) },
    ["Nature"] = { BG=Color3.fromRGB(40,55,35), Text=Color3.fromRGB(230,230,225), TextSecondary=Color3.fromRGB(180,185,175), Primary=Color3.fromRGB(115,155,96), Surface=Color3.fromRGB(50,65,45), Border=Color3.fromRGB(130,115,100), Danger=Color3.fromRGB(190,80,70) }
}

local UI = {}
local dropdownState = { isOpen = false, currentDropdown = nil }
local fontMap = { ['Arial']=Enum.Font.Legacy, ['Roboto']=Enum.Font.SourceSans, ['Inter']=Enum.Font.SourceSans, ['Gotham']=Enum.Font.Gotham }

function styleButton(button, styleType, theme)
    button.Font = Enum.Font.Gotham
    button.TextSize = 13
    button.TextScaled = true
    button.AutoButtonColor = false

    local corner = button:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    if styleType == "Primary" then 
        button.BackgroundColor3 = theme.Primary
        button.TextColor3 = Color3.fromRGB(255,255,255)
    elseif styleType == "Secondary" then 
        button.BackgroundColor3 = theme.Surface
        button.TextColor3 = theme.Text
    elseif styleType == "Danger" then 
        button.BackgroundColor3 = theme.Danger
        button.TextColor3 = Color3.fromRGB(255,255,255)
    end

    local stroke = button:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = theme.Border
    stroke.Thickness = 1
    stroke.Parent = button

    local originalColor = button.BackgroundColor3
    local originalStroke = stroke.Color

    button.MouseEnter:Connect(function()
        local brighterColor = Color3.new(
            math.min(1, originalColor.R * 1.15),
            math.min(1, originalColor.G * 1.15),
            math.min(1, originalColor.B * 1.15)
        )
        TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = brighterColor
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Color = theme.Primary
        }):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = originalColor
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Color = originalStroke
        }):Play()
    end)

    button.MouseButton1Down:Connect(function()
        local darkerColor = Color3.new(
            originalColor.R * 0.85,
            originalColor.G * 0.85,
            originalColor.B * 0.85
        )
        TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = darkerColor,
            Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset, button.Size.Y.Scale, button.Size.Y.Offset - 1)
        }):Play()
    end)

    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            BackgroundColor3 = originalColor,
            Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset, button.Size.Y.Scale, button.Size.Y.Offset + 1)
        }):Play()
    end)
end

function closeDropdown()
    if dropdownState.isOpen and dropdownState.currentDropdown then
        dropdownState.isOpen = false
        local optionsFrame = dropdownState.currentDropdown
        local tween = TweenService:Create(optionsFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, 0)
        })
        tween:Play()
        tween.Completed:Connect(function()
            optionsFrame.Visible = false
        end)
        dropdownState.currentDropdown = nil
    end
end

function applyTheme(themeName)
    local theme = Themes[themeName] or Themes["Dracula"]
    Config.THEME = themeName
    for name, element in pairs(UI) do
        if not element.Parent then continue end
        if name:match("Frame$") then 
            element.BackgroundColor3 = theme.BG
        elseif name:match("Title") then 
            element.TextColor3 = theme.Text
        elseif name:match("Label") or name:match("Support") or name:match("Instructions") or name:match("Version") or name:match("PromptText") then 
            element.TextColor3 = theme.TextSecondary
            element.BackgroundTransparency = 1
        elseif name:match("TextScrollFrame") then 
            element.BackgroundColor3 = theme.Surface
            element.BorderColor3 = theme.Border
        elseif name:match("TextBox") then 
            element.BackgroundColor3 = theme.Surface
            element.TextColor3 = theme.Text
            element.PlaceholderColor3 = theme.TextSecondary
        elseif name:match("Icon") then 
            element.ImageColor3 = theme.TextSecondary
        end
        if element:IsA("TextButton") then
            local style = element:GetAttribute("StyleType")
            if style then
                styleButton(element, style, theme)
            end
        end
    end
    if UI.SettingsThemeDropdown then
        styleButton(UI.SettingsThemeDropdown, "Secondary", theme)
        local optionsFrame = UI.SettingsThemeOptionsFrame
        if optionsFrame then
            optionsFrame.BackgroundColor3 = theme.Surface
            optionsFrame.BorderColor3 = theme.Border
            local stroke = optionsFrame:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
            stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            stroke.Color = theme.Border
            stroke.Thickness = 1
            stroke.Parent = optionsFrame
            for _, child in ipairs(optionsFrame:GetChildren()) do
                if child:IsA("TextButton") then
                    child.BackgroundColor3 = theme.Surface
                    child.TextColor3 = theme.Text
                    child.Font = Enum.Font.Gotham
                    child.TextSize = 12
                    child.TextScaled = true
                end
            end
        end
    end
end

function createLoadingUI(widget)
    local container = Instance.new("Frame")
    container.Name = "LoadingContainer"
    container.Size = UDim2.fromScale(1, 1)
    container.BackgroundTransparency = 1
    container.ZIndex = 10
    container.Parent = widget
    UI.LoadingContainer = container

    local topHalf = Instance.new("Frame")
    topHalf.Name = "TopHalf"
    topHalf.Size = UDim2.new(1, 0, 0.5, 0)
    topHalf.Position = UDim2.new(0, 0, 0, 0)
    topHalf.BackgroundColor3 = Themes[Config.THEME].BG
    topHalf.BorderSizePixel = 0
    topHalf.ClipsDescendants = true
    topHalf.Parent = container
    UI.LoadingTopHalf = topHalf

    local bottomHalf = Instance.new("Frame")
    bottomHalf.Name = "BottomHalf"
    bottomHalf.Size = UDim2.new(1, 0, 0.5, 0)
    bottomHalf.Position = UDim2.new(0, 0, 0.5, 0)
    bottomHalf.BackgroundColor3 = Themes[Config.THEME].BG
    bottomHalf.BorderSizePixel = 0
    bottomHalf.ClipsDescendants = true
    bottomHalf.Parent = container
    UI.LoadingBottomHalf = bottomHalf

    local function addGradient(parent)
        local gradient = Instance.new("UIGradient", parent)
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Themes[Config.THEME].BG),
            ColorSequenceKeypoint.new(0.5, Color3.new(
                math.min(1, Themes[Config.THEME].BG.R * 1.1),
                math.min(1, Themes[Config.THEME].BG.G * 1.1),
                math.min(1, Themes[Config.THEME].BG.B * 1.1)
            )),
            ColorSequenceKeypoint.new(1, Themes[Config.THEME].BG)
        }
        gradient.Rotation = 45
    end
    addGradient(topHalf)
    addGradient(bottomHalf)

    local logo = Instance.new("ImageLabel", topHalf)
    logo.Name = "Logo"
    logo.Image = "rbxassetid://127991582997910"
    logo.BackgroundTransparency = 1
    logo.Size = UDim2.new(0, 40, 0, 52)
    logo.AnchorPoint = Vector2.new(0.5, 1)
    logo.Position = UDim2.new(0.5, 0, 0.85, 0)
    logo.ImageTransparency = 1
    logo.ScaleType = Enum.ScaleType.Fit
    UI.LoadingLogo = logo

    local titleLabel = Instance.new("TextLabel", topHalf)
    titleLabel.Name = "LoadingTitle"
    titleLabel.Text = "Framify"
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 20
    titleLabel.TextScaled = true
    titleLabel.TextColor3 = Themes[Config.THEME].Text
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, 0, 0, 28)
    titleLabel.AnchorPoint = Vector2.new(0.5, 1)
    titleLabel.Position = UDim2.new(0.5, 0, 0.98, 0)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.TextTransparency = 1
    UI.LoadingTitle = titleLabel

    local barContainer = Instance.new("Frame", bottomHalf)
    barContainer.Name = "BarContainer"
    barContainer.BackgroundTransparency = 1
    barContainer.Size = UDim2.new(0.6, 0, 0, 6)
    barContainer.AnchorPoint = Vector2.new(0.5, 0)
    barContainer.Position = UDim2.new(0.5, 0, 0.1, 0)
    UI.LoadingBarContainer = barContainer

    local barBG = Instance.new("Frame", barContainer)
    barBG.Name = "BarBackground"
    barBG.BackgroundColor3 = Themes[Config.THEME].Surface
    barBG.BorderSizePixel = 0
    barBG.Size = UDim2.fromScale(1, 1)
    local barBGCorner = Instance.new("UICorner", barBG)
    barBGCorner.CornerRadius = UDim.new(0.5, 0)

    local bar = Instance.new("Frame", barContainer)
    bar.Name = "LoadingBar"
    bar.BackgroundColor3 = Themes[Config.THEME].Primary
    bar.BorderSizePixel = 0
    bar.Size = UDim2.fromScale(0, 1)
    bar.Position = UDim2.fromScale(0, 0)
    UI.LoadingBar = bar

    local barCorner = Instance.new("UICorner", bar)
    barCorner.CornerRadius = UDim.new(0.5, 0)

    local subtitleLabel = Instance.new("TextLabel", bottomHalf)
    subtitleLabel.Name = "LoadingSubtitle"
    subtitleLabel.Text = "Loading..."
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.TextSize = 11
    subtitleLabel.TextScaled = true
    subtitleLabel.TextColor3 = Themes[Config.THEME].TextSecondary
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Size = UDim2.new(1, 0, 0, 18)
    subtitleLabel.AnchorPoint = Vector2.new(0.5, 0)
    subtitleLabel.Position = UDim2.new(0.5, 0, 0.2, 0)
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Center
    subtitleLabel.TextTransparency = 1
    UI.LoadingSubtitle = subtitleLabel

    return container, logo, bar
end

function createMainUI(widget)
    local containerFrame = Instance.new("Frame")
    containerFrame.Name = "MainFrameContainer"
    containerFrame.Size = UDim2.fromScale(1, 1)
    containerFrame.BackgroundTransparency = 1
    containerFrame.ZIndex = 1
    containerFrame.Parent = widget

    local cg = Instance.new("CanvasGroup")
    cg.Name = "MainFrame"
    cg.Size = UDim2.fromScale(1, 1)
    cg.Visible = false
    cg.GroupTransparency = 1
    cg.AnchorPoint = Vector2.new(0.5, 0.5)
    cg.Position = UDim2.new(0.5, 0, 0.52, 0)
    cg.Parent = containerFrame
    UI.MainFrame = cg

    local p = Instance.new("UIPadding", cg)
    p.PaddingLeft = UDim.new(0, 24)
    p.PaddingRight = UDim.new(0, 24)
    p.PaddingTop = UDim.new(0, 20)
    p.PaddingBottom = UDim.new(0, 20)

    local l = Instance.new("UIListLayout", cg)
    l.Padding = UDim.new(0, 16)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local header = Instance.new("Frame", cg)
    header.Name = "Header"
    header.BackgroundTransparency = 1
    header.LayoutOrder = 1
    header.Size = UDim2.new(1, 0, 0, 36)
    UI.MainHeader = header

    local hl = Instance.new("UIListLayout", header)
    hl.FillDirection = Enum.FillDirection.Horizontal
    hl.VerticalAlignment = Enum.VerticalAlignment.Center
    hl.HorizontalAlignment = Enum.HorizontalAlignment.Left
    hl.Padding = UDim.new(0, 10)

    local logo = Instance.new("ImageLabel")
    logo.Name = "Logo"
    logo.Image = "rbxassetid://127991582997910"
    logo.BackgroundTransparency = 1
    logo.Size = UDim2.new(0, 28, 0, 36)
    logo.ScaleType = Enum.ScaleType.Fit
    UI.MainLogo = logo

    local t = Instance.new("TextLabel", header)
    t.Name = "Title"
    t.Text = "Framify Importer"
    t.Font = Enum.Font.GothamBold
    t.TextSize = 16
    t.TextScaled = true
    t.BackgroundTransparency = 1
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Size = UDim2.new(1, -38, 1, 0)
    UI.MainTitle = t

    local i = Instance.new("TextLabel", cg)
    i.Name = "Instructions"
    i.LayoutOrder = 2
    i.Text = "Paste your mapping string below to begin."
    i.Size = UDim2.new(1, 0, 0, 18)
    i.Font = Enum.Font.Gotham
    i.TextSize = 11
    i.TextScaled = true
    i.TextWrapped = true
    i.BackgroundTransparency = 1
    i.TextXAlignment = Enum.TextXAlignment.Center
    UI.MainInstructions = i

    local s = Instance.new("ScrollingFrame", cg)
    s.Name = "TextScrollFrame"
    s.LayoutOrder = 3
    s.Size = UDim2.new(1, 0, 0, 200)
    s.BorderSizePixel = 0
    s.BackgroundTransparency = 0
    s.ScrollBarThickness = 6
    UI.MainTextScrollFrame = s

    local sCorner = Instance.new("UICorner", s)
    sCorner.CornerRadius = UDim.new(0, 6)

    local sStroke = Instance.new("UIStroke", s)
    sStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    sStroke.Thickness = 1

    local tb = Instance.new("TextBox", s)
    tb.Name = "TextBox"
    tb.AutomaticSize = Enum.AutomaticSize.Y
    tb.Font = Enum.Font.Code
    tb.TextSize = 10
    tb.TextScaled = false
    tb.MultiLine = true
    tb.ClearTextOnFocus = false
    tb.PlaceholderText = "Paste your Framify mapping string here..."
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.TextYAlignment = Enum.TextYAlignment.Top
    tb.Size = UDim2.new(1, -16, 0, 0)
    tb.Position = UDim2.fromOffset(8, 8)
    tb.BackgroundTransparency = 1
    UI.MainMappingTextBox = tb

    tb:GetPropertyChangedSignal("Text"):Connect(function()
        s.CanvasSize = UDim2.new(0, 0, 0, math.max(tb.AbsoluteSize.Y + 16, s.AbsoluteSize.Y))
    end)

    local btn = Instance.new("TextButton", cg)
    btn:SetAttribute("StyleType", "Primary")
    btn.LayoutOrder = 4
    btn.Text = "Import"
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextScaled = true
    btn.BackgroundColor3 = Themes[Config.THEME].Primary
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BorderSizePixel = 0
    UI.MainImportButton = btn

    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 6)

    local st = Instance.new("TextLabel", cg)
    st.Name = "Label"
    st.LayoutOrder = 5
    st.Text = ""
    st.Font = Enum.Font.Gotham
    st.TextSize = 10
    st.TextScaled = true
    st.BackgroundTransparency = 1
    st.TextXAlignment = Enum.TextXAlignment.Center
    st.Size = UDim2.new(1, 0, 0, 14)
    UI.MainStatusLabel = st

    local v = Instance.new("TextLabel", cg)
    v.Name = "Version"
    v.LayoutOrder = 6
    v.Text = "V" .. VERSION
    v.Font = Enum.Font.Gotham
    v.TextSize = 9
    v.TextScaled = true
    v.BackgroundTransparency = 1
    v.Size = UDim2.new(1, 0, 0, 12)
    v.TextXAlignment = Enum.TextXAlignment.Center
    UI.MainVersionLabel = v

    local sup = Instance.new("TextLabel", cg)
    sup.Name = "Support"
    sup.LayoutOrder = 7
    sup.Text = "Contact .ludio. on Discord for support/errors"
    sup.Font = Enum.Font.Gotham
    sup.TextSize = 8
    sup.TextScaled = true
    sup.BackgroundTransparency = 1
    sup.Size = UDim2.new(1, 0, 0, 14)
    sup.TextXAlignment = Enum.TextXAlignment.Center
    UI.MainSupportLabel = sup

    return btn, tb, st, cg, logo
end

function createSettingsUI(widget)
    local f = Instance.new("Frame")
    f.Name = "SettingsFrame"
    f.Size = UDim2.fromScale(1, 1)
    f.Parent = widget
    UI.SettingsFrame = f

    local p = Instance.new("UIPadding", f)
    p.PaddingLeft = UDim.new(0, 20)
    p.PaddingRight = UDim.new(0, 20)
    p.PaddingTop = UDim.new(0, 16)
    p.PaddingBottom = UDim.new(0, 16)

    local l = Instance.new("UIListLayout", f)
    l.Padding = UDim.new(0, 10)
    l.SortOrder = Enum.SortOrder.LayoutOrder

    local t = Instance.new("TextLabel", f)
    t.Name = "Title"
    t.LayoutOrder = 1
    t.Text = "Settings"
    t.Size = UDim2.new(1, 0, 0, 28)
    t.Font = Enum.Font.GothamBold
    t.TextSize = 16
    t.TextScaled = true
    t.BackgroundTransparency = 1
    t.TextXAlignment = Enum.TextXAlignment.Left
    UI.SettingsTitle = t

    local function createToggle(order, text, key)
        local btn = Instance.new("TextButton", f)
        btn:SetAttribute("StyleType", "Secondary")
        btn.LayoutOrder = order
        btn.Size = UDim2.new(1, 0, 0, 32)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 11
        btn.TextScaled = true

        local function updateText()
            btn.Text = text .. ": " .. (Config[key] and "✓ On" or "✗ Off")
        end
        updateText()

        btn.MouseButton1Click:Connect(function()
            Config[key] = not Config[key]
            updateText()

            local flashColor = Config[key] and Themes[Config.THEME].Primary or Themes[Config.THEME].Danger
            local originalColor = btn.BackgroundColor3
            TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = flashColor
            }):Play()
            task.wait(0.08)
            TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = originalColor
            }):Play()
        end)
        return btn
    end

    local al = Instance.new("TextLabel", f)
    al.Name = "Label"
    al.LayoutOrder = 2
    al.Text = "Asset Folder Name"
    al.Size = UDim2.new(1, 0, 0, 16)
    al.Font = Enum.Font.Gotham
    al.TextSize = 11
    al.TextScaled = true
    al.BackgroundTransparency = 1
    al.TextXAlignment = Enum.TextXAlignment.Left
    UI.SettingsAssetLabel = al

    local at = Instance.new("TextBox", f)
    at.Name = "TextBox"
    at.LayoutOrder = 3
    at.Text = Config.ASSET_FOLDER_NAME
    at.Size = UDim2.new(1, 0, 0, 28)
    at.Font = Enum.Font.Code
    at.TextSize = 11
    at.TextScaled = true
    at.BackgroundTransparency = 0
    UI.SettingsAssetText = at

    local atCorner = Instance.new("UICorner", at)
    atCorner.CornerRadius = UDim.new(0, 6)

    local atStroke = Instance.new("UIStroke", at)
    atStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    atStroke.Thickness = 1

    at.FocusLost:Connect(function()
        Config.ASSET_FOLDER_NAME = at.Text
        local flashColor = Themes[Config.THEME].Primary
        local originalStroke = atStroke.Color
        TweenService:Create(atStroke, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Color = flashColor
        }):Play()
        task.wait(0.2)
        TweenService:Create(atStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Color = originalStroke
        }):Play()
    end)

    UI.SettingsAnchorPopupCheck = createToggle(4, "Show Anchoring Popup", "SHOW_ANCHOR_POPUP")
    UI.SettingsScaleCheck = createToggle(5, "Auto Scale UI", "AUTO_SCALE")

    local tl = Instance.new("TextLabel", f)
    tl.Name = "Label"
    tl.LayoutOrder = 6
    tl.Text = "Theme"
    tl.Size = UDim2.new(1, 0, 0, 16)
    tl.Font = Enum.Font.Gotham
    tl.TextSize = 11
    tl.TextScaled = true
    tl.BackgroundTransparency = 1
    tl.TextXAlignment = Enum.TextXAlignment.Left
    UI.SettingsThemeLabel = tl

    local dropdownContainer = Instance.new("Frame", f)
    dropdownContainer.Name = "DropdownContainer"
    dropdownContainer.LayoutOrder = 7
    dropdownContainer.Size = UDim2.new(1, 0, 0, 32)
    dropdownContainer.BackgroundTransparency = 1
    dropdownContainer.ZIndex = 10

    local dropdownButton = Instance.new("TextButton", dropdownContainer)
    dropdownButton:SetAttribute("StyleType", "Secondary")
    dropdownButton.Size = UDim2.fromScale(1, 1)
    dropdownButton.Text = "🎨 " .. Config.THEME
    dropdownButton.Font = Enum.Font.Gotham
    dropdownButton.TextSize = 11
    dropdownButton.TextScaled = true
    UI.SettingsThemeDropdown = dropdownButton

    local optionsFrame = Instance.new("ScrollingFrame", dropdownContainer)
    optionsFrame.Name = "OptionsFrame"
    optionsFrame.Position = UDim2.new(0, 0, 1, 2)
    optionsFrame.Size = UDim2.new(1, 0, 0, 0)
    optionsFrame.ClipsDescendants = true
    optionsFrame.Visible = false
    optionsFrame.ZIndex = 50
    optionsFrame.BorderSizePixel = 0
    optionsFrame.BackgroundTransparency = 0
    optionsFrame.ScrollBarThickness = 4
    local optionsCorner = Instance.new("UICorner", optionsFrame)
    optionsCorner.CornerRadius = UDim.new(0, 6)
    UI.SettingsThemeOptionsFrame = optionsFrame

    local optionsLayout = Instance.new("UIListLayout", optionsFrame)
    optionsLayout.Padding = UDim.new(0, 1)
    optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder

    dropdownButton.MouseButton1Click:Connect(function()
        if dropdownState.isOpen then
            closeDropdown()
        else
            dropdownState.isOpen = true
            dropdownState.currentDropdown = optionsFrame
            optionsFrame.Visible = true

            local themeCount = 0
            for _ in pairs(Themes) do
                themeCount = themeCount + 1
            end
            optionsFrame.CanvasSize = UDim2.new(0, 0, 0, themeCount * 26 + (themeCount - 1))

            local targetHeight = math.min(120, themeCount * 27)
            TweenService:Create(optionsFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 0, targetHeight)
            }):Play()
        end
    end)

    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and dropdownState.isOpen then
            local mousePos = UserInputService:GetMouseLocation()
            local dropdownPos = dropdownContainer.AbsolutePosition
            local dropdownSize = dropdownContainer.AbsoluteSize

            if mousePos.X < dropdownPos.X or mousePos.X > dropdownPos.X + dropdownSize.X or
               mousePos.Y < dropdownPos.Y or mousePos.Y > dropdownPos.Y + dropdownSize.Y + 120 then
                closeDropdown()
            end
        end
    end)

    local layoutOrder = 0
    for themeName, theme in pairs(Themes) do
        layoutOrder = layoutOrder + 1
        local optionButton = Instance.new("TextButton", optionsFrame)
        optionButton.Name = themeName
        optionButton.Text = themeName
        optionButton.LayoutOrder = layoutOrder
        optionButton.Size = UDim2.new(1, -6, 0, 24)
        optionButton.BackgroundTransparency = 0
        optionButton.BackgroundColor3 = Themes[Config.THEME].Surface
        optionButton.TextColor3 = Themes[Config.THEME].Text
        optionButton.Font = Enum.Font.Gotham
        optionButton.TextSize = 10
        optionButton.TextScaled = true
        optionButton.BorderSizePixel = 0
        optionButton.AutoButtonColor = false
        optionButton.ZIndex = 51
        local optionCorner = Instance.new("UICorner", optionButton)
        optionCorner.CornerRadius = UDim.new(0, 4)

        optionButton.MouseEnter:Connect(function()
            TweenService:Create(optionButton, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = Themes[Config.THEME].Primary,
                TextColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
        end)

        optionButton.MouseLeave:Connect(function()
            TweenService:Create(optionButton, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = Themes[Config.THEME].Surface,
                TextColor3 = Themes[Config.THEME].Text
            }):Play()
        end)

        optionButton.MouseButton1Click:Connect(function()
            dropdownButton.Text = "🎨 " .. themeName
            closeDropdown()
            applyTheme(themeName)

            TweenService:Create(dropdownButton, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 1, 2)
            }):Play()
            task.wait(0.08)
            TweenService:Create(dropdownButton, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 1, 0)
            }):Play()
        end)
    end

    local v = Instance.new("TextLabel", f)
    v.Name = "Version"
    v.LayoutOrder = 8
    v.Text = "V" .. VERSION
    v.Font = Enum.Font.Gotham
    v.TextSize = 9
    v.TextScaled = true
    v.BackgroundTransparency = 1
    v.Size = UDim2.new(1, 0, 0, 16)
    v.TextXAlignment = Enum.TextXAlignment.Center
    UI.SettingsVersionLabel = v
end

function populatePromptUI(widget, title, text, onYes, onNo)
    for _, c in ipairs(widget:GetChildren()) do
        c:Destroy()
    end
    local f = Instance.new("Frame")
    f.Name = "PromptFrame"
    f.Size = UDim2.fromScale(1, 1)
    f.Parent = widget
    UI.PromptFrame = f

    local p = Instance.new("UIPadding", f)
    p.PaddingLeft = UDim.new(0, 20)
    p.PaddingRight = UDim.new(0, 20)
    p.PaddingTop = UDim.new(0, 20)
    p.PaddingBottom = UDim.new(0, 20)

    local l = Instance.new("UIListLayout", f)
    l.Padding = UDim.new(0, 16)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    l.VerticalAlignment = Enum.VerticalAlignment.Center

    local t = Instance.new("TextLabel", f)
    t.Name = "Title"
    t.LayoutOrder = 1
    t.Text = title
    t.Size = UDim2.new(1, 0, 0, 28)
    t.Font = Enum.Font.GothamBold
    t.TextSize = 16
    t.TextScaled = true
    t.BackgroundTransparency = 1
    t.TextXAlignment = Enum.TextXAlignment.Center
    UI.PromptTitle = t

    local i = Instance.new("TextLabel", f)
    i.Name = "Label"
    i.LayoutOrder = 2
    i.Text = text
    i.Size = UDim2.new(1, 0, 0, 50)
    i.Font = Enum.Font.Gotham
    i.TextSize = 11
    i.TextScaled = true
    i.TextWrapped = true
    i.BackgroundTransparency = 1
    i.TextXAlignment = Enum.TextXAlignment.Center
    UI.PromptText = i

    local bf = Instance.new("Frame", f)
    bf.Name = "ButtonFrame"
    bf.LayoutOrder = 3
    bf.Size = UDim2.new(1, 0, 0, 36)
    bf.BackgroundTransparency = 1

    local bl = Instance.new("UIGridLayout", bf)
    bl.CellSize = UDim2.new(0.4, 0, 1, 0)
    bl.HorizontalAlignment = Enum.HorizontalAlignment.Center
    bl.VerticalAlignment = Enum.VerticalAlignment.Center
    bl.CellPadding = UDim2.new(0.05, 0, 0, 0)

    local yb = Instance.new("TextButton", bf)
    yb:SetAttribute("StyleType", "Primary")
    yb.Text = "Yes"
    yb.Font = Enum.Font.Gotham
    yb.TextSize = 11
    yb.TextScaled = true
    UI.PromptYes = yb
    yb.MouseButton1Click:Connect(function()
        onYes()
        widget.Enabled = false
    end)

    local nb = Instance.new("TextButton", bf)
    nb:SetAttribute("StyleType", "Danger")
    nb.Text = "No"
    nb.Font = Enum.Font.Gotham
    nb.TextSize = 11
    nb.TextScaled = true
    UI.PromptNo = nb
    nb.MouseButton1Click:Connect(function()
        onNo()
        widget.Enabled = false
    end)

    applyTheme(Config.THEME)
    widget.Enabled = true
end

function findImageAsset(assetId)
    if not assetId then
        return nil
    end
    local assetFolder = ReplicatedStorage:FindFirstChild(Config.ASSET_FOLDER_NAME)
    if not assetFolder then
        return nil
    end
    local image = assetFolder:FindFirstChild(assetId, true)
    if image then
        if image:IsA("ImageLabel") then
            return image.Image
        elseif image:IsA("ImageButton") then
            return image.Image
        elseif image:IsA("Decal") then
            return image.Texture
        end
    end
    return nil
end

function createBehaviorScript(element, tags)
    local s = [[local b=script.Parent;local c=b:GetAttribute;local n=c(b,"NormalImage");local h=c(b,"HoverImage");local p=c(b,"ClickedImage");local d=c(b,"DisabledImage");local t=c(b,"IsToggled")or false;local e=c(b,"IsEnabled")or true;local function u()if not e then b.Image=d or n;return end;if t and p then b.Image=p elseif c(b,"IsHovering")and h then b.Image=h else b.Image=n end end;b.MouseEnter:Connect(function()b:SetAttribute("IsHovering",true)u()end)b.MouseLeave:Connect(function()b:SetAttribute("IsHovering",false)u()end)b.MouseButton1Click:Connect(function()if not e then return end;if c(b,"IsToggleable")then t=not t;b:SetAttribute("IsToggled",t)end;u()end)b:GetAttributeChangedSignal("IsEnabled"):Connect(function()e=c(b,"IsEnabled")u()end)u()]]
    local S = Instance.new("LocalScript")
    S.Name = "ButtonBehavior"
    S.Source = s
    element:SetAttribute("NormalImage", element.Image)
    element:SetAttribute("HoverImage", findImageAsset(element.Name .. "_hover"))
    element:SetAttribute("ClickedImage", findImageAsset(element.Name .. "_clicked"))
    element:SetAttribute("DisabledImage", findImageAsset(element.Name .. "_disabled"))
    element:SetAttribute("IsToggleable", table.find(tags, "toggled"))
    element:SetAttribute("IsEnabled", not table.find(tags, "disabled"))
    S.Parent = element
end

function applyFills(element, fills)
    if not fills or #fills == 0 then
        element.BackgroundTransparency = 1
        return
    end
    local fill = fills[1]
    local opacity = fill.opacity or 1
    if fill.type == "SOLID" then
        element.BackgroundColor3 = Color3.new(fill.color.r, fill.color.g, fill.color.b)
        element.BackgroundTransparency = 1 - opacity
    elseif string.find(fill.type, "GRADIENT") then
        local gradient = Instance.new("UIGradient")
        local colorStops = {}
        for _, stop in ipairs(fill.gradientStops) do
            table.insert(colorStops, ColorSequenceKeypoint.new(stop.position, Color3.new(stop.color.r, stop.color.g, stop.color.b)))
        end
        gradient.Color = ColorSequence.new(colorStops)
        gradient.Parent = element
    end
end

function applyStrokes(element, strokes, weight, scale)
    if not strokes or #strokes == 0 then
        return
    end
    local stroke = strokes[1]
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Thickness = (weight or 1) * (scale or 1)
    if stroke.type == "SOLID" then
        uiStroke.Color = Color3.new(stroke.color.r, stroke.color.g, stroke.color.b)
    end
    uiStroke.Parent = element
end

function applyConstraints(element, constraints)
    if not constraints then
        return
    end
    local x, y = 0, 0
    if constraints.horizontal == "CENTER" then
        x = 0.5
    elseif constraints.horizontal == "RIGHT" then
        x = 1
    elseif constraints.horizontal == "SCALE" then
        x = 0.5
    end
    if constraints.vertical == "CENTER" then
        y = 0.5
    elseif constraints.vertical == "BOTTOM" then
        y = 1
    elseif constraints.vertical == "SCALE" then
        y = 0.5
    end
    element.AnchorPoint = Vector2.new(x, y)
    if not Config.AUTO_SCALE then
        element.Position = UDim2.new(x, element.Position.X.Offset, y, element.Position.Y.Offset)
    end
end

local propertyAppliers = {}
propertyAppliers.Default = function(element, data, parentSize)
    local props = data.properties
    element.Name = data.name
    element.Visible = props.visible ~= false
    element.Rotation = props.rotation or 0
    element.ClipsDescendants = data.type == 'FRAME'
    applyFills(element, props.fills)

    if not props.size or not props.position then
        return
    end

    local anchorPoint = Vector2.new(0, 0)
    if props.constraints then
        if props.constraints.horizontal == "CENTER" then
            anchorPoint = Vector2.new(0.5, anchorPoint.Y)
        elseif props.constraints.horizontal == "RIGHT" then
            anchorPoint = Vector2.new(1, anchorPoint.Y)
        end
        if props.constraints.vertical == "CENTER" then
            anchorPoint = Vector2.new(anchorPoint.X, 0.5)
        elseif props.constraints.vertical == "BOTTOM" then
            anchorPoint = Vector2.new(anchorPoint.X, 1)
        end
    end
    element.AnchorPoint = anchorPoint

    if Config.AUTO_SCALE then
        local parentW = parentSize.X
        local parentH = parentSize.Y
        if parentW <= 0 or parentH <= 0 then parentW, parentH = 1920, 1080 end

        local sizeXScale = props.size.x / parentW
        local sizeYScale = props.size.y / parentH
        element.Size = UDim2.fromScale(sizeXScale, sizeYScale)

        local posXScale = (props.position.x + (props.size.x * anchorPoint.X)) / parentW
        local posYScale = (props.position.y + (props.size.y * anchorPoint.Y)) / parentH
        element.Position = UDim2.fromScale(posXScale, posYScale)
        
        if props.cornerRadius and props.cornerRadius > 0 then
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, props.cornerRadius)
            c.Parent = element
        end
        applyStrokes(element, props.strokes, props.strokeWeight)
    else
        element.Position = UDim2.fromOffset(props.position.x, props.position.y)
        element.Size = UDim2.fromOffset(props.size.x, props.size.y)
        
        if props.cornerRadius and props.cornerRadius > 0 then
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, props.cornerRadius)
            c.Parent = element
        end
        applyStrokes(element, props.strokes, props.strokeWeight)
    end
end

propertyAppliers.TEXT = function(element, data, parentSize)
    propertyAppliers.Default(element, data, parentSize)
    local props = data.properties
    element.Text = props.characters or ""
    element.Font = (props.fontName and fontMap[props.fontName.family]) or Enum.Font.SourceSans
    
    element.TextScaled = true
    element.TextWrapped = true
    element.TextSize = props.fontSize or 14
    
    if props.fills and #props.fills > 0 then
        local fill = props.fills[1]
        element.TextColor3 = Color3.new(fill.color.r, fill.color.g, fill.color.b)
        element.TextTransparency = 1 - (fill.opacity or 1)
    end
    
    local textAlignH = props.textAlignHorizontal
    if textAlignH == "LEFT" then
        element.TextXAlignment = Enum.TextXAlignment.Left
    elseif textAlignH == "CENTER" then
        element.TextXAlignment = Enum.TextXAlignment.Center
    elseif textAlignH == "RIGHT" then
        element.TextXAlignment = Enum.TextXAlignment.Right
    else
        element.TextXAlignment = Enum.TextXAlignment.Left
    end
    
    local textAlignV = props.textAlignVertical
    if textAlignV == "TOP" then
        element.TextYAlignment = Enum.TextYAlignment.Top
    elseif textAlignV == "CENTER" then
        element.TextYAlignment = Enum.TextYAlignment.Center
    elseif textAlignV == "BOTTOM" then
        element.TextYAlignment = Enum.TextYAlignment.Bottom
    else
        element.TextYAlignment = Enum.TextYAlignment.Top
    end
end

propertyAppliers.Image = function(element, data)
    if data.assetId then
        local imageId = findImageAsset(data.assetId)
        if imageId and imageId ~= "" then
            element.Image = imageId
        end
        element.BackgroundTransparency = 1
        element.ScaleType = Enum.ScaleType.Fit
    end
end

local elementCreators = {}
elementCreators.Default = function(data)
    local tags = data.tags or {}
    if data.assetId and data.assetId ~= "" then
        if table.find(tags, "button") then
            local btn = Instance.new("ImageButton")
            btn.ScaleType = Enum.ScaleType.Fit
            return btn
        else
            local img = Instance.new("ImageLabel")
            img.ScaleType = Enum.ScaleType.Fit
            return img
        end
    end
    local element
    if table.find(tags, "button") then
        element = Instance.new("ImageButton")
        element.ScaleType = Enum.ScaleType.Fit
    elseif table.find(tags, "image") then
        element = Instance.new("ImageLabel")
        element.ScaleType = Enum.ScaleType.Fit
    elseif table.find(tags, "vpf") then
        element = Instance.new("ViewportFrame")
    elseif table.find(tags, "canvas") then
        element = Instance.new("CanvasGroup")
    elseif table.find(tags, "scroll") or string.upper(data.name):find("SCROLL") then
        element = Instance.new("ScrollingFrame")
        element.ScrollingDirection = table.find(tags, "scrollx") and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y
        element.ScrollBarThickness = 8
        element.CanvasSize = UDim2.fromScale(0, 0)
        local layout = Instance.new("UIListLayout")
        layout.Parent = element
    else
        element = Instance.new("Frame")
    end
    if table.find(tags, "box") then
        local layout = Instance.new("UIListLayout")
        layout.Parent = element
    end
    return element
end

elementCreators.TEXT = function(data)
    local label = Instance.new("TextLabel")
    label.TextScaled = true
    return label
end

function createFromData(data, parent, parentSize)
    local element = (elementCreators[data.type] or elementCreators.Default)(data)
    ;(propertyAppliers[data.type] or propertyAppliers.Default)(element, data, parentSize)
    if element:IsA("ImageLabel") or element:IsA("ImageButton") then
        propertyAppliers.Image(element, data)
    end
    if Config.CREATE_BEHAVIOR_SCRIPTS and data.tags and table.find(data.tags, "button") then
        createBehaviorScript(element, data.tags)
    end
    element.Parent = parent
    if data.children and #data.children > 0 then
        local childParentSize = Vector2.new(data.properties.size.x, data.properties.size.y)
        for _, childData in ipairs(data.children) do
            createFromData(childData, element, childParentSize)
        end
    end
    return element
end

function collectAssetIds(dataTable)
    local ids = {}
    local function traverse(data)
        for _, nodeData in ipairs(data) do
            if nodeData.assetId and nodeData.assetId ~= "" and not ids[nodeData.assetId] then
                ids[nodeData.assetId] = true
            end
            if nodeData.children and #nodeData.children > 0 then
                traverse(nodeData.children)
            end
        end
    end
    traverse(dataTable)
    local idList = {}
    for id, _ in pairs(ids) do
        table.insert(idList, id)
    end
    return idList
end

function verifyAssets(assetIds)
    local missing = {}
    local assetFolder = ReplicatedStorage:FindFirstChild(Config.ASSET_FOLDER_NAME)
    if not assetFolder then
        return assetIds, "Asset folder '" .. Config.ASSET_FOLDER_NAME .. "' not found in ReplicatedStorage."
    end
    for _, id in ipairs(assetIds) do
        if not findImageAsset(id) then
            table.insert(missing, id)
        end
    end
    if #missing > 0 then
        return missing, "Missing assets: " .. table.concat(missing, ", ")
    else
        return {}, nil
    end
end

function performImport(data, statusLabel)
    statusLabel.Text = "Importing..."
    local targetGui = StarterGui:FindFirstChild(Config.TARGET_SCREEN_GUI)
    if targetGui then
        targetGui:Destroy()
    end
    targetGui = Instance.new("ScreenGui")
    targetGui.Name = Config.TARGET_SCREEN_GUI

    local nodes = data.nodes or {}
    
    local referenceSize = data.referenceSize
    if not referenceSize or not referenceSize.x or not referenceSize.y or referenceSize.x <= 0 or referenceSize.y <= 0 then
        referenceSize = { x = 1920, y = 1080 }
    end
    
    local rootRefSize = Vector2.new(referenceSize.x, referenceSize.y)

    local mainContainer = Instance.new("Frame")
    mainContainer.Name = "ImportContainer"
    mainContainer.BackgroundTransparency = 1

    -- Size the container to fill the screen, but maintain aspect ratio
    mainContainer.Size = UDim2.fromScale(1, 1)

    local importParent = mainContainer

    mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    mainContainer.Position = UDim2.fromScale(0.5, 0.5)

    mainContainer.Parent = targetGui

    local aspectRatio = rootRefSize.X / rootRefSize.Y
    local constraint = Instance.new("UIAspectRatioConstraint")
    constraint.AspectRatio = aspectRatio
    constraint.DominantAxis = Enum.DominantAxis.Height
    constraint.Parent = mainContainer

    for _, nodeData in ipairs(nodes) do
        createFromData(nodeData, importParent, rootRefSize)
    end

    targetGui.Parent = StarterGui
    Selection:Set({ targetGui })
    statusLabel.Text = "Import successful!"

    if Config.SHOW_ANCHOR_POPUP then
        if not finalizationWidget then
            local finalizationWidgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 220, 280, 220, 280)
            finalizationWidget = plugin:CreateDockWidgetPluginGui("FramifyFinalization", finalizationWidgetInfo)
            finalizationWidget.Title = "Import Finalization"
        end
        populateFinalizationUI(finalizationWidget, mainContainer)
        finalizationWidget.Enabled = true
    end
end

function createSlider(parent, theme, options)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local listLayout = Instance.new("UIListLayout", container)
    listLayout.Padding = UDim.new(0, 4)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local topRow = Instance.new("Frame")
    topRow.Size = UDim2.new(1, 0, 0, 16)
    topRow.BackgroundTransparency = 1
    topRow.Parent = container
    topRow.LayoutOrder = 1

    local topRowLayout = Instance.new("UIListLayout", topRow)
    topRowLayout.FillDirection = Enum.FillDirection.Horizontal
    topRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local label = Instance.new("TextLabel", topRow)
    label.Name = "Label"
    label.Text = options.text
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextColor3 = theme.Text
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(0.7, -4, 1, 0)

    local valueBox = Instance.new("TextBox", topRow)
    valueBox.Name = "ValueBox"
    valueBox.Text = string.format("%.2f", options.default)
    valueBox.Font = Enum.Font.Code
    valueBox.TextSize = 11
    valueBox.TextColor3 = theme.Primary
    valueBox.BackgroundColor3 = theme.Surface
    valueBox.TextXAlignment = Enum.TextXAlignment.Right
    valueBox.Size = UDim2.new(0.3, 0, 1, 0)
    valueBox.ClearTextOnFocus = false
    local boxCorner = Instance.new("UICorner", valueBox)
    boxCorner.CornerRadius = UDim.new(0, 4)

    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, 0, 0, 20)
    sliderFrame.BackgroundColor3 = theme.Surface
    sliderFrame.Parent = container
    sliderFrame.LayoutOrder = 2

    local corner = Instance.new("UICorner", sliderFrame)
    corner.CornerRadius = UDim.new(0, 4)

    local bar = Instance.new("Frame", sliderFrame)
    bar.BackgroundColor3 = theme.Primary
    bar.BorderSizePixel = 0
    bar.Size = UDim2.new((options.default - options.min) / (options.max - options.min), 0, 1, 0)

    local barCorner = Instance.new("UICorner", bar)
    barCorner.CornerRadius = UDim.new(0, 4)

    local thumb = Instance.new("Frame", sliderFrame)
    thumb.Size = UDim2.new(0, 12, 0, 12)
    thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    thumb.Position = UDim2.new(bar.Size.X.Scale, 0, 0.5, 0)
    thumb.BackgroundColor3 = theme.Text
    thumb.BorderSizePixel = 2
    thumb.BorderColor3 = theme.Primary

    local thumbCorner = Instance.new("UICorner", thumb)
    thumbCorner.CornerRadius = UDim.new(1, 0)

    local dragging = false
    local currentValue = options.default

    local function updateVisuals(value)
        local scale = (value - options.min) / (options.max - options.min)
        bar.Size = UDim2.new(scale, 0, 1, 0)
        thumb.Position = UDim2.new(scale, 0, 0.5, 0)
        valueBox.Text = string.format("%.2f", value)
        currentValue = value
    end

    local function updateFromInput(inputPos)
        if not dragging then return end
        local scale = math.clamp((inputPos.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
        local value = options.min + scale * (options.max - options.min)
        updateVisuals(value)
        if options.onChanged then
            options.onChanged(value)
        end
    end

    sliderFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromInput(input.Position)
        end
    end)

    sliderFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    sliderFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            updateFromInput(input.Position)
        end
    end)

    valueBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local num = tonumber(valueBox.Text)
            if num then
                local clampedValue = math.clamp(num, options.min, options.max)
                updateVisuals(clampedValue)
                if options.onChanged then
                    options.onChanged(clampedValue)
                end
            else
                valueBox.Text = string.format("%.2f", currentValue)
            end
        else
            valueBox.Text = string.format("%.2f", currentValue)
        end
    end)

    return container
end

function createColorEditorUI(parent, theme, options)
    local container = Instance.new("Frame")
    container.Name = "ColorEditorContainer"
    container.Size = UDim2.new(1, 0, 0, 250)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local listLayout = Instance.new("UIListLayout", container)
    listLayout.Padding = UDim.new(0, 8)

    local title = Instance.new("TextLabel", container)
    title.Name = "Title"
    title.Text = "Theme Colors"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Size = UDim2.new(1, 0, 0, 20)
    title.TextColor3 = theme.Text
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left

    local propertySelectorFrame = Instance.new("Frame", container)
    propertySelectorFrame.Size = UDim2.new(1, 0, 0, 24)
    propertySelectorFrame.BackgroundTransparency = 1

    local propertyLayout = Instance.new("UIListLayout", propertySelectorFrame)
    propertyLayout.FillDirection = Enum.FillDirection.Horizontal
    propertyLayout.Padding = UDim.new(0, 5)

    local pickerFrame = Instance.new("Frame", container)
    pickerFrame.Size = UDim2.new(1, 0, 0, 100)
    pickerFrame.BackgroundTransparency = 1

    local pickerLayout = Instance.new("UIListLayout", pickerFrame)
    pickerLayout.FillDirection = Enum.FillDirection.Horizontal
    pickerLayout.Padding = UDim.new(0, 10)
    pickerLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local svBox = Instance.new("ImageLabel", pickerFrame)
    svBox.Size = UDim2.new(0, 100, 0, 100)

    local saturation = Instance.new("UIGradient", svBox)
    saturation.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, Color3.new(1,1,1,0))})
    saturation.Rotation = 90

    local value = Instance.new("UIGradient", svBox)
    value.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(0,0,0,0)), ColorSequenceKeypoint.new(1, Color3.new(0,0,0))})

    local svThumb = Instance.new("Frame", svBox)
    svThumb.Size = UDim2.new(0, 10, 0, 10)
    svThumb.AnchorPoint = Vector2.new(0.5, 0.5)
    svThumb.BackgroundColor3 = Color3.new(1,1,1)
    svThumb.BorderSizePixel = 2
    svThumb.BorderColor3 = Color3.new(0,0,0)
    local thumbCorner = Instance.new("UICorner", svThumb)
    thumbCorner.CornerRadius = UDim.new(1, 0)

    local hueSlider = Instance.new("ImageLabel", pickerFrame)
    hueSlider.Size = UDim2.new(0, 20, 0, 100)

    local hueGradient = Instance.new("UIGradient", hueSlider)
    hueGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)), ColorSequenceKeypoint.new(1/6, Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(2/6, Color3.fromRGB(0,255,0)), ColorSequenceKeypoint.new(3/6, Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(4/6, Color3.fromRGB(0,0,255)), ColorSequenceKeypoint.new(5/6, Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0))
    })

    local hueThumb = Instance.new("Frame", hueSlider)
    hueThumb.Size = UDim2.new(1, 4, 0, 4)
    hueThumb.Position = UDim2.fromScale(0.5, 0)
    hueThumb.AnchorPoint = Vector2.new(0.5, 0.5)
    hueThumb.BackgroundColor3 = Color3.new(1,1,1)
    hueThumb.BorderSizePixel = 1
    hueThumb.BorderColor3 = Color3.new(0,0,0)

    local swatchFrame = Instance.new("Frame", container)
    swatchFrame.Size = UDim2.new(1, 0, 0, 24)
    swatchFrame.BackgroundTransparency = 1

    local swatchLayout = Instance.new("UIGridLayout", swatchFrame)
    swatchLayout.CellSize = UDim2.fromOffset(22, 22)
    swatchLayout.CellPadding = UDim2.new(0, 4, 0, 4)
    swatchLayout.FillDirectionMaxCells = 8

    local genericColors = {
        Color3.fromRGB(255,77,77), Color3.fromRGB(255,166,77), Color3.fromRGB(255,255,77), Color3.fromRGB(77,255,77),
        Color3.fromRGB(77,77,255), Color3.fromRGB(166,77,255), Color3.fromRGB(255,77,166), Color3.fromRGB(255,255,255)
    }

    local state = {
        h = 0, s = 1, v = 1,
        keypoints = {
            ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
            ColorSequenceKeypoint.new(1, Color3.new(1,1,1))
        },
        selectedKeypointIndex = 1
    }
    state.editingProperty = "Primary"
    state.h, state.s, state.v = Color3.toHSV(theme[state.editingProperty])

    local renderGradient

    local function updateColor()
        local finalColor = Color3.fromHSV(state.h, state.s, state.v)
        svBox.BackgroundColor3 = Color3.fromHSV(state.h, 1, 1)
        svThumb.Position = UDim2.fromScale(state.s, 1 - state.v)
        hueThumb.Position = UDim2.new(0.5, 0, state.h, 0)

        local currentKp = state.keypoints[state.selectedKeypointIndex]
        if currentKp then
            state.keypoints[state.selectedKeypointIndex] = ColorSequenceKeypoint.new(currentKp.Time, finalColor)
            if renderGradient then renderGradient() end
        end

        if options.onChanged then
            options.onChanged(state.editingProperty, finalColor)
        end
    end

    local propertyButtons = {}
    for propName, _ in pairs(theme) do
        local btn = Instance.new("TextButton", propertySelectorFrame)
        btn.Name = propName
        btn.Text = propName
        btn.Size = UDim2.new(0, 50, 1, 0)
        styleButton(btn, "Secondary", theme)
        table.insert(propertyButtons, btn)

        btn.MouseButton1Click:Connect(function()
            state.editingProperty = propName
            state.h, state.s, state.v = Color.toHSV(theme[propName])
            updateColor()
            for _, b in ipairs(propertyButtons) do
                b.BorderSizePixel = (b.Name == propName) and 2 or 1
            end
        end)
    end

    local gradientEditor, rg = createGradientEditor(container, theme, state, updateColor)
    renderGradient = rg

    local hueDragging = false
    local svDragging = false

    local function updateHue(inputPos)
        if not hueDragging then return end
        h = math.clamp(inputPos.Y / hueSlider.AbsoluteSize.Y, 0, 1)
        updateColor()
    end

    local function updateSV(inputPos)
        if not svDragging then return end
        local boxSize = svBox.AbsoluteSize
        local boxPos = svBox.AbsolutePosition
        s = math.clamp((inputPos.X - boxPos.X) / boxSize.X, 0, 1)
        v = 1 - math.clamp((inputPos.Y - boxPos.Y) / boxSize.Y, 0, 1)
        updateColor()
    end

    hueSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            hueDragging = true
            updateHue(input.Position)
        end
    end)
    hueSlider.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            updateHue(input.Position)
        end
    end)
    hueSlider.InputEnded:Connect(function() hueDragging = false end)

    svBox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            svDragging = true
            updateSV(input.Position)
        end
    end)
    svBox.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            updateSV(input.Position)
        end
    end)
    svBox.InputEnded:Connect(function() svDragging = false end)

    for _, swatch in ipairs(swatchFrame:GetChildren()) do
        if swatch:IsA("TextButton") then
            swatch.MouseButton1Click:Connect(function()
                state.h, state.s, state.v = Color3.toHSV(swatch.BackgroundColor3)
                updateColor()
            end)
        end
    end

    updateColor()

    createGradientEditor(container, theme, state, onStateChanged)

    local favoritesContainer = Instance.new("Frame")
    favoritesContainer.Name = "FavoritesContainer"
    favoritesContainer.Size = UDim2.new(1, 0, 0, 80)
    favoritesContainer.BackgroundTransparency = 1
    favoritesContainer.Parent = container

    local favListLayout = Instance.new("UIListLayout", favoritesContainer)
    favListLayout.Padding = UDim.new(0, 4)

    local favTitleFrame = Instance.new("Frame", favoritesContainer)
    favTitleFrame.Size = UDim2.new(1, 0, 0, 20)
    favTitleFrame.BackgroundTransparency = 1

    local favTitleLayout = Instance.new("UIListLayout", favTitleFrame)
    favTitleLayout.FillDirection = Enum.FillDirection.Horizontal
    favTitleLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local favTitle = Instance.new("TextLabel", favTitleFrame)
    favTitle.Text = "Favorites"
    favTitle.Font = Enum.Font.GothamBold
    favTitle.TextSize = 12
    favTitle.TextColor3 = theme.Text
    favTitle.BackgroundTransparency = 1
    favTitle.TextXAlignment = Enum.TextXAlignment.Left
    favTitle.Size = UDim2.new(1, -52, 1, 0)

    local saveColorBtn = Instance.new("TextButton", favTitleFrame)
    saveColorBtn.Text = "C+"
    saveColorBtn.ToolTip = "Save Current Color"
    saveColorBtn.Size = UDim2.new(0, 22, 1, 0)
    styleButton(saveColorBtn, "Secondary", theme)

    local saveGradientBtn = Instance.new("TextButton", favTitleFrame)
    saveGradientBtn.Text = "G+"
    saveGradientBtn.ToolTip = "Save Current Gradient"
    saveGradientBtn.Size = UDim2.new(0, 22, 1, 0)
    styleButton(saveGradientBtn, "Secondary", theme)

    local favoritesFrame = Instance.new("ScrollingFrame", favoritesContainer)
    favoritesFrame.Size = UDim2.new(1, 0, 1, -24)
    favoritesFrame.BackgroundColor3 = theme.Surface
    favoritesFrame.BorderSizePixel = 0
    local favCorner = Instance.new("UICorner", favoritesFrame)
    favCorner.CornerRadius = UDim.new(0, 4)

    local favFrameLayout = Instance.new("UIGridLayout", favoritesFrame)
    favFrameLayout.CellSize = UDim2.fromOffset(22, 22)
    favFrameLayout.CellPadding = UDim2.new(0, 4, 0, 4)

    local function renderFavorites()
        for _, child in ipairs(favoritesFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        local favs = plugin:GetSetting("favorites")
        if not favs then favs = {} end

        for _, fav in ipairs(favs) do
            local swatch = Instance.new("TextButton")
            swatch.Text = ""
            swatch.Size = UDim2.fromOffset(22, 22)
            swatch.Parent = favoritesFrame

            if fav.isGradient then
                local g = Instance.new("UIGradient", swatch)
                g.Color = ColorSequence.new(fav.value)
            else
                swatch.BackgroundColor3 = Color3.new(fav.value.r, fav.value.g, fav.value.b)
            end

            swatch.MouseButton1Click:Connect(function()
                if fav.isGradient then
                    -- To-do: apply gradient
                else
                    state.h, state.s, state.v = Color.toHSV(swatch.BackgroundColor3)
                    onStateChanged()
                end
            end)
        end
    end

    local function renderFavorites()
        for _, child in ipairs(favoritesFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        local favsJSON = plugin:GetSetting("favorites") or "[]"
        local favs = HttpService:JSONDecode(favsJSON)

        for _, favData in ipairs(favs) do
            local swatch = Instance.new("TextButton")
            swatch.Text = ""
            swatch.Size = UDim2.fromOffset(22, 22)
            swatch.Parent = favoritesFrame

            if favData.isGradient then
                local g = Instance.new("UIGradient", swatch)
                local kps = {}
                for _, kpData in ipairs(favData.value) do
                    table.insert(kps, ColorSequenceKeypoint.new(kpData.time, Color3.new(kpData.r, kpData.g, kpData.b)))
                end
                g.Color = ColorSequence.new(kps)
            else
                swatch.BackgroundColor3 = Color3.new(favData.value.r, favData.value.g, favData.value.b)
            end

            swatch.MouseButton1Click:Connect(function()
                if favData.isGradient then
                    local kps = {}
                    for _, kpData in ipairs(favData.value) do
                        table.insert(kps, ColorSequenceKeypoint.new(kpData.time, Color3.new(kpData.r, kpData.g, kpData.b)))
                    end
                    state.keypoints = kps
                    state.selectedKeypointIndex = 1
                    local firstColor = state.keypoints[1].Value
                    state.h, state.s, state.v = Color3.toHSV(firstColor)
                    onStateChanged()
                else
                    state.h, state.s, state.v = Color3.toHSV(swatch.BackgroundColor3)
                    onStateChanged()
                end
            end)
        end
    end

    saveColorBtn.MouseButton1Click:Connect(function()
        local favsJSON = plugin:GetSetting("favorites") or "[]"
        local favs = HttpService:JSONDecode(favsJSON)
        local currentColor = Color3.fromHSV(state.h, state.s, state.v)
        local newFav = { isGradient = false, value = { r = currentColor.R, g = currentColor.G, b = currentColor.B } }
        table.insert(favs, newFav)
        plugin:SetSetting("favorites", HttpService:JSONEncode(favs))
        renderFavorites()
    end)

    saveGradientBtn.MouseButton1Click:Connect(function()
        local favsJSON = plugin:GetSetting("favorites") or "[]"
        local favs = HttpService:JSONDecode(favsJSON)
        local serializableKeypoints = {}
        for _, kp in ipairs(state.keypoints) do
            table.insert(serializableKeypoints, { time = kp.Time, r = kp.Value.R, g = kp.Value.G, b = kp.Value.B })
        end
        local newFav = { isGradient = true, value = serializableKeypoints }
        table.insert(favs, newFav)
        plugin:SetSetting("favorites", HttpService:JSONEncode(favs))
        renderFavorites()
    end)

    renderFavorites()

    return container
end

function createGradientEditor(parent, theme, state, onStateChanged)
    local container = Instance.new("Frame")
    container.Name = "GradientEditorContainer"
    container.Size = UDim2.new(1, 0, 0, 60)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local listLayout = Instance.new("UIListLayout", container)
    listLayout.Padding = UDim.new(0, 4)

    local title = Instance.new("TextLabel", container)
    title.Name = "Title"
    title.Text = "Gradient"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.Size = UDim2.new(1, 0, 0, 16)
    title.TextColor3 = theme.Text
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left

    local editorFrame = Instance.new("Frame", container)
    editorFrame.Size = UDim2.new(1, 0, 0, 30)
    editorFrame.BackgroundTransparency = 1

    local editorLayout = Instance.new("UIListLayout", editorFrame)
    editorLayout.FillDirection = Enum.FillDirection.Horizontal
    editorLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    editorLayout.Padding = UDim.new(0, 8)

    local preview = Instance.new("ImageLabel", editorFrame)
    preview.Size = UDim2.new(1, -76, 1, 0)
    preview.BackgroundColor3 = theme.Surface
    local previewCorner = Instance.new("UICorner", preview)
    previewCorner.CornerRadius = UDim.new(0, 4)
    local previewGradient = Instance.new("UIGradient", preview)

    local addBtn = Instance.new("TextButton", editorFrame)
    addBtn.Text = "+"
    addBtn.Size = UDim2.new(0, 30, 1, 0)
    styleButton(addBtn, "Secondary", theme)

    local removeBtn = Instance.new("TextButton", editorFrame)
    removeBtn.Text = "-"
    removeBtn.Size = UDim2.new(0, 30, 1, 0)
    styleButton(removeBtn, "Secondary", theme)

    local function renderGradient()
        previewGradient.Color = ColorSequence.new(state.keypoints)
        for _, child in ipairs(preview:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        for i, kp in ipairs(state.keypoints) do
            local marker = Instance.new("TextButton")
            marker.Text = ""
            marker.Size = UDim2.new(0, 10, 0, 10)
            marker.AnchorPoint = Vector2.new(0.5, 0)
            marker.Position = UDim2.new(kp.Time, 0, 1, 2)
            marker.BackgroundColor3 = kp.Value
            marker.BorderSizePixel = (i == state.selectedKeypointIndex) and 2 or 1
            marker.BorderColor3 = theme.Text
            marker.Parent = preview

            marker.MouseButton1Click:Connect(function()
                state.selectedKeypointIndex = i
                local color = state.keypoints[i].Value
                state.h, state.s, state.v = Color3.toHSV(color)
                onStateChanged()
            end)

            local markerDragging = false
            marker.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    markerDragging = true
                end
            end)
            marker.InputChanged:Connect(function(input)
                if markerDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local newTime = math.clamp((input.Position.X - preview.AbsolutePosition.X) / preview.AbsoluteSize.X, 0, 1)
                    state.keypoints[i] = ColorSequenceKeypoint.new(newTime, kp.Value)
                    table.sort(state.keypoints, function(a,b) return a.Time < b.Time end)
                    onStateChanged()
                end
            end)
            marker.InputEnded:Connect(function() markerDragging = false end)
        end
    end

    addBtn.MouseButton1Click:Connect(function()
        local newColor = Color3.fromHSV(state.h, state.s, state.v)
        table.insert(state.keypoints, ColorSequenceKeypoint.new(0.5, newColor))
        table.sort(state.keypoints, function(a,b) return a.Time < b.Time end)
        onStateChanged()
    end)

    removeBtn.MouseButton1Click:Connect(function()
        if #state.keypoints > 2 then
            table.remove(state.keypoints, state.selectedKeypointIndex)
            state.selectedKeypointIndex = math.max(1, state.selectedKeypointIndex - 1)
            onStateChanged()
        end
    end)

    return container, renderGradient
end

function populateFinalizationUI(widget, targetElement)
    for _, child in ipairs(widget:GetChildren()) do
        child:Destroy()
    end

    widget.Title = "Import Finalization"

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.fromScale(1, 1)
    mainFrame.BackgroundColor3 = Themes[Config.THEME].BG
    mainFrame.Parent = widget

    local padding = Instance.new("UIPadding", mainFrame)
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.PaddingTop = UDim.new(0, 12)
    padding.PaddingBottom = UDim.new(0, 12)

    local listLayout = Instance.new("UIListLayout", mainFrame)
    listLayout.Padding = UDim.new(0, 10)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local anchorTitle = Instance.new("TextLabel", mainFrame)
    anchorTitle.Name = "Title"
    anchorTitle.Text = "Anchor Point"
    anchorTitle.Font = Enum.Font.GothamBold
    anchorTitle.TextSize = 14
    anchorTitle.Size = UDim2.new(1, 0, 0, 20)
    anchorTitle.TextColor3 = Themes[Config.THEME].Text
    anchorTitle.BackgroundTransparency = 1
    anchorTitle.LayoutOrder = 1

    local gridFrame = Instance.new("Frame", mainFrame)
    gridFrame.Size = UDim2.new(1, 0, 0, 120)
    gridFrame.BackgroundTransparency = 1
    gridFrame.LayoutOrder = 2

    local gridLayout = Instance.new("UIGridLayout", gridFrame)
    gridLayout.CellSize = UDim2.fromScale(0.3, 0.3)
    gridLayout.CellPadding = UDim2.fromScale(0.05, 0.05)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local anchors = {
        { name = "┌", value = Vector2.new(0, 0) }, { name = "┬", value = Vector2.new(0.5, 0) }, { name = "┐", value = Vector2.new(1, 0) },
        { name = "├", value = Vector2.new(0, 0.5) }, { name = "+", value = Vector2.new(0.5, 0.5) }, { name = "┤", value = Vector2.new(1, 0.5) },
        { name = "└", value = Vector2.new(0, 1) }, { name = "┴", value = Vector2.new(0.5, 1) }, { name = "┘", value = Vector2.new(1, 1) }
    }

    for _, anchorInfo in ipairs(anchors) do
        local btn = Instance.new("TextButton")
        btn.Name = anchorInfo.name
        btn.Text = anchorInfo.name
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 24
        btn.Parent = gridFrame

        styleButton(btn, "Secondary", Themes[Config.THEME])

        btn.MouseButton1Click:Connect(function()
            targetElement.AnchorPoint = anchorInfo.value
        end)
    end

    local scaleSlider = createSlider(mainFrame, Themes[Config.THEME], {
        text = "Scale",
        min = 0.1,
        max = 10,
        default = 1,
        onChanged = function(value)
            targetElement.Size = UDim2.fromScale(value, value)
        end
    })
    scaleSlider.LayoutOrder = 3

    local colorEditor = createColorEditorUI(mainFrame, Themes[Config.THEME], {
        onChanged = function(propName, newColor)
            local currentThemeName = Config.THEME
            Themes[currentThemeName][propName] = newColor
            applyTheme(currentThemeName)
        end
    })
    colorEditor.LayoutOrder = 4

    local doneBtn = Instance.new("TextButton", mainFrame)
    doneBtn.Name = "DoneButton"
    doneBtn.Text = "Done"
    doneBtn.Size = UDim2.new(1, 0, 0, 36)
    styleButton(doneBtn, "Primary", Themes[Config.THEME])
    doneBtn.LayoutOrder = 4

    doneBtn.MouseButton1Click:Connect(function()
        widget.Enabled = false
    end)
end

local function playLoadingAnimation()
    -- Initial State
    UI.MainFrame.Visible = false
    UI.LoadingContainer.Visible = true
    UI.LoadingTopHalf.Visible = true
    UI.LoadingBottomHalf.Visible = true
    UI.LoadingTopHalf.Position = UDim2.fromScale(0, 0)
    UI.LoadingBottomHalf.Position = UDim2.fromScale(0, 0.5)
    UI.LoadingLogo.ImageTransparency = 1
    UI.LoadingTitle.TextTransparency = 1
    UI.LoadingSubtitle.TextTransparency = 1
    UI.LoadingBar.Size = UDim2.fromScale(0, 1)

    -- Fade In Animation
    task.wait(0.15)
    local logoFadeIn = TweenService:Create(UI.LoadingLogo, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        ImageTransparency = 0
    })
    logoFadeIn:Play()
    task.wait(0.2)
    TweenService:Create(UI.LoadingTitle, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    }):Play()
    task.wait(0.15)
    TweenService:Create(UI.LoadingSubtitle, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    }):Play()

    -- Progress Bar Animation
    task.wait(0.2)
    local progressTween = TweenService:Create(UI.LoadingBar, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.fromScale(1, 1)
    })
    progressTween:Play()
    progressTween.Completed:Wait()
    task.wait(0.2)

    -- Split and Slide Out Animation
    local slideOutInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
    local slideTop = TweenService:Create(UI.LoadingTopHalf, slideOutInfo, { Position = UDim2.new(0, 0, -0.5, 0) })
    local slideBottom = TweenService:Create(UI.LoadingBottomHalf, slideOutInfo, { Position = UDim2.new(0, 0, 1, 0) })

    slideTop:Play()
    slideBottom:Play()

    -- Main UI Entrance Animation
    UI.MainFrame.Visible = true
    local slideInInfo = TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local slideUp = TweenService:Create(UI.MainFrame, slideInInfo, { Position = UDim2.fromScale(0.5, 0.5) })
    local fadeIn = TweenService:Create(UI.MainFrame, slideInInfo, { GroupTransparency = 0 })

    task.wait(0.15) -- Wait a bit for the split to start before sliding in
    slideUp:Play()
    fadeIn:Play()

    -- Cleanup
    slideBottom.Completed:Wait()
    fadeIn.Completed:Wait()
    UI.LoadingContainer.Visible = false
end

local toolbar = plugin:CreateToolbar("Framify")
local mainPluginButton = toolbar:CreateButton("Framify Importer", "Open Framify Importer", "rbxassetid://127991582997910")
local settingsPluginButton = toolbar:CreateButton("Framify Settings", "Open Framify Settings", "rbxassetid://93472476640298")

local mainWidget, settingsWidget, promptWidget, finalizationWidget
local isInitialized = false

local function initializeUI()
    if isInitialized then return end

    local mainWidgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 380, 520, 380, 520)
    mainWidget = plugin:CreateDockWidgetPluginGui("FramifyImporter", mainWidgetInfo)
    mainWidget.Title = "Framify Importer"

    createLoadingUI(mainWidget)
    local importBtn, mappingTextBox, statusLabel, _, _ = createMainUI(mainWidget)

    local settingsWidgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 320, 420, 320, 420)
    settingsWidget = plugin:CreateDockWidgetPluginGui("FramifySettings", settingsWidgetInfo)
    settingsWidget.Title = "Framify Settings"
    createSettingsUI(settingsWidget)

    local promptWidgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 340, 180, 340, 180)
    promptWidget = plugin:CreateDockWidgetPluginGui("FramifyPrompt", promptWidgetInfo)
    promptWidget.Title = "Framify Prompt"
    promptWidget.Enabled = false

    applyTheme(Config.THEME)

    importBtn.MouseButton1Click:Connect(function()
        statusLabel.Text = ""
        local mappingString = mappingTextBox.Text
        if mappingString == "" then
            statusLabel.Text = "Error: Mapping string cannot be empty."
            return
        end
        local success, data = pcall(function()
            return HttpService:JSONDecode(mappingString)
        end)
        if not success or not data.nodes or not data.referenceSize then
            statusLabel.Text = "Error: Invalid mapping string."
            return
        end
        local requiredAssets = collectAssetIds(data.nodes)
        if #requiredAssets > 0 then
            local missingAssets, err = verifyAssets(requiredAssets)
            if #missingAssets > 0 then
                statusLabel.Text = "Error: " .. err
                return
            end
            populatePromptUI(promptWidget, "Image Assets Found", "This UI requires images that appear to be uploaded. Proceed with import?",
                function()
                    performImport(data, statusLabel)
                end,
                function()
                    statusLabel.Text = "Import cancelled."
                end
            )
        else
            performImport(data, statusLabel)
        end
    end)

    mainWidget.Enabled = false
    settingsWidget.Enabled = false
    promptWidget.Enabled = false

    isInitialized = true
end

mainPluginButton.Click:Connect(function()
    initializeUI()
    mainWidget.Enabled = not mainWidget.Enabled
    if mainWidget.Enabled then
        coroutine.wrap(playLoadingAnimation)()
    end
end)

settingsPluginButton.Click:Connect(function()
    initializeUI()
    settingsWidget.Enabled = not settingsWidget.Enabled
end)
