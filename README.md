# pbrTemplatePrj

[English](README.md) | [简体中文](README.zh-CN.md)


A PBR rendering project template (URP) with a set of reusable "Box" effect shaders and learning demos.

## Overview

PBR rendering project template for the Universal Render Pipeline. It provides a full-featured PBR base shader (`URP/pbr1`), a collection of common effects ("Box" series: decal / snow / lighting / blur / fog ...), URP template shaders (terrain lit, unlit, skybox ...), and shader-learning demos. All effects live in one asset folder, with heavy reuse of the sibling **PowerShaderLib** include library.

## Includes / Features

### pbrTemplate — PBR base shader + volume cloud example
| File | Shader / Class | Description |
| --- | --- | --- |
| `pbr1/pbr1.shader` | `URP/pbr1` | Full PBR shader: base color/normal/PBR-mask maps, 3 lighting models (PBR / Aniso / Charlie), GI reflections (grazing term), main+additional light shadows with custom bias, emission + GI, thin film, parallax, depth/height fog, AnimTex GPU animation & GPU skinning, stencil / alpha / blend presets; passes: Forward, DepthOnly, ShadowCaster, Meta |
| `pbr1/pbr1_learn.shader` | `URP/pbr1_learn` | Simplified learning version of pbr1 (base maps + metallic/smoothness/occlusion only) |
| `pbr1/Lib/PBRInput.hlsl`, `PBRForwardPass.hlsl` | - | Shader input / forward pass includes (depend on PowerShaderLib: UnityLib, TangentLib, BSDF, Colors, FogLib, MaterialLib, Lighting, ParallaxLib, AnimTextureLib) |
| `pbrTemplate.asmdef` | `pbrTemplate` | Assembly definition (references shared PowerXXX GUIDs incl. PowerUtilities) |
| `Scenes/Volume/Cloud.shader` | `Hidden/Cloud` | Volume cloud example: ray-marching a sphere inside the camera-depth reconstructed world space |
| `Scenes/Volume/TestCloud.cs` | `TestCloud` (ScriptableRendererFeature via `PowerUtilities.RenderFeatures.SRPPass`) | Renderer feature that finds `Hidden/Cloud` and blits it into a temp RT |
| `Scenes/Volume/Lib/CommonUtils.hlsl` | - | Depth linearization (`LinearizeDepth`) + `ScreenToWorldPos` helpers |

### CommonShaders — blur / billboard / planar shadow
| File | Shader / Class | Description |
| --- | --- | --- |
| `Blur/Shaders/GaussianBlur.shader` | `Hidden/Blur/GaussianBlur` | Separable Gaussian(7-tap) blur, horizontal + vertical passes, `_Scale` and blit-triangle (`FullScreenTriangleVert`) support |
| `Blur/Scripts/GaussianKernel.cs` | `GaussianKernel` + editor `Calc Kernel` button | Editor tool that computes / logs a normalized N×N Gaussian weight kernel |
| `Blur/Shaders/BlurBackground.shader` | `Unlit/Blur/BlurBackground` | Screen-space background blur of `_CameraOpaqueTexture` (BoxBlur3 / Gaussian7 modes + noise offset), fade to main texture |
| `Blur/Shaders/BlurBackground_drp.shader` | `Unlit/Blur/Gaussian/BlurBackground_drp` | Built-in (DRP) variant using `GrabPass` |
| `Blur/Test/TestBlur.unity` | - | Blur test scene + `Unlit_GaussBlur.mat` |
| `Billboard/Bill.shader` (+ `BillLib.hlsl`) | `URP/Unlit/Bill` | Billboard (XY-plane or full face camera) with diffuse ramp lighting, matcap, fog, wind vertex-color animation, snow, rotated shadows |
| `Parallax/ParallaxOcclusion.shader` | `URP/Unlit/ParallaxOcclusion` | Parallax occlusion example |
| `PlanarShadow_URP.shader` | `Character/PlanarShadow_URP` | Planar shadow projected from the main light direction + player position (stencil, distance attenuation); reuses URP Lit `ForwardLit` as base pass |

