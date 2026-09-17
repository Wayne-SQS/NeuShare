from PIL import Image
import os

def create_pixel_art(filename, pixel_data, colors, pixel_size=20):
    """
    创建像素图
    pixel_data: 二维列表，表示像素颜色索引
    colors: 颜色字典，索引对应的颜色
    pixel_size: 每个像素块的大小
    """
    height = len(pixel_data)
    width = len(pixel_data[0])
    
    img = Image.new('RGB', (width * pixel_size, height * pixel_size))
    
    for y, row in enumerate(pixel_data):
        for x, color_idx in enumerate(row):
            if color_idx != 0:  # 0表示透明
                color = colors.get(color_idx, (255, 255, 255))
                for py in range(pixel_size):
                    for px in range(pixel_size):
                        img.putpixel((x * pixel_size + px, y * pixel_size + py), color)
    
    img.save(filename)
    print(f"已保存: {filename}")

# 人工智能 - 机器人头像
ai_colors = {
    1: (64, 64, 64),    # 深灰 - 头部
    2: (128, 128, 128),  # 浅灰 - 面部
    3: (0, 200, 255),    # 蓝色 - 眼睛
    4: (255, 100, 100),  # 红色 - 嘴巴
    5: (200, 200, 200),  # 亮灰 - 天线
}

ai_pixel_data = [
    [0, 0, 5, 0, 0],
    [0, 0, 5, 0, 0],
    [0, 1, 1, 1, 0],
    [1, 2, 2, 2, 1],
    [1, 3, 2, 3, 1],
    [1, 2, 2, 2, 1],
    [1, 2, 4, 2, 1],
    [0, 1, 1, 1, 0],
]

# 开源社区 - 代码/链接图标
open_source_colors = {
    1: (50, 50, 50),     # 深色 - 代码背景
    2: (0, 200, 100),    # 绿色 - 代码符号
    3: (255, 255, 255),  # 白色 - 文字
    4: (100, 200, 255),  # 浅蓝 - 链接
    5: (255, 200, 0),    # 黄色 - 星标
}

open_source_pixel_data = [
    [1, 1, 1, 1, 1, 1],
    [1, 3, 3, 3, 3, 1],
    [1, 2, 4, 4, 2, 1],
    [1, 3, 4, 4, 3, 1],
    [1, 2, 2, 2, 2, 1],
    [1, 5, 3, 3, 5, 1],
    [1, 1, 1, 1, 1, 1],
]

# 学校教学 - 书本和学士帽
school_colors = {
    1: (150, 100, 50),   # 棕色 - 书本
    2: (200, 150, 80),   # 浅棕 - 书页
    3: (0, 0, 0),        # 黑色 - 学士帽
    4: (255, 215, 0),    # 金色 - 流苏
    5: (255, 255, 255),  # 白色 - 文字
}

school_pixel_data = [
    [0, 0, 3, 3, 3, 0, 0],
    [0, 3, 3, 3, 3, 3, 0],
    [0, 0, 3, 4, 3, 0, 0],
    [0, 0, 1, 1, 1, 0, 0],
    [0, 1, 2, 2, 2, 1, 0],
    [1, 2, 5, 5, 5, 2, 1],
    [1, 2, 2, 2, 2, 2, 1],
    [1, 1, 1, 1, 1, 1, 1],
]

# 保存图片
output_dir = r"E:\桌面\像素图"

create_pixel_art(
    os.path.join(output_dir, "人工智能.png"),
    ai_pixel_data,
    ai_colors,
    pixel_size=30
)

create_pixel_art(
    os.path.join(output_dir, "开源社区.png"),
    open_source_pixel_data,
    open_source_colors,
    pixel_size=25
)

create_pixel_art(
    os.path.join(output_dir, "学校教学.png"),
    school_pixel_data,
    school_colors,
    pixel_size=25
)

print("所有像素图已生成完毕！")