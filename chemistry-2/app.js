// app.js
App({
  onLaunch() {
    // 展示本地存储能力
    const logs = wx.getStorageSync('logs') || []
    logs.unshift(Date.now())
    wx.setStorageSync('logs', logs)

    // 登录
    wx.login({
      success: res => {
        // 发送 res.code 到后台换取 openId, sessionKey, unionId
      }
    })
  },
  globalData: {
    userInfo: null,
    // 共享检测结果
    sharedResult: null
    // 结构: {
    //   imagePath: '',
    //   processedImagePath: '',
    //   concentration: '',
    //   absorbance: '',
    //   rgbValues: '',
    //   rgbRed: 0,
    //   rgbGreen: 0,
    //   rgbBlue: 0,
    //   colorType: '',
    //   timestamp: ''
    // }
  }
})
