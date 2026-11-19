enum PromisionStatus { error, granted, checking }

class PromisionState {
  const PromisionState({
    this.status = PromisionStatus.checking,
    this.message,
    this.country,
    this.city,
  });

  final PromisionStatus status;

  final String? message;

  final String? country;

  final String? city;

  PromisionState copyWith({
    PromisionStatus? status,
    String? message,
    String? country,
    String? city,
  }) {
    return PromisionState(
      status: status ?? this.status,
      message: message ?? this.message,
      country: country ?? this.country,
      city: city ?? this.city,
    );
  }
}
