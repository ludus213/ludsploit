-- Framify Importer
-- Version: 8.0.0 ABSOLUTELY DEFINITIVE FINAL
-- This script contains the full, final, and completely refactored logic for the Framify Roblox Studio plugin.

local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VERSION = "1.0.0"

local Config = {
    TARGET_SCREEN_GUI = "FramifyImport",
    ASSET_FOLDER_NAME = "FramifyAssets",
    CREATE_BEHAVIOR_SCRIPTS = true,
    AUTO_CENTER_UI = true,
    THEME = "High Contrast"
}

local Themes = {
    ["Midnight"] = { BG=Color3.fromRGB(18,18,18), Text=Color3.fromRGB(160,160,160), TextSecondary=Color3.fromRGB(100,100,100), Primary=Color3.fromRGB(80,80,80), Surface=Color3.fromRGB(25,25,25), Border=Color3.fromRGB(40,40,40), Danger=Color3.fromRGB(120,50,50) },
    ["High Contrast"] = { BG=Color3.fromRGB(20,20,20), Text=Color3.fromRGB(240,240,240), TextSecondary=Color3.fromRGB(180,180,180), Primary=Color3.fromRGB(0,122,255), Surface=Color3.fromRGB(35,35,35), Border=Color3.fromRGB(80,80,80), Danger=Color3.fromRGB(220,60,60) },
    ["Green"] = { BG=Color3.fromRGB(20,30,25), Text=Color3.fromRGB(200,255,220), TextSecondary=Color3.fromRGB(150,200,170), Primary=Color3.fromRGB(0,180,100), Surface=Color3.fromRGB(30,45,38), Border=Color3.fromRGB(50,100,75), Danger=Color3.fromRGB(180,80,80) },
    ["Light"] = { BG=Color3.fromRGB(245,245,245), Text=Color3.fromRGB(20,20,20), TextSecondary=Color3.fromRGB(100,100,100), Primary=Color3.fromRGB(0,122,255), Surface=Color3.fromRGB(255,255,255), Border=Color3.fromRGB(200,200,200), Danger=Color3.fromRGB(220,60,60) }
}

local UI = {}
local fontMap = { ['Arial']=Enum.Font.Legacy, ['Roboto']=Enum.Font.SourceSans, ['Inter']=Enum.Font.SourceSans, ['Gotham']=Enum.Font.Gotham }

function styleButton(button, styleType, theme)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 16
    local corner = button:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    if styleType == "Primary" then button.BackgroundColor3 = theme.Primary; button.TextColor3 = Color3.new(1,1,1)
    elseif styleType == "Secondary" then button.BackgroundColor3 = theme.Surface; button.TextColor3 = theme.Text
    elseif styleType == "Danger" then button.BackgroundColor3 = theme.Danger; button.TextColor3 = Color3.new(1,1,1)
    end
end

function applyTheme(themeName)
    local theme = Themes[themeName] or Themes["High Contrast"]
    Config.THEME = themeName
    for name, element in pairs(UI) do
        if name:match("Frame$") then element.BackgroundColor3 = theme.BG
        elseif name:match("Title") then element.TextColor3 = theme.Text
        elseif name:match("Label") or name:match("Support") or name:match("Instructions") or name:match("Version") then element.TextColor3 = theme.TextSecondary
        elseif name:match("TextScrollFrame") then element.BackgroundColor3 = theme.Surface; element.BorderColor3 = theme.Border
        elseif name:match("TextBox") then element.BackgroundColor3 = theme.Surface; element.TextColor3 = theme.Text; element.PlaceholderColor3 = theme.TextSecondary
        elseif name:match("Button$") then styleButton(element, "Primary", theme)
        elseif name:match("Check$") or name:match("Dropdown$") then styleButton(element, "Secondary", theme)
        elseif name:match("Icon") then element.ImageColor3 = theme.TextSecondary
        end
    end
    if UI.PromptYes then styleButton(UI.PromptYes, "Primary", theme) end
    if UI.PromptNo then styleButton(UI.PromptNo, "Danger", theme) end
