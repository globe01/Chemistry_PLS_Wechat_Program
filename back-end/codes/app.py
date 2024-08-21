from flask import Flask, request, jsonify
import numpy as np
import cv2
import joblib
import os
from werkzeug.utils import secure_filename
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # 允许所有跨域请求

UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# 创建上传文件夹
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

# 加载训练好的PLS模型和标准化器
pls_model = joblib.load('pls_model.pkl')
scaler_X = joblib.load('scaler_X.pkl')
scaler_y = joblib.load('scaler_y.pkl')


def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


def extract_rgb(image_path):
    img = cv2.imread(image_path)
    height, width, _ = img.shape
    center_x, center_y = width // 4, height // 4
    center_width, center_height = width // 2, height // 2
    center_img = img[center_y:center_y + center_height, center_x:center_x + center_width]

    avg_color_per_row = np.average(center_img, axis=0)
    avg_colors = np.average(avg_color_per_row, axis=0)
    return {'red': avg_colors[2], 'green': avg_colors[1], 'blue': avg_colors[0]}


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

        # 提取RGB值
        rgb = extract_rgb(file_path)
        print("Extracted RGB:", rgb)

        # 标准化输入数据
        X = np.array([[rgb['red'], rgb['green'], rgb['blue']]])
        X_scaled = scaler_X.transform(X)

        # 进行预测
        y_pred_scaled = pls_model.predict(X_scaled)
        y_pred = scaler_y.inverse_transform(y_pred_scaled.reshape(-1, 1)).ravel()[0]
        print("Predicted absorbance:", y_pred)

        return jsonify({'rgb': rgb, 'absorbance': y_pred})
    else:
        print("File type not allowed")
        return jsonify({'error': 'File type not allowed'})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
