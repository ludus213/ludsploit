-- Framify Importer
-- Version: 3.0.0 FINAL
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
    ["Midnight"] = { BG = Color3.fromRGB(18, 18, 18), Text = Color3.fromRGB(160, 160, 160), TextSecondary = Color3.fromRGB(100, 100, 100), Primary = Color3.fromRGB(80, 80, 80), Surface = Color3.fromRGB(25, 25, 25), Border = Color3.fromRGB(40, 40, 40) },
    ["High Contrast"] = { BG = Color3.fromRGB(20, 20, 20), Text = Color3.fromRGB(240, 240, 240), TextSecondary = Color3.fromRGB(180, 180, 180), Primary = Color3.fromRGB(0, 122, 255), Surface = Color3.fromRGB(35, 35, 35), Border = Color3.fromRGB(80, 80, 80) },
    ["Green"] = { BG = Color3.fromRGB(20, 30, 25), Text = Color3.fromRGB(200, 255, 220), TextSecondary = Color3.fromRGB(150, 200, 170), Primary = Color3.fromRGB(0, 180, 100), Surface = Color3.fromRGB(30, 45, 38), Border = Color3.fromRGB(50, 100, 75) },
    ["Light"] = { BG = Color3.fromRGB(245, 245, 245), Text = Color3.fromRGB(20, 20, 20), TextSecondary = Color3.fromRGB(100, 100, 100), Primary = Color3.fromRGB(0, 122, 255), Surface = Color3.fromRGB(255, 255, 255), Border = Color3.fromRGB(200, 200, 200) }
}

local UI = {}
local fontMap = { ['Arial'] = Enum.Font.Legacy, ['Roboto'] = Enum.Font.SourceSans, ['Inter'] = Enum.Font.SourceSans, ['Gotham'] = Enum.Font.Gotham }

function applyTheme(themeName)
    local theme = Themes[themeName]
    if not theme then return end
    Config.THEME = themeName

    local elementsToTheme = {
        MainFrame = { "BackgroundColor3", theme.BG },
        MainTitle = { "TextColor3", theme.Text },
        MainInstructions = { "TextColor3", theme.TextSecondary },
        MainTextScrollFrame = { "BackgroundColor3", theme.Surface, "BorderColor3", theme.Border },
        MainMappingTextBox = { "BackgroundColor3", theme.Surface, "TextColor3", theme.Text },
        MainImportButton = { "BackgroundColor3", theme.Primary, "TextColor3", Color3.new(1,1,1) },
        MainStatusLabel = { "TextColor3", theme.TextSecondary },
        MainSupportLabel = { "TextColor3", theme.TextSecondary },
        MainSettingsButtonIcon = { "ImageColor3", theme.TextSecondary },
        SettingsFrame = { "BackgroundColor3", theme.BG },
        SettingsTitle = { "TextColor3", theme.Text },
        SettingsBackButton = { "BackgroundColor3", theme.Surface, "TextColor3", theme.Text },
        SettingsAssetLabel = { "TextColor3", theme.TextSecondary },
        SettingsAssetText = { "BackgroundColor3", theme.Surface, "TextColor3", theme.Text, "BorderColor3", theme.Border },
        SettingsCenterCheck = { "BackgroundColor3", theme.Surface, "TextColor3", theme.Text, "BorderColor3", theme.Border },
        SettingsThemeLabel = { "TextColor3", theme.TextSecondary },
        SettingsThemeDropdown = { "BackgroundColor3", theme.Surface, "TextColor3", theme.Text, "BorderColor3", theme.Border },
    }

    for name, data in pairs(elementsToTheme) do
        if UI[name] then
            for i = 1, #data, 2 do
                UI[name][data[i]] = data[i+1]
            end
        end
    end
end

