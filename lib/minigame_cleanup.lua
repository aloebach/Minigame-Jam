--[[
	minigame cleanup
]]
function minigame_cleanup(game, _env)
	gfx.clear()
	playdate.display.setRefreshRate( math.min(20 * time_scaler), 50 )
	gfx.sprite.removeAll()
	
	--trigger garbage collection to clear up memory
	game = nil
	_env = nil
	collectgarbage("collect")
end