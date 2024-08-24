import pandas as pd
import matplotlib.pyplot as plt
from sklearn.preprocessing import StandardScaler
from sklearn.cross_decomposition import PLSRegression
from sklearn.metrics import mean_squared_error, r2_score
import joblib

# 加载训练数据
train_data = pd.read_excel('../Data/1-standard-methyl-orange/output_rgb_values.xlsx')
X_train = train_data[['Red', 'Green', 'Blue']].values
y_train = train_data['Absorbance'].values

# 加载验证数据
validation_data = pd.read_excel('../Data/8-catalyzer-orange/1-Ag-TiO2/output_rgb_values.xlsx')
X_val = validation_data[['Red', 'Green', 'Blue']].values
y_val = validation_data['Absorbance'].values

# 数据标准化
scaler_X = StandardScaler()
scaler_y = StandardScaler()

X_train_scaled = scaler_X.fit_transform(X_train)
y_train_scaled = scaler_y.fit_transform(y_train.reshape(-1, 1)).ravel()

X_val_scaled = scaler_X.transform(X_val)
y_val_scaled = scaler_y.transform(y_val.reshape(-1, 1)).ravel()

# 建立PLS回归模型
n_components = 2  # 选择PLS成分的数量
pls = PLSRegression(n_components=n_components)
pls.fit(X_train_scaled, y_train_scaled)

# 训练集预测
y_train_pred_scaled = pls.predict(X_train_scaled)
y_train_pred = scaler_y.inverse_transform(y_train_pred_scaled.reshape(-1, 1)).ravel()

# 验证集预测
y_val_pred_scaled = pls.predict(X_val_scaled)
y_val_pred = scaler_y.inverse_transform(y_val_pred_scaled.reshape(-1, 1)).ravel()

# 计算性能指标
r2_train = r2_score(y_train, y_train_pred)
rmse_train = mean_squared_error(y_train, y_train_pred, squared=False)

r2_val = r2_score(y_val, y_val_pred)
rmse_val = mean_squared_error(y_val, y_val_pred, squared=False)

print(f'训练集 R2: {r2_train:.3f}, RMSE: {rmse_train:.3f}')
print(f'验证集 R2: {r2_val:.3f}, RMSE: {rmse_val:.3f}')

# 保存模型和标准化器
joblib.dump(pls, 'pls_model.pkl')
joblib.dump(scaler_X, 'scaler_X.pkl')
joblib.dump(scaler_y, 'scaler_y.pkl')



# 绘制预测结果图
plt.figure(figsize=(18, 6))

# 训练集预测结果图
plt.subplot(1, 2, 1)
plt.scatter(y_train, y_train_pred, color='brown', edgecolor='k', label='Train')
plt.plot([min(y_train), max(y_train)], [min(y_train), max(y_train)], color='black', linestyle='--')
plt.xlabel('Reference')
plt.ylabel('Prediction')
plt.title(f'Train: R={r2_train:.3f}, RMSE={rmse_train:.3f}')
plt.legend()

# 验证集预测结果图
plt.subplot(1, 2, 2)
plt.scatter(y_val, y_val_pred, color='brown', edgecolor='k', label='Validation')
plt.plot([min(y_val), max(y_val)], [min(y_val), max(y_val)], color='black', linestyle='--')
plt.xlabel('Reference')
plt.ylabel('Prediction')
plt.title(f'Validation: R={r2_val:.3f}, RMSE={rmse_val:.3f}')
plt.legend()

plt.tight_layout()
plt.show()


