extends Node2D

var battle_scene = preload("res://Battle/Battle.tscn")
var world_scene = load("res://World.tscn")

var spawn_points : Array = []
var enemy_types : Array = []

var active_floor
var curr_pos

export (ButtonGroup) var group
export (ButtonGroup) var group2

func check_enemy_count():
	if (get_node("Enemies").get_children() == []):
		pass_player_to_select(get_node("Player"))
	else:
		pass

func initialize(Map, Player):
	if (Player.visible == false):
		Player.visible = true
	if ($Map.visible == false):
		$Map.visible = true
	for button in group.get_buttons():
		button.connect("pressed", self, "shop_button_pressed")
	for button in group2.get_buttons():
		button.connect("pressed", self, "back_button_pressed")
	match Map:
		"Forest":
			$Map/Forest.visible = true
			$Map/Dungeon.visible = false
			$Map/Ruins.visible = false
			$Store.visible = false
			get_spawnpoints("Forest")
			enemy_types = ["res://Enemies/Small/Forest/Small Mushroom/Small Mushroom.tscn", 
			"res://Enemies/Small/Forest/Twig Blight/Twig Blight.tscn", "res://Enemies/Small/Ruins/Wisp/Whisp.tscn",
			"res://Enemies/Medium/Forest/Wolf/Wolf.tscn"]
			spawn_player("Forest", Player)
			spawn_enemies(enemy_types.size(), 1)
			active_floor = "Forest"
		"Ruins":
			$Map/Forest.visible = false
			$Map/Dungeon.visible = false
			$Map/Ruins.visible = true
			$Store.visible = false
			get_spawnpoints("Ruins")
			enemy_types = ["res://Enemies/Small/Ruins/Imp/Imp.tscn", "res://Enemies/Small/Ruins/Skullflame/Skullflame.tscn", 
			"res://Enemies/Small/Ruins/Wisp/Whisp.tscn","res://Enemies/Small/Ruins/Child Spirit/Child Spirit.tscn",
			"res://Enemies/Small/Ruins/Hell Critter/Hell Critter.tscn"]
			spawn_player("Ruins", Player)
			spawn_enemies(enemy_types.size(), 9)
			active_floor = "Ruins"
		"Dungeon":
			$Map/Forest.visible = false
			$Map/Dungeon.visible = true
			$Map/Ruins.visible = false
			$Store.visible = false
			get_spawnpoints("Dungeon")
			enemy_types = ["res://Enemies/Small/Ruins/Imp/Imp.tscn", "res://Enemies/Small/Ruins/Skullflame/Skullflame.tscn", 
			"res://Enemies/Small/Ruins/Wisp/Whisp.tscn","res://Enemies/Small/Ruins/Child Spirit/Child Spirit.tscn",
			"res://Enemies/Small/Dungeon/Mimic/Mimic.tscn"]
			spawn_player("Dungeon", Player)
			spawn_enemies(enemy_types.size(), 9)
			active_floor = "Dungeon"
		"Store":
			$Map.visible = false
			$Store.visible = true
			$Store/StoreKeeper/AnimationPlayer.play("Idle")
			spawn_player("Store", Player)
			update_potion_labels()
			active_floor = "Store"
	make_world_interactable()

func update_potion_labels():
	var health_potion_label = get_node("Store/Potions/Health Potion/Label")
	var attack_potion_label = get_node("Store/Potions/Attack Potion/Label")
	var player = get_node("Player")
	health_potion_label.text = ": " + str(player.get_potion_count("Health Potion"))
	attack_potion_label.text = ": " + str(player.get_potion_count("Attack Potion"))

func _on_Player_battle_start(player, enemy):
	start_battle(player, enemy)

func start_battle(player, enemy):
	player.set_physics_process(false)
	var temp_player = player
	curr_pos = player.get_global_position()
	yield(get_tree().create_timer(.1), 'timeout')
	remove_child(player)
	var temp_enemy = enemy
	get_node("Enemies").remove_child(enemy)
	change_map_visibility(false)
	yield(get_tree().create_timer(.01), 'timeout')
	add_child(battle_scene.instance())
	$Battle.initialize(temp_player, temp_enemy, active_floor)

