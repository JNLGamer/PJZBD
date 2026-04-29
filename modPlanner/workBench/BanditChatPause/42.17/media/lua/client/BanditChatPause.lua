--[[
BanditChatPause — pauses the game in singleplayer when the chat is open.

Patches:
  ISChat:focus()   → setGameSpeed(0) (pause) when SP
  ISChat:unfocus() → setGameSpeed(1) (resume) when SP

Watchdog: an OnTick check resumes the game if chat lost focus without
unfocus being called (e.g., player tabs out, hits Escape, etc.).
]]

if not ISChat then return end

local BanditChatPause = {}
BanditChatPause.wasPausedByUs = false

local function isSinglePlayer()
    return not isClient() and not isServer()
end

-- Wrap ISChat:focus
local original_focus = ISChat.focus
function ISChat:focus(...)
    local result = original_focus(self, ...)
    if isSinglePlayer() then
        if getGameSpeed() ~= 0 then
            setGameSpeed(0)
            BanditChatPause.wasPausedByUs = true
        end
    end
    return result
end

-- Wrap ISChat:unfocus
local original_unfocus = ISChat.unfocus
function ISChat:unfocus(...)
    local result = original_unfocus(self, ...)
    if isSinglePlayer() and BanditChatPause.wasPausedByUs then
        setGameSpeed(1)
        BanditChatPause.wasPausedByUs = false
    end
    return result
end

-- Watchdog: if chat is no longer focused but we're still paused by us,
-- restore game speed. Catches edge cases where unfocus is bypassed.
local function watchdog()
    if not isSinglePlayer() then return end
    if not BanditChatPause.wasPausedByUs then return end
    if not ISChat.focused then
        if getGameSpeed() == 0 then
            setGameSpeed(1)
        end
        BanditChatPause.wasPausedByUs = false
    end
end

Events.OnTick.Add(watchdog)

-- Expose for debugging
_G.BanditChatPause = BanditChatPause