function createDropdown(parent, options, callback)
    local dropdownFrame = Instance.new("Frame"); dropdownFrame.Size = UDim2.new(1, 0, 0, 35); dropdownFrame.BackgroundTransparency = 1; dropdownFrame.Parent = parent
    local dropdown = Instance.new("TextButton"); dropdown.Size = UDim2.fromScale(1,1); dropdown.Text = Config.THEME; dropdown.Parent = dropdownFrame; UI.SettingsThemeDropdown = dropdown
    local optionsFrame = Instance.new("ScrollingFrame"); optionsFrame.Size = UDim2.new(1,0,0,120); optionsFrame.Position = UDim2.new(0,0,1,0); optionsFrame.Visible = false; optionsFrame.Parent = dropdownFrame
    local list = Instance.new("UIListLayout"); list.Parent = optionsFrame
    dropdown.MouseButton1Click:Connect(function() optionsFrame.Visible = not optionsFrame.Visible end)
    for _, optionName in ipairs(options) do
        local optionBtn = Instance.new("TextButton"); optionBtn.Size=UDim2.new(1,0,0,30); optionBtn.Text=optionName; optionBtn.Parent = optionsFrame
        optionBtn.MouseButton1Click:Connect(function() dropdown.Text = optionName; optionsFrame.Visible = false; callback(optionName) end)
    end
    return dropdown
end

function createMainUI(widget)
    local mainFrame = Instance.new("Frame"); mainFrame.Size = UDim2.fromScale(1,1); UI.MainFrame = mainFrame
    local padding = Instance.new("UIPadding"); padding.PaddingLeft=UDim.new(0,15); padding.PaddingRight=UDim.new(0,15); padding.PaddingTop=UDim.new(0,15); padding.PaddingBottom=UDim.new(0,15); padding.Parent=mainFrame
    local list = Instance.new("UIListLayout"); list.Padding = UDim.new(0,15); list.Parent=mainFrame
    local title = Instance.new("TextLabel"); title.Text="Framify Importer"; title.Size=UDim2.new(1,0,0,24); title.Font=Enum.Font.GothamBold; title.TextSize=22; title.BackgroundTransparency=1; title.TextXAlignment=Enum.TextXAlignment.Left; title.Parent=mainFrame; UI.MainTitle=title
    local instructions = Instance.new("TextLabel"); instructions.Text="Paste your mapping string below to begin."; instructions.Size=UDim2.new(1,0,0,18); instructions.Font=Enum.Font.Gotham; instructions.TextSize=14; instructions.TextWrapped=true; instructions.BackgroundTransparency=1; instructions.TextXAlignment=Enum.TextXAlignment.Left; instructions.Parent=mainFrame; UI.MainInstructions=instructions
    local scroll = Instance.new("ScrollingFrame"); scroll.Size=UDim2.new(1,0,1,-180); scroll.BorderSizePixel=1; scroll.Parent=mainFrame; UI.MainTextScrollFrame=scroll
    local textbox = Instance.new("TextBox"); textbox.AutomaticSize=Enum.AutomaticSize.Y; textbox.Font=Enum.Font.Code; textbox.TextSize=13; textbox.MultiLine=true; textbox.ClearTextOnFocus=false; textbox.PlaceholderText="Paste here..."; textbox.TextXAlignment=Enum.TextXAlignment.Left; textbox.TextYAlignment=Enum.TextYAlignment.Top; textbox.Size=UDim2.new(1,0,0,0); textbox.Parent=scroll; UI.MainMappingTextBox=textbox
    textbox:GetPropertyChangedSignal("Text"):Connect(function() scroll.CanvasSize = UDim2.new(0,0,0,textbox.AbsoluteSize.Y) end)
    local importBtn = Instance.new("TextButton"); importBtn.Text="Import"; importBtn.Font=Enum.Font.GothamBold; importBtn.TextSize=16; importBtn.Size=UDim2.new(1,0,0,40); Instance.new("UICorner",importBtn).CornerRadius=UDim.new(0,6); importBtn.Parent=mainFrame; UI.MainImportButton=importBtn
    local status = Instance.new("TextLabel"); status.Text=""; status.Font=Enum.Font.Gotham; status.TextSize=12; status.BackgroundTransparency=1; status.TextXAlignment=Enum.TextXAlignment.Left; status.Size=UDim2.new(1,0,0,20); status.Parent=mainFrame; UI.MainStatusLabel=status
    local support = Instance.new("TextLabel"); support.Text="Contact .ludio. on Discord for support/errors"; support.Font=Enum.Font.Gotham; support.TextSize=10; support.BackgroundTransparency=1; support.Size=UDim2.new(1,0,0,20); support.Parent=mainFrame; UI.MainSupportLabel=support
    mainFrame.Parent = widget
    return importBtn, textbox, status
