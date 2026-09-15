#include "MainScene.h"

#include <Graphics/ResourceFactory.h>

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

void MainScene::Render() {}