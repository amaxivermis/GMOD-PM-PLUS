using Godot;
using System;

public partial class SkeletonManager : Node
{
    [Signal]
    public delegate void SkeletonChangedEventHandler(Skeleton3D newSkeleton);

    public static SkeletonManager Singleton { get; private set; }
    public Skeleton3D SkeletonInstance
    {
        get => _skeletonInstance; set
        {
            _skeletonInstance = value;
            EmitSignal(SignalName.SkeletonChanged, _skeletonInstance);
        }
    }

    private Skeleton3D _skeletonInstance;

    // Called when the node enters the scene tree for the first time.
    public override void _Ready()
    {
        Singleton = this;
    }
}
