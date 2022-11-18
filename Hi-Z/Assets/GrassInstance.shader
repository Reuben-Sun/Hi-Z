Shader "HZB/GrassInstance"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Roughness ("Roughness", Range(0,1)) = 0.8
        _Cutoff ("Cutoff", float) = 0.5
        _GrassSize ("Grass Size", Vector) = (2,2,1,0)
        _WaveSpeed ("Wave Speed", Vector) = (1,1,0.2,0.2)
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
            #include "UnityLightingCommon.cginc"
             #include "AutoLight.cginc"

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 diffuse : TEXCOORD1;
                float3 specular : TEXCOORD2;
                SHADOW_COORDS(3)
            };

            sampler2D _MainTex;
            StructuredBuffer<float3> posVisibleBuffer;
            float _Cutoff;
            float4 _GrassSize;
            float4 _WaveSpeed;
            float _Roughness;

            float rand(float3 co, float minNum, float maxNum)
            {
                return frac(sin(dot(co, float3(12.9898, 78.233, 53.539))) * 43758.5453) * (maxNum - minNum) + minNum;
            }

            float rand2(float3 co, float minNum, float maxNum)
            {
                return frac(sin(dot(co, float3(66.123, 13.1313, 77.996))) * 9876.1234) * (maxNum - minNum) + minNum;
            }

            inline float3 billboard(float3 pos)
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

            inline float3 rotateRand(float3 pos, float3 posWS)
            {
                float x = rand(posWS, -_GrassSize.a, _GrassSize.a);
                float z = rand2(posWS, -_GrassSize.a, _GrassSize.a);
                float2x2 m = float2x2(x, -z, z, x);
                float3 rotatedPos = pos;
                rotatedPos.xz = mul(pos.xz, m);
                return rotatedPos;
            }
            v2f vert (appdata_full v, uint instanceID : SV_InstanceID)
            {
                v2f o;
                float3 posWS = posVisibleBuffer[instanceID];
                
                float3 loaclPos = billboard(rotateRand(v.vertex.xyz, posWS));
                posWS += loaclPos;

                //Wave
                float2 samplePos = posWS.xz;
                float heightFactor = v.vertex.y > 0.3;
                heightFactor = heightFactor * pow(2, v.vertex.y);
                samplePos += _Time.x * _WaveSpeed.xy;
                posWS.z += sin(samplePos.x) * _WaveSpeed.z * heightFactor;
                posWS.x += cos(samplePos.y) * _WaveSpeed.a * heightFactor;
                
                o.pos = mul(UNITY_MATRIX_VP, float4(posWS, 1.0f));
                o.uv = v.texcoord;

                //lighting
                float3 V = normalize(_WorldSpaceCameraPos - posWS);
                float3 H = normalize(V + normalize(_WorldSpaceLightPos0.xyz));
                float NoH = saturate(dot(float3(0,1,0), H));
                float NoH2 = saturate(dot(v.normal, H));
                o.diffuse = (NoH * 0.5 + 0.5) * _LightColor0.rgb;
                float m2 = _Roughness * _Roughness;
                float D =(NoH2 * m2 - NoH2) * NoH2 + 1;
                D = D * D + 1e-06;
                o.specular = 0.25 * m2 / D;
                
                TRANSFER_SHADOW(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 albedo = tex2D(_MainTex, i.uv);
                fixed shadow = SHADOW_ATTENUATION(i);
                clip(albedo.a - _Cutoff);
                float3 color = albedo.xyz * (clamp(i.diffuse, 0.5, 1) + i.specular) * shadow;
                return float4(color, 1);
            }
            ENDCG
        }
    }
}
