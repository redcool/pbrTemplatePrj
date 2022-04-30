using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteAlways]
public class OceanDepth : MonoBehaviour
{
    public RenderTexture colorRT;
    public RenderTexture depthRT;
    public RenderTexture depthTex;
    public Camera cam;

    CommandBuffer blitBack, blitDepth;
    public bool useCameraDepthMode = false;
    // Start is called before the first frame update
    void Start()
    {
        if (!cam)
            cam = GetComponent<Camera>();

        if (!cam)
            return;

        if (useCameraDepthMode)
        {
            cam.depthTextureMode = DepthTextureMode.Depth;
            return;
        }

        InitBuffers(cam);
        InitCommands();

        // set targets
        cam.SetTargetBuffers(colorRT.colorBuffer, depthRT.depthBuffer);
    }

    private void OnDestroy()
    {
        ClearCommands();
    }


    void ClearCommand(Camera cam, CameraEvent e, CommandBuffer buf)
    {
        if (!cam || buf == null)
            return;

        cam.RemoveCommandBuffer(e, buf);
        buf.Dispose();
    }

    private void ClearCommands()
    {
        ClearCommand(cam, CameraEvent.AfterEverything, blitBack);
        ClearCommand(cam, CameraEvent.AfterEverything, blitDepth);
    }

    private void InitCommands()
    {
        blitBack = new CommandBuffer { name = "Blit Back" };
        blitBack.Blit(colorRT, (RenderTexture)null);
        cam.AddCommandBuffer(CameraEvent.AfterEverything, blitBack);


        blitDepth = new CommandBuffer { name = "Blit Depth" };
        blitDepth.Blit(depthRT.depthBuffer, depthTex.colorBuffer);
        // bind textures
        blitDepth.SetGlobalTexture("_CameraScreenTexture", colorRT);
        blitDepth.SetGlobalTexture("_CameraDepthTexture", depthTex);
        cam.AddCommandBuffer(CameraEvent.AfterForwardOpaque, blitDepth);
    }

    private void InitBuffers(Camera cam)
    {
        colorRT = new RenderTexture(cam.pixelWidth, cam.pixelHeight, 0,RenderTextureFormat.ARGB32);
        depthRT = new RenderTexture(cam.pixelWidth, cam.pixelHeight, 24, RenderTextureFormat.Depth);
        depthTex = new RenderTexture(cam.pixelWidth, cam.pixelHeight, 0, RenderTextureFormat.R16);
    }

    //void OnPreRender()
    //{
    //    cam.SetTargetBuffers(colorRT.colorBuffer, depthRT.depthBuffer);
    //}

}
