#ifndef CUSTOM_SHADER_PLATEAU_TRIPLANAR_FUNCTION_INCLUDED
#define CUSTOM_SHADER_PLATEAU_TRIPLANAR_FUNCTION_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"



#ifndef FLT_EPSILON
#define FLT_EPSILON 1.192092896e-07
#endif

struct PlateauTriplanarInput
{
    sampler2D mainTexture;
    float4 mainColor;
    sampler2D normalMap;
    float normalStrength;
    float metallic;
    float roughness;
    sampler2D ambientOcclusionTexture;
    float ambientOcclusion;
    float opacity;
    float titling;
    float blend;
    sampler2D emissionTexture;
    float4 emissionColor;
    sampler2D roughnessTexture;
    sampler2D metallicTexture;
    float3 positionWS;
    float3 normalWS;
    float3 tangentWS;
    float3 binormalWS;
};

float3 UnpackNormalmapRGorAGLocal(float4 packednormal)
{
    // This do the trick
    packednormal.x *= packednormal.w;

    float3 normal;
    normal.xy = packednormal.xy * 2 - 1;
    normal.z = sqrt(1 - saturate(dot(normal.xy, normal.xy)));
    return normal;
}

float3 TransformWorldToTangentLocal(float3 dirWS, float3x3 worldToTangent)
{
    return mul(worldToTangent, dirWS);
}

float4 TriplanarSample(sampler2D sampleTexture, float3 position, float3 normal, float tile, float blend)
{
    float3 Node_UV = position * tile;
    float3 Node_Blend = pow(abs(normal), blend);
    Node_Blend /= dot(Node_Blend, 1.0);
    float4 Node_X = tex2D(sampleTexture, Node_UV.zy);
    float4 Node_Y = tex2D(sampleTexture, Node_UV.xz);
    float4 Node_Z = tex2D(sampleTexture, Node_UV.xy);
    return Node_X * Node_Blend.x + Node_Y * Node_Blend.y + Node_Z * Node_Blend.z;
}

float4 TriplanarSampleNormal(sampler2D normalTexture, float3 position, float3 normal, float3 tangent, float3 binormal, float tile, float blend)
{
    float3 Node_UV = position * tile;
    float3 Node_Blend = max(pow(abs(normal), blend), 0);
    Node_Blend /= (Node_Blend.x + Node_Blend.y + Node_Blend.z).xxx;
    float3 Node_X = UnpackNormalmapRGorAGLocal(tex2D(normalTexture, Node_UV.zy));
    float3 Node_Y = UnpackNormalmapRGorAGLocal(tex2D(normalTexture, Node_UV.xz));
    float3 Node_Z = UnpackNormalmapRGorAGLocal(tex2D(normalTexture, Node_UV.xy));
    Node_X = float3(Node_X.xy + normal.zy, abs(Node_X.z) * normal.x);
    Node_Y = float3(Node_Y.xy + normal.xz, abs(Node_Y.z) * normal.y);
    Node_Z = float3(Node_Z.xy + normal.xy, abs(Node_Z.z) * normal.z);
    float4 result = float4(normalize(Node_X.zyx * Node_Blend.x + Node_Y.xzy * Node_Blend.y + Node_Z.xyz * Node_Blend.z), 1);
    float3x3 Node_Transform = float3x3(tangent, binormal, normal);
    result.xyz = TransformWorldToTangentLocal(result.xyz, Node_Transform);
    
    return result;
}

float3 NormalStrength(float3 normal, float strength)
{
    return float3(normal.xy * strength, lerp(1, normal.z, saturate(strength)));
}

float3 PositivePowColorSpace(float3 base, float3 power)
{
    return pow(max(abs(base), float3(FLT_EPSILON, FLT_EPSILON, FLT_EPSILON)), power);
}

float3 LinearToSRGB_float(float3 c)
{
#if UNITY_COLORSPACE_GAMMA
    return c;
#else
    float3 sRGBLo = c * 12.92;
    float3 sRGBHi = (PositivePowColorSpace(c, float3(1.0 / 2.4, 1.0 / 2.4, 1.0 / 2.4)) * 1.055) - 0.055;
    return (c <= 0.0031308) ? sRGBLo : sRGBHi;
#endif
}

SurfaceData PlateauTriplanarSubProcess(PlateauTriplanarInput input)
{
    SurfaceData sData = (SurfaceData) 0;
    
    // BaseColor
    float4 baseColor = TriplanarSample(input.mainTexture, input.positionWS, input.normalWS, input.titling, input.blend);
    baseColor = baseColor * float4(input.mainColor.xyz, input.opacity);
    
    // Normal
    float3 normal = TriplanarSampleNormal(input.normalMap, input.positionWS, input.normalWS, input.tangentWS, input.binormalWS, input.titling, input.blend).xyz;
    normal = NormalStrength(normal, input.normalStrength);
    
    // Metallic
    float metallic = TriplanarSample(input.metallicTexture, input.positionWS, input.normalWS, input.titling, input.blend).x;
    metallic = metallic * input.metallic;
    
    // Roughness
    float roughness = TriplanarSample(input.roughnessTexture, input.positionWS, input.normalWS, input.titling, input.blend).x;
    roughness = roughness * input.roughness;
    
    // Occlusion
    float occlusion = TriplanarSample(input.ambientOcclusionTexture, input.positionWS, input.normalWS, input.titling, input.blend).x;
    occlusion = occlusion * input.ambientOcclusion;
    
    // Emission
    float3 emission = TriplanarSample(input.emissionTexture, input.positionWS, input.normalWS, input.titling, input.blend).xyz;
    emission = emission * input.emissionColor.xyz;
    
    
    sData.albedo = LinearToSRGB_float(baseColor.xyz);
    sData.alpha = baseColor.w;
    sData.normalTS = normal;
    sData.metallic = metallic;
    sData.occlusion = occlusion;
    sData.smoothness = 1 - roughness;
    sData.emission = emission;
    
    return sData;
}

SurfaceData PlateauTriplanarCombineSideAndTop(SurfaceData side, SurfaceData top, float3 normalWS)
{
    float t = abs(dot(float3(0, 1, 0), normalWS));
    
    SurfaceData sData = (SurfaceData) 0;
    
    sData.albedo = lerp(side.albedo, top.albedo, t);
    sData.alpha = lerp(side.alpha, top.alpha, t);
    sData.normalTS = lerp(side.normalTS, top.normalTS, t);
    sData.metallic = lerp(side.metallic, top.metallic, t);
    sData.occlusion = lerp(side.occlusion, top.occlusion, t);
    sData.smoothness = lerp(side.smoothness, top.smoothness, t);
    sData.emission = lerp(side.emission, top.emission, t);
    
    return sData;
}

#endif