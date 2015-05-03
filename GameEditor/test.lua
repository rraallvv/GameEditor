-- Test the bridge
local ffi = require('ffi')
ffi.cdef[[
	void import(const char *framework);
]]

function objc:import(framework)
	ffi.C.import(framework)
end

objc:import("AVKit")
print(objc.AVPlayerView:alloc():init())

-- Create a test sprite
local sprite = objc.SKSpriteNode:spriteNodeWithImageNamed('Spaceship')
sprite:setName('test')
sprite:runAction(objc.SKAction:repeatActionForever(objc.SKAction:rotateByAngle_duration(5, 1)))
scene:addChild(sprite)
