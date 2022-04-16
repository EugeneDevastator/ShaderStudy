Shader "Unlit/PerlinNoise_nongrid"
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
            static const float2 CELL_SIZE =float2(20,40);
            
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
            inline float2 point2cell(float2 pointv,float2 cellsize){
                float2 pt = pointv*pointv*float2(1,2);
                float2 gridcell= floor(pt*cellsize)/cellsize;
                return gridcell;
            }
            inline float2 voffset(float2 offset,float2 cellsize){
                return offset/cellsize;
            }
            /*
            inline float getDistanceTocell(float2 pointv){
                return distance(point2cell(pointv),pointv)*CELL_SIZE;
            }*/

            float perlinpoint(float2 pointv,float2 offset, float2 cellsize){
                float2 cellpos=point2cell(pointv+voffset(offset,cellsize),cellsize);
                float2 gradvec=getGradVector(cellpos);
                //distance from visual point to cell point
                float2 distVec=(cellpos-pointv)*cellsize;
                float resdot=dot(gradvec,distVec);
                return resdot;
            }
            float fade(float t){
                //sinus approximation for fucking opacity value!
                return 6 * pow(t,5) - 15 * pow(t,4) + 10 * pow(t,3);
            }
            
            float fade_0(float t){
                //faster sinus approximation for fucking opacity value!
                return 3 * pow(t,2) - 2 * pow(t,3);
            }
            
            float perlincell (float2 pointval,float2 cellsize){
                float2 pointdir= (pointval-point2cell(pointval,cellsize))*cellsize;

                float up =   lerp(perlinpoint(pointval,float2(0,0),cellsize),perlinpoint(pointval,float2(1,0),cellsize),fade(pointdir.x));
                float down = lerp(perlinpoint(pointval,float2(0,1),cellsize),perlinpoint(pointval,float2(1,1),cellsize),fade(pointdir.x));
                float perl =lerp(up,down,fade(pointdir.y));
                return (perl+0.5);
            }
            fixed4 frag (fragIn i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                //return float4(getGradVector(point2cell(i.uv)),-getGradVector(point2cell(i.uv)).y,1);
                //return float4(point2cell(i.uv,float2(8,8)),0,1);
                return perlincell(i.uv,float2(8,8));
                //return (perlincell(i.uv,float2(3,3))+perlincell(i.uv,float2(16,16))+perlincell(i.uv,float2(32,32)))/3;
            }
            ENDCG
        }
    }
}
