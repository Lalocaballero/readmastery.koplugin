--[[
    Icon definitions for ReadMastery
    Pure ASCII - guaranteed to work on all Kindle devices
]]

local Icons = {}

-- Main UI Icons - Pure ASCII
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

-- Helper function to build star ratings (e.g., for intensity)
function Icons.starRating(value, max)
    max = max or 5
    local stars = ""
    for i = 1, max do
        if i <= value then
            stars = stars .. Icons.STAR
        else
            stars = stars .. Icons.STAR_EMPTY
        end
    end
    return stars
end

-- Heatmap intensity characters (for vertical bars)
function Icons.heatmapBar(intensity, max_height)
    max_height = max_height or 5
    local height = math.floor((intensity / 4) * max_height)
    return string.rep(Icons.PROGRESS_FULL, height) .. string.rep(Icons.PROGRESS_EMPTY, max_height - height)
end

-- Vertical heatmap bar (returns characters for each level)
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