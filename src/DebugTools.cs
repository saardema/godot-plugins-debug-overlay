using Godot;
using System;

[Tool]
public partial class DebugTools : Node
{
    public static Node3D gd_instance;

    public static DebugTools instance;

    public DebugTools() => instance = this;

    private static bool IsInstanceSet()
    {
        gd_instance ??= instance.GetNodeOrNull<Node3D>("../.");

        return gd_instance == null;
    }

    public static void Write(String id, float value, int precision = 2, bool expires = true)
    {
        string formatted = value.ToString("F" + precision);
        Write(id, formatted, expires);
    }

    public static void DrawLine(
        string id,
        Vector3 p1,
        Vector3 p2,
        Color? color = null,
        float thickness = 0.01f,
        bool expires = true)
    {
        if (!IsInstanceSet()) return;

        color ??= Colors.Red;

        gd_instance.Call("draw_line", id, p1, p2, (Color)color, thickness, expires);
    }

    public static void Write(string id, string text, bool expires = true)
    {
        if (!IsInstanceSet()) return;

        gd_instance.Call("write", id, text, expires);
    }
}
