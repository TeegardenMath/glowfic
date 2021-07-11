RSpec.describe ApplicationHelper do
  describe "#breakable_text" do
    it "leaves blank strings intact" do
      expect(helper.send(:breakable_text, nil)).to eq(nil)
      expect(helper.send(:breakable_text, '')).to eq('')
    end

    it "does not do anything special to linebreaks" do
      expect(helper.send(:breakable_text, "text\ntext")).to eq("text\ntext")
      expect(helper.send(:breakable_text, "text\r\ntext")).to eq("text\r\ntext")
    end

    it "escapes HTML elements" do
      text = "screenname <b>text</b> &amp; more text"
      expected = "screenname &lt;b&gt;text&lt;/b&gt; &amp;amp; more text"
      result = helper.send(:breakable_text, text)
      expect(result).to eq(expected)
      expect(result).to be_html_safe
    end

    it "leaves simple text intact" do
      text = "screenname"
      expected = text
      expect(helper.send(:breakable_text, text)).to eq(expected)
    end

    it "leaves hyphenated text intact" do
      text = "screen-name"
      expected = text
      expect(helper.send(:breakable_text, text)).to eq(expected)

      text = "-screen-name-"
      expected = text
      expect(helper.send(:breakable_text, text)).to eq(expected)
    end

    it "adds wordbreak opportunities after underscores" do
      text = "screen_name"
      expected = "screen_<wbr>name"
      expect(helper.send(:breakable_text, text)).to eq(expected)
    end
  end

  describe "#swap_icon_url" do
    let(:user) { create(:user) }
    let(:swap) { 'icons/swap.png' }
    let(:swap_grey) { 'icons/swapgray.png' }

    before(:each) do
      without_partial_double_verification do
        allow(helper).to receive(:current_user).and_return(user)
      end
    end

    it "handles no user" do
      without_partial_double_verification do
        allow(helper).to receive(:current_user).and_return(nil)
      end
      expect(helper.swap_icon_url).to eq(swap)
    end

    it "handles no layout" do
      expect(helper.swap_icon_url).to eq(swap)
    end

    it "handles starries" do
      user.update!(layout: 'starrydark')
      expect(helper.swap_icon_url).to eq(swap_grey)
      user.update!(layout: 'starrylight')
      expect(helper.swap_icon_url).to eq(swap_grey)
    end

    it "handles dark" do
      user.update!(layout: 'dark')
      expect(helper.swap_icon_url).to eq(swap_grey)
    end

    it "handles other themes" do
      user.update!(layout: 'monochrome')
      expect(helper.swap_icon_url).to eq(swap)
    end
  end

  describe "#fun_name" do
    let(:user) { create(:user) }

    it "returns deleted user for deleted users" do
      user.update!(deleted: true)
      expect(helper.fun_name(user)).to eq('(deleted user)')
    end

    it "returns username for users without moieties" do
      expect(helper.fun_name(user)).to eq(user.username)
    end

    it "returns colored username for users with moieties" do
      color = '111111'
      user.update!(moiety: color)
      html = tag.span user.username, style: "font-weight: bold; color: ##{color}"
      expect(helper.fun_name(user)).to eq(html)
    end
  end

  shared_examples "link_img" do
    let(:user) { create(:user) }

    before(:each) do
      without_partial_double_verification do
        allow(helper).to receive(:current_user).and_return(user)
      end
    end

    it "handles no user" do
      without_partial_double_verification do
        allow(helper).to receive(:current_user).and_return(nil)
      end
      expect(method).to eq(icon)
    end

    it "handles no layout" do
      expect(method).to eq(icon)
    end

    it "handles dark" do
      user.update!(layout: 'dark')
      expect(method).to eq(dark_icon)
    end

    it "handles starrydark" do
      user.update!(layout: 'starrydark')
      expect(method).to eq(dark_icon)
    end

    it "handles other themes" do
      user.update!(layout: 'monochrome')
      expect(method).to eq(icon)
    end
  end

  describe "#unread_img" do
    let(:icon) { 'icons/note_go.png' }
    let(:dark_icon) { 'icons/bullet_go.png' }
    let(:method) { helper.unread_img }

    include_examples 'link_img'
  end

  describe "#lastlink_img" do
    let(:icon) { 'icons/note_go_strong.png' }
    let(:dark_icon) { 'icons/bullet_go_strong.png' }
    let(:method) { helper.lastlink_img }

    include_examples 'link_img'
  end

  describe "#per_page_options" do
    let(:options) { {10=>10, 25=>25, 50=>50, 100=>100} }

    it "handles no default" do
      without_partial_double_verification do
        allow(helper).to receive(:per_page).and_return(25)
      end
      html = options_for_select(options, 25)
      expect(helper.per_page_options).to eq(html)
    end

    it "handles default greater than 100" do
      html = options_for_select(options, nil)
      expect(helper.per_page_options(200)).to eq(html)
    end

    it "handles zero default" do
      html = options_for_select(options, 0)
      expect(helper.per_page_options(0)).to eq(html)
    end

    it "handles normal default" do
      html = options_for_select(options, 25)
      expect(helper.per_page_options(25)).to eq(html)
    end

    it "handles custom default" do
      options = {10=>10, 25=>25, 30=>30, 50=>50, 100=>100}
      html = options_for_select(options, 30)
      expect(helper.per_page_options(30)).to eq(html)
    end
  end
end
