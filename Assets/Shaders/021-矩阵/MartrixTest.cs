using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MartrixTest : MonoBehaviour
{
    public Matrix4x4 matrix1;
    // Start is called before the first frame update
    void Start()
    {
        Vector3 v = new Vector3(2, 3, 3);
        matrix1 = Matrix4x4.Translate(v);
        Debug.Log(matrix1);
    }

    // Update is called once per frame
    void Update()
    {

    }
}
