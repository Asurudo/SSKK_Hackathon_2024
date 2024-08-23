using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class CustumPostEffect : VolumeComponent, IPostProcessComponent
{
    [Tooltip("KuwaharaFilter RectSize.")]
    public ClampedIntParameter rectSize = new ClampedIntParameter(1, 1, 18);
    [Tooltip("Outline.")]
    public BoolParameter outline = new BoolParameter(false);
    [Tooltip("Edge DepthThreshold.")]
    public ClampedFloatParameter edgeDepthThreshold = new ClampedFloatParameter(0.1f, 0.01f, 1.0f);
    [Tooltip("Edge Color.")]
    public ColorParameter edgeColor = new ColorParameter(new Color(0.01f, 0.01f, 0.01f));

    public bool IsActive() => true;

    public bool IsTileCompatible() => false;

}