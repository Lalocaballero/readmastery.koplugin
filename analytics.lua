local _ = require("gettext")
local Icons = require("icons")

local Analytics = {}

function Analytics:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Session Stats (Level 3)
function Analytics:getSessionStats(session)
    if not session or not session.is_active then
        return nil
    end
    
    local duration = os.time() - session.start_time
    local minutes = math.floor(duration / 60)
    local hours = math.floor(minutes / 60)
    local remaining_minutes = minutes % 60
    
    return {
        duration_seconds = duration,
        duration_formatted = string.format("%d:%02d:%02d", hours, remaining_minutes, duration % 60),
        pages_read = session.pages_read,
        book = session.current_book,
        format = session.current_format,
        pages_per_hour = minutes > 0 and math.floor((session.pages_read / minutes) * 60) or 0,
    }
end

-- Heatmap (Level 5)
function Analytics:getHeatmap()
    local heatmap = {}
    local max_pages = 1
    
    for i = 6, 0, -1 do
        local date = os.date("%Y-%m-%d", os.time() - (i * 86400))
        local day_name = os.date("%A", os.time() - (i * 86400))  -- Full day name
        local short_day = os.date("%a", os.time() - (i * 86400)) -- Short day name
        local pages = self.core:getDailyPages(date)
        
        if pages > max_pages then
            max_pages = pages
        end
        
        table.insert(heatmap, {
            date = date,
            day = day_name,
            short_day = short_day,
            pages = pages,
        })
    end
    
    -- Calculate intensity levels (0-4)
    for _, day in ipairs(heatmap) do
        if day.pages == 0 then
            day.intensity = 0
        else
            day.intensity = math.min(4, math.floor((day.pages / max_pages) * 4) + 1)
        end
    end
    
    return heatmap, max_pages
end

