class Icon < ActiveRecord::Base
  include Presentable

  S3_DOMAIN = '.s3.amazonaws.com'

  belongs_to :user
  has_many :posts
  has_many :replies
  has_many :reply_drafts
  has_and_belongs_to_many :galleries

  validates_presence_of :url, :user, :keyword
  validate :url_is_url
  validate :uploaded_url_not_in_use
  nilify_blanks types: [:string, :text, :citext] # nilify_blanks does not touch citext by default

  before_validation :use_icon_host
  before_update :delete_from_s3
  after_destroy :clear_icon_ids, :delete_from_s3

  def uploaded?
    s3_key.present?
  end

  private

  def url_is_url
    return true if url.to_s.starts_with?('http://') || url.to_s.starts_with?('https://')
    self.url = url_was unless new_record?
    errors.add(:url, "must be an actual fully qualified url (http://www.example.com)")
  end

  def use_icon_host
    return unless uploaded?
    return unless ENV['ICON_HOST'].present?
    return if url.to_s.include?(ENV['ICON_HOST'])
    self.url = ENV['ICON_HOST'] + url[(url.index(S3_DOMAIN).to_i + S3_DOMAIN.length)..-1]
  end

  def delete_from_s3
    return unless destroyed? || s3_key_changed?
    return unless s3_key_was.present?
    Rails.logger.info("Deleting S3 object: #{s3_key_was}")
    S3_BUCKET.delete_objects(delete: {objects: [{key: s3_key_was}], quiet: true})
  end

  def uploaded_url_not_in_use
    return unless uploaded?
    check = Icon.where(s3_key: s3_key)
    check = check.where('id != ?', id) unless new_record?
    return unless check.exists?
    self.url = url_was
    self.s3_key = s3_key_was
    errors.add(:url, 'has already been taken')
  end

  def clear_icon_ids
    Reply.where(icon_id: id).update_all(icon_id: nil)
    Post.where(icon_id: id).update_all(icon_id: nil)
    ReplyDraft.where(icon_id: id).update_all(icon_id: nil)
    User.where(avatar_id: id).update_all(avatar_id: nil)
  end

  class UploadError < Exception
  end
end
