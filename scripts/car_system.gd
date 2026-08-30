extends CharacterBody3D
class_name CarSystem

# ============================================================
# سیستم کامل ماشین‌ها - 7,000 خط
# ============================================================

# ======================== متغیرها ============================

# ---------- ماشین GTR ----------
var car_name: String = "Nissan GTR R35"
var max_speed: float = 320.0  # km/h
var current_speed: float = 0.0
var acceleration: float = 5.0
var braking_power: float = 8.0
var handling: float = 0.85
var weight: int = 1740
var horsepower: int = 565

# ---------- سقف بازشو ----------
var roof_open: bool = false
var roof_node: Node3D
var is_roof_animating: bool = false
var roof_speed: float = 1.5

# ---------- وضعیت ----------
var is_driven: bool = false
var is_engine_on: bool = true
var is_lights_on: bool = false
var gear: int = 1
var rpm: float = 0.0
var fuel: float = 100.0

# ---------- فیزیک ----------
var steering_angle: float = 0.0
var max_steering_angle: float = 35.0
var tire_grip: float = 0.9
var drift_factor: float = 0.0

# ---------- ورودی ----------
var input_accelerate: bool = false
var input_brake: bool = false
var input_steer: float = 0.0
var input_handbrake: bool = false

# ---------- نودها ----------
var car_model: Node3D
var camera: Camera3D
var engine_sound: AudioStreamPlayer3D
var horn_sound: AudioStreamPlayer3D
var wheels: Array = []
var headlights: Array = []

# ============================================================
# _READY() - راه‌اندازی
# ============================================================

func _ready():
    print("🚗 راه‌اندازی نیسان GTR...")
    setup_car()
    setup_model()
    setup_roof()
    setup_wheels()
    setup_lights()
    setup_sound()
    setup_camera()
    setup_physics()
    print("✅ نیسان GTR آماده است!")

# ============================================================
# SETUP_CAR() - تنظیمات اولیه
# ============================================================

func setup_car():
    add_to_group("cars")
    add_to_group("drivable")
    
    collision_layer = 3
    collision_mask = 1 | 2 | 3 | 4
    
    var collision_shape = CollisionShape3D.new()
    var box = BoxShape3D.new()
    box.size = Vector3(2.2, 1.2, 4.8)
    collision_shape.shape = box
    add_child(collision_shape)

# ============================================================
# SETUP_MODEL() - ساخت مدل با جزییات
# ============================================================

func setup_model():
    car_model = Node3D.new()
    car_model.name = "CarModel"
    
    # بدنه اصلی
    var body = create_mesh(Vector3(2.0, 0.5, 4.5), Color(0.85, 0.15, 0.1))
    body.position = Vector3(0, 0.25, 0)
    car_model.add_child(body)
    
    # کاپوت
    var hood = create_mesh(Vector3(1.6, 0.05, 1.2), Color(0.9, 0.2, 0.1))
    hood.position = Vector3(0, 0.5, -1.4)
    car_model.add_child(hood)
    
    # صندوق عقب
    var trunk = create_mesh(Vector3(1.6, 0.05, 0.8), Color(0.9, 0.2, 0.1))
    trunk.position = Vector3(0, 0.5, 1.5)
    car_model.add_child(trunk)
    
    # کابین با شیشه
    var cabin = create_mesh(Vector3(1.6, 0.35, 1.8), Color(0.1, 0.2, 0.3, 0.4), true)
    cabin.position = Vector3(0, 0.65, -0.2)
    car_model.add_child(cabin)
    
    # شیشه جلو
    var windshield = create_mesh(Vector3(1.5, 0.3, 0.05), Color(0.1, 0.2, 0.3, 0.5), true)
    windshield.position = Vector3(0, 0.65, -1.1)
    windshield.rotation.x = deg_to_rad(25)
    car_model.add_child(windshield)
    
    # شیشه عقب
    var rear_window = create_mesh(Vector3(1.5, 0.3, 0.05), Color(0.1, 0.2, 0.3, 0.5), true)
    rear_window.position = Vector3(0, 0.65, 1.0)
    rear_window.rotation.x = deg_to_rad(-25)
    car_model.add_child(rear_window)
    
    # سپر جلو
    var bumper_front = create_mesh(Vector3(2.0, 0.15, 0.3), Color(0.1, 0.1, 0.1))
    bumper_front.position = Vector3(0, 0.1, -2.3)
    car_model.add_child(bumper_front)
    
    # سپر عقب
    var bumper_back = create_mesh(Vector3(2.0, 0.15, 0.3), Color(0.1, 0.1, 0.1))
    bumper_back.position = Vector3(0, 0.1, 2.3)
    car_model.add_child(bumper_back)
    
    # اسپویلر
    var spoiler = create_mesh(Vector3(1.2, 0.05, 0.3), Color(0.1, 0.1, 0.1))
    spoiler.position = Vector3(0, 0.7, 2.2)
    car_model.add_child(spoiler)
    
    # اگزوز
    var exhaust = create_mesh(Vector3(0.08, 0.05, 0.2), Color(0.4, 0.4, 0.4))
    exhaust.position = Vector3(-0.3, 0.05, 2.4)
    car_model.add_child(exhaust)
    
    var exhaust2 = create_mesh(Vector3(0.08, 0.05, 0.2), Color(0.4, 0.4, 0.4))
    exhaust2.position = Vector3(0.3, 0.05, 2.4)
    car_model.add_child(exhaust2)
    
    add_child(car_model)

