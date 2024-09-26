import pandas as pd
import numpy as np
from sklearn.metrics import mean_squared_error, r2_score

# 加载测试集数据
file_path = '../newData/purpletest2.xlsx'  # 你的测试集文件路径
data = pd.read_excel(file_path)

# 提取真实值和预测值
y_true = data['Absorbance'].values
y_pred = data['Predicted'].values

# 计算相关系数 R²
r2 = r2_score(y_true, y_pred)
print(f"相关系数 R²: {r2:.3f}")

# 计算 RMSEP (预测均方根误差)
rmsep = np.sqrt(mean_squared_error(y_true, y_pred))
print(f"预测的均方根误差 RMSEP: {rmsep:.3f}")
