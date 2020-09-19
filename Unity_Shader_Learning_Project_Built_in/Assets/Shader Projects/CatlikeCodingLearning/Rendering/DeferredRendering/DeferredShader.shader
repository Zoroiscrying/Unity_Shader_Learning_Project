Shader "Zoroiscrying/RenderingLearning/DeferredShader"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" {}
        _Tint("Tint", Color) = (1,1,1)
        //[NoScaleOffset]_HeightMap ("Heights", 2D) = "gray" {}
        [NoScaleOffset] _NormalMap ("Normals", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Float) = 1
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
        [NoScaleOffset] _MetallicMap ("Metallic", 2D) = "white" {}
        [Gamma]_Metallic ("Metallic", Range(0, 1)) = 0
        _DetailTex ("Detail Texture", 2D) = "gray" {}
        [NoScaleOffset] _DetailNormalMap ("Detail Normals", 2D) = "bump" {}
		_DetailBumpScale ("Detail Bump Scale", Float) = 1
        //_SpecularTint ("Specular", Color) = (0.5, 0.5, 0.5)
        [NoScaleOffset] _EmissionMap ("Emission", 2D) = "black" {}
		_Emission ("Emission", Color) = (0, 0, 0)
        [NoScaleOffset] _OcclusionMap ("Occlusion", 2D) = "white" {}
		_OcclusionStrength("Occlusion Strength", Range(0, 1)) = 1
		[NoScaleOffset] _DetailMask ("Detail Mask", 2D) = "white" {}
    }
    SubShader
    {

        Pass
        {
           Tags{"LightMode" = "Deferred"}
           
           
			CGPROGRAM

			#pragma target 3.0
			#pragma exclude_renderers nomrt

			#pragma shader_feature _ _RENDERING_CUTOUT
			#pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
			#pragma shader_feature _NORMAL_MAP
			#pragma shader_feature _OCCLUSION_MAP
			#pragma shader_feature _EMISSION_MAP
			#pragma shader_feature _DETAIL_MASK
			#pragma shader_feature _DETAIL_ALBEDO_MAP
			#pragma shader_feature _DETAIL_NORMAL_MAP
			
			#pragma multi_compile_prepassfinal
			//#pragma multi_compile _ UNITY_HDR_ON
			//#pragma multi_compile _ LIGHTMAP_ON
			
			#define DEFERRED_PASS
			
			#pragma multi_compile_instancing
			
			#include "../MultipleLights/MyLighting.cginc"

			#pragma vertex vert
			#pragma fragment Frag_Full
			
			ENDCG
        }
        
        Pass {
			Tags {
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM

			#pragma target 3.0

            #pragma multi_compile_shadowcaster
            
			#pragma vertex MyShadowVertexProgram
			#pragma fragment MyShadowFragmentProgram

			#include "../MultipleLights/MyShadow.cginc"

			ENDCG
		}
    }
    CustomEditor "MyLightingShaderGui"
}
