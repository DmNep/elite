# ELITE
# Unofficial fan remake for the Windows console.
# Not the ZX Spectrum ROM, and not the original source.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\Elite.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\Elite.ps1 -SelfTest

param([switch]$SelfTest)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$script:Inv = [Globalization.CultureInfo]::InvariantCulture
$script:SaveDir = Join-Path $env:LOCALAPPDATA 'ElitePS'
$script:SavePath = Join-Path $script:SaveDir 'commander.json'
$script:AsyncKeys = $false
$script:UseAnsi = $false
$script:ConsoleOn = $false
$script:Fatal = $null
$script:W = 0
$script:H = 0
$script:SmallWarned = $false
$script:Sb = $null
$script:M = $null
$script:Buf = $null
$script:ViewTmp = $null
$script:StM = $null
$script:StSpin = 0.0
$script:FaceVis = $null
$script:BoltM = $null
$script:Market = $null
$script:NoSpawn = $false
$script:KeyPrev = @{}
$script:QuietPresent = $false
$script:Dots = $null
$script:Pri = $null
$script:Cam = $null
$script:View = 0
$script:Laser = @('pulse', 'none', 'none', 'none')
$script:ShieldF = 100.0
$script:ShieldA = 100.0
$script:DialPitch = 0.0
$script:DialRoll = 0.0
$script:EcmT = 0.0
$script:ScanRange = 10240.0
$script:ScanDots = $null
$script:ScanBuf = $null
$script:ScanCol = $null
$script:Heat = 0.0
$script:Temp = 0.0
$script:MissileArm = 0
$script:ECM = $false
$script:Scoops = $false
$script:EscapePod = $false
$script:Bomb = 0
$script:EnergyUnit = $false
$script:GalCharges = 0
$script:HasCloak = $false
$script:CloakOn = $false
$script:Heavy = 0
$script:Nova = 0
$script:NovaSys = -1
$script:Cloak = 0
$script:Base = 0
$script:FitMount = 0
$script:Rare = 'Krait'
$script:InTorus = $false
$script:JumpT = 0.0
$script:Tick = 0
$script:Pending = New-Object System.Collections.Generic.List[object]
$script:Escaping = $false
$script:Energy = 100.0
$script:EnergyMax = 100.0
$script:ViewName = @('FRONT', 'REAR', 'LEFT', 'RIGHT')

# Palette matches ANSI 30-37 then 90-97.
# 0 black  1 red  2 green  3 yellow  4 blue  5 magenta  6 cyan  7 gray
# 8 dark gray  9 bright red  10 bright green  11 bright yellow
# 12 bright blue  13 bright magenta  14 bright cyan  15 white

$script:Ansi = @(
    "$([char]27)[30m", "$([char]27)[31m", "$([char]27)[32m", "$([char]27)[33m",
    "$([char]27)[34m", "$([char]27)[35m", "$([char]27)[36m", "$([char]27)[37m",
    "$([char]27)[90m", "$([char]27)[91m", "$([char]27)[92m", "$([char]27)[93m",
    "$([char]27)[94m", "$([char]27)[95m", "$([char]27)[96m", "$([char]27)[97m"
)
$script:Pal = @(
    [ConsoleColor]::Black, [ConsoleColor]::DarkRed, [ConsoleColor]::DarkGreen, [ConsoleColor]::DarkYellow,
    [ConsoleColor]::DarkBlue, [ConsoleColor]::DarkMagenta, [ConsoleColor]::DarkCyan, [ConsoleColor]::Gray,
    [ConsoleColor]::DarkGray, [ConsoleColor]::Red, [ConsoleColor]::Green, [ConsoleColor]::Yellow,
    [ConsoleColor]::Blue, [ConsoleColor]::Magenta, [ConsoleColor]::Cyan, [ConsoleColor]::White
)

$script:EcoName = @(
    'Rich Industrial', 'Average Industrial', 'Poor Industrial', 'Mainly Industrial',
    'Mainly Agricultural', 'Rich Agricultural', 'Average Agricultural', 'Poor Agricultural'
)
$script:GovName = @(
    'Anarchy', 'Feudal', 'Multi-Gov', 'Dictatorship',
    'Communist', 'Confederacy', 'Democracy', 'Corporate'
)
$script:Ranks = @(
    @(0, 'Harmless'), @(8, 'Mostly Harmless'), @(16, 'Poor'), @(32, 'Average'),
    @(64, 'Above Average'), @(128, 'Competent'), @(512, 'Dangerous'),
    @(2560, 'Deadly'), @(6400, 'Elite')
)
$script:Syl = @(
    'ar','on','en','is','or','an','us','er','in','al','es','ed','ra','le','ve','ti',
    'so','me','di','qa','xe','zo','ka','ri','th','ae','io','ya','ul','ox','qu','br'
)
$script:Features = @(
    'vast rain forests', 'pirate lore', 'ancient ruins', 'orbital shipyards',
    'spice orchards', 'radioactive deserts', 'deep oceans', 'robot foundries',
    'gem mines', 'dusty plateaus', 'coral atolls', 'frozen poles',
    'busy freeports', 'silent monasteries', 'acid lakes', 'crystal caverns'
)
# Averages follow the 48K flight manual. B is the mid-economy price.
$script:Goods = @(
    @{ N = 'Food';         B = 4;   K = -1; T = 0; Il = $false },
    @{ N = 'Textiles';     B = 6;   K = -1; T = 0; Il = $false },
    @{ N = 'Radioactives'; B = 21;  K = -2; T = 0; Il = $false },
    @{ N = 'Slaves';       B = 8;   K = -1; T = 0; Il = $true  },
    @{ N = 'Liquor';       B = 25;  K = -1; T = 0; Il = $false },
    @{ N = 'Luxuries';     B = 91;  K = -2; T = 0; Il = $false },
    @{ N = 'Narcotics';    B = 115; K = -4; T = 0; Il = $true  },
    @{ N = 'Computers';    B = 84;  K = 6;  T = 0; Il = $false },
    @{ N = 'Machinery';    B = 56;  K = 4;  T = 0; Il = $false },
    @{ N = 'Alloys';       B = 33;  K = 3;  T = 0; Il = $false },
    @{ N = 'Firearms';     B = 70;  K = 3;  T = 0; Il = $true  },
    @{ N = 'Furs';         B = 56;  K = -2; T = 0; Il = $false },
    @{ N = 'Minerals';     B = 8;   K = -1; T = 0; Il = $false },
    @{ N = 'Gold';         B = 37;  K = 1;  T = 0; Il = $false },
    @{ N = 'Platinum';     B = 65;  K = 1;  T = 0; Il = $false },
    @{ N = 'Gem-Stones';   B = 16;  K = 2;  T = 0; Il = $false },
    @{ N = 'Alien Items';  B = 27;  K = 0;  T = 0; Il = $false }
)

# Wireframes follow the classic Elite blueprints: +X right, +Y up, +Z nose.
# The Coriolis is scaled by 3.5 so the docking face sits 560 m out. It rolls about that face.
# N is the face plane: direction and distance from the centre. A names the two faces of each edge.
# An edge is drawn when the eye is near enough and on the outside of one of those faces.
# FV and EV are the original distances, on the 0-31 scale, past which a face is kept and an edge is dropped.
# A Thargon keeps the canister edge list, the way the cassette blueprint does.
$script:MeshSide = @{
    V = [double[]]@(
        -32, 0, 36, 32, 0, 36, 64, 0, -28,
        -64, 0, -28, 0, 16, -28, 0, -16, -28,
        -12, 6, -28, 12, 6, -28, 12, -6, -28,
        -12, -6, -28
    )
    E = [int[]]@(
        0, 1, 1, 2, 1, 4, 0, 4, 0, 3, 3, 4, 2, 4, 3, 5,
        2, 5, 1, 5, 0, 5, 6, 7, 7, 8, 6, 9, 8, 9
    )
    N = [double[]]@(
        0, 32, 8, -12, 47, 6, 12, 47, 6, 
        0, 0, -112, -12, -47, 6, 0, -32, 8, 
        12, -47, 6
    )
    A = [int[]]@(
        0, 5, 2, 6, 0, 2, 0, 1, 1, 4, 1, 3, 2, 3, 3, 4, 
        3, 6, 5, 6, 4, 5, 3, 3, 3, 3, 3, 3, 3, 3
    )
    FV = [int[]]@(31, 31, 31, 31, 31, 31, 31)
    EV = [int[]]@(31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 15, 12, 12, 12)
}
$script:MeshViper = @{
    V = [double[]]@(
        0, 0, 72, 0, 16, 24, 0, -16, 24,
        48, 0, -24, -48, 0, -24, 24, -16, -24,
        -24, -16, -24, 24, 16, -24, -24, 16, -24,
        -32, 0, -24, 32, 0, -24, 8, 8, -24,
        -8, 8, -24, -8, -8, -24, 8, -8, -24
    )
    E = [int[]]@(
        0, 3, 0, 1, 0, 2, 0, 4, 1, 7, 1, 8, 2, 5, 2, 6,
        7, 8, 5, 6, 4, 8, 4, 6, 3, 7, 3, 5, 9, 12, 9, 13,
        10, 11, 10, 14, 11, 14, 12, 13
    )
    N = [double[]]@(
        0, 32, 0, -22, 33, 11, 22, 33, 11, 
        -22, -33, 11, 22, -33, 11, 0, -32, 0, 
        0, 0, -48
    )
    A = [int[]]@(
        2, 4, 1, 2, 3, 4, 1, 3, 0, 2, 0, 1, 4, 5, 3, 5, 
        0, 6, 5, 6, 1, 6, 3, 6, 2, 6, 6, 4, 6, 6, 6, 6, 
        6, 6, 6, 6, 6, 6, 6, 6
    )
    FV = [int[]]@(31, 31, 31, 31, 31, 31, 31)
    EV = [int[]]@(31, 30, 30, 31, 30, 30, 30, 30, 31, 30, 31, 30, 31, 30, 19, 18, 19, 18, 16, 16)
}
$script:MeshCobra = @{
    V = [double[]]@(
        32, 0, 76, -32, 0, 76, 0, 26, 24,
        -120, -3, -8, 120, -3, -8, -88, 16, -40,
        88, 16, -40, 128, -8, -40, -128, -8, -40,
        0, 26, -40, -32, -24, -40, 32, -24, -40,
        -36, 8, -40, -8, 12, -40, 8, 12, -40,
        36, 8, -40, 36, -12, -40, 8, -16, -40,
        -8, -16, -40, -36, -12, -40, 0, 0, 76,
        0, 0, 90, -80, -6, -40, -80, 6, -40,
        -88, 0, -40, 80, 6, -40, 88, 0, -40,
        80, -6, -40
    )
    E = [int[]]@(
        0, 1, 0, 4, 1, 3, 3, 8, 4, 7, 6, 7, 6, 9, 5, 9,
        5, 8, 2, 5, 2, 6, 3, 5, 4, 6, 1, 2, 0, 2, 8, 10,
        10, 11, 7, 11, 1, 10, 0, 11, 1, 5, 0, 6, 20, 21, 12, 13,
        18, 19, 14, 15, 16, 17, 15, 16, 14, 17, 13, 18, 12, 19, 2, 9,
        22, 24, 23, 24, 22, 23, 25, 26, 26, 27, 25, 27
    )
    N = [double[]]@(
        0, 62, 31, -18, 55, 16, 18, 55, 16, 
        -16, 52, 14, 16, 52, 14, -14, 47, 0, 
        14, 47, 0, -61, 102, 0, 61, 102, 0, 
        0, 0, -80, -7, -42, 9, 0, -30, 6, 
        7, -42, 9
    )
    A = [int[]]@(
        0, 11, 4, 12, 3, 10, 7, 10, 8, 12, 8, 9, 6, 9, 5, 9, 
        7, 9, 1, 5, 2, 6, 3, 7, 4, 8, 0, 1, 0, 2, 9, 10, 
        9, 11, 9, 12, 10, 11, 11, 12, 1, 3, 2, 4, 0, 11, 9, 9, 
        9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 5, 6, 
        9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9
    )
    FV = [int[]]@(31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31)
    EV = [int[]]@(31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 29, 29, 6, 20, 20, 20, 20, 19, 17, 19, 19, 30, 6, 6, 8, 6, 6, 8)
}
$script:MeshAdder = @{
    V = [double[]]@(
        -18, 0, 40, 18, 0, 40, 30, 0, -24,
        30, 0, -40, 18, -7, -40, -18, -7, -40,
        -30, 0, -40, -30, 0, -24, -18, 7, -40,
        18, 7, -40, -18, 7, 13, 18, 7, 13,
        -18, -7, 13, 18, -7, 13, -11, 3, 29,
        11, 3, 29, 11, 4, 24, -11, 4, 24
    )
    E = [int[]]@(
        0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 0,
        3, 9, 9, 8, 8, 6, 0, 10, 7, 10, 1, 11, 2, 11, 0, 12,
        7, 12, 1, 13, 2, 13, 10, 11, 12, 13, 8, 10, 9, 11, 5, 12,
        4, 13, 14, 15, 15, 16, 16, 17, 17, 14
    )
    N = [double[]]@(
        0, 39, 10, 0, -39, 10, 69, 50, 13, 
        69, -50, 13, 30, 52, 0, 30, -52, 0, 
        0, 0, -160, 0, 0, -160, 0, 0, -160, 
        -30, 52, 0, -30, -52, 0, -69, 50, 13, 
        -69, -50, 13, 0, 28, 0, 0, -28, 0
    )
    A = [int[]]@(
        1, 0, 3, 2, 5, 4, 6, 5, 14, 7, 10, 8, 10, 9, 12, 11, 
        6, 4, 13, 7, 9, 8, 11, 0, 11, 9, 2, 0, 4, 2, 12, 1, 
        12, 10, 3, 1, 5, 3, 13, 0, 14, 1, 13, 9, 13, 4, 14, 10, 
        14, 5, 0, 0, 0, 0, 0, 0, 0, 0
    )
    FV = [int[]]@(31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31)
    EV = [int[]]@(31, 7, 31, 31, 31, 31, 31, 7, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 5, 3, 4, 3)
}
$script:MeshKrait = @{
    V = [double[]]@(
        0, 0, 96, 0, 18, -48, 0, -18, -48,
        90, 0, -3, -90, 0, -3, 90, 0, 87,
        -90, 0, 87, 0, 5, 53, 0, 7, 38,
        -18, 7, 19, 18, 7, 19, 18, 11, -39,
        18, -11, -39, 36, 0, -30, -18, 11, -39,
        -18, -11, -39, -36, 0, -30
    )
    E = [int[]]@(
        0, 1, 0, 2, 0, 3, 0, 4, 1, 4, 4, 2, 2, 3, 3, 1,
        3, 5, 4, 6, 1, 2, 7, 10, 8, 10, 7, 9, 8, 9, 11, 13,
        13, 12, 12, 11, 14, 15, 15, 16, 16, 14
    )
    N = [double[]]@(
        3, 24, 3, 3, -24, 3, -3, -24, 3, 
        -3, 24, 3, 38, 0, -77, -38, 0, -77
    )
    A = [int[]]@(
        3, 0, 2, 1, 1, 0, 3, 2, 5, 3, 5, 2, 4, 1, 4, 0, 
        1, 0, 3, 2, 5, 4, 0, 0, 0, 0, 3, 3, 3, 3, 4, 4, 
        4, 4, 4, 4, 5, 5, 5, 5, 5, 5
    )
    FV = [int[]]@(31, 31, 31, 31, 31, 31)
    EV = [int[]]@(31, 31, 31, 31, 31, 31, 31, 31, 30, 30, 8, 9, 6, 9, 6, 8, 8, 7, 7, 8, 8)
}
$script:MeshAsp = @{
    V = [double[]]@(
        0, -18, 0, 0, -9, -45, 43, 0, -45,
        69, -3, 0, 43, -14, 28, -43, 0, -45,
        -69, -3, 0, -43, -14, 28, 26, -7, 73,
        -26, -7, 73, 43, 14, 28, -43, 14, 28,
        0, 9, -45, -17, 0, -45, 17, 0, -45,
        0, -4, -45, 0, 4, -45, 0, -7, 73,
        0, -7, 83
    )
    E = [int[]]@(
        0, 1, 0, 4, 0, 7, 1, 2, 2, 3, 3, 8, 8, 9, 6, 9,
        5, 6, 1, 5, 3, 4, 4, 8, 6, 7, 7, 9, 2, 12, 5, 12,
        10, 12, 11, 12, 10, 11, 6, 11, 9, 11, 3, 10, 8, 10, 13, 15,
        15, 14, 14, 16, 16, 13, 18, 17
    )
    N = [double[]]@(
        0, -35, 5, 8, -38, -7, -8, -38, -7, 
        0, 24, -1, 0, 43, 19, -6, 28, -2, 
        6, 28, -2, 59, -64, 31, -59, -64, 31, 
        80, 46, 50, -80, 46, 50, 0, 0, -90
    )
    A = [int[]]@(
        2, 1, 1, 0, 2, 0, 11, 1, 6, 1, 9, 7, 4, 0, 10, 8, 
        5, 2, 11, 2, 7, 1, 7, 0, 8, 2, 8, 0, 11, 6, 11, 5, 
        6, 3, 5, 3, 4, 3, 10, 5, 10, 4, 9, 6, 9, 4, 11, 11, 
        11, 11,         11, 11, 11, 11, 4, 0
    )
    FV = [int[]]@(31, 31, 31, 22, 31, 31, 31, 31, 31, 31, 31, 31)
    EV = [int[]]@(22, 22, 22, 31, 31, 16, 31, 16, 31, 31, 31, 31, 31, 31, 31, 31, 22, 22, 22, 31, 31, 31, 31, 10, 9, 8, 8, 10)
}
$script:MeshFdl = @{
    V = [double[]]@(
        0, -14, 108, -40, -14, -4, -12, -14, -52,
        12, -14, -52, 40, -14, -4, -40, 14, -4,
        -12, 2, -52, 12, 2, -52, 40, 14, -4,
        0, 18, -20, -3, -11, 97, -26, 8, 18,
        -16, 14, -4, 3, -11, 97, 26, 8, 18,
        16, 14, -4, 0, -14, -20, -14, -14, 44,
        14, -14, 44
    )
    E = [int[]]@(
        0, 1, 1, 2, 2, 3, 3, 4, 0, 4, 0, 5, 5, 6, 6, 7,
        7, 8, 0, 8, 5, 9, 6, 9, 7, 9, 8, 9, 1, 5, 2, 6,
        3, 7, 4, 8, 10, 11, 11, 12, 10, 12, 13, 14, 14, 15, 13, 15,
        16, 17, 16, 18, 17, 18
    )
    N = [double[]]@(
        0, 24, 6, -68, 0, 24, -63, 0, -37, 
        0, 0, -104, 63, 0, -37, 68, 0, 24, 
        -12, 46, -19, 0, 45, -22, 12, 46, -19, 
        0, -28, 0
    )
    A = [int[]]@(
        9, 1, 9, 2, 9, 3, 9, 4, 9, 5, 1, 0, 6, 2, 7, 3, 
        8, 4, 5, 0, 6, 0, 7, 6, 8, 7, 8, 0, 2, 1, 3, 2, 
        4, 3, 5, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        9, 9, 9, 9, 9, 9
    )
    FV = [int[]]@(28, 31, 31, 31, 31, 31, 28, 28, 28, 31)
    EV = [int[]]@(31, 31, 31, 31, 31, 28, 28, 28, 28, 28, 15, 11, 11, 15, 14, 14, 14, 14, 8, 9, 11, 8, 9, 11, 12, 12, 8)
}
$script:MeshPython = @{
    V = [double[]]@(
        0, 0, 224, 0, 48, 48, 96, 0, -16,
        -96, 0, -16, 0, 48, -32, 0, 24, -112,
        -48, 0, -112, 48, 0, -112, 0, -48, 48,
        0, -48, -32, 0, -24, -112
    )
    E = [int[]]@(
        0, 8, 0, 3, 0, 2, 0, 1, 2, 4, 1, 2, 2, 8, 1, 3,
        3, 8, 2, 9, 3, 4, 3, 9, 3, 5, 3, 10, 2, 5, 2, 10,
        2, 7, 3, 6, 5, 6, 5, 7, 7, 10, 6, 10, 4, 5, 9, 10,
        1, 4, 8, 9
    )
    N = [double[]]@(
        -27, 40, 11, 27, 40, 11, -27, -40, 11, 
        27, -40, 11, -19, 38, 0, 19, 38, 0, 
        -19, -38, 0, 19, -38, 0, -25, 37, -11, 
        25, 37, -11, 25, -37, -11, -25, -37, -11, 
        0, 0, -112
    )
    A = [int[]]@(
        2, 3, 0, 2, 1, 3, 0, 1, 9, 5, 1, 5, 7, 3, 0, 4, 
        2, 6, 7, 10, 4, 8, 6, 11, 8, 8, 11, 11, 9, 9, 10, 10, 
        9, 10, 8, 11, 8, 12, 9, 12, 12, 10, 11, 12, 8, 9, 10, 11, 
        4, 5, 6, 7
    )
    FV = [int[]]@(31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31)
    EV = [int[]]@(31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 7, 7, 7, 7, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31)
}
$script:MeshThargoid = @{
    V = [double[]]@(
        32, -48, 48, 32, -68, 0, 32, -48, -48,
        32, 0, -68, 32, 48, -48, 32, 68, 0,
        32, 48, 48, 32, 0, 68, -24, -116, 116,
        -24, -164, 0, -24, -116, -116, -24, 0, -164,
        -24, 116, -116, -24, 164, 0, -24, 116, 116,
        -24, 0, 164, -24, 64, 80, -24, 64, -80,
        -24, -64, -80, -24, -64, 80
    )
    E = [int[]]@(
        0, 7, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7,
        0, 8, 1, 9, 2, 10, 3, 11, 4, 12, 5, 13, 6, 14, 7, 15,
        8, 15, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14, 14, 15,
        16, 17, 18, 19
    )
    N = [double[]]@(
        103, -60, 25, 103, -60, -25, 103, -25, -60, 
        103, 25, -60, 64, 0, 0, 103, 60, -25, 
        103, 60, 25, 103, 25, 60, 103, -25, 60, 
        -48, 0, 0
    )
    A = [int[]]@(
        4, 8, 0, 4, 1, 4, 2, 4, 3, 4, 4, 5, 4, 6, 4, 7, 
        0, 8, 0, 1, 1, 2, 2, 3, 3, 5, 5, 6, 6, 7, 7, 8, 
        8, 9, 0, 9, 1, 9, 2, 9, 3, 9, 5, 9, 6, 9, 7, 9, 
        9, 9, 9, 9
    )
    FV = [int[]]@(31, 31, 31, 31, 31, 31, 31, 31, 31, 31)
    EV = [int[]]@(31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 30, 30)
}
$script:MeshThargon = @{
    V = [double[]]@(
        -9, 0, 40, -9, -38, 12, -9, -24, -32,
        -9, 24, -32, -9, 38, 12, 9, 0, -8,
        9, -10, -15, 9, -6, -26, 9, 6, -26,
        9, 10, -15
    )
    E = [int[]]@(
        0, 1, 1, 2, 2, 3, 3, 4, 0, 4, 0, 5, 1, 6, 2, 7,
        3, 8, 4, 9, 5, 6, 6, 7, 7, 8, 8, 9, 9, 5
    )
    N = [double[]]@(
        -36, 0, 0, 20, -5, 7, 46, -42, -14, 
        36, 0, -104, 46, 42, -14, 20, 5, 7, 
        36, 0, 0
    )
    A = [int[]]@(
        0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 1, 5, 1, 2, 2, 3, 
        3, 4, 4, 5, 1, 6, 2, 6, 3, 6, 4, 6, 5, 6
    )
}
$script:MeshRock = @{
    V = [double[]]@(
        0, 80, 0, -80, -10, 0, 0, -80, 0,
        70, -40, 0, 60, 50, 0, 50, 0, 60,
        -40, 0, 70, 0, 30, -75, 0, -50, -60
    )
    E = [int[]]@(
        0, 1, 0, 4, 3, 4, 2, 3, 1, 2, 1, 6, 2, 6, 2, 5,
        5, 6, 0, 5, 3, 5, 0, 6, 4, 5, 1, 8, 1, 7, 0, 7,
        4, 7, 3, 7, 3, 8, 2, 8, 7, 8
    )
    N = [double[]]@(
        9, 66, 81, 9, -66, 81, -72, 64, 31, 
        -64, -73, 47, 45, -79, 65, 135, 15, 35, 
        38, 76, 70, -66, 59, -39, -67, -15, -80, 
        66, -14, -75, -70, -80, -40, 58, -102, -51, 
        81, 9, -67, 47, 94, -63
    )
    A = [int[]]@(
        2, 7, 6, 13, 5, 12, 4, 11, 3, 10, 2, 3, 1, 3, 1, 4, 
        0, 1, 0, 6, 4, 5, 0, 2, 5, 6, 8, 10, 7, 8, 7, 13, 
        12, 13, 9, 12, 9, 11, 10, 11, 8, 9
    )
}
$script:MeshCan = @{
    V = [double[]]@(
        24, 16, 0, 24, 5, 15, 24, -13, 9,
        24, -13, -9, 24, 5, -15, -24, 16, 0,
        -24, 5, 15, -24, -13, 9, -24, -13, -9,
        -24, 5, -15
    )
    E = [int[]]@(
        0, 1, 1, 2, 2, 3, 3, 4, 0, 4, 0, 5, 1, 6, 2, 7,
        3, 8, 4, 9, 5, 6, 6, 7, 7, 8, 8, 9, 9, 5
    )
    N = [double[]]@(
        96, 0, 0, 0, 41, 30, 0, -18, 48, 
        0, -51, 0, 0, -18, -48, 0, 41, -30, 
        -96, 0, 0
    )
    A = [int[]]@(
        0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 1, 5, 1, 2, 2, 3, 
        3, 4, 4, 5, 1, 6, 2, 6, 3, 6, 4, 6, 5, 6
    )
}
$script:MeshMissile = @{
    V = [double[]]@(
        0, 0, 68, 8, -8, 36, 8, 8, 36,
        -8, 8, 36, -8, -8, 36, 8, 8, -44,
        8, -8, -44, -8, -8, -44, -8, 8, -44,
        12, 12, -44, 12, -12, -44, -12, -12, -44,
        -12, 12, -44, -8, 8, -12, -8, -8, -12,
        8, 8, -12, 8, -8, -12
    )
    E = [int[]]@(
        0, 1, 0, 2, 0, 3, 0, 4, 1, 2, 1, 4, 3, 4, 2, 3,
        2, 5, 1, 6, 4, 7, 3, 8, 7, 8, 5, 8, 5, 6, 6, 7,
        6, 10, 5, 9, 8, 12, 7, 11, 9, 15, 10, 16, 12, 13, 11, 14
    )
    N = [double[]]@(
        -64, 0, 16, 0, -64, 16, 64, 0, 16, 
        0, 64, 16, 32, 0, 0, 0, -32, 0, 
        -32, 0, 0, 0, 32, 0, 0, 0, -176
    )
    A = [int[]]@(
        1, 2, 2, 3, 0, 3, 0, 1, 4, 2, 1, 5, 0, 6, 3, 7, 
        4, 7, 4, 5, 5, 6, 6, 7, 6, 8, 7, 8, 4, 8, 5, 8, 
        5, 8, 7, 8, 7, 8,         5, 8, 4, 7, 4, 5, 6, 7, 5, 6
    )
    FV = [int[]]@(31, 31, 31, 31, 31, 31, 31, 31, 31)
    EV = [int[]]@(31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 8, 8, 8, 8, 8, 8, 8, 8)
}
$script:MeshStation = @{
    V = [double[]]@(
        560, 0, 560, 0, 560, 560, -560, 0, 560,
        0, -560, 560, 560, -560, 0, 560, 560, 0,
        -560, 560, 0, -560, -560, 0, 560, 0, -560,
        0, 560, -560, -560, 0, -560, 0, -560, -560,
        35, -105, 560, 35, 105, 560, -35, 105, 560,
        -35, -105, 560
    )
    E = [int[]]@(
        0, 3, 0, 1, 1, 2, 2, 3, 3, 4, 0, 4, 0, 5, 5, 1,
        1, 6, 2, 6, 2, 7, 3, 7, 8, 11, 8, 9, 9, 10, 10, 11,
        4, 11, 4, 8, 5, 8, 5, 9, 6, 9, 6, 10, 7, 10, 7, 11
    )
    N = [double[]]@(
        0, 0, 560, 374.5, -374.5, 374.5, 374.5, 374.5, 374.5,
        -374.5, 374.5, 374.5, -374.5, -374.5, 374.5, 0, -560, 0,
        560, 0, 0, -560, 0, 0, 0, 560, 0,
        -374.5, -374.5, -374.5, 374.5, -374.5, -374.5, 374.5, 374.5, -374.5,
        -374.5, 374.5, -374.5, 0, 0, -560
    )
    A = [int[]]@(
        0, 1, 0, 2, 0, 3, 0, 4, 1, 5, 1, 6, 2, 6, 2, 8, 
        3, 8, 3, 7, 4, 7, 4, 5, 10, 13, 11, 13, 12, 13, 9, 13, 
        5, 10, 6, 10, 6, 11, 8, 11, 8, 12, 7, 12, 7, 9, 5, 9
    )
}
$script:MeshPort = @{
    V = [double[]]@(
        35, -105, 560, 35, 105, 560, -35, 105, 560, -35, -105, 560
    )
    E = [int[]]@(0, 1, 1, 2, 2, 3, 3, 0)
    N = [double[]]@(0, 0, 560)
    A = [int[]]@(0, 0, 0, 0, 0, 0, 0, 0)
    FV = [int[]]@(31)
    EV = [int[]]@(30, 30, 30, 30)
}

