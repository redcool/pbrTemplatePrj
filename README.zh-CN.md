# pbrTemplatePrj

[English](README.md) | [简体中文](README.zh-CN.md)

## 简介

pbrTemplatePrj 是一个基于 URP（通用渲染管线）的 PBR 渲染项目模板，附带一组可复用的 "Box" 系列特效着色器（shader）与学习示例。

该模板面向通用渲染管线（Universal Render Pipeline，URP）。它提供了一个功能完整的 PBR 基础着色器（`URP/pbr1`）、一组常用特效（"Box" 系列：贴花 decal / 雪 snow / 光照 lighting / 模糊 blur / 雾效 fog ...）、URP 模板着色器（terrain lit 地形光照、unlit 无光照、skybox 天空盒 ...）以及着色器学习示例。所有特效均位于同一资源目录下，并大量复用同级包 **PowerShaderLib** 的 include 库。

## 功能特性（Features）

### pbrTemplate — PBR 基础着色器 + 体积云示例

| 文件 | 着色器 / 类 | 说明 |
| --- | --- | --- |
| `pbr1/pbr1.shader` | `URP/pbr1` | 完整 PBR 着色器：基础色 / 法线 / PBR 遮罩贴图、3 种光照模型（PBR / Aniso / Charlie）、GI 反射（掠射项 grazing term）、主光 + 附加光的带自定义偏移阴影、自发光 + GI、薄膜（thin film）、视差（parallax）、深度 / 高度雾效、AnimTex GPU 动画与 GPU 蒙皮、模板（stencil）/ alpha / 混合预设；Pass：Forward、DepthOnly、ShadowCaster、Meta |
| `pbr1/pbr1_learn.shader` | `URP/pbr1_learn` | pbr1 的简化学习版（仅基础贴图 + 金属度 / 光滑度 / 遮蔽） |
| `pbr1/Lib/PBRInput.hlsl`、`PBRForwardPass.hlsl` | - | 着色器输入 / 前向 Pass 的 include 文件（依赖 PowerShaderLib：UnityLib、TangentLib、BSDF、Colors、FogLib、MaterialLib、Lighting、ParallaxLib、AnimTextureLib） |
| `pbrTemplate.asmdef` | `pbrTemplate` | 程序集定义（引用共享的 PowerXXX GUID，包含 PowerUtilities） |
| `Scenes/Volume/Cloud.shader` | `Hidden/Cloud` | 体积云示例：在相机深度重建的世界空间中对球体进行光线步进（ray-marching） |
| `Scenes/Volume/TestCloud.cs` | `TestCloud`（通过 `PowerUtilities.RenderFeatures.SRPPass` 实现的 ScriptableRendererFeature） | 查找 `Hidden/Cloud` 并将其 blit 到临时 RT 的渲染器特性（Renderer Feature） |
| `Scenes/Volume/Lib/CommonUtils.hlsl` | - | 深度线性化（`LinearizeDepth`）+ `ScreenToWorldPos` 辅助函数 |

### CommonShaders — 模糊 / 广告牌 / 平面阴影

| 文件 | 着色器 / 类 | 说明 |
| --- | --- | --- |
| `Blur/Shaders/GaussianBlur.shader` | `Hidden/Blur/GaussianBlur` | 分离式高斯（7 tap）模糊，水平 + 垂直两个 Pass，支持 `_Scale` 与 blit 三角形（`FullScreenTriangleVert`） |
| `Blur/Scripts/GaussianKernel.cs` | `GaussianKernel` + 编辑器 `Calc Kernel` 按钮 | 计算并输出归一化 N×N 高斯权重核的编辑器工具 |
| `Blur/Shaders/BlurBackground.shader` | `Unlit/Blur/BlurBackground` | 对 `_CameraOpaqueTexture` 做屏幕空间背景模糊（BoxBlur3 / Gaussian7 模式 + 噪声偏移），可淡出到主纹理 |
| `Blur/Shaders/BlurBackground_drp.shader` | `Unlit/Blur/Gaussian/BlurBackground_drp` | 使用 `GrabPass` 的内置渲染管线（DRP）版本 |
| `Blur/Test/TestBlur.unity` | - | 模糊测试场景 + `Unlit_GaussBlur.mat` |
| `Billboard/Bill.shader`（+ `BillLib.hlsl`） | `URP/Unlit/Bill` | 广告牌（XY 平面或始终面向相机的完整面向）着色器，带漫反射 ramp 光照、matcap、雾效、风场顶点色动画、雪、旋转阴影 |
| `Parallax/ParallaxOcclusion.shader` | `URP/Unlit/ParallaxOcclusion` | 视差遮蔽（parallax occlusion）示例 |
| `PlanarShadow_URP.shader` | `Character/PlanarShadow_URP` | 由主光方向 + 玩家位置投影出的平面阴影（模板 stencil、距离衰减）；复用 URP Lit 的 `ForwardLit` 作为基础 Pass |

