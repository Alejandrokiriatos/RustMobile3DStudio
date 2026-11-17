extends Node3D
## Procedural vegetation library. All pieces are actual Godot MeshInstance3D meshes.
const TREES := [
 ["TREE_01_PINE","Pino","pine",5.8,"315b3b"],["TREE_02_OAK","Roble","round",5.2,"477b39"],
 ["TREE_03_BIRCH","Abedul","round",5.0,"6b9148"],["TREE_04_WILLOW","Sauce","willow",5.1,"789b3c"],
 ["TREE_05_PALM","Palmera","palm",6.2,"39834a"],["TREE_06_DEAD","Árbol muerto","dead",4.7,"786044"],
 ["TREE_07_MAPLE","Arce otoñal","autumn",5.3,"c65a24"],["TREE_08_BANANA","Banano","banana",4.2,"5b9b32"],
 ["TREE_09_CYPRESS","Ciprés","cypress",6.0,"28543d"],["TREE_10_ACACIA","Acacia","acacia",4.8,"789448"],
 ["TREE_11_SNOW_PINE","Pino nevado","snow",5.7,"456d55"],["TREE_12_CHERRY","Cerezo","round",5.0,"e8a5c2"],
 ["TREE_13_JUNGLE","Árbol de jungla","jungle",6.4,"347343"],["TREE_14_FRUIT","Árbol frutal","fruit",4.8,"4f8735"],
 ["TREE_15_DESERT","Árbol desértico","dead",4.2,"9a8a55"]
]
const BUSHES := [["BUSH_01_FIBER","Arbusto de fibras","fiber"],["BUSH_02_FOOD","Arbusto de comida","berries"]]
var rng := RandomNumberGenerator.new()

func _ready() -> void:
 rng.seed = 91427
 _build_stage()
 for i in TREES.size():
  var d = TREES[i]
  var item = create_tree(d[0])
  item.position = Vector3((i % 5) * 5.0 - 10.0, 0, floori(float(i)/5.0)*8.0)
  add_child(item)
 for i in BUSHES.size():
  var item = create_bush(BUSHES[i][0])
  item.position = Vector3(-2.5 + i*5.0,0,25.0)
  add_child(item)

func create_tree(asset_id: String) -> Node3D:
 var d = _tree_data(asset_id)
 if d.is_empty(): push_error("Unknown tree: "+asset_id); return Node3D.new()
 var root = Node3D.new()
 root.name = asset_id
 root.set_meta("asset_id",asset_id)
 root.set_meta("harvestable",false)
 var kind:String=d[2]; var h:float=d[3]
 var bark = _material(Color("#69503a") if kind!="birch" else Color("#e1dfcf"))
 var foliage = _material(Color("#"+d[4]))
 var trunk = CylinderMesh.new()
 trunk.top_radius=0.15; trunk.bottom_radius=0.29; trunk.height=h*0.62
 _add(root,trunk,bark,Vector3(0,h*0.31,0))
 if kind=="dead":
  for j in 5:
   var branch= CylinderMesh.new()
   branch.top_radius=0.025; branch.bottom_radius=0.095; branch.height=h*0.38
   var b=_add(root,branch,bark,Vector3(0,h*0.57,0))
   b.rotation_degrees=Vector3(-35+j*15,j*72,28+j*8)
 elif kind=="palm":
  for j in 9:
   var leaf=_add(root,_ellipsoid(Vector3(0.13,0.045,1.5)),foliage,Vector3(0,h*0.88,0))
   leaf.rotation_degrees=Vector3(-22,j*40,-25)
 elif kind=="banana":
  for j in 8:
   var leaf=_add(root,_ellipsoid(Vector3(0.12,0.04,1.35)),foliage,Vector3(0,h*0.79,0))
   leaf.rotation_degrees=Vector3(-18,j*45,-35+(j%3)*30)
 else:
  var count=7 if kind in ["pine","snow","cypress"] else 10
  for j in count:
   var t=float(j)/float(count-1)
   var y=h*(0.40+t*0.48)
   var spread=(1.0-t)*h*0.27+0.15
   var p=Vector3(rng.randf_range(-spread,spread),y,rng.randf_range(-spread,spread))
   if kind in ["pine","snow","cypress"]:
    var radius=0.9 if kind!="cypress" else 0.58
    _add(root,_cone(radius,1.45),foliage,p)
    if kind=="snow": _add(root,_cone(radius*0.82,0.38),_material(Color("#e8eeee")),p+Vector3(0,0.43,0))
   else:
    var s=Vector3(0.68,0.48,0.68)
    if kind=="willow": s=Vector3(0.31,0.68,0.31)
    if kind=="acacia": s=Vector3(1.48,0.30,1.05)
    if kind=="jungle": s=Vector3(1.2,0.62,1.0)
    _add(root,_ellipsoid(s),foliage,p)
  if kind=="fruit":
   var red=_material(Color("#d84b32"))
   for j in 14:
    _add(root,_ellipsoid(Vector3.ONE*0.11),red,Vector3(rng.randf_range(-0.9,0.9),rng.randf_range(h*0.5,h*0.86),rng.randf_range(-0.8,0.8)))
 return root

