#ifndef OVERLAYMODE
#define OVERLAYMODE


/********************************************************加深***************************************************************/
half3 Darken(half3 a, half3 b)     //变暗:
{
	half3 c = min(a, b);
	return c;
}

half3 Multiply(half3 a, half3 b)   //正片叠底:
{
	half3 c = a*b;
	return c;
}

half3 ColorBurn(half3 a, half3 b)   //颜色加深:
{
	half3 c = 1 - (1 - a) / b;
	return c;
}

half3 LinearBurn(half3 a, half3 b)  //线性加深:
{
	half3 c = a + b - 1.0h;
	return c;
}

half3 DarkerColor(half3 a, half3 b) //深色:
{
	half3 c;
	c = lerp(a, b, saturate(((a.r + a.g + a.b) - (b.r + b.g + b.b)) * 10000));
	return c;
}

/********************************************************减淡***************************************************************/
half3	Lighten(half3 a, half3 b)   //变亮: 
{
	half3 c = max(a, b);
	return c;
}

half3 Screen(half3 a, half3 b)     //滤色: 
{
	half3 c = 1 - (1 - a)*(1 - b);
	return c;
}

half3 ColorDodge(half3 a, half3 b) //颜色减淡: 
{
	half3 c = a / (1 - b);
	return c;
}

half3 LinearDodge(half3 a, half3 b) //线性减淡/添加:
{
	half3 c = a + b;
	return c;
}

half3 LighterColor(half3 a, half3 b) //浅色:
{
	half3 c = lerp(b, a, saturate(((a.r + a.g + a.b) - (b.r + b.g + b.b)) * 10000));
	return c;
}

/********************************************************对比***************************************************************/
half3 Overlay(half3 a, half3 b)    //叠加:
{
	half3 left = 2 * a*b;
	half3 right = 1 - 2*(1 - a)*(1 - b);
	half3 c = lerp(left, right, saturate((a - 0.5) * 10000));
	return c;
}

half3 SolfLight(half3 a, half3 b)  //柔光:
{
	half3 left = 2 * a*b + a*a*(1 - 2 * b);
	half3 right = 2 * a*(1 - b) + sqrt(a)*(2 * b - 1);
	half3 c = lerp(left, right, saturate((a - 0.5) * 10000));
	return c;
}

half3 HardLight(half3 a, half3 b)  //强光:
{
	half3 left = 1 - 2 * (1 - a)*(1 - b);
	half3 right = 2 * a*b;
	half3 c = lerp( left, right, saturate((a - 0.5) * 10000));
	return c;
}

half3 VividLight(half3 a, half3 b)//亮光:
{
	half3 left = 1 - (1 - b) / (2 * a);
	half3 right = b / (2 * (1 - a));
	half3 c = lerp(left, right, saturate((a - 0.5) * 10000));
	return c;
}

half3 LinearLight(half3 a, half3 b)//线性光:
{
	half3 c = a + 2*b - 1;
	return c;
}

half3 PinLight(half3 a, half3 b)   //点光:
{
	//if(b < (2*a - 1))
	//	c = 2*a - 1;
	//if(b > 2*a - 1 && b < 2*a)
	//	c = b;
	//if(b > 2 * a)
	//	c = 2 * a;
	half3 c = lerp(2 * b - 1, a, saturate((a - (2 * b - 1)) * 10000));
	half3 d = lerp(c, 2 * b, saturate((a - 2*b) * 10000));
	return d;
}

half3 HardMix(half3 a, half3 b)    //实色混合:
{
	half3 c = lerp(0, 1, saturate((a - (1 - b)) * 10000));
	return c;
}


/********************************************************差集***************************************************************/
half3 Differencce(half3 a, half3 b)//差值:
{
	half3 c = abs(b - a);
	return c;
}

half3 Exclusion(half3 a, half3 b)  //排除:
{
	return  a*(1 - b) + b*(1 - a);
}

half3 Subtract(half3 a, half3 b)   //减法:
{
	return a-b;
}

half3 Divde(half3 a, half3 b)      //划分:
{
	return a/b;
}