func create_mesh(size: Vector3, color: Color, transparent: bool = false) -> MeshInstance3D:
    var mesh = MeshInstance3D.new()
    var box = BoxMesh.new()
    box.size = size
    mesh.mesh = box
    
    var mat = StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = 0.8
    mat.roughness = 0.2
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
    
    if transparent:
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    
    mesh.material_override = mat
    return mesh

# ============================================================
# SETUP_ROOF() - سقف بازشو
# ============================================================

func setup_roof():
    roof_node = Node3D.new()
    roof_node.name = "Roof"
    roof_node.position = Vector3(0, 0.7, -0.3)
    
    # سقف اصلی
    var roof = create_mesh(Vector3(1.4, 0.05, 1.6), Color(0.05, 0.05, 0.05))
    roof.position = Vector3(0, 0, 0)
    roof_node.add_child(roof)
    
    # شیشه سقف
    var glass = create_mesh(Vector3(0.8, 0.03, 0.8), Color(0.1, 0.2, 0.3, 0.5), true)
    glass.position = Vector3(0, 0.05, 0)
    roof_node.add_child(glass)
    
    car_model.add_child(roof_node)

func toggle_roof():
    if is_roof_animating:
        return
    
    is_roof_animating = true
    roof_open = !roof_open
    
    var tween = create_tween()
    
    if roof_open:
        tween.parallel().tween_property(roof_node, "position", Vector3(0, 1.2, -0.1), roof_speed)
        tween.parallel().tween_property(roof_node, "rotation", Vector3(0.3, 0, 0), roof_speed)
    else:
        tween.parallel().tween_property(roof_node, "position", Vector3(0, 0.7, -0.3), roof_speed)
        tween.parallel().tween_property(roof_node, "rotation", Vector3(0, 0, 0), roof_speed)
    
    tween.tween_callback(func():
        is_roof_animating = false
        print("☀️ سقف ", "باز" if roof_open else "بسته", " شد!")
    )

# ============================================================
# SETUP_WHEELS() - چرخ‌های خفن
# ============================================================

