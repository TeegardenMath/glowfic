require "spec_helper"

RSpec.describe Api::V1::IndexSectionsController do
  describe "POST reorder" do
    it "requires login", :show_in_doc do
      post :reorder
      expect(response).to have_http_status(401)
      expect(response.json['errors'][0]['message']).to eq("You must be logged in to view that page.")
    end

    it "requires a index you have access to" do
      index = create(:index)
      section1 = create(:index_section, index_id: index.id)
      section2 = create(:index_section, index_id: index.id)
      expect(section1.reload.section_order).to eq(0)
      expect(section2.reload.section_order).to eq(1)

      section_ids = [section2.id, section1.id]

      login
      post :reorder, params: { ordered_section_ids: section_ids }
      expect(response).to have_http_status(403)
      expect(section1.reload.section_order).to eq(0)
      expect(section2.reload.section_order).to eq(1)
    end

    it "requires a single index" do
      user = create(:user)
      index1 = create(:index, user: user)
      index2 = create(:index, user: user)
      section1 = create(:index_section, index_id: index1.id)
      section2 = create(:index_section, index_id: index2.id)
      section3 = create(:index_section, index_id: index2.id)

      expect(section1.reload.section_order).to eq(0)
      expect(section2.reload.section_order).to eq(0)
      expect(section3.reload.section_order).to eq(1)

      section_ids = [section3.id, section2.id, section1.id]
      login_as(user)
      post :reorder, params: { ordered_section_ids: section_ids }
      expect(response).to have_http_status(422)
      expect(response.json['errors'][0]['message']).to eq('Sections must be from one index')
      expect(section1.reload.section_order).to eq(0)
      expect(section2.reload.section_order).to eq(0)
      expect(section3.reload.section_order).to eq(1)
    end

    it "requires valid section ids" do
      index = create(:index)
      section1 = create(:index_section, index_id: index.id)
      section2 = create(:index_section, index_id: index.id)
      expect(section1.reload.section_order).to eq(0)
      expect(section2.reload.section_order).to eq(1)
      section_ids = [-1]

      login_as(index.user)
      post :reorder, params: { ordered_section_ids: section_ids }
      expect(response).to have_http_status(404)
      expect(response.json['errors'][0]['message']).to eq('Some sections could not be found: -1')
      expect(section1.reload.section_order).to eq(0)
      expect(section2.reload.section_order).to eq(1)
    end

    it "works for valid changes", :show_in_doc do
      index = create(:index)
      index2 = create(:index, user: index.user)
      section1 = create(:index_section, index_id: index.id)
      section2 = create(:index_section, index_id: index.id)
      section3 = create(:index_section, index_id: index.id)
      section4 = create(:index_section, index_id: index.id)
      section5 = create(:index_section, index_id: index2.id)

      expect(section1.reload.section_order).to eq(0)
      expect(section2.reload.section_order).to eq(1)
      expect(section3.reload.section_order).to eq(2)
      expect(section4.reload.section_order).to eq(3)
      expect(section5.reload.section_order).to eq(0)

      section_ids = [section3.id, section1.id, section4.id, section2.id]

      login_as(index.user)
      post :reorder, params: { ordered_section_ids: section_ids }
      expect(response).to have_http_status(200)
      expect(response.json).to eq({'section_ids' => section_ids})
      expect(section1.reload.section_order).to eq(1)
      expect(section2.reload.section_order).to eq(3)
      expect(section3.reload.section_order).to eq(0)
      expect(section4.reload.section_order).to eq(2)
      expect(section5.reload.section_order).to eq(0)
    end

    it "works when specifying valid subset", :show_in_doc do
      index = create(:index)
      index2 = create(:index, user: index.user)
      section1 = create(:index_section, index_id: index.id)
      section2 = create(:index_section, index_id: index.id)
      section3 = create(:index_section, index_id: index.id)
      section4 = create(:index_section, index_id: index.id)
      section5 = create(:index_section, index_id: index2.id)

      expect(section1.reload.section_order).to eq(0)
      expect(section2.reload.section_order).to eq(1)
      expect(section3.reload.section_order).to eq(2)
      expect(section4.reload.section_order).to eq(3)
      expect(section5.reload.section_order).to eq(0)

      section_ids = [section3.id, section1.id]

      login_as(index.user)
      post :reorder, params: { ordered_section_ids: section_ids }
      expect(response).to have_http_status(200)
      expect(response.json).to eq({'section_ids' => [section3.id, section1.id, section2.id, section4.id]})
      expect(section1.reload.section_order).to eq(1)
      expect(section2.reload.section_order).to eq(2)
      expect(section3.reload.section_order).to eq(0)
      expect(section4.reload.section_order).to eq(3)
      expect(section5.reload.section_order).to eq(0)
    end
  end
end
