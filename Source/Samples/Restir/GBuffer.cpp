#include "GBuffer.h"

namespace Restir
{
using namespace Falcor;

GBuffer::GBuffer() {}

void GBuffer::init(ref<Device> pDevice, ref<Scene> pScene, uint32_t width, uint32_t height)
{
    mpDevice = pDevice;
    mpScene = pScene;
    mWidth = width;
    mHeight = height;

    createTextures();
    compileProgram();
}

void GBuffer::createTextures()
{
    mCurrentPositionWsTexture = mpDevice->createTexture2D(
        mWidth, mHeight, ResourceFormat::RGBA32Float, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess
    );

    mPreviousPositionWsTexture = mpDevice->createTexture2D(
        mWidth, mHeight, ResourceFormat::RGBA32Float, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess
    );

    mCurrentNormalWsTexture = mpDevice->createTexture2D(
        mWidth, mHeight, ResourceFormat::RGBA32Float, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess
    );

    mPreviousNormalWsTexture = mpDevice->createTexture2D(
        mWidth, mHeight, ResourceFormat::RGBA32Float, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess
    );

    mAlbedoTexture = mpDevice->createTexture2D(
        mWidth, mHeight, ResourceFormat::RGBA32Float, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess
    );

    mSpecularTexture = mpDevice->createTexture2D(
        mWidth, mHeight, ResourceFormat::RGBA32Float, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess
    );

    mDepthTexture = mpDevice->createTexture2D(
        mWidth, mHeight, ResourceFormat::D32Float, 1, 1, nullptr, ResourceBindFlags::DepthStencil
    );
}

void GBuffer::compileProgram()
{
    auto shaderModules = mpScene->getShaderModules();
    auto typeConformances = mpScene->getTypeConformances();
    auto defines = mpScene->getSceneDefines();

    ProgramDesc rasterProgDesc;
    rasterProgDesc.addShaderModules(shaderModules);
    rasterProgDesc.addShaderLibrary("Samples/Restir/GBuffer.slang").vsEntry("vsMain").psEntry("psMain");
    rasterProgDesc.addTypeConformances(typeConformances);

    mpRasterPass = RasterPass::create(mpDevice, rasterProgDesc, defines);
    mpFbo = Fbo::create(mpDevice);
}

void GBuffer::render(RenderContext* pRenderContext)
{
    FALCOR_PROFILE(pRenderContext, "GBuffer::render");

    mpFbo->attachColorTarget(mCurrentPositionWsTexture, 0u);
    mpFbo->attachColorTarget(mCurrentNormalWsTexture, 1u);
    mpFbo->attachColorTarget(mAlbedoTexture, 2u);
    mpFbo->attachColorTarget(mSpecularTexture, 3u);
    mpFbo->attachDepthStencilTarget(mDepthTexture);

    pRenderContext->clearDsv(mDepthTexture->getDSV().get(), 1.f, 0);
    mpRasterPass->getState()->setFbo(mpFbo);

    mpScene->rasterize(pRenderContext, mpRasterPass->getState().get(), mpRasterPass->getVars().get());
}

} // namespace Restir

