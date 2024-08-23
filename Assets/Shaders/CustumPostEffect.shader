Shader "Custom/CustumPostProcess"
{
    Properties 
    {
        [Toggle(SAMPLE_EFFECT_ENABLE)] _SampleEffectEnable("Sample Effect Enable", Float) = 1
        _RectSize           ("RectSize", int) = 0
        _EdgeDepthThreshold ("EdgeDepthThreshold", Float) = 0
        _EdgeColor          ("EdgeColor", Color) = (0,0,0,0)
        _EdgeFactor         ("EdgeFactor", Float) = 0
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

            float4x4 _ViewToWorld;
            float4 _BlitTexture_TexelSize;
            float4 _CameraDepthTexture_TexelSize;

            float   _SampleEffectEnable;
            int     _RectSize;
            float   _EdgeDepthThreshold;
            float4  _EdgeColor;
            float   _EdgeFactor;
            

            
            struct VS
            {
                uint vertexID : SV_VertexID;
            };
                                    
            struct PS
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
                                        
            PS vert(VS vin)
            {
                PS pout;
                                    
                pout.pos = GetFullScreenTriangleVertexPosition(vin.vertexID);
                pout.uv = GetFullScreenTriangleTexCoord(vin.vertexID);
                                    
                return pout;
            }

            float4 SampleEffect(PS pin)
            {
                /* GetNormal
                float3 normal = SampleSceneNormals(pin.uv);
                normal = mul((float3x3)_ViewToWorld, normal);
                */

                float depth = SampleSceneDepth(pin.uv);
                depth = Linear01Depth(depth, _ZBufferParams);
                

                const float2 uv =  pin.uv;
		        const float4 inputColor = SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, uv);

                float4 vOutputColor = inputColor;

                // Kuwahawa-Filter NxN
                // https://en.wikipedia.org/wiki/Kuwahara_filter
                {
                    #define MAX_RECT_SIZE           (18)
                    #define MAX_KERNEL_HALF_SIZE    (MAX_RECT_SIZE-1)
                    #define MAX_KERNEL_SIZE         (MAX_KERNEL_HALF_SIZE*2+1)
                    const int iRectSize         = clamp(_RectSize, 1, MAX_RECT_SIZE);
                    const int iKernelHalfSize   = iRectSize-1;
                    const int iKernelSize       = iKernelHalfSize*2+1;
                    if (iRectSize > 1)
                    {
                        float4 avColor[MAX_KERNEL_SIZE * MAX_KERNEL_SIZE];
                        {
                            for (int i = 0; i < iKernelSize; ++i)
                            {
                                for (int j = 0; j < iKernelSize; ++j)
                                {
                                    avColor[i * iKernelSize + j] = SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, uv + float2(i - iKernelHalfSize, j - iKernelHalfSize) * _BlitTexture_TexelSize.xy);
                                }
                            }
                        }
                        float4 vMaxVarianceColor = float4(1.e+38f, 1.e+38f, 1.e+38f, 0);
                        [unroll]
                        for (int k = 0; k < 4; ++k)
                        {
                            const int2 vRectOffset = int2(k % 2, k / 2) * iKernelHalfSize; // (0,0),(1,0),(0,1),(1,1)*iKernelHalfSize
                            float4 vMeanColor = float4(0, 0, 0, 0);
                            float4 vMeanColorSq = float4(0, 0, 0, 0);
                            for (int i = 0; i < iRectSize; ++i)
                            {
                                for (int j = 0; j < iRectSize; ++j)
                                {
                                    const float4 vColor = avColor[(vRectOffset.x + i) * iKernelSize + (vRectOffset.y + j)];
                                    vMeanColor += vColor;
                                    vMeanColorSq += vColor * vColor;
                                }
                            }
                            const float fSampleCount = float(iRectSize * iRectSize);
                            vMeanColor /= fSampleCount;
                            vMeanColorSq /= fSampleCount;
                            const float4 vVarianceColor = abs(vMeanColorSq - vMeanColor * vMeanColor);
                            if (vVarianceColor.r < vMaxVarianceColor.r) vOutputColor.r = vMeanColor.r;
                            if (vVarianceColor.g < vMaxVarianceColor.g) vOutputColor.g = vMeanColor.g;
                            if (vVarianceColor.b < vMaxVarianceColor.b) vOutputColor.b = vMeanColor.b;
                            vMaxVarianceColor = min(vMaxVarianceColor, vVarianceColor);
                        }
                    }
                }

                // Sobel Filter
                // https://blog.siliconstudio.co.jp/2021/05/960/
                {
                    float afLogViewZ[3][3];
                    {
                        for (int i = 0; i < 3; ++i)
                        {
                            for (int j = 0; j < 3; ++j)
                            {
                                const float depth = SampleSceneDepth(uv + float2(i - 1, j - 1) * _CameraDepthTexture_TexelSize.xy);
                                const float linearDepth = Linear01Depth(depth, _ZBufferParams);
                                const float viewZ = LinearEyeDepth(depth, _ZBufferParams);
                                afLogViewZ[i][j] = log2(viewZ);
                            }
                        }
                    }
                    const float fSobelX = afLogViewZ[0][0] + 2.0f * afLogViewZ[0][1] + afLogViewZ[0][2] - afLogViewZ[2][0] - 2.0f * afLogViewZ[2][1] - afLogViewZ[2][2];
                    const float fSobelY = afLogViewZ[0][0] + 2.0f * afLogViewZ[1][0] + afLogViewZ[2][0] - afLogViewZ[0][2] - 2.0f * afLogViewZ[1][2] - afLogViewZ[2][2];
                    const float fSobel = sqrt(fSobelX * fSobelX + fSobelY * fSobelY);
                    if (fSobel > _EdgeDepthThreshold)
                    {
                        vOutputColor.rgb = lerp(vOutputColor.rgb, _EdgeColor.rgb, _EdgeFactor);
                    }
                }
                return float4(vOutputColor.rgb, 1.0f);
            }
            
            float4 frag(PS pin) : SV_Target
            {
                #ifdef SAMPLE_EFFECT_ENABLE
                    return SampleEffect(pin);
                #else
                    return SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, pin.uv);
                #endif
            }
            ENDHLSL
        }

    }
}
