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
            return ReplicatedStorage:WaitForChild("Packages")
                :WaitForChild("Knit")
                :WaitForChild("Services")
                :WaitForChild("MonsterService")
                :WaitForChild("RF")
        end

        local MonsterService = GetMonsterService()
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
            local closestEnemy = nil
            local minDistance = math.huge
            local myPosition = RootPart.Position

            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj ~= Character then
                    local humanoid = obj:FindFirstChildOfClass("Humanoid")
                    local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")

                    if humanoid and humanoid.Health > 0 and hrp then
                        local distance = (hrp.Position - myPosition).Magnitude
                        if distance < minDistance and distance <= AttackRange then
                            closestEnemy = {
                                hrp = hrp,
                                humanoid = humanoid,
                                distance = distance
                            }
                            minDistance = distance
                        end
                    end
                end
            end
            return closestEnemy
        end

        while true do
            if not RootPart or not RootPart.Parent then
                RootPart = Character:FindFirstChild("HumanoidRootPart")
                if not RootPart then break end
            end

            CurrentTarget = GetClosestEnemy()

            if CurrentTarget then
                local targetHRP = CurrentTarget.hrp
                if targetHRP and targetHRP.Parent and CurrentTarget.humanoid.Health > 0 then
                    local direction = (targetHRP.Position - RootPart.Position).unit
                    RootPart.CFrame = CFrame.lookAt(
                        RootPart.Position,
                        RootPart.Position + Vector3.new(direction.X, 0, direction.Z)
                    )

                    pcall(function()
                        RequestAttack:InvokeServer(targetHRP.CFrame)
                    end)
                else
                    CurrentTarget = nil
                end
            end

            task.wait(CooldownTime)
        end
    end)
end

while true do
    local success, error = pcall(StartKillAura)
    if not success then
        warn("⚠️ Erro no script: ", error)
    end
    task.wait(0.5)
end