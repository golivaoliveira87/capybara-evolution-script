-- Function that starts the Kill Aura
local function StartKillAura()
    -- Start a new thread to run the function in parallel
    task.spawn(function()
        -- Game services required
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Workspace = game:GetService("Workspace")
        local LocalPlayer = Players.LocalPlayer

        -- Wait until the player's character is loaded
        repeat task.wait() until LocalPlayer.Character  
        local Character = LocalPlayer.Character  
        local RootPart = Character:FindFirstChild("HumanoidRootPart")  
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")

        -- Connect to update data when the player's character is changed
        LocalPlayer.CharacterAdded:Connect(function(newCharacter)  
            Character = newCharacter  
            repeat task.wait() until newCharacter:FindFirstChild("HumanoidRootPart")  
            RootPart = newCharacter:FindFirstChild("HumanoidRootPart")  
            Humanoid = newCharacter:FindFirstChildOfClass("Humanoid")
        end)  

        -- If RootPart is not found, exit the function
        if not RootPart then return end  

        -- Function to get the MonsterService from ReplicatedStorage
        local function GetMonsterService()  
            local success, service = pcall(function()  
                return ReplicatedStorage:WaitForChild("Packages", 3)  
                    :WaitForChild("Knit", 3)  
                    :WaitForChild("Services", 3)  
                    :WaitForChild("MonsterService", 3)  
                    :WaitForChild("RF", 3)  
            end)  
            return success and service or nil  
        end  

        -- Get the MonsterService
        local MonsterService = GetMonsterService()  
        if not MonsterService then  
            warn("⚠️ MonsterService not found, stopping the script.")  
            return  
        end  

        -- Get the RequestAttack function from MonsterService
        local RequestAttack = MonsterService:FindFirstChild("RequestAttack")  
        if not RequestAttack then  
            warn("⚠️ RequestAttack not found, stopping the script.")  
            return  
        end  

        -- Parameter definitions
        local AttackRange = 100  -- Attack range
        local CooldownTime = 0.1  -- Time between attacks
        local CurrentTarget = nil  -- Current target for Kill Aura
        local PreviousPosition = RootPart.Position  -- Previous position of the character
        local IsMoving = false  -- Checks if the character is moving

        -- Function to get nearby enemies dynamically
        local function GetNearbyEnemies()  
            local enemies = {}

            -- Iterate through all objects in the Workspace
            for _, obj in ipairs(Workspace:GetChildren()) do  
                -- Check if the object is a model and not the player's own character
                if obj:IsA("Model") and obj ~= Character then  
                    local humanoid = obj:FindFirstChildOfClass("Humanoid")  -- Check if the model has a Humanoid
                    local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")  -- Check if the model has the HumanoidRootPart or Head

                    -- If the model has humanoid and is an enemy
                    if humanoid and humanoid.Health > 0 and hrp then  
                        local distance = (hrp.Position - RootPart.Position).Magnitude  -- Calculate the distance between the player and the enemy
                        if distance <= AttackRange then  
                            -- Add the enemy to the list (avoid duplication and caching)
                            enemies[#enemies + 1] = {hrp = hrp, humanoid = humanoid, distance = distance}
                        end  
                    end  
                end  
            end  

            -- Sort the enemies by the closest distance
            table.sort(enemies, function(a, b) return a.distance < b.distance end)  

            -- Return the list of enemies
            return enemies  
        end

        -- Main loop that will keep running to check enemies and attack
        while true do  
            -- Check if the RootPart still exists, if not, try to find it again
            if not RootPart or not RootPart.Parent then  
                RootPart = Character and Character:FindFirstChild("HumanoidRootPart")  
                if not RootPart then return end  
            end  

            -- Check if the character is moving
            local CurrentPosition = RootPart.Position  
            IsMoving = (CurrentPosition - PreviousPosition).Magnitude > 0.1  
            PreviousPosition = CurrentPosition  

            -- If the character is moving, change the target
            if IsMoving then  
                local enemies = GetNearbyEnemies()  
                CurrentTarget = #enemies > 0 and enemies[1] or nil  -- If there are enemies, select the closest one
            else  
                -- If the character is not moving, keep the current target
                if CurrentTarget then  
                    local targetHRP, targetHumanoid = CurrentTarget.hrp, CurrentTarget.humanoid  
                    local distance = (targetHRP.Position - RootPart.Position).Magnitude  
                    if not targetHRP or not targetHRP.Parent or targetHumanoid.Health <= 0 or distance > AttackRange then  
                        CurrentTarget = nil  -- If the target is invalid, reset the target
                    end  
                end  
            end  

            -- If there is a target, perform the attack
            if CurrentTarget then  
                local targetHRP = CurrentTarget.hrp  
                if RootPart and targetHRP then  
                    -- Calculate the attack direction and adjust the character's rotation
                    local direction = (targetHRP.Position - RootPart.Position).unit  
                    RootPart.CFrame = CFrame.lookAt(RootPart.Position, RootPart.Position + Vector3.new(direction.X, 0, direction.Z))  

                    -- Perform the attack
                    pcall(function()  
                        RequestAttack:InvokeServer(targetHRP.CFrame)  
                    end)  
                end  
            end  

            -- Wait for the cooldown time before trying to attack again
            task.wait(CooldownTime)  
        end  
    end)
end

-- Loop that keeps trying to start the Kill Aura repeatedly
while true do  
    -- Try to execute the StartKillAura function
    local success, error = pcall(StartKillAura)  
    if not success then  
        warn("⚠️ Error in script: ", error)  -- If an error occurs, display a warning
    end  
    task.wait(0.5)  -- Wait for half a second before trying again
end
