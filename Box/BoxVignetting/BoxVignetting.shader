Shader "Hidden/FX/Others/BoxVignetting"
{
    Properties
    {
        [GroupHeader(v0.0.1)]
        [Group(Base)]
        [GroupToggle(Base)]_FullScreenOn("_FullScreenOn",int) = 1

        [Group(Vignette)]
        [GroupToggle(Vignette)]_RoundOn("_RoundOn",float) = 0
        [GroupItem(Vignette)]_Intensity("_Intensity",range(0,1)) = 1
        [GroupVectorSlider(Vignette,centerX centerY,0_1 0_1,position)] _Center("_Center",vector) = (0.5,0.5,0,0)
        [GroupVectorSlider(Vignette,min max,0_1 0_1,vignet range smooth )] _VignetRange("_VignetRange",vector) = (0.5,0.7,0,0)        
        [GroupVectorSlider(Vignette,min max,0_1 0_1,blink eye)] _Oval("_Oval",vector) = (1,1,0,0)

        [GroupItem(Vignette)] _Color1("_Color1",color) = (0,0,0,0)
        [GroupItem(Vignette)] _Color2("_Color2",color) = (0,0,0,1)

        //=================================
        [Group(Alpha)]
        [GroupHeader(Alpha,BlendMode)]
        [GroupPresetBlendMode(Alpha,,_SrcMode,_DstMode)]_PresetBlendMode("_PresetBlendMode",int)=1
        // [GroupEnum(Alpha,UnityEngine.Rendering.BlendMode)]
        [HideInInspector]_SrcMode("_SrcMode",int) = 1
        [HideInInspector]_DstMode("_DstMode",int) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        LOD 100
        zwrite off
        ztest always
        blend [_SrcMode][_DstMode]

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
            #include "../../../PowerShaderLib/Lib/PowerUtils.hlsl"
            #include "../../../PowerShaderLib/Lib/SDF.hlsl"
            #include "../../../PowerShaderLib/Lib/NoiseLib.hlsl"
            #include "../../../PowerShaderLib/Lib/MathLib.hlsl"
            #include "../../../PowerShaderLib/Lib/Colors.hlsl"
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

            sampler2D _MainTex;
            sampler2D _CameraColorTexture;
            sampler2D _CameraDepthTexture;

            CBUFFER_START(UnityPerMaterial)
            half _FullScreenOn;
            // half4 _MainTex_ST;

            half4 _Color1,_Color2;
            half2 _VignetRange;
            float2 _Center;
            half2 _Oval;
            half _RoundOn;
            half _Intensity;

            CBUFFER_END

            // #define _CameraDepthTexture _CameraDepthAttachment
            #define _CameraOpaqueTexture _CameraColorTexture

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = _FullScreenOn ? float4(v.vertex.xy * 2,UNITY_NEAR_CLIP_VALUE,1) : TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                return o;
            }


            float4 frag (v2f i) : SV_Target
            {
                float2 screenUV = i.vertex.xy / _ScaledScreenParams.xy;
                half4 col = CalcVignette(screenUV,_Center,_RoundOn,_Oval,_VignetRange,_Color1,_Color2,_Intensity);
                return col;
                
            }
            ENDHLSL
        }
    }
}
