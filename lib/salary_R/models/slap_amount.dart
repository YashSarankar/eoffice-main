class SlapAmount {
  final String value;
  final List<GradeAmount> gradeAmounts;

  SlapAmount({required this.value, required this.gradeAmounts});
}

class GradeAmount {
  final String value;
  final String directAddSalary;
  final String mergedAmount;
  final String directAddTotalSalary;
  final String level;
  final List<String> salaryAmountOptions;

  GradeAmount({
    required this.value,
    required this.directAddSalary,
    required this.mergedAmount,
    required this.directAddTotalSalary,
    required this.level,
    required this.salaryAmountOptions,
  });
}
