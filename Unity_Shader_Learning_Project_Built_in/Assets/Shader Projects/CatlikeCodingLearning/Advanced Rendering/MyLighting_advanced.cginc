// Upgrade NOTE: upgraded instancing buffer 'InstanceProperties' to new syntax.

// Upgrade NOTE: replaced 'UNITY_PASS_TEXCUBE(unity_SpecCube1)' with 'UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0)'


//#include "UnityCG.cginc"
#if !defined(MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED

#include "MyLightingInput.cginc"

#if !defined(ALBEDO_FUNCTION)
	#define ALBEDO_FUNCTION GetAlbedo
#endif

float4 ApplyFog (float4 color, v2f i) {
    // x = density / sqrt(ln(2)), useful for Exp2 mode
    // y = density / ln(2), useful for Exp mode
    // z = -1/(end-start), useful for Linear mode
    // w = end/(end-start), useful for Linear mode
    //float4 unity_FogParams;
    #if FOG_ON
        float3 fogColor = 0;
        #if defined(FORWARD_BASE_PASS)
            fogColor = unity_FogColor.rgb;
        #endif
        float viewDistance = length(_WorldSpaceCameraPos - i.worldPos);
        #if FOG_DEPTH
            viewDistance = UNITY_Z_0_FAR_FROM_CLIPSPACE(i.worldPos.w);
        #endif
        UNITY_CALC_FOG_FACTOR_RAW(viewDistance);
        color.rgb = lerp(fogColor, color.rgb, saturate(unityFogFactor));
    #endif
    return color;
}


float3 CreateBinormal (float3 normal, float3 tangent, float binormalSign) {
    return cross(normal, tangent.xyz) *
        (binormalSign * unity_WorldTransformParams.w);
}


void ComputeVertexLightColor (inout v2f i) {
    #if defined(VERTEXLIGHT_ON)
    ////the position of the first light (x component)
    //float3 lightPos = float3(
    //    unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x
    //);
    //float3 lightVec = lightPos - i.worldPos;
    //float3 lightDir = normalize(lightVec);
    //float ndotl = DotClamped(i.normal, lightDir);
    //float attenuation = 1 / (1 + dot(lightVec, lightVec * unity_4LightAtten0.x));
    //i.vertexLightColor = unity_LightColor[0].rgb * ndotl * attenuation;
    
    //compute all the vertex lights
    i.vertexLightColor = Shade4PointLights(
        unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
        unity_LightColor[0].rgb, unity_LightColor[1].rgb,
        unity_LightColor[2].rgb, unity_LightColor[3].rgb,
        unity_4LightAtten0, i.worldPos, i.normal
    );
    #endif
}


v2f vert (appdata v)
{
    v2f o;
    UNITY_INITIALIZE_OUTPUT(v2f, o);
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
    o.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);
    
    #if VERTEX_DISPLACEMENT
		float displacement = tex2Dlod(_DisplacementMap, float4(o.uv.xy, 0, 0)).g;
	    displacement = (displacement - 0.5) * _DisplacementStrength;
	    //v.vertex.y += displacement;
	    v.vertex.xyz += v.normal * displacement;
	#endif
    
    o.pos = UnityObjectToClipPos(v.vertex);
    //o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
    o.normal = UnityObjectToWorldNormal(v.normal);
    
    o.worldPos.xyz = mul(unity_ObjectToWorld, v.vertex);
    #if FOG_DEPTH
        o.worldPos.w = o.pos.z;
    #endif
    
    #if defined(BINORMAL_PER_FRAGMENT)
        o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
    #else
        o.tangent = UnityObjectToWorldDir(v.tangent.xyz);
        o.binormal = CreateBinormal(o.normal, o.tangent, v.tangent.w);
    #endif
   
    
    #if defined(LIGHTMAP_ON) || ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS
        o.lightmapUV = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
    #endif
    
    #if defined(DYNAMICLIGHTMAP_ON)
        o.dynamicLightmapUV =
            v.uv2 * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
    #endif
    //#if defined(SHADOWS_SCREEN)
    //    o.shadowCoordinates = ComputeScreenPos(o.vertex);
    //#endif
    UNITY_TRANSFER_SHADOW(o, v.uv1)
    ComputeVertexLightColor(o);
    
    #if defined (_PARALLAX_MAP)
        #if defined(PARALLAX_SUPPORT_SCALED_DYNAMIC_BATCHING)
			v.tangent.xyz = normalize(v.tangent.xyz);
			v.normal = normalize(v.normal);
		#endif
		float3x3 objectToTangent = float3x3(
			v.tangent.xyz,
			cross(v.normal, v.tangent.xyz) * v.tangent.w,
			v.normal
		);
		o.tangentViewDir = mul(objectToTangent, ObjSpaceViewDir(v.vertex));
	#endif
    
    return o;
}

