// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "LiRui/Water"
{
    Properties
    {
        _MainTex("Water Base Texture",2D) = "white"{}
        _BumpMap("Noise Texture",2D) = "bump"{}
        _CausticMap("_Caustic Texture",2D) = "white"{}
        _Magnitude("Magnitude",Range(0,1)) = 0.5
        _WaterColor("Water Color",Color) = (1,1,1,1)
        _WaterMagnitude("Water Magnitude",float) = 1
        _WaterPeriodo("Water Periodo",float) = 1
    }
    SubShader
    {
        Tags 
        {
             "Queue"="Transparent"
             "IgnoreProjector"="True"
             "RenderType"="Opaque" 
        }
        ZWrite On
        Lighting Off
        Cull Off
        Fog {Mode off}
        Blend One Zero
        LOD 100

        //在对玻璃第一遍渲染时，把整个场景拍照，绘制到一个名为_GrabTexture的纹理上
        GrabPass{"_GrabTexture"} 
        
        //将GrabPass抓取的内容贴图到当前pass
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            sampler2D _GrabTexture;//表示在GrabPass中抓取的数据
            sampler2D _MainTex;
            sampler2D _BumpMap;//噪音贴图
            sampler2D _CausticMap;
            float _Magnitude;
            float4 _WaterColor;
            float _WaterMagnitude;//波长
            float _WaterPeriodo;

            struct VertInput
            {
                float4 vertex:POSITION;
                float4 color:COLOR;
                float2 texcoord:TEXCOORD0;
            };

            struct VertOutput
            {
                float4 vertex:POSITION;
                fixed4 color:COLOR;
                float2 texcoord:TEXCOORD0;//_Maintex的纹理坐标
                float4 uvgrab:TEXCOORD1; // _Bump的纹理坐标
            };
            
            //计算每个顶点相关的属性（位置，纹理坐标等）
            VertOutput vert(VertInput i)
            {
                VertOutput o;
                o.vertex = UnityObjectToClipPos(i.vertex);
                //ComputeGrabScreenPos:传入一个投影空间中的顶点坐标，此方法
                //会以摄像机可视范围的左下角为纹理坐标【0,0】点，以右上角【1,1】
                //点，计算出当前顶点位置对应的纹理坐标
                //4D向量的w分量，代表投影空间坐标点的透视系数（x,y,z,w） == (x/w,y/w,z/w)
                o.uvgrab = ComputeGrabScreenPos(o.vertex);
                //3D模型里面，每个顶点的颜色和纹理坐标带入到片元处理阶段，在每个像素点进行处理
                o.color = i.color;
                o.texcoord = i.texcoord;
                return o;
            }
            
            float2 sinusoid(float2 x,float2 m,float2 M,float2 periodo)
            {
                float2 escursione = M - m;
                float2 coefficiente = 3.1415*2.0/periodo;
                return escursione / 2.0 * (1.0 + sin(x*coefficiente))+m;
            }

            //对Unity光栅化阶段经过顶点插值得到片元（像素）的属性进行计算，得到
            //每个片元的颜色值
            half4 frag(VertOutput i):COLOR
            {
              fixed4 noise = tex2D(_BumpMap,i.texcoord);
              fixed4 mainColor = tex2D(_MainTex,i.texcoord);

              float time = _Time[1];
              float waterDisplacement = sinusoid(
                float2(time,time) + noise.xy,
                float2(-_WaterMagnitude,-_WaterMagnitude),
                float2(_WaterMagnitude,_WaterMagnitude),
                float2(_WaterPeriodo,_WaterPeriodo)
              );//当前值，最小值，最大值，周期
              i.uvgrab.xy += waterDisplacement;
              fixed4 grabColor = tex2Dproj(_GrabTexture,i.uvgrab);
              fixed4 causticColor = tex2D(_CausticMap,i.texcoord.xy*0.25f + waterDisplacement*5);

              return grabColor*mainColor*causticColor*_WaterColor; 
            }
            ENDCG
        }
    }
}