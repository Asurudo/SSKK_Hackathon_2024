using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class CustumPostEffect : VolumeComponent, IPostProcessComponent
{
    [Range(0.1f, 3.0f)]
    public FloatParameter fogDensity = new FloatParameter(0.0f);
    public ColorParameter fogColor = new ColorParameter(Color.white);
    public FloatParameter fogStart = new FloatParameter(0.0f);
    public FloatParameter fogEnd = new FloatParameter(10.0f);

    public TextureParameter noiseTexture = new TextureParameter(null);

    [Range(-0.5f, 0.5f)]
    public FloatParameter fogXSpeed = new FloatParameter(0.1f);
    [Range(-0.5f, 0.5f)]
    public FloatParameter fogYSpeed = new FloatParameter(0.1f);
    [Range(0.0f, 3.0f)]
    public FloatParameter noiseAmount = new FloatParameter(1.0f);

    public bool IsActive() => true;

    public bool IsTileCompatible() => false;

}