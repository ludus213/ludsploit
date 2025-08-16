-- Framify Importer
-- Version: 1.2.0
-- This script contains the full logic for the Framify Roblox Studio plugin.

--------------------------------------------------------------------------------
--[[ CONFIGURATION ]]--
--------------------------------------------------------------------------------
local TARGET_SCREEN_GUI = "FramifyImport"
local ASSET_FOLDER_NAME = "FramifyAssets" -- The name of the folder in ReplicatedStorage to search for images
local CREATE_BEHAVIOR_SCRIPTS = true
local AUTO_CENTER_UI = true

--------------------------------------------------------------------------------
--[[ SERVICES ]]--
--------------------------------------------------------------------------------
local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--------------------------------------------------------------------------------
--[[ PLUGIN UI SETUP (Polished Version) ]]--
--------------------------------------------------------------------------------
local toolbar = plugin:CreateToolbar("Framify")
local importButton = toolbar:CreateButton("Import UI", "Import UI from Framify mapping string", "rbxassetid://123456789")
local widgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, false, 320, 500, 320, 500)
local mainWidget = plugin:CreateDockWidgetPluginGui("FramifyImporter", widgetInfo)
mainWidget.Title = "Framify Importer"

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(44, 44, 44)
mainFrame.Parent = mainWidget

local mainLayout = Instance.new("UIListLayout")
mainLayout.Padding = UDim.new(0, 15)
mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
mainLayout.Parent = mainFrame
local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 15)
padding.PaddingRight = UDim.new(0, 15)
padding.PaddingTop = UDim.new(0, 15)
padding.PaddingBottom = UDim.new(0, 15)
padding.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Text = "Framify Importer"
titleLabel.Size = UDim2.new(1, 0, 0, 24)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 20
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.BackgroundTransparency = 1
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.LayoutOrder = 1
titleLabel.Parent = mainFrame

local instructionLabel = Instance.new("TextLabel")
instructionLabel.Text = "Paste the mapping string from the Figma plugin below."
instructionLabel.Size = UDim2.new(1, 0, 0, 35)
instructionLabel.Font = Enum.Font.Gotham
instructionLabel.TextSize = 14
instructionLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
instructionLabel.TextWrapped = true
instructionLabel.BackgroundTransparency = 1
instructionLabel.TextXAlignment = Enum.TextXAlignment.Left
instructionLabel.LayoutOrder = 2
instructionLabel.Parent = mainFrame

local textScrollFrame = Instance.new("ScrollingFrame")
textScrollFrame.Size = UDim2.new(1, 0, 1, -150)
textScrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
textScrollFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
textScrollFrame.BorderSizePixel = 1
textScrollFrame.LayoutOrder = 3
textScrollFrame.Parent = mainFrame

local mappingTextBox = Instance.new("TextBox")
mappingTextBox.Size = UDim2.new(1, 0, 0, 0)
mappingTextBox.AutomaticSize = Enum.AutomaticSize.Y
mappingTextBox.Font = Enum.Font.Code
mappingTextBox.TextSize = 13
mappingTextBox.MultiLine = true
mappingTextBox.ClearTextOnFocus = false
mappingTextBox.PlaceholderText = "Paste mapping string here..."
mappingTextBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mappingTextBox.TextColor3 = Color3.fromRGB(240, 240, 240)
mappingTextBox.TextXAlignment = Enum.TextXAlignment.Left
mappingTextBox.TextYAlignment = Enum.TextYAlignment.Top
mappingTextBox.Parent = textScrollFrame
mappingTextBox:GetPropertyChangedSignal("Text"):Connect(function()
    textScrollFrame.CanvasSize = UDim2.new(0, 0, 0, mappingTextBox.AbsoluteSize.Y)
end)

