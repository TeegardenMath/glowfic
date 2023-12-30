# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `GenerateFlatPostJob`.
# Please instead update this file by running `bin/tapioca dsl GenerateFlatPostJob`.

class GenerateFlatPostJob
  class << self
    sig do
      params(
        post_id: T.untyped,
        block: T.nilable(T.proc.params(job: GenerateFlatPostJob).void)
      ).returns(T.any(GenerateFlatPostJob, FalseClass))
    end
    def perform_later(post_id, &block); end

    sig { params(post_id: T.untyped).returns(T.untyped) }
    def perform_now(post_id); end
  end
end
