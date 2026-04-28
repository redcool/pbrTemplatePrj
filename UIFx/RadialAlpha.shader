Shader "Unlit/RadialAlpha"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        _Progress ("Progress", Range(0, 1)) = 0.5

        [Header(Mask)]
        _MaskMap("_MaskMap(r)", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_BaseMap);
            TEXTURE2D(_MaskMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float _Progress;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;
                half mask = SAMPLE_TEXTURE2D(_MaskMap, sampler_BaseMap, IN.uv).r;
                color.a *= mask; // 将mask的alpha乘到颜色的alpha上
                
                float2 center = IN.uv *2 -1; // 将UV坐标转换为[-1, 1]范围
                float angle = atan2(center.x, center.y); // 计算角度,从下侧,顺时针为正,(交换xy,加负号,可以换方向)
                float normalizedAngle = (angle + 3.14159265) / (2 * 3.14159265); // 将角度归一化到[0, 1]范围
                color.a *= normalizedAngle > _Progress; // 设置alpha为0，使像素完全透明    
                return color;
            }
            ENDHLSL
        }
    }
}