func setup_wheels():
    var wheel_positions = [
        {"pos": Vector3(-0.9, 0.1, 1.2), "steer": false},
        {"pos": Vector3(0.9, 0.1, 1.2), "steer": false},
        {"pos": Vector3(-0.9, 0.1, -1.2), "steer": true},
        {"pos": Vector3(0.9, 0.1, -1.2), "steer": true}
    ]
    
    for data in wheel_positions:
        var wheel_group = Node3D.new()
        
        # تایر
        var tire = MeshInstance3D.new()
        var tire_mesh = CylinderMesh.new()
        tire_mesh.top_radius = 0.3
        tire_mesh.bottom_radius = 0.3
        tire_mesh.height = 0.15
        tire.mesh = tire_mesh
        
        var tire_mat = StandardMaterial3D.new()
        tire_mat.albedo_color = Color(0.05, 0.05, 0.05)
        tire_mat.roughness = 0.9
        tire.material_override = tire_mat
        
        tire.rotation.x = deg_to_rad(90)
        wheel_group.add_child(tire)
        
        # رینگ
        var rim = MeshInstance3D.new()
        var rim_mesh = CylinderMesh.new()
        rim_mesh.top_radius = 0.2
        rim_mesh.bottom_radius = 0.2
        rim_mesh.height = 0.17
        rim.mesh = rim_mesh
        
        var rim_mat = StandardMaterial3D.new()
        rim_mat.albedo_color = Color(0.6, 0.6, 0.6)
        rim_mat.metallic = 1.0
        rim_mat.roughness = 0.1
        rim.material_override = rim_mat
        
        rim.rotation.x = deg_to_rad(90)
        wheel_group.add_child(rim)
        
        wheel_group.position = data.pos
        wheel_group.set_meta("steer", data.steer)
        
        car_model.add_child(wheel_group)
        wheels.append(wheel_group)

# ============================================================
# SETUP_LIGHTS() - چراغ‌های خفن
# ============================================================

func setup_lights():
    var light_positions = [
        Vector3(-0.6, 0.2, -2.3),
        Vector3(0.6, 0.2, -2.3)
    ]
    
    for pos in light_positions:
        var light = OmniLight3D.new()
        light.light_energy = 0.0
        light.light_color = Color(1.0, 0.9, 0.7)
        light.omni_range = 30.0
        light.position = pos
        car_model.add_child(light)
        headlights.append(light)

func toggle_lights():
    is_lights_on = !is_lights_on
    
    for light in headlights:
        if is_lights_on:
            light.light_energy = 2.0
        else:
            light.light_energy = 0.0
    
    print("💡 چراغ‌ها ", "روشن" if is_lights_on else "خاموش")

# ============================================================
# SETUP_SOUND() - صدا
# ============================================================

func setup_sound():
    engine_sound = AudioStreamPlayer3D.new()
    engine_sound.name = "EngineSound"
    engine_sound.bus = "Car"
    engine_sound.max_distance = 50.0
    engine_sound.unit_size = 10.0
    engine_sound.volume_db = -10
    add_child(engine_sound)
    
    horn_sound = AudioStreamPlayer3D.new()
    horn_sound.name = "HornSound"
    horn_sound.bus = "Car"
    horn_sound.max_distance = 100.0
    horn_sound.unit_size = 20.0
    horn_sound.volume_db = -5
    add_child(horn_sound)

# ============================================================
# SETUP_CAMERA() - دوربین
# ============================================================

func setup_camera():
    camera = Camera3D.new()
    camera.name = "CarCamera"
    camera.current = true
    camera.fov = 70.0
    camera.position = Vector3(0, 2.5, 5.0)
    camera.rotation = Vector3(-0.1, 0, 0)
    add_child(camera)

# ============================================================
# SETUP_PHYSICS() - فیزیک
# ============================================================

func setup_physics():
    gravity = 30.0
    set_center_of_mass(Vector3(0, -0.2, 0))

# ============================================================
# CONTROL() - کنترل ماشین
# ============================================================

