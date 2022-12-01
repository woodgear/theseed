extends KinematicBody

var velocity = Vector3() #动量

var _mouse_motion = Vector2()
var _selected_block = 6

onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

onready var head = $Head
onready var raycast = $Head/RayCast
onready var selected_block_texture = $SelectedBlock
onready var voxel_world = $"../VoxelWorld"
onready var crosshair = $"../PauseMenu/Crosshair"
enum PlayerMode {FLY,NORMAL}
var mode = PlayerMode.NORMAL setget ,get_mode
var super_mode = true
func get_mode() ->String:
	if mode==PlayerMode.FLY:
		return "fly"
	if mode==PlayerMode.NORMAL:
		return "normal"
	return "unknow"
	
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	transform.origin.y=0

func _input(event):
	
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			# 为什么是+=?
			_mouse_motion += event.relative
			#print_debug("axx",_mouse_motion,event.relative)



func _process(_delta):
	# Mouse movement.
	# 不要超过屏幕大小
	_mouse_motion.y = clamp(_mouse_motion.y, -1550, 1550)
	# 当我左右转的时候我们需要转变自己身体的朝向
	self.transform.basis = Basis(Vector3(0,_mouse_motion.x * -0.001 , 0))
	# 当我们上下转的时候，我们只要转变自己的头就行了
	head.transform.basis = Basis(Vector3(_mouse_motion.y * -0.001,0 , 0))
	
	# Block selection.
	var position = raycast.get_collision_point()
	var normal = raycast.get_collision_normal()
	#print_debug("pos",position,"normal",normal)

	if Input.is_action_just_pressed("pick_block"):

		# Block picking.
		# 碰撞点沿着射线方向移动一点(normal是标准的1单位)这样我们的这个点就一定在block内了。
		var block_global_position = (position - normal / 2).floor()
		#var block_global_position = position.floor()

		_selected_block = voxel_world.get_block_global_position(block_global_position)
	else:
		# Block prev/next keys.
		if Input.is_action_just_pressed("prev_block"):
			_selected_block -= 1
		if Input.is_action_just_pressed("next_block"):
			_selected_block += 1
		_selected_block = wrapi(_selected_block, 1, 30)
	# Set the appropriate texture.
	var uv = Chunk.calculate_block_uvs(_selected_block)
	selected_block_texture.texture.region = Rect2(uv[0] * 512, Vector2.ONE * 64)

	# Block breaking/placing.
	if crosshair.visible and raycast.is_colliding():
		var breaking = Input.is_action_just_pressed("break")
		var placing = Input.is_action_just_pressed("place")
		# Either both buttons were pressed or neither are, so stop.
		if breaking == placing:
			return

		if breaking:
			var block_global_position = (position - normal / 2).floor()
			voxel_world.set_block_global_position(block_global_position, 0)
		elif placing:
			var block_global_position = (position + normal / 2).floor()
			voxel_world.set_block_global_position(block_global_position, _selected_block)

func _physics_process_normal(delta):
	# Crouching.
	var crouching = Input.is_action_pressed("crouch")
	if crouching:
		head.transform.origin = Vector3(0, 1.2, 0) # 高度调成1.2m # 设置摄像头的偏移
	else:
		head.transform.origin = Vector3(0, 1.6, 0) # 高度调成1.6m

	# Keyboard movement.
	var movement_vec2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	var movement = transform.basis.xform(Vector3(movement_vec2.x, 0, movement_vec2.y))
	if !crouching:
		movement *= 5

	# Gravity. # 因为重力而下落
	velocity.y -= gravity * delta 
	#warning-ignore:return_value_discarded
	velocity = move_and_slide(Vector3(movement.x, velocity.y, movement.z), Vector3.UP)

	# Jumping, applied next frame.
	if is_on_floor() and Input.is_action_pressed("jump"):
		velocity.y = 5
	pass
	
func _physics_process_watcher(delta):
	# 当左右前后移动时我们需要根据当前的视角方向来进行调整
	var move=Vector3(0,0,0)
	var press_move=false
	var step =30
	if Input.is_action_pressed("move_left"):
		self.move_and_slide(transform.basis.xform(Vector3(-1*step,0,0)),Vector3.UP)
		pass
	if Input.is_action_pressed("move_right"):
		self.move_and_slide(transform.basis.xform(Vector3(1*step,0,0)),Vector3.UP)
		pass
	if Input.is_action_pressed("move_forward"):
		self.move_and_slide(transform.basis.xform(Vector3(0,0,-1*step)),Vector3.UP)
		pass
	if Input.is_action_pressed("move_back"):
		self.move_and_slide(transform.basis.xform(Vector3(0,0,1*step)),Vector3.UP)
		pass
	if Input.is_action_pressed("move_up"):
		self.move_and_slide(Vector3(0,1*step,0),Vector3.UP)
		pass
	if Input.is_action_pressed("move_down"):
		self.move_and_slide(Vector3(0,-1*step,0),Vector3.UP)
		pass
		

#	self.move_and_slide(movement, Vector3.UP)
	pass
	
func _physics_process(delta):
	if Input.is_action_just_pressed("super_mdoe"):
		self.super_mode=!self.super_mode
		pass
	if self.super_mode:
		self._physics_process_watcher(delta)
		pass
	if !self.super_mode:
		self._physics_process_normal(delta)
		pass

#	if mode == PlayerMode.FLY:
#		self._physics_process_fly(delta)
#		pass
#	if mode == PlayerMode.NORMAL:
#		pass
#	pass


func chunk_pos():
	return (transform.origin / Chunk.CHUNK_SIZE).floor()
