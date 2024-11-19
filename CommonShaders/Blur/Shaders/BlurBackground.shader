Shader "Unlit/Blur/BlurBackground"
{
    Properties
    {
        [GroupHeader(Blur For transform object)]
        _MainTex ("Texture", 2D) = "white" {}
        _Fade("_Fade",range(0,1)) = 0.5

        [Header(Blur Mode)]
        // [KeywordEnum(None,X3,X7)]
        [GroupEnum(,None _BOX_BLUR_X3 _GAUSS_X7,true)]
        _BlurMode("_BlurMode",int) = 0

        [Header(Blur Options)]
        _BlurScale("_BlurScale",range(0.5,5)) = 1

        _NoiseTex("_NoiseTex",2d) = "bump"{}
        _NormalScale("_NormalScale",float) = 1
    }
    SubShader
    {
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _BOX_BLUR_X3 _GAUSS_X7

            #include "../../../../PowerShaderLib/Lib/UnityLib.hlsl"
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
            sampler2D _CameraOpaqueTexture;
            sampler2D _NoiseTex;
CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float _Fade;

            float _BlurScale;

            float4 _CameraOpaqueTexture_TexelSize;

            float4 _NoiseTex_ST;
            float _NormalScale;
CBUFFER_END
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv,_NoiseTex);
                
                // #if UNITY_UV_STARTS_AT_TOP // urp dont use this.
                //     half sign = -1;
                // #else
                //     half sign = 1;
                // #endif

                o.screenPos.xy = (half2(o.vertex.x,o.vertex.y * 1) + o.vertex.w) * 0.5;
                o.screenPos.zw = o.vertex.zw;

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float2 noiseTex = 0;
                #if defined(_GAUSS_X7) || defined(_BOX_BLUR_X3)
                    noiseTex = tex2D(_NoiseTex,i.uv.zw).xy * _NormalScale;
                #endif

                half2 screenUV = i.screenPos.xy/i.screenPos.w;

                half4 col = 0;
                #if defined(_GAUSS_X7)
                    col.xyz += Gaussian7(_CameraOpaqueTexture,screenUV, _CameraOpaqueTexture_TexelSize.xy * (_BlurScale * half2(0,1) + noiseTex));
                    col.xyz += Gaussian7(_CameraOpaqueTexture,screenUV, _CameraOpaqueTexture_TexelSize.xy * (_BlurScale * half2(1,0) + noiseTex));
                    col *= 0.5;
                #elif defined(_BOX_BLUR_X3)
                    col.xyz += BoxBlur3(_CameraOpaqueTexture,screenUV, _CameraOpaqueTexture_TexelSize.xy * (_BlurScale * half2(0,1) + noiseTex));
                    col.xyz += BoxBlur3(_CameraOpaqueTexture,screenUV, _CameraOpaqueTexture_TexelSize.xy * (_BlurScale * half2(1,0) + noiseTex));
                    col *= 0.5;
                #else
                    col = tex2D(_CameraOpaqueTexture,screenUV);
                #endif

                // sample the texture
                half4 mainTex = tex2D(_MainTex,i.uv.xy);
                col = lerp(col,mainTex,_Fade);

                col.a = mainTex.a;
                return col;
            }
            ENDHLSL
        }
    }
}
