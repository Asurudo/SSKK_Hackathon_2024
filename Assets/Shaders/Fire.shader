Shader "URP/Fire" {
    Properties {
        _MainTex("Texture", 2D) = "white"{}

        [Header(Base)]
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc("BlendSrc", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendDst("BlendDst", Float) = 10
        [KeywordEnum(Base, Cartoon, Pixel)] _Style("Style", Int) = 0
        [HDR] _Color1("Color1", Color) = (0.77, 0.08, 0.11, 1)
        [HDR] _Color2("Color2", Color) = (1.2, 1.2, 0.6, 1)
        _Speed("Speed", Range(0, 1)) = 0.2
        _Scale("Scale", Range(0, 5)) = 1.5
        _VerticalBillboarding("Vertical Restraints", Range(0, 1)) = 1 

        [Header(Advance)]
        _RgbLerpOffset("RgbLerpOffset", Range(-1, 1)) = -0.3
        _RgbPow("RgbPow", Range(0, 2)) = 2
        _AlphaLerpOffset("AlphaLerpOffset", Range(-1, 1)) = 0.03
        _AlphaPow("AlphaPow", Range(0, 2)) = 1
        _Shape("Shape", Range(1, 30)) = 6
        _ChipPow("ChipPow", Range(0, 5)) = 1.7
        _ChipVal("ChipVal", Range(-2, 2)) = 0.1
        _ChipParam("ChipParam", Vector) = (20, -13, 46.5, 2)

        [Header(Cartoon Style)]
        [HDR] _CartoonLineColor("CartoonLineColor", Color) = (0, 0, 0, 0.4)
        _CartoonLineWidth("CartoonLineWidth", Range(0, 0.5)) = 0.3
        _CartoonColorLayer("CartoonColorLayer", Range(0, 5)) = 2
        _CartoonBlur("CartoonBlur", Range(0, 1)) = 0.6
        _CartoonAlphaPow("CartoonAlphaPow", Range(0.1, 1)) = 0.3

        [Header(Pixel Style)]
        _PixelSize("PixelSize", Int) = 64
        _PixelFps("PixelFps", Int) = 24
        _PixelColorLayer("PixelColorLayer", Range(0, 5)) = 2
        _PixelOffsetX("PixelOffsetX", Range(-1, 1)) = 0
        _PixelOffsetY("PixelOffsetY", Range(-1, 1)) = 0
    }
    SubShader {
        Tags {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Alphatest+50"
        }
        Cull Back
        ZWrite Off
        Blend [_BlendSrc] [_BlendDst]

        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature USE_CPU_TIME _STYLE_BASE _STYLE_CARTOON _STYLE_PIXEL
            #define PI 3.1415926535
            #define TAU (2 * PI)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color1;
            float4 _Color2;
            float _Speed;
            float _Scale;
            float _RgbLerpOffset;
            float _RgbPow;
            float _AlphaLerpOffset;
            float _AlphaPow;
            float _Shape;
            float _ChipPow;
            float _ChipVal;
            float4 _ChipParam;
            float4 _CartoonLineColor;
            float _CartoonLineWidth;
            float _CartoonColorLayer;
            float _CartoonBlur;
            float _CartoonAlphaPow;
            float _PixelSize;
            float _PixelFps;
            float _PixelColorLayer;
            float _PixelOffsetX;
            float _PixelOffsetY;
            float _VerticalBillboarding;

            Varyings vert(Attributes input) {
                Varyings output;

                float3 center = float3(0, 0, 0);
                float3 viewer = TransformWorldToObject(GetCameraPositionWS());

                float3 normalDir = normalize(viewer - center);

                normalDir.y = normalDir.y * _VerticalBillboarding;
                normalDir = normalize(normalDir);

                float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
                float3 rightDir = normalize(cross(upDir, normalDir));
                upDir = normalize(cross(normalDir, rightDir));

                float3 centerOffs = input.positionOS.xyz - center;
                float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;

                float4 worldPos = mul(unity_ObjectToWorld, float4(localPos, 1.0));

                worldPos.x += sign(worldPos.x) * sin(_Time.w+worldPos.x)/1;
                worldPos.y += sign(worldPos.y) * cos(_Time.w+worldPos.y)/1;

                output.positionHCS = mul(UNITY_MATRIX_VP, worldPos);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);

                return output;
            }

            float WaterDrop(float2 uv) {
                float x = 2 * uv.x - 1;
                float y = 2 - 2 * uv.y;
                return (x * x + y * y) * (x * x + y * y) - 2 * y * (x * x + y * y) + _Shape * x * x;
            }

            float Fire(float2 uv, float t) {
                float x = uv.x;
                float y = uv.y;
                float o = pow(y, _ChipPow) * _ChipVal * (sin(_ChipParam.x * y + _ChipParam.y * t) + sin(_ChipParam.z * x + _ChipParam.w * t));
                float a = max(0, 1 - WaterDrop(uv));
                return -WaterDrop(uv + float2(a * o, 0));
            }

            float4 frag(Varyings input) : SV_Target {
                // return float4(1,1,1,1);
                float t = _Time.y;
                float2 uv = 0;
            #if defined(_STYLE_PIXEL)
                float2 pixelOffset = float2(_PixelOffsetX, _PixelOffsetY);
                uv = ((floor(input.uv * _PixelSize + pixelOffset) - pixelOffset) / _PixelSize - 0.5) * _Scale + 0.5;
                t = floor(t * _PixelFps) / _PixelFps;
            #else
                uv = (input.uv - 0.5) * _Scale + 0.5;
            #endif

                t *= TAU * _Speed;
                float fire = Fire(uv, t);
                float rgbLerp = max(0, pow(fire + _RgbLerpOffset, _RgbPow) * sign(fire));
                float alphaLerp = saturate(pow(max(0, fire + _AlphaLerpOffset), _AlphaPow));

                float4 result = 0;
            #if defined(_STYLE_BASE)
                result = float4(lerp(_Color1, _Color2, rgbLerp).rgb, alphaLerp);
            #elif defined(_STYLE_CARTOON)
                rgbLerp = lerp(rgbLerp, floor(rgbLerp * _CartoonColorLayer) / _CartoonColorLayer, _CartoonBlur);
                float4 bg = float4(lerp(_Color1, _Color2, rgbLerp).rgb, alphaLerp > 0);
                float4 outLine = (alphaLerp > 0) * (alphaLerp < _CartoonLineWidth) * _CartoonLineColor;
                result = float4(lerp(bg.rgb, outLine.rgb, outLine.a), max(bg.a, outLine.a) * pow(saturate(1 - uv.y), _CartoonAlphaPow));
            #elif defined(_STYLE_PIXEL)
                rgbLerp = floor(rgbLerp * _PixelColorLayer) / _PixelColorLayer;
                result = float4(lerp(_Color1, _Color2, rgbLerp).rgb, alphaLerp > 0);
            #else
                result = float4(0, 0, 0, 0);
            #endif

                return result;
            }
            ENDHLSL
        }
    }
}
