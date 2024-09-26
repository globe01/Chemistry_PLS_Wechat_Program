// index.js
Page({
  data: {
    imagePath: '',
    processedImagePath: '',  // 用于存储带红框的图像路径
    concentration: ''  // 用于存储检测的浓度值
  },
  chooseImage() {
    wx.chooseImage({
      count: 1,
      sizeType: ['compressed'],
      sourceType: ['album', 'camera'],
      success: (res) => {
        this.setData({
          imagePath: res.tempFilePaths[0],
          concentration: '',
          processedImagePath: ''  // 重置处理后图像路径
        });
        this.uploadImage(res.tempFilePaths[0]);
      }
    });
  },
  uploadImage(filePath) {
    wx.uploadFile({
      url: 'https://chemistryplsmodel.com/upload',
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
          const concentrationWithUnit = `${formattedConcentration} mg/L`;  // 添加单位
          wx.showToast({
            title: `检测浓度: ${concentrationWithUnit}`,
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

          // 下载处理后的图像并显示
          wx.downloadFile({
            url: `https://chemistryplsmodel.com/processed_image/${data.processed_image}`,
            success: (downloadRes) => {
              if (downloadRes.statusCode === 200) {
                this.setData({
                  processedImagePath: downloadRes.tempFilePath  // 临时文件路径
                });
              }
            },
            fail: (err) => {
              console.error('Failed to download processed image:', err);
            }
          });
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
