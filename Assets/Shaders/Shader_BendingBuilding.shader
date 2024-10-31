Shader "SXSG/Shader_BendingBuilding"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainColor ("Main Color", Color) = (1, 1, 1, 1)

        _PivotX ("Pivot X (WorldPos)", Float) = 50
        _PivotY ("Pivot Y (WorldPos)", Float) = 100

        _InnerX ("Inner X (LocalPos)", Float) = 10
        // _OuterX ("Outer X (WorldPos)", Float) = -10
        
        _BendingRatio ("Bending Ratio", Range (0.0, 1.0)) = 0.0
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
                float4 vertex : SV_POSITION;
                float4 localPos : TEXCOORD1;
                // float isUpperThanStartHeight : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _PivotY;
            float _PivotX;

            float _InnerX;
            // float _OuterX;

            float _BendingRatio;

            float4 _MainColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.localPos = v.vertex;
                
                // 월드 위치
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                float4 worldInnerPos = mul (unity_ObjectToWorld, float4(_InnerX, 0.0, 0.0, 1.0));
                
                // 영향을 받을 부분 판단 (일정 높이 이상)
                float isUpperThanStartHeight = step (_PivotY, worldPos.y);

                // 얼마나 Bending 시킬 지 판단 
                
                // 반지름
                float radius = (_PivotX - worldPos.x);
                // 하나의 기준 축을 이용하여 계산 (부피에 따른 적절한 비율로 계산하기 위함)
                float radiusInner = (_PivotX - worldInnerPos.x);
                
                float length = abs (worldPos.y - _PivotY);
                float angle = length / radiusInner;
                
                // 길이와 각을 이용하여 굽힘 정도 계산
                float4 offsetWorldPos = float4 (0.0, 0.0, 0.0, 0.0);
                offsetWorldPos.y = sin (angle) * radius;
                offsetWorldPos.x = cos (angle) * -radius;
                
                float4 pivotWorldPos = float4 (_PivotX, _PivotY, worldPos.z, 1.0);

                // // Bending 적용
                float ratio = isUpperThanStartHeight * _BendingRatio;
                o.vertex = UnityWorldToClipPos ((1 - ratio) * worldPos + ratio * (offsetWorldPos + pivotWorldPos));

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

                col *= _MainColor;

                // col.rgb *= fmod (i.localPos.x + 10000, 1.0); 
                
                return col;
            }
            ENDCG
        }
    }
}
