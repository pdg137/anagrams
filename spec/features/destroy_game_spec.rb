require 'rails_helper'

feature 'destroy game', type: :feature, js: true do
  let!(:game) { Game.create!(log: 'AAABBBCCC') }
  let(:confirm_text) { 'Are you sure you want to delete this game?' }

  scenario 'prompts before deleting' do
    visit game_path(game)
    expect(page).to have_no_button('Destroy this game')
    click_link 'Edit this game'

    dismiss_confirm(confirm_text) do
      click_button 'Destroy this game'
    end

    expect(page).to have_current_path(edit_game_path(game), ignore_query: true)
    expect(Game.exists?(game.id)).to be(true)
  end

  scenario 'allows deletion after accepting the confirmation' do
    visit edit_game_path(game)

    accept_confirm(confirm_text) do
      click_button 'Destroy this game'
    end

    expect(page).to have_current_path(games_path, ignore_query: true)
    expect(Game.exists?(game.id)).to be(false)
  end
end
