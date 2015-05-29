function createNodeAtPosition(position)
	local color = NSColor.redColor()
	local size = {width=100, height=100}
	local sprite = SKSpriteNode.spriteNodeWithColorSize(color, size)
	sprite.position = position
	return sprite
end