function F0([double]$n) { return ([Math]::Round($n)).ToString($script:Inv) }
function F1([double]$n) { return $n.ToString('0.0', $script:Inv) }

function Get-RankName([int]$kills) {
    $name = 'Harmless'
    foreach ($row in $script:Ranks) {
        if ($kills -ge [int]$row[0]) { $name = [string]$row[1] }
    }
    return $name
}

function Test-Lawful([int]$gov) { return $gov -ge 5 }

function Next-U16([int64]$n) {
    $x = $n -band 65535
    $x = $x -bxor (($x -shl 7) -band 65535)
    $x = $x -bxor (($x -shr 9) -band 65535)
    $x = $x -bxor (($x -shl 8) -band 65535)
    return [int]($x -band 65535)
}

function Get-SysName([int]$seed, [hashtable]$used) {
    $h = [int64]$seed
    if ($h -lt 1) { $h = 1 }
    $count = 2 + ($h -band 1)
    if (($h -band 7) -eq 0) { $count = 3 }
    $s = ''
    for ($k = 0; $k -lt $count; $k++) {
        $h = ($h * 1103515245 + 12345) -band 2147483647
        $s += $script:Syl[$h % $script:Syl.Count]
    }
    if ($s.Length -gt 12) { $s = $s.Substring(0, 12) }
    $name = $s.Substring(0, 1).ToUpperInvariant() + $s.Substring(1)
    $base = $name
    $n = 2
    while ($used.ContainsKey($name)) {
        $name = $base.Substring(0, [Math]::Min(9, $base.Length)) + $n.ToString($script:Inv)
        $n++
    }
    $used[$name] = $true
    return $name
}

function Build-Galaxy([int]$seed) {
    $w0 = $seed -band 65535
    if ($w0 -eq 0) { $w0 = 4381 }
    $w1 = Next-U16 ($w0 * 3 + 17)
    $w2 = Next-U16 ($w0 * 9 + 91)
    $systems = New-Object object[] 256
    $usedPos = @{}
    $usedName = @{}
    for ($i = 0; $i -lt 256; $i++) {
        $w0 = Next-U16 $w0
        $w1 = Next-U16 ($w1 + $w0 + 1)
        $w2 = Next-U16 ($w2 + $w1 + $i)
        $x = $w1 -band 255
        $y = $w2 -band 255
        $guard = 0
        while ($usedPos.ContainsKey("$x,$y") -and $guard -lt 24) {
            $x = ($x + 11) -band 255
            $y = ($y + 5) -band 255
            $guard++
        }
        $usedPos["$x,$y"] = $true
        $gov = $w1 -band 7
        $eco = $w0 -band 7
        $tech = (7 - $eco) + ($w2 -band 3)
        if ($gov -ge 6) { $tech += 2 }
        if ($gov -eq 0) { $tech -= 2 }
        if ($tech -lt 0) { $tech = 0 }
        if ($tech -gt 15) { $tech = 15 }
        $pop = [Math]::Round((($tech + 1) * (4 + (7 - [Math]::Abs(4 - $eco))) + $gov) / 18.0, 1)
        $systems[$i] = @{
            X = [int]$x; Y = [int]$y; Gov = [int]$gov; Eco = [int]$eco; Tech = [int]$tech
            Seed = [int](($w0 -bxor $w1 -bxor ($i * 97)) -band 65535)
            Name = (Get-SysName ($w0 -bxor ($i * 131)) $usedName)
            Feature = $script:Features[$w2 % $script:Features.Count]
            Pop = [double]$pop
        }
    }
    $script:Systems = $systems
    $script:GalSeed = $seed
}

function Get-Ly([int]$i, [int]$j) {
    $a = $script:Systems[$i]
    $b = $script:Systems[$j]
    $dx = [double]$a.X - [double]$b.X
    $dy = [double]$a.Y - [double]$b.Y
    return [Math]::Sqrt($dx * $dx + $dy * $dy) / 4.0
}

function Get-Price([hashtable]$good, [int]$eco, [int]$fluc) {
    $price = [int]$good.B + [int]$good.K * ($eco - 4) + $fluc
    if ($price -lt 1) { $price = 1 }
    if ($price -gt 400) { $price = 400 }
    return $price
}

function Build-Market($sys) {
    $list = New-Object object[] $script:Goods.Count
    for ($i = 0; $i -lt $script:Goods.Count; $i++) {
        $g = $script:Goods[$i]
        $fluc = (($sys.Seed -bxor ($script:Day * 17) -bxor ($i * 53)) % 5) - 2
        $price = Get-Price $g $sys.Eco $fluc
        $qty = 16 - [int](($price - [int]$g.B) / 2)
        if ($sys.Tech -lt [int]$g.T) { $qty -= (6 + [int]$g.T) }
        if ($qty -lt 0) { $qty = 0 }
        if ($qty -gt 24) { $qty = 24 }
        $illegal = [bool]$g.Il -and (Test-Lawful $sys.Gov)
        if ($illegal) { $qty = 0 }
        $list[$i] = @{
            Name = [string]$g.N; Price = $price; Stock = $qty; Illegal = $illegal; Il = [bool]$g.Il
        }
    }
    return $list
}

function Refresh-Market {
    if ($script:MarketDay -eq $script:Day -and $script:MarketSys -eq $script:Sys -and $null -ne $script:Market) { return }
    $script:Market = Build-Market $script:Systems[$script:Sys]
    $script:MarketDay = $script:Day
    $script:MarketSys = $script:Sys
}

function Get-Hold([string]$name) {
    if ($script:Cargo.ContainsKey($name)) { return [int]$script:Cargo[$name] }
    return 0
}

function Update-CargoUsed {
    $u = 0
    foreach ($k in @($script:Cargo.Keys)) {
        $q = [int]$script:Cargo[$k]
        if ($q -le 0) { [void]$script:Cargo.Remove($k) }
        else { $u += $q }
    }
    $script:CargoUsed = $u
}

function Estimate-Price([string]$name, $sys) {
    foreach ($g in $script:Goods) {
        if ([string]$g.N -eq $name) { return (Get-Price $g $sys.Eco 0) }
    }
    return 0
}

function Get-BestRun {
    Refresh-Market
    $bestMargin = 0
    $bestText = 'No profitable hop inside fuel range.'
    $free = $script:CargoMax - $script:CargoUsed
    if ($free -lt 1) { return 'Cargo hold is full.' }
    if ($script:Cash -lt 2) { return 'Not enough credits to buy cargo.' }
    for ($j = 0; $j -lt 256; $j++) {
        if ($j -eq $script:Sys) { continue }
        $ly = Get-Ly $script:Sys $j
        if ($ly -gt $script:Fuel + 0.001 -or $ly -lt 0.05) { continue }
        $dest = $script:Systems[$j]
        foreach ($row in $script:Market) {
            if ($row.Stock -lt 1) { continue }
            if ($row.Il -and (Test-Lawful $dest.Gov)) { continue }
            $sell = Estimate-Price $row.Name $dest
            $margin = $sell - [int]$row.Price
            if ($margin -gt $bestMargin) {
                $bestMargin = $margin
                $bestText = "Best hop: $($row.Name) to $($dest.Name)  +$margin cr/t  ($(F1 $ly) LY)"
            }
        }
    }
    return $bestText
}

function Trade-Good([int]$idx, [int]$sign, [int]$qty) {
    Refresh-Market
    if ($idx -lt 0 -or $idx -ge $script:Market.Count) { return }
    $row = $script:Market[$idx]
    $sys = $script:Systems[$script:Sys]
    if ($row.Il -and (Test-Lawful $sys.Gov)) {
        Say 'This station refuses contraband.'
        return
    }
    if ($sign -gt 0) {
        if ($qty -gt $row.Stock) { $qty = $row.Stock }
        $room = $script:CargoMax - $script:CargoUsed
        if ($qty -gt $room) { $qty = $room }
        if ($row.Price -gt 0) {
            $afford = [int]([Math]::Floor($script:Cash / [double]$row.Price))
            if ($qty -gt $afford) { $qty = $afford }
        }
        if ($qty -le 0) { Say 'Cannot buy that.'; return }
        $script:Cash -= $qty * [int]$row.Price
        $row.Stock -= $qty
        $have = Get-Hold $row.Name
        $script:Cargo[$row.Name] = $have + $qty
        Update-CargoUsed
        Say "Bought $qty t $($row.Name)."
        return
    }
    $have = Get-Hold $row.Name
    if ($qty -gt $have) { $qty = $have }
    if ($qty -le 0) { Say 'You have none.'; return }
    $script:Cash += $qty * [int]$row.Price
    $row.Stock += $qty
    $script:Cargo[$row.Name] = $have - $qty
    Update-CargoUsed
    Say "Sold $qty t $($row.Name)."
}

function Say([string]$text) {
    $script:Msg = $text
    $script:MsgT = 5.0
}

function Note($obj, [string]$name, $fallback) {
    if ($null -eq $obj) { return $fallback }
    $p = $obj.PSObject.Properties[$name]
    if ($null -eq $p -or $null -eq $p.Value) { return $fallback }
    return $p.Value
}

function Test-Contraband([string]$name) {
    return $name -eq 'Slaves' -or $name -eq 'Narcotics' -or $name -eq 'Firearms'
}

function Clear-Cargo {
    $script:Cargo = @{}
    $script:CargoUsed = 0
}

function Sync-LaserFlag {
    $front = 'pulse'
    if ($null -ne $script:Laser -and $script:Laser.Count -gt 0) { $front = [string]$script:Laser[0] }
    $script:Beam = ($front -eq 'beam')
}

function Laser-Worth([string]$kind) {
    switch ($kind) {
        'pulse' { return 400 }
        'beam' { return 1000 }
        'military' { return 6000 }
        'mining' { return 800 }
        default { return 0 }
    }
}

function Laser-Kind {
    $kind = 'none'
    if ($null -ne $script:Laser -and $script:View -ge 0 -and $script:View -lt $script:Laser.Count) {
        $kind = [string]$script:Laser[$script:View]
    }
    if ($kind -eq 'none' -and $script:View -eq 0 -and $script:Beam) { $kind = 'beam' }
    return $kind
}

function Reset-Commander([string]$name, [int]$seed) {
    Build-Galaxy $seed
    $script:Name = $name
    $script:Cash = 100
    $script:Fuel = 7.0
    $script:Cargo = @{}
    $script:CargoUsed = 0
    $script:CargoMax = 20
    $script:Hull = 100.0
    $script:HullMax = 100.0
    $script:Shield = 100.0
    $script:ShieldMax = 100.0
    $script:ShieldF = 100.0
    $script:ShieldA = 100.0
    $script:Energy = 100.0
    $script:EnergyMax = 100.0
    $script:Beam = $false
    $script:Laser = @('pulse', 'none', 'none', 'none')
    $script:Missiles = 3
    $script:MissileArm = 0
    $script:DockComp = $false
    $script:GalDrive = $false
    $script:GalCharges = 0
    $script:ECM = $false
    $script:Scoops = $false
    $script:EscapePod = $false
    $script:Bomb = 0
    $script:EnergyUnit = $false
    $script:HasCloak = $false
    $script:CloakOn = $false
    $script:Heavy = 0
    $script:Nova = 0
    $script:NovaSys = -1
    $script:Cloak = 0
    $script:Base = 0
    $script:View = 0
    $script:FitMount = 0
    $script:Heat = 0.0
    $script:Temp = 0.0
    $script:JumpT = 0.0
    $script:Rare = $(if (($seed -band 1) -eq 0) { 'Krait' } else { 'Adder' })
    $script:Kills = 0
    $script:Legal = 0
    $script:Day = 0
    $script:GalNum = 1
    $script:JumpTarget = -1
    $script:Market = $null
    $script:MarketDay = -1
    $script:MarketSys = -1
    $script:Sys = Find-Home
    Set-Lave
    $script:Msg = ''
    $script:MsgT = 0
    $script:Px = 0.0
    $script:Py = 0.0
    $script:Pz = 0.0
    $script:Vx = 0.0
    $script:Vy = 0.0
    $script:Vz = 0.0
    $script:Witch = $false
    $script:PlR = 3000.0
    $script:PlX = 9000.0
    $script:PlY = 0.0
    $script:PlZ = 0.0
    if ($null -eq $script:M) { $script:M = New-Object 'double[]' 9 }
    Set-Identity $script:M
    Refresh-Market
}

function Find-Home {
    for ($pass = 0; $pass -lt 3; $pass++) {
        for ($i = 0; $i -lt 256; $i++) {
            $s = $script:Systems[$i]
            $ecoOk = $false
            $govOk = $false
            if ($pass -eq 0) { $ecoOk = $s.Eco -ge 5; $govOk = $s.Gov -ge 6 }
            elseif ($pass -eq 1) { $ecoOk = $s.Eco -ge 4; $govOk = $s.Gov -ge 4 }
            else { $ecoOk = $s.Eco -ge 4; $govOk = $true }
            if (-not $ecoOk -or -not $govOk) { continue }
            for ($j = 0; $j -lt 256; $j++) {
                if ($j -eq $i) { continue }
                if ($script:Systems[$j].Eco -gt 2) { continue }
                if ((Get-Ly $i $j) -le 6.5) { return $i }
            }
        }
    }
    $script:Systems[0].Eco = 6
    $script:Systems[0].Gov = 6
    $script:Systems[0].Tech = 4
    $script:Systems[0].X = 100
    $script:Systems[0].Y = 100
    $script:Systems[1].Eco = 0
    $script:Systems[1].Gov = 6
    $script:Systems[1].Tech = 12
    $script:Systems[1].X = 120
    $script:Systems[1].Y = 100
    return 0
}

function Set-Lave {
    $h = $script:Sys
    for ($i = 0; $i -lt 256; $i++) {
        if ($i -ne $h -and $script:Systems[$i].Name -eq 'Lave') {
            $script:Systems[$i].Name = 'Lavea'
        }
    }
    $lave = $script:Systems[$h]
    $lave.Name = 'Lave'
    $lave.Gov = 3
    $lave.Eco = 5
    $lave.Tech = 5
}

function Save-Commander {
    if (-not (Test-Path $script:SaveDir)) { New-Item -ItemType Directory -Path $script:SaveDir | Out-Null }
    $cargo = @()
    foreach ($k in @($script:Cargo.Keys)) {
        $cargo += @{ N = [string]$k; Q = [int]$script:Cargo[$k] }
    }
    $data = @{
        Version = 2
        Name = $script:Name
        Cash = [int]$script:Cash
        Fuel = [double]$script:Fuel
        Cargo = $cargo
        CargoMax = [int]$script:CargoMax
        Hull = [double]$script:Hull
        ShieldMax = [double]$script:ShieldMax
        Beam = [bool]$script:Beam
        Lasers = ($script:Laser -join ',')
        Missiles = [int]$script:Missiles
        DockComp = [bool]$script:DockComp
        GalDrive = [bool]($script:GalCharges -gt 0)
        GalCharges = [int]$script:GalCharges
        ECM = [bool]$script:ECM
        Scoops = [bool]$script:Scoops
        EscapePod = [bool]$script:EscapePod
        Bomb = [int]$script:Bomb
        EnergyUnit = [bool]$script:EnergyUnit
        HasCloak = [bool]$script:HasCloak
        Heavy = [int]$script:Heavy
        Nova = [int]$script:Nova
        NovaSys = [int]$script:NovaSys
        Cloak = [int]$script:Cloak
        Base = [int]$script:Base
        Rare = [string]$script:Rare
        Kills = [int]$script:Kills
        Legal = [int]$script:Legal
        Day = [int]$script:Day
        GalNum = [int]$script:GalNum
        GalSeed = [int]$script:GalSeed
        Sys = [int]$script:Sys
        JumpTarget = [int]$script:JumpTarget
    }
    $json = $data | ConvertTo-Json -Depth 4
    Set-Content -Path $script:SavePath -Value $json -Encoding UTF8
}

function Load-Commander {
    if (-not (Test-Path $script:SavePath)) { return $false }
    $raw = Get-Content -Path $script:SavePath -Raw -Encoding UTF8
    $data = $raw | ConvertFrom-Json
    if ($null -eq $data.GalSeed) { return $false }
    Build-Galaxy ([int]$data.GalSeed)
    $script:Name = [string]$data.Name
    $script:Cash = [int]$data.Cash
    $script:Fuel = [double]$data.Fuel
    $script:Cargo = @{}
    if ($null -ne $data.Cargo) {
        foreach ($c in @($data.Cargo)) {
            $script:Cargo[[string]$c.N] = [int]$c.Q
        }
    }
    Update-CargoUsed
    $script:CargoMax = [int]$data.CargoMax
    $script:Hull = [double]$data.Hull
    $script:HullMax = 100.0
    $script:ShieldMax = [double]$data.ShieldMax
    $script:Shield = $script:ShieldMax
    $script:EnergyMax = 100.0
    $script:Energy = 100.0
    $script:Beam = [bool]$data.Beam
    $laserText = [string](Note $data 'Lasers' '')
    if ($laserText.Length -gt 0) {
        $script:Laser = @($laserText.Split(','))
    }
    elseif ($script:Beam) {
        $script:Laser = @('beam', 'none', 'none', 'none')
    }
    else {
        $script:Laser = @('pulse', 'none', 'none', 'none')
    }
    while ($script:Laser.Count -lt 4) { $script:Laser += 'none' }
    $script:Missiles = [int]$data.Missiles
    $script:MissileArm = 0
    $script:DockComp = [bool]$data.DockComp
    $script:GalCharges = [int](Note $data 'GalCharges' $(if ([bool]$data.GalDrive) { 1 } else { 0 }))
    $script:GalDrive = ($script:GalCharges -gt 0)
    $script:ECM = [bool](Note $data 'ECM' $false)
    $script:Scoops = [bool](Note $data 'Scoops' $false)
    $script:EscapePod = [bool](Note $data 'EscapePod' $false)
    $script:Bomb = [int](Note $data 'Bomb' 0)
    $script:EnergyUnit = [bool](Note $data 'EnergyUnit' $false)
    $script:HasCloak = [bool](Note $data 'HasCloak' $false)
    $script:CloakOn = $false
    $script:Heavy = [int](Note $data 'Heavy' 0)
    $script:Nova = [int](Note $data 'Nova' 0)
    $script:NovaSys = [int](Note $data 'NovaSys' -1)
    $script:Cloak = [int](Note $data 'Cloak' 0)
    $script:Base = [int](Note $data 'Base' 0)
    $script:Rare = [string](Note $data 'Rare' 'Krait')
    $script:View = 0
    $script:FitMount = 0
    $script:Heat = 0.0
    $script:Temp = 0.0
    $script:JumpT = 0.0
    $script:ShieldF = $script:ShieldMax
    $script:ShieldA = $script:ShieldMax
    $script:Kills = [int]$data.Kills
    $script:Legal = [int]$data.Legal
    $script:Day = [int]$data.Day
    $script:GalNum = [int]$data.GalNum
    $script:Sys = [int]$data.Sys
    $script:JumpTarget = [int]$data.JumpTarget
    if ($script:Sys -lt 0 -or $script:Sys -gt 255) { $script:Sys = 0 }
    $script:Market = $null
    $script:MarketDay = -1
    $script:MarketSys = -1
    $script:Msg = ''
    $script:MsgT = 0
    $script:Px = 0.0
    $script:Py = 0.0
    $script:Pz = 0.0
    $script:Vx = 0.0
    $script:Vy = 0.0
    $script:Vz = 0.0
    $script:Witch = $false
    $script:PlR = 3000.0
    $script:PlX = 9000.0
    $script:PlY = 0.0
    $script:PlZ = 0.0
    if ($null -eq $script:M) { $script:M = New-Object 'double[]' 9 }
    Set-Identity $script:M
    Refresh-Market
    return $true
}

