// pages/history/history.js
Page({
  data: {
    history: []
  },
  onLoad() {
    const history = wx.getStorageSync('history') || [];
    this.setData({ history });
  }
});

