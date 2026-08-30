-- ==========================================
-- TÍN HUB | MAIN COMBINED SCRIPT (V5.5 FULL UPDATED UI)
-- ==========================================

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("RuneWeaponSkillRemote", 10)

-- ==========================================
-- 1. QUÉT FOLDER SKILL TỪ GITHUB
-- ==========================================
local REPO_OWNER = "tinvn1"
local REPO_NAME = "ht1708"
local FOLDER_PATH = "SkillPatterns"
local API_URL = string.format("https://api.github.com/repos/%s/%s/contents/%s", REPO_OWNER, REPO_NAME, FOLDER_PATH)

local SkillList = {}
local SkillDownloadUrls = {}

local function fetchSkillListFromGitHub()
    local success, response = pcall(function() return game:HttpGet(API_URL) end)
    if success and response then
        local decodeSuccess, fileDataList = pcall(function() return HttpService:JSONDecode(response) end)
        if decodeSuccess and type(fileDataList) == "table" then
            for _, fileItem in ipairs(fileDataList) do
                if fileItem.type == "file" and fileItem.name:match("%.lua$") then
                    local skillName = fileItem.name:gsub("%.lua$", "")
                    table.insert(SkillList, skillName)
                    SkillDownloadUrls[skillName] = fileItem.download_url
                end
            end
        end
    end
end
fetchSkillListFromGitHub()

local SkillDropdownOptions = {"None"}
for _, name in ipairs(SkillList) do table.insert(SkillDropdownOptions, name) end

-- ==========================================
-- 2. KHỞI TẠO UI FLUENT & SAVE MANAGER
-- ==========================================
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Tín Hub | Mobile & PC",
    SubTitle = "v5.5 Dynamic UI Upgrade",
    TabWidth = 135,
    Size = UDim2.fromOffset(580, 360),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Slots     = Window:AddTab({ Title = "Skill Slots", Icon = "zap" }),
    Keyboard  = Window:AddTab({ Title = "Keybinds", Icon = "keyboard" }),
    Islands   = Window:AddTab({ Title = "Auto Islands", Icon = "map-pin" }),
    Structure = Window:AddTab({ Title = "Auto Structure", Icon = "box" }),
    Pickup    = Window:AddTab({ Title = "Auto Pickup", Icon = "shopping-bag" }),
    Player    = Window:AddTab({ Title = "Player & Spawn", Icon = "user" }),
    Settings  = Window:AddTab({ Title = "Misc & Server", Icon = "settings" })
}

-- ==========================================
-- 3. KHỞI TẠO DỮ LIỆU & LOGIC CAST SKILL
-- ==========================================
local LoadedSkillPatterns = {}
local SlotConfig = {
    [1] = { Skill = "None", AllowSpam = false, AutoExecute = false, Delay = 0.5, Key = Enum.KeyCode.One, IsSpamming = false },
    [2] = { Skill = "None", AllowSpam = false, AutoExecute = false, Delay = 0.5, Key = Enum.KeyCode.Two, IsSpamming = false },
    [3] = { Skill = "None", AllowSpam = false, AutoExecute = false, Delay = 0.5, Key = Enum.KeyCode.Three, IsSpamming = false },
    [4] = { Skill = "None", AllowSpam = false, AutoExecute = false, Delay = 0.5, Key = Enum.KeyCode.Four, IsSpamming = false }
}

local MobileButtons = {}
local slotThreads = {}

local function getCharacterCFrame()
    if LocalPlayer and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp.CFrame end
    end
    if workspace.CurrentCamera then return workspace.CurrentCamera.CFrame end
    return CFrame.new()
end

local function getOrFetchSkillPattern(skillName)
    if skillName == "None" or skillName == "" then return nil end
    if LoadedSkillPatterns[skillName] then return LoadedSkillPatterns[skillName] end
    local rawUrl = SkillDownloadUrls[skillName]
    if not rawUrl then return nil end

    local success, result = pcall(function()
        return loadstring(game:HttpGet(rawUrl))()
    end)
    if success and type(result) == "table" then
        LoadedSkillPatterns[skillName] = result
        return result
    end
    return nil
end

local function castSkillBySlot(slotNum)
    local cfg = SlotConfig[slotNum]
    if not cfg or cfg.Skill == "None" then return end
    local pattern = getOrFetchSkillPattern(cfg.Skill)
    if pattern and Remote then
        task.spawn(function()
            pcall(function()
                Remote:InvokeServer("TryCast", cfg.Skill, pattern, getCharacterCFrame())
            end)
        end)
    end
end

local function toggleSpamSlot(slotNum, state)
    local cfg = SlotConfig[slotNum]
    if not cfg or cfg.Skill == "None" then return end

    if state == nil then 
        cfg.IsSpamming = not cfg.IsSpamming 
    else 
        cfg.IsSpamming = state 
    end

    if cfg.IsSpamming then
        if slotThreads[slotNum] then
            task.cancel(slotThreads[slotNum])
            slotThreads[slotNum] = nil
        end
        
        slotThreads[slotNum] = task.spawn(function()
            while cfg.IsSpamming and cfg.Skill ~= "None" do
                castSkillBySlot(slotNum)
                task.wait(math.max(0.05, cfg.Delay))
            end
            slotThreads[slotNum] = nil
        end)
    else
        if slotThreads[slotNum] then
            task.cancel(slotThreads[slotNum])
            slotThreads[slotNum] = nil
        end
    end

    if MobileButtons[slotNum] then
        local stroke = MobileButtons[slotNum]:FindFirstChildOfClass("UIStroke")
        if cfg.IsSpamming then
            MobileButtons[slotNum].BackgroundColor3 = Color3.fromRGB(0, 180, 100)
            if stroke then stroke.Color = Color3.fromRGB(0, 255, 150) end
        else
            MobileButtons[slotNum].BackgroundColor3 = Color3.fromRGB(20, 24, 35)
            if stroke then stroke.Color = Color3.fromRGB(0, 170, 255) end
        end
    end
