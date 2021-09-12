class "VuSvc"

-- Include our configuration
require("__shared/SvcConfig")

-- The different api paths for each category
VuSvcApis = {
    -- Player api
    Player = "/api/Player",

    -- Player command endpoints
    PlayerCmds = {
        Create = "/Create",
        Info = "/Info",
        List = "/"
    },

    -- Server api
    Server = "/api/Server",

    ServerCmds = {
        Get = "/",
        Output = "/Output",
        Error = "/Error",
        Remove = "/Remove",
        Create = "/Create"
    },

    -- Match api
    Match = "/api/Match",

    -- Lobby api
    Lobby = "/api/Lobby",

    -- Lobby command endpoints
    LobbyCmds = {
        Create = "/Create",
        Remove = "/Remove",
        Join = "/Join",
        Leave = "/Leave",
        GetStatus = "/Status",
        Update = "/Update"
    },

    -- Stats api
    Stats = "/api/Stats"
}

function VuSvc:__init()
    self.m_Host = SvcConfig.Host

    self.m_Headers = {
        ["Content-Type"] = "application/json"
    }
    self.m_Options = HttpOptions(self.m_Headers, SvcConfig.BackendTimeout)
    self.m_Options.verifyCertificate = SvcConfig.Should_VerifyCertificate
end


function VuSvc:Server_UpdateStatus()
end

function VuSvc:Server_GetSquads()
end

function VuSvc:Server_GetReturnLobby()
end

function VuSvc:MakeRequest(p_Api, p_Cmd, p_Request)
    -- Make sure we have a valid api
    if p_Api == nil then
        return nil
    end

    -- Make sure we have a valid cmd
    if p_Cmd == nil then
        return nil
    end

    -- If there is no request specified then create a empty table
    if p_Request == nil then
        p_Request = { }
    end
    
    -- Encode the table
    local s_EncodedData = json.encode(p_Request)
    if s_EncodedData == nil then
        print("err: could not encode data.")
        return nil
    end

    -- Send a sync request to the backend
    local s_Response = Net:PostHTTP(self:CreateUrl(p_Api, p_Cmd), s_EncodedData, self.m_Options)
    if s_Response == nil then
        print("err: could not get response.")
        return nil
    end

    -- Make sure that we get a success status
    if s_Response.status ~= 200 then
        print("err: response status returned " .. s_Response.status)
        return nil
    end

    -- Decode the response data
    local s_ResponseTable = json.decode(s_Response.body)
    if s_ResponseTable == nil then
        print("err: could not decode json response.")
        return nil
    end

    return s_ResponseTable
end

--[[
    =========================================================
    Player APIs
    =========================================================
]]--

--[[
    CreatePlayer

    This will create a new player on the backend, or if the player exists will return
    the existing data for that player.

    p_ZeusId - Guid - The input guid
    p_PlayerName - String - The players current server name

    Returns:
    Guid BackendGuid, String BackendName

    or nil on error
]]--
function VuSvc:CreatePlayer(p_ZeusId, p_PlayerName)
    -- Create the CreatPlayerRequest
    local s_CreatePlayerRequest = {
        ["ZeusId"] = tostring(p_ZeusId),
        ["Name"] = p_PlayerName
    }

    -- Get the player data
    local s_PlayerData = self:MakeRequest(VuSvcApis.Player, VuSvcApis.PlayerCmds.Create, s_CreatePlayerRequest)
    if s_PlayerData == nil then
        print("err: could not get player data.")
        return nil
    end

    -- DEBUG: Uncomment below
    --print(s_PlayerData)

    -- Get the player id
    local s_PlayerBackendId = s_PlayerData["playerId"]
    if s_PlayerBackendId == nil then
        print("err: player data id missing.")
        return nil
    end

    -- Get the player backend name
    local s_PlayerBackendName = s_PlayerData["name"]
    if s_PlayerBackendName == nil then
        print("err: player data name missing.")
        return nil
    end

    print("CreatePlayer Ret: (" .. s_PlayerBackendId .. ") Name: " .. s_PlayerBackendName)

    return s_PlayerBackendId, s_PlayerBackendName
end

