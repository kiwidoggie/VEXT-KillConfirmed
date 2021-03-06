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
    self.m_UpdateFreq = 1.25

    self.m_FriendlySmoke = nil

    self.m_EnemyFire = nil

    self.m_ClonedFireEmitterTemplateData = nil

    self.m_ClonedFireEmitterDocument = nil

    self.m_ClonedFireEffectBlueprint = nil

    -- Manual override for disabling effects
    self.m_DisableEffects = false

    self.m_Tags = { } 

    self.m_Params = EffectParams()
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
    if self.m_FriendlySmoke ~= nil and self.m_EnemyFire ~= nil then
        return true
    end

    print("get fire effect resource")
    -- Get the EffectBlueprint FX/Ambient/Generic/FireSmoke/Fire/FX_Prop_OilDrumFire_01
    s_FireEffectResource = ResourceManager:SearchForInstanceByGUID(Guid('64D3EA22-1B96-4374-BAEB-39AC2FF641FC'))
    if s_FireEffectResource == nil then
        print("could not find fire effect resource")
        return false
    end

    print("get effect blueprint")
    s_FireEffectBlueprint = EffectBlueprint(s_FireEffectResource)
    if s_FireEffectBlueprint == nil then
        print("could not find fire effect blueprint")
        return false
    end

    -- First we need to clone the object that will be pointed to by the cloned fire effect
    print("get blueprint object")
    s_FireEffectBlueprintObject = s_FireEffectBlueprint.object
    if s_FireEffectBlueprintObject == nil then
        print("could not find fire effect blueprint object")
        return false
    end

    print("get effect entity data")
    s_FireEffectEntityData = EffectEntityData(s_FireEffectBlueprintObject) --ResourceManager:SearchForInstanceByGUID(Guid('068E2B44-4D6D-4A2C-92E9-6D1D433EB8EE'))
    if s_FireEffectEntityData == nil then
        print("could not find fire effect entity data")
        return false
    end

    print("get fire emitter document resource")
    -- Get the emitter document for the emitter entity data
    -- EmitterDocument fx/ambient/generic/firesmoke/fire/vertical/emitter_s/em_amb_generic_fire_vertical_s_01/51CD26B2-3E01-481A-BF4A-40B0D7806D07
    s_FireEmitterDocumentResource = ResourceManager:SearchForInstanceByGUID(Guid('51CD26B2-3E01-481A-BF4A-40B0D7806D07'))
    if s_FireEmitterDocumentResource == nil then
        print("could not find fire emitter document resource")
        return false
    end

    print("get emitter document")
    s_FireEmitterDocument = EmitterDocument(s_FireEmitterDocumentResource)
    if s_FireEmitterDocument == nil then
        print("could not find the fire emitter document")
        return false
    end

    print("get template data")
    s_FireEmitterTemplateDataResource = s_FireEmitterDocument.templateData
    if s_FireEmitterTemplateDataResource == nil then
        print("could not find fire emitter template data resource")
        return false
    end

    print("get fire emitter template data")
    s_FireEmitterTemplateData = EmitterTemplateData(s_FireEmitterTemplateDataResource)
    if s_FireEmitterTemplateData == nil then
        print("could not get fire emitter template data")
        return false
    end

    print("get cloned emitter template data")
    -- First clone the fire emitter template data, as that is where we change the colors and shit
    self.m_ClonedFireEmitterTemplateData = EmitterTemplateData(s_FireEmitterTemplateData:Clone())
    if self.m_ClonedFireEmitterTemplateData == nil then
        print("could not clone the fire emitter template data")
        return false
    end

    -- Change the radius and color to blue
    print("changing color to blue")
    self.m_ClonedFireEmitterTemplateData:MakeWritable()
    self.m_ClonedFireEmitterTemplateData.pointLightRadius = 9999.0
    self.m_ClonedFireEmitterTemplateData.pointLightColor = Vec3(0.0, 0.0, 9999.0) -- r, g, b
    self.m_ClonedFireEmitterTemplateData.pointLightIntensity = Vec4(1.0, 1.0, 1.0, 1.0)
    self.m_ClonedFireEmitterTemplateData.lightMultiplier = 9999.0
    self.m_ClonedFireEmitterTemplateData.pointLightRandomIntensityMin = 15.0
    self.m_ClonedFireEmitterTemplateData.pointLightRandomIntensityMax = 16.0
    self.m_ClonedFireEmitterTemplateData.actAsPointLight = true
    self.m_ClonedFireEmitterTemplateData.pointLightMinClamp = 15.0
    self.m_ClonedFireEmitterTemplateData.pointLightMaxClamp = 999999.0
    self.m_ClonedFireEmitterTemplateData.distanceScaleNearValue = 100.0
    self.m_ClonedFireEmitterTemplateData.distanceScaleFarValue = 100.0
    self.m_ClonedFireEmitterTemplateData.distanceScaleLength = 100.0
    self.m_ClonedFireEmitterTemplateData.maxSpawnDistance = 100.0
    -- Clone the emitter document
    print("cloned fire emitter document")
    self.m_ClonedFireEmitterDocument = EmitterDocument(s_FireEmitterDocument:Clone())
    if self.m_ClonedFireEmitterDocument == nil then
        print("could not clone the fire emitter document")
        return false
    end

    -- Change our target template data to the cloned one
    print("assigning template data")
    self.m_ClonedFireEmitterDocument:MakeWritable()
    self.m_ClonedFireEmitterDocument.templateData = self.m_ClonedFireEmitterTemplateData

    print("cloned fire effect entity data")
    self.m_ClonedFireEffectEntityData = EffectEntityData(s_FireEffectEntityData:Clone())
    if self.m_ClonedFireEffectEntityData == nil then
        print("could not clone the fire effect entity data")
        return false
    end

    print("iterations")
    for index, component in ipairs(self.m_ClonedFireEffectEntityData.components) do
        -- TODO: We need to clone all of the components
        --print("index: " .. index)

        if component.typeInfo.name ~= "EmitterEntityData" then
            goto component_continue
        end

        l_Component = EmitterEntityData(component)
        l_EmitterEntityData = EmitterEntityData(l_Component:Clone())
        l_EmitterEntityData:MakeWritable()
        l_EmitterEntityData.emitter = self.m_ClonedFireEmitterDocument

        print("updating our cloned components")
        self.m_ClonedFireEffectEntityData.components:set(index, l_EmitterEntityData)
        ::component_continue::
    end

    self.m_ClonedFireEffectBlueprint = EffectBlueprint(s_FireEffectBlueprint:Clone())
    if self.m_ClonedFireEffectBlueprint == nil then
        print("could not clone fire effect blueprint")
        return false
    end
    self.m_ClonedFireEffectBlueprint:MakeWritable()
    self.m_ClonedFireEffectBlueprint.object = self.m_ClonedFireEffectEntityData

    self.m_FriendlySmoke = self.m_ClonedFireEffectBlueprint
    self.m_EnemyFire = s_FireEffectBlueprint
    -- TODO: Need to clone this, and any references that we need to manipulate
    -- This involves modifying:
    -- https://github.com/Powback/Venice-EBX/blob/071473993867cd2297dc662517c61edaff51e8fe/FX/Ambient/Generic/FireSmoke/Fire/Vertical/Emitter_S/Em_Amb_Generic_LowEnd_Fire_Vertical_S_01.txt#L21
    -- https://github.com/Powback/Venice-EBX/blob/071473993867cd2297dc662517c61edaff51e8fe/FX/Ambient/Generic/FireSmoke/Fire/Vertical/Emitter_S/Em_Amb_Generic_LowEnd_Fire_Vertical_S_01.txt#L14
    -- https://github.com/Powback/Venice-EBX/blob/071473993867cd2297dc662517c61edaff51e8fe/FX/Ambient/Generic/FireSmoke/Fire/Vertical/FX_Amb_Generic_Fire_Vertical_S_01.txt#L1

    return true
