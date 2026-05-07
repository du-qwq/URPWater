using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[ExecuteAlways]
public class PlanarReflectionRenderer : MonoBehaviour
{
    [Header("References")]
    [SerializeField] private Transform waterPlane;
    [SerializeField] private Camera targetCamera;
    [SerializeField] private Material waterMaterial;

    [Header("Reflection Settings")]
    [SerializeField] private int textureSize = 1024;
    [SerializeField] private LayerMask reflectionMask = ~0;
    [SerializeField] private float clipPlaneOffset = 0.05f;

    private Camera reflectionCamera;
    private RenderTexture reflectionTexture;

    private static readonly int PlanarReflectionTexID = Shader.PropertyToID("_PlanarReflectionTex");

    private void OnEnable()
    {
        CreateResources();
    }

    private void OnDisable()
    {
        ReleaseResources();
    }

    private void LateUpdate()
    {
        if (waterPlane == null || waterMaterial == null)
            return;

        if (targetCamera == null)
            targetCamera = Camera.main;

        if (targetCamera == null)
            return;

        CreateResources();
        RenderReflection();
    }

    private void CreateResources()
    {
        if (reflectionTexture == null || reflectionTexture.width != textureSize)
        {
            if (reflectionTexture != null)
                reflectionTexture.Release();

            reflectionTexture = new RenderTexture(textureSize, textureSize, 16, RenderTextureFormat.ARGB32);
            reflectionTexture.name = "Planar Reflection RT";
            reflectionTexture.useMipMap = false;
            reflectionTexture.autoGenerateMips = false;
        }

        if (reflectionCamera == null)
        {
            GameObject camObj = new GameObject("Planar Reflection Camera");
            camObj.hideFlags = HideFlags.HideAndDontSave;

            reflectionCamera = camObj.AddComponent<Camera>();
            reflectionCamera.enabled = false;//禁用这个摄像机的自动渲染

            UniversalAdditionalCameraData urpData = camObj.AddComponent<UniversalAdditionalCameraData>();//给反射摄像机添加 URP 的附加摄像机数据组件
            urpData.renderShadows = false;
            urpData.requiresColorOption = CameraOverrideOption.Off;
            urpData.requiresDepthOption = CameraOverrideOption.Off;
        }
    }

    private void ReleaseResources()
    {
        if (reflectionTexture != null)
        {
            reflectionTexture.Release();
            DestroyImmediate(reflectionTexture);
            reflectionTexture = null;
        }

        if (reflectionCamera != null)
        {
            DestroyImmediate(reflectionCamera.gameObject);
            reflectionCamera = null;
        }
    }

    private void RenderReflection()
    {
        if (reflectionCamera == null || reflectionTexture == null)
            return;

        reflectionCamera.CopyFrom(targetCamera);//让反射摄像机复制主摄像机的设置

        reflectionCamera.cullingMask = reflectionMask;//设置反射相机能渲染哪些 Layer
        reflectionCamera.targetTexture = reflectionTexture;//正常摄像机是输出到屏幕，这里让反射摄像机的画面输出到 RenderTexture

        Vector3 waterPos = waterPlane.position;
        Vector3 waterNormal = waterPlane.up;

        //构造水面平面方程 Ax + By + Cz + D = 0
        float d = -Vector3.Dot(waterNormal, waterPos) - clipPlaneOffset;//D=-dot(normal, pointOnPlane)
        Vector4 reflectionPlane = new Vector4(waterNormal.x, waterNormal.y, waterNormal.z, d);//A B C = 平面法线 normal.x normal.y normal.z

        Matrix4x4 reflectionMatrix = CalculateReflectionMatrix(reflectionPlane);

        reflectionCamera.worldToCameraMatrix = targetCamera.worldToCameraMatrix * reflectionMatrix;

        Vector4 clipPlane = CameraSpacePlane(reflectionCamera, waterPos, waterNormal, 1.0f);//把世界空间里的水面转换成反射相机空间里的裁剪平面
        Matrix4x4 projection = reflectionCamera.CalculateObliqueMatrix(clipPlane);
        reflectionCamera.projectionMatrix = projection;

        GL.invertCulling = true;//打开反向剔除
        reflectionCamera.Render();
        GL.invertCulling = false;

        waterMaterial.SetTexture(PlanarReflectionTexID, reflectionTexture);
    }

    private static Matrix4x4 CalculateReflectionMatrix(Vector4 plane)
    {
        Matrix4x4 reflectionMat = Matrix4x4.zero;

        reflectionMat.m00 = 1F - 2F * plane[0] * plane[0];
        reflectionMat.m01 = -2F * plane[0] * plane[1];
        reflectionMat.m02 = -2F * plane[0] * plane[2];
        reflectionMat.m03 = -2F * plane[3] * plane[0];

        reflectionMat.m10 = -2F * plane[1] * plane[0];
        reflectionMat.m11 = 1F - 2F * plane[1] * plane[1];
        reflectionMat.m12 = -2F * plane[1] * plane[2];
        reflectionMat.m13 = -2F * plane[3] * plane[1];

        reflectionMat.m20 = -2F * plane[2] * plane[0];
        reflectionMat.m21 = -2F * plane[2] * plane[1];
        reflectionMat.m22 = 1F - 2F * plane[2] * plane[2];
        reflectionMat.m23 = -2F * plane[3] * plane[2];

        reflectionMat.m30 = 0F;
        reflectionMat.m31 = 0F;
        reflectionMat.m32 = 0F;
        reflectionMat.m33 = 1F;

        return reflectionMat;
    }

    private Vector4 CameraSpacePlane(Camera cam, Vector3 pos, Vector3 normal, float sideSign)
    {
        Vector3 offsetPos = pos + normal * clipPlaneOffset;

        Matrix4x4 m = cam.worldToCameraMatrix;//获取摄像机的世界到摄像机空间矩阵
        Vector3 cameraPos = m.MultiplyPoint(offsetPos);//把裁剪平面上的点从世界空间转换到摄像机空间
        Vector3 cameraNormal = m.MultiplyVector(normal).normalized * sideSign;//把法线从世界空间转换到摄像机空间

        return new Vector4(
            cameraNormal.x,
            cameraNormal.y,
            cameraNormal.z,
            -Vector3.Dot(cameraPos, cameraNormal)
        );
    }
}