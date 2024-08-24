import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.cross_decomposition import PLSRegression
from sklearn.metrics import mean_squared_error, r2_score
import joblib
import glob
import os

# 设置中文字体
plt.rcParams['font.sans-serif'] = ['SimHei']  # 使用黑体
plt.rcParams['axes.unicode_minus'] = False  # 解决保存图像时负号显示为方块的问题

# 加载所有数据文件，排除临时文件（以~$开头的文件）
file_paths = [f for f in glob.glob('../Data/ALL-Orange-Data/*.xlsx') if not os.path.basename(f).startswith('~$')]

all_data = []

for file_path in file_paths:
    data = pd.read_excel(file_path)
    all_data.append(data)

# 合并所有数据
data = pd.concat(all_data, ignore_index=True)

# 检查并移除离群点
z_scores = np.abs((data - data.mean()) / data.std())  # 计算Z分数
threshold = 2.1
outliers = np.where(z_scores > threshold)

print("离群点索引:", outliers)

# 移除离群点
cleaned_data = data[(z_scores < threshold).all(axis=1)]

# 提取特征和目标变量
X = cleaned_data[['Red', 'Green', 'Blue']].values
y_absorbance = cleaned_data['Absorbance'].values
y_concentration = cleaned_data['Concentration'].values

# 划分数据集为训练集和验证集
X_train, X_val, y_train_absorbance, y_val_absorbance, y_train_concentration, y_val_concentration = train_test_split(
    X, y_absorbance, y_concentration, test_size=0.2, random_state=42
)

# 数据标准化
scaler_X = StandardScaler()
scaler_y_absorbance = StandardScaler()
scaler_y_concentration = StandardScaler()

X_train_scaled = scaler_X.fit_transform(X_train)
y_train_absorbance_scaled = scaler_y_absorbance.fit_transform(y_train_absorbance.reshape(-1, 1)).ravel()
y_train_concentration_scaled = scaler_y_concentration.fit_transform(y_train_concentration.reshape(-1, 1)).ravel()

X_val_scaled = scaler_X.transform(X_val)
y_val_absorbance_scaled = scaler_y_absorbance.transform(y_val_absorbance.reshape(-1, 1)).ravel()
y_val_concentration_scaled = scaler_y_concentration.transform(y_val_concentration.reshape(-1, 1)).ravel()

# 建立PLS回归模型用于吸光度预测
n_components = 3  # 选择PLS成分的数量，3最优
pls_absorbance = PLSRegression(n_components=n_components)
pls_absorbance.fit(X_train_scaled, y_train_absorbance_scaled)

# 建立PLS回归模型用于浓度预测
pls_concentration = PLSRegression(n_components=n_components)
pls_concentration.fit(X_train_scaled, y_train_concentration_scaled)

# 训练集预测
y_train_absorbance_pred_scaled = pls_absorbance.predict(X_train_scaled)
y_train_absorbance_pred = scaler_y_absorbance.inverse_transform(y_train_absorbance_pred_scaled.reshape(-1, 1)).ravel()

y_train_concentration_pred_scaled = pls_concentration.predict(X_train_scaled)
y_train_concentration_pred = scaler_y_concentration.inverse_transform(y_train_concentration_pred_scaled.reshape(-1, 1)).ravel()

# 验证集预测
y_val_absorbance_pred_scaled = pls_absorbance.predict(X_val_scaled)
y_val_absorbance_pred = scaler_y_absorbance.inverse_transform(y_val_absorbance_pred_scaled.reshape(-1, 1)).ravel()

y_val_concentration_pred_scaled = pls_concentration.predict(X_val_scaled)
y_val_concentration_pred = scaler_y_concentration.inverse_transform(y_val_concentration_pred_scaled.reshape(-1, 1)).ravel()

# 修正负值，确保预测值不为负数
y_train_concentration_pred = np.maximum(0, y_train_concentration_pred)
y_val_concentration_pred = np.maximum(0, y_val_concentration_pred)

# 计算性能指标
r2_train_absorbance = r2_score(y_train_absorbance, y_train_absorbance_pred)
rmse_train_absorbance = mean_squared_error(y_train_absorbance, y_train_absorbance_pred, squared=False)

r2_val_absorbance = r2_score(y_val_absorbance, y_val_absorbance_pred)
rmse_val_absorbance = mean_squared_error(y_val_absorbance, y_val_absorbance_pred, squared=False)

r2_train_concentration = r2_score(y_train_concentration, y_train_concentration_pred)
rmse_train_concentration = mean_squared_error(y_train_concentration, y_train_concentration_pred, squared=False)

