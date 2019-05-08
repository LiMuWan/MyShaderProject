Shader "MyShader/TextureShader"
{
	//不受光照影响的Shader
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
		_MainTex("Texture",2D) = "white"{ }
	}
	SubShader
	{
	  Pass
	 {
	   CGPROGRAM
	   #pragma vertex vert
	   #pragma fragment frag

	   #include "UnityCG.cginc"

	   sampler2D _MainTex;
	   float4 _MainTex_ST;
	   fixed4 _Color;

	   // 顶点着色器的输入和输出结构体
	   struct a2v
	   {
		   float4 vertex:POSITION;
		   float2 uv:TEXCOORD0;
	   };

	   struct v2f
	   {
		   float2 uv:TEXCOORD0;
		   float4 vertex:SV_POSITION;
	   };

	   // 顶点着色器
	   v2f vert(a2v v)
	   {
		   v2f o;
		   o.vertex = UnityObjectToClipPos(v.vertex);
		   o.uv = TRANSFORM_TEX(v.uv, _MainTex);
		   return o;
	   }

	  // 片元着色器
	  fixed4 frag(v2f i) :SV_Target
	  {
		fixed4 col = tex2D(_MainTex,i.uv) * _Color;
		return col;
	  }
	   ENDCG
	 }
    }
}
