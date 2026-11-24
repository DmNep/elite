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
$script:Market = $null
$script:NoSpawn = $false
$script:KeyPrev = @{}
$script:QuietPresent = $false
$script:Dots = $null
$script:Pri = $null

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
    @(0, 'Harmless'), @(2, 'Mostly Harmless'), @(6, 'Poor'), @(12, 'Average'),
    @(24, 'Above Average'), @(48, 'Competent'), @(100, 'Dangerous'),
    @(200, 'Deadly'), @(400, 'Elite')
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
$script:Goods = @(
    @{ N = 'Food';         B = 16;  K = -3; T = 0;  Il = $false },
    @{ N = 'Textiles';     B = 24;  K = -2; T = 0;  Il = $false },
    @{ N = 'Radioactives'; B = 28;  K = -1; T = 0;  Il = $false },
    @{ N = 'Spirits';      B = 32;  K = -2; T = 0;  Il = $false },
    @{ N = 'Luxuries';     B = 44;  K = -2; T = 0;  Il = $false },
    @{ N = 'Minerals';     B = 22;  K = -1; T = 1;  Il = $false },
    @{ N = 'Gold';         B = 74;  K = 1;  T = 2;  Il = $false },
    @{ N = 'Platinum';     B = 98;  K = 1;  T = 3;  Il = $false },
    @{ N = 'Gemstones';    B = 86;  K = 2;  T = 2;  Il = $false },
    @{ N = 'Alloys';       B = 40;  K = 3;  T = 4;  Il = $false },
    @{ N = 'Firearms';     B = 52;  K = 4;  T = 5;  Il = $true  },
    @{ N = 'Narcotics';    B = 70;  K = -4; T = 0;  Il = $true  },
    @{ N = 'Computers';    B = 96;  K = 7;  T = 8;  Il = $false },
    @{ N = 'Machinery';    B = 56;  K = 5;  T = 5;  Il = $false },
    @{ N = 'Robots';       B = 120; K = 8;  T = 10; Il = $false }
)