end

function createMainUI(widget)
    local f = Instance.new("Frame"); f.Name="MainFrame"; f.Size=UDim2.fromScale(1,1); UI.MainFrame=f; f.Parent=widget
    local p = Instance.new("UIPadding",f); p.PaddingLeft,p.PaddingRight,p.PaddingTop,p.PaddingBottom=UDim.new(0,15),UDim.new(0,15),UDim.new(0,15),UDim.new(0,15)
    local l = Instance.new("UIListLayout",f); l.Padding=UDim.new(0,15); l.SortOrder=Enum.SortOrder.LayoutOrder; l.HorizontalAlignment=Enum.HorizontalAlignment.Center
    local t = Instance.new("TextLabel",f); t.Name="Title"; t.LayoutOrder=1; t.Text="Framify Importer"; t.Size=UDim2.new(1,0,0,24); t.Font=Enum.Font.GothamBold; t.TextSize=22; t.BackgroundTransparency=1; t.TextXAlignment=Enum.TextXAlignment.Center; UI.MainTitle=t
    local i = Instance.new("TextLabel",f); i.Name="Instructions"; i.LayoutOrder=2; i.Text="Paste your mapping string below to begin."; i.Size=UDim2.new(1,0,0,18); i.Font=Enum.Font.Gotham; i.TextSize=14; i.TextWrapped=true; i.BackgroundTransparency=1; i.TextXAlignment=Enum.TextXAlignment.Center; UI.MainInstructions=i
    local s = Instance.new("ScrollingFrame",f); s.Name="TextScrollFrame"; s.LayoutOrder=3; s.Size=UDim2.new(1,0,1,-210); s.BorderSizePixel=1; UI.MainTextScrollFrame=s
    local tb = Instance.new("TextBox",s); tb.Name="TextBox"; tb.AutomaticSize=Enum.AutomaticSize.Y; tb.Font=Enum.Font.Code; tb.TextSize=13; tb.MultiLine=true; tb.ClearTextOnFocus=false; tb.PlaceholderText="Paste here..."; tb.TextXAlignment=Enum.TextXAlignment.Left; tb.TextYAlignment=Enum.TextYAlignment.Top; tb.Size=UDim2.new(1,0,0,0); UI.MainMappingTextBox=tb
    tb:GetPropertyChangedSignal("Text"):Connect(function() s.CanvasSize = UDim2.new(0,0,0,tb.AbsoluteSize.Y) end)
    local btn = Instance.new("TextButton",f); btn.Name="Primary"; btn.LayoutOrder=4; btn.Text="Import"; UI.MainImportButton=btn
    local st = Instance.new("TextLabel",f); st.Name="Label"; st.LayoutOrder=5; st.Text=""; st.Font=Enum.Font.Gotham; st.TextSize=12; st.BackgroundTransparency=1; st.TextXAlignment=Enum.TextXAlignment.Center; st.Size=UDim2.new(1,0,0,20); UI.MainStatusLabel=st
    local v = Instance.new("TextLabel",f); v.Name="Version"; v.LayoutOrder=6; v.Text="V"..VERSION; v.Font=Enum.Font.Gotham; v.TextSize=12; v.BackgroundTransparency=1; v.Size=UDim2.new(1,0,0,15); v.TextXAlignment=Enum.TextXAlignment.Center; UI.MainVersionLabel=v
    local sup = Instance.new("TextLabel",f); sup.Name="Support"; sup.LayoutOrder=7; sup.Text="Contact .ludio. on Discord for support/errors"; sup.Font=Enum.Font.Gotham; sup.TextSize=10; sup.BackgroundTransparency=1; sup.Size=UDim2.new(1,0,0,20); sup.TextXAlignment=Enum.TextXAlignment.Center; UI.MainSupportLabel=sup
    return btn, tb, st
