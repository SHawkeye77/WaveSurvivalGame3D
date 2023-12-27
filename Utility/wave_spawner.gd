extends Node3D

@onready var player = get_tree().get_first_node_in_group("player")
@onready var world = get_tree().get_first_node_in_group("world")
@onready var spawnNextEnemyTimer = get_node("%SpawnNextEnemyTimer")
@onready var spawnPoints = get_tree().get_first_node_in_group("SpawnPoints")
@onready var worldZombies = get_tree().get_first_node_in_group("WorldZombies")
@onready var startNewWaveTimer = get_node("%StartNewWaveTimer")
@onready var z = preload("res://Models/Zombie/zombie.tscn") # Zombie
var zombieInstance = null
var currentWaveIndex = -1
var currentEnemyIndex = -1
var currentWaveEnemiesData = null
var currentWaveEnemiesSpawned = []
@onready var WAVES = [
	# Wave 1 
	[
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 15.0],
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 5.0],
	],
	# Wave 2
	[
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 5.0],
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 5.0],
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 5.0],
	],
	# Wave 3
	[
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 5.0],
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 5.0],
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 5.0],
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 5.0],
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 5.0],
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 5.0],
	],
	# Wave 4
	[
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 5.0],
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 5.0],
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 5.0],
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 5.0],
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 5.0],
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 5.0],
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 5.0],
	],
	# Wave 5
	[
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 1.0],
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 1.0],
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 1.0],
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 1.0],
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 1.0],
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 1.0],
		[z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 0], [z, 1.0],
	],
]


func _ready():
	startNewWaveTimer.wait_time = Global.WORLD_TIME_BETWEEN_WAVES
	# Seeding our rng
	randomize()
	# Setting up the wave
	player.wave = currentWaveIndex + 1
	player.updateUI()
	spawnNextEnemyTimer.wait_time = 0.1

# Spawns the next wave
func spawnNextWave():
	currentWaveIndex += 1
	player.wave = currentWaveIndex + 1
	player.updateUI()
	# Game won
	if currentWaveIndex == len(WAVES):
		player.gameOver()
	# Spawn next wave
	else:
		world.playNewWaveAudio()
		currentWaveEnemiesData = WAVES[currentWaveIndex]
		currentEnemyIndex = 0
		startNewWaveTimer.start()
		
# Spawns the next enemy in the current wave
func spawnEnemy():
	# If there are more enemies left in this wave, spawn the next enemy
	if currentEnemyIndex != len(currentWaveEnemiesData):
		var enemyInfo = currentWaveEnemiesData[currentEnemyIndex]
		# Spawning the new enemy
		var newEnemy = enemyInfo[0].instantiate()
		newEnemy.global_position = getRandomPosition()
		add_child(newEnemy)
		currentWaveEnemiesSpawned.append(newEnemy)
		# Set up the timer to spawn the next enemy
		if (enemyInfo[1] == 0): # Setting to small value, otherwise run into some bugs with setting the timer
			spawnNextEnemyTimer.start(0.001)
		else:
			spawnNextEnemyTimer.start(enemyInfo[1])
		currentEnemyIndex += 1

# Called when an enemy dies
func enemyDied(enemy):
	# Checking so we do not double remove enemies (e.g. if two shotgun bullets hit an enemy during the same frame)
	var enemyIndex = currentWaveEnemiesSpawned.find(enemy)
	if enemyIndex != -1:
		currentWaveEnemiesSpawned.remove_at(enemyIndex)
	# If we have no more alive ones and no more to spawn
	if (len(currentWaveEnemiesSpawned) == 0 && currentEnemyIndex == len(currentWaveEnemiesData)):
		spawnNextWave()

func getRandomPosition():
	var randomIdx = randi() % spawnPoints.get_child_count()
	return spawnPoints.get_child(randomIdx).global_position

func _on_spawn_next_enemy_timer_timeout():
	spawnEnemy()

func _on_start_new_wave_timer_timeout():
	spawnEnemy()
