Shader "Character/PlanarShadow_URP"
{
    Properties
    {
        [Header(Base Color)]
        [MainColor] _BaseColor("_BaseColor", Color) = (1,1,1,1)
        [MainTexture] _BaseMap("_BaseMap (albedo)", 2D) = "white" {}

        [Header(Alpha)]
	    [GroupToggle]_Clipping ("Alpha Clipping", Float) = 1
        _Cutoff("_Cutoff (Alpha Cutoff)", Range(0.0, 1.0)) = 0.5 // alpha clip threshold
        
        [Header(Shadow)]
        _HeightOffset("_HeightOffset", Float) = 0.5
        _ShadowColor("_ShadowColor", Color) = (0,0,0,1)
	    _ShadowDistanceAtten("_ShadowDistanceAtten", float) = 2

        // Blending state
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _Cull("__cull", Float) = 2.0
    }
    SubShader
    {       
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent"
        }
        LOD 300

        // ForwardLit pass
        // USEPASS "Universal Render Pipeline/Lit/ForwardLit"
        
        // Planar Shadows平面阴影
        Pass
        {
            Name "PlanarShadow"

            //用使用模板测试以保证alpha显示正确
            Stencil
            {
                Ref 0
                Comp equal
                Pass incrWrap
                Fail keep
                ZFail keep
            }

            Cull Off

            //透明混合模式
            Blend SrcAlpha OneMinusSrcAlpha

            //关闭深度写入
            ZWrite off

            //深度稍微偏移防止阴影与地面穿插
            Offset -1 , 0

            HLSLPROGRAM

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma vertex vert
            #pragma fragment frag
            
            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
            float _HeightOffset;
            float4 _ShadowColor;
            float _ShadowDistanceAtten;
            half4 _BaseColor;
            sampler2D _BaseMap;
            float4 _BaseMap_ST;
            float _Clipping;
            half _Cutoff;
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            float3 ShadowProjectPos(float4 vertPos)
            {
                float3 shadowPos;

                //得到顶点的世界空间坐标
                float3 worldPos = mul(unity_ObjectToWorld , vertPos).xyz;

                //灯光方向
                Light mainLight = GetMainLight();
                float3 lightDir = normalize(mainLight.direction);

                //阴影的世界空间坐标（低于地面的部分不做改变）
                float y = unity_ObjectToWorld._24 - _HeightOffset;
                shadowPos.y = min(worldPos .y , y);
                shadowPos.xz = worldPos .xz - lightDir.xz * max(0 , worldPos .y - y) / lightDir.y; 

                return shadowPos;
            }

            float GetAlpha (v2f i) {
                float alpha = _BaseColor.a;
                alpha *= tex2D(_BaseMap, i.uv.xy).a;
                return alpha;
            }

            v2f vert (appdata v)
            {
                v2f o;

                float3 shadowPos = ShadowProjectPos(v.vertex);
                o.vertex = TransformWorldToHClip(shadowPos);

                float3 shadowStartPos = unity_ObjectToWorld._14_24_34;
                shadowStartPos.y = _HeightOffset;

                float distAtten = _ShadowDistanceAtten/distance(shadowPos,shadowStartPos);


                o.color = _ShadowColor;
                o.color.a *= distAtten;
                
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float alpha = GetAlpha(i);
                i.color.a *= alpha;

                if (_Clipping)
                {
                    i.color.a *= step(_Cutoff, alpha);
                }
                return i.color;
            }
            ENDHLSL
        }
    }
}