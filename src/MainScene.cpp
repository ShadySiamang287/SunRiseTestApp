#include "MainScene.h"

#include <Graphics/ResourceFactory.h>
#include <Graphics/GraphicsCommands.h>

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <iostream>

#include <chrono>

MainScene::MainScene() {
    std::array<vk::DescriptorSetLayoutBinding, 2> bindings;
    bindings[0] = {
        .binding = 0,
        .descriptorType = vk::DescriptorType::eInputAttachment,
        .descriptorCount = 1,
        .stageFlags = vk::ShaderStageFlagBits::eFragment
    };
    bindings[1] = {
        .binding = 1,
        .descriptorType = vk::DescriptorType::eInputAttachment,
        .descriptorCount = 1,
        .stageFlags = vk::ShaderStageFlagBits::eFragment
    };

    mLightingDescriptors = SUN::ResourceFactory::CreateDescriptorResources(bindings);
    mLightingLayout = SUN::ResourceFactory::CreatePipelineLayout(&mLightingDescriptors);

    mPipelineLayout = SUN::ResourceFactory::CreatePipelineLayout();

    SUN::PipelineConfig gBuffer = {
        .vertexFile = "./shaders/slang.spv",
        .vertexName = "vertMain",
        .fragFile =  "./shaders/slang.spv",
        .fragName = "gBufferFrag",
        .primitiveTopology = vk::PrimitiveTopology::eTriangleList,
        .colorAttachmentFormats = {
            vk::Format::eR16G16B16A16Sfloat,
            vk::Format::eR16G16B16A16Sfloat
        },
        .colorAttachmentLocations = {
            0,
            1
        },
        .depthAttachmentFormat = vk::Format::eD32Sfloat,
        .useVertexInput = true
    };
    mGbufferPipeline = SUN::ResourceFactory::CreatePipeline(gBuffer, mPipelineLayout, "GBuffer pipeline");

    SUN::PipelineConfig lighting = {
        .vertexFile = "./shaders/slang.spv",
        .vertexName = "lightVert",
        .fragFile = "./shaders/slang.spv",
        .fragName = "lightFrag",

        .primitiveTopology = vk::PrimitiveTopology::eTriangleList,

        .colorAttachmentFormats = {
            SUN::GraphicsCommands::GetSwapchainFormat()
        },
        .colorAttachmentLocations = {
            0
        },
        .useVertexInput = false
    };
    mLightingPipeline = SUN::ResourceFactory::CreatePipeline(lighting, mLightingLayout, "Lighting Pipeline");

    const std::vector<SUN::Vertex> vertices = {
        {{-0.5f, -0.5f, 1.f}, {1.0f, 0.0f, 0.0f}, {1.0f, 0.0f, 0.0f}},
        {{0.5f, -0.5f, 1.f}, {0.0f, 1.0f, 0.0f}, {1.0f, 0.0f, 0.0f}},
        {{0.5f, 0.5f, 1.f}, {0.0f, 0.0f, 1.0f}, {1.0f, 0.0f, 0.0f}},
        {{-0.5f, 0.5f, 1.f}, {1.0f, 1.0f, 1.0f}, {1.0f, 0.0f, 0.0f}}
    };

    const std::vector<uint32_t> indices = {
        0, 1, 2, 2, 3, 0
    };

    mMeshBuffer.Init(vertices.data(), vertices.size() * sizeof(SUN::Vertex), sizeof(SUN::Vertex), indices.data(), indices.size() * sizeof(uint32_t), vk::IndexType::eUint32);

    mFrameDataBuffer.Init(sizeof(FrameData));
}

MainScene::~MainScene() {

}

void MainScene::Update(const float& dt) {
    static auto startTime = std::chrono::high_resolution_clock::now();
    static int frames = 0;
    frames++;


    auto currentTime = std::chrono::high_resolution_clock::now();
    float time       = std::chrono::duration<float, std::chrono::seconds::period>(currentTime - startTime).count();

    mFrameData = {
        glm::rotate(glm::mat4(1.0f), time * glm::radians(90.0f), glm::vec3(0.0f, 0.0f, 1.0f)),
        lookAt(glm::vec3(2.0f, 2.0f, 2.0f), glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f, 0.0f, 1.0f)),
        glm::perspective(glm::radians(45.0f), 16.f / 9.f, 0.1f, 10.0f)
    };

    mFrameDataBuffer.Upload(&mFrameData, sizeof(FrameData));
}

void MainScene::Render() {
    using namespace SUN;
    const SUN::PushConstants pConstant {
        mFrameDataBuffer.GetDeviceAddress()
    };

    GraphicsCommands::BeginDraw();
    GraphicsCommands::WriteLightingDescriptorSets(mLightingDescriptors);

    GraphicsCommands::BeginGBufferPass();

    GraphicsCommands::SetViewport();
    GraphicsCommands::SetScissor();

    GraphicsCommands::BindPipeline(mGbufferPipeline);

    GraphicsCommands::SetDepthTestEnable(true);
    GraphicsCommands::SetDepthWriteEnable(true);

    GraphicsCommands::BindGeometryBuffer(mMeshBuffer);

    GraphicsCommands::PushConstants(mPipelineLayout, vk::ShaderStageFlagBits::eVertex | vk::ShaderStageFlagBits::eFragment,  pConstant);
    GraphicsCommands::Draw(6, 1, 0, 0, 0);
    
    GraphicsCommands::EndGBufferPass();
    GraphicsCommands::BeginLightingPass();

    GraphicsCommands::SetDepthTestEnable(false);
    GraphicsCommands::SetDepthWriteEnable(false);

    GraphicsCommands::BindPipeline(mLightingPipeline);
    GraphicsCommands::BindDescriptorSets(mLightingLayout, mLightingDescriptors);
    GraphicsCommands::Draw(
        3,  // fullscreen triangle
        1,
        0,
        0,
        0
    );

    GraphicsCommands::EndLightingPass();

    
    GraphicsCommands::EndDraw();
}