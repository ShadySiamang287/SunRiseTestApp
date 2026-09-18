#include "MainScene.h"

#include <Graphics/ResourceFactory.h>
#include <Graphics/GraphicsCommands.h>

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <iostream>

#include <chrono>

#include <Renderer/Renderer3D.h>
#include <SceneManagement/Entity.h>
#include <SceneManagement/Systems/RenderSystem.h>
#include <SceneManagement/Components.h>

MainScene::MainScene() {
    using namespace SUN;

    const std::vector<SUN::Vertex> vertices = {
        {{-0.5f, -0.5f, 1.f}, {1.0f, 0.0f, 0.0f}, {1.0f, 0.0f, 0.0f}},
        {{0.5f, -0.5f, 1.f}, {0.0f, 1.0f, 0.0f}, {1.0f, 0.0f, 0.0f}},
        {{0.5f, 0.5f, 1.f}, {0.0f, 0.0f, 1.0f}, {1.0f, 0.0f, 0.0f}},
        {{-0.5f, 0.5f, 1.f}, {1.0f, 1.0f, 1.0f}, {1.0f, 0.0f, 0.0f}}
    };

    const std::vector<uint32_t> indices = {
        0, 1, 2, 2, 3, 0
    };

    Entity camEntity = CreateEntity("Camera");
    camEntity.AddComponent<CameraComponent>();
    auto& cam = camEntity.GetComponent<CameraComponent>().Camera;
    cam.Position = {0.f, 0.f, 1.0f + 0.866f};

    Entity meshEntity = CreateEntity("MeshTest");
    meshEntity.AddComponent<MeshComponent>();
    auto& mesh = meshEntity.GetComponent<MeshComponent>();
    mesh.mesh.buffer.Init(vertices.data(), vertices.size() * sizeof(SUN::Vertex), sizeof(SUN::Vertex), indices.data(), indices.size() * sizeof(uint32_t), vk::IndexType::eUint32);
    mesh.mesh.indexCount = 6;
}

MainScene::~MainScene() {

}

void MainScene::Update(const float& dt) {

}

void MainScene::Render(SUN::RenderContext& context) {

    auto camView = mRegistry.view<SUN::CameraComponent>();
    SUN::Camera cam = camView.get<SUN::CameraComponent>(camView.front()).Camera;

    auto& renderer = context.renderer;
    renderer->BeginScene(cam);
    SUN::RenderSystem::Render(*this, renderer);
    renderer->EndScene(context);
}