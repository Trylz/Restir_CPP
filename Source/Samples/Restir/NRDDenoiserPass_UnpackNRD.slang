#include "NRDEncoding.slangh"
#include "NRD.slangh"

cbuffer PerFrameCB
{
    uint2 viewportDims;
    uint reservoirIdx;
    uint nbReservoirPerPixel;
};

Texture2D<float4> gNRDOutput;
RWStructuredBuffer<RestirReservoir> gReservoirs;

[numthreads(16, 16, 1)] void UnpackNRD(uint3 threadId
                                       : SV_DispatchThreadID)
{
    const uint2 pixel = threadId.xy;
    if (any(pixel >= viewportDims))
        return;

    const uint pixelLinearIndex = pixel.y * viewportDims.x + pixel.x;
    const size_t reservoirsStart = pixelLinearIndex * nbReservoirPerPixel;

    RestirReservoir r = gReservoirs[reservoirsStart + reservoirIdx];
    r.mY.mIncomingRadiance = gNRDOutput[pixel];

    gReservoirs[reservoirsStart + reservoirIdx] = r;
}


