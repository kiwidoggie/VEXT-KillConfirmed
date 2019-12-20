class "KillConfirmedClient"

require("__shared/Tag")

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

    -- Update tick frequency (default: 1/4 second = 0.25)
    self.m_UpdateFreq = 1

    self.m_FriendlySmoke = nil

    self.m_EnemyFire = nil

    -- Manual override for disabling effects
    self.m_DisableEffects = false

    self.m_Tags = { } 
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

function KillConfirmedClient:CreateEffect()
    -- If we have already found our effects, don't do anything
    if s_SmokeEffect ~= nil and s_FireEffect ~= nil then
        return true
    end

    -- Get Smoke FX/Ambient/Generic/FireSmoke/Smoke/SmokePillars/Generic/FX_Crater_Smoke_01_M
    local s_SmokeEffect = ResourceManager:SearchForInstanceByGUID(Guid('A5A43C6D-A713-4C19-8C24-F64BC740EF5F'))
    if s_SmokeEffect == nil then
        print("Could not get smoke effect")
        return false
    end

    self.m_FriendlySmoke = EffectBlueprint(s_SmokeEffect)

    -- Get the EffectBlueprint FX/Ambient/Generic/FireSmoke/Fire/FX_Prop_OilDrumFire_01
    local s_FireEffect = ResourceManager:SearchForInstanceByGUID(Guid('64D3EA22-1B96-4374-BAEB-39AC2FF641FC'))
    if s_FireEffect == nil then
        print("Could not find fire effect")
        return false
    end

    self.m_EnemyFire = EffectBlueprint(s_FireEffect)

    return true
end

function KillConfirmedClient:Delete(identifier)
end

function KillConfirmedClient:AddOrInsert()
end

function KillConfirmedClient:OnCreateTag(spawnPositionX, spawnPositionY, spawnPositionZ, teamId, identifier)
    print("OnCreateTag called")
    
    -- Manual override for disabling effects
    if self.m_DisableEffects == true then
        return
    end

    -- Ensure that we have our effects loaded
    if self:CreateEffect() ~= true then
        print("Could not get fire/smoke effects")
        return
    end

    local s_LocalPlayer = PlayerManager:GetLocalPlayer()
    if s_LocalPlayer == nil then
        print("Could not get local player")
        return
    end
    
    spawnPosition = Vec3(spawnPositionX, spawnPositionY, spawnPositionZ)

    local s_TeamId = s_LocalPlayer.teamId
    s_Params = EffectParams()
    s_Transform = LinearTransform()
    s_Transform.trans = spawnPosition

    if s_TeamId == teamId then
        -- Handle creation of a friendly effect
        s_EffectHandle = EffectManager:PlayEffect(self.m_FriendlySmoke, s_Transform, s_Params, true)
        if EffectManager:IsEffectPlaying(s_EffectHandle) == false then
            print("friendly effect not playing")
            return
        end
    else
        -- Handle creation of an enemy effect
        s_EffectHandle = EffectManager:PlayEffect(self.m_EnemyFire, s_Transform, s_Params, true)
        if EffectManager:IsEffectPlaying(s_EffectHandle) == false then
            print("enemy effect not playing")
            return
        end
    end

    

    --print("create tag " .. spawnPositionX .. " " .. spawnPositionY .. " " .. spawnPositionZ .. " teamId: " .. teamId .. " ident: " .. identifier .. " effectHandle: ")
    s_CreatedTag = KillConfirmedTag(spawnPosition, teamId, identifier, s_EffectHandle)
    
    print("Created effect")

    -- Iterate over all of the effects and see if we have any nil
    for l_Index, l_Tag in ipairs(self.m_Tags) do
        if l_Tag == nil then
            print("assigning effect to index: " .. l_Index)
            self.m_Tags[l_Index] = s_CreatedTag
            return
        end
    end

    -- If we don't have any nil available, insert
    table.insert(self.m_Tags, s_CreatedTag)
end

function KillConfirmedClient:OnRemoveTag(identifier)
    print("OnRemoveTag called ident: " .. identifier)

    for l_Index, l_Tag in ipairs(self.m_Tags) do
        if l_Tag:GetIdentifier() ~= identifier then
            goto continue
        end

        EffectManager:StopEffect(l_Tag:GetEffect())
        self.m_Tags[l_Index] = nil
        print("Removed Effect")
        break

        ::continue::
    end
end

function KillConfirmedClient:OnClientTick()
end

return KillConfirmedClient()