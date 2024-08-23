using PLATEAU.CityGML;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using static Unity.VisualScripting.Member;

public class CustumRenderPass : ScriptableRenderPass
{
    private UnityEngine.Material sampleMaterial;
    private RenderTargetIdentifier currentTarget;
    private RTHandle normalTextureHandle;
    private RTHandle cameraColorTargetHandle;

    public CustumRenderPass()
    {
        Shader sampleShader = Shader.Find("Hidden/Custom/CustumPostProcess");
        if (sampleShader != null) sampleMaterial = new UnityEngine.Material(sampleShader);
    }

    public void SetRenderTarget(RenderTargetIdentifier target, RTHandle normal, RTHandle color)
    {
        this.currentTarget = target;
        this.normalTextureHandle = normal;
        this.cameraColorTargetHandle = color;
    }

    // This method is called before executing the render pass.
    // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
    // When empty this render pass will render to the active camera render target.
    // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
    // The render pipeline will ensure target setup and clearing happens in an performance manner.
    public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
    {

    }

    // Here you can implement the rendering logic.
    // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
    // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
    // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (!renderingData.cameraData.postProcessEnabled) return;
        if (renderingData.cameraData.isSceneViewCamera) return;
        CustumPostEffect volume = VolumeManager.instance.stack.GetComponent<CustumPostEffect>();

        Camera camera = renderingData.cameraData.camera;
        Transform cameraTransform = camera.transform;

        Matrix4x4 frustumCorners = Matrix4x4.identity;

        float fov = camera.fieldOfView;
        float near = camera.nearClipPlane;
        float aspect = camera.aspect;

        float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
        Vector3 toRight = cameraTransform.right * halfHeight * aspect;
        Vector3 toTop = cameraTransform.up * halfHeight;

        Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;
        float scale = topLeft.magnitude / near;

        topLeft.Normalize();
        topLeft *= scale;

        Vector3 topRight = cameraTransform.forward * near + toRight + toTop;
        topRight.Normalize();
        topRight *= scale;

        Vector3 bottomLeft = cameraTransform.forward * near - toTop - toRight;
        bottomLeft.Normalize();
        bottomLeft *= scale;

        Vector3 bottomRight = cameraTransform.forward * near + toRight - toTop;
        bottomRight.Normalize();
        bottomRight *= scale;

        frustumCorners.SetRow(0, bottomLeft);
        frustumCorners.SetRow(1, bottomRight);
        frustumCorners.SetRow(2, topRight);
        frustumCorners.SetRow(3, topLeft);

        int FrustumCornersRayId = Shader.PropertyToID("_FrustumCornersRay");
        sampleMaterial.SetMatrix(FrustumCornersRayId, frustumCorners);
        int FogDensityId = Shader.PropertyToID("_FogDensity");
        sampleMaterial.SetFloat(FogDensityId, volume.fogDensity.value);
        int FogColorId = Shader.PropertyToID("_FogColor");
        sampleMaterial.SetColor(FogColorId, volume.fogColor.value);
        int FogStartId = Shader.PropertyToID("_FogStart");
        sampleMaterial.SetFloat(FogStartId, volume.fogStart.value);
        int FogEndId = Shader.PropertyToID("_FogEnd");
        sampleMaterial.SetFloat(FogEndId, volume.fogEnd.value);

        int NoiseTexId = Shader.PropertyToID("_NoiseTex");
        sampleMaterial.SetTexture(NoiseTexId, volume.noiseTexture.value);
        int FogXSpeedId = Shader.PropertyToID("_FogXSpeed");
        sampleMaterial.SetFloat(FogXSpeedId, volume.fogXSpeed.value);
        int FogYSpeedId = Shader.PropertyToID("_FogYSpeed");
        sampleMaterial.SetFloat(FogYSpeedId, volume.fogYSpeed.value);
        int NoiseAmountId = Shader.PropertyToID("_NoiseAmount");
        sampleMaterial.SetFloat(NoiseAmountId, volume.noiseAmount.value);

        var cmd = CommandBufferPool.Get("CustomRenderPass");


        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();

        int temp = Shader.PropertyToID("_MainTex");
        sampleMaterial.SetTexture(temp, cameraColorTargetHandle);
        RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
        cmd.GetTemporaryRT(temp, desc);
        cmd.Blit(currentTarget, temp);

        cmd.SetGlobalTexture("_MainTex", cameraColorTargetHandle);
        cmd.Blit(temp, currentTarget, sampleMaterial);
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }

    /// Cleanup any allocated resources that were created during the execution of this render pass.
    public override void FrameCleanup(CommandBuffer cmd)
    {
    }
};