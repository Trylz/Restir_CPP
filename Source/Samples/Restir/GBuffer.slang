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

    float3 faceNormal = gScene.getFaceNormalW(vsOut.instanceID, triangleIndex);
    VertexData v = prepareVertexData(vsOut, faceNormal);
    let lod = ImplicitLodTextureSampler();

    const float3 viewDir = normalize(gScene.camera.getPosition() - v.posW);
    const ShadingData sd = prepareShadingData(vsOut, triangleIndex, viewDir);

    let mi = gScene.materials.getMaterialInstance(sd, lod);
    let bsdfProperties = mi.getProperties(sd);

    // Write the ws position.
    {
        psOut.positionWs = float4(sd.posW, 1.f);
    }

    // Write the ws normal.
    {
        psOut.normalWs = float4(sd.faceN, length(gScene.camera.getPosition() - sd.posW));
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
