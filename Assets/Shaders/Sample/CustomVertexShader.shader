Shader "Sample/CustomVertexShader"
{
    Properties
    {
        // Plateau inputs properties
	    _Side_MainTexture ("Side-MainTexture", 2D) = "white" {}
        _Side_NormalMap ("Side-NormalMap", 2D) = "NormalMap" {}
        _Side_NormalStrength ("Side-NormalStrength", Range (0, 2)) = 1
        _Side_Titling ("Side-Titling", Float) = 0.05
        _Side_Blend ("Side-Blend", Range (0.01, 30)) = 30
        _Side_Metallic ("Side-Metallic", Range (0, 1)) = 0
        _Side_MetallicTexture ("Side-MetallicTexture", 2D) = "white" {}
        _Side_RoughnessTexture ("Side-RoughnessTexture", 2D) = "white" {}
        _Side_Roughness ("Side-Roughness", Range (0, 1)) = 1
        _Side_AmbientOcclusionTex ("Side-AmbientOcclusionTex", 2D) = "white" {}
        _Side_AmbientOcclusion ("Side-AmbientOcclusion", Range (0, 1)) = 1
        _Side_EmissionTexture ("Side-EmissionTexture", 2D) = "white" {}
        _Side_EmissionColor ("Side-EmissionColor", Color) = (0,0,0,0)
        _Top_MainTexture ("Top-MainTexture", 2D) = "white" {}
        _Top_Titling ("Top-Titling", Float) = 0.05
        _Top_Blend ("Top-Blend", Range (0.01, 30)) = 30
        _Top_NormalMap ("Top-NormalMap", 2D) = "NormalMap" {}
        _Top_NormalStrength ("Top-NormalStrength", Range (0, 2)) = 1
        _Top_MetallicTexture ("Top-MetallicTexture", 2D) = "white" {}
        _Top_Metallic ("Top-Metallic", Range (0, 1)) = 0
        _Top_RoughnessTexture ("Top-RoughnessTexture", 2D) = "white" {}
        _Top_Roughness ("Top-Roughness", Range (0, 1)) = 1
        _Top_AmbientOcclusionTex ("Top-AmbientOcclusionTex", 2D) = "white" {}
        _Top_AmbientOcclusion ("Top-AmbientOcclusion", Range (0, 1)) = 1
        _Top_EmissionTexture ("Top-EmissionTexture", 2D) = "white" {}
        _Top_EmissionColor ("Top-EmissionColor", Color) = (0,0,0,0)
        _MainColor ("MainColor", Color) = (255,255,255,255)

        // Default inputs properties
        [MainTexture] _BaseMap ("Texture", 2D) = "white" {}
        [MainColor] _BaseColor ("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100


    
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma enable_d3d11_debug_symbols
            // make fog work
            #pragma multi_compile_fog

            // URP shadow keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "SampleLighting.hlsl"
            #include "CustomVertexShaderFunction.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS :  NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            //Plateau Input
            sampler2D _Side_MainTexture;
            sampler2D _Side_NormalMap;
            float _Side_NormalStrength;
            float _Side_Titling;
            float _Side_Blend;
            float _Side_Metallic;
            sampler2D _Side_MetallicTexture;
            sampler2D _Side_RoughnessTexture;
            float _Side_Roughness;
            sampler2D _Side_AmbientOcclusionTex;
            float _Side_AmbientOcclusion;
            sampler2D _Side_EmissionTexture;
            float4 _Side_EmissionColor;
            sampler2D _Top_MainTexture;
            float _Top_Titling;
            float _Top_Blend;
            sampler2D _Top_NormalMap;
            float _Top_NormalStrength;
            float _Top_Metallic;
            sampler2D _Top_MetallicTexture;
            sampler2D _Top_RoughnessTexture;
            float _Top_Roughness;
            sampler2D _Top_AmbientOcclusionTex;
            float _Top_AmbientOcclusion;
            sampler2D _Top_EmissionTexture;
            float4 _Top_EmissionColor;
            float4 _MainColor;

            //Default Inputs
            sampler2D _BaseMap;

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
            CBUFFER_END

            Varyings vert (Attributes input)
            {
                Varyings output;

                float3 vertexPos = CustomVertexShader(input.positionOS);

                VertexPositionInputs vertexData = GetVertexPositionInputs(vertexPos.xyz);
                VertexNormalInputs normalData = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.positionHCS = vertexData.positionCS;
                output.positionWS = TransformObjectToWorld(vertexPos.xyz);
                output.normalWS = normalData.normalWS.xyz;
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                float3 finalColor = SimpleLighting(input.positionWS, input.normalWS, _BaseColor);

                return float4(finalColor * 0.5,0.1);
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Off

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _GLOSSINESS_FROM_BASE_ALPHA

            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "CustomVertexShaderFunction.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
            CBUFFER_END


            float4 _ShadowBias; // x: depth bias, y: normal bias
            float3 _LightDirection;

            struct ShadowAttributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 texcoord     : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct ShadowVaryings
            {
                float2 uv           : TEXCOORD0;
                float4 positionCS   : SV_POSITION;
            };

            float4 GetShadowPositionHClip(ShadowAttributes input)
            {
                float3 vertexPos = CustomVertexShader(input.positionOS);

                float3 positionWS = TransformObjectToWorld(vertexPos.xyz);
                float3 normalWS = TransformObjectToWorldDir(input.normalOS);

                float invNdotL = 1.0 - saturate(dot(_LightDirection, normalWS));
                float scale = invNdotL * _ShadowBias.y;

                // normal bias is negative since we want to apply an inset normal offset
                positionWS = _LightDirection * _ShadowBias.xxx + positionWS;
                positionWS = normalWS * scale.xxx + positionWS;
                float4 positionCS = TransformWorldToHClip(positionWS);

            #if UNITY_REVERSED_Z
                positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
            #else
                positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
            #endif

                return positionCS;
            }

            ShadowVaryings ShadowPassVertex(ShadowAttributes input)
            {
                ShadowVaryings output;
                UNITY_SETUP_INSTANCE_ID(input);

                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionCS = GetShadowPositionHClip(input);
                return output;
            }

            half4 ShadowPassFragment(ShadowVaryings input) : SV_TARGET
            {
                return 0;
            }


            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask 0
            Cull Off

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _GLOSSINESS_FROM_BASE_ALPHA
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
            CBUFFER_END

            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode" = "DepthNormals" }

            ZWrite On
            Cull Off

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _GLOSSINESS_FROM_BASE_ALPHA
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "CustomVertexShaderFunction.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
            CBUFFER_END

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #if defined(LOD_FADE_CROSSFADE)
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

            #if defined(_ALPHATEST_ON) || defined(_NORMALMAP)
                #define REQUIRES_UV_INTERPOLATOR
            #endif

            struct DepthAttributes
            {
                float4 positionOS   : POSITION;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
                float3 normal       : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct DepthVaryings
            {
                float4 positionCS      : SV_POSITION;

                #if defined(REQUIRES_UV_INTERPOLATOR)
                    float2 uv          : TEXCOORD1;
                #endif

                #ifdef _NORMALMAP
                    half4 normalWS    : TEXCOORD2;    // xyz: normal, w: viewDir.x
                    half4 tangentWS   : TEXCOORD3;    // xyz: tangent, w: viewDir.y
                    half4 bitangentWS : TEXCOORD4;    // xyz: bitangent, w: viewDir.z
                #else
                    half3 normalWS    : TEXCOORD2;
                    half3 viewDir     : TEXCOORD3;
                #endif

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            DepthVaryings DepthNormalsVertex(DepthAttributes input)
            {
                float3 vertexPos = CustomVertexShader(input.positionOS);

                DepthVaryings output = (DepthVaryings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                #if defined(REQUIRES_UV_INTERPOLATOR)
                    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                #endif
                output.positionCS = TransformObjectToHClip(vertexPos.xyz);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(vertexPos.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal, input.tangentOS);

                #if defined(_NORMALMAP)
                    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
                    output.normalWS = half4(normalInput.normalWS, viewDirWS.x);
                    output.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
                    output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);
                #else
                    output.normalWS = half3(NormalizeNormalPerVertex(normalInput.normalWS));
                #endif

                return output;
            }

            void DepthNormalsFragment(
                DepthVaryings input
                , out half4 outNormalWS : SV_Target0
            #ifdef _WRITE_RENDERING_LAYERS
                , out float4 outRenderingLayers : SV_Target1
            #endif
            )
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                #if defined(_ALPHATEST_ON)
                    Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
                #endif

                #if defined(LOD_FADE_CROSSFADE)
                    LODFadeCrossFade(input.positionCS);
                #endif

                #if defined(_GBUFFER_NORMALS_OCT)
                    float3 normalWS = normalize(input.normalWS);
                    float2 octNormalWS = PackNormalOctQuadEncode(normalWS);           // values between [-1, +1], must use fp32 on some platforms
                    float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);   // values between [ 0,  1]
                    half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);      // values between [ 0,  1]
                    outNormalWS = half4(packedNormalWS, 0.0);
                #else
                    #if defined(_NORMALMAP)
                        half3 normalTS = SampleNormal(input.uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap));
                        half3 normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
                    #else
                        half3 normalWS = input.normalWS;
                    #endif

                    normalWS = NormalizeNormalPerPixel(normalWS);
                    outNormalWS = half4(normalWS, 0.0);
                #endif

                #ifdef _WRITE_RENDERING_LAYERS
                    uint renderingLayers = GetMeshRenderingLayer();
                    outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
                #endif
            }

            ENDHLSL
        }

        Pass
        {
            Name "Meta"
            Tags{ "LightMode" = "Meta" }

            Cull Off

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaSimple

            #pragma shader_feature EDITOR_VISUALIZATION
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _SPECGLOSSMAP

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
            CBUFFER_END

            float3 _EmissionColor = 0;

            #include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitMetaPass.hlsl"

            ENDHLSL
        }
    }
}