end

function createSettingsUI(widget)
    local settingsFrame = Instance.new("Frame"); settingsFrame.Size=UDim2.fromScale(1,1); settingsFrame.ClipsDescendants=true; UI.SettingsFrame=settingsFrame
    local padding = Instance.new("UIPadding"); padding.PaddingLeft=UDim.new(0,15); padding.PaddingRight=UDim.new(0,15); padding.PaddingTop=UDim.new(0,15); padding.PaddingBottom=UDim.new(0,15); padding.Parent=settingsFrame
    local list = Instance.new("UIListLayout"); list.Padding=UDim.new(0,15); list.Parent=settingsFrame
    local title = Instance.new("TextLabel"); title.Text="Settings"; title.Size=UDim2.new(1,0,0,24); title.Font=Enum.Font.GothamBold; title.TextSize=22; title.BackgroundTransparency=1; title.TextXAlignment=Enum.TextXAlignment.Left; title.Parent=settingsFrame; UI.SettingsTitle=title
    local assetLabel = Instance.new("TextLabel"); assetLabel.Text="Asset Folder Name"; assetLabel.Size=UDim2.new(1,0,0,18); assetLabel.Font=Enum.Font.Gotham; assetLabel.TextSize=14; assetLabel.BackgroundTransparency=1; assetLabel.TextXAlignment=Enum.TextXAlignment.Left; assetLabel.Parent=settingsFrame; UI.SettingsAssetLabel=assetLabel
    local assetText = Instance.new("TextBox"); assetText.Text=Config.ASSET_FOLDER_NAME; assetText.Size=UDim2.new(1,0,0,35); assetText.Font=Enum.Font.Code; assetText.Parent=settingsFrame; UI.SettingsAssetText=assetText
    assetText.FocusLost:Connect(function() Config.ASSET_FOLDER_NAME=assetText.Text end)
    local centerCheck = Instance.new("TextButton"); centerCheck.Size=UDim2.new(1,0,0,35); centerCheck.Text="Auto Center UI: "..(Config.AUTO_CENTER_UI and "On" or "Off"); centerCheck.Parent=settingsFrame; UI.SettingsCenterCheck=centerCheck
    centerCheck.MouseButton1Click:Connect(function() Config.AUTO_CENTER_UI=not Config.AUTO_CENTER_UI; centerCheck.Text="Auto Center UI: "..(Config.AUTO_CENTER_UI and "On" or "Off") end)
    local themeLabel = Instance.new("TextLabel"); themeLabel.Text="Theme"; themeLabel.Size=UDim2.new(1,0,0,18); themeLabel.Font=Enum.Font.Gotham; themeLabel.TextSize=14; themeLabel.BackgroundTransparency=1; themeLabel.TextXAlignment=Enum.TextXAlignment.Left; themeLabel.Parent=settingsFrame; UI.SettingsThemeLabel=themeLabel
    createDropdown(settingsFrame, {"Midnight", "High Contrast", "Green", "Light"}, applyTheme)
    settingsFrame.Parent = widget
end

