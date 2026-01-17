using Godot;
using MIConvexHull;
using System;

public partial class CollisionGenerator : Node
{
    /// <summary>
    /// Represents a point in 3D space.
    /// </summary>
    class Vertex : IVertex
    {
        public Vertex(double x, double y, double z)
        {
            Position = new double[] { x, y, z };
        }

        //public Point3D ToPoint3D()
        //{
        //    return new Point3D(Position[0], Position[1], Position[2]);
        //}

        public double[] Position { get; set; }
    }

    class Face : ConvexFace<Vertex, Face>
    {

    }

    public Mesh GenerateConvexHull(Godot.Collections.Array<Vector3> vertices)
    {
        System.Collections.Generic.List<Vertex> convertedVertices = [];

        foreach (Vector3 i in vertices)
        {
            convertedVertices.Add(new(i.X, i.Y, i.Z));
        }

        var convexHull = ConvexHull.Create<Vertex, Face>(convertedVertices);
        Vertex[] convexHullVertices = convexHull.Result.Points as Vertex[];

        // Generate mesh
        Godot.Collections.Array surfaceArray = [];
        surfaceArray.Resize((int)Mesh.ArrayType.Max);

        System.Collections.Generic.List<Vector3> verts = [];
        System.Collections.Generic.List<int> indices = [];

        foreach (Vertex i in convexHullVertices)
        {
            verts.Add(new Vector3((float)i.Position[0], (float)i.Position[1], (float)i.Position[2]));
        }

        foreach (Face f in convexHull.Result.Faces)
        {
            // The vertices are stored in clockwise order.

            indices.Add(Array.IndexOf(convexHullVertices, f.Vertices[0]));
            indices.Add(Array.IndexOf(convexHullVertices, f.Vertices[1]));
            indices.Add(Array.IndexOf(convexHullVertices, f.Vertices[2]));
        }

        surfaceArray[(int)Mesh.ArrayType.Vertex] = verts.ToArray();
        surfaceArray[(int)Mesh.ArrayType.Index] = indices.ToArray();

        ArrayMesh newMesh = new();
        newMesh.AddSurfaceFromArrays(Mesh.PrimitiveType.Triangles, surfaceArray);
        return newMesh;
    }

    /*public int[] TriangulateConvex(Godot.Collections.Array<Vector3> vertices)
    {
        System.Collections.Generic.List<Vertex> convertedVertices = [];

        foreach (Vector3 i in vertices)
        {
            convertedVertices.Add(new(i.X, i.Y, i.Z));
        }

        var indices = Triangulation.CreateDelaunay(convertedVertices).Cells;

        return null;
        }*/
}
