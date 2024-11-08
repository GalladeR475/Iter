local PlayerService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Iter = require(ReplicatedStorage.Iter)

--// Greet the players!
function Greet(Player: Player): ()
    print(`Hello {Player.Name}! How are you?`)
end

--// Wait for some players to join..
task.wait(3)

--// First, we make an Iterator of all existing players
local Players = Iter.Values(PlayerService:GetPlayers())

--// Second, we use `ForEach` to greet all the players!
Players:ForEach(Greet)