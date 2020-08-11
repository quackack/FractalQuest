// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/FractalShader"
{
    Properties
    {
        _Scale("Scale", Float) = 2
        _Offset("Offset", Float) = -2
        _BallSize("Ball Size", Float) = 1
        //_FractalIterations("Fractal Iterations", Int) = 7
		_VertexMarchIterations("Vertex March Iterations", Int) = 12
        _FragmentMarchIterations("Pixel March Iterations", Int) = 8
        _ContactThreshold("Contact Threshold", Range(0, 1)) = 0.01
		_VertexGap("Vertex Gap", Float) = 2
    }

        SubShader
    {
        Tags{ "Queue" = "Background" }

        ZWrite On
        //ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            //uniform int _FractalIterations;
			#define _FractalIterations 8
			uniform int _VertexMarchIterations;
            uniform int _FragmentMarchIterations;
			//#define _VertexMarchIterations 10
			//#define _FragmentMarchIterations 8
			uniform float _VertexGap;
            uniform float _ContactThreshold;
            uniform float _Scale;
            uniform float _Offset;
            uniform float _BallSize;

            struct v2f
            {
                float4 position : POSITION;
				float3 worldPos : TEXCOORD0;
                float starting_distance : TEXCOORD1;
            };

            struct fragOut
            {
                float3 color : COLOR;
                float depth : DEPTH;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.vertex);
                float3 geometryPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldPos = geometryPos;
				float3 viewDir = normalize(-UnityWorldSpaceViewDir(geometryPos));

				float distanceScaler = pow(_Scale, -_FractalIterations);
				float3 current_pos = _WorldSpaceCameraPos;
				float total_distance = 0;
				for (int i = 0; i < _VertexMarchIterations; i++) {
					float3 fractalPos = current_pos;
					for (int j = 0; j < _FractalIterations; j++) {
						fractalPos = abs(mad(_Scale, fractalPos, _Offset));
					}
					float distance = max(0, max(0, length(fractalPos) - _BallSize) * distanceScaler - total_distance * _VertexGap);
					total_distance += distance;
					current_pos = _WorldSpaceCameraPos + viewDir * total_distance;
				}

				o.starting_distance = total_distance;

                return o;
            }

            fragOut frag(in v2f i)
            {
				float3 viewDir = normalize(-UnityWorldSpaceViewDir(i.worldPos));
                float3 current_pos = _WorldSpaceCameraPos + viewDir * i.starting_distance;
                float distance = 0;
                float distanceScaler = pow(_Scale, -_FractalIterations);
				float threshholdRec = 1 / _ContactThreshold;
                
                float contactTime = _FragmentMarchIterations;
                for (int i = 0; i < _FragmentMarchIterations; i++) {
                    float3 fractalPos = current_pos;
                    for (int j = 0; j < _FractalIterations; j++) {
                        fractalPos = abs(mad(_Scale, fractalPos, _Offset));
                    }
                    distance = max(0, length(fractalPos) - _BallSize) * distanceScaler;
                    contactTime = min(contactTime, i + distance * threshholdRec);
                    current_pos = current_pos + viewDir * distance;
                }

                fragOut o;
                if (contactTime < _FragmentMarchIterations) {
					float4 clipPos = UnityWorldToClipPos(current_pos);
					#if UNITY_REVERSED_Z
						float d = clipPos.w;
					#else
						float d = clipPos.z;
					#endif

					d = (1 - d * _ZBufferParams.w) / (d * _ZBufferParams.z);
					o.depth = d;
					o.color = (1 - contactTime / _FragmentMarchIterations);
                }
                else {
					o.color = 0;//float4(viewDir, 1);
					#if UNITY_REVERSED_Z
						o.depth = 0;
					#else
						o.depth = 1;
					#endif
                }
                return o;
            }
            ENDCG
        }
    }
}
