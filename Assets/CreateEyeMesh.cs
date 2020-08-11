using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CreateEyeMesh : MonoBehaviour
{
    public Material fractalMaterial;
    public Transform head;

    public float horFov;
    public float verFov;
    public int horRes;
    public int verRes;

    public float eyeMeshSize = 0.31f;

    GameObject createGrid()
    {
        GameObject gridObject = new GameObject();
        Mesh mesh = new Mesh();

        Vector3[] vertices = new Vector3[horRes * verRes];
        for (int j = 0; j < verRes; j++)
        {
            for (int i = 0; i < horRes; i++)
            {
                float theta = horFov * (i - horRes * 0.5f) / horRes;
                float phi = verFov * (j - verRes * 0.5f) / verRes;
                vertices[j * horRes + i] = new Vector3(Mathf.Sin(theta) * Mathf.Cos(phi), Mathf.Sin(phi), Mathf.Cos(theta) * Mathf.Cos(phi));
            }
        }
        mesh.SetVertices(vertices);

        int[] triangles = new int[(verRes - 1) * (horRes - 1) * 6];
        for (int j = 0; j < verRes-1; j++)
        {
            for (int i = 0; i < horRes-1; i++)
            {
                triangles[6 * (j * (horRes - 1) + i)] = j * horRes + i;
                triangles[6 * (j * (horRes - 1) + i) + 1] = (j + 1) * horRes + i;
                triangles[6 * (j * (horRes - 1) + i) + 2] = j * horRes + i + 1;
                triangles[6 * (j * (horRes - 1) + i) + 3] = (j + 1) * horRes + i;
                triangles[6 * (j * (horRes - 1) + i) + 4] = (j + 1) * horRes + i + 1;
                triangles[6 * (j * (horRes - 1) + i) + 5] = j * horRes + i + 1;
            }
        }

        mesh.SetTriangles(triangles, 0);

        MeshFilter meshFilter = gridObject.AddComponent<MeshFilter>();
        meshFilter.mesh = mesh;
        MeshRenderer meshRenderer = gridObject.AddComponent<MeshRenderer>();
        meshRenderer.material = fractalMaterial;
        gridObject.transform.localScale = new Vector3(eyeMeshSize, eyeMeshSize, eyeMeshSize);
        return gridObject;
    }

    // Start is called before the first frame update
    void Start()
    {
        print("I started.");
        GameObject lefty = createGrid();
        lefty.transform.SetParent(head, false);
        print("I Finished.");
    }
}
