Shader "Unlit/Shader_Reconstruction"
{
    Properties
    {
        _BaseMap ("Texture", 2D) = "white" {}

        _IDMask ("ID Mask Map", 2D) = "white" {}
        _DirectionMask ("Direction Mask Map", 2D) = "white" {}

        _RecontructionRate ("Recontruction Rate", Range (0.0, 1.0)) = 0

        _DirectionDegree ("Direction Degree", Float) = 0
        _DirectionRandomDegree ("Direction Random Degree", Float) = 0.5
        _RotationDegree ("Rotation Degree", Float) = 0
        _RandomSeed ("Random Seed", Int) = 12345
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            // #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                // UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _BaseMap;
            float4 _BaseMap_ST;

            sampler2D _IDMask;
            float4 _IDMask_ST;
            
            sampler2D _DirectionMask;
            float4 _DirectionMask_ST;
            
            float _RecontructionRate;

            float _DirectionDegree;
            float _DirectionRandomDegree;
            float _RotationDegree;
            float _RandomSeed;

            float customRandom (in float value)
            {
                return frac (sin (value * -_RandomSeed) * 12345.6789);
            }

            void offsetLocalPosition (inout appdata v, in float4 offset)
            {
                v.vertex.x += offset.x;
                v.vertex.y += offset.y;
                v.vertex.z += offset.z;
            }

            void rotateLocalRotaion_X (inout appdata v, in float degree)
            {
                // 로컬 위치 YZ평면 회전
                float rad = radians(degree);
                float cosTheta = cos(rad);
                float sinTheta = sin(rad);

                float2 rotatedPosition;
                rotatedPosition.x = v.vertex.y * cosTheta - v.vertex.z * sinTheta;
                rotatedPosition.y = v.vertex.y * sinTheta + v.vertex.z * cosTheta;
                v.vertex = float4(v.vertex.x, rotatedPosition.x, rotatedPosition.y, v.vertex.w);
            }

            void rotateLocalRotaion_Y (inout appdata v, in float degree)
            {
                // 로컬 위치 XZ평면 회전
                float rad = radians(degree);
                float cosTheta = cos(rad);
                float sinTheta = sin(rad);

                float2 rotatedPosition;
                rotatedPosition.x = v.vertex.x * cosTheta - v.vertex.z * sinTheta;
                rotatedPosition.y = v.vertex.x * sinTheta + v.vertex.z * cosTheta;
                v.vertex = float4(rotatedPosition.x, v.vertex.y, rotatedPosition.y, v.vertex.w);
            }

            void rotateLocalRotaion_Z (inout appdata v, in float degree)
            {
                // 로컬 위치 XY평면 회전
                float rad = radians(degree);
                float cosTheta = cos(rad);
                float sinTheta = sin(rad);

                float2 rotatedPosition;
                rotatedPosition.x = v.vertex.x * cosTheta - v.vertex.y * sinTheta;
                rotatedPosition.y = v.vertex.x * sinTheta + v.vertex.y * cosTheta;
                v.vertex = float4(rotatedPosition.x, rotatedPosition.y, v.vertex.z, v.vertex.w);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                // UNITY_TRANSFER_FOG(o, o.vertex);

                // Sample _IDMask texture in the vertex shader

                // 랜덤 값
                float4 idCol = tex2Dlod(_IDMask, float4(o.uv, 0.0, 1.0));
                float3 randomOffset = 
                float3(customRandom(idCol+10.0), customRandom(idCol+10.25), customRandom(idCol+10.5));
                
                // 로테이션
                rotateLocalRotaion_X (v, randomOffset.x * _RotationDegree * _RecontructionRate);
                rotateLocalRotaion_Y (v, randomOffset.y * _RotationDegree * _RecontructionRate);
                rotateLocalRotaion_Z (v, randomOffset.z * _RotationDegree * _RecontructionRate);

                // 위치 Offset
                float4 directionCol = tex2Dlod(_DirectionMask, float4(o.uv, 0.0, 1.0));
                directionCol -= 0.5;
                directionCol *= 2;
                
                v.vertex.xyz += (directionCol.xyz + randomOffset * _DirectionRandomDegree) * _DirectionDegree * _RecontructionRate;
                
                o.vertex = UnityObjectToClipPos(v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_BaseMap, i.uv);
                // apply fog
                // UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