end

function createSettingsUI(widget)
    local f = Instance.new("Frame"); f.Name="SettingsFrame"; f.Size=UDim2.fromScale(1,1); f.Parent=widget; UI.SettingsFrame=f
    local p = Instance.new("UIPadding",f); p.PaddingLeft,p.PaddingRight,p.PaddingTop,p.PaddingBottom=UDim.new(0,15),UDim.new(0,15),UDim.new(0,15),UDim.new(0,15)
    local l = Instance.new("UIListLayout",f); l.Padding=UDim.new(0,10); l.SortOrder=Enum.SortOrder.LayoutOrder
    local t = Instance.new("TextLabel",f); t.Name="Title"; t.LayoutOrder=1; t.Text="Settings"; t.Size=UDim2.new(1,0,0,24); t.Font=Enum.Font.GothamBold; t.TextSize=22; t.BackgroundTransparency=1; t.TextXAlignment=Enum.TextXAlignment.Left; UI.SettingsTitle=t
    local al = Instance.new("TextLabel",f); al.Name="Label"; al.LayoutOrder=2; al.Text="Asset Folder Name"; al.Size=UDim2.new(1,0,0,18); al.Font=Enum.Font.Gotham; al.TextSize=14; al.BackgroundTransparency=1; al.TextXAlignment=Enum.TextXAlignment.Left; UI.SettingsAssetLabel=al
    local at = Instance.new("TextBox",f); at.Name="TextBox"; at.LayoutOrder=3; at.Text=Config.ASSET_FOLDER_NAME; at.Size=UDim2.new(1,0,0,35); at.Font=Enum.Font.Code; at.TextScaled=true; UI.SettingsAssetText=at; at.FocusLost:Connect(function() Config.ASSET_FOLDER_NAME=at.Text end)
    local cc = Instance.new("TextButton",f); cc.Name="Secondary"; cc.LayoutOrder=4; cc.Size=UDim2.new(1,0,0,35); cc.Text="Auto Center UI: "..(Config.AUTO_CENTER_UI and "On" or "Off"); UI.SettingsCenterCheck=cc; cc.MouseButton1Click:Connect(function() Config.AUTO_CENTER_UI=not Config.AUTO_CENTER_UI; cc.Text="Auto Center UI: "..(Config.AUTO_CENTER_UI and "On" or "Off") end)
    local tl = Instance.new("TextLabel",f); tl.Name="Label"; tl.LayoutOrder=5; tl.Text="Theme"; tl.Size=UDim2.new(1,0,0,18); tl.Font=Enum.Font.Gotham; tl.TextSize=14; tl.BackgroundTransparency=1; tl.TextXAlignment=Enum.TextXAlignment.Left; UI.SettingsThemeLabel=tl
    local df = Instance.new("Frame",f); df.Name="DropdownFrame"; df.LayoutOrder=6; df.Size=UDim2.new(1,0,0,35); df.BackgroundTransparency=1
    local d = Instance.new("TextButton",df); d.Name="Secondary"; d.Size=UDim2.fromScale(1,1); d.Text=Config.THEME; UI.SettingsThemeDropdown=d
    local o = Instance.new("ScrollingFrame",f); o.Name="OptionsFrame"; o.ZIndex=2; o.Position=UDim2.new(0,0,1,0); o.Size=UDim2.new(1,0,0,120); o.Visible=false; o.Parent=d
    local ol = Instance.new("UIListLayout",o)
    d.MouseButton1Click:Connect(function() o.Visible=not o.Visible end)
    for name,_ in pairs(Themes) do local b=Instance.new("TextButton",o); b.Name="Secondary"; b.Size=UDim2.new(1,0,0,30); b.Text=name; b.MouseButton1Click:Connect(function() d.Text=name; o.Visible=false; applyTheme(name) end) end
    local v = Instance.new("TextLabel",f); v.Name="Version"; v.LayoutOrder=7; v.Text="V"..VERSION; v.Font=Enum.Font.Gotham; v.TextSize=12; v.BackgroundTransparency=1; v.Size=UDim2.new(1,0,1,-45); v.TextXAlignment=Enum.TextXAlignment.Center; UI.SettingsVersionLabel=v
