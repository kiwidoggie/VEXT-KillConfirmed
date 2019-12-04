class "KillConfirmedTag"

-- KillConfirmedTag(Vec3 position, TeamId teamId, number Identifier)
function KillConfirmedTag:__init(position, teamId, identifier)
    self.m_Position = position
    self.m_TeamId = teamId
    self.m_Identifier = identifer
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