using Godot;
using System;

[Tool]
public partial class DebugTools : Node
{
	private static Node3D gd_instance;

	public override void _EnterTree()
	{
		gd_instance = GetNode<Node3D>("../.");
	}

	public static void Write(String id, Vector3 vector, int precision = 2, bool expires = true)
	{
		var format = "F" + precision;
		int pad = precision + 3;
		if (precision == 0) pad -= 1;
		string x = vector.X.ToString(format).PadLeft(pad);
		string y = vector.Y.ToString(format).PadLeft(pad);
		string z = vector.Z.ToString(format).PadLeft(pad);
		string formatted = $"{x}, {y}, {z}";
		Write(id, formatted, expires);
	}

	public static void Write(String id, float floatValue, int precision = 2, bool expires = true)
	{
		string formatted = floatValue.ToString("F" + precision);
		Write(id, formatted, expires);
	}

	public static void Write(string id, string text, bool expires = true)
	{
		// if (!IsInstanceSet()) return;

		gd_instance.Call("write", id, text, expires);
	}

	public static void DrawLine(
		string id,
		Vector3 p1,
		Vector3 p2,
		Color? color = null,
		float thickness = 0.01f,
		bool expires = true)
	{
		// if (!IsInstanceSet()) return;

		color ??= Colors.Red;

		gd_instance.Call("draw_line", id, p1, p2, (Color)color, thickness, expires);
	}
}
