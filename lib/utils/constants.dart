class AppConstants {
  static const String appName = 'Freshmart';

  // Shared Preferences Keys
  static const String cartKey = 'cart_items';
  static const String userKey = 'user_data';

  // Default values
  static const int defaultQuantity = 1;
  static const double defaultShippingCost = 15000;

  // Validation
  static const int maxQuantityPerItem = 99;
  static const int minQuantityPerItem = 1;
}

class AppStrings {
  // Common
  static const String cancel = 'Hủy';
  static const String confirm = 'Xác nhận';
  static const String ok = 'OK';
  static const String error = 'Lỗi';
  static const String success = 'Thành công';

  // Navigation
  static const String home = 'Trang chủ';
  static const String cart = 'Giỏ hàng';
  static const String profile = 'Tài khoản';

  // Home Screen
  static const String searchHint = 'Tìm kiếm sản phẩm...';
  static const String allCategories = 'Tất cả';

  // Cart Screen
  static const String emptyCart = 'Giỏ hàng trống';
  static const String emptyCartSubtitle = 'Thêm sản phẩm để bắt đầu mua sắm';
  static const String totalAmount = 'Tổng cộng:';
  static const String checkout = 'Thanh toán';

  // Messages
  static const String addedToCart = 'Đã thêm vào giỏ hàng';
  static const String removedFromCart = 'Đã xóa khỏi giỏ hàng';
  static const String orderConfirmation = 'Xác nhận đơn hàng';
  static const String orderSuccess = 'Đơn hàng đã được đặt thành công!';
  static const String orderSuccessSubtitle = 'Chúng tôi sẽ giao hàng trong 24h.';

  // Profile
  static const String orderHistory = 'Lịch sử mua hàng';
  static const String favorites = 'Sản phẩm yêu thích';
  static const String shippingAddress = 'Địa chỉ giao hàng';
  static const String paymentMethods = 'Phương thức thanh toán';
  static const String notifications = 'Thông báo';
  static const String suggestion = 'Góp ý';
  static const String settings = 'Cài đặt';
}