### Box — effect shader collection (fullscreen post / object VFX, URP)
| Folder | Shader | Description |
| --- | --- | --- |
| `Box/BoxDecal` | `FX/Box/BoxDecal` | Unlit depth-based bounding-box decal (project camera depth into object space), optional gradient-noise distortion + fog blend (`Unlit_BoxDecal_1/2.mat`) |
| `Box/BoxSnow` | `FX/Box/Snow` | Screen-space snow overlay limited by world height and screen range |
| `Box/BoxLight` | `Hidden/FX/Box/BoxLighting` | Fullscreen light effect: dir/point/spot light, main-light shadow + "big shadow", and in-box 3D noise volume scattering (BoxVolumeLib) |
| `Box/BoxBlur` | `FX/Box/Blur/Box_PostEffects` | Blur + chromatic aberration + vignette post effect (`Box_PostEffects_WaterProfile.mat`, `Unlit_Box_PostEffects.mat`) |
| `Box/BoxSceneFog` | `FX/Box/Nature/BoxSceneFog` | Scene fog: main + detail noise maps, mask texture, height fog (`Nature_BoxSceneFog.mat`) |
| `Box/BoxFog` | `FX/Box/BoxExpFog` | Exponential fog with height/depth density & falloff and start distance (`FX_Box_BoxExpFog.mat`) |
| other Box folders | `FX/Box/AO`, `FX/Box/Scan`, `FX/Box/Kernels`, `FX/Box/Template`, `Hidden/FX/Others/BoxVignetting`, `FX/Box/BoxRadialBlur`, `FX/Box/Nature/BoxClouds3`, `Unlit/TestRaymarch`, `FX/Box/BoxCloudShadow` | Additional experiments: AO, scan, kernel, template, vignetting, radial blur, clouds (raymarch / fullscreen) and cloud shadow |

### URPTemplate — URP template shaders
| File | Shader | Description |
| --- | --- | --- |
| `Terrain/TerrainLit_WorldPosSample/TerrainLit.shader` | `URP/Terrain/Lit_WorldSample` | Terrain lit shader with height blend; split base/add/basemap-gen passes (`TerrainLitBase/Add/BasemapGen.shader`) + `TerrainLitInput/Passes/Meta/DepthNormalsPass.hlsl` |
| `Unlit/RadialFade.shader` | `UITK/Default` | Radial fade shader with `_Progress`, ramp and mask maps |
| `Unlit/*` | `URP/Unlit/Template`, `URP/Unlit/Instanced`, `Template/Unlit/InstancedLightmap`, `URP/Unlit/ScreenColor`, `Template/Unlit/VertexMoveByColorId`, `Template/Unlit/Lightmap`, `Template/Unlit/DepthOnly`, `Template/Unlit/StencilColorOnly`, `URP/Unlit/Color_MRT`, `Unlit/FX/Border4Fading`, `Hidden/StateTemplate` | Unlit / template variants: instancing, lightmap, screen color, vertex-color animation, color MRT, border fading, state template |
| `Skybox/*` | `Template/Unlit/SkyBox_Rotated`, `Template/Unlit/SkyBox_InteriorMap` | Rotating skybox and interior-map skybox |

### TMPProShaderEx — TextMeshPro shader extension
| File | Description |
| --- | --- |
| `TMPro_Mobile.cginc` (+ `TMPro.cginc`, `TMPro_Surface.cginc`, `TMPro_Properties.cginc`) | Modified TMPro mobile shader library (vertex/pixel structs, `SRGBToLinear` when `FORCE_LINEAR`) |
| `TMP_SDF-Mobile_FixedOutlineWidth.shader` | `TextMeshPro/Mobile/Distance Field - FixedOutlineWidth` — mobile SDF with fixed outline width |
| `TMP_SDF-Gamma.shader` | `TextMeshPro/Distance Field-Gamma` — gamma-space SDF variant |

