-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
--[[
	This example expands on the last
]]
-----------------------------------------------------------------------------------------




-- Hide status bar
display.setStatusBar( display.HiddenStatusBar )

-- Import Sprite
require( "sprite" )


local alien_hoard_array = {}

-----------------------------------------------------------------------------------------
-- Set up level 
-----------------------------------------------------------------------------------------
local function setup_level()
	alien_hoard_array = {4,4,4,4, 11,11,11,11, 15,15,15,15}
end
setup_level()
-----------------------------------------------------------------------------------------








--------------------------------------------------------------------------------
-- set up rcorona
-- Use this to test with a real device sending accelerometer data to the simulator
--------------------------------------------------------------------------------
if system.getInfo("environment") == "simulator" then
	local rcorona = require("rcorona")
	rcorona.startServer(8181)
end
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------
-- Check if two boxes overlap
local function hitTestObjects( obj1, obj2 )
        return obj1.contentBounds.xMin < obj2.contentBounds.xMax
			and obj1.contentBounds.xMax > obj2.contentBounds.xMin
			and obj1.contentBounds.yMin < obj2.contentBounds.yMax
			and obj1.contentBounds.yMax > obj2.contentBounds.yMin
end

-- get the distance between two points
local function distanceBetween( point1, point2 ) 
	local xfactor = point2.x-point1.x ; local yfactor = point2.y-point1.y
	local distanceBetween = math.sqrt((xfactor*xfactor) + (yfactor*yfactor))
	return distanceBetween
end

-- get the angle between two points
local function angleBetween ( srcObj, dstObj )
 	local xDist = dstObj.x-srcObj.x ; local yDist = dstObj.y-srcObj.y
	local angleBetween = math.deg( math.atan( yDist/xDist ) )
	if ( srcObj.x < dstObj.x ) then angleBetween = angleBetween+90 else angleBetween = angleBetween-90 end
	return angleBetween
end
--------------------------------------------------------------------------------






-----------------------------------------------------------------------------------------
-- Set up a sprite  sheet for the alien. 
-----------------------------------------------------------------------------------------
local explosion_sheet = sprite.newSpriteSheet( "explosion_43FR.png", 93, 100 ) 
local explosion_set = sprite.newSpriteSet( explosion_sheet, 1, 40)
sprite.add( explosion_set, "explosion", 1, 40, 30, 1 )

local alien_sheet = sprite.newSpriteSheet( "Alien_32.png", 32, 32 )
local alien_set = sprite.newSpriteSet( alien_sheet, 1, 25 )
sprite.add( alien_set, "alien", 1, 25, 1000, 0 )

local ship_sheet = sprite.newSpriteSheet( "ships_1.png", 36, 50 )
local ship_set = sprite.newSpriteSet( ship_sheet, 1, 5 )
sprite.add( ship_set, "ship", 1, 5, 1000, 0 )

local missile_sheet = sprite.newSpriteSheet( "missile_1.png", 6, 22 )
local missile_set = sprite.newSpriteSet( missile_sheet, 1, 1 )
sprite.add( missile_set, "missile", 1, 1, 1000, 0 )

local bomb_sheet = sprite.newSpriteSheet( "bomb.png", 3, 4 )
local bomb_set = sprite.newSpriteSet( bomb_sheet, 1, 1 )
sprite.add( bomb_set, "bomb", 1, 1, 1000, 0 )
-----------------------------------------------------------------------------------------












-----------------------------------------------------------------------------------------
-- These functions acts as a factory to make explosion sprites and remove them.
-----------------------------------------------------------------------------------------
-- This function removes the explosion
local function remove_explosion( event )
	local phase = event.phase
	if phase == "loop" then 
		local explosion = event.target
		explosion:removeEventListener( "sprite", remove_explosion )
		explosion:removeSelf()
	end 
end 

-- This function makes a new explosion.
local function make_explosion( x, y )
	local explosion = sprite.newSprite( explosion_set )
	
	explosion.x = x
	explosion.y = y
	
	explosion:prepare()
	explosion:play()
	explosion:addEventListener( "sprite", remove_explosion )

	return explosion
end
-----------------------------------------------------------------------------------------








-----------------------------------------------------------------------------------------
-- Make Bombs
-----------------------------------------------------------------------------------------
local bomb_array = {}

local function remove_bomb( bomb )
	transition.cancel( bomb.transition )
	bomb:removeSelf()
end 

local function make_bomb( x, y ) 
	local bomb = sprite.newSprite( bomb_set )
	
	bomb.x = x
	bomb.y = y 
	
	print( ">>>> Bomb y:", y  )
	
	bomb.transition = transition.to( bomb, {y=y+480, time=2000, onComplete=remove_bomb} )
	
	table.insert( bomb_array, bomb ) 
	
	return bomb 
end 
-----------------------------------------------------------------------------------------









-----------------------------------------------------------------------------------------
-- Make aliens
-----------------------------------------------------------------------------------------
local end_y = display.contentHeight + 40
local alien_array = {}
local touch_alien

local function remove_alien( alien )
	local transitions = alien.transitions
	for i = 1, #transitions, 1 do 
		transition.cancel( transitions[i] )
	end 
	
	local index = table.indexOf( alien_array, alien )
	
	timer.cancel( alien.bomb_timer )
	table.remove( alien_array, index )
	alien:removeSelf()
end 


