#include "MainScene.h"

#include <Graphics/ResourceFactory.h>
#include <Graphics/GraphicsCommands.h>

MainScene::MainScene() {
    mPipelineLayout = SUN::ResourceFactory::CreatePipelineLayout();

    SUN::PipelineConfig pipelineConfig = {
        .vertexFile = "./shaders/slang.spv",
        .vertexName = "vertMain",
        .fragFile =  "./shaders/slang.spv",
        .fragName = "fragMain",
        .primitiveTopology = vk::PrimitiveTopology::eTriangleList
    };
    mPipeline = SUN::ResourceFactory::CreatePipeline(pipelineConfig, mPipelineLayout);
}

void MainScene::Render() {
    using namespace SUN;
    GraphicsCommands::BeginDraw();

    GraphicsCommands::SetViewport();
    GraphicsCommands::SetScissor();

    GraphicsCommands::BindPipeline(mPipeline);
    
    GraphicsCommands::Draw(3, 1, 0, 0);
    
    GraphicsCommands::EndDraw();
}