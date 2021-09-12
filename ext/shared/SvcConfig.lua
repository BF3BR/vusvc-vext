SvcConfig = {
    Host = "https://localhost:5001",

    -- Should the http client verify the tls certificate
    Should_VerifyCertificate = false,

    -- Http request/response timeout in seconds
    BackendTimeout = 5,

    -- Length of the lobby code, this needs to match the backend
    BackendLobbyCodeLength = 4,

    -- Max lobby code length (default: 4)
    LobbyCodeMaxLength = 4,
}