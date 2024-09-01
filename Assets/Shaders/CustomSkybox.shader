Shader "Custom/CustomPlateauSkybox"
{
    Properties 
    {
        _Tint ("Tint", Color) = (0.5, 0.5, 0.5, 0.5)
        _Exposure ("Exposure", Range(0, 8)) = 1.0
        _Mipmap ("Mipmap", Range(0, 10)) = 0.0
        _Rotation ("Rotation", Range(0, 360)) = 0
        _SkyCube ("SkyCube", Cube) = "Skybox" {}
    }
    SubShader 
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "Queue"="Background"
            "RenderType"="Background"
            "PreviewType"="Skybox"
        }

        Pass {
            Cull Off
            ZWrite Off

			HLSLPROGRAM
            #pragma target 2.0

            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			uniform half4 _Tint;
            uniform half _Exposure;
            uniform half _Mipmap;
            uniform float _Rotation;
			uniform half4 _SkyCube_HDR;
			
			TEXTURECUBE(_SkyCube);	    SAMPLER(sampler_SkyCube);

            // Y軸を中心に指定された角度（度）でvertexを回転させる関数
            float3 RotateAroundYInDegrees(float3 vertex, float degrees)
            {
                // 度をラジアンに変換
                float alpha = degrees * PI / 180.0;

                // sinとcosを計算
                float sina, cosa;
                sincos(alpha, sina, cosa);

                // 回転行列を作成
                float2x2 m = float2x2(cosa, -sina, sina, cosa);

                // XZ平面で回転を適用し、元のY座標を保持
                return float3(mul(m, vertex.xz), vertex.y).xzy;
            }

            // HDRデータをデコードするための関数
            // https://discussions.unity.com/t/how-to-sample-hdr-texture-in-shader/730747/3
            inline half3 DecodeHDR(half4 data, half4 decodeInstructions)
            {
                #if defined(UNITY_NO_LINEAR_COLORSPACE)
                    // リニアカラースペースでない場合、通常のデコードを使用
                    return (decodeInstructions.x * data.a) * data.rgb;
                #else
                    // リニアカラースペースの場合、指定されたデコード手順に従ってデコード
                    return (decodeInstructions.x * pow(abs(data.a), decodeInstructions.y)) * data.rgb;
                #endif
            }

			#ifdef UNITY_COLORSPACE_GAMMA
            #define unity_ColorSpaceDouble half4(2.0, 2.0, 2.0, 2.0)
            #else
            #define unity_ColorSpaceDouble half4(4.59479380, 4.59479380, 4.59479380, 2.0)
            #endif
			
            struct Attributes
			{
                float4 positionOS : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionHCS : SV_POSITION;
                float3 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes input)
            {
                Varyings output;

                // インスタンスIDを設定
                UNITY_SETUP_INSTANCE_ID(input);
    
                // インスタンスIDを転送
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                // Y軸を中心に指定された回転角度で位置を回転
                float3 rotated = RotateAroundYInDegrees(input.positionOS.xyz, _Rotation);

                // 回転後の位置をホモジニアス座標に変換
                output.positionHCS = TransformObjectToHClip(rotated);

                // UV座標を位置に設定
                output.uv = input.positionOS.xyz;

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                // インスタンスIDを設定
                UNITY_SETUP_INSTANCE_ID(input);

                // キューブマップから色をサンプル
                half4 var_SkyCube = SAMPLE_TEXTURECUBE_LOD(_SkyCube, sampler_SkyCube, input.uv, _Mipmap);

                // HDRデータをデコード
                half3 skyCube = DecodeHDR(var_SkyCube, _SkyCube_HDR);

                // 色をティントとカラースペースに基づいて調整
                skyCube = skyCube * _Tint.rgb * unity_ColorSpaceDouble.rgb;
                skyCube *= _Exposure;

                // 最終的な色を返す（アルファ値は1）
                return half4(skyCube, 1);
            }

            ENDHLSL
        }
    }
}
