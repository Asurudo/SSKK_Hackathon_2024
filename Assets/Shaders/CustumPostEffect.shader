Shader "Custom/CustumPostProcess"
{
    Properties 
    {
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

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
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

            SAMPLER(_CameraOpaqueTexture);
            float4 _CameraOpaqueTexture_TexelSize;
            float4x4 _FrustumCornersRay;

            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex); 
           
            struct Attributes
            {
               float4 vertex   : POSITION;
               float2 texcoord : TEXCOORD;
               uint vertexID : SV_VertexID;
            }; 

            struct Varyings {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 interpolatedRay : TEXCOORD1;
            };
            
            Varyings vert(Attributes v) {
              Varyings o;
              o.pos = GetFullScreenTriangleVertexPosition(v.vertexID);
              o.uv = GetFullScreenTriangleTexCoord(v.vertexID);

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

            float4 frag(Varyings i) : SV_Target {

                float linearDepth = LinearEyeDepth(SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture,i.uv).x,_ZBufferParams).x;
                float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;

                float2 speed = _Time.y *  float2(_FogXSpeed, _FogYSpeed);
                float noise = (SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv + speed).r - 0.5) *  _NoiseAmount;

                float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart); 
                fogDensity = saturate(fogDensity  * _FogDensity *  (1 + noise)) * 0.5;

                float4 finalColor = tex2D(_CameraOpaqueTexture, i.uv);
                finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);

                return finalColor;
            }
            ENDHLSL
        }

    }
}
