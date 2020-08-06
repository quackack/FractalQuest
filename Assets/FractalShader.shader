// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/FractalShader"
{
    Properties
    {
        _Scale("Scale", Float) = 2
        _Offset("Offset", Float) = -2
        _BallSize("Ball Size", Float) = 1
        _FractalIterations("Fractal Iterations", Int) = 7
        _MarchIterations("March Iterations", Int) = 20
        _ContactThreshold("Contact Threshold", Range(0, 1)) = 0.01
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

            uniform int _FractalIterations;
            uniform int _MarchIterations;
            uniform float _ContactThreshold;
            uniform float _Scale;
            uniform float _Offset;
            uniform float _BallSize;

            struct v2f
            {
                float4 position : POSITION;
                float3 worldPos : TEXCOORD0;
            };

            struct fragOut
            {
                float4 color : COLOR;
                float depth : DEPTH;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fragOut frag(in v2f i)
            {
                float3 current_pos = _WorldSpaceCameraPos;
                float3 viewDir = normalize(-UnityWorldSpaceViewDir(i.worldPos));
                float distance = 0;
                float distanceScaler = pow(_Scale, -_FractalIterations);
                
                float contactTime = _MarchIterations;
                for (int i = 0; i < _MarchIterations; i++) {
                    float3 fractalPos = current_pos;
                    for (int j = 0; j < _FractalIterations; j++) {
                        fractalPos = _Scale * abs(fractalPos) + _Offset;
                    }

                    distance = max(0, sqrt(dot(fractalPos, fractalPos)) - _BallSize) * distanceScaler;
                    if (distance < _ContactThreshold) {
                        contactTime = min(contactTime, i + distance / _ContactThreshold);
                    }
                    current_pos = current_pos + viewDir * distance;
                }

                fragOut o;
                float4 clipPos = mul(UNITY_MATRIX_VP, float4(current_pos, 1));
                float d = clipPos.z;
                if (d < 50){
                    d = (1 / d - _ZBufferParams.w) / _ZBufferParams.z;

                    o.color = (1 - contactTime / _MarchIterations);
                    o.depth = d;
                }
                else {
                    o.color = float4(viewDir, 1);
                    o.depth = 1;
                }
                return o;
            }
            ENDCG
        }
    }
}