func get_spawnpoints(Map):
	for i in range(10):
		spawn_points.append(get_node("SpawnPoints").get_node(Map).get_node("Normal").get_child(i))

func spawn_enemies(NumTypes, NumEnemies):
	var Spawns = choose_spawns(NumEnemies)
	var enemies_spawned : Dictionary = make_enemy_type_dict()
	for spawn in Spawns:
		randomize()
		var enemy_type = get_valid_type(NumTypes, enemies_spawned)
		var enemy = load(enemy_type).instance()
		enemies_spawned[enemy_type] += 1
		spawn_single_enemy(enemy, spawn_points[spawn].position )

func spawn_single_enemy(enemyScene, spawnLocation):
	get_node("Enemies").add_child(enemyScene)
	match active_floor:
		"Forest":
			enemyScene.layers = 2
		"Dungeon":
			enemyScene.layers = 4
		"Ruins":
			enemyScene.layers = 3
	enemyScene.level_up(get_node("Player").get_level())
	enemyScene.scale = Vector2(1.5,1.5)
	enemyScene.set_global_position(spawnLocation)

func get_valid_type(NumTypes, EnemyDict):
	var type = enemy_types[randi()%NumTypes]
	while EnemyDict[type] >= 3:
		type = enemy_types[randi()%NumTypes]
	return type

func make_enemy_type_dict():
	var enemies = {}
	for type in enemy_types:
		enemies[type] = 0
	return enemies

func choose_spawns(NumEnemies):
	var SpawnsPicked = []
	for i in range(NumEnemies):
		randomize()
		var spawn_point = randi()%9+1
		while SpawnsPicked.count(spawn_point) == 1:
			spawn_point = randi()%9+1
		SpawnsPicked.append(spawn_point)
	return SpawnsPicked

func spawn_player(Map, Player):
	add_child(Player)
	var player_spawn
	if (Map != "Store"):
		player_spawn = get_node("SpawnPoints/" + Map + "/Player/PlayerSpawn")
		Player.get_node("Gold").visible = false
		Player.get_node("Heart").visible = true
	else:
		player_spawn = get_node("Store/PlayerSpawn")
		Player.get_node("Gold").visible = true
		Player.get_node("Heart").visible = false
	Player.set_global_position(player_spawn.position)
	Player.scale = Vector2(.4,.4)

func clear_enemies():
	var enemies = get_node("Enemies")
	for enemy in enemies.get_children():
		enemy.queue_free()

func make_world_interactable():
	if active_floor == "Store":
		pass
	else:
		var background = get_node("Map/" + str(active_floor)).get_node("Background")
		var foreground = get_node("Map/" + str(active_floor)).get_node("Foreground")
		background.collision_layer = 1
		background.collision_mask = 1
		foreground.collision_layer = 1
		foreground.collision_mask = 1

func clear_world():
	for node in self.get_children():
		node.queue_free()
	self.queue_free()

func clear_all():
	clear_enemies()
	clear_world()

func change_map_visibility(isVisible : bool):
	$Map.visible = isVisible
	$Enemies.visible = isVisible

func shop_button_pressed():
	var active_button = group.get_pressed_button()
	match active_button.name:
		"Attack Potion":
			print("Attack Potion")
			get_node("Player").buy_item("Attack Potion")
		"Health Potion":
			print("Health Potion")
			get_node("Player").buy_item("Health Potion")
	update_potion_labels()

func back_button_pressed():
	pass_player_to_select(get_node("Player"))
	get_node("Map").get_parent().queue_free()
	get_parent().get_node("WorldSelect").visible = true

func pass_player_to_select(Player):
	ready_player_to_pass(Player)
	change_map_visibility(false)
	clear_all()
	var select_screen = get_tree().root.get_node("WorldSelect")
	select_screen.add_child(Player)
	select_screen.visible = true

func ready_player_to_pass(Player):
	Player.visible = false
	remove_child(Player)
