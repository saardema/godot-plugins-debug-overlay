#if TOOLS
using System;
using System.Collections.Generic;
using Godot;
using Godot.NativeInterop;

[Tool]
public partial class DebugOverlay : Control
{
	MeshInstance3D _immediateDrawTarget;
	VBoxContainer _labelContainer;
	Node3D _line3DContainer;
	PanelContainer panelContainer;

	public LabelSettings _labelSettings;

	private bool _immediateMeshIsDirty = false;

	readonly Dictionary<string, ExpiringEntity> lineNodes = [];

	readonly Dictionary<string, ExpiringEntity> textNodes = [];

	public ulong _timeLastCleanup;

	public static DebugOverlay Instance { get; private set; }

	public DebugOverlay() => GD.Print("DebugOverlay constructor");

	~DebugOverlay() => GD.Print("DebugOverlay deconstructor");

	public override void _EnterTree() => GD.Print("DebugOverlay EnterTree");

	public override void _Ready()
	{
		GD.Print("DebugOverlay Ready");

		Name = "DebugOverlay";

		Instance = this;

		_immediateDrawTarget = (MeshInstance3D)GetNode("MeshInstance3D");
		_labelContainer = (VBoxContainer)GetNode("PanelContainer/MarginContainer/VBoxContainer");
		_line3DContainer = (Node3D)GetNode("Line3DContainer");
		panelContainer = (PanelContainer)GetNode("PanelContainer");

		panelContainer.Visible = false;

		_labelSettings = new()
		{
			FontSize = 36,
			Font = new SystemFont()
		};
	}

	public void OnSceneChange(Node SceneRoot)
	{

	}

	public override void _ExitTree()
	{
		GD.Print("DebugOverlay Exit tree");
		lineNodes.Clear();
		textNodes.Clear();
	}

	public void Write(string id, float value) =>
		Write(id, value, 2, true);

	public void Write(string id, float value, int precision) =>
		Write(id, value, precision, true);

	public void Write(string id, float value, int precision, bool expires) =>
		Write(id, value.ToString("N" + precision), expires);

	public void Write(string id, string value) =>
		Write(id, value, true);

	public void Write(string id, string value, bool expires)
	{
		ExpiringEntity textNode;

		if (textNodes.TryGetValue(id, out textNode))
		{
			textNode.KeepAlive();
		}
		else
		{
			textNode = CreateLabel(expires);
			textNodes[id] = textNode;
			_labelContainer.AddChild(textNode.Node);
		}

		var label = (Label)textNode.Node;
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
		if (_immediateMeshIsDirty)
		{
			_immediateMeshIsDirty = false;
			var mesh = (ImmediateMesh)_immediateDrawTarget.Mesh;
			mesh.ClearSurfaces();
		}

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

		_immediateMeshIsDirty = true;
	}

	public void DrawLine3D(string id, Vector3 from, Vector3 to) => DrawLine3D(id, from, to, Colors.Red);

	public void DrawLine3D(string id, Vector3 from, Vector3 to, Color color)
	{
		Node3D node;

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

	public partial class ExpiringEntity
	{
		public Node Node;
		public ulong timeUpdated;
		public bool expires;
		public static float lifetimeMs = 1000;

		public ExpiringEntity() { }

		public ExpiringEntity(Node _node, bool _expires = true)
		{
			Node = _node;
			expires = _expires;
			KeepAlive();
		}

		public void KeepAlive() => timeUpdated = Time.GetTicksMsec();
	}
}
#endif