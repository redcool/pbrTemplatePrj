Shader "Examples/SRPBatchAndInstanced"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
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
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID // use this to access instanced properties in the fragment shader.
            };

            /**
                2 这里展示,同时支持 srp batch 与instancing的写法

                渲染流程如下:
                if(srp batch on)
                {
                    draw srp batch objects
                    // if you wanna draw instanced object, need override UnityPerMaterial to another
                }
                else
                {
                    if(instancedOn)
                    {
                        draw instanced objects
                    }else{
                        draw objects one by one
                    }
                }
            */
            
            /**
                2.1 这里定义cbuffer,名字为UnityPerMaterial
            */
            // #define UnityPerMaterial Prop  //srpBatch开,想用instanced需要使用其他名
            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
            #define _Color UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Color)

            v2f vert(appdata v)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                return _Color;
            }
            ENDCG
        }
    }
}