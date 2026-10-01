import common;

struct DrawIndexedIndirectCommand
{
    uint indexCount;
    uint instanceCount;
    uint firstIndex;
    int vertexOffset;
    uint firstInstance;
};

struct CullPushConstant
{
    FrameData* frameData;
    ObjectData* objectData;
    DrawIndexedIndirectCommand* indirectCommands;
    uint objectCount;
    uint padding;
};

[[vk::push_constant]]
CullPushConstant pc;

bool IsVisible(
    ObjectData objectData,
    FrameData frameData
)
{
    float3 center = objectData.boundsCenter.xyz;
    float3 extents = objectData.boundsExtents.xyz;

    bool outsideLeft = true;
    bool outsideRight = true;
    bool outsideBottom = true;
    bool outsideTop = true;
    bool outsideNear = true;
    bool outsideFar = true;

    for (uint cornerIndex = 0;
         cornerIndex < 8;
         ++cornerIndex)
    {
        float3 localCorner = center + float3(
            (cornerIndex & 1) != 0 ? extents.x : -extents.x,
            (cornerIndex & 2) != 0 ? extents.y : -extents.y,
            (cornerIndex & 4) != 0 ? extents.z : -extents.z
        );

        float4 worldPosition =
            mul(
                objectData.model,
                float4(localCorner, 1.0)
            );

        float4 clipPosition =
            mul(
                frameData.projection,
                mul(
                    frameData.view,
                    worldPosition
                )
            );

        outsideLeft =
            outsideLeft &&
            clipPosition.x < -clipPosition.w;

        outsideRight =
            outsideRight &&
            clipPosition.x > clipPosition.w;

        outsideBottom =
            outsideBottom &&
            clipPosition.y < -clipPosition.w;

        outsideTop =
            outsideTop &&
            clipPosition.y > clipPosition.w;

        // Vulkan's depth clip range is 0..w.
        outsideNear =
            outsideNear &&
            clipPosition.z < 0.0;

        outsideFar =
            outsideFar &&
            clipPosition.z > clipPosition.w;
    }

    return !(
        outsideLeft ||
        outsideRight ||
        outsideBottom ||
        outsideTop ||
        outsideNear ||
        outsideFar
    );
}

[shader("compute")]
[numthreads(64, 1, 1)]
void cullMain(
    uint3 dispatchThreadID : SV_DispatchThreadID
)
{
    uint objectIndex = dispatchThreadID.x;

    if (objectIndex >= pc.objectCount)
        return;

    ObjectData objectData =
        pc.objectData[objectIndex];

    DrawIndexedIndirectCommand command;

    command.indexCount =
        objectData.indexCount;

    command.instanceCount =
        IsVisible(
            objectData,
            pc.frameData[0]
        )
            ? 1
            : 0;

    command.firstIndex =
        objectData.firstIndex;

    command.vertexOffset =
        objectData.vertexOffset;

    command.firstInstance =
        objectIndex;

    pc.indirectCommands[objectIndex] =
        command;
}