local function alien_complete( target ) 
	local alien = target
	local index = table.indexOf( alien_array, alien )
	timer.cancel( alien.bomb_timer )
	table.remove ( alien_array, index )
	alien:removeSelf()
end 

local function make_alien()
	local alien
	
	if #alien_hoard_array > 0 then 
		local f = alien_hoard_array[1]
		table.remove( alien_hoard_array, 1 )
		alien = sprite.newSprite( alien_set )
		alien.currentFrame = f
	else 
		print( "game over" )
		return 
	end
	
	alien.x = 32
	alien.y = -32
	local transition_time = math.random( 5000, 10000 )
	
	local transitions = {}
	table.insert( transitions, transition.to( alien, {y=50, time=1000} ) )
	table.insert( transitions, transition.to( alien, {x=288, time=1200, delay=1000} ) )
	table.insert( transitions, transition.to( alien, {y=150, time=1000, delay=2200} ) )
	table.insert( transitions, transition.to( alien, {x=32, time=1200, delay=3200} ) )
	table.insert( transitions, transition.to( alien, {y=end_y, time=1400, delay=4400, onComplete=alien_complete} ) )
	
	alien.transitions = transitions
	table.insert( alien_array, alien )
	
	local function create_timer_callback( alien )
		local alien = alien
		return function()
			make_bomb( alien.x, alien.y )
		end
	end
	
	local bomb_delay = math.random(1000, 2000)
	
	alien.bomb_timer = timer.performWithDelay( bomb_delay, create_timer_callback( alien ), -1 )
	
end 

local alien_timer = timer.performWithDelay( 1000, make_alien, -1 )
-----------------------------------------------------------------------------------------


























-----------------------------------------------------------------------------------------
-- Make Base
-----------------------------------------------------------------------------------------

local vx_text = display.newText("0", 100, 100, native.systemFont, 32 )


local ship = sprite.newSprite( ship_set )
ship.currentFrame = 3

ship.x = display.contentCenterX
ship.y = display.contentHeight - 32

local max_speed = 4
local accel = 2.5
local right_limit = display.contentWidth - 20
local left_limit = 20
local vx = 0

local function on_accelerometer( event )
	local xGravity = event.xGravity
	
	vx = vx + xGravity * accel
	
	-- Set a limit on vx. This if limits vx to no more than abs max_speed
	if vx > max_speed then 
		vx = max_speed
	elseif vx < -max_speed then 
		vx = -max_speed
	end 
end

local function move_ship() 
	ship.x = ship.x + vx
	
	vx_text.text = math.round( vx )
	
	if vx < -2 then 
		ship.currentFrame = 2
	elseif vx < -3 then 
		ship.currentFrame = 1
	elseif vx > 2 then 
		ship.currentFrame = 4
	elseif vx > 3 then 
		ship.currentFrame = 5
	else 
		ship.currentFrame = 3
	end 
	
	if ship.x > right_limit then 
		ship.x = right_limit
		vx = 0
	elseif ship.x < left_limit then 
		ship.x = left_limit
		vx = 0
	end 
end 

Runtime:addEventListener( "accelerometer", on_accelerometer )
-----------------------------------------------------------------------------------------




-----------------------------------------------------------------------------------------
-- Make Missiles
-----------------------------------------------------------------------------------------
local missile_text = display.newText( "0", 0, 0, native.systemFont, 32 )
missile_text.x = 100
missile_text.y = 164

local missile_array = {}


local function remove_missile( missile )
	local index = table.indexOf( missile_array, missile )
	
	transition.cancel( missile.transition )
	
	table.remove( missile_array, index )
	missile:removeSelf()
end 





local function check_missile_collision()
	for m = 1, #missile_array, 1 do 
		for a = 1, #alien_array, 1 do 
			
			local missile = missile_array[m]
			local alien = alien_array[a]
			
			if missile ~= nil and alien ~= nil then 
				
				local bounds = alien.contentBounds
				
				local xMin = bounds.xMin
				local xMax = bounds.xMax
				local yMin = bounds.yMin
				local yMax = bounds.yMax
				
				-- print( m, xMin, xMax, yMin, yMax, missile, missile.x, missile.y )
				
				if missile.x >= xMin 
					and missile.x <= xMax 
					and missile.y >= yMin 
					and missile.y <= yMax then 
					make_explosion( alien.x, alien.y )
					remove_missile( missile )
					remove_alien( alien )
				end 
			end
		end 
	end 
end


local function drop_bomb()
	local alien = alien_array[ math.random( #alien_array )]
	print( "***** ", alien )
	make_bomb( alien.x, alien.y )
end 

-- local bomb_timer = timer.performWithDelay( 1200, drop_bomb, -1 )

local function on_frame( event ) 
	missile_text.text = #missile_array .. " " .. #alien_array
	
	check_missile_collision()
	move_ship()
end 

Runtime:addEventListener( "enterFrame", on_frame )

local function make_missile( x, y )
	local missile = sprite.newSprite( missile_set )
	missile.x = x
	missile.y = y 
	
	missile.transition = transition.to( missile, {y=0, time=1000, onComplete=remove_missile} )
	table.insert( missile_array, missile )
end 

local function on_touch( event ) 
	local phase = event.phase 
	if phase == "began" then 
		make_missile( ship.x, ship.y - 30 )
	end 
end 

Runtime:addEventListener( "touch", on_touch )


-----------------------------------------------------------------------------------------
