### Box — 特效着色器集合（全屏后处理 / 物体 VFX，URP）

| 文件夹 | 着色器 | 说明 |
| --- | --- | --- |
| `Box/BoxDecal` | `FX/Box/BoxDecal` | 基于深度的无光照包围盒贴花（将相机深度投影到物体空间），可选渐变噪声扭曲 + 雾效混合（`Unlit_BoxDecal_1/2.mat`） |
| `Box/BoxSnow` | `FX/Box/Snow` | 受世界高度与屏幕范围限制的屏幕空间降雪叠加 |
| `Box/BoxLight` | `Hidden/FX/Box/BoxLighting` | 全屏光照效果：平行光 / 点光 / 聚光、主光阴影 + "大阴影"、盒内 3D 噪声体积散射（BoxVolumeLib） |
| `Box/BoxBlur` | `FX/Box/Blur/Box_PostEffects` | 模糊 + 色差 + 暗角后处理效果（`Box_PostEffects_WaterProfile.mat`、`Unlit_Box_PostEffects.mat`） |
| `Box/BoxSceneFog` | `FX/Box/Nature/BoxSceneFog` | 场景雾效：主 + 细节噪声贴图、遮罩纹理、高度雾（`Nature_BoxSceneFog.mat`） |
| `Box/BoxFog` | `FX/Box/BoxExpFog` | 带高度 / 深度密度与衰减、起始距离的指数雾（`FX_Box_BoxExpFog.mat`） |
| 其他 Box 文件夹 | `FX/Box/AO`、`FX/Box/Scan`、`FX/Box/Kernels`、`FX/Box/Template`、`Hidden/FX/Others/BoxVignetting`、`FX/Box/BoxRadialBlur`、`FX/Box/Nature/BoxClouds3`、`Unlit/TestRaymarch`、`FX/Box/BoxCloudShadow` | 其他实验效果：AO、扫描、核、模板、暗角、径向模糊、云（光线步进 / 全屏）与云的阴影 |

### URPTemplate — URP 模板着色器

| 文件 | 着色器 | 说明 |
| --- | --- | --- |
| `Terrain/TerrainLit_WorldPosSample/TerrainLit.shader` | `URP/Terrain/Lit_WorldSample` | 带高度混合的地形光照着色器；分为 base / add / basemap-gen Pass（`TerrainLitBase/Add/BasemapGen.shader`）+ `TerrainLitInput/Passes/Meta/DepthNormalsPass.hlsl` |
| `Unlit/RadialFade.shader` | `UITK/Default` | 带 `_Progress`、ramp 与遮罩贴图的径向渐隐着色器 |
| `Unlit/*` | `URP/Unlit/Template`、`URP/Unlit/Instanced`、`Template/Unlit/InstancedLightmap`、`URP/Unlit/ScreenColor`、`Template/Unlit/VertexMoveByColorId`、`Template/Unlit/Lightmap`、`Template/Unlit/DepthOnly`、`Template/Unlit/StencilColorOnly`、`URP/Unlit/Color_MRT`、`Unlit/FX/Border4Fading`、`Hidden/StateTemplate` | 无光照 / 模板变体：实例化、光照贴图、屏幕颜色、顶点色动画、颜色 MRT、边框渐隐、状态模板 |
| `Skybox/*` | `Template/Unlit/SkyBox_Rotated`、`Template/Unlit/SkyBox_InteriorMap` | 旋转天空盒与内置贴图天空盒 |

### TMPProShaderEx — TextMeshPro 着色器扩展

| 文件 | 说明 |
| --- | --- |
| `TMPro_Mobile.cginc`（+ `TMPro.cginc`、`TMPro_Surface.cginc`、`TMPro_Properties.cginc`） | 修改过的 TMPro 移动端着色器库（顶点 / 片元结构体，`FORCE_LINEAR` 时执行 `SRGBToLinear`） |
| `TMP_SDF-Mobile_FixedOutlineWidth.shader` | `TextMeshPro/Mobile/Distance Field - FixedOutlineWidth` — 固定描边宽度的移动端 SDF |
| `TMP_SDF-Gamma.shader` | `TextMeshPro/Distance Field-Gamma` — gamma 空间的 SDF 变体 |

