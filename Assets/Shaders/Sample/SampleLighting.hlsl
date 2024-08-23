#ifndef CUSTOM_SHADER_SAMPLE_LIGHTING_INCLUDED
#define CUSTOM_SHADER_SAMPLE_LIGHTING_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

float3 SimpleLighting(float3 positionWS, float3 normalWS, float3 baseColor)
{
    float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
    Light mainLight = GetMainLight(shadowCoord);

    float diffuse = saturate(dot(normalWS, mainLight.direction));

    // ÇªÇÍÇ¡Ç€Ç≠Ç»ÇÈÇÊÇ§Ç…ê›íË
    float diffuseGradation = lerp(0.5, 1, diffuse);
    float shadowGradation = lerp(0.5, 1, mainLight.shadowAttenuation);

    float3 returnColor = baseColor * diffuseGradation * shadowGradation;
    
    return returnColor;
}

#endif