-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

----------------------
-- Global variables --
----------------------
local physics = require( "physics" )
physics.start()
physics.setGravity( 0, 0 )

local score = 0
local died = false
local arePlatformsMoving = false
 
local platformsTable = {}
local aliensTables = {}

local player
local gameLoopTimer
local scoreText

local gravity = 0.005
local playerVel = 0.0
local playerAcc = 0.0

local playerXVel = 0.0

local maxVel = 7.0

-- Set up display groups
local backGroup = display.newGroup()  -- Display group for the background image
local mainGroup = display.newGroup()  -- Display group for the ship, asteroids, lasers, etc.

-- Seed the random number generator
math.randomseed(os.time())

-- Load the background
local background = display.newImageRect(backGroup, "./resources/background.png", 320, 512)
background.x = display.contentCenterX
background.y = display.contentCenterY

-- Load the player
player = display.newImageRect( mainGroup, "./resources/player_right.png", 62, 60 )
player.x = display.contentCenterX
player.y = display.contentHeight - 250
physics.addBody( player, "dynamic", { radius=30, isSensor=true } )
player.myName = "player"

-- Hide the status bar
display.setStatusBar( display.HiddenStatusBar )

local function createSinglePlatform(yOffset, randomHeightFactor)
    local newPlatform = display.newImageRect( mainGroup, "./resources/platform.png", 75, 13 )
    table.insert( platformsTable, newPlatform )
    physics.addBody( newPlatform, "static")
    newPlatform.myName = "platform"

    newPlatform.x = math.random(newPlatform.width / 2, display.contentWidth - newPlatform.width / 2)
    newPlatform.y = math.random(0, (display.contentHeight - newPlatform.height) * randomHeightFactor) + yOffset
end

local function initializePlatforms()
    -- Create a platform at the bottom
    local newPlatform = display.newImageRect( mainGroup, "./resources/platform.png", 150, 25 )
    table.insert( platformsTable, newPlatform )
    physics.addBody( newPlatform, "static")
    newPlatform.myName = "platform"

    newPlatform.x = display.contentCenterX
    newPlatform.y = display.contentHeight - 50

    for i=1, 10 do
        createSinglePlatform(0, 1)
    end
end

local function updatePlayerYPosition()
    playerAcc = playerAcc + gravity
    playerVel = playerVel + playerAcc

    if (playerVel > maxVel) then
        playerVel = maxVel
    elseif (playerVel < -maxVel) then
        playerVel = -maxVel
    end

    if(not arePlatformsMoving) then
        player.y = player.y + playerVel
    end

    print(playerXVel)
    player.x = player.x + playerXVel

    if player.x < 0 then
        player.x = display.contentWidth
    elseif player.x > display.contentWidth then
        player.x = 0
    end
end

local function updatePlayerXPosition(event)
    if ( event.phase == "down" ) then
        if ( event.keyName == "d" ) then
            playerXVel = 5
        elseif event.keyName == "a" then
            playerXVel = -5
        end
    elseif event.phase == "up" then
        playerXVel = 0.0
    end
end

local function updatePlatforms()
    if (player.y < display.contentHeight / 2 and playerVel < 0) then
        arePlatformsMoving = true
        for i = #platformsTable, 1, -1 do
            local currentPlatform = platformsTable[i]

            currentPlatform.y = currentPlatform.y - playerVel
        end
    else
        arePlatformsMoving = false
    end

end

local function onCollision( event )
    if ( event.phase == "began" ) then
 
        local obj1 = event.object1
        local obj2 = event.object2

        if ( (( obj1.myName == "player" and obj2.myName == "platform" ) or
             ( obj1.myName == "platform" and obj2.myName == "player" ))
            and playerVel >= 0)
        then
            playerAcc = 0.0
            playerVel = -maxVel
        end
    end
end

local function gameLoop()
    updatePlayerYPosition()
    updatePlatforms()

    -- Remove platforms which have drifted off screen
    for i = #platformsTable, 1, -1 do
        local currentPlatform = platformsTable[i]
 
        if ( currentPlatform.y > display.contentHeight + 100)
        then
            display.remove( currentPlatform )
            table.remove( platformsTable, i )
            createSinglePlatform(-display.contentHeight / 4, 0.5)
        end
    end
end

initializePlatforms()

gameLoopTimer = timer.performWithDelay( 1000 / 60, gameLoop, 0 )

Runtime:addEventListener("key", updatePlayerXPosition)
Runtime:addEventListener("collision", onCollision)