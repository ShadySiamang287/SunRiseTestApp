public struct FrameData {
    public float4x4 model;
    public float4x4 view;
    public float4x4 projection;
}

public struct PushConstant {
    public FrameData *frameData;
}

public struct FullPassVertOut
{
    public float4 position : SV_Position;
    public float2 uv : TEXCOORD0;
};

public struct GBufferOutput
{
    public float4 albedo : SV_Target0;
    public float4 normal : SV_Target1;
};

public struct VSInput {
    public float3 inPosition;
    public float3 inNormal;
    public float3 inColor;
};

public struct VSOutput
{
    public float4 pos : SV_Position;
    public float3 color;
    public float3 normal;
};

[[vk::push_constant]]
public PushConstant pc;