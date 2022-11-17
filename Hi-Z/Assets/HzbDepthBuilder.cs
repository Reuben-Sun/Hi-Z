using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HzbDepthBuilder : MonoBehaviour
{
    public RenderTexture hzbDepth;
    public Shader hzbBuildShader;
    public bool stopMode;
    
    private Material _material;
    private readonly int _DepthTextureShaderId = Shader.PropertyToID("_DepthTexture");
    private readonly int _InvSizeShaderId = Shader.PropertyToID("_InvSize");

    private void Start()
    {
        if (hzbBuildShader == null)
        {
            return;
        }
        _material = new Material(hzbBuildShader);
        Camera.main.depthTextureMode |= DepthTextureMode.Depth;

        hzbDepth = new RenderTexture(1024, 1024, 0, RenderTextureFormat.RHalf);
        hzbDepth.autoGenerateMips = false;
        hzbDepth.useMipMap = true;
        hzbDepth.filterMode = FilterMode.Point;
        hzbDepth.Create();
        
        HzbInstance.HzbDepth = hzbDepth;
    }

    private void OnDestroy()
    {
        hzbDepth.Release();
        Destroy(hzbDepth);
    }

    private void OnPreRender()
    {
        if (stopMode)
        {
            return;
        }

        int w = hzbDepth.width;
        int h = hzbDepth.height;
        int level = 0;

        RenderTexture lastFrameRenderTexture = null;
        RenderTexture tempRT;
        while (h > 8)
        {
            _material.SetVector(_InvSizeShaderId, new Vector4(1.0f/w, 1.0f/h, 0, 0));
            tempRT = RenderTexture.GetTemporary(w, h, 0, hzbDepth.format);
            tempRT.filterMode = FilterMode.Point;
            if (lastFrameRenderTexture == null)
            {
                Graphics.Blit(Shader.GetGlobalTexture("_CameraDepthTexture"), tempRT);
            }
            else
            {
                _material.SetTexture(_DepthTextureShaderId, lastFrameRenderTexture);
                Graphics.Blit(null, tempRT, _material);
                RenderTexture.ReleaseTemporary(lastFrameRenderTexture);
            }
            Graphics.CopyTexture(tempRT, 0, 0, hzbDepth, 0, level);
            lastFrameRenderTexture = tempRT;

            w /= 2;
            h /= 2;
            level++;
        }
        RenderTexture.ReleaseTemporary(lastFrameRenderTexture);
    }
}
