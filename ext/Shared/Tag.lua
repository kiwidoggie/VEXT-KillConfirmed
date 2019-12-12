class "KillConfirmedTag"

-- KillConfirmedTag(Vec3 position, TeamId teamId, number Identifier, effect handle)
function KillConfirmedTag:__init(position, teamId, identifier, effect)
    self.m_Position = Vec3(position)
    self.m_TeamId = TeamId(teamId)
    self.m_Identifier = identifer
    self.m_Effect = effect
end

function KillConfirmedTag:GetPosition()
    return self.m_Position
end

function KillConfirmedTag:GetTeamId()
    return self.m_TeamId
end

function KillConfirmedTag:GetIdentifier()
    return self.m_Identifier
end

function KillConfirmedTag:GetEffect()
    return self.m_Effect
end