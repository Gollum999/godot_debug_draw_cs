![icon](icon.png)

# Debug drawing utility

This is a debug drawing script, which you can setup as an autoload singleton. Written in C#, so only Godot Mono supported.

Inspired by Zilann's addon for the GDScript https://github.com/Zylann/godot_debug_draw

## Donations

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/I2I53VZ2D)

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://paypal.me/dmitriysalnikov)

## Features

Primitives:

* Box
* Sphere
* Cylinder
* Line
* Line with Arrow
* Line Path
* Camera Frustum
* Billboard opaque square
* Position 3D (3 crossing axis)

Overlay:

* Text (with grouping and coloring)
* FPS Graph

No need to warry about removing or disabling functionality of this addon in export builds. Everything in this addon will be disabled automatically.

## Usage

1. Copy `addons/debug_draw` to your `addon` folder, create it if the folder doesn't exist.
1. Rebuild project.
1. Add `addons/debug_draw/DebugDraw.gd` to your project as autoload singleton.
1. (Optionally) Enable the `Debug Draw For Editor` plugin to enable debug drawing support inside the editor.

Example (information about all public static functions and properties is present inside the script):

```
public override void _Process(float delta)
{
    var time = OS.GetTicksMsec() / 1000f;
    var box_pos = Vector3(0, sin(time * 4f), 0);
    var line_begin = Vector3(-1, sin(time * 4f), 0);
    var line_end = Vector3(1, cos(time * 4f), 0);

    DebugDraw.draw_box(box_pos, Vector3(1, 2, 1), Color(0, 1, 0), 0, false);
    DebugDraw.draw_line_3d(line_begin, line_end, Color(1, 1, 0));
    DebugDraw.set_text("Time", time);
    DebugDraw.set_text("Frames drawn", Engine.GetFramesDrawn());
    DebugDraw.set_text("FPS", Engine.GetFramesPerSecond());
    DebugDraw.set_text("delta", delta);
}
```

![screenshot_3](screenshots/screenshot_3.png)

If you see `ERROR: _gl_debug_print: GL ERROR: Source: OpenGL  Type: Error ID: 1281   Severity: High   Message: GL_INVALID_VALUE error generated. Invalid offset and/or size.`, try increasing the value of `rendering/limits/buffers/immediate_buffer_size_kb`.

## More screenshots

`DebugDrawDemoScene.tscn` in editor
![screenshot_1](screenshots/screenshot_1.png)

`DebugDrawDemoScene.tscn` in play mode
![screenshot_2](screenshots/screenshot_2.png)
