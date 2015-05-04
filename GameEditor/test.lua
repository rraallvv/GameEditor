print(text)
print(SKSpriteNode)
print(scene)
print(nil_value)

-- Load the required frameworks
objc.import('AVKit')
print(objc.AVPlayerView:alloc():init())

-- Create a test sprite
local sprite = objc.SKSpriteNode:spriteNodeWithImageNamed('Spaceship')
sprite:setName('test')
sprite:runAction(objc.SKAction:repeatActionForever(objc.SKAction:rotateByAngle_duration(5, 1)))
scene:addChild(sprite)
