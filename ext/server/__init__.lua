class "VuSvcServer"
require("__shared/VuSvc")

function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
 end

 function string.split(line)
    local s_Array = { }
    for token in string.gmatch(line, "[^%s]+") do
        --print(token)
        table.insert(s_Array, token)
     end

     return s_Array
 end

 
function VuSvcServer:__init()
    --self.m_PlayerJoiningEvent = Events:Subscribe("Player:Joining", self, self.OnPlayerJoining)
    self.m_PlayerRequestJoinHook = Hooks:Install("Player:RequestJoin", 1, self, self.OnPlayerRequestJoin)
    self.m_PlayerChatEvent = Events:Subscribe("Player:Chat", self, self.OnPlayerChat)

    self.m_Svc = VuSvc()

    self.m_Players = { }
end

function VuSvcServer:__gc()
end

function VuSvcServer:OnPlayerRequestJoin(p_Hook, p_JoinMode, p_AccountGuid, p_PlayerGuid, p_PlayerName)
    --print(p_AccountGuid)
    --print(p_PlayerGuid)

    local s_Id, s_Name = self.m_Svc:CreatePlayer(p_AccountGuid, p_PlayerName)
    if s_Id == nil or s_Name == nil then
        print("err: failed to register (" .. p_PlayerName .. ").")
        p_Hook:Return(false)
        return
    end

    print("Registered VuSvc Id: " .. tostring(s_Id) .. " Name: " .. s_Name)

    -- HACK: Save the id based on name
    self.m_Players[p_PlayerName] = s_Id

    p_Hook:Return(true)
end

function VuSvcServer:OnPlayerChat(p_Player, p_RecipientMask, p_Message)
    if p_Player == nil then
        return
    end

    local s_PlayerName = p_Player.name

    -- Handle lobby creation
    if string.starts(p_Message, "!create") then
        local s_SvcId = self.m_Players[s_PlayerName]
        if s_SvcId == nil then
            print("err: player tried to create a lobby without an id")
            return
        end

        local s_LobbyId, s_LobbyCode = self.m_Svc:CreateLobby(s_SvcId, "lobby_" .. s_PlayerName, 4)
        if s_LobbyId == nil or s_LobbyCode == nil then
            print("err: lobby id or code is nil.")
            return
        end

        ChatManager:SendMessage("Lobby (" .. s_LobbyId .. ") Code (" .. s_LobbyCode .. ") Size (4)")
    end

    -- Hanndle lobby joining
    if string.starts(p_Message, "!join") then
        local s_Parts = string.split(p_Message)
        if #s_Parts < 3 then
            print("err: not enough parts")
            return
        end

        -- s_Parts[1] = !join

        local s_LobbyId = s_Parts[2]
        --print("lobbyId: " .. s_LobbyId)

        local s_LobbyCode = s_Parts[3]
        --print("lobbyCode: " .. s_LobbyCode)

        --local s_ResponseData = self.m_Svc.JoinLobby()
    end
end

local g_VuSvcServer = VuSvcServer()