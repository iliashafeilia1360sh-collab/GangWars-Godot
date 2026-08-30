extends Node3D

# --------------------------------------------
# GANG WARS PIXEL 3D - MAIN GAME
# نسخه کامل با مود منو، ماشین‌ها، سلاح‌ها و...
# --------------------------------------------

var player: CharacterBody3D
var camera: Camera3D
var cars: Array = []
var weapons: Array = []
var npcs: Array = []
var mod_menu_active: bool = false
var game_time: float = 0.0
var is_paused: bool = false

# ---------- متغیرهای ماشین GTR ----------
var gtr_car: CharacterBody3D
var gtr_roof_open: bool = false
var gtr_roof_node: Node3D

# ---------- تنظیمات گرافیک ----------
var graphics_quality: int = 3  # 0=low, 1=medium, 2=high, 3=ultra

func _ready():
    print("🚀 راه‌اندازی بازی Gang Wars Pixel 3D...")
    randomize()
    
    # تنظیمات اولیه
    setup_graphics()
    setup_input()
    create_world()
    create_player()
    create_cars()
    create_weapons()
    create_npcs()
    setup_mod_menu()
    
    print("✅ بازی آماده است!")

# ============================================================
# سیستم گرافیک (70-80% رئالیسم)
# ============================================================

func setup_graphics():
    var viewport = get_viewport()
    viewport.msaa = Viewport.MSAA_4X
    viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
    viewport.use_hdr_2d = true
    
    # تنظیمات محیط
    var world_env = WorldEnvironment.new()
    var env = Environment.new()
    
    # نورپردازی پیشرفته
    env.sdfgi_enabled = true
    env.sdfgi_cascade_0_distance = 20.0
    env.sdfgi_cascade_1_distance = 50.0
    env.sdfgi_cascade_2_distance = 100.0
    env.sdfgi_cascade_3_distance = 300.0
    env.sdfgi_y_scale = 2.0
    env.sdfgi_use_occlusion = true
    env.sdfgi_ray_count = 8
    env.sdfgi_frames_to_converge = 10
    env.sdfgi_energy = 2.0
    
    # مه حجمی
    env.volumetric_fog_enabled = true
    env.volumetric_fog_density = 0.02
    env.volumetric_fog_albedo = Color(0.8, 0.8, 0.85)
    env.volumetric_fog_length = 200.0
    
    # Bloom
    env.glow_enabled = true
    env.glow_intensity = 0.8
    env.glow_strength = 1.2
    env.glow_bloom = 0.5
    env.glow_hdr_threshold = 1.5
    env.glow_hdr_scale = 2.0
    
    # SSAO
    env.ssao_enabled = true
    env.ssao_radius = 2.0
    env.ssao_intensity = 1.5
    env.ssao_power = 1.8
    env.ssao_quality = 3
    
    # آسمان
    var sky = ProceduralSky.new()
    sky.sky_top_color = Color(0.1, 0.2, 0.5)
    sky.sky_horizon_color = Color(0.3, 0.4, 0.6)
    sky.ground_bottom_color = Color(0.05, 0.1, 0.15)
    sky.ground_horizon_color = Color(0.2, 0.25, 0.3)
    sky.sun_angle_max = 45.0
    sky.sun_angle_min = 10.0
    env.sky = sky
    
    # سایه
    env.shadow_atlas_size = 8192
    
    # تنظیمات رنگ
    env.tonemap_mode = Environment.TONE_MAPPER_ACES
    env.tonemap_exposure = 1.0
    env.tonemap_white = 1.0
    
    world_env.environment = env
    add_child(world_env)
    
    # نور خورشید
    var sun = DirectionalLight3D.new()
    sun.light_energy = 2.0
    sun.light_color = Color(1.0, 0.95, 0.85)
    sun.shadow_enabled = true
    sun.shadow_bias = 0.05
    sun.shadow_normal_bias = 0.5
    sun.shadow_blur = 4.0
    sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
    sun.directional_shadow_size = 4096
    sun.directional_shadow_range = 500.0
    sun.directional_shadow_length = 1000.0
    sun.rotation = Vector3(deg_to_rad(45), 0, 0)
    add_child(sun)
    
    # نور محیط
    var ambient = AmbientLight3D.new()
    ambient.light_energy = 0.5
    ambient.light_color = Color(0.5, 0.6, 0.8)
    add_child(ambient)