/********************************************************RGB<->HSV**********************************************************/
/*
float3 RGBToHSV(float3 rgb)
{
	float R = rgb.x, G = rgb.y, B = rgb.z;
	float3 hsv;
	float max1 = max(R, max(G, B));
	float min1 = min(R, min(G, B));
	if (R == max1)
	{
		hsv.x = (G - B) / (max1 - min1);
	}
	if (G == max1)
	{
		hsv.x = 2 + (B - R) / (max1 - min1);
	}
	if (B == max1)
	{
		hsv.x = 4 + (R - G) / (max1 - min1);
	}
	hsv.x = hsv.x * 60.0;
	if (hsv.x < 0)
		hsv.x = hsv.x + 360;
	hsv.z = max1;
	hsv.y = (max1 - min1) / max1;
	return hsv;
}

float3 HSVToRGB(float3 hsv)
{
	float R, G, B;
	//float3 rgb;
	if (hsv.y == 0)
	{
		R = G = B = hsv.z;
	}
	else
	{
		hsv.x = hsv.x / 60.0;
		int i = (int)hsv.x;
		float f = hsv.x - (float)i;
		float a = hsv.z * (1 - hsv.y);
		float b = hsv.z * (1 - hsv.y * f);
		float c = hsv.z * (1 - hsv.y * (1 - f));
		switch (i)
		{
		case 0: R = hsv.z; G = c; B = a;
			break;
		case 1: R = b; G = hsv.z; B = a;
			break;
		case 2: R = a; G = hsv.z; B = c;
			break;
		case 3: R = a; G = b; B = hsv.z;
			break;
		case 4: R = c; G = a; B = hsv.z;
			break;
		default: R = hsv.z; G = a; B = b;
			break;
		}
	}
	return float3(R, G, B);
}

float3 rgb2hsv(float3 c)
{
	float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
	float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 hsv2rgb(float3 c)
{
	float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
*/

float Hue2RGB(float v1, float v2, float vH)
{
	if (vH < 0) vH += 1;
	if (vH > 1) vH -= 1;
	if (6.0 * vH < 1) return v1 + (v2 - v1) * 6.0 * vH;
	if (2.0 * vH < 1) return v2;
	if (3.0 * vH < 2) return v1 + (v2 - v1) * ((2.0 / 3.0) - vH) * 6.0;
	return (v1);
}

void RGBToHSB(float3 AColor, int H, int S, int L)
{
	float h, s, l;
	RGBToHSB(AColor, h, s, l);
	H = h * 240 / 255;
	S = s * 240 / 255;
	L = l * 240 / 255;
}


float3 HSBToRGB(int H, int S, int L)
{
	float h, s, l;
	h = H / 240 / 255;
	s = S / 240 / 255;
	l = L / 240 / 255;
	return HSBToRGB(h, s, l);
}

float3 RGBToHSB(float3 AColor)
{
	float H;
	float S;
	float L;

	float R, G, B, Max, Min, del_R, del_G, del_B, del_Max;
	R = AColor.r;       //Where RGB values = 0 ÷ 255
	G = AColor.g;
	B = AColor.b;

	Min = min(R, min(G, B));    //Min. value of RGB
	Max = max(R, max(G, B));    //Max. value of RGB
	del_Max = Max - Min;        //Delta RGB value

	L = (Max + Min) / 2.0;

	if (del_Max == 0)           //This is a gray, no chroma...
	{
		H = 0;                  //HSB results = 0 ÷ 1
		S = 0;
	}
	else                        //Chromatic data...
	{
		if (L < 0.5) S = del_Max / (Max + Min);
		else         S = del_Max / (2 - Max - Min);

		del_R = (((Max - R) / 6.0) + (del_Max / 2.0)) / del_Max;
		del_G = (((Max - G) / 6.0) + (del_Max / 2.0)) / del_Max;
		del_B = (((Max - B) / 6.0) + (del_Max / 2.0)) / del_Max;

		if (R == Max) H = del_B - del_G;
		else if (G == Max) H = (1.0 / 3.0) + del_R - del_B;
		else if (B == Max) H = (2.0 / 3.0) + del_G - del_R;

		if (H < 0)  H += 1;
		if (H > 1)  H -= 1;
	}
	return float3(H, S, L);
}

float3 HSBToRGB(float3 HSL)
{
	float R, G, B;
	float var_1, var_2;
	if (HSL.y == 0)                       //HSB values = 0 ÷ 1
	{
		R = HSL.z;                   //RGB results = 0 ÷ 255
		G = HSL.z;
		B = HSL.z;
	}
	else
	{
		if(HSL.z < 0.5)
			var_2 = HSL.z * (1 + HSL.y);
		else
			var_2 = (HSL.z + HSL.y) - (HSL.y * HSL.z);

		var_1 = 2.0 * HSL.z - var_2;

		R = Hue2RGB(var_1, var_2, HSL.x + (1.0 / 3.0));
		G = Hue2RGB(var_1, var_2, HSL.x);
		B = Hue2RGB(var_1, var_2, HSL.x - (1.0 / 3.0));
	}
	return float3(R, G, B);
}

