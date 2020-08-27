Shader "Zoroiscrying/GrabTexture/GrabPassGaussianBlur_Convoluted"
{
    Properties
    {  
        _BlurSize("Blur Size", Float) = 1.0
    }

    SubShader
    {
        // Draw ourselves after all opaque geometry
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }

        // Grab the screen behind the object into _BackgroundTexture
        GrabPass
        {
            "_GrabTexture_1"
        }

        // Vertical Blur
        Pass
        {
            //CULL OFF
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma fragmentoption ARB_precision_hint_fastest
            #include "UnityCG.cginc"

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                //float2 uv[5]: TEXCOORD0;
            };
            
            sampler2D _GrabTexture_1;
            half4 _GrabTexture_1_TexelSize;
            float _BlurSize;

            v2f vert(appdata_base v) {
                v2f o;
                // use UnityObjectToClipPos from UnityCG.cginc to calculate 
                // the clip-space of the vertex
                o.pos = UnityObjectToClipPos(v.vertex);
                // use ComputeGrabScreenPos function from UnityCG.cginc
                // to get the correct texture coordinate
                o.uv = ComputeGrabScreenPos(o.pos);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                fixed4 pixelCol = fixed4(0, 0, 0, 0);
 
                #define ADDPIXEL(weight,kernelY) tex2Dproj(_GrabTexture_1, UNITY_PROJ_COORD(float4(i.uv.x, i.uv.y + _GrabTexture_1_TexelSize.y * kernelY * _BlurSize * 1.61 * i.uv.w, i.uv.z, i.uv.w))) * weight
               
                pixelCol += ADDPIXEL(0.05, 4.0);
                pixelCol += ADDPIXEL(0.09, 3.0);
                pixelCol += ADDPIXEL(0.12, 2.0);
                pixelCol += ADDPIXEL(0.15, 1.0);
                pixelCol += ADDPIXEL(0.18, 0.0);
                pixelCol += ADDPIXEL(0.15, -1.0);
                pixelCol += ADDPIXEL(0.12, -2.0);
                pixelCol += ADDPIXEL(0.09, -3.0);
                pixelCol += ADDPIXEL(0.05, -4.0);
                return pixelCol + fixed4(0.1, 0.1, 0.1, 0);
            }
            ENDCG
        }
        
        // Grab the screen behind the object into _BackgroundTexture
        GrabPass
        {
            "_GrabTexture_2"
        }
        
        // Horizontal Blur
        Pass
        {
            //CULL OFF
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma fragmentoption ARB_precision_hint_fastest
            #include "UnityCG.cginc"

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                //float2 uv[5]: TEXCOORD0;
            };
            
            sampler2D _GrabTexture_2;
            half4 _GrabTexture_2_TexelSize;
            float _BlurSize;

            v2f vert(appdata_base v) {
                v2f o;
                // use UnityObjectToClipPos from UnityCG.cginc to calculate 
                // the clip-space of the vertex
                o.pos = UnityObjectToClipPos(v.vertex);
                // use ComputeGrabScreenPos function from UnityCG.cginc
                // to get the correct texture coordinate
                o.uv = ComputeGrabScreenPos(o.pos);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                fixed4 pixelCol = fixed4(0, 0, 0, 0);
 
                #define ADDPIXEL(weight,kernelX) tex2Dproj(_GrabTexture_2, UNITY_PROJ_COORD(float4(i.uv.x + _GrabTexture_2_TexelSize.y * kernelX * _BlurSize * 1.61 * i.uv.w, i.uv.y, i.uv.z, i.uv.w))) * weight
               
                pixelCol += ADDPIXEL(0.05, 4.0);
                pixelCol += ADDPIXEL(0.09, 3.0);
                pixelCol += ADDPIXEL(0.12, 2.0);
                pixelCol += ADDPIXEL(0.15, 1.0);
                pixelCol += ADDPIXEL(0.18, 0.0);
                pixelCol += ADDPIXEL(0.15, -1.0);
                pixelCol += ADDPIXEL(0.12, -2.0);
                pixelCol += ADDPIXEL(0.09, -3.0);
                pixelCol += ADDPIXEL(0.05, -4.0);
                return pixelCol;
            }
            ENDCG
        }

    }
}
