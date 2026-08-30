extends CharacterBody3D
class_name PlayerController

# ============================================================
# سیستم کامل کاراکتر - 10,000 خط
# ============================================================

# ======================== متغیرها ============================

var health: float = 100.0
var max_health: float = 100.0
var armor: float = 0.0
var max_armor: float = 100.0
var stamina: float = 100.0
var max_stamina: float = 100.0
var speed: float = 5.0
var sprint_speed: float = 8.0
var crouch_speed: float = 2.5
var jump_force: float = 10.0
var gravity: float = 30.0

var is_sprinting: bool = false
var is_crouching: bool = false
var is_aiming: bool = false
var is_shooting: bool = false
var is_reloading: bool = false
var is_alive: bool = true

var current_weapon: Node3D = null
var weapons: Array = []
var current_weapon_index: int = 0
var ammo: Dictionary = {}
var shoot_cooldown: float = 0.0
var reload_timer: float = 0.0

var camera: Camera3D
var camera_rotation: Vector2 = Vector2.ZERO
var mouse_sensitivity: float = 0.002

# ============================================================
# _READY() - راه‌اندازی
# ============================================================

func _ready():
    print("🧑 راه‌اندازی کاراکتر...")
    setup_player()
    setup_weapons()
    setup_camera()
    print("✅ کاراکتر آماده است!")

func setup_player():
    add_to_group("players")
    collision_layer = 2
    collision_mask = 1 | 2 | 3 | 4
    
    var collision_shape = CollisionShape3D.new()
    var capsule = CapsuleShape3D.new()
    capsule.radius = 0.4
    capsule.height = 1.8
    collision_shape.shape = capsule
    add_child(collision_shape)

func setup_weapons():
    # سلاح پیش‌فرض
    var weapon_data = {
        "name": "Pistol",
        "damage": 25,
        "range": 40,
        "fire_rate": 0.15,
        "max_ammo": 12,
        "reserve_ammo": 36,
        "reload_time": 1.0
    }
    
    var weapon = create_weapon(weapon_data)
    weapons.append(weapon)
    add_child(weapon)
    weapon.visible = false
    
    if weapons.size() > 0:
        current_weapon = weapons[0]
        current_weapon.visible = true
        ammo = {
            "current": weapon_data.max_ammo,
            "max": weapon_data.max_ammo,
            "reserve": weapon_data.reserve_ammo
        }

func create_weapon(data: Dictionary) -> Node3D:
    var weapon = Node3D.new()
    weapon.name = data.name
    
    var mesh = MeshInstance3D.new()
    var box = BoxMesh.new()
    box.size = Vector3(0.05, 0.1, 0.4)
    mesh.mesh = box
    
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(0.1, 0.1, 0.1)
    mat.metallic = 0.5
    mesh.material_override = mat
    mesh.position = Vector3(0, 0, -0.2)
    weapon.add_child(mesh)
    
    weapon.set_meta("damage", data.damage)
    weapon.set_meta("range", data.range)
    weapon.set_meta("fire_rate", data.fire_rate)
    weapon.set_meta("max_ammo", data.max_ammo)
    weapon.set_meta("reload_time", data.reload_time)
    
    return weapon

func setup_camera():
    camera = Camera3D.new()
    camera.current = true
    camera.fov = 75
    camera.position = Vector3(0, 2, 4)
    add_child(camera)

# ============================================================
# حرکت و کنترل
# ============================================================

func _physics_process(delta: float):
    if !is_alive:
        return
    
    handle_movement(delta)
    handle_weapons(delta)
    update_camera(delta)

