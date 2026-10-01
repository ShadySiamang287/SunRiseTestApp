public struct FrameData {
    public float4x4 view;
    public float4x4 projection;
    public float4x4 inverseView;
    public float4x4 inverseProjection;

    public float4 cameraPosition;
    public uint directionalLightCount;
    public uint pointLightCount;
    uint padding0;
    uint padding1;
}

public struct PushConstant {
    public FrameData *frameData;
    public ObjectData *objectData;
    public MaterialData *materialData;
    public DirectionalLight *directionalLights;
    public PointLight *pointLights;
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
    public float2 inUV;
    public float4 inTangent;
};

public struct VSOutput
{
    public float4 pos : SV_Position;
    public float3 normal;
    public float2 uv;
    public float4 tangent;
    public nointerpolation uint materialIndex;
};

public struct ObjectData {
    public float4x4 model;
    public float4x4 normalMatrix;

    public float4 boundsCenter;
    public float4 boundsExtents;

    public uint materialIndex;
    public uint firstIndex;
    public uint indexCount;
    public int vertexOffset;
}

public struct MaterialData {
    public float4 baseColorFactor;

    public uint albedoTextureIndex;
    public uint normalTextureIndex;
    public uint materialTextureIndex;
    public float metallicFactor;

    public float roughnessFactor;
    uint padding0;
    uint padding1;
    uint padding2;
}

public struct DirectionalLight {
    public float4 directionIntensity;
    public float4 color;

    public float4x4 lightViewProjection;

    public uint shadowIndex;
    public uint castsShadows;
    uint padding0;
    uint padding1;
}

public struct PointLight {
    public float4 positionRange;
    public float4 colorIntensity;

    public uint shadowIndex;
    public uint castsShadows;
    uint padding0;
    uint padding1;
}
