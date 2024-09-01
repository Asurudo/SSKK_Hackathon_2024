Shader "Custom/CustomBubble"
{
    Properties 
    {
        _BaseColor ("BaseColor", Color) = (1.0, 1.0, 1.0, 1.0)
    	_ReflectIntensity ("ReflectIntensity", Range(0, 20)) = 2
    	_BubbleAlpha ("BubbleAlpha", Range(0,2)) = 1
        _FloatSpeed ("Float Speed", Float) = 1.0
        _FloatSize ("Float Size", Float) = 0.5
        
        _FlowMap ("Flow Map", 2D) = "white" {}
        _TimeSpeed ("Time Speed", Float) = 1
        _FlowSpeed ("Flow Speed", Float) = 1 
        
        _RampMap ("Ramp Map",2D) = "white" {}
        _RampXAxisOffset ("Ramp X Axis Offset", Range(0, 1)) = 0.333
        _RampXAxisNoiseStrength("Ramp X Axis Noise Strength", Range(0, 1)) = 1.0
        
        _CubeMap ("CubeMap", Cube) = "_Skybox" {}
        _ReflectAmount ("ReflectAmount", Range(0,1)) = 0.5
        
        _BumpMap("Normal Map", 2D) = "bump" {}
        
    	_RimColor ("Rim Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _RimPower("Rim Power", Float) = 4.0        

    }
    SubShader 
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Alphatest+50"
        }

        Pass {
            Tags {"LightMode" = "UniversalForward" } 

            Cull Off
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            
			HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			uniform float4 _BaseColor;
			
			uniform float4 _FlowMap_ST;
			uniform float _TimeSpeed;
			uniform float _FlowSpeed;
            uniform float _FloatSpeed;
            uniform float _FloatSize;

			uniform float _RampXAxisOffset;
			uniform float _RampXAxisNoiseStrength;

			uniform float _ReflectIntensity;
			uniform float _ReflectAmount;
			uniform float _BubbleAlpha;
			
			uniform float4 _BumpMap_ST;
			
			uniform float4 _RimColor;
			uniform float _RimPower;
			
			TEXTURE2D(_FlowMap);	SAMPLER(sampler_FlowMap);
			TEXTURE2D(_RampMap);	SAMPLER(sampler_RampMap);
			TEXTURE2D(_BumpMap);	SAMPLER(sampler_BumpMap);
            TEXTURECUBE(_CubeMap);  SAMPLER(sampler_CubeMap);
			
            struct Attributes
			{
                float4 positionOS : POSITION;
            	float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
            	float3 normalWS : TEXCOORD1;
            	float4 tangentWS : TEXCOORD2;
            	float fogFactor: TEXCOORD3;
            	float4 uv : TEXCOORD4;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            // 擬似乱数生成関数
            // https://thebookofshaders.com/10/
            float random(float x)
            {
                float y = frac(sin(x)*100000.0);
                return y;
            }

            Varyings vert (Attributes input)
			{
                Varyings output;

                // 全部バブルが同じように描く
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = positionInputs.positionCS;

                // ゆらゆら
                float time = _Time.y * _FloatSpeed;
                float offset = sin(time + output.positionCS.x * 0.5) * _FloatSize;
                float4 floatOffset = float4(0, offset, 0, 0);
                output.positionCS = output.positionCS + floatOffset;
                
                // TODO：バブルの位置変換
                // float upwardOffset = _Time.y * 1;
                // output.positionCS.y -= upwardOffset;
                // if(output.positionCS.y >= 30)
                //     output.positionCS.y -= 30;

                // float bubbleID = dot(floor(output.positionCS.xy), float2(12.9898, 78.233));

                // float randomValueX = random(float3(bubbleID, 0.0, 0.0));
                // float randomValueZ = random(float3(0.0, bubbleID, 0.0));
                 
                // output.positionCS.x += (0.01 * (randomValueX - 0.5)) * deltaTime;
                // output.positionCS.z += (0.01 * (randomValueZ - 0.5)) * deltaTime;

                output.positionWS = positionInputs.positionWS;
            	
            	VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS = normalInputs.normalWS;
                output.tangentWS = half4(normalInputs.tangentWS.xyz, input.tangentOS.w * GetOddNegativeScale());
            	
            	output.fogFactor = ComputeFogFactor(input.positionOS.z);
            	
                output.uv.xy = TRANSFORM_TEX(input.texcoord, _BumpMap);
                output.uv.zw = input.texcoord;

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                // 全てのバブルが同じように描画されるように、インスタンスIDを設定
                UNITY_SETUP_INSTANCE_ID(input);

                // 流れるUVの計算
                float2 flowUV  = (input.uv.zw + _Time.y * 0.1) * _FlowMap_ST.xy + _FlowMap_ST.zw;
                // フロー方向をサンプリングして調整
                float3 flowDir = SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, flowUV).xyz * 2 - 1;
                flowDir *= _FlowSpeed;

                // 時間に基づいたフェーズ計算
                float phase0 = frac(_Time.y * 0.1 * _TimeSpeed);
                float phase1 = frac(_Time.y * 0.1 * _TimeSpeed + 0.5);
                // フローの補間係数計算
                float flowlerp = abs((0.5 - phase0) / 0.5);

                // バンプマップから法線をサンプリングし、補間
                float4 var_BumpMap0 = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, flowDir.xy * phase0);
                float4 var_BumpMap1 = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, flowDir.xy * phase1);
                float4 packedNormal = lerp(var_BumpMap0, var_BumpMap1, flowlerp);

                // ビタンジェントとTBN行列の計算
                float3 bitangent = input.tangentWS.w * cross(input.normalWS.xyz, input.tangentWS.xyz);
                half3x3 TBN = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
                // ワールド空間の法線とビュー方向の計算
                half3 normalWS = normalize(TransformTangentToWorld(packedNormal, TBN));
                float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);
    
                // フレネル係数の計算，RIM関連
                float fresnel1 = saturate(dot(normalWS, viewDirWS));
                float fresnel2 = saturate(dot(normalize(input.normalWS), viewDirWS));
                float fresnel = pow(1.0 - fresnel2, _RimPower);

                // 波のテクスチャUV計算
                float2 wave = lerp(flowDir.xy * phase0, flowDir.xy * phase1, flowlerp);
                
                // ランプのY軸とX軸の計算
                float RampYAxis = saturate((fresnel1 - fresnel2 * 0.95) + 0.4 - wave.x * 0.8);
                float RampXAxis = _RampXAxisOffset + packedNormal.r * _RampXAxisNoiseStrength;
                float2 rampTexUV = float2(RampXAxis, RampYAxis);
                // ランプマップから色をサンプリング
                float3 rampColor = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, rampTexUV).rgb * _ReflectIntensity;
    
                // 反射方向の計算
                float3 reflectDirWS = reflect(-viewDirWS, input.normalWS);
                float3 negaReflectDirWS = float3(-reflectDirWS.x, -reflectDirWS.y, reflectDirWS.z);
                
                // 反射カラーのサンプリング、上下
                float3 reflectCol1 = SAMPLE_TEXTURECUBE_LOD(_CubeMap, sampler_CubeMap, reflectDirWS, 1).rgb * _ReflectAmount;
                float3 reflectCol2 = SAMPLE_TEXTURECUBE_LOD(_CubeMap, sampler_CubeMap, negaReflectDirWS, 1).rgb * _ReflectAmount;
                float3 reflectCol  = clamp(reflectCol1 + reflectCol2, 0.0, 2.0);

                // 反射カラーの輝度計算
                // float3(0.2235, 0.7725, 0.7333)=#39C5BB、Hatsune Mikuの色です、0.39は零点ミク
                // 特に意味はない、ただミクさんに含めたい~~
                float reflectLumin = abs(dot(reflectCol, float3(0.2235, 0.7725, 0.7333)*0.39));        

                // 最終的な色の計算
                float3 finalRampCol = rampColor * (pow(reflectLumin, 4) + 0.05);
                finalRampCol = pow(abs(finalRampCol), 1.4);
                float3 finalCol = finalRampCol * _BaseColor.rgb + fresnel * _RimColor.rgb * _RimColor.a * finalRampCol * reflectLumin;
                finalCol += reflectCol * 0.8;

                // 最終的なアルファ値の計算
                float finalAlpha = _BubbleAlpha * (reflectLumin * 0.5 + 0.5) + fresnel * 0.2;

                // フォグファクターの計算と適用
                float fogFactor = ComputeFogFactor(input.positionCS.z * input.positionCS.w);
                finalCol = MixFog(finalCol, fogFactor);
    
                // 最終的なカラーとアルファを返す
                return half4(finalCol, finalAlpha);
            }

            ENDHLSL
        }
    }
}
