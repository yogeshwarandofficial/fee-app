/// Student domain model — mirrors the MongoDB Student document.
///
/// All numeric fields default to 0 so the UI never encounters null/NaN.
class BalanceBucket {
  const BalanceBucket({this.paid = 0, this.due = 0});

  final num paid;
  final num due;

  factory BalanceBucket.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BalanceBucket();
    return BalanceBucket(
      paid: (json['paid'] as num?) ?? 0,
      due:  (json['due']  as num?) ?? 0,
    );
  }
}

class StudentBalances {
  const StudentBalances({
    this.tuition   = const BalanceBucket(),
    this.transport = const BalanceBucket(),
    this.other     = const BalanceBucket(),
  });

  final BalanceBucket tuition;
  final BalanceBucket transport;
  final BalanceBucket other;

  factory StudentBalances.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const StudentBalances();
    return StudentBalances(
      tuition:   BalanceBucket.fromJson(json['tuition']   as Map<String, dynamic>?),
      transport: BalanceBucket.fromJson(json['transport'] as Map<String, dynamic>?),
      other:     BalanceBucket.fromJson(json['other']     as Map<String, dynamic>?),
    );
  }

  num get totalPaid => tuition.paid + transport.paid + other.paid;
  num get totalDue  => tuition.due  + transport.due  + other.due;
}

class CustomFee {
  const CustomFee({
    required this.feeDescription,
    required this.amount,
    required this.status,
  });

  final String feeDescription;
  final num    amount;
  final String status;

  factory CustomFee.fromJson(Map<String, dynamic> json) {
    return CustomFee(
      feeDescription: (json['fee_description'] as String?) ?? '',
      amount:         (json['amount']          as num?)    ?? 0,
      status:         (json['status']          as String?) ?? 'pending',
    );
  }
}

class Student {
  const Student({
    required this.id,
    required this.studentId,
    required this.fullName,
    required this.gradeId,
    required this.gradeName,
    required this.sectionId,
    required this.sectionName,
    required this.phoneNumber,
    this.avatarUrl,
    this.transportRouteId,
    this.transportRouteName,
    required this.balances,
    required this.customFees,
    required this.status,
  });

  final String         id;
  final String         studentId;
  final String         fullName;
  final String         gradeId;
  final String         gradeName;
  final String         sectionId;
  final String         sectionName;
  final String         phoneNumber;
  final String?        avatarUrl;
  final String?        transportRouteId;
  final String?        transportRouteName;
  final StudentBalances balances;
  final List<CustomFee> customFees;
  final String         status; // "cleared" | "pending"

  bool get isCleared => status == 'cleared';

  factory Student.fromJson(Map<String, dynamic> json) {
    // grade_id can be a populated object OR a raw string ObjectId
    String gradeId   = '';
    String gradeName = '';
    final gradeRaw = json['grade_id'];
    if (gradeRaw is Map<String, dynamic>) {
      gradeId   = (gradeRaw['_id']  as String?) ?? '';
      gradeName = (gradeRaw['name'] as String?) ?? '';
    } else if (gradeRaw is String) {
      gradeId = gradeRaw;
    }

    String sectionId   = '';
    String sectionName = '';
    final sectionRaw = json['section_id'];
    if (sectionRaw is Map<String, dynamic>) {
      sectionId   = (sectionRaw['_id']  as String?) ?? '';
      sectionName = (sectionRaw['name'] as String?) ?? '';
    } else if (sectionRaw is String) {
      sectionId = sectionRaw;
    }

    String? routeId;
    String? routeName;
    final routeRaw = json['transport_route_id'];
    if (routeRaw is Map<String, dynamic>) {
      routeId   = (routeRaw['_id']  as String?);
      routeName = (routeRaw['name'] as String?);
    } else if (routeRaw is String) {
      routeId = routeRaw;
    }

    return Student(
      id:                 (json['_id']          as String?) ?? '',
      studentId:          (json['student_id']   as String?) ?? '',
      fullName:           (json['full_name']    as String?) ?? '',
      gradeId:            gradeId,
      gradeName:          gradeName,
      sectionId:          sectionId,
      sectionName:        sectionName,
      phoneNumber:        (json['phone_number'] as String?) ?? '',
      avatarUrl:          json['avatar_url']    as String?,
      transportRouteId:   routeId,
      transportRouteName: routeName,
      balances:           StudentBalances.fromJson(json['balances'] as Map<String, dynamic>?),
      customFees:         ((json['custom_fees'] as List<dynamic>?) ?? [])
                              .map((e) => CustomFee.fromJson(e as Map<String, dynamic>))
                              .toList(),
      status:             (json['status'] as String?) ?? 'pending',
    );
  }
}

class Transaction {
  const Transaction({
    required this.transactionId,
    required this.feeCategory,
    required this.amountCollected,
    required this.timestamp,
  });

  final String   transactionId;
  final String   feeCategory;
  final num      amountCollected;
  final DateTime timestamp;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      transactionId:    (json['transaction_id']   as String?) ?? '',
      feeCategory:      (json['fee_category']     as String?) ?? '',
      amountCollected:  (json['amount_collected'] as num?)    ?? 0,
      timestamp:        json['timestamp'] != null
                          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
                          : DateTime.now(),
    );
  }
}

class PaginatedStudents {
  const PaginatedStudents({
    required this.students,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final List<Student> students;
  final int           total;
  final int           page;
  final int           limit;
  final int           totalPages;

  factory PaginatedStudents.fromJson(Map<String, dynamic> json) {
    final data       = json['data']       as Map<String, dynamic>? ?? {};
    final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
    return PaginatedStudents(
      students:   ((data['students'] as List<dynamic>?) ?? [])
                      .map((e) => Student.fromJson(e as Map<String, dynamic>))
                      .toList(),
      total:      (pagination['total']      as int?) ?? 0,
      page:       (pagination['page']       as int?) ?? 1,
      limit:      (pagination['limit']      as int?) ?? 20,
      totalPages: (pagination['totalPages'] as int?) ?? 1,
    );
  }
}
