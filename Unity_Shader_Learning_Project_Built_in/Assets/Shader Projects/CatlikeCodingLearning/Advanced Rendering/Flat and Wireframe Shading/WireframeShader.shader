Shader "Zoroiscrying/AdvancedRendering/WireframeShader"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" {}
        _Color ("Tint", Color) = (1, 1, 1, 1)
        //_Tint("Tint", Color) = (1,1,1,1)
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
        [NoScaleOffset] _ParallaxMap ("Parallax", 2D) = "black" {}
		_ParallaxStrength ("Parallax Strength", Range(0, 0.1)) = 0
        [NoScaleOffset] _OcclusionMap ("Occlusion", 2D) = "white" {}
		_OcclusionStrength("Occlusion Strength", Range(0, 1)) = 1
		[NoScaleOffset] _DetailMask ("Detail Mask", 2D) = "white" {}
		_Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
		[HideInInspector] _ZWrite ("_ZWrite", Float) = 1
        [HideInInspector] _SrcBlend ("_SrcBlend", Float) = 1
		[HideInInspector] _DstBlend ("_DstBlend", Float) = 0
        _WireframeColor ("Wireframe Color", Color) = (0, 0, 0)
		_WireframeSmoothing ("Wireframe Smoothing", Range(0, 10)) = 1
		_WireframeThickness ("Wireframe Thickness", Range(0, 10)) = 1
    }
    SubShader
    {
        Tags {
            "LightMode" = "ForwardBase"
        }
        Blend [_SrcBlend] [_DstBlend]
        ZWrite [_ZWrite]

        Pass
        {
            CGPROGRAM
            #pragma target 4.0
            //detail maps
            #pragma shader_feature _DETAIL_ALBEDO_MAP
			#pragma shader_feature _DETAIL_NORMAL_MAP
			//normal maps
            #pragma shader_feature _NORMAL_MAP
            //metaillic maps
            #pragma shader_feature _METALLIC_MAP
            //smothness from albedo or metallic
            #pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
            //parallax maps
            #pragma shader_feature _PARALLAX_MAP
            #define PARALLAX_BIAS 0
            //	#define PARALLAX_OFFSET_LIMITING
            #define PARALLAX_RAYMARCHING_STEPS 10
            //#define PARALLAX_RAYMARCHING_INTERPOLATE
            #define PARALLAX_RAYMARCHING_SEARCH_STEPS 4
            #define PARALLAX_FUNCTION ParallaxRaymarching
            #define PARALLAX_SUPPORT_SCALED_DYNAMIC_BATCHING
            //occlusion maps
            #pragma shader_feature _OCCLUSION_MAP
            //emission maps
            #pragma shader_feature _EMISSION_MAP
            //detail maps
            #pragma shader_feature _DETAIL_MASK
            //calculate shadows
            #pragma multi_compile_fwdbase
            //#pragma multi_compile _ SHADOWS_SCREEN
            
            //calculate vertex light or static light mapping
            //#pragma multi_compile _ VERTEXLIGHT_ON LIGHTMAP_ON
            //Forward base pass
            #define FORWARD_BASE_PASS
            #pragma multi_compile_instancing
            //lod instancing
            #pragma instancing_options lodfade
            //rendering cut_out?
            #pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
            
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            
            //#define FOG_DISTANCE
            
            
            //calculate fogs
            #pragma multi_compile_fog
            
            #include "MyFlatWireframe.cginc"
            
            #pragma vertex vert
            #pragma geometry MyGeometryProgram
            #pragma fragment Frag_Full
            
            
            
            ENDCG
        }
    }
    CustomEditor "MyLightingShaderGui"
}
