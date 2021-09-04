tool
extends EditorPlugin

# static PluginDir: string = "res:#addons/debug_draw/"

spatial_viewport: ViewportContainer = null

func _enter_tree() -> void:
    _create_auto_find()

    if not is_connected("scene_changed", self, "_on_scene_changed"):
        connect("scene_changed", self, "_on_scene_changed")

func _exit_tree() -> void:
    _remove_prev_node()

    if is_connected("scene_changed", self, "_on_scene_changed"):
        disconnect("scene_changed", self, "_on_scene_changed")

func disable_plugin() -> void:
    _remove_prev_node()

func _process(delta: float) -> void:
    # Dirty workaround for reloading of DebugDraw after project rebuild
    _create_auto_find()

func _on_scene_changed(node: Node) -> void:
    if node == null:
        return

    _create_new_node(node)

# Try to recursively find `SpatialEditorViewport`
func _find_spatial_editor_viewport(c, level) -> Control:
    if c is SpatialEditorViewport:
        return c

    # 4 Levels must be enough for 3.2.4
    if level < 4:
        for o in c.get_children():
            if o is Control:
                var ch := (o as Control)
                var res = get(ch, level + 1)
                if res != null:
                    return res

    return null

# HACK for finding canvas and drawing on it
# Hardcoded for 3.2.4
func _find_viewport_control() -> void:
    # Create temp control to get spatial viewport
    var ctrl := Control.new()
    add_control_to_container(CustomControlContainer.CONTAINER_SPATIAL_EDITOR_MENU, ctrl)

    # Try to get main viewport node. Must be `SpatialEditor`
    var spatial_editor: Control = ctrl.get_parent().get_parent()

    # Remove and destroy temp control
    remove_control_from_container(CustomControlContainer.CONTAINER_SPATIAL_EDITOR_MENU, ctrl)
    ctrl.queue_free()

    spatial_viewport = null
    if spatial_editor is SpatialEditor:
        # Try to recursively find `SpatialEditorViewport`
        var viewport = _find_spatial_editor_viewport(spatial_editor, 0)
        if viewport != null:
            spatial_viewport = viewport.get_child(0)

    if spatial_viewport != null:
        spatial_viewport.set_meta("UseParentSize", true)
        spatial_viewport.update()

func _remove_prev_node() -> void:
    if DebugDraw.instance != null:
        DebugDraw.instance.queue_free()
    if spatial_viewport != null:
        spatial_viewport.update()

    var tree := Engine.GetMainLoop() as SceneTree
    if tree != null:
        var root = tree.edited_scene_root
        if root != null:
            var nodes = root.get_children()
            for n in nodes:
                if n.Owner == null and n.has_meta("DebugDraw") and not n.is_queued_for_deletion():
                    n.queue_free()

func _create_new_node(parent: Node) -> void:
    _remove_prev_node()
    if DebugDraw.instance == null:
        _find_viewport_control()

        var d = DebugDraw.new()
        parent.add_child(d)

        DebugDraw.custom_viewport = spatial_viewport.get_child(0)
        DebugDraw.custom_canvas = spatial_viewport

func _create_auto_find() -> void:
    if DebugDraw.instance == null:
        var scene_tree := (Engine.get_main_loop() as SceneTree)
        if scene_tree != null:
            var node: Node = scene_tree.edited_scene_root
            if node != null:
                _create_new_node(node)
