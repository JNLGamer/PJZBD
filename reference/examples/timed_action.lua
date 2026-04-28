-- Custom timed action example
-- Place at: media/lua/client/TimedActions/MyMod_ScavengeAction.lua
--
-- Usage:
--   ISTimedActionQueue.add(MyMod_ScavengeAction:new(getPlayer(), targetContainer))

MyMod_ScavengeAction = ISBaseTimedAction:derive("MyMod_ScavengeAction")

function MyMod_ScavengeAction:new(character, container)
    local o = ISBaseTimedAction.new(self, character)
    o.character  = character
    o.container  = container
    o.maxTime    = 150        -- ~5 seconds
    o.stopOnWalk = true
    o.stopOnRun  = true
    return o
end

function MyMod_ScavengeAction:isValid()
    -- Cancel the action if the container disappeared
    return self.container ~= nil
end

function MyMod_ScavengeAction:start()
    self:setActionAnim("Loot")
end

function MyMod_ScavengeAction:update()
    -- Keep facing the container during the action
    local sq = self.container:getSquare()
    if sq then
        self.character:faceLocation(sq:getX(), sq:getY())
    end
end

function MyMod_ScavengeAction:perform()
    -- Action completed successfully — give player a random item
    local inv = self.character:getInventory()
    local roll = ZombRand(100)
    if roll < 30 then
        inv:AddItem("Base.Nails")
    elseif roll < 60 then
        inv:AddItem("Base.Plank")
    end

    -- Always call super last
    ISBaseTimedAction.perform(self)
end

function MyMod_ScavengeAction:stop()
    ISBaseTimedAction.stop(self)
end