--[[
    GetPlayerInfo
    Guid p_SvcId - Player id from the backend

    Returns:
    Table or nil on error
]]
function VuSvc:GetPlayerInfo(p_SvcId)
    -- Send a sync request to the backend
    local s_Response = Net:GetHTTP(self:CreateUrl(VuSvcApis.Player, VuSvcApis.PlayerCmds.Info) .. "/" .. p_SvcId, self.m_Options)
    if s_Response == nil then
        print("err: could not get response.")
        return nil
    end

    -- Make sure that we get a success status
    if s_Response.status ~= 200 then
        print("err: response status returned " .. s_Response.status)
        return nil
    end

    -- Decode the response data
    local s_ResponseTable = json.decode(s_Response.body)
    if s_ResponseTable == nil then
        print("err: could not decode json player info response.")
        return nil
    end

    return s_ResponseTable
end

--[[
    GetPlayers
    Gets all players currently active on the server
    NOTE: This is admin/debug functionality only

    Returns:
    SafePlayerInfo[] or nil on error
]]--
function VuSvc:GetPlayers()
    -- This is debug/admin only functionality
    return nil
end

--[[
    =========================================================
    Lobby APIs
    =========================================================
]]--


--[[
    CreateLobby
    Guid p_PlayerId - Requesting player id
    String p_LobbyName - Lobby name
    int p_MaxPlayers - Maximum players for this lobby

    Returns:
    Guid LobbyId
    String LobbyCode
]]--
function VuSvc:CreateLobby(p_PlayerId, p_LobbyName, p_MaxPlayers)
    if p_PlayerId == nil then
        print("err: invalid player id.")
        return nil
    end

    local s_CreateLobbyRequest = {
        ["playerId"] = p_PlayerId,
        ["name"] = p_LobbyName,
        ["maxPlayers"] = p_MaxPlayers
    }

    local s_LobbyData = self:MakeRequest(VuSvcApis.Lobby, VuSvcApis.LobbyCmds.Create, s_CreateLobbyRequest)
    if s_LobbyData == nil then
        print("err: could not get lobby data.")
        return nil
    end

    local s_LobbyId = s_LobbyData["lobbyId"]
    if s_LobbyId == nil then
        print("err: could not decode lobby id")
        return nil
    end

    local s_LobbyCode = s_LobbyData["code"]
    if s_LobbyCode == nil then
        print("err: could not decode lobby code")
        return nil
    end

    return s_LobbyId, s_LobbyCode
end

--[[
    GetLobbyStatus
    p_LobbyId - Guid - The guid of the lobby
    p_Code - String - The lobby code that is given on creation

    Returns:
    Guid LobbyId, int MaxPlayerCount, string[] PlayerNamesArray
    
    or nil on error
]]--
function VuSvc:GetLobbyStatus(p_LobbyId, p_LobbyCode)
    -- Validate our lobby id and code length
    if p_LobbyId == nil or #p_LobbyCode ~= SvcConfig.BackendLobbyCodeLength then
        print("err: invalid lobby id or code.")
        return nil
    end

    -- Create a new request
    local s_GetLobbyStatusRequest = {
        ["lobbyId"] = tostring(p_LobbyId),
        ["code"] = p_LobbyCode
    }

    -- Get the request in JSON format
    local s_GetLobbyStatusData = json.encode(s_GetLobbyStatusRequest)

    -- Post to the backend
    local s_Response = Net:PostHTTP(self:CreateUrl(VuSvcApis.Lobby, VuSvcApis.LobbyCmds.GetStatus), s_GetLobbyStatusData, self.m_Options)
    if s_Response == nil then
        print("err: could not get a response.")
        return nil
    end

    -- Verify the response status
    if s_Response.status ~= 200 then 
        print("err: incorrect response status (" .. s_Response.status .. ")")
        return nil
    end

    -- Decode our JSON data back to a table
    local s_LobbyStatusResponse = json.decode(s_Response.body)
    if s_LobbyStatusResponse == nil then
        print("err: could not decode the lobby status response.")
        return nil
    end

    -- Get the lobby id
    local s_LobbyId = s_LobbyStatusResponse["lobbyId"]
    if s_LobbyId == nil then
        print("err: could not decode lobby id.")
        return nil
    end

    -- Get the lobby max player count
    local s_MaxPlayerCount = s_LobbyStatusResponse["maxPlayerCount"]
    if s_MaxPlayerCount == nil then
        print("err: could not decode max player count.")
        return nil
    end

    -- Get all of the player names in the lobby
    local s_PlayerNamesArray = s_LobbyStatusResponse["playerNames"]
    if s_PlayerNamesArray == nil then
        print("err: could not decode player names array.")
        return nil
    end

    return s_LobbyId, s_MaxPlayerCount, s_PlayerNamesArray
end

function VuSvc:CreateUrl(p_Api, p_Cmd)
    return self.m_Host .. p_Api .. p_Cmd
end

return VuSvc