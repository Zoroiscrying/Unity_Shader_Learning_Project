// Upgrade NOTE: replaced 'texRECTproj' with 'tex2Dproj'

// Upgrade NOTE: replaced 'glstate.matrix.mvp' with 'UNITY_MATRIX_MVP'

Shader "Zoroiscrying/GrabTexture/GrabPassRefraction"
{
    SubShader
    {
        // Draw ourselves after all opaque geometry
        Tags { "Queue" = "Transparent" "RenderType"="Transparent" }
        LOD 100

        // Grab the screen behind the object into _BackgroundTexture
        GrabPass
        {
            "_GrabTexture"
        }

        // Render the object with the texture generated above, and invert the colors
        Pass
        {
            CULL OFF
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct v2f
            {
                float4 grabPos : TEXCOORD0;
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD1;
                float3 normal:TEXCOORD2;
            };

            v2f vert(appdata_base v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.grabPos = ComputeGrabScreenPos(o.pos);
                o.uv = TRANSFORM_UV(1);
                o.normal = mul((float3x3)UNITY_MATRIX_MVP, v.normal);
                return o;
            }

            sampler2D _GrabTexture;

            half4 frag(v2f i) : SV_Target
            {
                i.normal = normalize(i.normal);
                
                // Calculate refracted vector based on the surface normal.
                // This is only an approximation because we don't know the
                // thickness of the object. So just use anything that looks
                // "good enough"
                
                half3 refracted = i.normal * abs(i.normal);
                //half3 refracted = refract( i.normal, half3(0,0,1), 1.333 );
                
                // perturb coordinates of the grabbed image
                i.grabPos.xy = refracted.xy * (i.grabPos.w * 0.05) + i.grabPos.xy;
                
                half4 refr = tex2Dproj( _GrabTexture, i.grabPos );
                return refr;
            }
            ENDCG
        }

    }
}
