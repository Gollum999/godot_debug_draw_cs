tool
extends Spatial

export bool ZylannExample = false
var start_pos: Vector3
var box: CSGBox = null

func _ready() -> void:
    box = GetNodeOrNull<CSGBox>("LagTest")
    start_pos = box.Translation
    ProcessPriority = 1

func _process(delta: float) -> void:
    # Zylann's example :D
    if ZylannExample:
        var time = OS.GetTicksMsec() / 1000f
        var box_pos = Vector3(0, sin(time * 4f), 0)
        var line_begin = Vector3(-1, sin(time * 4f), 0)
        var line_end = Vector3(1, cos(time * 4f), 0)

        DebugDraw.draw_box(box_pos, Vector3(1, 2, 1), Color(0, 1, 0), 0, false) # Box need to be NOT centered
        DebugDraw.draw_line_3d(line_begin, line_end, Color(1, 1, 0))
        DebugDraw.set_text("Time", time)
        DebugDraw.set_text("Frames drawn", Engine.GetFramesDrawn())
        DebugDraw.set_text("FPS", Engine.GetFramesPerSecond())
        DebugDraw.set_text("delta", delta)
        return


    # Enable FPSGraph
    DebugDraw.FPSGraphEnabled = true
    DebugDraw.FPSGraphShowTextFlags = DebugDraw.FPSGraphTextFlags.CURRENT | DebugDraw.FPSGraphTextFlags.MAX | DebugDraw.FPSGraphTextFlags.MIN
    DebugDraw.FPSGraphSize = Vector2(200, 32)

    # Debug for debug
    DebugDraw.Freeze3DRender = Input.IsActionPressed("ui_accept")
    DebugDraw.ForceUseCameraFromScene = Input.IsActionPressed("ui_up")
    DebugDraw.DebugEnabled = !Input.IsActionPressed("ui_down")

    # Zones
    var col = Color.black
    foreach (Spatial z in get_node("Zones").get_children()):
        DebugDraw.draw_box(z.GlobalTransform, col)

    # Spheres
    {
        DebugDraw.draw_sphere(get_node("SphereTransform").GlobalTransform, Color.crimson)
        DebugDraw.draw_sphere(get_node("SpherePosition").GlobalTransform.origin, 2, Color.blueviolet)
    }

    # Cylinders
    {
        DebugDraw.draw_cylinder(get_node("Cylinder1").GlobalTransform, Color.crimson)
        DebugDraw.draw_cylinder(get_node("Cylinder2").GlobalTransform.origin, 1, 2, Color.red)
    }

    # Boxes
    {
        DebugDraw.draw_box(get_node("Box1").GlobalTransform, Color.purple)
        DebugDraw.draw_box(get_node("Box2").GlobalTransform.origin, Vector3.One, Color.rebeccapurple)
        DebugDraw.draw_box(get_node("Box3").GlobalTransform.origin, Quat.new(Vector3.Up, PI * 0.25f), Vector3.One * 2, Color.rosybrown)

        var r = get_node("AABB")
        DebugDraw.draw_aabb(r.GetChild<Spatial>(0).GlobalTransform.origin, r.GetChild<Spatial>(1).GlobalTransform.origin, Color.deeppink)

        DebugDraw.draw_aabb(AABB(get_node("AABB_fixed").GlobalTransform.origin, Vector3(2, 1, 2)), Color.aqua)
    }

    # Lines
    {
        var target = get_node("Lines/Target")
        DebugDraw.draw_billboard_square(target.GlobalTransform.origin, 0.5f, Color.red)

        # Normal
        {
            DebugDraw.draw_line_3d(get_node("Lines/1").GlobalTransform.origin, target.GlobalTransform.origin, Color.fuchsia)
            DebugDraw.draw_ray_3d(get_node("Lines/3").GlobalTransform.origin, (target.GlobalTransform.origin - get_node("Lines/3").GlobalTransform.origin).normalized(), 3f, Color.crimson)
        }

        # Arrow
        {
            DebugDraw.draw_arrow_line_3d(get_node("Lines/2").GlobalTransform.origin, target.GlobalTransform.origin, Color.blue)
            DebugDraw.draw_arrow_ray_3d(get_node("Lines/4").GlobalTransform.origin, (target.GlobalTransform.origin - get_node("Lines/4").GlobalTransform.origin).normalized(), 8f, Color.lavender)
        }

        # Path
        {
            DebugDraw.draw_line_path_3d(get_node("LinePath")?.get_children().ToArray<Spatial>().Select((o) => o.GlobalTransform.origin).ToArray(), Color.beige)
            DebugDraw.draw_arrow_path_3d(get_node("LinePath")?.get_children().ToArray<Spatial>().Select((o) => o.GlobalTransform.origin + Vector3.Down).ToArray(), Color.gold)
        }

        DebugDraw.draw_line_3d_hit(get_node("Lines/5").GlobalTransform.origin, target.GlobalTransform.origin, true, abs(sin((float)DateTime.Now.TimeOfDay.TotalSeconds)), 0.25f, 0, Color.aqua)
    }

    # Misc
    {
        DebugDraw.draw_camera_frustum(get_node("Camera"), Color.darkorange)
        DebugDraw.draw_billboard_square(get_node("Billboard").GlobalTransform.origin, 0.5f, Color.green)
        DebugDraw.draw_position_3d(get_node("Position").GlobalTransform, Color.brown)
    }

    # Text
    {
        DebugDraw.set_text("FPS", $"{Engine.GetFramesPerSecond():F2}", 0, Color.gold)

        DebugDraw.begin_text_group("-- First Group --", 2, Color.forestgreen)
        DebugDraw.set_text("Simple text")
        DebugDraw.set_text("Text", "Value", 0, Color.aquamarine)
        DebugDraw.set_text("Text out of order", null, -1, Color.silver)
        DebugDraw.begin_text_group("-- Second Group --", 1, Color.beige)
        DebugDraw.set_text("Rendered frames", $"{Engine.GetFramesDrawn()}")
        DebugDraw.end_text_group()

        DebugDraw.begin_text_group("-- Stats --", 3, Color.wheat)
        DebugDraw.set_text("Total rendered", DebugDraw.RenderCount.Total, 0)
        DebugDraw.set_text("Instances", DebugDraw.RenderCount.Instances, 1)
        DebugDraw.set_text("Wireframes", DebugDraw.RenderCount.Wireframes, 2)
        DebugDraw.end_text_group()
    }

    # Lag Test
    {
        if not Engine.EditorHint and box != null:
            box.Translation = start_pos + Vector3(sin(OS.GetTicksMsec() / 100.0f) * 2.5f, 0, 0)
            DebugDraw.draw_box(box.GlobalTransform.origin, Vector3.One * 2f)
    }


# public static class Extensions
# {
#     public static T[] ToArray<T>(this Godot.Collections.Array array) where T : Godot.Node, new()
#     {
#         var res = new T[array.size()]
#         for (int i = 0 i < array.size() i++)
#             res[i] = array[i] as T
#         return res
#     }
# }