end

local function handleSkillTrigger(slotNum)
    local cfg = SlotConfig[slotNum]
    if not cfg or cfg.Skill == "None" then return end
    if cfg.AllowSpam then 
        toggleSpamSlot(slotNum) 
    else 
        castSkillBySlot(slotNum) 
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    for slotNum, cfg in pairs(SlotConfig) do
        if input.KeyCode == cfg.Key then
            handleSkillTrigger(slotNum)
        end
    end
end)

-- ==========================================
-- 4. LOGIC AUTO DI CHUYỂN PHÁ KIẾN TRÚC & FAIRY BOSS
-- ==========================================
local StructureConfig = {
    Enabled = false,
    TargetFolder = "All",
    DistanceOffset = 5,
    WalkSpeed = 60,
    WaitTime = 2
}

local StructureFolders = { "All", "Fairy", "Angel", "Cave", "Fire", "Forest", "Ice", "Village", "Void", "Water" }
local IgnoredStructures = {}

local function getTargetStructurePart(targetObj)
    if not targetObj then return nil end
    if targetObj:IsA("BasePart") then
        return targetObj
    elseif targetObj:IsA("Model") then
        return targetObj.PrimaryPart 
            or targetObj:FindFirstChild("HumanoidRootPart") 
            or targetObj:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function getFairyBossPart()
    local monsterFolder = workspace:FindFirstChild("monster")
    if monsterFolder then
        local fairyMonsterFolder = monsterFolder:FindFirstChild("Fairy")
        if fairyMonsterFolder then
            local fairyBoss = fairyMonsterFolder:FindFirstChild("Fairy Boss")
            if fairyBoss then
                return getTargetStructurePart(fairyBoss)
            end
        end
    end
    return nil
end

local function getClosestStructure()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    if StructureConfig.TargetFolder == "Fairy" or StructureConfig.TargetFolder == "All" then
        local bossPart = getFairyBossPart()
        if bossPart and bossPart.Parent then
            return bossPart.Parent
        end
    end

    local structureFolder = workspace:FindFirstChild("structure")
    if not structureFolder then return nil end

    local closestObj = nil
    local minDistance = math.huge
    local currentTime = tick()

    local foldersToCheck = {}
    if StructureConfig.TargetFolder == "All" then
        foldersToCheck = structureFolder:GetChildren()
    else
        local sub = structureFolder:FindFirstChild(StructureConfig.TargetFolder)
        if sub then table.insert(foldersToCheck, sub) end
    end

    for _, subFolder in ipairs(foldersToCheck) do
        for _, item in ipairs(subFolder:GetChildren()) do
            if not IgnoredStructures[item] or (currentTime - IgnoredStructures[item]) >= StructureConfig.WaitTime then
                local targetPart = getTargetStructurePart(item)
                if targetPart then
                    local dist = (hrp.Position - targetPart.Position).Magnitude
                    if dist < minDistance then
                        minDistance = dist
                        closestObj = item
                    end
                end
            end
        end
    end

    return closestObj
end

RunService.Heartbeat:Connect(function(deltaTime)
    if not StructureConfig.Enabled then return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local targetObj = getClosestStructure()
    if not targetObj then return end

    local targetPart = getTargetStructurePart(targetObj)
    if not targetPart or not targetPart.Parent then return end

    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end

    local targetPos = targetPart.Position
    local currentPos = hrp.Position
    local dir = (targetPos - currentPos)
    
    local flatDir = Vector3.new(dir.X, 0, dir.Z)
    local distance = flatDir.Magnitude

    if distance > StructureConfig.DistanceOffset then
        local moveDir = flatDir.Unit
        local moveStep = moveDir * StructureConfig.WalkSpeed * deltaTime
        local nextPos = currentPos + moveStep
        hrp.CFrame = CFrame.new(nextPos, nextPos + moveDir)
    else
        hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
        if targetObj.Name ~= "Fairy Boss" then
            if not IgnoredStructures[targetObj] or (tick() - IgnoredStructures[targetObj]) >= StructureConfig.WaitTime then
                IgnoredStructures[targetObj] = tick()
            end
        end
    end
end)

-- ==========================================
-- 5. AUTO PLAY ISLANDS & AUTO RE-TELEPORT
-- ==========================================
local ManualPinnedCFrame = nil

