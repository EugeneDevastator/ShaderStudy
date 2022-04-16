// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/Hightmap_Surface"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Period ("PeriodMap", 2D) = "white" {}
        _Amplitude ("AmplitudeOfPeriod", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        sampler2D _Period;
        sampler2D _Amplitude;


        fixed HeightFunction(float2 uvpos){
                fixed pmono1 = frac(tex2Dlod(_Period, float4(uvpos*0.2-_Time/12,0,0)).r*4);//i.uv-_Time/12;
                fixed p = frac(1-pmono1 - _Time*10);
                fixed2 ampArg = fixed2(p,0);
                fixed col1 = (tex2Dlod(_Amplitude,float4(ampArg,0,0))-0.5).r*1.2;

                fixed pmono2 = frac(tex2Dlod(_Period, float4(uvpos*0.5+_Time/14,0,0)).r*3); //i.uv*1.4+_Time/14;
                fixed p2 = frac(1-pmono2 - _Time*17.21);
                fixed2 ampArg2 = fixed2(p2,0);
                fixed col2 = (tex2Dlod(_Amplitude,float4(ampArg2,0,0))-0.5).r*0.5;
                return (col1+col2)/4;
        }

      void vert (inout appdata_full v) {

/*
solving in world normals - shittuuu
                float dv = 0.07;
                fixed h0 = HeightFunction(v.vertex.xy);
                fixed h1 = HeightFunction(v.vertex.xy+float2(dv,0));
                fixed h2 = HeightFunction(v.vertex.xy+float2(0,dv));

                float4 v0 = mul((unity_ObjectToWorld), v.vertex.xyz + float3(0,0,h0));
                float4 v1 = mul((unity_ObjectToWorld), v.vertex.xyz + float3(dv,0,h1));
                float4 v2 = mul((unity_ObjectToWorld), v.vertex.xyz + float3(0,dv,h2));

                float3 vnW =-cross(v2-v0,v1-v0).rbg;
                float4 vn = mul((unity_WorldToObject),vnW);
                v.normal = normalize(vn).rbg;
                //v.vertex = v.vertex+float4( v.normal,0)*0.1;
                v.vertex = mul((unity_WorldToObject),v0);
*/
//solution is from here https://www.ronja-tutorials.com/2018/06/16/Wobble-Displacement.html
// take existing normal and tangent. find bitangent. calculate partial derivatives using tangent and bitan.
// generate new tangent and bitangent using these derivatives
// and we are operating in local space whole time!

                float dv = 0.1;
                float4 modifiedPos = v.vertex;

                float3 posPlusTangent = v.vertex + v.tangent * dv;
                float3 bitangent = cross(v.normal, v.tangent);
                float3 posPlusBitangent = v.vertex + bitangent * dv;

                fixed h0 = HeightFunction(v.vertex.xy);
                fixed h1 = HeightFunction(posPlusTangent.xy);
                fixed h2 = HeightFunction(posPlusBitangent.xy);

                modifiedPos.z+=h0;
                posPlusTangent.z+=h1;
                posPlusBitangent.z+=h2;

                float3 modifiedTangent = posPlusTangent - modifiedPos;
                float3 modifiedBitangent = posPlusBitangent - modifiedPos;
                float3 modifiedNormal = cross(modifiedTangent, modifiedBitangent);
                v.normal = normalize(modifiedNormal);
                v.vertex = modifiedPos;

                //normal recalculation from world here: https://www.youtube.com/watch?v=1G37-Yav2ZM&ab_channel=AdrianMyers
      }

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
