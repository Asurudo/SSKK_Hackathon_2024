Shader "Custom/CustumPostProcess"
{
    Properties 
    {
        [Toggle(SAMPLE_EFFECT_ENABLE)] _SampleEffectEnable("Sample Effect Enable", Float) = 1
        _FogDensity ("Fog Density", Float) = 0.01
        _FogColor ("Fog Color", Color) = (1, 1, 1, 1)
        _FogStart ("Fog Start", Float) = 0.0
        _FogEnd ("Fog End", Float) = 1.0
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _FogXSpeed ("Fog Horizontal Speed", Float) = 0.01
        _FogYSpeed ("Fog Vertical Speed", Float) = 0.01
        _NoiseAmount ("Noise Amount", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" 
                "RenderPipeline" = "UniversalPipeline" }

        LOD 100

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature SAMPLE_EFFECT_ENABLE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"   
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/lighting.hlsl"


            half _FogDensity;
            float4 _FogColor;
            float _FogStart;
            float _FogEnd;
            half _FogXSpeed;
            half _FogYSpeed;
            half _NoiseAmount;
            float4x4 _FrustumCornersRay;

            float4 _CameraOpaqueTexture_TexelSize;
            TEXTURE2D(_NoiseTex);
            SAMPLER(_CameraOpaqueTexture);
            SAMPLER(sampler_NoiseTex); 
           

            struct a2v
            {
               float4 vertex   : POSITION;
               float2 texcoord : TEXCOORD;
               uint vertexID : SV_VertexID;
            }; 

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uv_depth : TEXCOORD1;
                float4 interpolatedRay : TEXCOORD2;
            };
            
            v2f vert(a2v v) {
              v2f o;
              o.pos = GetFullScreenTriangleVertexPosition(v.vertexID);
              o.uv = GetFullScreenTriangleTexCoord(v.vertexID);
              o.uv_depth = GetFullScreenTriangleTexCoord(v.vertexID);

                #if UNITY_UV_STARTS_AT_TOP
                if (_CameraOpaqueTexture_TexelSize.y < 0)
                o.uv_depth.y = 1 - o.uv_depth.y;
                #endif
              int index = 0;
                if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5) {
                index = 0;
                } else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5) {
                index = 1;
                } else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5) {
                index = 2;
                } else {
                index = 3;
                }
              o.interpolatedRay = _FrustumCornersRay[index];
              return o;
            }

            float4 frag(v2f i) : SV_Target {

                float linearDepth = LinearEyeDepth(SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture,i.uv_depth).x,_ZBufferParams).x;

                float3 worldPos = _WorldSpaceCameraPos + linearDepth *  i.interpolatedRay.xyz;

                float2 speed = _Time.y *  float2(_FogXSpeed, _FogYSpeed);
                float noise = (SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex ,i.uv + speed).r - 0.5) *  _NoiseAmount;

                float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart); 

                fogDensity = saturate(fogDensity  * _FogDensity *  (1 + noise));

                float4 finalColor = tex2D(_CameraOpaqueTexture, i.uv);
                // float4 finalColor = float4(1.0, 1.0, 1.0, 1.0);
                finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);

                return finalColor;
            }
            ENDHLSL
        }

    }
}