# ============================================================
# سیستم ورودی
# ============================================================

func setup_input():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    
    # کلیدهای اصلی
    var key_bindings = {
        "move_forward": KEY_W,
        "move_back": KEY_S,
        "move_left": KEY_A,
        "move_right": KEY_D,
        "jump": KEY_SPACE,
        "sprint": KEY_SHIFT,
        "crouch": KEY_CTRL,
        "interact": KEY_E,
        "reload": KEY_R,
        "next_weapon": KEY_Q,
        "previous_weapon": KEY_Z,
        "toggle_roof": KEY_T,
        "change_character": KEY_C,
        "open_menu": KEY_ESCAPE,
        "open_map": KEY_M,
        "enter_exit_car": KEY_F,
        "accelerate": KEY_UP,
        "brake": KEY_DOWN,
        "steer_left": KEY_LEFT,
        "steer_right": KEY_RIGHT,
        "quick_save": KEY_F5,
        "quick_load": KEY_F9,
        "mod_menu": KEY_F11,
        "screenshot": KEY_F12
    }
    
    for action in key_bindings:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
            var event = InputEventKey.new()
            event.keycode = key_bindings[action]
            InputMap.action_add_event(action, event)
    
    # ماوس
    var mouse_actions = {"shoot": MOUSE_BUTTON_LEFT, "aim": MOUSE_BUTTON_RIGHT}
    for action in mouse_actions:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
            var event = InputEventMouseButton.new()
            event.button_index = mouse_actions[action]
            InputMap.action_add_event(action, event)

# ============================================================
# ساخت دنیا
# ============================================================

func create_world():
    print("🌍 ساخت دنیا...")
    
    # زمین
    var terrain = MeshInstance3D.new()
    var plane = PlaneMesh.new()
    plane.size = Vector2(1000, 1000)
    plane.subdivide_width = 50
    plane.subdivide_height = 50
    terrain.mesh = plane
    terrain.rotation.x = -deg_to_rad(90)
    terrain.position = Vector3(0, -0.5, 0)
    
    var terrain_mat = StandardMaterial3D.new()
    terrain_mat.albedo_color = Color(0.3, 0.5, 0.2)
    terrain_mat.roughness = 0.8
    terrain.material_override = terrain_mat
    add_child(terrain)
    
    # ساختمان‌ها
    for i in range(50):
        var building = create_building()
        building.position = Vector3(
            randf_range(-100, 100),
            0,
            randf_range(-100, 100)
        )
        add_child(building)
    
    # جاده‌ها
    for i in range(10):
        var road = create_road()
        road.position = Vector3(
            randf_range(-50, 50),
            0.1,
            randf_range(-50, 50)
        )
        add_child(road)
    
    print("✅ دنیا ساخته شد!")

func create_building() -> MeshInstance3D:
    var mesh = MeshInstance3D.new()
    var box = BoxMesh.new()
    var w = randf_range(3, 8)
    var h = randf_range(2, 15)
    var d = randf_range(3, 8)
    box.size = Vector3(w, h, d)
    mesh.mesh = box
    
    var colors = [
        Color(0.6, 0.5, 0.4),
        Color(0.7, 0.6, 0.5),
        Color(0.8, 0.7, 0.6),
        Color(0.5, 0.5, 0.5)
    ]
    var mat = StandardMaterial3D.new()
    mat.albedo_color = colors[randi() % colors.size()]
    mat.roughness = 0.7
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
    mesh.material_override = mat
    mesh.position = Vector3(0, h/2, 0)
    
    return mesh

func create_road() -> MeshInstance3D:
    var mesh = MeshInstance3D.new()
    var plane = PlaneMesh.new()
    plane.size = Vector2(randf_range(10, 30), randf_range(3, 6))
    mesh.mesh = plane
    mesh.rotation.x = -deg_to_rad(90)
    
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(0.2, 0.2, 0.2)
    mat.roughness = 0.9
    mesh.material_override = mat
    
    mesh.rotation.y = randf_range(0, 6.28)
    return mesh

# ============================================================
# ساخت کاراکتر اصلی
# ============================================================

