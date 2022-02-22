using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Text;

#if UNITY_EDITOR
using UnityEditor;
[CustomEditor(typeof(GaussianKernel))]
public class GaussianKernelEditor : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        if(GUILayout.Button("Calc Kernel"))
        {
            var inst = (GaussianKernel)target;
            var weights = inst.CalcKernel(inst.count);

            var sb = new StringBuilder();
            for (int i = 0; i < weights.GetLength(0); i++)
            {
                for (int j = 0; j < weights.GetLength(1); j++)
                {
                    sb.Append($"{weights[i, j]} , ");
                }
                sb.AppendLine();
            }
            Debug.Log(sb);
        }
    }
}
#endif

public class GaussianKernel : MonoBehaviour
{
    public int count = 3;
    public float[,] CalcKernel(int count,float sigma=1)
    {
        float[,] weights = new float[count,count];

        var center = count / 2;
        float sum = 0;
        for (int i = 0; i < count; i++)
        {
            for (int j = 0; j < count; j++)
            {
                weights[i, j] = (1f / (2 * Mathf.PI * sigma * sigma)) * Mathf.Exp(
                    -((i - center) * (i - center) + (j - center) * (j - center)) / (2 * sigma * sigma)
                    );
                sum += weights[i, j];
            }
        }
        for (int i = 0; i < count; i++)
        {
            for(int j = 0; j < count; j++)
            {
                weights[i, j] /= sum;
            }
        }
        return weights;
    }
}