### UIFx — UI effect shader
| File | Shader | Description |
| --- | --- | --- |
| `UIFx.shader` (+ `UIFxCore.hlsl`) | `Unlit/UIFx` | UI effect shader with SDF rounded-rect mask (`_Min`/`_Max`) applied to the main texture (`Unlit_UIFx.mat`) |

### ShaderProjectDemo — shader learning demos
`SubShaderDetails`, `SRPBatchAndInstanced`, `ShaderFunctionOverrideDemo`, `ShaderFlowOverrideDemo`, `MacroDefineDemo` (demonstrating macro defines + `Lib/_DemoLib.hlsl`, `Lib/ShaderFlowPass{Version1,Version2}.hlsl`), `TestLOD.cs` (`Shader.globalMaximumLOD` demo), `Unlit_SRPBatchAndInstanced.mat`. These show SubShader/LOD, SRP batching + instancing, preprocessor function overriding, macro definitions, and shader-flow override patterns. (`MacroDefineDemo .md` is a stray copy of the MacroDefineDemo shader.)

### Arts / Test
- `Arts/`: texture assets used by demos — `white/black/gray.psd`, `alpha_r_border4fading.psd`, `controlMap_1234.psd`, `earth.jpg`.
- `Test/`: `Unlit/TestDepth2`, `TestParallax`, `Test ColorTransform/` (color-space test scene + `ColorSpace.hlsl`, `Ref/overlay.hlsl`, sample photos), `Custom_PlanarShadow_URP.mat`, demo scenes `PbrTemplateTest.unity` / `Test ColorTransform/TestColorTransform.unity`.

## Folder structure

```
pbrTemplatePrj/
├── pbrTemplate/                # PBR base shader + asmdef + volume cloud example
│   ├── pbr1/                   #   pbr1.shader / pbr1_learn.shader + Lib(PBRInput, PBRForwardPass)
│   ├── Scenes/Volume/          #   Cloud.shader + TestCloud.cs + Lib/CommonUtils.hlsl
│   └── pbrTemplate.asmdef
├── CommonShaders/              # GaussianBlur + GaussianKernel.cs, BlurBackground(+drp), Bill, ParallaxOcclusion, PlanarShadow_URP
├── Box/                        # Box* effect collection (Decal, Snow, Light, Blur, SceneFog, Fog + AO/Scan/Kernel/Template/Vignetting/RadialBlur/Clouds/CloudShadow)
├── URPTemplate/                # Terrain(Lit_WorldSample) / Unlit templates / Skybox
├── TMPProShaderEx/             # TMPro shader extension (TMPro_Mobile.cginc + 2 shaders)
├── UIFx/                       # Unlit/UIFx
├── ShaderProjectDemo/          # shader learning demos + TestLOD.cs
├── Arts/                       # texture assets
└── Test/                       # misc test shaders/scenes/materials
```

## Requirements

- **Unity URP** (Universal Render Pipeline) — shaders include `com.unity.render-pipelines.universal` / `com.unity.render-pipelines.core` shader libraries; `PlanarShadow_URP` reuses the URP Lit `ForwardLit` pass.
- **PowerShaderLib** (sibling package in PowerXXX) — shader-only include library referenced by relative path (`../../../../PowerShaderLib/...`): UnityLib, BSDF, FogLib, BlurLib, SDF, NoiseLib, FullscreenLib, ScreenTextures, BigShadows, BoxVolumeLib, etc. (no asmdef; required for every effect shader).
- **PowerUtilities** — referenced by `pbrTemplate.asmdef` (GUID `4d7978c8...`) and used at runtime by `TestCloud.cs` (`PowerUtilities.RenderFeatures.SRPPass`).

## Reference Gits

(No git/URL references are present in this package's files. This package is a submodule inside the PowerXXX container repo — see the parent `PowerXXX/README.md` for the subpackage index and docs.)