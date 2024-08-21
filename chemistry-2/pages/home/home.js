Page({
  data: {},
  goToPrediction() {
    wx.switchTab({
      url: '/pages/index/index',  // 进入浓度页面的路径
    });
  }
});
