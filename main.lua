local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

local rawUrl = "https://raw.githubusercontent.com/ikkybarry-beep/KorD/refs/heads/main/GUI.lua"
local success, UI = pcall(function()
    return loadstring(game:HttpGet(rawUrl))()
end)

if not success or not UI then
    warn("[Barry] Gagal memuat GUI.lua!")
    return
end

local scannedLocations = {}
local scannedPrompts = {}
local currentTpIndex = 0
local isScanning = false
local cancelRequested = false
local executableGuiScript = ""

local function typeWriteText(labelObject, fullText, delayTime)
    delayTime = delayTime or 0.005
    labelObject.Text = ""
    for i = 1, #fullText do
        if cancelRequested then
            labelObject.Text = fullText
            break
        end
        labelObject.Text = string.sub(fullText, 1, i)
        if i % 3 == 0 then
            task.wait(delayTime)
        end
    end
end

local isMinimized = false
UI.minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    UI.contentLeft.Visible = not isMinimized
    UI.mainFrame.Size = isMinimized and UDim2.new(0, 260, 0, 24) or UDim2.new(0, 260, 0, 360)
    UI.titleLabel.Text = isMinimized and "[Barry Scanner]" or "Barry | Safe Step Scanner"
end)

UI.resCloseBtn.MouseButton1Click:Connect(function()
    UI.resultFrame.Visible = false
end)

local function generateStandaloneGuiCode(modeTitle)
    local code = [[
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

if CoreGui:FindFirstChild("CustomTpGui") then
    CoreGui.CustomTpGui:Destroy()
end

local sg = Instance.new("ScreenGui")
sg.Name = "CustomTpGui"
sg.ResetOnSpawn = false
sg.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 280)
frame.Position = UDim2.new(0.8, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(0, 255, 204)
frame.Active = true
frame.Draggable = true
frame.Parent = sg

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -25, 0, 25)
title.Position = UDim2.new(0, 5, 0, 0)
title.Text = "TP Menu: ]] .. modeTitle .. [["
title.TextColor3 = Color3.fromRGB(0, 255, 204)
title.TextSize = 10
title.Font = Enum.Font.SourceSansBold
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 20, 0, 20)
close.Position = UDim2.new(1, -22, 0, 2)
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
close.Font = Enum.Font.SourceSansBold
close.Parent = frame
close.MouseButton1Click:Connect(function() sg:Destroy() end)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -35)
scroll.Position = UDim2.new(0, 5, 0, 30)
scroll.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
scroll.ScrollBarThickness = 5
scroll.Parent = frame

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 3)
layout.Parent = scroll

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end)

local function safeTp(pos)
    if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local root = localPlayer.Character.HumanoidRootPart
        local conn = RunService.Stepped:Connect(function()
            if localPlayer.Character then
                for _, p in ipairs(localPlayer.Character:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
        root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
        task.wait(1.5)
        conn:Disconnect()
    end
end
]]

    for i, loc in ipairs(scannedLocations) do
        local btnName = string.gsub(loc.name, '["\n\r]', "")
        code = code .. string.format([[
local btn%d = Instance.new("TextButton")
btn%d.Size = UDim2.new(1, 0, 0, 22)
btn%d.Text = "%d. %s"
btn%d.TextColor3 = Color3.fromRGB(255, 255, 255)
btn%d.BackgroundColor3 = Color3.fromRGB(35, 45, 60)
btn%d.Font = Enum.Font.SourceSans
btn%d.TextSize = 9
btn%d.TextWrapped = true
btn%d.Parent = scroll
btn%d.MouseButton1Click:Connect(function() safeTp(Vector3.new(%.1f, %.1f, %.1f)) end)
]], i, i, i, i, btnName, i, i, i, i, i, i, loc.pos.X, loc.pos.Y, loc.pos.Z)
    end

    return code
end

