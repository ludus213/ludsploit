-- Framify Importer
-- Version: 4.0.0 DEFINITIVE
-- This script contains the full, final, and completely refactored logic for the Framify Roblox Studio plugin.

local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = {
    TARGET_SCREEN_GUI = "FramifyImport",
    ASSET_FOLDER_NAME = "FramifyAssets",
    CREATE_BEHAVIOR_SCRIPTS = true,
    AUTO_CENTER_UI = true,
    THEME = "High Contrast"
}

local Themes = {
    ["Midnight"] = { BG=Color3.fromRGB(18,18,18), Text=Color3.fromRGB(160,160,160), TextSecondary=Color3.fromRGB(100,100,100), Primary=Color3.fromRGB(80,80,80), Surface=Color3.fromRGB(25,25,25), Border=Color3.fromRGB(40,40,40), Success=Color3.fromRGB(40,100,60), Danger=Color3.fromRGB(100,40,40) },
    ["High Contrast"] = { BG=Color3.fromRGB(20,20,20), Text=Color3.fromRGB(240,240,240), TextSecondary=Color3.fromRGB(180,180,180), Primary=Color3.fromRGB(0,122,255), Surface=Color3.fromRGB(35,35,35), Border=Color3.fromRGB(80,80,80), Success=Color3.fromRGB(0,150,80), Danger=Color3.fromRGB(200,50,50) },
    ["Green"] = { BG=Color3.fromRGB(20,30,25), Text=Color3.fromRGB(200,255,220), TextSecondary=Color3.fromRGB(150,200,170), Primary=Color3.fromRGB(0,180,100), Surface=Color3.fromRGB(30,45,38), Border=Color3.fromRGB(50,100,75), Success=Color3.fromRGB(40,180,120), Danger=Color3.fromRGB(180,80,80) },
    ["Light"] = { BG=Color3.fromRGB(245,245,245), Text=Color3.fromRGB(20,20,20), TextSecondary=Color3.fromRGB(100,100,100), Primary=Color3.fromRGB(0,122,255), Surface=Color3.fromRGB(255,255,255), Border=Color3.fromRGB(200,200,200), Success=Color3.fromRGB(0,150,80), Danger=Color3.fromRGB(200,50,50) }
}

local UI = {}
local fontMap = { ['Arial']=Enum.Font.Legacy, ['Roboto']=Enum.Font.SourceSans, ['Inter']=Enum.Font.SourceSans, ['Gotham']=Enum.Font.Gotham }

function applyTheme(themeName)
    local theme = Themes[themeName] or Themes["High Contrast"]
    Config.THEME = themeName
    for name, element in pairs(UI) do
        local elType = element.ClassName
        if elType == "Frame" then element.BackgroundColor3 = theme.BG
        elseif elType == "TextLabel" then
            if element.Name == "Title" then element.TextColor3 = theme.Text
            elseif element.Name == "Label" or element.Name == "Support" then element.TextColor3 = theme.TextSecondary
            end
        elseif elType == "TextButton" then
            if element.Name == "Primary" then element.BackgroundColor3 = theme.Primary; element.TextColor3 = Color3.new(1,1,1)
            elseif element.Name == "Secondary" then element.BackgroundColor3 = theme.Surface; element.TextColor3 = theme.Text
            elseif element.Name == "Danger" then element.BackgroundColor3 = theme.Danger; element.TextColor3 = Color3.new(1,1,1)
            end
        elseif elType == "TextBox" then element.BackgroundColor3 = theme.Surface; element.TextColor3 = theme.Text; element.PlaceholderColor3 = theme.TextSecondary
        elseif elType == "ScrollingFrame" then element.BackgroundColor3 = theme.Surface; element.BorderColor3 = theme.Border
        elseif elType == "ImageLabel" and element.Name == "Icon" then element.ImageColor3 = theme.TextSecondary
        end
    end
end

function createStyled(instanceType, name, parent, properties)
    local element = Instance.new(instanceType)
    element.Name = name
    for k,v in pairs(properties or {}) do element[k] = v end
    element.Parent = parent
    UI[name] = element
    return element
end

