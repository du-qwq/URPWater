using UnityEngine;

public class Camera_Move : MonoBehaviour
{
    [Header("移动设置")]
    public float moveSpeed = 5f;          // 基础移动速度
    public float shiftMultiplier = 2f;     // 按住 Shift 时的速度倍率
    public float mouseSensitivity = 2f;    // 鼠标灵敏度

    private float rotationX = 0f;
    private float rotationY = 0f;

    void Start()
    {
        // 初始化旋转角度为当前摄像机的欧拉角
        rotationX = transform.eulerAngles.x;
        rotationY = transform.eulerAngles.y;

        // 锁定并隐藏光标，便于控制（也可根据需要取消）
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
    }

    void Update()
    {
        // 鼠标旋转（仅在按住右键时旋转，或一直旋转，这里使用按住右键）
        if (Input.GetMouseButton(1)) // 右键按住
        {
            float mouseX = Input.GetAxis("Mouse X") * mouseSensitivity;
            float mouseY = Input.GetAxis("Mouse Y") * mouseSensitivity;

            rotationY += mouseX;
            rotationX -= mouseY;
            rotationX = Mathf.Clamp(rotationX, -90f, 90f); // 限制上下角度，防止翻转

            transform.rotation = Quaternion.Euler(rotationX, rotationY, 0f);
        }

        // 移动
        float speed = moveSpeed;
        if (Input.GetKey(KeyCode.LeftShift)) speed *= shiftMultiplier;

        float horizontal = Input.GetAxis("Horizontal"); // A/D
        float vertical = Input.GetAxis("Vertical");     // W/S
        float upDown = 0f;
        if (Input.GetKey(KeyCode.LeftControl)) upDown = -1f;
        if (Input.GetKey(KeyCode.Space)) upDown = 1f;

        Vector3 moveDirection = transform.right * horizontal + transform.forward * vertical + transform.up * upDown;
        transform.position += moveDirection * speed * Time.deltaTime;
    }
}