end

function populatePromptUI(widget, title, text, onYes, onNo)
    for _,c in ipairs(widget:GetChildren()) do c:Destroy() end
    local f = Instance.new("Frame"); f.Name="PromptFrame"; f.Size=UDim2.fromScale(1,1); f.Parent=widget; UI.PromptFrame=f
    local p = Instance.new("UIPadding",f); p.PaddingLeft,p.PaddingRight,p.PaddingTop,p.PaddingBottom=UDim.new(0,15),UDim.new(0,15),UDim.new(0,15),UDim.new(0,15)
    local l = Instance.new("UIListLayout",f); l.Padding=UDim.new(0,15); l.SortOrder=Enum.SortOrder.LayoutOrder; l.HorizontalAlignment=Enum.HorizontalAlignment.Center; l.VerticalAlignment=Enum.VerticalAlignment.Center
    local t = Instance.new("TextLabel",f); t.Name="Title"; t.LayoutOrder=1; t.Text=title; t.Size=UDim2.new(1,0,0,24); t.Font=Enum.Font.GothamBold; t.TextSize=22; t.BackgroundTransparency=1; t.TextXAlignment=Enum.TextXAlignment.Center; UI.PromptTitle=t
    local i = Instance.new("TextLabel",f); i.Name="Label"; i.LayoutOrder=2; i.Text=text; i.Size=UDim2.new(1,0,0,60); i.Font=Enum.Font.Gotham; i.TextSize=14; i.TextWrapped=true; i.BackgroundTransparency=1; i.TextXAlignment=Enum.TextXAlignment.Center; UI.PromptText=i
    local bf = Instance.new("Frame",f); bf.Name="ButtonFrame"; bf.LayoutOrder=3; bf.Size=UDim2.new(1,0,0,40); bf.BackgroundTransparency=1
    local bl = Instance.new("UIListLayout",bf); bl.FillDirection=Enum.FillDirection.Horizontal; bl.HorizontalAlignment=Enum.HorizontalAlignment.Center; bl.Padding=UDim.new(0,10)
    local yb = Instance.new("TextButton",bf); yb.Name="Primary"; yb.Text="Yes"; yb.Size=UDim2.new(0,100,1,0); UI.PromptYes=yb; yb.MouseButton1Click:Connect(function() onYes(); widget.Enabled=false end)
    local nb = Instance.new("TextButton",bf); nb.Name="Danger"; nb.Text="No"; nb.Size=UDim2.new(0,100,1,0); UI.PromptNo=nb; nb.MouseButton1Click:Connect(function() onNo(); widget.Enabled=false end)
    applyTheme(Config.THEME)
    widget.Enabled = true
end