function createMainUI(widget)
    local f = createStyled("Frame", "MainFrame", widget, {Size=UDim2.fromScale(1,1)})
    local p = Instance.new("UIPadding",f); p.PaddingLeft,p.PaddingRight,p.PaddingTop,p.PaddingBottom = UDim.new(0,15),UDim.new(0,15),UDim.new(0,15),UDim.new(0,15)
    local l = Instance.new("UIListLayout",f); l.Padding=UDim.new(0,15)
    createStyled("TextLabel", "MainTitle", f, {Text="Framify Importer", Size=UDim2.new(1,0,0,24), Font=Enum.Font.GothamBold, TextSize=22, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left})
    createStyled("TextLabel", "MainInstructions", f, {Text="Paste your mapping string below to begin.", Size=UDim2.new(1,0,0,18), Font=Enum.Font.Gotham, TextSize=14, TextWrapped=true, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left})
    local scroll = createStyled("ScrollingFrame", "MainTextScrollFrame", f, {Size=UDim2.new(1,0,1,-180), BorderSizePixel=1})
    local textbox = createStyled("TextBox", "MainMappingTextBox", scroll, {AutomaticSize=Enum.AutomaticSize.Y, Font=Enum.Font.Code, TextSize=13, MultiLine=true, ClearTextOnFocus=false, PlaceholderText="Paste here...", TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top, Size=UDim2.new(1,0,0,0)})
    textbox:GetPropertyChangedSignal("Text"):Connect(function() scroll.CanvasSize = UDim2.new(0,0,0,textbox.AbsoluteSize.Y) end)
    local importBtn = createStyled("TextButton", "MainImportButton", f, {Name="Primary", Text="Import", Font=Enum.Font.GothamBold, TextSize=16, Size=UDim2.new(1,0,0,40)})
    Instance.new("UICorner",importBtn).CornerRadius=UDim.new(0,6)
    local status = createStyled("TextLabel", "MainStatusLabel", f, {Name="Label", Text="", Font=Enum.Font.Gotham, TextSize=12, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left, Size=UDim2.new(1,0,0,20)})
    createStyled("TextLabel", "MainSupportLabel", f, {Name="Support", Text="Contact .ludio. on Discord for support/errors", Font=Enum.Font.Gotham, TextSize=10, BackgroundTransparency=1, Size=UDim2.new(1,0,0,20)})
    return importBtn, textbox, status
end

function createSettingsUI(widget)
    local f = createStyled("Frame", "SettingsFrame", widget, {Size=UDim2.fromScale(1,1)})
    local p = Instance.new("UIPadding",f); p.PaddingLeft,p.PaddingRight,p.PaddingTop,p.PaddingBottom = UDim.new(0,15),UDim.new(0,15),UDim.new(0,15),UDim.new(0,15)
    local l = Instance.new("UIListLayout",f); l.Padding=UDim.new(0,10); l.VerticalAlignment=Enum.VerticalAlignment.Top
    createStyled("TextLabel", "SettingsTitle", f, {Text="Settings", Size=UDim2.new(1,0,0,24), Font=Enum.Font.GothamBold, TextSize=22, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left})
    createStyled("TextLabel", "SettingsAssetLabel", f, {Name="Label", Text="Asset Folder Name", Size=UDim2.new(1,0,0,18), Font=Enum.Font.Gotham, TextSize=14, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left})
    local assetText = createStyled("TextBox", "SettingsAssetText", f, {Text=Config.ASSET_FOLDER_NAME, Size=UDim2.new(1,0,0,35), Font=Enum.Font.Code})
    assetText.FocusLost:Connect(function() Config.ASSET_FOLDER_NAME=assetText.Text end)
    local centerCheck = createStyled("TextButton", "SettingsCenterCheck", f, {Name="Secondary", Size=UDim2.new(1,0,0,35), Text="Auto Center UI: "..(Config.AUTO_CENTER_UI and "On" or "Off")})
    centerCheck.MouseButton1Click:Connect(function() Config.AUTO_CENTER_UI=not Config.AUTO_CENTER_UI; centerCheck.Text="Auto Center UI: "..(Config.AUTO_CENTER_UI and "On" or "Off") end)
    createStyled("TextLabel", "SettingsThemeLabel", f, {Name="Label", Text="Theme", Size=UDim2.new(1,0,0,18), Font=Enum.Font.Gotham, TextSize=14, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left})
    local dropdownFrame = createStyled("Frame", "SettingsDropdownFrame", f, {Size=UDim2.new(1,0,0,35), BackgroundTransparency=1})
    local dropdown = createStyled("TextButton", "SettingsThemeDropdown", dropdownFrame, {Name="Secondary", Size=UDim2.fromScale(1,1), Text=Config.THEME})
    local options = createStyled("ScrollingFrame", "SettingsThemeOptions", dropdownFrame, {Position=UDim2.new(0,0,1,0), Size=UDim2.new(1,0,0,120), Visible=false})
    local list = Instance.new("UIListLayout", options)
    dropdown.MouseButton1Click:Connect(function() options.Visible = not options.Visible end)
    for name,_ in pairs(Themes) do
        local btn = createStyled("TextButton", "SettingsThemeOption_"..name, options, {Name="Secondary", Size=UDim2.new(1,0,0,30), Text=name})
        btn.MouseButton1Click:Connect(function() dropdown.Text=name; options.Visible=false; applyTheme(name) end)
    end
