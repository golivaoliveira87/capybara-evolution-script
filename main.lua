-- Function that starts the Kill Aura
local function StartKillAura()
    task.spawn(function()
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Workspace = game:GetService("Workspace")
        local LocalPlayer = Players.LocalPlayer

        repeat task.wait() until LocalPlayer.Character  
        local Character = LocalPlayer.Character  
        local RootPart = Character:FindFirstChild("HumanoidRootPart")  
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")

        LocalPlayer.CharacterAdded:Connect(function(newCharacter)  
            Character = newCharacter  
            repeat task.wait() until newCharacter:FindFirstChild("HumanoidRootPart")  
            RootPart = newCharacter:FindFirstChild("HumanoidRootPart")  
            Humanoid = newCharacter:FindFirstChildOfClass("Humanoid")
        end)  

        if not RootPart then return end  

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

        local MonsterService = GetMonsterService()  
        if not MonsterService then  
            warn("⚠️ MonsterService not found, stopping the script.")  
            return  
        end  

        local RequestAttack = MonsterService:FindFirstChild("RequestAttack")  
        if not RequestAttack then  
            warn("⚠️ RequestAttack not found, stopping the script.")  
            return  
        end  

        local AttackRange = 100  
        local CooldownTime = 0.1  
        local CurrentTarget = nil  
        local LastAttackTime = tick()  

        local function GetClosestEnemy()  
            local closestEnemy = nil  
            local minDistance = AttackRange  

            for _, obj in ipairs(Workspace:GetChildren()) do  
                if obj:IsA("Model") and obj ~= Character then  
                    local humanoid = obj:FindFirstChildOfClass("Humanoid")  
                    local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")  

                    if humanoid and humanoid.Health > 0 and hrp then  
                        local distance = (hrp.Position - RootPart.Position).Magnitude  
                        if distance < minDistance then  
                            closestEnemy = { hrp = hrp, humanoid = humanoid, distance = distance }
                            minDistance = distance  
                        end  
                    end  
                end  
            end  

            return closestEnemy  
        end

        while true do  
            if not RootPart or not RootPart.Parent then  
                RootPart = Character and Character:FindFirstChild("HumanoidRootPart")  
                if not RootPart then return end  
            end  

            -- Verifica se o tempo sem atacar passou de 2 segundos
            if tick() - LastAttackTime > 2 then  
                CurrentTarget = GetClosestEnemy()  
            end  

            if CurrentTarget then  
                local targetHRP = CurrentTarget.hrp  
                if targetHRP and targetHRP.Parent and CurrentTarget.humanoid.Health > 0 then  
                    local direction = (targetHRP.Position - RootPart.Position).unit  
                    RootPart.CFrame = CFrame.lookAt(RootPart.Position, RootPart.Position + Vector3.new(direction.X, 0, direction.Z))  

                    pcall(function()  
                        RequestAttack:InvokeServer(targetHRP.CFrame)  
                    end)  

                    LastAttackTime = tick()  -- Atualiza o tempo do último ataque
                else  
                    CurrentTarget = nil  -- Se o alvo ficou inválido, reseta
                end  
            end  

            task.wait(CooldownTime)  
        end  
    end)
end

while true do  
    local success, error = pcall(StartKillAura)  
    if not success then  
        warn("⚠️ Error in script: ", error)  
    end  
    task.wait(0.5)  
end