function Set-Identity([double[]]$m) {
    $m[0] = 1; $m[1] = 0; $m[2] = 0
    $m[3] = 0; $m[4] = 1; $m[5] = 0
    $m[6] = 0; $m[7] = 0; $m[8] = 1
}

function Repair-Axes([double[]]$m) {
    $fl = [Math]::Sqrt($m[6] * $m[6] + $m[7] * $m[7] + $m[8] * $m[8])
    if ($fl -lt 0.0000001) { return }
    $m[6] /= $fl; $m[7] /= $fl; $m[8] /= $fl
    $dot = $m[3] * $m[6] + $m[4] * $m[7] + $m[5] * $m[8]
    $m[3] -= $dot * $m[6]; $m[4] -= $dot * $m[7]; $m[5] -= $dot * $m[8]
    $ul = [Math]::Sqrt($m[3] * $m[3] + $m[4] * $m[4] + $m[5] * $m[5])
    if ($ul -lt 0.0000001) { return }
    $m[3] /= $ul; $m[4] /= $ul; $m[5] /= $ul
    $m[0] = $m[4] * $m[8] - $m[5] * $m[7]
    $m[1] = $m[5] * $m[6] - $m[3] * $m[8]
    $m[2] = $m[3] * $m[7] - $m[4] * $m[6]
}

function Turn-Ship([double[]]$m, [double]$pitch, [double]$roll) {
    if ([Math]::Abs($pitch) -gt 0.000001) {
        $c = [Math]::Cos($pitch); $s = [Math]::Sin($pitch)
        for ($i = 0; $i -lt 3; $i++) {
            $f = $m[6 + $i]; $u = $m[3 + $i]
            $m[6 + $i] = $f * $c + $u * $s
            $m[3 + $i] = $u * $c - $f * $s
        }
    }
    if ([Math]::Abs($roll) -gt 0.000001) {
        $c = [Math]::Cos($roll); $s = [Math]::Sin($roll)
        for ($i = 0; $i -lt 3; $i++) {
            $r = $m[$i]; $u = $m[3 + $i]
            $m[$i] = $r * $c - $u * $s
            $m[3 + $i] = $r * $s + $u * $c
        }
    }
}

function Set-Facing([double[]]$m, [double]$fx, [double]$fy, [double]$fz) {
    $fl = [Math]::Sqrt($fx * $fx + $fy * $fy + $fz * $fz)
    if ($fl -lt 0.0001) { Set-Identity $m; return }
    $m[6] = $fx / $fl; $m[7] = $fy / $fl; $m[8] = $fz / $fl
    $ux = 0.0; $uy = 1.0; $uz = 0.0
    if ([Math]::Abs($m[7]) -gt 0.92) { $ux = 1.0; $uy = 0.0; $uz = 0.0 }
    $m[3] = $ux; $m[4] = $uy; $m[5] = $uz
    Repair-Axes $m
}

function World-To-Local([double[]]$m, [double]$dx, [double]$dy, [double]$dz) {
    $script:LocX = $dx * $m[0] + $dy * $m[1] + $dz * $m[2]
    $script:LocY = $dx * $m[3] + $dy * $m[4] + $dz * $m[5]
    $script:LocZ = $dx * $m[6] + $dy * $m[7] + $dz * $m[8]
}

function Get-Steer([double[]]$m, [double]$dx, [double]$dy, [double]$dz) {
    $dist = [Math]::Sqrt($dx * $dx + $dy * $dy + $dz * $dz)
    if ($dist -lt 0.001) { $dist = 0.001 }
    $dx /= $dist; $dy /= $dist; $dz /= $dist
    World-To-Local $m $dx $dy $dz
    $pitch = 0.0
    $roll = 0.0
    if ($script:LocZ -lt 0.25) {
        # Target is beside or behind: pitch the nose around, roll to lift it.
        $pitch = 1.8
        $roll = $script:LocX * 4.0
        if ($roll -gt 2.4) { $roll = 2.4 }
        if ($roll -lt -2.4) { $roll = -2.4 }
    }
    else {
        $roll = $script:LocX * 3.2
        $pitch = $script:LocY * 3.2
        if ([Math]::Abs($script:LocX) -gt 0.35) { $pitch *= 0.22 }
        if ($roll -gt 2.4) { $roll = 2.4 }
        if ($roll -lt -2.4) { $roll = -2.4 }
        if ($pitch -gt 1.8) { $pitch = 1.8 }
        if ($pitch -lt -1.8) { $pitch = -1.8 }
    }
    $script:StPitch = $pitch
    $script:StRoll = $roll
    $script:StDist = $dist
}

function New-Ship([string]$type, [string]$role, [double]$x, [double]$y, [double]$z) {
    $hull = 22.0; $dmg = 5.0; $maxSp = 220.0; $accel = 90.0; $bounty = 25; $scale = 1.0; $color = [byte]9
    $ecm = $false; $msl = 0; $blink = $false; $radius = 40.0
    if ($type -eq 'Sidewinder') { $hull = 16; $dmg = 4; $maxSp = 280; $accel = 140; $bounty = 15; $radius = 40; $msl = 1 }
    elseif ($type -eq 'Trader' -or $type -eq 'Cobra') { $hull = 40; $dmg = 5; $maxSp = 160; $accel = 60; $bounty = 35; $radius = 90; $color = [byte]11; $ecm = $true }
    elseif ($type -eq 'Adder') { $hull = 28; $dmg = 5; $maxSp = 210; $accel = 85; $bounty = 30; $radius = 32; $msl = 1 }
    elseif ($type -eq 'Krait') { $hull = 18; $dmg = 6; $maxSp = 310; $accel = 160; $bounty = 40; $radius = 60; $color = [byte]12; $msl = 1 }
    elseif ($type -eq 'Asp') { $hull = 55; $dmg = 9; $maxSp = 320; $accel = 140; $bounty = 140; $radius = 55; $color = [byte]13; $msl = 1 }
    elseif ($type -eq 'Fer-de-Lance') { $hull = 72; $dmg = 12; $maxSp = 300; $accel = 125; $bounty = 200; $radius = 70; $color = [byte]12; $msl = 2 }
    elseif ($type -eq 'Python') { $hull = 90; $dmg = 10; $maxSp = 150; $accel = 50; $bounty = 160; $radius = 140; $color = [byte]9; $ecm = $true; $msl = 1 }
    elseif ($type -eq 'Police') { $hull = 36; $dmg = 7; $maxSp = 260; $accel = 110; $bounty = 0; $radius = 48; $color = [byte]14 }
    elseif ($type -eq 'Thargoid' -or $type -eq 'Alien') { $hull = 120; $dmg = 14; $maxSp = 280; $accel = 130; $bounty = 350; $radius = 110; $color = [byte]13; $ecm = $true; $msl = 2 }
    elseif ($type -eq 'Thargon') { $hull = 8; $dmg = 4; $maxSp = 340; $accel = 180; $bounty = 8; $radius = 28; $color = [byte]13 }
    elseif ($type -eq 'Asteroid') { $hull = 28; $dmg = 0; $maxSp = 20; $accel = 0; $bounty = 5; $radius = 55; $color = [byte]8 }
    elseif ($type -eq 'Canister') { $hull = 1; $dmg = 0; $maxSp = 0; $accel = 0; $bounty = 0; $radius = 20; $color = [byte]11 }
    elseif ($type -eq 'ThargoidStation') { $hull = 240; $dmg = 0; $maxSp = 0; $accel = 0; $bounty = 5000; $radius = 520; $color = [byte]13 }
    $m = New-Object 'double[]' 9
    Set-Identity $m
    $ship = @{
        Id = $script:NextId; Type = $type; Role = $role
        X = $x; Y = $y; Z = $z; VX = 0.0; VY = 0.0; VZ = 0.0
        M = $m; Hull = $hull; HullMax = $hull; Dmg = $dmg; MaxSp = $maxSp; Accel = $accel
        Bounty = $bounty; Scale = $scale; Color = $color; Cool = 0.8 + ($script:NextId % 5) * 0.15
        Provoked = $false; Radius = $radius
        Jx = ($x * 0.15); Jy = 200.0; Jz = $z
        Ecm = $ecm; Msl = $msl; Blink = $blink; Good = ''; SpawnT = 3.0
    }
    $script:NextId++
    Set-Facing $m (-$x) (200 - $y) (-$z)
    return $ship
}

function Flush-Pending {
    if ($null -eq $script:Pending) { return }
    foreach ($s in $script:Pending) { [void]$script:Ships.Add($s) }
    $script:Pending.Clear()
}

function Mesh-Of($ship) {
    switch ($ship.Type) {
        'Sidewinder' { return $script:MeshSide }
        'Viper' { return $script:MeshViper }
        'Police' { return $script:MeshViper }
        'Trader' { return $script:MeshCobra }
        'Cobra' { return $script:MeshCobra }
        'Adder' { return $script:MeshAdder }
        'Krait' { return $script:MeshKrait }
        'Python' { return $script:MeshPython }
        'Asp' { return $script:MeshAsp }
        'Fer-de-Lance' { return $script:MeshFdl }
        'Alien' { return $script:MeshThargoid }
        'Thargoid' { return $script:MeshThargoid }
        'Thargon' { return $script:MeshThargon }
        'Asteroid' { return $script:MeshRock }
        'Canister' { return $script:MeshCan }
        'ThargoidStation' { return $script:MeshStation }
        default { return $script:MeshViper }
    }
}

function Spawn-Traffic {
    $script:Ships = New-Object System.Collections.Generic.List[object]
    $script:Bolts = New-Object System.Collections.Generic.List[object]
    $script:Debris = New-Object System.Collections.Generic.List[object]
    if ($script:NoSpawn) { return }
    $sys = $script:Systems[$script:Sys]
    $roll = ($sys.Seed + $script:Day * 13) % 10
    $pirates = 1
    if ($sys.Gov -ge 6) { $pirates = 0; if ($roll -ge 7) { $pirates = 1 } }
    elseif ($sys.Gov -ge 3) { $pirates = 1 + ($roll % 2) }
    else { $pirates = 2 + ($roll % 3) }
    if ($pirates -gt 4) { $pirates = 4 }
    $rng = New-Object System.Random (($sys.Seed + 1) * ($script:Day + 3) + $script:GalNum * 17)
    $pool = @('Sidewinder', 'Sidewinder', 'Viper', 'Cobra')
    if ($sys.Gov -le 3) { $pool += @($script:Rare, 'Cobra', 'Asp') }
    if ($sys.Gov -le 1) { $pool += @('Python', $script:Rare, 'Sidewinder') }
    for ($n = 0; $n -lt $pirates; $n++) {
        $ang = $rng.NextDouble() * 6.28318
        $dist = 4500.0 + $rng.NextDouble() * 7000.0
        $x = [Math]::Cos($ang) * $dist
        $z = [Math]::Sin($ang) * $dist
        $y = ($rng.NextDouble() - 0.5) * 1600.0
        $type = $pool[$rng.Next(0, $pool.Count)]
        [void]$script:Ships.Add((New-Ship $type 'pirate' $x $y $z))
    }
    if ($script:Legal -ge 20 -and $script:Kills -ge 128) {
        [void]$script:Ships.Add((New-Ship 'Fer-de-Lance' 'hunter' 5200 400 -1800))
    }
    $traders = 1
    if ($sys.Gov -ge 4) { $traders = 2 }
    for ($n = 0; $n -lt $traders; $n++) {
        $ang = $rng.NextDouble() * 6.28318
        $dist = 3000.0 + $rng.NextDouble() * 5000.0
        [void]$script:Ships.Add((New-Ship 'Cobra' 'trader' ([Math]::Cos($ang) * $dist) (($rng.NextDouble() - 0.5) * 800) ([Math]::Sin($ang) * $dist)))
    }
    $illegal = $false
    foreach ($k in @($script:Cargo.Keys)) {
        if (Test-Contraband $k) { $illegal = $true }
    }
    $cops = 0
    if ($sys.Gov -ge 6) { $cops = 1 }
    if ((Test-Lawful $sys.Gov) -and ($script:Legal -gt 0 -or $illegal)) { $cops = 1 }
    if ($script:Legal -gt 20) { $cops = 2 }
    for ($n = 0; $n -lt $cops; $n++) {
        [void]$script:Ships.Add((New-Ship 'Police' 'police' (1800.0 + $n * 400) 300.0 (2200.0 + $n * 300)))
    }
    $rocks = 2
    if ($sys.Gov -le 1) { $rocks = 4 }
    for ($n = 0; $n -lt $rocks; $n++) {
        $ang = $rng.NextDouble() * 6.28318
        $dist = 5000.0 + $rng.NextDouble() * 4000.0
        $rock = New-Ship 'Asteroid' 'rock' ([Math]::Cos($ang) * $dist) (($rng.NextDouble() - 0.5) * 600) ([Math]::Sin($ang) * $dist)
        $rock.VX = ($rng.NextDouble() - 0.5) * 12
        $rock.VZ = ($rng.NextDouble() - 0.5) * 12
        [void]$script:Ships.Add($rock)
    }
    if ($script:Cloak -eq 1) {
        $asp = New-Ship 'Asp' 'cloak' 4200 180 900
        $asp.Blink = $true
        [void]$script:Ships.Add($asp)
    }
    if ($script:Base -eq 1) {
        [void]$script:Ships.Add((New-Ship 'ThargoidStation' 'base' 6400 0 2400))
        $script:Base = 2
    }
}

function Enter-Space([string]$mode) {
    $script:Witch = $false
    $script:Dead = $false
    $script:AutoDock = $false
    $script:DidDock = $false
    $script:HitFlash = 0.0
    $script:SinceHit = 9.0
    $script:Cool = 0.0
    $script:LaserT = 0.0
    $script:TargetId = -1
    $script:NextId = 1
    $script:KeyPrev = @{}
    $sys = $script:Systems[$script:Sys]
    $ang = ($sys.Seed % 360) * 0.0174533
    $orbit = 9000.0 + ($sys.Seed % 5) * 400.0
    $script:PlX = [Math]::Cos($ang) * $orbit
    $script:PlY = (($sys.Seed % 5) - 2) * 350.0
    $script:PlZ = [Math]::Sin($ang) * $orbit
    $script:PlR = 2600.0 + ($sys.Seed % 7) * 120.0
    $script:SuX = -[Math]::Cos($ang + 0.6) * 46000.0
    $script:SuY = 8000.0
    $script:SuZ = -[Math]::Sin($ang + 0.6) * 46000.0
    $script:SuR = 5600.0
    $script:StAngle = ($script:Day * 0.55 + ($sys.Seed % 20) * 0.1)
    $script:StSpin = 0.0
    $stars = 110
    $script:StarN = $stars
    $script:Stars = New-Object 'double[]' ($stars * 3)
    $rng = New-Object System.Random ($sys.Seed + 99)
    for ($i = 0; $i -lt $stars; $i++) {
        $a = $rng.NextDouble() * 6.28318
        $b = ($rng.NextDouble() - 0.5) * 2.2
        $r = 2500.0 + $rng.NextDouble() * 28000.0
        $script:Stars[$i * 3] = [Math]::Cos($a) * [Math]::Cos($b) * $r
        $script:Stars[$i * 3 + 1] = [Math]::Sin($b) * $r
        $script:Stars[$i * 3 + 2] = [Math]::Sin($a) * [Math]::Cos($b) * $r
    }
    if ($null -eq $script:M) { $script:M = New-Object 'double[]' 9 }
    if ($mode -eq 'launch') {
        $ex = [Math]::Sin($script:StAngle)
        $ez = [Math]::Cos($script:StAngle)
        $script:Px = $ex * 860.0
        $script:Py = 0.0
        $script:Pz = $ez * 860.0
        Set-Facing $script:M $ex 0.0 $ez
        $script:Vx = $ex * 35.0
        $script:Vy = 0.0
        $script:Vz = $ez * 35.0
        Say 'Launched. Station is behind you.'
    }
    else {
        $script:Px = 2800.0
        $script:Py = 500.0
        $script:Pz = 3600.0
        $script:Vx = 0.0; $script:Vy = 0.0; $script:Vz = 0.0
        Set-Facing $script:M (-$script:Px) (-$script:Py) (-$script:Pz)
        Say "Arrived at $($sys.Name). Dock when you are ready."
    }
    Spawn-Traffic
    Refresh-Market
}

function Enter-Witch {
    $script:Witch = $true
    $script:Dead = $false
    $script:AutoDock = $false
    $script:DidDock = $false
    $script:Px = 0; $script:Py = 0; $script:Pz = 0
    $script:Vx = 0; $script:Vy = 0; $script:Vz = 0
    if ($null -eq $script:M) { $script:M = New-Object 'double[]' 9 }
    Set-Identity $script:M
    $script:Ships = New-Object System.Collections.Generic.List[object]
    $script:Bolts = New-Object System.Collections.Generic.List[object]
    $script:Debris = New-Object System.Collections.Generic.List[object]
    $script:NextId = 1
    $script:TargetId = -1
    [void]$script:Ships.Add((New-Ship 'Thargoid' 'alien' 0 0 2200))
    Say 'WITCH-SPACE. A Thargoid has locked on.'
}

function Complete-Witch {
    $script:Sys = $script:PendingSys
    Enter-Space 'jump'
    Say 'Normal space. The witch-space tear has closed.'
}

function Hurt-Player([double]$amount, [bool]$fore) {
    if (-not $PSBoundParameters.ContainsKey('fore')) { $fore = $true }
    $script:SinceHit = 0
    $script:HitFlash = 0.18
    $left = $amount
    if ($fore) {
        if ($script:ShieldF -gt 0) {
            $script:ShieldF -= $left
            if ($script:ShieldF -lt 0) { $left = -$script:ShieldF; $script:ShieldF = 0 }
            else { $left = 0 }
        }
    }
    else {
        if ($script:ShieldA -gt 0) {
            $script:ShieldA -= $left
            if ($script:ShieldA -lt 0) { $left = -$script:ShieldA; $script:ShieldA = 0 }
            else { $left = 0 }
        }
    }
    if ($left -gt 0) {
        if ($script:Energy -gt 0) {
            $script:Energy -= $left
            if ($script:Energy -lt 0) { $left = -$script:Energy; $script:Energy = 0 }
            else { $left = 0 }
        }
    }
    if ($left -gt 0) { $script:Hull -= $left }
    $script:Shield = $script:ShieldF
    if ($script:Hull -le 0) {
        $script:Hull = 0
        $script:Dead = $true
    }
}

function Add-Debris([double]$x, [double]$y, [double]$z, [byte]$color) {
    for ($k = 0; $k -lt 5; $k++) {
        $script:Debris.Add(@{
            X = $x; Y = $y; Z = $z
            VX = (Get-Random -Minimum -80 -Maximum 80)
            VY = (Get-Random -Minimum -80 -Maximum 80)
            VZ = (Get-Random -Minimum -80 -Maximum 80)
            Life = 1.3; Color = $color
        })
    }
}

function Drop-Can([double]$x, [double]$y, [double]$z, [string]$good) {
    $can = New-Ship 'Canister' 'cargo' $x $y $z
    $can.Good = $good
    if ($null -eq $script:Pending) { $script:Pending = New-Object System.Collections.Generic.List[object] }
    $script:Pending.Add($can)
}

function Kill-Ship($ship) {
    $paid = $false
    if ($ship.Role -eq 'pirate' -or $ship.Role -eq 'alien' -or $ship.Role -eq 'hunter' -or $ship.Role -eq 'rock') {
        $script:Kills++
        $script:Cash += [int]$ship.Bounty
        $paid = $true
        if ($ship.Role -eq 'rock') { Say "Asteroid broken. Bounty $($ship.Bounty) CR." }
        elseif ($ship.Type -eq 'Thargoid') { Say "Thargoid destroyed. Bounty $($ship.Bounty) CR. Thargons go inert." }
        else { Say "Destroyed $($ship.Type). Bounty $($ship.Bounty) CR." }
    }
    elseif ($ship.Role -eq 'police') {
        $script:Legal += 12
        Say 'Police ship destroyed. You are wanted.'
    }
    elseif ($ship.Role -eq 'trader') {
        if ($ship.Provoked) {
            $script:Legal += 6
            $script:Cash += [int]$ship.Bounty
            Say 'Trader destroyed. The law will remember.'
        }
        else {
            $script:Legal += 10
            Say 'You fired on a clean ship.'
        }
    }
    elseif ($ship.Role -eq 'base') {
        $script:Kills++
        $script:Cash += [int]$ship.Bounty
        $script:Base = 3
        $paid = $true
        Say "Thargoid station destroyed. Bounty $($ship.Bounty) CR."
    }
    elseif ($ship.Role -eq 'cloak') {
        $script:Kills++
        $script:Cash += [int]$ship.Bounty
        $script:Cloak = 2
        Drop-Can $ship.X $ship.Y $ship.Z 'Cloak'
        Say 'The Asp breaks up. Scoop the canister.'
    }
    if ($paid -and $ship.Role -ne 'rock' -and $ship.Role -ne 'base' -and $script:Scoops) {
        Drop-Can ($ship.X + 40) $ship.Y ($ship.Z + 40) 'Minerals'
    }
    if ($ship.Role -eq 'rock' -and (Laser-Kind) -eq 'mining') {
        Drop-Can ($ship.X + 30) $ship.Y $ship.Z 'Minerals'
        Drop-Can ($ship.X - 30) ($ship.Y + 20) $ship.Z 'Minerals'
        Drop-Can $ship.X ($ship.Y - 20) ($ship.Z + 30) 'Minerals'
    }
    Add-Debris $ship.X $ship.Y $ship.Z $ship.Color
}

function Sync-Camera {
    if ($null -eq $script:Cam) { $script:Cam = New-Object 'double[]' 9 }
    $m = $script:M
    $v = $script:View
    if ($v -eq 1) {
        $script:Cam[0] = -$m[0]; $script:Cam[1] = -$m[1]; $script:Cam[2] = -$m[2]
        $script:Cam[3] = $m[3]; $script:Cam[4] = $m[4]; $script:Cam[5] = $m[5]
        $script:Cam[6] = -$m[6]; $script:Cam[7] = -$m[7]; $script:Cam[8] = -$m[8]
    }
    elseif ($v -eq 2) {
        $script:Cam[0] = $m[6]; $script:Cam[1] = $m[7]; $script:Cam[2] = $m[8]
        $script:Cam[3] = $m[3]; $script:Cam[4] = $m[4]; $script:Cam[5] = $m[5]
        $script:Cam[6] = -$m[0]; $script:Cam[7] = -$m[1]; $script:Cam[8] = -$m[2]
    }
    elseif ($v -eq 3) {
        $script:Cam[0] = -$m[6]; $script:Cam[1] = -$m[7]; $script:Cam[2] = -$m[8]
        $script:Cam[3] = $m[3]; $script:Cam[4] = $m[4]; $script:Cam[5] = $m[5]
        $script:Cam[6] = $m[0]; $script:Cam[7] = $m[1]; $script:Cam[8] = $m[2]
    }
    else {
        for ($i = 0; $i -lt 9; $i++) { $script:Cam[$i] = $m[$i] }
    }
}

function Cam-Local([double]$dx, [double]$dy, [double]$dz) {
    $c = $script:Cam
    if ($null -eq $c) { $c = $script:M }
    $script:LocX = $dx * $c[0] + $dy * $c[1] + $dz * $c[2]
    $script:LocY = $dx * $c[3] + $dy * $c[4] + $dz * $c[5]
    $script:LocZ = $dx * $c[6] + $dy * $c[7] + $dz * $c[8]
}

