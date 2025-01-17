using UnityEngine;
using UnityEngine.Experimental.Rendering.RenderGraphModule;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

/// <summary>
/// Defines the <see cref="MultiMaterialFullScreenPassFeature" />
/// </summary>
public class MultiMaterialFullScreenPassFeature : ScriptableRendererFeature
{
    /// <summary>
    /// An injection point for the full screen pass. This is similar to RenderPassEvent enum but limits to only supported events
    /// </summary>
    public enum InjectionPoint
    {
        /// <summary>
        /// Defines the BeforeRenderingTransparents
        /// </summary>
        BeforeRenderingTransparents = RenderPassEvent.BeforeRenderingTransparents,

        /// <summary>
        /// Defines the BeforeRenderingPostProcessing
        /// </summary>
        BeforeRenderingPostProcessing = RenderPassEvent.BeforeRenderingPostProcessing,

        /// <summary>
        /// Defines the AfterRenderingPostProcessing
        /// </summary>
        AfterRenderingPostProcessing = RenderPassEvent.AfterRenderingPostProcessing
    }

    /// <summary>
    /// Material the Renderer Feature uses to render the effect
    /// </summary>
    public UnityEngine.Material[] passMaterial;

    /// <summary>
    /// Selection for when the effect is rendered
    /// </summary>
    public InjectionPoint injectionPoint = InjectionPoint.AfterRenderingPostProcessing;

    /// <summary>
    /// One or more requirements for pass. Based on chosen flags certain passes will be added to the pipeline
    /// </summary>
    public ScriptableRenderPassInput requirements = ScriptableRenderPassInput.Color;

    /// <summary>
    /// An index that tells renderer feature which pass to use if passMaterial contains more than one. Default is 0.
    /// We draw custom pass index entry with the custom dropdown inside FullScreenPassRendererFeatureEditor that sets this value.
    /// Setting it directly will be overridden by the editor class
    /// </summary>
    [HideInInspector]
    public int passIndex = 0;

    /// <summary>
    /// Defines the fullScreenPass
    /// </summary>
    private CustomFullScreenRenderPass fullScreenPass;

    /// <summary>
    /// Defines the requiresColor
    /// </summary>
    private bool requiresColor;

    /// <summary>
    /// Defines the injectedBeforeTransparents
    /// </summary>
    private bool injectedBeforeTransparents;

    /// <inheritdoc/>
    public override void Create()
    {
        fullScreenPass = new CustomFullScreenRenderPass();
        fullScreenPass.renderPassEvent = (RenderPassEvent)injectionPoint;

        // This copy of requirements is used as a parameter to configure input in order to avoid copy color pass
        ScriptableRenderPassInput modifiedRequirements = requirements;

        requiresColor = (requirements & ScriptableRenderPassInput.Color) != 0;
        injectedBeforeTransparents = injectionPoint <= InjectionPoint.BeforeRenderingTransparents;

        if (requiresColor && !injectedBeforeTransparents)
        {
            // Removing Color flag in order to avoid unnecessary CopyColor pass
            // Does not apply to before rendering transparents, due to how depth and color are being handled until
            // that injection point.
            modifiedRequirements ^= ScriptableRenderPassInput.Color;
        }
        fullScreenPass.ConfigureInput(modifiedRequirements);
    }

    /// <inheritdoc/>
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (passMaterial.Length == 0)
        {
            Debug.LogWarningFormat("Missing Post Processing effect Material. {0} Fullscreen pass will not execute. Check for missing reference in the assigned renderer.", GetType().Name);
            return;
        }

        fullScreenPass.Setup(passMaterial, passIndex, requiresColor, injectedBeforeTransparents, "FullScreenPassRendererFeature", renderingData);

