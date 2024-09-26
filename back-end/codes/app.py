from flask import Flask, request, jsonify, send_file
import numpy as np
import cv2
import joblib
import os
from werkzeug.utils import secure_filename
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

UPLOAD_FOLDER = 'uploads'
PROCESSED_FOLDER = 'processed'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['PROCESSED_FOLDER'] = PROCESSED_FOLDER

if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)
if not os.path.exists(PROCESSED_FOLDER):
    os.makedirs(PROCESSED_FOLDER)

# 加载训练好的PLS模型和标准化器
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

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def extract_rgb(image_path):
    img = cv2.imread(image_path)
    height, width, _ = img.shape

    # 提取四个角的白色区域，每个区域大小为 h//8 和 w//8
    corner_h = height // 8
    corner_w = width // 8

    # 获取四个角区域
    top_left = img[:corner_h, :corner_w]
    top_right = img[:corner_h, -corner_w:]
    bottom_left = img[-corner_h:, :corner_w]
    bottom_right = img[-corner_h:, -corner_w:]

    # 合并四个角的区域，计算平均白色RGB
    white_regions = np.concatenate((top_left, top_right, bottom_left, bottom_right), axis=0)
    avg_color_per_row = np.average(white_regions, axis=0)
    avg_white_colors = np.average(avg_color_per_row, axis=0)

    # 计算白色校正因子，目标是将白色矫正到理想的白色RGB [255, 255, 255]
    ideal_white = np.array([255, 255, 255])
    correction_factor = ideal_white / avg_white_colors

    # 提取中心区域的 RGB 值
    center_x, center_y = width // 4, height // 4
    center_width, center_height = width // 2, height // 2
    center_img = img[center_y:center_y + center_height, center_x:center_x + center_width]

    # 对中心区域应用白色校正因子
    corrected_center_img = center_img * correction_factor
    corrected_center_img = np.clip(corrected_center_img, 0, 255).astype(np.uint8)

    # 计算校正后的中心区域的平均RGB
    avg_color_per_row_center = np.average(corrected_center_img, axis=0)
    avg_colors_center = np.average(avg_color_per_row_center, axis=0)

    # 返回校正后的中心RGB值和中心区域的坐标
    return {'red': avg_colors_center[2], 'green': avg_colors_center[1], 'blue': avg_colors_center[0]}, (center_x, center_y, center_width, center_height)


def add_red_box(image_path, box_coords):
    img = cv2.imread(image_path)
    center_x, center_y, center_width, center_height = box_coords
    cv2.rectangle(img, (center_x, center_y), (center_x + center_width, center_y + center_height), (0, 0, 255), 2)
    processed_image_path = os.path.join(app.config['PROCESSED_FOLDER'], 'processed_' + os.path.basename(image_path))
    cv2.imwrite(processed_image_path, img)
    return processed_image_path

def determine_color(rgb):
    """简单判断颜色是甲基橙还是亚甲基蓝"""
    red, green, blue = rgb['red'], rgb['green'], rgb['blue']
    if red > blue:
        return 'orange'
    else:
        return 'blue'


@app.route('/')
def home():
    return '''
        <h1>Welcome to Chemistry PLS App!</h1>
        <p>ICP备案/许可证号：<a href="https://beian.miit.gov.cn/" target="_blank">津ICP备2024023054号-2</a></p>
    '''


@app.route('/upload', methods=['POST'])
def upload_file():
    print("Received request:", request.method)
    if 'file' not in request.files:
        print("No file part")
        return jsonify({'error': 'No file part'})

    file = request.files['file']
    print("File received:", file.filename)

    if file.filename == '':
        print("No selected file")
        return jsonify({'error': 'No selected file'})

    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(file_path)
        print("File saved to:", file_path)

        # 提取RGB值并获取中心区域的坐标
        rgb, box_coords = extract_rgb(file_path)
        print("Extracted RGB:", rgb)

        # 识别颜色类型
        color_type = determine_color(rgb)
        print("Detected color type:", color_type)

        # 选择相应的模型
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

        # 添加红色方框并保存处理后的图像
        processed_image_path = add_red_box(file_path, box_coords)
        print("Processed image saved to:", processed_image_path)

        # 标准化输入数据
        X = np.array([[rgb['red'], rgb['green'], rgb['blue']]])
        X_scaled = scaler_X.transform(X)

        # 进行预测
        model_type = request.form.get('model_type')
        if model_type == 'absorbance':
            y_pred_scaled = pls_absorbance_model.predict(X_scaled)
            y_pred = scaler_y_absorbance.inverse_transform(y_pred_scaled.reshape(-1, 1)).ravel()[0]
            y_pred = max(0, y_pred)
            print("Predicted absorbance:", y_pred)
            return jsonify({'rgb': rgb, 'absorbance': y_pred, 'processed_image': processed_image_path})

        elif model_type == 'concentration':
            y_pred_scaled = pls_concentration_model.predict(X_scaled)
            y_pred = scaler_y_concentration.inverse_transform(y_pred_scaled.reshape(-1, 1)).ravel()[0]
            y_pred = max(0, y_pred)
            print("Predicted concentration:", y_pred)
            return jsonify({'rgb': rgb, 'concentration': y_pred, 'processed_image': processed_image_path})

    else:
        print("File type not allowed")
        return jsonify({'error': 'File type not allowed'})


@app.route('/processed_image/<filename>', methods=['GET'])
def get_processed_image(filename):
    return send_file(os.path.join(app.config['PROCESSED_FOLDER'], filename))


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
