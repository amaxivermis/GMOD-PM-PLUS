using Godot;
using MessagePack;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

public partial class SaveModel : Node
{
    [Signal]
    public delegate void PushErrorEventHandler(string error);
    [Signal]
    public delegate void PushWarningEventHandler(string warning);

    [MessagePackObject]
    public class SaveData
    {
        [Key(0)]
        public PersistentProperty[] Properties;
        [Key(1)]
        public byte[] SkeletonGLTFData;
    }

    [MessagePackObject]
    public class PersistentProperty
    {
        [Key(0)]
        public string NodePath;
        [Key(1)]
        public string PropertyPath;
        [Key(2)]
        public byte[] Data;
    }

    [Export] Node ToBeAddedTo;
    [Export] Node FieldsToSave;

    private string _currentSaveFile = null;

    // Called when the node enters the scene tree for the first time.
    public override void _Ready()
    {
        SetDirectory(null);
    }

    // Called every frame. 'delta' is the elapsed time since the previous frame.
    public override void _Process(double delta)
    {
    }

    public void Save()
    {
        if (SkeletonManager.Singleton.SkeletonInstance == null)
        {
            EmitSignal(SignalName.PushError, "No model is present, can't save anything!");
            return;
        }

        if (_currentSaveFile == null)
        {
            GetNode<FileDialog>("SaveDialogue").PopupCentered();
            return;
        }

        CreateFile(_currentSaveFile);
    }

    public void OpenFile(string directory)
    {
        SaveData data = LoadFile(directory);
        if (data == null)
        {
            EmitSignal(SignalName.PushError, "Failed to load file, invalid path?");
            return;
        }

        // delete the old model
        var model = SkeletonManager.Singleton.SkeletonInstance;
        if (model != null)
        {
            model.QueueFree();
        }

        ImportModelData(data.SkeletonGLTFData);

        // set the properties
        foreach (var i in data.Properties)
            GetNodeOrNull<Node>(i.NodePath)?.SetDeferred(i.PropertyPath, GD.BytesToVar(i.Data));

        SetDirectory(directory);
    }

    public void CreateFile(string directory)
    {
        SetDirectory(directory);

        byte[] data = SaveScene();
        FileStream file = new(directory, FileMode.Create, System.IO.FileAccess.Write, FileShare.None);
        file.Write(data, 0, data.Length);
        file.Close();
    }

    private SaveData LoadFile(string directory)
    {
        if (!File.Exists(directory))
        {
            return null;
        }

        byte[] data = File.ReadAllBytes(directory);

        var lz4Options = MessagePackSerializerOptions.Standard.WithCompression(MessagePackCompression.Lz4BlockArray);
        return MessagePackSerializer.Deserialize<SaveData>(data, lz4Options);
    }

    private void SetDirectory(string directory)
    {
        _currentSaveFile = directory;

        if (directory == null)
            GetTree().Root.Title = "[Unsaved] GMod PM+";
        else
            GetTree().Root.Title = directory + " - GMod PM+";
    }

    private byte[] SaveScene()
    {
        SaveData data = new();

        // skeleton data
        var gltfDocumentSave = new GltfDocument();
        var gltfStateSave = new GltfState();
        gltfDocumentSave.AppendFromScene(SkeletonManager.Singleton.SkeletonInstance.GetParent(), gltfStateSave);
        data.SkeletonGLTFData = gltfDocumentSave.GenerateBuffer(gltfStateSave);

        // property data
        List<Node> nodes = [FieldsToSave];
        List<PersistentProperty> properties = [];

        string[] bannedControlProperties = [
            "position",
            "size",
            "rotation",
            "skeleton",
            "pivot_offset",
            "pivot_offset_ratio",
            "scale",
            "vertical"
        ];

        for (int i = 0; i < nodes.Count; i++)
        {
            nodes.AddRange(nodes[i].GetChildren());

            foreach (Godot.Collections.Dictionary k in nodes[i].GetPropertyList())
            {
                string propertyName = k["name"].AsString();
                Variant.Type propertyType = (Variant.Type)k["type"].AsInt32();

                if (bannedControlProperties.Contains(propertyName) && nodes[i] is Control)
                    continue;

                if (propertyType == Variant.Type.Object || propertyType == Variant.Type.Array || propertyType == Variant.Type.Dictionary)
                    continue;

                PersistentProperty propData = new();
                propData.NodePath = nodes[i].GetPath();
                propData.PropertyPath = propertyName;
                propData.Data = GD.VarToBytes(nodes[i].Get(propertyName));
                properties.Add(propData);
            }
        }

        // set it now
        data.Properties = properties.ToArray();

        // enabling compression
        var lz4Options = MessagePackSerializerOptions.Standard.WithCompression(MessagePackCompression.Lz4BlockArray);
        return MessagePackSerializer.Serialize(data, lz4Options);
    }

    private void ImportModelData(byte[] data)
    {
        GltfDocument gltfDocumentLoad = new();

        GltfState gltfStateLoad = new();
        gltfStateLoad.BasePath = "";
        var error = gltfDocumentLoad.AppendFromBuffer(data, "", gltfStateLoad);

        if (error != Error.Ok)
        {
            EmitSignal(SignalName.PushError, "Couldn't open save file, error " + error.ToString());
            return;
        }

        var gltfSceneRootNode = gltfDocumentLoad.GenerateScene(gltfStateLoad, 30.0f);
        ToBeAddedTo.AddChild(gltfSceneRootNode);

        Skeleton3D skeleton = GetSkeleton(gltfSceneRootNode);
        if (skeleton == null)
        {
            EmitSignal(SignalName.PushError, "The imported file is not an armature");
            return;
        }

        // reparent now
        // skeleton.Reparent(ToBeAddedTo);
        //gltfSceneRootNode.QueueFree();

        SkeletonManager.Singleton.SkeletonInstance = skeleton;
    }

    private Skeleton3D GetSkeleton(Node node)
    {
        List<Node> children = [node];

        for (int i = 0; i < children.Count; i++)
        {
            children.AddRange(children[i].GetChildren());

            if (children[i] is Skeleton3D)
                return (Skeleton3D)children[i];
        }

        return null;
    }
}
