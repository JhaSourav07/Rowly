sealed class Failure {
  final String message;
  const Failure(this.message);
}

class FileAccessFailure extends Failure {
  const FileAccessFailure(super.message);
}

class ParseFailure extends Failure {
  const ParseFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}