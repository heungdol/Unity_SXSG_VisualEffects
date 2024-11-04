Shader "SXSG/Shader_Fractal_Quad"
{
    Properties
    {
        _BaseMap ("Texture", 2D) = "white" {}
        _BumpMap("Normal Map", 2D) = "bump" {}

        _OffsetLocalPos ("Offset Local Position", Vector) = (0, 0, 0, 1)
        _OffsetLocalRot ("Offset Local Rotation", Vector) = (0, 0, 0, 1)
        
        _RotationSpeed ("Rotation Speed by Time", Vector) = (0, 0, 0, 1)
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Queue"
            "LightMode" = "ForwardBase"
        }

        LOD 100

        // =============================================================
        
        Cull Back

        // #1 (0)
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Shader_Utils.cginc"
            #include "Shader_Fractal.cginc"
            
            // 각 패스마다 수정할 것
            #define startAngle 0.0
            #define gapAngle 45
 
            v2f vert (appdata_full v)
            {
                v2f o;

                calculateVert (v, o, startAngle, 0.0);
                
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                if (isBetweenAngle(i, startAngle, gapAngle) < 0.5)
                {
                    discard;
                }

                return calculateColor (i);
            }

            ENDCG
        }

        // #3 (180)
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Shader_Utils.cginc"
            #include "Shader_Fractal.cginc"

            // 각 패스마다 수정할 것
            #define startAngle 180
            #define gapAngle 45
 
            v2f vert (appdata_full v)
            {
                v2f o;     

                calculateVert (v, o, startAngle, 0.0);
                
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                if (isBetweenAngle(i, startAngle, gapAngle) < 0.5)
                {
                    discard;
                }

                return calculateColor (i);
            }
            
            ENDCG
        }

        // =============================================================
        
        Cull Front

        // #2 (90)
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Shader_Utils.cginc"
            #include "Shader_Fractal.cginc"

            // 각 패스마다 수정할 것
            #define startAngle 90
            #define gapAngle 45
 
            v2f vert (appdata_full v)
            {
                v2f o;  

                calculateVert (v, o, startAngle, 1.0);
                
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                if (isBetweenAngle(i, startAngle, gapAngle) < 0.5)
                {
                    discard;
                }

                return calculateColor (i);
            }

            ENDCG
        }

        // #4 (270)
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Shader_Utils.cginc"
            #include "Shader_Fractal.cginc"

            // 각 패스마다 수정할 것
            #define startAngle 270
            #define gapAngle 45
 
            v2f vert (appdata_full v)
            {
                v2f o;

                calculateVert (v, o, startAngle, 1.0);
                
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                if (isBetweenAngle(i, startAngle, gapAngle) < 0.5)
                {
                    discard;
                }

                return calculateColor (i);
            }
            
            ENDCG
        }
    }   
}
