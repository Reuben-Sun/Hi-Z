Shader "HZB/HzbBuild"
{
    Properties
    {
        [HideInInspector] _DepthTexture("Depth Texture", 2D) = "black"{}
        [HideInInspector] _InvSize("Inverse Mipmap Size", Vector) = (0, 0, 0, 0)
    }
    SubShader
    {
        Pass
        {
            Cull Off ZWrite Off ZTest Always
            
            Name "HzbBuild"
            
            CGPROGRAM
            #pragma target 3.0
            
            #pragma vertex vert
            #pragma fragment frag
            
            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            sampler2D _DepthTexture;
            float4 _InvSize;

            inline float HzbReduce(sampler2D mainTex, float2 inUV, float2 invSize)
            {
                float4 depth;
                float2 uv0 = inUV + float2(-0.25f, -0.25f) * invSize;
                float2 uv1 = inUV + float2(0.25f, -0.25f) * invSize;
                float2 uv2 = inUV + float2(-0.25f, 0.25f) * invSize;
                float2 uv3 = inUV + float2(0.25f, 0.25f) * invSize;

                depth.x = tex2D(mainTex, uv0);
                depth.y = tex2D(mainTex, uv1);
                depth.z = tex2D(mainTex, uv2);
                depth.w = tex2D(mainTex, uv3);

#if defined(UNITY_REVERSED_Z)
                return min(min(depth.x, depth.y), min(depth.z, depth.w));
#else
                return max(max(depth.x, depth.y), max(depth.z, depth.w));
#endif
            }
            
            Varyings vert (Attributes v)
            {
                Varyings o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (Varyings i) : SV_Target
            {
                float2 invSize = _InvSize.xy;
                float2 inUV = i.uv;
                float depth = HzbReduce(_DepthTexture, inUV, invSize);
                return float4(depth, 0, 0, 1);
            }
            ENDCG
        }
    }
}