end

function KillConfirmedClient:OnCreateTag(spawnPositionX, spawnPositionY, spawnPositionZ, teamId, identifier)
    --print("OnCreateTag called")
    --print("spawnPositionX: " .. type(spawnPositionX))
    --print("spawnPositionY: " .. type(spawnPositionY))
    --print("spawnPositionZ: " .. type(spawnPositionZ))
    --print("teamId: " .. type(teamId))
    --print("identifier: " .. type(identifier))
    
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

    local s_PlayerTeamId = s_LocalPlayer.teamId
    
    s_Transform = LinearTransform()
    s_Transform.trans = spawnPosition

    if s_PlayerTeamId == teamId then
        -- Handle creation of a friendly effect
        print("spawn friendly")
        s_EffectHandle = EffectManager:PlayEffect(self.m_FriendlySmoke, s_Transform, self.m_Params, true)
        if EffectManager:IsEffectPlaying(s_EffectHandle) == false then
            print("friendly effect not playing")
            return
        end
    else
        print("spawn enemy")
        -- Handle creation of an enemy effect
        s_EffectHandle = EffectManager:PlayEffect(self.m_EnemyFire, s_Transform, self.m_Params, true)
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
        if l_Tag == nil then
            goto continue
        end
        
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
    -- Do Nothing
end

return KillConfirmedClient()