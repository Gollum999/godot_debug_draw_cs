# TODO need 'tool'?
using GDArray = Godot.Collections.Array

# const INT_MAX = 2147483647
const INT_MAX: int = pow(2, 31) - 1

### <summary>
### Single-file autoload for debug drawing and printing.
### Draw and print on screen from anywhere in a single line of code.
###
### You can use only this file by adding it to autoload.
### Also you can use it in editor by enabling 'Debug Draw For Editor' plugin.
###
### No need to remove any code associated with this class in the release build.
### Canvas placed on layer 64.
### All positions in global space.
### Thread-safe (I hope).
### "Game Camera Override" is not supports, because no one in the Godot Core Team
### exposes methods to support this (but you can just disable culling see <see cref="UseFrustumCulling"/>).
### </summary>
extends Node
{
    enum BlockPosition
    {
        LEFT_TOP,
        RIGHT_TOP,
        LEFT_BOTTOM,
        RIGHT_BOTTOM,
    }

    enum FPSGraphTextFlags
    {
        NONE = 0,
        CURRENT = 1 << 0,
        AVERAGE = 1 << 1,
        MAX = 1 << 2,
        MIN = 1 << 3,
        ALL = CURRENT | AVERAGE | MAX | MIN,
    }

    class RenderCountData:
        instances: int
        wireframes: int
        total: int

        func _init(instances: int, wireframes: int):
            instances = instances
            wireframes = wireframes
            total = instances + wireframes

    # GENERAL

    ### <summary>
    ### Enable or disable all debug draw.
    ### </summary>
    public static bool DebugEnabled { get set } = true

    ### <summary>
    ### Debug for debug...
    ### </summary>
    public static bool Freeze3DRender { get set } = false

    ### <summary>
    ### Geometry culling based on camera frustum
    ### Change to false to disable it
    ### </summary>
    public static bool UseFrustumCulling { get set } = true

    ### <summary>
    ### Force use camera placed on edited scene. Usable for editor.
    ### </summary>
    public static bool ForceUseCameraFromScene { get set } = false

    # TEXT

    ### <summary>
    ### Position of text block
    ### </summary>
    public static BlockPosition TextBlockPosition { get set } = BlockPosition.LEFT_TOP

    ### <summary>
    ### Offset from the corner selected in <see cref="TextBlockPosition"/>
    ### </summary>
    public static Vector2 TextBlockOffset { get set } = Vector2(8, 8)

    ### <summary>
    ### Text padding for each line
    ### </summary>
    public static Vector2 TextPadding { get set } = Vector2(2, 1)

    ### <summary>
    ### How long HUD text lines remain shown after being invoked.
    ### </summary>
    public static TimeSpan TextDefaultDuration { get set } = TimeSpan.FromSeconds(0.5)

    ### <summary>
    ### Color of the text drawn as HUD
    ### </summary>
    public static Color TextForegroundColor { get set } = Color(1, 1, 1)

    ### <summary>
    ### Background color of the text drawn as HUD
    ### </summary>
    public static Color TextBackgroundColor { get set } = Color(0.3f, 0.3f, 0.3f, 0.8f)

    # FPS GRAPH

    ### <summary>
    ### Is FPSGraph enabled
    ### </summary>
    public static bool FPSGraphEnabled { get set } = false

    ### <summary>
    ### Switch between frame time and FPS modes
    ### </summary>
    public static bool FPSGraphFrameTimeMode { get set } = true

    ### <summary>
    ### Draw a graph line aligned vertically in the center
    ### </summary>
    public static bool FPSGraphCenteredGraphLine { get set } = true

    ### <summary>
    ### Sets the text visibility
    ### </summary>
    public static FPSGraphTextFlags FPSGraphShowTextFlags { get set } = FPSGraphTextFlags.ALL

    ### <summary>
    ### Size of the FPS Graph. The width is equal to the number of stored frames.
    ### </summary>
    public static Vector2 FPSGraphSize { get set } = Vector2(256, 64)

    ### <summary>
    ### Offset from the corner selected in <see cref="FPSGraphPosition"/>
    ### </summary>
    public static Vector2 FPSGraphOffset { get set } = Vector2(8, 8)

    ### <summary>
    ### FPS Graph position
    ### </summary>
    public static BlockPosition FPSGraphPosition { get set } = BlockPosition.RIGHT_TOP

    ### <summary>
    ### Graph line color
    ### </summary>
    public static Color FPSGraphLineColor { get set } = Color.orangered

    ### <summary>
    ### Color of the info text
    ### </summary>
    public static Color FPSGraphTextColor { get set } = Color.whitesmoke

    ### <summary>
    ### Background color
    ### </summary>
    public static Color FPSGraphBackgroundColor { get set } = Color(0.2f, 0.2f, 0.2f, 0.6f)

    ### <summary>
    ### Border color
    ### </summary>
    public static Color FPSGraphBorderColor { get set } = Color.black

    # GEOMETRY

    public static RenderCountData RenderCount
    {
#if DEBUG
        get
        {
            if internal_instance != null:
                return RenderCountData.new(internal_instance.render_instances, internal_instance.render_wireframes)
            else:
                return default
        }
#else
        get => default
#endif
    }

    ### <summary>
    ### Color of line with hit
    ### </summary>
    public static Color LineHitColor { get set } = Color.red

    ### <summary>
    ### Color of line after hit
    ### </summary>
    public static Color LineAfterHitColor { get set } = Color.green

    # Misc

    ### <summary>
    ### Custom <see cref="Viewport"/> to use for frustum culling.
    ### Usually used in editor.
    ### </summary>
    public static Viewport CustomViewport { get set } = null

    ### <summary>
    ### Custom <see cref="CanvasItem"/> to draw on it. Set to <see langword="null"/> to disable.
    ### </summary>
    public static CanvasItem CustomCanvas
    {
#if DEBUG
        get => internal_instance?.CustomCanvas
        set { if (internal_instance != null) internal_instance.CustomCanvas = value }
#else
        get set
#endif
    }

#if DEBUG

    static DebugDrawInternalFunctionality.DebugDrawImplementation internal_instance = null
    static DebugDraw instance = null

    ### <summary>
    ### Do not use it directly. This property will not be available without debug
    ### </summary>
    public static DebugDraw Instance
    {
        get => instance
    }

#endif

    #region Node Functions

#if DEBUG

    func _init():
        if instance == null:
            instance = self
        else:
            push_error("Only 1 instance of DebugDraw is allowed")

        Name = "DebugDraw"
        internal_instance = DebugDrawInternalFunctionality.DebugDrawImplementation.new(self)
    }

    func _enter_tree() -> void:
        set_meta("DebugDraw", true)

        # Specific for editor settings
        if Engine.editor_hint:
            TextBlockPosition = BlockPosition.LEFT_BOTTOM
            FPSGraphOffset = Vector2(12, 72)
            FPSGraphPosition = BlockPosition.LEFT_TOP

    protected override void Dispose(bool disposing)
    {
        if internal_instance != null:
            internal_instance.Dispose()
        internal_instance = null
        instance = null

        if NativeInstance != IntPtr.Zero and not is_queued_for_deletion():
            queue_free()
        base.Dispose(disposing)
    }

    func _exit_tree() -> void:
        if internal_instance != null:
            internal_instance.Dispose()
        internal_instance = null

    func _ready() -> void:
        ProcessPriority = int.MaxValue
        internal_instance.ready()

    func _process(delta: float) -> void:
        if internal_instance != null:
            internal_instance.update(delta)