function Try-Fire {
    $kind = Laser-Kind
    if ($kind -eq 'none') { return }
    if ($script:Heat -gt 92) { Say 'Laser temperature too high.'; return }
    $cost = 7.0; $cool = 0.28; $dmg = 11.0; $heat = 16.0; $range = 6200.0
    if ($kind -eq 'beam') { $cost = 4.0; $cool = 0.08; $dmg = 7.0; $heat = 9.0 }
    elseif ($kind -eq 'military') { $cost = 10.0; $cool = 0.16; $dmg = 18.0; $heat = 18.0 }
    elseif ($kind -eq 'mining') { $cost = 5.0; $cool = 0.14; $dmg = 3.0; $heat = 8.0 }
    if ($script:Cool -gt 0 -or $script:Energy -lt $cost) { return }
    $script:Energy -= $cost
    $script:Cool = $cool
    $script:Heat += $heat
    if ($script:Heat -gt 100) { $script:Heat = 100 }
    $script:LaserT = 0.07
    Sync-Camera
    $best = $null
    $bestD = $range
    foreach ($s in $script:Ships) {
        if ($s.Hull -le 0 -or $s.Role -eq 'cargo') { continue }
        $dx = $s.X - $script:Px; $dy = $s.Y - $script:Py; $dz = $s.Z - $script:Pz
        Cam-Local $dx $dy $dz
        $dist = [Math]::Sqrt($script:LocX * $script:LocX + $script:LocY * $script:LocY + $script:LocZ * $script:LocZ)
        if ($script:LocZ -le 40 -or $dist -gt $range -or $dist -lt 1) { continue }
        $off = [Math]::Sqrt($script:LocX * $script:LocX + $script:LocY * $script:LocY) / $dist
        if ($off -lt 0.11 -and $dist -lt $bestD) { $best = $s; $bestD = $dist }
    }
    if ($null -ne $best) {
        $hit = $dmg
        if ($kind -eq 'mining' -and $best.Role -eq 'rock') { $hit = 40 }
        $best.Hull -= $hit
        if ($best.Role -eq 'trader') { $best.Provoked = $true; $script:Legal += 1 }
        $script:Lx = $best.X; $script:Ly = $best.Y; $script:Lz = $best.Z
        if ($best.Hull -le 0) { Kill-Ship $best }
    }
    else {
        $c = $script:Cam
        $script:Lx = $script:Px + $c[6] * 2400.0
        $script:Ly = $script:Py + $c[7] * 2400.0
        $script:Lz = $script:Pz + $c[8] * 2400.0
    }
}

function Arm-Missile {
    if ($script:Missiles -le 0) { Say 'No missiles.'; return }
    Sync-Camera
    $best = $null
    $bestD = 8000.0
    foreach ($s in $script:Ships) {
        if ($s.Hull -le 0 -or $s.Role -eq 'cargo') { continue }
        Cam-Local ($s.X - $script:Px) ($s.Y - $script:Py) ($s.Z - $script:Pz)
        $dist = Speed-Of $script:LocX $script:LocY $script:LocZ
        if ($script:LocZ -le 0 -or $dist -lt 1 -or $dist -gt $bestD) { continue }
        $off = [Math]::Sqrt($script:LocX * $script:LocX + $script:LocY * $script:LocY) / $dist
        if ($off -lt 0.22) { $best = $s; $bestD = $dist }
    }
    if ($null -eq $best) {
        Cycle-Target
        $script:MissileArm = 1
        Say 'Missile armed. No lock yet.'
        return
    }
    $script:TargetId = $best.Id
    $script:MissileArm = 2
    Say "Missile locked. $($best.Type)."
}

function Try-Missile {
    if ($script:Missiles -le 0) { Say 'No missiles.'; return }
    if ($script:MissileArm -lt 2) { Say 'Lock a target with T.'; return }
    $target = $null
    foreach ($s in $script:Ships) {
        if ($s.Id -eq $script:TargetId -and $s.Hull -gt 0) { $target = $s }
    }
    if ($null -eq $target) { Say 'Lock lost.'; $script:MissileArm = 0; return }
    $script:Missiles--
    $script:MissileArm = 0
    $script:Bolts.Add(@{
        X = $script:Px + $script:M[6] * 80; Y = $script:Py + $script:M[7] * 80; Z = $script:Pz + $script:M[8] * 80
        VX = $script:M[6] * 500; VY = $script:M[7] * 500; VZ = $script:M[8] * 500
        Life = 8.0; Target = $target.Id; Player = $false
    })
    Say 'Missile away.'
}

function Try-Heavy {
    if ($script:Heavy -le 0) { Say 'No heavy missile.'; return }
    $script:Heavy--
    $targetId = -3
    foreach ($s in $script:Ships) {
        if ($s.Role -eq 'base' -and $s.Hull -gt 0) { $targetId = $s.Id }
    }
    $script:Bolts.Add(@{
        X = $script:Px + $script:M[6] * 90; Y = $script:Py + $script:M[7] * 90; Z = $script:Pz + $script:M[8] * 90
        VX = $script:M[6] * 420; VY = $script:M[7] * 420; VZ = $script:M[8] * 420
        Life = 12.0; Target = $targetId; Player = $false; Heavy = $true
    })
    Say 'Heavy missile away.'
}

function Try-ECM {
    if (-not $script:ECM) { Say 'No ECM system.'; return }
    if ($script:Energy -lt 16) { Say 'Not enough energy for ECM.'; return }
    $script:Energy -= 16
    $script:EcmT = 2.2
    if ($null -ne $script:Bolts) { $script:Bolts.Clear() }
    Say 'ECM. Missiles destroyed.'
}

function Try-Bomb {
    if ($script:Bomb -le 0) { Say 'No energy bomb.'; return }
    $script:Bomb--
    foreach ($s in $script:Ships) {
        if ($s.Hull -le 0) { continue }
        if ($s.Role -eq 'cargo') { continue }
        $s.Hull = 0
        if ($s.Role -eq 'base') { $script:Base = 3; $script:Cash += [int]$s.Bounty; $script:Kills++ }
        elseif ($s.Role -eq 'pirate' -or $s.Role -eq 'alien' -or $s.Role -eq 'hunter' -or $s.Role -eq 'rock') {
            $script:Kills++; $script:Cash += [int]$s.Bounty
        }
        elseif ($s.Role -eq 'police') { $script:Legal += 12 }
        elseif ($s.Role -eq 'trader') { $script:Legal += 8 }
    }
    if ($null -ne $script:Bolts) { $script:Bolts.Clear() }
    Say 'Energy bomb. The sky is empty.'
}

function Try-Escape {
    if (-not $script:EscapePod) { Say 'No escape pod.'; return }
    if ($script:Witch) { Say 'The pod cannot launch in witch-space.'; return }
    Clear-Cargo
    $script:Legal = 0
    $script:Hull = 100
    $script:ShieldF = $script:ShieldMax
    $script:ShieldA = $script:ShieldMax
    $script:Shield = $script:ShieldMax
    $script:Energy = $script:EnergyMax
    $script:CloakOn = $false
    $script:Escaping = $true
    $script:DidDock = $true
    Say 'Escape pod away. A new Cobra is waiting at the station.'
}

function Cycle-Target {
    $ids = @()
    foreach ($s in $script:Ships) {
        if ($s.Hull -gt 0) { $ids += [int]$s.Id }
    }
    if ($ids.Count -eq 0) { $script:TargetId = -1; Say 'No contacts.'; return }
    $pick = $ids[0]
    $seen = $false
    foreach ($id in $ids) {
        if ($seen) { $pick = $id; break }
        if ($id -eq $script:TargetId) { $seen = $true }
    }
    $script:TargetId = $pick
}

function Speed-Of([double]$x, [double]$y, [double]$z) {
    return [Math]::Sqrt($x * $x + $y * $y + $z * $z)
}

function Brake-Velocity([double]$rate, [double]$dt) {
    $sp = Speed-Of $script:Vx $script:Vy $script:Vz
    if ($sp -lt 0.01) { $script:Vx = 0; $script:Vy = 0; $script:Vz = 0; return }
    $drop = $rate * $dt
    if ($drop -gt $sp) { $drop = $sp }
    $scale = ($sp - $drop) / $sp
    $script:Vx *= $scale; $script:Vy *= $scale; $script:Vz *= $scale
}

function Clamp-Speed([double]$max) {
    $sp = Speed-Of $script:Vx $script:Vy $script:Vz
    if ($sp -gt $max -and $sp -gt 0.01) {
        $scale = $max / $sp
        $script:Vx *= $scale; $script:Vy *= $scale; $script:Vz *= $scale
    }
}

function Test-MassLocked {
    $ds = Speed-Of $script:Px $script:Py $script:Pz
    if ($ds -lt 2100) { return $true }
    $dx = $script:Px - $script:PlX; $dy = $script:Py - $script:PlY; $dz = $script:Pz - $script:PlZ
    $dp = Speed-Of $dx $dy $dz
    if ($dp -lt ($script:PlR + 700)) { return $true }
    return $false
}

function Test-TorusLocked {
    if (Test-MassLocked) { return $true }
    $dx = $script:Px - $script:SuX; $dy = $script:Py - $script:SuY; $dz = $script:Pz - $script:SuZ
    if ((Speed-Of $dx $dy $dz) -lt ($script:SuR + 4000)) { return $true }
    if ($null -eq $script:Ships) { return $false }
    foreach ($s in $script:Ships) {
        if ($s.Hull -le 0 -or $s.Role -eq 'cargo' -or $s.Role -eq 'rock') { continue }
        if ((Speed-Of ($s.X - $script:Px) ($s.Y - $script:Py) ($s.Z - $script:Pz)) -lt 2600) { return $true }
    }
    return $false
}

function Try-Jump {
    if ($script:JumpT -gt 0) { $script:JumpT = 0; Say 'Hyperspace aborted.'; return }
    if ($script:Witch) {
        foreach ($s in $script:Ships) {
            if ($s.Role -eq 'alien' -and $s.Hull -gt 0) { Say 'Witch-space interference.'; return }
        }
        Complete-Witch
        return
    }
    if ($script:JumpTarget -lt 0 -or $script:JumpTarget -gt 255) { Say 'Set a destination on the chart (C).'; return }
    if ($script:JumpTarget -eq $script:Sys) { Say 'You are already in that system.'; return }
    $dist = Get-Ly $script:Sys $script:JumpTarget
    if ($dist -gt $script:Fuel + 0.001) { Say "Need $(F1 $dist) LY of fuel."; return }
    if (Test-MassLocked) { Say 'Mass-locked. Move away from the station or planet.'; return }
    $script:JumpT = 3.0
    Say 'Hyperspace in 3.'
}

function Complete-Jump {
    if ($script:JumpTarget -lt 0 -or $script:JumpTarget -gt 255 -or $script:JumpTarget -eq $script:Sys) {
        Say 'Hyperspace aborted.'
        return
    }
    $dist = Get-Ly $script:Sys $script:JumpTarget
    if ($dist -gt $script:Fuel + 0.001) { Say "Need $(F1 $dist) LY of fuel."; return }
    if (Test-MassLocked) { Say 'Mass-locked. Countdown cancelled.'; return }
    $leak = $false
    $destTech = $script:Systems[$script:JumpTarget].Tech
    $canEscape = $script:Scoops -or ($script:GalCharges -gt 0) -or ($destTech -ge 5)
    if ($script:Nova -eq 0 -and $script:Day -ge 2 -and $canEscape -and (($script:GalSeed + $script:Day * 3) % 7) -eq 0) { $leak = $true }
    $script:Fuel -= $dist
    if ($script:Fuel -lt 0) { $script:Fuel = 0 }
    $script:Day++
    $script:PendingSys = $script:JumpTarget
    $witchRoll = ($script:Systems[$script:Sys].Seed + $script:Day * 29 + $script:GalNum) % 11
    if ($witchRoll -eq 0) { Enter-Witch }
    else {
        $script:Sys = $script:JumpTarget
        Enter-Space 'jump'
    }
    if ($leak) {
        $script:Fuel = 0.2
        $script:Nova = 1
        Say 'Fuel leak. The tank is almost empty. Dock now.'
    }
}

function Try-Galactic {
    if ($script:GalCharges -le 0) { Say 'No galactic hyperdrive.'; return }
    if ($script:Witch) { Say 'Not in witch-space.'; return }
    if (Test-MassLocked) { Say 'Mass-locked.'; return }
    $script:GalCharges--
    $script:GalDrive = ($script:GalCharges -gt 0)
    $script:GalNum++
    if ($script:GalNum -gt 8) { $script:GalNum = 1 }
    $script:GalSeed = ($script:GalSeed + 4099) -band 65535
    if ($script:GalSeed -eq 0) { $script:GalSeed = 17 }
    $keep = $script:Sys
    Build-Galaxy $script:GalSeed
    $script:Sys = $keep
    $script:JumpTarget = -1
    $script:Market = $null
    $script:Day++
    Enter-Space 'jump'
    Say "Galaxy $($script:GalNum). That hyperdrive is spent."
}

function Station-Entrance {
    $script:Ex = [Math]::Sin($script:StAngle)
    $script:Ez = [Math]::Cos($script:StAngle)
}

function Try-Dock {
    if ($script:Witch) { Say 'There is no station here.'; return }
    Station-Entrance
    $dist = Speed-Of $script:Px $script:Py $script:Pz
    $sp = Speed-Of $script:Vx $script:Vy $script:Vz
    $align = 0.0
    if ($dist -gt 1) { $align = ($script:Px * $script:Ex + $script:Pz * $script:Ez) / $dist }
    $facing = 0.0
    if ($dist -gt 1) {
        $facing = - ($script:M[6] * $script:Px + $script:M[7] * $script:Py + $script:M[8] * $script:Pz) / $dist
    }
    if ($dist -lt 820 -and $sp -lt 62 -and $align -gt 0.72 -and $facing -gt 0.2) {
        $script:DidDock = $true
        return
    }
    if ($script:DockComp) {
        $script:AutoDock = -not $script:AutoDock
        if ($script:AutoDock) { Say 'Docking computer engaged.' }
        else { Say 'Docking computer off.' }
        return
    }
    if ($dist -lt 820) {
        $pct = [int]([Math]::Max(0, $align) * 100)
        Say "Dock failed. Align $pct%  speed $(F0 $sp)  (need 72% and under 62)."
        return
    }
    Say 'Too far to dock. Buy a docking computer or fly in.'
}

function Offer-Missions {
    if ($script:Nova -eq 1) {
        Clear-Cargo
        $script:Cargo['Refugees'] = 10
        Update-CargoUsed
        $script:Nova = 2
        $script:NovaSys = $script:Sys
        Say 'The sun is going nova. Refugees fill the hold. Leave and do not come back.'
        return
    }
    if ($script:Nova -eq 2 -and $script:Sys -eq $script:NovaSys) {
        Say 'The station will not keep the refugees. Leave this system.'
        return
    }
    if ($script:Nova -eq 2) {
        if ($script:Cargo.ContainsKey('Refugees')) { [void]$script:Cargo.Remove('Refugees') }
        Update-CargoUsed
        $script:Cash += 1000
        $script:Nova = 3
        Say 'Refugees safe. The navy pays 1000 CR.'
        return
    }
    if ($script:Cloak -eq 0 -and $script:Kills -ge 512) {
        $script:Cloak = 1
        Say 'Naval note: a cloaked Asp will meet you after launch. Scoop what it drops.'
        return
    }
    if ($script:Base -eq 0 -and $script:Kills -ge 2560) {
        $script:Base = 1
        $script:Heavy = 1
        Say 'Thargoid station occupies this system. One heavy missile is aboard. Press B.'
        return
    }
}

function Apply-DockService {
    $sys = $script:Systems[$script:Sys]
    $script:ShieldF = $script:ShieldMax
    $script:ShieldA = $script:ShieldMax
    $script:Shield = $script:ShieldMax
    $script:Energy = $script:EnergyMax
    $script:Heat = 0
    $script:Temp = 0
    $script:CloakOn = $false
    $script:JumpT = 0
    $script:AutoDock = $false
    $script:Vx = 0; $script:Vy = 0; $script:Vz = 0
    if ($script:Escaping) {
        $script:Escaping = $false
        $script:Legal = 0
        Say "Pod recovered at $($sys.Name). Status cleared. The new Cobra keeps your fittings."
        Offer-Missions
        Save-Commander
        return
    }
    $fine = 0
    if (Test-Lawful $sys.Gov) {
        $fine += $script:Legal * 20
        foreach ($k in @($script:Cargo.Keys)) {
            if (Test-Contraband $k) {
                $q = [int]$script:Cargo[$k]
                $fine += $q * 40
                [void]$script:Cargo.Remove($k)
            }
        }
        Update-CargoUsed
    }
    if ($fine -gt 0) {
        if ($script:Cash -ge $fine) {
            $script:Cash -= $fine
            $script:Legal = 0
            Say "Docked. Fine $fine CR paid. Shields restored."
        }
        else {
            $script:Cash = 0
            Say "Docked. Fine $fine CR. Credits seized, status remains."
        }
    }
    else {
        Say "Docked at $($sys.Name). Shields restored."
    }
    Offer-Missions
    Save-Commander
}

function Update-Enemies([double]$dt) {
    $mother = $false
    foreach ($e in $script:Ships) {
        if ($e.Role -eq 'alien' -and $e.Hull -gt 0) { $mother = $true }
    }
    if (-not $mother) {
        foreach ($e in $script:Ships) {
            if ($e.Type -eq 'Thargon' -and $e.Hull -gt 0) { $e.Hull = 0 }
        }
    }
    $safe = (Speed-Of $script:Px $script:Py $script:Pz) -lt 1700
    foreach ($e in $script:Ships) {
        if ($e.Hull -le 0) { continue }
        if ($e.Role -eq 'cargo' -or $e.Role -eq 'base') { continue }
        if ($e.Role -eq 'rock') {
            $e.X += $e.VX * $dt; $e.Y += $e.VY * $dt; $e.Z += $e.VZ * $dt
            continue
        }
        if ($e.Role -eq 'alien') {
            $e.SpawnT -= $dt
            $thargons = 0
            foreach ($t in $script:Ships) { if ($t.Type -eq 'Thargon' -and $t.Hull -gt 0) { $thargons++ } }
            if ($e.SpawnT -le 0 -and $thargons -lt 4) {
                $spawn = New-Ship 'Thargon' 'thargon' ($e.X + 180) $e.Y ($e.Z - 200)
                if ($null -eq $script:Pending) { $script:Pending = New-Object System.Collections.Generic.List[object] }
                $script:Pending.Add($spawn)
                $e.SpawnT = 2.6
            }
        }
        $dx = $script:Px - $e.X; $dy = $script:Py - $e.Y; $dz = $script:Pz - $e.Z
        $dist = Speed-Of $dx $dy $dz
        $hostile = $e.Role -eq 'pirate' -or $e.Role -eq 'police' -or $e.Role -eq 'alien' -or $e.Role -eq 'hunter' -or $e.Role -eq 'thargon' -or $e.Role -eq 'cloak' -or $e.Provoked
        if ($script:CloakOn -and $dist -gt 480) { $hostile = $false }
        if ($e.Role -eq 'trader' -and -not $e.Provoked) {
            $dx = $e.Jx - $e.X; $dy = $e.Jy - $e.Y; $dz = $e.Jz - $e.Z
            if ((Speed-Of $dx $dy $dz) -lt 600) {
                $e.Jx = $e.X + (($e.Id * 137) % 4000) - 2000
                $e.Jz = $e.Z + (($e.Id * 91) % 4000) - 2000
            }
        }
        Get-Steer $e.M $dx $dy $dz
        Turn-Ship $e.M ($script:StPitch * $dt) ($script:StRoll * $dt)
        Repair-Axes $e.M
        $chase = $dist
        if (-not $hostile) { $chase = Speed-Of ($e.Jx - $e.X) ($e.Jy - $e.Y) ($e.Jz - $e.Z) }
        if ($chase -gt 700) {
            $e.VX += $e.M[6] * $e.Accel * $dt
            $e.VY += $e.M[7] * $e.Accel * $dt
            $e.VZ += $e.M[8] * $e.Accel * $dt
        }
        $sp = Speed-Of $e.VX $e.VY $e.VZ
        if ($sp -gt $e.MaxSp -and $sp -gt 0.01) {
            $sc = $e.MaxSp / $sp
            $e.VX *= $sc; $e.VY *= $sc; $e.VZ *= $sc
        }
        $e.X += $e.VX * $dt; $e.Y += $e.VY * $dt; $e.Z += $e.VZ * $dt
        $e.Cool -= $dt
        if ($hostile -and -not $safe -and $e.Cool -le 0 -and $dist -lt 4200 -and $dist -gt 200) {
            World-To-Local $e.M ($script:Px - $e.X) ($script:Py - $e.Y) ($script:Pz - $e.Z)
            $ld = Speed-Of $script:LocX $script:LocY $script:LocZ
            if ($ld -gt 1 -and $script:LocZ -gt 0) {
                $off = [Math]::Sqrt($script:LocX * $script:LocX + $script:LocY * $script:LocY) / $ld
                if ($off -lt 0.16) {
                    if ($e.Msl -gt 0 -and $dist -lt 2600) {
                        $e.Msl--
                        $script:Bolts.Add(@{
                            X = $e.X; Y = $e.Y; Z = $e.Z
                            VX = $e.M[6] * 500; VY = $e.M[7] * 500; VZ = $e.M[8] * 500
                            Life = 8.0; Target = -2; Player = $true; Heavy = $false
                        })
                        $e.Cool = 2.4
                        Say 'INCOMING MISSILE'
                    }
                    else {
                        World-To-Local $script:M ($e.X - $script:Px) ($e.Y - $script:Py) ($e.Z - $script:Pz)
                        Hurt-Player $e.Dmg ($script:LocZ -ge 0)
                        $e.Cool = 1.15
                        Say 'Under fire.'
                    }
                }
            }
        }
        if ($dist -lt (70 + $e.Radius) -and $e.Role -ne 'cargo') {
            World-To-Local $script:M ($e.X - $script:Px) ($e.Y - $script:Py) ($e.Z - $script:Pz)
            Hurt-Player 8 ($script:LocZ -ge 0)
            $e.Hull -= 6
        }
    }
    Flush-Pending
}

function Update-Bolts([double]$dt) {
    for ($i = $script:Bolts.Count - 1; $i -ge 0; $i--) {
        $b = $script:Bolts[$i]
        $target = $null
        foreach ($s in $script:Ships) {
            if ($s.Id -eq $b.Target -and $s.Hull -gt 0) { $target = $s }
        }
        $aimX = 0.0; $aimY = 0.0; $aimZ = 0.0; $homing = $false
        if ($b.Target -eq -2) {
            $aimX = $script:Px; $aimY = $script:Py; $aimZ = $script:Pz
            $homing = $true
        }
        elseif ($null -ne $target) {
            $aimX = $target.X; $aimY = $target.Y; $aimZ = $target.Z
            $homing = $true
        }
        if ($homing) {
            $dx = $aimX - $b.X; $dy = $aimY - $b.Y; $dz = $aimZ - $b.Z
            $dist = Speed-Of $dx $dy $dz
            if ($null -ne $target -and $target.Ecm -and $dist -lt 900 -and (($script:Tick % 4) -eq 0)) {
                $script:Bolts.Clear()
                $script:EcmT = 2.2
                Say "$($target.Type) fires ECM."
                return
            }
            if ($dist -lt 120) {
                if ($b.Target -eq -2) {
                    Hurt-Player 30 $true
                    Say 'Missile impact.'
                }
                else {
                    $blow = 46.0
                    if ($b.ContainsKey('Heavy') -and $b.Heavy) { $blow = 220 }
                    $target.Hull -= $blow
                    if ($target.Role -eq 'trader') { $target.Provoked = $true; $script:Legal += 1 }
                    if ($target.Hull -le 0) { Kill-Ship $target }
                }
                $script:Bolts.RemoveAt($i)
                continue
            }
            if ($dist -gt 0.01) {
                $b.VX = $dx / $dist * 780
                $b.VY = $dy / $dist * 780
                $b.VZ = $dz / $dist * 780
            }
        }
        $b.X += $b.VX * $dt; $b.Y += $b.VY * $dt; $b.Z += $b.VZ * $dt
        $b.Life -= $dt
        if ($b.Life -le 0) { $script:Bolts.RemoveAt($i) }
    }
}

function Sweep-Dead {
    for ($i = $script:Ships.Count - 1; $i -ge 0; $i--) {
        if ($script:Ships[$i].Hull -le 0) {
            if ($script:TargetId -eq $script:Ships[$i].Id) { $script:TargetId = -1 }
            $script:Ships.RemoveAt($i)
        }
    }
    for ($i = $script:Debris.Count - 1; $i -ge 0; $i--) {
        $d = $script:Debris[$i]
        $d.X += $d.VX * 0.05; $d.Y += $d.VY * 0.05; $d.Z += $d.VZ * 0.05
        $d.Life -= 0.05
        if ($d.Life -le 0) { $script:Debris.RemoveAt($i) }
    }
}

