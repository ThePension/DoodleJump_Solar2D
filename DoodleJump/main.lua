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

-- Set up display groups
local backGroup = display.newGroup()  -- Display group for the background image
local mainGroup = display.newGroup()  -- Display group for the ship, asteroids, lasers, etc.
local uiGroup = display.newGroup()

local score = 0
local died = false
local haveJetpack = false
local arePlatformsMoving = false
 
local objectsTable = {}

local plateformDimensionX = 75
local plateformDimensionY = 13

local player
local gameLoopTimer
local scoreText = display.newText( uiGroup, "Score : " .. score, display.contentCenterX, 20, native.systemFont, 30 )

local gravity = 0.005
local playerVel = 0.0
local playerAcc = 0.0

local playerXVel = 0.0

local maxVel = 7.0

local jetpackSheetOptions =
{
    width = 32,
    height = 64,
    sheetContentWidth  = 128,
    sheetContentHeight  = 192,
    numFrames = 10
}

local sequences_jetpack = {
    -- consecutive frames sequence
    {
        name = "jetpack_animation",
        frames = { 1, 4, 7, 10, 2, 5, 8, 11, 3, 6, 9, 12 },
        time = 800,
        loopCount = 0
    }
}

local sheet_jetpack = graphics.newImageSheet("./resources/jetpack_sheet.png", jetpackSheetOptions )
local jetpack_animation = display.newSprite(mainGroup, sheet_jetpack, sequences_jetpack)

local jetpack

-- Seed the random number generator
math.randomseed(os.time())

-- Load the background
local background = display.newImageRect(backGroup, "./resources/background.png", 320, 512)
background.x = display.contentCenterX
background.y = display.contentCenterY

-- Load the player
player = display.newImageRect( mainGroup, "./resources/player_left.png", 62, 60 )
player.x = display.contentCenterX
player.y = display.contentHeight - 250
physics.addBody( player, "dynamic", { radius=30, isSensor=true } )
player.myName = "player"

-- Hide the status bar
display.setStatusBar( display.HiddenStatusBar )

local function endOfJetpack()
    local gravity = 0.005
    haveJetpack = false
    jetpack_animation.x = display.contentWidth * 2
end

local function createJetpack(offsetStart, offsetEnd)
    jetpack = display.newImageRect(mainGroup, "./resources/jetpack.png", 25, 38)
    jetpack.x = math.random(0 + jetpack.width / 2, display.contentWidth - jetpack.width / 2)
    jetpack.y = math.random(offsetStart, offsetEnd)
    jetpack.myName = "jetpack"
    physics.addBody( jetpack, "static")
    table.insert( objectsTable, jetpack )
    timer.performWithDelay(5000, endOfJetpack)
end

local function createMonster(offsetStart, offsetEnd)
    local newMonster = display.newImageRect(mainGroup, "./resources/monster.png", 60, 80)
    newMonster.x = math.random(0 + newMonster.width / 2, display.contentWidth - newMonster.width / 2)
    newMonster.y = math.random(offsetStart, offsetEnd)
    newMonster.myName = "monster"
    physics.addBody( newMonster, "static")
    table.insert( objectsTable, newMonster )

    newMonster:toBack()
end

local function createSinglePlatform(offsetStart, offsetEnd)
    local newPlatform = display.newImageRect( mainGroup, "./resources/greenplatform.png", plateformDimensionX, plateformDimensionY )
    table.insert( objectsTable, newPlatform )
    physics.addBody( newPlatform, "static")
    newPlatform.myName = "platform"

    newPlatform.x = math.random(newPlatform.width / 2, display.contentWidth - newPlatform.width / 2)
    newPlatform.y = math.random(offsetStart, offsetEnd)

    newPlatform:toBack()
end

local function createRandomEntity(offsetStart, offsetEnd)
    if math.random(0, 50) > 1 or haveJetpack then
        if math.random(0, 20) > 1 or haveJetpack then
            createSinglePlatform(-display.contentHeight / 5, 0)
        else
            createMonster(-display.contentHeight / 5, 0)
        end
    else
        createJetpack(-display.contentHeight / 5, 0)
    end
end

local function initializePlatforms()
    -- Create a platform at the bottom
    local newPlatform = display.newImageRect( mainGroup, "./resources/greenplatform.png", plateformDimensionX, plateformDimensionY)
    table.insert( objectsTable, newPlatform )
    physics.addBody( newPlatform, "static")
    newPlatform.myName = "platform"

    -- Set its position
    newPlatform.x = display.contentCenterX
    newPlatform.y = display.contentHeight - 50

    -- Create 10 random platforms
    for i=1, 10 do
        createSinglePlatform(-display.contentHeight / 4, display.contentHeight)
    end
