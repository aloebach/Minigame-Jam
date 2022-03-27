--[[
	MobWare Minigames
	
	Author: Andrew Loebach
	loebach@gmail.com

--This main program will reference the Minigames, and run the minigames by calling their functions to run the minigame's logic

To-Do's:
-Add references to frame timers -> minigames should use frame timers so that the difficulty scales properly
-Add story-linked transition animations and polish main game interface
-Add opening sequence
-Add ending sequence
-Add menu including bonus games / features
-Define custom menu
]]

-- debug variables:
-- Set "DEBUG_GAME" variable to the name of the minigame you want to test and it'll be chosen every time
--DEBUG_GAME = "bird_hunt"
--SET_FRAME_RATE = 40

-- Import CoreLibs
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/frameTimer" 
import "CoreLibs/nineslice"
import "CoreLibs/ui"
import "CoreLibs/crank"
import "CoreLibs/easing"

-- Import supporting libraries
import 'lib/AnimatedSprite' --used to generate animations from spritesheet
import 'lib/mobware_ui'

-- Import list of minigames
import 'minigame_list' --> names of minigames can now be referenced in via "minigame_list"

-- Defining gfx as shorthand for playdate graphics API
local gfx <const> = playdate.graphics

--Define local variables to be used outside of the minigames
local GameState
local game
local score
local lives
local time_scaler
local minigame
local GAME_WINNING_SCORE = 5 --score that, when reached, will congratulate player and show credits

-- seed the RNG so that calls to random are always random
local s, ms = playdate.getSecondsSinceEpoch()
math.randomseed(ms,s)