local IslandLocations = {
    { Name = "Đảo Fairy", CFrame = CFrame.new(780.169128, 223.536789, -2753.00854, -0.374607235, -6.99194857e-07, -0.927183568, 1.09453174e-06, 1, -1.19632659e-06, 0.927183568, -1.46298441e-06, -0.374607235), FolderTarget = "Fairy" },
    { Name = "Đảo Thiên Đường", CFrame = CFrame.new(66.006, 4.293, -2506.463, 0.993, 0.000, -0.122, 0.000, 1.000, 0.000, 0.122, 0.000, 0.993), FolderTarget = "Angel" },
    { Name = "Void", CFrame = CFrame.new(48.717, 6.277, -1602.447, -0.999, 0.000, 0.044, 0.000, 1.000, 0.000, -0.044, 0.000, -0.999), FolderTarget = "Void" },
    { Name = "Đảo Dân Làng", CFrame = CFrame.new(75.163, 5.793, -1318.145, -0.999, 0.000, -0.035, 0.000, 1.000, -0.000, 0.035, -0.000, -0.999), FolderTarget = "Village" },
    { Name = "Đảo Nước", CFrame = CFrame.new(75.163, 5.793, -1318.145, -0.999, 0.000, -0.035, 0.000, 1.000, -0.000, 0.035, -0.000, -0.999), FolderTarget = "Water" },
    { Name = "Đảo Lửa", CFrame = CFrame.new(58.588, 5.610, -124.633, -1.000, 0.000, 0.009, 0.000, 1.000, -0.000, -0.009, -0.000, -1.000), FolderTarget = "Fire" },
    { Name = "Đảo Băng", CFrame = CFrame.new(65.089, 5.606, 400.480, -1.000, -0.000, 0.009, -0.000, 1.000, 0.000, -0.009, 0.000, -1.000), FolderTarget = "Ice" },
    { Name = "Đảo Đá", CFrame = CFrame.new(62.443, 5.605, 703.599, -1.000, -0.000, 0.009, -0.000, 1.000, 0.000, -0.009, 0.000, -1.000), FolderTarget = "Cave" },
    { Name = "Đảo Newbie", CFrame = CFrame.new(55.903, 5.585, 1155.590, 1.000, -0.000, 0.017, 0.000, 1.000, -0.000, -0.017, 0.000, 1.000), FolderTarget = "Forest" }
}

local IslandNames = {}
for _, island in ipairs(IslandLocations) do table.insert(IslandNames, island.Name) end

local AutoPlayConfig = { Enabled = false, TimePerIsland = 600, CurrentIndex = 1, TimerThread = nil }
local SelectedSpawnIsland = "None"
local EnableFixedIslandSpawn = true
local EnableReTeleport = false
local ReTeleportInterval = 60
local reTeleportThread = nil

local function teleportToIsland(index)
    local islandData = IslandLocations[index]
    if not islandData then return end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 10)
    if hrp then
        hrp.CFrame = islandData.CFrame
        ManualPinnedCFrame = islandData.CFrame
        if StructureConfig then
            StructureConfig.TargetFolder = islandData.FolderTarget
            if Fluent and Fluent.Options and Fluent.Options.SelectStructureFolder then
                Fluent.Options.SelectStructureFolder:SetValue(islandData.FolderTarget)
            end
        end
        if Fluent then
            Fluent:Notify({ Title = "Auto Spawn Island", Content = "Đã kết nối đảo: " .. islandData.Name, Duration = 2 })
        end
    end
end

local function executeSpawnIslandLogic()
    if AutoPlayConfig.Enabled then
        teleportToIsland(AutoPlayConfig.CurrentIndex)
    elseif EnableFixedIslandSpawn and SelectedSpawnIsland ~= "None" then
        for idx, island in ipairs(IslandLocations) do
            if island.Name == SelectedSpawnIsland then
                teleportToIsland(idx)
                break
            end
        end
    end
end

local function startReTeleportLoop()
    if reTeleportThread then task.cancel(reTeleportThread) end
    reTeleportThread = task.spawn(function()
        while EnableReTeleport do
            task.wait(ReTeleportInterval)
            if EnableReTeleport and SelectedSpawnIsland ~= "None" and not AutoPlayConfig.Enabled then
                executeSpawnIslandLogic()
            end
        end
    end)
end

task.spawn(function() task.wait(1.5) executeSpawnIslandLogic() end)

LocalPlayer.CharacterAdded:Connect(function(char)
    local humanoid = char:WaitForChild("Humanoid", 10)
    if humanoid then
        humanoid.Died:Connect(function()
            if AutoPlayConfig.Enabled then
                AutoPlayConfig.CurrentIndex = AutoPlayConfig.CurrentIndex + 1
                if AutoPlayConfig.CurrentIndex > #IslandLocations then AutoPlayConfig.CurrentIndex = 1 end
            end
        end)
    end
    task.spawn(function()
        char:WaitForChild("HumanoidRootPart", 10)
        task.wait(0.5)
        executeSpawnIslandLogic()
    end)
end)

-- ==========================================
-- 6. HỆ THỐNG AUTO PICKUP
-- ==========================================
local Rarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Divine", "Secret" }
local StatOptions = { 
    "Crit Chance", "Crit Damage", "Damage", 
    "DamageReduction", "Mana Regen", "ManaCostReduction", "Gold Bonus", "Luck", 
    "Health", "ReflectDamage", "Slash", "Immunity"
}

local SkillDropOptions = {
    "Fairy", "Fairy Staff", "Fairy Sword", "Fire Arrow", "Fire Ball", "Fire Hole",
    "Fire Slash", "Fire Sword", "Health", "Ice Magical", "Ice Sword", "Immunity",
    "Light Health", "Light Sword", "Light Zone", "Lighting Staff", "Meteo", "Murasaki",
    "Pistol", "Prime Ice Sword", "Prime Ice Sword V2", "Prime Ice Sword V3", "Rock Dragon",
    "Slash", "Stamp on Ice", "Star Fire", "Summon", "Tornado", "Tornado Fire",
    "Ultra Black Hole", "Ultra Fire Hole", "Ultrasound", "Wall", "Water Ball",
    "Water Beam", "Water Hole", "Whirl Pool"
}