end

local function updatePlayerPosition()
    -- Update player x position
    player.x = player.x + playerXVel
    
    if not haveJetpack then
        -- Apply basic physic
        playerAcc = playerAcc + gravity
        playerVel = playerVel + playerAcc

        -- Limit the max velocity
        if (playerVel > maxVel) then
            playerVel = maxVel
        elseif (playerVel < -maxVel) then
            playerVel = -maxVel
        end
    else
        -- Apply basic physic
        playerVel = -15
        jetpack_animation.x = player.x + player.width / 2 - 10
        jetpack_animation.y = player.y + player.height / 2 - 10
    end
    
    -- Don't move up the player if platforms are moving
    if(not arePlatformsMoving) then
        player.y = player.y + playerVel
    end

    -- If the player goes offscreen on the right, teleport it on the left
    -- Same from left to right
    if player.x < 0 then
        player.x = display.contentWidth
    elseif player.x > display.contentWidth then
        player.x = 0
    end
end

local function updatePlayerXPosition(event)
    if (event.phase == "down") then
        if (event.keyName == "d") then
            playerXVel = 5
        elseif event.keyName == "a" then
            playerXVel = -5
        end
    elseif event.phase == "up" then
        playerXVel = 0.0
    end
end

local function updateScore()
    scoreText.text = "Score: " .. math.floor(score)
end

local function updatePlatforms()
    -- If the height of the player is above the middle of the screen
    if (player.y < display.contentHeight / 2 and playerVel < 0) then
        score = score - playerVel / 10
        updateScore()
        -- Move down the platforms by the inverse of the player velocity
        arePlatformsMoving = true
        for i = #objectsTable, 1, -1 do
            local currentPlatform = objectsTable[i]
            currentPlatform.y = currentPlatform.y - playerVel
        end
    else
        arePlatformsMoving = false
    end
end

local function onCollision(event)
    if (event.phase == "began") then
        local obj1 = event.object1
        local obj2 = event.object2

        if (
            (
                (obj1.myName == "player" and obj2.myName == "platform" ) 
                or
                (obj1.myName == "platform" and obj2.myName == "player")
            )
            and playerVel >= 0
        )
        then
            local collidedPlatform

            if obj1.myName == "platform" then
                collidedPlatform = obj1
            else
                collidedPlatform = obj2
            end

            if (player.y  + player.height / 2 < collidedPlatform.y) then
                playerAcc = 0.0
                playerVel = -maxVel
            end
        elseif 
            (obj1.myName == "jetpack" and obj2.myName == "player" ) 
            or
            (obj1.myName == "player" and obj2.myName == "jetpack")
            then

            jetpack.hasCollided = true

            jetpack_animation:play()

            haveJetpack = true
        elseif
                (obj1.myName == "monster" and obj2.myName == "player" ) 
                or
                (obj1.myName == "player" and obj2.myName == "monster")
                then
            if obj1.myName == "monster" then
                obj1.hasCollided = true
            else
                obj2.hasCollided = true
            end
        end
    end
end

local function checkPlayerDied()
    return player.y - player.height / 2 > display.contentHeight
end

local function applyCollisionActions()
    for i = #objectsTable, 1, -1 do
        local currentObject = objectsTable[i]

        if currentObject.hasCollided then
            if currentObject.myName == "monster" then
                display.remove(currentObject)
                table.remove(objectsTable, i)

                score = 0
                updateScore()

                createRandomEntity(-display.contentHeight / 5, 0)
            elseif currentObject.myName == "jetpack" then
                display.remove(jetpack)
                table.remove(objectsTable, i)
                jetpack.hasCollided = false

                createRandomEntity(-display.contentHeight / 5, 0)
            end
        end
    end
end

local function gameLoop()
    died = checkPlayerDied()

    if not died then
        updatePlayerPosition()
        updatePlatforms()
        applyCollisionActions()
    else
        -- print("died")
    end

    -- Remove platforms which have drifted off screen
    for i = #objectsTable, 1, -1 do
        local currentPlatform = objectsTable[i]
 
        if (currentPlatform.y - currentPlatform.height / 2 > display.contentHeight)
        then
            display.remove(currentPlatform)
            table.remove(objectsTable, i)
            
            createRandomEntity(-display.contentHeight / 5, 0)
        end
    end
end

initializePlatforms()

gameLoopTimer = timer.performWithDelay(1000 / 60, gameLoop, 0)

Runtime:addEventListener("key", updatePlayerXPosition)
Runtime:addEventListener("collision", onCollision)