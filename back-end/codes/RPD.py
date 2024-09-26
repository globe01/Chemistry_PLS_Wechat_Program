import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.metrics import mean_squared_error, r2_score

# 加载测试集数据
file_path = '../newData/purpletest3.xlsx'  # 你的测试集文件路径
data = pd.read_excel(file_path)

# 提取真实值和预测值
y_true = data['Absorbance'].values
y_pred = data['Predicted'].values

# 计算相关系数 R²
r2 = r2_score(y_true, y_pred)
print(f"相关系数 R²: {r2:.3f}")

# 计算 RMSEC (校准的均方根误差)
rmsec = np.sqrt(mean_squared_error(y_true, y_pred))
print(f"校准的均方根误差 RMSEC: {rmsec:.3f}")

# 绘制散点图
plt.figure(figsize=(8, 6))

# 使用红色绘制散点
plt.scatter(y_true, y_pred, color='red', label='Predicted vs Reference')

# 绘制 y = x 线（理想线）
plt.plot([min(y_true), max(y_true)], [min(y_true), max(y_true)], color='black', linestyle='--', label='y = x')

# 设置图表标题和标签
plt.title(f"Prediction vs Reference\nR² = {r2:.3f}, RMSEC = {rmsec:.3f}", fontsize=14)
plt.xlabel("Reference (mg/L)", fontsize=12)
plt.ylabel("Predicted (mg/L)", fontsize=12)
plt.legend()

# 显示网格
plt.grid(False)

# 显示图形
plt.show()
