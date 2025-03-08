local function StartKillAura()
    task.spawn(function()
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Workspace = game:GetService("Workspace")
        local LocalPlayer = Players.LocalPlayer

        repeat task.wait() until LocalPlayer.Character
        local Character = LocalPlayer.Character
        local RootPart = Character:WaitForChild("HumanoidRootPart")
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")

        LocalPlayer.CharacterAdded:Connect(function(newCharacter)
            Character = newCharacter
            RootPart = newCharacter:WaitForChild("HumanoidRootPart")
            Humanoid = newCharacter:FindFirstChildOfClass("Humanoid")
        end)

        local MonsterService = ReplicatedStorage:WaitForChild("Packages")
            :WaitForChild("Knit")
            :WaitForChild("Services")
            :WaitForChild("MonsterService")
            :WaitForChild("RF")

        if not MonsterService then
            warn("⚠️ MonsterService não encontrado")
            return
        end

        local RequestAttack = MonsterService:FindFirstChild("RequestAttack")
        if not RequestAttack then
            warn("⚠️ RequestAttack não encontrado")
            return
        end

        local AttackRange = 100
        local CooldownTime = 0.1
        local CurrentTarget = nil  

        local function GetClosestEnemy()
            local closestEnemy, minDistance
            local myPosition = RootPart.Position

            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj:IsA("Model") and obj ~= Character then
                    local humanoid = obj:FindFirstChildOfClass("Humanoid")
                    local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")

                    if humanoid and humanoid.Health > 0 and hrp then
                        local distance = (hrp.Position - myPosition).Magnitude
                        if not minDistance or distance < minDistance and distance <= AttackRange then
                            closestEnemy = { hrp = hrp, humanoid = humanoid }
                            minDistance = distance
                        end
                    end
                end
            end
            return closestEnemy
        end

        while task.wait(CooldownTime) do
            if not RootPart.Parent then break end

            -- Se não há alvo ou o alvo morreu, busca um novo
            if not CurrentTarget or CurrentTarget.humanoid.Health <= 0 or (CurrentTarget.hrp.Position - RootPart.Position).Magnitude > AttackRange then
                CurrentTarget = GetClosestEnemy()
            end

            -- Ataca apenas se ainda houver um alvo válido
            if CurrentTarget then
                local targetHRP = CurrentTarget.hrp
                local direction = (targetHRP.Position - RootPart.Position).unit
                RootPart.CFrame = CFrame.lookAt(RootPart.Position, RootPart.Position + Vector3.new(direction.X, 0, direction.Z))

                pcall(function()
                    RequestAttack:InvokeServer(targetHRP.CFrame)
                end)
            end
        end
    end)
end

while task.wait(0.5) do
    local success, errorMsg = pcall(StartKillAura)
    if not success then
        warn("⚠️ Erro no script:", errorMsg)
    end
end
