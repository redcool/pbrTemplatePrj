Shader "FX/Others/BoxScan"
{
    Properties
    {
        [GroupHeader(v0.0.4)]
        [Group(Base)]
        [GroupToggle(Base)]_FullScreenOn("_FullScreenOn",int) = 1

        [Group(Color)]
        [GroupHeader(Color,Edge Textures)]
        [GroupItem(Color)] _MainTex ("Texture 1", 2D) = "white" {}
        [GroupToggle(Color,,stop auto pan)]_MainTexOffsetStop("_MainTex OffsetStop",int) = 0

        [GroupItem(Color)] _MainTex2 ("Texture 2", 2D) = "white" {}
        [GroupToggle(Color,,stop auto pan)]_MainTex2OffsetStop("_MainTex2 OffsetStop",int) = 0

        [GroupHeader(Color,Edge Colors)]
        [GroupItem(Color)]  [hdr]_Color("_Color",color) = (1,0,0,0)
        [GroupItem(Color)]  [hdr]_Color2("_Color2",color) = (0,1,0,0)
        [GroupItem(Color)] _ColorScale("_ColorScale",range(1,100)) = 1

        [Group(Noise)]
        [GroupToggle(Noise,_NOISE_ON)]_NoiseOn("_NoiseOn",float) = 0
        [GroupItem(Noise)] _NoiseTex("_NoiseTex",2d) = "bump"{}
        [GroupToggle(Noise,,stop auto pan)]_NoiseTexOffsetStop("_NoiseTex OffsetStop",int) = 0
        [GroupItem(Noise)] _TextureNoiseScale("_TextureNoiseScale",float) = 0.2
        [GroupItem(Noise)] _BorderNoiseScale("_BorderNoiseScale",float) = 0.2
        
        [Group(Distance)]
        [GroupHeader(Distance,Base)]
        [GroupItem(Distance,sphere position)] _Center("_Center",vector) = (0,0,0,0)
        [GroupItem(Distance,sphere radius)] _Radius("_Radius",float) = 1

        [Group(Border)]
        [GroupHeader(Border,Border Range)]
        // distance and inner dist
        [GroupVectorSlider(Border, colorRange.x colorRange.y texRange.x texRange.y, 0_1 1_2 m1_1 m1_1,color range and texture range,field )]
        _Range("_Range",vector) = (0,1,1,5)

        [GroupHeader(Border,Border Inner Range)]
        [GroupToggle(Border,,control sphere inner distance)]_InnerDistanceOn("_InnerDistanceOn",float) = 0
        [GroupVectorSlider(Border, range.x range.y, 0_1 1_2,inner distance,field )] _InnerRange("_InnerRange",vector) = (-10,-3,0,0)

        [GroupHeader(Border,Options)]
        [GroupToggle(Border)]_ReverseTextureOn("_ReverseTextureOn",int) = 0
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
            #pragma shader_feature _NOISE_ON

            #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
            #include "../../../PowerShaderLib/Lib/PowerUtils.hlsl"
            #include "../../../PowerShaderLib/Lib/SDF.hlsl"
            #include "../../../PowerShaderLib/Lib/NoiseLib.hlsl"
            #include "../../../PowerShaderLib/Lib/MathLib.hlsl"
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
            sampler2D _CameraOpaqueTexture,_CameraColorTexture;
            sampler2D _CameraDepthTexture,_CameraDepthAttachment;

            CBUFFER_START(UnityPerMaterial)
            half _FullScreenOn;
            half4 _MainTex_ST,_MainTex2_ST,_NoiseTex_ST;
            half _MainTexOffsetStop,_MainTex2OffsetStop,_NoiseTexOffsetStop;
            half3 _Center;
            half _Radius;
            half4 _Range,_InnerRange;
            half4 _Color,_Color2;
            half _ColorScale;
            half _ReverseTextureOn;
            half _TextureNoiseScale,_BorderNoiseScale;
            half _InnerDistanceOn;
            CBUFFER_END

// #define _CameraDepthTexture _CameraDepthAttachment
#define _CameraOpaqueTexture _CameraColorTexture

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = _FullScreenOn ? float4(v.vertex.xy * 2,0,1) : TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                return o;
            }



            float4 frag (v2f i) : SV_Target
            {
                float2 screenUV = i.vertex.xy / _ScaledScreenParams.xy;

// float d = distance(screenUV ,0.5) - _Radius;
// d = abs(d);
// return smoothstep(_Range.x,_Range.y,d);
//============ world pos
                float depthTex = tex2D(_CameraDepthTexture,screenUV).x;
                half isFar = IsTooFar(depthTex.x);
                
                float3 worldPos = ScreenToWorldPos(screenUV,depthTex,UNITY_MATRIX_I_VP);
//============ Noise

                float borderNoise = 0,textureNoise = 0;
#if defined(_NOISE_ON)
                // half noise = N21(floor((worldPos.xz+worldPos.xy+worldPos.xz )))*2-1;
                // return noise;
                half2 noiseOffset = UVOffset(_NoiseTex_ST.zw, _NoiseTexOffsetStop);
                half4 borderNoiseTex = tex2D(_NoiseTex,(worldPos.xz)* _NoiseTex_ST.xy + noiseOffset);
                half noise = (borderNoiseTex.x*2-1);
                borderNoise =  noise * _BorderNoiseScale;
                textureNoise = noise * _TextureNoiseScale;
#endif

//============ Distances
                float dist,distSign,bandDist;
                float d = CalcWorldDistance(dist,distSign/**/,bandDist/**/,worldPos,_Center,_Radius+borderNoise,_Range.xy,_Range.zw);
                float d2 = _InnerDistanceOn ? (smoothstep(_InnerRange.x,_InnerRange.y,dist)) : 1;
// return d;
                // float d = distance(worldPos,_Center) - _Radius;
                // distSign = smoothstep(-1,1,(d));
                // d = 1 - abs(d);

                // d = smoothstep(_Range.x,_Range.y,d);
                // d = 1-d;
                // bandDist = smoothstep(0,0.2,saturate(d)); // color blending
                
//============Textures
                half3 tex = 1;
                half4 tex1 = tex2D(_MainTex,worldPos.xz * _MainTex_ST.xy + UVOffset(_MainTex_ST.zw,_MainTexOffsetStop)+textureNoise);
                half4 tex2 = tex2D(_MainTex2,worldPos.xz * _MainTex2_ST.xy + UVOffset(_MainTex2_ST.zw,_MainTex2OffsetStop)+textureNoise);
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
                texRate *= d2;
// return texRate;
                col.xyz = lerp(opaqueTex.xyz,tex.xyz,texRate) * color.xyz;
                return col;
            }
            ENDHLSL
        }
    }
}