r2_val_concentration = r2_score(y_val_concentration, y_val_concentration_pred)
rmse_val_concentration = mean_squared_error(y_val_concentration, y_val_concentration_pred, squared=False)

print(f'吸光度 - 训练集 R2: {r2_train_absorbance:.3f}, RMSE: {rmse_train_absorbance:.3f}')
print(f'吸光度 - 验证集 R2: {r2_val_absorbance:.3f}, RMSE: {rmse_val_absorbance:.3f}')

print(f'浓度 - 训练集 R2: {r2_train_concentration:.3f}, RMSE: {rmse_train_concentration:.3f}')
print(f'浓度 - 验证集 R2: {r2_val_concentration:.3f}, RMSE: {rmse_val_concentration:.3f}')

# 保存模型和标准化器
joblib.dump(pls_absorbance, 'orange_pls_absorbance_model.pkl')
joblib.dump(pls_concentration, 'orange_pls_concentration_model.pkl')
joblib.dump(scaler_X, 'orange_scaler_X.pkl')
joblib.dump(scaler_y_absorbance, 'orange_scaler_y_absorbance.pkl')
joblib.dump(scaler_y_concentration, 'orange_scaler_y_concentration.pkl')

# 绘制预测结果图
plt.figure(figsize=(18, 6))

# 吸光度预测结果图
plt.subplot(1, 2, 1)
plt.scatter(y_train_absorbance, y_train_absorbance_pred, color='brown', edgecolor='k', label='Train')
plt.scatter(y_val_absorbance, y_val_absorbance_pred, color='blue', edgecolor='k', label='Validation')
plt.plot([min(y_train_absorbance), max(y_train_absorbance)], [min(y_train_absorbance), max(y_train_absorbance)], color='black', linestyle='--')
plt.xlabel('Reference')
plt.ylabel('Prediction')
plt.title(f'吸光度: Train R={r2_train_absorbance:.3f}, RMSE={rmse_train_absorbance:.3f} | Validation R={r2_val_absorbance:.3f}, RMSE={rmse_val_absorbance:.3f}')
plt.legend()

# 浓度预测结果图
plt.subplot(1, 2, 2)
plt.scatter(y_train_concentration, y_train_concentration_pred, color='brown', edgecolor='k', label='Train')
plt.scatter(y_val_concentration, y_val_concentration_pred, color='blue', edgecolor='k', label='Validation')
plt.plot([min(y_train_concentration), max(y_train_concentration)], [min(y_train_concentration), max(y_train_concentration)], color='black', linestyle='--')
plt.xlabel('Reference')
plt.ylabel('Prediction')
plt.title(f'浓度: Train R={r2_train_concentration:.3f}, RMSE={rmse_train_concentration:.3f} | Validation R={r2_val_concentration:.3f}, RMSE={rmse_val_concentration:.3f}')
plt.legend()

plt.tight_layout()
plt.show()



# # 测试
# def predict_custom_input(pls_absorbance, pls_concentration, scaler_X, scaler_y_absorbance, scaler_y_concentration):
#     # 用户输入
#     red = float(input("请输入红色值 (Red): "))
#     green = float(input("请输入绿色值 (Green): "))
#     blue = float(input("请输入蓝色值 (Blue): "))
#
#     # 将输入数据放入数组
#     custom_input = np.array([[red, green, blue]])
#
#     # 数据标准化
#     custom_input_scaled = scaler_X.transform(custom_input)
#
#     # 预测吸光度
#     absorbance_pred_scaled = pls_absorbance.predict(custom_input_scaled)
#     absorbance_pred = scaler_y_absorbance.inverse_transform(absorbance_pred_scaled.reshape(-1, 1)).ravel()
#
#     # 预测浓度
#     concentration_pred_scaled = pls_concentration.predict(custom_input_scaled)
#     concentration_pred = scaler_y_concentration.inverse_transform(concentration_pred_scaled.reshape(-1, 1)).ravel()
#
#     # 修正负值
#     absorbance_pred = np.maximum(0, absorbance_pred)
#     concentration_pred = np.maximum(0, concentration_pred)
#
#     # 输出结果
#     print(f"\n预测的吸光度: {absorbance_pred[0]:.3f}")
#     print(f"预测的浓度: {concentration_pred[0]:.3f}")
#
# # 调用测试函数
# predict_custom_input(pls_absorbance, pls_concentration, scaler_X, scaler_y_absorbance, scaler_y_concentration)
