#pragma once

#include <SceneManagement/SceneManager.h>
#include <Core/Layer.h>

#include "MainScene.h"

class GameLayer : public SUN::Layer{ 
public:
    void OnAttach() override
    {
        mSceneManager.LoadScene<MainScene>();
    }

    void OnUpdate(const float& dt) override
    {
        mSceneManager.HandleInput();
        mSceneManager.Update(dt);
    }

    void OnRender() override
    {
        mSceneManager.Render();
    }

private:
    SUN::SceneManager mSceneManager;
};