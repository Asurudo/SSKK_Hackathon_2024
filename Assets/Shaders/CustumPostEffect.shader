Shader "Custom/CustumPostProcess"
{
    Properties 
    {
        _FogDensity ("Fog Density", Float) = 0.01
        _FogEffect ("Fog Effect", Range(0, 2)) = 0.5
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
            half _FogEffect;
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

                // フルスクリーントライアングルの頂点位置を取得
                o.pos = GetFullScreenTriangleVertexPosition(v.vertexID);
 
                // フルスクリーントライアングルのテクスチャ座標を取得
                o.uv = GetFullScreenTriangleTexCoord(v.vertexID);

                // 入力テクスチャ座標に基づいて視錐体の角のインデックスを決定
                int index = 0;
                if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5) {
                  // 左下角 
                  index = 0;
                } else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5) { 
                  // 右下角
                  index = 1;
                } else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5) {
                  // 右上角
                  index = 2;
                } else {
                  // 左上角
                  index = 3;
                }

                // 視錐体の角の光線方向をフラグメントシェーダーに渡す
                o.interpolatedRay = _FrustumCornersRay[index];
                return o;
                } 


           float4 frag(Varyings i) : SV_Target {

            // カメラ深度テクスチャから深度値を取得し、線形深度に変換
            float linearDepth = LinearEyeDepth(SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv).x, _ZBufferParams).x;
    
            // ワールド空間での位置を計算
            float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;

            // ノイズテクスチャのサンプリングと速度に基づくノイズの適用
            float2 speed = _Time.y * float2(_FogXSpeed, _FogYSpeed);
            float noise = (SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv + speed).r - 0.5) * _NoiseAmount;

            // フォグの密度を計算
            float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart); 
            fogDensity = saturate(fogDensity * _FogDensity * (1 + noise)) * _FogEffect;

            // カメラの不透明テクスチャから最終色を取得
            float4 finalColor = tex2D(_CameraOpaqueTexture, i.uv);
    
            // フォグの色で最終色を補正
            finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);

            return finalColor;
        }

            ENDHLSL
        }

    }
}
