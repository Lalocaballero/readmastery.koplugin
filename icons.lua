--[[
    Icon definitions for ReadMastery
    Pure ASCII - guaranteed to work on all Kindle devices
]]

local Icons = {}

-- Main UI Icons
Icons.STAR = "*"
Icons.STAR_EMPTY = "."
Icons.FIRE = "~"
Icons.CHECK = "[x]"
Icons.CROSS = "[ ]"
Icons.LOCK = "[#]"
Icons.UNLOCK = "[o]"
Icons.TROPHY = "[T]"
Icons.MEDAL = "[M]"
Icons.CROWN = "[K]"
Icons.BOOK = "[B]"
Icons.BOOKS = "[BB]"
Icons.PAGE = "[P]"
Icons.CHART = "[=]"
Icons.CALENDAR = "[C]"
Icons.CLOCK = "[t]"
Icons.LIGHTNING = "!"
Icons.HEART = "<3"
Icons.DIAMOND = "<>"
Icons.CIRCLE = "(o)"
Icons.CIRCLE_EMPTY = "( )"
Icons.SQUARE = "[#]"
Icons.SQUARE_EMPTY = "[ ]"
Icons.ARROW_UP = "^"
Icons.ARROW_RIGHT = ">"
Icons.ARROW_DOWN = "v"
Icons.GEAR = "[*]"
Icons.INFO = "(i)"
Icons.WARNING = "/!\\"
Icons.SNOWFLAKE = "[F]"
Icons.SUN = "(sun)"
Icons.MOON = "(moon)"
Icons.TARGET = "(+)"

-- Tier Icons
Icons.TIER_BRONZE = "(B)"
Icons.TIER_SILVER = "(S)"
Icons.TIER_GOLD = "(G)"
Icons.TIER_PLATINUM = "(P)"

-- Tier names for display
Icons.TIER_NAMES = {
    bronze = "Bronze",
    silver = "Silver",
    gold = "Gold",
    platinum = "Platinum",
}

-- Progress bar characters
Icons.PROGRESS_FULL = "#"
Icons.PROGRESS_HIGH = "#"
Icons.PROGRESS_MED = "="
Icons.PROGRESS_LOW = "-"
Icons.PROGRESS_EMPTY = "."

-- Achievement category icons
Icons.CAT_HABIT = "[H]"
Icons.CAT_SESSION = "[S]"
Icons.CAT_DISCOVERY = "[D]"
Icons.CAT_MILESTONE = "[M]"

-- Achievement specific icons
Icons.ACH_EARLY_BIRD = "(EB)"
Icons.ACH_NIGHT_OWL = "(NO)"
Icons.ACH_WEEKEND = "(WW)"
Icons.ACH_CENTURION = "(CT)"
Icons.ACH_MARATHON = "(MR)"
Icons.ACH_SPRINT = "(SP)"
Icons.ACH_EXPLORER = "(EX)"
Icons.ACH_BOOK_SLAYER = "(BS)"
Icons.ACH_PAPERBACK = "(PH)"
Icons.ACH_BIBLIOPHILE = "(BF)"
Icons.ACH_LEGEND = "(LL)"

-- Rank icons
Icons.RANK_TITAN = "[TITAN]"
Icons.RANK_SCHOLAR = "[SCHOLAR]"
Icons.RANK_APPRENTICE = "[APPR]"
Icons.RANK_NOVICE = "[NOV]"
Icons.RANK_BEGINNER = "[BEG]"

-- Speed style icons
Icons.SPEED_FAST = ">>>"
Icons.SPEED_SWIFT = ">>"
Icons.SPEED_BALANCED = "><"
Icons.SPEED_THOUGHTFUL = "..."
Icons.SPEED_DEEP = "<<<"

-- Helper function to build progress bars
function Icons.progressBar(percentage, width)
    width = width or 20
    local filled = math.floor((percentage / 100) * width)
    local empty = width - filled
    
    return "[" .. string.rep(Icons.PROGRESS_FULL, filled) 
               .. string.rep(Icons.PROGRESS_EMPTY, empty) .. "]"
end

-- Helper function to get tier icon
function Icons.getTierIcon(tier)
    local tier_icons = {
        bronze = Icons.TIER_BRONZE,
        silver = Icons.TIER_SILVER,
        gold = Icons.TIER_GOLD,
        platinum = Icons.TIER_PLATINUM,
    }
    return tier_icons[tier] or Icons.TIER_BRONZE
end

-- Helper function to get tier name
function Icons.getTierName(tier)
    return Icons.TIER_NAMES[tier] or "Bronze"
end

-- Heatmap intensity characters
function Icons.heatmapLevel(intensity)
    local levels = {
        [0] = ".....",
        [1] = "#....",
        [2] = "##...",
        [3] = "###..",
        [4] = "#####",
    }
    return levels[intensity] or levels[0]
end

return Icons