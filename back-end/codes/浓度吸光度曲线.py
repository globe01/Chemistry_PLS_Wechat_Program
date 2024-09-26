import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# 读取数据
file_path = '../newData/blueconcentrationandAbsorb.xlsx'
data = pd.read_excel(file_path)

# 提取 Concentration 和 Absorbance 列
concentration = data['Concentration'].values
absorbance = data['Absorbance'].values

# 绘制吸光度-浓度图
plt.figure(figsize=(8, 6))

# 绘制散点图
plt.scatter(concentration, absorbance, color='orange')

# 拟合线性模型
coefficients = np.polyfit(concentration, absorbance, 1)  # 拟合直线
poly_eq = np.poly1d(coefficients)  # 将系数转换为多项式表达式
x_fit = np.linspace(min(concentration), max(concentration), 100)  # 在浓度范围内生成拟合线
y_fit = poly_eq(x_fit)
plt.plot(x_fit, y_fit, color='black', linestyle='-')

# 计算 R²（相关系数平方）
r_squared = np.corrcoef(absorbance, poly_eq(concentration))[0, 1] ** 2

# 计算 RMSEC（校准均方根误差）
y_pred = poly_eq(concentration)  # 使用拟合方程计算预测值
rmsec = np.sqrt(np.mean((absorbance - y_pred) ** 2))  # 计算 RMSEC

# 显示拟合方程、R² 和 RMSEC
plt.text(2, 3.8, f"y={coefficients[0]:.5f}x+{coefficients[1]:.5f}", fontsize=12)
plt.text(2, 3.6, f"R²={r_squared:.4f}", fontsize=12)
plt.text(2, 3.4, f"RMSEC={rmsec:.4f}", fontsize=12)

# 设置标题和标签
plt.title("Absorbance-concentration standard curve of methyl orange", fontsize=14)
plt.xlabel("Concentration (mg/L)", fontsize=12)
plt.ylabel("Absorbance (a.u.)", fontsize=12)

# 去掉格子
plt.grid(False)

# 显示图形
plt.show()
