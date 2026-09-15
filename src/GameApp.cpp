#include <EntryPoint.h>
#include "MainScene.h"

class GameApp : public SUN::Application{
public:
    GameApp(){
        mCurrentScenePtr = std::make_unique<MainScene>();
    }

};

SUN::Application* SUN::CreateApplication() {
    return new GameApp();
}
