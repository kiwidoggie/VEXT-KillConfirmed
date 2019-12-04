class "KillConfirmedClient"

-- TODO: Implement creation of an object only client side that way it has no colision
-- TODO: Implement on corpus creation/player death that we create an area that someone can walk into
-- TODO: Implement sending events to the clients (from the server) in order to create said object/delete said object
-- TODO: Implement score manipulation manually adding points for each collection/restore
-- TODO: Beta test

function KillConfirmedClient:__init()
    -- Debug output
    print("initializing promod client")

    -- Engine update events
    self.m_EngineUpdateEvent = Events:Subscribe("Engine:Update", self, self.OnEngineUpdate)
    self.m_CreateTagEvent = NetEvents:Subscribe("KC:CreateTag", self, self.OnCreateTag)
    self.m_RemoveTagEvent = NetEvents:Subscribe("KC:RemoveTag", self, self.OnRemoveTag)

    -- Timer that gets added to each engine update (deltaTime gets added)
    self.m_UpdateTimer = 0.0

    -- Update tick frequency (default: 1/4 second)
    self.m_UpdateFreq = 0.25
end

function KillConfirmedClient:OnEngineUpdate(deltaTime, simulationDeltaTime)
    -- Add deltaTime to our current timer
    self.m_UpdateTimer = self.m_UpdateTimer + deltaTime

    -- If we elapse a tick, reset the timer and fire an event
    if self.m_UpdateTimer > self.m_UpdateFreq then
        self.m_UpdateTimer = 0.0
        self:OnClientTick()
    end
end

function KillConfirmedClient:OnCreateTag(spawnPosition, teamId, identifier)
    print("OnCreateTag called")

    print("TODO: create tag " .. spawnPosition.x .. " " .. spawnPosition.y .. " " .. spawnPosition.z .. " teamId: " .. teamId .. " ident: " .. identifier)
end

function KillConfirmedClient:OnRemoveTag(identifier)
    print("OnRemoveTag called ident: " .. identifier)
end

function KillConfirmedClient:OnClientTick()
end

return KillConfirmedClient()