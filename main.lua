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

        local AttackRange = 10 -- Alcance de ataque
        local CooldownTime = 0.1
        local targetHRP = nil

        local function GetEnemyInFront()
            local myPosition = RootPart.Position
            local myLookVector = RootPart.CFrame.LookVector

            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj ~= Character then
                    local humanoid = obj:FindFirstChildOfClass("Humanoid")
                    local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")

                    if humanoid and humanoid.Health > 0 and hrp then
                        local directionToEnemy = (hrp.Position - myPosition).unit
                        local dotProduct = directionToEnemy:Dot(myLookVector)
                        local distance = (hrp.Position - myPosition).Magnitude

                        -- Verifica se o inimigo está na frente e dentro do alcance
                        if dotProduct > 0.8 and distance <= AttackRange then
                            return { hrp = hrp, humanoid = humanoid }
                        end
                    end
                end
            end
            return nil
        end

        while task.wait(CooldownTime) do
            if not RootPart or not RootPart.Parent then break end

            -- Verifica se o alvo atual é inválido ou morto
            if not targetHRP or not targetHRP.hrp or not targetHRP.hrp.Parent or targetHRP.humanoid.Health <= 0 then
                targetHRP = GetEnemyInFront()
            end

            -- Ataca o alvo se ele for válido
            if targetHRP and targetHRP.hrp and targetHRP.hrp.Parent and targetHRP.humanoid.Health > 0 then
                pcall(function()
                    RequestAttack:InvokeServer(targetHRP.hrp.CFrame)
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