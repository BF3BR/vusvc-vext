class "VuSvcServer"
require("__shared/VuSvc")

function VuSvcServer:__init()
    --self.m_PlayerJoiningEvent = Events:Subscribe("Player:Joining", self, self.OnPlayerJoining)
    self.m_PlayerRequestJoinHook = Hooks:Install("Player:RequestJoin", 1, self, self.OnPlayerRequestJoin)

    self.m_Svc = VuSvc()
end

function VuSvcServer:__gc()
end

function VuSvcServer:OnPlayerRequestJoin(p_Hook, p_JoinMode, p_AccountGuid, p_PlayerGuid, p_PlayerName)
    print(p_AccountGuid)
    print(p_PlayerGuid)

    local s_Id, s_Name = self.m_Svc:CreatePlayer(p_AccountGuid, p_PlayerName)
    if s_Id == nil or s_Name == nil then
        print("err: failed to register (" .. p_PlayerName .. ").")
        p_Hook:Return(false)
        return
    end

    print("Registered VuSvc Id: " .. tostring(s_Id) .. " Name: " .. s_Name)

    p_Hook:Return(true)
end

local g_VuSvcServer = VuSvcServer()