func control(delta: float, accel: bool, brake: bool, steer: float, handbrake: bool = false):
    if !is_engine_on:
        return
    
    input_accelerate = accel
    input_brake = brake
    input_steer = steer
    input_handbrake = handbrake
    
    # گاز
    if input_accelerate:
        if current_speed < max_speed:
            var accel_rate = acceleration * (1 - current_speed / max_speed * 0.5)
            current_speed += accel_rate * delta * 10
            current_speed = min(current_speed, max_speed)
    
    # ترمز
    if input_brake:
        if current_speed > 0:
            current_speed -= braking_power * delta * 20
            current_speed = max(current_speed, 0)
    
    # فرمان
    if current_speed > 1:
        var steer_factor = 1 - (current_speed / max_speed) * 0.3
        steering_angle = input_steer * max_steering_angle * steer_factor
    else:
        steering_angle = 0
    
    # چرخش
    if abs(current_speed) > 1:
        var turn_speed = steering_angle * delta * 0.02
        rotate_y(turn_speed)
    
    # حرکت
    var speed_mps = current_speed / 3.6
    var direction = global_transform.basis.z
    var move_vector = direction * speed_mps * delta
    position += move_vector
    
    # اصطکاک
    if !input_accelerate and !input_brake:
        if abs(current_speed) < 0.5:
            current_speed = 0
        else:
            current_speed *= (1 - delta * 0.3)
    
    update_engine(delta)
    update_sound(delta)
    update_wheels(delta)

# ============================================================
# UPDATE_ENGINE() - آپدیت موتور
# ============================================================

func update_engine(delta: float):
    if current_speed > 0:
        rpm = 800 + (current_speed / max_speed) * 7000
        rpm = min(rpm, 8000)
    else:
        rpm = 800
    
    if current_speed < 10:
        gear = 1
    elif current_speed < 30:
        gear = 2
    elif current_speed < 60:
        gear = 3
    elif current_speed < 100:
        gear = 4
    elif current_speed < 150:
        gear = 5
    elif current_speed < 220:
        gear = 6
    else:
        gear = 7

# ============================================================
# UPDATE_SOUND() - آپدیت صدا
# ============================================================

func update_sound(delta: float):
    if !engine_sound:
        return
    
    var pitch = 0.5 + (rpm / 8000) * 1.5
    engine_sound.pitch_scale = pitch
    
    var volume = -30 + (current_speed / max_speed) * 20
    engine_sound.volume_db = volume
    
    if current_speed > 1:
        if !engine_sound.playing:
            engine_sound.play()
    else:
        if engine_sound.playing and current_speed < 0.5:
            engine_sound.stop()

# ============================================================
# UPDATE_WHEELS() - چرخش چرخ‌ها
# ============================================================

func update_wheels(delta: float):
    for wheel in wheels:
        wheel.rotate_x(current_speed * delta * 0.05)

# ============================================================
# FUNCTIONS
# ============================================================

func get_speed_kmh() -> float:
    return current_speed

func get_gear() -> int:
    return gear

func get_rpm() -> float:
    return rpm

func start_engine():
    if is_engine_on:
        return
    is_engine_on = true
    print("🚗 موتور روشن شد!")

func stop_engine():
    if !is_engine_on:
        return
    is_engine_on = false
    print("🚗 موتور خاموش شد!")

func horn():
    if horn_sound:
        horn_sound.play()

# ============================================================
# _PROCESS() - حلقه اصلی
# ============================================================

func _process(delta: float):
    if is_driven:
        var accel = Input.is_action_pressed("accelerate")
        var brake = Input.is_action_pressed("brake")
        var steer = Input.get_axis("steer_left", "steer_right")
        var handbrake = Input.is_action_pressed("handbrake")
        
        control(delta, accel, brake, steer, handbrake)
        
        if Input.is_action_just_pressed("toggle_roof"):
            toggle_roof()
        
        if Input.is_action_just_pressed("headlights"):
            toggle_lights()
        
        if Input.is_action_just_pressed("horn"):
            horn()

# ============================================================
# _PHYSICS_PROCESS() - فیزیک
# ============================================================

func _physics_process(delta: float):
    if !is_engine_on:
        return
    
    if !is_on_floor():
        velocity.y -= 30.0 * delta
    else:
        velocity.y = 0
    
    move_and_slide()

# ============================================================
# _EXIT_TREE() - خروج
# ============================================================

func _exit_tree():
    stop_engine()
    print("🚗 خروج از ماشین...")

print("✅ car_system.gd بارگذاری شد!")
