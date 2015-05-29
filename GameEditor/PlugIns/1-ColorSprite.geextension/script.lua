function addNodeAtPosition(position)
	print(position.x, position.y)
	local color = NSColor.redColor()
	local size = {width=100, height=100}
	local sprite = SKSpriteNode.spriteNodeWithColorSize(color, size)
	sprite.position = position
	print(scene)
	scene.addChild(sprite)
end
