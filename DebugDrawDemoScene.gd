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
        var box_pos = new Vector3(0, Mathf.Sin(time * 4f), 0)
        var line_begin = new Vector3(-1, Mathf.Sin(time * 4f), 0)
        var line_end = new Vector3(1, Mathf.Cos(time * 4f), 0)

        DebugDraw.draw_box(box_pos, new Vector3(1, 2, 1), new Color(0, 1, 0), 0, false) # Box need to be NOT centered
        DebugDraw.draw_line_3d(line_begin, line_end, new Color(1, 1, 0))
        DebugDraw.set_text("Time", time)
        DebugDraw.set_text("Frames drawn", Engine.GetFramesDrawn())
        DebugDraw.set_text("FPS", Engine.GetFramesPerSecond())
        DebugDraw.set_text("delta", delta)
        return


    # Enable FPSGraph
    DebugDraw.FPSGraphEnabled = true
    DebugDraw.FPSGraphShowTextFlags = DebugDraw.FPSGraphTextFlags.Current | DebugDraw.FPSGraphTextFlags.Max | DebugDraw.FPSGraphTextFlags.Min
    DebugDraw.FPSGraphSize = new Vector2(200, 32)

    # Debug for debug
    DebugDraw.Freeze3DRender = Input.IsActionPressed("ui_accept")
    DebugDraw.ForceUseCameraFromScene = Input.IsActionPressed("ui_up")
    DebugDraw.DebugEnabled = !Input.IsActionPressed("ui_down")

    # Zones
    var col = Colors.Black
    foreach (Spatial z in GetNode<Spatial>("Zones").GetChildren()):
        DebugDraw.draw_box(z.GlobalTransform, col)

    # Spheres
    {
        DebugDraw.draw_sphere(GetNode<Spatial>("SphereTransform").GlobalTransform, Colors.Crimson)
        DebugDraw.draw_sphere(GetNode<Spatial>("SpherePosition").GlobalTransform.origin, 2, Colors.BlueViolet)
    }

    # Cylinders
    {
        DebugDraw.draw_cylinder(GetNode<Spatial>("Cylinder1").GlobalTransform, Colors.Crimson)
        DebugDraw.draw_cylinder(GetNode<Spatial>("Cylinder2").GlobalTransform.origin, 1, 2, Colors.Red)
    }

    # Boxes
    {
        DebugDraw.draw_box(GetNode<Spatial>("Box1").GlobalTransform, Colors.Purple)
        DebugDraw.draw_box(GetNode<Spatial>("Box2").GlobalTransform.origin, Vector3.One, Colors.RebeccaPurple)
        DebugDraw.draw_box(GetNode<Spatial>("Box3").GlobalTransform.origin, new Quat(Vector3.Up, Mathf.Pi * 0.25f), Vector3.One * 2, Colors.RosyBrown)

        var r = GetNode<Spatial>("AABB")
        DebugDraw.draw_aabb(r.GetChild<Spatial>(0).GlobalTransform.origin, r.GetChild<Spatial>(1).GlobalTransform.origin, Colors.DeepPink)

        DebugDraw.draw_aabb(new AABB(GetNode<Spatial>("AABB_fixed").GlobalTransform.origin, new Vector3(2, 1, 2)), Colors.Aqua)
    }

    # Lines
    {
        var target = GetNode<Spatial>("Lines/Target")
        DebugDraw.draw_billboard_square(target.GlobalTransform.origin, 0.5f, Colors.Red)

        # Normal
        {
            DebugDraw.draw_line_3d(GetNode<Spatial>("Lines/1").GlobalTransform.origin, target.GlobalTransform.origin, Colors.Fuchsia)
            DebugDraw.draw_ray_3d(GetNode<Spatial>("Lines/3").GlobalTransform.origin, (target.GlobalTransform.origin - GetNode<Spatial>("Lines/3").GlobalTransform.origin).Normalized(), 3f, Colors.Crimson)
        }

        # Arrow
        {
            DebugDraw.draw_arrow_line_3d(GetNode<Spatial>("Lines/2").GlobalTransform.origin, target.GlobalTransform.origin, Colors.Blue)
            DebugDraw.draw_arrow_ray_3d(GetNode<Spatial>("Lines/4").GlobalTransform.origin, (target.GlobalTransform.origin - GetNode<Spatial>("Lines/4").GlobalTransform.origin).Normalized(), 8f, Colors.Lavender)
        }

        # Path
        {
            DebugDraw.draw_line_path_3d(GetNode<Spatial>("LinePath")?.GetChildren().ToArray<Spatial>().Select((o) => o.GlobalTransform.origin).ToArray(), Colors.Beige)
            DebugDraw.draw_arrow_path_3d(GetNode<Spatial>("LinePath")?.GetChildren().ToArray<Spatial>().Select((o) => o.GlobalTransform.origin + Vector3.Down).ToArray(), Colors.Gold)
        }

        DebugDraw.draw_line_3d_hit(GetNode<Spatial>("Lines/5").GlobalTransform.origin, target.GlobalTransform.origin, true, Mathf.Abs(Mathf.Sin((float)DateTime.Now.TimeOfDay.TotalSeconds)), 0.25f, 0, Colors.Aqua)
    }

    # Misc
    {
        DebugDraw.draw_camera_frustum(GetNode<Camera>("Camera"), Colors.DarkOrange)
        DebugDraw.draw_billboard_square(GetNode<Spatial>("Billboard").GlobalTransform.origin, 0.5f, Colors.Green)
        DebugDraw.draw_position_3d(GetNode<Spatial>("Position").GlobalTransform, Colors.Brown)
    }

    # Text
    {
        DebugDraw.set_text("FPS", $"{Engine.GetFramesPerSecond():F2}", 0, Colors.Gold)

        DebugDraw.begin_text_group("-- First Group --", 2, Colors.ForestGreen)
        DebugDraw.set_text("Simple text")
        DebugDraw.set_text("Text", "Value", 0, Colors.Aquamarine)
        DebugDraw.set_text("Text out of order", null, -1, Colors.Silver)
        DebugDraw.begin_text_group("-- Second Group --", 1, Colors.Beige)
        DebugDraw.set_text("Rendered frames", $"{Engine.GetFramesDrawn()}")
        DebugDraw.end_text_group()

        DebugDraw.begin_text_group("-- Stats --", 3, Colors.Wheat)
        DebugDraw.set_text("Total rendered", DebugDraw.RenderCount.Total, 0)
        DebugDraw.set_text("Instances", DebugDraw.RenderCount.Instances, 1)
        DebugDraw.set_text("Wireframes", DebugDraw.RenderCount.Wireframes, 2)
        DebugDraw.end_text_group()
    }

    # Lag Test
    {
        if not Engine.EditorHint and box != null:
            box.Translation = start_pos + new Vector3(Mathf.Sin(OS.GetTicksMsec() / 100.0f) * 2.5f, 0, 0)
            DebugDraw.draw_box(box.GlobalTransform.origin, Vector3.One * 2f)
    }


# public static class Extensions
# {
#     public static T[] ToArray<T>(this Godot.Collections.Array array) where T : Godot.Node, new()
#     {
#         var res = new T[array.Count]
#         for (int i = 0 i < array.Count i++)
#             res[i] = array[i] as T
#         return res
#     }
# }
