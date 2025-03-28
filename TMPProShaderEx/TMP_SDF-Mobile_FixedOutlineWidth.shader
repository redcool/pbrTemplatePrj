// Simplified SDF shader:
// - No Shading Option (bevel / bump / env map)
// - No Glow Option
// - Softness is applied on both side of the outline

Shader "TextMeshPro/Mobile/Distance Field - FixedOutlineWidth " {

Properties {
	[HDR]_FaceColor     ("Face Color", Color) = (1,1,1,1)
	_FaceDilate			("Face Dilate", Range(-1,1)) = 0

	[HDR]_OutlineColor	("Outline Color", Color) = (0,0,0,1)
	_OutlineWidth		("Outline Thickness", Range(0,1)) = 0
	_OutlineSoftness	("Outline Softness", Range(0,1)) = 0

	[HDR]_UnderlayColor	("Border Color", Color) = (0,0,0,.5)
	_UnderlayOffsetX 	("Border OffsetX", Range(-1,1)) = 0
	_UnderlayOffsetY 	("Border OffsetY", Range(-1,1)) = 0
	_UnderlayDilate		("Border Dilate", Range(-1,1)) = 0
	_UnderlaySoftness 	("Border Softness", Range(0,1)) = 0

	_WeightNormal		("Weight Normal", float) = 0
	_WeightBold			("Weight Bold", float) = .5

	_ShaderFlags		("Flags", float) = 0
	_ScaleRatioA		("Scale RatioA", float) = 1
	_ScaleRatioB		("Scale RatioB", float) = 1
	_ScaleRatioC		("Scale RatioC", float) = 1

	_MainTex			("Font Atlas", 2D) = "white" {}
	_TextureWidth		("Texture Width", float) = 512
	_TextureHeight		("Texture Height", float) = 512
	_GradientScale		("Gradient Scale", float) = 5
	_ScaleX				("Scale X", float) = 1
	_ScaleY				("Scale Y", float) = 1
	_PerspectiveFilter	("Perspective Correction", Range(0, 1)) = 0.875
	_Sharpness			("Sharpness", Range(-1,1)) = 0

	_VertexOffsetX		("Vertex OffsetX", float) = 0
	_VertexOffsetY		("Vertex OffsetY", float) = 0

	_ClipRect			("Clip Rect", vector) = (-32767, -32767, 32767, 32767)
	_MaskSoftnessX		("Mask SoftnessX", float) = 0
	_MaskSoftnessY		("Mask SoftnessY", float) = 0

	_StencilComp		("Stencil Comparison", Float) = 8
	_Stencil			("Stencil ID", Float) = 0
	_StencilOp			("Stencil Operation", Float) = 0
	_StencilWriteMask	("Stencil Write Mask", Float) = 255
	_StencilReadMask	("Stencil Read Mask", Float) = 255

	// _CullMode			("Cull Mode", Float) = 0
	_ColorMask			("Color Mask", Float) = 15

	[Group(Effects)]
	[GroupToggle(Effects)]_GrayOn("_GrayOn",int) = 0
	[GroupToggle(Effects)]_TwoColor("_TwoColor",int) = 0


	[Group(Alpha)]
	[GroupPresetBlendMode(Alpha,,_SrcMode,_DstMode)]_PresetBlendMode("_PresetBlendMode",int)=0
	// [GroupEnum(Alpha,UnityEngine.Rendering.BlendMode)]
	[HideInInspector]_SrcMode("_SrcMode",int) = 1
	[HideInInspector]_DstMode("_DstMode",int) = 10  

	[Group(Settings)]
	[GroupToggle(Settings)]_ZWriteMode("ZWriteMode",int) = 0
	/*
	Disabled,Never,Less,Equal,LessEqual,Greater,NotEqual,GreaterEqual,Always
	*/
	[GroupEnum(Settings,UnityEngine.Rendering.CompareFunction)]_ZTestMode("_ZTestMode",float) = 8
	[GroupEnum(Settings,UnityEngine.Rendering.CullMode)]_CullMode("_CullMode",int) = 0

}

SubShader {
	Tags
	{
		"Queue"="Transparent"
		"IgnoreProjector"="True"
		"RenderType"="Transparent"
	}


	Stencil
	{
		Ref [_Stencil]
		Comp [_StencilComp]
		Pass [_StencilOp]
		ReadMask [_StencilReadMask]
		WriteMask [_StencilWriteMask]
	}

	Fog { Mode Off }
	Cull[_CullMode]
	Lighting Off
	ZWrite [_ZWriteMode]
	ZTest [unity_GUIZTestMode]
	// Blend One OneMinusSrcAlpha
	blend [_SrcMode][_DstMode]
	ColorMask [_ColorMask]

	Pass {
		HLSLPROGRAM
		#pragma vertex VertShader
		#pragma fragment PixShader
		#pragma shader_feature OUTLINE_ON
		#pragma shader_feature UNDERLAY_ON UNDERLAY_INNER

		#pragma multi_compile __ UNITY_UI_CLIP_RECT
		#pragma multi_compile __ UNITY_UI_ALPHACLIP

		// #define USE_URP
		#include "../../PowerShaderLib/Lib/UnityLib.hlsl"
		#include "../../PowerShaderLib/Lib/ColorSpace.hlsl"
		
		#include "UnityUI.cginc"
		#include "TMPro_Properties.cginc"

		#pragma multi_compile_fragment _ _SRGB_TO_LINEAR_CONVERSION _LINEAR_TO_SRGB_CONVERSION

        float2 UnpackUV(float uv)
		{ 
			float2 output;
			output.x = floor(uv / 4096);
			output.y = uv - 4096 * output.x;

			return output * 0.001953125;
		}

		struct vertex_t {
			UNITY_VERTEX_INPUT_INSTANCE_ID
			float4	vertex			: POSITION;
			float3	normal			: NORMAL;
			fixed4	color			: COLOR;
			float2	texcoord0		: TEXCOORD0;
			float2	texcoord1		: TEXCOORD1;
		};

		struct pixel_t {
			UNITY_VERTEX_INPUT_INSTANCE_ID
			UNITY_VERTEX_OUTPUT_STEREO
			float4	vertex			: SV_POSITION;
			fixed4	faceColor		: COLOR;
			fixed4	outlineColor	: COLOR1;
			float4	texcoord0		: TEXCOORD0;			// Texture UV, Mask UV
			half4	param			: TEXCOORD1;			// Scale(x), BiasIn(y), BiasOut(z), Bias(w)
			half4	mask			: TEXCOORD2;			// Position in clip space(xy), Softness(zw)
			#if (UNDERLAY_ON | UNDERLAY_INNER)
			float4	texcoord1		: TEXCOORD3;			// Texture UV, alpha, reserved
			half2	underlayParam	: TEXCOORD4;			// Scale(x), Bias(y)
			#endif
            float4	textureUV		: TEXCOORD5;
			float4	upCol			: TEXCOORD6;
			float4	downCol		: TEXCOORD7;
		};

		pixel_t VertShader(vertex_t input)
		{
			pixel_t output;

			UNITY_INITIALIZE_OUTPUT(pixel_t, output);
			UNITY_SETUP_INSTANCE_ID(input);
			UNITY_TRANSFER_INSTANCE_ID(input, output);
			UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

			float bold = step(input.texcoord1.y, 0);

			float4 vert = input.vertex;
			vert.x += _VertexOffsetX;
			vert.y += _VertexOffsetY;
			float4 vPosition = UnityObjectToClipPos(vert);

			// float2 screenSize = _ScaledScreenParams;
			float isOrtho = unity_OrthoParams.w;
			float pixelScale = lerp(4,1,isOrtho);

			float2 screenSize = float2(1920,1080);
			screenSize = lerp(screenSize.xy, screenSize.yx ,_ScreenParams.y > _ScreenParams.x);
			float2 pixelSize = vPosition.w;
			pixelSize /= float2(_ScaleX, _ScaleY) * abs(mul((float2x2)UNITY_MATRIX_P, screenSize.xy));
			// pixelSize = 4/_ScaledScreenParams*float2(_ScaleX, _ScaleY);
			// pixelSize *= pixelScale;

			float scale = rsqrt(dot(pixelSize, pixelSize));
			scale *= abs(input.texcoord1.y) * _GradientScale * (_Sharpness + 1);
			if(UNITY_MATRIX_P[3][3] == 0) scale = lerp(abs(scale) * (1 - _PerspectiveFilter), scale, abs(dot(UnityObjectToWorldNormal(input.normal.xyz), normalize(WorldSpaceViewDir(vert)))));

			float weight = lerp(_WeightNormal, _WeightBold, bold) / 4.0;
			weight = (weight + _FaceDilate) * _ScaleRatioA * 0.5;

			float layerScale = scale;

			scale /= 1 + (_OutlineSoftness * _ScaleRatioA * scale);
			float bias = (0.5 - weight) * scale - 0.5;
			//float outline = _OutlineWidth * _ScaleRatioA * 0.5 * scale;

			// use _OutlineWidth direct
			float outline = _OutlineWidth *_ScaleRatioA *10;

			float opacity = input.color.a;
			#if (UNDERLAY_ON | UNDERLAY_INNER)
			opacity = 1.0;
			#endif

            fixed4 faceColor = fixed4(input.color.rgb, opacity) * _FaceColor;
        
            float2 textureUV = UnpackUV(input.texcoord1.xy);			
			fixed4 upColor = float4(0,0,0,1);
			fixed4 downColor = float4(0,0,0,1);
            float _Threshold = 0.01;
            if (abs(textureUV.y) < _Threshold)
			{downColor.rgb = input.color.rgb;}
			else
			{upColor.rgb = input.color.rgb;}
			
			faceColor.rgb *= faceColor.a;

			fixed4 outlineColor = _OutlineColor;
			outlineColor.a *= opacity;
			outlineColor.rgb *= outlineColor.a;
			outlineColor = lerp(faceColor, outlineColor, sqrt(min(1.0, (outline * 2))));

			#if (UNDERLAY_ON | UNDERLAY_INNER)
			layerScale /= 1 + ((_UnderlaySoftness * _ScaleRatioC) * layerScale);
			float layerBias = (.5 - weight) * layerScale - .5 - ((_UnderlayDilate * _ScaleRatioC) * .5 * layerScale);

			float x = -(_UnderlayOffsetX * _ScaleRatioC) * _GradientScale / _TextureWidth;
			float y = -(_UnderlayOffsetY * _ScaleRatioC) * _GradientScale / _TextureHeight;
			float2 layerOffset = float2(x, y);
			#endif

			// Generate UV for the Masking Texture
			float4 clampedRect = clamp(_ClipRect, -2e10, 2e10);
			float2 maskUV = (vert.xy - clampedRect.xy) / (clampedRect.zw - clampedRect.xy);

			// Populate structure for pixel shader
			output.vertex = vPosition;
			output.faceColor = faceColor;
			output.outlineColor = outlineColor;
			output.texcoord0 = float4(input.texcoord0.x, input.texcoord0.y, maskUV.x, maskUV.y);
			output.param = half4(scale, bias - outline, bias + outline, bias);
			output.mask = half4(vert.xy * 2 - clampedRect.xy - clampedRect.zw, 0.25 / (0.25 * half2(_MaskSoftnessX, _MaskSoftnessY) + pixelSize.xy));
			#if (UNDERLAY_ON || UNDERLAY_INNER)
			output.texcoord1 = float4(input.texcoord0 + layerOffset, input.color.a, 0);
			output.underlayParam = half2(layerScale, layerBias);
			#endif
            output.textureUV = float4(textureUV,textureUV);
			output.upCol = upColor;
			output.downCol = downColor;

			return output;
		}


		// PIXEL SHADER
		fixed4 PixShader(pixel_t input) : SV_Target
		{
			#if defined(_TWO_COLOR)
			return 0;
			#endif
			UNITY_SETUP_INSTANCE_ID(input);

			half d = tex2D(_MainTex, input.texcoord0.xy).a * input.param.x;
			//half4 c = input.faceColor * saturate(d - input.param.w);
            half4 c = lerp(input.faceColor,_FaceColor *(input.upCol*(input.textureUV.y>0.5)+input.downCol*(input.textureUV.y<0.5)),_TwoColor)* saturate(d - input.param.w);


			#ifdef OUTLINE_ON
			float outlineRate = saturate(smoothstep(0.01,0.02,d)*4 );
			//c = lerp(input.outlineColor, input.faceColor, saturate(d - input.param.z));
            c = lerp(input.outlineColor, c, saturate(d - input.param.z));
			c *= saturate(d - input.param.y) * outlineRate;
			#endif

			#if UNDERLAY_ON
			d = tex2D(_MainTex, input.texcoord1.xy).a * input.underlayParam.x;
			c += float4(_UnderlayColor.rgb * _UnderlayColor.a, _UnderlayColor.a) * saturate(d - input.underlayParam.y) * (1 - c.a);
			#endif

			#if UNDERLAY_INNER
			half sd = saturate(d - input.param.z);
			d = tex2D(_MainTex, input.texcoord1.xy).a * input.underlayParam.x;
			c += float4(_UnderlayColor.rgb * _UnderlayColor.a, _UnderlayColor.a) * (1 - saturate(d - input.underlayParam.y)) * sd * (1 - c.a);
			#endif

			// Alternative implementation to UnityGet2DClipping with support for softness.
			#if UNITY_UI_CLIP_RECT
			half2 m = saturate((_ClipRect.zw - _ClipRect.xy - abs(input.mask.xy)) * input.mask.zw);
			c *= m.x * m.y;
			#endif

			#if (UNDERLAY_ON | UNDERLAY_INNER)
			c *= input.texcoord1.z;
			#endif

			#if UNITY_UI_ALPHACLIP
			clip(c.a - 0.001);
			#endif

			LinearGammaAutoChange(c/**/);
			c.xyz = lerp(c.xyz,dot(float3(0.2,0.7,0.02),c.xyz),_GrayOn);
            c.xyz = lerp(c.xyz,c.xyz*1.5,_TwoColor);
			return c;
		}
		ENDHLSL
	}
}

CustomEditor "PowerUtilities.TMP_SDFShaderGUI"
}
