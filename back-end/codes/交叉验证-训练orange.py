import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.preprocessing import StandardScaler
from sklearn.cross_decomposition import PLSRegression
from sklearn.metrics import mean_squared_error, r2_score, make_scorer
from sklearn.model_selection import cross_val_score, KFold
import joblib
import glob
import os

# 设置中文字体
plt.rcParams['font.sans-serif'] = ['SimHei']  # 使用黑体
plt.rcParams['axes.unicode_minus'] = False  # 解决保存图像时负号显示为方块的问题

# 加载所有数据文件，排除临时文件（以~$开头的文件）
file_paths = [f for f in glob.glob('../newData/standard/corrected_standard_orange.xlsx') if not os.path.basename(f).startswith('~$')]

all_data = []

for file_path in file_paths:
    data = pd.read_excel(file_path)
    all_data.append(data)

# 合并所有数据
data = pd.concat(all_data, ignore_index=True)

# 检查并移除离群点
z_scores = np.abs((data - data.mean()) / data.std())  # 计算Z分数
threshold = 2.1
cleaned_data = data[(z_scores < threshold).all(axis=1)]  # 移除离群点

# 提取特征和目标变量
X = cleaned_data[['Red', 'Green', 'Blue']].values
y_absorbance = cleaned_data['Absorbance'].values
y_concentration = cleaned_data['Concentration'].values

# 数据标准化
scaler_X = StandardScaler()
X_scaled = scaler_X.fit_transform(X)

scaler_y_absorbance = StandardScaler()
y_absorbance_scaled = scaler_y_absorbance.fit_transform(y_absorbance.reshape(-1, 1)).ravel()

scaler_y_concentration = StandardScaler()
y_concentration_scaled = scaler_y_concentration.fit_transform(y_concentration.reshape(-1, 1)).ravel()

# 建立PLS回归模型
n_components = 3  # 选择PLS成分的数量，3最优
pls_absorbance = PLSRegression(n_components=n_components)
pls_concentration = PLSRegression(n_components=n_components)

# 定义交叉验证 (KFold，5折交叉验证)
kf = KFold(n_splits=5, shuffle=True, random_state=42)

# R² 分数和 RMSE 作为评分标准
def rmse(y_true, y_pred):
    return np.sqrt(mean_squared_error(y_true, y_pred))

scorer_r2 = make_scorer(r2_score)
scorer_rmse = make_scorer(rmse, greater_is_better=False)

# 吸光度交叉验证
r2_scores_absorbance = cross_val_score(pls_absorbance, X_scaled, y_absorbance_scaled, cv=kf, scoring=scorer_r2)
rmse_scores_absorbance = cross_val_score(pls_absorbance, X_scaled, y_absorbance_scaled, cv=kf, scoring=scorer_rmse)

# 浓度交叉验证
r2_scores_concentration = cross_val_score(pls_concentration, X_scaled, y_concentration_scaled, cv=kf, scoring=scorer_r2)
rmse_scores_concentration = cross_val_score(pls_concentration, X_scaled, y_concentration_scaled, cv=kf, scoring=scorer_rmse)

# 打印交叉验证结果
print(f'吸光度 - 平均 R²: {np.mean(r2_scores_absorbance):.3f}, 平均 RMSE: {np.mean(np.abs(rmse_scores_absorbance)):.3f}')
print(f'浓度 - 平均 R²: {np.mean(r2_scores_concentration):.3f}, 平均 RMSE: {np.mean(np.abs(rmse_scores_concentration)):.3f}')

# 训练模型并保存
pls_absorbance.fit(X_scaled, y_absorbance_scaled)
pls_concentration.fit(X_scaled, y_concentration_scaled)

# 保存模型和标准化器
joblib.dump(pls_absorbance, 'corrected_orange_pls_absorbance_model.pkl')
joblib.dump(pls_concentration, 'corrected_orange_pls_concentration_model.pkl')
joblib.dump(scaler_X, 'corrected_orange_scaler_X.pkl')
joblib.dump(scaler_y_absorbance, 'corrected_orange_scaler_y_absorbance.pkl')
joblib.dump(scaler_y_concentration, 'corrected_orange_scaler_y_concentration.pkl')

# 绘制交叉验证预测结果图（使用最后一个训练的模型）
y_absorbance_pred_scaled = pls_absorbance.predict(X_scaled)
y_absorbance_pred = scaler_y_absorbance.inverse_transform(y_absorbance_pred_scaled.reshape(-1, 1)).ravel()

y_concentration_pred_scaled = pls_concentration.predict(X_scaled)
y_concentration_pred = scaler_y_concentration.inverse_transform(y_concentration_pred_scaled.reshape(-1, 1)).ravel()

# 绘制预测结果图
plt.figure(figsize=(18, 6))

# 吸光度预测结果图
plt.subplot(1, 2, 1)
plt.scatter(y_absorbance, y_absorbance_pred, color='brown', edgecolor='k', label='Prediction')
plt.plot([min(y_absorbance), max(y_absorbance)], [min(y_absorbance), max(y_absorbance)], color='black', linestyle='--')
plt.xlabel('Reference')
plt.ylabel('Prediction')
plt.title(f'吸光度: 平均 R²={np.mean(r2_scores_absorbance):.3f}, 平均 RMSE={np.mean(np.abs(rmse_scores_absorbance)):.3f}')
plt.legend()

# 浓度预测结果图
plt.subplot(1, 2, 2)
plt.scatter(y_concentration, y_concentration_pred, color='blue', edgecolor='k', label='Prediction')
plt.plot([min(y_concentration), max(y_concentration)], [min(y_concentration), max(y_concentration)], color='black', linestyle='--')
plt.xlabel('Reference')
plt.ylabel('Prediction')
plt.title(f'浓度: 平均 R²={np.mean(r2_scores_concentration):.3f}, 平均 RMSE={np.mean(np.abs(rmse_scores_concentration)):.3f}')
plt.legend()

plt.tight_layout()
plt.show()
