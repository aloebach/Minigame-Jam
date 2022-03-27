--[[
	Pulp loader

	function for loading and running a Pulp pdx file from within Lua

	Author: Andrew Loebach
	loebach@gmail.com

	special thanks to Shaun Inman for all of the help!
]]

--[[
-- callback functions:
playdate.AButtonDown()
playdate.AButtonUp()
playdate.BButtonDown()
playdate.BButtonUp()
playdate.upButtonDown()
playdate.upButtonUp()
playdate.downButtonDown()
playdate.downButtonUp()
playdate.leftButtonDown()
playdate.leftButtonUp()
playdate.rightButtonDown()
playdate.rightButtonUp()
playdate.update()
playdate.keyPressed(key)
]]

-- Reference code from Shaun:
local callbacks = {
    'AButtonDown',
    'AButtonUp',
    'BButtonDown',
    'BButtonUp',
    'upButtonDown',
    'upButtonUp',
    'downButtonDown',
    'downButtonUp',
    'leftButtonDown',
    'leftButtonUp',
    'rightButtonDown',
    'rightButtonUp',
    'update',
    'keyPressed',
    'debugDraw',
}

local inner = {}
local outer = {}
function playdate.update()
    if playdate.buttonJustPressed('a') then
        -- backup main game's current callbacks
        for i=1,#callbacks do
            local callback = callbacks[i]
            outer[callback] = playdate[callback]
            inner[callback] = nil
        end
        
        -- load minigame        
        playdate.file.run('inner')
        
        -- store minigame's callbacks
        for i=1,#callbacks do
            local callback = callbacks[i]
            inner[callback] = playdate[callback]
        end
        
        -- restore main game's callbacks
        for i=1,#callbacks do
            local callback = callbacks[i]
            playdate[callback] = outer[callback]
        end
    end
    
    -- call minigame's update
    if inner.update then
        inner.update()
    end
end