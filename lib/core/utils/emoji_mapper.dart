class EmojiMapper {
  // Maps a category name and type ('income' or 'expense') to an emoji.
  static String getEmoji(String? category, String type) {
    if (category == null || category.isEmpty) {
      return type == 'income' ? '💰' : '💸';
    }

    final c = category.toLowerCase().trim();

    // --- INCOME ---
    if (c.contains('salary') || c.contains('wages')) return '💰';
    if (c.contains('sales') || c.contains('business income')) return '📈';
    if (c.contains('freelance') || c.contains('project')) return '💻';
    if (c.contains('rental income')) return '🏘️';
    if (c.contains('loan repayment') || c.contains('loan received')) return '🔄';
    if (c.contains('cashback') || c.contains('reward')) return '🎁';
    if (c.contains('sold')) return '📦';
    if (c.contains('interest') || c.contains('dividend')) return '🏦';
    if (c.contains('pocket money')) return '🪙';
    if (c.contains('bonus')) return '🎉';
    if (c.contains('investment') || c.contains('return')) return '📊';
    if (c.contains('gift')) return '🎁';
    if (c.contains('refund')) return '🔄';

    // --- EXPENSE ---
    if (c.contains('food') || c.contains('dining')) return '🍔';
    if (c.contains('restaurant') || c.contains('cafe')) return '🍕';
    if (c.contains('coffee')) return '☕';
    if (c.contains('groceries') || c.contains('grocery')) return '🛒';
    if (c.contains('shopping') || c.contains('clothes') || c.contains('clothing')) return '🛍️';
    if (c.contains('beauty') || c.contains('salon') || c.contains('cosmetic')) return '💄';
    if (c.contains('fuel') || c.contains('petrol')) return '⛽';
    if (c.contains('medical') || c.contains('health') || c.contains('hospital')) return '🏥';
    if (c.contains('medicine') || c.contains('pharmacy')) return '💊';
    if (c.contains('electricity') || c.contains('electric')) return '⚡';
    if (c.contains('water')) return '💧';
    if (c.contains('gas')) return '🔥';
    if (c.contains('internet') || c.contains('broadband') || c.contains('wifi')) return '🌐';
    if (c.contains('mobile') || c.contains('recharge') || c.contains('phone')) return '📱';
    if (c.contains('utilities') || c.contains('bill')) return '⚡';
    if (c.contains('rent') || c.contains('emi') || c.contains('mortgage')) return '🏠';
    if (c.contains('travel') || c.contains('flight') || c.contains('airline')) return '✈️';
    if (c.contains('taxi') || c.contains('cab') || c.contains('uber')) return '🚕';
    if (c.contains('bus')) return '🚌';
    if (c.contains('train') || c.contains('rail') || c.contains('metro')) return '🚆';
    if (c.contains('transport') || c.contains('commute')) return '🚗';
    if (c.contains('entertainment') || c.contains('movie') || c.contains('cinema')) return '🎬';
    if (c.contains('streaming') || c.contains('subscription')) return '🍿';
    if (c.contains('education') || c.contains('school') || c.contains('tuition')) return '📚';
    if (c.contains('gym') || c.contains('fitness') || c.contains('sport')) return '💪';
    if (c.contains('pet') || c.contains('dog') || c.contains('cat')) return '🐶';
    if (c.contains('repair') || c.contains('maintenance')) return '🔧';
    if (c.contains('office') || c.contains('stationery')) return '💼';
    if (c.contains('charity') || c.contains('donation')) return '❤️';
    if (c.contains('festival') || c.contains('celebration') || c.contains('party')) return '🎊';
    if (c.contains('supplier') || c.contains('vendor')) return '🤝';
    if (c.contains('loan given')) return '💸';
    if (c.contains('business')) return '💼';
    if (c.contains('miscellaneous') || c.contains('other')) {
      return type == 'income' ? '💰' : '💸';
    }

    // Fallback
    return type == 'income' ? '💰' : '💸';
  }

  static bool isIncome(String type) => type == 'income';
}