float3 BoxProjection (
    float3 direction, float3 position,
    float4 cubemapPosition, float3 boxMin, float3 boxMax
) {
    #if UNITY_SPECCUBE_BOX_PROJECTION
        UNITY_BRANCH
        if (cubemapPosition.w > 0) {
            float3 factors =
                ((direction > 0 ? boxMax : boxMin) - position) / direction;
            float scalar = min(min(factors.x, factors.y), factors.z);
            direction = direction * scalar + (position - cubemapPosition);
        }
    #endif
    return direction;
}

void InitializeFragmentNormal(inout v2f i) {
	//float3 dpdx = ddx(i.worldPos);
	//float3 dpdy = ddy(i.worldPos);
	//i.normal = normalize(cross(dpdy, dpdx));
	
    float3 tangentSpaceNormal = GetTangentSpaceNormal(i);
    #if defined(BINORMAL_PER_FRAGMENT)
        float3 binormal = CreateBinormal(i.normal, i.tangent.xyz, i.tangent.w);
    #else
        float3 binormal = i.binormal;
    #endif
    
    i.normal = normalize(
        tangentSpaceNormal.x * i.tangent +
        tangentSpaceNormal.y * binormal +
        tangentSpaceNormal.z * i.normal
    );
}

void ApplySubtractiveLighting (
     v2f i, inout UnityIndirect indirectLight
) 
{
    #if SUBTRACTIVE_LIGHTING
        UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);
        attenuation = FadeShadows(i, attenuation);
        float ndotl = saturate(dot(i.normal, _WorldSpaceLightPos0.xyz));
        float3 shadowedLightEstimate =
            ndotl * (1 - attenuation) * _LightColor0.rgb;
        float3 subtractedLight = indirectLight.diffuse - shadowedLightEstimate
        subtractedLight = max(subtractedLight, unity_ShadowColor.rgb);
        subtractedLight =
            lerp(subtractedLight, indirectLight.diffuse, _LightShadowData.x);
        indirectLight.diffuse = min(subtractedLight, indirectLight.diffuse);
    #endif
}

