require 'rails_helper'

feature 'basic chat', type: :feature, js: true do
  def expect_chat_history_to_include(text)
    expect(page).to have_field('chat_output', with: /#{Regexp.escape(text)}/)
  end

  it 'allows changing nickname and sending chat messages' do
    visit new_game_path
    click_button 'Create Game'

    expect(page).to have_css('#chat_input')

    fill_in 'chat_input', with: '/nick Alice'
    click_button 'Say'
    expect_chat_history_to_include('Someone set nickname to Alice')

    fill_in 'chat_input', with: 'Hi there'
    click_button 'Say'
    expect_chat_history_to_include('Alice said: Hi there')
  end
end
