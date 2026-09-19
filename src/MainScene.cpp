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

    // -------------------------------------------------------------------------
    // Geometry
    // -------------------------------------------------------------------------

    const std::vector<Vertex> vertices = {
        // position               normal            colour
        {{-0.5f, -0.5f, 0.0f}, {0.f, 0.f, 1.f}, {1.0f, 1.0f, 1.0f}},
        {{ 0.5f, -0.5f, 0.0f}, {0.f, 0.f, 1.f}, {1.0f, 1.0f, 1.0f}},
        {{ 0.5f,  0.5f, 0.0f}, {0.f, 0.f, 1.f}, {1.0f, 1.0f, 1.0f}},
        {{-0.5f,  0.5f, 0.0f}, {0.f, 0.f, 1.f}, {1.0f, 1.0f, 1.0f}}
    };

    const std::vector<uint32_t> indices = {
        0, 1, 2,
        2, 3, 0
    };

    auto mesh = std::make_shared<Mesh>();

    mesh->buffer.Init(
        vertices.data(),
        vertices.size() * sizeof(Vertex),
        sizeof(Vertex),

        indices.data(),
        indices.size() * sizeof(uint32_t),

        vk::IndexType::eUint32
    );


    // -------------------------------------------------------------------------
    // Camera
    // -------------------------------------------------------------------------

    Entity cameraEntity = CreateEntity("Camera");

    cameraEntity.AddComponent<CameraComponent>();
    cameraEntity.AddComponent<FlyCameraComponent>();

    auto& camera =
        cameraEntity.GetComponent<CameraComponent>().Camera;

    camera.Position = {
        0.0f,
        0.0f,
        7.0f
    };


    // -------------------------------------------------------------------------
    // Helper for spawning test planes
    // -------------------------------------------------------------------------

    auto spawnPlane =
        [this, &mesh](
            const std::string& name,
            glm::vec3 position,
            glm::vec3 scale,
            glm::quat rotation)
        {
            Entity entity = CreateEntity(name);

            entity.AddComponent<MeshComponent>().mesh =
                mesh;

            auto& transform =
                entity.GetComponent<TransformComponent>();

            transform.Position = position;
            transform.Scale = scale;
            transform.Rotation = rotation;

            return entity;
        };


    // -------------------------------------------------------------------------
    // Lighting test geometry
    // -------------------------------------------------------------------------

    // Flat plane directly facing the camera/light.
    spawnPlane(
        "Centre",
        glm::vec3(0.0f, 0.0f, 0.0f),
        glm::vec3(1.5f),
        glm::quat(1.0f, 0.0f, 0.0f, 0.0f)
    );

    // Tilted around Y.
    // This should receive visibly less directional light than Centre.
    spawnPlane(
        "TiltedLeft",
        glm::vec3(-2.0f, 0.0f, 0.0f),
        glm::vec3(1.5f),
        glm::angleAxis(
            glm::radians(-45.0f),
            glm::vec3(0.0f, 1.0f, 0.0f)
        )
    );

    // Tilted the other direction.
    spawnPlane(
        "TiltedRight",
        glm::vec3(2.0f, 0.0f, 0.0f),
        glm::vec3(1.5f),
        glm::angleAxis(
            glm::radians(45.0f),
            glm::vec3(0.0f, 1.0f, 0.0f)
        )
    );

    // Non-uniform scaling test.
    // Useful for checking your inverse-transpose normal matrix.
    spawnPlane(
        "NonUniformScale",
        glm::vec3(0.0f, -2.0f, 0.0f),
        glm::vec3(2.0f, 0.75f, 1.0f),
        glm::angleAxis(
            glm::radians(30.0f),
            glm::vec3(1.0f, 0.0f, 0.0f)
        )
    );


    // -------------------------------------------------------------------------
    // Directional light
    // -------------------------------------------------------------------------

    Entity directionalEntity =
        CreateEntity("Directional Light");

    auto& directional =
        directionalEntity
            .AddComponent<DirectionalLightComponent>();

    directional.Colour = {
        1.0f,
        0.95f,
        0.85f
    };

    directional.intensity = 0.6f;

    auto& directionalTransform =
        directionalEntity.GetComponent<TransformComponent>();

    // Your RenderSystem calculates:
    //
    // direction =
    //     Rotation * vec3(0, 0, -1)
    //
    // An identity rotation therefore gives direction (0,0,-1).
    //
    // Your shader then uses -direction as the vector TO the light,
    // giving (0,0,+1), which matches these planes' +Z normals.
    directionalTransform.Rotation =
        glm::quat(
            1.0f,
            0.0f,
            0.0f,
            0.0f
        );


    // -------------------------------------------------------------------------
    // Point light
    // -------------------------------------------------------------------------

    Entity pointEntity =
        CreateEntity("Point Light");

    auto& point =
        pointEntity.AddComponent<PointLightComponent>();

    point.Colour = {
        0.25f,
        0.5f,
        1.0f
    };

    point.intensity = 20.0f;
    point.range = 10.0f;

    auto& pointTransform =
        pointEntity.GetComponent<TransformComponent>();

    // In front of the planes toward the camera.
    pointTransform.Position = {
        1.5f,
        1.0f,
        3.0f
    };
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