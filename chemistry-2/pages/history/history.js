// pages/history/history.js
Page({
  data: {
    history: []
  },

  onLoad() {
    this.loadHistory();
  },

  onShow() {
    // 每次显示页面时刷新历史记录
    this.loadHistory();
  },

  loadHistory() {
    const history = wx.getStorageSync('history') || [];
    this.setData({ history });
  },

  clearHistory() {
    wx.showModal({
      title: '确认清空',
      content: '确定要清空所有历史记录吗？此操作不可恢复。',
      confirmText: '清空',
      confirmColor: '#ff4d4d',
      success: (res) => {
        if (res.confirm) {
          wx.setStorageSync('history', []);
          this.setData({ history: [] });
          wx.showToast({
            title: '已清空',
            icon: 'success'
          });
        }
      }
    });
  }
});
