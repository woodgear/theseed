class_name TerrainGenerator
extends Resource

# Can't be "Chunk.CHUNK_SIZE" due to cyclic dependency issues.
# https://github.com/godotengine/godot/issues/21461
const CHUNK_SIZE = 8


static func empty():
	return {}


static func random_blocks():
	var random_data = {}
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			for z in range(CHUNK_SIZE):
				var vec = Vector3(x, y, z) # TODO: Vector3i
				if randf() < 0.01:
					random_data[vec] = randi() % 29 + 1
	return random_data


static func flat(chunk_position):
	var data = {}

	if chunk_position.y != -10:
		return data

	for x in range(CHUNK_SIZE):
		for z in range(CHUNK_SIZE):
			data[Vector3(x, 0, z)] = 3
			data[Vector3(x, 1, z)] = 3
			data[Vector3(x, 2, z)] = 3

	return data


# Used to create the project icon.
static func origin_grass(chunk_position):
	if chunk_position == Vector3.ZERO:
		return {Vector3.ZERO: 3}

	return {}
