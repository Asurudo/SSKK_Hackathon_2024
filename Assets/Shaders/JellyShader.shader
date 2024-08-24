Shader "Custom/JellyShader"
{
    Properties 
    {
        _Color ("Color", Color) = (1,1,1,0.5)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}

    }
    SubShader 
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
        }

        Pass {
            Name "SKY_FORWARD"
            //Tags { "LightMode" = "UniversalForward" }
             
            Cull Off
            ZWrite Off

			HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x	
            #pragma target 2.0

            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			
            half _Glossiness;
		    half _Metallic;
		    float4 _Color;
            uniform float4 _MainTex_ST;

			TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
			
            struct Attributes
            {
                float4 position : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
            };


            Varyings vert (Attributes v)
			{
                v.position.x += sign(v.position.x) * sin(_Time.w+v.position.x)/10;
                v.position.y += sign(v.position.y) * cos(_Time.w+v.position.y)/10;

                Varyings o;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.position.xyz);
                o.position = positionInputs.positionCS;

                o.uv = v.uv;
                return o;
            }

            half4 frag(Varyings i) : SV_Target
			{
                half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                
                return c;
            } 
            ENDHLSL
        }
    }
}
