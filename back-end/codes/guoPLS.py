import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.preprocessing import StandardScaler
from sklearn.cross_decomposition import PLSRegression
from sklearn.model_selection import cross_val_predict, KFold
from sklearn.metrics import mean_squared_error


# 定义PLS模型类
class PLSModel:
    def __init__(self, nLV=12, n_fold=5, pre_def_LV=None, isplot=False):
        self.nLV = nLV
        self.n_fold = n_fold
        self.pre_def_LV = pre_def_LV if pre_def_LV is not None else nLV
        self.isplot = isplot
        self.scaler_X = StandardScaler()
        self.scaler_y = StandardScaler()
        self.pls = PLSRegression(n_components=nLV)

    def pretreat(self, X, method='center'):
        if method == 'center':
            return self.scaler_X.fit_transform(X)
        else:
            raise ValueError('Unknown pretreat method: {}'.format(method))

    def calc_rmsec(self, y, yhat):
        mse = mean_squared_error(y, yhat)
        rmsec = np.sqrt(mse)
        R2 = np.corrcoef(y.flatten(), yhat.flatten())[0, 1] ** 2
        return rmsec, R2

    def fit(self, Xcal, ycal):
        Xcal_c = self.pretreat(Xcal, 'center')
        ycal_c = self.scaler_y.fit_transform(ycal.reshape(-1, 1)).flatten()
        self.pls.fit(Xcal_c, ycal_c)
        self.coef_ = self.pls.coef_
        self.VIP_ = self.calculate_vip(Xcal_c, ycal_c)
        return self

    def predict(self, X):
        X_c = self.scaler_X.transform(X)
        y_pred = self.pls.predict(X_c)
        return self.scaler_y.inverse_transform(y_pred.reshape(-1, 1)).flatten()

    def cross_validate(self, Xcal, ycal):
        Xcal_c = self.pretreat(Xcal, 'center')
        ycal_c = self.scaler_y.transform(ycal.reshape(-1, 1)).flatten()
        kf = KFold(n_splits=self.n_fold)
        yhat_cv = cross_val_predict(self.pls, Xcal_c, ycal_c, cv=kf)
        RMSECV, R2cv = self.calc_rmsec(ycal, yhat_cv)
        return RMSECV, R2cv

    def evaluate(self, Xtest, ytest):
        y_pred = self.predict(Xtest)
        RMSEP, R2p = self.calc_rmsec(ytest, y_pred)
        return y_pred, RMSEP, R2p

    def calculate_vip(self, X, y):
        # Fit the model to get t, w, q
        X_c = self.pretreat(X, 'center')
        y_c = self.scaler_y.transform(y.reshape(-1, 1)).flatten()

        # Calculate scores, weights, and loadings
        t = self.pls.x_scores_
        w = self.pls.x_weights_
        q = self.pls.y_loadings_

        # VIP calculation
        p, h = X.shape
        t2 = t ** 2
        q2 = q ** 2
        s = np.diag(np.dot(t2, q2.T))  # Calculate the VIP contribution
        total_s = np.sum(s)

        # Calculate VIP values
        vip = np.sqrt(h * s / total_s).flatten()
        return vip

    def plot_results(self, y_true, y_pred, title='Prediction vs Reference'):
        plt.scatter(y_true, y_pred, color='red')
        plt.plot([min(y_true), max(y_true)], [min(y_true), max(y_true)], color='black')
        plt.xlabel('Reference')
        plt.ylabel('Prediction')
        plt.title(title)
        plt.show()


# 读取之前提取的RGB值和吸光度数据
input_path_cal = '../Data/1-standard-methyl-orange/output_rgb_values.xlsx'
data_cal = pd.read_excel(input_path_cal)

# 准备校准数据
Xcal = data_cal[['Red', 'Green', 'Blue']].values
ycal = data_cal['Absorbance'].values

# 创建和训练PLS模型
pls_model = PLSModel(nLV=2, isplot=True)
pls_model.fit(Xcal, ycal)

# 交叉验证
rmsecv, r2cv = pls_model.cross_validate(Xcal, ycal)
print(f'Cross-Validation RMSE: {rmsecv}, R2: {r2cv}')

# 预测和评估（在校准数据上）
ycal_pred = pls_model.predict(Xcal)
cal_rmse, cal_r2 = pls_model.calc_rmsec(ycal, ycal_pred)
print(f'Calibration RMSE: {cal_rmse}, R2: {cal_r2}')

# 绘制校准结果
pls_model.plot_results(ycal, ycal_pred, title='Calibration')

# 读取外部验证数据
input_path_ext = '../Data/8-catalyzer-orange/1-Ag-TiO2/output_rgb_values.xlsx'
data_ext = pd.read_excel(input_path_ext)

# 准备外部验证数据
Xtest = data_ext[['Red', 'Green', 'Blue']].values
ytest = data_ext['Absorbance'].values

# 使用模型进行预测
ytest_pred, rmsep, r2p = pls_model.evaluate(Xtest, ytest)
print(f'External Validation RMSE: {rmsep}, R2: {r2p}')

# 绘制外部验证结果
pls_model.plot_results(ytest, ytest_pred, title='External Validation')

# 输出VIP值
print("VIP值:", pls_model.VIP_)
