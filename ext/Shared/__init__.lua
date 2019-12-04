class "KillConfirmedShared"

function KillConfirmedShared:__init()
    print("initializing promod shared")

    self.m_PartitionLoadedEvent = Events:Subscribe("Partition:Loaded", self, self.OnPartitionLoaded)
end

function KillConfirmedShared:OnPartitionLoaded(partition)
    -- Validate that our partition is valid
    if partition == nil then
        return
    end

    for _, instance in pairs(partition.instances) do
        -- We want to modify all ScoringTypeData's to zero them out
        -- This is so that we can manually add the scoring in kill-confirmed gametype
        if instance.typeInfo.name == "ScoringTypeData" then
            instance:MakeWritable()
            
            -- Validate that this is not a read-only instance
            if instance.typeInfo.isReadOnly == true then
                print("instance " .. instance.typeInfo.name .. " is read-only")
                goto continue
            end

            local scoringInstance = ScoringTypeData(instance)
            scoringInstance.score = 0.0
            scoringInstance.additionalValueMultiplier = 0.0
        end

        ::continue::
    end
end

return KillConfirmedShared()