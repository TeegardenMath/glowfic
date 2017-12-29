require "spec_helper"

RSpec.describe Api::V1::SettingsController do
  describe "GET index" do
    shared_examples_for "index.json" do |in_doc|
      it "should support setting search", show_in_doc: in_doc do
        tag = create(:setting)
        get :index, params: { q: tag.name }
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(tag.as_json.stringify_keys)
      end

      it "should handle invalid input", show_in_doc: in_doc do
        get :index, params: { setting_id: -1 }
        expect(response).to have_http_status(422)
        expect(response.json).to have_key('errors')
        expect(response.json['errors'].first['message']).to include("Invalid parameter 'setting_id'")
      end
    end

    context "when logged in" do
      before(:each) { login }
      it_behaves_like "index.json", false
    end

    context "when logged out" do
      it_behaves_like "index.json", true
    end
  end

  describe "GET show" do
    it "should support getting settings" do
      tag = create(:setting)
      get :show, params: { id: tag.id }
      expect(response).to have_http_status(200)
      expect(response.json['id']).to eq(tag.id)
    end

    it "should handle invalid tag", show_in_doc: true do
      get :show, params: { id: 99 }
      expect(response).to have_http_status(404)
      expect(response.json).to have_key('errors')
      expect(response.json['errors'][0]['message']).to eq("Setting could not be found")
    end
  end
end