func create_bush(asset_id:String) -> Node3D:
 var d=[]
 for row in BUSHES:
  if row[0]==asset_id: d=row
 if d.is_empty(): push_error("Unknown bush: "+asset_id); return Node3D.new()
 var root=Node3D.new()
 root.name=asset_id
 root.set_meta("asset_id",asset_id)
 root.set_meta("harvestable",true)
 root.set_meta("resource_type",d[2])
 root.set_meta("yield_min",2 if d[2]=="fiber" else 3)
 root.set_meta("yield_max",5 if d[2]=="fiber" else 6)
 var green=_material(Color("#718b42") if d[2]=="fiber" else Color("#4f8738"))
 for j in 12:
  var s=Vector3(rng.randf_range(0.32,0.55),rng.randf_range(0.27,0.45),rng.randf_range(0.32,0.55))
  _add(root,_ellipsoid(s),green,Vector3(rng.randf_range(-0.6,0.6),s.y,rng.randf_range(-0.6,0.6)))
 if d[2]=="fiber":
  var blade_mat=_material(Color("#a9b66b"))
  for j in 24:
   var blade=_add(root,_ellipsoid(Vector3(0.035,0.045,rng.randf_range(0.4,0.8))),blade_mat,Vector3(rng.randf_range(-0.45,0.45),0.34,rng.randf_range(-0.45,0.45)))
   blade.rotation_degrees=Vector3(-18,rng.randf_range(0,360),rng.randf_range(-40,40))
 else:
  var red=_material(Color("#bd3438"))
  for j in 20:
   _add(root,_ellipsoid(Vector3.ONE*0.075),red,Vector3(rng.randf_range(-0.62,0.62),rng.randf_range(0.3,0.85),rng.randf_range(-0.62,0.62)))
 return root

func _tree_data(id:String) -> Array:
 for d in TREES:
  if d[0]==id: return d
 return []
func _material(c:Color) -> StandardMaterial3D:
 var m=StandardMaterial3D.new(); m.albedo_color=c; m.roughness=0.9; return m
func _ellipsoid(s:Vector3) -> SphereMesh:
 var m=SphereMesh.new(); m.radius=0.5; m.height=1.0; m.radial_segments=8; m.rings=5; m.set_meta("veg_scale",s); return m
func _cone(r:float,h:float) -> ConeMesh:
 var m=ConeMesh.new(); m.top_radius=0.025; m.bottom_radius=r; m.height=h; m.radial_segments=9; return m
func _add(parent:Node3D,mesh:Mesh,mat:Material,pos:Vector3) -> MeshInstance3D:
 var n=MeshInstance3D.new(); n.mesh=mesh; n.material_override=mat; n.position=pos
 if mesh.has_meta("veg_scale"): n.scale=mesh.get_meta("veg_scale")
 parent.add_child(n); return n

func _build_stage() -> void:
 var env=WorldEnvironment.new()
 var e=Environment.new()
 e.background_mode=Environment.BG_COLOR
 e.background_color=Color("#b8c2c0")
 e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 e.ambient_light_color=Color("#dce5df")
 e.ambient_light_energy=0.8
 env.environment=e
 add_child(env)
 var light=DirectionalLight3D.new()
 light.rotation_degrees=Vector3(-48,-28,0)
 light.light_energy=1.25
 light.shadow_enabled=true
 add_child(light)
 var floor_mesh=PlaneMesh.new()
 floor_mesh.size=Vector2(38,38)
 var floor_node=MeshInstance3D.new()
 floor_node.mesh=floor_mesh
 floor_node.position=Vector3(0,-0.05,10)
 floor_node.material_override=_material(Color("#777d70"))
 add_child(floor_node)
 var camera=Camera3D.new()
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.size=37.0
 camera.position=Vector3(0,20,43)
 camera.look_at(Vector3(0,2,10),Vector3.UP)
 add_child(camera)
 camera.current=true
 if OS.get_environment("CAPTURE_VEGETATION")=="1":
  _capture_preview.call_deferred()

func _capture_preview() -> void:
 await get_tree().create_timer(3.0).timeout
 await RenderingServer.frame_post_draw
 var image=get_viewport().get_texture().get_image()
 var path=ProjectSettings.globalize_path("res://Screenshots/vegetation_gallery_godot.png")
 var err=image.save_png(path)
 print("VEGETATION_CAPTURE path=",path," error=",err," size=",image.get_size())
 get_tree().quit()
