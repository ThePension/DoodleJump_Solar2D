-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

local composer = require( "composer" )
 
local scene = composer.newScene()

----------------------
-- Global variables --
----------------------
local physics = require("physics")
physics.start()
physics.setGravity(0, 0)

-- Set up display groups
local backGroup
local mainGroup
local uiGroup

local score = 0
local died = false
local haveJetpack = false
local arePlatformsMoving = false
local mouseX = 0
 
local objectsTable = {}

local plateformDimensionX = 60
local plateformDimensionY = 13

local player
local gameLoopTimer
local scoreText

local gravity = 0.005
local playerVel = 0.0
local playerAcc = 0.0
local playerDir = -1 -- 1 = left, -1 = right

local playerXVel = 0.0

local maxVel = 6.0

local bulletSpeed = -4.0

local monster2SheetOptions = {
    width = 78,
    height = 37,
    sheetContentWidth = 312,
    sheetContentHeight = 74,
    numFrames = 8
}

local sequences_monster2 = {
    -- consecutive frames sequence
    {
        name = "monster2_animation",
        frames = { 1, 2, 3, 4, 5 },
        time = 800,
        loopCount = 0
    }
}

local sheet_monster2

local jetpack_flip_offset = 0
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
        frames = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
        time = 800,
        loopCount = 0
    }
}

local sheet_jetpack
local jetpack_animation

local jetpack

local background

local function endGame()
    composer.setVariable( "finalScore", score )
    composer.gotoScene( "highscores", { time=800, effect="crossFade" } )
end

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
    local monster2_animation = display.newSprite(mainGroup, sheet_monster2, sequences_monster2)
    monster2_animation.myName = "monster"

    -- local newMonster = display.newImageRect(mainGroup, "./resources/monster.png", 60, 80)
    -- newMonster.x = math.random(0 + newMonster.width / 2, display.contentWidth - newMonster.width / 2)
    -- newMonster.y = math.random(offsetStart, offsetEnd)
    -- newMonster.myName = "monster"
    monster2_animation.x = math.random(0 + monster2_animation.width / 2, display.contentWidth - monster2_animation.width / 2)
    monster2_animation.y = math.random(offsetStart, offsetEnd)
    physics.addBody( monster2_animation, "static", {isSensor=true})
    table.insert( objectsTable, monster2_animation )

    monster2_animation:play()

    monster2_animation:toBack()
end

local function playerShoot()
    local bullet = display.newImageRect(mainGroup, "./resources/bullet.png", 16, 16)
    bullet.x = player.x
    bullet.y = player.y - player.height / 2
    bullet.myName = "bullet"
    physics.addBody(bullet, "dynamic", {isSensor=true})
    -- table.insert(objectsTable, bullet) -- Useless
    
    transition.to( bullet, { y=-40, x=mouseX, time=500,
            onComplete = function() display.remove( bullet ) end
        } )
end

local function createSinglePlatform(offsetStart, offsetEnd)
    local newPlatform

    -- 20% chance to create a blue platform (moving platform)
    if (math.random(0, 100) > 10) then
        newPlatform = display.newImageRect( mainGroup, "./resources/greenplatform.png", plateformDimensionX, plateformDimensionY )
        newPlatform.x = math.random(newPlatform.width / 2, display.contentWidth - newPlatform.width / 2)
    else
        newPlatform = display.newImageRect( mainGroup, "./resources/blueplatform.png", plateformDimensionX, plateformDimensionY )
        newPlatform.x = display.contentCenterX
        newPlatform.isMoving = true

        if(math.random(0, 1)) == 0 then
            newPlatform.movingXVel = -1
        else
            newPlatform.movingXVel = 1
        end
    end

    table.insert( objectsTable, newPlatform )
    physics.addBody( newPlatform, "dynamic", {isSensor=true})
    newPlatform.myName = "platform"

    newPlatform.y = math.random(offsetStart, offsetEnd)

    newPlatform:toBack()

    -- 5% chance of adding a spring
    if math.random(0, 100) <= 5 then
        local spring = display.newImageRect(mainGroup, "./resources/compact_spring.png", 15, 10)
        -- table.insert(objectsTable, spring)
        physics.addBody(spring, "dynamic", {isSensor=true})
        spring.myName = "spring"

        spring.x = math.random(newPlatform.x - newPlatform.width / 3, newPlatform.x + newPlatform.width / 3)
        spring.y = newPlatform.y - newPlatform.height / 2 - spring.height / 2 + 3
        spring:toBack()

        newPlatform.attachedObject = spring
    end
