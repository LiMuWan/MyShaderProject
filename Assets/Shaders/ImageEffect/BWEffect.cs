using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//此脚本挂摄像机上
public class BWEffect : MonoBehaviour
{
    private Material m;
    [Range(0,1)]
    public float intensity = 0;
    void Awake()
    {
        m = new Material(Shader.Find("Hidden/BWDiffuse"));
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if(intensity == 0)
        {
             Graphics.Blit(src,dest);
             return;
        }
        m.SetFloat("_bwBlend",intensity);
        Graphics.Blit(src,dest,m);
    }
}