function Scoop-Cans {
    if ($null -eq $script:Ships) { return }
    Sync-Camera
    for ($i = $script:Ships.Count - 1; $i -ge 0; $i--) {
        $s = $script:Ships[$i]
        if ($s.Role -ne 'cargo' -or $s.Hull -le 0) { continue }
        $dist = Speed-Of ($s.X - $script:Px) ($s.Y - $script:Py) ($s.Z - $script:Pz)
        if ($dist -gt 260) { continue }
        Cam-Local ($s.X - $script:Px) ($s.Y - $script:Py) ($s.Z - $script:Pz)
        if ($script:LocZ -le 0 -or $script:LocY -gt 40) { continue }
        if ($s.Good -eq 'Cloak') {
            $script:HasCloak = $true
            $script:Cloak = 3
            $s.Hull = 0
            Say 'Cloaking device scooped. Press V.'
            continue
        }
        $good = [string]$s.Good
        if ($good.Length -eq 0) { $good = 'Minerals' }
        if ($script:CargoUsed -ge $script:CargoMax) { Say 'Hold full.'; continue }
        $script:Cargo[$good] = (Get-Hold $good) + 1
        Update-CargoUsed
        $s.Hull = 0
        Say "Scooped 1t $good."
    }
}

function Update-Flight([double]$dt) {
    if ($script:Dead) { return 'dead' }
    if ($dt -gt 0.12) { $dt = 0.12 }
    if ($dt -lt 0.001) { $dt = 0.001 }
    $script:StSpin += $dt * 0.09
    $script:Cool -= $dt
    if ($script:Cool -lt 0) { $script:Cool = 0 }
    $script:LaserT -= $dt
    $script:HitFlash -= $dt
    $script:SinceHit += $dt
    $script:EcmT -= $dt
    if ($script:EcmT -lt 0) { $script:EcmT = 0 }
    $script:MsgT -= $dt
    $script:Tick++
    $script:Heat -= 24 * $dt
    if ($script:Heat -lt 0) { $script:Heat = 0 }
    if ($script:JumpT -gt 0) {
        $script:JumpT -= $dt
        if ($script:JumpT -le 0) {
            $script:JumpT = 0
            Complete-Jump
            return 'ok'
        }
    }
    $recharge = 16.0
    if ($script:EnergyUnit) { $recharge = 32.0 }
    if ($script:CloakOn) {
        $recharge -= 12.0
        if ($script:Energy -lt 8) { $script:CloakOn = $false; Say 'Cloak dropped. Energy gone.' }
    }
    if ($script:Energy -lt $script:EnergyMax) {
        $script:Energy += $recharge * $dt
        if ($script:Energy -gt $script:EnergyMax) { $script:Energy = $script:EnergyMax }
        if ($script:Energy -lt 0) { $script:Energy = 0 }
    }
    if ($script:Energy -gt 0 -and $script:Energy -lt 25 -and $script:Msg -ne 'ENERGY LOW') { Say 'ENERGY LOW' }
    if ($script:SinceHit -gt 2.2) {
        if ($script:ShieldF -lt $script:ShieldMax) { $script:ShieldF += 12 * $dt }
        if ($script:ShieldA -lt $script:ShieldMax) { $script:ShieldA += 12 * $dt }
        if ($script:ShieldF -gt $script:ShieldMax) { $script:ShieldF = $script:ShieldMax }
        if ($script:ShieldA -gt $script:ShieldMax) { $script:ShieldA = $script:ShieldMax }
        $script:Shield = $script:ShieldF
    }

    $pitch = $script:InPitch * 1.7
    $roll = $script:InRoll * 2.2
    $manualTurn = ([Math]::Abs($script:InPitch) -gt 0.01) -or ([Math]::Abs($script:InRoll) -gt 0.01)
    $manualThrust = [Math]::Abs($script:InThrust) -gt 0.01 -or $script:InBrake

    if ($script:AutoDock -and -not $script:Witch -and -not $manualTurn) {
        Station-Entrance
        $dist = Speed-Of $script:Px $script:Py $script:Pz
        $along = $script:Px * $script:Ex + $script:Pz * $script:Ez
        $aimR = $along - 280.0
        if ($aimR -lt 560) { $aimR = 560 }
        Get-Steer $script:M (($script:Ex * $aimR) - $script:Px) (0 - $script:Py) (($script:Ez * $aimR) - $script:Pz)
        $pitch = $script:StPitch
        $roll = $script:StRoll
        if ($dist -lt 1800) {
            $roll += $script:M[1] * 1.8
            if ($script:M[4] -lt 0.45) { $roll += 1.5 }
        }
        $sp = Speed-Of $script:Vx $script:Vy $script:Vz
        $desired = 90.0
        if ($dist -lt 2200) { $desired = 48 }
        if ($dist -lt 1200) { $desired = 28 }
        if ($script:LocZ -lt 0.86) {
            $script:InThrust = 0
            $script:InBrake = $true
        }
        elseif ($sp -lt $desired - 4) { $script:InThrust = 1; $script:InBrake = $false }
        elseif ($sp -gt $desired + 8) { $script:InBrake = $true; $script:InThrust = 0 }
        else { $script:InThrust = 0; $script:InBrake = $false }
    }

    $script:DialPitch = $pitch
    $script:DialRoll = $roll
    Turn-Ship $script:M ($pitch * $dt) ($roll * $dt)
    Repair-Axes $script:M
    if ($script:InThrust -gt 0) {
        $script:Vx += $script:M[6] * 230 * $dt
        $script:Vy += $script:M[7] * 230 * $dt
        $script:Vz += $script:M[8] * 230 * $dt
        if ($manualThrust) { $script:AutoDock = $false }
    }
    elseif ($script:InThrust -lt 0) {
        $script:Vx -= $script:M[6] * 150 * $dt
        $script:Vy -= $script:M[7] * 150 * $dt
        $script:Vz -= $script:M[8] * 150 * $dt
        if ($manualThrust) { $script:AutoDock = $false }
    }
    if ($script:InBrake) {
        Brake-Velocity 170 $dt
        if ($manualThrust) { $script:AutoDock = $false }
    }
    $torusGo = $false
    if ($script:InTorus) {
        if ($script:Witch -or (Test-TorusLocked)) {
            if ($script:Msg -ne 'Mass-locked.') { Say 'Mass-locked.' }
        }
        else {
            $script:Vx = $script:M[6] * 2100
            $script:Vy = $script:M[7] * 2100
            $script:Vz = $script:M[8] * 2100
            $script:AutoDock = $false
            $torusGo = $true
        }
    }
    if ($torusGo) { Clamp-Speed 2200 } else { Clamp-Speed 640 }
    $script:Px += $script:Vx * $dt
    $script:Py += $script:Vy * $dt
    $script:Pz += $script:Vz * $dt

    if (-not $script:Witch) {
        $sux = $script:Px - $script:SuX; $suy = $script:Py - $script:SuY; $suz = $script:Pz - $script:SuZ
        $sud = Speed-Of $sux $suy $suz
        $script:Temp = 0
        if ($sud -lt ($script:SuR + 2200)) {
            $script:Temp = (1.0 - (($sud - $script:SuR) / 2200.0)) * 100.0
            if ($script:Temp -lt 0) { $script:Temp = 0 }
            if ($script:Temp -gt 100) { $script:Temp = 100 }
            if ($script:Scoops -and $sud -gt ($script:SuR + 180) -and $script:Fuel -lt 7) {
                $script:Fuel += 0.5 * $dt
                if ($script:Fuel -gt 7) { $script:Fuel = 7 }
                if ($script:MsgT -lt 0.3) { Say 'Fuel scooping.' }
            }
            if ($script:Temp -gt 92) { Hurt-Player (24 * $dt) $true }
        }
        if ($script:Scoops) { Scoop-Cans }
        $pdx = $script:Px - $script:PlX; $pdy = $script:Py - $script:PlY; $pdz = $script:Pz - $script:PlZ
        $pd = Speed-Of $pdx $pdy $pdz
        if ($pd -lt $script:PlR + 30) {
            Hurt-Player 80
            $push = ($script:PlR + 80) / $pd
            $script:Px = $script:PlX + $pdx * $push
            $script:Py = $script:PlY + $pdy * $push
            $script:Pz = $script:PlZ + $pdz * $push
            Say 'Planet collision.'
        }
        $sd = Speed-Of $script:Px $script:Py $script:Pz
        Station-Entrance
        $sp = Speed-Of $script:Vx $script:Vy $script:Vz
        $align = 0.0
        if ($sd -gt 1) { $align = ($script:Px * $script:Ex + $script:Pz * $script:Ez) / $sd }
        $facingIn = 0.0
        if ($sd -gt 1) {
            $facingIn = - ($script:M[6] * $script:Px + $script:M[7] * $script:Py + $script:M[8] * $script:Pz) / $sd
        }
        if ($sd -lt 820 -and $align -gt 0.72 -and $sp -lt 62 -and $facingIn -gt 0.2) {
            if ($script:M[4] -lt 0.45) {
                if ($script:HitFlash -le 0) { Hurt-Player 10 $true; Say 'Roll the slot level.' }
            }
            else { $script:DidDock = $true }
        }
        elseif ($sd -lt 400) {
            $ux = $script:Px / $sd
            $uy = $script:Py / $sd
            $uz = $script:Pz / $sd
            $script:Px = $ux * 520
            $script:Py = $uy * 520
            $script:Pz = $uz * 520
            $script:Vx = $ux * 25
            $script:Vy = $uy * 25
            $script:Vz = $uz * 25
            if ($script:HitFlash -le 0) { Hurt-Player 18; Say 'Hull strike on the station.' }
        }
    }

    Update-Enemies $dt
    Update-Bolts $dt
    Sweep-Dead
    if ($script:InFire) { Try-Fire }
    Flush-Pending
    if ($script:Dead) { return 'dead' }
    if ($script:DidDock) { return 'docked' }
    return 'ok'
}

function Set-Frame([int]$w, [int]$h) {
    if ($w -lt 40) { $w = 40 }
    if ($h -lt 16) { $h = 16 }
    $script:W = $w
    $script:H = $h
    $script:HudH = 11
    if ($h -lt 28) { $script:HudH = 9 }
    if ($h -lt 24) { $script:HudH = 6 }
    $script:ViewY = 1
    $script:ViewH = $h - 1 - $script:HudH
    if ($script:ViewH -lt 6) { $script:ViewH = 6 }
    $script:HudY = $script:ViewY + $script:ViewH
    if ($script:HudY + $script:HudH -gt $h) { $script:HudY = $h - $script:HudH }
    $script:CX = [int]($w / 2)
    $script:CY = $script:ViewY + [int]($script:ViewH / 2)
    $script:Fov = [Math]::Max(18.0, $script:ViewH * 1.15)
    Enable-Braille
    $script:DW = $w * 2
    $script:DH = $script:ViewH * 4
    $script:Dots = New-Object 'byte[]' ($script:DW * $script:DH)
    $script:DotSX = $script:Fov * 3.30
    $script:DotSY = $script:Fov * 3.28
    $script:DX = ($script:CX * 2) + 1
    $script:DY = (($script:CY - $script:ViewY) * 4) + 2
    $n = $w * $h
    $script:Buf = New-Object 'char[]' $n
    $script:Col = New-Object 'byte[]' $n
    $script:Blank = New-Object 'char[]' $n
    for ($i = 0; $i -lt $n; $i++) { $script:Blank[$i] = ' ' }
    if ($null -eq $script:Sb) { $script:Sb = New-Object System.Text.StringBuilder ($n + 512) }
}

function Sync-Console {
    $w = 80
    $h = 30
    try {
        $w = [Console]::WindowWidth - 1
        $h = [Console]::WindowHeight - 1
    }
    catch { }
    if ($w -lt 40) { $w = 40 }
    if ($h -lt 16) { $h = 16 }
    if ($w -gt 200) { $w = 200 }
    if ($h -gt 64) { $h = 64 }
    if ($script:W -eq $w -and $script:H -eq $h -and $null -ne $script:Buf) { return }
    $redraw = ($null -ne $script:Buf -and $script:ConsoleOn)
    Set-Frame $w $h
    if ($redraw) {
        try { [Console]::Clear() } catch { }
    }
}

function Clear-Frame {
    [Array]::Copy($script:Blank, $script:Buf, $script:Buf.Length)
    [Array]::Clear($script:Col, 0, $script:Col.Length)
    if ($null -ne $script:Dots) {
        [Array]::Clear($script:Dots, 0, $script:Dots.Length)
    }
}

function Write-At([int]$x, [int]$y, [string]$text, [byte]$color, [int]$maxW) {
    if ($y -lt 0 -or $y -ge $script:H) { return }
    if ($maxW -le 0) { $maxW = $script:W }
    $n = $text.Length
    if ($n -gt $maxW) { $n = $maxW }
    $w = $script:W
    for ($i = 0; $i -lt $n; $i++) {
        $xx = $x + $i
        if ($xx -ge 0 -and $xx -lt $w) {
            $idx = $y * $w + $xx
            $script:Buf[$idx] = $text[$i]
            $script:Col[$idx] = $color
        }
    }
}

function Write-Mid([int]$y, [string]$text, [byte]$color) {
    $x = [int](($script:W - $text.Length) / 2)
    if ($x -lt 0) { $x = 0 }
    Write-At $x $y $text $color $script:W
}

