Config = Config or {}

Config.Lang = "EE" -- Default: EN [Language option]

Config.Logs = true -- Default: false [Enables logs feature with depedency resource]

-- Core Settings
Config.IdentifierType = 'steam' --[Select identifier type]
Config.ESXCoreName = 'ncfw' --[Select Framework name for ESX]
Config.QBCoreName = 'qb-core' --[Select Framework name for QBUS]
Config.VORPCoreName = "vorp_core" --[Select Framework name for REDM VORP]

-- Gametype Feature Toggles
Config.RedM = false --[Select GameType for CFX]
Config.Fivem = true

-- Checks
Config.UserCheck = false --[User account creation and data check]
Config.SavePlayersHours = false --[User playhours ] IDK why is this here
Config.Whitelist = true --[User whitelist check ]
Config.NameCheck = false --[User name check ]
Config.Discord = false --[User discord check ]
Config.Identifier = true --[User license check ]
Config.Ban = true --[User ban check ]


-- Whitelist strings


Config.UCPWebsite = "https://fivemucp.vercel.app" -- Your FivemServer UCP
