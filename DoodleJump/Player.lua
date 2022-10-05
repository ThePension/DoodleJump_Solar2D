Player = {
    velocity = 0.0
    acceleration = 0.0,
    maxVelocity = 5.0
}

function Player:new(o, velocity, acceleration, maxVelocity)
    o = o or {}
    setmetatable( o, self )

    self.__index = self
    self.velocity = velocity
    self.acceleration = acceleration
    self.maxVelocity = maxVelocity

    return o
end

function Player:update(elapsedTime)

end