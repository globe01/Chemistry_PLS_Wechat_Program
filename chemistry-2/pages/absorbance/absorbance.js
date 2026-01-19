// absorbance.js
const app = getApp();

Page({
  data: {
    imagePath: '',
    processedImagePath: '',
    concentration: '',
    absorbance: '',
    rgbValues: '',
    rgbRed: 0,
    rgbGreen: 0,
    rgbBlue: 0,
    colorType: '',
    isLoading: false
  },

  onShow() {
    // 页面显示时检查全局共享数据
    const sharedResult = app.globalData.sharedResult;
    if (sharedResult && sharedResult.absorbance) {
      this.setData({
        imagePath: sharedResult.imagePath || '',
        processedImagePath: sharedResult.processedImagePath || '',
        concentration: sharedResult.concentration || '',
        absorbance: sharedResult.absorbance,
        rgbValues: sharedResult.rgbValues,
        rgbRed: sharedResult.rgbRed,
        rgbGreen: sharedResult.rgbGreen,
        rgbBlue: sharedResult.rgbBlue,
        colorType: sharedResult.colorType,
        isLoading: false  // 确保重置加载状态
      });
    }
  },

  chooseImage() {
    wx.chooseImage({
      count: 1,
      sizeType: ['compressed'],
      sourceType: ['album', 'camera'],
      success: (res) => {
        // 清空全局数据，开始新的检测
        app.globalData.sharedResult = null;
        
        this.setData({
          imagePath: res.tempFilePaths[0],
          concentration: '',
          absorbance: '',
          processedImagePath: '',
          rgbValues: '',
          rgbRed: 0,
          rgbGreen: 0,
          rgbBlue: 0,
          colorType: '',
          isLoading: true
        });
        this.uploadImage(res.tempFilePaths[0], 0);
      }
    });
  },

  uploadImage(filePath, retryCount) {
    const maxRetry = 2;
    const that = this;  // 保存 this 引用
    
    wx.uploadFile({
      url: 'https://chemistryplsmodel.com/upload',
      filePath: filePath,
      name: 'file',
      timeout: 60000,
      formData: {
        'model_type': 'both'
      },
      success: (res) => {
        console.log('Server response:', res);
        try {
          const data = JSON.parse(res.data);
          if (data.error) {
            that.setData({ isLoading: false });
            wx.showToast({
              title: `错误: ${data.error}`,
              icon: 'none'
            });
            return;
          }
          
          // 格式化数据
          const formattedConcentration = parseFloat(data.concentration).toFixed(3);
          const concentrationWithUnit = `${formattedConcentration} mg/L`;
          const formattedAbsorbance = parseFloat(data.absorbance).toFixed(3);
          
          const rgbRed = Math.round(data.rgb.red);
          const rgbGreen = Math.round(data.rgb.green);
          const rgbBlue = Math.round(data.rgb.blue);
          const rgbFormatted = `R: ${rgbRed}, G: ${rgbGreen}, B: ${rgbBlue}`;
          const colorType = rgbRed > rgbBlue ? 'orange' : 'blue';
          
          // 保存到历史记录
          const newRecord = {
            type: 'both',
            concentration: concentrationWithUnit,
            absorbance: formattedAbsorbance,
            rgbValues: rgbFormatted,
            colorType: colorType,
            timestamp: new Date().toLocaleString()
          };
          let history = wx.getStorageSync('history') || [];
          history.unshift(newRecord);
          wx.setStorageSync('history', history);

          // 先立即保存全局数据（在下载图片之前）
          app.globalData.sharedResult = {
            imagePath: filePath,
            processedImagePath: '',
            concentration: concentrationWithUnit,
            absorbance: formattedAbsorbance,
            rgbValues: rgbFormatted,
            rgbRed: rgbRed,
            rgbGreen: rgbGreen,
            rgbBlue: rgbBlue,
            colorType: colorType,
            timestamp: new Date().getTime()
          };

          // 先停止加载动画，显示结果
          that.setData({
            isLoading: false,
            concentration: concentrationWithUnit,
            absorbance: formattedAbsorbance,
            rgbValues: rgbFormatted,
            rgbRed: rgbRed,
            rgbGreen: rgbGreen,
            rgbBlue: rgbBlue,
            colorType: colorType
          }, () => {
            // setData 回调确保 UI 已更新后再下载图片
            that.downloadProcessedImage(data.processed_image, filePath);
          });

        } catch (e) {
          console.error('Parse error:', e);
          that.setData({ isLoading: false });
          wx.showToast({ title: '数据解析失败', icon: 'none' });
        }
      },
      fail: (err) => {
        console.error('Upload failed:', err);
        if (retryCount < maxRetry) {
          console.log(`Retrying... (${retryCount + 1}/${maxRetry})`);
          setTimeout(() => {
            that.uploadImage(filePath, retryCount + 1);
          }, 1000);
        } else {
          that.setData({ isLoading: false });
          wx.showToast({
            title: '网络不稳定，请重试',
            icon: 'none',
            duration: 2000
          });
        }
      }
    });
  },

  downloadProcessedImage(imagePath, originalFilePath) {
    const that = this;
    const filename = imagePath.split('/').pop();
    
    wx.downloadFile({
      url: `https://chemistryplsmodel.com/processed_image/${filename}`,
      timeout: 30000,
      success: (downloadRes) => {
        console.log('Download processed image success:', downloadRes);
        if (downloadRes.statusCode === 200) {
          that.setData({
            processedImagePath: downloadRes.tempFilePath
          });
          
          // 更新全局数据中的处理后图片路径
          if (app.globalData.sharedResult) {
            app.globalData.sharedResult.processedImagePath = downloadRes.tempFilePath;
          }
        }
      },
      fail: (err) => {
        console.error('Failed to download processed image:', err);
        // 下载失败不影响结果显示
      }
    });
  },

  previewImage(e) {
    const src = e.currentTarget.dataset.src;
    const urls = [this.data.imagePath];
    if (this.data.processedImagePath) {
      urls.push(this.data.processedImagePath);
    }
    wx.previewImage({
      current: src,
      urls: urls
    });
  }
});
