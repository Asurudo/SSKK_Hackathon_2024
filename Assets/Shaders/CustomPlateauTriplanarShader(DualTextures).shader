Shader "Custom/CustomPlateauTriplanarShader(DualTextures)"
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
        [MainColor] _BaseColor ("Base Color", Color) = (1,1,1,1)
        _CircleCenter ("Circle Center Color", Vector) = (0, 0, 0, 0)
        _CircleSpreadSpeed ("Circle Spread Speed", Float) = 30
        _CircleTexFrequency ("Circle Texture Frequency", Float) = 4000
        _CircleTexColorRatio ("Circle Texture Color Ratio", Range(0, 1)) = 0.7
        _JellyEdge ("Jelly Edge", Float) = 100
        _JellyRefelectionColor ("Jelly Refelection Color",Color) = (1,1,1,1)
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

            // make fog work
            #pragma multi_compile_fog

            // URP shadow keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            #include "Sample/SampleLighting.hlsl"

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
                float4 position : TEXCOORD2;
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

            float4 _CircleCenter;
            float _CircleSpreadSpeed; 
            float _CircleTexFrequency;
            float _JellyEdge;
            float4 _JellyRefelectionColor;
            float _CircleTexColorRatio;

            //Default Inputs
            sampler2D _BaseMap;

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
            CBUFFER_END

            Varyings vert (Attributes input)
            {
                Varyings output;
                
                output.position = input.positionOS;

                // ビルが周期的に揺れる、グニグニ
                input.positionOS.x += sign(input.positionOS.x) * sin(_Time.w+input.positionOS.x)/1;
                input.positionOS.y += sign(input.positionOS.y) * cos(_Time.w+input.positionOS.y)/1;

                VertexPositionInputs vertexData = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalData = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.positionHCS = vertexData.positionCS;
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);

                output.normalWS =  normalData.normalWS.xyz;
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                // 基本的なライティング効果
                float3 finalColor = SimpleLighting(input.positionWS.xyz, input.normalWS.xyz, _BaseColor.xyz);

                // サークルの位置に基づく他の効果、例えば周期的な色合い
                float distanceFromCenter = -distance(input.position.xyz, _CircleCenter.xyz);
                float4 tintColor = tex2D(_BaseMap, frac(float2(_Time.w/_CircleSpreadSpeed + distanceFromCenter/_CircleTexFrequency, 
                                                               _Time.w/_CircleSpreadSpeed + distanceFromCenter/_CircleTexFrequency)));
                finalColor.rgb = lerp(finalColor.rgb, tintColor.rgb, _CircleTexColorRatio);

                // ゼリー効果の処理：視線角度に基づく色合いの変化
                float3 viewDir = normalize(_WorldSpaceCameraPos - input.positionWS);
                float fresnelEffect = pow(1.0 - saturate(dot(viewDir, input.normalWS)), _JellyEdge);
                float4 jellyColor = lerp(float4(finalColor, 1.0), _BaseColor, fresnelEffect);

                // ゼリー効果の処理：反射効果
                float3 reflection = reflect(viewDir, input.normalWS);
                float4 reflectionColor = _JellyRefelectionColor; 

                // ゼリー効果を色合いに適用
                finalColor = lerp(finalColor, jellyColor.rgb * reflectionColor.rgb, fresnelEffect);

                // 最終的な色を返す
                return float4(finalColor, 1.0);
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
