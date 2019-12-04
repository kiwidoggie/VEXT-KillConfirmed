class "KillConfirmedServer"

require("__shared/Tag")

function KillConfirmedServer:__init()
    print("initializing promod server")

    self.m_PlayerKilledEvent = Events:Subscribe("Player:Killed", self, self.OnPlayerKilled)

    self.m_EngineUpdateEvent = Events:Subscribe("Engine:Update", self, self.OnEngineUpdate)

    -- Timer that gets added to each engine update (deltaTime gets added)
    self.m_UpdateTimer = 0.0

    -- Update tick frequency (default: 1 second)
    self.m_UpdateFreq = 0.15

    -- Box size in game units
    self.m_BoxSize = 1.5

    -- Array of tags
    self.m_CurrentTags = { }

    self.m_IdentifierCounter = 0
end

function KillConfirmedServer:OnPlayerKilled(player, inflictor, position, weapon, roadkill, headshot, victimInReviveState)
    -- Check that we have a valid player
    if player == nil then
        return
    end

    -- Skip suicides
    if player == inflictor then
        return
    end

    local teamId = player.teamId
    -- We want the death position to be within bounds
    local spawnPosition = Vec3(position.x, position.y + 0.75, position.z)

    -- Create a new tag and add it to the list
    identifier = self.m_IdentifierCounter
    tag = KillConfirmedTag(spawnPosition, teamId, identifier)

    table.insert(self.m_CurrentTags, tag)

    print("Added a new tag at location " .. spawnPosition.x .. " " .. spawnPosition.y .. " " .. spawnPosition.z)

    NetEvents:Broadcast("KC:CreateTag", spawnPosition, teamId, identifier)
    self.m_IdentifierCounter = self.m_IdentifierCounter + 1
end

-- IsPlayerInBounds(ServerPlayer player, Vec3 position, number size)
function KillConfirmedServer:IsPlayerInBounds(player, position, size)
    if player == nil then
        return false
    end

    -- Check if our player is alive
    if player.alive == false then
        return false
    end

    -- Check if the player has a soldier
    if player.hasSoldier == false then
        return false
    end

    local soldier = player.soldier
    if soldier == nil then
        return false
    end

    local playerPosition = soldier.worldTransform.trans

    local minPosition = Vec3(position.x - size, position.y - size, position.z - size)
    local maxPosition = Vec3(position.x + size, position.y + size, position.z + size)

    -- Check to see if our player position is within these coordinates
    if (playerPosition.x > minPosition.x and playerPosition.x < maxPosition.x) and
        (playerPosition.y > minPosition.y and playerPosition.y < maxPosition.y) and
        (playerPosition.z > minPosition.z and playerPosition.z < maxPosition.z) then
            return true
    end

    return false
end

function KillConfirmedServer:OnEngineUpdate(deltaTime, simulationDeltaTime)
    -- Add deltaTime to our current timer
    self.m_UpdateTimer = self.m_UpdateTimer + deltaTime

    -- If we elapse a tick, reset the timer and fire an event
    if self.m_UpdateTimer > self.m_UpdateFreq then
        self.m_UpdateTimer = 0.0
        self:OnServerTick()
    end
end

function KillConfirmedServer:OnServerTick()
    --print("OnServerTick: Called")
    
    s_Players = PlayerManager:GetPlayers()
    for _, l_Player in pairs(s_Players) do
        if l_Player == nil then
            goto continue
        end
        

        local l_RemoveIndicies = { }

        for l_Index, l_Tag in pairs(self.m_CurrentTags) do
            if self:IsPlayerInBounds(l_Player, l_Tag:GetPosition(), l_Tag:GetTeamId()) == false then
                goto int_continue
            end

            -- Add this tag index for removabl for later (if we do this in the loop shit gets all fucked up)
            table.insert(l_RemoveIndicies, l_Index)

            -- Broadcast out to all clients to remove the tag
            NetEvents:Broadcast("KC:RemoveTag", l_Tag:GetIdentifier())

            -- Increment the ticket count by one
            ticketCount = TicketManager:GetTicketCount(l_Player.teamId)
            ticketCount = ticketCount + 1
            TicketManager:SetTicketCount(l_Player.teamId, ticketCount)

            ::int_continue::
        end

        -- Remove all of the current tags bnased on index that have been "picked up"
        for _, l_RemoveIndex in pairs(l_RemoveIndicies) do
            table.remove(self.m_CurrentTags, l_RemoveIndex)
        end

        ::continue::
    end
end

return KillConfirmedServer()