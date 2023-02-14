shader "Examples/SubShaderDetails"
{
    subshader
    {
        /**
         * 1 这里展示 subshader的 lod
            lod控制 subshader的执行, 通过Shader.maximumLOD控制
            lod需要从大到小排序.

        subshader执行的条件是:
            subshader lod < Shader.maximumLOD控制
        */
        lod 600 // Shader.maximumLOD <= 600, 

        /**
            subShader里的pass,没有指定Tags的话,drp会逐个执行, urp会执行2个.
        */
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            /**
                2 引入库之前,可以定义 宏(macro)来让预编译器
                    执行字符替换
                    编译不同的代码分支
            */
            #include "UnityCG.cginc"

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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return 1;
            }
            ENDCG
        }
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return 1;
            }
            ENDCG
        }
    }

}