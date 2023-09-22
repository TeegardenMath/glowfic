RSpec.feature "Adding a character alias" do
  scenario "Adding successfully" do
    user = login
    character = create(:character, user: user)
    visit characters_path
    click_link character.name
    click_link "Edit Character"
    expect(page).not_to have_text("AnAlias")
    click_link "New Alias"
    fill_in "Alias", with: "AnAlias"
    click_button 'Save'
    expect(page).to have_selector('.success', text: 'Alias created.')
    expect(page).to have_text("AnAlias")
  end
end
