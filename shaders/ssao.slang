import common;

struct SSAOData
{
    float4 samples[64];

    // x = radius
    // y = bias
    // z = kernel size
    // w = power
    float4 settings;
};

[[vk::binding(0, 0)]]
Texture2D<float> gDepth;

[[vk::binding(1, 0)]]
Texture2D<float4> gNormal;

[[vk::binding(2, 0)]]
Texture2D<float4> gNoise;

[[vk::binding(3, 0)]]
SamplerState gBufferSampler;

[[vk::binding(4, 0)]]
SamplerState gNoiseSampler;

[[vk::binding(5, 0)]]
ConstantBuffer<SSAOData> gSSAOData;

[[vk::push_constant]]
PushConstant pc;


float3 ReconstructViewPosition(
    float2 texCoord,
    float depth,
    FrameData frameData)
{
    float2 ndc;
    ndc.x = texCoord.x * 2.0 - 1.0;
    ndc.y = 1.0 - texCoord.y * 2.0;

    // Vulkan depth is already 0..1.
    float4 clipPosition = float4(
        ndc,
        depth,
        1.0
    );

    float4 viewPosition = mul(
        frameData.inverseProjection,
        clipPosition
    );

    viewPosition /= viewPosition.w;

    return viewPosition.xyz;
}


[shader("fragment")]
float ssao(FullPassVertOut input) : SV_Target0
{
    FrameData frameData = pc.frameData[0];

    float2 texCoord = float2(
        input.uv.x,
        1.0 - input.uv.y
    );

    float depth = gDepth.SampleLevel(
        gBufferSampler,
        texCoord,
        0
    );

    // No geometry here.
    if (depth >= 1.0)
        return 1.0;

    // Reconstruct current fragment position in VIEW SPACE.
    float3 pos = ReconstructViewPosition(
        texCoord,
        depth,
        frameData
    );

    // G-buffer normal is stored in WORLD SPACE.
    float3 normalWS = gNormal.SampleLevel(
        gBufferSampler,
        texCoord,
        0
    ).xyz;

    // Convert the normal to VIEW SPACE so that it matches pos.
    float3 normal = normalize(
        mul(
            (float3x3)frameData.view,
            normalWS
        )
    );

    // Work out how many times the 4x4 noise texture should tile.
    uint width;
    uint height;
    gDepth.GetDimensions(width, height);

    uint noiseWidth;
    uint noiseHeight;
    gNoise.GetDimensions(
        noiseWidth,
        noiseHeight
    );

    float2 noiseScale =
        float2(width, height) /
        float2(noiseWidth, noiseHeight);

    // Noise is stored as UNORM, so decode [0, 1] -> [-1, 1].
    float3 randomVec = gNoise.SampleLevel(
        gNoiseSampler,
        texCoord * noiseScale,
        0
    ).xyz * 2.0 - 1.0;

    // Build tangent basis around the surface normal.
    float3 tangent = normalize(
        randomVec -
        normal * dot(randomVec, normal)
    );

    float3 bitangent = cross(
        normal,
        tangent
    );

    float radius = gSSAOData.settings.x;
    float bias = gSSAOData.settings.y;

    uint kernelSize = min(
        (uint)gSSAOData.settings.z,
        64u
    );

    float occlusion = 0.0;

    for (uint i = 0; i < kernelSize; ++i)
    {
        float3 kernelSample =
            gSSAOData.samples[i].xyz;

        // Tangent-space hemisphere sample -> view space.
        // Written explicitly to avoid matrix row/column ambiguity.
        float3 sampleDirection =
            tangent   * kernelSample.x +
            bitangent * kernelSample.y +
            normal    * kernelSample.z;

        // Position the sample around this fragment.
        float3 samplePos =
            pos +
            sampleDirection * radius;

        // View space -> clip space.
        float4 clip = mul(
            frameData.projection,
            float4(samplePos, 1.0)
        );

        // Avoid invalid projection.
        if (abs(clip.w) < 0.00001)
            continue;

        // Clip space -> NDC.
        float3 ndc =
            clip.xyz / clip.w;

        // NDC X/Y [-1, 1] -> texture UV [0, 1].
        float2 sampleUV =
            ndc.xy * 0.5 + 0.5;

        // Match the engine's texture-coordinate convention.
        sampleUV.y =
            1.0 - sampleUV.y;

        // Don't let clamp-to-edge sampling create fake AO
        // for samples that leave the screen.
        if (
            sampleUV.x < 0.0 ||
            sampleUV.x > 1.0 ||
            sampleUV.y < 0.0 ||
            sampleUV.y > 1.0
        )
        {
            continue;
        }

        // Read hardware depth at the projected sample location.
        float hardwareDepth =
            gDepth.SampleLevel(
                gBufferSampler,
                sampleUV,
                0
            );

        // Ignore background samples.
        if (hardwareDepth >= 1.0)
            continue;

        // Convert sampled hardware depth back into VIEW SPACE.
        // We cannot compare hardware depth directly with samplePos.z.
        float3 sampledPos =
            ReconstructViewPosition(
                sampleUV,
                hardwareDepth,
                frameData
            );

        float sampleDepth =
            sampledPos.z;

        // Prevent distant geometry from incorrectly occluding this pixel.
        float depthDifference =
            abs(pos.z - sampleDepth);

        float rangeCheck = smoothstep(
            0.0,
            1.0,
            radius / max(depthDifference, 0.0001)
        );

        // GLM's usual RH projection means view-space forward is -Z.
        // Larger / less-negative Z is closer to the camera.
        float isOccluded =
            sampleDepth >= samplePos.z + bias
                ? 1.0
                : 0.0;

        occlusion +=
            isOccluded * rangeCheck;
    }

    float ao =
        1.0 -
        occlusion / max(float(kernelSize), 1.0);

    // Optional strength control.
    ao = pow(
        saturate(ao),
        gSSAOData.settings.w
    );

    return ao;
}