class_name TerrainGenerator
extends Resource

# Can't be "Chunk.CHUNK_SIZE" due to cyclic dependency issues.
# https://github.com/godotengine/godot/issues/21461
const CHUNK_SIZE = 9


static func empty():
	return {}


#给定一个chunk的pos,填满这个chunk
static func fill(chunk_position,id):
	var data = {}

#	if chunk_position.y != -100:
#		return data
	if id==null:	
		id=randi() % 29 + 1
	
	# 设置每个chunk最底层的cube
	for x in range(CHUNK_SIZE):
		for z in range(CHUNK_SIZE):
			data[Vector3(x, 0, z)] = id

			#print("x ",x," z ",z)
			if x==0:
				#data[Vector3(x, 3, z)] = 3
			#	data[Vector3(x, 4, z)] = 3
				pass

			if z==0:
			#	data[Vector3(x, 3, z)] = 3
			#	data[Vector3(x, 4, z)] = 3
				pass
				
			#data[Vector3(x, 0, z)] = 3
			#data[Vector3(x, 1, z)] = 3
			#data[Vector3(x, 2, z)] = 3

	return data


# Used to create the project icon.
static func origin_grass(chunk_position):
	if chunk_position == Vector3.ZERO:
		return {Vector3.ZERO: 3}

	return {}
