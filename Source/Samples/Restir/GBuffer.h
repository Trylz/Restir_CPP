#pragma once

#include "Singleton.h"
#include "Core/Pass/RasterPass.h"

namespace Restir
{
class GBuffer
{
public:
    GBuffer();

    void init(Falcor::ref<Falcor::Device> pDevice, Falcor::ref<Falcor::Scene> pScene, uint32_t width, uint32_t height);

    void render(Falcor::RenderContext* pRenderContext);

    inline const Falcor::ref<Falcor::Texture>& getCurrentPositionWsTexture() const { return mCurrentPositionWsTexture; }
    inline const Falcor::ref<Falcor::Texture>& getPreviousPositionWsTexture() const { return mPreviousPositionWsTexture; }

    inline const Falcor::ref<Falcor::Texture>& getCurrentNormalWsTexture() const { return mCurrentNormalWsTexture; }
    inline const Falcor::ref<Falcor::Texture>& getPreviousNormalWsTexture() const { return mPreviousNormalWsTexture; }

    inline const Falcor::ref<Falcor::Texture>& getAlbedoTexture() const { return mAlbedoTexture; }
    inline const Falcor::ref<Falcor::Texture>& getSpecularTexture() const { return mSpecularTexture; }

    inline void setNextFrame()
    {
        std::swap(mCurrentNormalWsTexture, mPreviousNormalWsTexture);
        std::swap(mCurrentPositionWsTexture, mPreviousPositionWsTexture);
    }

private:
    void createTextures();
    void compileProgram();

    Falcor::ref<Falcor::Device> mpDevice;
    Falcor::ref<Falcor::Scene> mpScene;

    uint32_t mWidth;
    uint32_t mHeight;

    Falcor::ref<Falcor::Texture> mCurrentPositionWsTexture;
    Falcor::ref<Falcor::Texture> mPreviousPositionWsTexture;

    Falcor::ref<Falcor::Texture> mAlbedoTexture;
    Falcor::ref<Falcor::Texture> mSpecularTexture;
    Falcor::ref<Falcor::Texture> mDepthTexture;

    Falcor::ref<Falcor::Texture> mCurrentNormalWsTexture;
    Falcor::ref<Falcor::Texture> mPreviousNormalWsTexture;

    ref<RasterPass> mpRasterPass;
    ref<Fbo> mpFbo;

    uint32_t mSampleIndex = 0u;
};

using GBufferSingleton = Singleton<GBuffer>;

} // namespace Restir

