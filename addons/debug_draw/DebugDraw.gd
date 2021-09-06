# TODO need 'tool'?
using GDArray = Godot.Collections.Array

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
        LeftTop,
        RightTop,
        LeftBottom,
        RightBottom,
    }

    enum FPSGraphTextFlags
    {
        None = 0,
        Current = 1 << 0,
        Avarage = 1 << 1,
        Max = 1 << 2,
        Min = 1 << 3,
        All = Current | Avarage | Max | Min,
    }

    class RenderCountData:
        instances: int
        wireframes: int
        total: int

        _init(instances: int, wireframes: int):
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
    public static BlockPosition TextBlockPosition { get set } = BlockPosition.LeftTop

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
    public static Color TextForegroundColor { get set } = new Color(1, 1, 1)

    ### <summary>
    ### Background color of the text drawn as HUD
    ### </summary>
    public static Color TextBackgroundColor { get set } = new Color(0.3f, 0.3f, 0.3f, 0.8f)

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
    public static FPSGraphTextFlags FPSGraphShowTextFlags { get set } = FPSGraphTextFlags.All

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
    public static BlockPosition FPSGraphPosition { get set } = BlockPosition.RightTop

    ### <summary>
    ### Graph line color
    ### </summary>
    public static Color FPSGraphLineColor { get set } = Colors.OrangeRed

    ### <summary>
    ### Color of the info text
    ### </summary>
    public static Color FPSGraphTextColor { get set } = Colors.WhiteSmoke

    ### <summary>
    ### Background color
    ### </summary>
    public static Color FPSGraphBackgroundColor { get set } = new Color(0.2f, 0.2f, 0.2f, 0.6f)

    ### <summary>
    ### Border color
    ### </summary>
    public static Color FPSGraphBorderColor { get set } = Colors.Black

    # GEOMETRY

    public static RenderCountData RenderCount
    {
#if DEBUG
        get
        {
            if (internalInstance != null)
                return new RenderCountData(internalInstance.renderInstances, internalInstance.renderWireframes)
            else
                return default
        }
#else
        get => default
#endif
    }

    ### <summary>
    ### Color of line with hit
    ### </summary>
    public static Color LineHitColor { get set } = Colors.Red

    ### <summary>
    ### Color of line after hit
    ### </summary>
    public static Color LineAfterHitColor { get set } = Colors.Green

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
        get => internalInstance?.CustomCanvas
        set { if (internalInstance != null) internalInstance.CustomCanvas = value }
#else
        get set
#endif
    }

#if DEBUG

    static DebugDrawInternalFunctionality.DebugDrawImplementation internalInstance = null
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
        internalInstance = new DebugDrawInternalFunctionality.DebugDrawImplementation(self)
    }

    func _enter_tree() -> void:
        set_meta("DebugDraw", true)

        # Specific for editor settings
        if Engine.editor_hint:
            TextBlockPosition = BlockPosition.LeftBottom
            FPSGraphOffset = Vector2(12, 72)
            FPSGraphPosition = BlockPosition.LeftTop

    protected override void Dispose(bool disposing)
    {
        internalInstance?.Dispose()
        internalInstance = null
        instance = null

        if NativeInstance != IntPtr.Zero and not IsQueuedForDeletion():
            queue_free()
        base.Dispose(disposing)
    }

    func _exit_tree() -> void:
        internalInstance?.Dispose()
        internalInstance = null

    func _ready() -> void:
        ProcessPriority = int.MaxValue
        internalInstance.ready()

    func _process(delta: float) ->
        internalInstance?.update(delta)

