
import 'package:ai_therapy_teteocan/data/models/bank_info_model.dart';

abstract class BankInfoEvent {
  const BankInfoEvent();
}

class LoadBankInfo extends BankInfoEvent {
  final String psychologistId;
  const LoadBankInfo(this.psychologistId);
}

class SaveBankInfo extends BankInfoEvent {
  final BankInfoModel bankInfo;
  const SaveBankInfo(this.bankInfo);
}

class UpdateBankInfo extends BankInfoEvent {
  final BankInfoModel bankInfo;
  const UpdateBankInfo(this.bankInfo);
}

class LoadPaymentHistory extends BankInfoEvent {
  final String psychologistId;
  final String? status; // 'completed', 'pending', null (todos)
  const LoadPaymentHistory(this.psychologistId, {this.status});
}

class FilterPayments extends BankInfoEvent {
  final String? status;
  const FilterPayments(this.status);
}