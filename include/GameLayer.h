#pragma once

#include <SceneManagement/SceneManager.h>
#include <Core/Layer.h>
#include <AssetManagement/AssetManager.h>

#include "MainScene.h"

class GameLayer : public SUN::Layer{ 
public:
    explicit GameLayer(SUN::AssetManager& assetManager)
        : mAssetManager(assetManager)
    {
    }

    void OnAttach() override
    {
        mSceneManager.LoadScene<MainScene>(mAssetManager);
        mSceneManager.ApplyPendingScene();
    }

    void OnUpdate(const float& dt) override
    {
        mSceneManager.HandleInput();
        mSceneManager.Update(dt);

        mSceneManager.ApplyPendingScene();
    }

    void OnRender(SUN::RenderContext& context) override
    {
        mSceneManager.Render(context);
    }

private:
    SUN::AssetManager& mAssetManager;
    SUN::SceneManager mSceneManager;
};