function createPrompt(title, text, onYes, onNo)
    local promptHolder = Instance.new("Frame"); promptHolder.Name="Prompt"; promptHolder.Size=UDim2.fromScale(1,1); promptHolder.BackgroundColor3=Color3.new(0,0,0); promptHolder.BackgroundTransparency=0.7; promptHolder.ZIndex=100; promptHolder.Parent=UI.MainFrame
    local dialog = Instance.new("Frame"); dialog.Size=UDim2.new(0,280,0,150); dialog.Position=UDim2.fromScale(0.5,0.5); dialog.AnchorPoint=Vector2.new(0.5,0.5); dialog.Parent = promptHolder
    local list = Instance.new("UIListLayout"); list.Padding=UDim.new(0,10); list.Parent=dialog
    local titleLabel = Instance.new("TextLabel"); titleLabel.Text=title; titleLabel.Size=UDim2.new(1,0,0,30); titleLabel.Parent=dialog
    local textLabel = Instance.new("TextLabel"); textLabel.Text=text; textLabel.Size=UDim2.new(1,0,1,-70); textLabel.TextWrapped=true; textLabel.Parent=dialog
    local btnFrame = Instance.new("Frame"); btnFrame.Size=UDim2.new(1,0,0,30); btnFrame.BackgroundTransparency=1; btnFrame.Parent=dialog
    local btnLayout = Instance.new("UIListLayout"); btnLayout.FillDirection=Enum.FillDirection.Horizontal; btnLayout.HorizontalAlignment=Enum.HorizontalAlignment.Right; btnLayout.Parent=btnFrame
    local yesBtn = Instance.new("TextButton"); yesBtn.Text="Yes"; yesBtn.Size=UDim2.new(0,80,1,0); yesBtn.Parent=btnFrame
    local noBtn = Instance.new("TextButton"); noBtn.Text="No"; noBtn.Size=UDim2.new(0,80,1,0); noBtn.Parent=btnFrame
    yesBtn.MouseButton1Click:Connect(function() onYes(); promptHolder:Destroy() end)
    noBtn.MouseButton1Click:Connect(function() onNo(); promptHolder:Destroy() end)
end

