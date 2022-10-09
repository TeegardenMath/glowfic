class Template < ApplicationRecord
  include Presentable

  belongs_to :user, inverse_of: :templates, optional: false
  has_many :characters, -> { ordered }, inverse_of: :template, dependent: :nullify
  has_one :template_tag, class_name: 'Tag::TemplateTag', dependent: :destroy, inverse_of: :template
  has_one :character_group, through: :template_tag, dependent: :destroy

  validates :name, presence: true

  scope :ordered, -> { order(name: :asc, created_at: :asc, id: :asc) }

  CHAR_PLUCK = Arel.sql("id, concat_ws(' | ', name, nickname, screenname)")
  NPC_PLUCK = Arel.sql("id, concat_ws(' | ', name, nickname)")

  def plucked_characters
    characters.non_npcs.where(retired: false).pluck(CHAR_PLUCK)
  end
end
