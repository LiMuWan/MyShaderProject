// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Glass/GrabShader"
{
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

            struct VertInput
            {
                float4 vertex:POSITION;
            };

            struct VertOutput
            {
                float4 vertex:POSITION;
                float4 uvgrab:TEXCOORD1;
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
                // o.uvgrab = ComputeGrabScreenPos(o.vertex);
                o.uvgrab = o.vertex * 0.5f;
                o.uvgrab.xy = float2(o.uvgrab.x,o.uvgrab.y*-1) + o.uvgrab.w;
                o.uvgrab.w = o.vertex.w;
                return o;
            }
            
            //对Unity光栅化阶段经过顶点插值得到片元（像素）的属性进行计算，得到
            //每个片元的颜色值
            half4 frag(VertOutput i):COLOR
            {
               fixed4 color = tex2Dproj(_GrabTexture,i.uvgrab);//i.uvgrab.xy/i.uvgrab.w
               //上面的代码中，xy是基于投影平面（以摄像机为原点）的投影空间中的坐标点，
               //其z值仅用于视锥裁剪，投影空间中的片元（带深度值的像素点）的实际位置可以用其xy/w
               //算出
               /* 结合vert的代码来看：
               （i.uvgrab.xy/i.uvgrab.w + 0.5）
               含义：
               这里的代码总体的意思是：
               * 为了体现玻璃的半透明（透光）效果，需要抓取整个场景到一张纹理，也即GrabTexture
               ** 然后对GrabTexture进行贴图，但是平面贴图怎么把玻璃区域刚好贴到玻璃四边形上呢？
               **顶点的xy坐标除以顶点的其次坐标w,得到其透视投影环境下的位置
               ** 把投影空间（半立方体空间）中的顶点转换到纹理坐标空间，也即：[-1,+1]->[0,1]
               *** 由于D3D的纹理坐标是v朝下的，而顶点的y坐标是朝上的，所以要做一个转换（*-1）
               */
               return color;
            }
            ENDCG
        }
    }
}
