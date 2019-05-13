// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "MyShader/NormalMapWorldSpace"
{
	Properties
	{
		_Color("Color",Color) = (1,1,1,1)
		_MainTex("Texture", 2D) = "white" {}
		_BumpMap("Albedo(RGB)",2D) = "bump"{}
		_BumpScale("BumpScale",Float) = 1.0
		_Specular("Specular",Color) = (1,1,1,1)
		_Gloss("Gloss",Range(8.0,256)) = 20
	}
		SubShader
		{

			Pass
			{
				Tags{"LightMode" = "ForwardBase"}

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "Lighting.cginc"


				fixed4 _Color;
				sampler2D _MainTex;
				float4 _MainTex_ST;
				sampler2D _BumpMap;
				float4 _BumpMap_ST;
				float _BumpScale;
				fixed4 _Specular;
				float _Gloss;

				struct a2v
				{
					float4 vertex : POSITION;
					float3 normal: NORMAL;
					float4 tangent :TANGENT;
					float4 texcoord: TEXCOORD0;
				};

				struct v2f
				{
					float4 pos:SV_POSITION;
					float4 uv:TEXCOORD0;
					float4 Ttow0:TEXCOORD1;
					float4 Ttow1:TEXCOORD2;
					float4 Ttow2:TEXCOORD3;
				};

				v2f vert(a2v v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					//存储_MainTex的uv
					o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
					//存储凹凸纹理的uv
					o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);
					
					fixed3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
					fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
					fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

					o.Ttow0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
					o.Ttow1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
					o.Ttow2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					float3 worldPos = float3(i.Ttow0.w,i.Ttow1.w,i.Ttow2.w);

					fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				    fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

					//获取法线贴图中的纹素
					fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
					//需要将对应的纹理设置为“Normal Map”才能正确解出来
					fixed3 bump = UnpackNormal(packedNormal);
					bump.xy *= _BumpScale;
					bump.z = sqrt(1.0 - saturate(dot(bump.xy,bump.xy)));

					fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

					fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(bump,lightDir));

					fixed3 halfDir = normalize(lightDir + viewDir);
					fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(bump, halfDir)), _Gloss);


					return fixed4(ambient + diffuse + specular,1.0);
				}
				ENDCG
			}
		}
			FallBack "Specular"
}
