RSpec.describe IconsController do
  include ActiveJob::TestHelper

  describe "DELETE delete_multiple" do
    let(:user) { create(:user) }
    let(:icon) { create(:icon) }

    it "requires login" do
      delete :delete_multiple
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      login_as(create(:reader_user))
      delete :delete_multiple
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("This feature is not available to read-only accounts.")
    end

    it "requires icons" do
      login_as(user)
      delete :delete_multiple
      expect(response).to redirect_to(user_galleries_url(user))
      expect(flash[:error]).to eq("No icons selected.")
    end

    it "requires valid icons" do
      Audited.audit_class.as_user(icon.user) { icon.destroy! }
      login_as(user)
      delete :delete_multiple, params: { marked_ids: [0, '0', 'abc', -1, '-1', icon.id] }
      expect(response).to redirect_to(user_galleries_url(user))
      expect(flash[:error]).to eq("No icons selected.")
    end

    context "removing icons from a gallery" do
      let(:icon) { create(:icon, user: user) }
      let(:gallery) { create(:gallery, user: user, icons: [icon]) }

      before(:each) { login_as(user) }

      it "requires gallery" do
        delete :delete_multiple, params: { marked_ids: [icon.id], gallery_delete: true }
        expect(response).to redirect_to(user_galleries_url(user.id))
        expect(flash[:error]).to eq("Gallery could not be found.")
      end

      it "requires your gallery" do
        delete :delete_multiple, params: { marked_ids: [icon.id], gallery_id: create(:gallery).id, gallery_delete: true }
        expect(response).to redirect_to(user_galleries_url(user.id))
        expect(flash[:error]).to eq("That is not your gallery.")
      end

      it "skips other people's icons" do
        icon = create(:icon)
        gallery = create(:gallery, user: user, icons: [icon])
        icon.reload
        expect(icon.galleries.count).to eq(1)
        delete :delete_multiple, params: { marked_ids: [icon.id], gallery_id: gallery.id, gallery_delete: true }
        icon.reload
        expect(icon.galleries.count).to eq(1)
      end

      it "removes int ids from gallery" do
        gallery
        expect(icon.galleries.count).to eq(1)
        delete :delete_multiple, params: { marked_ids: [icon.id], gallery_id: gallery.id, gallery_delete: true }
        expect(icon.galleries.count).to eq(0)
        expect(response).to redirect_to(gallery_url(gallery))
        expect(flash[:success]).to eq("Icons removed from gallery.")
      end

      it "removes string ids from gallery" do
        gallery
        expect(icon.galleries.count).to eq(1)
        delete :delete_multiple, params: { marked_ids: [icon.id.to_s], gallery_id: gallery.id, gallery_delete: true }
        expect(icon.galleries.count).to eq(0)
        expect(response).to redirect_to(gallery_url(gallery))
        expect(flash[:success]).to eq("Icons removed from gallery.")
      end

      it "goes back to index page if given" do
        gallery
        expect(icon.galleries.count).to eq(1)
        delete :delete_multiple, params: {
          marked_ids: [icon.id.to_s],
          gallery_id: gallery.id,
          gallery_delete: true,
          return_to: 'index',
        }
        expect(icon.galleries.count).to eq(0)
        expect(response).to redirect_to(user_galleries_url(user.id, anchor: "gallery-#{gallery.id}"))
      end

      it "goes back to tag page if given" do
        group = create(:gallery_group, user: user)
        group.galleries << gallery
        expect(icon.galleries.count).to eq(1)
        delete :delete_multiple, params: {
          marked_ids: [icon.id.to_s],
          gallery_id: gallery.id,
          gallery_delete: true,
          return_tag: group.id,
        }
        expect(icon.galleries.count).to eq(0)
        expect(response).to redirect_to(tag_url(group, anchor: "gallery-#{gallery.id}"))
      end
    end

    context "deleting icons from the site" do
      let(:icon) { create(:icon, user: user) }
      let(:gallery) { create(:gallery, user: user, icons: [icon]) }

      before(:each) { login_as(user) }

      it "skips other people's icons" do
        icon = create(:icon)
        delete :delete_multiple, params: { marked_ids: [icon.id] }
        icon.reload
      end

      it "removes int ids from gallery" do
        delete :delete_multiple, params: { marked_ids: [icon.id] }
        expect(Icon.find_by_id(icon.id)).to be_nil
      end

      it "removes string ids from gallery" do
        icon2 = create(:icon, user: user)
        delete :delete_multiple, params: { marked_ids: [icon.id.to_s, icon2.id.to_s] }
        expect(Icon.find_by_id(icon.id)).to be_nil
        expect(Icon.find_by_id(icon2.id)).to be_nil
        expect(response).to redirect_to(user_gallery_path(id: 0, user_id: user.id))
      end

      it "goes back to index page if given" do
        delete :delete_multiple, params: { marked_ids: [icon.id], gallery_id: gallery.id, return_to: 'index' }
        expect(Icon.find_by_id(icon.id)).to be_nil
        expect(response).to redirect_to(user_galleries_url(user.id, anchor: "gallery-#{gallery.id}"))
      end

      it "goes back to tag page if given" do
        group = create(:gallery_group, user: user)
        group.galleries << gallery
        delete :delete_multiple, params: { marked_ids: [icon.id], gallery_id: gallery.id, return_tag: group.id }
        expect(Icon.find_by_id(icon.id)).to be_nil
        expect(response).to redirect_to(tag_url(group, anchor: "gallery-#{gallery.id}"))
      end
    end
  end

  describe "GET show" do
    let(:icon) { create(:icon) }

    it "requires valid icon logged out" do
      get :show, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("Icon could not be found.")
    end

    it "requires valid icon logged in" do
      user = create(:user)
      login_as(user)
      get :show, params: { id: -1 }
      expect(response).to redirect_to(user_galleries_url(user))
      expect(flash[:error]).to eq("Icon could not be found.")
    end

    it "successfully loads when logged out" do
      get :show, params: { id: icon.id }
      expect(response).to have_http_status(200)
      expect(assigns(:posts)).to be_nil
    end

    it "successfully loads when logged in" do
      login
      get :show, params: { id: icon.id }
      expect(response).to have_http_status(200)
      expect(assigns(:posts)).to be_nil
    end

    it "successfully loads as reader" do
      login_as(create(:reader_user))
      get :show, params: { id: icon.id }
      expect(response).to have_http_status(200)
    end

    it "calculates OpenGraph meta" do
      user = create(:user, username: 'user')
      gallery1 = create(:gallery, name: 'gallery 1', user: user)
      gallery2 = create(:gallery, name: 'gallery 2', user: user)
      icon = create(:icon, keyword: 'icon', credit: "sample credit", gallery_ids: [gallery1.id, gallery2.id], user: user)

      get :show, params: { id: icon.id }

      meta_og = assigns(:meta_og)
      expect(meta_og.keys).to match_array([:url, :title, :description, :image])
      expect(meta_og[:url]).to eq(icon_url(icon))
      expect(meta_og[:title]).to eq('icon')
      expect(meta_og[:description]).to eq('Galleries: gallery 1, gallery 2. By sample credit')
      expect(meta_og[:image].keys).to match_array([:src, :width, :height])
      expect(meta_og[:image][:src]).to eq(icon.url)
      expect(meta_og[:image][:width]).to eq('75')
      expect(meta_og[:image][:width]).to eq('75')
    end

    context "post view" do
      let(:post) { create(:post, icon: icon, user: icon.user) }
      let(:other_post) { create(:post) }
      let(:reply) { create(:reply, icon: icon, user: icon.user, post: other_post) }

      before(:each) do
        create(:post) # should not be found
        post
        reply
      end

      it "loads posts logged out" do
        get :show, params: { id: icon.id, view: 'posts' }
        expect(response).to have_http_status(200)
        expect(assigns(:posts)).to match_array([post, other_post])
      end

      it "loads posts logged in" do
        login
        get :show, params: { id: icon.id, view: 'posts' }
        expect(response).to have_http_status(200)
        expect(assigns(:posts)).to match_array([post, other_post])
      end

      it "orders posts correctly" do
        post3 = create(:post, icon: icon, user: icon.user)
        post4 = create(:post, icon: icon, user: icon.user)
        post.update!(tagged_at: Time.zone.now - 5.minutes)
        other_post.update!(tagged_at: Time.zone.now - 2.minutes)
        post3.update!(tagged_at: Time.zone.now - 8.minutes)
        post4.update!(tagged_at: Time.zone.now - 4.minutes)
        get :show, params: { id: icon.id, view: 'posts' }
        expect(assigns(:posts)).to eq([other_post, post4, post, post3])
      end
    end

    context "galleries view" do
      render_views
      let(:gallery) { create(:gallery) }
      let!(:icon) { create(:icon, galleries: [gallery], user: gallery.user) }

      it "loads logged out" do
        get :show, params: { id: icon.id, view: 'galleries' }
        expect(response).to have_http_status(200)
        expect(assigns(:javascripts)).to include('galleries/expander_old')
      end

      it "loads logged in" do
        login
        get :show, params: { id: icon.id, view: 'galleries' }
        expect(response).to have_http_status(200)
        expect(assigns(:javascripts)).to include('galleries/expander_old')
      end
    end

    context "stats view" do
      let(:user) { create(:user) }
      let(:icon) { create(:icon, user: user) }
      let(:post) { create(:post, icon: icon, user: user) }

      before(:each) do
        create(:reply, post: post, user: user, icon: icon)
        create(:reply, icon: icon, user: user)
        create(:post, icon: icon, user: user, privacy: :private)
        create(:post, icon: icon, user: user, privacy: :registered)
        create(:post, icon: icon, user: user, privacy: :full_accounts)
      end

      it "fetches correct counts for icon owner" do
        login_as(user)
        get :show, params: { id: icon.id }
        expect(response).to have_http_status(200)
        expect(assigns(:times_used)).to eq(6)
        expect(assigns(:posts_used)).to eq(5)
      end

      it "fetches correct counts when logged in as full user" do
        login
        get :show, params: { id: icon.id }
        expect(response).to have_http_status(200)
        expect(assigns(:times_used)).to eq(5)
        expect(assigns(:posts_used)).to eq(4)
      end

      it "fetches correct counts when logged in as reader account" do
        login_as(create(:reader_user))
        get :show, params: { id: icon.id }
        expect(response).to have_http_status(200)
        expect(assigns(:times_used)).to eq(4)
        expect(assigns(:posts_used)).to eq(3)
      end

      it "fetches corect counts when logged out" do
        get :show, params: { id: icon.id }
        expect(response).to have_http_status(200)
        expect(assigns(:times_used)).to eq(3)
        expect(assigns(:posts_used)).to eq(2)
      end
    end
  end

  describe "GET edit" do
    let(:user) { create(:user) }

    it "requires login" do
      get :edit, params: { id: -1 }
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      login_as(create(:reader_user))
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("This feature is not available to read-only accounts.")
    end

    it "requires valid icon" do
      login_as(user)
      get :edit, params: { id: -1 }
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(user_galleries_url(user))
      expect(flash[:error]).to eq("Icon could not be found.")
    end

    it "requires your icon" do
      login_as(user)
      get :edit, params: { id: create(:icon).id }
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(user_galleries_url(user))
      expect(flash[:error]).to eq("That is not your icon.")
    end

    it "successfully loads" do
      login_as(user)
      icon = create(:icon, user: user)
      get :edit, params: { id: icon.id }
      expect(response.status).to eq(200)
    end
  end

  describe "PUT update" do
    let(:user) { create(:user) }
    let(:icon) { create(:icon, user: user) }

    it "requires login" do
      put :update, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      login_as(create(:reader_user))
      put :update, params: { id: -1 }
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("This feature is not available to read-only accounts.")
    end

    it "requires valid icon" do
      login_as(user)
      put :update, params: { id: -1 }
      expect(response).to redirect_to(user_galleries_url(user))
      expect(flash[:error]).to eq("Icon could not be found.")
    end

    it "requires your icon" do
      login_as(user)
      put :update, params: { id: create(:icon).id }
      expect(response).to redirect_to(user_galleries_url(user))
      expect(flash[:error]).to eq("That is not your icon.")
    end

    it "requires valid params" do
      login_as(user)
      put :update, params: { id: icon.id, icon: { url: '' } }
      expect(response).to render_template(:edit)
      expect(flash[:error][:message]).to eq("Your icon could not be saved due to the following problems:")
    end

    it "successfully updates" do
      login_as(user)
      new_url = icon.url + '?param'
      put :update, params: { id: icon.id, icon: { url: new_url, keyword: 'new keyword', credit: 'new credit' } }
      expect(response).to redirect_to(icon_url(icon))
      expect(flash[:success]).to eq("Icon updated.")
      icon.reload
      expect(icon.url).to eq(new_url)
      expect(icon.keyword).to eq('new keyword')
      expect(icon.credit).to eq('new credit')
    end
  end

  describe "DELETE destroy" do
    let(:user) { create(:user) }
    let(:icon) { create(:icon, user: user) }

    it "requires login" do
      delete :destroy, params: { id: -1 }
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      login_as(create(:reader_user))
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("This feature is not available to read-only accounts.")
    end

    it "requires valid icon" do
      login_as(user)
      delete :destroy, params: { id: -1 }
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(user_galleries_url(user))
      expect(flash[:error]).to eq("Icon could not be found.")
    end

    it "requires your icon" do
      login_as(user)
      delete :destroy, params: { id: create(:icon).id }
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(user_galleries_url(user))
      expect(flash[:error]).to eq("That is not your icon.")
    end

    it "successfully destroys" do
      login_as(user)
      delete :destroy, params: { id: icon.id }
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(user_galleries_url(user))
      expect(flash[:success]).to eq("Icon deleted successfully.")
      expect(Icon.find_by_id(icon.id)).to be_nil
    end

    it "successfully goes to gallery if one" do
      gallery = create(:gallery, user: icon.user)
      icon.galleries << gallery
      login_as(user)
      delete :destroy, params: { id: icon.id }
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(gallery_url(gallery))
      expect(flash[:success]).to eq("Icon deleted successfully.")
      expect(Icon.find_by_id(icon.id)).to be_nil
    end

    it "handles destroy failure" do
      post = create(:post, user: user, icon: icon)
      login_as(user)
      expect_any_instance_of(Icon).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed, 'fake error')
      delete :destroy, params: { id: icon.id }
      expect(response).to redirect_to(icon_url(icon))
      expect(flash[:error]).to eq({ message: "Icon could not be deleted.", array: [] })
      expect(post.reload.icon).to eq(icon)
    end
  end

  describe "POST avatar" do
    let(:user) { create(:user) }
    let(:icon) { create(:icon, user: user) }

    it "requires login" do
      post :avatar, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      login_as(create(:reader_user))
      post :avatar, params: { id: -1 }
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("This feature is not available to read-only accounts.")
    end

    it "requires valid icon" do
      login_as(user)
      post :avatar, params: { id: -1 }
      expect(response).to redirect_to(user_galleries_url(user))
      expect(flash[:error]).to eq("Icon could not be found.")
    end

    it "requires your icon" do
      login_as(user)
      post :avatar, params: { id: create(:icon).id }
      expect(response).to redirect_to(user_galleries_url(user))
      expect(flash[:error]).to eq("That is not your icon.")
    end

    it "handles save errors" do
      expect(user.avatar_id).to be_nil
      login_as(user)

      expect_any_instance_of(User).to receive(:update).and_return(false)
      post :avatar, params: { id: icon.id }

      expect(response).to redirect_to(icon_url(icon))
      expect(flash[:error]).to eq("Something went wrong.")
      expect(user.reload.avatar_id).to be_nil
    end

    it "works" do
      expect(user.avatar_id).to be_nil
      login_as(user)

      post :avatar, params: { id: icon.id }

      expect(response).to redirect_to(icon_url(icon))
      expect(flash[:success]).to eq("Avatar has been set!")
      expect(user.reload.avatar_id).to eq(icon.id)
    end
  end

  describe "GET replace" do
    let(:user) { create(:user) }
    let(:icon) { create(:icon, user: user) }

    it "requires login" do
      get :replace, params: { id: create(:icon).id }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      login_as(create(:reader_user))
      get :replace, params: { id: create(:icon).id }
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("This feature is not available to read-only accounts.")
    end

    it "requires valid icon" do
      login_as(user)
      get :replace, params: { id: -1 }
      expect(response).to redirect_to(user_galleries_url(user))
      expect(flash[:error]).to eq("Icon could not be found.")
    end

    it "requires your icon" do
      login_as(user)
      get :replace, params: { id: create(:icon).id }
      expect(response).to redirect_to(user_galleries_url(user))
      expect(flash[:error]).to eq("That is not your icon.")
    end

    context "sets variables correctly" do
      let!(:alts) { create_list(:icon, 5, user: user) }
      let!(:other_icon) { create(:icon, user: user) }
      let!(:post) { create(:post, user: user, icon: icon) }
      let!(:reply) { create(:reply, user: user, icon: icon) }

      before(:each) do
        create(:reply, post: post, user: user, icon: icon)
        create(:post, user: user, icon: other_icon)
        create(:reply, user: user, icon: other_icon)

        login_as(user)
      end

      it "with galleryless icon" do
        gallery = create(:gallery, user: user, icons: [other_icon])
        expect(gallery.icons).to match_array([other_icon])

        get :replace, params: { id: icon.id }
        expect(response).to have_http_status(200)
        expect(assigns(:alts)).to match_array(alts)
        expect(assigns(:posts)).to match_array([post, reply.post])
        expect(assigns(:page_title)).to eq("Replace Icon: " + icon.keyword)
      end

      it "with icon gallery" do
        gallery = create(:gallery, user: user, icon_ids: [icon.id] + alts.map(&:id))
        expect(gallery.icons).to match_array([icon] + alts)

        get :replace, params: { id: icon.id }
        expect(response).to have_http_status(200)
        expect(assigns(:alts)).to match_array(alts)
        expect(assigns(:posts)).to match_array([post, reply.post])
        expect(assigns(:page_title)).to eq("Replace Icon: " + icon.keyword)
      end
    end
  end

  describe "POST do_replace" do
    let(:user) { create(:user) }
    let(:icon) { create(:icon, user: user) }

    it "requires login" do
      post :do_replace, params: { id: create(:icon).id }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      login_as(create(:reader_user))
      post :do_replace, params: { id: create(:icon).id }
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("This feature is not available to read-only accounts.")
    end

    it "requires valid icon" do
      login_as(user)
      post :do_replace, params: { id: -1 }
      expect(response).to redirect_to(user_galleries_url(user))
      expect(flash[:error]).to eq("Icon could not be found.")
    end

    it "requires your icon" do
      login_as(user)
      post :do_replace, params: { id: create(:icon).id }
      expect(response).to redirect_to(user_galleries_url(user))
      expect(flash[:error]).to eq("That is not your icon.")
    end

    it "requires valid other icon" do
      login_as(user)
      post :do_replace, params: { id: icon.id, icon_dropdown: -1 }
      expect(response).to redirect_to(replace_icon_path(icon))
      expect(flash[:error]).to eq('Icon could not be found.')
    end

    it "requires other icon to be yours if present" do
      other_icon = create(:icon)
      login_as(user)
      post :do_replace, params: { id: icon.id, icon_dropdown: other_icon.id }
      expect(response).to redirect_to(replace_icon_path(icon))
      expect(flash[:error]).to eq('That is not your icon.')
    end

    context "succeeds" do
      let(:other_icon) { create(:icon, user: user) }
      let!(:icon_post) { create(:post, user: user, icon: icon) }
      let!(:reply) { create(:reply, user: user, icon: icon) }

      before(:each) { login_as(user) }

      it "with valid other icon" do
        reply_post_icon = reply.post.icon_id

        perform_enqueued_jobs(only: UpdateModelJob) do
          post :do_replace, params: { id: icon.id, icon_dropdown: other_icon.id }
        end
        expect(response).to redirect_to(icon_path(icon))
        expect(flash[:success]).to eq('All uses of this icon will be replaced.')

        expect(icon_post.reload.icon_id).to eq(other_icon.id)
        expect(reply.reload.icon_id).to eq(other_icon.id)
        expect(reply.post.reload.icon_id).to eq(reply_post_icon) # check it doesn't replace all replies in a post
      end

      it "with no other icon" do
        perform_enqueued_jobs(only: UpdateModelJob) do
          post :do_replace, params: { id: icon.id }
        end
        expect(response).to redirect_to(icon_path(icon))
        expect(flash[:success]).to eq('All uses of this icon will be replaced.')

        expect(icon_post.reload.icon_id).to be_nil
        expect(reply.reload.icon_id).to be_nil
      end

      it "and filters to selected posts if given" do
        other_post = create(:post, user: user, icon: icon)

        perform_enqueued_jobs(only: UpdateModelJob) do
          post :do_replace, params: {
            id: icon.id,
            icon_dropdown: other_icon.id,
            post_ids: [icon_post.id, reply.post.id],
          }
        end
        expect(response).to redirect_to(icon_path(icon))
        expect(flash[:success]).to eq('All uses of this icon will be replaced.')

        expect(icon_post.reload.icon_id).to eq(other_icon.id)
        expect(reply.reload.icon_id).to eq(other_icon.id)
        expect(other_post.reload.icon_id).to eq(icon.id)
      end
    end
  end
end
