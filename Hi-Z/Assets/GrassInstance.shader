Shader "HZB/GrassInstance"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Cutoff("Cutoff", float) = 0.5
    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode"="ForwardBase"}
            Cull Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
            #pragma target 4.5
            
            #include "UnityCG.cginc"


            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            StructuredBuffer<float3> posVisibleBuffer;
            float _Cutoff;
            
            v2f vert (appdata_full v, uint instanceID : SV_InstanceID)
            {
                v2f o;
                float3 posWS = posVisibleBuffer[instanceID];
                
                float3 camRight = UNITY_MATRIX_IT_MV[0].xyz;
                float3 camUp = UNITY_MATRIX_IT_MV[1].xyz;
                posWS += camRight * v.vertex.x + camUp * v.vertex.y;

                o.vertex = mul(UNITY_MATRIX_VP, float4(posWS, 1.0f));
                o.uv = v.texcoord;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                clip(col.a - _Cutoff);
                return col;
            }
            ENDCG
        }
    }
}