function findImageAsset(assetId) if not assetId then return nil end; local assetFolder = ReplicatedStorage:FindFirstChild(Config.ASSET_FOLDER_NAME); if not assetFolder then return nil end; local image = assetFolder:FindFirstChild(assetId, true); if image then if image:IsA("ImageLabel") then return image.Image elseif image:IsA("ImageButton") then return image.Image elseif image:IsA("Decal") then return image.Texture end end; return nil end
function createBehaviorScript(element, tags) local s=[[local b=script.Parent;local c=b:GetAttribute;local n=c(b,"NormalImage");local h=c(b,"HoverImage");local p=c(b,"ClickedImage");local d=c(b,"DisabledImage");local t=c(b,"IsToggled")or false;local e=c(b,"IsEnabled")or true;local function u()if not e then b.Image=d or n;return end;if t and p then b.Image=p elseif c(b,"IsHovering")and h then b.Image=h else b.Image=n end end;b.MouseEnter:Connect(function()b:SetAttribute("IsHovering",true)u()end)b.MouseLeave:Connect(function()b:SetAttribute("IsHovering",false)u()end)b.MouseButton1Click:Connect(function()if not e then return end;if c(b,"IsToggleable")then t=not t;b:SetAttribute("IsToggled",t)end;u()end)b:GetAttributeChangedSignal("IsEnabled"):Connect(function()e=c(b,"IsEnabled")u()end)u()]];local S=Instance.new("LocalScript");S.Name="ButtonBehavior";S.Source=s;element:SetAttribute("NormalImage",element.Image);element:SetAttribute("HoverImage",findImageAsset(element.Name.."_hover"));element:SetAttribute("ClickedImage",findImageAsset(element.Name.."_clicked"));element:SetAttribute("DisabledImage",findImageAsset(element.Name.."_disabled"));element:SetAttribute("IsToggleable",table.find(tags,"toggled"));element:SetAttribute("IsEnabled",not table.find(tags,"disabled"));S.Parent=element end
function applyFills(element, fills) if not fills or #fills == 0 then element.BackgroundTransparency = 1; return end; local fill = fills[1]; local opacity = fill.opacity or 1; if fill.type == "SOLID" then element.BackgroundColor3 = Color3.new(fill.color.r, fill.color.g, fill.color.b); element.BackgroundTransparency = 1 - opacity elseif string.find(fill.type, "GRADIENT") then local gradient = Instance.new("UIGradient"); local colorStops = {}; for _, stop in ipairs(fill.gradientStops) do table.insert(colorStops, ColorSequenceKeypoint.new(stop.position, Color3.new(stop.color.r, stop.color.g, stop.color.b))) end; gradient.Color = ColorSequence.new(colorStops); gradient.Parent = element end end
function applyStrokes(element, strokes, weight) if not strokes or #strokes == 0 then return end; local stroke = strokes[1]; local uiStroke = Instance.new("UIStroke"); uiStroke.Thickness = weight or 1; if stroke.type == "SOLID" then uiStroke.Color = Color3.new(stroke.color.r, stroke.color.g, stroke.color.b) end; uiStroke.Parent = element end
function applyConstraints(element, constraints) if not constraints then return end; local x, y = 0, 0; if constraints.horizontal == "CENTER" then x = 0.5 elseif constraints.horizontal == "RIGHT" then x = 1 elseif constraints.horizontal == "SCALE" then x = 0.5 end; if constraints.vertical == "CENTER" then y = 0.5 elseif constraints.vertical == "BOTTOM" then y = 1 elseif constraints.vertical == "SCALE" then y = 0.5 end; element.AnchorPoint = Vector2.new(x, y); element.Position = UDim2.new(x, element.Position.X.Offset, y, element.Position.Y.Offset) end
local propertyAppliers = {}; propertyAppliers.Default = function(element, data) local props = data.properties; element.Name = data.name; element.Visible = props.visible; element.Position = UDim2.fromOffset(props.position.x, props.position.y); element.Size = UDim2.fromOffset(props.size.x, props.size.y); element.Rotation = props.rotation; element.ClipsDescendants = data.type == 'FRAME'; applyFills(element, props.fills); applyStrokes(element, props.strokes, props.strokeWeight); if props.cornerRadius and props.cornerRadius > 0 then local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, props.cornerRadius); c.Parent = element end; applyConstraints(element, props.constraints) end; propertyAppliers.TEXT = function(element, data) propertyAppliers.Default(element, data); local props = data.properties; element.Text = props.characters; element.Font = (props.fontName and fontMap[props.fontName.family]) or Enum.Font.SourceSans; element.TextSize = props.fontSize; element.TextWrapped = true; if props.fills and #props.fills > 0 then local fill = props.fills[1]; element.TextColor3 = Color3.new(fill.color.r, fill.color.g, fill.color.b); element.TextTransparency = 1 - (fill.opacity or 1) end; element.TextXAlignment = props.textAlignHorizontal; element.TextYAlignment = props.textAlignVertical end; propertyAppliers.Image = function(element, data) if data.assetId then local imageId = findImageAsset(data.assetId); if imageId and imageId ~= "" then element.Image = imageId end; element.BackgroundTransparency = 1 end end
local elementCreators = {}; elementCreators.Default = function(data) local tags=data.tags; if data.assetId and data.assetId ~= "" then if table.find(tags,"button") then return Instance.new("ImageButton") else return Instance.new("ImageLabel") end end; local element; if table.find(tags,"button") then element=Instance.new("ImageButton") elseif table.find(tags,"image") then element=Instance.new("ImageLabel") elseif table.find(tags,"vpf") then element=Instance.new("ViewportFrame") elseif table.find(tags,"canvas") then element=Instance.new("CanvasGroup") elseif table.find(tags,"scroll") then element=Instance.new("ScrollingFrame");element.ScrollingDirection=table.find(tags,"scrollx")and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y else element=Instance.new("Frame") end; if table.find(tags,"box") then Instance.new("UIListLayout").Parent=element end; return element end; elementCreators.TEXT = function(data) return Instance.new("TextLabel") end
function createFromData(data, parent) local element = (elementCreators[data.type] or elementCreators.Default)(data);(propertyAppliers[data.type] or propertyAppliers.Default)(element, data); if element:IsA("ImageLabel") or element:IsA("ImageButton") then propertyAppliers.Image(element, data) end; if Config.CREATE_BEHAVIOR_SCRIPTS and table.find(data.tags, "button") then createBehaviorScript(element, data.tags) end; element.Parent = parent; if data.children then for _, childData in ipairs(data.children) do createFromData(childData, element) end end; return element end
function collectAssetIds(dataTable) local ids = {}; function traverse(data) for _, nodeData in ipairs(data) do if nodeData.assetId and nodeData.assetId ~= "" and not ids[nodeData.assetId] then ids[nodeData.assetId] = true end; if nodeData.children and #nodeData.children > 0 then traverse(nodeData.children) end end end; traverse(dataTable); local idList = {}; for id,_ in pairs(ids) do table.insert(idList, id) end; return idList end
function verifyAssets(assetIds) local missing = {}; local assetFolder = ReplicatedStorage:FindFirstChild(Config.ASSET_FOLDER_NAME); if not assetFolder then return assetIds, "Asset folder '"..Config.ASSET_FOLDER_NAME.."' not found in ReplicatedStorage." end; for _,id in ipairs(assetIds) do if not findImageAsset(id) then table.insert(missing, id) end end; if #missing > 0 then return missing, "Missing assets: " .. table.concat(missing, ", ") else return {}, nil end end
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

local promptWidgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 400, 240, 400, 240)
local promptWidget = plugin:CreateDockWidgetPluginGui("FramifyPrompt", promptWidgetInfo)
promptWidget.Title = "Framify Prompt"

applyTheme(Config.THEME)

importBtn.MouseButton1Click:Connect(function()
    statusLabel.Text = ""
    local mappingString = mappingTextBox.Text
    if mappingString == "" then statusLabel.Text = "Error: Mapping string cannot be empty."; return end
    local success, data = pcall(function() return HttpService:JSONDecode(mappingString) end)
    if not success then statusLabel.Text = "Error: Invalid mapping string."; return end
    local requiredAssets = collectAssetIds(data)
    if #requiredAssets > 0 then
        local missingAssets, err = verifyAssets(requiredAssets)
        if #missingAssets > 0 then
            statusLabel.Text = "Error: " .. err
            return
        end
        populatePromptUI(promptWidget, "Image Assets Found", "This UI requires images that appear to be uploaded. Proceed with import?",
            function() performImport(data, statusLabel) end,
            function() statusLabel.Text = "Import cancelled." end
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