function findImageAsset(assetId) if not assetId then return "" end; local assetFolder = ReplicatedStorage:FindFirstChild(Config.ASSET_FOLDER_NAME); if not assetFolder then warn("Framify: Asset folder '"..Config.ASSET_FOLDER_NAME.."' not found."); return "" end; local image = assetFolder:FindFirstChild(assetId, true); if image then if image:IsA("ImageLabel") then return image.Image elseif image:IsA("ImageButton") then return image.Image elseif image:IsA("Decal") then return image.Texture end end; return "" end
function createBehaviorScript(element, tags) local s=[[local b=script.Parent;local c=b:GetAttribute;local n=c(b,"NormalImage");local h=c(b,"HoverImage");local p=c(b,"ClickedImage");local d=c(b,"DisabledImage");local t=c(b,"IsToggled")or false;local e=c(b,"IsEnabled")or true;local function u()if not e then b.Image=d or n;return end;if t and p then b.Image=p elseif c(b,"IsHovering")and h then b.Image=h else b.Image=n end end;b.MouseEnter:Connect(function()b:SetAttribute("IsHovering",true)u()end)b.MouseLeave:Connect(function()b:SetAttribute("IsHovering",false)u()end)b.MouseButton1Click:Connect(function()if not e then return end;if c(b,"IsToggleable")then t=not t;b:SetAttribute("IsToggled",t)end;u()end)b:GetAttributeChangedSignal("IsEnabled"):Connect(function()e=c(b,"IsEnabled")u()end)u()]];local S=Instance.new("LocalScript");S.Name="ButtonBehavior";S.Source=s;element:SetAttribute("NormalImage",element.Image);element:SetAttribute("HoverImage",findImageAsset(element.Name.."_hover"));element:SetAttribute("ClickedImage",findImageAsset(element.Name.."_clicked"));element:SetAttribute("DisabledImage",findImageAsset(element.Name.."_disabled"));element:SetAttribute("IsToggleable",table.find(tags,"toggled"));element:SetAttribute("IsEnabled",not table.find(tags,"disabled"));S.Parent=element end
function applyFills(element, fills) if not fills or #fills == 0 then element.BackgroundTransparency = 1; return end; local fill = fills[1]; local opacity = fill.opacity or 1; if fill.type == "SOLID" then element.BackgroundColor3 = Color3.new(fill.color.r, fill.color.g, fill.color.b); element.BackgroundTransparency = 1 - opacity elseif string.find(fill.type, "GRADIENT") then local gradient = Instance.new("UIGradient"); local colorStops = {}; for _, stop in ipairs(fill.gradientStops) do table.insert(colorStops, ColorSequenceKeypoint.new(stop.position, Color3.new(stop.color.r, stop.color.g, stop.color.b))) end; gradient.Color = ColorSequence.new(colorStops); gradient.Parent = element end end
function applyStrokes(element, strokes, weight) if not strokes or #strokes == 0 then return end; local stroke = strokes[1]; local uiStroke = Instance.new("UIStroke"); uiStroke.Thickness = weight or 1; if stroke.type == "SOLID" then uiStroke.Color = Color3.new(stroke.color.r, stroke.color.g, stroke.color.b) end; uiStroke.Parent = element end
function applyConstraints(element, constraints) if not constraints then return end; local x, y = 0, 0; if constraints.horizontal == "CENTER" then x = 0.5 elseif constraints.horizontal == "RIGHT" then x = 1 elseif constraints.horizontal == "SCALE" then x = 0.5 end; if constraints.vertical == "CENTER" then y = 0.5 elseif constraints.vertical == "BOTTOM" then y = 1 elseif constraints.vertical == "SCALE" then y = 0.5 end; element.AnchorPoint = Vector2.new(x, y); element.Position = UDim2.new(x, element.Position.X.Offset, y, element.Position.Y.Offset) end
local propertyAppliers = {}; propertyAppliers.Default = function(element, data) local props = data.properties; element.Name = data.name; element.Visible = props.visible; element.Position = UDim2.fromOffset(props.position.x, props.position.y); element.Size = UDim2.fromOffset(props.size.x, props.size.y); element.Rotation = props.rotation; element.ClipsDescendants = data.type == 'FRAME'; applyFills(element, props.fills); applyStrokes(element, props.strokes, props.strokeWeight); if props.cornerRadius and props.cornerRadius > 0 then local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, props.cornerRadius); c.Parent = element end; applyConstraints(element, props.constraints) end; propertyAppliers.TEXT = function(element, data) propertyAppliers.Default(element, data); local props = data.properties; element.Text = props.characters; element.Font = (props.fontName and fontMap[props.fontName.family]) or Enum.Font.SourceSans; element.TextSize = props.fontSize; element.TextWrapped = true; if props.fills and #props.fills > 0 then local fill = props.fills[1]; element.TextColor3 = Color3.new(fill.color.r, fill.color.g, fill.color.b); element.TextTransparency = 1 - (fill.opacity or 1) end; element.TextXAlignment = props.textAlignHorizontal; element.TextYAlignment = props.textAlignVertical end; propertyAppliers.Image = function(element, data) if data.assetId then element.Image = findImageAsset(data.assetId); element.BackgroundTransparency = 1 end end
local elementCreators = {}; elementCreators.Default = function(data) local tags=data.tags; if data.assetId then if table.find(tags,"button") then return Instance.new("ImageButton") else return Instance.new("ImageLabel") end end; local element; if table.find(tags,"button") then element=Instance.new("ImageButton") elseif table.find(tags,"image") then element=Instance.new("ImageLabel") elseif table.find(tags,"vpf") then element=Instance.new("ViewportFrame") elseif table.find(tags,"canvas") then element=Instance.new("CanvasGroup") elseif table.find(tags,"scroll") then element=Instance.new("ScrollingFrame");element.ScrollingDirection=table.find(tags,"scrollx")and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y else element=Instance.new("Frame") end; if table.find(tags,"box") then Instance.new("UIListLayout").Parent=element end; return element end; elementCreators.TEXT = function(data) return Instance.new("TextLabel") end
function createFromData(data, parent) local element = (elementCreators[data.type] or elementCreators.Default)(data);(propertyAppliers[data.type] or propertyAppliers.Default)(element, data); if element:IsA("ImageLabel") or element:IsA("ImageButton") then propertyAppliers.Image(element, data) end; if Config.CREATE_BEHAVIOR_SCRIPTS and table.find(data.tags, "button") then createBehaviorScript(element, data.tags) end; element.Parent = parent; if data.children then for _, childData in ipairs(data.children) do createFromData(childData, element) end end; return element end
function hasAssetIds(dataTable) for _, nodeData in ipairs(dataTable) do if nodeData.assetId and nodeData.assetId ~= "" then return true end; if nodeData.children and #nodeData.children > 0 then if hasAssetIds(nodeData.children) then return true end end end; return false end
function performImport(data, statusLabel) statusLabel.Text = "Importing..."; local targetGui = StarterGui:FindFirstChild(Config.TARGET_SCREEN_GUI); if targetGui then targetGui:Destroy() end; targetGui = Instance.new("ScreenGui"); targetGui.Name = Config.TARGET_SCREEN_GUI; local importParent = targetGui; if Config.AUTO_CENTER_UI then local mainContainer = Instance.new("Frame"); mainContainer.Name = "ImportContainer"; mainContainer.BackgroundTransparency = 1; mainContainer.AnchorPoint = Vector2.new(0.5, 0.5); mainContainer.Position = UDim2.fromScale(0.5, 0.5); local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge; for _, nodeData in ipairs(data) do local props = nodeData.properties; minX = math.min(minX, props.position.x); minY = math.min(minY, props.position.y); maxX = math.max(maxX, props.position.x + props.size.x); maxY = math.max(maxY, props.position.y + props.size.y) end; mainContainer.Size = UDim2.fromOffset(maxX - minX, maxY - minY); for _, nodeData in ipairs(data) do nodeData.properties.position.x = nodeData.properties.position.x - minX; nodeData.properties.position.y = nodeData.properties.position.y - minY end; mainContainer.Parent = targetGui; importParent = mainContainer end; for _, nodeData in ipairs(data) do createFromData(nodeData, importParent) end; targetGui.Parent = StarterGui; Selection:Set({targetGui}); statusLabel.Text = "Import successful!" end

