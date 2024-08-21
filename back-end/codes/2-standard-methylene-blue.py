# 提取出标准曲线-甲基橙文件夹中所有图片的RGB的值

import os
import cv2 # 用OpenCV库
import pandas as pd

# 定义图像文件夹路径
image_dir = '../Data/2-standard-methylene-blue'  # 使用绝对路径

# 获取文件夹中的所有图像文件
image_files = [f for f in os.listdir(image_dir) if f.endswith('.png')]

# 提取图像平均RGB值的函数
def extract_rgb(image_path):
    image = cv2.imread(image_path)
    if image is None:
        raise FileNotFoundError(f"无法打开文件: {image_path}")
    h, w, _ = image.shape
    roi = image[h//4:3*h//4, w//4:3*w//4]  # 选择图像的中心区域来计算平均RGB值，去掉上下和左右各1/4的边界
    average_color = cv2.mean(roi)[:3] # 用cv2.mean函数计算平均RGB值
    return average_color

# 初始化存储结果的列表
results = []

# 处理每个图像文件
for image_file in image_files:# 循环遍历每个图像文件
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
output_path = '../Data/2-standard-methylene-blue/output_rgb_values.xlsx'  # 保存到原文件夹之下
df_results.to_excel(output_path, index=False)

print(f"RGB值已成功提取并保存到 {output_path}")

