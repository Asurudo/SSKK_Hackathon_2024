Shader "Bubble"
{
    Properties 
    {
        [Header(Base)][Space(6)]
        _BaseColor ("BaseColor", Color) = (1.0, 1.0, 1.0, 1.0)
    	_Hue ("Hue", Range(0.0, 1.0)) = 0.0
    	_ReflectIntensity ("ReflectIntensity", Range(0, 20)) = 2
    	_BubbleAlpha ("BubbleAlpha", Range(0,2)) = 1
        _FloatSpeed ("Float Speed", Float) = 1.0
        _FloatSize ("Float Size", Float) = 0.5
        
        [Header(FlowMap)][Space(6)]
        _FlowMap ("Flow Map", 2D) = "white" {}
        _TimeSpeed ("Time Speed", Float) = 1
        _FlowSpeed ("Flow Speed", Float) = 1 
        _FlowUVDir ("Flow UV Dir", Vector) = (0.5, 0.1, 0.0, 0.0)
        
        [Header(RampMap)][Space(6)]
        [NoScaleOffset] _RampMap ("Ramp Map",2D) = "white" {}
        _RampXAxisOffset ("Ramp X Axis Offset", Range(0, 1)) = 0.333
        _RampXAxisNoiseStrength("Ramp X Axis Noise Strength", Range(0, 1)) = 1.0
        
        [Header(Reflection)][Space(6)]

    	[Toggle] _UseNormalReflection ("UseNormalReflection", Float) = 1.0
    	[Toggle] _UseCustomReflection ("UseCustomReflection", Float) = 1.0
        [NoScaleOffset] _CubeMap ("CubeMap", Cube) = "_Skybox" {}
        _CubeMapLOD ("CubeMapLOD", Range(0.0, 10.0)) = 0.0
        _ReflectAmount ("ReflectAmount", Range(0,1)) = 0.5
        
        [Header(Normal)][Space(6)]
        _BumpScale("Normal Scale", Float) = 1.0
        [NoScaleOffset] _BumpMap("Normal Map", 2D) = "bump" {}
        
        [Header(Rim)][Space(6)]
    	[HDR] _RimColor ("Rim Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _RimPower("Rim Power", Float) = 4.0        

        [Header(Other)][Space(6)]
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 2
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
            Name "FORWARD"
            Tags {"LightMode" = "UniversalForward" } 

            Cull [_CullMode]
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            
			HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x	
            #pragma target 2.0

            #pragma multi_compile_instancing

			#pragma shader_feature _USENORMALREFLECTION_ON
			#pragma shader_feature _USECUSTOMREFLECTION_ON

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
			uniform float _Hue;
			uniform float4 _BaseColor;
			
			uniform float4 _FlowMap_ST;
			uniform float _TimeSpeed;
			uniform float _FlowSpeed;
			uniform float4 _FlowUVDir;
            uniform float _FloatSpeed;
            uniform float _FloatSize;

			uniform float _RampXAxisOffset;
			uniform float _RampXAxisNoiseStrength;

			uniform float _ReflectIntensity;
			uniform float _CubeMapLOD;
			uniform float _ReflectAmount;
			uniform float _BubbleAlpha;
			
			uniform float _BumpScale;
			uniform float4 _BumpMap_ST;
			
			uniform float4 _RimColor;
			uniform float _RimPower;
            CBUFFER_END
			
			TEXTURE2D(_FlowMap);	SAMPLER(sampler_FlowMap);
			TEXTURE2D(_RampMap);	SAMPLER(sampler_RampMap);
			TEXTURE2D(_BumpMap);	SAMPLER(sampler_BumpMap);
            TEXTURECUBE(_CubeMap);  SAMPLER(sampler_CubeMap);
			
			float3 Unity_Hue_Radians_float(float3 In, float Offset)
			{
			    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
			    float4 P = lerp(float4(In.bg, K.wz), float4(In.gb, K.xy), step(In.b, In.g));
			    float4 Q = lerp(float4(P.xyw, In.r), float4(In.r, P.yzx), step(P.x, In.r));
			    float D = Q.x - min(Q.w, Q.y);
			    float E = 1e-10;
			    float3 hsv = float3(abs(Q.z + (Q.w - Q.y)/(6.0 * D + E)), D / (Q.x + E), Q.x);

			    float hue = hsv.x + Offset;
			    hsv.x = (hue < 0)
			            ? hue + 1
			            : (hue > 1)
			                ? hue - 1
			                : hue;

			    float4 K2 = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
			    float3 P2 = abs(frac(hsv.xxx + K2.xyz) * 6.0 - K2.www);
			    return hsv.z * lerp(K2.xxx, saturate(P2 - K2.xxx), hsv.y);
			}
			
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

            float random(float x)
            {
                float y = frac(sin(x)*100000.0);
                return y;
            }

            Varyings vert (Attributes input)
			{
                Varyings output;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = positionInputs.positionCS;

                float time = _Time * _FloatSpeed;
                float offset = sin(time + output.positionCS.x * 0.5) * _FloatSize;
                float4 floatOffset = float4(0, offset, 0, 0);
                output.positionCS = output.positionCS + floatOffset;
                
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
                UNITY_SETUP_INSTANCE_ID(input);

                float2 flowUV  = (input.uv.zw + _Time.x * 0.1 * _FlowUVDir.xy) * _FlowMap_ST.xy + _FlowMap_ST.zw;
                float3 flowDir = SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, flowUV).xyz * 2 - 1;
                flowDir *= _FlowSpeed;

                float phase0 = frac(_Time.x * 0.1 * _TimeSpeed);
                float phase1 = frac(_Time.x * 0.1 * _TimeSpeed + 0.5);
				float flowlerp = abs((0.5 - phase0) / 0.5);

                float4 var_BumpMap0 = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, flowDir.xy * phase0);
                float4 var_BumpMap1 = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, flowDir.xy * phase1);
                float4 packedNormal = lerp(var_BumpMap0, var_BumpMap1, flowlerp);
                float3 normalTS = UnpackNormalScale(packedNormal, _BumpScale);

			    float3 bitangent = input.tangentWS.w * cross(input.normalWS.xyz, input.tangentWS.xyz);
                half3x3 TBN = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
				half3 normalWS = normalize(TransformTangentToWorld(normalTS, TBN));
				float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);
				
                float fresnel1 = saturate(dot(normalWS, viewDirWS));
                float fresnel2 = saturate(dot(normalize(input.normalWS), viewDirWS));
				float fresnel = pow(1.0 - fresnel2, _RimPower);

				float2 wave = lerp(flowDir.xy * phase0, flowDir.xy * phase1, flowlerp);
                float RampYAxis = saturate((fresnel1 - fresnel2 * 0.95) + 0.4 - wave.x * 0.8);
                float RampXAxis = _RampXAxisOffset + packedNormal.r * _RampXAxisNoiseStrength;
                float2 rampTexUV = float2(RampXAxis, RampYAxis);
                float3 rampColor = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, rampTexUV).rgb * _ReflectIntensity;
				
				#if _USENORMALREFLECTION_ON
					float3 reflectDirWS = reflect(-viewDirWS, input.normalWS);
				#else
					float3 reflectDirWS = reflect(-TransformWorldToView(input.positionWS), input.normalWS);
				#endif
				float3 negaReflectDirWS = float3(-reflectDirWS.x, -reflectDirWS.y, reflectDirWS.z);

				#if _USECUSTOMREFLECTION_ON
					float3 reflectCol1 = SAMPLE_TEXTURECUBE_LOD(_CubeMap, sampler_CubeMap, reflectDirWS, _CubeMapLOD).rgb * _ReflectAmount;
					float3 reflectCol2 = SAMPLE_TEXTURECUBE_LOD(_CubeMap, sampler_CubeMap, negaReflectDirWS, _CubeMapLOD).rgb * _ReflectAmount;
				#else
					float3 reflectCol1 = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDirWS, _CubeMapLOD).rgb * _ReflectAmount;
					float3 reflectCol2 = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, negaReflectDirWS, _CubeMapLOD).rgb * _ReflectAmount;
				#endif
                float3 reflectCol  = clamp(reflectCol1 + reflectCol2, 0.0, 2.0);

				float reflectLumin = abs(dot(reflectCol, float3(0.22,0.707,0.071)));		

                float3 finalRampCol = rampColor * (pow(reflectLumin, 1.5) + 0.05);
                finalRampCol = pow(abs(finalRampCol), 1.4);
				
                float3 finalCol = finalRampCol * _BaseColor.rgb + fresnel * _RimColor.rgb * _RimColor.a * finalRampCol * reflectLumin;
				finalCol = Unity_Hue_Radians_float(finalCol, _Hue);
				finalCol += reflectCol;
				
                float finalAlpha = _BubbleAlpha * (reflectLumin * 0.5 + 0.5) + fresnel * 0.2;
				
                float fogFactor = ComputeFogFactor(input.positionCS.z * input.positionCS.w);
                finalCol = MixFog(finalCol, fogFactor);
                
                return half4(finalCol, finalAlpha);
            } 
            ENDHLSL
        }
    }
}