end

function populatePromptUI(widget, title, text, onYes, onNo)
    for _,child in ipairs(widget:GetChildren()) do child:Destroy() end
    local f = createStyled("Frame", "PromptFrame", widget, {Size=UDim2.fromScale(1,1)})
    local p = Instance.new("UIPadding",f); p.PaddingLeft,p.PaddingRight,p.PaddingTop,p.PaddingBottom = UDim.new(0,15),UDim.new(0,15),UDim.new(0,15),UDim.new(0,15)
    local l = Instance.new("UIListLayout",f); l.Padding=UDim.new(0,15); l.VerticalAlignment=Enum.VerticalAlignment.Center
    createStyled("TextLabel", "PromptTitle", f, {Text=title, Size=UDim2.new(1,0,0,24), Font=Enum.Font.GothamBold, TextSize=22, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left})
    createStyled("TextLabel", "PromptText", f, {Text=text, Size=UDim2.new(1,0,0,60), Font=Enum.Font.Gotham, TextSize=14, TextWrapped=true, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left})
    local btnFrame = createStyled("Frame", "PromptButtonFrame", f, {Size=UDim2.new(1,0,0,40), BackgroundTransparency=1})
    local btnLayout = Instance.new("UIListLayout", btnFrame); btnLayout.FillDirection=Enum.FillDirection.Horizontal; btnLayout.HorizontalAlignment=Enum.HorizontalAlignment.Right; btnLayout.Padding = UDim.new(0,10)
    local yesBtn = createStyled("TextButton", "PromptYes", btnFrame, {Name="Primary", Text="Yes", Size=UDim2.new(0,100,1,0)})
    local noBtn = createStyled("TextButton", "PromptNo", btnFrame, {Name="Secondary", Text="No", Size=UDim2.new(0,100,1,0)})
    yesBtn.MouseButton1Click:Connect(function() onYes(); widget.Enabled=false end)
    noBtn.MouseButton1Click:Connect(function() onNo(); widget.Enabled=false end)
    applyTheme(Config.THEME)
    widget.Enabled = true
end

