extends Node3D

func _ready():
    print("🚀 Gang Wars Pixel 3D Started!")
    
    # ساخت یه ماشین ساده برای تست
    var car = MeshInstance3D.new()
    var box = BoxMesh.new()
    box.size = Vector3(2, 0.5, 4)
    car.mesh = box
    
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(1, 0, 0)
    car.material_override = mat
    
    car.position = Vector3(0, 0.5, 0)
    add_child(car)
    
    print("✅ ماشین قرمز ساخته شد!")