local importGuiButton = Instance.new("TextButton")
importGuiButton.Name = "ImportButton"
importGuiButton.Text = "Import"
importGuiButton.Size = UDim2.new(1, 0, 0, 40)
importGuiButton.Font = Enum.Font.GothamBold
importGuiButton.TextSize = 16
importGuiButton.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
importGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
importGuiButton.LayoutOrder = 4
Instance.new("UICorner", importGuiButton).CornerRadius = UDim.new(0, 6)
importGuiButton.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Text = ""
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
statusLabel.BackgroundTransparency = 1
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.LayoutOrder = 5
statusLabel.Parent = mainFrame

--------------------------------------------------------------------------------
--[[ CORE LOGIC ]]--
--------------------------------------------------------------------------------
local fontMap = { ['Arial'] = Enum.Font.Legacy, ['Roboto'] = Enum.Font.SourceSans, ['Inter'] = Enum.Font.SourceSans, ['Gotham'] = Enum.Font.Gotham }
local assetFolder = ReplicatedStorage:FindFirstChild(ASSET_FOLDER_NAME)

function findImageAsset(assetId)
    if not assetId then return "" end
    if not assetFolder then
        warn("Framify: Asset folder '" .. ASSET_FOLDER_NAME .. "' not found in ReplicatedStorage.")
        return ""
    end
    local image = assetFolder:FindFirstChild(assetId, true)
    if image then
        if image:IsA("ImageLabel") then return image.Image
        elseif image:IsA("ImageButton") then return image.Image
        elseif image:IsA("Decal") then return image.Texture
        end
    end
    return ""
end

function createPrompt(title, text, onYes, onNo)
    local promptFrame = Instance.new("Frame")
    promptFrame.Name = "ConfirmationPrompt"
    promptFrame.Size = UDim2.new(1, 0, 1, 0)
    promptFrame.BackgroundColor3 = Color3.fromRGB(0,0,0)
    promptFrame.BackgroundTransparency = 0.7
    promptFrame.ZIndex = 100
    promptFrame.Parent = mainFrame
    -- ... build a full prompt UI ...
    -- For simplicity here, we'll just use the status label and disable the main button
    statusLabel.Text = text .. " (See output for details)"
    warn(title .. ": " .. text)
    -- In a real scenario, this would create a modal dialog.
    -- The core logic below simulates the user clicking "Yes" or "No".
    return function(userChoice)
        promptFrame:Destroy()
        if userChoice then onYes() else onNo() end
    end
end

function hasAssetIds(dataTable)
    for _, nodeData in ipairs(dataTable) do
        if nodeData.assetId and nodeData.assetId ~= "" then return true end
        if nodeData.children and #nodeData.children > 0 then
            if hasAssetIds(nodeData.children) then return true end
        end
    end
    return false
end

function performImport(data)
    showStatus("Importing...", false)
    local targetGui = StarterGui:FindFirstChild(TARGET_SCREEN_GUI); if targetGui then targetGui:Destroy() end
    targetGui = Instance.new("ScreenGui"); targetGui.Name = TARGET_SCREEN_GUI
    local importParent = targetGui
    if AUTO_CENTER_UI then
        local mainContainer = Instance.new("Frame"); mainContainer.Name = "ImportContainer"; mainContainer.BackgroundTransparency = 1; mainContainer.AnchorPoint = Vector2.new(0.5, 0.5); mainContainer.Position = UDim2.fromScale(0.5, 0.5)
        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        for _, nodeData in ipairs(data) do local props = nodeData.properties; minX = math.min(minX, props.position.x); minY = math.min(minY, props.position.y); maxX = math.max(maxX, props.position.x + props.size.x); maxY = math.max(maxY, props.position.y + props.size.y) end
        mainContainer.Size = UDim2.fromOffset(maxX - minX, maxY - minY)
        for _, nodeData in ipairs(data) do nodeData.properties.position.x = nodeData.properties.position.x - minX; nodeData.properties.position.y = nodeData.properties.position.y - minY end
        mainContainer.Parent = targetGui; importParent = mainContainer
    end
    for _, nodeData in ipairs(data) do createFromData(nodeData, importParent) end
    targetGui.Parent = StarterGui; Selection:Set({targetGui})
    showStatus("Import successful!", false)
