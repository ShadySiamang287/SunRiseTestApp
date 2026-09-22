import common;

[[vk::binding(0, 0)]]
Texture2D<float4> finalImage;

[[vk::binding(1, 0)]]
SamplerState gSampler;

float3 SampleOffset(float2 uv, float2 offset, float2 invResolution) {
    return finalImage.Sample(gSampler, uv + float2(offset) * invResolution).rgb;
}

float Luma(float3 rgb) {
    return rgb.y * (0.587 / 0.299) + rgb.x;
}

static const float EdgeThreshold = 0.25f;
static const float EdgeThresholdMin = 1.0 / 16.f;
static const uint SubPixelFiltering = 1;
static const float SubPixelTrim = 0.25f;
static const float SubPixelTrimScale = (1.f / (1.f - SubPixelTrim));
static const float SubPixelCap = 0.75f;
static const uint SearchSteps = 3;
static const float SearchThreshold = 0.25f;

[shader("fragment")]
float4 FXAA(FullPassVertOut input) {

    float2 uv = float2(input.uv.x, 1.0 - input.uv.y);

    uint width;
    uint height;
    finalImage.GetDimensions(width, height);
    float2 texelSize = 1.f / float2(width, height);

    float3 rgbN = SampleOffset(uv, float2(0, -1), texelSize);
    float3 rgbW = SampleOffset(uv, float2(-1, 0), texelSize);
    float3 rgbM = SampleOffset(uv, float2(0, 0), texelSize);
    float3 rgbE = SampleOffset(uv, float2(1, 0), texelSize);
    float3 rgbS = SampleOffset(uv, float2(0, 1), texelSize);

    float lumaN = Luma(rgbN);
    float lumaW = Luma(rgbW);
    float lumaM = Luma(rgbM);
    float lumaE = Luma(rgbE);
    float lumaS = Luma(rgbS);

    float rangeMin = min(lumaM, min(min(lumaN, lumaW), min(lumaS, lumaE)));
    float rangeMax = max(lumaM, max(max(lumaN, lumaW), max(lumaS, lumaE)));
    float range = rangeMax - rangeMin;

    if (range < max(EdgeThresholdMin, rangeMax * EdgeThreshold)) {
        return float4(rgbM, 0);
    }

    float lumaL = (lumaN + lumaW + lumaE + lumaS) * 0.25;
    float rangeL = abs(lumaL - lumaM);
    float blendL = max(0.0, (rangeL / range) - SubPixelTrim) * SubPixelTrimScale;
    blendL = min(SubPixelCap, blendL);

    float3 rgbL = rgbN + rgbW + rgbM + rgbE + rgbS;
    float3 rgbNW = SampleOffset(uv, float2(-1, -1), texelSize);
    float3 rgbNE = SampleOffset(uv, float2(1, -1), texelSize);
    float3 rgbSW = SampleOffset(uv, float2(-1, 1), texelSize);
    float3 rgbSE = SampleOffset(uv, float2(1, 1), texelSize);
    rgbL += (rgbNW + rgbNE + rgbSW + rgbSE);
    rgbL *= (1.f / 9.f);

    float lumaNW = Luma(rgbNW);
    float lumaNE = Luma(rgbNE);
    float lumaSW = Luma(rgbSW);
    float lumaSE = Luma(rgbSE);

    bool doneN = false;
    bool doneP = false;

    float edgeVert =
        abs((0.25 * lumaNW) + (-0.5 * lumaN) + (0.25 * lumaNE)) +
        abs((0.50 * lumaW) + (-1.0 * lumaM) + (0.50 * lumaE)) +
        abs((0.25 * lumaSW) + (-0.5 * lumaS) + (0.25 * lumaSE));
    float edgeHorz =
        abs((0.25 * lumaNW) + (-0.5 * lumaW) + (0.25 * lumaSW)) +
        abs((0.50 * lumaN) + (-1.0 * lumaM) + (0.50 * lumaS)) +
        abs((0.25 * lumaNE) + (-0.5 * lumaE) + (0.25 * lumaSE));
    bool horzSpan = edgeHorz >= edgeVert;

    float lengthSign = horzSpan ? -texelSize.y : -texelSize.x;

    if (!horzSpan)
    {
        lumaN = lumaW;
        lumaS = lumaE;
    }

    float gradientN = abs(lumaN - lumaM);
    float gradientS = abs(lumaS - lumaM);

    lumaN = (lumaN + lumaM) * 0.5;
    lumaS = (lumaS + lumaM) * 0.5;

    bool pairN = gradientN >= gradientS;

    if (!pairN)
    {
        lumaN = lumaS;
        gradientN = gradientS;
        lengthSign *= -1.0;
    }

    float2 posN;

    posN.x = uv.x + (horzSpan ? 0.0 : lengthSign * 0.5);

    posN.y = uv.y + (horzSpan ? lengthSign * 0.5 : 0.0);
    gradientN *= SearchThreshold;

    float2 posP = posN;

    // Direction to walk ALONG the edge.
    float2 offNP = horzSpan ? float2(texelSize.x, 0.0) : float2(0.0, texelSize.y);

    float lumaEndN = lumaN;
    float lumaEndP = lumaN;

    for (uint i = 0; i < SearchSteps; i++) {
        if (!doneN) lumaEndN = Luma(finalImage.SampleLevel(gSampler, posN, 0.0).rgb);

        if (!doneP) lumaEndP = Luma(finalImage.SampleLevel(gSampler, posP, 0.0).rgb);
        doneN = doneN || (abs(lumaEndN - lumaN) >= gradientN);
        doneP = doneP || (abs(lumaEndP - lumaN) >= gradientN);
        
        if (doneN && doneP) break;
        if (!doneN) posN -= offNP;
        if (!doneP) posP += offNP;
    }

    float dstN = horzSpan ? uv.x - posN.x : uv.y - posN.y;

    float dstP = horzSpan ? posP.x - uv.x : posP.y - uv.y;

    bool directionN = dstN < dstP;

    // Pick the luminance from the closest end.
    lumaEndN = directionN ? lumaEndN : lumaEndP;

    // Make sure we're moving in the correct direction
    // relative to the edge.
    if (((lumaM - lumaN) < 0.0) ==
        ((lumaEndN - lumaN) < 0.0))
    {
        lengthSign = 0.0;
    }

    float spanLength = dstP + dstN;

    // Use distance to the closest endpoint.
    dstN = directionN ? dstN : dstP;

    float subPixelOffset =
        (0.5 - (dstN / spanLength)) * lengthSign;

    float2 finalPos = uv.xy;

    if (horzSpan)
    {
        finalPos.y += subPixelOffset;
    }
    else
    {
        finalPos.x += subPixelOffset;
    }

    float3 rgbF = finalImage.Sample(gSampler, finalPos).rgb;
    float3 finalColor = lerp(rgbF, rgbL, blendL);
    return float4(finalColor, 1.f);
}