// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Ocean/OceanSurface"
{
    Properties
    {
        _Color1 ("Color1", Color) = (1,1,1,1)
		_Color2("Color2", Color) = (1,1,1,1)

        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

		// normal map
		_NormalMap("Normal Map",2d) = "bump"{}
		_NormalTile("Normal Tile",float) = 0.3
		_NormalStrength("Normal Strength",float) = 1
		_NormalSpeed("Normal speed",float) = 0.15
		// wave
		_WaveTile("Wave Tile",float) = 1
		_WaveScale("Wave Scale",float) = 1
		_WaveSpeed("Wave Speed",float) = 1
		_WaveStrength("Wave Strength",float) = 1
		// foam
		_FoamDepth("Foam Depth",float) = 1
		_FoamTexture("Foam Texture",2d) = ""{}
		_FoamTile("Foam Tile",float) = 1
		_FoamSpeed("Foam Speed",float) = 1
		_FoamColor("Foam Color",color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        LOD 200
		// blend srcAlpha oneMinusSrcAlpha
		// ztest always

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard nolightmap alpha:fade vertex:vert

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0
#include "NodeLib.cginc"

        struct Input
        {
            float2 uv_MainTex;
			float3 worldPos;
			float4 screenPos;
			float eyeDepth;

			float3 worldNormal;
			INTERNAL_DATA
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color1;
		fixed4 _Color2;
		//normal
		sampler2D _NormalMap;
		float _NormalTile;
		float _NormalSpeed;
		float _NormalStrength;

		//wave
		float _WaveTile;
		float _WaveScale;
		float _WaveSpeed;
		float _WaveStrength;
		//foam
		float _FoamDepth;
		sampler2D _FoamTexture;
		float _FoamTile;
		float _FoamSpeed;
		float4 _FoamColor;

		sampler2D _CameraDepthTexture;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

		// vertex wave.
		void VertexWave(inout appdata_full v) {
			float4 worldPos = mul(unity_ObjectToWorld, v.vertex);

			float2 uv = (float2)0;
			Unity_TilingAndOffset_float(worldPos.xz, (float2)_WaveTile, float2(1, 0) * _Time.y * _WaveStrength, uv);

			float wave;
			Unity_SimpleNoise_float(uv, _WaveStrength, wave);
			v.vertex.y = wave;
		}

		void vert(inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input, o);
			COMPUTE_EYEDEPTH(o.eyeDepth);

			VertexWave(v);
		}


        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			//xz normal
			float2 uv = (float2)0;
			Unity_TilingAndOffset_float(IN.worldPos.xz, (float2)_NormalTile, float2(1, 0) * _Time.y * 0.15f * _NormalSpeed, uv);
			float3 worldNormal1 = NormalStrength(UnpackNormal(tex2D(_NormalMap, uv)), _NormalStrength);

			Unity_TilingAndOffset_float(IN.worldPos.xz, (float2)_NormalTile,float2(-1, 0.3)* _Time.y * 0.15f * _NormalSpeed, uv);
			float3 worldNormal2 = NormalStrength(UnpackNormal(tex2D(_NormalMap, uv)), _NormalStrength);

			//uv normal
			float3 worldNormal = NormalStrength(UnpackNormal(tex2D(_NormalMap,IN.uv_MainTex)), _NormalStrength);
			float fresnal = SimpleFresnal(_WorldSpaceCameraPos.xyz, worldNormal,1);

			//wave
			Unity_TilingAndOffset_float(IN.worldPos.xz * float2(0.02, 0.5), (float2)_WaveTile, float2(0, 1) * _Time.y * 0.15 * _WaveSpeed, uv);

			float wave;
			Unity_SimpleNoise_float(uv, _WaveScale, wave);
			wave = clamp(wave, 0.5, 1);

			//depth
			float d = LinearEyeDepth(tex2D(_CameraDepthTexture, IN.screenPos.xy / IN.screenPos.w).r);
			d = clamp((d - IN.eyeDepth) * _FoamDepth , 0, 1);
			float invDepth = 1 - d;
			//foam
			Unity_TilingAndOffset_float(IN.uv_MainTex, (float2)_FoamTile, float2(0, 1) * _Time.y * 0.15 * _FoamSpeed, uv);
			float4 foamCol = tex2D(_FoamTexture, uv) * _FoamColor;

            // Albedo comes from a texture tinted by color
			float4 col = lerp(_Color1, _Color2, fresnal);
			o.Albedo = (col  * wave  + invDepth * foamCol);
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = col.a * d;

			o.Normal = BlendNormal(worldNormal1, worldNormal2);
        }
        ENDCG
    }
    //FallBack "Diffuse"
}