local RingOptions = { "Ring Water", "Ring Nature", "Ring Fire", "Ring Ice", "Ring Shadow", "Ring Angel", "Ring Fairy", "Void Ring" }

local DropConfig = {
    Enabled = false,
    TeleportEnabled = true,
    Radius = 250,
    StatMinValues = {}
}

for _, stat in ipairs(StatOptions) do DropConfig.StatMinValues[stat] = 0 end

local function passesDropFilter(model, prompt)
    if not model then return false end

    local rawSkills = (Fluent.Options.SelectSkills and Fluent.Options.SelectSkills.Value) or {}
    local rawRings = (Fluent.Options.SelectRings and Fluent.Options.SelectRings.Value) or {}
    local rawRingRarities = (Fluent.Options.SelectRingRarity and Fluent.Options.SelectRingRarity.Value) or {}
    local rawRarities = (Fluent.Options.SelectRarity and Fluent.Options.SelectRarity.Value) or {}
    local rawStats = (Fluent.Options.SelectStats and Fluent.Options.SelectStats.Value) or {}

    local activeSkills, activeRings, activeRingRarities, activeRarities, activeStats = {}, {}, {}, {}, {}

    for name, enabled in pairs(rawSkills) do if enabled == true then table.insert(activeSkills, string.lower(name)) end end
    for name, enabled in pairs(rawRings) do if enabled == true then table.insert(activeRings, string.lower(name)) end end
    for name, enabled in pairs(rawRingRarities) do if enabled == true then table.insert(activeRingRarities, string.lower(name)) end end
    for name, enabled in pairs(rawRarities) do if enabled == true then table.insert(activeRarities, string.lower(name)) end end
    for name, enabled in pairs(rawStats) do if enabled == true then table.insert(activeStats, name) end end

    local itemCategory = tostring(model:GetAttribute("ItemCategory") or (model.Parent and model.Parent:GetAttribute("ItemCategory")) or ""):lower()
    local itemType = tostring(model:GetAttribute("ItemType") or (model.Parent and model.Parent:GetAttribute("ItemType")) or ""):lower()
    local itemName = tostring(model:GetAttribute("ItemName") or model.Name or ""):lower()
    local itemTier = tostring(model:GetAttribute("ItemTier") or (model.Parent and model.Parent:GetAttribute("ItemTier")) or ""):lower()
    local skillId = tostring(model:GetAttribute("SkillId") or (model.Parent and model.Parent:GetAttribute("SkillId")) or ""):lower()
    local promptText = prompt and prompt.ObjectText and prompt.ObjectText:lower() or ""

    local fullModelName = (itemName .. " " .. promptText):lower()

    local isActualSkill = (itemCategory == "skill" or itemType == "skill" or skillId ~= "") 
                          and not fullModelName:find("armor") and not fullModelName:find("gloves") and not fullModelName:find("robe")

    if isActualSkill then
        if #activeSkills > 0 then
            for _, skillName in ipairs(activeSkills) do
                if skillId == skillName or itemName == skillName then
                    return true
                end

                local pattern = "%f[%a]" .. skillName .. "%f[%A]"
                if fullModelName:find(pattern) then
                    return true
                end
            end
        end
        return false
    end

    local isRing = itemType == "ring" or itemCategory == "ring" or fullModelName:find("ring", 1, true) ~= nil

    if isRing then
        if #activeRings == 0 then return false end

        local ringMatch = false
        for _, ringName in ipairs(activeRings) do
            local pattern = "%f[%a]" .. ringName .. "%f[%A]"
            if fullModelName:find(pattern) or fullModelName:find(ringName, 1, true) then
                ringMatch = true
                break
            end
        end

        if not ringMatch then return false end

        if #activeRingRarities > 0 then
            for _, rName in ipairs(activeRingRarities) do
                if itemTier == rName or fullModelName:find(rName, 1, true) then
                    return true
                end
            end
            return false
        end

        return true
    end

    if #activeRarities == 0 and #activeStats == 0 then return false end

    local rarityMatch = false
    if #activeRarities > 0 then
        for _, rName in ipairs(activeRarities) do
            if itemTier == rName or fullModelName:find(rName, 1, true) then
                rarityMatch = true
                break
            end
        end
    else
        rarityMatch = true
    end

    if not rarityMatch then return false end

    local statMatch = false
    if #activeStats > 0 then
        local enchantsData = {}
        local jsonStr = model:GetAttribute("EnchantsJson") or (model.Parent and model.Parent:GetAttribute("EnchantsJson"))
        if jsonStr and jsonStr ~= "" then
            pcall(function() enchantsData = HttpService:JSONDecode(jsonStr) end)
        end

        local enchantName = tostring(model:GetAttribute("EnchantName") or (model.Parent and model.Parent:GetAttribute("EnchantName")) or ""):lower()
        local enchantVal = tonumber(model:GetAttribute("EnchantValue")) 
                         or tonumber(model:GetAttribute("EnchantBaseValue")) 
                         or (model.Parent and tonumber(model.Parent:GetAttribute("EnchantValue"))) or 0

        for _, statName in ipairs(activeStats) do
            local cleanStat = string.lower(statName):gsub("%s+", "")
            local minReq = DropConfig.StatMinValues[statName] or 0

            local cleanEnchant = enchantName:gsub("%s+", "")
            if (cleanEnchant == cleanStat or cleanEnchant:find(cleanStat, 1, true) or fullModelName:find(cleanStat, 1, true)) then
                if enchantVal >= minReq then
                    statMatch = true
                    break
                end
            end

            if type(enchantsData) == "table" then
                for _, enc in ipairs(enchantsData) do
                    local eName = tostring(enc.name or enc.EnchantName or ""):lower():gsub("%s+", "")
                    local eVal = tonumber(enc.value or enc.EnchantValue or enc.baseValue) or 0
                    if (eName == cleanStat or eName:find(cleanStat, 1, true)) and eVal >= minReq then
                        statMatch = true
                        break
                    end
                end
            end
            if statMatch then break end
        end
    else
        statMatch = true
    end

    return rarityMatch and statMatch