UnityIndirect CreateIndirectLight (v2f i, float3 viewDir) {
    UnityIndirect indirectLight;
    indirectLight.diffuse = 0;
    indirectLight.specular = 0;
    #if defined(VERTEXLIGHT_ON)
        indirectLight.diffuse = i.vertexLightColor;
    #endif
    
    //calculate Spherical Harmonic Lightings and add it to the Indirect Light data
    #if defined(FORWARD_BASE_PASS) || defined(DEFERRED_PASS)
        #if defined(LIGHTMAP_ON)
            indirectLight.diffuse = DecodeLightmap(
            UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lightmapUV)
            );
            
            #if defined(DIRLIGHTMAP_COMBINED)
                float4 lightmapDirection = UNITY_SAMPLE_TEX2D_SAMPLER(
                unity_LightmapInd, unity_Lightmap, i.lightmapUV
                );
                indirectLight.diffuse = DecodeDirectionalLightmap(
                    indirectLight.diffuse, lightmapDirection, i.normal
                );
            #endif
            
            ApplySubtractiveLighting(i, indirectLight);
        #endif
        
        #if defined(DYNAMICLIGHTMAP_ON)
            float3 dynamicLightDiffuse = DecodeRealtimeLightmap(
                UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, i.dynamicLightmapUV)
            );

            #if defined(DIRLIGHTMAP_COMBINED)
                float4 dynamicLightmapDirection = UNITY_SAMPLE_TEX2D_SAMPLER(
                    unity_DynamicDirectionality, unity_DynamicLightmap,
                    i.dynamicLightmapUV
                );
                indirectLight.diffuse += DecodeDirectionalLightmap(
                    dynamicLightDiffuse, dynamicLightmapDirection, i.normal
                );
            #else
                indirectLight.diffuse += dynamicLightDiffuse;
            #endif
        #endif

        #if !defined(LIGHTMAP_ON) && !defined(DYNAMICLIGHTMAP_ON)
            #if UNITY_LIGHT_PROBE_PROXY_VOLUME
                if (unity_ProbeVolumeParams.x == 1) {
                    indirectLight.diffuse = SHEvalLinearL0L1_SampleProbeVolume(
                                            float4(i.normal, 1), i.worldPos);
                    indirectLight.diffuse = max(0, indirectLight.diffuse);
                    #if defined(UNITY_COLORSPACE_GAMMA)
                        indirectLight.diffuse =
                            LinearToGammaSpace(indirectLight.diffuse);
                    #endif
                }
                else {
                    indirectLight.diffuse +=
                        max(0, ShadeSH9(float4(i.normal, 1)));
                }
            #else
                indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
            #endif
        #endif
        
        float3 reflectionDir = reflect(-viewDir, i.normal);
        //float roughness = 1 - _Smoothness;
        //roughness *= 1.7 - 0.7 * roughness;
        //float4 envSample = UNITY_SAMPLE_TEXCUBE_LOD(
        //    unity_SpecCube0, reflectionDir, roughness * UNITY_SPECCUBE_LOD_STEPS
        //);
        Unity_GlossyEnvironmentData envData;
        envData.roughness = 1 - _Smoothness;
        //envData.reflUVW = reflectionDir;
        float interpolator = unity_SpecCube0_BoxMin.w;
        envData.reflUVW = BoxProjection(
            reflectionDir, i.worldPos,
            unity_SpecCube0_ProbePosition,
            unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
        );
        //indirectLight.specular = DecodeHDR(envSample, unity_SpecCube0_HDR);
        float3 probe0 = Unity_GlossyEnvironment(
            UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData
        );
        #if UNITY_SPECCUBE_BLENDING
            UNITY_BRANCH
            if (interpolator < 0.99999) {
                float3 probe1 = Unity_GlossyEnvironment(
                    UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0),
                    unity_SpecCube0_HDR, envData
                );
                indirectLight.specular = lerp(probe1, probe0, interpolator);
            }
            else {
                indirectLight.specular = probe0;
            }
        #else
             indirectLight.specular = probe0;
        #endif
    #endif
    
    float occlusion = GetOcclusion(i);
    indirectLight.diffuse *= occlusion;
    indirectLight.specular *= occlusion;
    #if defined(DEFERRED_PASS) && UNITY_ENABLE_REFLECTION_BUFFERS
        indirectLight.specular = 0;
    #endif
    
    return indirectLight;
}

float FadeShadows (v2f i, float attenuation) {
    #if HANDLE_SHADOWS_BLENDING_IN_GI || ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS
        // UNITY_LIGHT_ATTENUATION doesn't fade shadows for us.
        #if ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS
            attenuation = SHADOW_ATTENUATION(i);
        #endif
        float viewZ =
            dot(_WorldSpaceCameraPos - i.worldPos, UNITY_MATRIX_V[2].xyz);
        float shadowFadeDistance =
            UnityComputeShadowFadeDistance(i.worldPos, viewZ);
        float shadowFade = UnityComputeShadowFade(shadowFadeDistance);
        float bakedAttenuation =
            UnitySampleBakedOcclusion(i.lightmapUV, i.worldPos);
        attenuation = UnityMixRealtimeAndBakedShadows(
            attenuation, bakedAttenuation, shadowFade
        );
    #endif
    
    return attenuation;
}