### UIFx — UI 特效着色器

| 文件 | 着色器 | 说明 |
| --- | --- | --- |
| `UIFx.shader`（+ `UIFxCore.hlsl`） | `Unlit/UIFx` | 带 SDF 圆角矩形遮罩（`_Min` / `_Max`）并作用于主纹理的 UI 特效着色器（`Unlit_UIFx.mat`） |

### ShaderProjectDemo — 着色器学习示例

`SubShaderDetails`、`SRPBatchAndInstanced`、`ShaderFunctionOverrideDemo`、`ShaderFlowOverrideDemo`、`MacroDefineDemo`（演示宏定义 + `Lib/_DemoLib.hlsl`、`Lib/ShaderFlowPass{Version1,Version2}.hlsl`）、`TestLOD.cs`（`Shader.globalMaximumLOD` 演示）、`Unlit_SRPBatchAndInstanced.mat`。这些示例展示了 SubShader / LOD、SRP 合批 + 实例化、预处理器函数覆写、宏定义以及着色器流程覆写（shader-flow override）模式。（`MacroDefineDemo .md` 是 MacroDefineDemo 着色器的散落副本。）

### Arts / Test

- `Arts/`：示例使用的纹理资源 — `white/black/gray.psd`、`alpha_r_border4fading.psd`、`controlMap_1234.psd`、`earth.jpg`。
- `Test/`：`Unlit/TestDepth2`、`TestParallax`、`Test ColorTransform/`（色彩空间测试场景 + `ColorSpace.hlsl`、`Ref/overlay.hlsl`、示例照片）、`Custom_PlanarShadow_URP.mat`、示例场景 `PbrTemplateTest.unity` / `Test ColorTransform/TestColorTransform.unity`。

## 目录结构（Folder structure）

```
pbrTemplatePrj/
├── pbrTemplate/                # PBR 基础着色器 + asmdef + 体积云示例
│   ├── pbr1/                   #   pbr1.shader / pbr1_learn.shader + Lib(PBRInput, PBRForwardPass)
│   ├── Scenes/Volume/          #   Cloud.shader + TestCloud.cs + Lib/CommonUtils.hlsl
│   └── pbrTemplate.asmdef
├── CommonShaders/              # GaussianBlur + GaussianKernel.cs、BlurBackground(+drp)、Bill、ParallaxOcclusion、PlanarShadow_URP
├── Box/                        # Box* 特效集合（Decal、Snow、Light、Blur、SceneFog、Fog + AO/Scan/Kernel/Template/Vignetting/RadialBlur/Clouds/CloudShadow）
├── URPTemplate/                # Terrain(Lit_WorldSample) / Unlit 模板 / Skybox
├── TMPProShaderEx/             # TMPro 着色器扩展（TMPro_Mobile.cginc + 2 个着色器）
├── UIFx/                       # Unlit/UIFx
├── ShaderProjectDemo/          # 着色器学习示例 + TestLOD.cs
├── Arts/                       # 纹理资源
└── Test/                       # 杂项测试着色器 / 场景 / 材质球
```

## 使用说明（Usage）

- **Unity URP（通用渲染管线）** — 着色器包含 `com.unity.render-pipelines.universal` / `com.unity.render-pipelines.core` 着色器库；`PlanarShadow_URP` 复用了 URP Lit 的 `ForwardLit` Pass。
- **PowerShaderLib**（PowerXXX 中的同级包）— 仅含着色器的 include 库，通过相对路径（`../../../../PowerShaderLib/...`）引用：UnityLib、BSDF、FogLib、BlurLib、SDF、NoiseLib、FullscreenLib、ScreenTextures、BigShadows、BoxVolumeLib 等（无 asmdef；每个特效着色器都依赖它）。
- **PowerUtilities** — 被 `pbrTemplate.asmdef` 引用（GUID `4d7978c8...`），并在运行时由 `TestCloud.cs`（`PowerUtilities.RenderFeatures.SRPPass`）使用。

## 参考仓库 / 依赖（Reference Gits）

本包的文件中不包含任何 git / URL 引用。此包是 PowerXXX 容器仓库内的一个子模块（submodule）— 子包索引与相关文档请参见父级 `PowerXXX/README.md`。

## 备注 / 更新记录（Notes / Changelog）

原英文 README 中未包含单独的更新记录（changelog）章节；本中文文档与英文版本内容保持逐条一一对应，未新增任何额外条目。
