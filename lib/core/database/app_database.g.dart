// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stockQuantityMeta = const VerificationMeta(
    'stockQuantity',
  );
  @override
  late final GeneratedColumn<int> stockQuantity = GeneratedColumn<int>(
    'stock_quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<String> size = GeneratedColumn<String>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    brand,
    price,
    category,
    stockQuantity,
    imageUrl,
    tenantId,
    branchId,
    size,
    description,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    } else if (isInserting) {
      context.missing(_brandMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('stock_quantity')) {
      context.handle(
        _stockQuantityMeta,
        stockQuantity.isAcceptableOrUnknown(
          data['stock_quantity']!,
          _stockQuantityMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      stockQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock_quantity'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      ),
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      ),
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}size'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final String id;
  final String name;
  final String brand;
  final double price;
  final String category;
  final int stockQuantity;
  final String? imageUrl;
  final String? tenantId;
  final String? branchId;
  final String size;
  final String description;
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.category,
    required this.stockQuantity,
    this.imageUrl,
    this.tenantId,
    this.branchId,
    required this.size,
    required this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['brand'] = Variable<String>(brand);
    map['price'] = Variable<double>(price);
    map['category'] = Variable<String>(category);
    map['stock_quantity'] = Variable<int>(stockQuantity);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || tenantId != null) {
      map['tenant_id'] = Variable<String>(tenantId);
    }
    if (!nullToAbsent || branchId != null) {
      map['branch_id'] = Variable<String>(branchId);
    }
    map['size'] = Variable<String>(size);
    map['description'] = Variable<String>(description);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      name: Value(name),
      brand: Value(brand),
      price: Value(price),
      category: Value(category),
      stockQuantity: Value(stockQuantity),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      tenantId: tenantId == null && nullToAbsent
          ? const Value.absent()
          : Value(tenantId),
      branchId: branchId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchId),
      size: Value(size),
      description: Value(description),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      brand: serializer.fromJson<String>(json['brand']),
      price: serializer.fromJson<double>(json['price']),
      category: serializer.fromJson<String>(json['category']),
      stockQuantity: serializer.fromJson<int>(json['stockQuantity']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      tenantId: serializer.fromJson<String?>(json['tenantId']),
      branchId: serializer.fromJson<String?>(json['branchId']),
      size: serializer.fromJson<String>(json['size']),
      description: serializer.fromJson<String>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'brand': serializer.toJson<String>(brand),
      'price': serializer.toJson<double>(price),
      'category': serializer.toJson<String>(category),
      'stockQuantity': serializer.toJson<int>(stockQuantity),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'tenantId': serializer.toJson<String?>(tenantId),
      'branchId': serializer.toJson<String?>(branchId),
      'size': serializer.toJson<String>(size),
      'description': serializer.toJson<String>(description),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    double? price,
    String? category,
    int? stockQuantity,
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> tenantId = const Value.absent(),
    Value<String?> branchId = const Value.absent(),
    String? size,
    String? description,
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    brand: brand ?? this.brand,
    price: price ?? this.price,
    category: category ?? this.category,
    stockQuantity: stockQuantity ?? this.stockQuantity,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    tenantId: tenantId.present ? tenantId.value : this.tenantId,
    branchId: branchId.present ? branchId.value : this.branchId,
    size: size ?? this.size,
    description: description ?? this.description,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      brand: data.brand.present ? data.brand.value : this.brand,
      price: data.price.present ? data.price.value : this.price,
      category: data.category.present ? data.category.value : this.category,
      stockQuantity: data.stockQuantity.present
          ? data.stockQuantity.value
          : this.stockQuantity,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      size: data.size.present ? data.size.value : this.size,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('price: $price, ')
          ..write('category: $category, ')
          ..write('stockQuantity: $stockQuantity, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('size: $size, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    brand,
    price,
    category,
    stockQuantity,
    imageUrl,
    tenantId,
    branchId,
    size,
    description,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.name == this.name &&
          other.brand == this.brand &&
          other.price == this.price &&
          other.category == this.category &&
          other.stockQuantity == this.stockQuantity &&
          other.imageUrl == this.imageUrl &&
          other.tenantId == this.tenantId &&
          other.branchId == this.branchId &&
          other.size == this.size &&
          other.description == this.description);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> brand;
  final Value<double> price;
  final Value<String> category;
  final Value<int> stockQuantity;
  final Value<String?> imageUrl;
  final Value<String?> tenantId;
  final Value<String?> branchId;
  final Value<String> size;
  final Value<String> description;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.price = const Value.absent(),
    this.category = const Value.absent(),
    this.stockQuantity = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.size = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String name,
    required String brand,
    required double price,
    required String category,
    this.stockQuantity = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.size = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       brand = Value(brand),
       price = Value(price),
       category = Value(category);
  static Insertable<Product> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? brand,
    Expression<double>? price,
    Expression<String>? category,
    Expression<int>? stockQuantity,
    Expression<String>? imageUrl,
    Expression<String>? tenantId,
    Expression<String>? branchId,
    Expression<String>? size,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (price != null) 'price': price,
      if (category != null) 'category': category,
      if (stockQuantity != null) 'stock_quantity': stockQuantity,
      if (imageUrl != null) 'image_url': imageUrl,
      if (tenantId != null) 'tenant_id': tenantId,
      if (branchId != null) 'branch_id': branchId,
      if (size != null) 'size': size,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? brand,
    Value<double>? price,
    Value<String>? category,
    Value<int>? stockQuantity,
    Value<String?>? imageUrl,
    Value<String?>? tenantId,
    Value<String?>? branchId,
    Value<String>? size,
    Value<String>? description,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      category: category ?? this.category,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      imageUrl: imageUrl ?? this.imageUrl,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      size: size ?? this.size,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (stockQuantity.present) {
      map['stock_quantity'] = Variable<int>(stockQuantity.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (size.present) {
      map['size'] = Variable<String>(size.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('price: $price, ')
          ..write('category: $category, ')
          ..write('stockQuantity: $stockQuantity, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('size: $size, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrdersTable extends Orders with TableInfo<$OrdersTable, Order> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerPhoneMeta = const VerificationMeta(
    'customerPhone',
  );
  @override
  late final GeneratedColumn<String> customerPhone = GeneratedColumn<String>(
    'customer_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _terminalIdMeta = const VerificationMeta(
    'terminalId',
  );
  @override
  late final GeneratedColumn<String> terminalId = GeneratedColumn<String>(
    'terminal_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    totalAmount,
    status,
    createdAt,
    customerPhone,
    tenantId,
    branchId,
    terminalId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Order> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('customer_phone')) {
      context.handle(
        _customerPhoneMeta,
        customerPhone.isAcceptableOrUnknown(
          data['customer_phone']!,
          _customerPhoneMeta,
        ),
      );
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    }
    if (data.containsKey('terminal_id')) {
      context.handle(
        _terminalIdMeta,
        terminalId.isAcceptableOrUnknown(data['terminal_id']!, _terminalIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Order map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Order(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      customerPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_phone'],
      ),
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      ),
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      ),
      terminalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}terminal_id'],
      ),
    );
  }

  @override
  $OrdersTable createAlias(String alias) {
    return $OrdersTable(attachedDatabase, alias);
  }
}

class Order extends DataClass implements Insertable<Order> {
  final String id;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final String? customerPhone;
  final String? tenantId;
  final String? branchId;
  final String? terminalId;
  const Order({
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.customerPhone,
    this.tenantId,
    this.branchId,
    this.terminalId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['total_amount'] = Variable<double>(totalAmount);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || customerPhone != null) {
      map['customer_phone'] = Variable<String>(customerPhone);
    }
    if (!nullToAbsent || tenantId != null) {
      map['tenant_id'] = Variable<String>(tenantId);
    }
    if (!nullToAbsent || branchId != null) {
      map['branch_id'] = Variable<String>(branchId);
    }
    if (!nullToAbsent || terminalId != null) {
      map['terminal_id'] = Variable<String>(terminalId);
    }
    return map;
  }

  OrdersCompanion toCompanion(bool nullToAbsent) {
    return OrdersCompanion(
      id: Value(id),
      totalAmount: Value(totalAmount),
      status: Value(status),
      createdAt: Value(createdAt),
      customerPhone: customerPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(customerPhone),
      tenantId: tenantId == null && nullToAbsent
          ? const Value.absent()
          : Value(tenantId),
      branchId: branchId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchId),
      terminalId: terminalId == null && nullToAbsent
          ? const Value.absent()
          : Value(terminalId),
    );
  }

  factory Order.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Order(
      id: serializer.fromJson<String>(json['id']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      customerPhone: serializer.fromJson<String?>(json['customerPhone']),
      tenantId: serializer.fromJson<String?>(json['tenantId']),
      branchId: serializer.fromJson<String?>(json['branchId']),
      terminalId: serializer.fromJson<String?>(json['terminalId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'customerPhone': serializer.toJson<String?>(customerPhone),
      'tenantId': serializer.toJson<String?>(tenantId),
      'branchId': serializer.toJson<String?>(branchId),
      'terminalId': serializer.toJson<String?>(terminalId),
    };
  }

  Order copyWith({
    String? id,
    double? totalAmount,
    String? status,
    DateTime? createdAt,
    Value<String?> customerPhone = const Value.absent(),
    Value<String?> tenantId = const Value.absent(),
    Value<String?> branchId = const Value.absent(),
    Value<String?> terminalId = const Value.absent(),
  }) => Order(
    id: id ?? this.id,
    totalAmount: totalAmount ?? this.totalAmount,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    customerPhone: customerPhone.present
        ? customerPhone.value
        : this.customerPhone,
    tenantId: tenantId.present ? tenantId.value : this.tenantId,
    branchId: branchId.present ? branchId.value : this.branchId,
    terminalId: terminalId.present ? terminalId.value : this.terminalId,
  );
  Order copyWithCompanion(OrdersCompanion data) {
    return Order(
      id: data.id.present ? data.id.value : this.id,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      customerPhone: data.customerPhone.present
          ? data.customerPhone.value
          : this.customerPhone,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      terminalId: data.terminalId.present
          ? data.terminalId.value
          : this.terminalId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Order(')
          ..write('id: $id, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('terminalId: $terminalId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    totalAmount,
    status,
    createdAt,
    customerPhone,
    tenantId,
    branchId,
    terminalId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Order &&
          other.id == this.id &&
          other.totalAmount == this.totalAmount &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.customerPhone == this.customerPhone &&
          other.tenantId == this.tenantId &&
          other.branchId == this.branchId &&
          other.terminalId == this.terminalId);
}

class OrdersCompanion extends UpdateCompanion<Order> {
  final Value<String> id;
  final Value<double> totalAmount;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<String?> customerPhone;
  final Value<String?> tenantId;
  final Value<String?> branchId;
  final Value<String?> terminalId;
  final Value<int> rowid;
  const OrdersCompanion({
    this.id = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.customerPhone = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.terminalId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrdersCompanion.insert({
    required String id,
    required double totalAmount,
    required String status,
    required DateTime createdAt,
    this.customerPhone = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.terminalId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       totalAmount = Value(totalAmount),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<Order> custom({
    Expression<String>? id,
    Expression<double>? totalAmount,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<String>? customerPhone,
    Expression<String>? tenantId,
    Expression<String>? branchId,
    Expression<String>? terminalId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (customerPhone != null) 'customer_phone': customerPhone,
      if (tenantId != null) 'tenant_id': tenantId,
      if (branchId != null) 'branch_id': branchId,
      if (terminalId != null) 'terminal_id': terminalId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrdersCompanion copyWith({
    Value<String>? id,
    Value<double>? totalAmount,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<String?>? customerPhone,
    Value<String?>? tenantId,
    Value<String?>? branchId,
    Value<String?>? terminalId,
    Value<int>? rowid,
  }) {
    return OrdersCompanion(
      id: id ?? this.id,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      customerPhone: customerPhone ?? this.customerPhone,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      terminalId: terminalId ?? this.terminalId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (customerPhone.present) {
      map['customer_phone'] = Variable<String>(customerPhone.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (terminalId.present) {
      map['terminal_id'] = Variable<String>(terminalId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdersCompanion(')
          ..write('id: $id, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('terminalId: $terminalId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrderItemsTable extends OrderItems
    with TableInfo<$OrderItemsTable, OrderItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrderItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES orders (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productVariantMeta = const VerificationMeta(
    'productVariant',
  );
  @override
  late final GeneratedColumn<String> productVariant = GeneratedColumn<String>(
    'product_variant',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PAID'),
  );
  static const VerificationMeta _productCategoryMeta = const VerificationMeta(
    'productCategory',
  );
  @override
  late final GeneratedColumn<String> productCategory = GeneratedColumn<String>(
    'product_category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    orderId,
    productId,
    quantity,
    unitPrice,
    productName,
    productVariant,
    status,
    productCategory,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'order_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrderItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('product_variant')) {
      context.handle(
        _productVariantMeta,
        productVariant.isAcceptableOrUnknown(
          data['product_variant']!,
          _productVariantMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('product_category')) {
      context.handle(
        _productCategoryMeta,
        productCategory.isAcceptableOrUnknown(
          data['product_category']!,
          _productCategoryMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrderItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      productVariant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_variant'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      productCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_category'],
      )!,
    );
  }

  @override
  $OrderItemsTable createAlias(String alias) {
    return $OrderItemsTable(attachedDatabase, alias);
  }
}

class OrderItem extends DataClass implements Insertable<OrderItem> {
  final int id;
  final String orderId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final String productName;
  final String? productVariant;
  final String status;
  final String productCategory;
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.productName,
    this.productVariant,
    required this.status,
    required this.productCategory,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['order_id'] = Variable<String>(orderId);
    map['product_id'] = Variable<String>(productId);
    map['quantity'] = Variable<int>(quantity);
    map['unit_price'] = Variable<double>(unitPrice);
    map['product_name'] = Variable<String>(productName);
    if (!nullToAbsent || productVariant != null) {
      map['product_variant'] = Variable<String>(productVariant);
    }
    map['status'] = Variable<String>(status);
    map['product_category'] = Variable<String>(productCategory);
    return map;
  }

  OrderItemsCompanion toCompanion(bool nullToAbsent) {
    return OrderItemsCompanion(
      id: Value(id),
      orderId: Value(orderId),
      productId: Value(productId),
      quantity: Value(quantity),
      unitPrice: Value(unitPrice),
      productName: Value(productName),
      productVariant: productVariant == null && nullToAbsent
          ? const Value.absent()
          : Value(productVariant),
      status: Value(status),
      productCategory: Value(productCategory),
    );
  }

  factory OrderItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderItem(
      id: serializer.fromJson<int>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      productId: serializer.fromJson<String>(json['productId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      productName: serializer.fromJson<String>(json['productName']),
      productVariant: serializer.fromJson<String?>(json['productVariant']),
      status: serializer.fromJson<String>(json['status']),
      productCategory: serializer.fromJson<String>(json['productCategory']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'orderId': serializer.toJson<String>(orderId),
      'productId': serializer.toJson<String>(productId),
      'quantity': serializer.toJson<int>(quantity),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'productName': serializer.toJson<String>(productName),
      'productVariant': serializer.toJson<String?>(productVariant),
      'status': serializer.toJson<String>(status),
      'productCategory': serializer.toJson<String>(productCategory),
    };
  }

  OrderItem copyWith({
    int? id,
    String? orderId,
    String? productId,
    int? quantity,
    double? unitPrice,
    String? productName,
    Value<String?> productVariant = const Value.absent(),
    String? status,
    String? productCategory,
  }) => OrderItem(
    id: id ?? this.id,
    orderId: orderId ?? this.orderId,
    productId: productId ?? this.productId,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
    productName: productName ?? this.productName,
    productVariant: productVariant.present
        ? productVariant.value
        : this.productVariant,
    status: status ?? this.status,
    productCategory: productCategory ?? this.productCategory,
  );
  OrderItem copyWithCompanion(OrderItemsCompanion data) {
    return OrderItem(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      productId: data.productId.present ? data.productId.value : this.productId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      productVariant: data.productVariant.present
          ? data.productVariant.value
          : this.productVariant,
      status: data.status.present ? data.status.value : this.status,
      productCategory: data.productCategory.present
          ? data.productCategory.value
          : this.productCategory,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderItem(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('productName: $productName, ')
          ..write('productVariant: $productVariant, ')
          ..write('status: $status, ')
          ..write('productCategory: $productCategory')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    orderId,
    productId,
    quantity,
    unitPrice,
    productName,
    productVariant,
    status,
    productCategory,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderItem &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.productId == this.productId &&
          other.quantity == this.quantity &&
          other.unitPrice == this.unitPrice &&
          other.productName == this.productName &&
          other.productVariant == this.productVariant &&
          other.status == this.status &&
          other.productCategory == this.productCategory);
}

class OrderItemsCompanion extends UpdateCompanion<OrderItem> {
  final Value<int> id;
  final Value<String> orderId;
  final Value<String> productId;
  final Value<int> quantity;
  final Value<double> unitPrice;
  final Value<String> productName;
  final Value<String?> productVariant;
  final Value<String> status;
  final Value<String> productCategory;
  const OrderItemsCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.productName = const Value.absent(),
    this.productVariant = const Value.absent(),
    this.status = const Value.absent(),
    this.productCategory = const Value.absent(),
  });
  OrderItemsCompanion.insert({
    this.id = const Value.absent(),
    required String orderId,
    required String productId,
    required int quantity,
    required double unitPrice,
    required String productName,
    this.productVariant = const Value.absent(),
    this.status = const Value.absent(),
    this.productCategory = const Value.absent(),
  }) : orderId = Value(orderId),
       productId = Value(productId),
       quantity = Value(quantity),
       unitPrice = Value(unitPrice),
       productName = Value(productName);
  static Insertable<OrderItem> custom({
    Expression<int>? id,
    Expression<String>? orderId,
    Expression<String>? productId,
    Expression<int>? quantity,
    Expression<double>? unitPrice,
    Expression<String>? productName,
    Expression<String>? productVariant,
    Expression<String>? status,
    Expression<String>? productCategory,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (productId != null) 'product_id': productId,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (productName != null) 'product_name': productName,
      if (productVariant != null) 'product_variant': productVariant,
      if (status != null) 'status': status,
      if (productCategory != null) 'product_category': productCategory,
    });
  }

  OrderItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? orderId,
    Value<String>? productId,
    Value<int>? quantity,
    Value<double>? unitPrice,
    Value<String>? productName,
    Value<String?>? productVariant,
    Value<String>? status,
    Value<String>? productCategory,
  }) {
    return OrderItemsCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      productName: productName ?? this.productName,
      productVariant: productVariant ?? this.productVariant,
      status: status ?? this.status,
      productCategory: productCategory ?? this.productCategory,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (productVariant.present) {
      map['product_variant'] = Variable<String>(productVariant.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (productCategory.present) {
      map['product_category'] = Variable<String>(productCategory.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrderItemsCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('productName: $productName, ')
          ..write('productVariant: $productVariant, ')
          ..write('status: $status, ')
          ..write('productCategory: $productCategory')
          ..write(')'))
        .toString();
  }
}

class $AppConfigTable extends AppConfig
    with TableInfo<$AppConfigTable, AppConfigData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppConfigTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_config';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppConfigData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppConfigData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppConfigData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppConfigTable createAlias(String alias) {
    return $AppConfigTable(attachedDatabase, alias);
  }
}

class AppConfigData extends DataClass implements Insertable<AppConfigData> {
  final String key;
  final String value;
  const AppConfigData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppConfigCompanion toCompanion(bool nullToAbsent) {
    return AppConfigCompanion(key: Value(key), value: Value(value));
  }

  factory AppConfigData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppConfigData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppConfigData copyWith({String? key, String? value}) =>
      AppConfigData(key: key ?? this.key, value: value ?? this.value);
  AppConfigData copyWithCompanion(AppConfigCompanion data) {
    return AppConfigData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppConfigData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppConfigData &&
          other.key == this.key &&
          other.value == this.value);
}

class AppConfigCompanion extends UpdateCompanion<AppConfigData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppConfigCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppConfigCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppConfigData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppConfigCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppConfigCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppConfigCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WarehousesTable extends Warehouses
    with TableInfo<$WarehousesTable, Warehouse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WarehousesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoriesMeta = const VerificationMeta(
    'categories',
  );
  @override
  late final GeneratedColumn<String> categories = GeneratedColumn<String>(
    'categories',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loginUsernameMeta = const VerificationMeta(
    'loginUsername',
  );
  @override
  late final GeneratedColumn<String> loginUsername = GeneratedColumn<String>(
    'login_username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loginPasswordMeta = const VerificationMeta(
    'loginPassword',
  );
  @override
  late final GeneratedColumn<String> loginPassword = GeneratedColumn<String>(
    'login_password',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    branchId,
    name,
    categories,
    loginUsername,
    loginPassword,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'warehouses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Warehouse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('categories')) {
      context.handle(
        _categoriesMeta,
        categories.isAcceptableOrUnknown(data['categories']!, _categoriesMeta),
      );
    } else if (isInserting) {
      context.missing(_categoriesMeta);
    }
    if (data.containsKey('login_username')) {
      context.handle(
        _loginUsernameMeta,
        loginUsername.isAcceptableOrUnknown(
          data['login_username']!,
          _loginUsernameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_loginUsernameMeta);
    }
    if (data.containsKey('login_password')) {
      context.handle(
        _loginPasswordMeta,
        loginPassword.isAcceptableOrUnknown(
          data['login_password']!,
          _loginPasswordMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_loginPasswordMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Warehouse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Warehouse(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      ),
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      categories: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categories'],
      )!,
      loginUsername: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}login_username'],
      )!,
      loginPassword: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}login_password'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $WarehousesTable createAlias(String alias) {
    return $WarehousesTable(attachedDatabase, alias);
  }
}

class Warehouse extends DataClass implements Insertable<Warehouse> {
  final String id;
  final String? tenantId;
  final String branchId;
  final String name;
  final String categories;
  final String loginUsername;
  final String loginPassword;
  final bool isActive;
  const Warehouse({
    required this.id,
    this.tenantId,
    required this.branchId,
    required this.name,
    required this.categories,
    required this.loginUsername,
    required this.loginPassword,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || tenantId != null) {
      map['tenant_id'] = Variable<String>(tenantId);
    }
    map['branch_id'] = Variable<String>(branchId);
    map['name'] = Variable<String>(name);
    map['categories'] = Variable<String>(categories);
    map['login_username'] = Variable<String>(loginUsername);
    map['login_password'] = Variable<String>(loginPassword);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  WarehousesCompanion toCompanion(bool nullToAbsent) {
    return WarehousesCompanion(
      id: Value(id),
      tenantId: tenantId == null && nullToAbsent
          ? const Value.absent()
          : Value(tenantId),
      branchId: Value(branchId),
      name: Value(name),
      categories: Value(categories),
      loginUsername: Value(loginUsername),
      loginPassword: Value(loginPassword),
      isActive: Value(isActive),
    );
  }

  factory Warehouse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Warehouse(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String?>(json['tenantId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      name: serializer.fromJson<String>(json['name']),
      categories: serializer.fromJson<String>(json['categories']),
      loginUsername: serializer.fromJson<String>(json['loginUsername']),
      loginPassword: serializer.fromJson<String>(json['loginPassword']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String?>(tenantId),
      'branchId': serializer.toJson<String>(branchId),
      'name': serializer.toJson<String>(name),
      'categories': serializer.toJson<String>(categories),
      'loginUsername': serializer.toJson<String>(loginUsername),
      'loginPassword': serializer.toJson<String>(loginPassword),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Warehouse copyWith({
    String? id,
    Value<String?> tenantId = const Value.absent(),
    String? branchId,
    String? name,
    String? categories,
    String? loginUsername,
    String? loginPassword,
    bool? isActive,
  }) => Warehouse(
    id: id ?? this.id,
    tenantId: tenantId.present ? tenantId.value : this.tenantId,
    branchId: branchId ?? this.branchId,
    name: name ?? this.name,
    categories: categories ?? this.categories,
    loginUsername: loginUsername ?? this.loginUsername,
    loginPassword: loginPassword ?? this.loginPassword,
    isActive: isActive ?? this.isActive,
  );
  Warehouse copyWithCompanion(WarehousesCompanion data) {
    return Warehouse(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      name: data.name.present ? data.name.value : this.name,
      categories: data.categories.present
          ? data.categories.value
          : this.categories,
      loginUsername: data.loginUsername.present
          ? data.loginUsername.value
          : this.loginUsername,
      loginPassword: data.loginPassword.present
          ? data.loginPassword.value
          : this.loginPassword,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Warehouse(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('name: $name, ')
          ..write('categories: $categories, ')
          ..write('loginUsername: $loginUsername, ')
          ..write('loginPassword: $loginPassword, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    branchId,
    name,
    categories,
    loginUsername,
    loginPassword,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Warehouse &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.branchId == this.branchId &&
          other.name == this.name &&
          other.categories == this.categories &&
          other.loginUsername == this.loginUsername &&
          other.loginPassword == this.loginPassword &&
          other.isActive == this.isActive);
}

class WarehousesCompanion extends UpdateCompanion<Warehouse> {
  final Value<String> id;
  final Value<String?> tenantId;
  final Value<String> branchId;
  final Value<String> name;
  final Value<String> categories;
  final Value<String> loginUsername;
  final Value<String> loginPassword;
  final Value<bool> isActive;
  final Value<int> rowid;
  const WarehousesCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.name = const Value.absent(),
    this.categories = const Value.absent(),
    this.loginUsername = const Value.absent(),
    this.loginPassword = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WarehousesCompanion.insert({
    required String id,
    this.tenantId = const Value.absent(),
    required String branchId,
    required String name,
    required String categories,
    required String loginUsername,
    required String loginPassword,
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       branchId = Value(branchId),
       name = Value(name),
       categories = Value(categories),
       loginUsername = Value(loginUsername),
       loginPassword = Value(loginPassword);
  static Insertable<Warehouse> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? branchId,
    Expression<String>? name,
    Expression<String>? categories,
    Expression<String>? loginUsername,
    Expression<String>? loginPassword,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (branchId != null) 'branch_id': branchId,
      if (name != null) 'name': name,
      if (categories != null) 'categories': categories,
      if (loginUsername != null) 'login_username': loginUsername,
      if (loginPassword != null) 'login_password': loginPassword,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WarehousesCompanion copyWith({
    Value<String>? id,
    Value<String?>? tenantId,
    Value<String>? branchId,
    Value<String>? name,
    Value<String>? categories,
    Value<String>? loginUsername,
    Value<String>? loginPassword,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return WarehousesCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      categories: categories ?? this.categories,
      loginUsername: loginUsername ?? this.loginUsername,
      loginPassword: loginPassword ?? this.loginPassword,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (categories.present) {
      map['categories'] = Variable<String>(categories.value);
    }
    if (loginUsername.present) {
      map['login_username'] = Variable<String>(loginUsername.value);
    }
    if (loginPassword.present) {
      map['login_password'] = Variable<String>(loginPassword.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WarehousesCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('name: $name, ')
          ..write('categories: $categories, ')
          ..write('loginUsername: $loginUsername, ')
          ..write('loginPassword: $loginPassword, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BranchesTable extends Branches with TableInfo<$BranchesTable, Branche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BranchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contactPhoneMeta = const VerificationMeta(
    'contactPhone',
  );
  @override
  late final GeneratedColumn<String> contactPhone = GeneratedColumn<String>(
    'contact_phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _managerNameMeta = const VerificationMeta(
    'managerName',
  );
  @override
  late final GeneratedColumn<String> managerName = GeneratedColumn<String>(
    'manager_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loginUsernameMeta = const VerificationMeta(
    'loginUsername',
  );
  @override
  late final GeneratedColumn<String> loginUsername = GeneratedColumn<String>(
    'login_username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loginPasswordMeta = const VerificationMeta(
    'loginPassword',
  );
  @override
  late final GeneratedColumn<String> loginPassword = GeneratedColumn<String>(
    'login_password',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    name,
    location,
    contactPhone,
    managerName,
    loginUsername,
    loginPassword,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'branches';
  @override
  VerificationContext validateIntegrity(
    Insertable<Branche> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    if (data.containsKey('contact_phone')) {
      context.handle(
        _contactPhoneMeta,
        contactPhone.isAcceptableOrUnknown(
          data['contact_phone']!,
          _contactPhoneMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contactPhoneMeta);
    }
    if (data.containsKey('manager_name')) {
      context.handle(
        _managerNameMeta,
        managerName.isAcceptableOrUnknown(
          data['manager_name']!,
          _managerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_managerNameMeta);
    }
    if (data.containsKey('login_username')) {
      context.handle(
        _loginUsernameMeta,
        loginUsername.isAcceptableOrUnknown(
          data['login_username']!,
          _loginUsernameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_loginUsernameMeta);
    }
    if (data.containsKey('login_password')) {
      context.handle(
        _loginPasswordMeta,
        loginPassword.isAcceptableOrUnknown(
          data['login_password']!,
          _loginPasswordMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_loginPasswordMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Branche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Branche(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      contactPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_phone'],
      )!,
      managerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manager_name'],
      )!,
      loginUsername: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}login_username'],
      )!,
      loginPassword: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}login_password'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $BranchesTable createAlias(String alias) {
    return $BranchesTable(attachedDatabase, alias);
  }
}

class Branche extends DataClass implements Insertable<Branche> {
  final String id;
  final String tenantId;
  final String name;
  final String location;
  final String contactPhone;
  final String managerName;
  final String loginUsername;
  final String loginPassword;
  final bool isActive;
  const Branche({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.location,
    required this.contactPhone,
    required this.managerName,
    required this.loginUsername,
    required this.loginPassword,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['name'] = Variable<String>(name);
    map['location'] = Variable<String>(location);
    map['contact_phone'] = Variable<String>(contactPhone);
    map['manager_name'] = Variable<String>(managerName);
    map['login_username'] = Variable<String>(loginUsername);
    map['login_password'] = Variable<String>(loginPassword);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  BranchesCompanion toCompanion(bool nullToAbsent) {
    return BranchesCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      name: Value(name),
      location: Value(location),
      contactPhone: Value(contactPhone),
      managerName: Value(managerName),
      loginUsername: Value(loginUsername),
      loginPassword: Value(loginPassword),
      isActive: Value(isActive),
    );
  }

  factory Branche.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Branche(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      name: serializer.fromJson<String>(json['name']),
      location: serializer.fromJson<String>(json['location']),
      contactPhone: serializer.fromJson<String>(json['contactPhone']),
      managerName: serializer.fromJson<String>(json['managerName']),
      loginUsername: serializer.fromJson<String>(json['loginUsername']),
      loginPassword: serializer.fromJson<String>(json['loginPassword']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'name': serializer.toJson<String>(name),
      'location': serializer.toJson<String>(location),
      'contactPhone': serializer.toJson<String>(contactPhone),
      'managerName': serializer.toJson<String>(managerName),
      'loginUsername': serializer.toJson<String>(loginUsername),
      'loginPassword': serializer.toJson<String>(loginPassword),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Branche copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? location,
    String? contactPhone,
    String? managerName,
    String? loginUsername,
    String? loginPassword,
    bool? isActive,
  }) => Branche(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    name: name ?? this.name,
    location: location ?? this.location,
    contactPhone: contactPhone ?? this.contactPhone,
    managerName: managerName ?? this.managerName,
    loginUsername: loginUsername ?? this.loginUsername,
    loginPassword: loginPassword ?? this.loginPassword,
    isActive: isActive ?? this.isActive,
  );
  Branche copyWithCompanion(BranchesCompanion data) {
    return Branche(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      name: data.name.present ? data.name.value : this.name,
      location: data.location.present ? data.location.value : this.location,
      contactPhone: data.contactPhone.present
          ? data.contactPhone.value
          : this.contactPhone,
      managerName: data.managerName.present
          ? data.managerName.value
          : this.managerName,
      loginUsername: data.loginUsername.present
          ? data.loginUsername.value
          : this.loginUsername,
      loginPassword: data.loginPassword.present
          ? data.loginPassword.value
          : this.loginPassword,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Branche(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('name: $name, ')
          ..write('location: $location, ')
          ..write('contactPhone: $contactPhone, ')
          ..write('managerName: $managerName, ')
          ..write('loginUsername: $loginUsername, ')
          ..write('loginPassword: $loginPassword, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    name,
    location,
    contactPhone,
    managerName,
    loginUsername,
    loginPassword,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Branche &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.name == this.name &&
          other.location == this.location &&
          other.contactPhone == this.contactPhone &&
          other.managerName == this.managerName &&
          other.loginUsername == this.loginUsername &&
          other.loginPassword == this.loginPassword &&
          other.isActive == this.isActive);
}

class BranchesCompanion extends UpdateCompanion<Branche> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> name;
  final Value<String> location;
  final Value<String> contactPhone;
  final Value<String> managerName;
  final Value<String> loginUsername;
  final Value<String> loginPassword;
  final Value<bool> isActive;
  final Value<int> rowid;
  const BranchesCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.name = const Value.absent(),
    this.location = const Value.absent(),
    this.contactPhone = const Value.absent(),
    this.managerName = const Value.absent(),
    this.loginUsername = const Value.absent(),
    this.loginPassword = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BranchesCompanion.insert({
    required String id,
    required String tenantId,
    required String name,
    required String location,
    required String contactPhone,
    required String managerName,
    required String loginUsername,
    required String loginPassword,
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       name = Value(name),
       location = Value(location),
       contactPhone = Value(contactPhone),
       managerName = Value(managerName),
       loginUsername = Value(loginUsername),
       loginPassword = Value(loginPassword);
  static Insertable<Branche> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? name,
    Expression<String>? location,
    Expression<String>? contactPhone,
    Expression<String>? managerName,
    Expression<String>? loginUsername,
    Expression<String>? loginPassword,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (name != null) 'name': name,
      if (location != null) 'location': location,
      if (contactPhone != null) 'contact_phone': contactPhone,
      if (managerName != null) 'manager_name': managerName,
      if (loginUsername != null) 'login_username': loginUsername,
      if (loginPassword != null) 'login_password': loginPassword,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BranchesCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? name,
    Value<String>? location,
    Value<String>? contactPhone,
    Value<String>? managerName,
    Value<String>? loginUsername,
    Value<String>? loginPassword,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return BranchesCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      location: location ?? this.location,
      contactPhone: contactPhone ?? this.contactPhone,
      managerName: managerName ?? this.managerName,
      loginUsername: loginUsername ?? this.loginUsername,
      loginPassword: loginPassword ?? this.loginPassword,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (contactPhone.present) {
      map['contact_phone'] = Variable<String>(contactPhone.value);
    }
    if (managerName.present) {
      map['manager_name'] = Variable<String>(managerName.value);
    }
    if (loginUsername.present) {
      map['login_username'] = Variable<String>(loginUsername.value);
    }
    if (loginPassword.present) {
      map['login_password'] = Variable<String>(loginPassword.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BranchesCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('name: $name, ')
          ..write('location: $location, ')
          ..write('contactPhone: $contactPhone, ')
          ..write('managerName: $managerName, ')
          ..write('loginUsername: $loginUsername, ')
          ..write('loginPassword: $loginPassword, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TenantsTable extends Tenants with TableInfo<$TenantsTable, Tenant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TenantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessNameMeta = const VerificationMeta(
    'businessName',
  );
  @override
  late final GeneratedColumn<String> businessName = GeneratedColumn<String>(
    'business_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tierIdMeta = const VerificationMeta('tierId');
  @override
  late final GeneratedColumn<String> tierId = GeneratedColumn<String>(
    'tier_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('standard'),
  );
  static const VerificationMeta _createdDateMeta = const VerificationMeta(
    'createdDate',
  );
  @override
  late final GeneratedColumn<DateTime> createdDate = GeneratedColumn<DateTime>(
    'created_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastLoginMeta = const VerificationMeta(
    'lastLogin',
  );
  @override
  late final GeneratedColumn<DateTime> lastLogin = GeneratedColumn<DateTime>(
    'last_login',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ordersCountMeta = const VerificationMeta(
    'ordersCount',
  );
  @override
  late final GeneratedColumn<int> ordersCount = GeneratedColumn<int>(
    'orders_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _revenueMeta = const VerificationMeta(
    'revenue',
  );
  @override
  late final GeneratedColumn<double> revenue = GeneratedColumn<double>(
    'revenue',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _isMaintenanceModeMeta = const VerificationMeta(
    'isMaintenanceMode',
  );
  @override
  late final GeneratedColumn<bool> isMaintenanceMode = GeneratedColumn<bool>(
    'is_maintenance_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_maintenance_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _enabledFeaturesMeta = const VerificationMeta(
    'enabledFeatures',
  );
  @override
  late final GeneratedColumn<String> enabledFeatures = GeneratedColumn<String>(
    'enabled_features',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _allowUpdateMeta = const VerificationMeta(
    'allowUpdate',
  );
  @override
  late final GeneratedColumn<bool> allowUpdate = GeneratedColumn<bool>(
    'allow_update',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("allow_update" IN (0, 1))',
    ),
  );
  static const VerificationMeta _immuneToBlockingMeta = const VerificationMeta(
    'immuneToBlocking',
  );
  @override
  late final GeneratedColumn<bool> immuneToBlocking = GeneratedColumn<bool>(
    'immune_to_blocking',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("immune_to_blocking" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    businessName,
    email,
    phone,
    status,
    tierId,
    createdDate,
    lastLogin,
    ordersCount,
    revenue,
    isMaintenanceMode,
    enabledFeatures,
    allowUpdate,
    immuneToBlocking,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tenants';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tenant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('business_name')) {
      context.handle(
        _businessNameMeta,
        businessName.isAcceptableOrUnknown(
          data['business_name']!,
          _businessNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessNameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('tier_id')) {
      context.handle(
        _tierIdMeta,
        tierId.isAcceptableOrUnknown(data['tier_id']!, _tierIdMeta),
      );
    }
    if (data.containsKey('created_date')) {
      context.handle(
        _createdDateMeta,
        createdDate.isAcceptableOrUnknown(
          data['created_date']!,
          _createdDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdDateMeta);
    }
    if (data.containsKey('last_login')) {
      context.handle(
        _lastLoginMeta,
        lastLogin.isAcceptableOrUnknown(data['last_login']!, _lastLoginMeta),
      );
    }
    if (data.containsKey('orders_count')) {
      context.handle(
        _ordersCountMeta,
        ordersCount.isAcceptableOrUnknown(
          data['orders_count']!,
          _ordersCountMeta,
        ),
      );
    }
    if (data.containsKey('revenue')) {
      context.handle(
        _revenueMeta,
        revenue.isAcceptableOrUnknown(data['revenue']!, _revenueMeta),
      );
    }
    if (data.containsKey('is_maintenance_mode')) {
      context.handle(
        _isMaintenanceModeMeta,
        isMaintenanceMode.isAcceptableOrUnknown(
          data['is_maintenance_mode']!,
          _isMaintenanceModeMeta,
        ),
      );
    }
    if (data.containsKey('enabled_features')) {
      context.handle(
        _enabledFeaturesMeta,
        enabledFeatures.isAcceptableOrUnknown(
          data['enabled_features']!,
          _enabledFeaturesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_enabledFeaturesMeta);
    }
    if (data.containsKey('allow_update')) {
      context.handle(
        _allowUpdateMeta,
        allowUpdate.isAcceptableOrUnknown(
          data['allow_update']!,
          _allowUpdateMeta,
        ),
      );
    }
    if (data.containsKey('immune_to_blocking')) {
      context.handle(
        _immuneToBlockingMeta,
        immuneToBlocking.isAcceptableOrUnknown(
          data['immune_to_blocking']!,
          _immuneToBlockingMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tenant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tenant(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      businessName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      tierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tier_id'],
      )!,
      createdDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_date'],
      )!,
      lastLogin: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_login'],
      ),
      ordersCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}orders_count'],
      )!,
      revenue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}revenue'],
      )!,
      isMaintenanceMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_maintenance_mode'],
      )!,
      enabledFeatures: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}enabled_features'],
      )!,
      allowUpdate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allow_update'],
      ),
      immuneToBlocking: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}immune_to_blocking'],
      ),
    );
  }

  @override
  $TenantsTable createAlias(String alias) {
    return $TenantsTable(attachedDatabase, alias);
  }
}

class Tenant extends DataClass implements Insertable<Tenant> {
  final String id;
  final String name;
  final String businessName;
  final String email;
  final String phone;
  final String status;
  final String tierId;
  final DateTime createdDate;
  final DateTime? lastLogin;
  final int ordersCount;
  final double revenue;
  final bool isMaintenanceMode;
  final String enabledFeatures;
  final bool? allowUpdate;
  final bool? immuneToBlocking;
  const Tenant({
    required this.id,
    required this.name,
    required this.businessName,
    required this.email,
    required this.phone,
    required this.status,
    required this.tierId,
    required this.createdDate,
    this.lastLogin,
    required this.ordersCount,
    required this.revenue,
    required this.isMaintenanceMode,
    required this.enabledFeatures,
    this.allowUpdate,
    this.immuneToBlocking,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['business_name'] = Variable<String>(businessName);
    map['email'] = Variable<String>(email);
    map['phone'] = Variable<String>(phone);
    map['status'] = Variable<String>(status);
    map['tier_id'] = Variable<String>(tierId);
    map['created_date'] = Variable<DateTime>(createdDate);
    if (!nullToAbsent || lastLogin != null) {
      map['last_login'] = Variable<DateTime>(lastLogin);
    }
    map['orders_count'] = Variable<int>(ordersCount);
    map['revenue'] = Variable<double>(revenue);
    map['is_maintenance_mode'] = Variable<bool>(isMaintenanceMode);
    map['enabled_features'] = Variable<String>(enabledFeatures);
    if (!nullToAbsent || allowUpdate != null) {
      map['allow_update'] = Variable<bool>(allowUpdate);
    }
    if (!nullToAbsent || immuneToBlocking != null) {
      map['immune_to_blocking'] = Variable<bool>(immuneToBlocking);
    }
    return map;
  }

  TenantsCompanion toCompanion(bool nullToAbsent) {
    return TenantsCompanion(
      id: Value(id),
      name: Value(name),
      businessName: Value(businessName),
      email: Value(email),
      phone: Value(phone),
      status: Value(status),
      tierId: Value(tierId),
      createdDate: Value(createdDate),
      lastLogin: lastLogin == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLogin),
      ordersCount: Value(ordersCount),
      revenue: Value(revenue),
      isMaintenanceMode: Value(isMaintenanceMode),
      enabledFeatures: Value(enabledFeatures),
      allowUpdate: allowUpdate == null && nullToAbsent
          ? const Value.absent()
          : Value(allowUpdate),
      immuneToBlocking: immuneToBlocking == null && nullToAbsent
          ? const Value.absent()
          : Value(immuneToBlocking),
    );
  }

  factory Tenant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tenant(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      businessName: serializer.fromJson<String>(json['businessName']),
      email: serializer.fromJson<String>(json['email']),
      phone: serializer.fromJson<String>(json['phone']),
      status: serializer.fromJson<String>(json['status']),
      tierId: serializer.fromJson<String>(json['tierId']),
      createdDate: serializer.fromJson<DateTime>(json['createdDate']),
      lastLogin: serializer.fromJson<DateTime?>(json['lastLogin']),
      ordersCount: serializer.fromJson<int>(json['ordersCount']),
      revenue: serializer.fromJson<double>(json['revenue']),
      isMaintenanceMode: serializer.fromJson<bool>(json['isMaintenanceMode']),
      enabledFeatures: serializer.fromJson<String>(json['enabledFeatures']),
      allowUpdate: serializer.fromJson<bool?>(json['allowUpdate']),
      immuneToBlocking: serializer.fromJson<bool?>(json['immuneToBlocking']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'businessName': serializer.toJson<String>(businessName),
      'email': serializer.toJson<String>(email),
      'phone': serializer.toJson<String>(phone),
      'status': serializer.toJson<String>(status),
      'tierId': serializer.toJson<String>(tierId),
      'createdDate': serializer.toJson<DateTime>(createdDate),
      'lastLogin': serializer.toJson<DateTime?>(lastLogin),
      'ordersCount': serializer.toJson<int>(ordersCount),
      'revenue': serializer.toJson<double>(revenue),
      'isMaintenanceMode': serializer.toJson<bool>(isMaintenanceMode),
      'enabledFeatures': serializer.toJson<String>(enabledFeatures),
      'allowUpdate': serializer.toJson<bool?>(allowUpdate),
      'immuneToBlocking': serializer.toJson<bool?>(immuneToBlocking),
    };
  }

  Tenant copyWith({
    String? id,
    String? name,
    String? businessName,
    String? email,
    String? phone,
    String? status,
    String? tierId,
    DateTime? createdDate,
    Value<DateTime?> lastLogin = const Value.absent(),
    int? ordersCount,
    double? revenue,
    bool? isMaintenanceMode,
    String? enabledFeatures,
    Value<bool?> allowUpdate = const Value.absent(),
    Value<bool?> immuneToBlocking = const Value.absent(),
  }) => Tenant(
    id: id ?? this.id,
    name: name ?? this.name,
    businessName: businessName ?? this.businessName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    status: status ?? this.status,
    tierId: tierId ?? this.tierId,
    createdDate: createdDate ?? this.createdDate,
    lastLogin: lastLogin.present ? lastLogin.value : this.lastLogin,
    ordersCount: ordersCount ?? this.ordersCount,
    revenue: revenue ?? this.revenue,
    isMaintenanceMode: isMaintenanceMode ?? this.isMaintenanceMode,
    enabledFeatures: enabledFeatures ?? this.enabledFeatures,
    allowUpdate: allowUpdate.present ? allowUpdate.value : this.allowUpdate,
    immuneToBlocking: immuneToBlocking.present
        ? immuneToBlocking.value
        : this.immuneToBlocking,
  );
  Tenant copyWithCompanion(TenantsCompanion data) {
    return Tenant(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      businessName: data.businessName.present
          ? data.businessName.value
          : this.businessName,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      status: data.status.present ? data.status.value : this.status,
      tierId: data.tierId.present ? data.tierId.value : this.tierId,
      createdDate: data.createdDate.present
          ? data.createdDate.value
          : this.createdDate,
      lastLogin: data.lastLogin.present ? data.lastLogin.value : this.lastLogin,
      ordersCount: data.ordersCount.present
          ? data.ordersCount.value
          : this.ordersCount,
      revenue: data.revenue.present ? data.revenue.value : this.revenue,
      isMaintenanceMode: data.isMaintenanceMode.present
          ? data.isMaintenanceMode.value
          : this.isMaintenanceMode,
      enabledFeatures: data.enabledFeatures.present
          ? data.enabledFeatures.value
          : this.enabledFeatures,
      allowUpdate: data.allowUpdate.present
          ? data.allowUpdate.value
          : this.allowUpdate,
      immuneToBlocking: data.immuneToBlocking.present
          ? data.immuneToBlocking.value
          : this.immuneToBlocking,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tenant(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('businessName: $businessName, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('status: $status, ')
          ..write('tierId: $tierId, ')
          ..write('createdDate: $createdDate, ')
          ..write('lastLogin: $lastLogin, ')
          ..write('ordersCount: $ordersCount, ')
          ..write('revenue: $revenue, ')
          ..write('isMaintenanceMode: $isMaintenanceMode, ')
          ..write('enabledFeatures: $enabledFeatures, ')
          ..write('allowUpdate: $allowUpdate, ')
          ..write('immuneToBlocking: $immuneToBlocking')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    businessName,
    email,
    phone,
    status,
    tierId,
    createdDate,
    lastLogin,
    ordersCount,
    revenue,
    isMaintenanceMode,
    enabledFeatures,
    allowUpdate,
    immuneToBlocking,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tenant &&
          other.id == this.id &&
          other.name == this.name &&
          other.businessName == this.businessName &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.status == this.status &&
          other.tierId == this.tierId &&
          other.createdDate == this.createdDate &&
          other.lastLogin == this.lastLogin &&
          other.ordersCount == this.ordersCount &&
          other.revenue == this.revenue &&
          other.isMaintenanceMode == this.isMaintenanceMode &&
          other.enabledFeatures == this.enabledFeatures &&
          other.allowUpdate == this.allowUpdate &&
          other.immuneToBlocking == this.immuneToBlocking);
}

class TenantsCompanion extends UpdateCompanion<Tenant> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> businessName;
  final Value<String> email;
  final Value<String> phone;
  final Value<String> status;
  final Value<String> tierId;
  final Value<DateTime> createdDate;
  final Value<DateTime?> lastLogin;
  final Value<int> ordersCount;
  final Value<double> revenue;
  final Value<bool> isMaintenanceMode;
  final Value<String> enabledFeatures;
  final Value<bool?> allowUpdate;
  final Value<bool?> immuneToBlocking;
  final Value<int> rowid;
  const TenantsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.businessName = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.status = const Value.absent(),
    this.tierId = const Value.absent(),
    this.createdDate = const Value.absent(),
    this.lastLogin = const Value.absent(),
    this.ordersCount = const Value.absent(),
    this.revenue = const Value.absent(),
    this.isMaintenanceMode = const Value.absent(),
    this.enabledFeatures = const Value.absent(),
    this.allowUpdate = const Value.absent(),
    this.immuneToBlocking = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TenantsCompanion.insert({
    required String id,
    required String name,
    required String businessName,
    required String email,
    required String phone,
    required String status,
    this.tierId = const Value.absent(),
    required DateTime createdDate,
    this.lastLogin = const Value.absent(),
    this.ordersCount = const Value.absent(),
    this.revenue = const Value.absent(),
    this.isMaintenanceMode = const Value.absent(),
    required String enabledFeatures,
    this.allowUpdate = const Value.absent(),
    this.immuneToBlocking = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       businessName = Value(businessName),
       email = Value(email),
       phone = Value(phone),
       status = Value(status),
       createdDate = Value(createdDate),
       enabledFeatures = Value(enabledFeatures);
  static Insertable<Tenant> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? businessName,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<String>? status,
    Expression<String>? tierId,
    Expression<DateTime>? createdDate,
    Expression<DateTime>? lastLogin,
    Expression<int>? ordersCount,
    Expression<double>? revenue,
    Expression<bool>? isMaintenanceMode,
    Expression<String>? enabledFeatures,
    Expression<bool>? allowUpdate,
    Expression<bool>? immuneToBlocking,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (businessName != null) 'business_name': businessName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (status != null) 'status': status,
      if (tierId != null) 'tier_id': tierId,
      if (createdDate != null) 'created_date': createdDate,
      if (lastLogin != null) 'last_login': lastLogin,
      if (ordersCount != null) 'orders_count': ordersCount,
      if (revenue != null) 'revenue': revenue,
      if (isMaintenanceMode != null) 'is_maintenance_mode': isMaintenanceMode,
      if (enabledFeatures != null) 'enabled_features': enabledFeatures,
      if (allowUpdate != null) 'allow_update': allowUpdate,
      if (immuneToBlocking != null) 'immune_to_blocking': immuneToBlocking,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TenantsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? businessName,
    Value<String>? email,
    Value<String>? phone,
    Value<String>? status,
    Value<String>? tierId,
    Value<DateTime>? createdDate,
    Value<DateTime?>? lastLogin,
    Value<int>? ordersCount,
    Value<double>? revenue,
    Value<bool>? isMaintenanceMode,
    Value<String>? enabledFeatures,
    Value<bool?>? allowUpdate,
    Value<bool?>? immuneToBlocking,
    Value<int>? rowid,
  }) {
    return TenantsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      businessName: businessName ?? this.businessName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      tierId: tierId ?? this.tierId,
      createdDate: createdDate ?? this.createdDate,
      lastLogin: lastLogin ?? this.lastLogin,
      ordersCount: ordersCount ?? this.ordersCount,
      revenue: revenue ?? this.revenue,
      isMaintenanceMode: isMaintenanceMode ?? this.isMaintenanceMode,
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
      allowUpdate: allowUpdate ?? this.allowUpdate,
      immuneToBlocking: immuneToBlocking ?? this.immuneToBlocking,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (businessName.present) {
      map['business_name'] = Variable<String>(businessName.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (tierId.present) {
      map['tier_id'] = Variable<String>(tierId.value);
    }
    if (createdDate.present) {
      map['created_date'] = Variable<DateTime>(createdDate.value);
    }
    if (lastLogin.present) {
      map['last_login'] = Variable<DateTime>(lastLogin.value);
    }
    if (ordersCount.present) {
      map['orders_count'] = Variable<int>(ordersCount.value);
    }
    if (revenue.present) {
      map['revenue'] = Variable<double>(revenue.value);
    }
    if (isMaintenanceMode.present) {
      map['is_maintenance_mode'] = Variable<bool>(isMaintenanceMode.value);
    }
    if (enabledFeatures.present) {
      map['enabled_features'] = Variable<String>(enabledFeatures.value);
    }
    if (allowUpdate.present) {
      map['allow_update'] = Variable<bool>(allowUpdate.value);
    }
    if (immuneToBlocking.present) {
      map['immune_to_blocking'] = Variable<bool>(immuneToBlocking.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TenantsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('businessName: $businessName, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('status: $status, ')
          ..write('tierId: $tierId, ')
          ..write('createdDate: $createdDate, ')
          ..write('lastLogin: $lastLogin, ')
          ..write('ordersCount: $ordersCount, ')
          ..write('revenue: $revenue, ')
          ..write('isMaintenanceMode: $isMaintenanceMode, ')
          ..write('enabledFeatures: $enabledFeatures, ')
          ..write('allowUpdate: $allowUpdate, ')
          ..write('immuneToBlocking: $immuneToBlocking, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TiersTable extends Tiers with TableInfo<$TiersTable, Tier> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TiersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledFeaturesMeta = const VerificationMeta(
    'enabledFeatures',
  );
  @override
  late final GeneratedColumn<String> enabledFeatures = GeneratedColumn<String>(
    'enabled_features',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _allowUpdatesMeta = const VerificationMeta(
    'allowUpdates',
  );
  @override
  late final GeneratedColumn<bool> allowUpdates = GeneratedColumn<bool>(
    'allow_updates',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("allow_updates" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _immuneToBlockingMeta = const VerificationMeta(
    'immuneToBlocking',
  );
  @override
  late final GeneratedColumn<bool> immuneToBlocking = GeneratedColumn<bool>(
    'immune_to_blocking',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("immune_to_blocking" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    enabledFeatures,
    allowUpdates,
    immuneToBlocking,
    description,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tiers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tier> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('enabled_features')) {
      context.handle(
        _enabledFeaturesMeta,
        enabledFeatures.isAcceptableOrUnknown(
          data['enabled_features']!,
          _enabledFeaturesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_enabledFeaturesMeta);
    }
    if (data.containsKey('allow_updates')) {
      context.handle(
        _allowUpdatesMeta,
        allowUpdates.isAcceptableOrUnknown(
          data['allow_updates']!,
          _allowUpdatesMeta,
        ),
      );
    }
    if (data.containsKey('immune_to_blocking')) {
      context.handle(
        _immuneToBlockingMeta,
        immuneToBlocking.isAcceptableOrUnknown(
          data['immune_to_blocking']!,
          _immuneToBlockingMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tier map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tier(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      enabledFeatures: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}enabled_features'],
      )!,
      allowUpdates: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allow_updates'],
      )!,
      immuneToBlocking: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}immune_to_blocking'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
    );
  }

  @override
  $TiersTable createAlias(String alias) {
    return $TiersTable(attachedDatabase, alias);
  }
}

class Tier extends DataClass implements Insertable<Tier> {
  final String id;
  final String name;
  final String enabledFeatures;
  final bool allowUpdates;
  final bool immuneToBlocking;
  final String description;
  const Tier({
    required this.id,
    required this.name,
    required this.enabledFeatures,
    required this.allowUpdates,
    required this.immuneToBlocking,
    required this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['enabled_features'] = Variable<String>(enabledFeatures);
    map['allow_updates'] = Variable<bool>(allowUpdates);
    map['immune_to_blocking'] = Variable<bool>(immuneToBlocking);
    map['description'] = Variable<String>(description);
    return map;
  }

  TiersCompanion toCompanion(bool nullToAbsent) {
    return TiersCompanion(
      id: Value(id),
      name: Value(name),
      enabledFeatures: Value(enabledFeatures),
      allowUpdates: Value(allowUpdates),
      immuneToBlocking: Value(immuneToBlocking),
      description: Value(description),
    );
  }

  factory Tier.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tier(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      enabledFeatures: serializer.fromJson<String>(json['enabledFeatures']),
      allowUpdates: serializer.fromJson<bool>(json['allowUpdates']),
      immuneToBlocking: serializer.fromJson<bool>(json['immuneToBlocking']),
      description: serializer.fromJson<String>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'enabledFeatures': serializer.toJson<String>(enabledFeatures),
      'allowUpdates': serializer.toJson<bool>(allowUpdates),
      'immuneToBlocking': serializer.toJson<bool>(immuneToBlocking),
      'description': serializer.toJson<String>(description),
    };
  }

  Tier copyWith({
    String? id,
    String? name,
    String? enabledFeatures,
    bool? allowUpdates,
    bool? immuneToBlocking,
    String? description,
  }) => Tier(
    id: id ?? this.id,
    name: name ?? this.name,
    enabledFeatures: enabledFeatures ?? this.enabledFeatures,
    allowUpdates: allowUpdates ?? this.allowUpdates,
    immuneToBlocking: immuneToBlocking ?? this.immuneToBlocking,
    description: description ?? this.description,
  );
  Tier copyWithCompanion(TiersCompanion data) {
    return Tier(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      enabledFeatures: data.enabledFeatures.present
          ? data.enabledFeatures.value
          : this.enabledFeatures,
      allowUpdates: data.allowUpdates.present
          ? data.allowUpdates.value
          : this.allowUpdates,
      immuneToBlocking: data.immuneToBlocking.present
          ? data.immuneToBlocking.value
          : this.immuneToBlocking,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tier(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('enabledFeatures: $enabledFeatures, ')
          ..write('allowUpdates: $allowUpdates, ')
          ..write('immuneToBlocking: $immuneToBlocking, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    enabledFeatures,
    allowUpdates,
    immuneToBlocking,
    description,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tier &&
          other.id == this.id &&
          other.name == this.name &&
          other.enabledFeatures == this.enabledFeatures &&
          other.allowUpdates == this.allowUpdates &&
          other.immuneToBlocking == this.immuneToBlocking &&
          other.description == this.description);
}

class TiersCompanion extends UpdateCompanion<Tier> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> enabledFeatures;
  final Value<bool> allowUpdates;
  final Value<bool> immuneToBlocking;
  final Value<String> description;
  final Value<int> rowid;
  const TiersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.enabledFeatures = const Value.absent(),
    this.allowUpdates = const Value.absent(),
    this.immuneToBlocking = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TiersCompanion.insert({
    required String id,
    required String name,
    required String enabledFeatures,
    this.allowUpdates = const Value.absent(),
    this.immuneToBlocking = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       enabledFeatures = Value(enabledFeatures);
  static Insertable<Tier> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? enabledFeatures,
    Expression<bool>? allowUpdates,
    Expression<bool>? immuneToBlocking,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (enabledFeatures != null) 'enabled_features': enabledFeatures,
      if (allowUpdates != null) 'allow_updates': allowUpdates,
      if (immuneToBlocking != null) 'immune_to_blocking': immuneToBlocking,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TiersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? enabledFeatures,
    Value<bool>? allowUpdates,
    Value<bool>? immuneToBlocking,
    Value<String>? description,
    Value<int>? rowid,
  }) {
    return TiersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
      allowUpdates: allowUpdates ?? this.allowUpdates,
      immuneToBlocking: immuneToBlocking ?? this.immuneToBlocking,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (enabledFeatures.present) {
      map['enabled_features'] = Variable<String>(enabledFeatures.value);
    }
    if (allowUpdates.present) {
      map['allow_updates'] = Variable<bool>(allowUpdates.value);
    }
    if (immuneToBlocking.present) {
      map['immune_to_blocking'] = Variable<bool>(immuneToBlocking.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TiersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('enabledFeatures: $enabledFeatures, ')
          ..write('allowUpdates: $allowUpdates, ')
          ..write('immuneToBlocking: $immuneToBlocking, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CartItemsTable extends CartItems
    with TableInfo<$CartItemsTable, CartItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CartItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productPriceMeta = const VerificationMeta(
    'productPrice',
  );
  @override
  late final GeneratedColumn<double> productPrice = GeneratedColumn<double>(
    'product_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productImageMeta = const VerificationMeta(
    'productImage',
  );
  @override
  late final GeneratedColumn<String> productImage = GeneratedColumn<String>(
    'product_image',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    quantity,
    tenantId,
    productName,
    productPrice,
    productImage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cart_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CartItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    }
    if (data.containsKey('product_price')) {
      context.handle(
        _productPriceMeta,
        productPrice.isAcceptableOrUnknown(
          data['product_price']!,
          _productPriceMeta,
        ),
      );
    }
    if (data.containsKey('product_image')) {
      context.handle(
        _productImageMeta,
        productImage.isAcceptableOrUnknown(
          data['product_image']!,
          _productImageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CartItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CartItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      ),
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      ),
      productPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}product_price'],
      ),
      productImage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_image'],
      ),
    );
  }

  @override
  $CartItemsTable createAlias(String alias) {
    return $CartItemsTable(attachedDatabase, alias);
  }
}

class CartItem extends DataClass implements Insertable<CartItem> {
  final int id;
  final String productId;
  final int quantity;
  final String? tenantId;
  final String? productName;
  final double? productPrice;
  final String? productImage;
  const CartItem({
    required this.id,
    required this.productId,
    required this.quantity,
    this.tenantId,
    this.productName,
    this.productPrice,
    this.productImage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product_id'] = Variable<String>(productId);
    map['quantity'] = Variable<int>(quantity);
    if (!nullToAbsent || tenantId != null) {
      map['tenant_id'] = Variable<String>(tenantId);
    }
    if (!nullToAbsent || productName != null) {
      map['product_name'] = Variable<String>(productName);
    }
    if (!nullToAbsent || productPrice != null) {
      map['product_price'] = Variable<double>(productPrice);
    }
    if (!nullToAbsent || productImage != null) {
      map['product_image'] = Variable<String>(productImage);
    }
    return map;
  }

  CartItemsCompanion toCompanion(bool nullToAbsent) {
    return CartItemsCompanion(
      id: Value(id),
      productId: Value(productId),
      quantity: Value(quantity),
      tenantId: tenantId == null && nullToAbsent
          ? const Value.absent()
          : Value(tenantId),
      productName: productName == null && nullToAbsent
          ? const Value.absent()
          : Value(productName),
      productPrice: productPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(productPrice),
      productImage: productImage == null && nullToAbsent
          ? const Value.absent()
          : Value(productImage),
    );
  }

  factory CartItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CartItem(
      id: serializer.fromJson<int>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      tenantId: serializer.fromJson<String?>(json['tenantId']),
      productName: serializer.fromJson<String?>(json['productName']),
      productPrice: serializer.fromJson<double?>(json['productPrice']),
      productImage: serializer.fromJson<String?>(json['productImage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productId': serializer.toJson<String>(productId),
      'quantity': serializer.toJson<int>(quantity),
      'tenantId': serializer.toJson<String?>(tenantId),
      'productName': serializer.toJson<String?>(productName),
      'productPrice': serializer.toJson<double?>(productPrice),
      'productImage': serializer.toJson<String?>(productImage),
    };
  }

  CartItem copyWith({
    int? id,
    String? productId,
    int? quantity,
    Value<String?> tenantId = const Value.absent(),
    Value<String?> productName = const Value.absent(),
    Value<double?> productPrice = const Value.absent(),
    Value<String?> productImage = const Value.absent(),
  }) => CartItem(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    quantity: quantity ?? this.quantity,
    tenantId: tenantId.present ? tenantId.value : this.tenantId,
    productName: productName.present ? productName.value : this.productName,
    productPrice: productPrice.present ? productPrice.value : this.productPrice,
    productImage: productImage.present ? productImage.value : this.productImage,
  );
  CartItem copyWithCompanion(CartItemsCompanion data) {
    return CartItem(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      productPrice: data.productPrice.present
          ? data.productPrice.value
          : this.productPrice,
      productImage: data.productImage.present
          ? data.productImage.value
          : this.productImage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CartItem(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('tenantId: $tenantId, ')
          ..write('productName: $productName, ')
          ..write('productPrice: $productPrice, ')
          ..write('productImage: $productImage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    quantity,
    tenantId,
    productName,
    productPrice,
    productImage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CartItem &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.quantity == this.quantity &&
          other.tenantId == this.tenantId &&
          other.productName == this.productName &&
          other.productPrice == this.productPrice &&
          other.productImage == this.productImage);
}

class CartItemsCompanion extends UpdateCompanion<CartItem> {
  final Value<int> id;
  final Value<String> productId;
  final Value<int> quantity;
  final Value<String?> tenantId;
  final Value<String?> productName;
  final Value<double?> productPrice;
  final Value<String?> productImage;
  const CartItemsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.productName = const Value.absent(),
    this.productPrice = const Value.absent(),
    this.productImage = const Value.absent(),
  });
  CartItemsCompanion.insert({
    this.id = const Value.absent(),
    required String productId,
    required int quantity,
    this.tenantId = const Value.absent(),
    this.productName = const Value.absent(),
    this.productPrice = const Value.absent(),
    this.productImage = const Value.absent(),
  }) : productId = Value(productId),
       quantity = Value(quantity);
  static Insertable<CartItem> custom({
    Expression<int>? id,
    Expression<String>? productId,
    Expression<int>? quantity,
    Expression<String>? tenantId,
    Expression<String>? productName,
    Expression<double>? productPrice,
    Expression<String>? productImage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (quantity != null) 'quantity': quantity,
      if (tenantId != null) 'tenant_id': tenantId,
      if (productName != null) 'product_name': productName,
      if (productPrice != null) 'product_price': productPrice,
      if (productImage != null) 'product_image': productImage,
    });
  }

  CartItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? productId,
    Value<int>? quantity,
    Value<String?>? tenantId,
    Value<String?>? productName,
    Value<double?>? productPrice,
    Value<String?>? productImage,
  }) {
    return CartItemsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      tenantId: tenantId ?? this.tenantId,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      productImage: productImage ?? this.productImage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (productPrice.present) {
      map['product_price'] = Variable<double>(productPrice.value);
    }
    if (productImage.present) {
      map['product_image'] = Variable<String>(productImage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CartItemsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('tenantId: $tenantId, ')
          ..write('productName: $productName, ')
          ..write('productPrice: $productPrice, ')
          ..write('productImage: $productImage')
          ..write(')'))
        .toString();
  }
}

class $TenantConfigsTable extends TenantConfigs
    with TableInfo<$TenantConfigsTable, TenantConfig> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TenantConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _logoPathMeta = const VerificationMeta(
    'logoPath',
  );
  @override
  late final GeneratedColumn<String> logoPath = GeneratedColumn<String>(
    'logo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _primaryColorMeta = const VerificationMeta(
    'primaryColor',
  );
  @override
  late final GeneratedColumn<int> primaryColor = GeneratedColumn<int>(
    'primary_color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _secondaryColorMeta = const VerificationMeta(
    'secondaryColor',
  );
  @override
  late final GeneratedColumn<int> secondaryColor = GeneratedColumn<int>(
    'secondary_color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backgroundPathMeta = const VerificationMeta(
    'backgroundPath',
  );
  @override
  late final GeneratedColumn<String> backgroundPath = GeneratedColumn<String>(
    'background_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _appNameMeta = const VerificationMeta(
    'appName',
  );
  @override
  late final GeneratedColumn<String> appName = GeneratedColumn<String>(
    'app_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _welcomeMessageMeta = const VerificationMeta(
    'welcomeMessage',
  );
  @override
  late final GeneratedColumn<String> welcomeMessage = GeneratedColumn<String>(
    'welcome_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    logoPath,
    primaryColor,
    secondaryColor,
    backgroundPath,
    appName,
    welcomeMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tenant_configs';
  @override
  VerificationContext validateIntegrity(
    Insertable<TenantConfig> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('logo_path')) {
      context.handle(
        _logoPathMeta,
        logoPath.isAcceptableOrUnknown(data['logo_path']!, _logoPathMeta),
      );
    }
    if (data.containsKey('primary_color')) {
      context.handle(
        _primaryColorMeta,
        primaryColor.isAcceptableOrUnknown(
          data['primary_color']!,
          _primaryColorMeta,
        ),
      );
    }
    if (data.containsKey('secondary_color')) {
      context.handle(
        _secondaryColorMeta,
        secondaryColor.isAcceptableOrUnknown(
          data['secondary_color']!,
          _secondaryColorMeta,
        ),
      );
    }
    if (data.containsKey('background_path')) {
      context.handle(
        _backgroundPathMeta,
        backgroundPath.isAcceptableOrUnknown(
          data['background_path']!,
          _backgroundPathMeta,
        ),
      );
    }
    if (data.containsKey('app_name')) {
      context.handle(
        _appNameMeta,
        appName.isAcceptableOrUnknown(data['app_name']!, _appNameMeta),
      );
    }
    if (data.containsKey('welcome_message')) {
      context.handle(
        _welcomeMessageMeta,
        welcomeMessage.isAcceptableOrUnknown(
          data['welcome_message']!,
          _welcomeMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId};
  @override
  TenantConfig map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TenantConfig(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      logoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_path'],
      ),
      primaryColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}primary_color'],
      ),
      secondaryColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}secondary_color'],
      ),
      backgroundPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}background_path'],
      ),
      appName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_name'],
      ),
      welcomeMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}welcome_message'],
      ),
    );
  }

  @override
  $TenantConfigsTable createAlias(String alias) {
    return $TenantConfigsTable(attachedDatabase, alias);
  }
}

class TenantConfig extends DataClass implements Insertable<TenantConfig> {
  final String tenantId;
  final String? logoPath;
  final int? primaryColor;
  final int? secondaryColor;
  final String? backgroundPath;
  final String? appName;
  final String? welcomeMessage;
  const TenantConfig({
    required this.tenantId,
    this.logoPath,
    this.primaryColor,
    this.secondaryColor,
    this.backgroundPath,
    this.appName,
    this.welcomeMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    if (!nullToAbsent || logoPath != null) {
      map['logo_path'] = Variable<String>(logoPath);
    }
    if (!nullToAbsent || primaryColor != null) {
      map['primary_color'] = Variable<int>(primaryColor);
    }
    if (!nullToAbsent || secondaryColor != null) {
      map['secondary_color'] = Variable<int>(secondaryColor);
    }
    if (!nullToAbsent || backgroundPath != null) {
      map['background_path'] = Variable<String>(backgroundPath);
    }
    if (!nullToAbsent || appName != null) {
      map['app_name'] = Variable<String>(appName);
    }
    if (!nullToAbsent || welcomeMessage != null) {
      map['welcome_message'] = Variable<String>(welcomeMessage);
    }
    return map;
  }

  TenantConfigsCompanion toCompanion(bool nullToAbsent) {
    return TenantConfigsCompanion(
      tenantId: Value(tenantId),
      logoPath: logoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(logoPath),
      primaryColor: primaryColor == null && nullToAbsent
          ? const Value.absent()
          : Value(primaryColor),
      secondaryColor: secondaryColor == null && nullToAbsent
          ? const Value.absent()
          : Value(secondaryColor),
      backgroundPath: backgroundPath == null && nullToAbsent
          ? const Value.absent()
          : Value(backgroundPath),
      appName: appName == null && nullToAbsent
          ? const Value.absent()
          : Value(appName),
      welcomeMessage: welcomeMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(welcomeMessage),
    );
  }

  factory TenantConfig.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TenantConfig(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      logoPath: serializer.fromJson<String?>(json['logoPath']),
      primaryColor: serializer.fromJson<int?>(json['primaryColor']),
      secondaryColor: serializer.fromJson<int?>(json['secondaryColor']),
      backgroundPath: serializer.fromJson<String?>(json['backgroundPath']),
      appName: serializer.fromJson<String?>(json['appName']),
      welcomeMessage: serializer.fromJson<String?>(json['welcomeMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'logoPath': serializer.toJson<String?>(logoPath),
      'primaryColor': serializer.toJson<int?>(primaryColor),
      'secondaryColor': serializer.toJson<int?>(secondaryColor),
      'backgroundPath': serializer.toJson<String?>(backgroundPath),
      'appName': serializer.toJson<String?>(appName),
      'welcomeMessage': serializer.toJson<String?>(welcomeMessage),
    };
  }

  TenantConfig copyWith({
    String? tenantId,
    Value<String?> logoPath = const Value.absent(),
    Value<int?> primaryColor = const Value.absent(),
    Value<int?> secondaryColor = const Value.absent(),
    Value<String?> backgroundPath = const Value.absent(),
    Value<String?> appName = const Value.absent(),
    Value<String?> welcomeMessage = const Value.absent(),
  }) => TenantConfig(
    tenantId: tenantId ?? this.tenantId,
    logoPath: logoPath.present ? logoPath.value : this.logoPath,
    primaryColor: primaryColor.present ? primaryColor.value : this.primaryColor,
    secondaryColor: secondaryColor.present
        ? secondaryColor.value
        : this.secondaryColor,
    backgroundPath: backgroundPath.present
        ? backgroundPath.value
        : this.backgroundPath,
    appName: appName.present ? appName.value : this.appName,
    welcomeMessage: welcomeMessage.present
        ? welcomeMessage.value
        : this.welcomeMessage,
  );
  TenantConfig copyWithCompanion(TenantConfigsCompanion data) {
    return TenantConfig(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      logoPath: data.logoPath.present ? data.logoPath.value : this.logoPath,
      primaryColor: data.primaryColor.present
          ? data.primaryColor.value
          : this.primaryColor,
      secondaryColor: data.secondaryColor.present
          ? data.secondaryColor.value
          : this.secondaryColor,
      backgroundPath: data.backgroundPath.present
          ? data.backgroundPath.value
          : this.backgroundPath,
      appName: data.appName.present ? data.appName.value : this.appName,
      welcomeMessage: data.welcomeMessage.present
          ? data.welcomeMessage.value
          : this.welcomeMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TenantConfig(')
          ..write('tenantId: $tenantId, ')
          ..write('logoPath: $logoPath, ')
          ..write('primaryColor: $primaryColor, ')
          ..write('secondaryColor: $secondaryColor, ')
          ..write('backgroundPath: $backgroundPath, ')
          ..write('appName: $appName, ')
          ..write('welcomeMessage: $welcomeMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tenantId,
    logoPath,
    primaryColor,
    secondaryColor,
    backgroundPath,
    appName,
    welcomeMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TenantConfig &&
          other.tenantId == this.tenantId &&
          other.logoPath == this.logoPath &&
          other.primaryColor == this.primaryColor &&
          other.secondaryColor == this.secondaryColor &&
          other.backgroundPath == this.backgroundPath &&
          other.appName == this.appName &&
          other.welcomeMessage == this.welcomeMessage);
}

class TenantConfigsCompanion extends UpdateCompanion<TenantConfig> {
  final Value<String> tenantId;
  final Value<String?> logoPath;
  final Value<int?> primaryColor;
  final Value<int?> secondaryColor;
  final Value<String?> backgroundPath;
  final Value<String?> appName;
  final Value<String?> welcomeMessage;
  final Value<int> rowid;
  const TenantConfigsCompanion({
    this.tenantId = const Value.absent(),
    this.logoPath = const Value.absent(),
    this.primaryColor = const Value.absent(),
    this.secondaryColor = const Value.absent(),
    this.backgroundPath = const Value.absent(),
    this.appName = const Value.absent(),
    this.welcomeMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TenantConfigsCompanion.insert({
    required String tenantId,
    this.logoPath = const Value.absent(),
    this.primaryColor = const Value.absent(),
    this.secondaryColor = const Value.absent(),
    this.backgroundPath = const Value.absent(),
    this.appName = const Value.absent(),
    this.welcomeMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId);
  static Insertable<TenantConfig> custom({
    Expression<String>? tenantId,
    Expression<String>? logoPath,
    Expression<int>? primaryColor,
    Expression<int>? secondaryColor,
    Expression<String>? backgroundPath,
    Expression<String>? appName,
    Expression<String>? welcomeMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (logoPath != null) 'logo_path': logoPath,
      if (primaryColor != null) 'primary_color': primaryColor,
      if (secondaryColor != null) 'secondary_color': secondaryColor,
      if (backgroundPath != null) 'background_path': backgroundPath,
      if (appName != null) 'app_name': appName,
      if (welcomeMessage != null) 'welcome_message': welcomeMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TenantConfigsCompanion copyWith({
    Value<String>? tenantId,
    Value<String?>? logoPath,
    Value<int?>? primaryColor,
    Value<int?>? secondaryColor,
    Value<String?>? backgroundPath,
    Value<String?>? appName,
    Value<String?>? welcomeMessage,
    Value<int>? rowid,
  }) {
    return TenantConfigsCompanion(
      tenantId: tenantId ?? this.tenantId,
      logoPath: logoPath ?? this.logoPath,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundPath: backgroundPath ?? this.backgroundPath,
      appName: appName ?? this.appName,
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (logoPath.present) {
      map['logo_path'] = Variable<String>(logoPath.value);
    }
    if (primaryColor.present) {
      map['primary_color'] = Variable<int>(primaryColor.value);
    }
    if (secondaryColor.present) {
      map['secondary_color'] = Variable<int>(secondaryColor.value);
    }
    if (backgroundPath.present) {
      map['background_path'] = Variable<String>(backgroundPath.value);
    }
    if (appName.present) {
      map['app_name'] = Variable<String>(appName.value);
    }
    if (welcomeMessage.present) {
      map['welcome_message'] = Variable<String>(welcomeMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TenantConfigsCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('logoPath: $logoPath, ')
          ..write('primaryColor: $primaryColor, ')
          ..write('secondaryColor: $secondaryColor, ')
          ..write('backgroundPath: $backgroundPath, ')
          ..write('appName: $appName, ')
          ..write('welcomeMessage: $welcomeMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $OrdersTable orders = $OrdersTable(this);
  late final $OrderItemsTable orderItems = $OrderItemsTable(this);
  late final $AppConfigTable appConfig = $AppConfigTable(this);
  late final $WarehousesTable warehouses = $WarehousesTable(this);
  late final $BranchesTable branches = $BranchesTable(this);
  late final $TenantsTable tenants = $TenantsTable(this);
  late final $TiersTable tiers = $TiersTable(this);
  late final $CartItemsTable cartItems = $CartItemsTable(this);
  late final $TenantConfigsTable tenantConfigs = $TenantConfigsTable(this);
  late final ProductsDao productsDao = ProductsDao(this as AppDatabase);
  late final OrdersDao ordersDao = OrdersDao(this as AppDatabase);
  late final WarehousesDao warehousesDao = WarehousesDao(this as AppDatabase);
  late final TenantsDao tenantsDao = TenantsDao(this as AppDatabase);
  late final TiersDao tiersDao = TiersDao(this as AppDatabase);
  late final CartDao cartDao = CartDao(this as AppDatabase);
  late final TenantConfigDao tenantConfigDao = TenantConfigDao(
    this as AppDatabase,
  );
  late final BranchesDao branchesDao = BranchesDao(this as AppDatabase);
  late final AppConfigDao appConfigDao = AppConfigDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    products,
    orders,
    orderItems,
    appConfig,
    warehouses,
    branches,
    tenants,
    tiers,
    cartItems,
    tenantConfigs,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'orders',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('order_items', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ProductsTableCreateCompanionBuilder =
    ProductsCompanion Function({
      required String id,
      required String name,
      required String brand,
      required double price,
      required String category,
      Value<int> stockQuantity,
      Value<String?> imageUrl,
      Value<String?> tenantId,
      Value<String?> branchId,
      Value<String> size,
      Value<String> description,
      Value<int> rowid,
    });
typedef $$ProductsTableUpdateCompanionBuilder =
    ProductsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> brand,
      Value<double> price,
      Value<String> category,
      Value<int> stockQuantity,
      Value<String?> imageUrl,
      Value<String?> tenantId,
      Value<String?> branchId,
      Value<String> size,
      Value<String> description,
      Value<int> rowid,
    });

final class $$ProductsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductsTable, Product> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$OrderItemsTable, List<OrderItem>>
  _orderItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.orderItems,
    aliasName: $_aliasNameGenerator(db.products.id, db.orderItems.productId),
  );

  $$OrderItemsTableProcessedTableManager get orderItemsRefs {
    final manager = $$OrderItemsTableTableManager(
      $_db,
      $_db.orderItems,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_orderItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stockQuantity => $composableBuilder(
    column: $table.stockQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> orderItemsRefs(
    Expression<bool> Function($$OrderItemsTableFilterComposer f) f,
  ) {
    final $$OrderItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.orderItems,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrderItemsTableFilterComposer(
            $db: $db,
            $table: $db.orderItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stockQuantity => $composableBuilder(
    column: $table.stockQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get stockQuantity => $composableBuilder(
    column: $table.stockQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  Expression<T> orderItemsRefs<T extends Object>(
    Expression<T> Function($$OrderItemsTableAnnotationComposer a) f,
  ) {
    final $$OrderItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.orderItems,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrderItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.orderItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, $$ProductsTableReferences),
          Product,
          PrefetchHooks Function({bool orderItemsRefs})
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> brand = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> stockQuantity = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> tenantId = const Value.absent(),
                Value<String?> branchId = const Value.absent(),
                Value<String> size = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                name: name,
                brand: brand,
                price: price,
                category: category,
                stockQuantity: stockQuantity,
                imageUrl: imageUrl,
                tenantId: tenantId,
                branchId: branchId,
                size: size,
                description: description,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String brand,
                required double price,
                required String category,
                Value<int> stockQuantity = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> tenantId = const Value.absent(),
                Value<String?> branchId = const Value.absent(),
                Value<String> size = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                name: name,
                brand: brand,
                price: price,
                category: category,
                stockQuantity: stockQuantity,
                imageUrl: imageUrl,
                tenantId: tenantId,
                branchId: branchId,
                size: size,
                description: description,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProductsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({orderItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (orderItemsRefs) db.orderItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (orderItemsRefs)
                    await $_getPrefetchedData<
                      Product,
                      $ProductsTable,
                      OrderItem
                    >(
                      currentTable: table,
                      referencedTable: $$ProductsTableReferences
                          ._orderItemsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ProductsTableReferences(
                        db,
                        table,
                        p0,
                      ).orderItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.productId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, $$ProductsTableReferences),
      Product,
      PrefetchHooks Function({bool orderItemsRefs})
    >;
typedef $$OrdersTableCreateCompanionBuilder =
    OrdersCompanion Function({
      required String id,
      required double totalAmount,
      required String status,
      required DateTime createdAt,
      Value<String?> customerPhone,
      Value<String?> tenantId,
      Value<String?> branchId,
      Value<String?> terminalId,
      Value<int> rowid,
    });
typedef $$OrdersTableUpdateCompanionBuilder =
    OrdersCompanion Function({
      Value<String> id,
      Value<double> totalAmount,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<String?> customerPhone,
      Value<String?> tenantId,
      Value<String?> branchId,
      Value<String?> terminalId,
      Value<int> rowid,
    });

final class $$OrdersTableReferences
    extends BaseReferences<_$AppDatabase, $OrdersTable, Order> {
  $$OrdersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$OrderItemsTable, List<OrderItem>>
  _orderItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.orderItems,
    aliasName: $_aliasNameGenerator(db.orders.id, db.orderItems.orderId),
  );

  $$OrderItemsTableProcessedTableManager get orderItemsRefs {
    final manager = $$OrderItemsTableTableManager(
      $_db,
      $_db.orderItems,
    ).filter((f) => f.orderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_orderItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$OrdersTableFilterComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get terminalId => $composableBuilder(
    column: $table.terminalId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> orderItemsRefs(
    Expression<bool> Function($$OrderItemsTableFilterComposer f) f,
  ) {
    final $$OrderItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.orderItems,
      getReferencedColumn: (t) => t.orderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrderItemsTableFilterComposer(
            $db: $db,
            $table: $db.orderItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get terminalId => $composableBuilder(
    column: $table.terminalId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get terminalId => $composableBuilder(
    column: $table.terminalId,
    builder: (column) => column,
  );

  Expression<T> orderItemsRefs<T extends Object>(
    Expression<T> Function($$OrderItemsTableAnnotationComposer a) f,
  ) {
    final $$OrderItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.orderItems,
      getReferencedColumn: (t) => t.orderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrderItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.orderItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OrdersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrdersTable,
          Order,
          $$OrdersTableFilterComposer,
          $$OrdersTableOrderingComposer,
          $$OrdersTableAnnotationComposer,
          $$OrdersTableCreateCompanionBuilder,
          $$OrdersTableUpdateCompanionBuilder,
          (Order, $$OrdersTableReferences),
          Order,
          PrefetchHooks Function({bool orderItemsRefs})
        > {
  $$OrdersTableTableManager(_$AppDatabase db, $OrdersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> customerPhone = const Value.absent(),
                Value<String?> tenantId = const Value.absent(),
                Value<String?> branchId = const Value.absent(),
                Value<String?> terminalId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersCompanion(
                id: id,
                totalAmount: totalAmount,
                status: status,
                createdAt: createdAt,
                customerPhone: customerPhone,
                tenantId: tenantId,
                branchId: branchId,
                terminalId: terminalId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required double totalAmount,
                required String status,
                required DateTime createdAt,
                Value<String?> customerPhone = const Value.absent(),
                Value<String?> tenantId = const Value.absent(),
                Value<String?> branchId = const Value.absent(),
                Value<String?> terminalId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersCompanion.insert(
                id: id,
                totalAmount: totalAmount,
                status: status,
                createdAt: createdAt,
                customerPhone: customerPhone,
                tenantId: tenantId,
                branchId: branchId,
                terminalId: terminalId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$OrdersTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({orderItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (orderItemsRefs) db.orderItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (orderItemsRefs)
                    await $_getPrefetchedData<Order, $OrdersTable, OrderItem>(
                      currentTable: table,
                      referencedTable: $$OrdersTableReferences
                          ._orderItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$OrdersTableReferences(db, table, p0).orderItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.orderId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$OrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrdersTable,
      Order,
      $$OrdersTableFilterComposer,
      $$OrdersTableOrderingComposer,
      $$OrdersTableAnnotationComposer,
      $$OrdersTableCreateCompanionBuilder,
      $$OrdersTableUpdateCompanionBuilder,
      (Order, $$OrdersTableReferences),
      Order,
      PrefetchHooks Function({bool orderItemsRefs})
    >;
typedef $$OrderItemsTableCreateCompanionBuilder =
    OrderItemsCompanion Function({
      Value<int> id,
      required String orderId,
      required String productId,
      required int quantity,
      required double unitPrice,
      required String productName,
      Value<String?> productVariant,
      Value<String> status,
      Value<String> productCategory,
    });
typedef $$OrderItemsTableUpdateCompanionBuilder =
    OrderItemsCompanion Function({
      Value<int> id,
      Value<String> orderId,
      Value<String> productId,
      Value<int> quantity,
      Value<double> unitPrice,
      Value<String> productName,
      Value<String?> productVariant,
      Value<String> status,
      Value<String> productCategory,
    });

final class $$OrderItemsTableReferences
    extends BaseReferences<_$AppDatabase, $OrderItemsTable, OrderItem> {
  $$OrderItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $OrdersTable _orderIdTable(_$AppDatabase db) => db.orders.createAlias(
    $_aliasNameGenerator(db.orderItems.orderId, db.orders.id),
  );

  $$OrdersTableProcessedTableManager get orderId {
    final $_column = $_itemColumn<String>('order_id')!;

    final manager = $$OrdersTableTableManager(
      $_db,
      $_db.orders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias(
        $_aliasNameGenerator(db.orderItems.productId, db.products.id),
      );

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OrderItemsTableFilterComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productVariant => $composableBuilder(
    column: $table.productVariant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productCategory => $composableBuilder(
    column: $table.productCategory,
    builder: (column) => ColumnFilters(column),
  );

  $$OrdersTableFilterComposer get orderId {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableFilterComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrderItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productVariant => $composableBuilder(
    column: $table.productVariant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productCategory => $composableBuilder(
    column: $table.productCategory,
    builder: (column) => ColumnOrderings(column),
  );

  $$OrdersTableOrderingComposer get orderId {
    final $$OrdersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableOrderingComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrderItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productVariant => $composableBuilder(
    column: $table.productVariant,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get productCategory => $composableBuilder(
    column: $table.productCategory,
    builder: (column) => column,
  );

  $$OrdersTableAnnotationComposer get orderId {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableAnnotationComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrderItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrderItemsTable,
          OrderItem,
          $$OrderItemsTableFilterComposer,
          $$OrderItemsTableOrderingComposer,
          $$OrderItemsTableAnnotationComposer,
          $$OrderItemsTableCreateCompanionBuilder,
          $$OrderItemsTableUpdateCompanionBuilder,
          (OrderItem, $$OrderItemsTableReferences),
          OrderItem,
          PrefetchHooks Function({bool orderId, bool productId})
        > {
  $$OrderItemsTableTableManager(_$AppDatabase db, $OrderItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrderItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrderItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrderItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> orderId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String?> productVariant = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> productCategory = const Value.absent(),
              }) => OrderItemsCompanion(
                id: id,
                orderId: orderId,
                productId: productId,
                quantity: quantity,
                unitPrice: unitPrice,
                productName: productName,
                productVariant: productVariant,
                status: status,
                productCategory: productCategory,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String orderId,
                required String productId,
                required int quantity,
                required double unitPrice,
                required String productName,
                Value<String?> productVariant = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> productCategory = const Value.absent(),
              }) => OrderItemsCompanion.insert(
                id: id,
                orderId: orderId,
                productId: productId,
                quantity: quantity,
                unitPrice: unitPrice,
                productName: productName,
                productVariant: productVariant,
                status: status,
                productCategory: productCategory,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$OrderItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({orderId = false, productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (orderId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.orderId,
                                referencedTable: $$OrderItemsTableReferences
                                    ._orderIdTable(db),
                                referencedColumn: $$OrderItemsTableReferences
                                    ._orderIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable: $$OrderItemsTableReferences
                                    ._productIdTable(db),
                                referencedColumn: $$OrderItemsTableReferences
                                    ._productIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$OrderItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrderItemsTable,
      OrderItem,
      $$OrderItemsTableFilterComposer,
      $$OrderItemsTableOrderingComposer,
      $$OrderItemsTableAnnotationComposer,
      $$OrderItemsTableCreateCompanionBuilder,
      $$OrderItemsTableUpdateCompanionBuilder,
      (OrderItem, $$OrderItemsTableReferences),
      OrderItem,
      PrefetchHooks Function({bool orderId, bool productId})
    >;
typedef $$AppConfigTableCreateCompanionBuilder =
    AppConfigCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppConfigTableUpdateCompanionBuilder =
    AppConfigCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppConfigTableFilterComposer
    extends Composer<_$AppDatabase, $AppConfigTable> {
  $$AppConfigTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppConfigTableOrderingComposer
    extends Composer<_$AppDatabase, $AppConfigTable> {
  $$AppConfigTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppConfigTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppConfigTable> {
  $$AppConfigTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppConfigTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppConfigTable,
          AppConfigData,
          $$AppConfigTableFilterComposer,
          $$AppConfigTableOrderingComposer,
          $$AppConfigTableAnnotationComposer,
          $$AppConfigTableCreateCompanionBuilder,
          $$AppConfigTableUpdateCompanionBuilder,
          (
            AppConfigData,
            BaseReferences<_$AppDatabase, $AppConfigTable, AppConfigData>,
          ),
          AppConfigData,
          PrefetchHooks Function()
        > {
  $$AppConfigTableTableManager(_$AppDatabase db, $AppConfigTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppConfigTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppConfigTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppConfigTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppConfigCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppConfigCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppConfigTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppConfigTable,
      AppConfigData,
      $$AppConfigTableFilterComposer,
      $$AppConfigTableOrderingComposer,
      $$AppConfigTableAnnotationComposer,
      $$AppConfigTableCreateCompanionBuilder,
      $$AppConfigTableUpdateCompanionBuilder,
      (
        AppConfigData,
        BaseReferences<_$AppDatabase, $AppConfigTable, AppConfigData>,
      ),
      AppConfigData,
      PrefetchHooks Function()
    >;
typedef $$WarehousesTableCreateCompanionBuilder =
    WarehousesCompanion Function({
      required String id,
      Value<String?> tenantId,
      required String branchId,
      required String name,
      required String categories,
      required String loginUsername,
      required String loginPassword,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$WarehousesTableUpdateCompanionBuilder =
    WarehousesCompanion Function({
      Value<String> id,
      Value<String?> tenantId,
      Value<String> branchId,
      Value<String> name,
      Value<String> categories,
      Value<String> loginUsername,
      Value<String> loginPassword,
      Value<bool> isActive,
      Value<int> rowid,
    });

class $$WarehousesTableFilterComposer
    extends Composer<_$AppDatabase, $WarehousesTable> {
  $$WarehousesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loginUsername => $composableBuilder(
    column: $table.loginUsername,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loginPassword => $composableBuilder(
    column: $table.loginPassword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WarehousesTableOrderingComposer
    extends Composer<_$AppDatabase, $WarehousesTable> {
  $$WarehousesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loginUsername => $composableBuilder(
    column: $table.loginUsername,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loginPassword => $composableBuilder(
    column: $table.loginPassword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WarehousesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WarehousesTable> {
  $$WarehousesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => column,
  );

  GeneratedColumn<String> get loginUsername => $composableBuilder(
    column: $table.loginUsername,
    builder: (column) => column,
  );

  GeneratedColumn<String> get loginPassword => $composableBuilder(
    column: $table.loginPassword,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$WarehousesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WarehousesTable,
          Warehouse,
          $$WarehousesTableFilterComposer,
          $$WarehousesTableOrderingComposer,
          $$WarehousesTableAnnotationComposer,
          $$WarehousesTableCreateCompanionBuilder,
          $$WarehousesTableUpdateCompanionBuilder,
          (
            Warehouse,
            BaseReferences<_$AppDatabase, $WarehousesTable, Warehouse>,
          ),
          Warehouse,
          PrefetchHooks Function()
        > {
  $$WarehousesTableTableManager(_$AppDatabase db, $WarehousesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WarehousesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WarehousesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WarehousesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> tenantId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> categories = const Value.absent(),
                Value<String> loginUsername = const Value.absent(),
                Value<String> loginPassword = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WarehousesCompanion(
                id: id,
                tenantId: tenantId,
                branchId: branchId,
                name: name,
                categories: categories,
                loginUsername: loginUsername,
                loginPassword: loginPassword,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> tenantId = const Value.absent(),
                required String branchId,
                required String name,
                required String categories,
                required String loginUsername,
                required String loginPassword,
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WarehousesCompanion.insert(
                id: id,
                tenantId: tenantId,
                branchId: branchId,
                name: name,
                categories: categories,
                loginUsername: loginUsername,
                loginPassword: loginPassword,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WarehousesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WarehousesTable,
      Warehouse,
      $$WarehousesTableFilterComposer,
      $$WarehousesTableOrderingComposer,
      $$WarehousesTableAnnotationComposer,
      $$WarehousesTableCreateCompanionBuilder,
      $$WarehousesTableUpdateCompanionBuilder,
      (Warehouse, BaseReferences<_$AppDatabase, $WarehousesTable, Warehouse>),
      Warehouse,
      PrefetchHooks Function()
    >;
typedef $$BranchesTableCreateCompanionBuilder =
    BranchesCompanion Function({
      required String id,
      required String tenantId,
      required String name,
      required String location,
      required String contactPhone,
      required String managerName,
      required String loginUsername,
      required String loginPassword,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$BranchesTableUpdateCompanionBuilder =
    BranchesCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> name,
      Value<String> location,
      Value<String> contactPhone,
      Value<String> managerName,
      Value<String> loginUsername,
      Value<String> loginPassword,
      Value<bool> isActive,
      Value<int> rowid,
    });

class $$BranchesTableFilterComposer
    extends Composer<_$AppDatabase, $BranchesTable> {
  $$BranchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactPhone => $composableBuilder(
    column: $table.contactPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get managerName => $composableBuilder(
    column: $table.managerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loginUsername => $composableBuilder(
    column: $table.loginUsername,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loginPassword => $composableBuilder(
    column: $table.loginPassword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BranchesTableOrderingComposer
    extends Composer<_$AppDatabase, $BranchesTable> {
  $$BranchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactPhone => $composableBuilder(
    column: $table.contactPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get managerName => $composableBuilder(
    column: $table.managerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loginUsername => $composableBuilder(
    column: $table.loginUsername,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loginPassword => $composableBuilder(
    column: $table.loginPassword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BranchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BranchesTable> {
  $$BranchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get contactPhone => $composableBuilder(
    column: $table.contactPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get managerName => $composableBuilder(
    column: $table.managerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get loginUsername => $composableBuilder(
    column: $table.loginUsername,
    builder: (column) => column,
  );

  GeneratedColumn<String> get loginPassword => $composableBuilder(
    column: $table.loginPassword,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$BranchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BranchesTable,
          Branche,
          $$BranchesTableFilterComposer,
          $$BranchesTableOrderingComposer,
          $$BranchesTableAnnotationComposer,
          $$BranchesTableCreateCompanionBuilder,
          $$BranchesTableUpdateCompanionBuilder,
          (Branche, BaseReferences<_$AppDatabase, $BranchesTable, Branche>),
          Branche,
          PrefetchHooks Function()
        > {
  $$BranchesTableTableManager(_$AppDatabase db, $BranchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BranchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BranchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BranchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<String> contactPhone = const Value.absent(),
                Value<String> managerName = const Value.absent(),
                Value<String> loginUsername = const Value.absent(),
                Value<String> loginPassword = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BranchesCompanion(
                id: id,
                tenantId: tenantId,
                name: name,
                location: location,
                contactPhone: contactPhone,
                managerName: managerName,
                loginUsername: loginUsername,
                loginPassword: loginPassword,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                required String name,
                required String location,
                required String contactPhone,
                required String managerName,
                required String loginUsername,
                required String loginPassword,
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BranchesCompanion.insert(
                id: id,
                tenantId: tenantId,
                name: name,
                location: location,
                contactPhone: contactPhone,
                managerName: managerName,
                loginUsername: loginUsername,
                loginPassword: loginPassword,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BranchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BranchesTable,
      Branche,
      $$BranchesTableFilterComposer,
      $$BranchesTableOrderingComposer,
      $$BranchesTableAnnotationComposer,
      $$BranchesTableCreateCompanionBuilder,
      $$BranchesTableUpdateCompanionBuilder,
      (Branche, BaseReferences<_$AppDatabase, $BranchesTable, Branche>),
      Branche,
      PrefetchHooks Function()
    >;
typedef $$TenantsTableCreateCompanionBuilder =
    TenantsCompanion Function({
      required String id,
      required String name,
      required String businessName,
      required String email,
      required String phone,
      required String status,
      Value<String> tierId,
      required DateTime createdDate,
      Value<DateTime?> lastLogin,
      Value<int> ordersCount,
      Value<double> revenue,
      Value<bool> isMaintenanceMode,
      required String enabledFeatures,
      Value<bool?> allowUpdate,
      Value<bool?> immuneToBlocking,
      Value<int> rowid,
    });
typedef $$TenantsTableUpdateCompanionBuilder =
    TenantsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> businessName,
      Value<String> email,
      Value<String> phone,
      Value<String> status,
      Value<String> tierId,
      Value<DateTime> createdDate,
      Value<DateTime?> lastLogin,
      Value<int> ordersCount,
      Value<double> revenue,
      Value<bool> isMaintenanceMode,
      Value<String> enabledFeatures,
      Value<bool?> allowUpdate,
      Value<bool?> immuneToBlocking,
      Value<int> rowid,
    });

class $$TenantsTableFilterComposer
    extends Composer<_$AppDatabase, $TenantsTable> {
  $$TenantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tierId => $composableBuilder(
    column: $table.tierId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdDate => $composableBuilder(
    column: $table.createdDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastLogin => $composableBuilder(
    column: $table.lastLogin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordersCount => $composableBuilder(
    column: $table.ordersCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get revenue => $composableBuilder(
    column: $table.revenue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMaintenanceMode => $composableBuilder(
    column: $table.isMaintenanceMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enabledFeatures => $composableBuilder(
    column: $table.enabledFeatures,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allowUpdate => $composableBuilder(
    column: $table.allowUpdate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get immuneToBlocking => $composableBuilder(
    column: $table.immuneToBlocking,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TenantsTableOrderingComposer
    extends Composer<_$AppDatabase, $TenantsTable> {
  $$TenantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tierId => $composableBuilder(
    column: $table.tierId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdDate => $composableBuilder(
    column: $table.createdDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastLogin => $composableBuilder(
    column: $table.lastLogin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordersCount => $composableBuilder(
    column: $table.ordersCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get revenue => $composableBuilder(
    column: $table.revenue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMaintenanceMode => $composableBuilder(
    column: $table.isMaintenanceMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enabledFeatures => $composableBuilder(
    column: $table.enabledFeatures,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowUpdate => $composableBuilder(
    column: $table.allowUpdate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get immuneToBlocking => $composableBuilder(
    column: $table.immuneToBlocking,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TenantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TenantsTable> {
  $$TenantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get tierId =>
      $composableBuilder(column: $table.tierId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdDate => $composableBuilder(
    column: $table.createdDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastLogin =>
      $composableBuilder(column: $table.lastLogin, builder: (column) => column);

  GeneratedColumn<int> get ordersCount => $composableBuilder(
    column: $table.ordersCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get revenue =>
      $composableBuilder(column: $table.revenue, builder: (column) => column);

  GeneratedColumn<bool> get isMaintenanceMode => $composableBuilder(
    column: $table.isMaintenanceMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get enabledFeatures => $composableBuilder(
    column: $table.enabledFeatures,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get allowUpdate => $composableBuilder(
    column: $table.allowUpdate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get immuneToBlocking => $composableBuilder(
    column: $table.immuneToBlocking,
    builder: (column) => column,
  );
}

class $$TenantsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TenantsTable,
          Tenant,
          $$TenantsTableFilterComposer,
          $$TenantsTableOrderingComposer,
          $$TenantsTableAnnotationComposer,
          $$TenantsTableCreateCompanionBuilder,
          $$TenantsTableUpdateCompanionBuilder,
          (Tenant, BaseReferences<_$AppDatabase, $TenantsTable, Tenant>),
          Tenant,
          PrefetchHooks Function()
        > {
  $$TenantsTableTableManager(_$AppDatabase db, $TenantsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TenantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TenantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TenantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> businessName = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> tierId = const Value.absent(),
                Value<DateTime> createdDate = const Value.absent(),
                Value<DateTime?> lastLogin = const Value.absent(),
                Value<int> ordersCount = const Value.absent(),
                Value<double> revenue = const Value.absent(),
                Value<bool> isMaintenanceMode = const Value.absent(),
                Value<String> enabledFeatures = const Value.absent(),
                Value<bool?> allowUpdate = const Value.absent(),
                Value<bool?> immuneToBlocking = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TenantsCompanion(
                id: id,
                name: name,
                businessName: businessName,
                email: email,
                phone: phone,
                status: status,
                tierId: tierId,
                createdDate: createdDate,
                lastLogin: lastLogin,
                ordersCount: ordersCount,
                revenue: revenue,
                isMaintenanceMode: isMaintenanceMode,
                enabledFeatures: enabledFeatures,
                allowUpdate: allowUpdate,
                immuneToBlocking: immuneToBlocking,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String businessName,
                required String email,
                required String phone,
                required String status,
                Value<String> tierId = const Value.absent(),
                required DateTime createdDate,
                Value<DateTime?> lastLogin = const Value.absent(),
                Value<int> ordersCount = const Value.absent(),
                Value<double> revenue = const Value.absent(),
                Value<bool> isMaintenanceMode = const Value.absent(),
                required String enabledFeatures,
                Value<bool?> allowUpdate = const Value.absent(),
                Value<bool?> immuneToBlocking = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TenantsCompanion.insert(
                id: id,
                name: name,
                businessName: businessName,
                email: email,
                phone: phone,
                status: status,
                tierId: tierId,
                createdDate: createdDate,
                lastLogin: lastLogin,
                ordersCount: ordersCount,
                revenue: revenue,
                isMaintenanceMode: isMaintenanceMode,
                enabledFeatures: enabledFeatures,
                allowUpdate: allowUpdate,
                immuneToBlocking: immuneToBlocking,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TenantsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TenantsTable,
      Tenant,
      $$TenantsTableFilterComposer,
      $$TenantsTableOrderingComposer,
      $$TenantsTableAnnotationComposer,
      $$TenantsTableCreateCompanionBuilder,
      $$TenantsTableUpdateCompanionBuilder,
      (Tenant, BaseReferences<_$AppDatabase, $TenantsTable, Tenant>),
      Tenant,
      PrefetchHooks Function()
    >;
typedef $$TiersTableCreateCompanionBuilder =
    TiersCompanion Function({
      required String id,
      required String name,
      required String enabledFeatures,
      Value<bool> allowUpdates,
      Value<bool> immuneToBlocking,
      Value<String> description,
      Value<int> rowid,
    });
typedef $$TiersTableUpdateCompanionBuilder =
    TiersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> enabledFeatures,
      Value<bool> allowUpdates,
      Value<bool> immuneToBlocking,
      Value<String> description,
      Value<int> rowid,
    });

class $$TiersTableFilterComposer extends Composer<_$AppDatabase, $TiersTable> {
  $$TiersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enabledFeatures => $composableBuilder(
    column: $table.enabledFeatures,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allowUpdates => $composableBuilder(
    column: $table.allowUpdates,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get immuneToBlocking => $composableBuilder(
    column: $table.immuneToBlocking,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TiersTableOrderingComposer
    extends Composer<_$AppDatabase, $TiersTable> {
  $$TiersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enabledFeatures => $composableBuilder(
    column: $table.enabledFeatures,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowUpdates => $composableBuilder(
    column: $table.allowUpdates,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get immuneToBlocking => $composableBuilder(
    column: $table.immuneToBlocking,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TiersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TiersTable> {
  $$TiersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get enabledFeatures => $composableBuilder(
    column: $table.enabledFeatures,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get allowUpdates => $composableBuilder(
    column: $table.allowUpdates,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get immuneToBlocking => $composableBuilder(
    column: $table.immuneToBlocking,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );
}

class $$TiersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TiersTable,
          Tier,
          $$TiersTableFilterComposer,
          $$TiersTableOrderingComposer,
          $$TiersTableAnnotationComposer,
          $$TiersTableCreateCompanionBuilder,
          $$TiersTableUpdateCompanionBuilder,
          (Tier, BaseReferences<_$AppDatabase, $TiersTable, Tier>),
          Tier,
          PrefetchHooks Function()
        > {
  $$TiersTableTableManager(_$AppDatabase db, $TiersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TiersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TiersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TiersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> enabledFeatures = const Value.absent(),
                Value<bool> allowUpdates = const Value.absent(),
                Value<bool> immuneToBlocking = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TiersCompanion(
                id: id,
                name: name,
                enabledFeatures: enabledFeatures,
                allowUpdates: allowUpdates,
                immuneToBlocking: immuneToBlocking,
                description: description,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String enabledFeatures,
                Value<bool> allowUpdates = const Value.absent(),
                Value<bool> immuneToBlocking = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TiersCompanion.insert(
                id: id,
                name: name,
                enabledFeatures: enabledFeatures,
                allowUpdates: allowUpdates,
                immuneToBlocking: immuneToBlocking,
                description: description,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TiersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TiersTable,
      Tier,
      $$TiersTableFilterComposer,
      $$TiersTableOrderingComposer,
      $$TiersTableAnnotationComposer,
      $$TiersTableCreateCompanionBuilder,
      $$TiersTableUpdateCompanionBuilder,
      (Tier, BaseReferences<_$AppDatabase, $TiersTable, Tier>),
      Tier,
      PrefetchHooks Function()
    >;
typedef $$CartItemsTableCreateCompanionBuilder =
    CartItemsCompanion Function({
      Value<int> id,
      required String productId,
      required int quantity,
      Value<String?> tenantId,
      Value<String?> productName,
      Value<double?> productPrice,
      Value<String?> productImage,
    });
typedef $$CartItemsTableUpdateCompanionBuilder =
    CartItemsCompanion Function({
      Value<int> id,
      Value<String> productId,
      Value<int> quantity,
      Value<String?> tenantId,
      Value<String?> productName,
      Value<double?> productPrice,
      Value<String?> productImage,
    });

class $$CartItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CartItemsTable> {
  $$CartItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get productPrice => $composableBuilder(
    column: $table.productPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productImage => $composableBuilder(
    column: $table.productImage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CartItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CartItemsTable> {
  $$CartItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get productPrice => $composableBuilder(
    column: $table.productPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productImage => $composableBuilder(
    column: $table.productImage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CartItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CartItemsTable> {
  $$CartItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get productPrice => $composableBuilder(
    column: $table.productPrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productImage => $composableBuilder(
    column: $table.productImage,
    builder: (column) => column,
  );
}

class $$CartItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CartItemsTable,
          CartItem,
          $$CartItemsTableFilterComposer,
          $$CartItemsTableOrderingComposer,
          $$CartItemsTableAnnotationComposer,
          $$CartItemsTableCreateCompanionBuilder,
          $$CartItemsTableUpdateCompanionBuilder,
          (CartItem, BaseReferences<_$AppDatabase, $CartItemsTable, CartItem>),
          CartItem,
          PrefetchHooks Function()
        > {
  $$CartItemsTableTableManager(_$AppDatabase db, $CartItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CartItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CartItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CartItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String?> tenantId = const Value.absent(),
                Value<String?> productName = const Value.absent(),
                Value<double?> productPrice = const Value.absent(),
                Value<String?> productImage = const Value.absent(),
              }) => CartItemsCompanion(
                id: id,
                productId: productId,
                quantity: quantity,
                tenantId: tenantId,
                productName: productName,
                productPrice: productPrice,
                productImage: productImage,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String productId,
                required int quantity,
                Value<String?> tenantId = const Value.absent(),
                Value<String?> productName = const Value.absent(),
                Value<double?> productPrice = const Value.absent(),
                Value<String?> productImage = const Value.absent(),
              }) => CartItemsCompanion.insert(
                id: id,
                productId: productId,
                quantity: quantity,
                tenantId: tenantId,
                productName: productName,
                productPrice: productPrice,
                productImage: productImage,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CartItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CartItemsTable,
      CartItem,
      $$CartItemsTableFilterComposer,
      $$CartItemsTableOrderingComposer,
      $$CartItemsTableAnnotationComposer,
      $$CartItemsTableCreateCompanionBuilder,
      $$CartItemsTableUpdateCompanionBuilder,
      (CartItem, BaseReferences<_$AppDatabase, $CartItemsTable, CartItem>),
      CartItem,
      PrefetchHooks Function()
    >;
typedef $$TenantConfigsTableCreateCompanionBuilder =
    TenantConfigsCompanion Function({
      required String tenantId,
      Value<String?> logoPath,
      Value<int?> primaryColor,
      Value<int?> secondaryColor,
      Value<String?> backgroundPath,
      Value<String?> appName,
      Value<String?> welcomeMessage,
      Value<int> rowid,
    });
typedef $$TenantConfigsTableUpdateCompanionBuilder =
    TenantConfigsCompanion Function({
      Value<String> tenantId,
      Value<String?> logoPath,
      Value<int?> primaryColor,
      Value<int?> secondaryColor,
      Value<String?> backgroundPath,
      Value<String?> appName,
      Value<String?> welcomeMessage,
      Value<int> rowid,
    });

class $$TenantConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $TenantConfigsTable> {
  $$TenantConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logoPath => $composableBuilder(
    column: $table.logoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get primaryColor => $composableBuilder(
    column: $table.primaryColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get secondaryColor => $composableBuilder(
    column: $table.secondaryColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backgroundPath => $composableBuilder(
    column: $table.backgroundPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get welcomeMessage => $composableBuilder(
    column: $table.welcomeMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TenantConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $TenantConfigsTable> {
  $$TenantConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logoPath => $composableBuilder(
    column: $table.logoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get primaryColor => $composableBuilder(
    column: $table.primaryColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get secondaryColor => $composableBuilder(
    column: $table.secondaryColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backgroundPath => $composableBuilder(
    column: $table.backgroundPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get welcomeMessage => $composableBuilder(
    column: $table.welcomeMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TenantConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TenantConfigsTable> {
  $$TenantConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get logoPath =>
      $composableBuilder(column: $table.logoPath, builder: (column) => column);

  GeneratedColumn<int> get primaryColor => $composableBuilder(
    column: $table.primaryColor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get secondaryColor => $composableBuilder(
    column: $table.secondaryColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backgroundPath => $composableBuilder(
    column: $table.backgroundPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appName =>
      $composableBuilder(column: $table.appName, builder: (column) => column);

  GeneratedColumn<String> get welcomeMessage => $composableBuilder(
    column: $table.welcomeMessage,
    builder: (column) => column,
  );
}

class $$TenantConfigsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TenantConfigsTable,
          TenantConfig,
          $$TenantConfigsTableFilterComposer,
          $$TenantConfigsTableOrderingComposer,
          $$TenantConfigsTableAnnotationComposer,
          $$TenantConfigsTableCreateCompanionBuilder,
          $$TenantConfigsTableUpdateCompanionBuilder,
          (
            TenantConfig,
            BaseReferences<_$AppDatabase, $TenantConfigsTable, TenantConfig>,
          ),
          TenantConfig,
          PrefetchHooks Function()
        > {
  $$TenantConfigsTableTableManager(_$AppDatabase db, $TenantConfigsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TenantConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TenantConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TenantConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String?> logoPath = const Value.absent(),
                Value<int?> primaryColor = const Value.absent(),
                Value<int?> secondaryColor = const Value.absent(),
                Value<String?> backgroundPath = const Value.absent(),
                Value<String?> appName = const Value.absent(),
                Value<String?> welcomeMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TenantConfigsCompanion(
                tenantId: tenantId,
                logoPath: logoPath,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                backgroundPath: backgroundPath,
                appName: appName,
                welcomeMessage: welcomeMessage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                Value<String?> logoPath = const Value.absent(),
                Value<int?> primaryColor = const Value.absent(),
                Value<int?> secondaryColor = const Value.absent(),
                Value<String?> backgroundPath = const Value.absent(),
                Value<String?> appName = const Value.absent(),
                Value<String?> welcomeMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TenantConfigsCompanion.insert(
                tenantId: tenantId,
                logoPath: logoPath,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                backgroundPath: backgroundPath,
                appName: appName,
                welcomeMessage: welcomeMessage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TenantConfigsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TenantConfigsTable,
      TenantConfig,
      $$TenantConfigsTableFilterComposer,
      $$TenantConfigsTableOrderingComposer,
      $$TenantConfigsTableAnnotationComposer,
      $$TenantConfigsTableCreateCompanionBuilder,
      $$TenantConfigsTableUpdateCompanionBuilder,
      (
        TenantConfig,
        BaseReferences<_$AppDatabase, $TenantConfigsTable, TenantConfig>,
      ),
      TenantConfig,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db, _db.orders);
  $$OrderItemsTableTableManager get orderItems =>
      $$OrderItemsTableTableManager(_db, _db.orderItems);
  $$AppConfigTableTableManager get appConfig =>
      $$AppConfigTableTableManager(_db, _db.appConfig);
  $$WarehousesTableTableManager get warehouses =>
      $$WarehousesTableTableManager(_db, _db.warehouses);
  $$BranchesTableTableManager get branches =>
      $$BranchesTableTableManager(_db, _db.branches);
  $$TenantsTableTableManager get tenants =>
      $$TenantsTableTableManager(_db, _db.tenants);
  $$TiersTableTableManager get tiers =>
      $$TiersTableTableManager(_db, _db.tiers);
  $$CartItemsTableTableManager get cartItems =>
      $$CartItemsTableTableManager(_db, _db.cartItems);
  $$TenantConfigsTableTableManager get tenantConfigs =>
      $$TenantConfigsTableTableManager(_db, _db.tenantConfigs);
}