local toolbar = plugin:CreateToolbar("Framify")
local mainPluginButton = toolbar:CreateButton("Framify Importer", "Open Framify Importer", "rbxassetid://123456789")
local settingsPluginButton = toolbar:CreateButton("Framify Settings", "Open Framify Settings", "rbxassetid://3926307971")

local mainWidget = plugin:CreateDockWidgetPluginGui("FramifyImporter", DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, false, 340, 520, 340, 520))
mainWidget.Title = "Framify Importer"
local importBtn, mappingTextBox, statusLabel = createMainUI(mainWidget)

local settingsWidget = plugin:CreateDockWidgetPluginGui("FramifySettings", DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, false, 300, 400, 300, 400))
settingsWidget.Title = "Framify Settings"
createSettingsUI(settingsWidget)

applyTheme(Config.THEME)

importBtn.MouseButton1Click:Connect(function()
    statusLabel.Text = ""
    local mappingString = mappingTextBox.Text
    if mappingString == "" then statusLabel.Text = "Mapping string cannot be empty."; return end
    local success, data = pcall(function() return HttpService:JSONDecode(mappingString) end)
    if not success then statusLabel.Text = "Error: Invalid mapping string."; return end
    if hasAssetIds(data) then
        createPrompt("Image Assets Required", "This UI requires images. Have you uploaded the assets from the .zip file to the '" .. Config.ASSET_FOLDER_NAME .. "' folder in ReplicatedStorage?",
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