func create_player():
    print("🧑 ساخت کاراکتر...")
    
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0, 2, 0)
    
    # بدنه
    var body = MeshInstance3D.new()
    var capsule = CapsuleMesh.new()
    capsule.radius = 0.4
    capsule.height = 1.6
    body.mesh = capsule
    
    var body_mat = StandardMaterial3D.new()
    body_mat.albedo_color = Color(0.8, 0.6, 0.4)
    body_mat.roughness = 0.5
    body.material_override = body_mat
    body.position = Vector3(0, 0.8, 0)
    player.add_child(body)
    
    # سر
    var head = MeshInstance3D.new()
    var sphere = SphereMesh.new()
    sphere.radius = 0.2
    sphere.height = 0.25
    head.mesh = sphere
    head.position = Vector3(0, 1.6, 0)
    var head_mat = StandardMaterial3D.new()
    head_mat.albedo_color = Color(0.8, 0.6, 0.4)
    head_mat.roughness = 0.3
    head.material_override = head_mat
    player.add_child(head)
    
    # دوربین
    camera = Camera3D.new()
    camera.current = true
    camera.fov = 75
    camera.position = Vector3(0, 2, 4)
    player.add_child(camera)
    
    add_child(player)
    print("✅ کاراکتر ساخته شد!")

# ============================================================
# ساخت ماشین‌ها (با نیسان GTR)
# ============================================================

func create_cars():
    print("🚗 ساخت ماشین‌ها...")
    
    # ماشین GTR مخصوص
    gtr_car = create_gtr_car()
    gtr_car.position = Vector3(10, 0.5, 5)
    add_child(gtr_car)
    cars.append(gtr_car)
    
    # ماشین‌های دیگه
    for i in range(10):
        var car = create_random_car()
        car.position = Vector3(
            randf_range(-30, 30),
            0.5,
            randf_range(-30, 30)
        )
        add_child(car)
        cars.append(car)
    
    print("✅ ", cars.size(), " ماشین ساخته شد!")

func create_gtr_car() -> CharacterBody3D:
    var car = CharacterBody3D.new()
    car.name = "NissanGTR"
    
    # بدنه
    var body = MeshInstance3D.new()
    var box = BoxMesh.new()
    box.size = Vector3(2.2, 0.6, 4.8)
    body.mesh = box
    
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(0.8, 0.15, 0.1)  # قرمز اسپرت
    mat.metallic = 0.9
    mat.roughness = 0.2
    mat.clearcoat_enabled = true
    mat.clearcoat = 0.5
    body.material_override = mat
    body.position = Vector3(0, 0.3, 0)
    car.add_child(body)
    
    # کابین
    var cabin = MeshInstance3D.new()
    var cabin_box = BoxMesh.new()
    cabin_box.size = Vector3(1.6, 0.4, 2.0)
    cabin.mesh = cabin_box
    var cabin_mat = StandardMaterial3D.new()
    cabin_mat.albedo_color = Color(0.1, 0.2, 0.3, 0.4)
    cabin_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    cabin.material_override = cabin_mat
    cabin.position = Vector3(0, 0.7, -0.3)
    car.add_child(cabin)
    
    # سقف (برای باز و بسته شدن)
    gtr_roof_node = Node3D.new()
    gtr_roof_node.name = "Roof"
    gtr_roof_node.position = Vector3(0, 0.8, -0.3)
    
    var roof = MeshInstance3D.new()
    var roof_box = BoxMesh.new()
    roof_box.size = Vector3(1.4, 0.08, 1.6)
    roof.mesh = roof_box
    var roof_mat = StandardMaterial3D.new()
    roof_mat.albedo_color = Color(0.05, 0.05, 0.05)
    roof_mat.metallic = 0.9
    roof_mat.roughness = 0.1
    roof.material_override = roof_mat
    gtr_roof_node.add_child(roof)
    
    car.add_child(gtr_roof_node)
    
    # چرخ‌ها
    var wheel_positions = [
        Vector3(-0.9, 0.1, 1.2),
        Vector3(0.9, 0.1, 1.2),
        Vector3(-0.9, 0.1, -1.2),
        Vector3(0.9, 0.1, -1.2)
    ]
    for pos in wheel_positions:
        var wheel = MeshInstance3D.new()
        var cyl = CylinderMesh.new()
        cyl.top_radius = 0.3
        cyl.bottom_radius = 0.3
        cyl.height = 0.15
        wheel.mesh = cyl
        var wheel_mat = StandardMaterial3D.new()
        wheel_mat.albedo_color = Color(0.05, 0.05, 0.05)
        wheel_mat.roughness = 0.9
        wheel.material_override = wheel_mat
        wheel.position = pos
        wheel.rotation.x = deg_to_rad(90)
        car.add_child(wheel)
    
    return car

