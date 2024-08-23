using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class CustumRendererFeature : ScriptableRendererFeature
{
    private CustumRenderPass CustumRenderPass;

    private CameraNormalTexturePass cameraNormalTexturePass;
    private RTHandle cameraNormalTextureRT;

    public override void Create()
    {
        cameraNormalTexturePass = new CameraNormalTexturePass(RenderQueueRange.opaque, -1);
        cameraNormalTexturePass.renderPassEvent = RenderPassEvent.AfterRenderingPrePasses;        
        CustumRenderPass = new CustumRenderPass();
        CustumRenderPass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(cameraNormalTexturePass);
        renderer.EnqueuePass(CustumRenderPass);
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        // https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@13.1/manual/upgrade-guide-2022-1.html
        var desc = renderingData.cameraData.cameraTargetDescriptor;
        desc.colorFormat = RenderTextureFormat.ARGBHalf;
        desc.depthBufferBits = 0; // Color and depth cannot be combined in RTHandles
        RenderingUtils.ReAllocateIfNeeded(ref cameraNormalTextureRT, desc, FilterMode.Point, TextureWrapMode.Clamp, name: cameraNormalTexturePass.TextureName);
        cameraNormalTexturePass.Setup(desc, cameraNormalTextureRT);
        CustumRenderPass.SetRenderTarget(renderer.cameraColorTargetHandle, cameraNormalTextureRT);
    }
}

