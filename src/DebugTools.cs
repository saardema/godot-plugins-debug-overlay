using Godot;
using System;

public partial class DebugTools : Node
{
    public static void Ping() => GD.Print("Pong");
}
