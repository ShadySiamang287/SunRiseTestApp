import common;

struct ShadowPushConstant
{
    ObjectData* objectData;
    uint2 padding;
    float4x4 lightViewProjection;
};

[[vk::push_constant]]
ShadowPushConstant pc;

[shader("vertex")]
float4 shadowVert(
    VSInput input,
    uint instanceID : SV_VulkanInstanceID
) : SV_Position
{
    ObjectData objectData =
        pc.objectData[instanceID];

    float4 worldPosition =
        mul(
            objectData.model,
            float4(input.inPosition, 1.0)
        );

    return mul(
        pc.lightViewProjection,
        worldPosition
    );
}
