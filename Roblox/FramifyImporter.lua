
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
    AUTO_CENTER_UI = true,
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
    local cg = Instance.new("CanvasGroup")
    cg.Name = "MainFrame"
    cg.Size = UDim2.fromScale(1, 1)
    cg.Visible = false
    cg.GroupTransparency = 1
    cg.AnchorPoint = Vector2.new(0.5, 0.5)
    cg.Position = UDim2.new(0.5, 0, 0.52, 0)
    cg.Parent = widget
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

    UI.SettingsCenterCheck = createToggle(4, "Auto Center UI", "AUTO_CENTER_UI")
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

    element.AnchorPoint = Vector2.new(0, 0)

    if Config.AUTO_SCALE then
        local parentW = parentSize.X
        local parentH = parentSize.Y

        if parentW <= 0 or parentH <= 0 then
            -- Fallback for invalid parent size
            parentW = 1920
            parentH = 1080
        end

        local scaleX = props.size.x / parentW
        local scaleY = props.size.y / parentH
        local posX = props.position.x / parentW
        local posY = props.position.y / parentH

        element.Size = UDim2.fromScale(scaleX, scaleY)
        element.Position = UDim2.fromScale(posX, posY)
        
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
        element.CanvasSize = UDim2.fromScale(1, 1)
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
    if element:IsA("ScrollingFrame") then
        element.CanvasSize = UDim2.fromScale(1, 1)
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
    
    if Config.AUTO_CENTER_UI then
        mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
        mainContainer.Position = UDim2.fromScale(0.5, 0.5)
    end

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

local mainWidget, settingsWidget, promptWidget
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