#endif

    func on_canvas_item_draw(ci: CanvasItem) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.on_canvas_item_draw(ci)

    #endregion # Node Functions

    #region Static Draw Functions

    ### <summary>
    ### Clear all 3D objects
    ### </summary>
    static func clear_3d_objects() -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.clear_3d_objects_internal()

    ### <summary>
    ### Clear all 2D objects
    ### </summary>
    static func clear_2d_objects() -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.clear_2d_objects_internal()

    ### <summary>
    ### Clear all debug objects
    ### </summary>
    static func clear_all() -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.clear_all_internal()

    #region 3D

    #region Spheres

    ### <summary>
    ### Draw sphere
    ### </summary>
    ### <param name="position">Position of the sphere center</param>
    ### <param name="radius">Sphere radius</param>
    ### <param name="color">Sphere color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_sphere(position: Vector3, radius: float, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_sphere_internal(ref position, radius, ref color, duration)

    ### <summary>
    ### Draw sphere
    ### </summary>
    ### <param name="transform">Transform of the sphere</param>
    ### <param name="color">Sphere color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_sphere(transform: Transform, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_sphere_internal(ref transform, ref color, duration)

    #endregion # Spheres

    #region Cylinders

    ### <summary>
    ### Draw vertical cylinder
    ### </summary>
    ### <param name="position">Center position</param>
    ### <param name="radius">Cylinder radius</param>
    ### <param name="height">Cylinder height</param>
    ### <param name="color">Cylinder color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_cylinder(position: Vector3, radius: float, height: float, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_cylinder_internal(ref position, radius, height, ref color, duration)

    ### <summary>
    ### Draw vertical cylinder
    ### </summary>
    ### <param name="transform">Cylinder transform</param>
    ### <param name="color">Cylinder color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_cylinder(transform: Transform, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_cylinder_internal(ref transform, ref color, duration)

    #endregion # Cylinders

    #region Boxes

    ### <summary>
    ### Draw box
    ### </summary>
    ### <param name="position">Position of the box</param>
    ### <param name="size">Box size</param>
    ### <param name="color">Box color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    ### <param name="isBoxCentered">Use <paramref name="position"/> as center of the box</param>
    static func draw_box(position: Vector3, size: Vector3, color: Color? = null, duration: float = 0f, isBoxCentered: bool = true) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_box_internal(ref position, ref size, ref color, duration, isBoxCentered)

    ### <summary>
    ### Draw rotated box
    ### </summary>
    ### <param name="position">Position of the box</param>
    ### <param name="rotation">Box rotation</param>
    ### <param name="size">Box size</param>
    ### <param name="color">Box color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    ### <param name="isBoxCentered">Use <paramref name="position"/> as center of the box</param>
    static func draw_box(position: Vector3, rotation: Quat, size: Vector3, color: Color? = null, duration: float = 0f, isBoxCentered: bool = true) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_box_internal(ref position, ref rotation, ref size, ref color, duration, isBoxCentered)

    ### <summary>
    ### Draw rotated box
    ### </summary>
    ### <param name="transform">Box transform</param>
    ### <param name="color">Box color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    ### <param name="isBoxCentered">Use <paramref name="position"/> as center of the box</param>
    static func draw_box(transform: Transform, color: Color? = null, duration: float = 0f, isBoxCentered: bool = true) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_box_internal(ref transform, ref color, duration, isBoxCentered)

    ### <summary>
    ### Draw AABB from <paramref name="a"/> to <paramref name="b"/>
    ### </summary>
    ### <param name="a">Firts corner</param>
    ### <param name="b">Second corner</param>
    ### <param name="color">Box color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_aabb(a: Vector3, b: Vector3, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_aabb_internal(ref a, ref b, ref color, duration)

    ### <summary>
    ### Draw AABB
    ### </summary>
    ### <param name="aabb">AABB</param>
    ### <param name="color">Box color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_aabb(aabb: AABB, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_aabb_internal(ref aabb, ref color, duration)

    #endregion # Boxes

    #region Lines

    ### <summary>
    ### Draw line separated by hit point (billboard square) or not separated if <paramref name="is_hit"/> = <see langword="false"/>
    ### </summary>
    ### <param name="a">Start point</param>
    ### <param name="b">End point</param>
    ### <param name="is_hit">Is hit</param>
    ### <param name="unitOffsetOfHit">Unit offset on the line where the hit occurs</param>
    ### <param name="duration">Duration of existence in seconds</param>
    ### <param name="hitColor">Color of the hit point and line before hit</param>
    ### <param name="afterHitColor">Color of line after hit position</param>
    static func draw_line_3d_hit(a: Vector3, b: Vector3, is_hit: bool, unit_offset_of_hit: float = 0.5f, hit_size: float = 0.25f, duration: float = 0f, hit_color: Color? = null, after_hit_color: Color? = null) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_line_3d_hit_internal(ref a, ref b, is_hit, unit_offset_of_hit, hit_size, duration, ref hit_color, ref after_hit_color)

    #region Normal

    ### <summary>
    ### Draw line
    ### </summary>
    ### <param name="a">Start point</param>
    ### <param name="b">End point</param>
    ### <param name="color">Line color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_line_3d(a: Vector3, b: Vector3, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_line_3d_internal(ref a, ref b, ref color, duration)

    ### <summary>
    ### Draw ray
    ### </summary>
    ### <param name="origin">Origin</param>
    ### <param name="direction">Direction</param>
    ### <param name="length">Length</param>
    ### <param name="color">Ray color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_ray_3d(origin: Vector3, direction: Vector3, length: float, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_ray_3d_internal(origin, direction, length, color, duration)

    ### <summary>
    ### Draw a sequence of points connected by lines
    ### </summary>
    ### <param name="path">Sequence of points</param>
    ### <param name="color">Color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_line_path_3d(path: IList<Vector3>, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_line_path_3d_internal(path, color, duration)

    ### <summary>
    ### Draw a sequence of points connected by lines
    ### </summary>
    ### <param name="color">Color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    ### <param name="path">Sequence of points</param>
    static func draw_line_path_3d(Color? color = null, float duration = 0f, params Vector3[] path) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_line_path_3d_internal(color, duration, path)

    #endregion # Normal

    #region Arrows

    ### <summary>
    ### Draw line with arrow
    ### </summary>
    ### <param name="a">Start point</param>
    ### <param name="b">End point</param>
    ### <param name="color">Line color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    ### <param name="arrowSize">Size of the arrow</param>
    ### <param name="absoluteSize">Is the <paramref name="arrowSize"/> absolute or relative to the length of the line?</param>
    static func draw_arrow_line_3d(a: Vector3, b: Vector3, color: Color? = null, duration: float = 0f, arrow_size: float = 0.15f, absolute_size: bool = false) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_arrow_line_3d_internal(a, b, color, duration, arrow_size, absolute_size)

    ### <summary>
    ### Draw ray with arrow
    ### </summary>
    ### <param name="origin">Origin</param>
    ### <param name="direction">Direction</param>
    ### <param name="length">Length</param>
    ### <param name="color">Ray color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    ### <param name="arrowSize">Size of the arrow</param>
    ### <param name="absoluteSize">Is the <paramref name="arrowSize"/> absolute or relative to the length of the line?</param>
    static func draw_arrow_ray_3d(origin: Vector3, direction: Vector3, length: float, color: Color? = null, duration: float = 0f, arrow_size: float = 0.15f, absolute_size: bool = false) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_arrow_ray_3d_internal(origin, direction, length, color, duration, arrow_size, absolute_size)

    ### <summary>
    ### Draw a sequence of points connected by lines with arrows
    ### </summary>
    ### <param name="path">Sequence of points</param>
    ### <param name="color">Color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    ### <param name="arrowSize">Size of the arrow</param>
    ### <param name="absoluteSize">Is the <paramref name="arrowSize"/> absolute or relative to the length of the line?</param>
    static func draw_arrow_path_3d(path: IList<Vector3>, color: Color? = null, duration: float = 0f, arrow_size: float = 0.75f, absolute_size: bool = true) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_arrow_path_3d_internal(path, ref color, duration, arrow_size, absolute_size)

    ### <summary>
    ### Draw a sequence of points connected by lines with arrows
    ### </summary>
    ### <param name="color">Color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    ### <param name="path">Sequence of points</param>
    ### <param name="arrowSize">Size of the arrow</param>
    ### <param name="absoluteSize">Is the <paramref name="arrowSize"/> absolute or relative to the length of the line?</param>
    static func draw_arrow_path_3d(Color? color = null, float duration = 0f, float arrow_size = 0.75f, bool absolute_size = true, params Vector3[] path) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_arrow_path_3d_internal(ref color, duration, arrow_size, absolute_size, path)

    #endregion # Arrows
    #endregion # Lines

    #region Misc

    ### <summary>
    ### Draw a square that will always be turned towards the camera
    ### </summary>
    ### <param name="position">Center position of square</param>
    ### <param name="color">Color</param>
    ### <param name="size">Unit size</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_billboard_square(position: Vector3, size: float = 0.2f, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_billboard_square_internal(ref position, size, ref color, duration)

    #region Camera Frustum

    ### <summary>
    ### Draw camera frustum area
    ### </summary>
    ### <param name="camera">Camera node</param>
    ### <param name="color">Color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_camera_frustum(camera: Camera, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_camera_frustum_internal(ref camera, ref color, duration)

    ### <summary>
    ### Draw camera frustum area
    ### </summary>
    ### <param name="cameraFrustum">Array of frustum planes</param>
    ### <param name="color">Color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_camera_frustum(camera_frustum: GDArray, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_camera_frustum_internal(ref camera_frustum, ref color, duration)

    ### <summary>
    ### Draw camera frustum area
    ### </summary>
    ### <param name="planes">Array of frustum planes</param>
    ### <param name="color">Color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_camera_frustum(planes: Plane[], color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_camera_frustum_internal(ref planes, ref color, duration)

    #endregion # Camera Frustum

    ### <summary>
    ### Draw 3 intersecting lines with the given transformations
    ### </summary>
    ### <param name="transform">Transform</param>
    ### <param name="color">Color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_position_3d(transform: Transform, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_position_3d_internal(ref transform, ref color, duration)

    ### <summary>
    ### Draw 3 intersecting lines with the given transformations
    ### </summary>
    ### <param name="position">Center position</param>
    ### <param name="rotation">Rotation</param>
    ### <param name="scale">Scale</param>
    ### <param name="color">Color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_position_3d(position: Vector3, rotation: Quat, scale: Vector3, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_position_3d_internal(ref position, ref rotation, ref scale, ref color, duration)

    ### <summary>
    ### Draw 3 intersecting lines with the given transformations
    ### </summary>
    ### <param name="position">Center position</param>
    ### <param name="color">Color</param>
    ### <param name="scale">Uniform scale</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_position_3d(position: Vector3, color: Color? = null, scale: float = 0.25f, duration: float = 0f) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.draw_position_3d_internal(ref position, ref color, scale, duration)

    #endregion # Misc
    #endregion # 3D

    #region 2D

    ### <summary>
    ### Begin text group
    ### </summary>
    ### <param name="groupTitle">Group title and ID</param>
    ### <param name="groupPriority">Group priority</param>
    ### <param name="showTitle">Whether to show the title</param>
    static func begin_text_group(group_title: String, group_priority: int = 0, group_color: Color? = null, show_title: bool = true) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.begin_text_group_internal(group_title, group_priority, ref group_color, show_title)

    ### <summary>
    ### End text group. Should be called after <see cref="begin_text_group(String, int, bool)"/> if you don't need more than one group.
    ### If you need to create 2+ groups just call again <see cref="begin_text_group(String, int, bool)"/>
    ### and this function in the end.
    ### </summary>
    ### <param name="groupTitle">Group title and ID</param>
    ### <param name="groupPriority">Group priority</param>
    ### <param name="showTitle">Whether to show the title</param>
    static func end_text_group() -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.end_text_group_internal()

    ### <summary>
    ### Add or update text in overlay
    ### </summary>
    ### <param name="key">Name of field if <paramref name="value"/> exists, otherwise whole line will equal <paramref name="key"/>.</param>
    ### <param name="value">Value of field</param>
    ### <param name="priority">Priority of this line. Lower value is higher position.</param>
    ### <param name="duration">Expiration time</param>
    static func set_text(String key, object value = null, int priority = 0, Color? color_of_value = null, float duration = -1f) -> void:
        if OS.is_debug_build() and internal_instance != null:
            internal_instance.set_text_internal(ref key, ref value, priority, ref color_of_value, duration)

    #endregion # 2D

    #endregion
}

