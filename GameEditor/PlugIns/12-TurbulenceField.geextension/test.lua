print('text: '..tostring(text))
print('SKScene class: '..tostring(SKScene))
print('scene: '..tostring(scene))
print('nil_value: '..tostring(nil_value))

-- Create a test sprite
local sprite = SKSpriteNode.spriteNodeWithImageNamed('Spaceship')
sprite.name = 'test'
sprite.runAction(SKAction.repeatActionForever(SKAction.rotateByAngleDuration(5, 1)))
scene.addChild(sprite)
