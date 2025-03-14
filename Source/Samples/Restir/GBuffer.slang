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

    const float3 faceNormal = gScene.getFaceNormalW(vsOut.instanceID, triangleIndex);
    const VertexData v = prepareVertexData(vsOut, faceNormal);
    const let lod = ImplicitLodTextureSampler();

    const float3 viewDir = normalize(gScene.camera.getPosition() - v.posW);
    const ShadingData sd = prepareShadingData(vsOut, triangleIndex, viewDir);

    let mi = gScene.materials.getMaterialInstance(sd, lod);
    let bsdfProperties = mi.getProperties(sd);

    // Write the ws position.
    {
        psOut.positionWs = float4(sd.posW, 1.f);
    }

    // Write the ws normal and hit distance.
    {
        psOut.normalWs = float4(sd.faceN, length(gScene.camera.getPosition() - sd.posW));
    }

    // Write the albedo and material id.
    {
        psOut.albedo = float4(bsdfProperties.diffuseReflectionAlbedo, vsOut.materialID);
    }

    // Write the specular and roughness.
    {
        psOut.specular = float4(bsdfProperties.specularReflectionAlbedo, bsdfProperties.roughness);
    }

    return psOut;
}
