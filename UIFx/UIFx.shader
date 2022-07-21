Shader "Unlit/UIFx"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Min("_Min",range(0,1)) = 0
        _Max("_Max",range(0,1)) = .1
    }
    SubShader
    {
        Tags {"Queue"="Transparent"}
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "../../PowerShaderLib/Lib/UnityLib.hlsl"
            #include "UIFxCore.hlsl"

            float _Min,_Max;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float sdfRect = SDFRect(i.uv,float2(_Max,_Min));
                
                // sample the texture
                half4 col = tex2D(_MainTex, i.uv);
                col.xyz *= sdfRect;
                
                return col;
            }
            ENDHLSL
        }
    }
}
