Shader "Unlit/Heightmap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HeightMap ("heightmap", 2D) = "white" {}
        _Period ("PeriodMap", 2D) = "white" {}
        _Amplitude ("AmplitudeOfPeriod", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 color : COLOR0;
            };

            sampler2D _MainTex;
            sampler2D _HeightMap;
            sampler2D _Period;
            sampler2D _Amplitude;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;

                fixed pmono1 = frac(tex2Dlod(_Period, float4(v.vertex.xy*0.2-_Time/12,0,0)).r*4);//i.uv-_Time/12;
                fixed p = frac(1-pmono1 - _Time*10);
                fixed2 ampArg = fixed2(p,0);
                fixed4 col1 = tex2Dlod(_Amplitude,float4(ampArg,0,0))-0.5;

                fixed pmono2 = frac(tex2Dlod(_Period, float4(v.vertex.xy*0.5+_Time/14,0,0)).r*3); //i.uv*1.4+_Time/14;
                fixed p2 = frac(1-pmono2 - _Time*17.21);
                fixed2 ampArg2 = fixed2(p2,0);
                fixed4 col2 = tex2Dlod(_Amplitude,float4(ampArg2,0,0))-0.5;

                fixed textureHeightValue = col1+col2;

                //float textureHeightValue = tex2Dlod(_HeightMap, float4(v.vertex.xy, 0, 0)).r;
                v.vertex.z += textureHeightValue/40;

                o.color = textureHeightValue;//tex2Dlod(_HeightMap, float4(v.vertex.xy, 0, 0));
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
