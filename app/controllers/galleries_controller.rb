# frozen_string_literal: true
class GalleriesController < UploadingController
  include Taggable

  before_action :login_required, except: [:index, :show, :search]
  before_action :find_model, only: [:destroy, :edit, :update]
  before_action :require_edit_permission, only: [:edit, :update, :destroy]
  before_action :require_create_permission, only: [:new, :create, :add, :icon]
  before_action :find_user, only: [:index]
  before_action :require_own_gallery, only: [:add, :icon]
  before_action :setup_new_icons, only: [:add, :icon]
  before_action :set_s3_url, only: [:edit, :add, :icon]
  before_action :editor_setup, only: [:new, :edit]

  def index
    @page_title = if @user.id == current_user.try(:id)
      "Your Galleries"
    else
      @user.username + "'s Galleries"
    end
    use_javascript('galleries/expander')
    gon.user_id = @user.id
  end

  def new
    @page_title = 'New Gallery'
    @gallery = Gallery.new
  end

  def create
    @gallery = Gallery.new(permitted_params)
    @gallery.user = current_user
    @gallery.gallery_groups = process_tags(GalleryGroup, obj_param: :gallery, id_param: :gallery_group_ids)

    begin
      @gallery.save!
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = {
        message: "Your gallery could not be saved because of the following problems:",
        array: @gallery.errors.full_messages,
      }
      @page_title = 'New Gallery'
      editor_setup
      render :new
    else
      flash[:success] = "Gallery saved successfully."
      redirect_to @gallery
    end
  end

  def add
    if params[:id] == '0' && params[:type] == 'existing'
      flash[:error] = 'Cannot add existing icons to galleryless. Please remove from existing galleries instead.'
      redirect_to user_gallery_path(id: 0, user_id: current_user.id)
    end
  end

  def show
    if params[:id].to_s == '0' # avoids casting nils to 0
      return unless find_user
      @page_title = 'Galleryless Icons'
    else
      return unless find_model
      @user = @gallery.user
      @page_title = @gallery.name + ' (Gallery)'
      @meta_og = og_data
    end
    icons = @gallery ? @gallery.icons : @user.galleryless_icons
    if page_view == 'list'
      posts = Post.visible_to(current_user).where(icon_id: icons.map(&:id))
      post_counts = posts.select(:icon_id).group(:icon_id).count
      replies = Reply.visible_to(current_user).where(icon_id: icons.map(&:id))
      reply_counts = replies.select(:icon_id).group(:icon_id).count
      post_ids = replies.select(:icon_id, :post_id).distinct.pluck(:icon_id, :post_id)
      post_ids += posts.select(:icon_id, :id).distinct.pluck(:icon_id, :id)

      @times_used = post_counts.merge(reply_counts) { |_, p, r| p + r }
      @posts_used = post_ids.uniq.group_by(&:first).transform_values(&:size)
    end
    render :show, locals: { icons: icons }
  end

  def edit
    @page_title = 'Edit Gallery: ' + @gallery.name
    use_javascript('galleries/uploader')
    use_javascript('galleries/edit')
  end

  def update
    @gallery.assign_attributes(permitted_params)

    begin
      Gallery.transaction do
        @gallery.gallery_groups = process_tags(GalleryGroup, obj_param: :gallery, id_param: :gallery_group_ids)
        @gallery.save!
      end
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = {
        message: "Gallery could not be saved.",
        array: @gallery.errors.full_messages,
      }
      @page_title = 'Edit Gallery: ' + @gallery.name_was
      use_javascript('galleries/uploader')
      use_javascript('galleries/edit')
      editor_setup
      set_s3_url
      render :edit
    else
      flash[:success] = "Gallery saved."
      redirect_to edit_gallery_path(@gallery)
    end
  end

  def icon
    if params[:image_ids].present?
      add_existing_icons
    else
      add_new_icons
    end
  end

  def destroy
    begin
      @gallery.destroy!
    rescue ActiveRecord::RecordNotDestroyed
      flash[:error] = {
        message: "Gallery could not be deleted.",
        array: @gallery.errors.full_messages,
      }
      redirect_to @gallery
    else
      flash[:success] = "Gallery deleted successfully."
      redirect_to user_galleries_path(current_user)
    end
  end

  def search
  end

  private

  def find_model
    unless (@gallery = Gallery.find_by_id(params[:id]))
      flash[:error] = "Gallery could not be found."
      redirect_to logged_in? ? user_galleries_path(current_user) : root_path
      return false
    end
    true
  end

  def require_edit_permission
    unless @gallery.user_id == current_user.id
      flash[:error] = "That is not your gallery."
      redirect_to user_galleries_path(current_user)
    end
  end

  def require_create_permission
    return unless current_user.read_only?
    flash[:error] = "You do not have permission to create galleries."
    redirect_to continuities_path and return
  end

  def require_own_gallery
    return if params[:id].to_s == '0'
    return unless find_model
    require_edit_permission
  end

  def find_user
    if params[:user_id].present?
      unless (@user = User.active.full.find_by_id(params[:user_id]))
        flash[:error] = 'User could not be found.'
        redirect_to root_path and return
      end
    else
      return if login_required
      return if readonly_forbidden
      @user = current_user
    end
    true
  end

  def add_existing_icons
    unless @gallery # gallery required for adding icons from other galleries
      flash[:error] = "Gallery could not be found."
      redirect_to user_galleries_path(current_user) and return
    end

    icon_ids = params[:image_ids].split(',').map(&:to_i).reject(&:zero?)
    icon_ids -= @gallery.icons.pluck(:id)
    icons = Icon.where(id: icon_ids, user_id: current_user.id)
    icons.each { |icon| @gallery.icons << icon }
    flash[:success] = "Icons added to gallery successfully."
    redirect_to @gallery and return
  end

  def add_new_icons
    @icons = (params[:icons] || []).reject { |icon| icon.values.all?(&:blank?) }
    if @icons.empty?
      flash.now[:error] = "You have to enter something."
      render :add and return
    end

    icons = @icons.map { |hash| Icon.new(icon_params(hash.except('filename', 'file')).merge(user: current_user)) }

    if icons.any?{ |i| !i.valid? }
      flash.now[:error] = {
        message: "Your icons could not be saved.",
        array: []
      }

      icons.each_with_index do |icon, index|
        next if icon.valid?
        @icons[index]['url'] = @icons[index]['s3_key'] = '' if icon.errors.added?(:url, :invalid)
        flash.now[:error][:array] += icon.errors.full_messages.map { |m| "Icon #{index + 1}: #{m.downcase}" }
      end

      render :add and return
    end

    errors = []
    icons.each_with_index do |icon, index|
      if icon.save
        @gallery.icons << icon if @gallery
      else
        errors += icon.errors.full_messages.map { |m| "Icon #{index + 1}: #{m.downcase}" }
      end
    end

    if errors.present?
      flash.now[:error] = {
        message: "Some of your icons could not be saved.",
        array: errors,
      }
      render :add
    else
      flash[:success] = "Icons saved successfully."
      if @gallery
        redirect_to @gallery
      else
        redirect_to user_gallery_path(id: 0, user: current_user)
      end
    end
  end

  def setup_new_icons
    if params[:type] == "existing"
      use_javascript('galleries/add_existing')
    else
      use_javascript('galleries/add_new')
      use_javascript('galleries/uploader')
    end
    @icons = []
    @unassigned = current_user.galleryless_icons
    @page_title = "Add Icons"
    @page_title += ": " + @gallery.name unless @gallery.nil?
  end

  def editor_setup
    use_javascript('galleries/editor')
    gon.user_id = current_user.id
  end

  def og_data
    icon_count = @gallery.icons.count
    desc = ["#{icon_count} " + "icon".pluralize(icon_count)]
    tags = @gallery.gallery_groups_data.pluck(:name)
    tag_count = tags.count
    desc << ("Tag".pluralize(tag_count) + ": " + generate_short(tags.join(', '))) if tag_count > 0
    title = [@gallery.name]
    title.prepend(@gallery.user.username) unless @gallery.user.deleted?
    {
      url: gallery_url(@gallery),
      title: title.join(' » '),
      description: desc.join("\n"),
    }
  end

  def permitted_params
    params.fetch(:gallery, {}).permit(
      :name,
      galleries_icons_attributes: [
        :id,
        :_destroy,
        icon_attributes: [:url, :keyword, :credit, :id, :_destroy, :s3_key],
      ],
      icon_ids: [],
    )
  end

  def icon_params(paramset)
    paramset.permit(:url, :keyword, :credit, :s3_key)
  end
end
