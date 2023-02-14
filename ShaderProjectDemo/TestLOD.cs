
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestLOD : MonoBehaviour
{
    public int lod = 600;
    // Start is called before the first frame update
    void Start()
    {
        Shader.globalMaximumLOD = lod;
    }

}
