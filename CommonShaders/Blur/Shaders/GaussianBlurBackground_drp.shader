Shader "Unlit/Blur/Gaussian/BlurBackground_drp"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Fade("_Fade",range(0,1)) = 0.5

        [Header(Blur Mode)]
        [KeywordEnum(None,X3,X7)]_BlurMode("_BlurMode",int) = 0

        [Header(Blur Options)]
        _BlurScale("_BlurScale",range(0.5,5)) = 1

        _NormalMap("_NormalMap",2d) = "bump"{}
        _NormalScale("_NormalScale",float) = 1
    }
    SubShader
    {
        LOD 100

        GrabPass{"_CameraOpaqueTexture"}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _BLURMODE_X3 _BLURMODE_X7

            #include "UnityCG.cginc"
            #define USE_SAMPLER2D
            #include "../../../../PowerShaderLib/Lib/BlurLib.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 screenPos:TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Fade;

            float _BlurScale;

            sampler2D _CameraOpaqueTexture;
            float4 _CameraOpaqueTexture_TexelSize;

            sampler2D _NormalMap;
            float4 _NormalMap_ST;
            float _NormalScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv,_NormalMap);
                
                #if UNITY_UV_STARTS_AT_TOP // urp dont use this.
                    half sign = -1;
                #else
                    half sign = 1;
                #endif

                o.screenPos.xy = (half2(o.vertex.x,o.vertex.y * sign) + o.vertex.w) * 0.5;
                o.screenPos.zw = o.vertex.zw;

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                #if defined(_BLURMODE_X7) | defined(_BLURMODE_X3)
                    float2 bump = UnpackNormal(tex2D(_NormalMap,i.uv.zw)).xy * _NormalScale;
                #endif

                half2 screenUV = i.screenPos.xy/i.screenPos.w;

                half4 col = 0;
                #if defined(_BLURMODE_X7)
                    col.xyz += Gaussian7(_CameraOpaqueTexture,screenUV, _CameraOpaqueTexture_TexelSize.xy * (_BlurScale * half2(0,1) + bump));
                    col.xyz += Gaussian7(_CameraOpaqueTexture,screenUV, _CameraOpaqueTexture_TexelSize.xy * (_BlurScale * half2(1,0) + bump));
                    col *= 0.5;
                #elif defined(_BLURMODE_X3)
                    col.xyz += BoxBlur(_CameraOpaqueTexture,screenUV, _CameraOpaqueTexture_TexelSize.xy * (_BlurScale * half2(0,1) + bump));
                    col.xyz += BoxBlur(_CameraOpaqueTexture,screenUV, _CameraOpaqueTexture_TexelSize.xy * (_BlurScale * half2(1,0) + bump));
                    col *= 0.5;
                #else
                    col = tex2D(_CameraOpaqueTexture,screenUV);
                #endif

                // sample the texture
                half4 mainTex = tex2D(_MainTex,i.uv);
                col = lerp(col,mainTex,_Fade);

                col.a = mainTex.a;
                return col;
            }
            ENDCG
        }
    }
}
