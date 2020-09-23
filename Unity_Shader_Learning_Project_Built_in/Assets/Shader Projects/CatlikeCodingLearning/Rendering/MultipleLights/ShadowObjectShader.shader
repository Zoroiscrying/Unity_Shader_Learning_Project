Shader "Zoroiscrying/RenderingLearning/ShadowObject"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Tint("Tint", Color) = (1,1,1)
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
        [Gamma]_Metallic ("Metallic", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags {
				"LightMode" = "ForwardBase"
			}
        
            CGPROGRAM
            #pragma target 3.0
            //enable vertex lights -- cheap method to render multiple lights in the scene
            #pragma multi_compile _ VERTEXLIGHT_ON
            #pragma multi_compile _ SHADOWS_SCREEN
            #define FORWARD_BASE_PASS
            
            #pragma vertex vert
            #pragma fragment frag
            
            #include "MyLighting_simple.cginc"
            ENDCG
        }
        
        //second light calculation
        Pass {
        
			Tags {
				"LightMode" = "ForwardAdd"
			}
			
			//additive blending (default One Zero, overriding pixel colors before)
			Blend One One
			//Disable depth buffer writing, because this is the same pixel
			ZWrite Off

			CGPROGRAM

			#pragma target 3.0
            
			#pragma vertex vert
			#pragma fragment frag
			
			//tell the UNITY_LIGHT_ATTENUATION that we are dealing with a point light
			//#define POINT
			
			//#pragma multi_compile DIRECTIONAL DIRECTIONAL_COOKIE POINT POINT_COOKIE SPOT
			#pragma multi_compile_fwdadd_fullshadows
			
			#include "MyLighting_simple.cginc"

			ENDCG
		}
		
        Pass {
			Tags {
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM

			#pragma target 3.0

            #pragma multi_compile_shadowcaster
            
			#pragma vertex vert
			#pragma fragment MyShadowFragmentProgram

			#include "MyShadow.cginc"

			ENDCG
		}
    }
}