function findImageAsset(assetId) if not assetId then return "" end; local assetFolder = ReplicatedStorage:FindFirstChild(Config.ASSET_FOLDER_NAME); if not assetFolder then warn("Framify: Asset folder '"..Config.ASSET_FOLDER_NAME.."' not found."); return "" end; local image = assetFolder:FindFirstChild(assetId, true); if image then if image:IsA("ImageLabel") then return image.Image elseif image:IsA("ImageButton") then return image.Image elseif image:IsA("Decal") then return image.Texture end end; return "" end
function createBehaviorScript(element, tags) local s=[[local b=script.Parent;local c=b:GetAttribute;local n=c(b,"NormalImage");local h=c(b,"HoverImage");local p=c(b,"ClickedImage");local d=c(b,"DisabledImage");local t=c(b,"IsToggled")or false;local e=c(b,"IsEnabled")or true;local function u()if not e then b.Image=d or n;return end;if t and p then b.Image=p elseif c(b,"IsHovering")and h then b.Image=h else b.Image=n end end;b.MouseEnter:Connect(function()b:SetAttribute("IsHovering",true)u()end)b.MouseLeave:Connect(function()b:SetAttribute("IsHovering",false)u()end)b.MouseButton1Click:Connect(function()if not e then return end;if c(b,"IsToggleable")then t=not t;b:SetAttribute("IsToggled",t)end;u()end)b:GetAttributeChangedSignal("IsEnabled"):Connect(function()e=c(b,"IsEnabled")u()end)u()]];local S=Instance.new("LocalScript");S.Name="ButtonBehavior";S.Source=s;element:SetAttribute("NormalImage",element.Image);element:SetAttribute("HoverImage",findImageAsset(element.Name.."_hover"));element:SetAttribute("ClickedImage",findImageAsset(element.Name.."_clicked"));element:SetAttribute("DisabledImage",findImageAsset(element.Name.."_disabled"));element:SetAttribute("IsToggleable",table.find(tags,"toggled"));element:SetAttribute("IsEnabled",not table.find(tags,"disabled"));S.Parent=element end
function applyFills(element, fills) if not fills or #fills == 0 then element.BackgroundTransparency = 1; return end; local fill = fills[1]; local opacity = fill.opacity or 1; if fill.type == "SOLID" then element.BackgroundColor3 = Color3.new(fill.color.r, fill.color.g, fill.color.b); element.BackgroundTransparency = 1 - opacity elseif string.find(fill.type, "GRADIENT") then local gradient = Instance.new("UIGradient"); local colorStops = {}; for _, stop in ipairs(fill.gradientStops) do table.insert(colorStops, ColorSequenceKeypoint.new(stop.position, Color3.new(stop.color.r, stop.color.g, stop.color.b))) end; gradient.Color = ColorSequence.new(colorStops); gradient.Parent = element end end
function applyStrokes(element, strokes, weight) if not strokes or #strokes == 0 then return end; local stroke = strokes[1]; local uiStroke = Instance.new("UIStroke"); uiStroke.Thickness = weight or 1; if stroke.type == "SOLID" then uiStroke.Color = Color3.new(stroke.color.r, stroke.color.g, stroke.color.b) end; uiStroke.Parent = element end
function applyConstraints(element, constraints) if not constraints then return end; local x, y = 0, 0; if constraints.horizontal == "CENTER" then x = 0.5 elseif constraints.horizontal == "RIGHT" then x = 1 elseif constraints.horizontal == "SCALE" then x = 0.5 end; if constraints.vertical == "CENTER" then y = 0.5 elseif constraints.vertical == "BOTTOM" then y = 1 elseif constraints.vertical == "SCALE" then y = 0.5 end; element.AnchorPoint = Vector2.new(x, y); element.Position = UDim2.new(x, element.Position.X.Offset, y, element.Position.Y.Offset) end
local propertyAppliers = {}; propertyAppliers.Default = function(element, data) local props = data.properties; element.Name = data.name; element.Visible = props.visible; element.Position = UDim2.fromOffset(props.position.x, props.position.y); element.Size = UDim2.fromOffset(props.size.x, props.size.y); element.Rotation = props.rotation; element.ClipsDescendants = data.type == 'FRAME'; applyFills(element, props.fills); applyStrokes(element, props.strokes, props.strokeWeight); if props.cornerRadius and props.cornerRadius > 0 then local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, props.cornerRadius); c.Parent = element end; applyConstraints(element, props.constraints) end; propertyAppliers.TEXT = function(element, data) propertyAppliers.Default(element, data); local props = data.properties; element.Text = props.characters; element.Font = (props.fontName and fontMap[props.fontName.family]) or Enum.Font.SourceSans; element.TextSize = props.fontSize; element.TextWrapped = true; if props.fills and #props.fills > 0 then local fill = props.fills[1]; element.TextColor3 = Color3.new(fill.color.r, fill.color.g, fill.color.b); element.TextTransparency = 1 - (fill.opacity or 1) end; element.TextXAlignment = props.textAlignHorizontal; element.TextYAlignment = props.textAlignVertical end; propertyAppliers.Image = function(element, data) if data.assetId then element.Image = findImageAsset(data.assetId); element.BackgroundTransparency = 1 end end
local elementCreators = {}; elementCreators.Default = function(data) local tags=data.tags; if data.assetId and data.assetId ~= "" then if table.find(tags,"button") then return Instance.new("ImageButton") else return Instance.new("ImageLabel") end end; local element; if table.find(tags,"button") then element=Instance.new("ImageButton") elseif table.find(tags,"image") then element=Instance.new("ImageLabel") elseif table.find(tags,"vpf") then element=Instance.new("ViewportFrame") elseif table.find(tags,"canvas") then element=Instance.new("CanvasGroup") elseif table.find(tags,"scroll") then element=Instance.new("ScrollingFrame");element.ScrollingDirection=table.find(tags,"scrollx")and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y else element=Instance.new("Frame") end; if table.find(tags,"box") then Instance.new("UIListLayout").Parent=element end; return element end; elementCreators.TEXT = function(data) return Instance.new("TextLabel") end
function createFromData(data, parent) local element = (elementCreators[data.type] or elementCreators.Default)(data);(propertyAppliers[data.type] or propertyAppliers.Default)(element, data); if element:IsA("ImageLabel") or element:IsA("ImageButton") then propertyAppliers.Image(element, data) end; if Config.CREATE_BEHAVIOR_SCRIPTS and table.find(data.tags, "button") then createBehaviorScript(element, data.tags) end; element.Parent = parent; if data.children then for _, childData in ipairs(data.children) do createFromData(childData, element) end end; return element end
function hasAssetIds(dataTable) for _, nodeData in ipairs(dataTable) do if nodeData.assetId and nodeData.assetId ~= "" then return true end; if nodeData.children and #nodeData.children > 0 then if hasAssetIds(nodeData.children) then return true end end end; return false end
function performImport(data, statusLabel) statusLabel.Text = "Importing..."; local targetGui = StarterGui:FindFirstChild(Config.TARGET_SCREEN_GUI); if targetGui then targetGui:Destroy() end; targetGui = Instance.new("ScreenGui"); targetGui.Name = Config.TARGET_SCREEN_GUI; local importParent = targetGui; if Config.AUTO_CENTER_UI then local mainContainer = Instance.new("Frame"); mainContainer.Name = "ImportContainer"; mainContainer.BackgroundTransparency = 1; mainContainer.AnchorPoint = Vector2.new(0.5, 0.5); mainContainer.Position = UDim2.fromScale(0.5, 0.5); local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge; for _, nodeData in ipairs(data) do local props = nodeData.properties; minX = math.min(minX, props.position.x); minY = math.min(minY, props.position.y); maxX = math.max(maxX, props.position.x + props.size.x); maxY = math.max(maxY, props.position.y + props.size.y) end; mainContainer.Size = UDim2.fromOffset(maxX - minX, maxY - minY); for _, nodeData in ipairs(data) do nodeData.properties.position.x = nodeData.properties.position.x - minX; nodeData.properties.position.y = nodeData.properties.position.y - minY end; mainContainer.Parent = targetGui; importParent = mainContainer end; for _, nodeData in ipairs(data) do createFromData(nodeData, importParent) end; targetGui.Parent = StarterGui; Selection:Set({targetGui}); statusLabel.Text = "Import successful!" end

