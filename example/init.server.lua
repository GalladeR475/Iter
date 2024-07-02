local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Iterator = require(ReplicatedStorage:WaitForChild("Iter"));

local Players = game:GetService("Players");

function ValidatePlayer(player: Player?): (boolean?)
    if (player) then
        local Character = player.Character or player.CharacterAdded:Wait();
        if (Character) then
            local Humanoid = Character:FindFirstChildWhichIsA("Humanoid");
            if (Humanoid) then
                return Humanoid.Health > 0;
            end;
        end;
    end;
    return;
end;

task.wait(5);

local Iter: Iterator.Iter<Player> = Iterator.FromTable(Players:GetPlayers());

local AlivePlayers = Iter
    :Filter(ValidatePlayer)
    :Collect();

print(AlivePlayers);