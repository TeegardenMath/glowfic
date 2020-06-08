module Tag::Taggable::GalleryGroup
  extend ActiveSupport::Concern

  included do
    include Tag::Taggable

    define_attribute_method :gallery_group_list

    after_save :save_gallery_group_tags

    def gallery_group_list
      @gallery_group_list ||= Tag::List.new(gallery_groups.map(&:name))
    end

    def gallery_group_list=(list)
      list = Tag::List.new(list)
      gallery_group_list_will_change! unless list == gallery_group_list
      @gallery_group_list = list
    end

    def save_gallery_group_tags
      return unless gallery_group_list_changed?
      save_tags(::GalleryGroup, @gallery_group_list, gallery_group_list_was)
    end
  end
end
