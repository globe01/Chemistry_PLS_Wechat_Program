import pandas as pd
import numpy as np
import joblib

# 加载模型和标准化器
blue_pls_absorbance_model = joblib.load('BluePurple-trained_pls_absorbance_model.pkl')
blue_pls_concentration_model = joblib.load('BluePurple-trained_pls_concentration_model.pkl')
blue_scaler_X = joblib.load('BluePurple-scaler_X_standard.pkl')
blue_scaler_y_absorbance = joblib.load('BluePurple-scaler_y_absorbance_standard.pkl')
blue_scaler_y_concentration = joblib.load('BluePurple-scaler_y_concentration_standard.pkl')

orange_pls_absorbance_model = joblib.load('OrangePurple-trained_pls_absorbance_model.pkl')
orange_pls_concentration_model = joblib.load('OrangePurple-trained_pls_concentration_model.pkl')
orange_scaler_X = joblib.load('OrangePurple-scaler_X_standard.pkl')
orange_scaler_y_absorbance = joblib.load('OrangePurple-scaler_y_absorbance_standard.pkl')
orange_scaler_y_concentration = joblib.load('OrangePurple-scaler_y_concentration_standard.pkl')


def determine_color(rgb):
    """简单判断颜色是甲基橙还是亚甲基蓝"""
    red, green, blue = rgb['red'], rgb['green'], rgb['blue']
    if red > blue:
        return 'orange'
    else:
        return 'blue'


def predict_concentration_absorbance(rgb_input):
    # 确保输入为二维数组
    if isinstance(rgb_input, dict):
        rgb_input = np.array([[rgb_input['red'], rgb_input['green'], rgb_input['blue']]])

    # 根据RGB值确定颜色类型
    color_type = determine_color({'red': rgb_input[0][0], 'green': rgb_input[0][1], 'blue': rgb_input[0][2]})

    # 根据颜色类型选择对应的模型和标准化器
    if color_type == 'blue':
        pls_absorbance_model = blue_pls_absorbance_model
        pls_concentration_model = blue_pls_concentration_model
        scaler_X = blue_scaler_X
        scaler_y_absorbance = blue_scaler_y_absorbance
        scaler_y_concentration = blue_scaler_y_concentration
    else:
        pls_absorbance_model = orange_pls_absorbance_model
        pls_concentration_model = orange_pls_concentration_model
        scaler_X = orange_scaler_X
        scaler_y_absorbance = orange_scaler_y_absorbance
        scaler_y_concentration = orange_scaler_y_concentration

    # 标准化输入的RGB值
    rgb_input_scaled = scaler_X.transform(rgb_input)

    # 使用训练好的模型进行吸光度预测
    predicted_absorbance_scaled = pls_absorbance_model.predict(rgb_input_scaled)
    predicted_absorbance = scaler_y_absorbance.inverse_transform(predicted_absorbance_scaled.reshape(-1, 1)).ravel()

    # 使用训练好的模型进行浓度预测
    predicted_concentration_scaled = pls_concentration_model.predict(rgb_input_scaled)
    predicted_concentration = scaler_y_concentration.inverse_transform(
        predicted_concentration_scaled.reshape(-1, 1)).ravel()

    # 修正负值，确保预测值不为负数
    predicted_concentration = np.maximum(0, predicted_concentration)

    return predicted_absorbance[0], predicted_concentration[0]


# 读取输入文件，执行预测，并保存结果
def process_and_predict(input_file, output_file):
    # 读取输入文件
    data = pd.read_excel(input_file)

    # 创建存储预测结果的新列
    predicted_absorbance_list = []
    predicted_concentration_list = []

    # 遍历每一行数据，提取RGB进行预测
    for index, row in data.iterrows():
        rgb_input = {'red': row['Red'], 'green': row['Green'], 'blue': row['Blue']}
        predicted_absorbance, predicted_concentration = predict_concentration_absorbance(rgb_input)

        # 存储预测结果
        predicted_absorbance_list.append(predicted_absorbance)
        predicted_concentration_list.append(predicted_concentration)

    # 将预测结果添加到DataFrame
    data['PredictedConcentration'] = predicted_concentration_list
    data['PredictedAbsorbance'] = predicted_absorbance_list

    # 按照Absorbance列倒序排序
    data_sorted = data.sort_values(by='Absorbance', ascending=False)

    # 重新排列列的顺序
    columns_order = ['Absorbance', 'Red', 'Green', 'Blue', 'PredictedConcentration', 'PredictedAbsorbance']
    data_sorted = data_sorted[columns_order]

    # 保存结果到新的Excel文件
    data_sorted.to_excel(output_file, index=False)
    print(f"预测结果已保存至: {output_file}")


# 调用处理函数
input_file = '../newData/light/blue-AllLightData/blue-TiO2.xlsx'  # 你的输入文件
output_file = '../newData/light/blue-AllLightData/predicted/blue-TiO2-predicted.xlsx'  # 预测结果输出文件
process_and_predict(input_file, output_file)
