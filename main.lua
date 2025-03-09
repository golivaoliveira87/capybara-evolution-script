local UserInputService = game:GetService("UserInputService") -- Serviço para detectar inputs do usuário
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Função para iniciar o Kill Aura
local function StartKillAura()
    task.spawn(function()
        -- Espera até que o personagem do jogador seja carregado
        repeat task.wait() until LocalPlayer.Character
        local Character = LocalPlayer.Character
        local RootPart = Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")

        -- Atualiza os dados quando o personagem do jogador é alterado
        LocalPlayer.CharacterAdded:Connect(function(newCharacter)
            Character = newCharacter
            repeat task.wait() until newCharacter:FindFirstChild("HumanoidRootPart")
            RootPart = newCharacter:FindFirstChild("HumanoidRootPart")
            Humanoid = newCharacter:FindFirstChildOfClass("Humanoid")
        end)

        -- Se o RootPart não for encontrado, encerra a função
        if not RootPart then return end

        -- Função para obter o MonsterService do ReplicatedStorage
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

        -- Obtém o MonsterService
        local MonsterService = GetMonsterService()
        if not MonsterService then
            warn("⚠️ MonsterService não encontrado, parando o script.")
            return
        end

        -- Obtém a função RequestAttack do MonsterService
        local RequestAttack = MonsterService:FindFirstChild("RequestAttack")
        if not RequestAttack then
            warn("⚠️ RequestAttack não encontrado, parando o script.")
            return
        end

        -- Parâmetros
        local AttackRange = 100 -- Alcance de ataque
        local CooldownTime = 0.1 -- Tempo entre os ataques
        local CurrentTarget = nil -- Alvo atual do Kill Aura
        local NearbyEnemies = {} -- Lista de inimigos próximos
        local LastSearchTime = 0 -- Momento da última busca por inimigos

        -- Função para obter inimigos próximos
        local function GetNearbyEnemies()
            local enemies = {}

            -- Itera por todos os objetos no Workspace
            for _, obj in ipairs(Workspace:GetChildren()) do
                -- Verifica se o objeto é um modelo e não é o personagem do jogador
                if obj:IsA("Model") and obj ~= Character then
                    local humanoid = obj:FindFirstChildOfClass("Humanoid") -- Verifica se o modelo tem um Humanoid
                    local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") -- Verifica se o modelo tem o HumanoidRootPart ou Head

                    -- Se o modelo tem um Humanoid e é um inimigo
                    if humanoid and humanoid.Health > 0 and hrp then
                        local distance = (hrp.Position - RootPart.Position).Magnitude -- Calcula a distância entre o jogador e o inimigo
                        if distance <= AttackRange then
                            -- Adiciona o inimigo à lista
                            enemies[#enemies + 1] = { hrp = hrp, humanoid = humanoid, distance = distance }
                        end
                    end
                end
            end

            -- Ordena os inimigos pela distância mais próxima
            table.sort(enemies, function(a, b) return a.distance < b.distance end)

            return enemies
        end

        -- Função para limpar a lista de inimigos após 5 segundos
        local function ClearEnemiesAfterDelay()
            while true do
                task.wait(5) -- Espera 5 segundos
                NearbyEnemies = {} -- Limpa a lista de inimigos
                CurrentTarget = nil -- Reseta o alvo atual
            end
        end

        -- Inicia a thread para limpar a lista de inimigos
        task.spawn(ClearEnemiesAfterDelay)

        -- Detecta quando uma tecla é pressionada
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end -- Ignora se o jogo já processou o input

            -- Verifica se a tecla pressionada é a tecla desejada (por exemplo, a tecla "E")
            if input.KeyCode == Enum.KeyCode.E then
                NearbyEnemies = GetNearbyEnemies() -- Atualiza a lista de inimigos
                if #NearbyEnemies > 0 then
                    CurrentTarget = NearbyEnemies[1] -- Define o alvo como o inimigo mais próximo
                else
                    CurrentTarget = nil -- Se não houver inimigos, reseta o alvo
                end
            end
        end)

        -- Loop principal que verifica e ataca os inimigos
        while true do
            -- Verifica se o RootPart ainda existe, se não, tenta encontrá-lo novamente
            if not RootPart or not RootPart.Parent then
                RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
                if not RootPart then return end
            end

            -- Se houver um alvo, realiza o ataque
            if CurrentTarget then
                local targetHRP = CurrentTarget.hrp
                if RootPart and targetHRP then
                    -- Calcula a direção do ataque e ajusta a rotação do personagem
                    local direction = (targetHRP.Position - RootPart.Position).unit
                    RootPart.CFrame = CFrame.lookAt(RootPart.Position, RootPart.Position + Vector3.new(direction.X, 0, direction.Z))

                    -- Realiza o ataque
                    pcall(function()
                        RequestAttack:InvokeServer(targetHRP.CFrame)
                    end)
                end
            end

            -- Espera o tempo de cooldown antes de tentar atacar novamente
            task.wait(CooldownTime)
        end
    end)
end

-- Loop que tenta iniciar o Kill Aura repetidamente
while true do
    -- Tenta executar a função StartKillAura
    local success, error = pcall(StartKillAura)
    if not success then
        warn("⚠️ Erro no script: ", error) -- Se ocorrer um erro, exibe um aviso
    end
    task.wait(0.5) -- Espera meio segundo antes de tentar novamente
end