function Mobware_load()
	score = 0
	lives = 3

	-- initialize spritesheets for transitions
	playdate_spritesheet = gfx.imagetable.new("images/playdate_spinning")
	demon_spritesheet = gfx.imagetable.new("images/demon_big")
	
	GameState = 'start' -- variable for game state

    -- the state of our game; can be any of the following:
    -- 1. 'start' (the beginning of the game, before first minigame)
    -- 2. 'transition' (the state in between minigames)
    -- 3. 'initialize' (the next minigame is chosen and initialized)
    -- 4. 'play' (minigame is being played)
    -- 5. 'credits' (the player has reached a score to get the ending which displays the game's credits)
    -- 6. 'game_over' (the game is over, display score, ready for restart)

    -- Set initial FPS to 20, which will gradually increase to a maximum of 40
	time_scaler = 0 --initial value for variable used to speed up game speed over time
	playdate.display.setRefreshRate( SET_FRAME_RATE or math.min(20 + time_scaler, 40) )


	-- initialize fonts
	mobware_font_S = gfx.font.new("fonts/Mobware_S")
	mobware_font_M = gfx.font.new("fonts/Mobware_M")
	mobware_font_L = gfx.font.new("fonts/Mobware_L")
	mobware_default_font = mobware_font_M
	gfx.setFont(mobware_default_font)

end

-- Call load function to initialize and start game 
Mobware_load()


function playdate.update()


	if GameState == 'start' then
		-- Run file to play opening
		--playdate.file.run('opening') -- HERE IS WHERE THE GAME INTRO WILL BE, BUT STILL ISN'T FINISHED
		GameState = 'initialize'


	elseif GameState == 'initialize' then 
		-- Take a random game from our list of games, or take DEBUG_GAME if provided
		local game_num = math.random(#minigame_list)
		minigame = DEBUG_GAME or minigame_list[game_num]
		local game_file = 'Minigames/' .. minigame .. '/' .. minigame -- build minigame file path 
		
		-- Clean up graphical environment for minigame
		gfx.clear( gfx.kColorWhite )
		gfx.sprite.removeAll()

		-- Load minigame package:
		_minigame = {}	-- create new environment for minigame
	    setmetatable(_minigame, {__index = _G}) --> creating minigame's own namespace
	    game = _minigame
		_minigame.import = function(a) playdate.file.run( a, _minigame) end -- special import function
		game = playdate.file.run(game_file, _minigame) --loads minigame package to "game" variable
		GameState = 'play' 


	elseif GameState == 'play' then
		game_result = game.update()
		--> minigame update function should return 1 if the player won, and 0 if the player lost

		-- If minigame is over
		if game_result == 0 or game_result == 1 or game_result == 2 then
			GameState = 'transition'

			print('Minigame return value: ', game_result)

			-- Reset default display values, clear sprites, and collect garbage
			minigame_cleanup()

			if game_result == 0 then
				lives = lives - 1
				if lives == 0 then GameState = 'game_over' end
			elseif game_result == 1 then
				score = score + 1
				-- TO-DO: ADD MINIGAME_WON GAMESTATE with TRIUMPHANT SOUND EFFECT AND LOGIC FOR HAPPY ANIMATION!

				--if the player's score is sufficiently high, show credits
				if score == GAME_WINNING_SCORE then GameState = 'credits' end

				-- increase game speed after each successfull minigame:
				time_scaler = time_scaler + 1
			end

			-- Set up PlayDate sprite for transition animation
			demon_sprite = AnimatedSprite.new( demon_spritesheet )
			demon_sprite:addState("animate", nil, nil, {tickStep = 3}, true)
			demon_sprite:moveTo(200, 120)
			demon_sprite:setZIndex(1)

			playdate_sprite = AnimatedSprite.new( playdate_spritesheet )
			playdate_sprite:addState("animate", 1, 18, {tickStep = 1, yoyo = true, loop = 2}, true)
			playdate_sprite:moveTo(200, 120)
			playdate_sprite:setZIndex(2)

			timer = playdate.timer.new(2100)
			-- playdate.easingFunctions.outCubic(t, b, c, d) 
			-- playdate.easingFunctions.outCubic(timer.currentTime, 120, 120, d) 

		end


	elseif GameState == 'transition' then
		-- Play transition animation between minigames

		-- TO-DO: UPDATE WITH ANTAGONIST ANIMATIONS FOR VICTORY AND DEFEAT, 
		-- AND REPLACE ROTATION WITH PRERENDERED VERSION TO AVOID SLOWDOWN ON PLAYDATE HARDWARE

		-- update timer
		playdate.timer.updateTimers()

		--[[NEW CODE
		print("time:",timer.currentTime)
		local new_y
		if timer.currentTime <= 10000 then
			new_y = playdate.easingFunctions.outCubic(timer.currentTime, 120, 120, 1000) 
		else
			new_y = playdate.easingFunctions.outCubic(timer.currentTime, 240, -120, 1000) 
		end
		playdate_sprite:moveTo(200, new_y)
		--END NEW CODE]]

		if timer.currentTime >= 2100 then GameState = 'initialize' end



	elseif GameState == 'game_over' then
		-- TO-DO: UPDATE WITH GAME OVER SEQUENCE

  		-- Display game over screen
		gfx.clear(gfx.kColorBlack)
		gfx.setFont(mobware_font_M)
		mobware.print("GAME OVER!")  
        playdate.wait(4000)

		--reload game from the beginning
		Mobware_load()  


	elseif GameState == 'credits' then
		-- Play credits sequence

		minigame_cleanup()

		-- load "credits" as minigame
		_minigame = {}	-- create new environment for minigame
	    setmetatable(_minigame, {__index = _G}) --> creating credits' own namespace
	    game = _minigame
		_minigame.import = function(a) playdate.file.run( a, _minigame) end -- special import function
		game = playdate.file.run('credits', _minigame) --loads minigame package to "game" variable

		-- change gamestate to 'play' so our other functions can run the minigame logic within our "credits" script
		GameState = 'play' 		

	end


-- Rendering code:
	if GameState == 'start' or GameState == 'transition' then
		-- animate sprites on transition screen
		gfx.sprite.update() -- updates all sprites

		-- display UI for transition
		--gfx.setFont(mobware_font_M)
		--mobware.print("Mobware Minigames!", 15, 15)

		gfx.setFont(mobware_font_S)
		--gfx.drawText("score: " .. score, 10, 50)
		mobware.print("score: " .. score, 10, 20)
		--gfx.drawText("lives: " .. lives, 10, 65)
		mobware.print("lives: " .. lives, 10, 65)

		-- reset font to default
		gfx.setFont(mobware_default_font)
	end

end


-- Callback functions for Playdate inputs:

--if GameState == 'play' then

-- Callback functions for crank
function playdate.cranked(change, acceleratedChange) if game and game.cranked then game.cranked(change, acceleratedChange) end end
function playdate.crankDocked() if game and game.crankDocked then game.crankDocked() end end
function playdate.crankUndocked() if game and game.crankDocked then game.crankUndocked() end end

-- Callback functdions for button presses:
function playdate.AButtonDown() if game and game.AButtonDown then game.AButtonDown() end end
function playdate.AButtonHeld() if game and game.AButtonHeld then game.AButtonHeld() end end
function playdate.AButtonUp() if game and game.AButtonUp then game.AButtonUp() end end
function playdate.BButtonDown() if game and game.BButtonDown then game.BButtonDown() end end
function playdate.BButtonHeld() if game and game.BButtonHeld then game.BButtonHeld() end end
function playdate.BButtonUp() if game and game.BButtonUp then game.BButtonUp() end end
function playdate.downButtonDown() if game and game.downButtonDown then game.downButtonDown() end end
function playdate.downButtonUp() if game and game.downButtonUp then game.downButtonUp() end end
function playdate.leftButtonDown() if game and game.leftButtonDown then game.leftButtonDown() end end
function playdate.leftButtonUp() if game and game.leftButtonUp then game.leftButtonUp() end end
function playdate.rightButtonDown() if game and game.rightButtonDown then game.rightButtonDown() end end
function playdate.rightButtonUp() if game and game.rightButtonUp then game.rightButtonUp() end end
function playdate.upButtonDown() if game and game.upButtonDown then game.upButtonDown() end end
function playdate.upButtonUp() if game and game.upButtonUp then game.upButtonUp() end end


-- <TEST CODE FOR MESSING AROUND WITH MENU OPTIONS>
-- Add age selection
playdate.getSystemMenu():addOptionsMenuItem(
    'age',
    { '0-18', '18-30', '30+' },
    function(selectedOption)
        print(selectedOption)
    end
)
-- Add option to return to main menu
playdate.getSystemMenu():addMenuItem(
    'MW Menu',
    function()
    	-- Reset default display values, clear sprites, and collect garbage
		minigame_cleanup()
        GameState = "start"
    end
)
-- <END TEST CODE>


-- For debugging
function  playdate.keyPressed(key)
	if GameState == 'play' then pcall(game.keyPressed, game, key) end 
	
	--Debugging code for memory management
	print("Memory used: " .. math.floor(collectgarbage("count")))

	if key == "c" then print('Sprite count: ', gfx.sprite.spriteCount() ) end
end


function minigame_cleanup()
	-- Reset values for main game and clean up assets/memory
	gfx.clear()
	playdate.display.setRefreshRate( SET_FRAME_RATE or math.min(20 + time_scaler, 40) )
	gfx.setColor(gfx.kColorBlack)
	gfx.setBackgroundColor(gfx.kColorWhite)
	gfx.sprite.removeAll()
	gfx.setDrawOffset(0, 0)

	-- set font used in transition screen if I'm displaying text
	gfx.setFont(mobware_default_font)

	--trigger garbage collection to clear up memory
	game = nil
	_minigame = nil
	collectgarbage("collect")	
end