local toolbar = plugin:CreateToolbar("Framify")
local mainPluginButton = toolbar:CreateButton("Framify Importer", "Open Framify Importer", "rbxassetid://123456789")
local settingsPluginButton = toolbar:CreateButton("Framify Settings", "Open Framify Settings", "rbxassetid://3926307971")

local mainWidget = plugin:CreateDockWidgetPluginGui("FramifyImporter", DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, false, 360, 550, 360, 550))
mainWidget.Title = "Framify Importer"
local importBtn, mappingTextBox, statusLabel = createMainUI(mainWidget)

local settingsWidget = plugin:CreateDockWidgetPluginGui("FramifySettings", DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, false, 320, 420, 320, 420))
settingsWidget.Title = "Framify Settings"
createSettingsUI(settingsWidget)

local promptWidget = plugin:CreateDockWidgetPluginGui("FramifyPrompt", DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, false, 320, 200, 320, 200))
promptWidget.Title = "Framify Prompt"

applyTheme(Config.THEME)

importBtn.MouseButton1Click:Connect(function()
    statusLabel.Text = ""
    local mappingString = mappingTextBox.Text
    if mappingString == "" then statusLabel.Text = "Mapping string cannot be empty."; return end
    local success, data = pcall(function() return HttpService:JSONDecode(mappingString) end)
    if not success then statusLabel.Text = "Error: Invalid mapping string."; return end
    if hasAssetIds(data) then
        populatePromptUI(promptWidget, "Image Assets Required", "This UI requires images. Have you uploaded the assets from the .zip file to the '" .. Config.ASSET_FOLDER_NAME .. "' folder in ReplicatedStorage?",
            function() performImport(data, statusLabel) end,
            function() statusLabel.Text = "Import cancelled. Please upload images first." end
        )
    else
        performImport(data, statusLabel)
    end
end)

mainPluginButton.Click:Connect(function() mainWidget.Enabled = not mainWidget.Enabled end)
settingsPluginButton.Click:Connect(function() settingsWidget.Enabled = not settingsWidget.Enabled end)
mainWidget.Enabled = false
settingsWidget.Enabled = false
promptWidget.Enabled = false
