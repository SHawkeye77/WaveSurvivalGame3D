extends Node3D

@onready var waveSpawner = get_tree().get_first_node_in_group("WaveSpawner")
@onready var pistolShotAudio = get_node("%PistolShotAudio")
@onready var sniperShotAudio = get_node("%SniperShotAudio")
@onready var shotgunShotAudio = get_node("%ShotgunShotAudio")
@onready var repeaterShotAudio = get_node("%RepeaterShotAudio")
@onready var gunEquipAudio = get_node("%GunEquipAudio")
@onready var interactionAudio = get_node("%InteractionAudio")
@onready var mysteryBoxAudio = get_node("%MysteryBoxAudio")
@onready var reloadSpeedUpgradeAudio = get_node("%ReloadSpeedUpgradeAudio")
@onready var bulletDamageUpgradeAudio = get_node("%BulletDamageUpgradeAudio")
@onready var playerHurtAudio = get_node("%PlayerHurtAudio")
@onready var newWaveAudio = get_node("%NewWaveAudio")

func _ready():
	# Resetting game stats
	Global.maxWave = len(waveSpawner.WAVES)

### Audio players ###
func _on_start_game_timer_timeout():
	waveSpawner.spawnNextWave()
func playPistolShotAudio():
	pistolShotAudio.play()
func playSniperShotAudio():
	sniperShotAudio.play()
func playShotgunShotAudio():
	shotgunShotAudio.play()
func playRepeaterShotAudio():
	repeaterShotAudio.play()
func playGunEquipAudio():
	gunEquipAudio.play()
func playInteractionAudio():
	interactionAudio.play()
func playMysteryBoxAudio():
	mysteryBoxAudio.play()
func playReloadSpeedUpgradeAudio():
	reloadSpeedUpgradeAudio.play()
func playBulletDamageUpgradeAudio():
	bulletDamageUpgradeAudio.play()
func playPlayerHurtAudio():
	playerHurtAudio.play()
func playNewWaveAudio():
	newWaveAudio.play()
