#include "NRDEncoding.slangh"
#include "NRD.slangh"

cbuffer PerFrameCB
{
    uint2 viewportDims;
    float4x4 viewMat;
    float4x4 previousFrameViewProjMat;
    uint reservoirIdx;
    uint nbReservoirPerPixel;
};

RWTexture2D<float4> gOutRadianceHit;
StructuredBuffer<RestirReservoir> gReservoirs;

RWTexture2D<float4> gNormalLinearRoughness;
RWTexture2D<float> gViewZ;
RWTexture2D<float2> gMotionVector;

Texture2D<float4> gPositionWs;
Texture2D<float4> gAlbedo;
Texture2D<float4> gNormalWs;
Texture2D<float4> gSpecular;

int2 getPreviousFramePixelPos(float4 P, float width, float height)
{
    float4 ndc = mul(P, previousFrameViewProjMat);
    ndc = ndc / ndc.w;
    float2 s = (ndc.xy + float2(1, 1)) * 0.5f;
    s = float2(s.x, 1.f - s.y);
    return (int2)(s * float2(width, height));
}

[numthreads(16, 16, 1)]
void PackNRD(uint3 threadId: SV_DispatchThreadID)
{
    const uint2 pixel = threadId.xy;
    if (any(pixel >= viewportDims))
        return;

    const uint pixelLinearIndex = pixel.y * viewportDims.x + pixel.x;
    const size_t reservoirsStart = pixelLinearIndex * nbReservoirPerPixel;
    RestirReservoir r = gReservoirs[reservoirsStart + reservoirIdx];

    // Radiance hit
    gOutRadianceHit[pixel] = RELAX_FrontEnd_PackRadianceAndHitDist(r.mY.mIncomingRadiance, r.m_hitDistance, true);

    // Normal roughness
    gNormalLinearRoughness[pixel] = NRD_FrontEnd_PackNormalAndRoughness(gNormalWs[pixel].xyz, gSpecular[pixel].w, gAlbedo[pixel].w);

    // View Z and MVs
    const float4 P = gPositionWs[pixel];
    if (P.w!= 0.0f)
    {
        gViewZ[pixel] = mul(P, viewMat).z;

        int2 prevPixel = getPreviousFramePixelPos(P, (float)viewportDims.x, (float)viewportDims.y);
        prevPixel = clamp(prevPixel, int2(0, 0), int2(viewportDims.x - 1, viewportDims.y - 1));
        gMotionVector[pixel] = (float2)(pixel - prevPixel);
    }
    else
    {
        gViewZ[pixel] = 1e8f;
        gMotionVector[pixel] = 0.0f;
    }
}


