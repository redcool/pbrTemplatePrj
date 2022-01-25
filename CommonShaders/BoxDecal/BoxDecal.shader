Shader "Unlit/BoxDecal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    CGINCLUDE

            /**
                Decal in Box
                
                cube bounds is [-.5,.5]
                depth : [0, far]
                camPos : world space camera pos
                ray : camera's direction point to vertex
                return : xyz : cube space pos, w : is in box
            */
            float4 GetObjectPosFromDepth(float depth,float3 camPos,float3 ray){
                ray /= dot(ray,-UNITY_MATRIX_V[2].xyz);

                float3 worldPos = camPos + ray * depth;
                float3 objPos = mul(unity_WorldToObject,float4(worldPos,1));
                float3 inBox = .5 - abs(objPos);
                float a = min(min(inBox.x,inBox.y),inBox.z);

                return float4(objPos+0.5,a);
            }

    ENDCG
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent"}
        LOD 100
        // cull front
        // zwrite off
        // ztest always
        blend srcAlpha oneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 ray:TEXCOORD02;
                float4 screenPos:TEXCOORD3;
            };

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                float3 worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.ray = worldPos - _WorldSpaceCameraPos;
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }


            fixed4 frag (v2f i) : SV_Target
            {
                float2 screenUV = i.screenPos.xy/i.screenPos.w;
                float3 ray = normalize(i.ray);

                float depth = tex2D(_CameraDepthTexture,screenUV).x;
                depth = LinearEyeDepth(depth);

                float4 objPos = GetObjectPosFromDepth(depth,_WorldSpaceCameraPos,ray);
                // clip(objPos.w);

                // sample the texture
                fixed4 col = tex2D(_MainTex, objPos.xz);
                col.w *= smoothstep(0,0.1,objPos.w);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