end

local function createRandomEntity(offsetStart, offsetEnd)
    if math.random(0, 500) > 1 or haveJetpack then
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
    physics.addBody( newPlatform, "dynamic")
    newPlatform.myName = "platform"

    -- Set its position
    newPlatform.x = display.contentCenterX
    newPlatform.y = display.contentHeight - 50

    -- Create 10 random platforms
    for i=1, 20 do
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
        end
    else
        -- Apply basic physic
        playerVel = -15
        jetpack_animation.x = player.x + player.width / 2 - 10 + jetpack_flip_offset
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
            if player.xScale == 1 then
                player.xScale = -1
                jetpack_animation.xScale = -1
                jetpack_flip_offset = -player.width / 2 - jetpack_animation.width / 2 + 5
            end
        elseif event.keyName == "a" then
            playerXVel = -5
            if player.xScale == -1 then
                player.xScale = 1
                jetpack_animation.xScale = 1
                jetpack_flip_offset = 0
            end
        elseif event.keyName == "space" then
            playerShoot()
        end
    elseif event.phase == "up" then
        playerXVel = 0.0
    end
end

local function updateScore()
    scoreText.text = "Score: " .. math.floor(score)
end

local function updatePlatforms()
    for i = #objectsTable, 1, -1 do
        local currentObject = objectsTable[i]

        if currentObject.myName == "platform" then
            currentPlatform = currentObject
            if(currentPlatform.isMoving) then
                if(currentPlatform.x > display.contentWidth - currentPlatform.width / 2) then
                    print("right border")
                    currentPlatform.movingXVel = -1
                elseif (currentPlatform.x < currentPlatform.width / 2) then
                    print("left border")
                    currentPlatform.movingXVel = 1
                end

                currentPlatform.x = currentPlatform.x + currentPlatform.movingXVel
            end
        end
    end


    -- If the height of the player is above the middle of the screen
    if (player.y < display.contentHeight / 2 and playerVel < 0) then
        score = score - playerVel / 10
        updateScore()
        -- Move down the platforms by the inverse of the player velocity
        arePlatformsMoving = true
        for i = #objectsTable, 1, -1 do
            local currentPlatform = objectsTable[i]
            currentPlatform.y = currentPlatform.y - playerVel

            -- Also update the attached object if exists
            if not (currentPlatform.attachedObject == nil) then
                currentPlatform.attachedObject.y = currentPlatform.y - currentPlatform.height / 2 - currentPlatform.attachedObject.height / 2 + 3
            end
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
            obj1.myName == "platform" and obj2.myName == "platform"
        ) then
            obj1.hasCollidedWithAnotherPlatform = true
        end

        if (
            (
                (obj1.myName == "bullet" and obj2.myName == "monster" ) 
                or
                (obj1.myName == "monster" and obj2.myName == "bullet")
            )
        )
        then
            obj1.hasCollided = true
            obj2.hasCollided = true
        end

        if (
            (
                (obj1.myName == "player" and obj2.myName == "spring")
                or
                (obj1.myName == "spring" and obj2.myName == "player")
            )
            and playerVel >= 0
        ) then
            playerAcc = 0.0
            playerVel = -15

            transition.to( player, { rotation=360, time=800, transition=easing.linear,  
                onComplete = function() player:rotate(-360) end
            } )
        end

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
            local collidedMonster
            if obj1.myName == "monster" then
                collidedMonster = obj1
            end

            collidedMonster.hasCollided = true

            -- Check if the was above the monster (jump on head)
            if((player.y + player.height / 2 < collidedMonster.y) 
                and playerVel >= 0)
            then
                playerAcc = 0.0
                playerVel = -maxVel
            else
                player.monsterCollision = true
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
                createRandomEntity(-display.contentHeight / 5, 0)
            elseif currentObject.myName == "bullet" then
                display.remove(currentObject)
            elseif currentObject.myName == "jetpack" then
                display.remove(jetpack)
                table.remove(objectsTable, i)
                jetpack = nil

                createRandomEntity(-display.contentHeight / 5, 0)
            end
        elseif currentObject.hasCollidedWithAnotherPlatform then
            display.remove(currentObject.attachedObject)
            display.remove(currentObject)
            table.remove(objectsTable, i)
            createSinglePlatform(-display.contentHeight / 5, 0)
        end
    end
