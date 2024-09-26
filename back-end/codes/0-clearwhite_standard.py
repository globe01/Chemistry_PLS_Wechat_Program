import os
import cv2  # 用OpenCV库
import pandas as pd
import numpy as np


image_dir = '../newData/standard/blue'
image_files = [f for f in os.listdir(image_dir) if f.endswith('.png')]

# 考虑光线问题，把四周白色统一，先定义理想白色的RGB值
ideal_white = np.array([255, 255, 255])


# 提取图像平均RGB值的函数
def extract_rgb(image_path):
    image = cv2.imread(image_path)
    if image is None:
        raise FileNotFoundError(f"无法打开文件: {image_path}")

    # 将图像从BGR转换为RGB
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    h, w, _ = image.shape

    # 计算统一的区域大小，避免不同角落区域大小不一致的问题
    corner_h = h // 8
    corner_w = w // 8

    # 1. 提取白色区域的平均RGB值（取四周的小角落区域，1/64，一共4块，相当于1/16）
    white_roi = np.concatenate((
        image[:corner_h, :corner_w],  # 左上角
        image[:corner_h, -corner_w:],  # 右上角
        image[-corner_h:, :corner_w],  # 左下角
        image[-corner_h:, -corner_w:]  # 右下角
    ), axis=0)  # 将四角区域合并

    white_avg_rgb = cv2.mean(white_roi)[:3]  # 计算白色区域的平均RGB值

    # 2. 计算校正因子（根据白色区域与理想白色的差异）
    correction_factor = ideal_white / np.array(white_avg_rgb)

    # 3. 提取图像中心区域的RGB值
    center_roi = image[h // 4:3 * h // 4, w // 4:3 * w // 4]  # 选择图像的中心区域来计算平均RGB值，去掉上下和左右各1/4的边界

    # 4. 应用校正因子，矫正中心区域的RGB值
    corrected_center_roi = center_roi * correction_factor  # 将校正因子应用到中心区域
    corrected_center_roi = np.clip(corrected_center_roi, 0, 255)  # 确保RGB值在0到255之间

    average_color = cv2.mean(corrected_center_roi)[:3]  # 计算矫正后中心区域的平均RGB值

    return average_color


# 初始化存储结果的列表
results = []

# 处理每个图像文件
for image_file in image_files:  # 循环遍历每个图像文件
    image_path = os.path.join(image_dir, image_file)
    print(f"正在处理文件: {image_path}")
    try:
        avg_rgb = extract_rgb(image_path)
        absorbance = float(os.path.splitext(image_file)[0])  # 从文件名中提取吸光度值
        results.append((absorbance, avg_rgb[0], avg_rgb[1], avg_rgb[2]))
    except FileNotFoundError as e:
        print(e)

# 将结果创建为DataFrame
df_results = pd.DataFrame(results, columns=['Absorbance', 'Red', 'Green', 'Blue'])

# 按照吸光度排序
df_results = df_results.sort_values(by='Absorbance')

# 保存结果为Excel文件
output_path = '../newData/standard/blue/11-20blue.xlsx'  # 保存到原文件夹之下

df_results.to_excel(output_path, index=False)

print(f"RGB值已成功提取并保存到 {output_path}")
