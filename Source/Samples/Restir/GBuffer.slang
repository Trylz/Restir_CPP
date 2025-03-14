import Scene.Raster;
import Rendering.Lights.LightHelpers;

VSOut vsMain(VSIn vIn)
{
    return defaultVS(vIn);
}

struct GBufferPSOut
{
    float4 positionWs : SV_TARGET0;
    float4 normalWs : SV_TARGET1;
    float4 albedo : SV_TARGET2;
    float4 specular : SV_TARGET3;
};

GBufferPSOut psMain(VSOut vsOut, uint triangleIndex : SV_PrimitiveID) : SV_TARGET
{
    GBufferPSOut psOut = {};

    const ShadingData sd = prepareShadingData(vsOut, triangleIndex, viewDir);

    let mi = gScene.materials.getMaterialInstance(sd, lod);
    let bsdfProperties = mi.getProperties(sd);

    // Write the ws position.
    {
        psOut.posW = float4(sd.posW, 1.f);
    }

    // Write the ws normal.
    {
        const float3 viewDir = gScene.camera.getPosition() - sd.posW;
        psOut.normalWs = float4(sd.faceN, length(viewDir));
    }

    // Write the albedo.
    {
        psOut.albedo = float4(bsdfProperties.diffuseReflectionAlbedo, vsOut.materialID);
    }

    // Write the specular.
    {
        psOut.specular = float4(bsdfProperties.specularReflectionAlbedo, bsdfProperties.roughness);
    }

    return psOut;
}