UnityLight CreateLight (v2f i) {
    UnityLight light;
    //The _WorldSpaceLightPos0 variable contains the current light's position. 
    //But in case of a directional light, it actually holds the direction towards the light.
    
    //light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
    #if defined(DEFERRED_PASS) || SUBTRACTIVE_LIGHTING
        light.dir = float3(0, 1, 0);
        light.color = 0;
    #else
        #if defined(POINT) || defined(SPOT) || defined(POINT_COOKIE)
            light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
        #else
            light.dir = _WorldSpaceLightPos0.xyz;
        #endif
        //#if defined(SHADOWS_SCREEN)
        //    //float attenuation = tex2D(_ShadowMapTexture, i.shadowCoordinates.xy/i.shadowCoordinates.w);
        //    float attenuation = SHADOW_ATTENUATION(i);
        //    //float attenuation = 0;
        //#else
        //    UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);
        //#endif
        UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);
        attenuation = FadeShadows(i, attenuation);
        //float3 lightVec = _WorldSpaceLightPos0.xyz - i.worldPos;
        //float attenuation = 1 / (1+(dot(lightVec, lightVec)));
        //calculate the attenuation of a light using the macro below
        //Note that the macro defines the variable in the current scope. So we shouldn't declare it ourselves anymore.
        light.color = _LightColor0.rgb * attenuation;
    #endif
    //light.ndotl = DotClamped(i.normal, light.dir);
    
    return light;
}

float2 ParallaxOffset (float2 uv, float2 viewDir) {
	float height = GetParallaxHeight(uv);
	height -= 0.5;
	height *= _ParallaxStrength;
	return viewDir * height;
}

float2 ParallaxRaymarching (float2 uv, float2 viewDir) {
	#if !defined(PARALLAX_RAYMARCHING_STEPS)
		#define PARALLAX_RAYMARCHING_STEPS 10
	#endif
	float2 uvOffset = 0;
    float stepSize = 1.0 / PARALLAX_RAYMARCHING_STEPS;;
	float2 uvDelta = viewDir * (stepSize * _ParallaxStrength);
	
    float stepHeight = 1;
	float surfaceHeight = GetParallaxHeight(uv);
	
	//estimate correct position as the intersection point
    float2 prevUVOffset = uvOffset;
	float prevStepHeight = stepHeight;
	float prevSurfaceHeight = surfaceHeight;

	
	for (int i = 1; 
	    i < PARALLAX_RAYMARCHING_STEPS && stepHeight > surfaceHeight; 
	    i++) 
    {
        prevUVOffset = uvOffset;
		prevStepHeight = stepHeight;
		prevSurfaceHeight = surfaceHeight;
		
		uvOffset -= uvDelta;
		stepHeight -= stepSize;
		surfaceHeight = GetParallaxHeight(uv + uvOffset);
	}
	
    #if !defined(PARALLAX_RAYMARCHING_SEARCH_STEPS)
		#define PARALLAX_RAYMARCHING_SEARCH_STEPS 0
	#endif
	#if PARALLAX_RAYMARCHING_SEARCH_STEPS > 0
		for (int i = 0; i < PARALLAX_RAYMARCHING_SEARCH_STEPS; i++) {
            uvDelta *= 0.5;
			stepSize *= 0.5;

			if (stepHeight < surfaceHeight) {
				uvOffset += uvDelta;
				stepHeight += stepSize;
			}
			else {
				uvOffset -= uvDelta;
				stepHeight -= stepSize;
			}
			
			surfaceHeight = GetParallaxHeight(uv + uvOffset);
			
		}
	#elif defined(PARALLAX_RAYMARCHING_INTERPOLATE)
		float prevDifference = prevStepHeight - prevSurfaceHeight;
		float difference = surfaceHeight - stepHeight;
		float t = prevDifference / (prevDifference + difference);
		uvOffset = prevUVOffset - uvDelta * t;
	#endif
	
	return uvOffset;
}