end

local function onClick(event)
    -- Keep track of the mouse x coordinate
    mouseX = event.x
end

local function gameLoop()
    died = checkPlayerDied() or player.monsterCollision

    if not died then
        updatePlayerPosition()
        updatePlatforms()
        applyCollisionActions()
        -- print(#objectsTable) -- Checking object numbers
    else
        endGame()
    end

    -- Remove platforms which have drifted off screen
    for i = #objectsTable, 1, -1 do
        local currentPlatform = objectsTable[i]
 
        if (currentPlatform.y - currentPlatform.height / 2 > display.contentHeight)
        then
            display.remove(currentPlatform.attachedObject)
            display.remove(currentPlatform)
            table.remove(objectsTable, i)
            
            if not (currentPlatform.myName == "spring") then
                createRandomEntity(-display.contentHeight / 5, 0)
            end
        end
    end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen
 
    physics.pause()  -- Temporarily pause the physics engine

    -- Set up display groups
    backGroup = display.newGroup()  -- Display group for the background image
    sceneGroup:insert( backGroup )
    mainGroup = display.newGroup()  -- Display group for the ship, asteroids, lasers, etc.
    sceneGroup:insert( mainGroup )
    uiGroup = display.newGroup()
    sceneGroup:insert( uiGroup )

    scoreText = display.newText( uiGroup, "Score : " .. score, display.contentCenterX, 20, native.systemFont, 30 )

    sheet_monster2 = graphics.newImageSheet("./resources/monster2_sheet.png", monster2SheetOptions )

    sheet_jetpack = graphics.newImageSheet("./resources/jetpack_sheet.png", jetpackSheetOptions )
    jetpack_animation = display.newSprite(mainGroup, sheet_jetpack, sequences_jetpack)

    background = display.newImageRect(backGroup, "./resources/background.png", 320, 512)
    background.x = display.contentCenterX
    background.y = display.contentCenterY

    -- Load the player
    player = display.newImageRect( mainGroup, "./resources/player_left.png", 62, 60 )
    player.x = display.contentCenterX
    player.y = display.contentHeight - 250
    physics.addBody( player, "dynamic", { radius=30, isSensor=true } )
    player.myName = "player"

    initializePlatforms()
end

-- show()
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
        physics.start()
        Runtime:addEventListener("key", updatePlayerXPosition)
        Runtime:addEventListener("collision", onCollision)
        Runtime:addEventListener("mouse", onClick)
        gameLoopTimer = timer.performWithDelay(1000 / 60, gameLoop, 0)
    end
end

-- hide()
function scene:hide( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
        timer.cancel( gameLoopTimer )
 
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
        Runtime:removeEventListener("key", updatePlayerXPosition)
        Runtime:removeEventListener("collision", onCollision)
        Runtime:removeEventListener("mouse", onClick)
        physics.pause()
        composer.removeScene( "game" )
    end
end

-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene