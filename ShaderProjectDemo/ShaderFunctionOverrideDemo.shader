Shader "Examples/ShaderFunctionOverrideDemo"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
    }

    CGINCLUDE
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
        float4 _Color;
    ENDCG

    SubShader
    {

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            
            #include "Lib/_DemoLib.hlsl"

            /**
                1 这里展示通过预编译器来做方法重载

                1.1 定义一个新方法
            */
            float4 CalcColorOverride(v2f i){
                return _Color * float4(1,0,0,1);
            }
            /**
                1.2 覆盖目标方法
                使用CalcColorOverride版本,注掉 使用原始版本
            */
            #define CalcColor CalcColorOverride

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            half4 frag (v2f i) : SV_Target
            {
                // 1.3 最终的CalcColor的版本靠预编译器确定
                return CalcColor(i);
            }
            ENDCG
        }
    }
}