void ApplyParallax (inout v2f i) {
    #if defined(_PARALLAX_MAP)
        i.tangentViewDir = normalize(i.tangentViewDir);
        #if !defined(PARALLAX_OFFSET_LIMITING)
            #if !defined(PARALLAX_BIAS)
				#define PARALLAX_BIAS 0.42
			#endif
			i.tangentViewDir.xy /= (i.tangentViewDir.z + PARALLAX_BIAS);
		#endif
		
        #if !defined(PARALLAX_FUNCTION)
			#define PARALLAX_FUNCTION ParallaxOffset
		#endif
		float2 uvOffset = PARALLAX_FUNCTION(i.uv.xy, i.tangentViewDir.xy);
		
		i.uv.xy += uvOffset;
		i.uv.zw += uvOffset * (_DetailTex_ST.xy / _MainTex_ST.xy);
	#endif
}

fixed4 frag (v2f i) : SV_Target
{
    //PBR Lighting Calculation
    InitializeFragmentNormal(i);
    float3 lightDir = _WorldSpaceLightPos0.xyz;
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

    float3 lightColor = _LightColor0.rgb;

    float3 specularTint;
    float oneMinusReflectivity;
    float3 albedo = DiffuseAndSpecularFromMetallic(
        GetAlbedo(i), GetMetallic(i), specularTint, oneMinusReflectivity
    );
    

    float4 color = UNITY_BRDF_PBS(
        GetAlbedo(i), specularTint,
        oneMinusReflectivity, GetSmoothness(i),
        i.normal, viewDir,
        CreateLight(i), CreateIndirectLight(i, viewDir)
    );
    color.rgb += GetEmission(i);
    return color;
}

FragmentOutput_Deferred Frag_Full (v2f_crossFade i) {
    UNITY_SETUP_INSTANCE_ID(i);

    #if defined(LOD_FADE_CROSSFADE)
        UnityApplyDitherCrossFade(i.vpos);
    #endif
    
    ApplyParallax(i);
    
    float alpha = GetAlpha(i);
    #if defined(_RENDERING_CUTOUT)
        clip(alpha - _Cutoff);
    #endif

    //PBR Lighting Calculation
    InitializeFragmentNormal(i);
    float3 lightDir = _WorldSpaceLightPos0.xyz;
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

    float3 lightColor = _LightColor0.rgb;

    float3 specularTint;
    float oneMinusReflectivity;
    float3 albedo = DiffuseAndSpecularFromMetallic(
        ALBEDO_FUNCTION(i), GetMetallic(i), specularTint, oneMinusReflectivity
    );
    
    #if defined(_RENDERING_TRANSPARENT)
        albedo *= alpha;
        alpha = 1 - oneMinusReflectivity + alpha * oneMinusReflectivity;
    #endif
    
    float4 color = UNITY_BRDF_PBS(
        albedo, specularTint,
        oneMinusReflectivity, GetSmoothness(i),
        i.normal, viewDir,
        CreateLight(i), CreateIndirectLight(i, viewDir)
    );
    #if defined(_RENDERING_FADE) || defined(_RENDERING_TRANSPARENT)
        color.a = alpha;
    #endif
    color.rgb += GetEmission(i);
    
    FragmentOutput_Deferred output;
    #if defined(DEFERRED_PASS)
        #if !defined(UNITY_HDR_ON)
            color.rgb = exp2(-color.rgb);
        #endif
        output.gBuffer0.rgb = albedo;
        output.gBuffer0.a = GetOcclusion(i);
        output.gBuffer1.rgb = specularTint;
        output.gBuffer1.a = GetSmoothness(i);
        output.gBuffer2 = float4(i.normal * 0.5 + 0.5, 1);
        output.gBuffer3 = color;
        #if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
            float2 shadowUV = 0;
            #if defined(LIGHTMAP_ON)
                shadowUV = i.lightmapUV;
            #endif
            output.gBuffer4 =
                UnityGetRawBakedOcclusions(shadowUV, i.worldPos.xyz);
        #endif
    #else
        output.color = ApplyFog(color, i);
    #endif
    return output;
}

#endif