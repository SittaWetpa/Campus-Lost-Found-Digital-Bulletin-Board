enum ItemTaxonomy {
  electronics(id: 'electronics', displayNameEn: 'Electronics'),
  bagWallet(id: 'bag_wallet', displayNameEn: 'Bag & Wallet'),
  clothing(id: 'clothing', displayNameEn: 'Clothing'),
  stationery(id: 'stationery', displayNameEn: 'Stationery'),
  documentsCards(id: 'documents_cards', displayNameEn: 'Documents'),
  keys(id: 'keys', displayNameEn: 'Keys'),
  accessory(id: 'accessory', displayNameEn: 'Accessory'),
  other(id: 'other', displayNameEn: 'Other');

  const ItemTaxonomy({required this.id, required this.displayNameEn});

  final String id;
  final String displayNameEn;

  static ItemTaxonomy fromId(String id) => ItemTaxonomy.values.firstWhere(
        (e) => e.id == id,
        orElse: () => ItemTaxonomy.other,
      );
}

// Per-category quick-pick chips and adaptive placeholders for the post form.
const Map<ItemTaxonomy, _CategoryMeta> _kTaxonomyMeta = {
  ItemTaxonomy.electronics: _CategoryMeta(
    titlePlaceholder: 'e.g. iPhone 16, Galaxy Tab S9, AirPods…',
    descPlaceholder: 'Describe the device — model, color, condition, stickers or marks…',
    chips: ['iPhone', 'AirPods', 'Laptop', 'Charger', 'Earphones', 'Power bank', 'Tablet', 'Smartwatch'],
  ),
  ItemTaxonomy.bagWallet: _CategoryMeta(
    titlePlaceholder: 'e.g. Black leather wallet, navy backpack…',
    descPlaceholder: 'Describe the bag — brand, color, size, notable details or contents…',
    chips: ['Wallet', 'Backpack', 'Tote bag', 'Shoulder bag', 'Purse', 'Pouch'],
  ),
  ItemTaxonomy.clothing: _CategoryMeta(
    titlePlaceholder: 'e.g. Navy blue KMUTT hoodie…',
    descPlaceholder: 'Describe the item — color, size, brand, logos or patches…',
    chips: ['Jacket', 'Hoodie', 'Hat', 'Scarf', 'Shirt', 'Cardigan'],
  ),
  ItemTaxonomy.stationery: _CategoryMeta(
    titlePlaceholder: 'e.g. Casio fx-9860G calculator…',
    descPlaceholder: 'Describe the item — brand, model, color, writing or stickers…',
    chips: ['Calculator', 'Textbook', 'Notebook', 'Pen case', 'USB drive', 'Ruler'],
  ),
  ItemTaxonomy.documentsCards: _CategoryMeta(
    titlePlaceholder: 'e.g. Library card, faculty ID card…',
    descPlaceholder: 'Describe what you can see without revealing personal details…',
    chips: ['Library card', 'Bus pass', 'Club card', 'Loyalty card'],
  ),
  ItemTaxonomy.keys: _CategoryMeta(
    titlePlaceholder: 'e.g. Key ring with 3 keys and a tag…',
    descPlaceholder: 'Describe the keys — number, fobs, keychains, or labels attached…',
    chips: ['Key ring', 'Single key', 'Key + fob', 'Locker key'],
  ),
  ItemTaxonomy.accessory: _CategoryMeta(
    titlePlaceholder: 'e.g. Black framed glasses, silver watch…',
    descPlaceholder: 'Describe the item — brand, color, material, distinguishing marks…',
    chips: ['Glasses', 'Sunglasses', 'Watch', 'Earring', 'Bracelet', 'Lanyard'],
  ),
  ItemTaxonomy.other: _CategoryMeta(
    titlePlaceholder: 'e.g. Pink Hydro Flask water bottle…',
    descPlaceholder: 'Describe the item — color, size, brand, unique features…',
    chips: ['Water bottle', 'Umbrella', 'Lunch box', 'Bag tag'],
  ),
};

class _CategoryMeta {
  const _CategoryMeta({
    required this.titlePlaceholder,
    required this.descPlaceholder,
    required this.chips,
  });

  final String titlePlaceholder;
  final String descPlaceholder;
  final List<String> chips;
}

extension TaxonomyMeta on ItemTaxonomy {
  String get titlePlaceholder => _kTaxonomyMeta[this]!.titlePlaceholder;
  String get descPlaceholder => _kTaxonomyMeta[this]!.descPlaceholder;
  List<String> get chips => _kTaxonomyMeta[this]!.chips;
}