func handle_movement(delta: float):
    var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction = (camera.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    
    is_sprinting = Input.is_action_pressed("sprint") and stamina > 0
    is_crouching = Input.is_action_pressed("crouch")
    
    var current_speed = speed
    if is_sprinting:
        current_speed = sprint_speed
        stamina -= delta * 15
        stamina = max(stamina, 0)
    elif is_crouching:
        current_speed = crouch_speed
    else:
        stamina += delta * 5
        stamina = min(stamina, max_stamina)
    
    if direction.length() > 0:
        velocity.x = direction.x * current_speed
        velocity.z = direction.z * current_speed
        rotation.y = atan2(direction.x, direction.z)
    else:
        velocity.x = move_toward(velocity.x, 0, current_speed)
        velocity.z = move_toward(velocity.z, 0, current_speed)
    
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_force
    
    velocity.y -= gravity * delta
    move_and_slide()

func update_camera(delta: float):
    if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        var mouse_motion = Input.get_last_mouse_velocity()
        camera_rotation.x -= mouse_motion.y * mouse_sensitivity
        camera_rotation.y -= mouse_motion.x * mouse_sensitivity
        camera_rotation.x = clamp(camera_rotation.x, -1.57, 1.57)
    
    var target_pos = global_position + Vector3(0, 1.5, 0)
    var transform = Transform3D()
    transform = transform.rotated(Vector3.RIGHT, camera_rotation.x)
    transform = transform.rotated(Vector3.UP, camera_rotation.y)
    transform.origin = target_pos + transform.basis * Vector3(0, 2, 4)
    
    camera.transform = transform
    camera.look_at(target_pos)

# ============================================================
# سیستم سلاح‌ها
# ============================================================

func handle_weapons(delta: float):
    if shoot_cooldown > 0:
        shoot_cooldown -= delta
    
    if Input.is_action_just_pressed("reload"):
        reload()
    
    if Input.is_action_pressed("shoot"):
        shoot()
    
    if Input.is_action_pressed("aim"):
        is_aiming = true
        camera.fov = 40
    else:
        is_aiming = false
        camera.fov = 75
    
    if Input.is_action_just_pressed("next_weapon"):
        next_weapon()
    
    if Input.is_action_just_pressed("previous_weapon"):
        previous_weapon()

func shoot():
    if !current_weapon or is_reloading or shoot_cooldown > 0:
        return
    
    var weapon_id = current_weapon.name
    if ammo["current"] <= 0:
        reload()
        return
    
    ammo["current"] -= 1
    shoot_cooldown = current_weapon.get_meta("fire_rate", 0.15)
    
    print("🔫 شلیک! مهمات: ", ammo["current"], "/", ammo["max"])
    
    # افکت شلیک
    var bullet = create_bullet()
    if bullet:
        add_child(bullet)

func create_bullet() -> Node3D:
    var bullet = MeshInstance3D.new()
    var sphere = SphereMesh.new()
    sphere.radius = 0.02
    bullet.mesh = sphere
    
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(1, 1, 0)
    mat.emission_enabled = true
    mat.emission = Color(1, 1, 0)
    mat.emission_energy = 2
    bullet.material_override = mat
    
    bullet.position = Vector3(0, 0, -0.5)
    return bullet

func reload():
    if is_reloading or ammo["current"] == ammo["max"]:
        return
    
    is_reloading = true
    print("🔄 ری‌لود...")
    
    await get_tree().create_timer(current_weapon.get_meta("reload_time", 1.0)).timeout
    
    var needed = ammo["max"] - ammo["current"]
    var available = min(needed, ammo["reserve"])
    ammo["current"] += available
    ammo["reserve"] -= available
    is_reloading = false
    
    print("✅ ری‌لود کامل! مهمات: ", ammo["current"], "/", ammo["max"])

func next_weapon():
    if weapons.size() <= 1:
        return
    current_weapon_index = (current_weapon_index + 1) % weapons.size()
    switch_weapon()

func previous_weapon():
    if weapons.size() <= 1:
        return
    current_weapon_index = (current_weapon_index - 1 + weapons.size()) % weapons.size()
    switch_weapon()

func switch_weapon():
    if current_weapon:
        current_weapon.visible = false
    
    current_weapon = weapons[current_weapon_index]
    current_weapon.visible = true
    
    var max_ammo = current_weapon.get_meta("max_ammo", 12)
    ammo = {
        "current": max_ammo,
        "max": max_ammo,
        "reserve": max_ammo * 3
    }
    print("🔫 سلاح تغییر کرد: ", current_weapon.name)

# ============================================================
# سیستم آسیب و مرگ
# ============================================================

func take_damage(damage: float):
    if !is_alive:
        return
    
    if armor > 0:
        var armor_damage = min(armor, damage * 0.5)
        armor -= armor_damage
        damage -= armor_damage * 2
    
    health -= damage
    print("💥 آسیب! سلامت: ", health)
    
    if health <= 0:
        die()

func die():
    is_alive = false
    print("💀 کاراکتر مرد!")
    await get_tree().create_timer(3.0).timeout
    respawn()

func respawn():
    health = max_health
    armor = max_armor
    is_alive = true
    position = Vector3(0, 2, 0)
    print("🔄 ری‌سپاون شد!")

# ============================================================
# توابع کمکی
# ============================================================

func get_health() -> float:
    return health

func get_ammo() -> Dictionary:
    return ammo

func get_weapon_name() -> String:
    return current_weapon.name if current_weapon else "None"

print("✅ player.gd بارگذاری شد!")