local function runScan(mode)
    if isScanning then return end
    isScanning = true
    cancelRequested = false
    scannedLocations = {}
    scannedPrompts = {}
    currentTpIndex = 0
    executableGuiScript = ""
    
    typeWriteText(UI.infoLog, "> Initializing scan system...\n> Filtering objects in workspace...\n> Click '🛑 CANCEL SCAN' to stop.", 0.002)
    typeWriteText(UI.resultText, "[SYS LOG] Scanning workspace descendants...", 0.002)
    task.wait(0.02)
    
    local scannedCount = 0
    local descendants = workspace:GetDescendants()
    
    for _, obj in ipairs(descendants) do
        if cancelRequested then break end
        
        scannedCount = scannedCount + 1
        if scannedCount % 500 == 0 then
            task.wait()
        end
        
        local lowerName = obj.Name:lower()
        local isMatch = false
        local targetObject = nil
        local extraInfo = ""
        
        if mode == "code" then
            if lowerName:find("sspy") or lowerName:find("code") or lowerName:find("pass") or lowerName:find("secret") or lowerName:find("keycard") or lowerName:find("doorcode") then
                if obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("StringValue") or obj:IsA("IntValue") then
                    isMatch = true
                    targetObject = obj:IsA("ValueBase") and obj.Parent or obj
                    if obj:IsA("StringValue") or obj:IsA("IntValue") then
                        extraInfo = " [Val: " .. tostring(obj.Value) .. "]"
                    end
                end
            end
        elseif mode == "finish" then
            if lowerName:find("finish") or lowerName:find("win") or lowerName:find("end") 
               or lowerName:find("victory") or lowerName:find("escape") or lowerName:find("exit") 
               or lowerName:find("trophy") or lowerName:find("goal") or lowerName:find("badge") then
                if obj:IsA("BasePart") or obj:IsA("Model") then isMatch = true targetObject = obj end
            end
        elseif mode == "checkpoint" then
            if (lowerName:find("checkpoint") or lowerName:find("stage") or lowerName:find("spawn"))
               and not lowerName:find("finish") and not lowerName:find("end") then
                if obj:IsA("BasePart") or obj:IsA("Model") then isMatch = true targetObject = obj end
            end
        elseif mode == "item" then
            if lowerName:find("coin") or lowerName:find("loot") or lowerName:find("money") 
               or lowerName:find("gem") or lowerName:find("key") or lowerName:find("star") or lowerName:find("part") then
                if obj:IsA("BasePart") or obj:IsA("Model") then isMatch = true targetObject = obj end
            end
        elseif mode == "prompts" then
            if obj:IsA("ClickDetector") or obj:IsA("ProximityPrompt") then
                isMatch = true targetObject = obj.Parent
                table.insert(scannedPrompts, obj)
            end
        elseif mode == "safe" then
            if lowerName:find("safezone") or lowerName:find("safe_zone") or lowerName:find("nocheat") 
               or lowerName:find("bypas") or lowerName:find("afkzone") or lowerName:find("nodetect") then
                if obj:IsA("BasePart") or obj:IsA("Model") then isMatch = true targetObject = obj end
            end
        end
        
        if isMatch and targetObject then
            local pos = targetObject:IsA("Model") and targetObject:GetPivot().Position or (targetObject:IsA("BasePart") and targetObject.Position or nil)
            if pos then
                local isDuplicate = false
                for _, loc in ipairs(scannedLocations) do
                    if (loc.pos - pos).Magnitude < 1 then
                        isDuplicate = true
                        break
                    end
                end
                if not isDuplicate then
                    table.insert(scannedLocations, {name = targetObject.Name .. extraInfo, pos = pos})
                end
            end
        end
    end
    
    if cancelRequested then
        typeWriteText(UI.resultText, "=== SCAN CANCELLED ===\n\nPartial results found: " .. #scannedLocations, 0.002)
        typeWriteText(UI.infoLog, string.format("Scan Cancelled!\n\nCategory: %s\nFound: %d", mode:upper(), #scannedLocations), 0.002)
    else
        local report = string.format("=== SCANNED RESULTS (%d) ===\n\n", #scannedLocations)
        if #scannedLocations > 0 then
            for i, loc in ipairs(scannedLocations) do
                report = report .. string.format("%d. %s -> X: %.1f, Y: %.1f, Z: %.1f\n", i, loc.name, loc.pos.X, loc.pos.Y, loc.pos.Z)
            end
            executableGuiScript = generateStandaloneGuiCode(mode:upper())
        else
            report = report .. "No matching locations found.\n"
            executableGuiScript = "-- No target locations found"
        end
        
        task.spawn(function()
            typeWriteText(UI.resultText, report, 0.001)
        end)
        
        typeWriteText(UI.infoLog, string.format("Scan Complete!\n\nCategory: %s\nTotal Found: %d\n\nGUI Script Ready!", mode:upper(), #scannedLocations), 0.002)
    end
    
    isScanning = false
    cancelRequested = false
end

UI.firePromptsBtn.MouseButton1Click:Connect(function()
    if #scannedPrompts == 0 then
        typeWriteText(UI.infoLog, "No Prompts Found!\nRun SCAN PROMPTS first.", 0.002)
        return
    end
    local firedCount = 0
    for _, prompt in ipairs(scannedPrompts) do
        if prompt:IsA("ClickDetector") then
            fireclickdetector(prompt)
            firedCount = firedCount + 1
        elseif prompt:IsA("ProximityPrompt") then
            fireproximityprompt(prompt)
            firedCount = firedCount + 1
        end
    end
    typeWriteText(UI.infoLog, string.format("Auto-Fired %d Prompts Successfully!", firedCount), 0.002)
end)

UI.cancelBtn.MouseButton1Click:Connect(function()
    if isScanning then
        cancelRequested = true
        typeWriteText(UI.infoLog, "Cancelling scan process...", 0.002)
    end
end)

local function safeTeleport(targetPos)
    if not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local root = localPlayer.Character.HumanoidRootPart
    task.spawn(function()
        local noclipConnection = RunService.Stepped:Connect(function()
            if localPlayer.Character then
                for _, part in ipairs(localPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
        root.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
        task.wait(1.5)
        noclipConnection:Disconnect()
    end)
end

local function teleportToIndex(index)
    if #scannedLocations == 0 then return end
    local target = scannedLocations[index]
    safeTeleport(target.pos)
    typeWriteText(UI.infoLog, string.format("Teleported [%d/%d]:\nName: %s\nX: %.1f, Y: %.1f, Z: %.1f", index, #scannedLocations, target.name, target.pos.X, target.pos.Y, target.pos.Z), 0.002)
end

UI.tpNextBtn.MouseButton1Click:Connect(function()
    if #scannedLocations > 0 then
        currentTpIndex = currentTpIndex + 1
        if currentTpIndex > #scannedLocations then currentTpIndex = 1 end
        teleportToIndex(currentTpIndex)
    end
end)

UI.tpPrevBtn.MouseButton1Click:Connect(function()
    if #scannedLocations > 0 then
        currentTpIndex = currentTpIndex - 1
        if currentTpIndex < 1 then currentTpIndex = #scannedLocations end
        teleportToIndex(currentTpIndex)
    end
end)

UI.btnCodeItem.MouseButton1Click:Connect(function() runScan("code") end)
UI.btnFinish.MouseButton1Click:Connect(function() runScan("finish") end)
UI.btnCheckpoint.MouseButton1Click:Connect(function() runScan("checkpoint") end)
UI.btnItems.MouseButton1Click:Connect(function() runScan("item") end)
UI.btnPrompts.MouseButton1Click:Connect(function() runScan("prompts") end)
UI.btnSafeZone.MouseButton1Click:Connect(function() runScan("safe") end)

UI.copyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        local textToCopy = executableGuiScript ~= "" and executableGuiScript or UI.resultText.Text
        setclipboard(textToCopy)
        UI.copyBtn.Text = "✅ COPIED!"
        task.wait(1.2)
        UI.copyBtn.Text = "📋 COPY"
    end
end)

UI.closeBtn.MouseButton1Click:Connect(function()
    UI.screenGui:Destroy()
end)

print("[Barry] Animated Typing Scanner Loaded!")
