#if !defined(TESSELLATION_INCLUDED)
#define TESSELLATION_INCLUDED
//To determine how to subdivide a triangle, 
//the GPU uses four tessellation factors. 
//Each edge of the triangle patch gets a factor. 
//There's also a factor for the inside of the triangle. 
//The three edge vectors have to be passed along as a float array
//with the SV_TessFactor semantic. 
//The inside factor uses the SV_InsideTessFactor semantic.


struct TessellationFactors {
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};

struct TessellationControlPoint {
	float4 vertex : INTERNALTESSPOS;
	float3 normal : NORMAL;
	#if TESSELLATION_TANGENT
		float4 tangent : TANGENT;
	#endif
	float2 uv : TEXCOORD0;
	#if TESSELLATION_UV1
		float2 uv1 : TEXCOORD1;
	#endif
	#if TESSELLATION_UV2
		float2 uv2 : TEXCOORD2;
	#endif
};

float _TessellationUniform;
float _TessellationEdgeLength;

float TessellationEdgeFactor (
	float3 p0, float3 p1
) {
    #if defined(_TESSELLATION_EDGE)
		//float4 p0 = UnityObjectToClipPos(cp0.vertex);
		//float4 p1 = UnityObjectToClipPos(cp1.vertex);
		//float edgeLength = distance(p0.xy / p0.w, p1.xy / p1.w);
		//return edgeLength * _ScreenParams.y / _TessellationEdgeLength;
		
		//float3 p0 = mul(unity_ObjectToWorld, float4(cp0.vertex.xyz, 1)).xyz;
		//float3 p1 = mul(unity_ObjectToWorld, float4(cp1.vertex.xyz, 1)).xyz;
		float edgeLength = distance(p0, p1);

		float3 edgeCenter = (p0 + p1) * 0.5;
		float viewDistance = distance(edgeCenter, _WorldSpaceCameraPos);

		return edgeLength * _ScreenParams.y / (_TessellationEdgeLength * viewDistance);
	#else
		return _TessellationUniform;
	#endif
}

bool TriangleIsBelowClipPlane (float3 p0, float3 p1, float3 p2, int planeIndex, float bias) {
    //float4 plane = float4(1, 0, 0, 0);
	//float4 plane = unity_CameraWorldClipPlanes[0];
	float4 plane = unity_CameraWorldClipPlanes[planeIndex];
	return
		dot(float4(p0, 1), plane) < bias &&
		dot(float4(p1, 1), plane) < bias &&
		dot(float4(p2, 1), plane) < bias ;
}

bool TriangleIsCulled (float3 p0, float3 p1, float3 p2, float bias) {
	return TriangleIsBelowClipPlane(p0, p1, p2, 0, bias) ||
		TriangleIsBelowClipPlane(p0, p1, p2, 1, bias) ||
		TriangleIsBelowClipPlane(p0, p1, p2, 2, bias) ||
		TriangleIsBelowClipPlane(p0, p1, p2, 3, bias);
}

TessellationFactors MyPatchConstantFunction (InputPatch<TessellationControlPoint, 3> patch) {
	TessellationFactors f;
    //f.edge[0] = TessellationEdgeFactor(patch[1], patch[2]);
    //f.edge[1] = TessellationEdgeFactor(patch[2], patch[0]);
    //f.edge[2] = TessellationEdgeFactor(patch[0], patch[1]);
	float3 p0 = mul(unity_ObjectToWorld, patch[0].vertex).xyz;
	float3 p1 = mul(unity_ObjectToWorld, patch[1].vertex).xyz;
	float3 p2 = mul(unity_ObjectToWorld, patch[2].vertex).xyz;
    float bias = 0;
    #if VERTEX_DISPLACEMENT
		bias = -0.5 * _DisplacementStrength;
	#endif
    if (TriangleIsCulled(p0, p1, p2, bias)) {
		f.edge[0] = f.edge[1] = f.edge[2] = f.inside = 0;
	}
	else {
    f.edge[0] = TessellationEdgeFactor(p1, p2);
    f.edge[1] = TessellationEdgeFactor(p2, p0);
    f.edge[2] = TessellationEdgeFactor(p0, p1);
	f.inside =
		(TessellationEdgeFactor(p1, p2) +
		TessellationEdgeFactor(p2, p0) +
		TessellationEdgeFactor(p0, p1)) * (1 / 3.0);
    }
	return f;
}

//The job of the hull program is 
//to pass the required vertex data to the tessellation stage. 
[UNITY_domain("tri")] // working with triangles
[UNITY_outputcontrolpoints(3)] // outputting three control points per patch
[UNITY_outputtopology("triangle_cw")] //all of the triangles' topology should be clockwise
[UNITY_partitioning("fractional_odd")]
//[UNITY_partitioning("integer")] // patitioning methods
[UNITY_patchconstantfunc("MyPatchConstantFunction")] //how many parts the patch should be cut
TessellationControlPoint  MyHullProgram (
                    InputPatch<TessellationControlPoint , 3> patch,
	                uint id : SV_OutputControlPointID
) {
    return patch[id];
    
}

TessellationControlPoint  MyTessellationVertexProgram (appdata v) {
    TessellationControlPoint p;
	p.vertex = v.vertex;
	p.normal = v.normal;
	#if TESSELLATION_TANGENT
		p.tangent = v.tangent;
	#endif
	p.uv = v.uv;
	#if TESSELLATION_UV1
		p.uv1 = v.uv1;
	#endif
	#if TESSELLATION_UV2
		p.uv2 = v.uv2;
	#endif
	return p;
}

[UNITY_domain("tri")]
v2f MyDomainProgram (	
    TessellationFactors factors,
	OutputPatch<TessellationControlPoint, 3> patch,
	float3 barycentricCoordinates : SV_DomainLocation
) {
    appdata data;
	#define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) data.fieldName = \
		patch[0].fieldName * barycentricCoordinates.x + \
		patch[1].fieldName * barycentricCoordinates.y + \
		patch[2].fieldName * barycentricCoordinates.z;

	MY_DOMAIN_PROGRAM_INTERPOLATE(vertex)
    MY_DOMAIN_PROGRAM_INTERPOLATE(normal)
	#if TESSELLATION_TANGENT
		MY_DOMAIN_PROGRAM_INTERPOLATE(tangent)
	#endif
	MY_DOMAIN_PROGRAM_INTERPOLATE(uv)
	#if TESSELLATION_UV1
		MY_DOMAIN_PROGRAM_INTERPOLATE(uv1)
	#endif
	#if TESSELLATION_UV2
		MY_DOMAIN_PROGRAM_INTERPOLATE(uv2)
	#endif
	
	return vert(data);
}



#endif