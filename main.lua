--[[
	MobWare Minigames - Minigame jam edition!
		
	Author: Andrew Loebach
	loebach@gmail.com

--This main program will reference the Minigames, and run the minigames by calling their functions to run the minigame's logic
]]

-- debug variables:
-- Set "DEBUG_GAME" variable to the name of the minigame you want to test and it'll be chosen every time
--DEBUG_GAME = "rock_paper_scissors"
--DEBUG_GAME = "key_to_success"
--DEBUG_GAME = "solo_pong"
--DEBUG_GAME = "labyrinth"
--DEBUG_GAME = 'Dashing_Adventurer'
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

	-- initialize sprites for transitions
	background_image = gfx.image.new("images/game_jam_background") 
	drummer_spritesheet = gfx.imagetable.new("images/drummer")
	fan_spritesheet = gfx.imagetable.new("images/jam_fan")
		
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
	
	--> initialize music
	jam_music = playdate.sound.fileplayer.new('sounds/jam')

end

-- Call load function to initialize and start game 
Mobware_load()



function playdate.update()


	if GameState == 'start' then
		-- Run file to play opening
		--GameState = 'initialize'
		
		-- load transition animation
		GameState = 'transition' 
		load_transition()


	elseif GameState == 'initialize' then 
		-- Take a random game from our list of games, or take DEBUG_GAME if provided
		local game_num = math.random(#minigame_list)
		minigame = DEBUG_GAME or minigame_list[game_num]
		local game_file = 'Minigames/' .. minigame .. '/' .. minigame -- build minigame file path 
		
		-- Clean up graphical environment for minigame
		minigame_cleanup()

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

				-- increase game speed after each successful minigame:
				time_scaler = time_scaler + 1
			end
	
			-- initialize transition graphics and music if we're entering the transition gamestate		
			if GameState == 'transition' then
				load_transition()
			end

		end


	elseif GameState == 'transition' then
		-- Play transition animation between minigames

		-- update timer
		playdate.timer.updateTimers()

		if timer.currentTime >= 2100 then 
			GameState = 'initialize' 
			jam_music:stop()
		end


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

		jam_music:stop() -- stop transition music
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
		gfx.setFont(mobware_font_M)
		mobware.print("Minigame Jam!", 185, 200)

		gfx.setFont(mobware_font_S)
		mobware.print("score: " .. score, 20, 20)
		mobware.print("lives: " .. lives, 20, 65)

		-- reset font to default
		gfx.setFont(mobware_default_font)
	end

end


-- Callback functions for Playdate inputs:

-- Callback functions for crank
function playdate.cranked(change, acceleratedChange) if game and game.cranked then game.cranked(change, acceleratedChange) end end
function playdate.crankDocked() if game and game.crankDocked then game.crankDocked() end end
function playdate.crankUndocked() if game and game.crankDocked then game.crankUndocked() end end

-- Callback functions for button presses:
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


function minigame_cleanup()
	--NOTE: UNLOADING MINIGAME BEOFRE CLEARING GRAPHICS AND SPRITES TO ENSURE NO CALLBACK FUNCTIONS ARE CALLED IN THE MEANTIME
	-- unload minigame package
	game = nil
	_minigame = nil

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
	collectgarbage("collect")	
end


function load_transition()
	
	-- set background to black for transition
	gfx.setBackgroundColor(gfx.kColorBlack)
	
	local game_jam_background = gfx.sprite.new()
	game_jam_background:setImage( background_image )
	game_jam_background:moveTo(200, 120)
	game_jam_background:addSprite()
	
	-- Set up pixel drummer sprite for transition animation
	drummer_sprite = AnimatedSprite.new( drummer_spritesheet )
	drummer_sprite:addState("animate", nil, nil, {tickStep = 1}, true)
	drummer_sprite:moveTo(280, 96)
	drummer_sprite:setZIndex(2)
	
	-- Set up sprites for fans! 1 fan for each successfull minigame!
	for i=1, score do
		local fan_sprite = AnimatedSprite.new( fan_spritesheet )
		fan_sprite:addState("animate", nil, nil, {tickStep = 1}, true)
		--fan_sprite:moveTo( math.random(0, 150) , math.random(123, 143) )
		fan_sprite:moveTo( math.random(0, 130) , math.random(150, 170) )
		fan_sprite:setZIndex(fan_sprite.y)
	end

	-- play transition music
		--> music speeds up as your score increases
	local music_rate = math.min(1 + time_scaler / 20, 2)
	jam_music:setRate(music_rate)
	jam_music:play(0) -- play jam music (loop after it's finished) 
	
	timer = playdate.timer.new(2100)
end	