# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `DeleteIconFromS3Job`.
# Please instead update this file by running `bin/tapioca dsl DeleteIconFromS3Job`.

class DeleteIconFromS3Job
  class << self
    sig { params(s3_key: T.untyped).returns(T.any(DeleteIconFromS3Job, FalseClass)) }
    def perform_later(s3_key); end

    sig { params(s3_key: T.untyped).returns(T.untyped) }
    def perform_now(s3_key); end
  end
end
