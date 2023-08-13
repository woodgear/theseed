extends Node
# This file manages the creation and deletion of Chunks.

const CHUNK_MIDPOINT = Vector3(0.5, 0.5, 0.5) * Chunk.CHUNK_SIZE
const CHUNK_END_SIZE = Chunk.CHUNK_SIZE - 1

var effective_render_distance = 5
var _old_player_chunk = Vector3() # TODO: Vector3i

var _generating = true
var _deleting = false

var _chunks = {}


onready var player = $"../Player"


func _ready():
	var chunk = Chunk.new()
	chunk.connect("chunk_init_ready", self, "_on_first_chunk_ready")
	chunk.init_chunk=true
	var chunk_position = Vector3(0, 0, 0)
	# 创建初始chunk
	_chunks[chunk_position] = chunk
	self.add_child(chunk)

func _on_first_chunk_ready():
	print_debug("first chunk ready")
	var chunk=get_node(str(Vector3(0,0,0)))
	var cube_in_chunk=Vector3(Chunk.CHUNK_SIZE/2.0,1.8,Chunk.CHUNK_SIZE/2.0)
	var new_pos=get_global_position_of_block_base(Vector3(0,0,0),cube_in_chunk)
	var out = player.move_and_collide(new_pos)
	print("new pos",new_pos,cube_in_chunk,out)
	player.transform.origin=new_pos
	
	pass
	
func _process(_delta):

	#if _deleting or player_chunk != _old_player_chunk:
	#	_delete_far_away_chunks(player_chunk)
	#	_generating = true
	if not _generating:
		return
	var base = Vector3(0, 0, 0)
	# Check existing chunks within range. If it doesn't exist, create it.
	# 创建chunk,y代表高度 当面朝北的时候 x是左右 向右增加  z代表前后 向后增加 绘制顺序是x,y,z
	# 也是最左面 最前面的chunk开始绘制
	
	for x in range(base.x - effective_render_distance, base.x + effective_render_distance):
		for y in range(base.y - effective_render_distance, base.y + effective_render_distance):
			for z in range(base.z - effective_render_distance, base.z + effective_render_distance):
				var chunk_position = Vector3(x,y,z)
				if _chunks.has(chunk_position):
					continue
				var chunk = Chunk.new()
				chunk.chunk_position = chunk_position
				_chunks[chunk_position] = chunk
				#print_debug("add",chunk_position)
				self.add_child(chunk)
				return


# 给定全局坐标,获取这个坐标的cube
func get_block_global_position(block_global_position):
	var chunk_position = (block_global_position / Chunk.CHUNK_SIZE).floor()
	if _chunks.has(chunk_position):
		var chunk = _chunks[chunk_position]
		var sub_position = block_global_position.posmod(Chunk.CHUNK_SIZE)
		#print_debug("cp ",chunk_position," sp ",sub_position)
		if chunk.data.has(sub_position):
			return chunk.data[sub_position]
	return 0

# 给定chunk和subpos,获取这个cube的全局坐标
func get_global_position_of_block_base(chunk,sub):
	if !_chunks.has(chunk):
		return Vector3(100,100,100)
	return chunk*Chunk.CHUNK_SIZE+(sub)


# 给定全局坐标,设置这个坐标的cube
func set_block_global_position(block_global_position, block_id):
	var chunk_position = (block_global_position / Chunk.CHUNK_SIZE).floor()
	var chunk = _chunks[chunk_position]
	var sub_position = block_global_position.posmod(Chunk.CHUNK_SIZE)
	if block_id == 0 or block_id==null:
		chunk.data.erase(sub_position)
	else:
		chunk.data[sub_position] = block_id
	chunk.regenerate()
	return
	# We also might need to regenerate some neighboring chunks.
	if Chunk.is_block_transparent(block_id):
		if sub_position.x == 0:
			_chunks[chunk_position + Vector3.LEFT].regenerate()
		elif sub_position.x == CHUNK_END_SIZE:
			_chunks[chunk_position + Vector3.RIGHT].regenerate()
		if sub_position.z == 0:
			_chunks[chunk_position + Vector3.FORWARD].regenerate()
		elif sub_position.z == CHUNK_END_SIZE:
			_chunks[chunk_position + Vector3.BACK].regenerate()
		if sub_position.y == 0:
			_chunks[chunk_position + Vector3.DOWN].regenerate()
		elif sub_position.y == CHUNK_END_SIZE:
			_chunks[chunk_position + Vector3.UP].regenerate()


func clean_up():
	for chunk_position_key in _chunks.keys():
		var thread = _chunks[chunk_position_key]._thread
		if thread:
			thread.wait_to_finish()
	_chunks = {}
	set_process(false)
	for c in get_children():
		c.free()

