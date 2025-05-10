using Godot;
using System;

[Tool]
public partial class DebugTools : Node
{
    public static Node3D gd_instance;

    public void SetInstance(Node3D instance) => gd_instance = instance;

    // public static void Ping() => GD.Print("Pong");

    public override void _Ready()
    {
        // TrySetInstance();
        GD.Print("bridge ready", gd_instance);
    }

    // public void TrySetInstance()
    // {
    //     gd_instance = GetNodeOrNull<Node3D>("/root/DebugTools");
    // }

    public static void Write(String id, float value, int precision = 2, bool expires = true)
    {
        string formatted = value.ToString("F" + precision);
        Write(id, formatted, expires);
    }

    public static void Write(String id, String text, bool expires = true)
    {
        if (gd_instance == null)
        {
            GD.PrintErr("DebugTools.cs: No instance of DebugTools");
            return;
        }

        gd_instance.Call("write", id, text, expires);
    }
}
