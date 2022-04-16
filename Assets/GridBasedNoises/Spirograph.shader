Shader "Unlit/Spirograph"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            struct vertIn
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct fragIn
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            fragIn vert (vertIn v)
            {
                fragIn o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (fragIn i) : SV_Target
            {
                float pi = 3.14159265358979323846;
                float k=8.7;
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                float2 cUv=i.uv-0.5;
                // apply fog
                float r0=0.3;
                float r1=0.2;
                float rr0=abs(length(cUv));
                float ra0=atan2(cUv.y,cUv.x)+pi;//
                //return step(abs(rr0-r0),0.001);
                float xdes=r0*cos(ra0); //desired x pos of 1st level func.
                float ydes=r0*sin(ra0);
                float ra1=ra0*k;
                float reqx=xdes+r1*cos(ra1);
                float reqy=ydes+r1*sin(ra1);
                float2 reqpt=float2(reqx,reqy);
                
                return distance(cUv,reqpt);

    //               x=r0*cos(a0)+r1*cos(a0*k);

                return float4(rr0,ra0/(2*pi),0,1);



                return col;
            }
            ENDCG
        }
    }
}
