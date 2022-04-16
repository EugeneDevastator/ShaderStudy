Shader "Unlit/Noise"
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
            static const float CELL_SIZE =20;
            float random(float2 st){
                return frac(sin(dot(st.xy,float2(12.9898,78.233)))*43758.5453123);
            }
            float2 random2(float2 st){
                return float2( frac(sin(dot(st.xy,float2(12.9898,78.233)))*43758.5453123),frac(sin(dot(st.yx+float2(0.7,0.6),float2(12.9898,78.233)))*43758.5453123));
            }

            inline float2 getGradVector(float2 cell){
                return (random2(cell)-0.5)*2;
                //ensure it is in -1,1
            }
            //inline float getCellDist
            inline float2 point2cell(float2 pointv){
                return floor(pointv*CELL_SIZE)/CELL_SIZE;
            }
            inline float2 voffset(float2 offset){
                return offset/CELL_SIZE;
            }
            inline float getDistanceTocell(float2 pointv){
                return distance(point2cell(pointv),pointv)*CELL_SIZE;
            }

            float perlinpoint(float2 pointv,float2 offset){
                float2 cellpos=point2cell(pointv+voffset(offset));
                float2 gradvec=getGradVector(cellpos);
                //distance from visual point to cell point
                float2 distVec=(cellpos-pointv)*CELL_SIZE;
                float resdot=dot(gradvec,distVec);
                return resdot;
            }
            float fade_1(float t){
                //sinus approximation for fucking opacity value!
                return 6 * pow(t,5) - 15 * pow(t,4) + 10 * pow(t,3);
            }
            
            float fade(float t){
                //faster sinus approximation for fucking opacity value!
                return 3 * pow(t,2) - 2 * pow(t,3);
            }

            float perlin (float2 pointval){
                float2 pointdir= (pointval-point2cell(pointval))*CELL_SIZE;

                float up =   lerp(perlinpoint(pointval,float2(0,0)),perlinpoint(pointval,float2(1,0)),fade(pointdir.x));
                float down = lerp(perlinpoint(pointval,float2(0,1)),perlinpoint(pointval,float2(1,1)),fade(pointdir.x));
                float perl =lerp(up,down,fade(pointdir.y));
                return (perl+0.5);
            }
            fixed4 frag (fragIn i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                //return float4(getGradVector(point2cell(i.uv)),-getGradVector(point2cell(i.uv)).y,1);
                return perlin(i.uv);
            }
            ENDCG
        }
    }
}
