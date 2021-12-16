RSpec.describe PostHelper do
  describe "#author_links" do
    let(:post) { create(:post) }

    context "with only deleted users" do
      before(:each) { post.user.update!(deleted: true) }

      it "handles only a deleted user" do
        expect(helper.author_links(post)).to eq('(deleted user)')
      end

      it "handles only two deleted users" do
        reply = create(:reply, post: post)
        reply.user.update!(deleted: true)
        expect(helper.author_links(post)).to eq('(deleted users)')
      end

      it "handles >4 deleted users" do
        replies = create_list(:reply, 4, post: post)
        replies.each { |r| r.user.update!(deleted: true) }
        expect(helper.author_links(post)).to eq('(deleted users)')
      end
    end

    context "with active and deleted users" do
      it "handles two users with post user deleted" do
        post.user.update!(deleted: true)
        reply = create(:reply, post: post)
        expect(helper.author_links(post)).to eq(helper.user_link(reply.user) + ' and 1 deleted user')
        expect(helper.author_links(post)).to be_html_safe
      end

      it "handles two users with reply user deleted" do
        reply = create(:reply, post: post)
        reply.user.update!(deleted: true)
        expect(helper.author_links(post)).to eq(helper.user_link(post.user) + ' and 1 deleted user')
        expect(helper.author_links(post)).to be_html_safe
      end

      it "handles three users with one deleted" do
        post.user.update!(username: 'xxx')
        reply = create(:reply, post: post)
        reply.user.update!(deleted: true)
        reply = create(:reply, post: post, user: create(:user, username: 'yyy'))
        links = [post.user, reply.user].map { |u| helper.user_link(u) }.join(', ')
        expect(helper.author_links(post)).to eq(links + ' and 1 deleted user')
        expect(helper.author_links(post)).to be_html_safe
      end

      it "handles three users with two deleted" do
        reply = create(:reply, post: post)
        reply.user.update!(deleted: true)
        reply = create(:reply, post: post)
        reply.user.update!(deleted: true)
        expect(helper.author_links(post)).to eq(helper.user_link(post.user) + ' and 2 deleted users')
        expect(helper.author_links(post)).to be_html_safe
      end

      it "handles >4 users with post user first" do
        post.user.update!(username: 'zzz')
        create(:reply, post: post, user: create(:user, username: 'yyy'))
        reply = create(:reply, post: post, user: create(:user, username: 'xxx'))
        reply.user.update!(deleted: true)
        create(:reply, post: post, user: create(:user, username: 'www'))
        create(:reply, post: post, user: create(:user, username: 'vvv'))
        stats_link = helper.link_to('4 others', stats_post_path(post), title: 'vvv, www, yyy')
        expect(helper.author_links(post)).to eq(helper.user_link(post.user) + ' and ' + stats_link)
        expect(helper.author_links(post)).to be_html_safe
      end

      it "handles >4 users with alphabetical user first iff post user deleted" do
        post.user.update!(username: 'zzz', deleted: true)
        create(:reply, post: post, user: create(:user, username: 'yyy'))
        create(:reply, post: post, user: create(:user, username: 'xxx'))
        reply = create(:reply, post: post, user: create(:user, username: 'aaa'))
        create(:reply, post: post, user: create(:user, username: 'vvv'))
        stats_link = helper.link_to('4 others', stats_post_path(post), title: 'vvv, xxx, yyy')
        expect(helper.author_links(post)).to eq(helper.user_link(reply.user) + ' and ' + stats_link)
        expect(helper.author_links(post)).to be_html_safe
      end
    end

    context "with only active users" do
      it "handles only one user" do
        expect(helper.author_links(post)).to eq(helper.user_link(post.user))
        expect(helper.author_links(post)).to be_html_safe
      end

      it "handles two users with commas" do
        post.user.update!(username: 'xxx')
        reply = create(:reply, post: post, user: create(:user, username: 'yyy'))
        expect(helper.author_links(post)).to eq(helper.user_link(post.user) + ', ' + helper.user_link(reply.user))
        expect(helper.author_links(post)).to be_html_safe
      end

      it "handles three users with commas and no and" do
        post.user.update!(username: 'zzz')
        users = [post.user]
        users << create(:reply, post: post, user: create(:user, username: 'yyy')).user
        users << create(:reply, post: post, user: create(:user, username: 'xxx')).user
        expect(helper.author_links(post)).to eq(users.reverse.map { |u| helper.user_link(u) }.join(', '))
        expect(helper.author_links(post)).to be_html_safe
      end

      it "handles >4 users with post user first" do
        post.user.update!(username: 'zzz')
        create(:reply, post: post, user: create(:user, username: 'yyy'))
        create(:reply, post: post, user: create(:user, username: 'xxx'))
        create(:reply, post: post, user: create(:user, username: 'www'))
        create(:reply, post: post, user: create(:user, username: 'vvv'))
        stats_link = helper.link_to('4 others', stats_post_path(post), title: 'vvv, www, xxx, yyy')
        expect(helper.author_links(post)).to eq(helper.user_link(post.user) + ' and ' + stats_link)
        expect(helper.author_links(post)).to be_html_safe
      end
    end
  end

  describe "#allowed_boards" do
    it "includes open-to-everyone boards" do
      board = create(:board)
      user = create(:user)
      post = build(:post)
      expect(helper.allowed_boards(post, user)).to eq([board])
    end

    it "includes locked boards with user in" do
      user = create(:user)
      board = create(:board, authors_locked: true, authors: [user])
      post = build(:post)
      expect(helper.allowed_boards(post, user)).to eq([board])
    end

    it "hides boards that user can't write in" do
      create(:board, authors_locked: true)
      user = create(:user)
      post = build(:post)
      expect(helper.allowed_boards(post, user)).to eq([])
    end

    it "shows the post's board even if the user can't write in it" do
      board = create(:board, authors_locked: true)
      user = create(:user)
      post = build(:post, board: board)
      expect(helper.allowed_boards(post, user)).to eq([board])
    end

    it "orders boards" do
      board_a = create(:board, name: "A")
      board_b_pinned = create(:board, name: "B", pinned: true)
      board_c = create(:board, name: "C")
      user = create(:user)
      post = build(:post)
      expect(helper.allowed_boards(post, user)).to eq([board_b_pinned, board_a, board_c])
    end
  end
end
