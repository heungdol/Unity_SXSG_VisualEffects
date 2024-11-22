Shader "SXSG/Shader_BendingBuilding_Surface"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _BaseMap ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _PivotX ("Pivot X (WorldPos)", Float) = 50
        _PivotX_Max ("Pivot X Max (WorldPos)", Float) = 300

        _PivotY ("Pivot Y (WorldPos)", Float) = 100
        
        _BendingPosZ ("Bending Pos Z (Progress Degree)", Float) = 100
        [Min(0.1)] _BendingLengthZ ("Recontruction Length Z (For Calculating Progress Ratio)", Float) = 0
        // _InnerX ("Inner X (LocalPos)", Float) = 10

        // _BendingRatio ("Bending Ratio", Range (0.0, 1.0)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert addshadow
        #pragma target 3.0

        sampler2D _BaseMap;

        struct Input 
        {
			float2 uv_BaseMap;
		};

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        
        // float _BendingRatio;
        
        float _PivotY;
        float _PivotX;
        float _PivotX_Max;
        // float _InnerX;

        float _BendingPosZ;
        float _BendingLengthZ;
        
        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        // 오브젝트의 월드 Position Z 값
        float objectPosZInWorld ()
        {
            return mul (unity_ObjectToWorld, fixed4 (0, 0, 0, 1)).z;
        }

        // 현재 진행 정도 비율 계산
        float bendingRate ()
        {
            // trueT = Mathf.Sin((t - 0.5f) * Mathf.PI) * 0.5f + 0.5f;
            // trueT = Mathf.Pow (trueT, 0.25f);

            float wrapped = saturate ((_BendingPosZ - objectPosZInWorld()) / _BendingLengthZ);
            wrapped = sin ((wrapped - 0.5) * 3.141592) * 0.5 + 0.5;
            wrapped = pow (wrapped, 0.25);

            return wrapped;
        }

        // 현재 진행 정도를 이용한 반지름 계산
        float pivotRadius ()
        {
            return lerp (_PivotX_Max, _PivotX, bendingRate ());
        }

        void vert(inout appdata_full data)
        {
            // 월드 위치
            float4 worldPos = mul(unity_ObjectToWorld, data.vertex);
            // float4 worldInnerPos = mul (unity_ObjectToWorld, float4(_InnerX, 0.0, 0.0, 1.0));
            // float4 worldInnerPos = mul (unity_ObjectToWorld, float4(0.0, 0.0, 0.0, 1.0));
            
            // 영향을 받을 부분 판단 (일정 높이 이상)
            float isUpperThanStartHeight = step (_PivotY, worldPos.y);

            // 반지름
            float radius = (pivotRadius() - data.vertex.x);

            // 하나의 기준 축을 이용하여 계산 (부피에 따른 적절한 비율로 계산하기 위함)
            float radiusInner = (pivotRadius());// - worldInnerPos.x);
            
            float length = abs (worldPos.y - _PivotY);
            float angle = length / radiusInner;

            // 길이와 각을 이용하여 굽힘 정도 계산
            float3 offsetPos = float3 (0.0, 0.0, 0.0);
            offsetPos.x = cos (angle) * radius;
            offsetPos.x = radius - offsetPos.x;
    
            offsetPos.y = sin (angle) * radius - length;
            
            // Bending 적용
            float ratio = isUpperThanStartHeight * bendingRate();
            data.vertex.xyz = lerp(data.vertex.xyz, data.vertex.xyz + offsetPos, ratio);

            // data.vertex.xyz = bentWorldPos;//mul (unity_WorldToObject, float4(bentWorldPos, 1.0));
            // data.vertex.w = 1;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_BaseMap, IN.uv_BaseMap) * _Color;
            o.Albedo = c.rgb;

            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