float3 HSBToRGBCustom(float3 HSL)
{
	float R, G, B;
	float var_1, var_2;
	if (HSL.y == 0)                       //HSB values = 0 ÷ 1
	{
		R = HSL.z;                   //RGB results = 0 ÷ 255
		G = HSL.z;
		B = HSL.z;
	}
	else
	{
		if (HSL.z < 0.5)
			var_2 = HSL.z * (1 + HSL.y);
		else
			var_2 = (HSL.z + HSL.y) - (HSL.y * HSL.z);

		var_1 = 2.0 * HSL.z - var_2;

		R = Hue2RGB(var_1, var_2, HSL.x + (1.0 / 3.0));
		G = Hue2RGB(var_1, var_2, HSL.x);
		B = Hue2RGB(var_1, var_2, HSL.x - (1.0 / 3.0));
	}
	return float3(R, G, B);
}

//---------------------------------------------------------------------------


/********************************************************色彩**************************色彩(基于HSB的色彩混合模式)***************/
float3 Hue(float3 a, float3 b)         //色相:
{
	float3 left = RGBToHSB(a);
	float3 right = RGBToHSB(b);
	float3 combine = float3(right.r, left.g, left.b);
	float3 c = HSBToRGBCustom(combine);
	return c;
}
half3 Color(half3 a, half3 b)       //颜色:
{
	half3 left = RGBToHSB(a);
	half3 right = RGBToHSB(b);
	half3 combine = half3(right.r, right.g, left.b);
	half3 c = HSBToRGB(combine);
	return c;
}
half3 Saturation(half3 a, half3 b)  //饱和度:
{
	half3 left = RGBToHSB(a);
	half3 right = RGBToHSB(b);
	half3 combine = half3(left.r, right.g, left.b);
	half3 c = HSBToRGB(combine);
	return c;
}
half3 Luminosity(half3 a, half3 b)   //明度:
{
	half3 left = RGBToHSB(a);
	half3 right = RGBToHSB(b);
	half3 combine = half3(left.r, left.g, right.b);
	half3 c = HSBToRGB(combine);
	return c;
}

half3 Default(half4 detailCol, half4 mainCol, half blendBounds)
{
	half3 blendCol = detailCol.rgb * detailCol.a + mainCol.rgb * (1 - detailCol.a);
	half3 addCol = mainCol + detailCol.rgb * detailCol.a;
	half3 outCol = lerp(blendCol, addCol, blendBounds);
	return outCol;
}


half4 OverLayFunction(half4 detailCol, half4 mainCol, half blendBounds)
{
	half3 a = lerp(detailCol.rgb, mainCol.rgb, blendBounds);
	half3 b = lerp(detailCol.rgb, mainCol.rgb, 1.0 - blendBounds);
	a = pow(a, 0.45h);
	b = pow(b, 0.45h);
	half3 result = 0.0f;

#if defined(_USE_DETAIL_ON)
	result = Default(detailCol, mainCol, blendBounds);
#elif(_DARKEN)
	result = Darken(a, b);
#elif defined(_MULTIPLY)
	result = Multiply(a, b);
#elif defined(_COLORBURN)
	result = ColorBurn(a, b);
#elif defined(_LINEARBURN)
	result = LinearBurn(a, b);
#elif defined(_DARKERCOLOR)
	result = DarkerColor(a, b);
#elif defined(_LIGHTEN)
	result = Lighten(a, b);
#elif defined(_SCREEN)
	result = Screen(a, b);
#elif defined(_COLORDODGE)
	result = ColorDodge(a, b);
#elif defined(_LINEARDODGE)
	result = LinearDodge(a, b);
#elif defined(_LIGHTERCOLOR)
	result = LighterColor(a, b);
#elif defined(_OVERLAY)
	result = Overlay(a, b);
#elif defined(_SOLFLIGHT)
	result = SolfLight(a, b);
#elif defined(_HARDLIGHT)
	result = HardLight(a, b);
#elif defined(_VIVIDLIGHT) 
	result = VividLight(a, b);
#elif defined(_LINEARLIGHT)
	result = LinearLight(a, b);
#elif defined(_PINLIGHT)
	result = PinLight(a, b);
#elif defined(_HARDMIX)
	result = HardMix(a, b);
#elif defined(_DIFFERENCCE)
	result = Differencce(a, b);
#elif defined(_EXCLUSION)
	result = Exclusion(a, b);
#elif defined(_SUBTRACT)
	result = Subtract(a, b);
#elif defined(_DIVDE)
	result = Divde(a, b);
#elif defined(_HUE)
	result = Hue(a, b);
#elif defined(_COLOR)
	result = Color(a, b);
#elif defined(_SATURATION)
	result = Saturation(a, b);
#elif defined(_LUMINOSITY)
	result = Luminosity(a, b);
#endif
	return half4(pow(saturate(result),2.2), 1.0);
}

#endif //OVERLAYMODE

