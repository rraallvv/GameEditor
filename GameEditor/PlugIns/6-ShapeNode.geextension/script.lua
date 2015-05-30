function createNodeAtPosition(position)
    local rect = {x=-50, y=-50, width=100, height=100}
    local shape = SKShapeNode.shapeNodeWithRect(rect)
	shape.position = position
	return shape
end
