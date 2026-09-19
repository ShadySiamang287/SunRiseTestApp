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

#include "FlyCameraSystem.h"

MainScene::MainScene() {
    using namespace SUN;

    const std::vector<SUN::Vertex> vertices = {
        //  position              normal            colour
        {{-0.5f, -0.5f, 1.f}, {0.f, 0.f, 1.f}, {1.0f, 0.0f, 0.0f}}, // bottom-left  red
        {{ 0.5f, -0.5f, 1.f}, {0.f, 0.f, 1.f}, {0.0f, 1.0f, 0.0f}}, // bottom-right green
        {{ 0.5f,  0.5f, 1.f}, {0.f, 0.f, 1.f}, {0.0f, 0.0f, 1.0f}}, // top-right    blue
        {{-0.5f,  0.5f, 1.f}, {0.f, 0.f, 1.f}, {1.0f, 1.0f, 1.0f}}  // top-left     white
    };
    const std::vector<uint32_t> indices = { 0, 1, 2, 2, 3, 0 };

    // Mesh B: triangle, a different colour set so the two meshes can't be confused
    const std::vector<SUN::Vertex> triVertices = {
        {{-0.5f, -0.5f, 1.f}, {0.f, 0.f, 1.f}, {1.0f, 1.0f, 0.0f}}, // bottom-left  yellow
        {{ 0.5f, -0.5f, 1.f}, {0.f, 0.f, 1.f}, {0.0f, 1.0f, 1.0f}}, // bottom-right cyan
        {{ 0.0f,  0.5f, 1.f}, {0.f, 0.f, 1.f}, {1.0f, 0.0f, 1.0f}}  // top          magenta
    };
    const std::vector<uint32_t> triIndices = { 0, 1, 2 };


    Entity camEntity = CreateEntity("Camera");
    camEntity.AddComponent<CameraComponent>();
    camEntity.AddComponent<FlyCameraComponent>();
    auto& cam = camEntity.GetComponent<CameraComponent>().Camera;
    cam.Position = {0.f, 0.f, 7.f}; // TEST: pulled back so the whole grid is visible (was 1.0f + 0.866f)

    // ---- Instancing test ----
    auto makeMesh = [](const std::vector<SUN::Vertex>& verts, const std::vector<uint32_t>& idx) {
        std::shared_ptr<Mesh> mesh = std::make_shared<Mesh>();
        mesh->buffer.Init(verts.data(), verts.size() * sizeof(SUN::Vertex), sizeof(SUN::Vertex),
                          idx.data(), idx.size() * sizeof(uint32_t), vk::IndexType::eUint32);
        return mesh;
    };

    std::shared_ptr<Mesh> quad = makeMesh(vertices, indices);        // batch A, 6 indices
    std::shared_ptr<Mesh> triangle = makeMesh(triVertices, triIndices); // batch B, 3 indices

    auto spawn = [this](const std::string& name, const std::shared_ptr<Mesh>& mesh,
                        glm::vec3 position, glm::vec3 scale = glm::vec3(1.f), float rotZDegrees = 0.f) {
        Entity e = CreateEntity(name);
        e.AddComponent<MeshComponent>().mesh = mesh;

        auto& t = e.GetComponent<TransformComponent>();
        t.Position = position;
        t.Scale = scale;
        t.Rotation = glm::angleAxis(glm::radians(rotZDegrees), glm::vec3(0.f, 0.f, 1.f));
        return e;
    };

    // Row 1: 8 entities alternating quad, triangle, quad, triangle... The sort has to group them.
    for (int i = 0; i < 8; ++i) {
        spawn("Row_" + std::to_string(i), (i % 2 == 0) ? quad : triangle,
              glm::vec3((i - 3.5f) * 1.4f, 1.0f, 0.f), glm::vec3(0.8f));
    }

    // Row 2: rotation and non-uniform scale, to prove the model matrix isn't just translation
    spawn("Rotated_Quad",      quad,     glm::vec3(-1.5f, -1.0f, 0.f), glm::vec3(1.f), 45.f);
    spawn("Stretched_Triangle", triangle, glm::vec3( 1.5f, -1.0f, 0.f), glm::vec3(2.f, 0.5f, 1.f));

}

MainScene::~MainScene() {

}

void MainScene::Update(const float& dt) {
    FlyCameraSystem::Update(mRegistry, dt);
}

void MainScene::Render(SUN::RenderContext& context) {

    auto camView = mRegistry.view<SUN::CameraComponent>();
    SUN::Camera cam = camView.get<SUN::CameraComponent>(camView.front()).Camera;

    auto& renderer = context.renderer;
    renderer->BeginScene(cam);
    SUN::RenderSystem::Render(*this, renderer);
    renderer->EndScene(context);
}