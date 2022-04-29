Shader "Hidden/Cloud"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Lib/CommonUtils.hlsl"

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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;

            half TestCube(half3 center,half3 halfSize,half3 pos){
                pos = pos - center - halfSize;
                return pos.x && pos.y && pos.z;
                // return min(min(pos.x - halfSize.x,pos.y - halfSize.y),pos.z - halfSize.z);
            }

            half TestSphere(half3 center,half radius,half3 pos){
                half3 d2 = pos - center;
                return dot(d2,d2) - radius * radius;
            }

            half cloudRayMarching(half3 startPos,half3 dir){
                half3 p = startPos;
                half sum = 0;
                dir *=0.5;
                for(int i=0;i< 100;i++){
                    p += dir;
                    if(TestSphere(half3(0,0,1),1,p) < 0)
                        sum += 0.1;
                }
                return sum;
            }


            half4 frag (v2f i) : SV_Target
            {
                half depth = tex2D(_CameraDepthTexture,i.uv);
                depth = LinearizeDepth(depth);
                half3 worldPos = ScreenToWorldPos(i.uv,depth);
                // return worldPos.xyzx;

                half3 viewDir = mul((half3x3)UNITY_MATRIX_I_V,half3(0,0,1));
                viewDir = normalize(_WorldSpaceCameraPos - worldPos);
// return viewDir.xyzx;
                half cube = cloudRayMarching(worldPos,viewDir);
                return cube;
            }
            ENDHLSL
        }
    }
}