function Enable-Braille {
    if (-not ('EliteBraille.Raster' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
namespace EliteBraille {
  public static class Raster {
    public static void Plot(byte[] dots, int dw, int dh, int x, int y, byte color) {
      if ((uint)x < (uint)dw && (uint)y < (uint)dh) dots[y * dw + x] = color;
    }
    public static void Line(byte[] dots, int dw, int dh, int x0, int y0, int x1, int y1, byte color) {
      if (dw < 1 || dh < 1) return;
      if (!Clip(ref x0, ref y0, ref x1, ref y1, 0, 0, dw - 1, dh - 1)) return;
      int dx = Math.Abs(x1 - x0);
      int sx = x0 < x1 ? 1 : -1;
      int dy = -Math.Abs(y1 - y0);
      int sy = y0 < y1 ? 1 : -1;
      int err = dx + dy;
      int guard = 0;
      int limit = dw + dh + 4;
      while (guard++ < limit) {
        if ((uint)x0 < (uint)dw && (uint)y0 < (uint)dh)
          dots[y0 * dw + x0] = color;
        if (x0 == x1 && y0 == y1) break;
        int e2 = err << 1;
        if (e2 >= dy) { err += dy; x0 += sx; }
        if (e2 <= dx) { err += dx; y0 += sy; }
      }
    }
    static int OutCode(int x, int y, int xMin, int yMin, int xMax, int yMax) {
      int c = 0;
      if (x < xMin) c |= 1;
      else if (x > xMax) c |= 2;
      if (y < yMin) c |= 4;
      else if (y > yMax) c |= 8;
      return c;
    }
    static bool Clip(ref int x0, ref int y0, ref int x1, ref int y1, int xMin, int yMin, int xMax, int yMax) {
      int c0 = OutCode(x0, y0, xMin, yMin, xMax, yMax);
      int c1 = OutCode(x1, y1, xMin, yMin, xMax, yMax);
      for (int n = 0; n < 12; n++) {
        if ((c0 | c1) == 0) return true;
        if ((c0 & c1) != 0) return false;
        int c = c0 != 0 ? c0 : c1;
        int x, y;
        if ((c & 8) != 0) {
          x = x0 + (int)(((long)(x1 - x0) * (yMax - y0)) / (y1 - y0));
          y = yMax;
        }
        else if ((c & 4) != 0) {
          x = x0 + (int)(((long)(x1 - x0) * (yMin - y0)) / (y1 - y0));
          y = yMin;
        }
        else if ((c & 2) != 0) {
          y = y0 + (int)(((long)(y1 - y0) * (xMax - x0)) / (x1 - x0));
          x = xMax;
        }
        else {
          y = y0 + (int)(((long)(y1 - y0) * (xMin - x0)) / (x1 - x0));
          x = xMin;
        }
        if (c == c0) { x0 = x; y0 = y; c0 = OutCode(x0, y0, xMin, yMin, xMax, yMax); }
        else { x1 = x; y1 = y; c1 = OutCode(x1, y1, xMin, yMin, xMax, yMax); }
      }
      return false;
    }
    public static void Stamp(byte[] dots, int dw, char[] buf, byte[] col, int stride, int viewY, int viewH, byte[] pri) {
      for (int cy = 0; cy < viewH; cy++) {
        int rowBase = cy * 4 * dw;
        int bufRow = (cy + viewY) * stride;
        for (int cx = 0; cx < stride; cx++) {
          int i = rowBase + (cx << 1);
          int mask = 0;
          byte best = 0;
          byte bestP = 0;
          byte c;
          c = dots[i];
          if (c != 0) { mask |= 0x01; if (pri[c] >= bestP) { bestP = pri[c]; best = c; } }
          c = dots[i + 1];
          if (c != 0) { mask |= 0x08; if (pri[c] >= bestP) { bestP = pri[c]; best = c; } }
          int i2 = i + dw;
          c = dots[i2];
          if (c != 0) { mask |= 0x02; if (pri[c] >= bestP) { bestP = pri[c]; best = c; } }
          c = dots[i2 + 1];
          if (c != 0) { mask |= 0x10; if (pri[c] >= bestP) { bestP = pri[c]; best = c; } }
          int i3 = i2 + dw;
          c = dots[i3];
          if (c != 0) { mask |= 0x04; if (pri[c] >= bestP) { bestP = pri[c]; best = c; } }
          c = dots[i3 + 1];
          if (c != 0) { mask |= 0x20; if (pri[c] >= bestP) { bestP = pri[c]; best = c; } }
          int i4 = i3 + dw;
          c = dots[i4];
          if (c != 0) { mask |= 0x40; if (pri[c] >= bestP) { bestP = pri[c]; best = c; } }
          c = dots[i4 + 1];
          if (c != 0) { mask |= 0x80; if (pri[c] >= bestP) { bestP = pri[c]; best = c; } }
          if (mask != 0) {
            buf[bufRow + cx] = (char)(0x2800 + mask);
            col[bufRow + cx] = best;
          }
        }
      }
    }
  }
}
'@
    }
    if ($null -eq $script:Pri) {
        $p = New-Object 'byte[]' 16
        $p[2] = 3
        $p[3] = 4
        $p[5] = 2
        $p[7] = 2
        $p[8] = 1
        $p[9] = 5
        $p[11] = 4
        $p[13] = 5
        $p[14] = 6
        for ($i = 1; $i -le 15; $i++) {
            if ($p[$i] -eq 0) { $p[$i] = 2 }
        }
        $script:Pri = $p
    }
}

function Plot-Dot([int]$x, [int]$y, [byte]$color) {
    [EliteBraille.Raster]::Plot($script:Dots, $script:DW, $script:DH, $x, $y, $color)
}

function Draw-DotLine([int]$x0, [int]$y0, [int]$x1, [int]$y1, [byte]$color) {
    [EliteBraille.Raster]::Line($script:Dots, $script:DW, $script:DH, $x0, $y0, $x1, $y1, $color)
}

function Stamp-Braille {
    [EliteBraille.Raster]::Stamp($script:Dots, $script:DW, $script:Buf, $script:Col, $script:W, $script:ViewY, $script:ViewH, $script:Pri)
}

function Draw-Reticle([byte]$color) {
    $x = [int]$script:DX
    $y = [int]$script:DY
    for ($i = 3; $i -le 9; $i++) {
        Plot-Dot ($x + $i) $y $color
        Plot-Dot ($x - $i) $y $color
        Plot-Dot $x ($y + $i) $color
        Plot-Dot $x ($y - $i) $color
    }
}

function Draw-ViewLine([double]$x1, [double]$y1, [double]$z1, [double]$x2, [double]$y2, [double]$z2, [char]$ch, [byte]$color) {
    $near = 0.85
    if ($z1 -lt $near -and $z2 -lt $near) { return }
    if ($z1 -lt $near -or $z2 -lt $near) {
        $den = $z2 - $z1
        if ([Math]::Abs($den) -lt 0.00001) { return }
        $t = ($near - $z1) / $den
        $ix = $x1 + ($x2 - $x1) * $t
        $iy = $y1 + ($y2 - $y1) * $t
        if ($z1 -lt $near) { $x1 = $ix; $y1 = $iy; $z1 = $near }
        else { $x2 = $ix; $y2 = $iy; $z2 = $near }
    }
    $sx1 = $script:DX + ($x1 / $z1) * $script:DotSX
    $sy1 = $script:DY - ($y1 / $z1) * $script:DotSY
    $sx2 = $script:DX + ($x2 / $z2) * $script:DotSX
    $sy2 = $script:DY - ($y2 / $z2) * $script:DotSY
    Draw-DotLine ([int]$sx1) ([int]$sy1) ([int]$sx2) ([int]$sy2) $color
}

function Draw-Ellipse([double]$cx, [double]$cy, [double]$rx, [double]$ry, [char]$ch, [byte]$color) {
    if ($rx -lt 1.2) { $rx = 1.2 }
    if ($ry -lt 1.2) { $ry = 1.2 }
    if ($rx -gt 220) { $rx = 220 }
    if ($ry -gt 160) { $ry = 160 }
    $steps = [int](($rx + $ry) * 0.45)
    if ($steps -lt 18) { $steps = 18 }
    if ($steps -gt 72) { $steps = 72 }
    $prevX = 0; $prevY = 0; $has = $false
    for ($i = 0; $i -le $steps; $i++) {
        $t = ($i / [double]$steps) * 6.28318530718
        $x = [int]($cx + [Math]::Cos($t) * $rx)
        $y = [int]($cy + [Math]::Sin($t) * $ry)
        if ($has) { Draw-DotLine $prevX $prevY $x $y $color }
        $prevX = $x; $prevY = $y; $has = $true
    }
}

function Project-Body([double]$wx, [double]$wy, [double]$wz) {
    $dx = $wx - $script:Px; $dy = $wy - $script:Py; $dz = $wz - $script:Pz
    Cam-Local $dx $dy $dz
    $script:BodyZ = $script:LocZ
    if ($script:LocZ -lt 0.85) { $script:BodyOn = $false; return }
    $script:BodyOn = $true
    $script:BodyX = $script:DX + ($script:LocX / $script:LocZ) * $script:DotSX
    $script:BodyY = $script:DY - ($script:LocY / $script:LocZ) * $script:DotSY
}

function Draw-Mesh($mesh, [double]$ox, [double]$oy, [double]$oz, [double[]]$rm, [double]$scale, [char]$ch, [byte]$color) {
    $verts = $mesh.V
    $edges = $mesh.E
    $n = [int]($verts.Length / 3)
    if ($null -eq $script:ViewTmp -or $script:ViewTmp.Length -lt ($n * 3)) {
        $script:ViewTmp = New-Object 'double[]' ($n * 3)
    }
    $c = $script:Cam
    if ($null -eq $c) { $c = $script:M }
    for ($i = 0; $i -lt $n; $i++) {
        $lx = $verts[$i * 3] * $scale
        $ly = $verts[$i * 3 + 1] * $scale
        $lz = $verts[$i * 3 + 2] * $scale
        $wx = $ox + $lx * $rm[0] + $ly * $rm[3] + $lz * $rm[6]
        $wy = $oy + $lx * $rm[1] + $ly * $rm[4] + $lz * $rm[7]
        $wz = $oz + $lx * $rm[2] + $ly * $rm[5] + $lz * $rm[8]
        $dx = $wx - $script:Px; $dy = $wy - $script:Py; $dz = $wz - $script:Pz
        $script:ViewTmp[$i * 3] = $dx * $c[0] + $dy * $c[1] + $dz * $c[2]
        $script:ViewTmp[$i * 3 + 1] = $dx * $c[3] + $dy * $c[4] + $dz * $c[5]
        $script:ViewTmp[$i * 3 + 2] = $dx * $c[6] + $dy * $c[7] + $dz * $c[8]
    }
    $vis = $null
    if ($mesh.ContainsKey('N') -and $mesh.ContainsKey('A')) {
        $norms = $mesh.N
        $nf = [int]($norms.Length / 3)
        if ($null -eq $script:FaceVis -or $script:FaceVis.Length -lt $nf) {
            $script:FaceVis = New-Object 'bool[]' $nf
        }
        $vis = $script:FaceVis
        $dxs = $ox - $script:Px
        $dys = $oy - $script:Py
        $dzs = $oz - $script:Pz
        $qx = $dxs * $rm[0] + $dys * $rm[1] + $dzs * $rm[2]
        $qy = $dxs * $rm[3] + $dys * $rm[4] + $dzs * $rm[5]
        $qz = $dxs * $rm[6] + $dys * $rm[7] + $dzs * $rm[8]
        $ahead = $dxs * $c[6] + $dys * $c[7] + $dzs * $c[8]
        $far = [int]($ahead / 256.0)
        if ($far -lt 0) { $far = 0 }
        if ($far -gt 31) { $far = 31 }
        $fv = $null
        if ($mesh.ContainsKey('FV')) { $fv = $mesh.FV }
        for ($i = 0; $i -lt $nf; $i++) {
            $faceFar = 31
            if ($null -ne $fv -and $i -lt $fv.Length) { $faceFar = [int]$fv[$i] }
            if ($far -gt $faceFar) { $vis[$i] = $true; continue }
            $nx = $norms[$i * 3] * $scale
            $ny = $norms[$i * 3 + 1] * $scale
            $nz = $norms[$i * 3 + 2] * $scale
            $dot = ($qx + $nx) * $nx + ($qy + $ny) * $ny + ($qz + $nz) * $nz
            $vis[$i] = ($dot -lt 0)
        }
    }
    $adj = $null
    $ev = $null
    if ($null -ne $vis) {
        $adj = $mesh.A
        if ($mesh.ContainsKey('EV')) { $ev = $mesh.EV }
    }
    for ($e = 0; $e -lt $edges.Length; $e += 2) {
        if ($null -ne $vis) {
            $ei = [int]($e / 2)
            if ($null -ne $ev -and $ei -lt $ev.Length -and $far -gt [int]$ev[$ei]) { continue }
            $f1 = $adj[$e]; $f2 = $adj[$e + 1]
            $show = $false
            if ($f1 -ge 0 -and $f1 -lt $vis.Length -and $vis[$f1]) { $show = $true }
            elseif ($f2 -ge 0 -and $f2 -lt $vis.Length -and $f2 -ne $f1 -and $vis[$f2]) { $show = $true }
            if (-not $show) { continue }
        }
        $a = $edges[$e]; $b = $edges[$e + 1]
        Draw-ViewLine $script:ViewTmp[$a * 3] $script:ViewTmp[$a * 3 + 1] $script:ViewTmp[$a * 3 + 2] `
            $script:ViewTmp[$b * 3] $script:ViewTmp[$b * 3 + 1] $script:ViewTmp[$b * 3 + 2] $ch $color
    }
}

function Draw-Disc([double]$wx, [double]$wy, [double]$wz, [double]$radius, [char]$ch, [byte]$color) {
    Project-Body $wx $wy $wz
    if (-not $script:BodyOn) { return }
    $rx = ($radius / $script:BodyZ) * $script:DotSX
    $ry = ($radius / $script:BodyZ) * $script:DotSY
    if ($rx -lt 2.2 -and $ry -lt 2.2) {
        Plot-Dot ([int]$script:BodyX) ([int]$script:BodyY) $color
        return
    }
    Draw-Ellipse $script:BodyX $script:BodyY $rx $ry $ch $color
}

function Bar([double]$v, [double]$max, [int]$n) {
    $f = 0
    if ($max -gt 0) { $f = [int]([Math]::Round($n * $v / $max)) }
    if ($f -lt 0) { $f = 0 }
    if ($f -gt $n) { $f = $n }
    return ('#' * $f) + ('-' * ($n - $f))
}

function Format-Km([double]$metres) {
    $k = $metres / 1000.0
    if ($k -ge 100) { return (([Math]::Round($k)).ToString($script:Inv) + 'km') }
    return ($k.ToString('0.0', $script:Inv) + 'km')
}

function Get-Arrow {
    $script:CompassWhat = 'STN'
    $dx = -$script:Px; $dy = -$script:Py; $dz = -$script:Pz
    $station = Speed-Of $dx $dy $dz
    if ($station -gt $script:ScanRange) {
        $script:CompassWhat = 'PLN'
        $dx = $script:PlX - $script:Px; $dy = $script:PlY - $script:Py; $dz = $script:PlZ - $script:Pz
    }
    $dist = Speed-Of $dx $dy $dz
    if ($dist -lt 1) { $dist = 1 }
    World-To-Local $script:M ($dx / $dist) ($dy / $dist) ($dz / $dist)
    $script:CompassMark = '+'
    if ($script:LocZ -lt 0) { $script:CompassMark = 'o' }
    $lx = $script:LocX; $ly = $script:LocY; $lz = $script:LocZ
    $word = 'AHEAD'
    if ($lz -lt -0.15 -and [Math]::Abs($lx) -lt 0.45 -and [Math]::Abs($ly) -lt 0.45) { $word = 'BEHIND' }
    else {
        $nx = 0; $ny = 0
        if ($lx -gt 0.22) { $nx = 1 } elseif ($lx -lt -0.22) { $nx = -1 }
        if ($ly -gt 0.22) { $ny = 1 } elseif ($ly -lt -0.22) { $ny = -1 }
        if ($nx -eq 0 -and $ny -eq 0) { $word = 'AHEAD' }
        elseif ($nx -eq 0 -and $ny -eq 1) { $word = 'UP' }
        elseif ($nx -eq 0 -and $ny -eq -1) { $word = 'DOWN' }
        elseif ($nx -eq 1 -and $ny -eq 0) { $word = 'RIGHT' }
        elseif ($nx -eq -1 -and $ny -eq 0) { $word = 'LEFT' }
        elseif ($nx -eq 1 -and $ny -eq 1) { $word = 'UP-RIGHT' }
        elseif ($nx -eq -1 -and $ny -eq 1) { $word = 'UP-LEFT' }
        elseif ($nx -eq 1 -and $ny -eq -1) { $word = 'DOWN-RIGHT' }
        else { $word = 'DOWN-LEFT' }
    }
    $script:Arrow = $word
    $script:StationDist = $dist
}

function Write-Gauge([int]$x, [int]$y, [string]$name, [string]$bar) {
    Write-At $x $y $name 7 2
    Write-At ($x + 3) $y $bar 9 $bar.Length
}

function Center-Bar([double]$v) {
    $c = New-Object 'char[]' 5
    $c[0] = '-'; $c[1] = '-'; $c[2] = '+'; $c[3] = '-'; $c[4] = '-'
    $steps = [int]([Math]::Round([Math]::Abs($v) * 2.0))
    if ($steps -gt 2) { $steps = 2 }
    if ($steps -gt 0) {
        if ($v -gt 0) {
            for ($i = 1; $i -le $steps; $i++) { $c[2 + $i] = '#' }
        }
        else {
            for ($i = 1; $i -le $steps; $i++) { $c[2 - $i] = '#' }
        }
    }
    return [string]::new($c)
}

function Draw-Blip([double]$wx, [double]$wy, [double]$wz) {
    $range = $script:ScanRange
    if ($range -lt 1) { return }
    World-To-Local $script:M ($wx - $script:Px) ($wy - $script:Py) ($wz - $script:Pz)
    $lx = $script:LocX; $ly = $script:LocY; $lz = $script:LocZ
    if ([Math]::Abs($lx) -gt $range -or [Math]::Abs($ly) -gt $range -or [Math]::Abs($lz) -gt $range) { return }
    $bx = [int]([Math]::Round($script:ScCX + ($lx / $range) * $script:ScRX))
    $by = [int]([Math]::Round($script:ScCY - ($lz / $range) * $script:ScRY))
    $tip = [int]([Math]::Round($by - ($ly / $range) * $script:ScStick))
    if ($tip -lt 1) { $tip = 1 }
    if ($tip -gt ($script:ScDH - 2)) { $tip = $script:ScDH - 2 }
    [EliteBraille.Raster]::Line($script:ScanDots, $script:ScDW, $script:ScDH, $bx, $by, $bx, $tip, 11)
    [EliteBraille.Raster]::Plot($script:ScanDots, $script:ScDW, $script:ScDH, $bx, $tip, 15)
    [EliteBraille.Raster]::Plot($script:ScanDots, $script:ScDW, $script:ScDH, $bx + 1, $tip, 15)
    [EliteBraille.Raster]::Plot($script:ScanDots, $script:ScDW, $script:ScDH, $bx, $tip + 1, 15)
}

function Draw-Scanner([int]$ox, [int]$oy, [int]$cw, [int]$ch) {
    if ($cw -lt 14 -or $ch -lt 4) { return }
    if (-not ('EliteBraille.Raster' -as [type])) { return }
    $dw = $cw * 2
    $dh = $ch * 4
    $need = $dw * $dh
    if ($null -eq $script:ScanDots -or $script:ScanDots.Length -ne $need) {
        $script:ScanDots = New-Object 'byte[]' $need
    }
    else {
        [Array]::Clear($script:ScanDots, 0, $need)
    }
    $script:ScDW = $dw
    $script:ScDH = $dh
    $script:ScCX = [int]($dw / 2)
    $script:ScCY = [int]($dh / 2)
    $script:ScRX = [int]($dw * 0.40)
    $script:ScRY = [int]($script:ScRX * 0.27)
    $maxRy = [int]($dh / 2) - 4
    if ($maxRy -lt 3) { $maxRy = 3 }
    if ($script:ScRY -gt $maxRy) { $script:ScRY = $maxRy }
    if ($script:ScRX -gt ($dw / 2 - 2)) { $script:ScRX = [int]($dw / 2 - 2) }
    if ($script:ScRX -lt 6) { $script:ScRX = 6 }
    $script:ScStick = $script:ScRX * 0.50
    $steps = 64
    $px = 0
    $py = 0
    for ($i = 0; $i -le $steps; $i++) {
        $t = $i * 6.2831853 / $steps
        $x = [int]([Math]::Round($script:ScCX + [Math]::Cos($t) * $script:ScRX))
        $y = [int]([Math]::Round($script:ScCY + [Math]::Sin($t) * $script:ScRY))
        if ($i -gt 0) {
            [EliteBraille.Raster]::Line($script:ScanDots, $dw, $dh, $px, $py, $x, $y, 14)
        }
        $px = $x
        $py = $y
    }
    [EliteBraille.Raster]::Line($script:ScanDots, $dw, $dh, ($script:ScCX - $script:ScRX), $script:ScCY, ($script:ScCX + $script:ScRX), $script:ScCY, 6)
    [EliteBraille.Raster]::Line($script:ScanDots, $dw, $dh, $script:ScCX, ($script:ScCY - $script:ScRY), $script:ScCX, ($script:ScCY + $script:ScRY), 6)
    if (-not $script:Witch) { Draw-Blip 0 0 0 }
    foreach ($s in $script:Ships) {
        if ($s.Hull -le 0) { continue }
        Draw-Blip $s.X $s.Y $s.Z
    }
    if ($null -ne $script:Bolts) {
        foreach ($b in $script:Bolts) { Draw-Blip $b.X $b.Y $b.Z }
    }
    $n = $cw * $ch
    if ($null -eq $script:ScanBuf -or $script:ScanBuf.Length -ne $n) {
        $script:ScanBuf = New-Object 'char[]' $n
        $script:ScanCol = New-Object 'byte[]' $n
    }
    for ($i = 0; $i -lt $n; $i++) { $script:ScanBuf[$i] = ' ' }
    [Array]::Clear($script:ScanCol, 0, $n)
    [EliteBraille.Raster]::Stamp($script:ScanDots, $dw, $script:ScanBuf, $script:ScanCol, $cw, 0, $ch, $script:Pri)
    for ($y = 0; $y -lt $ch; $y++) {
        $src = $y * $cw
        $dst = ($oy + $y) * $script:W + $ox
        for ($x = 0; $x -lt $cw; $x++) {
            $cell = $script:ScanBuf[$src + $x]
            if ($cell -ne ' ') {
                $script:Buf[$dst + $x] = $cell
                $script:Col[$dst + $x] = $script:ScanCol[$src + $x]
            }
        }
    }
}

function Draw-Dashboard {
    $hy = $script:HudY
    $hh = $script:HudH
    $rule = '+' + ('-' * ($script:W - 2)) + '+'
    Write-At 0 $hy $rule 6 $script:W
    if ($hh -ge 2) { Write-At 0 ($hy + $hh - 1) $rule 6 $script:W }
    $top = $hy + 1
    $body = $hh - 2
    if ($body -lt 1) { return }

    $clx = 0.0
    $cly = 0.0
    $clz = 1.0
    $cwhat = 'PLN'
    if (-not $script:Witch) {
        Get-Arrow
        $clx = $script:LocX
        $cly = $script:LocY
        $clz = $script:LocZ
        $cwhat = $script:CompassWhat
    }
    $sp = Speed-Of $script:Vx $script:Vy $script:Vz
    $cond = 'GREEN'
    $condCol = [byte]10
    $nearHost = $false
    foreach ($s in $script:Ships) {
        if ($s.Role -eq 'trader') { continue }
        if ((Speed-Of ($s.X - $script:Px) ($s.Y - $script:Py) ($s.Z - $script:Pz)) -lt 8000) { $nearHost = $true }
    }
    if ($nearHost) { $cond = 'YELLOW'; $condCol = [byte]11 }
    if ($script:HitFlash -gt 0 -or $script:Witch) { $cond = 'RED'; $condCol = [byte]9 }
    if (-not $script:Witch -and (Speed-Of $script:Px $script:Py $script:Pz) -lt 1700) { $cond = 'GREEN'; $condCol = [byte]10 }
    $critical = ($script:Hull -lt 28 -or $script:Energy -lt 20)
    if ($critical) { $cond = 'RED'; $condCol = [byte]9 }
    $alt = 0.0
    if (-not $script:Witch) {
        $pd = Speed-Of ($script:Px - $script:PlX) ($script:Py - $script:PlY) ($script:Pz - $script:PlZ)
        $height = $pd - $script:PlR
        if ($height -lt 0) { $height = 0 }
        if ($height -lt 9000) { $alt = (1.0 - ($height / 9000.0)) * 100.0 }
    }
    $rightW = 20
    $rightX = $script:W - $rightW - 2
    $full = ($body -ge 9 -and $rightX -ge 36)
    if ($full) {
        for ($i = 0; $i -lt $body; $i++) {
            Write-At 0 ($top + $i) '|' 6 1
            Write-At ($script:W - 1) ($top + $i) '|' 6 1
        }
        Write-Gauge 2 ($top + 0) 'FS' (Bar $script:ShieldF $script:ShieldMax 8)
        Write-Gauge 2 ($top + 1) 'AS' (Bar $script:ShieldA $script:ShieldMax 8)
        Write-Gauge 2 ($top + 2) 'FU' (Bar $script:Fuel 7 8)
        Write-Gauge 2 ($top + 3) 'CT' (Bar $script:Temp 100 8)
        Write-Gauge 2 ($top + 4) 'LT' (Bar $script:Heat 100 8)
        Write-Gauge 2 ($top + 5) 'AL' (Bar $alt 100 8)
        Write-At 2 ($top + 6) 'MS' 7 2
        $mcol = [byte]11
        if ($script:MissileArm -eq 1) { $mcol = [byte]10 }
        elseif ($script:MissileArm -eq 2) { $mcol = [byte]9 }
        for ($i = 0; $i -lt 4; $i++) {
            if ($i -lt $script:Missiles) { Write-At (5 + $i * 2) ($top + 6) '#' $mcol 1 }
            else { Write-At (5 + $i * 2) ($top + 6) '.' 8 1 }
        }
        $mode = $script:ViewName[$script:View]
        $modeCol = [byte]6
        if ($script:JumpT -gt 0) {
            $mode = 'J ' + [string]([int][Math]::Ceiling($script:JumpT))
            $modeCol = [byte]11
        }
        elseif ($script:InTorus) { $mode = 'TORUS'; $modeCol = [byte]11 }
        elseif ($script:CloakOn) { $mode = 'CLOAK'; $modeCol = [byte]13 }
        elseif ($script:AutoDock) { $mode = 'AUTO'; $modeCol = [byte]14 }
        Write-At 2 ($top + 7) $mode $modeCol 8

        $art = @(
            ' .---. ',
            '/     \',
            '|     |',
            '\     /',
            " '---' "
        )
        for ($i = 0; $i -lt 5; $i++) { Write-At $rightX ($top + $i) $art[$i] 7 7 }
        if (-not $script:Witch) {
            $px = 3 + [int]([Math]::Round($clx * 2.0))
            $py = 2 - [int]([Math]::Round($cly * 1.0))
            if ($px -lt 1) { $px = 1 }
            if ($px -gt 5) { $px = 5 }
            if ($py -lt 1) { $py = 1 }
            if ($py -gt 3) { $py = 3 }
            $mark = '*'
            $markCol = [byte]15
            if ($clz -lt 0) { $mark = 'o'; $markCol = [byte]8 }
            Write-At ($rightX + $px) ($top + $py) $mark $markCol 1
        }
        if ($cwhat -eq 'STN' -and -not $script:Witch) { Write-At ($rightX + 8) ($top + 2) 'S' 11 1 }
        else { Write-At ($rightX + 8) ($top + 2) '.' 8 1 }
        if ($script:EcmT -gt 0) { Write-At ($rightX + 8) ($top + 3) 'E' 11 1 }
        else { Write-At ($rightX + 8) ($top + 3) '.' 8 1 }
        $lamp = $true
        if ($critical -and (($script:Tick % 8) -lt 4)) { $lamp = $false }
        if ($lamp) { Write-At ($rightX + 8) $top $cond $condCol 6 }
        Write-Gauge $rightX ($top + 5) 'SP' (Bar $sp 320 8)
        Write-At $rightX ($top + 6) 'RL' 7 2
        Write-At ($rightX + 3) ($top + 6) (Center-Bar ($script:DialRoll / 2.4)) 9 5
        Write-At $rightX ($top + 7) 'DC' 7 2
        Write-At ($rightX + 3) ($top + 7) (Center-Bar ($script:DialPitch / 2.4)) 9 5
        $bx = $rightX
        for ($i = 0; $i -lt 4; $i++) {
            $bank = $script:Energy - (25.0 * $i)
            if ($bank -lt 0) { $bank = 0 }
            if ($bank -gt 25) { $bank = 25 }
            Write-At $bx ($top + 8) ([string]($i + 1)) 7 1
            Write-At ($bx + 1) ($top + 8) (Bar $bank 25 3) 9 3
            $bx += 5
        }
        $scanL = 16
        $scanR = $rightX - 2
        $gap = $scanR - $scanL + 1
        $cw = $gap
        if ($cw -gt 46) { $cw = 46 }
        $ox = $scanL + [int](($gap - $cw) / 2)
        Draw-Scanner $ox $top $cw $body
    }
    else {
        Write-Gauge 1 $top 'FS' (Bar $script:ShieldF $script:ShieldMax 6)
        Write-Gauge 12 $top 'AS' (Bar $script:ShieldA $script:ShieldMax 6)
        if ($body -ge 2) {
            Write-Gauge 1 ($top + 1) 'FU' (Bar $script:Fuel 7 6)
            Write-Gauge 12 ($top + 1) 'SP' (Bar $sp 640 6)
        }
        if ($body -ge 3) {
            Write-Gauge 1 ($top + 2) 'CT' (Bar $script:Temp 100 4)
            Write-Gauge 10 ($top + 2) 'LT' (Bar $script:Heat 100 4)
            Write-Gauge 19 ($top + 2) 'AL' (Bar $alt 100 4)
            if (-not $critical -or (($script:Tick % 8) -ge 4)) { Write-At 28 ($top + 2) $cond $condCol 6 }
        }
        if ($body -ge 5) { Draw-Scanner 2 ($top + 3) ($script:W - 4) ($body - 3) }
    }
}

function Draw-Flight {
    Sync-Camera
    if (-not $script:Witch) {
        for ($i = 0; $i -lt $script:StarN; $i++) {
            Project-Body $script:Stars[$i * 3] $script:Stars[$i * 3 + 1] $script:Stars[$i * 3 + 2]
            if ($script:BodyOn) {
                $col = [byte]8
                if ($script:BodyZ -lt 8000) { $col = [byte]7 }
                Plot-Dot ([int]$script:BodyX) ([int]$script:BodyY) $col
                if ($script:BodyZ -lt 4000) { Plot-Dot ([int]$script:BodyX + 1) ([int]$script:BodyY) $col }
            }
        }
        Draw-Disc $script:SuX $script:SuY $script:SuZ $script:SuR 'o' 11
        Draw-Disc $script:PlX $script:PlY $script:PlZ $script:PlR 'o' 2
        Station-Entrance
        if ($null -eq $script:StM) { $script:StM = New-Object 'double[]' 9 }
        $ch = [Math]::Cos($script:StAngle); $sh = [Math]::Sin($script:StAngle)
        $cp = [Math]::Cos($script:StSpin); $spn = [Math]::Sin($script:StSpin)
        $script:StM[0] = $cp * $ch;  $script:StM[1] = $spn;       $script:StM[2] = -$cp * $sh
        $script:StM[3] = -$spn * $ch; $script:StM[4] = $cp;        $script:StM[5] = $spn * $sh
        $script:StM[6] = $sh;         $script:StM[7] = 0;          $script:StM[8] = $ch
        Draw-Mesh $script:MeshStation 0 0 0 $script:StM 1 '#' 3
        Draw-Mesh $script:MeshPort 0 0 0 $script:StM 1 '#' 14
    }
    else {
        for ($i = 0; $i -lt $script:StarN; $i++) {
            Project-Body $script:Stars[$i * 3] $script:Stars[$i * 3 + 1] $script:Stars[$i * 3 + 2]
            if ($script:BodyOn) { Plot-Dot ([int]$script:BodyX) ([int]$script:BodyY) 5 }
        }
    }
    foreach ($s in $script:Ships) {
        if ($s.Hull -le 0) { continue }
        if ($s.Blink -and (($script:Tick % 10) -lt 4)) { continue }
        Draw-Mesh (Mesh-Of $s) $s.X $s.Y $s.Z $s.M $s.Scale '#' $s.Color
    }
    foreach ($d in $script:Debris) {
        Project-Body $d.X $d.Y $d.Z
        if ($script:BodyOn) { Plot-Dot ([int]$script:BodyX) ([int]$script:BodyY) $d.Color }
    }
    foreach ($b in $script:Bolts) {
        if ($null -eq $script:BoltM) { $script:BoltM = New-Object 'double[]' 9 }
        Set-Facing $script:BoltM $b.VX $b.VY $b.VZ
        $ms = 0.5
        if ($b.Heavy) { $ms = 0.75 }
        Draw-Mesh $script:MeshMissile $b.X $b.Y $b.Z $script:BoltM $ms '#' 11
    }
    if ($script:LaserT -gt 0) {
        $dx = $script:Lx - $script:Px; $dy = $script:Ly - $script:Py; $dz = $script:Lz - $script:Pz
        Cam-Local $dx $dy $dz
        Draw-ViewLine 0 0 0.9 $script:LocX $script:LocY $script:LocZ '|' 14
    }
    $border = [byte]6
    if ($script:HitFlash -gt 0) { $border = [byte]9 }
    Draw-Reticle $border
    Stamp-Braille
    $y0 = $script:ViewY
    $y1 = $script:ViewY + $script:ViewH - 1
    $x1 = $script:W - 1
    Write-At 0 $y0 '+--' $border 3
    Write-At ($x1 - 2) $y0 '--+' $border 3
    Write-At 0 $y1 '+--' $border 3
    Write-At ($x1 - 2) $y1 '--+' $border 3

    $sys = $script:Systems[$script:Sys]
    $title = "$($sys.Name)   $($script:EcoName[$sys.Eco]) / $($script:GovName[$sys.Gov])   CMDR $($script:Name)   $(Get-RankName $script:Kills)"
    if ($script:Witch) { $title = "WITCH-SPACE   CMDR $($script:Name)   $(Get-RankName $script:Kills)" }
    Write-At 1 0 $title 14 $script:W

    Draw-Dashboard
    if ($script:MsgT -gt 0 -and $script:Msg.Length -gt 0) {
        Write-At 2 ($script:ViewY + $script:ViewH - 2) $script:Msg 11 ($script:W - 4)
    }
}

function Present-Frame {
    if (-not $script:ConsoleOn) { return }
    if ($script:UseAnsi) { Present-Ansi } else { Present-Legacy }
}

function Present-Ansi {
    $sb = $script:Sb
    $sb.Length = 0
    [void]$sb.Append("$([char]27)[H")
    $w = $script:W
    $h = $script:H
    $last = -1
    for ($y = 0; $y -lt $h; $y++) {
        [void]$sb.Append("$([char]27)[$($y + 1);1H")
        $row = $y * $w
        for ($x = 0; $x -lt $w; $x++) {
            $c = $script:Col[$row + $x]
            if ($c -ne $last) {
                [void]$sb.Append($script:Ansi[$c])
                $last = $c
            }
            [void]$sb.Append($script:Buf[$row + $x])
        }
    }
    if ($script:QuietPresent) { return }
    [Console]::Write($sb.ToString())
}

function Present-Legacy {
    for ($y = 0; $y -lt $script:H; $y++) {
        [Console]::SetCursorPosition(0, $y)
        $row = $y * $script:W
        $x = 0
        while ($x -lt $script:W) {
            $c = $script:Col[$row + $x]
            $x2 = $x + 1
            while ($x2 -lt $script:W -and $script:Col[$row + $x2] -eq $c) { $x2++ }
            [Console]::ForegroundColor = $script:Pal[$c]
            $len = $x2 - $x
            $chars = New-Object 'char[]' $len
            [Array]::Copy($script:Buf, $row + $x, $chars, 0, $len)
            [Console]::Write($chars)
            $x = $x2
        }
    }
}

function Open-Console {
    try { $script:OldTitle = $Host.UI.RawUI.WindowTitle } catch { $script:OldTitle = '' }
    try { $Host.UI.RawUI.WindowTitle = 'ELITE' } catch { }
    $script:UseAnsi = $false
    if (-not ('EliteConsole.Native' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace EliteConsole {
  public static class Native {
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr GetStdHandle(int nStdHandle);
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
  }
}
'@
    }
    $script:AsyncKeys = $true
    try {
        $handle = [EliteConsole.Native]::GetStdHandle(-11)
        $mode = [uint32]0
        $ok = [EliteConsole.Native]::GetConsoleMode($handle, [ref]$mode)
        if ($ok) {
            $enabled = [EliteConsole.Native]::SetConsoleMode($handle, ($mode -bor 4))
            if ($enabled) { $script:UseAnsi = $true }
        }
    }
    catch { $script:UseAnsi = $false }
    try {
        [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
        [Console]::BackgroundColor = [ConsoleColor]::Black
        [Console]::ForegroundColor = [ConsoleColor]::Gray
        [Console]::CursorVisible = $false
        [Console]::Clear()
    }
    catch { }
    $script:ConsoleOn = $true
    Sync-Console
}

function Close-Console {
    if (-not $script:ConsoleOn) { return }
    try { [Console]::CursorVisible = $true } catch { }
    try { [Console]::ResetColor() } catch { }
    try { [Console]::Write("$([char]27)[0m") } catch { }
    try { [Console]::Clear() } catch { }
    if ($script:OldTitle) {
        try { $Host.UI.RawUI.WindowTitle = $script:OldTitle } catch { }
    }
    $script:ConsoleOn = $false
}

function Test-Key([int]$vk) {
    if (-not $script:AsyncKeys) { return $false }
    return (([EliteConsole.Native]::GetAsyncKeyState($vk) -band 0x8000) -ne 0)
}

function Test-Edge([int]$vk) {
    $down = Test-Key $vk
    $prev = $false
    if ($script:KeyPrev.ContainsKey($vk)) { $prev = [bool]$script:KeyPrev[$vk] }
    $script:KeyPrev[$vk] = $down
    return ($down -and -not $prev)
}

function Acknowledge-Keys {
    foreach ($vk in @(37, 38, 39, 40, 65, 90, 88, 32, 77, 68, 74, 67, 71, 27, 84, 72)) {
        $script:KeyPrev[$vk] = Test-Key $vk
    }
}

function Read-FlightInput {
    $script:InPitch = 0.0
    $script:InRoll = 0.0
    $script:InThrust = 0.0
    $script:InBrake = $false
    $script:InFire = $false
    $script:EdgeDock = $false
    $script:EdgeJump = $false
    $script:EdgeChart = $false
    $script:EdgeGal = $false
    $script:EdgeTarget = $false
    $script:EdgePause = $false
    $script:EdgeMissile = $false
    $script:EdgeEcm = $false
    $script:EdgeBomb = $false
    $script:EdgeEscape = $false
    $script:EdgeUnarm = $false
    $script:EdgeHeavy = $false
    $script:EdgeCloak = $false
    $script:EdgeView = -1
    $script:InTorus = $false
    if (-not $script:AsyncKeys) {
        while ([Console]::KeyAvailable) {
            $k = [Console]::ReadKey($true)
            if ($k.Key -eq 'UpArrow') { $script:InPitch = 1 }
            elseif ($k.Key -eq 'DownArrow') { $script:InPitch = -1 }
            elseif ($k.Key -eq 'RightArrow') { $script:InRoll = 1 }
            elseif ($k.Key -eq 'LeftArrow') { $script:InRoll = -1 }
            elseif ($k.Key -eq 'A') { $script:InThrust = 1 }
            elseif ($k.Key -eq 'X') { $script:InThrust = -1 }
            elseif ($k.Key -eq 'Z') { $script:InBrake = $true }
            elseif ($k.Key -eq 'Spacebar') { $script:InFire = $true }
            elseif ($k.Key -eq 'D') { $script:EdgeDock = $true }
            elseif ($k.Key -eq 'J') { $script:EdgeJump = $true }
            elseif ($k.Key -eq 'C') { $script:EdgeChart = $true }
            elseif ($k.Key -eq 'G') { $script:EdgeGal = $true }
            elseif ($k.Key -eq 'T') { $script:EdgeTarget = $true }
            elseif ($k.Key -eq 'M' -or $k.Key -eq 'F') { $script:EdgeMissile = $true }
            elseif ($k.Key -eq 'E') { $script:EdgeEcm = $true }
            elseif ($k.Key -eq 'W') { $script:EdgeBomb = $true }
            elseif ($k.Key -eq 'Q') { $script:EdgeEscape = $true }
            elseif ($k.Key -eq 'U') { $script:EdgeUnarm = $true }
            elseif ($k.Key -eq 'B') { $script:EdgeHeavy = $true }
            elseif ($k.Key -eq 'V') { $script:EdgeCloak = $true }
            elseif ($k.Key -eq 'Y') { $script:InTorus = $true }
            elseif ($k.Key -eq 'H') { $script:EdgeJump = $true }
            elseif ($k.Key -eq 'D1' -or $k.Key -eq 'NumPad1') { $script:EdgeView = 0 }
            elseif ($k.Key -eq 'D2' -or $k.Key -eq 'NumPad2') { $script:EdgeView = 1 }
            elseif ($k.Key -eq 'D3' -or $k.Key -eq 'NumPad3') { $script:EdgeView = 2 }
            elseif ($k.Key -eq 'D4' -or $k.Key -eq 'NumPad4') { $script:EdgeView = 3 }
            elseif ($k.Key -eq 'Escape') { $script:EdgePause = $true }
        }
        return
    }
    if (Test-Key 38) { $script:InPitch = 1 }
    if (Test-Key 40) { $script:InPitch = -1 }
    if (Test-Key 39) { $script:InRoll = 1 }
    if (Test-Key 37) { $script:InRoll = -1 }
    if (Test-Key 65) { $script:InThrust = 1 }
    if (Test-Key 88) { $script:InThrust = -1 }
    if (Test-Key 90) { $script:InBrake = $true }
    $script:InFire = Test-Key 32
    $script:EdgeDock = Test-Edge 68
    $script:EdgeJump = Test-Edge 74
    $script:EdgeChart = Test-Edge 67
    $script:EdgeGal = Test-Edge 71
    $script:EdgeTarget = Test-Edge 84
    $script:EdgeMissile = (Test-Edge 77) -or (Test-Edge 70)
    $script:EdgeEcm = Test-Edge 69
    $script:EdgeBomb = Test-Edge 87
    $script:EdgeEscape = Test-Edge 81
    $script:EdgeUnarm = Test-Edge 85
    $script:EdgeHeavy = Test-Edge 66
    $script:EdgeCloak = Test-Edge 86
    $script:InTorus = Test-Key 89
    if (Test-Edge 72) { $script:EdgeJump = $true }
    if (Test-Edge 49) { $script:EdgeView = 0 }
    if (Test-Edge 50) { $script:EdgeView = 1 }
    if (Test-Edge 51) { $script:EdgeView = 2 }
    if (Test-Edge 52) { $script:EdgeView = 3 }
    $script:EdgePause = Test-Edge 27
}

function Dump-Frame([string]$path) {
    $sb = New-Object System.Text.StringBuilder
    for ($y = 0; $y -lt $script:H; $y++) {
        $row = $y * $script:W
        $line = New-Object 'char[]' $script:W
        [Array]::Copy($script:Buf, $row, $line, 0, $script:W)
        [void]$sb.Append([string]::new($line))
        [void]$sb.Append("`n")
    }
    Set-Content -Path $path -Value $sb.ToString() -Encoding ASCII
}

function Paint-Title {
    Clear-Frame
    Write-Mid 2 'E L I T E' 14
    Write-Mid 3 'space trade and combat' 6
    Write-Mid 5 'Unofficial console remake of the 1984 game.' 8
    Write-Mid 6 'A Cobra Mk III, a procedural galaxy, a station to dock.' 7
    $y = 9
    if (Test-Path $script:SavePath) {
        Write-Mid $y 'N  new commander' 15
        Write-Mid ($y + 1) 'L  load commander' 15
        Write-Mid ($y + 2) 'H  how to fly' 15
        Write-Mid ($y + 3) 'Q  quit' 15
    }
    else {
        Write-Mid $y 'N  new commander' 15
        Write-Mid ($y + 1) 'H  how to fly' 15
        Write-Mid ($y + 2) 'Q  quit' 15
    }
    Write-Mid ($script:H - 3) 'The view follows the window. 80x30 is comfortable.' 8
}

function Read-Name {
    $name = ''
    while ($true) {
        Sync-Console
        Paint-Title
        Write-Mid 16 'Commander name:' 11
        Write-Mid 17 $name 15
        Present-Frame
        $k = [Console]::ReadKey($true)
        if ($k.Key -eq 'Enter') { break }
        if ($k.Key -eq 'Escape') { return '' }
        if ($k.Key -eq 'Backspace') {
            if ($name.Length -gt 0) { $name = $name.Substring(0, $name.Length - 1) }
            continue
        }
        $ch = $k.KeyChar
        if ($ch -match '[A-Za-z0-9 \-]' -and $name.Length -lt 16) { $name += $ch }
    }
    if ($name.Trim().Length -eq 0) { return 'Jameson' }
    return $name.Trim()
}

function Show-Help([string]$back) {
    $lines = @(
        'You command a Cobra Mk III. Trade, fight, reach the rank of ELITE.',
        '',
        'DOCKED    arrows + Enter, or a number key.',
        'Buy Food on a farm world. Sell it on a factory world.',
        'The market screen names the best hop inside your fuel.',
        '',
        'FLIGHT',
        '  Left/Right roll   Up/Down pitch   A thrust  Z brake  X retro',
        '  1 front  2 rear  3 left  4 right. Space fires only that view.',
        '  T lock missile   F or M launch   U unarm   E ECM   W energy bomb',
        '  Y torus drive, mass-locked by ships, planet or sun',
        '  D dock   J or H hyperspace (3 second count, J again aborts)',
        '  C local chart   G galactic chart   Q escape pod   V cloak   B heavy',
        '',
        'DOCKING',
        '  The cyan slot faces the planet. Creep in under 62, aligned,',
        '  and roll until the wings are level. A scrape costs shields.',
        '',
        'You start at Lave: 100 CR, 7 LY, front pulse, three missiles.',
        'Contraband: Slaves, Narcotics, Firearms.',
        'Fuel scoop the sun. Mining laser plus scoops breaks asteroids.',
        'Galactic hyperdrive is one jump. ECM kills every missile.',
        'Press any key.'
    )
    while ($true) {
        Sync-Console
        Clear-Frame
        Write-Mid 1 'HOW TO FLY' 14
        $y = 3
        foreach ($line in $lines) {
            if ($y -ge $script:H - 1) { break }
            Write-At 2 $y $line 7 ($script:W - 4)
            $y++
        }
        Present-Frame
        [void][Console]::ReadKey($true)
        return $back
    }
}

function Show-Title {
    while ($true) {
        Sync-Console
        Paint-Title
        Present-Frame
        $k = [Console]::ReadKey($true)
        $ch = [string]$k.KeyChar
        if ($ch -eq 'n' -or $ch -eq 'N') {
            $name = Read-Name
            if ($name.Length -eq 0) { continue }
            $seed = Get-Random -Minimum 1 -Maximum 60000
            Reset-Commander $name $seed
            Save-Commander
            return 'docked'
        }
        if (($ch -eq 'l' -or $ch -eq 'L') -and (Test-Path $script:SavePath)) {
            if (Load-Commander) { return 'docked' }
            Say 'Save could not be read.'
        }
        if ($ch -eq 'h' -or $ch -eq 'H') { Show-Help 'title' | Out-Null }
        if ($ch -eq 'q' -or $ch -eq 'Q' -or $k.Key -eq 'Escape') { return 'quit' }
    }
}

function Target-Name {
    if ($script:JumpTarget -lt 0 -or $script:JumpTarget -gt 255) { return 'none' }
    $nm = $script:Systems[$script:JumpTarget].Name
    $ly = Get-Ly $script:Sys $script:JumpTarget
    return "$nm ($(F1 $ly) LY)"
}

function Legal-Word {
    if ($script:Legal -gt 15) { return 'Fugitive' }
    if ($script:Legal -gt 0) { return 'Offender' }
    return 'Clean'
}

function Paint-Docked([int]$sel) {
    Clear-Frame
    $sys = $script:Systems[$script:Sys]
    Write-At 1 0 'ELITE' 14 8
    Write-At ($script:W - 18) 0 "CR $($script:Cash)" 11 16
    Write-At 1 2 "Commander $($script:Name)    $(Get-RankName $script:Kills)    Kills $($script:Kills)" 15 ($script:W - 2)
    Write-At 1 3 "Cobra Mk III   Hull $(F0 $script:Hull)/100   Fuel $(F1 $script:Fuel) LY   Cargo $($script:CargoUsed)/$($script:CargoMax)t   Missiles $($script:Missiles)" 6 ($script:W - 2)
    Write-At 1 4 "$($sys.Name)   $($script:EcoName[$sys.Eco]) / $($script:GovName[$sys.Gov])   TL $($sys.Tech)   Galaxy $($script:GalNum)" 7 ($script:W - 2)
    Write-At 1 5 "Legal: $(Legal-Word)    Destination: $(Target-Name)" 7 ($script:W - 2)
    $hint = Get-BestRun
    Write-At 1 6 $hint 10 ($script:W - 2)
    $items = @(
        'Launch', 'Market', 'Equipment', 'Local chart', 'Galactic chart',
        'System data', 'Refuel', 'Repair hull', 'How to fly', 'Save and retire'
    )
    for ($i = 0; $i -lt $items.Count; $i++) {
        $prefix = '   '
        $col = [byte]7
        if ($i -eq $sel) { $prefix = ' > '; $col = [byte]14 }
        $label = "$prefix$($i + 1). $($items[$i])"
        if ($i -eq 6) {
            $cost = [int][Math]::Ceiling((7.0 - $script:Fuel) * 2)
            if ($cost -lt 0) { $cost = 0 }
            $label = "$prefix$($i + 1). Refuel ($cost CR)"
        }
        if ($i -eq 7) {
            $cost = [int](2 * [Math]::Ceiling($script:HullMax - $script:Hull))
            $label = "$prefix$($i + 1). Repair hull ($cost CR)"
        }
        Write-At 2 (8 + $i) $label $col ($script:W - 4)
    }
    if ($script:MsgT -gt 0) { Write-At 1 ($script:H - 2) $script:Msg 11 ($script:W - 2) }
}

function Buy-Fuel {
    $need = 7.0 - $script:Fuel
    if ($need -lt 0.05) { Say 'Fuel tanks are full.'; return }
    $cost = [int][Math]::Ceiling($need * 2)
    if ($script:Cash -lt $cost) { Say "Refuel costs $cost CR."; return }
    $script:Cash -= $cost
    $script:Fuel = 7.0
    Say "Tanks full. Paid $cost CR."
}

function Buy-Repair {
    $missing = $script:HullMax - $script:Hull
    if ($missing -lt 0.5) { Say 'Hull is intact.'; return }
    $cost = [int](2 * [Math]::Ceiling($missing))
    if ($script:Cash -lt $cost) {
        $points = [int]([Math]::Floor($script:Cash / 2.0))
        if ($points -le 0) { Say "Repair costs $cost CR."; return }
        $script:Hull += $points
        $script:Cash -= $points * 2
        Say "Partial repair. Hull $(F0 $script:Hull)."
        return
    }
    $script:Cash -= $cost
    $script:Hull = $script:HullMax
    Say "Hull repaired for $cost CR."
}

function Show-Docked {
    $sel = 0
    $items = 10
    while ($true) {
        Sync-Console
        Paint-Docked $sel
        Present-Frame
        $k = [Console]::ReadKey($true)
        if ($k.Key -eq 'UpArrow') { $sel--; if ($sel -lt 0) { $sel = $items - 1 } }
        elseif ($k.Key -eq 'DownArrow') { $sel++; if ($sel -ge $items) { $sel = 0 } }
        elseif ($k.Key -eq 'Escape') { $script:MsgT = 0 }
        elseif ($k.KeyChar -match '[1-9]') { $sel = [int][string]$k.KeyChar - 1 }
        elseif ($k.KeyChar -eq '0') { $sel = 9 }
        $activate = $k.Key -eq 'Enter' -or $k.Key -eq 'Spacebar' -or $k.KeyChar -match '[0-9]'
        if (-not $activate) { continue }
        switch ($sel) {
            0 { Launch-Ship; return 'flight' }
            1 { Show-Market }
            2 { Show-Equip }
            3 { Show-Chart $false $false | Out-Null }
            4 {
                $chart = Show-Chart $true $false
                if ($chart -eq 'galactic') { Say 'Launch first. Press H on the galactic chart in flight.' }
            }
            5 { Show-Info | Out-Null }
            6 { Buy-Fuel }
            7 { Buy-Repair }
            8 { Show-Help 'docked' | Out-Null }
            9 { Save-Commander; return 'title' }
        }
    }
}

function Launch-Ship {
    Enter-Space 'launch'
}

function Paint-Market([int]$sel) {
    Clear-Frame
    Refresh-Market
    $sys = $script:Systems[$script:Sys]
    Write-At 1 0 "MARKET  $($sys.Name)" 14 40
    Write-At ($script:W - 22) 0 "CR $($script:Cash)" 11 20
    Write-At 1 1 "Cargo $($script:CargoUsed)/$($script:CargoMax)t    $(Get-BestRun)" 10 ($script:W - 2)
    Write-At 1 3 '    Commodity        Price   Stock   Hold' 8 ($script:W - 2)
    $y = 4
    for ($i = 0; $i -lt $script:Market.Count; $i++) {
        if ($y -ge $script:H - 3) { break }
        $row = $script:Market[$i]
        $mark = ' '
        $col = [byte]7
        if ($i -eq $sel) { $mark = '>'; $col = [byte]14 }
        if ($row.Illegal) { $col = [byte]9 }
        $line = "{0} {1,-16} {2,6} {3,7} {4,6}" -f $mark, $row.Name, $row.Price, $row.Stock, (Get-Hold $row.Name)
        Write-At 1 $y $line $col ($script:W - 2)
        $y++
    }
    Write-At 1 ($script:H - 2) 'Up/Down move   Right buy 1   Left sell 1   B max   V all   Esc back' 8 ($script:W - 2)
    if ($script:MsgT -gt 0) { Write-At 1 ($script:H - 3) $script:Msg 11 ($script:W - 2) }
}

function Show-Market {
    Refresh-Market
    $sel = 0
    while ($true) {
        Sync-Console
        Paint-Market $sel
        Present-Frame
        $k = [Console]::ReadKey($true)
        if ($k.Key -eq 'UpArrow') { $sel--; if ($sel -lt 0) { $sel = $script:Market.Count - 1 } }
        elseif ($k.Key -eq 'DownArrow') { $sel++; if ($sel -ge $script:Market.Count) { $sel = 0 } }
        elseif ($k.Key -eq 'RightArrow') { Trade-Good $sel 1 1 }
        elseif ($k.Key -eq 'LeftArrow') { Trade-Good $sel -1 1 }
        elseif ($k.KeyChar -eq 'b' -or $k.KeyChar -eq 'B') { Trade-Good $sel 1 99 }
        elseif ($k.KeyChar -eq 'v' -or $k.KeyChar -eq 'V') { Trade-Good $sel -1 99 }
        elseif ($k.Key -eq 'Escape') { $script:MsgT = 0; return }
    }
}

function Equip-Rows {
    $mount = $script:ViewName[$script:FitMount]
    $fitted = [string]$script:Laser[$script:FitMount]
    $rows = New-Object System.Collections.Generic.List[object]
    $rows.Add(@{ Id = 'mount'; Name = "Mount $mount"; Price = 0; Tech = 0; Have = $false; Note = $fitted })
    $rows.Add(@{ Id = 'pulse'; Name = 'Pulse laser'; Price = 400; Tech = 3; Have = ($fitted -eq 'pulse'); Note = 'tech 3' })
    $rows.Add(@{ Id = 'beam'; Name = 'Beam laser'; Price = 1000; Tech = 4; Have = ($fitted -eq 'beam'); Note = 'tech 4' })
    $rows.Add(@{ Id = 'military'; Name = 'Military laser'; Price = 6000; Tech = 10; Have = ($fitted -eq 'military'); Note = 'tech 10' })
    $rows.Add(@{ Id = 'mining'; Name = 'Mining laser'; Price = 800; Tech = 10; Have = ($fitted -eq 'mining'); Note = 'tech 10' })
    $rows.Add(@{ Id = 'ecm'; Name = 'ECM system'; Price = 600; Tech = 2; Have = $script:ECM; Note = 'tech 2' })
    $rows.Add(@{ Id = 'scoop'; Name = 'Fuel scoops'; Price = 525; Tech = 5; Have = $script:Scoops; Note = 'tech 5' })
    $rows.Add(@{ Id = 'pod'; Name = 'Escape pod'; Price = 1000; Tech = 6; Have = $script:EscapePod; Note = 'tech 6' })
    $rows.Add(@{ Id = 'bomb'; Name = 'Energy bomb'; Price = 900; Tech = 7; Have = ($script:Bomb -gt 0); Note = 'tech 7' })
    $rows.Add(@{ Id = 'energy'; Name = 'Extra energy unit'; Price = 1500; Tech = 8; Have = $script:EnergyUnit; Note = 'tech 8' })
    $rows.Add(@{ Id = 'dock'; Name = 'Docking computer'; Price = 1500; Tech = 9; Have = $script:DockComp; Note = 'tech 9' })
    $rows.Add(@{ Id = 'gal'; Name = 'Galactic hyperdrive'; Price = 5000; Tech = 10; Have = $false; Note = "charges $($script:GalCharges)" })
    $rows.Add(@{ Id = 'cargo'; Name = 'Large cargo bay'; Price = 400; Tech = 0; Have = ($script:CargoMax -ge 35); Note = "$($script:CargoMax)t" })
    $rows.Add(@{ Id = 'missile'; Name = 'Missile'; Price = 30; Tech = 0; Have = ($script:Missiles -ge 4); Note = "$($script:Missiles)/4" })
    return $rows
}

function Show-Equip {
    $sel = 0
    while ($true) {
        Sync-Console
        $rows = Equip-Rows
        if ($sel -ge $rows.Count) { $sel = 0 }
        Clear-Frame
        Write-At 1 0 'EQUIPMENT' 14 20
        Write-At ($script:W - 18) 0 "CR $($script:Cash)" 11 16
        $techHere = $script:Systems[$script:Sys].Tech
        Write-At 1 2 "Station tech $techHere. Lasers fit the mount on the first line. Enter cycles it." 8 ($script:W - 2)
        for ($i = 0; $i -lt $rows.Count; $i++) {
            $r = $rows[$i]
            $mark = ' '
            $col = [byte]7
            if ($i -eq $sel) { $mark = '>'; $col = [byte]14 }
            $state = [string]$r.Note
            if ([string]$r.Note -eq '' -and $r.Have) { $state = 'fitted' }
            $line = "{0} {1,-22} {2,6} CR   {3}" -f $mark, $r.Name, $r.Price, $state
            Write-At 1 (4 + $i) $line $col ($script:W - 2)
        }
        Write-At 1 ($script:H - 2) 'Enter buys    Esc back' 8 40
        if ($script:MsgT -gt 0) { Write-At 1 ($script:H - 3) $script:Msg 11 ($script:W - 2) }
        Present-Frame
        $k = [Console]::ReadKey($true)
        if ($k.Key -eq 'UpArrow') { $sel--; if ($sel -lt 0) { $sel = $rows.Count - 1 } }
        elseif ($k.Key -eq 'DownArrow') { $sel++; if ($sel -ge $rows.Count) { $sel = 0 } }
        elseif ($k.Key -eq 'Escape') { $script:MsgT = 0; return }
        elseif ($k.Key -eq 'Enter' -or $k.Key -eq 'Spacebar') {
            $r = $rows[$sel]
            if ($r.Id -eq 'mount') {
                $script:FitMount++
                if ($script:FitMount -gt 3) { $script:FitMount = 0 }
                Say "Lasers will fit the $($script:ViewName[$script:FitMount]) mount."
                continue
            }
            $techHere = $script:Systems[$script:Sys].Tech
            if ([int]$r.Tech -gt $techHere) { Say "Needs tech $($r.Tech). This station is $techHere."; continue }
            if ($r.Have -and $r.Id -ne 'missile' -and $r.Id -ne 'gal' -and $r.Id -ne 'bomb') { Say 'Already fitted.'; continue }
            $price = [int]$r.Price
            if ($r.Id -eq 'pulse' -or $r.Id -eq 'beam' -or $r.Id -eq 'military' -or $r.Id -eq 'mining') {
                $price -= Laser-Worth ([string]$script:Laser[$script:FitMount])
                if ($price -lt 0) { $price = 0 }
            }
            if ($script:Cash -lt $price) { Say 'Not enough credits.'; continue }
            switch ($r.Id) {
                'pulse' { $script:Laser[$script:FitMount] = 'pulse'; $script:Cash -= $price; Sync-LaserFlag; Say 'Pulse laser fitted.' }
                'beam' { $script:Laser[$script:FitMount] = 'beam'; $script:Cash -= $price; Sync-LaserFlag; Say 'Beam laser fitted.' }
                'military' { $script:Laser[$script:FitMount] = 'military'; $script:Cash -= $price; Sync-LaserFlag; Say 'Military laser fitted.' }
                'mining' { $script:Laser[$script:FitMount] = 'mining'; $script:Cash -= $price; Sync-LaserFlag; Say 'Mining laser fitted.' }
                'ecm' { $script:ECM = $true; $script:Cash -= 600; Say 'ECM fitted. Press E.' }
                'scoop' { $script:Scoops = $true; $script:Cash -= 525; Say 'Fuel scoops fitted. Skim the sun, or the lower view.' }
                'pod' { $script:EscapePod = $true; $script:Cash -= 1000; Say 'Escape pod fitted. Press Q.' }
                'bomb' {
                    if ($script:Bomb -gt 0) { Say 'A bomb is already aboard.' }
                    else { $script:Bomb = 1; $script:Cash -= 900; Say 'Energy bomb aboard. Press W. One shot.' }
                }
                'energy' { $script:EnergyUnit = $true; $script:Cash -= 1500; Say 'Extra energy unit fitted. Recharge doubled.' }
                'dock' { $script:DockComp = $true; $script:Cash -= 1500; Say 'Docking computer fitted.' }
                'gal' { $script:GalCharges++; $script:GalDrive = $true; $script:Cash -= 5000; Say 'Galactic hyperdrive loaded. One jump. H on the galactic chart.' }
                'cargo' {
                    if ($script:CargoMax -ge 35) { Say 'Hold is already 35t.' }
                    else { $script:CargoMax = 35; $script:Cash -= 400; Say 'Large cargo bay fitted. Hold is 35t.' }
                }
                'missile' {
                    if ($script:Missiles -ge 4) { Say 'Magazine full.' }
                    else { $script:Missiles++; $script:Cash -= 30; Say 'Missile loaded.' }
                }
            }
        }
    }
}

function Nearest-System([int]$x, [int]$y) {
    $best = 0
    $bestD = 999999.0
    for ($i = 0; $i -lt 256; $i++) {
        $dx = [double]($script:Systems[$i].X - $x)
        $dy = [double]($script:Systems[$i].Y - $y)
        $d = $dx * $dx + $dy * $dy
        if ($d -lt $bestD) { $bestD = $d; $best = $i }
    }
    $script:NearD = [Math]::Sqrt($bestD)
    return $best
}

function Show-Chart([bool]$galactic, [bool]$fromFlight) {
    $cur = $script:Systems[$script:Sys]
    $cx = [int]$cur.X
    $cy = [int]$cur.Y
    while ($true) {
        Sync-Console
        Clear-Frame
        $title = 'SHORT RANGE CHART'
        if ($galactic) { $title = "GALACTIC CHART  $($script:GalNum)" }
        Write-At 1 0 $title 14 40
        Write-At ($script:W - 28) 0 "FUEL $(F1 $script:Fuel) LY" 11 26
        $plotW = $script:W - 2
        $plotH = $script:H - 8
        $ox = 1
        $oy = 2
        if ($galactic) {
            for ($i = 0; $i -lt 256; $i++) {
                $s = $script:Systems[$i]
                $x = $ox + [int]($s.X / 255.0 * ($plotW - 1))
                $y = $oy + [int]($s.Y / 255.0 * ($plotH - 1))
                $col = [byte]8
                $ch = '.'
                if ($i -eq $script:Sys) { $col = [byte]10; $ch = 'O' }
                elseif ($i -eq $script:JumpTarget) { $col = [byte]11; $ch = '*' }
                Write-At $x $y $ch $col 1
            }
            $hx = $ox + [int]($cx / 255.0 * ($plotW - 1))
            $hy = $oy + [int]($cy / 255.0 * ($plotH - 1))
            Write-At ($hx - 1) $hy '[' 14 1
            Write-At ($hx + 1) $hy ']' 14 1
        }
        else {
            $scale = ($plotW - 4) / 70.0
            if ($scale -lt 0.35) { $scale = 0.35 }
            $midX = $ox + [int]($plotW / 2)
            $midY = $oy + [int]($plotH / 2)
            for ($i = 0; $i -lt 256; $i++) {
                $s = $script:Systems[$i]
                $dx = $s.X - $cur.X
                $dy = $s.Y - $cur.Y
                $x = [int]($midX + $dx * $scale)
                $y = [int]($midY + $dy * $scale * 0.55)
                if ($x -lt $ox -or $y -lt $oy -or $x -ge $ox + $plotW -or $y -ge $oy + $plotH) { continue }
                $ly = Get-Ly $script:Sys $i
                $col = [byte]8
                $ch = '.'
                if ($ly -le $script:Fuel + 0.001) { $col = [byte]7; $ch = '+' }
                if ($i -eq $script:Sys) { $col = [byte]10; $ch = 'O' }
                elseif ($i -eq $script:JumpTarget) { $col = [byte]11; $ch = '*' }
                Write-At $x $y $ch $col 1
            }
            $hx = [int]($midX + ($cx - $cur.X) * $scale)
            $hy = [int]($midY + ($cy - $cur.Y) * $scale * 0.55)
            Write-At ($hx - 1) $hy '[' 14 1
            Write-At ($hx + 1) $hy ']' 14 1
        }
        $near = Nearest-System $cx $cy
        $ns = $script:Systems[$near]
        $ly = Get-Ly $script:Sys $near
        $info = "$($ns.Name)  $(F1 $ly) LY  $($script:GovName[$ns.Gov])  $($script:EcoName[$ns.Eco])  TL $($ns.Tech)"
        Write-At 1 ($script:H - 4) $info 15 ($script:W - 2)
        $help = 'Arrows move   Enter sets target   Esc back'
        if ($fromFlight) { $help = 'Arrows move   Enter sets target   J jumps   Esc back' }
        if ($galactic -and $script:GalDrive) { $help += '   H next galaxy' }
        Write-At 1 ($script:H - 2) $help 8 ($script:W - 2)
        if ($script:MsgT -gt 0) { Write-At 1 ($script:H - 3) $script:Msg 11 ($script:W - 2) }
        Present-Frame
        $k = [Console]::ReadKey($true)
        $step = 4
        if (-not $galactic) { $step = 2 }
        if ($k.Key -eq 'LeftArrow') { $cx -= $step }
        elseif ($k.Key -eq 'RightArrow') { $cx += $step }
        elseif ($k.Key -eq 'UpArrow') { $cy -= $step }
        elseif ($k.Key -eq 'DownArrow') { $cy += $step }
        elseif ($k.Key -eq 'Enter') {
            if ($script:NearD -le 8 -or $galactic) {
                $script:JumpTarget = $near
                Say "Destination $($ns.Name)."
            }
            else { Say 'No system under the cursor.' }
        }
        elseif ($k.Key -eq 'Delete') { $script:JumpTarget = -1; Say 'Destination cleared.' }
        elseif (($k.KeyChar -eq 'j' -or $k.KeyChar -eq 'J') -and $fromFlight) { return 'jump' }
        elseif (($k.KeyChar -eq 'h' -or $k.KeyChar -eq 'H') -and $galactic) { return 'galactic' }
        elseif ($k.Key -eq 'Escape') { $script:MsgT = 0; return 'back' }
        if ($cx -lt 0) { $cx = 0 }
        if ($cy -lt 0) { $cy = 0 }
        if ($cx -gt 255) { $cx = 255 }
        if ($cy -gt 255) { $cy = 255 }
    }
}

function Show-Info {
    $sys = $script:Systems[$script:Sys]
    while ($true) {
        Sync-Console
        Clear-Frame
        Write-Mid 1 $sys.Name.ToUpperInvariant() 14
        $blurb = "A $($script:EcoName[$sys.Eco].ToLowerInvariant()) world under $($script:GovName[$sys.Gov].ToLowerInvariant()) rule."
        Write-At 2 4 $blurb 7 ($script:W - 4)
        Write-At 2 5 "Tech level $($sys.Tech). Population $(F1 $sys.Pop) billion." 7 ($script:W - 4)
        Write-At 2 6 "Known for $($sys.Feature)." 7 ($script:W - 4)
        Write-At 2 8 "Coordinates $($sys.X), $($sys.Y).   Fuel $(F1 $script:Fuel) LY." 11 ($script:W - 4)
        $near = 0
        for ($i = 0; $i -lt 256; $i++) {
            if ($i -eq $script:Sys) { continue }
            if ((Get-Ly $script:Sys $i) -le 7.0) { $near++ }
        }
        Write-At 2 9 "Systems inside 7 LY: $near" 7 40
        Write-At 2 11 'Press any key.' 8 20
        Present-Frame
        [void][Console]::ReadKey($true)
        return 'back'
    }
}

function Show-Pause {
    $sel = 0
    $items = @('Continue', 'Local chart', 'Galactic chart', 'Jump', 'How to fly', 'Save', 'Exit to title')
    while ($true) {
        Sync-Console
        Clear-Frame
        Write-Mid 2 'PAUSED' 14
        for ($i = 0; $i -lt $items.Count; $i++) {
            $col = [byte]7
            $mark = '  '
            if ($i -eq $sel) { $col = [byte]14; $mark = '> ' }
            Write-Mid (5 + $i) "$mark$($items[$i])" $col
        }
        Present-Frame
        $k = [Console]::ReadKey($true)
        if ($k.Key -eq 'UpArrow') { $sel--; if ($sel -lt 0) { $sel = $items.Count - 1 } }
        elseif ($k.Key -eq 'DownArrow') { $sel++; if ($sel -ge $items.Count) { $sel = 0 } }
        elseif ($k.Key -eq 'Escape') { return 'continue' }
        elseif ($k.Key -eq 'Enter' -or $k.Key -eq 'Spacebar') {
            switch ($sel) {
                0 { return 'continue' }
                1 { return 'chart' }
                2 { return 'galaxy' }
                3 { return 'jump' }
                4 { Show-Help 'pause' | Out-Null }
                5 { Save-Commander; Say 'Commander saved.'; return 'continue' }
                6 { return 'title' }
            }
        }
    }
}

function Show-Flight {
    $clock = [Diagnostics.Stopwatch]::StartNew()
    Acknowledge-Keys
    while ($true) {
        $dt = $clock.Elapsed.TotalSeconds
        $clock.Restart()
        Sync-Console
        Read-FlightInput
        if ($script:EdgePause) {
            $choice = Show-Pause
            Acknowledge-Keys
            if ($choice -eq 'title') { return 'title' }
            if ($choice -eq 'chart') {
                $r = Show-Chart $false $true
                if ($r -eq 'jump') { Try-Jump }
            }
            elseif ($choice -eq 'galaxy') {
                $r = Show-Chart $true $true
                if ($r -eq 'jump') { Try-Jump }
                elseif ($r -eq 'galactic') { Try-Galactic }
            }
            elseif ($choice -eq 'jump') { Try-Jump }
            $clock.Restart()
            continue
        }
        if ($script:EdgeChart) {
            $r = Show-Chart $false $true
            Acknowledge-Keys
            if ($r -eq 'jump') { Try-Jump }
            $clock.Restart()
            continue
        }
        if ($script:EdgeGal) {
            $r = Show-Chart $true $true
            Acknowledge-Keys
            if ($r -eq 'jump') { Try-Jump }
            elseif ($r -eq 'galactic') { Try-Galactic }
            $clock.Restart()
            continue
        }
        if ($script:EdgeView -ge 0) {
            $script:View = $script:EdgeView
            Say "$($script:ViewName[$script:View]) view."
        }
        if ($script:EdgeEcm) { Try-ECM }
        if ($script:EdgeBomb) { Try-Bomb }
        if ($script:EdgeEscape) { Try-Escape }
        if ($script:EdgeUnarm) { $script:MissileArm = 0; Say 'Missiles safe.' }
        if ($script:EdgeHeavy) { Try-Heavy }
        if ($script:EdgeCloak) {
            if (-not $script:HasCloak) { Say 'No cloaking device.' }
            else { $script:CloakOn = -not $script:CloakOn; Say $(if ($script:CloakOn) { 'Cloak on.' } else { 'Cloak off.' }) }
        }
        if ($script:EdgeDock) { Try-Dock }
        if ($script:EdgeJump) { Try-Jump }
        if ($script:EdgeTarget) { Arm-Missile }
        if ($script:EdgeMissile) { Try-Missile }
        $state = Update-Flight $dt
        if ($state -eq 'docked') {
            Apply-DockService
            return 'docked'
        }
        if ($state -eq 'dead') { return 'dead' }
        Clear-Frame
        Draw-Flight
        Present-Frame
        $spent = $clock.Elapsed.TotalMilliseconds
        if ($spent -lt 45) { Start-Sleep -Milliseconds ([int](45 - $spent)) }
    }
}

function Show-GameOver {
    while ($true) {
        Sync-Console
        Clear-Frame
        Write-Mid 4 'SHIP DESTROYED' 9
        Write-Mid 6 "Commander $($script:Name)" 15
        Write-Mid 7 "Rank $(Get-RankName $script:Kills)    Kills $($script:Kills)" 7
        Write-Mid 8 "Credits $($script:Cash)    Days $($script:Day)" 7
        Write-Mid 11 'The last dock is still in the save file.' 8
        Write-Mid 13 'L  load save     T  title     Q  quit' 14
        Present-Frame
        $k = [Console]::ReadKey($true)
        $ch = [string]$k.KeyChar
        if ($ch -eq 'l' -or $ch -eq 'L') {
            if (Load-Commander) { return 'docked' }
        }
        if ($ch -eq 't' -or $ch -eq 'T') { return 'title' }
        if ($ch -eq 'q' -or $ch -eq 'Q') { return 'quit' }
    }
}

function Invoke-SelfTest {
    $failed = $false
    function Check([bool]$cond, [string]$msg) {
        if (-not $cond) {
            Write-Output "FAIL $msg"
            $script:TestFail = $true
        }
    }
    $script:TestFail = $false
    $script:NoSpawn = $true
    $script:InPitch = 0
    $script:InRoll = 0
    $script:InThrust = 0
    $script:InBrake = $false
    $script:InFire = $false
    $oldSave = $script:SavePath
    $script:SavePath = Join-Path $env:TEMP 'elite-ps-selftest.json'
    $script:SaveDir = $env:TEMP

    Reset-Commander 'Tester' 12345
    Check ($script:Systems.Count -eq 256) 'galaxy size'
    $names = @{}
    foreach ($s in $script:Systems) {
        Check ($s.Name.Length -gt 1) 'name'
        Check ($s.X -ge 0 -and $s.X -le 255) 'coord'
        $names[$s.Name] = $true
    }
    Check ($names.Count -gt 200) 'unique names'
    $homeSys = $script:Systems[$script:Sys]
    Check ($homeSys.Name -eq 'Lave') 'home is Lave'
    Check ($homeSys.Eco -ge 4) 'home is agricultural'
    Check ($script:Missiles -eq 3) 'three missiles'
    Check ((Get-RankName 8) -eq 'Mostly Harmless') 'rank 8'
    Check ((Get-RankName 512) -eq 'Dangerous') 'rank dangerous'
    Check ((Get-RankName 6400) -eq 'Elite') 'rank elite'
    $foundInd = $false
    for ($j = 0; $j -lt 256; $j++) {
        if ($j -eq $script:Sys) { continue }
        if ($script:Systems[$j].Eco -le 2 -and (Get-Ly $script:Sys $j) -le 7.0) { $foundInd = $true }
    }
    Check $foundInd 'industrial neighbour in fuel range'
    Refresh-Market
    Check ($script:Market.Count -eq 17) 'market rows'
    $food = $script:Market[0]
    Check ($food.Price -ge 1 -and $food.Price -le 80) "food price $($food.Price)"
    $script:Cash = 500
    Trade-Good 0 1 3
    Check ((Get-Hold 'Food') -eq 3) 'bought food'
    Check ($script:CargoUsed -eq 3) 'cargo used'
    Trade-Good 0 -1 3
    Check ((Get-Hold 'Food') -eq 0) 'sold food'

    $m = New-Object 'double[]' 9
    Set-Identity $m
    for ($n = 0; $n -lt 40; $n++) { Turn-Ship $m 0.2 0.15; Repair-Axes $m }
    $lenF = Speed-Of $m[6] $m[7] $m[8]
    $dot = $m[0] * $m[3] + $m[1] * $m[4] + $m[2] * $m[5]
    Check ([Math]::Abs($lenF - 1) -lt 0.02) "forward length $lenF"
    Check ([Math]::Abs($dot) -lt 0.02) "axis dot $dot"

    Set-Identity $m
    $script:M = $m
    $script:Px = 0; $script:Py = 0; $script:Pz = -1000
    Get-Steer $m 0 0 1000
    Check ($script:LocZ -gt 0.9) "ahead lz $($script:LocZ)"
    $script:Px = 0; $script:Py = 0; $script:Pz = 1000
    Get-Steer $m 0 0 -2000
    Check ($script:LocZ -lt -0.9) "behind lz $($script:LocZ)"

    Set-Frame 96 34
    Enter-Space 'launch'
    Clear-Frame
    Draw-Flight
    $dump = Join-Path $env:TEMP 'elite-frame.txt'
    Dump-Frame $dump
    $text = Get-Content $dump -Raw
    Check ($text.Contains('FS ')) 'hud shield'
    Check ($text.Contains('FU ')) 'hud fuel'
    Check ($text.Contains('SP ')) 'hud speed'
    Check ($text.Contains('+--')) 'cockpit corners'
    $nBraille = 0
    foreach ($ch in $script:Buf) {
        $code = [int]$ch
        if ($code -ge 0x2800 -and $code -le 0x28FF) { $nBraille++ }
    }
    Check ($nBraille -ge 10) "braille cells $nBraille"
    $hudDots = 0
    for ($y = $script:HudY; $y -lt $script:H; $y++) {
        $row = $y * $script:W
        for ($x = 0; $x -lt $script:W; $x++) {
            $code = [int]$script:Buf[$row + $x]
            if ($code -ge 0x2800 -and $code -le 0x28FF) { $hudDots++ }
        }
    }
    Check ($hudDots -ge 12) "scanner cells $hudDots"
    $sample = New-Object 'byte[]' 16
    [EliteBraille.Raster]::Plot($sample, 4, 4, 0, 0, 14)
    [EliteBraille.Raster]::Plot($sample, 4, 4, 1, 0, 14)
    $sampleBuf = New-Object 'char[]' 2
    $sampleCol = New-Object 'byte[]' 2
    [EliteBraille.Raster]::Stamp($sample, 4, $sampleBuf, $sampleCol, 2, 0, 1, $script:Pri)
    Check (([int]$sampleBuf[0]) -eq (0x2800 + 0x09)) 'braille dot pattern'
    Set-Identity $script:M
    $script:View = 1
    Sync-Camera
    Check ($script:Cam[8] -lt -0.9) "rear view $($script:Cam[8])"
    $script:View = 2
    Sync-Camera
    Check ($script:Cam[6] -lt -0.9) "left view $($script:Cam[6])"
    $script:View = 0
    Sync-Camera
    $script:ECM = $true
    $script:Energy = 40
    if ($null -eq $script:Bolts) { $script:Bolts = New-Object System.Collections.Generic.List[object] }
    $script:Bolts.Clear()
    $script:Bolts.Add(@{ X = 0; Y = 0; Z = 0; VX = 0; VY = 0; VZ = 0; Life = 3.0; Target = -2; Heavy = $false })
    Try-ECM
    Check ($script:Bolts.Count -eq 0) 'ecm clears missiles'
    Check ($script:Laser[0] -eq 'pulse') 'front pulse'
    $script:View = 3
    $script:Laser[3] = 'military'
    Check ((Laser-Kind) -eq 'military') 'right military'
    $script:View = 0
    $script:Laser[3] = 'none'
    Paint-Docked 0
    Paint-Market 0

    $script:Cash = 100
    $script:Hull = 40
    $script:Fuel = 2.2
    $script:JumpTarget = 4
    $script:Missiles = 2
    Save-Commander
    $script:Cash = 1
    $loaded = Load-Commander
    Check $loaded 'load'
    Check ($script:Cash -eq 100) 'save cash'
    Check ([Math]::Abs($script:Fuel - 2.2) -lt 0.01) 'save fuel'
    Check ($script:Name -eq 'Tester') 'save name'

    $script:NoSpawn = $true
    Enter-Space 'launch'
    $start = Speed-Of $script:Px $script:Py $script:Pz
    $script:AutoDock = $true
    $docked = $false
    for ($frame = 0; $frame -lt 700; $frame++) {
        $script:InPitch = 0
        $script:InRoll = 0
        $script:InThrust = 0
        $script:InBrake = $false
        $script:InFire = $false
        $state = Update-Flight 0.05
        if ($state -eq 'docked') { $docked = $true; break }
        if ($state -eq 'dead') { break }
    }
    $end = Speed-Of $script:Px $script:Py $script:Pz
    Check ($docked -or $end -lt $start) "autopilot start $start end $end docked $docked"
    Write-Output ("AUTOPILOT start={0} end={1} docked={2}" -f ([int]$start), ([int]$end), $docked)

    $script:QuietPresent = $true
    $sw = [Diagnostics.Stopwatch]::StartNew()
    for ($frame = 0; $frame -lt 15; $frame++) {
        Clear-Frame
        Draw-Flight
        Present-Ansi
    }
    $script:QuietPresent = $false
    $sw.Stop()
    $ms = $sw.Elapsed.TotalMilliseconds / 15.0
    Write-Output ("FRAME {0:0.0} ms" -f $ms)
    Check ($ms -lt 180) 'frame time'

    Remove-Item $script:SavePath -ErrorAction SilentlyContinue
    Remove-Item $dump -ErrorAction SilentlyContinue
    $script:SavePath = $oldSave
    if ($script:TestFail) { throw 'Self-test failed' }
    Write-Output 'SELFTEST OK'
}

if ($SelfTest) {
    Invoke-SelfTest
    return
}

try {
    Open-Console
    $next = 'title'
    while ($next -ne 'quit') {
        switch ($next) {
            'title' { $next = Show-Title }
            'docked' { $next = Show-Docked }
            'flight' { $next = Show-Flight }
            'dead' { $next = Show-GameOver }
            default { $next = 'quit' }
        }
    }
}
catch {
    $script:Fatal = $_
}
finally {
    Close-Console
}

if ($null -ne $script:Fatal) {
    Write-Host $script:Fatal.Exception.Message
    Write-Host $script:Fatal.ScriptStackTrace
    exit 1
}
