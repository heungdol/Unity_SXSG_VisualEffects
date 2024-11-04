Shader "SXSG/Shader_BendingBuilding"
{
    Properties
    {
        _BaseMap ("Texture", 2D) = "white" {}
        _MainColor ("Main Color", Color) = (1, 1, 1, 1)

        _PivotX ("Pivot X (WorldPos)", Float) = 50
        _PivotY ("Pivot Y (WorldPos)", Float) = 100

        // _InnerX ("Inner X (LocalPos)", Float) = 10
        _InnerX ("Inner X (LocalPos)", Float) = 10
        // _OuterX ("Outer X (WorldPos)", Float) = -10
        
        _BendingRatio ("Bending Ratio", Range (0.0, 1.0)) = 0.0
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode" = "ForwardBase" }

        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            // make fog work
            // #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Shader_Utils.cginc"

            // struct appdata
            // {
            //     float4 vertex : POSITION;
            //     float2 uv : TEXCOORD0;
            // };

            // struct v2f
            // {
            //     float2 uv : TEXCOORD0;
            //     float4 vertex : SV_POSITION;
            //     float4 localPos : TEXCOORD1;
            //     // float3 worldNormal : 
            //     // float isUpperThanStartHeight : TEXCOORD1;
            // };

            float _PivotY;
            float _PivotX;

            float _InnerX;
            // float _OuterX;

            float _BendingRatio;

            float4 _MainColor;

            v2f vert (appdata_full v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.localPos = v.vertex;
                
                // 월드 위치
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                float4 worldInnerPos = mul (unity_ObjectToWorld, float4(_InnerX, 0.0, 0.0, 1.0));
                
                // 영향을 받을 부분 판단 (일정 높이 이상)
                float isUpperThanStartHeight = step (_PivotY, o.worldPos.y);

                // 얼마나 Bending 시킬 지 판단 
                
                // 반지름
                float radius = (_PivotX - o.worldPos.x);
                // 하나의 기준 축을 이용하여 계산 (부피에 따른 적절한 비율로 계산하기 위함)
                float radiusInner = (_PivotX - worldInnerPos.x);
                
                float length = abs (o.worldPos.y - _PivotY);
                float angle = length / radiusInner;
                
                // 길이와 각을 이용하여 굽힘 정도 계산
                float4 offsetWorldPos = float4 (0.0, 0.0, 0.0, 0.0);
                offsetWorldPos.y = sin (angle) * radius;
                offsetWorldPos.x = cos (angle) * -radius;

                float4 pivotWorldPos = float4 (_PivotX, _PivotY, o.worldPos.z, 1.0);

                // // Bending 적용
                float ratio = isUpperThanStartHeight * _BendingRatio;
                float3 bentWorldPos = lerp(o.worldPos, offsetWorldPos + pivotWorldPos, ratio);
                o.pos = UnityWorldToClipPos(float4(bentWorldPos, 1.0));
                o.worldPos = float4(bentWorldPos.xyz, 1.0);

                // v.vertex = mul (unity_WorldToObject, float4(bentWorldPos.xyz, 1.0));

                // o._ShowCoord = TransformWorldToShadowCoord(o.worldNormal);

                // TRANSFER_SHADOW(o)
                TRANSFER_VERTEX_TO_FRAGMENT(o);

                o.worldPos = mul(unity_ObjectToWorld, o.pos);

                o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
                o.uv2 = TRANSFORM_TEX(v.texcoord2, _BaseMap);
                
                // 노멀 회전
                float2 rotatedNormal;
                rotatedNormal.x = v.normal.x * cos (angle) - v.normal.y * sin (angle);
                rotatedNormal.y = v.normal.x * sin (angle) + v.normal.y * cos (angle);
                v.normal = (1 - ratio) * v.normal + ratio * float3(rotatedNormal.x, rotatedNormal.y, v.normal.z);
                
                // 본래 정보 계산
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                half3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
                // compute bitangent from cross product of normal and tangent
                half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                half3 wBitangent = cross(o.worldNormal, wTangent) * tangentSign;
                // output the tangent space matrix
                o.tspace0 = half3(wTangent.x, wBitangent.x, o.worldNormal.x);
                o.tspace1 = half3(wTangent.y, wBitangent.y, o.worldNormal.y);
                o.tspace2 = half3(wTangent.z, wBitangent.z, o.worldNormal.z);

                
                // _ShadowCoord = TransformWorldToShadowCoord(o.worldNormal);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_BaseMap, i.uv);

                col *= _MainColor;

                // col.rgb *= fmod (i.localPos.x + 10000, 1.0); 
                
                half3 tnormal = UnpackNormal(tex2D(_BumpMap, i.uv));
                half3 worldNormal;
                worldNormal.x = dot(i.tspace0, tnormal);
                worldNormal.y = dot(i.tspace1, tnormal);
                worldNormal.z = dot(i.tspace2, tnormal);

                half nl = max (0, dot (worldNormal, _WorldSpaceLightPos0.xyz));
                float4 diff = nl * _LightColor0;
                diff.rgb += ShadeSH9(half4(worldNormal,1));
                
                col *= SHADOW_ATTENUATION(i) * 0.7 + 0.5;
                col *= diff;

                return float4(col.rgb, 1.0);
            }
            ENDCG
        }

        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
