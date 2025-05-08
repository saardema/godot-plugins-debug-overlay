
using System;
using System.Collections.Generic;
using Godot;
using Godot.NativeInterop;

// [Tool]
[GlobalClass]
public partial class DebugOverlay : Control
{
	MeshInstance3D _immediateDrawTarget;
	VBoxContainer _labelContainer;
	Node3D _line3DContainer;
	PanelContainer panelContainer;

	public LabelSettings _labelSettings;

	readonly Dictionary<string, ExpiringEntity> lineNodes = [];

	readonly Dictionary<string, ExpiringEntity> textNodes = [];

	public ulong _timeLastCleanup;

	public static DebugOverlay Instance { get; private set; }

	public override void _Ready()
	{
		GD.Print("Ready");
	}

	public override void _EnterTree()
	{
		GD.Print("Enter tree");

		Instance = this;
		_immediateDrawTarget = (MeshInstance3D)GetNode("MeshInstance3D");
		_labelContainer = (VBoxContainer)GetNode("PanelContainer/MarginContainer/VBoxContainer");
		_line3DContainer = (Node3D)GetNode("Line3DContainer");
		panelContainer = (PanelContainer)GetNode("PanelContainer");

		panelContainer.Visible = false;
		_labelSettings = new()
		{
			FontSize = 14,
			Font = new SystemFont()
		};
	}

	public override void _ExitTree()
	{
		GD.Print("Exit tree");
	}

	public void Write(StringName id, float value, int precision = 2, bool expires = true)
	{
		var stringValue = value.ToString("N" + precision);
		Write(id, stringValue, expires);
	}

	public void Write(StringName id, string value, bool expires = true)
	{
		if (!textNodes.ContainsKey(id))
		{
			textNodes[id] = CreateLabel(expires);
			_labelContainer.AddChild(textNodes[id].Node);
		}
		else
		{
			textNodes[id].KeepAlive();
		}

		var label = (Label)textNodes[id].Node;
		label.Text = $"{id}: {value}";
	}

	private ExpiringEntity CreateLabel(bool expires)
	{
		Label label = new() { LabelSettings = _labelSettings };
		var node = new ExpiringEntity(label, expires);

		return node;
	}

	public override void _PhysicsProcess(double _delta)
	{
		return;
		var mesh = (ImmediateMesh)_immediateDrawTarget.Mesh;
		mesh.ClearSurfaces();

		var time = Time.GetTicksMsec();
		if (time < _timeLastCleanup + 100) return;

		_timeLastCleanup = time;

		foreach (var id in textNodes.Keys)
		{
			if (!textNodes[id].expires) continue;

			if (time > textNodes[id].timeUpdated + ExpiringEntity.lifetimeMs)
			{
				textNodes[id].Node.QueueFree();
				textNodes.Remove(id);

			}
		}

		panelContainer.Visible = textNodes.Count > 0;

		foreach (var id in lineNodes.Keys)
		{
			if (time > lineNodes[id].timeUpdated + ExpiringEntity.lifetimeMs)
			{
				lineNodes[id].Node.QueueFree();
				lineNodes.Remove(id);
				//else:
				//var meshInstance = lineNodes[id].node.GetChild(0);
				//mesh_instance.transparency = (time - lineNodes[id].timeUpdated) / ExpiringNode.lifetimeMs;


			}
		}
	}

	public void DrawLine3dImmediate(Vector3 pointA, Vector3 pointB, Color? color = null)
	{
		if (pointA.IsEqualApprox(pointB))
			return;

		color ??= Colors.Red;

		var mesh = (ImmediateMesh)_immediateDrawTarget.Mesh;

		mesh.SurfaceBegin(Mesh.PrimitiveType.Lines);
		mesh.SurfaceSetColor((Color)color);

		mesh.SurfaceAddVertex(pointA);
		mesh.SurfaceAddVertex(pointB);

		mesh.SurfaceEnd();

	}

	public void DrawLine3d(string id, Vector3 from, Vector3 to, Color? color = null)
	{
		Node3D node;
		color ??= Colors.Red;

		if (lineNodes.TryGetValue(id, out ExpiringEntity expiringEntity))
		{
			node = (Node3D)expiringEntity.Node;
			expiringEntity.KeepAlive();
		}
		else
		{
			node = CreateLineNode();
			_line3DContainer.AddChild(node);
			lineNodes[id] = new ExpiringEntity(node);
		}

		var meshInstance = (MeshInstance3D)node.GetChild(0);
		var length = from.DistanceTo(to);

		if (Mathf.IsEqualApprox(from.X, to.X)) from.X += 0.005f;
		else if (Mathf.IsEqualApprox(from.Z, to.Z)) from.Z += 0.005f;

		node.LookAtFromPosition(from, to);

		meshInstance.Position = meshInstance.Position with { Z = -length / 2 };
		var mesh = (CylinderMesh)meshInstance.Mesh;
		mesh.Height = length;
		var material = (BaseMaterial3D)mesh.Material;
		material.AlbedoColor = (Color)color;
	}

	public Node3D CreateLineNode()
	{
		var node = new Node3D();
		var meshInstance = new MeshInstance3D();
		node.AddChild(meshInstance);

		var mesh = new CylinderMesh { TopRadius = 0.01f, BottomRadius = 0.01f, RadialSegments = 0 };

		meshInstance.CastShadow = GeometryInstance3D.ShadowCastingSetting.Off;
		meshInstance.Rotation = meshInstance.Rotation with { X = -Mathf.Pi / 2 };

		mesh.Material = new OrmMaterial3D
		{
			ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded,
			Transparency = BaseMaterial3D.TransparencyEnum.Alpha
		};

		meshInstance.Mesh = mesh;

		return node;
	}

	public partial class ExpiringEntity : RefCounted
	{
		public Node Node;
		public ulong timeUpdated;
		public bool expires;
		public static float lifetimeMs = 1000;

		public ExpiringEntity(Node _node, bool _expires = true)
		{
			Node = _node;
			expires = _expires;
			KeepAlive();
		}

		public void KeepAlive() => timeUpdated = Time.GetTicksMsec();
	}


}