# Local ship space: +Z forward, +Y up, +X right. Units are metres.
$script:MeshViper = @{
    V = [double[]]@(
        0, 0, 48,  -34, 7, -26,  34, 7, -26,  -34, -8, -26,  34, -8, -26,  0, 15, -6,  0, -4, 16
    )
    E = [int[]]@(0,1, 0,2, 0,5, 0,6, 1,2, 1,3, 2,4, 3,4, 1,5, 2,5, 3,6, 4,6, 5,3, 5,4)
}
$script:MeshTrader = @{
    V = [double[]]@(
        0, 0, 36,  -28, 14, 8,  28, 14, 8,  -28, -14, 8,  28, -14, 8,
        -28, 14, -32,  28, 14, -32,  -28, -14, -32,  28, -14, -32
    )
    E = [int[]]@(
        0,1, 0,2, 0,3, 0,4, 1,2, 3,4, 1,3, 2,4,
        1,5, 2,6, 3,7, 4,8, 5,6, 7,8, 5,7, 6,8
    )
}
$script:MeshPython = @{
    V = [double[]]@(
        0, 0, 78,  -22, 12, 24,  22, 12, 24,  -22, -12, 24,  22, -12, 24,
        -46, 10, -58,  46, 10, -58,  -46, -10, -58,  46, -10, -58,  0, 22, -10
    )
    E = [int[]]@(
        0,1, 0,2, 0,3, 0,4, 0,9, 1,2, 3,4, 1,3, 2,4,
        1,5, 2,6, 3,7, 4,8, 5,6, 7,8, 5,7, 6,8, 9,5, 9,6, 5,8, 6,7
    )
}
$script:MeshAlien = @{
    V = [double[]]@(
        0, 0, 70,  0, 0, -70,  0, 48, 0,  0, -48, 0,  48, 0, 0,  -48, 0, 0
    )
    E = [int[]]@(
        0,2, 0,3, 0,4, 0,5, 1,2, 1,3, 1,4, 1,5, 2,4, 4,3, 3,5, 5,2
    )
}
$script:MeshStation = @{
    V = [double[]]@(
        0, 560, 0,  0, -560, 0,  560, 0, 0,  -560, 0, 0,  0, 0, 560,  0, 0, -560
    )
    E = [int[]]@(
        0,2, 0,3, 0,4, 0,5, 1,2, 1,3, 1,4, 1,5, 2,4, 4,3, 3,5, 5,2
    )
}
$script:MeshPort = @{
    V = [double[]]@(
        -150, -70, 620,  150, -70, 620,  150, 70, 620,  -150, 70, 620
    )
    E = [int[]]@(0,1, 1,2, 2,3, 3,0, 0,2, 1,3)
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
    $script:Energy = 100.0
    $script:EnergyMax = 100.0
    $script:Beam = $false
    $script:Missiles = 0
    $script:DockComp = $false
    $script:GalDrive = $false
    $script:Kills = 0
    $script:Legal = 0
    $script:Day = 0
    $script:GalNum = 1
    $script:JumpTarget = -1
    $script:Market = $null
    $script:MarketDay = -1
    $script:MarketSys = -1
    $script:Sys = Find-Home
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

function Save-Commander {
    if (-not (Test-Path $script:SaveDir)) { New-Item -ItemType Directory -Path $script:SaveDir | Out-Null }
    $cargo = @()
    foreach ($k in @($script:Cargo.Keys)) {
        $cargo += @{ N = [string]$k; Q = [int]$script:Cargo[$k] }
    }
    $data = @{
        Version = 1
        Name = $script:Name
        Cash = [int]$script:Cash
        Fuel = [double]$script:Fuel
        Cargo = $cargo
        CargoMax = [int]$script:CargoMax
        Hull = [double]$script:Hull
        ShieldMax = [double]$script:ShieldMax
        Beam = [bool]$script:Beam
        Missiles = [int]$script:Missiles
        DockComp = [bool]$script:DockComp
        GalDrive = [bool]$script:GalDrive
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
    $script:Missiles = [int]$data.Missiles
    $script:DockComp = [bool]$data.DockComp
    $script:GalDrive = [bool]$data.GalDrive
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
    if ($type -eq 'Trader') { $hull = 34; $dmg = 4; $maxSp = 140; $accel = 50; $bounty = 10; $scale = 1.15; $color = [byte]11 }
    elseif ($type -eq 'Python') { $hull = 80; $dmg = 10; $maxSp = 160; $accel = 55; $bounty = 110; $scale = 1.35; $color = [byte]9 }
    elseif ($type -eq 'Police') { $hull = 36; $dmg = 7; $maxSp = 260; $accel = 110; $bounty = 0; $scale = 1.0; $color = [byte]14 }
    elseif ($type -eq 'Alien') { $hull = 110; $dmg = 14; $maxSp = 280; $accel = 130; $bounty = 250; $scale = 1.7; $color = [byte]13 }
    $m = New-Object 'double[]' 9
    Set-Identity $m
    $ship = @{
        Id = $script:NextId; Type = $type; Role = $role
        X = $x; Y = $y; Z = $z; VX = 0.0; VY = 0.0; VZ = 0.0
        M = $m; Hull = $hull; HullMax = $hull; Dmg = $dmg; MaxSp = $maxSp; Accel = $accel
        Bounty = $bounty; Scale = $scale; Color = $color; Cool = 0.6 + ($script:NextId % 5) * 0.15
        Provoked = $false; Radius = 40.0 * $scale
        Jx = ($x * 0.15); Jy = 200.0; Jz = $z
    }
    $script:NextId++
    Set-Facing $m (-$x) (200 - $y) (-$z)
    return $ship
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
    for ($n = 0; $n -lt $pirates; $n++) {
        $ang = $rng.NextDouble() * 6.28318
        $dist = 4500.0 + $rng.NextDouble() * 7000.0
        $x = [Math]::Cos($ang) * $dist
        $z = [Math]::Sin($ang) * $dist
        $y = ($rng.NextDouble() - 0.5) * 1600.0
        $type = 'Viper'
        if ($sys.Gov -le 2 -and $rng.Next(0, 5) -eq 0) { $type = 'Python' }
        [void]$script:Ships.Add((New-Ship $type 'pirate' $x $y $z))
    }
    $traders = 1
    if ($sys.Gov -ge 4) { $traders = 2 }
    for ($n = 0; $n -lt $traders; $n++) {
        $ang = $rng.NextDouble() * 6.28318
        $dist = 3000.0 + $rng.NextDouble() * 5000.0
        [void]$script:Ships.Add((New-Ship 'Trader' 'trader' ([Math]::Cos($ang) * $dist) (($rng.NextDouble() - 0.5) * 800) ([Math]::Sin($ang) * $dist)))
    }
    $illegal = $false
    foreach ($k in @($script:Cargo.Keys)) {
        if ($k -eq 'Narcotics' -or $k -eq 'Firearms') { $illegal = $true }
    }
    if ((Test-Lawful $sys.Gov) -and ($script:Legal -gt 0 -or $illegal)) {
        $cops = 1
        if ($script:Legal -gt 12) { $cops = 2 }
        for ($n = 0; $n -lt $cops; $n++) {
            [void]$script:Ships.Add((New-Ship 'Police' 'police' (1800.0 + $n * 400) 300.0 (2200.0 + $n * 300)))
        }
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
    [void]$script:Ships.Add((New-Ship 'Alien' 'alien' 0 0 2200))
    Say 'WITCH-SPACE. An intruder has locked on.'
}

function Complete-Witch {
    $script:Sys = $script:PendingSys
    Enter-Space 'jump'
    Say 'Normal space. The witch-space tear has closed.'
}

function Hurt-Player([double]$amount) {
    $script:SinceHit = 0
    $script:HitFlash = 0.18
    if ($script:Shield -gt 0) {
        $script:Shield -= $amount
        if ($script:Shield -lt 0) {
            $script:Hull += $script:Shield
            $script:Shield = 0
        }
    }
    else {
        $script:Hull -= $amount
    }
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

function Kill-Ship($ship) {
    if ($ship.Role -eq 'pirate' -or $ship.Role -eq 'alien') {
        $script:Kills++
        $script:Cash += [int]$ship.Bounty
        Say "Destroyed $($ship.Type). Bounty $($ship.Bounty) CR."
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
    Add-Debris $ship.X $ship.Y $ship.Z $ship.Color
}

function Try-Fire {
    $cost = 8.0; $cool = 0.34; $dmg = 12.0; $range = 6200.0
    if ($script:Beam) { $cost = 3.0; $cool = 0.08; $dmg = 6.0 }
    if ($script:Cool -gt 0 -or $script:Energy -lt $cost) { return }
    $script:Energy -= $cost
    $script:Cool = $cool
    $script:LaserT = 0.07
    $best = $null
    $bestD = $range
    foreach ($s in $script:Ships) {
        if ($s.Hull -le 0) { continue }
        $dx = $s.X - $script:Px; $dy = $s.Y - $script:Py; $dz = $s.Z - $script:Pz
        World-To-Local $script:M $dx $dy $dz
        $dist = [Math]::Sqrt($script:LocX * $script:LocX + $script:LocY * $script:LocY + $script:LocZ * $script:LocZ)
        if ($script:LocZ -le 40 -or $dist -gt $range -or $dist -lt 1) { continue }
        $off = [Math]::Sqrt($script:LocX * $script:LocX + $script:LocY * $script:LocY) / $dist
        if ($off -lt 0.11 -and $dist -lt $bestD) { $best = $s; $bestD = $dist }
    }
    if ($null -ne $best) {
        $best.Hull -= $dmg
        if ($best.Role -eq 'trader') { $best.Provoked = $true; $script:Legal += 1 }
        $script:Lx = $best.X; $script:Ly = $best.Y; $script:Lz = $best.Z
        if ($best.Hull -le 0) { Kill-Ship $best }
    }
    else {
        $script:Lx = $script:Px + $script:M[6] * 2400.0
        $script:Ly = $script:Py + $script:M[7] * 2400.0
        $script:Lz = $script:Pz + $script:M[8] * 2400.0
    }
}

function Try-Missile {
    if ($script:Missiles -le 0) { Say 'No missiles.'; return }
    $target = $null
    foreach ($s in $script:Ships) {
        if ($s.Id -eq $script:TargetId -and $s.Hull -gt 0) { $target = $s }
    }
    if ($null -eq $target) { Say 'No target. Press T.'; return }
    $script:Missiles--
    $script:Bolts.Add(@{
        X = $script:Px + $script:M[6] * 80; Y = $script:Py + $script:M[7] * 80; Z = $script:Pz + $script:M[8] * 80
        VX = $script:M[6] * 500; VY = $script:M[7] * 500; VZ = $script:M[8] * 500
        Life = 7.0; Target = $target.Id
    })
    Say 'Missile away.'
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

function Try-Jump {
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
}

function Try-Galactic {
    if (-not $script:GalDrive) { Say 'No galactic hyperdrive.'; return }
    if ($script:Witch) { Say 'Not in witch-space.'; return }
    if (Test-MassLocked) { Say 'Mass-locked.'; return }
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
    Say "Galaxy $($script:GalNum)."
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

function Apply-DockService {
    $sys = $script:Systems[$script:Sys]
    $script:Shield = $script:ShieldMax
    $script:Energy = $script:EnergyMax
    $script:AutoDock = $false
    $script:Vx = 0; $script:Vy = 0; $script:Vz = 0
    $fine = 0
    if (Test-Lawful $sys.Gov) {
        $fine += $script:Legal * 20
        foreach ($k in @($script:Cargo.Keys)) {
            if ($k -eq 'Narcotics' -or $k -eq 'Firearms') {
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
    Save-Commander
}

function Update-Enemies([double]$dt) {
    $safe = (Speed-Of $script:Px $script:Py $script:Pz) -lt 1700
    foreach ($e in $script:Ships) {
        if ($e.Hull -le 0) { continue }
        $dx = $script:Px - $e.X; $dy = $script:Py - $e.Y; $dz = $script:Pz - $e.Z
        $dist = Speed-Of $dx $dy $dz
        $hostile = $e.Role -eq 'pirate' -or $e.Role -eq 'police' -or $e.Role -eq 'alien' -or $e.Provoked
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
                    Hurt-Player $e.Dmg
                    $e.Cool = 1.15
                    Say 'Under fire.'
                }
            }
        }
        if ($dist -lt (70 + $e.Radius)) { Hurt-Player 8; $e.Hull -= 6 }
    }
}

function Update-Bolts([double]$dt) {
    for ($i = $script:Bolts.Count - 1; $i -ge 0; $i--) {
        $b = $script:Bolts[$i]
        $target = $null
        foreach ($s in $script:Ships) {
            if ($s.Id -eq $b.Target -and $s.Hull -gt 0) { $target = $s }
        }
        if ($null -ne $target) {
            $dx = $target.X - $b.X; $dy = $target.Y - $b.Y; $dz = $target.Z - $b.Z
            $dist = Speed-Of $dx $dy $dz
            if ($dist -lt 120) {
                $target.Hull -= 46
                if ($target.Role -eq 'trader') { $target.Provoked = $true; $script:Legal += 1 }
                if ($target.Hull -le 0) { Kill-Ship $target }
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

function Update-Flight([double]$dt) {
    if ($script:Dead) { return 'dead' }
    if ($dt -gt 0.12) { $dt = 0.12 }
    if ($dt -lt 0.001) { $dt = 0.001 }
    $script:StAngle += $dt * 0.09
    $script:Cool -= $dt
    if ($script:Cool -lt 0) { $script:Cool = 0 }
    $script:LaserT -= $dt
    $script:HitFlash -= $dt
    $script:SinceHit += $dt
    $script:MsgT -= $dt
    if ($script:Energy -lt $script:EnergyMax) {
        $script:Energy += 16 * $dt
        if ($script:Energy -gt $script:EnergyMax) { $script:Energy = $script:EnergyMax }
    }
    if ($script:SinceHit -gt 2.2 -and $script:Shield -lt $script:ShieldMax) {
        $script:Shield += 10 * $dt
        if ($script:Shield -gt $script:ShieldMax) { $script:Shield = $script:ShieldMax }
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
    Clamp-Speed 640
    $script:Px += $script:Vx * $dt
    $script:Py += $script:Vy * $dt
    $script:Pz += $script:Vz * $dt

    if (-not $script:Witch) {
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
            $script:DidDock = $true
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
    if ($script:Dead) { return 'dead' }
    if ($script:DidDock) { return 'docked' }
    return 'ok'
}

function Set-Frame([int]$w, [int]$h) {
    if ($w -lt 50) { $w = 50 }
    if ($h -lt 24) { $h = 24 }
    $script:W = $w
    $script:H = $h
    $script:HudH = 8
    $script:ViewY = 1
    $script:ViewH = $h - 1 - $script:HudH
    if ($script:ViewH -lt 10) { $script:ViewH = 10 }
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
    if ($w -lt 64) { $w = 64 }
    if ($h -lt 26) { $h = 26 }
    if ($w -gt 110) { $w = 110 }
    if ($h -gt 40) { $h = 40 }
    if ($script:W -ne $w -or $script:H -ne $h -or $null -eq $script:Buf) { Set-Frame $w $h }
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
      int dx = Math.Abs(x1 - x0);
      int sx = x0 < x1 ? 1 : -1;
      int dy = -Math.Abs(y1 - y0);
      int sy = y0 < y1 ? 1 : -1;
      int err = dx + dy;
      int guard = 0;
      while (guard++ < 1600) {
        if ((uint)x0 < (uint)dw && (uint)y0 < (uint)dh)
          dots[y0 * dw + x0] = color;
        if (x0 == x1 && y0 == y1) break;
        int e2 = err << 1;
        if (e2 >= dy) { err += dy; x0 += sx; }
        if (e2 <= dx) { err += dx; y0 += sy; }
      }
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
    World-To-Local $script:M $dx $dy $dz
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
    for ($i = 0; $i -lt $n; $i++) {
        $lx = $verts[$i * 3] * $scale
        $ly = $verts[$i * 3 + 1] * $scale
        $lz = $verts[$i * 3 + 2] * $scale
        $wx = $ox + $lx * $rm[0] + $ly * $rm[3] + $lz * $rm[6]
        $wy = $oy + $lx * $rm[1] + $ly * $rm[4] + $lz * $rm[7]
        $wz = $oz + $lx * $rm[2] + $ly * $rm[5] + $lz * $rm[8]
        $dx = $wx - $script:Px; $dy = $wy - $script:Py; $dz = $wz - $script:Pz
        $script:ViewTmp[$i * 3] = $dx * $script:M[0] + $dy * $script:M[1] + $dz * $script:M[2]
        $script:ViewTmp[$i * 3 + 1] = $dx * $script:M[3] + $dy * $script:M[4] + $dz * $script:M[5]
        $script:ViewTmp[$i * 3 + 2] = $dx * $script:M[6] + $dy * $script:M[7] + $dz * $script:M[8]
    }
    for ($e = 0; $e -lt $edges.Length; $e += 2) {
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
    $dx = -$script:Px; $dy = -$script:Py; $dz = -$script:Pz
    $dist = Speed-Of $dx $dy $dz
    if ($dist -lt 1) { $dist = 1 }
    World-To-Local $script:M ($dx / $dist) ($dy / $dist) ($dz / $dist)
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

function Draw-Scanner {
    $cx = $script:W - 16
    $cy = $script:HudY + 4
    if ($cx -lt 20) { return }
    for ($a = 0; $a -lt 20; $a++) {
        $t = $a * 6.28318 / 20.0
        $x = [int]($cx + [Math]::Cos($t) * 9)
        $y = [int]($cy + [Math]::Sin($t) * 2.4)
        Write-At $x $y '.' 8 1
    }
    Write-At $cx $cy '+' 14 1
    $range = 14000.0
    if (-not $script:Witch) {
        World-To-Local $script:M (-$script:Px) (-$script:Py) (-$script:Pz)
        $x = [int]($cx + ($script:LocX / $range) * 9)
        $y = [int]($cy - ($script:LocZ / $range) * 2.4)
        Write-At $x $y 'S' 11 1
        World-To-Local $script:M ($script:PlX - $script:Px) ($script:PlY - $script:Py) ($script:PlZ - $script:Pz)
        $x = [int]($cx + ($script:LocX / $range) * 9)
        $y = [int]($cy - ($script:LocZ / $range) * 2.4)
        Write-At $x $y 'P' 10 1
    }
    foreach ($s in $script:Ships) {
        World-To-Local $script:M ($s.X - $script:Px) ($s.Y - $script:Py) ($s.Z - $script:Pz)
        $x = [int]($cx + ($script:LocX / $range) * 9)
        $y = [int]($cy - ($script:LocZ / $range) * 2.4)
        $mark = '+'
        if ($script:LocY -gt 250) { $mark = '^' }
        elseif ($script:LocY -lt -250) { $mark = 'v' }
        $col = [byte]$s.Color
        Write-At $x $y $mark $col 1
    }
}

function Draw-Flight {
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
        $c = [Math]::Cos($script:StAngle); $s = [Math]::Sin($script:StAngle)
        $script:StM[0] = $c;  $script:StM[1] = 0; $script:StM[2] = -$s
        $script:StM[3] = 0;   $script:StM[4] = 1; $script:StM[5] = 0
        $script:StM[6] = $s;  $script:StM[7] = 0; $script:StM[8] = $c
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
        $mesh = $script:MeshViper
        if ($s.Type -eq 'Trader') { $mesh = $script:MeshTrader }
        elseif ($s.Type -eq 'Python') { $mesh = $script:MeshPython }
        elseif ($s.Type -eq 'Alien') { $mesh = $script:MeshAlien }
        Draw-Mesh $mesh $s.X $s.Y $s.Z $s.M $s.Scale '#' $s.Color
    }
    foreach ($d in $script:Debris) {
        Project-Body $d.X $d.Y $d.Z
        if ($script:BodyOn) { Plot-Dot ([int]$script:BodyX) ([int]$script:BodyY) $d.Color }
    }
    foreach ($b in $script:Bolts) {
        Project-Body $b.X $b.Y $b.Z
        if ($script:BodyOn) {
            Plot-Dot ([int]$script:BodyX) ([int]$script:BodyY) 11
            Plot-Dot ([int]$script:BodyX + 1) ([int]$script:BodyY) 11
        }
    }
    if ($script:LaserT -gt 0) {
        $dx = $script:Lx - $script:Px; $dy = $script:Ly - $script:Py; $dz = $script:Lz - $script:Pz
        World-To-Local $script:M $dx $dy $dz
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

    $sp = Speed-Of $script:Vx $script:Vy $script:Vz
    $legal = 'Clean'
    if ($script:Legal -gt 15) { $legal = 'Fugitive' }
    elseif ($script:Legal -gt 0) { $legal = 'Offender' }
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

    $hy = $script:HudY
    Write-At 0 $hy ('-' * $script:W) 8 $script:W
    $line = "SPD $(F0 $sp)   FUEL $(F1 $script:Fuel) LY   CR $($script:Cash)   LEGAL $legal"
    Write-At 1 ($hy + 1) $line 7 ($script:W - 2)
    $bars = "HULL $(Bar $script:Hull $script:HullMax 8) $(F0 $script:Hull)  SHD $(Bar $script:Shield $script:ShieldMax 8) $(F0 $script:Shield)  EN $(Bar $script:Energy $script:EnergyMax 8) $(F0 $script:Energy)  MSL $($script:Missiles)"
    Write-At 1 ($hy + 2) $bars 6 ($script:W - 2)
    Write-At 1 ($hy + 3) "COND $cond" $condCol 12
    if ($script:Witch) { Write-At 16 ($hy + 3) 'STN  none' 5 20 }
    else {
        Get-Arrow
        Write-At 16 ($hy + 3) "STN $(Format-Km $script:StationDist) $($script:Arrow)" 11 28
    }
    $tname = 'none'
    foreach ($s in $script:Ships) {
        if ($s.Id -eq $script:TargetId) {
            $td = Speed-Of ($s.X - $script:Px) ($s.Y - $script:Py) ($s.Z - $script:Pz)
            $tname = "$($s.Type) $(Format-Km $td) H$(F0 $s.Hull)"
        }
    }
    Write-At 1 ($hy + 4) "TGT $tname" 7 40
    if ($script:AutoDock) { Write-At 42 ($hy + 4) 'AUTODOCK' 14 10 }
    if ($script:W -ge 78) {
        Write-At 1 ($hy + 6) 'Arrows turn  A thrust  Z brake  X retro  Space fire  M missile' 8 ($script:W - 20)
        Write-At 1 ($hy + 7) 'D dock  J jump  C chart  G galaxy  T target  Esc pause' 8 ($script:W - 20)
    }
    Draw-Scanner
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
            elseif ($k.Key -eq 'M') { $script:EdgeMissile = $true }
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
    $script:EdgeMissile = Test-Edge 77
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
    Write-Mid ($script:H - 3) 'Window 80x30 or larger. Windows Terminal looks best.' 8
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
        '  Left / Right     roll',
        '  Up / Down        pitch',
        '  A / Z / X        thrust, brake, retro',
        '  Space            lasers     M missile',
        '  D                dock, or toggle the docking computer',
        '  J                hyperspace to the chart target',
        '  C / G            local chart / galactic chart',
        '  T                cycle target     Esc pause',
        '',
        'DOCKING',
        '  The cyan rectangle is the slot. Face it, creep in under 62,',
        '  alignment above 72 percent, then press D.',
        '  A docking computer (1,500 CR) flies the approach for you.',
        '',
        'JUMPS',
        '  Fuel is light-years, tank of 7. Set a target on the chart,',
        '  fly clear of the station and planet, then press J.',
        '  About one jump in eleven tears into witch-space.',
        '',
        'Contraband: Narcotics and Firearms. Lawful stations seize them.',
        'A save is written every time you dock.',
        '',
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
            $cost = [int][Math]::Ceiling((7.0 - $script:Fuel) * 8)
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
    $cost = [int][Math]::Ceiling($need * 8)
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
    $rows = New-Object System.Collections.Generic.List[object]
    $rows.Add(@{ Id = 'beam'; Name = 'Beam laser'; Price = 4000; Have = $script:Beam; Note = $(if ($script:Beam) { 'fitted' } else { '' }) })
    $rows.Add(@{ Id = 'dock'; Name = 'Docking computer'; Price = 1500; Have = $script:DockComp; Note = $(if ($script:DockComp) { 'fitted' } else { '' }) })
    $rows.Add(@{ Id = 'shield'; Name = 'Shield booster'; Price = 2500; Have = ($script:ShieldMax -ge 180); Note = $(if ($script:ShieldMax -ge 180) { 'fitted' } else { '' }) })
    $rows.Add(@{ Id = 'gal'; Name = 'Galactic hyperdrive'; Price = 5000; Have = $script:GalDrive; Note = $(if ($script:GalDrive) { 'fitted' } else { '' }) })
    $cargoFull = $script:CargoMax -ge 35
    $rows.Add(@{ Id = 'cargo'; Name = 'Cargo bay +5t'; Price = 400; Have = $cargoFull; Note = "$($script:CargoMax)t" })
    $rows.Add(@{ Id = 'missile'; Name = 'Missile'; Price = 30; Have = ($script:Missiles -ge 4); Note = "$($script:Missiles)/4" })
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
        Write-At 1 2 'Pulse laser is already fitted.' 8 40
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
            if ($r.Have -and $r.Id -ne 'missile') { Say 'Already fitted.'; continue }
            if ($script:Cash -lt [int]$r.Price) { Say 'Not enough credits.'; continue }
            switch ($r.Id) {
                'beam' { $script:Beam = $true; $script:Cash -= 4000; Say 'Beam laser fitted.' }
                'dock' { $script:DockComp = $true; $script:Cash -= 1500; Say 'Docking computer fitted.' }
                'shield' { $script:ShieldMax = 200; $script:Shield = 200; $script:Cash -= 2500; Say 'Shields boosted.' }
                'gal' { $script:GalDrive = $true; $script:Cash -= 5000; Say 'Galactic hyperdrive fitted. Press H on the galactic chart.' }
                'cargo' {
                    if ($script:CargoMax -ge 35) { Say 'Hold is already 35t.' }
                    else { $script:CargoMax += 5; $script:Cash -= 400; Say "Hold is $($script:CargoMax)t." }
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
        if ($script:EdgeDock) { Try-Dock }
        if ($script:EdgeJump) { Try-Jump }
        if ($script:EdgeTarget) { Cycle-Target }
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
    Check ($homeSys.Eco -ge 4) 'home is agricultural'
    $foundInd = $false
    for ($j = 0; $j -lt 256; $j++) {
        if ($j -eq $script:Sys) { continue }
        if ($script:Systems[$j].Eco -le 2 -and (Get-Ly $script:Sys $j) -le 7.0) { $foundInd = $true }
    }
    Check $foundInd 'industrial neighbour in fuel range'
    Refresh-Market
    Check ($script:Market.Count -eq 15) 'market rows'
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
    Check ($text.Contains('SPD')) 'hud speed'
    Check ($text.Contains('FUEL')) 'hud fuel'
    Check ($text.Contains('+--')) 'cockpit corners'
    $nBraille = 0
    foreach ($ch in $script:Buf) {
        $code = [int]$ch
        if ($code -ge 0x2800 -and $code -le 0x28FF) { $nBraille++ }
    }
    Check ($nBraille -ge 10) "braille cells $nBraille"
    $sample = New-Object 'byte[]' 16
    [EliteBraille.Raster]::Plot($sample, 4, 4, 0, 0, 14)
    [EliteBraille.Raster]::Plot($sample, 4, 4, 1, 0, 14)
    $sampleBuf = New-Object 'char[]' 2
    $sampleCol = New-Object 'byte[]' 2
    [EliteBraille.Raster]::Stamp($sample, 4, $sampleBuf, $sampleCol, 2, 0, 1, $script:Pri)
    Check (([int]$sampleBuf[0]) -eq (0x2800 + 0x09)) 'braille dot pattern'
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
