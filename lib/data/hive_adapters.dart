import 'package:hive/hive.dart';

import '../models/expense.dart';
import '../models/exchange_rate.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../models/payment.dart';

void registerHiveAdapters() {
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(MemberAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(GroupAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(ExpenseAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(ExchangeRateAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(PaymentAdapter());
  }
}

class MemberAdapter extends TypeAdapter<Member> {
  @override
  final int typeId = 0;

  @override
  Member read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    return Member(id: id, name: name);
  }

  @override
  void write(BinaryWriter writer, Member obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
  }
}

class GroupAdapter extends TypeAdapter<Group> {
  @override
  final int typeId = 1;

  @override
  Group read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final members = reader.readList().cast<Member>();
    return Group(id: id, name: name, members: members);
  }

  @override
  void write(BinaryWriter writer, Group obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeList(obj.members);
  }
}

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 2;

  @override
  Expense read(BinaryReader reader) {
    final id = reader.readString();
    final groupId = reader.readString();
    final title = reader.readString();
    final amountEur = reader.readDouble();
    final payerMemberId = reader.readString();
    final participantIds = reader.readList().cast<String>();
    final date = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final hasUsd = reader.readBool();
    final convertedAmountUsd = hasUsd ? reader.readDouble() : null;
    // Handle legacy extra data by skipping it if present, while keeping the planned flag.
    var isPlanned = false;
    if (reader.availableBytes > 0) {
      final legacyFlag = reader.readBool();
      if (reader.availableBytes > 0) {
        // Older entries stored an extra identifier after the flag; skip the string if it exists.
        if (legacyFlag && reader.availableBytes > 0) {
          reader.readString();
        }
        if (reader.availableBytes > 0) {
          isPlanned = reader.readBool();
        }
      } else {
        // Newer entries store the planned flag directly.
        isPlanned = legacyFlag;
      }
    }
    return Expense(
      id: id,
      groupId: groupId,
      title: title,
      amountEur: amountEur,
      payerMemberId: payerMemberId,
      participantIds: participantIds,
      date: date,
      convertedAmountUsd: convertedAmountUsd,
      isPlanned: isPlanned,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.groupId);
    writer.writeString(obj.title);
    writer.writeDouble(obj.amountEur);
    writer.writeString(obj.payerMemberId);
    writer.writeList(obj.participantIds);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeBool(obj.convertedAmountUsd != null);
    if (obj.convertedAmountUsd != null) {
      writer.writeDouble(obj.convertedAmountUsd!);
    }
    writer.writeBool(obj.isPlanned);
  }
}

class ExchangeRateAdapter extends TypeAdapter<ExchangeRate> {
  @override
  final int typeId = 3;

  @override
  ExchangeRate read(BinaryReader reader) {
    final rate = reader.readDouble();
    final fetchedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    return ExchangeRate(rate: rate, fetchedAt: fetchedAt);
  }

  @override
  void write(BinaryWriter writer, ExchangeRate obj) {
    writer.writeDouble(obj.rate);
    writer.writeInt(obj.fetchedAt.millisecondsSinceEpoch);
  }
}

class PaymentAdapter extends TypeAdapter<Payment> {
  @override
  final int typeId = 4;

  @override
  Payment read(BinaryReader reader) {
    final id = reader.readString();
    final groupId = reader.readString();
    final fromMemberId = reader.readString();
    final toMemberId = reader.readString();
    final amountEur = reader.readDouble();
    final date = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    return Payment(
      id: id,
      groupId: groupId,
      fromMemberId: fromMemberId,
      toMemberId: toMemberId,
      amountEur: amountEur,
      date: date,
    );
  }

  @override
  void write(BinaryWriter writer, Payment obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.groupId);
    writer.writeString(obj.fromMemberId);
    writer.writeString(obj.toMemberId);
    writer.writeDouble(obj.amountEur);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
  }
}

// ActivityLog adapter removed