#if DEBUG

# TODO
namespace DebugDrawInternalFunctionality
{
    #region Renderable Primitives

    class SphereBounds:
        position: Vector3
        radius: float

    class TextGroup:
        title: String
        group_priority: int
        group_color: Color
        show_title: bool
        # TODO
        texts := Dictionary<String, DelayedText>.new()

        func _init(title: String, priority: int, show_title: bool, group_color: Color):
            title = title
            group_priority = priority
            show_title = show_title
            group_color = group_color

        func clean_texts(update: Action) -> void:
            # TODO
            var keysToRemove = Texts
                .Where(p => p.Value.is_expired())
                .Select(p => p.Key).ToArray()

            for k in keysToRemove:
                texts.remove(k)

            if keysToRemove.size() > 0:
                # TODO
                update?.Invoke()

    class DelayedText:
        var expiration_time: DateTime
        var text: String
        var priority: int
        var value_color: Color = null

        func _init(expiration_time: DateTime, text: String, priority: int, color: Color):
            expiration_time = expiration_time
            text = text
            priority = priority
            value_color = color

        func is_expired() -> bool:
            # TODO
            return not DebugDraw.DebugEnabled or (DateTime.Now - expiration_time).TotalMilliseconds > 0

    # NOTE: These were originally stored in an object pool in the C# version, but I decided to remove the pool for GDScript.
    #       Due to the more limited toolset, implementing a pool in GDScript would probably look a lot different, and likely wouldn't be very efficient.
    #       Revisit if performance becomes a problem.
    class DelayedRenderer:
        var expiration_time: DateTime
        var is_used_one_time: bool = false  # TODO HasBeenDrawnOneTime?
        var is_visible: bool = true

        func is_expired() -> bool:
            return not DebugDraw.DebugEnabled or ((DateTime.Now - expiration_time).TotalMilliseconds > 0 and is_used_one_time)

        # TODO just a reset, no point if I create a new one each time
        # func returned() -> void:
        #     is_used_one_time = false
        #     is_visible = true

    class DelayedRendererInstance extends DelayedRenderer:
        var instance_transform: Transform
        var instance_color: Color
        var bounds: SphereBounds = SphereBounds.new()

    class DelayedRendererLine extends DelayedRenderer:
        var bounds: AABB { get set }
        var lines_color: Color
        var Vector3[] _lines = Array.Empty<Vector3>()

        func virtual Vector3[] Lines
        {
            get => _lines
            set
            {
                _lines = value
                bounds = _calculate_bounds_based_on_lines(ref _lines)
            }
        }

        func _calculate_bounds_based_on_lines(ref Vector3[] lines) -> AABB:
            if lines.size() > 0:
                var b = AABB(lines[0], Vector3.ZERO)
                for v in lines:
                    b = b.Expand(v)

                return b
            else:
                return AABB()

    #endregion # Renderable Primitives

    class FPSGraph:
        var float[] frame_times = new float[1]
        var position: int = 0
        var filled: int = 0

        func update(delta: float) -> void:
            if delta == 0:
                return

            var length = clamp((int)DebugDraw.FPSGraphSize.x, 150, int.MaxValue)
            if frame_times.size() != length:
                frame_times = new float[length]
                frame_times[0] = delta
                # loop array
                frame_times[length - 1] = delta
                position = 1
                filled = 1
            else:
                frame_times[position] = delta
                position = posmod(position + 1, frame_times.size())
                filled = clamp(filled + 1, 0, frame_times.size())

        func draw(ci: CanvasItem, font: Font, viewport_size: Vector2) -> void:
            var not_zero = frame_times.Where((f) => f > 0f).Select((f) => DebugDraw.FPSGraphFrameTimeMode ? f * 1000 : 1f / f).ToArray()

            # No elements. Leave
            if not_zero.size() == 0:
                return

            # TODO fix names
            var max = not_zero.Max()
            var min = not_zero.Min()
            var avg = not_zero.Average()

            # Truncate for pixel perfect render
            var graph_size = Vector2(frame_times.size(), (int)DebugDraw.FPSGraphSize.y)
            var graph_offset = Vector2((int)DebugDraw.FPSGraphOffset.x, (int)DebugDraw.FPSGraphOffset.y)
            var pos = graph_offset

            match DebugDraw.FPSGraphPosition:
                DebugDraw.BlockPosition.LEFT_TOP: [[fallthrough]]  # TODO
                DebugDraw.BlockPosition.RIGHT_TOP:
                    pos = Vector2(viewport_size.x - graph_size.x - graph_offset.x, graph_offset.y)
                DebugDraw.BlockPosition.LEFT_BOTTOM:
                    pos = Vector2(graph_offset.x, viewport_size.y - graph_size.y - graph_offset.y)
                DebugDraw.BlockPosition.RIGHT_BOTTOM:
                    pos = Vector2(viewport_size.x - graph_size.x - graph_offset.x, viewport_size.y - graph_size.y - graph_offset.y)

            var height_multiplier = graph_size.y / max
            var center_offset = DebugDraw.FPSGraphCenteredGraphLine ? (graph_size.y - height_multiplier * (max - min)) * 0.5f : 0
            float get_warped(int idx) => not_zero[posmod(idx, not_zero.size())]
            float get_y_pos(int idx) => graph_size.y - get_warped(idx) * height_multiplier + center_offset

            var start = position - filled
            var prev = Vector2(0, get_y_pos(start)) + pos
            var border_size = Rect2(pos + Vector2.UP, graph_size + Vector2.DOWN)

            # Draw background
            ci.draw_rect(border_size, DebugDraw.FPSGraphBackgroundColor, true)

            # Draw framerate graph
            for (int i = 1 i < filled i++):
                var idx = posmod(start + i, not_zero.size())
                var v = pos + Vector2(i, (int)get_y_pos(idx))
                ci.draw_line(v, prev, DebugDraw.FPSGraphLineColor)
                prev = v

            # Draw border
            ci.draw_rect(border_size, DebugDraw.FPSGraphBorderColor, false)

            # Draw text
            var suffix = "ms" if DebugDraw.FPSGraphFrameTimeMode else "fps"

            var min_text = $"min: {min:F1} {suffix}"

            var max_text = $"max: {max:F1} {suffix}"
            var max_height = font.get_height()

            var avg_text = $"avg: {avg:F1} {suffix}"
            var avg_height = font.get_height()

            # `space` at the end of line for offset from border
            var cur_text = $"{get_warped(position - 1):F1} {suffix} "
            var cur_size = font.get_string_size(cur_text)

            if (DebugDraw.FPSGraphShowTextFlags & DebugDraw.FPSGraphTextFlags.MAX) == DebugDraw.FPSGraphTextFlags.MAX:
                ci.draw_string(font, pos + Vector2(4, max_height - 1), max_text, DebugDraw.FPSGraphTextColor)

            if (DebugDraw.FPSGraphShowTextFlags & DebugDraw.FPSGraphTextFlags.AVERAGE) == DebugDraw.FPSGraphTextFlags.AVERAGE:
                ci.draw_string(font, pos + Vector2(4, graph_size.y * 0.5f + avg_height * 0.5f - 2), avg_text, DebugDraw.FPSGraphTextColor)

            if (DebugDraw.FPSGraphShowTextFlags & DebugDraw.FPSGraphTextFlags.MIN) == DebugDraw.FPSGraphTextFlags.MIN:
                ci.draw_string(font, pos + Vector2(4, graph_size.y - 3), min_text, DebugDraw.FPSGraphTextColor)

