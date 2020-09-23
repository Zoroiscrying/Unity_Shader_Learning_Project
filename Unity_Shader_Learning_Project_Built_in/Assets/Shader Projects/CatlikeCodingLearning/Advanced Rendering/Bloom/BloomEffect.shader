Shader "Zoroiscrying/AdvancedRendering/BloomEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    
    CGINCLUDE

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
        };

        v2f vert (appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.uv;
            return o;
        }

        sampler2D _MainTex, _SourceTex;;
        float4 _MainTex_TexelSize;
		half4 _Filter;
		half _Intensity;
    	//half _Threshold, _SoftThreshold;;

        half3 Sample (float2 uv) {
			return tex2D(_MainTex, uv).rgb;
		}

    	half3 Prefilter (half3 c) {
			half brightness = max(c.r, max(c.g, c.b));
        	
        	//half knee = _Threshold * _SoftThreshold;
			half soft = brightness - _Filter.y;
			soft = clamp(soft, 0, 2 * _Filter.z);
			soft = soft * soft * _Filter.w;
			half contribution = max(soft, brightness - _Filter.x);
			contribution /= max(brightness, 0.00001);
			return c * contribution;
		}

        half3 SampleBox (float2 uv, float delta) {
			float4 o = _MainTex_TexelSize.xyxy * float2(-delta, delta).xxyy;
			half3 s =
				Sample(uv + o.xy) + Sample(uv + o.zy) +
				Sample(uv + o.xw) + Sample(uv + o.zw);
			return s * 0.25f;
		}

    ENDCG
    
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always
    	
    	//down sampling profilter
    	Pass {
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				half4 frag (v2f i) : SV_Target {
					return half4(Prefilter(SampleBox(i.uv, 1)), 1);
				}
			ENDCG
		}

        //down sampling
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            fixed4 frag (v2f i) : SV_Target
            {
                return half4(SampleBox(i.uv, 1), 1);
            }
            ENDCG
        }
        
        //up sampling
        Pass
        {
            Blend One One
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            fixed4 frag (v2f i) : SV_Target
            {
                return half4(SampleBox(i.uv, .5), 1);
            }
            ENDCG
        }
        
        Pass { // 3
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				half4 frag (v2f i) : SV_Target {
					half4 c = tex2D(_SourceTex, i.uv);
					c.rgb +=_Intensity * SampleBox(i.uv, 0.5);
					return c;
				}
			ENDCG
		}
    	
    	Pass { // 4 debug sampling
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				half4 frag (v2f i) : SV_Target {
					return half4(_Intensity *SampleBox(i.uv, 0.5), 1);
				}
			ENDCG
		}
    }
}
