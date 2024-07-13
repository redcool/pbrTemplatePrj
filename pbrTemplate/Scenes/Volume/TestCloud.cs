using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class TestCloud : ScriptableRendererFeature
{
    class CustomRenderPass : ScriptableRenderPass
    {
        static bool isInited;

        public int _ResultTex = Shader.PropertyToID("_ResultTex");
        Material mat;
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            if (!isInited)
            {
                

                isInited = true;
            }
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (!mat)
                mat = new Material(Shader.Find("Hidden/Cloud"));

            ref var cameraData = ref renderingData.cameraData;
            var renderer = cameraData.renderer;


            var cmd = CommandBufferPool.Get();
            cmd.BeginSample(nameof(TestCloud));

            cmd.GetTemporaryRT(_ResultTex, renderingData.cameraData.cameraTargetDescriptor);

            //Blit(cmd, ref renderingData, mat);

            // cmd.Blit(renderer.cameraColorTarget, _ResultTex, mat);
            // cmd.Blit(_ResultTex, renderer.cameraColorTarget);

            cmd.EndSample(nameof(TestCloud));
            context.ExecuteCommandBuffer(cmd);

            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            //if (isInited)
            //{
            //    cmd.ReleaseTemporaryRT(_ResultTex);
            //}
        }
    }

    CustomRenderPass m_ScriptablePass;

    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass();

        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