function Analytics:renderHeatmapText()
    local heatmap, max_pages = self:getHeatmap()
    
    local lines = {}
    table.insert(lines, Icons.CHART .. " 7-Day Reading Heatmap")
    table.insert(lines, "")
    table.insert(lines, "Day        Pages  Intensity")
    table.insert(lines, string.rep("-", 35))
    
    for _, day in ipairs(heatmap) do
        -- Create intensity bar
        local bar = Icons.heatmapLevel(day.intensity)
        
        -- Format: "Monday     123   #####"
        local day_padded = day.short_day .. string.rep(" ", 10 - #day.short_day)
        local pages_str = tostring(day.pages)
        local pages_padded = string.rep(" ", 5 - #pages_str) .. pages_str
        
        local line = day_padded .. pages_padded .. "  [" .. bar .. "]"
        
        -- Add marker for today
        if day.date == os.date("%Y-%m-%d") then
            line = line .. " <-- Today"
        end
        
        table.insert(lines, line)
    end
    
    table.insert(lines, string.rep("-", 35))
    table.insert(lines, "")
    table.insert(lines, "Legend:")
    table.insert(lines, "  [.....] = No reading")
    table.insert(lines, "  [#....] = Light")
    table.insert(lines, "  [##...] = Moderate")
    table.insert(lines, "  [###..] = Good")
    table.insert(lines, "  [#####] = Excellent")
    table.insert(lines, "")
    table.insert(lines, "Peak this week: " .. max_pages .. " pages")
    
    return table.concat(lines, "\n")
end

-- Weekly Digest (Level 7)
function Analytics:getWeeklyDigest()
    local total_pages, active_days = self.core:getWeeklyPages()
    
    local rank = self:calculateWeeklyRank(total_pages, active_days)
    
    return {
        total_pages = total_pages,
        active_days = active_days,
        total_days = 7,
        average_pages_per_day = active_days > 0 and math.floor(total_pages / active_days) or 0,
        rank = rank.name,
        rank_icon = rank.icon,
    }
end

function Analytics:calculateWeeklyRank(pages, days)
    local ranks = {
        { min_pages = 500, min_days = 6, name = "Titan", icon = Icons.RANK_TITAN },
        { min_pages = 300, min_days = 5, name = "Scholar", icon = Icons.RANK_SCHOLAR },
        { min_pages = 150, min_days = 4, name = "Apprentice", icon = Icons.RANK_APPRENTICE },
        { min_pages = 50, min_days = 2, name = "Novice", icon = Icons.RANK_NOVICE },
        { min_pages = 0, min_days = 0, name = "Beginner", icon = Icons.RANK_BEGINNER },
    }
    
    for _, rank in ipairs(ranks) do
        if pages >= rank.min_pages and days >= rank.min_days then
            return rank
        end
    end
    
    return ranks[#ranks]
end

-- Speed Analytics (Level 10)
function Analytics:getSpeedAnalytics()
    local sessions = self.core.data.sessions
    local total_pages = 0
    local total_minutes = 0
    
    for _, session in ipairs(sessions) do
        total_pages = total_pages + (session.pages or 0)
        total_minutes = total_minutes + math.floor((session.duration or 0) / 60)
    end
    
    local avg_pages_per_hour = total_minutes > 0 and math.floor((total_pages / total_minutes) * 60) or 0
    local reading_style = self:categorizeReadingStyle(avg_pages_per_hour)
    
    return {
        total_sessions = #sessions,
        total_pages = total_pages,
        total_hours = math.floor(total_minutes / 60),
        average_pages_per_hour = avg_pages_per_hour,
        style = reading_style.name,
        style_icon = reading_style.icon,
        style_description = reading_style.description,
    }
end

function Analytics:categorizeReadingStyle(pages_per_hour)
    local styles = {
        { min = 60, name = "Speed Reader", icon = Icons.SPEED_FAST, description = "You devour books at lightning speed!" },
        { min = 40, name = "Swift Reader", icon = Icons.SPEED_SWIFT, description = "You read at a brisk, efficient pace." },
        { min = 25, name = "Balanced Reader", icon = Icons.SPEED_BALANCED, description = "You maintain a steady, comfortable pace." },
        { min = 15, name = "Thoughtful Reader", icon = Icons.SPEED_THOUGHTFUL, description = "You take time to absorb every detail." },
        { min = 0, name = "Deep Reader", icon = Icons.SPEED_DEEP, description = "You savor each page, reading deeply and slowly." },
    }
    
    for _, style in ipairs(styles) do
        if pages_per_hour >= style.min then
            return style
        end
    end
    
    return styles[#styles]
end

-- Book Completion Rate (Level 15)
function Analytics:getCompletionRate()
    local started = self.core:getBooksStarted()
    local completed = self.core:getBooksCompleted()
    
    local percentage = started > 0 and math.floor((completed / started) * 100) or 0
    local rank = self:calculateCompletionistRank(percentage, completed)
    
    return {
        books_started = started,
        books_completed = completed,
        completion_percentage = percentage,
        rank = rank.name,
        rank_icon = rank.icon,
    }
end

function Analytics:calculateCompletionistRank(percentage, completed)
    local ranks = {
        { min_pct = 80, min_books = 10, name = "Completionist Master", icon = Icons.TROPHY },
        { min_pct = 60, min_books = 5, name = "Dedicated Finisher", icon = Icons.MEDAL },
        { min_pct = 40, min_books = 3, name = "Steady Reader", icon = Icons.STAR },
        { min_pct = 20, min_books = 1, name = "Book Sampler", icon = Icons.BOOK },
        { min_pct = 0, min_books = 0, name = "Explorer", icon = Icons.TARGET },
    }
    
    for _, rank in ipairs(ranks) do
        if percentage >= rank.min_pct and completed >= rank.min_books then
            return rank
        end
    end
    
    return ranks[#ranks]
end

-- Hall of Fame (Level 20)
function Analytics:getHallOfFame()
    return {
        longest_streak = self.core:getLongestStreak(),
        most_pages_single_day = self.core.data.most_pages_single_day,
        lifetime_pages = self.core:getLifetimePages(),
        books_completed = self.core:getBooksCompleted(),
        total_xp = self.core:getXP(),
        current_level = self.core:getLevel(),
        achievements_unlocked = self.core.data.achievements,
        member_since = os.date("%Y-%m-%d", self.core.data.created_at),
    }
end

return Analytics