end

-- (All creator and applier functions remain the same)
function createBehaviorScript(element, tags) local scriptSource = [[ local button = script.Parent; local config = script:WaitForChild("Config"); local normalImage = config:GetAttribute("NormalImage"); local hoverImage = config:GetAttribute("HoverImage"); local clickedImage = config:GetAttribute("ClickedImage"); local disabledImage = config:GetAttribute("DisabledImage"); local isToggled = button:GetAttribute("IsToggled") or false; local isEnabled = button:GetAttribute("IsEnabled") or true; local function updateImage() if not isEnabled then button.Image = disabledImage or normalImage; return end; if isToggled and clickedImage then button.Image = clickedImage elseif button:GetAttribute("IsHovering") and hoverImage then button.Image = hoverImage else button.Image = normalImage end end; button.MouseEnter:Connect(function() button:SetAttribute("IsHovering", true); updateImage() end); button.MouseLeave:Connect(function() button:SetAttribute("IsHovering", false); updateImage() end); button.MouseButton1Click:Connect(function() if not isEnabled then return end; if button:GetAttribute("IsToggleable") then isToggled = not isToggled; button:SetAttribute("IsToggled", isToggled) end; updateImage() end); button:GetAttributeChangedSignal("IsEnabled"):Connect(function() isEnabled = button:GetAttribute("IsEnabled"); updateImage() end); updateImage() ]]; local script = Instance.new("LocalScript"); script.Name = "ButtonBehavior"; script.Source = scriptSource; local config = Instance.new("Configuration"); config.Name = "Config"; config.Parent = script; config:SetAttribute("NormalImage", element.Image); if table.find(tags, "hover") then config:SetAttribute("HoverImage", findImageAsset(element.Name .. "_hover")) end; if table.find(tags, "clicked") then config:SetAttribute("ClickedImage", findImageAsset(element.Name .. "_clicked")) end; if table.find(tags, "disabled") then config:SetAttribute("DisabledImage", findImageAsset(element.Name .. "_disabled")) end; element:SetAttribute("IsToggleable", table.find(tags, "toggled")); element:SetAttribute("IsEnabled", not table.find(tags, "disabled")); script.Parent = element end
elementCreators.Default = function(data) local tags = data.tags; local element; if table.find(tags, "button") then element = Instance.new("ImageButton") elseif table.find(tags, "image") then element = Instance.new("ImageLabel") elseif table.find(tags, "vpf") then element = Instance.new("ViewportFrame") elseif table.find(tags, "canvas") then element = Instance.new("CanvasGroup") elseif table.find(tags, "scroll") then element = Instance.new("ScrollingFrame"); element.ScrollingDirection = table.find(tags, "scrollx") and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y else element = Instance.new("Frame") end; if table.find(tags, "box") then Instance.new("UIListLayout").Parent = element end; return element end
elementCreators.TEXT = function(data) return Instance.new("TextLabel") end
function applyFills(element, fills) if not fills or #fills == 0 then element.BackgroundTransparency = 1; return end; local fill = fills[1]; local opacity = fill.opacity or 1; if fill.type == "SOLID" then element.BackgroundColor3 = Color3.new(fill.color.r, fill.color.g, fill.color.b); element.BackgroundTransparency = 1 - opacity elseif string.find(fill.type, "GRADIENT") then local gradient = Instance.new("UIGradient"); local colorStops = {}; for _, stop in ipairs(fill.gradientStops) do table.insert(colorStops, ColorSequenceKeypoint.new(stop.position, Color3.new(stop.color.r, stop.color.g, stop.color.b))) end; gradient.Color = ColorSequence.new(colorStops); gradient.Parent = element end end
function applyStrokes(element, strokes, weight) if not strokes or #strokes == 0 then return end; local stroke = strokes[1]; local uiStroke = Instance.new("UIStroke"); uiStroke.Thickness = weight or 1; if stroke.type == "SOLID" then uiStroke.Color = Color3.new(stroke.color.r, stroke.color.g, stroke.color.b) end; uiStroke.Parent = element end
function applyConstraints(element, constraints) if not constraints then return end; local x, y = 0, 0; if constraints.horizontal == "CENTER" then x = 0.5 elseif constraints.horizontal == "RIGHT" then x = 1 elseif constraints.horizontal == "SCALE" then x = 0.5 end; if constraints.vertical == "CENTER" then y = 0.5 elseif constraints.vertical == "BOTTOM" then y = 1 elseif constraints.vertical == "SCALE" then y = 0.5 end; element.AnchorPoint = Vector2.new(x, y); element.Position = UDim2.new(x, element.Position.X.Offset, y, element.Position.Y.Offset) end
propertyAppliers.Default = function(element, data) local props = data.properties; element.Name = data.name; element.Visible = props.visible; element.Position = UDim2.fromOffset(props.position.x, props.position.y); element.Size = UDim2.fromOffset(props.size.x, props.size.y); element.Rotation = props.rotation; element.ClipsDescendants = data.type == 'FRAME'; applyFills(element, props.fills); applyStrokes(element, props.strokes, props.strokeWeight); if props.cornerRadius and props.cornerRadius > 0 then local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, props.cornerRadius); c.Parent = element end; applyConstraints(element, props.constraints) end
propertyAppliers.TEXT = function(element, data) propertyAppliers.Default(element, data); local props = data.properties; element.Text = props.characters; element.Font = (props.fontName and fontMap[props.fontName.family]) or Enum.Font.SourceSans; element.TextSize = props.fontSize; element.TextWrapped = true; if props.fills and #props.fills > 0 then local fill = props.fills[1]; element.TextColor3 = Color3.new(fill.color.r, fill.color.g, fill.color.b); element.TextTransparency = 1 - (fill.opacity or 1) end; element.TextXAlignment = props.textAlignHorizontal; element.TextYAlignment = props.textAlignVertical end
propertyAppliers.Image = function(element, data) if data.assetId then element.Image = findImageAsset(data.assetId); element.BackgroundTransparency = 1 end end
function createFromData(data, parent) local element = (elementCreators[data.type] or elementCreators.Default)(data);(propertyAppliers[data.type] or propertyAppliers.Default)(element, data); if element:IsA("ImageLabel") or element:IsA("ImageButton") then propertyAppliers.Image(element, data) end; if CREATE_BEHAVIOR_SCRIPTS and table.find(data.tags, "button") then createBehaviorScript(element, data.tags) end; element.Parent = parent; if data.children then for _, childData in ipairs(data.children) do createFromData(childData, element) end end; return element end
function showStatus(message, isError) if isError then statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100) else statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100) end; statusLabel.Text = message end

importButton.Click:Connect(function() mainWidget.Enabled = not mainWidget.Enabled end)
importGuiButton.MouseButton1Click:Connect(function()
    showStatus("", false)
    local mappingString = mappingTextBox.Text
    if mappingString == "" then showStatus("Mapping string cannot be empty.", true); return end

    local success, data = pcall(function() return HttpService:JSONDecode(mappingString) end)
    if not success then showStatus("Error: Invalid mapping string.", true); return end

    if hasAssetIds(data) then
        -- For simplicity, this example uses a simple status message.
        -- A real implementation would involve creating a proper modal dialog.
        showStatus("Image assets required. Have you uploaded them to " .. ASSET_FOLDER_NAME .. "?", true)

        local response = createPrompt(
            "Image Assets Required",
            "This import requires image assets. Have you unzipped the file from Figma and uploaded the images to the '" .. ASSET_FOLDER_NAME .. "' folder in ReplicatedStorage?",
            function() performImport(data) end, -- onYes
            function() showStatus("Import cancelled. Please upload images first.", true) end -- onNo
        )
        -- This is a placeholder for a real UI interaction.
        -- In this simulated environment, we will assume the user clicks "Yes".
        response(true)
    else
        performImport(data)
    end
end)

mainWidget.Enabled = false
