Shader "HZB/GrassInstance"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Cutoff("Cutoff", float) = 0.5
        _GrassSize("Grass Size", Vector) = (2,2,1,0)
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
            float4 _GrassSize;

            float rand(float3 co, float minNum, float maxNum)
            {
                return frac(sin(dot(co, float3(12.9898, 78.233, 53.539))) * 43758.5453) * (maxNum - minNum) + minNum;
            }

            float3 billboard(float3 pos)
            {
                float3 center = float3(0, 0, 0);
				float3 viewer = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos, 1));
				
				float3 normalDir = viewer - center;
				normalDir.y = 0;
				normalDir = normalize(normalDir);

				float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1): float3(0, 1, 0);
				float3 rightDir = normalize(cross(upDir, normalDir))*-1;
				upDir = normalize(cross(normalDir, rightDir));
                
				float3 centerOffs = pos - center;
				float3 localPos = center + rightDir * centerOffs.x * _GrassSize.x
                    - upDir * centerOffs.y * _GrassSize.y
                    + normalDir * centerOffs.z * _GrassSize.z;
                return localPos;
            }
            
            v2f vert (appdata_full v, uint instanceID : SV_InstanceID)
            {
                v2f o;
                float3 posWS = posVisibleBuffer[instanceID];
                
                float3 loaclPos = billboard(v.vertex.xyz);
                posWS += loaclPos;
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