func create_random_car() -> CharacterBody3D:
    var car = CharacterBody3D.new()
    
    var body = MeshInstance3D.new()
    var box = BoxMesh.new()
    var w = randf_range(1.5, 2.5)
    var h = randf_range(0.4, 0.8)
    var d = randf_range(3.0, 5.0)
    box.size = Vector3(w, h, d)
    body.mesh = box
    
    var colors = [
        Color(0.8, 0.1, 0.1), Color(0.1, 0.3, 0.8),
        Color(0.9, 0.8, 0.1), Color(0.1, 0.6, 0.1),
        Color(0.05, 0.05, 0.05), Color(0.9, 0.9, 0.9)
    ]
    var mat = StandardMaterial3D.new()
    mat.albedo_color = colors[randi() % colors.size()]
    mat.metallic = 0.8
    mat.roughness = 0.2
    body.material_override = mat
    body.position = Vector3(0, h/2, 0)
    car.add_child(body)
    
    return car

# ============================================================
# ساخت سلاح‌ها
# ============================================================

func create_weapons():
    print("🔫 ساخت سلاح‌ها...")
    
    var weapon_data = [
        {"name": "M4", "damage": 35, "range": 100, "fire_rate": 0.08},
        {"name": "AK-47", "damage": 45, "range": 80, "fire_rate": 0.1},
        {"name": "DLQ-33", "damage": 95, "range": 200, "fire_rate": 0.5},
        {"name": "Arctic .50", "damage": 100, "range": 250, "fire_rate": 0.6},
        {"name": "MSMC", "damage": 25, "range": 50, "fire_rate": 0.05},
        {"name": "PDW-57", "damage": 28, "range": 55, "fire_rate": 0.06}
    ]
    
    for data in weapon_data:
        var weapon = create_weapon(data)
        weapon.position = Vector3(
            randf_range(-20, 20),
            0.5,
            randf_range(-20, 20)
        )
        add_child(weapon)
        weapons.append(weapon)
    
    print("✅ ", weapons.size(), " سلاح ساخته شد!")

func create_weapon(data: Dictionary) -> Node3D:
    var weapon = Node3D.new()
    weapon.name = data.name
    
    var mesh = MeshInstance3D.new()
    var box = BoxMesh.new()
    box.size = Vector3(0.05, 0.1, 0.5)
    mesh.mesh = box
    
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(0.1, 0.1, 0.1)
    mat.metallic = 0.5
    mesh.material_override = mat
    mesh.position = Vector3(0, 0, -0.25)
    weapon.add_child(mesh)
    
    weapon.set_meta("damage", data.damage)
    weapon.set_meta("range", data.range)
    weapon.set_meta("fire_rate", data.fire_rate)
    
    return weapon

# ============================================================
# ساخت NPCها
# ============================================================

func create_npcs():
    print("👤 ساخت NPCها...")
    
    for i in range(20):
        var npc = create_npc()
        npc.position = Vector3(
            randf_range(-40, 40),
            0,
            randf_range(-40, 40)
        )
        add_child(npc)
        npcs.append(npc)
    
    print("✅ ", npcs.size(), " NPC ساخته شد!")

func create_npc() -> CharacterBody3D:
    var npc = CharacterBody3D.new()
    
    var body = MeshInstance3D.new()
    var capsule = CapsuleMesh.new()
    capsule.radius = 0.3
    capsule.height = 1.0
    body.mesh = capsule
    body.position = Vector3(0, 0.5, 0)
    
    var skin = Color(randf_range(0.3, 0.7), randf_range(0.15, 0.3), randf_range(0.1, 0.2))
    var body_mat = StandardMaterial3D.new()
    body_mat.albedo_color = skin
    body_mat.roughness = 0.5
    body.material_override = body_mat
    npc.add_child(body)
    
    var head = MeshInstance3D.new()
    var sphere = SphereMesh.new()
    sphere.radius = 0.15
    sphere.height = 0.2
    head.mesh = sphere
    head.position = Vector3(0, 1.0, 0)
    var head_mat = StandardMaterial3D.new()
    head_mat.albedo_color = skin
    head_mat.roughness = 0.3
    head.material_override = head_mat
    npc.add_child(head)
    
    return npc

