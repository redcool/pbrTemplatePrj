Shader "Template/Unlit/Color_MRT"
{
    Properties
    {
        [Group(Main)]
        [GroupItem(Main)] _MainTex ("Texture", 2D) = "white" {}
        [GroupItem(Main)] _Color("_Color",color) = (1,1,1,1)

        [Group(Fog)]
        [GroupToggle(Fog)]_FogOn("_FogOn",int) = 1
        [GroupToggle(Fog,SIMPLE_FOG,use simple linear depth height fog)]_SimpleFog("_SimpleFog",int) = 0
        [GroupToggle(Fog)]_FogNoiseOn("_FogNoiseOn",int) = 0
        [GroupToggle(Fog)]_DepthFogOn("_DepthFogOn",int) = 1
        [GroupToggle(Fog)]_HeightFogOn("_HeightFogOn",int) = 1

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature SIMPLE_FOG

            #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
            #include "../../../PowerShaderLib/URPLib/URP_MotionVectors.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                DECLARE_MOTION_VS_INPUT(prevPos);
                float3 normal:NORMAL;
                float4 color:COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 worldPos:TEXCOORD1;
                float2 fogCoord:TEXCOORD2;
                // motion vectors
                DECLARE_MOTION_VS_OUTPUT(6,7);
                float4 color:COLOR;
                float4 normal:TEXCOORD3;
            };

            sampler2D _MainTex;
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _Color;
            half _FogOn,_FogNoiseOn,_DepthFogOn,_HeightFogOn;
            CBUFFER_END
            
            #include "../../../PowerShaderLib/Lib/FogLib.hlsl"


            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos.xyz = TransformObjectToWorld(v.vertex.xyz);
                o.fogCoord = CalcFogFactor(o.worldPos.xyz,o.vertex.z,_HeightFogOn,_DepthFogOn);
                o.color = v.color;
                o.normal.xyz = v.normal;

                CALC_MOTION_POSITIONS(v.prevPos,v.vertex,o,o.vertex);

                return o;
            }

            float4 frag (v2f i,out float4 outputNormal:SV_TARGET1,out float4 outputMotionVectors:SV_TARGET2) : SV_Target
            {
                // sample the texture
                float4 col = tex2D(_MainTex, i.uv) * _Color * i.color;
                float3 worldPos = i.worldPos.xyz;

                //-------- output mrt
                // output world normal
                outputNormal = half4(i.normal.xyz,0.5);
                // output motion
                outputMotionVectors = CALC_MOTION_VECTORS(i);

                BlendFogSphereKeyword(col.rgb/**/,worldPos,i.fogCoord.xy,_HeightFogOn,_FogNoiseOn,_DepthFogOn); // 2fps

                return col;
            }
            ENDHLSL
        }
    }
}
