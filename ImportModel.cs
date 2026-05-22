using Godot;
using System;
using System.Collections.Generic;

public partial class ImportModel : Node
{


    [Signal]
    public delegate void PushErrorEventHandler(string error);
    [Signal]
    public delegate void PushWarningEventHandler(string warning);
    [Signal]
    public delegate void ProjectFileEventHandler(string file);

    [Export] Node ToBeAddedTo;

    // Called when the node enters the scene tree for the first time.
    public override void _Ready()
    {
    }

    // Called every frame. 'delta' is the elapsed time since the previous frame.
    public override void _Process(double delta)
    {
    }

    public void Import(string path)
    {
        var model = SkeletonManager.Singleton.SkeletonInstance;
        if (model != null)
        {
            model.QueueFree();
        }

        if (path.GetExtension().ToLower() == "glb" || path.GetExtension().ToLower() == "gltf")
            ImportGLTF(path);
        else if (path.GetExtension().ToLower() == "fbx")
            ImportFBX(path);
        // it's a GMP file
        else if (path.GetExtension().ToLower() == "gmp")
            EmitSignal(SignalName.ProjectFile, path);
    }

    public void ImportGLTF(string path)
    {
        GD.Print("Importing GLTF: " + path);

        GltfDocument gltfDocumentLoad = new();

        GltfState gltfStateLoad = new();
        var error = gltfDocumentLoad.AppendFromFile(path, gltfStateLoad);

        if (error != Error.Ok)
        {
            EmitSignal(SignalName.PushError, "Couldn't open glTF file, error " + error.ToString());
            return;
        }

        var gltfSceneRootNode = gltfDocumentLoad.GenerateScene(gltfStateLoad, 30.0f);
        HandleScene(gltfSceneRootNode);
    }

    public void ImportFBX(string path)
    {
        EmitSignal(SignalName.PushWarning, "FBX is generally buggier than GLTF and is a closed format, if you use 3D modelling software it's recommended to use GLTF instead which is also an open format");

        GD.Print("Importing FBX: " + path);

        FbxDocument fbxDocumentLoad = new();

        FbxState fbxStateLoad = new();
        var error = fbxDocumentLoad.AppendFromFile(path, fbxStateLoad);

        if (error != Error.Ok)
        {
            EmitSignal(SignalName.PushError, "Couldn't open FBX file, error " + error.ToString());
            return;
        }

        var gltfSceneRootNode = fbxDocumentLoad.GenerateScene(fbxStateLoad, 30.0f);
        HandleScene(gltfSceneRootNode);
    }

    private void HandleScene(Node scene)
    {
        ToBeAddedTo.AddChild(scene);

        Skeleton3D skeleton = GetSkeleton(scene);
        if (skeleton == null)
        {
            EmitSignal(SignalName.PushError, "The imported file is not an armature");
            return;
        }

        // reparent now
        //skeleton.Reparent(ToBeAddedTo);
        //scene.QueueFree();

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
