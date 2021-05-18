class Setting < ApplicationRecord
  belongs_to :user, optional: false
  has_many :setting_posts, dependent: :destroy, inverse_of: :tag
  has_many :posts, through: :setting_posts, dependent: :destroy
  has_many :setting_characters, dependent: :destroy, inverse_of: :tag
  has_many :characters, through: :setting_characters, dependent: :destroy

  has_many :parent_setting_tags, class_name: 'Setting::SettingTag', foreign_key: :tag_id, inverse_of: :parent_setting, dependent: :destroy
  has_many :child_setting_tags, class_name: 'Setting::SettingTag', foreign_key: :tagged_id, inverse_of: :child_setting, dependent: :destroy

  has_many :parent_settings, -> { ordered_by_tag_tag }, class_name: 'Setting', through: :child_setting_tags,
    source: :parent_setting, dependent: :destroy
  has_many :child_settings, class_name: 'Setting', through: :parent_setting_tags, source: :child_setting, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  scope :ordered_by_name, -> { order(name: :asc) }

  scope :ordered_by_id, -> { order(id: :asc) }

  scope :ordered_by_char_tag, -> { order('character_setting.id ASC') }

  scope :ordered_by_post_tag, -> { order('post_setting.id ASC') }

  scope :ordered_by_tag_tag, -> { order('tag_tags.id ASC') }

  scope :with_character_counts, -> {
    # rubocop:disable Style/TrailingCommaInArguments
    select(
      <<~SQL
        (
          SELECT COUNT(DISTINCT setting_characters.character_id)
          FROM setting_characters
          WHERE setting_characters.tag_id = settings.id
        )
        AS character_count
      SQL
    )
    # rubocop:enable Style/TrailingCommaInArguments
  }

  def editable_by?(user)
    return false unless user
    return true if deletable_by?(user)
    return true if user.has_permission?(:edit_tags)
    return false unless is_a?(Setting)
    !owned?
  end

  def deletable_by?(user)
    return false unless user
    return true if user.has_permission?(:delete_tags)
    user.id == user_id
  end

  def as_json(options={})
    tag_json = {id: self.id, text: self.name}
    return tag_json unless options[:include].present?
    if options[:include].include?(:gallery_ids)
      g_tags = gallery_tags.joins(:gallery)
      g_tags = g_tags.where(galleries: {user_id: options[:user_id]}) if options[:user_id].present?
      tag_json[:gallery_ids] = g_tags.pluck(:gallery_id)
    end
    tag_json
  end

  def id_for_select
    return id if persisted? # id present on unpersisted records when associated record is invalid
    "_#{name}"
  end

  def post_count
    return read_attribute(:post_count) if has_attribute?(:post_count)
    posts.count
  end

  def character_count
    return read_attribute(:character_count) if has_attribute?(:character_count)
    characters.count
  end

  def merge_with(other_tag)
    transaction do
      # rubocop:disable Rails/SkipsModelValidations
      PostTag.where(tag_id: other_tag.id).where(post_id: post_tags.select(:post_id).distinct.pluck(:post_id)).delete_all
      PostTag.where(tag_id: other_tag.id).update_all(tag_id: self.id)
      CharacterTag.where(tag_id: other_tag.id).where(character_id: character_tags.select(:character_id).distinct.pluck(:character_id)).delete_all
      CharacterTag.where(tag_id: other_tag.id).update_all(tag_id: self.id)
      Setting::SettingTag.where(tag_id: other_tag.id, tagged_id: self.id).delete_all
      Setting::SettingTag.where(tag_id: self.id, tagged_id: other_tag.id).delete_all
      Setting::SettingTag.where(tag_id: other_tag.id).update_all(tag_id: self.id)
      Setting::SettingTag.where(tagged_id: other_tag.id).update_all(tagged_id: self.id)
      other_tag.destroy!
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