        renderer.EnqueuePass(fullScreenPass);
    }

    /// <inheritdoc/>
    protected override void Dispose(bool disposing)
    {
        fullScreenPass.Dispose();
    }

    /// <summary>
    /// Defines the <see cref="CustomFullScreenRenderPass" />
    /// </summary>
    internal class CustomFullScreenRenderPass : ScriptableRenderPass
    {
        /// <summary>
        /// Defines the s_PassMaterial
        /// </summary>
        private static UnityEngine.Material[] s_PassMaterial;

        /// <summary>
        /// Defines the m_PassIndex
        /// </summary>
        private int m_PassIndex;

        /// <summary>
        /// Defines the m_RequiresColor
        /// </summary>
        private bool m_RequiresColor;

        /// <summary>
        /// Defines the m_IsBeforeTransparents
        /// </summary>
        private bool m_IsBeforeTransparents;

        /// <summary>
        /// Defines the m_PassData
        /// </summary>
        private PassData m_PassData;

        /// <summary>
        /// Defines the m_ProfilingSampler
        /// </summary>
        private ProfilingSampler m_ProfilingSampler;

        /// <summary>
        /// Defines the m_CopiedColor
        /// </summary>
        private RTHandle m_CopiedColor;

        /// <summary>
        /// Defines the m_BlitTextureShaderID
        /// </summary>
        private static readonly int m_BlitTextureShaderID = Shader.PropertyToID("_BlitTexture");

        /// <summary>
        /// The Setup
        /// </summary>
        /// <param name="mat">The mat<see cref="UnityEngine.Material[]"/></param>
        /// <param name="index">The index<see cref="int"/></param>
        /// <param name="requiresColor">The requiresColor<see cref="bool"/></param>
        /// <param name="isBeforeTransparents">The isBeforeTransparents<see cref="bool"/></param>
        /// <param name="featureName">The featureName<see cref="string"/></param>
        /// <param name="renderingData">The renderingData<see cref="RenderingData"/></param>
        public void Setup(UnityEngine.Material[] mat, int index, bool requiresColor, bool isBeforeTransparents, string featureName, in RenderingData renderingData)
        {
            s_PassMaterial = mat;
            m_PassIndex = index;
            m_RequiresColor = requiresColor;
            m_IsBeforeTransparents = isBeforeTransparents;
            m_ProfilingSampler ??= new ProfilingSampler(featureName);

            var colorCopyDescriptor = renderingData.cameraData.cameraTargetDescriptor;
            colorCopyDescriptor.depthBufferBits = (int)DepthBits.None;
            RenderingUtils.ReAllocateIfNeeded(ref m_CopiedColor, colorCopyDescriptor, name: "_FullscreenPassColorCopy");

            m_PassData ??= new PassData();
        }

        /// <summary>
        /// The Dispose
        /// </summary>
        public void Dispose()
        {
            m_CopiedColor?.Release();
        }

        /// <summary>
        /// The OnCameraSetup
        /// </summary>
        /// <param name="cmd">The cmd<see cref="CommandBuffer"/></param>
        /// <param name="renderingData">The renderingData<see cref="RenderingData"/></param>
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            // FullScreenPass manages its own RenderTarget.
            // ResetTarget here so that ScriptableRenderer's active attachement can be invalidated when processing this ScriptableRenderPass.
            ResetTarget();
        }

        /// <summary>
        /// The Execute
        /// </summary>
        /// <param name="context">The context<see cref="ScriptableRenderContext"/></param>
        /// <param name="renderingData">The renderingData<see cref="RenderingData"/></param>
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            ref var cameraData = ref renderingData.cameraData;

            var cmd = CommandBufferPool.Get();

            if (s_PassMaterial.Length == 0)
            {
                // should not happen as we check it in feature
                return;
            }

            if (cameraData.isPreviewCamera)
            {
                return;
            }

            using (new ProfilingScope(cmd, profilingSampler))
            {
                for (int i = 0; i < s_PassMaterial.Length; i++)
                {
                    for (int pass = 0; pass < s_PassMaterial[i].passCount; pass++)
                    {
                        if (m_RequiresColor)
                        {
                            // For some reason BlitCameraTexture(cmd, dest, dest) scenario (as with before transparents effects) blitter fails to correctly blit the data
                            // Sometimes it copies only one effect out of two, sometimes second, sometimes data is invalid (as if sampling failed?).
                            // Adding RTHandle in between solves this issue.

                            var source = cameraData.renderer.cameraColorTargetHandle;

                            Blitter.BlitCameraTexture(cmd, source, m_CopiedColor);
                            s_PassMaterial[i].SetTexture(m_BlitTextureShaderID, m_CopiedColor);

                            var viewToWorld = cameraData.camera.cameraToWorldMatrix;
                            s_PassMaterial[i].SetMatrix("_ViewToWorld", viewToWorld);

                            Matrix4x4 frustumCorners = Matrix4x4.identity;
                            var camera = renderingData.cameraData.camera;
                            float fov = camera.fieldOfView;
                            float near = camera.nearClipPlane;
                            float aspect = camera.aspect;

                            float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
                            Vector3 toRight = camera.transform.right * halfHeight * aspect;
                            Vector3 toTop = camera.transform.up * halfHeight;

                            Vector3 topLeft = camera.transform.forward * near + toTop - toRight;
                            float scale = topLeft.magnitude / near;

                            topLeft.Normalize();
                            topLeft *= scale;

                            Vector3 topRight = camera.transform.forward * near + toRight + toTop;
                            topRight.Normalize();
                            topRight *= scale;

                            Vector3 bottomLeft = camera.transform.forward * near - toTop - toRight;
                            bottomLeft.Normalize();
                            bottomLeft *= scale;

                            Vector3 bottomRight = camera.transform.forward * near + toRight - toTop;
                            bottomRight.Normalize();
                            bottomRight *= scale;

                            frustumCorners.SetRow(0, bottomLeft);
                            frustumCorners.SetRow(1, bottomRight);
                            frustumCorners.SetRow(2, topRight);
                            frustumCorners.SetRow(3, topLeft);

                            s_PassMaterial[i].SetMatrix("_FrustumCornersRay", frustumCorners);

                        }

                        CoreUtils.SetRenderTarget(cmd, cameraData.renderer.cameraColorTargetHandle);

                        CoreUtils.DrawFullScreen(cmd, s_PassMaterial[i], null, pass);
                    }
                }
            }

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            CommandBufferPool.Release(cmd);
        }

        /// <summary>
        /// Defines the <see cref="PassData" />
        /// </summary>
        private class PassData
        {
            /// <summary>
            /// Defines the effectMaterial
            /// </summary>
            internal UnityEngine.Material effectMaterial;

            /// <summary>
            /// Defines the passIndex
            /// </summary>
            internal int passIndex;

            /// <summary>
            /// Defines the source
            /// </summary>
            internal TextureHandle source;

            /// <summary>
            /// Defines the copiedColor
            /// </summary>
            public TextureHandle copiedColor;
        }
    }
}
