from waitress import serve
from app import app  # 从app.py中导入app对象

if __name__ == '__main__':
    serve(app, host='0.0.0.0', port=5000)
