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
    freeIndex = -1
    tag = KillConfirmedTag(spawnPosition, teamId, identifier, nil)

    for l_Index, l_TagInstance in ipairs(self.m_CurrentTags) do
        if l_TagInstance ~= nil then
            goto killed_cont
        end

        freeIndex = l_Index
        break

        ::killed_cont::
    end

    -- If there was not any free space in the current array, insert into the end
    if freeIndex == -1 then
        table.insert(self.m_CurrentTags, tag)
    end

    print("Added a new tag at location " .. spawnPosition.x .. " " .. spawnPosition.y .. " " .. spawnPosition.z)

    NetEvents:Broadcast("KC:CreateTag", spawnPosition.x, spawnPosition.y, spawnPosition.z, teamId, identifier)
    self.m_IdentifierCounter = self.m_IdentifierCounter + 1
end

-- IsPlayerInBounds(ServerPlayer player, Vec3 position, number size)
function KillConfirmedServer:IsPlayerInBounds(player, positionX, positionY, positionZ, size)
    if player == nil then
        return false
    end

    --print("player: " .. type(player))
    --print("x: " .. type(positionX))
    --print("y: " .. type(positionY))
    --print("z: " .. type(positionZ))

    local position = Vec3(positionX, positionY, positionZ)
    if position == nil then
        print("why is position nil")
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

    -- Get the player position
    local playerPosition = soldier.worldTransform.trans

    --print("x: " .. playerPosition.x .. " y: " .. playerPosition.y .. " z: " .. playerPosition.z)
    --print("size: " .. size)

    -- Why is position fucked up, erroring on position.z ???
    --print("x: " .. position.x .. " y: " .. position.y .. " z: " .. position.z)

    -- Crashes here
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
        
        for l_Index, l_TagInstance in ipairs(self.m_CurrentTags) do
            -- Validate that we have a good tag instance
            if l_TagInstance == nil then
                goto int_continue
            end

            local l_Tag = l_TagInstance
            local l_Pos = Vec3(l_Tag:GetPosition())
            --print("l_Pos: " .. type(l_Pos))

            if l_Pos == nil then
                print("Position is nil")
                goto int_continue
            end

            if self:IsPlayerInBounds(l_Player, l_Pos.x, l_Pos.y, l_Pos.z, self.m_BoxSize) == false then
                goto int_continue
            end

            -- Broadcast out to all clients to remove the tag
            local l_Identifier = l_Tag:GetIdentifier()
            --print("l_Identifier: " .. l_Identifier)

            NetEvents:Broadcast("KC:RemoveTag", l_Identifier)

            -- Enemy team collection
            if l_Tag:GetTeamId() ~= l_Player.teamId then
                -- Increment the ticket count by one
                ticketCount = TicketManager:GetTicketCount(l_Player.teamId)
                print("currentTicketCount: " .. ticketCount)
                ticketCount = ticketCount + 1.0
                TicketManager:SetTicketCount(l_Player.teamId, ticketCount)

                ticketCount = TicketManager:GetTicketCount(l_Player.teamId)
                print("newTicketCount: " .. ticketCount)
            else
                -- Decrement the ticket count by one (same team recovery)
                ticketCount = TicketManager:GetTicketCount(l_Player.teamId)

                -- Don't allow players to go negative ticket count
                if ticketCount == 0 then
                    goto int_continue
                end

                ticketCount = ticketCount - 1.0
                TicketManager:SetTicketCount(l_Player.teamId, ticketCount)
            end

            self.m_CurrentTags[l_Index] = nil

            ::int_continue::
        end

        ::continue::
    end
end

return KillConfirmedServer()