#endif

    func on_canvas_item_draw(ci: CanvasItem) -> void:
        if OS.is_debug_build():
            internalInstance?.on_canvas_item_draw(ci)

    #endregion # Node Functions

    #region Static Draw Functions

    ### <summary>
    ### Clear all 3D objects
    ### </summary>
    static func clear_3d_objects() -> void:
        if OS.is_debug_build():
            internalInstance?.clear_3d_objects_internal()

    ### <summary>
    ### Clear all 2D objects
    ### </summary>
    static func clear_2d_objects() -> void:
        if OS.is_debug_build():
            internalInstance?.clear_2d_objects_internal()

    ### <summary>
    ### Clear all debug objects
    ### </summary>
    static func clear_all() -> void:
        if OS.is_debug_build():
            internalInstance?.clear_all_internal()

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
        if OS.is_debug_build():
            internalInstance?.draw_sphere_internal(ref position, radius, ref color, duration)

    ### <summary>
    ### Draw sphere
    ### </summary>
    ### <param name="transform">Transform of the sphere</param>
    ### <param name="color">Sphere color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_sphere(transform: Transform, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build():
            internalInstance?.draw_sphere_internal(ref transform, ref color, duration)

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
        if OS.is_debug_build():
            internalInstance?.draw_cylinder_internal(ref position, radius, height, ref color, duration)

    ### <summary>
    ### Draw vertical cylinder
    ### </summary>
    ### <param name="transform">Cylinder transform</param>
    ### <param name="color">Cylinder color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_cylinder(transform: Transform, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build():
            internalInstance?.draw_cylinder_internal(ref transform, ref color, duration)

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
        if OS.is_debug_build():
            internalInstance?.draw_box_internal(ref position, ref size, ref color, duration, isBoxCentered)

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
        if OS.is_debug_build():
            internalInstance?.draw_box_internal(ref position, ref rotation, ref size, ref color, duration, isBoxCentered)

    ### <summary>
    ### Draw rotated box
    ### </summary>
    ### <param name="transform">Box transform</param>
    ### <param name="color">Box color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    ### <param name="isBoxCentered">Use <paramref name="position"/> as center of the box</param>
    static func draw_box(transform: Transform, color: Color? = null, duration: float = 0f, isBoxCentered: bool = true) -> void:
        if OS.is_debug_build():
            internalInstance?.draw_box_internal(ref transform, ref color, duration, isBoxCentered)

    ### <summary>
    ### Draw AABB from <paramref name="a"/> to <paramref name="b"/>
    ### </summary>
    ### <param name="a">Firts corner</param>
    ### <param name="b">Second corner</param>
    ### <param name="color">Box color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_aabb(a: Vector3, b: Vector3, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build():
            internalInstance?.draw_aabb_internal(ref a, ref b, ref color, duration)

    ### <summary>
    ### Draw AABB
    ### </summary>
    ### <param name="aabb">AABB</param>
    ### <param name="color">Box color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_aabb(aabb: AABB, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build():
            internalInstance?.draw_aabb_internal(ref aabb, ref color, duration)

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
    static func draw_line_3d_hit(a: Vector3, b: Vector3, is_hit: bool, unitOffsetOfHit: float = 0.5f, hitSize: float = 0.25f, duration: float = 0f, hitColor: Color? = null, afterHitColor: Color? = null) -> void:
        if OS.is_debug_build():
            internalInstance?.draw_line_3d_hit_internal(ref a, ref b, is_hit, unitOffsetOfHit, hitSize, duration, ref hitColor, ref afterHitColor)

    #region Normal

    ### <summary>
    ### Draw line
    ### </summary>
    ### <param name="a">Start point</param>
    ### <param name="b">End point</param>
    ### <param name="color">Line color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_line_3d(a: Vector3, b: Vector3, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build():
            internalInstance?.draw_line_3d_internal(ref a, ref b, ref color, duration)

    ### <summary>
    ### Draw ray
    ### </summary>
    ### <param name="origin">Origin</param>
    ### <param name="direction">Direction</param>
    ### <param name="length">Length</param>
    ### <param name="color">Ray color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_ray_3d(origin: Vector3, direction: Vector3, length: float, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build():
            internalInstance?.draw_ray_3d_internal(origin, direction, length, color, duration)

    ### <summary>
    ### Draw a sequence of points connected by lines
    ### </summary>
    ### <param name="path">Sequence of points</param>
    ### <param name="color">Color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_line_path_3d(path: IList<Vector3>, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build():
            internalInstance?.draw_line_path_3d_internal(path, color, duration)

    ### <summary>
    ### Draw a sequence of points connected by lines
    ### </summary>
    ### <param name="color">Color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    ### <param name="path">Sequence of points</param>
    static func draw_line_path_3d(Color? color = null, float duration = 0f, params Vector3[] path) -> void:
        if OS.is_debug_build():
            internalInstance?.draw_line_path_3d_internal(color, duration, path)

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
    static func draw_arrow_line_3d(a: Vector3, b: Vector3, color: Color? = null, duration: float = 0f, arrowSize: float = 0.15f, absoluteSize: bool = false) -> void:
        if OS.is_debug_build():
            internalInstance?.draw_arrow_line_3d_internal(a, b, color, duration, arrowSize, absoluteSize)

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
    static func draw_arrow_ray_3d(origin: Vector3, direction: Vector3, length: float, color: Color? = null, duration: float = 0f, arrowSize: float = 0.15f, absoluteSize: bool = false) -> void:
        if OS.is_debug_build():
            internalInstance?.draw_arrow_ray_3d_internal(origin, direction, length, color, duration, arrowSize, absoluteSize)

    ### <summary>
    ### Draw a sequence of points connected by lines with arrows
    ### </summary>
    ### <param name="path">Sequence of points</param>
    ### <param name="color">Color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    ### <param name="arrowSize">Size of the arrow</param>
    ### <param name="absoluteSize">Is the <paramref name="arrowSize"/> absolute or relative to the length of the line?</param>
    static func draw_arrow_path_3d(path: IList<Vector3>, color: Color? = null, duration: float = 0f, arrowSize: float = 0.75f, absoluteSize: bool = true) -> void:
        if OS.is_debug_build():
            internalInstance?.draw_arrow_path_3d_internal(path, ref color, duration, arrowSize, absoluteSize)

    ### <summary>
    ### Draw a sequence of points connected by lines with arrows
    ### </summary>
    ### <param name="color">Color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    ### <param name="path">Sequence of points</param>
    ### <param name="arrowSize">Size of the arrow</param>
    ### <param name="absoluteSize">Is the <paramref name="arrowSize"/> absolute or relative to the length of the line?</param>
    static func draw_arrow_path_3d(Color? color = null, float duration = 0f, float arrowSize = 0.75f, bool absoluteSize = true, params Vector3[] path) -> void:
        if OS.is_debug_build():
            internalInstance?.draw_arrow_path_3d_internal(ref color, duration, arrowSize, absoluteSize, path)

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
        if OS.is_debug_build():
            internalInstance?.draw_billboard_square_internal(ref position, size, ref color, duration)

    #region Camera Frustum

    ### <summary>
    ### Draw camera frustum area
    ### </summary>
    ### <param name="camera">Camera node</param>
    ### <param name="color">Color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_camera_frustum(camera: Camera, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build():
            internalInstance?.draw_camera_frustum_internal(ref camera, ref color, duration)

    ### <summary>
    ### Draw camera frustum area
    ### </summary>
    ### <param name="cameraFrustum">Array of frustum planes</param>
    ### <param name="color">Color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_camera_frustum(cameraFrustum: GDArray, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build():
            internalInstance?.draw_camera_frustum_internal(ref cameraFrustum, ref color, duration)

    ### <summary>
    ### Draw camera frustum area
    ### </summary>
    ### <param name="planes">Array of frustum planes</param>
    ### <param name="color">Color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_camera_frustum(planes: Plane[], color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build():
            internalInstance?.draw_camera_frustum_internal(ref planes, ref color, duration)

    #endregion # Camera Frustum

    ### <summary>
    ### Draw 3 intersecting lines with the given transformations
    ### </summary>
    ### <param name="transform">Transform</param>
    ### <param name="color">Color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_position_3d(transform: Transform, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build():
            internalInstance?.draw_position_3d_internal(ref transform, ref color, duration)

    ### <summary>
    ### Draw 3 intersecting lines with the given transformations
    ### </summary>
    ### <param name="position">Center position</param>
    ### <param name="rotation">Rotation</param>
    ### <param name="scale">Scale</param>
    ### <param name="color">Color</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_position_3d(position: Vector3, rotation: Quat, scale: Vector3, color: Color? = null, duration: float = 0f) -> void:
        if OS.is_debug_build():
            internalInstance?.draw_position_3d_internal(ref position, ref rotation, ref scale, ref color, duration)

    ### <summary>
    ### Draw 3 intersecting lines with the given transformations
    ### </summary>
    ### <param name="position">Center position</param>
    ### <param name="color">Color</param>
    ### <param name="scale">Uniform scale</param>
    ### <param name="duration">Duration of existence in seconds</param>
    static func draw_position_3d(position: Vector3, color: Color? = null, scale: float = 0.25f, duration: float = 0f) -> void:
        if OS.is_debug_build():
            internalInstance?.draw_position_3d_internal(ref position, ref color, scale, duration)

    #endregion # Misc
    #endregion # 3D

    #region 2D

    ### <summary>
    ### Begin text group
    ### </summary>
    ### <param name="groupTitle">Group title and ID</param>
    ### <param name="groupPriority">Group priority</param>
    ### <param name="showTitle">Whether to show the title</param>
    static func begin_text_group(groupTitle: String, groupPriority: int = 0, groupColor: Color? = null, showTitle: bool = true) -> void:
        if OS.is_debug_build():
            internalInstance?.begin_text_group_internal(groupTitle, groupPriority, ref groupColor, showTitle)

    ### <summary>
    ### End text group. Should be called after <see cref="begin_text_group(String, int, bool)"/> if you don't need more than one group.
    ### If you need to create 2+ groups just call again <see cref="begin_text_group(String, int, bool)"/>
    ### and this function in the end.
    ### </summary>
    ### <param name="groupTitle">Group title and ID</param>
    ### <param name="groupPriority">Group priority</param>
    ### <param name="showTitle">Whether to show the title</param>
    static func end_text_group() -> void:
        if OS.is_debug_build():
            internalInstance?.end_text_group_internal()

    ### <summary>
    ### Add or update text in overlay
    ### </summary>
    ### <param name="key">Name of field if <paramref name="value"/> exists, otherwise whole line will equal <paramref name="key"/>.</param>
    ### <param name="value">Value of field</param>
    ### <param name="priority">Priority of this line. Lower value is higher position.</param>
    ### <param name="duration">Expiration time</param>
    static func set_text(String key, object value = null, int priority = 0, Color? colorOfValue = null, float duration = -1f) -> void:
        if OS.is_debug_build():
            internalInstance?.set_text_internal(ref key, ref value, priority, ref colorOfValue, duration)

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
        texts := new Dictionary<String, DelayedText>()

        func _init(title: String, priority: int, show_title: bool, group_color: Color):
            title = title
            group_priority = priority
            show_title = show_title
            group_color = group_color

        func clean_texts(update: Action) -> void:
            # TODO
            var keysToRemove = Texts
                .Where(p => p.Value.IsExpired())
                .Select(p => p.Key).ToArray()

            for k in keysToRemove:
                texts.remove(k)

            if keysToRemove.length() > 0:
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
        # func Returned() -> void:
        #     is_used_one_time = false
        #     is_visible = true

    class DelayedRendererInstance extends DelayedRenderer:
        var InstanceTransform: Transform
        var InstanceColor: Color
        var Bounds: SphereBounds = new SphereBounds()

    class DelayedRendererLine extends DelayedRenderer:
        var Bounds: AABB { get set }
        var LinesColor: Color
        var Vector3[] _lines = Array.Empty<Vector3>()

        func virtual Vector3[] Lines
        {
            get => _lines
            set
            {
                _lines = value
                Bounds = _calculate_bounds_based_on_lines(ref _lines)
            }
        }

        func _calculate_bounds_based_on_lines(ref Vector3[] lines) -> AABB:
            if lines.Length > 0:
                var b = new AABB(lines[0], Vector3.Zero)
                for v in lines:
                    b = b.Expand(v)

                return b
            else:
                return new AABB()

    #endregion # Renderable Primitives

    class FPSGraph:
        var float[] frameTimes = new float[1]
        var position: int = 0
        var filled: int = 0

        func update(delta: float) -> void:
            if delta == 0:
                return

            var length = Mathf.Clamp((int)DebugDraw.FPSGraphSize.x, 150, int.MaxValue)
            if frameTimes.length != length:
                frameTimes = new float[length]
                frameTimes[0] = delta
                # loop array
                frameTimes[length - 1] = delta
                position = 1
                filled = 1
            else:
                frameTimes[position] = delta
                position = Mathf.PosMod(position + 1, frameTimes.Length)
                filled = Mathf.Clamp(filled + 1, 0, frameTimes.Length)

        func draw(ci: CanvasItem, font: Font, viewportSize: Vector2) -> void:
            var notZero = frameTimes.Where((f) => f > 0f).Select((f) => DebugDraw.FPSGraphFrameTimeMode ? f * 1000 : 1f / f).ToArray()

            # No elements. Leave
            if notZero.length() == 0:
                return

            var max = notZero.Max()
            var min = notZero.Min()
            var avg = notZero.Average()

            # Truncate for pixel perfect render
            var graphSize = Vector2(frameTimes.Length, (int)DebugDraw.FPSGraphSize.y)
            var graphOffset = Vector2((int)DebugDraw.FPSGraphOffset.x, (int)DebugDraw.FPSGraphOffset.y)
            var pos = graphOffset

            match DebugDraw.FPSGraphPosition:
                DebugDraw.BlockPosition.LeftTop: [[fallthrough]]  # TODO
                DebugDraw.BlockPosition.RightTop:
                    pos = Vector2(viewportSize.x - graphSize.x - graphOffset.x, graphOffset.y)
                DebugDraw.BlockPosition.LeftBottom:
                    pos = Vector2(graphOffset.x, viewportSize.y - graphSize.y - graphOffset.y)
                DebugDraw.BlockPosition.RightBottom:
                    pos = Vector2(viewportSize.x - graphSize.x - graphOffset.x, viewportSize.y - graphSize.y - graphOffset.y)

            var height_multiplier = graphSize.y / max
            var center_offset = DebugDraw.FPSGraphCenteredGraphLine ? (graphSize.y - height_multiplier * (max - min)) * 0.5f : 0
            float get_warped(int idx) => notZero[Mathf.PosMod(idx, notZero.Length)]
            float get_y_pos(int idx) => graphSize.y - get_warped(idx) * height_multiplier + center_offset

            var start = position - filled
            var prev = Vector2(0, get_y_pos(start)) + pos
            var border_size = new Rect2(pos + Vector2.Up, graphSize + Vector2.Down)

            # Draw background
            ci.draw_rect(border_size, DebugDraw.FPSGraphBackgroundColor, true)

            # Draw framerate graph
            for (int i = 1 i < filled i++):
                var idx = Mathf.PosMod(start + i, notZero.Length)
                var v = pos + Vector2(i, (int)get_y_pos(idx))
                ci.DrawLine(v, prev, DebugDraw.FPSGraphLineColor)
                prev = v

            # Draw border
            ci.draw_rect(border_size, DebugDraw.FPSGraphBorderColor, false)

            # Draw text
            var suffix = (DebugDraw.FPSGraphFrameTimeMode ? "ms" : "fps")

            var min_text = $"min: {min:F1} {suffix}"

            var max_text = $"max: {max:F1} {suffix}"
            var max_height = font.GetHeight()

            var avg_text = $"avg: {avg:F1} {suffix}"
            var avg_height = font.GetHeight()

            # `space` at the end of line for offset from border
            var cur_text = $"{get_warped(position - 1):F1} {suffix} "
            var cur_size = font.GetStringSize(cur_text)

            if (DebugDraw.FPSGraphShowTextFlags & DebugDraw.FPSGraphTextFlags.Max) == DebugDraw.FPSGraphTextFlags.Max:
                ci.DrawString(font, pos + Vector2(4, max_height - 1), max_text, DebugDraw.FPSGraphTextColor)

            if (DebugDraw.FPSGraphShowTextFlags & DebugDraw.FPSGraphTextFlags.Avarage) == DebugDraw.FPSGraphTextFlags.Avarage:
                ci.DrawString(font, pos + Vector2(4, graphSize.y * 0.5f + avg_height * 0.5f - 2), avg_text, DebugDraw.FPSGraphTextColor)

            if (DebugDraw.FPSGraphShowTextFlags & DebugDraw.FPSGraphTextFlags.Min) == DebugDraw.FPSGraphTextFlags.Min:
                ci.DrawString(font, pos + Vector2(4, graphSize.y - 3), min_text, DebugDraw.FPSGraphTextColor)

            if (DebugDraw.FPSGraphShowTextFlags & DebugDraw.FPSGraphTextFlags.Current) == DebugDraw.FPSGraphTextFlags.Current:
                ci.DrawString(font, pos + Vector2(graphSize.x - cur_size.x, graphSize.y * 0.5f + cur_size.y * 0.5f - 2), cur_text, DebugDraw.FPSGraphTextColor)
    }

    class MultiMeshContainer
    {
        readonly Action<int> addRenderedObjects = null

        readonly MultiMeshInstance _mmi_cubes = null
        readonly MultiMeshInstance _mmi_cubes_centered = null
        readonly MultiMeshInstance _mmi_arrowheads = null
        readonly MultiMeshInstance _mmi_billboard_squares = null
        readonly MultiMeshInstance _mmi_positions = null
        readonly MultiMeshInstance _mmi_spheres = null
        readonly MultiMeshInstance _mmi_cylinders = null

        # TODO could do properties, but I would have to write getter fns either way
        public HashSet<DelayedRendererInstance> Cubes { get => all_mmi_with_values[_mmi_cubes] }
        public HashSet<DelayedRendererInstance> CubesCentered { get => all_mmi_with_values[_mmi_cubes_centered] }
        public HashSet<DelayedRendererInstance> Arrowheads { get => all_mmi_with_values[_mmi_arrowheads] }
        public HashSet<DelayedRendererInstance> BillboardSquares { get => all_mmi_with_values[_mmi_billboard_squares] }
        public HashSet<DelayedRendererInstance> Positions { get => all_mmi_with_values[_mmi_positions] }
        public HashSet<DelayedRendererInstance> Spheres { get => all_mmi_with_values[_mmi_spheres] }
        public HashSet<DelayedRendererInstance> Cylinders { get => all_mmi_with_values[_mmi_cylinders] }

        readonly Dictionary<MultiMeshInstance, HashSet<DelayedRendererInstance>> all_mmi_with_values =
            new Dictionary<MultiMeshInstance, HashSet<DelayedRendererInstance>>()  # TODO this is crucial

        func _init(root: Node, onObjectRendered: Action<int>):
            addRenderedObjects = onObjectRendered

            # Create node with material and MultiMesh. Add to tree. Create array of instances
            _mmi_cubes = _create_mmi(root, nameof(_mmi_cubes))
            _mmi_cubes_centered = _create_mmi(root, nameof(_mmi_cubes_centered))
            _mmi_arrowheads = _create_mmi(root, nameof(_mmi_arrowheads))
            _mmi_billboard_squares = _create_mmi(root, nameof(_mmi_billboard_squares))
            _mmi_positions = _create_mmi(root, nameof(_mmi_positions))
            _mmi_spheres = _create_mmi(root, nameof(_mmi_spheres))
            _mmi_cylinders = _create_mmi(root, nameof(_mmi_cylinders))

            # Customize parameters
            (_mmi_billboard_squares.MaterialOverride as SpatialMaterial).ParamsBillboardMode = SpatialMaterial.BillboardMode.Enabled
            (_mmi_billboard_squares.MaterialOverride as SpatialMaterial).ParamsBillboardKeepScale = true

            # Create Meshes
            _mmi_cubes.multimesh.mesh = _create_mesh(Mesh.PrimitiveType.Lines, DebugDrawImplementation.CubeVertices, DebugDrawImplementation.CubeIndices)
            _mmi_cubes_centered.multimesh.mesh = _create_mesh(Mesh.PrimitiveType.Lines, DebugDrawImplementation.CenteredCubeVertices, DebugDrawImplementation.CubeIndices)
            _mmi_arrowheads.multimesh.mesh = _create_mesh(Mesh.PrimitiveType.Lines, DebugDrawImplementation.ArrowheadVertices, DebugDrawImplementation.ArrowheadIndices)
            _mmi_billboard_squares.multimesh.mesh = _create_mesh(Mesh.PrimitiveType.Triangles, DebugDrawImplementation.CenteredSquareVertices, DebugDrawImplementation.SquareIndices)
            _mmi_positions.multimesh.mesh = _create_mesh(Mesh.PrimitiveType.Lines, DebugDrawImplementation.PositionVertices, DebugDrawImplementation.PositionIndices)
            _mmi_spheres.multimesh.mesh = _create_mesh(Mesh.PrimitiveType.Lines, DebugDrawImplementation.create_sphere_lines(6, 6, 0.5f, Vector3.Zero))
            _mmi_cylinders.multimesh.mesh = _create_mesh(Mesh.PrimitiveType.Lines, DebugDrawImplementation.create_cylinder_lines(52, 0.5f, 1, Vector3.Zero, 4))

        func _create_mmi(root: Node, name: String) -> MultiMeshInstance:
            var mmi = new MultiMeshInstance()
            {
                Name = name,
                CastShadow = GeometryInstance.ShadowCastingSetting.Off,
                UseInBakedLight = false,

                MaterialOverride = new SpatialMaterial()
                {
                    FlagsUnshaded = true,
                    VertexColorUseAsAlbedo = true
                }
            }
            mmi.Multimesh = new MultiMesh()
            {
                ColorFormat = MultiMesh.ColorFormatEnum.Float,
                CustomDataFormat = MultiMesh.CustomDataFormatEnum.None,
                TransformFormat = MultiMesh.TransformFormatEnum.Transform3d,
            }

            root.add_child(mmi)
            all_mmi_with_values.Add(mmi, new HashSet<DelayedRendererInstance>())
            return mmi

        func _create_mesh(type: Mesh.PrimitiveType, vertices: Vector3[], indices: int[] = null, colors: Color[] = null) -> ArrayMesh:
            var mesh = new ArrayMesh()
            var a = new GDArray()
            a.Resize((int)ArrayMesh.ArrayType.Max)

            a[(int)ArrayMesh.ArrayType.Vertex] = vertices
            if indices != null:
                a[(int)ArrayMesh.ArrayType.Index] = indices
            if colors != null:
                a[(int)ArrayMesh.ArrayType.Index] = colors

            mesh.AddSurfaceFromArrays(type, a)

            return mesh

        # TODO
        func Deinit() -> void:
            all_mmi_with_values.Clear()

            for p in all_mmi_with_values:
                p.Key?.queue_free()

        func clear_instances() -> void:
            foreach (var item in all_mmi_with_values):
                item.Value.Clear()

        func remove_expired(returnFunc: Action<DelayedRendererInstance>) -> void:
            for item in all_mmi_with_values:
                item.Value.RemoveWhere((o) =>
                {
                    if o == null or o.IsExpired():
                        returnFunc(o)
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
                item.Key.Multimesh.VisibleInstanceCount = 0

        func _update_instances_internal(mmi: MultiMeshInstance, instances: HashSet<DelayedRendererInstance>) -> void:
            if instances.Count > 0:
                if mmi.Multimesh.InstanceCount < instances.Count:
                    mmi.Multimesh.InstanceCount = instances.Count
                mmi.Multimesh.VisibleInstanceCount = instances.Sum((inst) => inst.is_visible ? 1 : 0)
                addRenderedObjects?.Invoke(mmi.Multimesh.VisibleInstanceCount)

                int i = 0
                for d in instances:
                    d.is_used_one_time = true
                    if d.is_visible:
                        mmi.Multimesh.SetInstanceTransform(i, d.InstanceTransform)
                        mmi.Multimesh.SetInstanceColor(i, d.InstanceColor)
                        i++
            else:
                mmi.Multimesh.VisibleInstanceCount = 0

        func _update_visibility_internal(instances: HashSet<DelayedRendererInstance>, frustum: Plane[]) -> void:
            for _mesh in instances:
                _mesh.is_visible = DebugDrawImplementation.bounds_partially_inside_convex_shape(_mesh.Bounds, frustum)
    }

    # https://docs.microsoft.com/en-gb/dotnet/standard/collections/thread-safe/how-to-create-an-object-pool
    # class ObjectPool<T> where T : class, IPoolable, new()
    # {
    #     private readonly ConcurrentBag<T> _objects
    #     private readonly Func<T> _objectGenerator

    #     public ObjectPool(Func<T> objectGenerator)
    #     {
    #         _objectGenerator = objectGenerator ?? throw new ArgumentNullException(nameof(objectGenerator))
    #         _objects = new ConcurrentBag<T>()
    #     }

    #     # TODO: pulls an object out of the pool (or creates a new one)
    #     public T Get() => _objects.TryTake(out T item) ? item : _objectGenerator()

    #     # TODO: puts an object back in that was pulled via Get()
    #     public void Return(T item)
    #     {
    #         _objects.Add(item)
    #         item.Returned()
    #     }
    # }

    class DebugDrawImplementation extends IDisposable:
        # 2D

        public Node2D CanvasItemInternal { get private set } = null
        CanvasLayer _canvasLayer = null
        bool _canvasNeedUpdate = true
        Font _font = null

        # fps
        readonly FPSGraph fpsGraph = new FPSGraph()

        # Text
        readonly HashSet<TextGroup> _textGroups = new HashSet<TextGroup>()
        TextGroup _currentTextGroup = null
        readonly TextGroup _defaultTextGroup = new TextGroup(null, 0, false, DebugDraw.TextForegroundColor)

        # 3D

        #region Predefined Geometry Parts

        public static float CubeDiagonalLengthForSphere = (Vector3.ONE * 0.5f).Length()

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

        ImmediateGeometry _immediateGeometry = null
        MultiMeshContainer _mmc = null
        readonly HashSet<DelayedRendererLine> _wireMeshes = new HashSet<DelayedRendererLine>()
        readonly ObjectPool<DelayedRendererLine> _poolWiredRenderers = null
        readonly ObjectPool<DelayedRendererInstance> _poolInstanceRenderers = null
        public int renderInstances = 0
        public int renderWireframes = 0

        # Misc

        readonly object dataLock = new object()
        readonly DebugDraw debugDraw = null
        bool is_ready = false

        CanvasItem _customCanvas = null
        public CanvasItem CustomCanvas
        {
            get => _customCanvas
            set
            {
                var connected_internal = CanvasItemInternal.is_connected("draw", debugDraw, "on_canvas_item_draw")
                var connected_custom = _customCanvas != null and _customCanvas.is_connected("draw", debugDraw, "on_canvas_item_draw")

                if value == null:
                    if not connected_internal:
                        CanvasItemInternal.connect("draw", debugDraw, "on_canvas_item_draw", new GDArray { CanvasItemInternal })
                    if connected_custom:
                        _customCanvas?.disconnect("draw", debugDraw, "on_canvas_item_draw")
                else:
                    if connected_internal:
                        CanvasItemInternal.disconnect("draw", debugDraw, "on_canvas_item_draw")
                    if not connected_custom:
                        value.connect("draw", debugDraw, "on_canvas_item_draw", new GDArray { value })
                _customCanvas = value
            }
        }

        func _init(dd: DebugDraw) -> void:  # TODO should init return void?
            debugDraw = dd

            _poolWiredRenderers = new ObjectPool<DelayedRendererLine>(() => new DelayedRendererLine())
            _poolInstanceRenderers = new ObjectPool<DelayedRendererInstance>(() => new DelayedRendererInstance())

        ### <summary>
        ### Must be called only once be DebugDraw class
        ### </summary>
        func ready() -> void:
            if not is_ready:
                is_ready = true

            # Funny hack to get default font
            var c = new Control()
            debugDraw.add_child(c)
            _font = c.GetFont("font")
            c.queue_free()

            # Setup default text group
            end_text_group_internal()

            # Create wireframe mesh drawer
            _immediateGeometry = new ImmediateGeometry()
            {
                Name = nameof(_immediateGeometry),
                CastShadow = GeometryInstance.ShadowCastingSetting.Off,
                UseInBakedLight = false,

                MaterialOverride = new SpatialMaterial()
                {
                    FlagsUnshaded = true,
                    VertexColorUseAsAlbedo = true
                }
            }
            debugDraw.add_child(_immediateGeometry)
            # Create MultiMeshInstance instances..
            _mmc = new MultiMeshContainer(debugDraw, (i) => renderInstances += i)

            # Create canvas item and canvas layer
            _canvasLayer = new CanvasLayer() { Layer = 64 }
            CanvasItemInternal = new Node2D()

            if CustomCanvas == null:
                CanvasItemInternal.connect("draw", debugDraw, "on_canvas_item_draw", new GDArray { CanvasItemInternal })

            debugDraw.add_child(_canvasLayer)
            _canvasLayer.add_child(CanvasItemInternal)

        public void Dispose()
        {
            _finalized_clear_all()
        }

        func _finalized_clear_all() -> void:
            lock (dataLock)
            {
                _textGroups.Clear()
                _wireMeshes.Clear()
                if _mmc != null:
                    _mmc.Deinit()
                _mmc = null
            }

            if _font != null:
                _font.Dispose()
            _font = null

            if CanvasItemInternal != null and CanvasItemInternal.is_connected("draw", debugDraw, "on_canvas_item_draw"):
                CanvasItemInternal.disconnect("draw", debugDraw, "on_canvas_item_draw")
            if _customCanvas != null and _customCanvas.is_connected("draw", debugDraw, "on_canvas_item_draw"):
                _customCanvas.disconnect("draw", debugDraw, "on_canvas_item_draw")

            if CanvasItemInternal != null:
                CanvasItemInternal.queue_free()
            CanvasItemInternal = null

            if _canvasLayer != null:
                _canvasLayer.queue_free()
            _canvasLayer = null

            if _immediateGeometry != null:
                _immediateGeometry.queue_free()
            _immediateGeometry = null

            # Clear editor canvas
            if CustomCanvas != null:
                CustomCanvas.update()

        func update(delta: float) -> void:
            lock (dataLock)
            {
                # Clean texts
                _textGroups.RemoveWhere((g) => g.Texts.Count == 0)
                foreach (var g in _textGroups) g.CleanTexts(() => _update_canvas())

                # Clean lines
                _wireMeshes.RemoveWhere((o) =>
                {
                    if o == null or o.IsExpired():
                        _poolWiredRenderers.Return(o)
                        return true
                    return false
                })

                # Clean instances
                _mmc.remove_expired((o) => _poolInstanceRenderers.Return(o))
            }

            # FPS Graph
            fpsGraph.update(delta)

            # Update overlay
            if _canvasNeedUpdate or DebugDraw.FPSGraphEnabled:
                if CustomCanvas == null:
                    CanvasItemInternal.update()
                else:
                    CustomCanvas.update()

                # reset some values
                _canvasNeedUpdate = false
                end_text_group_internal()

            # Update 3D debug
            _update_debug_geometry()

        func _update_debug_geometry() -> void:
            # Don't clear geometry for debug this debug class
            if DebugDraw.Freeze3DRender:
                return

            # Clear first and then leave
            _immediateGeometry.Clear()

            renderInstances = 0
            renderWireframes = 0

            # Return if nothing to do
            if not DebugDraw.DebugEnabled:
                lock (dataLock)
                    _mmc?.hide_all()
                return

            # Get camera frustum
            var frustum_array = DebugDraw.CustomViewport == null or DebugDraw.ForceUseCameraFromScene ?
                debugDraw.GetViewport().GetCamera()?.GetFrustum() :
                DebugDraw.CustomViewport.GetCamera().GetFrustum()

            # Convert frustum to C# array
            Plane[] f = null
            if frustum_array != null:
                f = new Plane[frustum_array.Count]
                for i in range(frustum_array.Count):
                    f[i] = ((Plane)frustum_array[i])

            # Check visibility of all objects

            lock (dataLock)
            {
                # Update visibility
                if DebugDraw.UseFrustumCulling and f != null:
                    # Update immediate geometry
                    for _lines in _wireMeshes:
                        _lines.is_visible = bounds_partially_inside_convex_shape(_lines.Bounds, f)
                    # Update meshes
                    _mmc.update_visibility(f)

                _immediateGeometry.Begin(Mesh.PrimitiveType.Lines)
                # Line drawing much faster with only one Begin/End call
                for m in _wireMeshes:
                    m.is_used_one_time = true

                    if m.is_visible:
                        renderWireframes++
                        _immediateGeometry.set_color(m.LinesColor)
                        for l in m.Lines:
                            _immediateGeometry.add_vertex(l)

                _immediateGeometry.End()

                {   # Debug bounds
                    #_immediateGeometry.Begin(Mesh.PrimitiveType.Lines) foreach (var l in _wire_meshes) ___draw_debug_bounds_for_debug_line_primitives(l) _immediateGeometry.End()
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

        func on_canvas_item_draw(ci: CanvasItem) -> void:
            if not DebugDraw.DebugEnabled:
                return

            var time = DateTime.Now
            Vector2 vp_size = ci.HasMeta("UseParentSize") ? ci.GetParent<Control>().RectSize : ci.GetViewportRect().size

            lock (dataLock)
            { # Text drawing
                var count = _textGroups.Sum((g) => g.Texts.Count + (g.ShowTitle ? 1 : 0))

                const String separator = " : "

                Vector2 ascent = Vector2(0, _font.GetAscent())
                Vector2 font_offset = ascent + DebugDraw.TextPadding
                float line_height = _font.GetHeight() + DebugDraw.TextPadding.y * 2
                Vector2 pos = Vector2.Zero
                float size_mul = 0

                switch (DebugDraw.TextBlockPosition)
                {
                    case DebugDraw.BlockPosition.LeftTop:
                        pos = DebugDraw.TextBlockOffset
                        size_mul = 0
                        break
                    case DebugDraw.BlockPosition.RightTop:
                        pos = Vector2(
                            vp_size.x - DebugDraw.TextBlockOffset.x,
                            DebugDraw.TextBlockOffset.y)
                        size_mul = -1
                        break
                    case DebugDraw.BlockPosition.LeftBottom:
                        pos = Vector2(
                            DebugDraw.TextBlockOffset.x,
                            vp_size.y - DebugDraw.TextBlockOffset.y - line_height * count)
                        size_mul = 0
                        break
                    case DebugDraw.BlockPosition.RightBottom:
                        pos = Vector2(
                            vp_size.x - DebugDraw.TextBlockOffset.x,
                            vp_size.y - DebugDraw.TextBlockOffset.y - line_height * count)
                        size_mul = -1
                        break
                }

                foreach (var g in _textGroups.OrderBy(g => g.GroupPriority))
                {
                    var a = g.Texts.OrderBy(t => t.Value.Priority).ThenBy(t => t.Key)

                    foreach (var t in g.ShowTitle ? a.Prepend(new KeyValuePair<String, DelayedText>(g.Title ?? "", null)) : a)
                    {
                        var keyText = t.Key if t.Key else ""
                        var text = t.Value?.Text == null ? keyText : $"{keyText}{separator}{t.Value.Text}"
                        var size = _font.GetStringSize(text)
                        float size_right_revert = (size.x + DebugDraw.TextPadding.x * 2) * size_mul
                        ci.draw_rect(
                            new Rect2(Vector2(pos.x + size_right_revert, pos.y),
                            Vector2(size.x + DebugDraw.TextPadding.x * 2, line_height)),
                            DebugDraw.TextBackgroundColor)

                        # Draw colored string
                        if (t.Value == null or t.Value.ValueColor == null or t.Value.Text == null)
                        {
                            ci.DrawString(_font, Vector2(pos.x + font_offset.x + size_right_revert, pos.y + font_offset.y), text, g.GroupColor)
                        }
                        else
                        {
                            var textSep = $"{keyText}{separator}"
                            var _keyLength = textSep.Length
                            ci.DrawString(_font,
                                Vector2(pos.x + font_offset.x + size_right_revert, pos.y + font_offset.y),
                                text.Substring(0, _keyLength), g.GroupColor)
                            ci.DrawString(_font,
                                Vector2(pos.x + font_offset.x + size_right_revert + _font.GetStringSize(textSep).x, pos.y + font_offset.y),
                                text.Substring(_keyLength), t.Value.ValueColor)
                        }
                        pos.y += line_height
                    }
                }
            }

            if (DebugDraw.FPSGraphEnabled)
                fpsGraph.Draw(ci, _font, vp_size)
        }

        func _update_canvas() -> void:
            _canvasNeedUpdate = true

        #region Local Draw Functions

        func clear_3d_objects_internal() -> void:
            lock (dataLock)
            {
                _wireMeshes.Clear()
                _mmc?.clear_instances()
            }

        func clear_2d_objects_internal() -> void:
            lock (dataLock)
            {
                _textGroups.Clear()
                _update_canvas()
            }

        func clear_all_internal() -> void:
            clear_2d_objects_internal()
            clear_3d_objects_internal()

        #region 3D

        #region Spheres

        func draw_sphere_internal(ref Vector3 position, float radius, ref Color? color, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return

            var t = Transform.Identity
            t.origin = position
            t.basis.Scale = Vector3.One * (radius * 2)

            draw_sphere_internal(ref t, ref color, duration)

        func draw_sphere_internal(ref Transform transform, ref Color? color, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return

            lock (dataLock)
            {
                var inst = _poolInstanceRenderers.Get()
                inst.InstanceTransform = transform
                inst.InstanceColor = color if color else Colors.Chartreuse
                inst.bounds.position = transform.origin
                inst.Bounds.Radius = transform.basis.Scale.Length() * 0.5f
                inst.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)

                _mmc?.Spheres.Add(inst)
            }

        #endregion # Spheres

        #region Cylinders

        func draw_cylinder_internal(ref Vector3 position, float radius, float height, ref Color? color, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return

            var t = Transform.Identity
            t.origin = position
            t.basis.Scale = Vector3(radius * 2, height, radius * 2)

            draw_cylinder_internal(ref t, ref color, duration)

        func draw_cylinder_internal(ref Transform transform, ref Color? color, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return

            lock (dataLock)
            {
                var inst = _poolInstanceRenderers.Get()
                inst.InstanceTransform = transform
                inst.InstanceColor = color if color else Colors.Yellow
                inst.bounds.position = transform.origin
                inst.Bounds.Radius = transform.basis.Scale.Length() * 0.5f
                inst.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)

                _mmc?.Cylinders.Add(inst)
            }

        #endregion # Cylinders

        #region Boxes

        func draw_box_internal(ref Vector3 position, ref Vector3 size, ref Color? color, float duration, bool isBoxCentered) -> void:
            if not DebugDraw.DebugEnabled:
                return

            var q = Quat.Identity
            draw_box_internal(ref position, ref q, ref size, ref color, duration, isBoxCentered)

        func draw_box_internal(ref Vector3 position, ref Quat rotation, ref Vector3 size, ref Color? color, float duration, bool isBoxCentered) -> void:
            if not DebugDraw.DebugEnabled:
                return

            lock (dataLock)
            {
                var t = new Transform(rotation, position)
                t.basis.Scale = size
                var radius = size.Length() * 0.5f

                var inst = _poolInstanceRenderers.Get()
                inst.InstanceTransform = t
                inst.InstanceColor = color if color else Colors.ForestGreen
                inst.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)
                inst.Bounds.Radius = radius

                if isBoxCentered:
                    inst.bounds.position = t.origin
                else:
                    inst.bounds.position = t.origin + size * 0.5f

                if isBoxCentered:
                    _mmc?.CubesCentered.Add(inst)
                else:
                    _mmc?.Cubes.Add(inst)
            }

        func draw_box_internal(ref Transform transform, ref Color? color, float duration, bool isBoxCentered) -> void:
            if not DebugDraw.DebugEnabled:
                return

            lock (dataLock)
            {
                var radius = transform.basis.Scale.Length() * 0.5f

                var inst = _poolInstanceRenderers.Get()
                inst.InstanceTransform = transform
                inst.InstanceColor = color if color else Colors.ForestGreen
                inst.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)
                inst.Bounds.Radius = radius

                if isBoxCentered:
                    inst.bounds.position = transform.origin
                else:
                    inst.bounds.position = transform.origin + transform.basis.scale * 0.5f

                if isBoxCentered:
                    _mmc?.CubesCentered.Add(inst)
                else:
                    _mmc?.Cubes.Add(inst)
            }

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

        func draw_line_3d_hit_internal(ref Vector3 a, ref Vector3 b, bool isHit, float unitOffsetOfHit, float hitSize, float duration, ref Color? hitColor, ref Color? afterHitColor) -> void:
            if not DebugDraw.DebugEnabled:
                return

            lock (dataLock)
            {
                if isHit and unitOffsetOfHit >= 0 and unitOffsetOfHit <= 1.0f:
                    var time = DateTime.Now + TimeSpan.FromSeconds(duration)
                    var hit_pos = (b - a).normalized() * a.distance_to(b) * unitOffsetOfHit + a

                    # Get lines from pool and setup
                    var line_a = _poolWiredRenderers.Get()
                    var line_b = _poolWiredRenderers.Get()

                    line_a.Lines = Vector3[] { a, hit_pos }
                    line_a.LinesColor = hitColor if hitColor else DebugDraw.LineHitColor
                    line_a.expiration_time = time

                    line_b.Lines = Vector3[] { hit_pos, b }
                    line_b.LinesColor = afterHitColor if afterHitColor else DebugDraw.LineAfterHitColor
                    line_b.expiration_time = time

                    _wireMeshes.Add(line_a)
                    _wireMeshes.Add(line_b)

                    # Get instance from pool and setup
                    var t = new Transform(Basis.Identity, hit_pos)
                    t.basis.Scale = Vector3.One * hitSize

                    var inst = _poolInstanceRenderers.Get()
                    inst.InstanceTransform = t
                    inst.InstanceColor = hitColor if hitColor else DebugDraw.LineHitColor
                    inst.bounds.position = t.origin
                    inst.Bounds.Radius = CubeDiagonalLengthForSphere * hitSize
                    inst.expiration_time = time

                    _mmc?.BillboardSquares.Add(inst)
                else:
                    var line = _poolWiredRenderers.Get()

                    line.Lines = Vector3[] { a, b }
                    line.LinesColor = hitColor if hitColor else DebugDraw.LineHitColor
                    line.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)

                    _wireMeshes.Add(line)
            }

        #region Normal

        func draw_line_3d_internal(ref Vector3 a, ref Vector3 b, ref Color? color, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return

            lock (dataLock)
            {
                var line = _poolWiredRenderers.Get()

                line.Lines = Vector3[] { a, b }
                line.LinesColor = color if color else Colors.LightGreen
                line.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)

                _wireMeshes.Add(line)
            }

        func draw_ray_3d_internal(origin: Vector3, direction: Vector3, length: float, color: Color?, duration: float) -> void:
            if not DebugDraw.DebugEnabled:
                return

            var end = origin + direction * length
            draw_line_3d_internal(ref origin, ref end, ref color, duration)

        func draw_line_path_3d_internal(path: IList<Vector3>, color: Color?, duration: float = 0f) -> void:
            if not DebugDraw.DebugEnabled:
                return

            if path == null or path.Count <= 2:
                return

            lock (dataLock)
            {
                var line = _poolWiredRenderers.Get()

                line.Lines = create_lines_from_path(path)
                line.LinesColor = color if color else Colors.LightGreen
                line.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)

                _wireMeshes.Add(line)
            }

        func draw_line_path_3d_internal(Color? color, float duration, params Vector3[] path) -> void:
            if not DebugDraw.DebugEnabled:
                return

            draw_line_path_3d_internal(path, color, duration)

        #endregion # Normal

        #region Arrows

        func draw_arrow_line_3d_internal(a: Vector3, b: Vector3, color: Color?, duration: float, arrowSize: float, absoluteSize: bool) -> void:
            if not DebugDraw.DebugEnabled:
                return

            var line = _poolWiredRenderers.Get()

            line.Lines = Vector3[] { a, b }
            line.LinesColor = color if color else Colors.LightGreen
            line.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)

            _wireMeshes.Add(line)

            _generate_arrowhead_instance(ref a, ref b, ref color, ref duration, ref arrowSize, ref absoluteSize)

        func draw_arrow_ray_3d_internal(origin: Vector3, direction: Vector3, length: float, color: Color?, duration: float, arrowSize: float, absoluteSize: bool) -> void:
            if not DebugDraw.DebugEnabled:
                return

            draw_arrow_line_3d_internal(origin, origin + direction * length, color, duration, arrowSize, absoluteSize)

        func draw_arrow_path_3d_internal(IList<Vector3> path, ref Color? color, float duration, float arrowSize, bool absoluteSize) -> void:
            if not DebugDraw.DebugEnabled:
                return

            if path == null or path.Count < 2:
                return

            var line = _poolWiredRenderers.Get()
            line.Lines = create_lines_from_path(path)
            line.LinesColor = color if color else Colors.LightGreen
            line.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)
            _wireMeshes.Add(line)

            for i in range(path.Count - 1):
                Vector3 a = path[i], b = path[i + 1]
                _generate_arrowhead_instance(ref a, ref b, ref color, ref duration, ref arrowSize, ref absoluteSize)

        func draw_arrow_path_3d_internal(ref Color? color, float duration, float arrowSize, bool absoluteSize, params Vector3[] path) -> void:
            if not DebugDraw.DebugEnabled:
                return

            draw_arrow_path_3d_internal(path, ref color, duration, arrowSize, absoluteSize)

        #endregion # Arrows
        #endregion # Lines

        #region Misc

        func draw_billboard_square_internal(ref Vector3 position, float size, ref Color? color, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return

            lock (dataLock)
            {
                var t = Transform.Identity
                t.origin = position
                t.basis.Scale = Vector3.One * size

                var inst = _poolInstanceRenderers.Get()
                inst.InstanceTransform = t
                inst.InstanceColor = color if color else Colors.Red
                inst.bounds.position = t.origin
                inst.Bounds.Radius = CubeDiagonalLengthForSphere * size
                inst.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)

                _mmc?.BillboardSquares.Add(inst)
            }

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
            if cameraFrustum.Count != 6:
                return

            Plane[] f = new Plane[cameraFrustum.Count]
            for i in range(cameraFrustum.Count):
                f[i] = ((Plane)cameraFrustum[i])

            draw_camera_frustum_internal(ref f, ref color, duration)

        func draw_camera_frustum_internal(ref Plane[] planes, ref Color? color, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return
            if planes.Length != 6:
                return

            lock (dataLock)
            {
                var line = _poolWiredRenderers.Get()

                line.Lines = create_camera_frustum_lines(planes)
                line.LinesColor = color if color else Colors.DarkSalmon
                line.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)

                _wireMeshes.Add(line)
            }

        #endregion # Camera frustum

        func draw_position_3d_internal(ref Transform transform, ref Color? color, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return

            lock (dataLock)
            {
                var s = transform.basis.Scale

                var inst = _poolInstanceRenderers.Get()
                inst.InstanceTransform = transform
                inst.InstanceColor = color if color else Colors.Crimson
                inst.bounds.position = transform.origin
                inst.Bounds.Radius = _get_max_value(ref s) * 0.5f
                inst.expiration_time = DateTime.Now + TimeSpan.FromSeconds(duration)

                _mmc?.Positions.Add(inst)
            }

        func draw_position_3d_internal(ref Vector3 position, ref Quat rotation, ref Vector3 scale, ref Color? color, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return

            var t = new Transform(new Basis(rotation), position)
            t.basis.Scale = scale

            draw_position_3d_internal(ref t, ref color, duration)

        func draw_position_3d_internal(ref Vector3 position, ref Color? color, float scale, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return

            var t = new Transform(Basis.Identity, position)
            t.basis.Scale = Vector3.One * scale

            draw_position_3d_internal(ref t, ref color, duration)

        #endregion # Misc
        #endregion # 3D

        #region 2D

        func begin_text_group_internal(String groupTitle, int groupPriority, ref Color? groupColor, bool showTitle) -> void:
            lock (dataLock)
            {
                var newGroup = _textGroups.FirstOrDefault(g => g.Title == groupTitle)
                if newGroup != null:
                    newGroup.ShowTitle = showTitle
                    newGroup.GroupPriority = groupPriority
                    newGroup.GroupColor = groupColor if groupColor else DebugDraw.TextForegroundColor
                else:
                    newGroup = new TextGroup(groupTitle, groupPriority, showTitle, groupColor if groupColor else DebugDraw.TextForegroundColor)
                    _textGroups.Add(newGroup)
                _currentTextGroup = newGroup
            }

        func end_text_group_internal() -> void:
            lock (dataLock)
            {
                if not _textGroups.Contains(_defaultTextGroup):
                    _textGroups.Add(_defaultTextGroup)
                _currentTextGroup = _defaultTextGroup

                # Update color
                _defaultTextGroup.GroupColor = DebugDraw.TextForegroundColor
            }

        func set_text_internal(ref String key, ref object value, int priority, ref Color? colorOfValue, float duration) -> void:
            if not DebugDraw.DebugEnabled:
                return

            var _newTime = DateTime.Now + (duration < 0 ? DebugDraw.TextDefaultDuration : TimeSpan.FromSeconds(duration))
            var _strVal = value?.ToString()

            lock (dataLock)
            {
                if _currentTextGroup.Texts.ContainsKey(key):
                    var t = _currentTextGroup.Texts[key]
                    if _strVal != t.Text:
                        _update_canvas()
                    t.Text = _strVal
                    t.Priority = priority
                    t.expiration_time = _newTime
                    t.ValueColor = colorOfValue
                else:
                    _currentTextGroup.Texts[key] = new DelayedText(_newTime, _strVal, priority, colorOfValue)
                    _update_canvas()
            }

        #endregion # 2D
        #endregion

        #region Utilities

        func _draw_debug_bounds_for_debug_line_primitives(dr: DelayedRendererLine) -> void:
            if not dr.is_visible:
                return

            var _lines = create_cube_lines(dr.bounds.position, Quat.IDENTITY, dr.bounds.size, false, true)

            renderWireframes++
            _immediateGeometry.set_color(Colors.Orange)
            for l in _lines:
                _immediateGeometry.add_vertex(l)

        func _draw_debug_bounds_for_debug_instance_primitive(dr: DelayedRendererInstance) -> void:
            if not dr.is_visible:
                return

            renderInstances++
            var p = dr.bounds.position
            var r = dr.Bounds.Radius
            Color? c = Colors.DarkOrange
            draw_sphere_internal(ref p, r, ref c, 0)

        func _generate_arrowhead_instance(ref Vector3 a, ref Vector3 b, ref Color? color, ref float duration, ref float arrowSize, ref bool absoluteSize) -> void:
            lock (dataLock)
            {
                var offset = (b - a)
                var length = (absoluteSize ? arrowSize : offset.Length() * arrowSize)

                var t = new Transform(Basis.Identity, b - offset.normalized() * length).LookingAt(b, Vector3.Up)
                t.basis.Scale = Vector3.One * length
                var time = DateTime.Now + TimeSpan.FromSeconds(duration)

                var inst = _poolInstanceRenderers.Get()
                inst.InstanceTransform = t
                inst.InstanceColor = color if color else Colors.LightGreen
                inst.bounds.position = t.origin - t.basis.z * 0.5f
                inst.Bounds.Radius = CubeDiagonalLengthForSphere * length
                inst.expiration_time = time

                _mmc?.Arrowheads.Add(inst)
            }

        # Broken converter from Transform and Color to raw float[]
        static func _get_raw_multimesh_transforms(instances: ISet<DelayedRendererInstance>) -> float[]:
            float[] res = new float[instances.Count * 16]
            int index = 0

            for i in instances:
                i.is_used_one_time = true # needed for proper clear
                int idx = index
                index += 16

                res[idx + 0] = i.InstanceTransform.basis.Row0.x res[idx + 1] = i.InstanceTransform.basis.Row0.y
                res[idx + 2] = i.InstanceTransform.basis.Row0.z res[idx + 3] = i.InstanceTransform.basis.Row1.x
                res[idx + 4] = i.InstanceTransform.basis.Row1.y res[idx + 5] = i.InstanceTransform.basis.Row1.z
                res[idx + 6] = i.InstanceTransform.basis.Row2.x res[idx + 7] = i.InstanceTransform.basis.Row2.y
                res[idx + 8] = i.InstanceTransform.basis.Row2.z res[idx + 9] = i.InstanceTransform.origin.x
                res[idx + 10] = i.InstanceTransform.origin.y res[idx + 11] = i.InstanceTransform.origin.z
                res[idx + 12] = i.InstanceColor.r res[idx + 13] = i.InstanceColor.g
                res[idx + 14] = i.InstanceColor.b res[idx + 15] = i.InstanceColor.a

            return res

        #region Geometry Generation

        static func create_camera_frustum_lines(frustum: Plane[]) -> Vector3[]:
            if frustum.Length != 6:
                return Array.Empty<Vector3>()

            Vector3[] res = Vector3[CubeIndices.Length]

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

            for i in range(res.Length):
                res[i] = cube[CubeIndices[i]]

            return res

        static func create_cube_lines(position: Vector3, rotation: Quat, size: Vector3, centeredBox: bool = true, withDiagonals: bool = false) -> Vector3[]:
            Vector3[] scaled = Vector3[8]
            Vector3[] res = Vector3[withDiagonals ? CubeWithDiagonalsIndices.Length : CubeIndices.Length]

            bool dont_rot = rotation == Quat.Identity

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

            for (int i = 0 i < 8 i++):
                scaled[i] = get(i)

            if withDiagonals:
                for (int i = 0 i < res.Length i++):
                    res[i] = scaled[CubeWithDiagonalsIndices[i]]
            else:
                for (int i = 0 i < res.Length i++):
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
                float lat0 = Mathf.Pi * (-0.5f + (float)(i - 1) / lats)
                float z0 = Mathf.Sin(lat0)
                float zr0 = Mathf.Cos(lat0)

                float lat1 = Mathf.Pi * (-0.5f + (float)i / lats)
                float z1 = Mathf.Sin(lat1)
                float zr1 = Mathf.Cos(lat1)

                for (int j = lons j >= 1 j--):
                    float lng0 = 2 * Mathf.Pi * (j - 1) / lons
                    float x0 = Mathf.Cos(lng0)
                    float y0 = Mathf.Sin(lng0)

                    float lng1 = 2 * Mathf.Pi * j / lons
                    float x1 = Mathf.Cos(lng1)
                    float y1 = Mathf.Sin(lng1)

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

        static func create_cylinder_lines(edges: int, radius: float, height: float, position: Vector3, drawEdgeEachNStep: int = 1) -> Vector3[]:
            var angle = 360f / edges

            List<Vector3> points = new List<Vector3>()

            Vector3 d = Vector3(0, height * 0.5f, 0)
            for i in range(edges):
                float ra = Mathf.Deg2Rad(i * angle)
                float rb = Mathf.Deg2Rad((i + 1) * angle)
                Vector3 a = Vector3(Mathf.Sin(ra), 0, Mathf.Cos(ra)) * radius + position
                Vector3 b = Vector3(Mathf.Sin(rb), 0, Mathf.Cos(rb)) * radius + position

                # Top
                points.Add(a + d)
                points.Add(b + d)

                # Bottom
                points.Add(a - d)
                points.Add(b - d)

                # Edge
                if i % drawEdgeEachNStep == 0:
                    points.Add(a + d)
                    points.Add(a - d)

            return points.ToArray()

        static func create_lines_from_path(path: IList<Vector3>) -> Vector3[]:
            var res = Vector3[(path.Count - 1) * 2]

            for (int i = 1 i < path.Count - 1 i++):
                res[i * 2] = path[i]
                res[i * 2 + 1] = path[i + 1]
            return res

        #endregion # Geometry Generation

        static func get_diagonal_vectors(Vector3 a, Vector3 b, out Vector3 bottom, out Vector3 top, out Vector3 diag) -> void:
            bottom = Vector3.Zero
            top = Vector3.Zero

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
            return Math.Max(Math.Abs(value.x), Math.Max(Math.Abs(value.y), Math.Abs(value.z)))

        #endregion # Utilities

    }
}
#endif # DebugDrawImplementation
