#include "MainScene.h"

#include <Graphics/ResourceFactory.h>
#include <Graphics/GraphicsCommands.h>

#include <Graphics/vertex.h>

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>

#include <chrono>

MainScene::MainScene() {
    mPipelineLayout = SUN::ResourceFactory::CreatePipelineLayout();

    SUN::PipelineConfig pipelineConfig = {
        .vertexFile = "./shaders/slang.spv",
        .vertexName = "vertMain",
        .fragFile =  "./shaders/slang.spv",
        .fragName = "fragMain",
        .primitiveTopology = vk::PrimitiveTopology::eTriangleList
    };
    mPipeline = SUN::ResourceFactory::CreatePipeline(pipelineConfig, mPipelineLayout, "Base pipeline");

    const std::vector<SUN::Vertex> vertices = {
        {{-0.5f, -0.5f}, {1.0f, 0.0f, 0.0f}},
        {{0.5f, -0.5f}, {0.0f, 1.0f, 0.0f}},
        {{0.5f, 0.5f}, {0.0f, 0.0f, 1.0f}},
        {{-0.5f, 0.5f}, {1.0f, 1.0f, 1.0f}}
    };

    const std::vector<uint32_t> indices = {
        0, 1, 2, 2, 3, 0
    };

    mMeshBuffer.Init(vertices.data(), vertices.size() * sizeof(SUN::Vertex), sizeof(SUN::Vertex), indices.data(), indices.size() * sizeof(uint32_t), vk::IndexType::eUint32);

    mFrameDataBuffer.Init(sizeof(FrameData));
}

MainScene::~MainScene() {

}

void MainScene::Update() {
    static auto startTime = std::chrono::high_resolution_clock::now();

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

    GraphicsCommands::SetViewport();
    GraphicsCommands::SetScissor();

    GraphicsCommands::BindPipeline(mPipeline);
    GraphicsCommands::BindGeometryBuffer(mMeshBuffer);
    GraphicsCommands::PushConstants(mPipelineLayout, vk::ShaderStageFlagBits::eVertex | vk::ShaderStageFlagBits::eFragment,  pConstant);
    GraphicsCommands::Draw(6, 1, 0, 0, 0);
    
    GraphicsCommands::EndDraw();
}