            if (DebugDraw.FPSGraphShowTextFlags & DebugDraw.FPSGraphTextFlags.CURRENT) == DebugDraw.FPSGraphTextFlags.CURRENT:
                ci.draw_string(font, pos + Vector2(graph_size.x - cur_size.x, graph_size.y * 0.5f + cur_size.y * 0.5f - 2), cur_text, DebugDraw.FPSGraphTextColor)
    }

    class MultiMeshContainer
    {
        const Action<int> _add_rendered_objects = null

        const MultiMeshInstance _mmi_cubes = null
        const MultiMeshInstance _mmi_cubes_centered = null
        const MultiMeshInstance _mmi_arrowheads = null
        const MultiMeshInstance _mmi_billboard_squares = null
        const MultiMeshInstance _mmi_positions = null
        const MultiMeshInstance _mmi_spheres = null
        const MultiMeshInstance _mmi_cylinders = null

        const all_mmi_with_values: Dictionary = {  # TODO these keys are currently null
            _mmi_cubes: [],
            _mmi_cubes_centered: [],
            _mmi_arrowheads: [],
            _mmi_billboard_squares: [],
            _mmi_positions: [],
            _mmi_spheres: [],
            _mmi_cylinders: [],
        }

        # TODO could do properties, but I would have to write getter fns either way
        # TODO uniqueness doesn't matter for these
        const Cubes = all_mmi_with_values[_mmi_cubes]
        const CubesCentered = all_mmi_with_values[_mmi_cubes_centered]
        const Arrowheads = all_mmi_with_values[_mmi_arrowheads]
        const BillboardSquares = all_mmi_with_values[_mmi_billboard_squares]
        const Positions = all_mmi_with_values[_mmi_positions]
        const Spheres = all_mmi_with_values[_mmi_spheres]
        const Cylinders = all_mmi_with_values[_mmi_cylinders]

        func _init(root: Node, on_object_rendered: Action<int>):
            _add_rendered_objects = on_object_rendered

            # Create node with material and MultiMesh. Add to tree. Create array of instances
            _mmi_cubes = _create_mmi(root, nameof(_mmi_cubes))
            _mmi_cubes_centered = _create_mmi(root, nameof(_mmi_cubes_centered))
            _mmi_arrowheads = _create_mmi(root, nameof(_mmi_arrowheads))
            _mmi_billboard_squares = _create_mmi(root, nameof(_mmi_billboard_squares))
            _mmi_positions = _create_mmi(root, nameof(_mmi_positions))
            _mmi_spheres = _create_mmi(root, nameof(_mmi_spheres))
            _mmi_cylinders = _create_mmi(root, nameof(_mmi_cylinders))

            # Customize parameters
            (_mmi_billboard_squares.material_override as SpatialMaterial).params_billboard_mode = SpatialMaterial.BillboardMode.BILLBOARD_ENABLED
            (_mmi_billboard_squares.material_override as SpatialMaterial).params_billboard_keep_scale = true

            # Create Meshes
            _mmi_cubes.multimesh.mesh = _create_mesh(Mesh.PrimitiveType.PRIMITIVE_LINES, DebugDrawImplementation.CubeVertices, DebugDrawImplementation.CubeIndices)
            _mmi_cubes_centered.multimesh.mesh = _create_mesh(Mesh.PrimitiveType.PRIMITIVE_LINES, DebugDrawImplementation.CenteredCubeVertices, DebugDrawImplementation.CubeIndices)
            _mmi_arrowheads.multimesh.mesh = _create_mesh(Mesh.PrimitiveType.PRIMITIVE_LINES, DebugDrawImplementation.ArrowheadVertices, DebugDrawImplementation.ArrowheadIndices)
            _mmi_billboard_squares.multimesh.mesh = _create_mesh(Mesh.PrimitiveType.PRIMITIVE_TRIANGLES, DebugDrawImplementation.CenteredSquareVertices, DebugDrawImplementation.SquareIndices)
            _mmi_positions.multimesh.mesh = _create_mesh(Mesh.PrimitiveType.PRIMITIVE_LINES, DebugDrawImplementation.PositionVertices, DebugDrawImplementation.PositionIndices)
            _mmi_spheres.multimesh.mesh = _create_mesh(Mesh.PrimitiveType.PRIMITIVE_LINES, DebugDrawImplementation.create_sphere_lines(6, 6, 0.5f, Vector3.ZERO))
            _mmi_cylinders.multimesh.mesh = _create_mesh(Mesh.PrimitiveType.PRIMITIVE_LINES, DebugDrawImplementation.create_cylinder_lines(52, 0.5f, 1, Vector3.ZERO, 4))

        func _create_mmi(root: Node, name: String) -> MultiMeshInstance:
            var mmi = MultiMeshInstance.new()
            mmi.name = name
            mmi.cast_shadow = GeometryInstance.ShadowCastingSetting.SHADOW_CASTING_SETTING_OFF
            mmi.use_in_baked_light = false

            mmi.material_override = SpatialMaterial.new()
            mmi.material_override.flags_unshaded = true
            mmi.material_override.vertex_color_use_as_albedo = true

            mmi.multimesh = MultiMesh.new()
            mmi.multimesh.color_format = MultiMesh.ColorFormat.COLOR_FLOAT
            mmi.multimesh.custom_data_format = MultiMesh.CustomDataFormat.CUSTOM_DATA_NONE
            mmi.multimesh.transform_format = MultiMesh.TransformFormat.TRANSFORM_3D

            root.add_child(mmi)
            all_mmi_with_values.Add(mmi, new HashSet<DelayedRendererInstance>())
            return mmi

        func _create_mesh(type: Mesh.PrimitiveType, vertices: Vector3[], indices: int[] = null, colors: Color[] = null) -> ArrayMesh:
            var mesh = ArrayMesh.new()
            var a = GDArray.new()
            a.Resize(ArrayMesh.ArrayType.ARRAY_MAX)

            a[ArrayMesh.ArrayType.ARRAY_VERTEX] = vertices
            if indices != null:
                a[ArrayMesh.ArrayType.ARRAY_INDEX] = indices
            if colors != null:
                a[ArrayMesh.ArrayType.ARRAY_INDEX] = colors

            mesh.add_surface_from_arrays(type, a)

            return mesh

        # TODO
        func deinit() -> void:
            all_mmi_with_values.clear()

            for p in all_mmi_with_values:
                p.Key?.queue_free()

        func clear_instances() -> void:
            for item in all_mmi_with_values:
                item.Value.clear()

        func remove_expired(return_func: Action<DelayedRendererInstance>) -> void:
            for item in all_mmi_with_values:
                item.Value.RemoveWhere((o) =>
                {
                    if o == null or o.is_expired():
                        return_func(o)
                        return true
                    return false
                })

        func update_visibility(frustum: Plane[]) -> void:
            Parallel.ForEach(all_mmi_with_values, (item) => _update_visibility_internal(item.Value, frustum))

        func update_instances() -> void:
            for item in all_mmi_with_values:
                _update_instances_internal(item.Key, item.Value)

        func hide_all() -> void:
            for item in all_mmi_with_values:
                item.key.multimesh.visible_instance_count = 0

        func _update_instances_internal(mmi: MultiMeshInstance, instances: HashSet<DelayedRendererInstance>) -> void:
            if instances.size() > 0:
                if mmi.multimesh.instance_count < instances.size():
                    mmi.multimesh.instance_count = instances.size()
                mmi.multimesh.visible_instance_count = instances.Sum((inst) => inst.is_visible ? 1 : 0)
                _add_rendered_objects?.Invoke(mmi.multimesh.visible_instance_count)

                int i = 0
                for d in instances:
                    d.is_used_one_time = true
                    if d.is_visible:
                        mmi.multimesh.set_instance_transform(i, d.instance_transform)
                        mmi.multimesh.set_instance_color(i, d.instance_color)
                        i++
            else:
                mmi.multimesh.visible_instance_count = 0

        func _update_visibility_internal(instances: HashSet<DelayedRendererInstance>, frustum: Plane[]) -> void:
            for _mesh in instances:
                _mesh.is_visible = DebugDrawImplementation.bounds_partially_inside_convex_shape(_mesh.bounds, frustum)
    }

    # https://docs.microsoft.com/en-gb/dotnet/standard/collections/thread-safe/how-to-create-an-object-pool
    # class ObjectPool<T> where T : class, IPoolable, new()
    # {
    #     private const ConcurrentBag<T> _objects
    #     private const Func<T> _objectGenerator

    #     public ObjectPool(Func<T> objectGenerator)
    #     {
    #         _objectGenerator = objectGenerator ?? throw new ArgumentNullException(nameof(objectGenerator))
    #         _objects = new ConcurrentBag<T>()
    #     }

    #     # TODO: pulls an object out of the pool (or creates a new one)
    #     public T Get() => _objects.TryTake(out T item) ? item : _objectGenerator()

    #     # TODO: puts an object back in that was pulled via Get()
    #     public void return(T item)
    #     {
    #         _objects.Add(item)
    #         item.returned()
    #     }
    # }

    class DebugDrawImplementation extends IDisposable:
        # 2D

        var CanvasItemInternal: Node2D { get private set } = null
        var _canvas_layer: CanvasLayer = null
        var _canvas_needs_update: bool = true
        var _font: Font = null

        # fps
        const var fps_graph: FPSGraph = FPSGraph.new()

        # Text
        const var _text_groups: HashSet<TextGroup> = new HashSet<TextGroup>()
        var _current_text_group: TextGroup = null
        const var _default_text_group: TextGroup = TextGroup.new(null, 0, false, DebugDraw.TextForegroundColor)

        # 3D

        #region Predefined Geometry Parts

        public static float CubeDiagonalLengthForSphere = (Vector3.ONE * 0.5f).length()

        public static Vector3[] CenteredCubeVertices = Vector3[]{
            Vector3(-0.5f, -0.5f, -0.5f),
            Vector3(0.5f, -0.5f, -0.5f),
            Vector3(0.5f, -0.5f, 0.5f),
            Vector3(-0.5f, -0.5f, 0.5f),
            Vector3(-0.5f, 0.5f, -0.5f),
            Vector3(0.5f, 0.5f, -0.5f),
            Vector3(0.5f, 0.5f, 0.5f),
            Vector3(-0.5f, 0.5f, 0.5f)
        }
        public static Vector3[] CubeVertices = Vector3[]{
            Vector3(0, 0, 0),
            Vector3(1, 0, 0),
            Vector3(1, 0, 1),
            Vector3(0, 0, 1),
            Vector3(0, 1, 0),
            Vector3(1, 1, 0),
            Vector3(1, 1, 1),
            Vector3(0, 1, 1)
        }
        public static int[] CubeIndices = new int[] {
            0, 1,
            1, 2,
            2, 3,
            3, 0,

            4, 5,
            5, 6,
            6, 7,
            7, 4,

            0, 4,
            1, 5,
            2, 6,
            3, 7,
        }
        public static int[] CubeWithDiagonalsIndices = new int[] {
            0, 1,
            1, 2,
            2, 3,
            3, 0,

            4, 5,
            5, 6,
            6, 7,
            7, 4,

            0, 4,
            1, 5,
            2, 6,
            3, 7,

            # Diagonals

            # Top Bottom
            1, 3,
            #0, 2,
            4, 6,
            #5, 7,

            # Front Back
            1, 4,
            #0, 5,
            3, 6,
            #2, 7,

            # Left Right
            3, 4,
            #0, 7,
            1, 6,
            #2, 5,
        }
        public static Vector3[] ArrowheadVertices = Vector3[]
        {
            Vector3(0, 0, -1),
            Vector3(0, 0.25f, 0),
            Vector3(0, -0.25f, 0),
            Vector3(0.25f, 0, 0),
            Vector3(-0.25f, 0, 0),
            # Cross to center
            Vector3(0, 0, -0.2f),
        }
        public static int[] ArrowheadIndices = new int[]
        {
            0, 1,
            0, 2,
            0, 3,
            0, 4,
            # Cross
            #1, 2,
            #3, 4,
            # Or Cross to center
            5, 1,
            5, 2,
            5, 3,
            5, 4,
        }
        public static Vector3[] CenteredSquareVertices = Vector3[]
        {
            Vector3(0.5f, 0.5f, 0),
            Vector3(0.5f, -0.5f, 0),
            Vector3(-0.5f, -0.5f, 0),
            Vector3(-0.5f, 0.5f, 0),
        }
        public static int[] SquareIndices = new int[]
        {
            0, 1, 2,
            2, 3, 0,
        }
        public static Vector3[] PositionVertices = Vector3[]
        {
            Vector3(0.5f, 0, 0),
            Vector3(-0.5f, 0, 0),
            Vector3(0, 0.5f, 0),
            Vector3(0, -0.5f, 0),
            Vector3(0, 0, 0.5f),
            Vector3(0, 0, -0.5f),
        }
        public static int[] PositionIndices = new int[]
        {
            0, 1,
            2, 3,
            4, 5,
        }

        #endregion

        var _immediate_geometry: ImmediateGeometry = null
        var _mmc: MultiMeshContainer = null
        const _wire_meshes: HashSet<DelayedRendererLine> = new HashSet<DelayedRendererLine>()
        const _pool_wired_renderers: ObjectPool<DelayedRendererLine> = null
        const _pool_instance_renderers: ObjectPool<DelayedRendererInstance> = null
        var render_instances: int = 0
        var render_wireframes: int = 0

        # Misc

        var _data_mutex: Mutex = Mutex.new()
        const DebugDraw debug_draw = null
        var _is_ready: bool = false

        var _customCanvas: CanvasItem = null
        public CanvasItem CustomCanvas
        {
            get => _customCanvas
            set
            {
                var connected_internal = CanvasItemInternal.is_connected("draw", debug_draw, "on_canvas_item_draw")
                var connected_custom = _customCanvas != null and _customCanvas.is_connected("draw", debug_draw, "on_canvas_item_draw")

                if value == null:
                    if not connected_internal:
                        CanvasItemInternal.connect("draw", debug_draw, "on_canvas_item_draw", new GDArray { CanvasItemInternal })
                    if connected_custom:
                        _customCanvas?.disconnect("draw", debug_draw, "on_canvas_item_draw")
                else:
                    if connected_internal:
                        CanvasItemInternal.disconnect("draw", debug_draw, "on_canvas_item_draw")
                    if not connected_custom:
                        value.connect("draw", debug_draw, "on_canvas_item_draw", new GDArray { value })
                _customCanvas = value
            }
        }

        func _init(dd: DebugDraw) -> void:  # TODO should init return void?
            debug_draw = dd

            _pool_wired_renderers = new ObjectPool<DelayedRendererLine>(() => DelayedRendererLine.new())
            _pool_instance_renderers = new ObjectPool<DelayedRendererInstance>(() => DelayedRendererInstance.new())

        ### <summary>
        ### Must be called only once be DebugDraw class
        ### </summary>
        func ready() -> void:
            if not _is_ready:
                _is_ready = true

            # Funny hack to get default font
            var c = Control.new()
            debug_draw.add_child(c)
            _font = c.get_font("font")
            c.queue_free()

            # Setup default text group
            end_text_group_internal()

            # Create wireframe mesh drawer
            _immediate_geometry = ImmediateGeometry.new()
            _immediate_geometry.name = nameof(_immediate_geometry)
            _immediate_geometry.cast_shadow = GeometryInstance.ShadowCastingSetting.SHADOW_CASTING_SETTING_OFF
            _immediate_geometry.use_in_baked_light = false

            _immediate_geometry.material_override = SpatialMaterial.new()
            _immediate_geometry.material_override.flags_unshaded = true,
            _immediate_geometry.material_override.vertex_color_use_as_albedo = true

            debug_draw.add_child(_immediate_geometry)
            # Create MultiMeshInstance instances..
            _mmc = MultiMeshContainer.new(debug_draw, (i) => render_instances += i)

            # Create canvas item and canvas layer
            _canvas_layer = CanvasLayer.new() { Layer = 64 }
            CanvasItemInternal = Node2D.new()

            if CustomCanvas == null:
                CanvasItemInternal.connect("draw", debug_draw, "on_canvas_item_draw", new GDArray { CanvasItemInternal })

            debug_draw.add_child(_canvas_layer)
            _canvas_layer.add_child(CanvasItemInternal)

        public void Dispose()
        {
            _finalized_clear_all()
        }

        func _finalized_clear_all() -> void:
            _data_mutex.lock()
            {
                _text_groups.clear()
                _wire_meshes.clear()
                if _mmc != null:
                    _mmc.deinit()
                _mmc = null
            }
            _data_mutex.unlock()

            if _font != null:
                _font.Dispose()
            _font = null

            if CanvasItemInternal != null and CanvasItemInternal.is_connected("draw", debug_draw, "on_canvas_item_draw"):
                CanvasItemInternal.disconnect("draw", debug_draw, "on_canvas_item_draw")
            if _customCanvas != null and _customCanvas.is_connected("draw", debug_draw, "on_canvas_item_draw"):
                _customCanvas.disconnect("draw", debug_draw, "on_canvas_item_draw")

            if CanvasItemInternal != null:
                CanvasItemInternal.queue_free()
            CanvasItemInternal = null

            if _canvas_layer != null:
                _canvas_layer.queue_free()
            _canvas_layer = null

            if _immediate_geometry != null:
                _immediate_geometry.queue_free()
            _immediate_geometry = null

            # Clear editor canvas
            if CustomCanvas != null:
                CustomCanvas.update()

        func update(delta: float) -> void:
            _data_mutex.lock()
            {
                # Clean texts
                _text_groups.RemoveWhere((g) => g.Texts.size() == 0)
                foreach (var g in _text_groups) g.CleanTexts(() => _update_canvas())

                # Clean lines
                _wire_meshes.RemoveWhere((o) =>
                {
                    if o == null or o.is_expired():
                        _pool_wired_renderers.return(o)
                        return true
                    return false
                })

                # Clean instances
                _mmc.remove_expired((o) => _pool_instance_renderers.return(o))
            }
            _data_mutex.unlock()

            # FPS Graph
            fps_graph.update(delta)

            # Update overlay
            if _canvas_needs_update or DebugDraw.FPSGraphEnabled:
                if CustomCanvas == null:
                    CanvasItemInternal.update()
                else:
                    CustomCanvas.update()

                # reset some values
                _canvas_needs_update = false
                end_text_group_internal()

            # Update 3D debug
            _update_debug_geometry()

        func _update_debug_geometry() -> void:
            # Don't clear geometry for debug this debug class
            if DebugDraw.Freeze3DRender:
                return

            # Clear first and then leave
            _immediate_geometry.clear()

            render_instances = 0
            render_wireframes = 0

            # Return if nothing to do
            if not DebugDraw.DebugEnabled:
                _data_mutex.lock()
                _mmc?.hide_all()
                _data_mutex.unlock()
                return

            # Get camera frustum
            var frustum_array = DebugDraw.CustomViewport == null or DebugDraw.ForceUseCameraFromScene ?
                debug_draw.GetViewport().GetCamera()?.GetFrustum() :
                DebugDraw.CustomViewport.GetCamera().GetFrustum()

            # Convert frustum to C# array
            Plane[] f = null
            if frustum_array != null:
                f = new Plane[frustum_array.size()]
                for i in range(frustum_array.size()):
                    f[i] = ((Plane)frustum_array[i])

            # Check visibility of all objects

            _data_mutex.lock()
            {
                # Update visibility
                if DebugDraw.UseFrustumCulling and f != null:
                    # Update immediate geometry
                    for _lines in _wire_meshes:
                        _lines.is_visible = bounds_partially_inside_convex_shape(_lines.bounds, f)
                    # Update meshes
                    _mmc.update_visibility(f)

                _immediate_geometry.begin(Mesh.PrimitiveType.PRIMITIVE_LINES)
                # Line drawing much faster with only one Begin/End call
                for m in _wire_meshes:
                    m.is_used_one_time = true

                    if m.is_visible:
                        render_wireframes++
                        _immediate_geometry.set_color(m.lines_color)
                        for l in m.Lines:
                            _immediate_geometry.add_vertex(l)

                _immediate_geometry.end()

                {   # Debug bounds
                    #_immediate_geometry.Begin(Mesh.PrimitiveType.PRIMITIVE_LINES) foreach (var l in _wire_meshes) ___draw_debug_bounds_for_debug_line_primitives(l) _immediate_geometry.End()
                    #foreach (var l in _mmc.Cubes.ToArray()) _draw_debug_bounds_for_debug_instance_primitives(l)
                    #foreach (var l in _mmc.CubesCentered.ToArray()) _draw_debug_bounds_for_debug_instance_primitives(l)
                    #foreach (var l in _mmc.BillboardSquares.ToArray()) _draw_debug_bounds_for_debug_instance_primitives(l)
                    #foreach (var l in _mmc.Arrowheads.ToArray()) _draw_debug_bounds_for_debug_instance_primitives(l)
                    #foreach (var l in _mmc.Positions.ToArray()) _draw_debug_bounds_for_debug_instance_primitives(l)
                    #foreach (var l in _mmc.Spheres.ToArray()) _draw_debug_bounds_for_debug_instance_primitives(l)
                    #foreach (var l in _mmc.Cylinders.ToArray()) _draw_debug_bounds_for_debug_instance_primitives(l)
                }

                # Update MultiMeshInstances
                _mmc.update_instances()
            }
            _data_mutex.unlock()

        func on_canvas_item_draw(ci: CanvasItem) -> void:
            if not DebugDraw.DebugEnabled:
                return

            var time = DateTime.Now
            Vector2 vp_size = ci.has_meta("UseParentSize") ? ci.get_parent().RectSize : ci.get_viewport_rect().size

            _data_mutex.lock()
            { # Text drawing
                var count = _text_groups.Sum((g) => g.Texts.size() + (g.ShowTitle ? 1 : 0))

                const String separator = " : "

                var ascent: Vector2 = Vector2(0, _font.get_ascent())
                var font_offset: Vector2 = ascent + DebugDraw.TextPadding
                var line_height: float = _font.get_height() + DebugDraw.TextPadding.y * 2
                var pos: Vector2 = Vector2.ZERO
                var size_mul: float = 0

                switch (DebugDraw.TextBlockPosition)
                {
                    case DebugDraw.BlockPosition.LEFT_TOP:
                        pos = DebugDraw.TextBlockOffset
                        size_mul = 0
                        break
                    case DebugDraw.BlockPosition.RIGHT_TOP:
                        pos = Vector2(
                            vp_size.x - DebugDraw.TextBlockOffset.x,
                            DebugDraw.TextBlockOffset.y)
                        size_mul = -1
                        break
                    case DebugDraw.BlockPosition.LEFT_BOTTOM:
                        pos = Vector2(
                            DebugDraw.TextBlockOffset.x,
                            vp_size.y - DebugDraw.TextBlockOffset.y - line_height * count)
                        size_mul = 0
                        break
                    case DebugDraw.BlockPosition.RIGHT_BOTTOM:
                        pos = Vector2(
                            vp_size.x - DebugDraw.TextBlockOffset.x,
                            vp_size.y - DebugDraw.TextBlockOffset.y - line_height * count)
                        size_mul = -1
                        break
                }

                foreach (var g in _text_groups.OrderBy(g => g.group_priority))
                {
                    var a = g.Texts.OrderBy(t => t.Value.Priority).ThenBy(t => t.Key)

                    foreach (var t in g.ShowTitle ? a.Prepend(new KeyValuePair<String, DelayedText>(g.Title ?? "", null)) : a)
                    {
                        var keyText = t.Key if t.Key else ""
                        var text = t.Value?.Text == null ? keyText : $"{keyText}{separator}{t.Value.Text}"
                        var size = _font.get_string_size(text)
                        float size_right_revert = (size.x + DebugDraw.TextPadding.x * 2) * size_mul
                        ci.draw_rect(
                            Rect2(Vector2(pos.x + size_right_revert, pos.y),
                            Vector2(size.x + DebugDraw.TextPadding.x * 2, line_height)),
                            DebugDraw.TextBackgroundColor)

                        # Draw colored string
                        if t.Value == null or t.value.value_color == null or t.value.text == null:
                            ci.draw_string(_font, Vector2(pos.x + font_offset.x + size_right_revert, pos.y + font_offset.y), text, g.group_color)
                        else:
                            var textSep = $"{keyText}{separator}"
                            var _keyLength = textSep.size()
                            ci.draw_string(_font,
                                Vector2(pos.x + font_offset.x + size_right_revert, pos.y + font_offset.y),
                                text.Substring(0, _keyLength), g.group_color)
                            ci.draw_string(_font,
                                Vector2(pos.x + font_offset.x + size_right_revert + _font.get_string_size(textSep).x, pos.y + font_offset.y),
                                text.Substring(_keyLength), t.value.value_color)
                        pos.y += line_height
                    }
                }
            }
            _data_mutex.unlock()

            if DebugDraw.FPSGraphEnabled:
                fps_graph.draw(ci, _font, vp_size)
        }

        func _update_canvas() -> void:
            _canvas_needs_update = true

        #region Local Draw Functions

        func clear_3d_objects_internal() -> void:
            _data_mutex.lock()
            {
                _wire_meshes.clear()
                _mmc?.clear_instances()
            }
            _data_mutex.unlock()

        func clear_2d_objects_internal() -> void:
            _data_mutex.lock()
            {
                _text_groups.clear()
                _update_canvas()
            }
            _data_mutex.unlock()

        func clear_all_internal() -> void:
            clear_2d_objects_internal()
            clear_3d_objects_internal()

        #region 3D

        #region Spheres

        func draw_sphere_internal(ref Vector3 position, float radius, ref Color? color, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return

            var t = Transform.IDENTITY
            t.origin = position
            t.basis.scale = Vector3.ONE * (radius * 2)

            draw_sphere_internal(ref t, ref color, duration)

        func draw_sphere_internal(ref Transform transform, ref Color? color, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return

            _data_mutex.lock()
            {
                var inst = _pool_instance_renderers.Get()
                inst.instance_transform = transform
                inst.instance_color = color if color else Color.chartreuse
                inst.bounds.position = transform.origin
                inst.bounds.radius = transform.basis.scale.length() * 0.5f
                inst.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)

                _mmc.Spheres.Add(inst)
            }
            _data_mutex.unlock()

        #endregion # Spheres

        #region Cylinders

        func draw_cylinder_internal(position: Vector3, radius: float, height: float, color: Color?, duration: float) -> void:
            if not DebugDraw.DebugEnabled:
                return

            var t = Transform.IDENTITY
            t.origin = position
            t.basis.scale = Vector3(radius * 2, height, radius * 2)

            draw_cylinder_internal(ref t, ref color, duration)

        func draw_cylinder_internal(transform: Transform, color: Color?, duration: float) -> void:
            if not DebugDraw.DebugEnabled:
                return

            _data_mutex.lock()
            {
                var inst = _pool_instance_renderers.Get()
                inst.instance_transform = transform
                inst.instance_color = color if color else Color.yellow
                inst.bounds.position = transform.origin
                inst.bounds.radius = transform.basis.scale.length() * 0.5f
                inst.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)

                _mmc.Cylinders.Add(inst)
            }
            _data_mutex.unlock()

        #endregion # Cylinders

        #region Boxes

        func draw_box_internal(ref Vector3 position, ref Vector3 size, ref Color? color, float duration, bool isBoxCentered) -> void:
            if not DebugDraw.DebugEnabled:
                return

            var q = Quat.IDENTITY
            draw_box_internal(ref position, ref q, ref size, ref color, duration, isBoxCentered)

        func draw_box_internal(ref Vector3 position, ref Quat rotation, ref Vector3 size, ref Color? color, float duration, bool is_box_centered) -> void:
            if not DebugDraw.DebugEnabled:
                return

            _data_mutex.lock()
            {
                var t = Transform.new(rotation, position)
                t.basis.scale = size
                var radius = size.size() * 0.5f

                var inst = _pool_instance_renderers.Get()
                inst.instance_transform = t
                inst.instance_color = color if color else Color.forestgreen
                inst.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)
                inst.bounds.radius = radius

                if is_box_centered:
                    inst.bounds.position = t.origin
                else:
                    inst.bounds.position = t.origin + size * 0.5f

                if is_box_centered:
                    _mmc.CubesCentered.Add(inst)
                else:
                    _mmc.Cubes.Add(inst)
            }
            _data_mutex.unlock()

        func draw_box_internal(ref Transform transform, ref Color? color, float duration, bool is_box_centered) -> void:
            if not DebugDraw.DebugEnabled:
                return

            _data_mutex.lock()
            {
                var radius = transform.basis.scale.size() * 0.5f

                var inst = _pool_instance_renderers.Get()
                inst.instance_transform = transform
                inst.instance_color = color if color else Color.forestgreen
                inst.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)
                inst.bounds.radius = radius

                if is_box_centered:
                    inst.bounds.position = transform.origin
                else:
                    inst.bounds.position = transform.origin + transform.basis.scale * 0.5f

                if is_box_centered:
                    _mmc.CubesCentered.Add(inst)
                else:
                    _mmc.Cubes.Add(inst)
            }
            _data_mutex.unlock()

        func draw_aabb_internal(ref AABB box, ref Color? color, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return
            get_diagonal_vectors(box.position, box.End, out Vector3 bottom, out _, out Vector3 diag)
            draw_box_internal(ref bottom, ref diag, ref color, duration, false)

        func draw_aabb_internal(ref Vector3 a, ref Vector3 b, ref Color? color, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return
            get_diagonal_vectors(a, b, out Vector3 bottom, out _, out Vector3 diag)
            draw_box_internal(ref bottom, ref diag, ref color, duration, false)

        #endregion # Boxes

        #region Lines

        func draw_line_3d_hit_internal(ref Vector3 a, ref Vector3 b, bool is_hit, float unit_offset_of_hit, float hit_size, float duration, ref Color? hit_color, ref Color? after_hit_color) -> void:
            if not DebugDraw.DebugEnabled:
                return

            _data_mutex.lock()
            {
                if is_hit and unit_offset_of_hit >= 0 and unit_offset_of_hit <= 1.0f:
                    var time = DateTime.Now + TimeSpan.FromSeconds(duration)
                    var hit_pos = (b - a).normalized() * a.distance_to(b) * unit_offset_of_hit + a

                    # Get lines from pool and setup
                    var line_a = _pool_wired_renderers.Get()
                    var line_b = _pool_wired_renderers.Get()

                    line_a.Lines = Vector3[] { a, hit_pos }
                    line_a.lines_color = hit_color if hit_color else DebugDraw.LineHitColor
                    line_a.expiration_time = time

                    line_b.Lines = Vector3[] { hit_pos, b }
                    line_b.lines_color = after_hit_color if after_hit_color else DebugDraw.LineAfterHitColor
                    line_b.expiration_time = time

                    _wire_meshes.Add(line_a)
                    _wire_meshes.Add(line_b)

                    # Get instance from pool and setup
                    var t = Transform.new(Basis.IDENTITY, hit_pos)
                    t.basis.scale = Vector3.ONE * hit_size

                    var inst = _pool_instance_renderers.Get()
                    inst.instance_transform = t
                    inst.instance_color = hit_color if hit_color else DebugDraw.LineHitColor
                    inst.bounds.position = t.origin
                    inst.bounds.radius = CubeDiagonalLengthForSphere * hit_size
                    inst.expiration_time = time

                    _mmc.BillboardSquares.Add(inst)
                else:
                    var line = _pool_wired_renderers.Get()

                    line.Lines = Vector3[] { a, b }
                    line.lines_color = hit_color if hit_color else DebugDraw.LineHitColor
                    line.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)

                    _wire_meshes.Add(line)
            }
            _data_mutex.unlock()

        #region Normal

        func draw_line_3d_internal(ref Vector3 a, ref Vector3 b, ref Color? color, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return

            _data_mutex.lock()
            {
                var line = _pool_wired_renderers.Get()

                line.Lines = Vector3[] { a, b }
                line.lines_color = color if color else Color.lightgreen
                line.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)

                _wire_meshes.Add(line)
            }
            _data_mutex.unlock()

        func draw_ray_3d_internal(origin: Vector3, direction: Vector3, length: float, color: Color?, duration: float) -> void:
            if not DebugDraw.DebugEnabled:
                return

            var end = origin + direction * length
            draw_line_3d_internal(ref origin, ref end, ref color, duration)

        func draw_line_path_3d_internal(path: IList<Vector3>, color: Color?, duration: float = 0f) -> void:
            if not DebugDraw.DebugEnabled:
                return

            if path == null or path.size() <= 2:
                return

            _data_mutex.lock()
            {
                var line = _pool_wired_renderers.Get()

                line.Lines = create_lines_from_path(path)
                line.lines_color = color if color else Color.lightgreen
                line.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)

                _wire_meshes.Add(line)
            }
            _data_mutex.unlock()

        func draw_line_path_3d_internal(Color? color, float duration, params Vector3[] path) -> void:
            if not DebugDraw.DebugEnabled:
                return

            draw_line_path_3d_internal(path, color, duration)

        #endregion # Normal

        #region Arrows

        func draw_arrow_line_3d_internal(a: Vector3, b: Vector3, color: Color?, duration: float, arrow_size: float, absolute_size: bool) -> void:
            if not DebugDraw.DebugEnabled:
                return

            var line = _pool_wired_renderers.Get()

            line.Lines = Vector3[] { a, b }
            line.lines_color = color if color else Color.lightgreen
            line.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)

            _wire_meshes.Add(line)

            _generate_arrowhead_instance(ref a, ref b, ref color, ref duration, ref arrow_size, ref absolute_size)

        func draw_arrow_ray_3d_internal(origin: Vector3, direction: Vector3, length: float, color: Color?, duration: float, arrow_size: float, absolute_size: bool) -> void:
            if not DebugDraw.DebugEnabled:
                return

            draw_arrow_line_3d_internal(origin, origin + direction * length, color, duration, arrow_size, absolute_size)

        func draw_arrow_path_3d_internal(IList<Vector3> path, ref Color? color, float duration, float arrow_size, bool absolute_size) -> void:
            if not DebugDraw.DebugEnabled:
                return

            if path == null or path.size() < 2:
                return

            var line = _pool_wired_renderers.Get()
            line.Lines = create_lines_from_path(path)
            line.lines_color = color if color else Color.lightgreen
            line.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)
            _wire_meshes.Add(line)

            for i in range(path.size() - 1):
                Vector3 a = path[i], b = path[i + 1]
                _generate_arrowhead_instance(ref a, ref b, ref color, ref duration, ref arrow_size, ref absolute_size)

        func draw_arrow_path_3d_internal(ref Color? color, float duration, float arrow_size, bool absolute_size, params Vector3[] path) -> void:
            if not DebugDraw.DebugEnabled:
                return

            draw_arrow_path_3d_internal(path, ref color, duration, arrow_size, absolute_size)

        #endregion # Arrows
        #endregion # Lines

        #region Misc

        func draw_billboard_square_internal(ref Vector3 position, float size, ref Color? color, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return

            _data_mutex.lock()
            {
                var t = Transform.IDENTITY
                t.origin = position
                t.basis.scale = Vector3.ONE * size

                var inst = _pool_instance_renderers.Get()
                inst.instance_transform = t
                inst.instance_color = color if color else Color.red
                inst.bounds.position = t.origin
                inst.bounds.radius = CubeDiagonalLengthForSphere * size
                inst.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)

                _mmc.BillboardSquares.Add(inst)
            }
            _data_mutex.unlock()

        #region Camera Frustum

        func draw_camera_frustum_internal(ref Camera camera, ref Color? color, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return
            if camera == null:
                return

            var f = camera.GetFrustum()
            draw_camera_frustum_internal(ref f, ref color, duration)

        func draw_camera_frustum_internal(ref GDArray cameraFrustum, ref Color? color, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return
            if cameraFrustum.size() != 6:
                return

            Plane[] f = new Plane[cameraFrustum.size()]
            for i in range(cameraFrustum.size()):
                f[i] = ((Plane)cameraFrustum[i])

            draw_camera_frustum_internal(ref f, ref color, duration)

        func draw_camera_frustum_internal(ref Plane[] planes, ref Color? color, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return
            if planes.size() != 6:
                return

            _data_mutex.lock()
            {
                var line = _pool_wired_renderers.Get()

                line.Lines = create_camera_frustum_lines(planes)
                line.lines_color = color if color else Color.darksalmon
                line.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)

                _wire_meshes.Add(line)
            }
            _data_mutex.unlock()

        #endregion # Camera frustum

        func draw_position_3d_internal(ref Transform transform, ref Color? color, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return

            _data_mutex.lock()
            {
                var s = transform.basis.scale

                var inst = _pool_instance_renderers.Get()
                inst.instance_transform = transform
                inst.instance_color = color if color else Color.crimson
                inst.bounds.position = transform.origin
                inst.bounds.radius = _get_max_value(ref s) * 0.5f
                inst.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)

                _mmc.Positions.Add(inst)
            }
            _data_mutex.unlock()

        func draw_position_3d_internal(ref Vector3 position, ref Quat rotation, ref Vector3 scale, ref Color? color, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return

            var t = Transform.new(Basis.new(rotation), position)
            t.basis.scale = scale

            draw_position_3d_internal(ref t, ref color, duration)

        func draw_position_3d_internal(ref Vector3 position, ref Color? color, float scale, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return

            var t = Transform.new(Basis.IDENTITY, position)
            t.basis.scale = Vector3.ONE * scale

            draw_position_3d_internal(ref t, ref color, duration)

        #endregion # Misc
        #endregion # 3D

        #region 2D

        func begin_text_group_internal(String group_title, int group_priority, ref Color? group_color, bool show_title) -> void:
            _data_mutex.lock()
            {
                var new_group = _text_groups.FirstOrDefault(g => g.Title == group_title)
                if new_group != null:
                    new_group.ShowTitle = show_title
                    new_group.group_priority = group_priority
                    new_group.group_color = group_color if group_color else DebugDraw.TextForegroundColor
                else:
                    new_group = TextGroup.new(group_title, group_priority, show_title, group_color if group_color else DebugDraw.TextForegroundColor)
                    _text_groups.Add(new_group)
                _current_text_group = new_group
            }
            _data_mutex.unlock()

        func end_text_group_internal() -> void:
            _data_mutex.lock()
            {
                if not _text_groups.Contains(_default_text_group):
                    _text_groups.Add(_default_text_group)
                _current_text_group = _default_text_group

                # Update color
                _default_text_group.group_color = DebugDraw.TextForegroundColor
            }
            _data_mutex.unlock()

        func set_text_internal(ref String key, ref object value, int priority, ref Color? color_of_value, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return

            var new_time = DateTime.Now + (duration < 0 ? DebugDraw.TextDefaultDuration : TimeSpan.FromSeconds(duration))
            var str_val = value?.ToString()

            _data_mutex.lock()
            {
                if _current_text_group.Texts.ContainsKey(key):
                    var t = _current_text_group.Texts[key]
                    if str_val != t.Text:
                        _update_canvas()
                    t.Text = str_val
                    t.Priority = priority
                    t.expiration_time = new_time
                    t.value_color = color_of_value
                else:
                    _current_text_group.Texts[key] = DelayedText.new(new_time, str_val, priority, color_of_value)
                    _update_canvas()
            }
            _data_mutex.unlock()

        #endregion # 2D
        #endregion

        #region Utilities

        func _draw_debug_bounds_for_debug_line_primitives(dr: DelayedRendererLine) -> void:
            if not dr.is_visible:
                return

            var _lines = create_cube_lines(dr.bounds.position, Quat.IDENTITY, dr.bounds.size, false, true)

            render_wireframes++
            _immediate_geometry.set_color(Color.orange)
            for l in _lines:
                _immediate_geometry.add_vertex(l)

        func _draw_debug_bounds_for_debug_instance_primitive(dr: DelayedRendererInstance) -> void:
            if not dr.is_visible:
                return

            render_instances++
            var p = dr.bounds.position
            var r = dr.bounds.radius
            Color? c = Color.darkorange
            draw_sphere_internal(ref p, r, ref c, 0)

        func _generate_arrowhead_instance(ref Vector3 a, ref Vector3 b, ref Color? color, ref float duration, ref float arrow_size, ref bool absolute_size) -> void:
            _data_mutex.lock()
            {
                var offset = (b - a)
                var length = (absolute_size ? arrow_size : offset.size() * arrow_size)

                var t = Transform.new(Basis.IDENTITY, b - offset.normalized() * length).looking_at(b, Vector3.Up)
                t.basis.scale = Vector3.ONE * length
                var time = DateTime.Now + TimeSpan.FromSeconds(duration)

                var inst = _pool_instance_renderers.Get()
                inst.instance_transform = t
                inst.instance_color = color if color else Color.lightgreen
                inst.bounds.position = t.origin - t.basis.z * 0.5f
                inst.bounds.radius = CubeDiagonalLengthForSphere * length
                inst.expiration_time = time

                _mmc.Arrowheads.Add(inst)
            }
            _data_mutex.unlock()

        # Broken converter from Transform and Color to raw float[]
        static func _get_raw_multimesh_transforms(instances: ISet<DelayedRendererInstance>) -> float[]:
            float[] res = new float[instances.size() * 16]
            var index: int = 0

            for i in instances:
                i.is_used_one_time = true # needed for proper clear
                var idx: int = index
                index += 16

                res[idx + 0] = i.instance_transform.basis.Row0.x res[idx + 1] = i.instance_transform.basis.Row0.y
                res[idx + 2] = i.instance_transform.basis.Row0.z res[idx + 3] = i.instance_transform.basis.Row1.x
                res[idx + 4] = i.instance_transform.basis.Row1.y res[idx + 5] = i.instance_transform.basis.Row1.z
                res[idx + 6] = i.instance_transform.basis.Row2.x res[idx + 7] = i.instance_transform.basis.Row2.y
                res[idx + 8] = i.instance_transform.basis.Row2.z res[idx + 9] = i.instance_transform.origin.x
                res[idx + 10] = i.instance_transform.origin.y res[idx + 11] = i.instance_transform.origin.z
                res[idx + 12] = i.instance_color.r res[idx + 13] = i.instance_color.g
                res[idx + 14] = i.instance_color.b res[idx + 15] = i.instance_color.a

            return res

        #region Geometry Generation

        static func create_camera_frustum_lines(frustum: Plane[]) -> Vector3[]:
            if frustum.size() != 6:
                return Array.Empty<Vector3>()

            Vector3[] res = Vector3[CubeIndices.size()]

            #  near, far, left, top, right, bottom
            #  0,    1,   2,    3,   4,     5
            var cube = Vector3[]{
            frustum[0].Intersect3(frustum[3], frustum[2]).Value,
            frustum[0].Intersect3(frustum[3], frustum[4]).Value,
            frustum[0].Intersect3(frustum[5], frustum[4]).Value,
            frustum[0].Intersect3(frustum[5], frustum[2]).Value,

            frustum[1].Intersect3(frustum[3], frustum[2]).Value,
            frustum[1].Intersect3(frustum[3], frustum[4]).Value,
            frustum[1].Intersect3(frustum[5], frustum[4]).Value,
            frustum[1].Intersect3(frustum[5], frustum[2]).Value,

            for i in range(res.size()):
                res[i] = cube[CubeIndices[i]]

            return res

        static func create_cube_lines(position: Vector3, rotation: Quat, size: Vector3, centeredBox: bool = true, withDiagonals: bool = false) -> Vector3[]:
            Vector3[] scaled = Vector3[8]
            Vector3[] res = Vector3[withDiagonals ? CubeWithDiagonalsIndices.size() : CubeIndices.size()]

            bool dont_rot = rotation == Quat.IDENTITY

            Func<int, Vector3> get
            if centeredBox:
                if dont_rot:
                    get = (idx) => CenteredCubeVertices[idx] * size + position
                else:
                    get = (idx) => rotation.Xform(CenteredCubeVertices[idx] * size) + position
            else:
                if dont_rot:
                    get = (idx) => CubeVertices[idx] * size + position
                else:
                    get = (idx) => rotation.Xform(CubeVertices[idx] * size) + position

            for i in range(8):
                scaled[i] = get(i)

            if withDiagonals:
                for i in range(res.size()):
                    res[i] = scaled[CubeWithDiagonalsIndices[i]]
            else:
                for i in range(res.size()):
                    res[i] = scaled[CubeIndices[i]]

            return res

        static func create_sphere_lines(lats: int, lons: int, radius: float, position: Vector3) -> Vector3[]:
            if lats < 2:
                lats = 2
            if lons < 4:
                lons = 4

            Vector3[] res = Vector3[lats * lons * 6]
            int total = 0
            for (int i = 1 i <= lats i++):
                float lat0 = PI * (-0.5f + (float)(i - 1) / lats)
                float z0 = sin(lat0)
                float zr0 = cos(lat0)

                float lat1 = PI * (-0.5f + (float)i / lats)
                float z1 = sin(lat1)
                float zr1 = cos(lat1)

                for (int j = lons j >= 1 j--):
                    float lng0 = 2 * PI * (j - 1) / lons
                    float x0 = cos(lng0)
                    float y0 = sin(lng0)

                    float lng1 = 2 * PI * j / lons
                    float x1 = cos(lng1)
                    float y1 = sin(lng1)

                    Vector3[] v = Vector3[]{
                        Vector3(x1 * zr0, z0, y1 * zr0) * radius + position,
                        Vector3(x1 * zr1, z1, y1 * zr1) * radius + position,
                        Vector3(x0 * zr1, z1, y0 * zr1) * radius + position,
                        Vector3(x0 * zr0, z0, y0 * zr0) * radius + position
                    }

                    res[total++] = v[0]
                    res[total++] = v[1]
                    res[total++] = v[2]

                    res[total++] = v[2]
                    res[total++] = v[3]
                    res[total++] = v[0]

            return res

        static func create_cylinder_lines(edges: int, radius: float, height: float, position: Vector3, draw_edge_each_n_steps: int = 1) -> Vector3[]:
            var angle = 360f / edges

            List<Vector3> points = new List<Vector3>()

            Vector3 d = Vector3(0, height * 0.5f, 0)
            for i in range(edges):
                float ra = deg2rad(i * angle)
                float rb = deg2rad((i + 1) * angle)
                Vector3 a = Vector3(sin(ra), 0, cos(ra)) * radius + position
                Vector3 b = Vector3(sin(rb), 0, cos(rb)) * radius + position

                # Top
                points.Add(a + d)
                points.Add(b + d)

                # Bottom
                points.Add(a - d)
                points.Add(b - d)

                # Edge
                if i % draw_edge_each_n_steps == 0:
                    points.Add(a + d)
                    points.Add(a - d)

            return points.ToArray()

        static func create_lines_from_path(path: IList<Vector3>) -> Vector3[]:
            var res = Vector3[(path.size() - 1) * 2]

            for (int i = 1 i < path.size() - 1 i++):
                res[i * 2] = path[i]
                res[i * 2 + 1] = path[i + 1]
            return res

        #endregion # Geometry Generation

        static func get_diagonal_vectors(Vector3 a, Vector3 b, out Vector3 bottom, out Vector3 top, out Vector3 diag) -> void:
            bottom = Vector3.ZERO
            top = Vector3.ZERO

            if a.x > b.x:
                top.x = a.x
                bottom.x = b.x
            else:
                top.x = b.x
                bottom.x = a.x

            if a.y > b.y:
                top.y = a.y
                bottom.y = b.y
            else:
                top.y = b.y
                bottom.y = a.y

            if a.z > b.z:
                top.z = a.z
                bottom.z = b.z
            else:
                top.z = b.z
                bottom.z = a.z

            diag = top - bottom

        static func bounds_partially_inside_convex_shape(bounds: AABB, planes: IList<Plane>) -> bool:
            var extent = bounds.size * 0.5f
            var center = bounds.position + extent
            for p in planes:
                #if ((center - extent * p.Normal.Sign()).Dot(p.Normal) > p.D) #little slower i think
                if (Vector3(
                        center.x - extent.x * Math.Sign(p.Normal.x),
                        center.y - extent.y * Math.Sign(p.Normal.y),
                        center.z - extent.z * Math.Sign(p.Normal.z)
                        ).Dot(p.Normal) > p.D)
                    return false

            return true

        static func bounds_partially_inside_convex_shape(sphere: SphereBounds, planes: IList<Plane>) -> bool:
            for p in planes:
                if p.distance_to(sphere.position) >= sphere.radius:
                    return false

            return true

        static func _get_max_value(ref Vector3 value) -> float:
            return Math.Max(abs(value.x), Math.Max(abs(value.y), abs(value.z)))

        #endregion # Utilities

    }
}
#endif # DebugDrawImplementation
