import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.preprocessing import StandardScaler
from sklearn.cross_decomposition import PLSRegression
from sklearn.metrics import mean_squared_error, r2_score
import joblib
import glob
import os

# 设置中文字体
plt.rcParams['font.sans-serif'] = ['SimHei']  # 使用黑体
plt.rcParams['axes.unicode_minus'] = False  # 解决保存图像时负号显示为方块的问题

# 1. 加载标准甲基橙溶液数据进行模型训练
standard_data_path = '../newData/standard/corrected_standard_blue.xlsx'
standard_data = pd.read_excel(standard_data_path)

# 提取标准数据的特征（RGB）和目标变量（吸光度、浓度）
X_standard = standard_data[['Red', 'Green', 'Blue']].values
y_absorbance_standard = standard_data['Absorbance'].values
y_concentration_standard = standard_data['Concentration'].values

# 数据标准化
scaler_X_standard = StandardScaler()
X_standard_scaled = scaler_X_standard.fit_transform(X_standard)

scaler_y_absorbance_standard = StandardScaler()
y_absorbance_standard_scaled = scaler_y_absorbance_standard.fit_transform(y_absorbance_standard.reshape(-1, 1)).ravel()

scaler_y_concentration_standard = StandardScaler()
y_concentration_standard_scaled = scaler_y_concentration_standard.fit_transform(y_concentration_standard.reshape(-1, 1)).ravel()

# PLS模型训练（吸光度和浓度）
n_components = 3  # 选择 PLS 成分数量
pls_absorbance = PLSRegression(n_components=n_components)
pls_concentration = PLSRegression(n_components=n_components)

# 训练吸光度模型
pls_absorbance.fit(X_standard_scaled, y_absorbance_standard_scaled)

# 训练浓度模型
pls_concentration.fit(X_standard_scaled, y_concentration_standard_scaled)

# 评估模型性能 - 校准阶段
y_train_concentration_pred_scaled = pls_concentration.predict(X_standard_scaled)
y_train_concentration_pred = scaler_y_concentration_standard.inverse_transform(y_train_concentration_pred_scaled.reshape(-1, 1)).ravel()

# 计算R² (相关系数) 和 RMSEC
r2_train_concentration = r2_score(y_concentration_standard, y_train_concentration_pred)
rmsec = np.sqrt(mean_squared_error(y_concentration_standard, y_train_concentration_pred))

print(f'校准 (训练集) - 相关系数 R²: {r2_train_concentration:.3f}')
print(f'校准 (训练集) - 均方根误差 RMSEC: {rmsec:.3f}')

# 保存标准化器和模型
joblib.dump(pls_absorbance, 'BluePurple-trained_pls_absorbance_model.pkl')
joblib.dump(pls_concentration, 'BluePurple-trained_pls_concentration_model.pkl')
joblib.dump(scaler_X_standard, 'BluePurple-scaler_X_standard.pkl')
joblib.dump(scaler_y_absorbance_standard, 'BluePurple-scaler_y_absorbance_standard.pkl')
joblib.dump(scaler_y_concentration_standard, 'BluePurple-scaler_y_concentration_standard.pkl')

# 2. 加载TiO2纳米球数据进行矫正
# 加载检测数据
test_data_path = '../newData/purple/blueAllData/*.xlsx'
test_file_paths = glob.glob(test_data_path)
test_data_all = []

for file_path in test_file_paths:
    test_data = pd.read_excel(file_path)
    test_data_all.append(test_data)

# 合并所有数据
test_data_combined = pd.concat(test_data_all, ignore_index=True)

# 提取特征和吸光度
X_test = test_data_combined[['Red', 'Green', 'Blue']].values
y_test_absorbance = test_data_combined['Absorbance'].values

# 对测试数据进行标准化
X_test_scaled = scaler_X_standard.transform(X_test)

# 使用训练好的模型对测试数据进行预测
y_test_concentration_pred_scaled = pls_concentration.predict(X_test_scaled)
# 将一维数组转为二维数组再进行逆标准化
y_test_concentration_pred = scaler_y_concentration_standard.inverse_transform(y_test_concentration_pred_scaled.reshape(-1, 1)).ravel()
# 修正负值，确保预测值不为负数
y_test_concentration_pred = np.maximum(0, y_test_concentration_pred)

# 评估模型性能 - 预测阶段
r2_test_concentration = r2_score(y_test_absorbance, y_test_concentration_pred)
rmsep = np.sqrt(mean_squared_error(y_test_absorbance, y_test_concentration_pred))

# print(f'预测 (测试集) - 相关系数 R²: {r2_test_concentration:.3f}')
# print(f'预测 (测试集) - 均方根误差 RMSEP: {rmsep:.3f}')

# 将预测浓度和实际的吸光度值结合起来
test_data_combined['Predicted_Concentration'] = y_test_concentration_pred

# 保存预测结果到 Excel
output_path = '../newData/predicted_results_blue_tiO2.xlsx'
test_data_combined.to_excel(output_path, index=False)

print(f"模型已成功训练，并对测试数据进行了矫正。预测结果已保存到 {output_path}.")

# 3. 绘制预测结果图
plt.figure(figsize=(10, 5))
plt.plot(range(len(y_test_absorbance)), y_test_absorbance, label='Actual Absorbance', color='blue')
plt.plot(range(len(y_test_concentration_pred)), y_test_concentration_pred, label='Predicted Concentration', color='orange')
plt.xlabel('Time (minutes)')
plt.ylabel('Absorbance / Concentration')
plt.title('TiO2 Degradation Efficiency - Absorbance vs Predicted Concentration')
plt.legend()
plt.show()
