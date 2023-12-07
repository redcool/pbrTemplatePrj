Shader "FX/Others/BoxScan"
{
    Properties
    {
        [GroupHeader(ScanLine v0.0.2)]

        [Group(Color)]
        [GroupHeader(Color,Edge Textures)]
        [GroupItem(Color)] _MainTex ("Inner Texture", 2D) = "white" {}
        [GroupItem(Color)] _MainTex2 ("outer Texture", 2D) = "white" {}

        [GroupHeader(Color,Edge Colors)]
        [GroupItem(Color)]  [hdr]_Color("_Color",color) = (1,0,0,0)
        [GroupItem(Color)]  [hdr]_Color2("_Color2",color) = (0,1,0,0)
        [GroupItem(Color)] _ColorScale("_ColorScale",range(1,100)) = 1

        [Group(Noise)]
        [GroupItem(Noise)] _NoiseTex("_NoiseTex",2d) = "bump"{}
        [GroupItem(Noise)] _NoiseScale("_NoiseScale",float) = 0.2

        [Group(Distance)]
        [GroupHeader(Distance,Base)]
        [GroupItem(Distance)] _Center("_Center",vector) = (0,0,0,0)
        [GroupItem(Distance)] _Radius("_Radius",float) = 1
        [GroupVectorSlider(Distance, Range.x range.y texRange.x texRange.y, 0_1 1_2 m1_1 m1_1,color range texture range,field )] _Range("_Range",vector) = (0,1,0,0)

        [GroupHeader(Distance,Options)]
        [GroupToggle(Distance)]_ReverseTextureOn("_ReverseTextureOn",int) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        LOD 100
        zwrite off
        ztest always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
            #include "../../../PowerShaderLib/Lib/PowerUtils.hlsl"
            #include "../../../PowerShaderLib/Lib/SDF.hlsl"
            #include "../../../PowerShaderLib/URPLib/URP_Input.hlsl"

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

            sampler2D _MainTex,_MainTex2,_NoiseTex;
            sampler2D _CameraOpaqueTexture,_CameraColorTexture,_CameraDepthTexture,_CameraDepthAttachment;

            CBUFFER_START(UnityPerMaterial)
            half4 _MainTex_ST,_MainTex2_ST;
            half3 _Center;
            half _Radius;
            half4 _Range;
            half4 _Color,_Color2;
            half _ColorScale;
            half _ReverseTextureOn;
            half _NoiseScale;
            CBUFFER_END

// #define _CameraDepthTexture _CameraDepthAttachment
#define _CameraOpaqueTexture _CameraColorTexture

            v2f vert (appdata v)
            {
                v2f o;
                // o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.vertex = float4(v.vertex.xy*2,0,1);
                o.uv = v.uv;
                return o;
            }



            float4 frag (v2f i) : SV_Target
            {
                float2 screenUV = i.vertex.xy / _ScaledScreenParams.xy;

// float d = distance(screenUV ,0.5) - _Radius;
// d = abs(d);
// return smoothstep(_Range.x,_Range.y,d);
//============ Noise                
                half4 borderNoiseTex = tex2D(_NoiseTex,screenUV);
                half borderNoise = (borderNoiseTex.x*2-1) * _NoiseScale;
//============ world pos
                float depthTex = tex2D(_CameraDepthTexture,screenUV).x;
                float3 worldPos = ScreenToWorldPos(screenUV,depthTex,UNITY_MATRIX_I_VP);
//============ Distances                
                float distSign,bandDist;
                float d = CalcWorldDistance(distSign/**/,bandDist/**/,worldPos,_Center,_Radius+borderNoise,_Range.xy,_Range.zw);
                // float d = distance(worldPos,_Center) - _Radius;
                // distSign = smoothstep(-1,1,(d));
                // d = abs(d);

                // d = smoothstep(_Range.x,_Range.y,d);
                // d = 1-d;
                // bandDist = smoothstep(0,0.2,saturate(d)); // color blending

//============Textures
                half3 tex = 1;
                half4 tex1 = tex2D(_MainTex,worldPos.xz * _MainTex_ST.xy + _MainTex_ST.zw);
                half4 tex2 = tex2D(_MainTex2,worldPos.xz * _MainTex2_ST.xy + _MainTex2_ST.zw);
                tex = tex1.xyz * tex2.xyz;
                
                // tex = lerp(tex1,tex2,distSign);
//============ colors
                half4 color = lerp(_Color,_Color2,d) * _ColorScale;
                color = lerp(1,color,bandDist);
//============ blends
                half4 opaqueTex = tex2D(_CameraOpaqueTexture,screenUV);
                // opaqueTex *= color;

                half4 col = 1;
                half texRate = _ReverseTextureOn ? 1 - distSign : distSign;

                col.xyz = lerp(opaqueTex.xyz,tex.xyz,texRate) * color.xyz;
                return col;
            }
            ENDHLSL
        }
    }
}
