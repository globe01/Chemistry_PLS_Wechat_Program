Page({
  data: {
    imagePath: '',
    absorbance: '' // 用于存储预测的吸光度值
  },
  chooseImage() {
    wx.chooseImage({
      count: 1,
      sizeType: ['compressed'],
      sourceType: ['album', 'camera'],
      success: (res) => {
        this.setData({
          imagePath: res.tempFilePaths[0],
          absorbance: ''
        });
        this.uploadImage(res.tempFilePaths[0]);
      }
    });
  },
  uploadImage(filePath) {
    wx.uploadFile({
      url: 'https://4138-2408-8226-250-fc0-6811-be2e-28b-392e.ngrok-free.app/upload', 
      filePath: filePath,
      name: 'file',
      method: 'POST',
      success: (res) => {
        console.log('Server response:', res);
        const data = JSON.parse(res.data);
        if (data.error) {
          wx.showToast({
            title: `Error: ${data.error}`,
            icon: 'none'
          });
        } else {
          wx.showToast({
            title: `预测吸光度: ${data.absorbance}`,
            icon: 'none'
          });

          // 记录历史数据，保留RGB值小数点后三位
          const rgbFormatted = `R: ${data.rgb.red.toFixed(3)}, G: ${data.rgb.green.toFixed(3)}, B: ${data.rgb.blue.toFixed(3)}`;
          const newRecord = {
            absorbance: data.absorbance,
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
