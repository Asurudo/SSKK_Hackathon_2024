Shader "Custom/CustomSiliconStudioFire" {
    Properties {
        _MainTex("Texture", 2D) = "white"{}

        // Jyoのメモ（中国語注意）https://asurudo.top/s/RKZsLKoPw#%E6%B7%B7%E5%90%88%E5%91%BD%E4%BB%A4
        // https://docs.unity3d.com/ScriptReference/Rendering.BlendMode.html
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc("BlendSrc", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendDst("BlendDst", Float) = 10
        [KeywordEnum(Base, Pixel)] _Style("Style", Int) = 0
        _Color1("Color1", Color) = (0.77, 0.08, 0.11, 1)
        _Color2("Color2", Color) = (1.2, 1.2, 0.6, 1)
        _Speed("Speed", Range(0, 1)) = 0.2
        _Scale("Scale", Range(0, 5)) = 1.5
        _VerticalBillboarding("Vertical Restraints", Range(0, 1)) = 1 

        _RgbLerpOffset("RgbLerpOffset", Range(-1, 1)) = -0.3
        _RgbPow("RgbPow", Range(0, 2)) = 2
        _AlphaLerpOffset("AlphaLerpOffset", Range(-1, 1)) = 0.03
        _AlphaPow("AlphaPow", Range(0, 2)) = 1
        _Shape("Shape", Range(1, 30)) = 6
        _ChipPow("ChipPow", Range(0, 5)) = 1.7
        _ChipVal("ChipVal", Range(-2, 2)) = 0.1
        _ChipParam("ChipParam", Vector) = (20, -13, 46.5, 2)

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
            #pragma shader_feature USE_CPU_TIME _STYLE_BASE _STYLE_PIXEL
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

            // ピクセルのサイズ
            float _PixelSize;
            float _PixelFps;
            // 内の炎のサイズ
            float _PixelColorLayer;
            float _PixelOffsetX;
            float _PixelOffsetY;

            float _VerticalBillboarding;

            // Billboard effect
            // https://www.youtube.com/watch?v=qGppGvgw7Dg
            // 火の炎が永遠にカメラに向かっているようにする
            Varyings vert(Attributes input) {
                Varyings output;

                // 中心点を原点 (0, 0, 0) として定義
                float3 center = float3(0, 0, 0);
                // カメラの位置をワールド空間からオブジェクト空間に変換
                float3 viewer = TransformWorldToObject(GetCameraPositionWS());

                // 中心点からカメラへの方向ベクトルを計算
                float3 normalDir = normalize(viewer - center);

                // 垂直ビルボード効果の適用（Y成分にスケールをかける）
                normalDir.y = normalDir.y * _VerticalBillboarding;
                normalDir = normalize(normalDir);

                // 上方向ベクトルを計算。Y成分がほぼ±1の場合、Z軸方向を使用
                float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
                // 右方向ベクトルを計算
                float3 rightDir = normalize(cross(upDir, normalDir));
                // 上方向ベクトルを再計算
                upDir = normalize(cross(normalDir, rightDir));

                // ローカル空間での位置を計算
                float3 centerOffs = input.positionOS.xyz - center;
                float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;

                // ワールド空間での位置を計算
                float4 worldPos = mul(unity_ObjectToWorld, float4(localPos, 1.0));

                // worldPos.x += sign(worldPos.x) * sin(_Time.w + worldPos.x) / 1;
                // worldPos.y += sign(worldPos.y) * cos(_Time.w + worldPos.y) / 1;

                // ホーム座標系に変換
                output.positionHCS = mul(UNITY_MATRIX_VP, worldPos);
                // UV座標を変換
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);

                return output;
            }

            // 数学公式で構築された炎、参考は以下になります
            // https://www.desmos.com/calculator/qu7ia1mniu?lang=ja
            // 炎の基本的な形、 W_0(x, y) = W(2x, 2-2y)
            // W(x^2+y^2)^2-2y(x^2+y^2)+(shape)*x^2
            float WaterDrop(float2 uv) {
                float x = 2 * uv.x - 1;
                float y = 2 - 2 * uv.y;
                return (x * x + y * y) * (x * x + y * y) - 2 * y * (x * x + y * y) + _Shape * x * x;
            }

            float Fire(float2 uv, float t) {
                float x = uv.x;
                float y = uv.y;
                // 時間のリズムに合わせて動くダイヤモンド、O = y^ChipPow * ChipVal * (sin(ChipParam.x * y + ChipParam.y * t) + sin(ChipParam.z * x + ChipParam.w * t))
                float o = pow(abs(y), _ChipPow) * _ChipVal * (sin(_ChipParam.x * y + _ChipParam.y * t) + sin(_ChipParam.z * x + _ChipParam.w * t));
                // 炎を特定の範囲内に制限します、A = max(0, 1-W_0)
                float a = max(0, 1 - WaterDrop(uv));
                // 炎の最終的な形、F = W_0(x+AO, y)
                return -WaterDrop(uv + float2(a * o, 0));
            }

            float4 frag(Varyings input) : SV_Target {
                float t = _Time.y;
                float2 uv = 0;

            #if defined(_STYLE_PIXEL)
                // 画素オフセットを定義します
                float2 pixelOffset = float2(_PixelOffsetX, _PixelOffsetY);
    
                // 画素オフセットに変わります
                uv = ((floor(input.uv * _PixelSize + pixelOffset) - pixelOffset) / _PixelSize - 0.5) * _Scale + 0.5;

                // 時間も離散化
                t = floor(t * _PixelFps) / _PixelFps;
            #else
                // ピクセルスタイルが定義されていない場合は、基本のUV座標スケーリングを適用します
                uv = (input.uv - 0.5) * _Scale + 0.5;
            #endif
                // 炎のスビート
                t *= TAU * _Speed;
                // 基本的な炎を手に入れます
                float fire = Fire(uv, t);
                // 色の補間
                float rgbLerp = max(0, pow(abs(fire + _RgbLerpOffset), _RgbPow) * sign(fire));
                float alphaLerp = saturate(pow(max(0, fire + _AlphaLerpOffset), _AlphaPow));

                float4 result = 0;
            #if defined(_STYLE_BASE)
                result = float4(lerp(_Color1, _Color2, rgbLerp).rgb, alphaLerp);

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
