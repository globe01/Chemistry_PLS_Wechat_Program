// index.js
// const defaultAvatarUrl = 'https://mmbiz.qpic.cn/mmbiz/icTdbqWNOwNRna42FI242Lcia07jQodd2FJGIYQfG0LAJGFxM4FbnQP6yfMxBgJ0F3YRqJCJ1aPAK2dQagdusBZg/0'

Page({
  data: {
    imagePath: '',
    rgbValues: '',
    absorbance: ''
  },
  chooseImage() {
    wx.chooseImage({
      count: 1,
      sizeType: ['compressed'],
      sourceType: ['album', 'camera'],
      success: (res) => {
        this.setData({
          imagePath: res.tempFilePaths[0],
          rgbValues: '',
          absorbance: ''
        });
        this.uploadImage(res.tempFilePaths[0]);
      }
    });
  },
  uploadImage(filePath) {
    wx.uploadFile({
      url: 'https://4138-2408-8226-250-fc0-6811-be2e-28b-392e.ngrok-free.app/upload', // 就是后端的Flask服务器地址，后面/upload记得写！暂且用ngrok提供的公网地址
      filePath: filePath,
      name: 'file',
      method: 'POST', // 全改成用POST方法
      success: (res) => {
        console.log('Server response:', res);// 添加log日志
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
          const newRecord = {
            rgbValues: `R: ${data.rgb.red}, G: ${data.rgb.green}, B: ${data.rgb.blue}`,
            absorbance: data.absorbance
          };
          this.setData(newRecord);

          // 保存到历史记录
          let history = wx.getStorageSync('history') || [];
          history.unshift(newRecord); // 添加到数组开头
          wx.setStorageSync('history', history);
        }
      },
      fail: (err) => {
        console.error(err);
        wx.showToast({
          title: '上传失败',
          icon: 'none'
        });
      }
    });
  }
});
