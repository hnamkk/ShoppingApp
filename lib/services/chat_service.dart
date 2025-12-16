import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final GenerativeModel _model;
  final Map<String, List<Content>> _conversationHistory = {};

  ChatService() {
    final apiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      print('WARNING: GOOGLE_API_KEY is empty!');
    }

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 512,
        topP: 0.9,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
      ],
    );
  }

  Future<void> testAPIConnection() async {
    try {
      print('Testing Gemini API...');
      final response = await _model.generateContent([
        Content.text('Hello')
      ]);
      print('API Test Success: ${response.text}');
    } catch (e) {
      print('API Test Failed: $e');
    }
  }

  Future<String> sendMessage(String message, String userId) async {
    try {
      if (message.trim().isEmpty) {
        return 'Bạn cần tôi hỗ trợ gì? Tôi có thể giúp kiểm tra đơn hàng, gợi ý sản phẩm, hoặc trả lời thắc mắc.';
      }

      final intent = await _detectIntentWithAI(message);

      switch (intent) {
        case ChatIntent.orderTracking:
          return await _handleOrderTracking(message, userId);
        case ChatIntent.productRecommendation:
          return await _handleProductRecommendationWithAI(message, userId);
        case ChatIntent.recipeHelp:
          return await _handleRecipeHelp(message, userId);
        default:
          return await _handleGeneral(message, userId);
      }
    } on GenerativeAIException catch (e) {
      print('GenerativeAIException: ${e.message}');
      return 'Xin lỗi, tôi đang gặp sự cố kết nối. Vui lòng thử lại sau.';
    } catch (e, stackTrace) {
      print('Error in sendMessage: $e');
      print('Stack trace: $stackTrace');
      return 'Hiện tại tôi không xử lý được yêu cầu, vui lòng thử lại sau.';
    }
  }

  Future<ChatIntent> _detectIntentWithAI(String message) async {
    try {
      final prompt = '''
Phân loại ý định của câu hỏi về mua sắm tạp hóa/thực phẩm:

ORDER_TRACKING: Kiểm tra đơn hàng, trạng thái giao hàng
PRODUCT_RECOMMENDATION: Gợi ý thực phẩm, tìm sản phẩm, hỏi có hàng không
RECIPE_HELP: Hỏi công thức nấu ăn, cách chế biến, kết hợp nguyên liệu
GENERAL: Chào hỏi, hỏi chính sách, giờ giao hàng, thanh toán

Câu: "$message"

Chỉ trả lời: ORDER_TRACKING hoặc PRODUCT_RECOMMENDATION hoặc RECIPE_HELP hoặc GENERAL
''';

      final response = await _model.generateContent([Content.text(prompt)]);

      if (response.text == null || response.text!.isEmpty) {
        return _detectIntentFallback(message);
      }

      final intent = response.text!.trim().toUpperCase().replaceAll(' ', '_');
      print('AI detected intent: $intent');

      if (intent.contains('ORDER')) return ChatIntent.orderTracking;
      if (intent.contains('RECIPE')) return ChatIntent.recipeHelp;
      if (intent.contains('PRODUCT') || intent.contains('RECOMMENDATION')) {
        return ChatIntent.productRecommendation;
      }
      return ChatIntent.general;
    } catch (e) {
      print('Error in AI intent detection: $e');
      return _detectIntentFallback(message);
    }
  }

  ChatIntent _detectIntentFallback(String message) {
    final m = message.toLowerCase();

    if (m.contains('đơn hàng') ||
        m.contains('trạng thái') ||
        m.contains('giao hàng') ||
        m.contains('order') ||
        m.contains('kiểm tra đơn')) {
      return ChatIntent.orderTracking;
    }

    if (m.contains('công thức') ||
        m.contains('nấu') ||
        m.contains('chế biến') ||
        m.contains('làm món') ||
        m.contains('recipe')) {
      return ChatIntent.recipeHelp;
    }

    if (m.contains('gợi ý') ||
        m.contains('tìm') ||
        m.contains('có') ||
        m.contains('bán') ||
        m.contains('mua') ||
        m.contains('tươi') ||
        m.contains('ngon')) {
      return ChatIntent.productRecommendation;
    }

    return ChatIntent.general;
  }

  Future<String> _handleOrderTracking(String message, String userId) async {
    final orders = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

    if (orders.docs.isEmpty) {
      return 'Bạn chưa có đơn hàng nào. Hãy đặt đơn để nhận ưu đãi giao hàng miễn phí cho đơn đầu tiên!';
    }

    final specificId = _extractOrderId(message);
    if (specificId != null) {
      return await _orderDetail(specificId, userId);
    }

    final buffer = StringBuffer();
    buffer.writeln('Đơn hàng gần đây của bạn:\n');

    for (final doc in orders.docs) {
      final data = doc.data();
      final orderId = doc.id;
      final status = _statusText(data['status'] ?? 'pending');
      final total = _formatCurrency((data['totalAmount'] ?? 0).toDouble());
      final createdAt = _formatDate(data['createdAt']);

      buffer.writeln('Mã: #$orderId');
      buffer.writeln('Trạng thái: $status');
      buffer.writeln('Tổng tiền: $total');
      buffer.writeln('Ngày đặt: $createdAt');
      buffer.writeln('');
    }

    buffer.writeln('Nhập mã đơn để xem chi tiết (vd: #${orders.docs.first.id})');
    return buffer.toString();
  }

  Future<String> _orderDetail(String orderId, String userId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (!doc.exists) {
        return 'Không tìm thấy đơn hàng $orderId. Vui lòng kiểm tra lại mã đơn.';
      }

      final data = doc.data()!;
      if ((data['userId'] ?? '') != userId) {
        return 'Đơn hàng này không thuộc tài khoản của bạn.';
      }

      final status = _statusText(data['status'] ?? 'pending');
      final subtotal = _formatCurrency((data['subtotalAmount'] ?? 0).toDouble());
      final discount = _formatCurrency((data['discount'] ?? 0).toDouble());
      final total = _formatCurrency((data['totalAmount'] ?? 0).toDouble());
      final createdAt = _formatDate(data['createdAt']);
      final paymentMethod = _paymentMethodText(data['paymentMethod'] ?? '');

      final items = (data['items'] as List<dynamic>? ?? [])
          .map((e) => '${e['name'] ?? 'Sản phẩm'} x${e['quantity'] ?? 1} - ${_formatCurrency((e['price'] ?? 0).toDouble())}')
          .join('\n');

      final address = data['deliveryAddress'] ?? 'Chưa cập nhật';
      final note = data['note'] ?? '';
      final voucherCode = data['voucherCode'];

      final buffer = StringBuffer();

      buffer.writeln('Chi tiết đơn hàng #$orderId\n');
      buffer.writeln('Trạng thái: $status');
      buffer.writeln('Ngày đặt: $createdAt');
      buffer.writeln('Phương thức thanh toán: $paymentMethod\n');
      buffer.writeln('Sản phẩm:');
      buffer.writeln(items);
      buffer.writeln('\nTạm tính: $subtotal');
      if ((data['discount'] ?? 0) > 0) {
        buffer.writeln('Giảm giá: -$discount');
        if (voucherCode != null) {
          buffer.writeln('Mã giảm giá: $voucherCode');
        }
      }
      buffer.writeln('Tổng tiền: $total\n');
      buffer.writeln('Địa chỉ giao hàng:');
      buffer.writeln(address);

      if (note.isNotEmpty) {
        buffer.writeln('\nGhi chú: $note');
      }

      if (data['status'] == 'shipping') {
        buffer.writeln('\nĐơn hàng đang trên đường giao đến bạn!');
      } else if (data['status'] == 'pending') {
        buffer.writeln('\nĐơn hàng đang chờ xác nhận. Chúng tôi sẽ liên hệ bạn sớm nhất.');
      }

      return buffer.toString();
    } catch (e) {
      print('Error getting order detail: $e');
      return 'Lỗi khi lấy chi tiết đơn hàng. Vui lòng thử lại.';
    }
  }

  Future<String> _handleProductRecommendationWithAI(String message, String userId) async {
    try {
      final historyProductIds = await _getPurchasedProductIds(userId);
      final favoriteIds = await _getFavoriteProductIds(userId);

      final used = <String>{};
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> picked = [];

      String? preferredCategory = _detectCategory(message);

      Future<void> addProductsByCategory(String? category) async {
        var query = _firestore.collection('products').where('stock', isGreaterThan: 0);

        if (category != null) {
          query = query.where('category', isEqualTo: category);
        }

        final products = await query.orderBy('stock').limit(20).get();

        for (final p in products.docs) {
          if (used.contains(p.id)) continue;
          picked.add(p);
          used.add(p.id);
          if (picked.length >= 5) return;
        }
      }

      if (preferredCategory != null) {
        await addProductsByCategory(preferredCategory);
      }

      if (picked.length < 5 && historyProductIds.isNotEmpty) {
        for (final id in historyProductIds.take(3)) {
          try {
            final doc = await _firestore.collection('products').doc(id).get();
            if (!doc.exists) continue;

            final category = doc.data()?['category'];
            if (category != null) {
              await addProductsByCategory(category);
            }
          } catch (e) {
            continue;
          }
          if (picked.length >= 5) break;
        }
      }

      if (picked.length < 5) {
        final featured = await _firestore
            .collection('products')
            .where('featured', isEqualTo: true)
            .where('stock', isGreaterThan: 0)
            .limit(10)
            .get();

        for (final p in featured.docs) {
          if (used.contains(p.id)) continue;
          picked.add(p);
          used.add(p.id);
          if (picked.length >= 5) break;
        }
      }

      if (picked.length < 5) {
        final trending = await _firestore
            .collection('products')
            .where('stock', isGreaterThan: 0)
            .orderBy('sold', descending: true)
            .limit(10)
            .get();

        for (final p in trending.docs) {
          if (used.contains(p.id)) continue;
          picked.add(p);
          used.add(p.id);
          if (picked.length >= 5) break;
        }
      }

      if (picked.isEmpty) {
        return 'Hiện tại chưa có sản phẩm phù hợp. Bạn có thể xem các danh mục trong ứng dụng nhé!';
      }

      final productsInfo = picked.take(5).map((doc) {
        final data = doc.data();
        return '${data['name']} - ${_formatCurrency((data['price'] ?? 0).toDouble())}';
      }).join(', ');

      final prompt = '''
Bạn là nhân viên tư vấn tạp hóa thân thiện.

Khách hỏi: "$message"
Sản phẩm có: $productsInfo

Viết 1 câu giới thiệu ngắn (15-20 từ) về các sản phẩm tươi ngon này.
Không liệt kê, không emoji, tự nhiên như nói chuyện.
''';

      String intro;
      try {
        final res = await _model.generateContent([Content.text(prompt)]);
        intro = res.text?.trim() ?? 'Sản phẩm tươi sống dành cho bạn:';
      } catch (e) {
        intro = 'Sản phẩm tươi sống dành cho bạn:';
      }

      final buffer = StringBuffer(intro);
      buffer.writeln('\n');

      for (final doc in picked.take(5)) {
        final data = doc.data();
        final name = data['name'] ?? 'Sản phẩm';
        final price = _formatCurrency((data['price'] ?? 0).toDouble());
        final stock = data['stock'] ?? 0;
        final sold = data['sold'] ?? 0;

        buffer.writeln('- $name');
        buffer.writeln('  Giá: $price | Đã bán: $sold | Còn: $stock');
      }
      return buffer.toString();
    } catch (e) {
      print('Error in product recommendation: $e');
      return 'Xin lỗi, tôi gặp sự cố khi tìm sản phẩm. Bạn có thể xem danh mục sản phẩm trong ứng dụng nhé!';
    }
  }

  String? _detectCategory(String message) {
    final m = message.toLowerCase();

    if (m.contains('rau') || m.contains('củ')) return 'Rau củ';
    if (m.contains('trái cây') || m.contains('hoa quả')) return 'Trái cây';
    if (m.contains('thịt') || m.contains('heo') || m.contains('bò') || m.contains('gà')) return 'Thịt';
    if (m.contains('cá') || m.contains('hải sản') || m.contains('tôm')) return 'Hải sản';
    if (m.contains('sữa') || m.contains('trứng') || m.contains('dairy')) return 'Sữa & trứng';
    if (m.contains('gia vị') || m.contains('đồ khô')) return 'Gia vị';
    if (m.contains('nước') || m.contains('giải khát')) return 'Đồ uống';
    if (m.contains('bánh') || m.contains('snack')) return 'Bánh kẹo';

    return null;
  }

  Future<String> _handleRecipeHelp(String message, String userId) async {
    try {
      final recentProducts = await _getRecentProductNames(userId, limit: 10);

      final context = recentProducts.isNotEmpty
          ? 'Nguyên liệu user có: ${recentProducts.join(", ")}'
          : 'User chưa có nguyên liệu nào';

      final prompt = '''
Bạn là đầu bếp tư vấn cho ứng dụng tạp hóa.

$context

Câu hỏi: "$message"

Hướng dẫn:
- Trả lời ngắn gọn 3-4 câu
- Đưa ra gợi ý món ăn hoặc cách chế biến
- Gợi ý nguyên liệu cần mua thêm nếu thiếu
- Không dùng emoji, tự nhiên
- Tiếng Việt

Ví dụ:
Q: Tôi có cà chua và trứng, nấu gì?
A: Bạn có thể làm món trứng xào cà chua đơn giản. Đập trứng, xào cà chua cho mềm rồi cho trứng vào. Nếu có thêm hành lá và nước mắm sẽ ngon hơn. Shop có bán hành lá tươi và nước mắm chất lượng bạn nhé!
''';

      final res = await _model.generateContent([Content.text(prompt)]);
      return res.text?.trim() ?? 'Tôi chưa có gợi ý phù hợp. Bạn có thể mô tả rõ hơn về nguyên liệu hoặc món ăn muốn làm không?';
    } catch (e) {
      print('Error in recipe help: $e');
      return 'Tôi gặp sự cố khi tìm công thức. Bạn thử hỏi cụ thể hơn nhé!';
    }
  }

  Future<List<String>> _getRecentProductNames(String userId, {int limit = 10}) async {
    try {
      final orders = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      final names = <String>[];
      for (final doc in orders.docs) {
        final items = (doc.data()['items'] as List<dynamic>? ?? []);
        for (final item in items) {
          final name = item['name'] as String?;
          if (name != null && name.isNotEmpty) {
            names.add(name);
          }
        }
        if (names.length >= limit) break;
      }
      return names.toSet().toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> _getPurchasedProductIds(String userId) async {
    try {
      final orders = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final ids = <String>[];
      for (final doc in orders.docs) {
        final items = (doc.data()['items'] as List<dynamic>? ?? []);
        for (final item in items) {
          final pid = item['productId'] as String?;
          if (pid != null && pid.isNotEmpty) {
            ids.add(pid);
          }
        }
      }
      return ids.toSet().toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> _getFavoriteProductIds(String userId) async {
    try {
      final favs = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();

      return favs.docs
          .map((d) => d.data()['productId'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<String> _handleGeneral(String message, String userId) async {
    try {
      final history = _conversationHistory[userId] ?? [];
      final userContext = await _getUserContext(userId);

      final systemPrompt = '''
Bạn là trợ lý ảo của ứng dụng tạp hóa online.

Thông tin: $userContext

Hướng dẫn trả lời:
- Ngắn gọn 2-3 câu, thân thiện
- Ưu tiên giải pháp cụ thể
- Không emoji, không markdown
- Tiếng Việt tự nhiên

Thông tin cửa hàng:
- Giao hàng: 30-60 phút trong nội thành
- COD: Có hỗ trợ thanh toán khi nhận hàng
- Đổi trả: 24h nếu sản phẩm không đảm bảo chất lượng
- Giờ đặt hàng: 6h-22h hàng ngày

Ví dụ:
Q: Shop giao hàng mất bao lâu?
A: Shop giao hàng trong 30-60 phút tùy khu vực. Nội thành sẽ nhanh hơn. Bạn có thể chọn khung giờ giao hàng khi đặt đơn nhé!

Q: Rau củ có tươi không?
A: Shop nhập rau củ tươi mỗi sáng từ chợ đầu mối. Bạn yên tâm về chất lượng. Nếu không hài lòng, shop hỗ trợ đổi trả trong 24h.
''';

      final contents = [
        Content.text(systemPrompt),
        ...history,
        Content.text(message),
      ];

      final res = await _model.generateContent(contents);
      final reply = res.text?.trim() ?? 'Tôi chưa hiểu câu hỏi, bạn mô tả rõ hơn nhé.';

      history.add(Content.text(message));
      history.add(Content.model([TextPart(reply)]));
      if (history.length > 20) {
        history.removeRange(0, history.length - 20);
      }
      _conversationHistory[userId] = history;

      return reply;
    } catch (e) {
      print('Error in general handler: $e');
      return 'Tôi chưa hiểu câu hỏi. Bạn có thể hỏi về đơn hàng, sản phẩm hoặc chính sách của shop.';
    }
  }

  Future<String> _getUserContext(String userId) async {
    try {
      final orders = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .limit(5)
          .get();

      final orderCount = orders.docs.length;

      if (orderCount == 0) {
        return 'Khách hàng mới';
      } else if (orderCount < 3) {
        return 'Khách quen ($orderCount đơn)';
      } else {
        return 'Khách VIP ($orderCount đơn)';
      }
    } catch (e) {
      return 'Khách hàng';
    }
  }

  void clearHistory(String userId) {
    _conversationHistory.remove(userId);
  }

  String? _extractOrderId(String message) {
    final m = RegExp(r'#([A-Za-z0-9\-]{6,})', caseSensitive: false)
        .firstMatch(message);
    return m?.group(1);
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'preparing':
        return 'Đang chuẩn bị';
      case 'shipping':
        return 'Đang giao';
      case 'delivered':
        return 'Đã giao';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status.isEmpty ? 'Không rõ' : status;
    }
  }

  String _paymentMethodText(String method) {
    switch (method.toLowerCase()) {
      case 'cod':
        return 'Thanh toán khi nhận hàng (COD)';
      case 'card':
        return 'Thẻ tín dụng/ghi nợ';
      case 'momo':
        return 'Ví MoMo';
      case 'zalopay':
        return 'ZaloPay';
      case 'banking':
        return 'Chuyển khoản ngân hàng';
      default:
        return method.isEmpty ? 'Chưa xác định' : method;
    }
  }

  String _formatCurrency(double value) {
    final s = value.toStringAsFixed(0);
    return '${s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    )}đ';
  }

  String _formatDate(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '';
  }
}

enum ChatIntent {
  orderTracking,
  productRecommendation,
  recipeHelp,
  general
}