end

local function triggerPrompt(prompt)
    if not prompt or not prompt.Parent then return end
    prompt.HoldDuration = 0
    prompt.RequiresLineOfSight = false
    prompt.MaxActivationDistance = math.huge
    prompt.Enabled = true

    if fireproximityprompt then fireproximityprompt(prompt) end

    pcall(function()
        if prompt.InputHoldBegin then
            prompt:InputHoldBegin()
            task.wait(0.05)
            prompt:InputHoldEnd()
        end
    end)
end

local isTeleportingToPick = false

task.spawn(function()
    while task.wait(0.1) do
        if DropConfig.Enabled and not isTeleportingToPick then
            local character = LocalPlayer and LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")

            if hrp then
                local itemDropFolder = workspace:FindFirstChild("itemdrop") or workspace
                for _, obj in pairs(itemDropFolder:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then
                        local itemModel = obj:FindFirstAncestorOfClass("Model") or obj.Parent
                        local targetPart = (obj.Parent and obj.Parent:IsA("BasePart") and obj.Parent) 
                                        or (itemModel and itemModel:FindFirstChildWhichIsA("BasePart", true))

                        if targetPart and (targetPart.Position - hrp.Position).Magnitude <= DropConfig.Radius then
                            local ok, filterResult = pcall(function()
                                return passesDropFilter(itemModel, obj)
                            end)
                            
                            if ok and filterResult == true then
                                isTeleportingToPick = true
                                local originalCFrame = hrp.CFrame

                                if DropConfig.TeleportEnabled then
                                    hrp.CFrame = targetPart.CFrame * CFrame.new(0, 1.5, 0)
                                    task.wait(0.1)

                                    local startTime = tick()
                                    while obj and obj.Parent and (tick() - startTime < 1.5) do
                                        triggerPrompt(obj)
                                        task.wait(0.1)
                                    end

                                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                        LocalPlayer.Character.HumanoidRootPart.CFrame = originalCFrame
                                    end
                                else
                                    triggerPrompt(obj)
                                end
                                
                                task.wait(0.1)
                                isTeleportingToPick = false
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ==========================================
-- 7. NOCLIP & SETSPAWN THỦ CÔNG
-- ==========================================
local NoclipEnabled = false
local AutoSetSpawnOnRespawn = false

RunService.Stepped:Connect(function()
    if NoclipEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    if AutoSetSpawnOnRespawn and not AutoPlayConfig.Enabled and not EnableFixedIslandSpawn then
        if ManualPinnedCFrame then
            task.spawn(function()
                local hrp = char:WaitForChild("HumanoidRootPart", 10)
                if hrp then
                    task.wait(0.5)
                    hrp.CFrame = ManualPinnedCFrame
                end
            end)
        end
    end
end)

-- ==========================================
-- 8. ĐỘN THỔ & BỆ ĐỨNG CỐ ĐỊNH TẠI CHỐ
-- ==========================================
local AutoUndergroundEnabled = false
local UndergroundOffset = -10
local currentPlatform = nil

local function removeUndergroundPlatform()
    if currentPlatform then
        currentPlatform:Destroy()
        currentPlatform = nil
    end
end

local function applyAutoUnderground(character)
    removeUndergroundPlatform()
    if not AutoUndergroundEnabled or not character then return end

    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end

    task.wait(0.2)

    local targetCFrame = hrp.CFrame * CFrame.new(0, UndergroundOffset, 0)
    hrp.CFrame = targetCFrame

    local platform = Instance.new("Part")
    platform.Name = "UndergroundPlatform"
    platform.Size = Vector3.new(12, 1, 12)
    platform.Position = targetCFrame.Position - Vector3.new(0, 3.5, 0)
    platform.Anchored = true
    platform.CanCollide = true
    platform.Material = Enum.Material.SmoothPlastic
    platform.Transparency = 0.3
    platform.Color = Color3.fromRGB(0, 170, 255)
    platform.Parent = workspace

    currentPlatform = platform
end

LocalPlayer.CharacterAdded:Connect(function(char)
    if AutoUndergroundEnabled then
        task.spawn(function() applyAutoUnderground(char) end)
    end
end)

-- ==========================================
-- 9. HỆ THỐNG SERVER VIP
-- ==========================================
local CustomVipCode = ""
local function findAndJoinMyServer()
    local placeId = game.PlaceId
    if CustomVipCode ~= "" then
        Fluent:Notify({ Title = "VIP System", Content = "Đang kết nối VIP Server...", Duration = 3 })
        local linkCode = CustomVipCode:match("privateServerLinkCode=([%d%a%-]+)") or CustomVipCode:match("code=([%d%a%-]+)") or CustomVipCode
        local launchUrl = string.format("roblox://placeId=%d&linkCode=%s", placeId, linkCode)
        
        local success = pcall(function()
            if setclipboard then setclipboard(launchUrl) end
            game:GetService("GuiService"):OpenBrowserWindow(launchUrl)
        end)

        if not success then
            pcall(function() TeleportService:TeleportToPlaceInstance(placeId, linkCode, LocalPlayer) end)
        end
        return
    end

    Fluent:Notify({ Title = "VIP System", Content = "Đang quét danh sách Server...", Duration = 3 })
    local cursor = ""
    local validServerId = nil

    for i = 1, 5 do
        local serverUrl = string.format("https://games.roblox.com/v1/games/%d/servers/0?sortOrder=Asc&limit=100&cursor=%s", placeId, cursor)
        local success, response = pcall(function() return game:HttpGet(serverUrl) end)

        if success and response then
            local decSuccess, data = pcall(function() return HttpService:JSONDecode(response) end)
            if decSuccess and data and data.data then
                for _, server in ipairs(data.data) do
                    if server.playing and server.playing > 0 and server.playing < server.maxPlayers and server.id ~= game.JobId then
                        validServerId = server.id
                        break
                    end
                end
                if validServerId then break end
                cursor = data.nextPageCursor or ""
                if cursor == "" or cursor == nil then break end
            end
        end
    end

    if validServerId then
        TeleportService:TeleportToPlaceInstance(placeId, validServerId, LocalPlayer)
    else
        Fluent:Notify({ Title = "VIP System", Content = "Vui lòng nhập Link/Code VIP!", Duration = 4 })
    end
end

-- ==========================================
-- 10. DỰNG GIAO DIỆN FLUENT UI
-- ==========================================

-- TAB 1: SKILL SLOTS
Tabs.Slots:AddSection("Cài Đặt Chế Độ Spam Skill")
for slot = 1, 4 do
    Tabs.Slots:AddDropdown("SlotDropdown_" .. slot, {
        Title = "Slot " .. slot .. " - Chọn Skill",
        Values = SkillDropdownOptions,
        Default = "None",
        Callback = function(Value)
            SlotConfig[slot].Skill = Value
            if Value == "None" then 
                toggleSpamSlot(slot, false) 
            elseif SlotConfig[slot].AutoExecute then
                toggleSpamSlot(slot, true)
            end

            if MobileButtons[slot] then
                MobileButtons[slot].Visible = (Value ~= "None")
                MobileButtons[slot].Text = string.format("[%d]\n%s", slot, Value)
            end
        end
    })

    Tabs.Slots:AddToggle("SlotAutoExecute_" .. slot, {
        Title = "Auto Execute Slot " .. slot,
        Default = false,
        Callback = function(Value)
            SlotConfig[slot].AutoExecute = Value
            if Value and SlotConfig[slot].Skill ~= "None" then
                toggleSpamSlot(slot, true)
            elseif not Value and not SlotConfig[slot].AllowSpam then
                toggleSpamSlot(slot, false)
            end
        end
    })

    Tabs.Slots:AddToggle("SlotSpam_" .. slot, {
        Title = "Toggle Spam Slot " .. slot,
        Default = false,
        Callback = function(Value)
            SlotConfig[slot].AllowSpam = Value
            if not Value and not SlotConfig[slot].AutoExecute then 
                toggleSpamSlot(slot, false) 
            end
        end
    })

    Tabs.Slots:AddSlider("SlotDelay_" .. slot, {
        Title = "Delay Slot " .. slot,
        Min = 0.1, Max = 3.0, Default = 0.5, Rounding = 1,
        Callback = function(Value) SlotConfig[slot].Delay = Value end
    })
end

-- TAB 2: KEYBOARD
Tabs.Keyboard:AddSection("Phím Tắt PC (Keybinds)")
for slot = 1, 4 do
    Tabs.Keyboard:AddKeybind("KeybindSlot_" .. slot, {
        Title = "Kích Hoạt Slot " .. slot,
        Mode = "Toggle",
        Default = SlotConfig[slot].Key.Name,
        Callback = function(Value)
            if typeof(Value) == "EnumItem" then
                SlotConfig[slot].Key = Value
            elseif type(Value) == "string" and Enum.KeyCode[Value] then
                SlotConfig[slot].Key = Enum.KeyCode[Value]
            end
        end
    })
end

-- TAB 3: AUTO ISLANDS
Tabs.Islands:AddSection("Cấu Hình Spawn Đảo")
local spawnOptions = {"None"}
for _, name in ipairs(IslandNames) do table.insert(spawnOptions, name) end

Tabs.Islands:AddToggle("ToggleFixedIslandSpawn", {
    Title = "Spawn Cố Định Đảo (Auto Teleport)",
    Default = true,
    Callback = function(Value) 
        EnableFixedIslandSpawn = Value 
        if Value then executeSpawnIslandLogic() end
    end
})

Tabs.Islands:AddDropdown("SelectSpawnIsland", {
    Title = "Chọn Đảo Respawn",
    Values = spawnOptions,
    Default = "None",
    Callback = function(Value) 
        SelectedSpawnIsland = Value 
        if Value ~= "None" and EnableFixedIslandSpawn then
            executeSpawnIslandLogic()
        end
    end
})

Tabs.Islands:AddToggle("ToggleReTeleportIsland", {
    Title = "Auto Re-Teleport Đảo Respawn (Theo Chu Kỳ)",
    Default = false,
    Callback = function(Value)
        EnableReTeleport = Value
        if Value then
            startReTeleportLoop()
        elseif reTeleportThread then
            task.cancel(reTeleportThread)
            reTeleportThread = nil
        end
    end
})

Tabs.Islands:AddSlider("ReTeleportIntervalSlider", {
    Title = "Thời Gian Re-Teleport Lại Đảo (Phút)",
    Min = 1, Max = 30, Default = 1, Rounding = 0,
    Callback = function(Value)
        ReTeleportInterval = Value * 60
    end
})

Tabs.Islands:AddSection("Chế Độ Rotate Đảo")
Tabs.Islands:AddToggle("ToggleAutoPlayIslands", {
    Title = "Auto Rotate Đảo (Theo Thời Gian)",
    Default = false,
    Callback = function(Value)
        AutoPlayConfig.Enabled = Value
        if Value then
            teleportToIsland(AutoPlayConfig.CurrentIndex)
        end
    end
})

Tabs.Islands:AddSlider("IslandTimeLimit", {
    Title = "Thời gian ở mỗi Đảo (Phút)",
    Min = 1, Max = 30, Default = 10, Rounding = 0,
    Callback = function(Value)
        AutoPlayConfig.TimePerIsland = Value * 60
    end
})

Tabs.Islands:AddSection("Teleport Đảo")
for idx, island in ipairs(IslandLocations) do
    Tabs.Islands:AddButton({
        Title = string.format("[%d] %s", idx, island.Name),
        Callback = function()
            AutoPlayConfig.CurrentIndex = idx
            teleportToIsland(idx)
        end
    })
end

-- TAB 4: AUTO STRUCTURE
Tabs.Structure:AddToggle("ToggleAutoStructure", {
    Title = "Auto Phá Kiến Trúc (Tự đánh Fairy Boss)",
    Default = false,
    Callback = function(Value) StructureConfig.Enabled = Value end
})

Tabs.Structure:AddDropdown("SelectStructureFolder", {
    Title = "Khu Vực Kiến Trúc",
    Values = StructureFolders,
    Default = "All",
    Callback = function(Value) StructureConfig.TargetFolder = Value end
})

Tabs.Structure:AddSlider("StructureWalkSpeed", {
    Title = "Tốc Độ Di Chuyển",
    Min = 16, Max = 150, Default = 60, Rounding = 0,
    Callback = function(Value) StructureConfig.WalkSpeed = Value end
})

Tabs.Structure:AddSlider("StructureWaitTime", {
    Title = "Thời Gian Chờ Đổi Target (s)",
    Min = 0.5, Max = 5, Default = 2, Rounding = 1,
    Callback = function(Value) StructureConfig.WaitTime = Value end
})

Tabs.Structure:AddSlider("StructureDistanceOffset", {
    Title = "Khoảng Cách Đứng (Offset)",
    Min = 2, Max = 20, Default = 5, Rounding = 0,
    Callback = function(Value) StructureConfig.DistanceOffset = Value end
})

-- TAB 5: AUTO PICKUP
Tabs.Pickup:AddToggle("ToggleAutoPickup", {
    Title = "Bật Auto Pickup", Default = false,
    Callback = function(Value) DropConfig.Enabled = Value end
})

Tabs.Pickup:AddToggle("ToggleTeleportPickup", {
    Title = "Teleport Đến Đồ Nhặt", Default = true,
    Callback = function(Value) DropConfig.TeleportEnabled = Value end
})

Tabs.Pickup:AddSlider("PickupDistance", {
    Title = "Bán kính quét (Studs)", Min = 20, Max = 500, Default = 250, Rounding = 0,
    Callback = function(Value) DropConfig.Radius = Value end
})

Tabs.Pickup:AddSection("1. Lọc Skill")
Tabs.Pickup:AddDropdown("SelectSkills", {
    Title = "Chọn Skill Muốn Nhặt",
    Values = SkillDropOptions, Multi = true, Default = {}
})

Tabs.Pickup:AddSection("2. Lọc Ring")
Tabs.Pickup:AddDropdown("SelectRings", {
    Title = "Chọn Ring Muốn Nhặt",
    Values = RingOptions, Multi = true, Default = {}
})

Tabs.Pickup:AddDropdown("SelectRingRarity", {
    Title = "Rarity Cho Ring (Tùy Chọn)",
    Values = Rarities, Multi = true, Default = {}
})

Tabs.Pickup:AddSection("3. Lọc Trang Bị Thường")
Tabs.Pickup:AddDropdown("SelectRarity", {
    Title = "Rarity Trang Bị",
    Values = Rarities, Multi = true, Default = {}
})

Tabs.Pickup:AddDropdown("SelectStats", {
    Title = "Lọc Chỉ Số Item",
    Values = StatOptions, Multi = true, Default = {}
})

Tabs.Pickup:AddSection("% Tối Thiểu Chỉ Số Item")
for _, statName in ipairs(StatOptions) do
    Tabs.Pickup:AddInput("Input_" .. statName, {
        Title = "% Min: " .. statName,
        Default = "0",
        Numeric = true,
        Finished = false,
        Callback = function(val)
            DropConfig.StatMinValues[statName] = tonumber(val) or 0
        end
    })
end

-- TAB 6: PLAYER & SPAWN
Tabs.Player:AddSection("Di Chuyển & Noclip")
Tabs.Player:AddToggle("ToggleNoclip", {
    Title = "Bật Noclip (Xuyên tường)", Default = false,
    Callback = function(Value) NoclipEnabled = Value end
})

Tabs.Player:AddSection("Tọa Độ Ghim Thủ Công")
Tabs.Player:AddButton({
    Title = "📌 Ghim Vị Trí Hiện Tại làm Spawn",
    Callback = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            ManualPinnedCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
            Fluent:Notify({ Title = "SetSpawn System", Content = "Đã ghim vị trí thành công!", Duration = 3 })
        end
    end
})

Tabs.Player:AddToggle("ToggleAutoSetSpawn", {
    Title = "Tự Teleport về điểm GHIM khi Respawn", Default = false,
    Callback = function(Value) AutoSetSpawnOnRespawn = Value end
})

-- TAB 7: MISC & SERVER
Tabs.Settings:AddSection("Độn Thổ (Platform)")
Tabs.Settings:AddToggle("ToggleUnderground", {
    Title = "Bật Độn Thổ Cố Định", Default = false,
    Callback = function(Value)
        AutoUndergroundEnabled = Value
        if Value and LocalPlayer.Character then
            applyAutoUnderground(LocalPlayer.Character)
        else
            removeUndergroundPlatform()
        end
    end
})

Tabs.Settings:AddSlider("UndergroundDepth", {
    Title = "Độ Sâu Độn Thổ", Min = -30, Max = -5, Default = -10, Rounding = 0,
    Callback = function(Value)
        UndergroundOffset = Value
        if AutoUndergroundEnabled and LocalPlayer.Character then
            applyAutoUnderground(LocalPlayer.Character)
        end
    end
})

Tabs.Settings:AddSection("Server / VIP System")
Tabs.Settings:AddInput("VipCodeInput", {
    Title = "Link / Code VIP Server", Default = "", Numeric = false, Finished = false,
    Callback = function(Value) CustomVipCode = Value end
})

Tabs.Settings:AddButton({
    Title = "Chuyển Server / Vào VIP",
    Callback = function() findAndJoinMyServer() end
})

-- ==========================================
-- 11. GIAO DIỆN NÚT SKILL MOBILE & PC NÂNG CẤP (ĐẸP & RÕ CHỮ)
-- ==========================================
local function createMobileUI()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild("MobileSkillGui") then playerGui.MobileSkillGui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MobileSkillGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 300, 0, 70)
    container.Position = UDim2.new(0.5, -150, 0.82, 0)
    container.BackgroundTransparency = 1
    container.Parent = screenGui

    for slot = 1, 4 do
        local btn = Instance.new("TextButton")
        btn.Name = "SkillBtn_" .. slot
        btn.Size = UDim2.new(0, 65, 0, 65)
        btn.Position = UDim2.new(0, (slot - 1) * 75, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(20, 24, 35)
        btn.TextColor3 = Color3.fromRGB(0, 210, 255)
        btn.TextScaled = true
        btn.Font = Enum.Font.GothamBold
        btn.Visible = false
        btn.BorderSizePixel = 0
        btn.Parent = container

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = btn

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(0, 170, 255)
        stroke.Thickness = 2
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = btn

        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0.12, 0)
        padding.PaddingBottom = UDim.new(0.12, 0)
        padding.PaddingLeft = UDim.new(0.08, 0)
        padding.PaddingRight = UDim.new(0.08, 0)
        padding.Parent = btn

        MobileButtons[slot] = btn
        btn.MouseButton1Click:Connect(function() handleSkillTrigger(slot) end)
    end
end

task.spawn(createMobileUI)

-- ==========================================
-- 12. NÚT TOGGLE UI TÍN HUB (KÉO THẢ & PHÁT SÁNG)
-- ==========================================
task.spawn(function()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild("MobileToggleGui") then playerGui.MobileToggleGui:Destroy() end

    local toggleGui = Instance.new("ScreenGui")
    toggleGui.Name = "MobileToggleGui"
    toggleGui.ResetOnSpawn = false
    toggleGui.Parent = playerGui

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleHubBtn"
    toggleBtn.Size = UDim2.new(0, 55, 0, 55)
    toggleBtn.Position = UDim2.new(0.05, 0, 0.15, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(20, 24, 35)
    toggleBtn.TextColor3 = Color3.fromRGB(0, 210, 255)
    toggleBtn.Text = "TÍN\nHUB"
    toggleBtn.TextScaled = true
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Active = true
    toggleBtn.Parent = toggleGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = toggleBtn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 170, 255)
    stroke.Thickness = 2.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = toggleBtn

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0.15, 0)
    padding.PaddingBottom = UDim.new(0.15, 0)
    padding.PaddingLeft = UDim.new(0.1, 0)
    padding.PaddingRight = UDim.new(0.1, 0)
    padding.Parent = toggleBtn

    -- Logic Kéo Thả Mượt Mà
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    toggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = toggleBtn.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    toggleBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)

    toggleBtn.MouseButton1Click:Connect(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
    end)
end)

-- ==========================================
-- 13. KHỞI TẠO SAVE MANAGER & NOTIFY
-- ==========================================
SaveManager:SetLibrary(Fluent)
SaveManager:SetFolder("TinHub/MainSystem")
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Fluent:Notify({
    Title = "Tín Hub Mobile & PC",
    Content = "Đã tải thành công giao diện mới!",
    Duration = 5
})
