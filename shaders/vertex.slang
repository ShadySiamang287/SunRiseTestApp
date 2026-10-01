import common;

[[vk::push_constant]]
PushConstant pc;

[shader("vertex")]
VSOutput vertMain(VSInput input, uint instanceID : SV_VulkanInstanceID) {
    FrameData frameData = pc.frameData[0];
    ObjectData obj = pc.objectData[instanceID];

    float4 worldPos = mul(obj.model, float4(input.inPosition, 1.0));

    VSOutput output;
    output.pos = mul(frameData.projection, mul(frameData.view, worldPos));

    float3 N = normalize(
        mul(
            (float3x3)obj.normalMatrix,
            input.inNormal
        )
    );

    float3 T = normalize(
        mul(
            (float3x3)obj.model,
            input.inTangent.xyz
        )
    );

    T = normalize(T - N * dot(N, T));

    output.normal = N;
    output.tangent = float4(T, input.inTangent.w);
    output.uv = input.inUV;
    output.materialIndex = obj.materialIndex;

    return output;
}
