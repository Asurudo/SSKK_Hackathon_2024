Shader "Sample/SamplePlateauTriplanarShader(DualTextures)"
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
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // make fog work
            #pragma multi_compile_fog

            // URP shadow keywords
            #pragma shader_feature_local _NORMALMAP

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            #include "PlateauTriplanarFunction.hlsl"

            struct Attributes
            {
                float4 positionOS           : POSITION;
                float3 normalOS             : NORMAL;
                float4 tangentOS            : TANGENT;
                float2 texcoord             : TEXCOORD0;
                float2 staticLightmapUV     : TEXCOORD1;
                float2 dynamicLightmapUV    : TEXCOORD2;
            };

            struct Varyings
            {
                float2 uv                       : TEXCOORD0;
                float3 positionWS               : TEXCOORD1;
                float3 normalWS                 : TEXCOORD2;
                float4 tangentWS                : TEXCOORD3;
                float3 viewDirWS                : TEXCOORD4;
                DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 5);
                float2  dynamicLightmapUV       : TEXCOORD6; // Dynamic lightmap UVs
                float  fogFactor                : TEXCOORD7;
                float4 positionCS               : SV_POSITION;
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
                Varyings output = (Varyings)0;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;

                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

                real sign = input.tangentOS.w * GetOddNegativeScale();
                half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);

                output.normalWS = normalInput.normalWS;
                output.tangentWS = tangentWS;
                output.viewDirWS = viewDirWS;

                output.positionWS = vertexInput.positionWS;

                output.positionCS = vertexInput.positionCS;


                // GI
                OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
                OUTPUT_SH( normalInput.normalWS.xyz, output.vertexSH );
                #ifdef DYNAMICLIGHTMAP_ON
                    output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
                #endif

                // Fog 
                half fogFactor = 0;
                #if !defined(_FOG_FRAGMENT)
                    fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
                #endif
                output.fogFactor = fogFactor;
                

                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                // Calc normal
                float3 normalWS = NormalizeNormalPerPixel(input.normalWS);
                float3 tangentWS = NormalizeNormalPerPixel(input.tangentWS.xyz);
                float3 binormalWS = normalize( cross( input.normalWS, input.tangentWS.xyz ) );

                // Side Process
                PlateauTriplanarInput sideInput;
                sideInput.mainTexture = _Side_MainTexture;
                sideInput.mainColor = _MainColor;
                sideInput.normalMap = _Side_NormalMap;
                sideInput.normalStrength = _Side_NormalStrength;
                sideInput.metallic = _Side_Metallic;
                sideInput.roughness = _Side_Roughness;
                sideInput.ambientOcclusionTexture = _Side_AmbientOcclusionTex;
                sideInput.ambientOcclusion = _Side_AmbientOcclusion;
                sideInput.opacity = 1;
                sideInput.titling = _Side_Titling;
                sideInput.blend = _Side_Blend;
                sideInput.emissionTexture = _Side_EmissionTexture;
                sideInput.emissionColor = _Side_EmissionColor;
                sideInput.roughnessTexture = _Side_RoughnessTexture;
                sideInput.metallicTexture = _Side_MetallicTexture;
                sideInput.positionWS = input.positionWS;
                sideInput.normalWS = normalWS;
                sideInput.tangentWS = tangentWS;
                sideInput.binormalWS = binormalWS;
                

                SurfaceData sideData = PlateauTriplanarSubProcess(sideInput);

                // Top Process
                PlateauTriplanarInput topInput;
                topInput.mainTexture = _Top_MainTexture;
                topInput.mainColor = _MainColor;
                topInput.normalMap = _Top_NormalMap;
                topInput.normalStrength = _Top_NormalStrength;
                topInput.metallic = _Top_Metallic;
                topInput.roughness = _Top_Roughness;
                topInput.ambientOcclusionTexture = _Top_AmbientOcclusionTex;
                topInput.ambientOcclusion = _Top_AmbientOcclusion;
                topInput.opacity = 1;
                topInput.titling = _Top_Titling;
                topInput.blend = _Top_Blend;
                topInput.emissionTexture = _Top_EmissionTexture;
                topInput.emissionColor = _Top_EmissionColor;
                topInput.roughnessTexture = _Top_RoughnessTexture;
                topInput.metallicTexture = _Top_MetallicTexture;
                topInput.positionWS = input.positionWS;
                topInput.normalWS = normalWS;
                topInput.tangentWS = tangentWS;
                topInput.binormalWS = binormalWS;

                SurfaceData topData = PlateauTriplanarSubProcess(topInput);

                SurfaceData sData = PlateauTriplanarCombineSideAndTop(sideData,topData,normalWS);

                // PBR InputData
                InputData inputData = (InputData)0;
                inputData.positionWS = input.positionWS;
                inputData.viewDirectionWS = SafeNormalize( input.viewDirWS );
                inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV( input.positionCS );

                // Normal map                
                float3x3 tangentSpace = float3x3( tangentWS, binormalWS, normalWS );
                float3 worldNormal = mul( sData.normalTS, tangentSpace );
                inputData.normalWS = worldNormal;

                // GI Bake
                #if defined(DYNAMICLIGHTMAP_ON)
                    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV, input.vertexSH, normalWS);
                    inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
                #else
                    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, normalWS);
                    inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
                #endif

                // Fog
                inputData.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactor);


                // Apply PBR Lighting
                float4 color = UniversalFragmentPBR( inputData, sData );

                color.rgb = MixFog(color.rgb, inputData.fogCoord);

                return color;
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

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
            CBUFFER_END

            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"

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

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
            CBUFFER_END

            #include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitDepthNormalsPass.hlsl"

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
