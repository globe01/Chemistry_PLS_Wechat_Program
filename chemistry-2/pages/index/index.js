// index.js
// const defaultAvatarUrl = 'https://mmbiz.qpic.cn/mmbiz/icTdbqWNOwNRna42FI242Lcia07jQodd2FJGIYQfG0LAJGFxM4FbnQP6yfMxBgJ0F3YRqJCJ1aPAK2dQagdusBZg/0'


// index.js
Page({
  data: {
    imagePath: '',
    concentration: ''  // 用于存储预测的浓度值
  },
  chooseImage() {
    wx.chooseImage({
      count: 1,
      sizeType: ['compressed'],
      sourceType: ['album', 'camera'],
      success: (res) => {
        this.setData({
          imagePath: res.tempFilePaths[0],
          concentration: ''
        });
        this.uploadImage(res.tempFilePaths[0]);
      }
    });
  },
  uploadImage(filePath) {
    wx.uploadFile({
      url: 'https://6a51-111-53-247-244.ngrok-free.app/upload',
      filePath: filePath,
      name: 'file',
      method: 'POST',
      formData: {
        'model_type': 'concentration'  // 指定使用浓度模型
      },
      success: (res) => {
        console.log('Server response:', res);
        const data = JSON.parse(res.data);
        if (data.error) {
          wx.showToast({
            title: `Error: ${data.error}`,
            icon: 'none'
          });
        } else {
          const formattedConcentration = parseFloat(data.concentration).toFixed(3);  // 保留三位小数
          const concentrationWithUnit = `${formattedConcentration} mmol/L`;  // 添加单位
          wx.showToast({
            title: `预测浓度: ${concentrationWithUnit}`,
            icon: 'none'
          });

          // 记录历史数据，保留RGB值小数点后三位
          const rgbFormatted = `R: ${data.rgb.red.toFixed(3)}, G: ${data.rgb.green.toFixed(3)}, B: ${data.rgb.blue.toFixed(3)}`;
          const newRecord = {
            concentration: concentrationWithUnit,
            rgbValues: rgbFormatted
          };
          this.setData(newRecord);

          // 保存到历史记录
          let history = wx.getStorageSync('history') || [];
          history.unshift(newRecord); // 添加到数组开头
          wx.setStorageSync('history', history);
        }
      },
      fail: (err) => {
        console.error('Upload failed:', err);
        wx.showToast({
          title: '上传失败',
          icon: 'none'
        });
      }
    });
  }
});


