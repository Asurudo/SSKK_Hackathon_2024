Shader "Custom/CustomSiliconStudioFire" {
    Properties {
        _MainTex("Texture", 2D) = "white"{}

        // Jyo�̃����i�����꒍�Ӂjhttps://asurudo.top/s/RKZsLKoPw#%E6%B7%B7%E5%90%88%E5%91%BD%E4%BB%A4
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

            // �s�N�Z���̃T�C�Y
            float _PixelSize;
            float _PixelFps;
            // ���̉��̃T�C�Y
            float _PixelColorLayer;
            float _PixelOffsetX;
            float _PixelOffsetY;

            float _VerticalBillboarding;

            // Billboard effect
            // https://www.youtube.com/watch?v=qGppGvgw7Dg
            // �΂̉����i���ɃJ�����Ɍ������Ă���悤�ɂ���
            Varyings vert(Attributes input) {
                Varyings output;

                // ���S�_�����_ (0, 0, 0) �Ƃ��Ē�`
                float3 center = float3(0, 0, 0);
                // �J�����̈ʒu�����[���h��Ԃ���I�u�W�F�N�g��Ԃɕϊ�
                float3 viewer = TransformWorldToObject(GetCameraPositionWS());

                // ���S�_����J�����ւ̕����x�N�g�����v�Z
                float3 normalDir = normalize(viewer - center);

                // �����r���{�[�h���ʂ̓K�p�iY�����ɃX�P�[����������j
                normalDir.y = normalDir.y * _VerticalBillboarding;
                normalDir = normalize(normalDir);

                // ������x�N�g�����v�Z�BY�������قځ}1�̏ꍇ�AZ���������g�p
                float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
                // �E�����x�N�g�����v�Z
                float3 rightDir = normalize(cross(upDir, normalDir));
                // ������x�N�g�����Čv�Z
                upDir = normalize(cross(normalDir, rightDir));

                // ���[�J����Ԃł̈ʒu���v�Z
                float3 centerOffs = input.positionOS.xyz - center;
                float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;

                // ���[���h��Ԃł̈ʒu���v�Z
                float4 worldPos = mul(unity_ObjectToWorld, float4(localPos, 1.0));

                // worldPos.x += sign(worldPos.x) * sin(_Time.w + worldPos.x) / 1;
                // worldPos.y += sign(worldPos.y) * cos(_Time.w + worldPos.y) / 1;

                // �z�[�����W�n�ɕϊ�
                output.positionHCS = mul(UNITY_MATRIX_VP, worldPos);
                // UV���W��ϊ�
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);

                return output;
            }

            // ���w�����ō\�z���ꂽ���A�Q�l�͈ȉ��ɂȂ�܂�
            // https://www.desmos.com/calculator/qu7ia1mniu?lang=ja
            // ���̊�{�I�Ȍ`�A W_0(x, y) = W(2x, 2-2y)
            // W(x^2+y^2)^2-2y(x^2+y^2)+(shape)*x^2
            float WaterDrop(float2 uv) {
                float x = 2 * uv.x - 1;
                float y = 2 - 2 * uv.y;
                return (x * x + y * y) * (x * x + y * y) - 2 * y * (x * x + y * y) + _Shape * x * x;
            }

            float Fire(float2 uv, float t) {
                float x = uv.x;
                float y = uv.y;
                // ���Ԃ̃��Y���ɍ��킹�ē����_�C�������h�AO = y^ChipPow * ChipVal * (sin(ChipParam.x * y + ChipParam.y * t) + sin(ChipParam.z * x + ChipParam.w * t))
                float o = pow(abs(y), _ChipPow) * _ChipVal * (sin(_ChipParam.x * y + _ChipParam.y * t) + sin(_ChipParam.z * x + _ChipParam.w * t));
                // �������͈͓̔��ɐ������܂��AA = max(0, 1-W_0)
                float a = max(0, 1 - WaterDrop(uv));
                // ���̍ŏI�I�Ȍ`�AF = W_0(x+AO, y)
                return -WaterDrop(uv + float2(a * o, 0));
            }

            float4 frag(Varyings input) : SV_Target {
                float t = _Time.y;
                float2 uv = 0;

            #if defined(_STYLE_PIXEL)
                // ��f�I�t�Z�b�g���`���܂�
                float2 pixelOffset = float2(_PixelOffsetX, _PixelOffsetY);
    
                // ��f�I�t�Z�b�g�ɕς��܂�
                uv = ((floor(input.uv * _PixelSize + pixelOffset) - pixelOffset) / _PixelSize - 0.5) * _Scale + 0.5;

                // ���Ԃ����U��
                t = floor(t * _PixelFps) / _PixelFps;
            #else
                // �s�N�Z���X�^�C������`����Ă��Ȃ��ꍇ�́A��{��UV���W�X�P�[�����O��K�p���܂�
                uv = (input.uv - 0.5) * _Scale + 0.5;
            #endif
                // ���̃X�r�[�g
                t *= TAU * _Speed;
                // ��{�I�ȉ�����ɓ���܂�
                float fire = Fire(uv, t);
                // �F�̕��
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