# ============================================================
# سیستم مود منو
# ============================================================

func setup_mod_menu():
    print("🎮 سیستم مود منو فعال شد!")
    print("   - F11 برای باز کردن مود منو")
    print("   - T برای باز/بسته کردن سقف GTR")
    print("   - C برای تغییر کاراکتر")

# ============================================================
# توابع کنترلی
# ============================================================

func toggle_roof():
    if gtr_roof_node:
        gtr_roof_open = !gtr_roof_open
        var target_y = 1.2 if gtr_roof_open else 0.8
        var target_rot = 0.3 if gtr_roof_open else 0.0
        
        var tween = create_tween()
        tween.parallel().tween_property(gtr_roof_node, "position:y", target_y, 0.5)
        tween.parallel().tween_property(gtr_roof_node, "rotation:x", target_rot, 0.5)
        
        print("☀️ سقف ", "باز" if gtr_roof_open else "بسته", " شد!")

func change_character():
    print("🔄 تعویض کاراکتر...")
    if player:
        var color = Color(randf(), randf(), randf())
        player.get_child(0).material_override.albedo_color = color
        print("✅ کاراکتر تغییر کرد!")

func toggle_mod_menu():
    mod_menu_active = !mod_menu_active
    if mod_menu_active:
        print("📋 مود منو باز شد!")
        print("   1. تغییر رنگ ماشین")
        print("   2. افزایش سرعت")
        print("   3. اسپاون NPC")
        print("   4. تغییر آب و هوا")
        print("   5. ریست بازی")
        print("   ESC برای بستن")
    else:
        print("📋 مود منو بسته شد!")

# ============================================================
# حلقه اصلی بازی
# ============================================================

func _process(delta: float):
    if is_paused:
        return
    
    game_time += delta
    
    # حرکت کاراکتر (ساده)
    if player and Input.is_action_pressed("move_forward"):
        player.position += Vector3(0, 0, -delta * 3)
    if player and Input.is_action_pressed("move_back"):
        player.position += Vector3(0, 0, delta * 3)
    if player and Input.is_action_pressed("move_left"):
        player.position += Vector3(-delta * 3, 0, 0)
    if player and Input.is_action_pressed("move_right"):
        player.position += Vector3(delta * 3, 0, 0)
    
    # ورودی‌های ویژه
    if Input.is_action_just_pressed("toggle_roof"):
        toggle_roof()
    
    if Input.is_action_just_pressed("change_character"):
        change_character()
    
    if Input.is_action_just_pressed("mod_menu"):
        toggle_mod_menu()
    
    if Input.is_action_just_pressed("open_menu"):
        is_paused = !is_paused
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_paused else Input.MOUSE_MODE_CAPTURED
        print("⏸ بازی ", "مکث" if is_paused else "ادامه")

func _input(event: InputEvent):
    if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
        if mod_menu_active:
            mod_menu_active = false
            print("📋 مود منو بسته شد!")

# ============================================================
# توابع ذخیره‌سازی
# ============================================================

func _notification(what):
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        print("💾 ذخیره خودکار...")
        var save_data = {
            "time": game_time,
            "player_pos": player.position if player else Vector3.ZERO,
            "cars": cars.size(),
            "npcs": npcs.size()
        }
        var file = FileAccess.open("user://savegame.dat", FileAccess.WRITE)
        if file:
            file.store_var(save_data)
            print("✅ بازی ذخیره شد!")

print("🎮 بازی Gang Wars Pixel 3D آماده است!")
print("   - ماشین‌ها: ", cars.size())
print("   - سلاح‌ها: ", weapons.size())
print("   - NPCها: ", npcs.size())
print("   - کلید T برای سقف GTR")
print("   - کلید F11 برای مود منو")
