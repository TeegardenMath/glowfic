RSpec.describe News do
  let(:user) { create(:user) }
  let!(:news) { create(:news, user: user) }

  describe "#mark_read" do
    let(:new_news) { create(:news) }

    it "works for never reads" do
      expect { news.mark_read(user) }.to change{NewsView.count}.from(0).to(1)
      expect(NewsView.last.news).to eq(news)
    end

    it "works for subsequent reads" do
      news.mark_read(user)
      view = NewsView.last
      new_news = create(:news)
      new_news.mark_read(user)
      expect(view.reload.news).to eq(new_news)
    end

    it "does nothing for historical reads" do
      new_news.mark_read(user)
      view = NewsView.last
      expect(view.news).to eq(new_news)
      expect { news.mark_read(user) }.to not_change{view.news_id}
    end
  end

  describe "#num_unread_for" do
    it "handles no user" do
      expect(News.num_unread_for(nil)).to eq(0)
    end

    it "returns correct number for partially read" do
      news.mark_read(user)
      create_list(:news, 5)
      expect(News.num_unread_for(user)).to eq(5)
    end

    it "returns correct number for unread" do
      create_list(:news, 5)
      expect(News.num_unread_for(user)).to eq(6)
    end

    context "caching" do
      it "creates cache when num_unread_for is called" do
        expect(Rails.cache.exist?(NewsView.cache_string_for(user.id))).to eq(false)
        expect(News.num_unread_for(user)).to eq(1)
        expect(Rails.cache.exist?(NewsView.cache_string_for(user.id))).to eq(true)
      end

      it "deletes cache when NewsView is created" do
        expect(NewsView.count).to eq(0)
        news.mark_read(user)
        expect(Rails.cache.exist?(NewsView.cache_string_for(user.id))).to eq(false)
      end

      it "deletes cache when NewsView is updated" do
        news.mark_read(user)
        expect(NewsView.count).to eq(1)
        create(:news)
        News.num_unread_for(user)
        expect(Rails.cache.exist?(NewsView.cache_string_for(user.id))).to eq(true)
        news.mark_read(user)
        expect(Rails.cache.exist?(NewsView.cache_string_for(user.id))).to eq(false)
      end

      it "deletes cache when News is created" do
        expect(News.num_unread_for(user)).to eq(1)
        expect(Rails.cache.exist?(NewsView.cache_string_for(user.id))).to eq(true)
        create(:news)
        expect(Rails.cache.exist?(NewsView.cache_string_for(user.id))).to eq(false)
      end
    end
  end
end
