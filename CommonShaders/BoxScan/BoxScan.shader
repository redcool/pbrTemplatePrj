Shader "FX/Others/BoxScan"
{
    Properties
    {
        [GroupHeader(ScanLine v0.0.1)]
        _MainTex ("Inner Texture", 2D) = "white" {}
        _MainTex2 ("Texture2", 2D) = "white" {}

        [GroupHeader(Edge Color)]
        [hdr]_Color("_Color",color) = (1,0,0,0)
        [hdr]_Color2("_Color2",color) = (0,1,0,0)
        _ColorScale("_ColorScale",range(1,100)) = 1

        [GroupHeader(Distance)]
        _Center("_Center",vector) = (0,0,0,0)
        _Radius("_Radius",float) = 1
        [GroupVectorSlider(_, Range.x range.y texRange.x texRange.y, 0_1 1_2 m1_1 m1_1,,field )] _Range("_Range",vector) = (0,1,0,0)

        [GroupHeader(Options)]
        [GroupToggle]_ReverseTextureOn("_ReverseTextureOn",int) = 0
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

            sampler2D _MainTex,_MainTex2;
            sampler2D _CameraOpaqueTexture,_CameraColorTexture,_CameraDepthTexture,_CameraDepthAttachment;

            CBUFFER_START(UnityPerMaterial)
            half4 _MainTex_ST,_MainTex2_ST;
            half3 _Center;
            half _Radius;
            half4 _Range;
            half4 _Color,_Color2;
            half _ColorScale;
            half _ReverseTextureOn;
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

            float CalcWorldDistance(out float distSign,out float bandDist,float3 worldPos,float3 center,float radius,float2 distRange,float2 distSignRange=float2(-1,1)){
                float d = distance(worldPos,center) - radius;
                distSign = smoothstep(distSignRange.x,distSignRange.y,(d));
                d = abs(d);

                d = smoothstep(distRange.x,distRange.y,d);
                d = 1-d;
                bandDist = smoothstep(0,0.2,saturate(d)); // color blending
                return d;
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 screenUV = i.vertex.xy / _ScaledScreenParams.xy;

// float d = distance(screenUV ,0.5) - _Radius;
// d = abs(d);
// return smoothstep(_Range.x,_Range.y,d);


                float depthTex = tex2D(_CameraDepthTexture,screenUV).x;
                float3 worldPos = ScreenToWorldPos(screenUV,depthTex,UNITY_MATRIX_I_VP);
//============ Distances                
                float distSign,bandDist;
                float d = CalcWorldDistance(distSign/**/,bandDist/**/,worldPos,_Center,_Radius,_Range.xy,_Range.zw);

                // float d = distance(worldPos,_Center) - _Radius;
                // distSign = smoothstep(-1,1,(d));
                // d = abs(d);

                // d = smoothstep(_Range.x,_Range.y,d);
                // d = 1-d;
                // bandDist = smoothstep(0,0.2,saturate(d)); // color blending
// return d;
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
