extends Node3D

@onready var voxel = $VoxelTerrain

var peer = ENetMultiplayerPeer.new()
@export var player_scene : PackedScene
	
func _ready():
	multiplayer.peer_disconnected.connect(del_player)
	
func _on_fire_hit(hit_pos) -> void:
	var tool = voxel.get_voxel_tool()
	print(hit_pos)
	tool.set_mode(VoxelTool.MODE_REMOVE)
	tool.do_sphere(hit_pos, 1)

func _on_join_pressed():
	print("join")
	var ip = $CanvasLayer/host_ip.get_text()
	#ip = "127.0.0.1"
	peer.create_client(ip, 2080)
	multiplayer.multiplayer_peer = peer
	$CanvasLayer.hide()

func _on_host_pressed():
	print("host")
	peer.create_server(2080)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player(1)
	$CanvasLayer.hide()
	
func add_player(id: int):
	var player = player_scene.instantiate()
	print("player added: ", id)
	player.name = str(id)
	player.fire_hit.connect(_on_fire_hit)
	call_deferred("add_child", player)

func exit_game():
	get_tree().quit()

func del_player(id):
	print("delete id: ", id)
	var player = get_node(str(id))
	if player:
		player.queue_free()
