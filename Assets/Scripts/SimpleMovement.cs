using UnityEngine;

/// <summary>
/// 简单的物体移动控制脚本
/// 挂载到需要移动的游戏对象上，通过WASD/箭头键控制前后左右移动
/// </summary>
public class SimpleMovement : MonoBehaviour
{
    [Header("移动速度")]
    public float moveSpeed = 5f;      // 默认移动速度

    void Update()
    {
        // 获取水平轴（A/D 或 左/右箭头）和垂直轴（W/S 或 上/下箭头）的输入值
        float horizontal = Input.GetAxis("Horizontal");
        float vertical = Input.GetAxis("Vertical");

        // 构建移动方向向量（X轴左右，Z轴前后）
        Vector3 direction = new Vector3(horizontal, 0f, vertical);
        
        // 归一化防止对角线移动速度过快（当有输入时保持各方向速度一致）
        if (direction.magnitude > 1f)
            direction.Normalize();

        // 在自身坐标系下移动（物体的前方就是它的蓝色轴（Z轴）方向）
        transform.Translate(direction * moveSpeed * Time.deltaTime, Space.Self);
    }
}